package Devel::Profiler;

use 5.006;
use strict;
use warnings;

our $VERSION = 0.04;

use B;
use Time::HiRes qw(time);

# set this to see a running chatter from the module.  Don't do this
# and then use the profiling results - the time spent printing
# debugging text is not accounted for in the profile.  Also, the
# overhead timing is turned off during debugging.
use constant DEBUG => $ENV{DEVEL_PROFILER_DEBUG} || 0;

# scan for subroutines 
INIT { init() }

# finish up
END { end() }

# initialize module
sub init {
    print STDERR __PACKAGE__ . "::init() called\n" if DEBUG;
    our $INIT = 1;
    our $PID = $$; # remember pid
    start_output();
    scan();
    start_clock();
    emit_pulse(1);
}

# write final results and close output file
sub end {
    our $INIT;
    return unless $INIT;
    print STDERR __PACKAGE__ . "::end() called\n" if DEBUG;

    # fake exits for subs remaining on stack.  Devel::DProf doesn't
    # bother, preferring to leave it to dprofpp -F.
    fake_exits();

    # empty the buffer
    empty_buffer();

    # emit the final timings
    emit_final_times();

    our $PID;
    if ($PID == $$) {
        close(FH) or die "Unable to close Devel::Profiler output file: $!";
    }
}

# take parameters from use line
sub import {
    my $pkg = shift;
    print STDERR __PACKAGE__ . "::import(", join(', ', @_), ") called\n"
      if DEBUG;
    die "Invalid import options for Devel::Profiler " . 
      "- must be a list of key-value pairs."
        if @_ % 2;

    # check for typos
    for (my $i = 0; $i < @_; $i += 2) {
        die "Unknown option name for Devel::Profiler : '$_[$i]'."
          unless grep { $_[$i] eq $_ } qw(output_file bad_pkgs bad_subs
                                          buffer_size override_caller
                                          package_filter sub_filter hz);
    }

    # setup defaults and allow @_ to override
    our %OPT = ( output_file     => 'tmon.out',
                 bad_pkgs        => [qw(UNIVERSAL Time::HiRes B Carp Exporter
                                        Cwd Config CORE DynaLoader XSLoader
                                        AutoLoader)],
                 bad_subs        => [],
                 buffer_size     => 64 * 1024,
                 override_caller => 1,
                 package_filter  => [],
                 sub_filter      => [],
                 hz              => 1000,
                 @_ );

    # push on list of pkgs to always avoid
    push @{$OPT{bad_pkgs}}, "Devel::Profiler", "DB";

    # compile lists into hashes for faster lookup
    $OPT{bad_pkgs} = { map { ($_, 1) } @{$OPT{bad_pkgs}} };
    $OPT{bad_subs} = { map { ($_, 1) } @{$OPT{bad_subs}} };

    # make sure package_filter is an array
    $OPT{package_filter} = [ $OPT{package_filter} ]
      unless ref $OPT{package_filter} eq 'ARRAY';

    # make sure sub_filter is an array
    $OPT{sub_filter} = [ $OPT{sub_filter} ]
      unless ref $OPT{sub_filter} eq 'ARRAY';
      
    # promote buffer size to global, it's used in profile_sub too
    # frequently to be accessed in a hash
    our $BUFFER_SIZE = $OPT{buffer_size};

    # same for hz
    our $HZ = $OPT{hz};

    # override caller
    *CORE::GLOBAL::caller = \&my_caller
      if $OPT{override_caller};
}

#
# scanning and instrumentation
#

