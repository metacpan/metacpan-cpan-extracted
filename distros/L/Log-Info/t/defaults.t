# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Log::Info defaults

This package tests the defaults of Log::Info

=cut

use FindBin  qw( $Bin );
use POSIX    qw( tmpnam );
use Test     qw( ok plan );

use lib  "$Bin/../lib";

# Channel names for playing with
use constant TESTCHAN1 => 'testchan1';
use constant TESTCHAN2 => 'testchan2';

# Test message for playing with
use constant MESSAGE1  => '--TEST--';

BEGIN {
  plan tests  => 5;
       todo   => [],
       ;
}

# ----------------------------------------------------------------------------

# grab_output()
#
# Eval some code and return what was printed to stdout and stderr.
#
# Parameters: string of code to eval
#
# Returns: listref of [ stdout text, stderr text ]
#
sub grab_output {
  die 'usage: grab_output(string to eval)' if @_ != 1;
  my $code = shift;
  my $tmp_o = POSIX::tmpnam(); my $tmp_e = POSIX::tmpnam();
  local (*OLDOUT, *OLDERR);

  # Try to get a message to the outside world if we die
  local $SIG{__DIE__} = sub { print $_[0]; die $_[0] };

  open(OLDOUT, ">&STDOUT") or die "can't dup stdout: $!";
  open(OLDERR, ">&STDERR") or die "can't dup stderr: $!";
  open(STDOUT, ">$tmp_o")  or die "can't open stdout to $tmp_o: $!";
  open(STDERR, ">$tmp_e")  or die "can't open stderr to $tmp_e: $!";
  eval $code;
  # Doubtful whether most of these messages will ever be seen!
  close(STDOUT)            or die "cannot close stdout opened to $tmp_o: $!";
  close(STDERR)            or die "cannot close stderr opened to $tmp_e: $!";
  open(STDOUT, ">&OLDOUT") or die "can't dup stdout back again: $!";
  open(STDERR, ">&OLDERR") or die "can't dup stderr back again: $!";

  die $@ if $@;

  local $/ = undef;
  open (TMP_O, $tmp_o) or die "cannot open $tmp_o: $!";
  open (TMP_E, $tmp_e) or die "cannot open $tmp_e: $!";
  my $o = <TMP_O>; my $e = <TMP_E>;
  close TMP_O   or die "cannot close filehandle opened to $tmp_o: $!";
  close TMP_E   or die "cannot close filehandle opened to $tmp_e: $!";
  unlink $tmp_o or die "cannot unlink $tmp_o: $!";
  unlink $tmp_e or die "cannot unlink $tmp_e: $!";

  return $o, $e;
}

# ----------------------------------------------------------------------------

use Log::Info qw( :DEFAULT :log_levels :default_channels );

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

Log::Info is imported as

  use Log::Info qw( :DEFAULT :log_levels :default_channels );

This tests bug #001

=cut

ok 1, 1, 'compilation';

=head2 Test 2: setting the out level

This test sets the output level on SINK_STDERR of CHAN_INFO to LOG_INFO.
The test is that no exception is thrown.

=cut

{
  my $ok = 0;
  eval {
    Log::Info::set_channel_out_level(CHAN_INFO, LOG_INFO);
    Log::Info::set_sink_out_level(CHAN_INFO, SINK_STDERR, LOG_INFO);
    $ok = 1;
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
    $ok = 0;
  }

  ok $ok, 1, 'setting the out level';
}

=head2 Test 3: Writing to CHAN_INFO

This test writes a message to CHAN_INFO, capturing the output.
The test is that no exception is thrown.

=cut

{
  my $ok = 0;
  my ($out, $err);
  eval {
    ($out, $err) = grab_output('Log(CHAN_INFO, LOG_INFO, MESSAGE1)');
    $ok = 1;
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
    $ok = 0;
  }

  ok $ok, 1, 'Writing to CHAN_INFO';

=head2 Test 4: Checking the message

This test is that the message written by the previous test is indeed output
(to stderr) (with a terminating newline).

=cut

  ok $err, MESSAGE1 . "\n", 'Checking the message';

=head2 Test 5: Checking stdout

This test is that nothing was written by the previous test to stdout.

=cut

  ok $out, '', 'Checking stdout';
}
