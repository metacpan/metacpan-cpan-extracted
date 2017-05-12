# -* - perl -*-

package Devel::Trace::Fork;
use Devel::Trace;
use Time::HiRes qw(gettimeofday);
use Fcntl ':flock';
use Carp;
use strict qw(vars subs);
use warnings;
our $VERSION = '0.11';
our ($FH, $FILE, $FH_LOCK, @O);
our $_PID2 = $$;
our $_PID = $$;
our $FLUSH = $ENV{DT_FORK_FLUSH} || 16_384;
our $SORT_NEEDED = 0;
our %IGNORE_PACKAGES = ('Devel::Trace::Fork' => 1);
$| = 1;

BEGIN {
  local $! = undef;
  $FILE = $ENV{DTRACE_FILE} || "./DTFork.$$";
  if (open $FH, '>', $FILE) {
    print $FH q{>  },$^X,q{ },$0,q{ },@ARGV,"\n";
    print $FH q{> },$^T,q{ },scalar gettimeofday(),"\n";
    close $FH;
    open ($FH_LOCK, '>>', "$FILE.x"); 
    print $FH_LOCK "$^T $$ <>\n"; 
    close $FH_LOCK;
  } else {
    croak "Devel::Trace::Fork: Failed to open trace output file $FILE: $!\n",
      "Use environment variable DTRACE_FILE to set an explicit trace output ",
      "file name.\n";
  }
}

no warnings 'redefine';
sub DB::DB {
  return unless $Devel::Trace::TRACE;
  my ($p, $f, $l) = caller;
  my $t;
  if ($_PID2 != $$) { 
    $t = sprintf '%11.6f', gettimeofday()-$^T;
    @O = (">> $t:$$: ----------------- NEW PROCESS -----------------\n");
    $_PID2 = $$;
    
    # In MSWin32, children do not call the END{} block?
    # Then we need to flush every line :-(
    # Also, we won't get the -- END OF PROCESS -- indicator at the end :-(
    flush();
    $FLUSH = 0 if $^O eq "MSWin32";
  }
  if (!defined $IGNORE_PACKAGES{$p}) {
    $t ||= sprintf '%11.6f', gettimeofday()-$^T;

    my $code = \@{"::_<$f"};
    my $cde = $code->[$l] || "--- code not available ---\n";
    if (!defined $f) {
      print STDERR "$0 \$f not defined, $p, $f, $l\n";
    }
    if (!defined $l) {
      print STDERR "$0 \$l not defined $p, $f, $l\n";
    }
    if (!defined $code) {
      print STDERR "$0 \$code not defined $p, $f, $l\n";
    } elsif (!defined $cde) {
      print STDERR "$0 \$cde, \$code->[\$l] not defined $p, $f, $l\n";
    }


    push @O, ">> $t:$$:$?:$f:$l: $cde";
    if (@O > $FLUSH) {
      flush();
    }
  }
  return;
}

sub flush {
  if ($$ != $_PID && ! -f "$FILE.x") {
    Carp::cluck "Devel::Trace::Fork: ",
	"possibly appending trace data from $$ ",
	"after main process $_PID exited.\n";
    $SORT_NEEDED = 1;
  }
  unless (open $FH_LOCK, '>>', "$FILE.x" and flock $FH_LOCK, LOCK_EX) {
    carp 'Devel::Trace::Fork: ',
      "failed to lock output file $FILE before flush: $! $FH_LOCK\n";
  }
  print $FH_LOCK "$$ ", scalar gettimeofday(), "\n";

  if (open($FH, '>>', $FILE)) {
    print $FH @O;
    close $FH;
    close $FH_LOCK;
  } else {
    carp 'Devel::Trace::Fork: failed to flush ',
      scalar @O, " lines of output from pid=$$!\n";
  }

  @O = ();
  return;
}