# traverse all packages intrumenting all subroutines found
sub scan {
    our (%OPT, $INIT);
    return unless $INIT;
    my %saw_pkg;  # packages touched on this pass

    my ($sym, $glob, $code);

    my @pkgs = ('main::');    
  PKG: while (@pkgs) {
        my $pkg = pop @pkgs;
        
        # is it a bad package?
        next if is_bad_pkg($pkg);

        # haven't I seen this place before?
        next if exists $saw_pkg{$pkg}; $saw_pkg{$pkg} = 1;           
        
        print STDERR "\n\n", __PACKAGE__, "::scan examining $pkg\n" 
          if DEBUG;
        
        no strict 'refs'; # need symbolic references to diddle symbol tables
        while (($sym, $glob) = each %{$pkg}) {
            next if $sym eq $pkg; # self ref?  (%main::main::main::...)
            
            # found a subpackage?
            if ($sym =~ /\:\:$/) {
                if ($pkg ne 'main::') {
                    push(@pkgs, "$pkg$sym");
                } else {
                    push(@pkgs, $sym);
                }
                next;
            }
            
            # found a code ref?  then instrument it
            instrument($pkg, $sym, $code) 
              if defined($code = *{$glob}{CODE}) and ref $code eq 'CODE';
              
        }
    }
}

sub is_bad_pkg {
    my $pkg = shift;
    our %OPT;
    our %KNOWN_PKGS;

    # take off trailing ::
    substr($pkg, -2, 2) = "";

    # check cache to avoid calling package filters thousands of times
    if (exists $KNOWN_PKGS{$pkg}) {
        return $KNOWN_PKGS{$pkg};
    }

    # check stop-list
    elsif (exists $OPT{bad_pkgs}{$pkg}) {
        $KNOWN_PKGS{$pkg} = 1;
        return 1;
    }

    # don't profile pragmata
    elsif ($pkg =~ /^[a-z\:]+$/ and $pkg ne 'main') {
        $KNOWN_PKGS{$pkg} = 1;
        return 1;
    }
    
    # check package filters if we have any
    elsif ($OPT{package_filter}) {
        foreach my $filter (@{$OPT{package_filter}}) {
            unless ($filter->($pkg)) {
                $KNOWN_PKGS{$pkg} = 1;
                return 1;
            }
        }
    }

    $KNOWN_PKGS{$pkg} = 0;
    return 0;
}

# check sub tables
sub is_bad_sub {
    my ($pkg, $sub) = @_;
    our %OPT;

    # check package
    return 1 if is_bad_pkg($pkg);

    # take off trailing ::
    substr($pkg, -2, 2) = "";

    # check sub filters if we have any (not worth caching because subs
    # are checked usually only once or twice)
    if ($OPT{sub_filter}) {
        foreach my $filter (@{$OPT{sub_filter}}) {
            return 1 unless $filter->($pkg, $sub);
        }
    }

    return 0;
}

# instrument a single subroutine
sub instrument {
    my ($pkg, $sym, $code) = @_;
    my $name = "$pkg$sym";
    our %OPT;
    our %my_code; # hash of code addresses of instrumented subroutines

    print STDERR __PACKAGE__ . 
      "::instrument($pkg, $sym) called.\n"
        if DEBUG;

    # is this a bad sub
    return if is_bad_sub($pkg, $sym);

    # never profile DESTROY
    return if $sym eq 'DESTROY';

    # is this subroutine already instrumented?
    return if exists $my_code{$name};

    # is this subroutine a fake?  Trying to instrument fake subs leads
    # to certains doom.  See: http://perlmonks.org/index.pl?node_id=168546
    return unless defined(&{$name});
    
    # try to guess if this is an imported alias
    my $real_pkg = get_real_package($code);
    if (defined $real_pkg and $pkg ne $real_pkg) {
        my $real_name = "$real_pkg$sym";
        if (not exists $my_code{$real_name}) {
            no strict 'refs';
            instrument($real_pkg, $sym, \&{$name});
        }
        if (exists $my_code{$real_name}) {
            no strict 'refs';
            no warnings 'redefine';
            *{$name} = \&{$real_name};
        }
        return;
    }

    # don't wrap AUTOLOAD - it breaks $AUTOLOAD for some reason
    return if $name =~ /::AUTOLOAD$/;
    
    # check stop-list
    return if exists $OPT{bad_subs}{$name};

    # don't instrument constants
    return if is_constant($name, $code);

    # create a profiling stub for the sub
    no strict 'refs';
    no warnings 'redefine';	    
    (my $pkg_name = $real_pkg) =~ s/\:\:$//;               
    if (defined(my $proto = prototype($name))) {
        # create wrapper around calling prof_code
        *{$name} = 
          eval "sub ($proto) { profile_sub(\$pkg_name,\$sym,\$code,\@_) }";
    } else {
        # assign the prof code directly
        *{$name} = sub { profile_sub($pkg_name, $sym, $code, @_); };
    }

    # save prof_code for use later
    $my_code{$name} = \&{$name};

    print STDERR __PACKAGE__ . 
      "::instrument installed sub for $name\n" 
        if DEBUG;
}

