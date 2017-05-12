# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Log::Info functions

This package tests the use of trapping warn()/die() in Log::Info.

=cut

use Carp            qw( carp croak );
use FindBin    1.42 qw( $Bin );
use Test       1.13 qw( ok plan );
use File::Spec::Functions qw( rel2abs );

use constant PERL => rel2abs $^X;

BEGIN { unshift @INC, $Bin };

BEGIN {
  # Timing issues in non-ipc run often screw this up.
  eval "use IPC::Run 0.44 qw( );";
  if ( $@ ) {
    print STDERR "DEBUG: $@\n"
      if $ENV{TEST_DEBUG};
    print "1..0 # Skip: IPC::Run not found (or too old).\n";
    exit 0;
  }
}

use test      qw( LIB_DIR evcheck save_output restore_output );
use test2     qw( runcheck );

# Sink names for playing with
use constant SINK1 => 'sink1';

# Message texts for playing with
use constant MESSAGE1 => 'Mrs. Cobbit';
use constant MESSAGE2 => 'Philby';
use constant MESSAGE3 => 'Chippy Minton';
use constant MESSAGE4 => 'Raggy Dan';

BEGIN {
  plan tests  => 25;
       todo   => [],
       ;
}

# ----------------------------------------------------------------------------

use Log::Info qw( :trap :default_channels Log );

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

ok 1, 1, 'compilation';

# -------------------------------------

=head2 Test 2: adding a sink

This test deletes the C<SINK_STDERR> sink, and adds a sink (C<SINK1), to
C<CHAN_INFO>.  The test is that no exception is thrown.

=cut

my @mess;

ok evcheck(sub {
             Log::Info::delete_sink(CHAN_INFO, SINK_STDERR);
             Log::Info::add_sink (CHAN_INFO, SINK1, 'SUBR', undef,
                                  { subr => sub { push @mess, $_[0] }});
           }, 'adding a sink'), 1, 'adding a sink';

# -------------------------------------

=head2 Test 3: logging some messages

This test writes two log messages to the channel with the sink.  The test is
that no exception is thrown.

This also tests that the explicit import of C<Log> works.  The second message
is logged at level 10, equal to the channel level.  This is expected to get
logged.

=cut

ok evcheck(sub {
             Log (CHAN_INFO, 3, MESSAGE1);
             Log (CHAN_INFO, 5, MESSAGE2);
           }, 'logging a message'), 1, 'logging a message';

# -------------------------------------

=head2 Tests 4--5: checking the messages

These tests check that the expected messages have been passed to the log
subroutine.

=cut

ok shift @mess, MESSAGE1, 'checking the messages (1)';
ok shift @mess, MESSAGE2, 'checking the messages (2)';

# -------------------------------------

=head2 Tests 6--9: checking that warn is now logged

This test invokes warn, and checks (1) that no exception is thrown, (2) that
exactly one message has been logged to CHAN_INFO, (3) the the message is
MESSAGE2, and (4) that the message is not written to stderr as usual.

=cut

{
  my $stderr;
  ok(evcheck(sub {
               save_output('stderr', *STDERR{IO});
               warn MESSAGE2 . "\n";
               $stderr = restore_output('stderr');
             }, 'checking that warn is now logged (1)'),
     1, 'checking that warn is now logged (1)');

  ok scalar(@mess), 1, 'checking that warn is now logged (2)';
  ok $mess[0], MESSAGE2 . "\n", 'checking that warn is now logged (3)';
  ok $stderr, '', 'checking that warn is now logged (4)';
  @mess = ();
}

# -------------------------------------

=head2 Tests 10--13: checking that die is now trapped

This test invokes C<die> (within an C<eval>), and checks (1) that an exception
is thrown, (2) that exactly one message has been logged to CHAN_INFO, (3) the
the message is MESSAGE1, and (4) that the message is trapped in C<$@> as
usual.

This is to check that nothing is messing with die by default.

=cut

# Can't use evcheck here, as that traps the die!
{
  my $ok = 0;
  eval {
    die MESSAGE1, "\n";
  }; if ($@) {
    $ok = 1;
  }
  ok $ok, 1, 'checking that die is now trapped (1)';
}
ok scalar(@mess), 1, 'checking that die is now trapped (2)';
ok $mess[0], MESSAGE1 . "\n", 'checking that die is now trapped (3)';
ok $@, MESSAGE1 . "\n", 'checking that die is now trapped (4)';
@mess = ();

# -------------------------------------

=head2 Tests 14--17: checking that croak messages are now trapped

This test invokes C<Carp::croak> (within an C<eval>), and checks (1) that an
exception is thrown, (2) that exactly one message has been logged to
CHAN_INFO, (3) the the message begins with MESSAGE1, and (4) that the message
is trapped in C<$@> as usual.

This is to check that nothing is messing with die by default.

=cut

# Can't use evcheck here, as that traps the die!
{
  my $ok = 0;
  eval {
    croak MESSAGE1, "\n";
  }; if ($@) {
    $ok = 1;
  }
  ok $ok, 1, 'checking that croak is now trapped (1)';
}

ok scalar(@mess), 1, 'checking that croak is now trapped (2)';
ok $mess[0], qr/^${\ MESSAGE1() }/, 'checking that croak is now trapped (3)';
ok $@, qr/^${\ MESSAGE1() }/, 'checking that croak is now trapped (4)';
@mess = ();

# -------------------------------------

=head2 Tests 18--21: checking that carp is now logged

This test invokes C<Carp::carp>, and checks (1) that no exception is thrown,
(2) that exactly one message has been logged to CHAN_INFO, (3) the the message
begins with MESSAGE2, and (4) that the message is not written to stderr as
usual.

=cut

{
  my $stderr;
  ok(evcheck(sub {
               save_output('stderr', *STDERR{IO});
               carp MESSAGE2 . "\n";
               $stderr = restore_output('stderr');
             }, 'checking that warn is now logged (1)'),
     1, 'checking that warn is now logged (1)');

  ok scalar(@mess), 1, 'checking that warn is now logged (2)';
  ok $mess[0], qr/^${\ MESSAGE2() }/, 'checking that warn is now logged (3)';
  ok $stderr, '', 'checking that warn is now logged (4)';
  @mess = ();
}

# -------------------------------------

=head2 Tests 22-23: exit test (die)

Run

  perl -I lib -MLog::Info=:trap -e '$!=4;die"Hello"'

( 1) Check exit status is 4
( 2) Check stderr reads Hello (twice, on per line)

=cut

{
  my $err = '';
  ok(runcheck([[PERL,
                -I => LIB_DIR,
                '-MLog::Info=:trap',
                -e => '$!=4;die"Hello"'],
               '2>', \$err],
              'exit test (die)', \$err, 4), 1,         'exit test (die) ( 1)');
  ok $err, "Hello at -e line 1\n",                      'exit test (die) ( 2)';
}

# -------------------------------------

=head2 Tests 24-25: exit test (croak)

Run

  perl -I lib -MCarp -MLog::Info=:trap -e '$!=77;carp"Hello"'

( 1) Check exit status is 4
( 2) Check stderr reads Hello (twice, on per line)

=cut

{
  my $err = '';
  ok(runcheck([[PERL,
                -I => LIB_DIR,
                '-MCarp', '-MLog::Info=:trap',
                -e => '$!=77;croak"Hello"'],
               '2>', \$err],
              'exit test (croak)', \$err, 77), 1,    'exit test (croak) ( 1)');
  ok $err,"Hello at -e line 1\n",                     'exit test (croak) ( 2)';
}

# ----------------------------------------------------------------------------
