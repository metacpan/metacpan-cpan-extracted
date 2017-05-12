# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for log-input

=cut

use Carp                        qw( carp croak );
use Fatal                  1.02 qw( close open unlink );
use File::Spec::Functions       qw( catfile );
use File::Temp             0.12 qw( tmpnam );
use FindBin                1.42 qw( $Bin );
use Test                   1.13 qw( ok plan );

BEGIN { unshift @INC, $Bin };

use test      qw( DATA_DIR
                  evcheck save_output restore_output );
use test2     qw( runcheck );

# Test files
use constant TESTFILE1 => 'testfile1';

my $STAMP_RE = 
  qr/(\d+) (\w{3}) (\w{3}) ([ \d]\d) (\d{2}):(\d{2}):(\d{2}) (\d{4}) (\w+)/;

BEGIN {
  plan tests  => 10;
       todo   => [],
       ;
}

# ----------------------------------------------------------------------------

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

ok 1, 1, 'compilation';

# ----------------------------------------------------------------------------

=head2 Tests 2--6: simple log-input run

This test runs log-input wrapping C<cat testfile1>.

(1) Test log-input ran without error
(2) Test that the line messages are all as expected from cat
(3) Test that the times stated are all as expected (during the period of
    invocation).
(4) Test that the lines are formatted correctly.
(5) Test that the output is all via stdout.

=cut

{
  my $tmpfn = tmpnam;
  my $testfile1 = catfile DATA_DIR, TESTFILE1;

  open my $testfh, '<', $testfile1;
  chomp (my @testlines = <$testfh>);
  close $testfh;

  my $start = time;
  ok runcheck([[':log-input', $tmpfn, 'cat', $testfile1], ]),
    1, 'simple log-input run (1)';
  my $end = time;

  open my $tmpfh, '<', $tmpfn;
  chomp (my @tmplines = <$tmpfh>);
  close $tmpfh;

  my %testlines = map { $_ => 1 } @testlines;
  my ($time_ok, $date_ok, $output_ok, $format_ok) = (1) x 4;

  for (my $i = 0; $i < @tmplines; $i++) {
    $_ = $tmplines[$i];
    if ( /^\[([^\]]+)\]\s*(.*?)$/ ) {
      my ($stamp, $message) = ($1, $2);
      if ( exists $testlines{$message} ) {
        delete $testlines{$message};
      } else {
        warn "Where did this message come from? (line $i): $_\n"
          if $ENV{TEST_DEBUG};
      }

      if ( $stamp =~ /^$STAMP_RE$/x ) {
        my ($time, $output) = ($1, $9);
        if ( $time < $start or $time > $end ) {
          $time_ok = 0;
          warn "Time $time out of bounds on output line $i: $_\n"
            if $ENV{TEST_DEBUG};
        }
        if ( $output ne 'out' ) {
          $output_ok = 0;
          warn "Wrong output on line $i: $_\n"
            if $ENV{TEST_DEBUG};
        }
      } else {
        $format_ok = 0;
        warn "Bad format on output line $i: '$_'\n"
          if $ENV{TEST_DEBUG};
      }
    }
  }

  ok scalar keys %testlines, 0, 'simple log-input run (2)';
  ok $time_ok, 1, 'simple log-input run (3)';
  ok $format_ok, 1, 'simple log-input run (4)';
  ok $output_ok, 1, 'simple log-input run (5)';

  if ( $ENV{TEST_DEBUG} ) {
    print STDERR "Used tempfile $tmpfn\n";
  } else {
    unlink $tmpfn;
  }
}

# ----------------------------------------------------------------------------

=head2 Test 7--10: log-input with redirect

This test runs log-input wrapping C<< cat testfile1 1>&2 >>.

(1) Test log-input ran without error
(2) Test that the line messages are all as expected from cat
(3) Test that the lines are well-formed.
(4) Test that the output is all via stderr.

=cut

{
  my $tmpfn = tmpnam;
  my $testfile1 = catfile DATA_DIR, TESTFILE1;

  open my $testfh, '<', $testfile1;
  chomp (my @testlines = <$testfh>);
  close $testfh;

  ok runcheck([[':log-input', $tmpfn, 'cat', $testfile1, '1>&2'], ]),
    1, 'log-input with redirect (1)';

  open my $tmpfh, '<', $tmpfn;
  chomp (my @tmplines = <$tmpfh>);
  close $tmpfh;

  my %testlines = map { $_ => 1 } @testlines;
  my ($format_ok, $output_ok) = (1) x 2;

  for (my $i = 0; $i < @tmplines; $i++) {
    $_ = $tmplines[$i];
    if ( /^\[([^\]]+)\]\s*(.*?)$/ ) {
      my ($stamp, $message) = ($1, $2);
      if ( exists $testlines{$message} ) {
        delete $testlines{$message};
      } else {
        warn "Where did this message come from? (line $i): $_\n"
          if $ENV{TEST_DEBUG};
      }

      if ( $stamp =~ /^$STAMP_RE$/x ) {
        my ($output) = ($9);
        if ( $output ne 'err' ) {
          $output_ok = 0;
          warn "Wrong output on line $i: $_\n"
            if $ENV{TEST_DEBUG};
        }
      } else {
        $format_ok = 0;
        warn "Bad format on output line $i: $_\n"
          if $ENV{TEST_DEBUG};
      }
    }
  }

  ok scalar keys %testlines, 0, 'log-input with redirect (2)';
  ok $format_ok, 1, 'log-input with redirect (3)';
  ok $output_ok, 1, 'log-input with redirect (4)';

  if ( $ENV{TEST_DEBUG} ) {
    print STDERR "Used tempfile $tmpfn\n";
  } else {
    unlink $tmpfn;
  }
}

# ----------------------------------------------------------------------------

# Check action under HUP
# Check file rotation
# Check action under SIGCONT
# Check action under SIGTERM
# Check maxsize option is respected

# LOG SIGNALS
# PASS THROUGH SIGNALS
#  - TERM,QUIT,INT, HUP?
#  Switchoffable
# MUTE SOME SIGNALS
# IGNORE HUP
#   CHECK CHILD DOES, TOO!

# HANDLE SIGCONT FOR LOG_INPUT
# HANDLE SIGTERM FOR LOG_INPUT