sub get_real_package {
    my $obj = B::svref_2object(shift);
    return unless $obj and ref $obj eq 'B::CV';

    my $gv  = $obj->GV;
    return unless $gv  and ref $gv  eq 'B::GV';

    my $egv = $gv->EGV;
    my $stash;
    if ($egv and ref $egv eq 'B::GV') {
        $stash = $egv->STASH;
    } else {
        $stash = $gv->STASH;
    }
    if ($stash and ref $stash eq 'B::HV') {
        return $stash->NAME . '::';
    }
    return;
}

# detect constants - is this the only/best way to do it?
sub is_constant {
    no strict 'refs';
    my $name = shift;
    my $code = shift;

    # must have any empty prototype to be a constnat
    my $proto = prototype($code);
    return 0 if defined $proto and length $proto;

    # attempt to redefine - this will cause a warning for a real
    # constant that starts with "Constant"
    my $is_const;
    {
        local $SIG{__WARN__} = sub { $is_const = 1 if $_[0] =~ /^Constant/ };
        eval { *{$name} = sub { "TEST" } }; # set it to something else
        eval { *{$name} = $code; };            # and set it back
    }

    print STDERR __PACKAGE__ . "::is_constant : $name is a constant.\n"
      if DEBUG and $is_const;

    # all done
    return $is_const;
}


#
# profiling stub
#