END {
  $Devel::Trace::TRACE = 0;
  # *DB::DB = sub { print STDERR "DB::DB end called $$\n"; };

  my $t = sprintf '%11.6f', gettimeofday()-$^T;
  push @O, ">> $t:$$: -------------- END OF PROCESS ------------------\n";
  flush();

  if ($$ == $_PID || $SORT_NEEDED) {
    if ($$ == $_PID && $ENV{DTFORK_ERASE_ON_GOOD_EXIT} && $? == 0) {
      print STDERR "Good exit on $_PID. Erasing $FILE\n";
      unlink "$FILE.x";
      unlink $FILE if $ENV{DTFORK_ERASE_ON_GOOD_EXIT} > 0;
      undef $FILE;
      $? = 0;
      return;
    }
    if (open($FH_LOCK, '>>', "$FILE.x")) {
      print $FH_LOCK "$$ ", scalar gettimeofday(), "\n";
      flock $FH_LOCK, LOCK_EX;
    }

    if (open($FH, '<', $FILE)) {
      my @P = <$FH>;
      close $FH;

      @P = sort @P;

      if (open($FH, '>', $FILE)) {
	print $FH @P;
	close $FH;
      } else {
	carp 'Devel::Trace::Fork: failed to rewrite sorted output';
      }
    } else {
      carp 'Devel::Trace::Fork: failed to read final output';
    }

    close $FH_LOCK;
    unlink "$FILE.x";

    print STDERR "Devel::Trace::Fork output in <$FILE>\n";
  }
}

1;

__END__

=head1 NAME

Devel::Trace::Fork - Devel::Trace-like output for multi-process programs

=head1 VERSION

0.11

=head1 SYNOPSIS

    perl -d:Trace::Fork program

=head1 DESCRIPTION

Like Mark Jason Dominus's L<Devel::Trace> module, 
but debugging output includes additional information like

=over 4

=item *

a high-resolution timestamp for the time each statement
was executed

=item *

the process id of the process that executes each statement

=item * 

the current value of the L<$CHILD_ERROR|perlvar/"$CHILD_ERROR">
variable (C<$?>)

=back

This additional information
can be helpful for debugging programs that make use of the
L<< fork|perlfunc/fork >> system call to run. For example,
the C<Trace::Fork> output of this program:

    if (fork() == 0) {
        print "This is the child.\n";
        exit 0;
    }
    print "This is the parent.\n";

will be a file that looks something like:

    /usr/bin/perl test
    1268025451 1268025451.815
    >>    0.816214:7996:0:test:1: if (fork() == 0) {
    >>    0.826566:7996:0:test:5: print "This is the parent.\n";
    >>    0.826684:9572:0:test:2:     print "This is the child.\n";
    >>    0.826941:9572:0:test:3:     exit 0;

=head1 DETAILS

Debug output is not to C<STDERR>, but to a file that is either
specified by C<$ENV{DTRACE_FILE}> or set to the file name
C<"DTFork.$$"> in the current directory (where C<$$> is the
process identifier of the parent process). To output debugging
output to C<STDERR> the way L<Devel::Trace> does, see
L<Devel::Trace::Fork::Stderr>.

See L<Devel::Trace>. Use the C<$Devel::Trace::TRACE> variable
or the C<Devel::Trace::trace> function exactly the way you
would use them with the pure C<Devel::Trace> module. To import
the C<Devel::Trace::trace> function into your program's
namespace, include the line:

    use Devel::Trace 'trace';

somewhere in your program.

=head1 SUBROUTINES/METHODS

None

=head1 DIAGNOSTICS

=over 4

=item C<Devel::Trace::Fork: failed to ...>

An I/O error occurred with the trace output file. Check
that you have permission to create or overwrite the file
specified by the C<DTRACE_FILE> environment variable,
or if C<DTRACE_FILE> is not specified, that you can create
files in the current directory.

=back

=head1 CONFIGURATION AND ENVIRONMENT

=over 4

=item C<$ENV{DTRACE_FILE}>

Name of trace output file. If not specified, uses the filename
C<"DTFork.$$"> in the current directory.

=item C<$ENV{DTFORK_ERASE_ON_GOOD_EXIT}>

If this variable is non-zero, and the program is successful
(that is, it is exiting with status 0), then the output trace
file will be removed. This setting is helpful if you are
trying to replicate an intermittent program failure and don't
want your directory littered with the trace files of 
successful runs.

=back

=head1 DEPENDENCIES

    Devel::Trace

=head1 BUGS AND LIMITATIONS

If there are child processes that exit later than the
parent process, then the final output will not be sorted.

There is almost enough information in the trace output
to use it for profiling. Almost.

=head1 SEE ALSO

L<Devel::Trace>, L<Devel::Trace::More>

=head1 AUTHOR

Marty O'Brien, E<lt>mob@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Marty O'Brien

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
