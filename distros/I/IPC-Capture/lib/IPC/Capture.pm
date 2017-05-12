package IPC::Capture;
use base qw( Class::Base );

=head1 NAME

IPC::Capture - portably run external apps and capture the output

=head1 SYNOPSIS

   use IPC::Capture;
   my $ich = IPC::Capture->new();
   $ich->set_filter('stdout_only');

   my $output = $ich->run( $this_cmd );
   if ( $output ) ) {
      # work with $output...
   }

   unless( $ich->can_run( $another_cmd ) {
      die "Will not be able to run the external command: $another_cmd\n";
   }

   $ich->set_filter('stderr_only');
   my $errors = $ich->run( $another_cmd );

   # stdout and stderr together:
   $ich->set_filter('all_output');
   my $all = $ich->run( $another_cmd );



=head1 DESCRIPTION

IPC::Capture is a module for running external applications
in a portable fashion when you're primarily interested in capturing
the returned output.

Essentially this is an attempt at creating a portable way of doing
"backticks" with io-redirection.  In fact, if it looks like it will work,
this module will internally just try to run the command via a sub-shell
invoked by qx; otherwise, it will try some other approaches which may work
(going through other modules such as L<IPC::Cmd>, L<IPC::Run>, and/or
L<IPC::Open3>).

The different ways of running external commands are called "ways" here
(because words like "methods" already have too many other associations).
At present, there are only two "ways" defined in this module: "qx" and
"ipc_cmd".  We probe the system trying each of the known ways (in the
order defined in the "ways" attribute), and use the first one that looks
like it will work.

=head2 METHODS

=over

=cut

use 5.008;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Hash::Util qw( lock_keys unlock_keys );
use File::Spec qw( devnull );
use File::Temp qw( tempfile tempdir );
# Note: IPC::Cmd is used below dynamically (if qx fails)
use List::MoreUtils qw( zip );

our $VERSION = '0.06';
my $DEBUG = 0;  # TODO change to 0 before shipping

# needed for accessor generation
our $AUTOLOAD;
my %ATTRIBUTES = ();

=item new

Creates a new IPC::Capture object.

Takes a hashref as an argument, with named fields identical
to the names of the object attributes (which also may be set
later via the accessor methods). These attributes are:

=over

=item filter

The "filter" is a code that specifies what command output
streams we're interested in capturing.  Allowed values:

=over

=item stdout_only

Discards stderr and returns only stdout.  Like the Bourne shell
redirect: '2>/dev/null'

=item stderr_only

Discards stdout and returns only stderr. Like the Bourne shell
redirect: '2>&1 1>/dev/null'

=item all_output

Intermixes lines of stdout and stderr in chronological order.
Like the Bourne shell redirect: '2>&1'

=item all_separated

The return will be an array reference with two elements: stdout and stderr.
(But under some circumstances, it may not be possible to seperate
the two, and all output will be returned intermixed, as the first
item, and the second will be undef.)

=back

=item autochomp

Set to a true value, causes all returned values to be
automatically chomped.  Defaults to false.

=item known_ways

List of known ways of invoking external commands, in the default
order in which they'll be tried (as of this writing: ['ex', 'ipc_cmd'].

=item ways

List of ways of invoking external commands, in the order the user
would like to try them.  Defaults to L</known_ways>.

=item way

The chosen "way" that will be used for invoking external commands.

=item stdout_probe_messages

List of messages which are sent to STDOUT by the probe sub-script.
An array reference.

=item stderr_probe_messages

List of messages which are sent to STDERR by the probe sub-script.
An array reference.

=back

Takes an optional hashref as an argument, with named fields
identical to the names of the object attributes.

=cut

# Note: "new" is inherited from Class::Base and
# calls the following "init" routine automatically.

=item init

Method that initializes object attributes and then locks them
down to prevent accidental creation of new ones.

Any class that inherits from this one should have an B<init> of
it's own that calls this B<init>.  Otherwise, it's an internally
used routine that is not of much interest to client coders.

=cut

sub init {
  my $self = shift;
  my $args = shift;
  unlock_keys( %{ $self } );

  my @attributes = qw(
                       filter

                       autochomp

                       known_ways
                       ways
                       way

                       known_filters

                       stdout_probe_messages
                       stderr_probe_messages

                       success
                      );

  foreach my $field (@attributes) {
    $ATTRIBUTES{ $field } = 1;
    $self->{ $field } = $args->{ $field };
  }

  $self->{ success } = 1; ### TODO stub.

  $self->{ known_ways } = ['qx', 'ipc_cmd'];
  $self->{ ways } ||= $self->{ known_ways };

  $self->{ known_filters } =
    [
     'stdout_only',
     'stderr_only',
     'all_output',
     'all_separated',
    ];

  $self->{ stdout_probe_messages } ||=
    [ 'abc', 'ijk', 'xyz' ];

  $self->{ stderr_probe_messages } ||=
    [ '123', '567', '890' ];

  my $way = $self->probe_system;
  unless( $way ) {
    $self->debug("IPC::Capture probe_system method has not found a way.");
  }
  $self->{ way } = $way || 'qx';  # TODO should there be a fallback default here?

  $self->debugging( 1 ) if $DEBUG;
  $DEBUG = 1 if $self->debugging();

  lock_keys( %{ $self } );
  return $self;
}
# Note: logically, known_ways and known_filters
# could be class data: but I don't think I care.

=item probe_system

Internally used during the init phase of object creation.
Chooses a good "way" of running commands external to perl.

=cut

sub probe_system {
  my $self = shift;
  my $ways = $self->ways;

  ## Here we use File::Temp to write out a small perl script that sends
  ## some known output to stdout and (optionally) to stderr
  my $code = $self->define_yammer_script();

  # creating a temporary perl script file
  # Note: we explicitly use tmpdir, or else it uses curdir which may not be writable(!)
  my $tmpdir = File::Spec->tmpdir();
  $File::Temp::KEEP_ALL = 1 if $DEBUG;  # overrides "UNLINK" & leaves tempfile
  my ($fh1, $scriptname) = tempfile('yap_XXXX',
                                     SUFFIX => '.pl',
                                     DIR    => $tmpdir,
                                     UNLINK => 1     );

  $self->debug( "scriptname: $scriptname\n" );
  print {$fh1} $code;
  close( $fh1 );

  # trying running the script a few different ways
  my $chosen_way;
  foreach my $way (@{ $ways } ) {
    my $method = "probe_system_$way";
    my $retval = $self->$method( $scriptname );
    if ( defined( $retval ) ) {
      $chosen_way = $way;
      last;
    }
  }

  # cleanup
  unlink( $scriptname );

  return $chosen_way;
}


=item define_yammer_script

This is an internally used routine, broken out as a method for
ease of testing.

This generates some code for the 'yammer_script' which is used
used by L</probe_system> to check which ways work for running
external commands.  The 'yammer_script' sends three lines of
output to stdout, and if provided with command-line arguments, it
will echo up to three of them to stderr.  The stderr output is
interleaved with the output sent to stdout, starting with stdout
(so the pattern is: OeOeOe).

This method uses the object data L</stdout_probe_messages> to get
an aref of messages to send to stdout; but this can be overridden
by passing it an aref of alternate messages.

So, just to make it clear: the STDOUT strings are defined when
this method is called, but the STDERR strings are defined only
when the yammer script it generates is run.

=cut

sub define_yammer_script {
  my $self = shift;
  my $messages = shift || $self->stdout_probe_messages;
  my ($x, $y, $z) = @{ $messages };
  my $code =
    '$|=1;' . "\n" .
    'print "' . $x . '\n"; ' . "\n" .
    'print STDERR "$ARGV[0]\n" if defined($ARGV[0]); ' . "\n" .
    'print "' . $y .  '\n"; ' . "\n" .
    'print STDERR  "$ARGV[1]\n" if defined($ARGV[1]); ' . "\n" .
    'print "' . $z . '\n"; ' . "\n" .
    'print STDERR  "$ARGV[2]\n" if defined($ARGV[2]); ' . "\n" ;
  return $code;
}


=item probe_system_qx

Method used internally by the internal method "probe_system".
Takes one argument: the script name, which it will try to run
via qx.

=cut

sub probe_system_qx {
  my $self       = shift;
  my $scriptname = shift;
  my $stderr_probe_messages = shift || $self->stderr_probe_messages;

  my $perl = $^X; # have perl tell us where it is (might not be in path)
  my $stderr_args = join ' ', @{ $stderr_probe_messages };
  my $cmd = "$perl $scriptname $stderr_args";

  my $stdout_probe_messages = $self->stdout_probe_messages;

  my ($capture_stdout, $capture_stderr, $capture_all);
  $capture_stdout = $self->run_qx_stdout_only( $cmd );
  chomp($capture_stdout);
  $capture_stderr = $self->run_qx_stderr_only( $cmd );
  chomp($capture_stderr);
  $capture_all    = $self->run_qx_all_output(  $cmd );
  chomp($capture_all);

  my $expected_stdout = join "\n", @{ $stdout_probe_messages };
  my $expected_stderr = join "\n", @{ $stderr_probe_messages };
  my $expected_all =    join "\n", zip @{ $stdout_probe_messages }, @{ $stderr_probe_messages };

  if ( ( $capture_stdout eq $expected_stdout ) &&
       ( $capture_stderr eq $expected_stderr ) &&
       ( $capture_all    eq $expected_all ) ) {
    return 1;
  } else {
    return;
  }
}


=item probe_system_ipc_cmd

Method used internally by the internal method "probe_system".
Takes one argument: the script name, which it will try to run
via IPC::Cmd.

=cut

sub probe_system_ipc_cmd {
  my $self       = shift;
  my $scriptname = shift;
  my $stderr_probe_messages = shift || [ '123', '567', '890' ];

  my $perl = $^X; # have perl tell us where it is (might not be in path)
  my $stderr_args = join ' ', @{ $stderr_probe_messages };
  my $cmd = "$perl $scriptname $stderr_args";

  my $stdout_probe_messages = $self->stdout_probe_messages;

  my ($capture_stdout, $capture_stderr, $capture_all);
  $capture_stdout = $self->run_ipc_cmd_stdout_only( $cmd );
  chomp($capture_stdout);
  $capture_stderr = $self->run_ipc_cmd_stderr_only( $cmd );
  chomp($capture_stderr);
  $capture_all    = $self->run_ipc_cmd_all_output(  $cmd );
  chomp($capture_all);

  my $expected_stdout = join "\n", @{ $stdout_probe_messages };
  my $expected_stderr = join "\n", @{ $stderr_probe_messages };
  my $expected_all =    join "\n", zip @{ $stdout_probe_messages }, @{ $stderr_probe_messages };

  if ( ( $capture_stdout eq $expected_stdout ) &&
       ( $capture_stderr eq $expected_stderr ) &&
       ( $capture_all    eq $expected_all ) ) {
    return 1;
  } else {
    return;
  }
}

=item can_run

Given the name of an external command, will check to see if we
can run it.

Note: just because the program has the name you're looking for,
there's no guarantee that it's the right program.

=cut

sub can_run {
  my $self = shift;
  my $cmd  = shift;
  my $way  = $self->way;
  my $method = "can_run_$way";
  my $status = $self->$method( $cmd );
  return $status;
}

=item can_run_qx

This is a method used internally by L</can_run>, it tries to
determine if the given program can be run via the shell
(i.e. the "qx" way), and returns the full path to the program
if it's found, otherwise, undef.

=cut

# Trying a few different ways, only one of which need work...
sub can_run_qx {
  my $self     = shift;
  my $program  = shift;
  my $found;

  if( $found = $self->can_run_qx_which( $program ) ) {
    return $found;
  } elsif( $found = $self->can_run_qx_path_glob( $program ) ) {
    return $found;
  }

  return; # undef, nothing found
}


=item can_run_qx_which

This is a method used internally by L</can_run_qx>.
It uses the old old unix utility "which" to look for
the given program.

=cut

sub can_run_qx_which {
  my $self    = shift;
  my $program = shift;
  my $subname = ( caller(0) )[3];

  my $which = 'which';
  my $found;
  eval {
    no warnings;
    $found = qx{ $which $program };
    chomp( $found );
  };
  if ($@) {
    $self->debug("$subname: Running '$which' errored out: $@\n");
    return;
  } elsif ( defined( $found ) && ($found =~ m{ \b $program $ }xms) ) {
    return $found;
  } else {
    return;
  }
}


=item can_run_qx_path_glob

This is a method used internally by L</can_run_qx>.
It looks for the given program by checking looking for
an executible file of that name somewhere in the path.

=cut

sub can_run_qx_path_glob {
  my $self = shift;
  my $program = shift;
  my $found;
  # Just look in each directory in the PATH for an
  # executable file with the right name,
  my @PATH = File::Spec->path();
  foreach my $loc (@PATH) {
    chdir( $loc );
  # This is better for debugging (for obscure reasons):
  #    my @names = glob '*';
  #    foreach my $name (@names) {
  # But this is more memory efficient...
    while ( my $name = glob '*' ) {
      if (( $name eq $program ) && ( -f "$loc/$name" ) && ( -x "$loc/$name" )) {
        $found = File::Spec->catfile($loc, $name);
        return $found;
      }
    }
  }
  return;
}

=item can_run_ipc_cmd

Given the name of a program, checks to see if it can run it.
Returns the full path to the binary if it is found.

Note: this is a simple wrapper around IPC::Cmd::can_run.

=cut

sub can_run_ipc_cmd {
  my $self    = shift;
  my $program = shift;
  require IPC::Cmd;
  my $path = IPC::Cmd::can_run( $program );
  return $path;
}

=item run

Takes one argument: an external command string.

Returns the output from the external command (as controlled by
the L</filter> setting in the object).  The output
will almost always be in the form of a multi-line string,
except in one case:

If filter is set to "all_separated", then this will return a
reference to an array of two elements, the first containing
stdout, the second stderr.

=cut

sub run {
  my $self = shift;
  my $cmd  = shift;
  my $output;
  my $way = $self->way;
  my $od  = $self->filter;
  my $method = 'run_' . $way. '_' . $od ;  # run_<way>_<od>
  $output = $self->$method( $cmd );
  return $output;
}

=back

=head2 "run_<way>_<od>"

These methods are for internal use by the "run" method.

=head2 "run_qx_*" methods

These are methods that take the given command and simply try to
run them via whatever shell is available to the qx{} operator.

The L</filter> setting is converted to equivalent
Bourne shell redirect.

=over

=item run_qx_all_output

=cut

sub run_qx_all_output {
  my $self = shift;
  my $cmd  = shift;
  my $output;
  my $sod = '2>&1';
  $output = qx{$cmd $sod};
  chomp( $output ) if $self->autochomp;
  return $output;
}

=item run_qx_stdout_only

=cut

sub run_qx_stdout_only {
  my $self = shift;
  my $cmd  = shift;
  my $output;
  my $devnull = File::Spec->devnull;
  my $sod = "2>$devnull";
  $output = qx{$cmd $sod};
  chomp( $output ) if $self->autochomp;
  return $output;
}

=item run_qx_stderr_only

=cut

sub run_qx_stderr_only {
  my $self = shift;
  my $cmd  = shift;
  my $output;
  my $devnull = File::Spec->devnull;
  my $sod = "2>&1 1>$devnull";
  $output = qx{$cmd $sod};
  chomp( $output ) if $self->autochomp;
  return $output;
}

=item run_qx_all_separated_old

(An earlier attempt that seemed "more correct"
to me, but doesn't work on MSwin32.)

=cut

# uses redirection to a temp file to get stderr isolated from stdout
sub run_qx_all_separated_old {
  my $self = shift;
  my $cmd  = shift;
  my ($output, $stdout, $stderr);
  my $tmpdir = File::Spec->tmpdir();

  $File::Temp::KEEP_ALL = 1 if $DEBUG;

  my ($fh, $filename) = tempfile('buf_XXXX',
                                 SUFFIX => '.dat',
                                 DIR => $tmpdir,
                                 UNLINK => 1);


  my $sod = "2>$filename";
  $stdout = qx{$cmd $sod};

  while( my $line = <$fh> ) {
    $stderr .= $line;
  }

  $output = [ $stdout, $stderr ];
  $self->chomp_aref( $output ) if $self->autochomp;
  return $output;
}


=item run_qx_all_separated


=cut

# And alternate form of L</run_qx_all_separated> to work
# around an mswin32 issue.

sub run_qx_all_separated {
  my $self = shift;
  my $cmd  = shift;
  my ($output, $stdout, $stderr);
  my $tmpdir = File::Spec->tmpdir();

  # $File::Temp::KEEP_ALL = 1 if $DEBUG;

  my ($fh, $filename) = tempfile('buf_XXXX',
                                 SUFFIX => '.dat',
                                 DIR => $tmpdir,
                                 UNLINK => 0);

  close($fh);

  my $sod = "2>$filename";
  $stdout = qx{$cmd $sod};

  open $fh, '<', $filename or croak "Could not re-open $filename for read: $!";

  while( my $line = <$fh> ) {
    $stderr .= $line;
  }
  close($fh);

  unlink( $filename ) unless $DEBUG;

  $output = [ $stdout, $stderr ];
  $self->chomp_aref( $output ) if $self->autochomp;
  return $output;
}



=back

=head2 "run_ipc_cmd_*" methods

These are methods that take the given command and try to
run them via the L<IPC::Cmd> module, (which in turn will try
to use L<IPC::Run> or L<Run::Open3>).

The L</filter> setting determines what kind of
IPC::Cmd call to use, and which of it's output channels will
be returned.

=over

=item run_ipc_cmd_stdout_only

Used internally by L</run> when the L</filter> is set
to 'stdout_only' (and the L</way> is 'ipc_cmd').

=cut

sub run_ipc_cmd_stdout_only {
  my $self = shift;
  my $cmd  = shift;
  my $output;
  my $all_buf;
  require IPC::Cmd;
  my( $success, $error_code, $all_sep_buf, $stdout_buf, $stderr_buf ) =
    IPC::Cmd::run( command => $cmd, verbose => 0, buffer=> \$all_buf );
  $output = $stdout_buf->[0];

  if( not( $success ) ) {
    warn "IPC::Cmd run of $cmd failed.";
  }
  chomp( $output ) if $self->autochomp;
  return $output;
}


=item run_ipc_cmd_stderr_only

Used internally by L</run> when the L</filter> is set
to 'stderr_only' (and the L</way> is 'ipc_cmd'):

=cut

sub run_ipc_cmd_stderr_only {
  my $self = shift;
  my $cmd  = shift;
  my $output;
  my $all_buf;
  require IPC::Cmd;
  my( $success, $error_code, $all_sep_buf, $stdout_buf, $stderr_buf ) =
    IPC::Cmd::run( command => $cmd, verbose => 0, buffer=> \$all_buf );
  $output = $stderr_buf->[0];

  if( not( $success ) ) {
    warn "IPC::Cmd run of $cmd has failed";
  }
  chomp( $output ) if $self->autochomp;
  return $output;
}


=item run_ipc_cmd_all_output

Used internally by L</run> when the L</filter> is set
to 'all_output' (and the L</way> is 'ipc_cmd'):

=cut

sub run_ipc_cmd_all_output {
  my $self = shift;
  my $cmd  = shift;
  my $output;
  my $all_buf;
  require IPC::Cmd;
  if(  IPC::Cmd::run( command => $cmd, verbose => 0, buffer=> \$all_buf )  ) {
    $output = $all_buf;
  } else {
    warn "IPC::Cmd run of $cmd failed.";
  }
  chomp( $output ) if $self->autochomp;
  return $output;
}

=item run_ipc_cmd_all_separated

Used internally by L</run> when the L</filter> is set
to 'all_separated' (and the L</way> is 'ipc_cmd'):

=cut

sub run_ipc_cmd_all_separated {
  my $self = shift;
  my $cmd  = shift;
  my ($output, $stdout, $stderr);
  my $all_buf;
  require IPC::Cmd;
  my( $success, $error_code, $all_sep_buf, $stdout_buf, $stderr_buf ) =
    IPC::Cmd::run( command => $cmd, verbose => 0, buffer=> \$all_buf );
  $output = $all_sep_buf;

  if( not( $success ) ) {
    warn "IPC::Cmd run of $cmd failed.";
  }

  $self->chomp_aref( $output ) if $self->autochomp;
  return $output;
}

=back

=head1 utility methods

=over

=item chomp_aref

Like "chomp", but presumes it's been given an array reference
of strings to work on.

=cut

sub chomp_aref {
  my $self  = shift;
  my $aref  = shift;

  unless ( ref( $aref ) eq 'ARRAY' ) {
    croak "chomp_aref only works on an array reference";
  }
  foreach ( @{ $aref } ){
    chomp( $_ );
  }
  return $aref;
}




=back

=head2 basic setters and getters

The naming convention in use here is that setters begin with
"set_", but getters have *no* prefix: the most commonly used case
deserves the simplest syntax (and mutators are deprecated).

These accessors exist for all of the object attributes (documented
above) irrespective of whether they're expected to be externally useful.

=head2  automatic generation of accessors

=over

=item AUTOLOAD

=cut

sub AUTOLOAD {
  return if $AUTOLOAD =~ /DESTROY$/;  # skip calls to DESTROY ()

  my ($name) = $AUTOLOAD =~ /([^:]+)$/; # extract method name
  (my $field = $name) =~ s/^set_//;

  # check that this is a valid accessor call
  croak("Unknown method '$AUTOLOAD' called")
    unless defined( $ATTRIBUTES{ $field } );

  { no strict 'refs';

    # create the setter and getter and install them in the symbol table

    if ( $name =~ /^set_/ ) {

      *$name = sub {
        my $self = shift;
        $self->{ $field } = shift;
        return $self->{ $field };
      };

      goto &$name;              # jump to the new method.
    } elsif ( $name =~ /^get_/ ) {
      carp("Apparent attempt at using a getter with unneeded 'get_' prefix.");
    }

    *$name = sub {
      my $self = shift;
      return $self->{ $field };
    };

    goto &$name;                # jump to the new method.
  }
}


1;

=back

=head1 How It Works

Where possible, IPC::Capture will simply work by running the
given command in a sub-shell, invoked with a qx.

During the init phase, it tries to determine if a qx works as
expected (using Bourne-shell style redirects) by the expedient of
writing a temporary perl script that generates a known output,
and then just trying to run the script. (This step will be
skipped if the object is told which style of i/o it should use
when instantiated.)

It appears that qx with i/o re-direction is a relatively portable
idiom these days: it's supported by most forms of perl on
Windows, and I would be surprised if OSX does not support it
also.

If a qx fails, then this system will try another way of doing
the job using the L<IPC::Cmd> module.

If no way of running a simple command and capturing it's output
can be found, an error will be signalled during instantiation.

L<IPC::Cmd> in turn uses L<IPC::Run> or L<IPC::Open3> (depending
on which is installed), which means that this module should have
a fair degree of cross-platform portability.

=head2 further notes

Depending on the type of output requested with the "filter",
this module will choose to do either a scalar or an array context call
to IPC::Cmd::run (insulating the user from one of IPC::Cmd's
oddities).

=head1 MOTIVATION

The original goal was to find something more portable than
shelling out via qx with Bourne shell redirection.

I'd just written the L<Emacs::Run> module that shells out to
emacs, and I was looking for improvements.  (Note: emacs is
a widely available program, with portability roughly on the
same scale as perl.)

The L<IPC::Cmd> module looked like a promising simplification
over directly using L<IPC::Run> or L<IPC::Open3>, but it's
output capture features seemed clumsy.

So: my first thought was to write a wrapper around the wrapper,
and as an added bonus, it would fall back on doing a simple qx
if L<IPC::Cmd> wasn't going to work.

My initial tests of that code immediately revealed a problem
with L<IPC::Cmd>: it usually worked as expected, but sometimes
would behave strangely (e.g. returning only one line of output
instead of the expected six; or instead of interleaving stderr
with stdout, it might return all stderr lines first).
My suspicion was that this was due to running on a perl with
threads enabled, but in any case, it didn't inspire confidence
with the idea that L<IPC::Cmd> was going to be more reliable than qx.

At which point, it occured to me that I could rewrite the
module to work the other way around: just use qx, but fall
back on L<IPC::Cmd>.  And indeed, it wasn't that difficult to
write probe routines to find out if qx works reliably.

All of this work seemed a little besides the point when I realized
that nearly every Windows installation of perl can deal with Bourne
shell redirects -- but still this module may very well improve
portability to some of the more unusual platforms such as VMS or
the older Macs.

And at the very least, if I use this module religiously, I can
stop worrying about mistyping '2>&1'.


=head1 TODO

o  More filters -- "output_to_file", etc.
   Add a general purpose, user-defineable one?

o  IPC::Cmd seems to have reliability problems (possibly, with
   multi-threaded perls?), the precise output it returns can vary
   from run to run.  Possibly: implement a voting algorithm, return
   the output most commonly recieved.

o  Better test coverage:  autochomp;  probe_system*;

o  02-can_run.t tests multiple internal routines, only one flavor of
   which need work for the overall behavior to work.  Possibly should
   ship only with tests that verify the interface methods...

o  IPC::Capture lacks "success", as of 0.05.  This means the SYNOPSIS
   is complete nonsense for versions 0.04 and earlier. For now,
   not mentioning "success", but think about implementing it.

=head1 SEE ALSO

L<IPC::Cmd>
L<IPC::Run>
L<IPC::Open3>

Shell redirection apparently works on Windows:
http://www.perlmonks.org/?node_id=679842


=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>,
07 Apr 2008

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS AND LIMITATIONS

There are possible security gotchas with using this module,
because it hands strings off to the shell to execute.  Any
commands built-up from user input should be scrubbed carefully
before being run with this module.  Using taint is strongly
recommended: see L<perlsec>.

=cut