sub profile_sub {
    my ($pkg, $sym, $code) = (shift, shift, shift);
    our (%ID, $LAST_ID);
    our @STACK;
    our ($BUFFER, $BUFFER_SIZE);

    # emit a timing mark
    emit_pulse();

    # get id
    my $id = $ID{"$pkg$sym"};
    if (not defined $id) {
        # first entry into sub - assign new ID
        $id = $ID{"$pkg$sym"} = ++$LAST_ID;
        $BUFFER .= "& $id $pkg $sym\n";
    }

    # check if caller is from Devel::Profiler - if it is then this sub
    # was called via goto &sub rather than a normal call
    my @caller = CORE::caller(3);

    #print STDERR "CALLER: ", 
    #  join(', ', map { defined $_ ? $_ : "(undef)" } @caller), "\n";

    if (@STACK and ($caller[3] || "") =~ /^Devel::Profiler/) {
        # emit goto entry mark
        $BUFFER .= "* $id\n";

        # replace top of stack with marker to supress exit
        $STACK[$#STACK] = undef;
    } else {
        # emit entry mark
        $BUFFER .= "+ $id\n";
    }
    
    # push $id and caller data onto stack for use later
    push(@STACK, $id);

    # need to empty buffer?
    empty_buffer() if length($BUFFER) >= $BUFFER_SIZE;

    print STDERR __PACKAGE__, "::profile_sub calling ${pkg}::$sym ($id)\n"
      if DEBUG and $sym ne 'test_sub';

    # make call, in correct context
    my $wantarray = wantarray;
    my ($ret, @ret);

    eval {
        if ($wantarray) {
            @ret = &$code;
        } elsif (defined $wantarray) {
            $ret = &$code;
        } else {
            &$code;
        }	 
    };

    # get returned id from stack, ignore caller data we won't need it now
    $id = pop @STACK;

    print STDERR __PACKAGE__, "::profile_sub ($id) returned\n"
      if DEBUG and defined $id and $sym ne 'test_sub';

    # emit a timing mark
    emit_pulse() if defined $id;

    # did the sub die?
    if ($@) {
        # emit die mark
        $BUFFER .= "/ $id\n" if defined $id;

        if (ref $@) {
            # just rethrow exception objects
            die $@;
        } else {
            # rethrow string die with a new-line to preserve the die
            # location
            die "$@\n";
        }
    }

    # emit exit mark
    $BUFFER .= "- $id\n" if defined $id;

    # need to empty buffer?
    empty_buffer() if length($BUFFER) >= $BUFFER_SIZE;

    # return as appropriate
    if ($wantarray) {
        return @ret;
    } elsif (defined $wantarray) {
        return $ret;
    }
    return;
}

#
# output routines
#


# open output file
sub start_output {
    our (%OPT, $BUFFER, $BUFFER_SIZE, $PID, $HZ);

    # only open files in the parent
    return unless $PID == $$;
 
    # make sure we don't try to write any output while testing
    local $BUFFER_SIZE = 1024 * 1024 * 1024;

    # initialize buffer
    $BUFFER = "";

    # test overhead unless we're debugging, in which case just use fake data
    my ($tests, $real, $user, $sys) = DEBUG ? (10000, 1, 0, 0) :
                                              test_overhead();

    # throw out junk data
    $BUFFER = "";

    # open output file
    open(FH, ">", $OPT{output_file}) or
      die "Unable to open output file \"$OPT{output_file}\" : $!";

    print STDERR __PACKAGE__,
      "::start_output : opened $OPT{output_file} for output.\n"
        if DEBUG;

    # output the preamble
    print FH <<END;
#fOrTyTwO
\$hz=$HZ;
\$XS_VERSION="Devel::Profiler $VERSION";
\$over_utime=$user;
\$over_stime=$sys;
\$over_rtime=$real;
\$over_tests=$tests;
END

    # note location to put final times
    our $OUTPUT_RESULTS_AT = tell(FH);

    # pad with room for results
    print FH " " x 255, "\n";

    # print token to start profiling section
    print FH "PART2\n";
}


# emit a timing pulse if there's anything to output.  called by
# profile_sub.
sub emit_pulse {
    my $force = shift;
    our ($RCLOCK, $UCLOCK, $SCLOCK, $BUFFER, $HZ);
    my  ($rtime, $utime, $stime, $relapse, $uelapse, $selapse);
    $rtime           = time;
    ($utime, $stime) = times;

    # get elapsed time in even HZ
    $relapse         = int(($rtime - $RCLOCK) * $HZ);
    $uelapse         = int(($utime - $UCLOCK) * $HZ);
    $selapse         = int(($stime - $SCLOCK) * $HZ);

    # anything to report?
    if ($relapse or $uelapse or $selapse or $force) {
        $BUFFER .= "@ $uelapse $selapse $relapse\n";

        # update clocks
        $RCLOCK = $rtime;
        $SCLOCK = $stime;
        $UCLOCK = $utime;
    }
}

# fake exits for subs left on the stack
sub fake_exits {
    our (@STACK, $BUFFER);
    while(@STACK) {
        $BUFFER .= "- " . pop(@STACK) . "\n";
    }
}

# empty buffer into OUTPUT
sub empty_buffer {
    our ($RCLOCK, $UCLOCK, $SCLOCK, $BUFFER, $PID, $HZ);
    
    # only output in the parent
    if ($PID != $$) {
        $BUFFER = "";
        return;
    }

    # start a timer to see if this is worth excluding from profile
    my  ($rtime, $utime, $stime, $relapse, $uelapse, $selapse);
    $rtime           = time;
    ($utime, $stime) = times;

    print FH $BUFFER;
    $BUFFER = "";

    # get elapsed time, in even HZ
    $relapse         = int(($rtime - $RCLOCK) * $HZ);
    $uelapse         = int(($utime - $UCLOCK) * $HZ);
    $selapse         = int(($stime - $SCLOCK) * $HZ);
    if ($relapse or $uelapse or $selapse) {
        # use the magic Devel::DProf::write token that tells dprofpp
        # to ignore this time
        print FH "+ & Devel::DProf::write\n",
                  "@ $uelapse $selapse $relapse\n",
                  "- & Devel::DProf::write\n";

        # update clock
        $RCLOCK = $rtime;
        $SCLOCK = $stime;
        $UCLOCK = $utime;
    }
}

# emit final times
sub emit_final_times {
    our ($RCLOCK_START, $UCLOCK_START, $SCLOCK_START, $OUTPUT_RESULTS_AT, 
         $PID, $HZ);
    return unless $PID == $$;

    our $RCLOCK            = time;
    our ($UCLOCK, $SCLOCK) = times;    
    
    my $rfinal = int(($RCLOCK - $RCLOCK_START) * $HZ);
    my $ufinal = int(($UCLOCK - $UCLOCK_START) * $HZ);
    my $sfinal = int(($SCLOCK - $SCLOCK_START) * $HZ);
    
    # seek to the right place
    seek(FH, $OUTPUT_RESULTS_AT, 0) or die "Unable to seek : $!";
    print FH <<END
\$rrun_utime=$ufinal;
\$rrun_stime=$sfinal;
\$rrun_rtime=$rfinal;
END
}

#
# timing routines
#

# synchronize clocks
sub start_clock {
    our $RCLOCK            = time;
    our ($UCLOCK, $SCLOCK) = times;
    our $RCLOCK_START = $RCLOCK;
    our $UCLOCK_START = $UCLOCK;
    our $SCLOCK_START = $SCLOCK;
    print STDERR __PACKAGE__ . "::start_clock ($RCLOCK $UCLOCK $SCLOCK)\n"
      if DEBUG;
}

# determine the profiling overhead
sub test_overhead {
    our $HZ;
    my $n = 10000; # how many times to run the test sub
    my ($utime1, $stime1, $rtime1, $utime2, $stime2, $rtime2);

    # first get times without instrumenting
    ($utime1, $stime1) = times;
    $rtime1            = time;
    test_sub($_) for (0 .. $n);
    ($utime2, $stime2) = times;
    $rtime2            = time;

    my $utime_base = $utime2 - $utime1;
    my $stime_base = $stime2 - $stime1;
    my $rtime_base = $rtime2 - $rtime1;
    
    # run tests to determine how much overhead instrumenting a sub causes
    instrument("Devel::Profiler::", "test_sub", \&test_sub, *test_sub);

    # start clocks for timing fakeup
    start_clock();

    # now measure instrumented times
    ($utime1, $stime1) = times;
    $rtime1            = time;
    test_sub($_) for (0 .. $n);
    ($utime2, $stime2) = times;
    $rtime2            = time;

    # calculate cost of profiling
    my $utime_inst = $utime2 - $utime1;
    my $stime_inst = $stime2 - $stime1;
    my $rtime_inst = $rtime2 - $rtime1;

    return ($n,
            int(($rtime_inst - $rtime_base) * $HZ),
            int(($utime_inst - $utime_base) * $HZ),
            int(($stime_inst - $stime_base) * $HZ));
}

# used to test call overhead.
sub test_sub { }

#
# CORE overrides to keep other modules from noticing my meddling.
# These are installed at INIT along with instrumented subs.
#

# override for caller() that ignores Devel::Profiler frames
sub my_caller {
    my $arg = shift;
    my $target = defined $arg ? $arg : 0;
    my $found = -1;
    my @stack;

    print STDERR __PACKAGE__,"::caller(",(defined($arg) ? $arg : "undef"),")\n"
      if DEBUG;
    dump_caller() if DEBUG > 1;

    # step through stack frames accumulating good ones
    my $i = 1;
    while(my @caller = CORE::caller($i++)) {
        push(@stack, \@caller); # save for later

        # is this a bad one?
        next if $caller[0] eq 'Devel::Profiler';

        # is this a profiled sub?  if so, patch up from 3 frames up
        if ($caller[3] eq 'Devel::Profiler::__ANON__') {
            @caller[3..9] = @{$stack[($i - 5)]}[3..9];
        }
        
        # all done?
        last if ++$found == $target;
    }

    # return nothing if we didn't find it
    return unless $found == $target;

    # return the top of the stack or nothing
    my $c = @stack ? $stack[-1] : [];

    print STDERR "Returning CALLER($target) => [", 
      (map { defined $_ ? "\n\t$_" : "\n\t(undef)" } @$c), "\n]\n"
        if DEBUG;

    if (wantarray) {
        return defined $arg ? @$c : @{$c}[0,1,2];
    } else {
        return $c->[0];
    }
}

#
# debugging routines
#

# pretty-prints the call stack to STDERR
sub dump_caller {
    my $i = 0;
    my @caller;
    my @names = qw(package filename line subroutine hasargs
                   wantarray evaltext is_require hints bitmask);
    while (@caller = CORE::caller($i + 1)) {
        print STDERR "-"x3, " Frame [$i] ", "-"x50, "\n";
        for (0 .. $#caller) {
            printf STDERR "%15s => %s\n", $names[$_], 
              (defined $caller[$_] ? $caller[$_] : "(undef)");
        }
        $i++;
    }
}  


1;
__END__

=head1 NAME

Devel::Profiler - a Perl profiler compatible with dprofpp

=head1 SYNOPSIS

To profile a Perl script, run it with a command-line like:

  $ perl -MDevel::Profiler script.pl

Or add a line using Devel::Profiler anywhere your script:

  use Devel::Profiler;

Use the script as usual and perform the operations you want to
profile.  Then run C<dprofpp> to analyze the generated file (called
C<tmon.out>):

  $ dprofpp

See the C<dprofpp> man page for details on examining the output.

For Apache/mod_perl profiling see the
L<Devel::Profiler::Apache|Devel::Profiler::Apache> module included
with Devel::Profiler.

=head1 DESCRIPTION

This module implements a Perl profiler that outputs profiling data in
a format compatible with C<dprofpp>, L<Devel::DProf|Devel::DProf>'s
profile analysis tool.  It is meant to be a drop-in replacement for
Devel::DProf.

B<NOTE:> If Devel::DProf works for your application then there is no
reason to use this module.

=head1 RATIONALE

I created this module because I desperately needed a profiler to
optimize a large Apache/mod_perl application.  Devel::DProf, however,
insisted on seg-faulting on every request.  I spent many days trying
to fix Devel::DProf, but eventually I had to admit that I wasn't going
to be able to do it.  Devel::DProf's virtuoso creator, Ilya
Zakharevich, was unable to spend the time to fix it.  Game over.

My next stop brought me to Devel::AutoProfiler by Greg London.  This
module is a pure-Perl profiler.  Reading the code convinced me that it
was possible to write profiler without going the route that led to
Devel::DProf's extremely difficult code.

Devel::AutoProfiler is a good module but I found several problems.
First, Devel::AutoProfiler doesn't output data in the format used by
C<dprofpp>.  I like C<dprofpp> - it has every option I want and the
C<tmon.out> format it supports is well designed.  In contrast,
Devel::AutoProfiler stores its profiling data in memory and then dumps
its data to STDOUT all in one go.  As a result, Devel::AutoProfiler
is, potentially, a heavy user of memory.  Finally, Devel::AutoProfiler
has some (seemingly) arbitrary limitations; for example, it won't
profile subroutines that begins with "__".

Thus, Devel::Profiler was born - an attempt to create a
dprofpp-compatible profiler that avoids Devel::DProf's most
debilitating bugs.

=head1 USAGE

The simplest way to use Devel::Profiler is to add it on the
command-line before a script to profile:

  perl -MDevel::Profiler script.pl

However, if you want to modify the way Devel::Profiler works you'll
need to add a line to your script.  This allows you to specify options
that control Devel::Profiler's behavior.  For example, this sets the
internal buffer size to 1024 bytes.

  use Devel::Profiler buffer_size => 1024;

The available options are listed in the OPTIONS section below.

=head1 OPTIONS

The available options are:

=over 4

=item output_file

This option controls the name of the output file.  By default this is
"tmon.out" and will be placed in the current directory.  If you change
this option then you'll have to specify it on the command-line to
C<dprofpp>.  For example, if you use this line to invoke
Devel::Profiler:

  use Devel::Profiler output_file => "profiler.out";

Then you'll need to invoke C<dprofpp> like this:

  dprofpp profiler.out

=item buffer_size

Devel::Profiler uses an internal buffer to avoid writing to the disk
before and after every subroutine call, which would greatly slow down
your program.  The default buffer_size is 64k which should be large
enough for most uses.  If you set this value to 0 then Devel::Profiler
will write data to disk as soon as it is available.

=item bad_pkgs

Devel::Profiler can skip profiling subroutines in a configurable list
of packages.  The default list is:

  [qw(UNIVERSAL Time::HiRes B Carp Exporter Cwd Config CORE DynaLoader
   XSLoader AutoLoader)]

You can specify your own array-ref of packages to avoid using this
option.  Note that by using this option you're overwriting the list
not adding to it.  As a result you'll generally want to include at
many of the packages listed above in your list.

Devel::Profiler never profiles pragmatic modules which are in all
lower-case.

In addition the DB package is always skipped since trying to
instrument the subroutines in DB will crash Perl.

Finally, Devel::Profiler never profiles pragmatic modules which it
detects by their being entirely lower-case.  Example of pragmatic
modules you've probably heard of are "strict", "warnings", etc.

=item package_filter

This option allows you to handle package selection more flexibly by
allowing you to construct a callback that will be used to control
which packages are profiled.  When the callback returns true the
package will be profiled, false and it will not.  A false return will
also inhibit profiling of child packages, so be sure to allow
'main'!

For example, to never profile packages in the Apache namespace you
would write:

  use Devel::Profiler 
    package_filter => sub { 
                          my $pkg = shift;
                          return 0 if $pkg =~ /^Apache/;
                          return 1;
                      };

The callback is consider after consulting bad_pkgs, so you will still
need to modify bad_pkgs if you intend to profile a default member of
that list.

If you pass an array-ref to package_filter you can specify a list of
filters.  These will be consulted in-order with the first to return 0
causing the package to be discarded, like a short-circuiting "and"
operator.

=item bad_subs

You can specify an array-ref containing a list of subs not to profile.
There are no items in this list by default.  Be sure to specify the
fully-qualified name - i.e. "Time::HiRes::time" not just "time".

=item sub_filter

The sub_filter option allows you to specify one or more callbacks to
be used to decide whether to profile a subroutine or not.  The callbacks
will recieve two parameters - the package name and the subroutine
name.

For example, to avoid wrapping all upper-case subroutines:

  use Devel::Profiler 
    sub_filter => sub { 
                         my ($pkg, $sub) = @_;
                         return 0 if $sub =~ /^[A-Z_]+$/;
                         return 1;
                      };

=item override_caller

By default Devel::Profiler will override Perl's builtin caller().  The
overriden caller() will ignore the frames generated by Devel::Profiler
and keep code that depends on caller() working under the profiler.
Set this option to 0 to inhibit this behavior.  Be aware that this is
likely to break many modules, particularly ones that implement their
own exporting.

=item hz

This variable sets the number of ticks-per-second in the timing
routines.  By default it is set to 1000, which should be good enough
to capture the accuracy of most times() implementations without
spamming the output file with timestamps.  Setting this too low will
reduce the accuracy of your data.  In general you should not need to
change this setting.

=head1 CAVEATS

This profiler has a number of inherent weaknesses that should be
acknowledged.  Here they are:

=over 4

=item *

Devel::Profiler doesn't profile anonymous subroutines.  It works by
walking package symbol tables so it won't notice routines with no
names.  As a result the time spent in anonymous subroutines is
credited to their named callers.  This may change in the future, but
if it does I'll add an option to restrict the profiler to named subs.

=item *

Devel::Profiler won't notice if you compile new subs after execution
begins (after INIT, to be accurate).  This happens when modules use
the Autoloader or Selfloader or include their own mechanisms for
creating subroutines on the fly (usually from AUTOLOAD).  This also
includes modules that are loaded on-demand with require.

=item *

Devel::Profiler uses Perl's C<times()> function and as a result it
won't work on systems that don't have C<times()>.

=item *

Devel::Profiler won't capture time used before execution begins - for
example, in BEGIN blocks.  I think of this as an advantage since I
rarely need to optimize initialization performance, but for frequently
run programs this might unfortunate.

=item *

Overloading causes Devel::Profiler serious indigestion.  You'll have
to exclude overloading packages with bad_pkgs or package_filter until
this changes.

=back

=head1 TODO

My todo list - feel free to send me patches for any of these!

=over 4

=item *

Add code to find and instrument anonymous subs.  Maybe use B::Utils
and B::Generate?  Good grief.

=item *

Allow users to request a re-scan for subs.  This is almost possible by
calling scan() except that scan() is missing code to inhibit
profiling while scanning.

=item *

Override require (and do(FILE) and eval""?) to automatically re-scan
for subs.  (Requires todo above to avoid horking the results.)

=item *

Do research into the differences between Devel::DProf's output and
Devel::Profiler's.  Usually they are quite close but occasionally they
disagree by orders of magnitude.  For example, running
HTML::Template's test suite under Devel::DProf shows output() taking
NO time but Devel::Profiler shows around 10% of the time is in
output().  I don't know which to trust but my gut tells me something
is wrong with Devel::DProf.  HTML::Template::output() is a big routine
that's called for every test.  Either way, something needs fixing.

=item *

Add better support for AUTOLOAD in all its myriad uses.

=item *

Find a way to either ignore or handle overloaded packages.

=back

=head1 BUGS

I know of no bugs aside from the caveats listed above.  If you find
one, please file a bug report at:

  http://rt.cpan.org

Alternately you can email me directly at sam@tregar.com.  Please
include the version of the module and a complete test case that
demonstrates the bug.

=head1 ACKNOWLEDGMENTS

I learned a great deal from the original Perl profiler, Devel::DProf
by Ilya Zakharevich.  It provided the design for the output format as
well as introducing me to many useful techniques.

Devel::AutoProfiler by Greg London proved to me that a pure-Perl
profiler was possible and that it need not rely on the buggy DB
facilities.  Without seeing this module I probably would have given up
on the project entirely.

In addition, the following people have contributed bug reports,
feature suggestions and/or code patches:

  Automated Perl Test Account
  Andreas Marcel Riechert
  Simon Rosenthal
  Jasper Zhao

Thanks!

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002 Sam Tregar

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

=head1 AUTHOR

Sam Tregar <sam@tregar.com>

=head1 SEE ALSO

L<Devel::DProf>, L<Devel::AutoProfiler>

=cut
