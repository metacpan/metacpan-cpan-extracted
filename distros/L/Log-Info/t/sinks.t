# (X)Emacs mode: -*- cperl -*-

use strict;
use warnings;

=head1 Unit Test Package for Log::Info functions

This package tests the use of sinks in Log::Info

=cut

use Data::Dumper          qw( Dumper );
use FindBin          1.42 qw( $Bin );
use Test::More            tests  => 21,
                          import => [qw( diag is ok )];

BEGIN { unshift @INC, $Bin };

use test      qw( evcheck );
use test2     qw( -no-ipc-run runcheck );


# Channel names for playing with
use constant TESTCHAN1 => 'testchan1';
use constant TESTCHAN2 => 'testchan2';

# Sink names for playing with
use constant SINK1 => 'sink1';
use constant SINK2 => 'sink2';

# Message texts for playing with
use constant MESSAGE1 => 'Windy Miller';
use constant MESSAGE2 => 'Mrs. Murphy';

$Data::Dumper::Maxdepth = 3;
$Data::Dumper::Indent = 0;
$Data::Dumper::Terse = 1;

# ----------------------------------------------------------------------------

use Log::Info qw( Log );

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

is 1, 1, 'compilation';

=head2 Test 2: adding a channel

This test adds a channel.  The test is that this occurs without error.

=cut

is evcheck(sub { Log::Info::add_channel (TESTCHAN1); },
           'adding a channel'), 1, 'adding a channel';

=head2 Test 3: adding a sink

This test adds a sink.  The test is that no exception is thrown.

=cut

my @mess;

is evcheck(sub {
             Log::Info::add_sink (TESTCHAN1, SINK1, 'SUBR', undef,
                                  { subr => sub { push @mess, $_[0] }});
           }, 'adding a sink'), 1, 'adding a sink';

=head2 Test 4: logging some messages

This test writes two log messages to the channel with the sink.  The test is
that no exception is thrown.

This also tests that the explicit import of C<Log> works.  The second message
is logged at level 10, equal to the channel level.  This is expected to get
logged.

=cut

is evcheck(sub {
             Log (TESTCHAN1, 3, MESSAGE1);
             Log (TESTCHAN1, 5, MESSAGE2);
           }, 'logging a message'), 1, 'logging a message';

=head2 Tests 5--6: checking the messages

These tests check that the expected messages have been passed to the log
subroutine.

=cut

is shift @mess, MESSAGE1, 'checking the messages (1)';
is shift @mess, MESSAGE2, 'checking the messages (2)';

=head2 Test 7: resetting the channel level

This test sets the channel level to 8.  The test is that no exception is
thrown.

=cut

is evcheck(sub {
             Log::Info::set_channel_out_level (TESTCHAN1, 8);
           }, 'resetting the channel level'), 1, 'resetting the channel level';

=head2 Tests 8--9: logging above level

This test writes a log messages to channel with the sink at log level 10.  The
first test is that no exception is thrown, the second is that no message is
logged.

This also tests that the previous setting to level 8 worked.

=cut

is evcheck(sub {
             Log (TESTCHAN1, 10, MESSAGE1);
           }, 'logging above level (1)'), 1, 'logging above level (1)';

is scalar(@mess), 0, 'logging above level (2)'
  or print "# MESS> $_\n" for @mess;
@mess = ();

=head2 Test 10: resetting the sink level

This test increases the sink output level to 3.  The test is that no exception
is thrown.

=cut

is evcheck(sub {
             Log::Info::set_sink_out_level (TESTCHAN1, SINK1, 3);
           }, 'resetting the sink level'), 1, 'resetting the sink level';

=head2 Tests 11--12: logging between levels

This test writes a log messages to channel with the sink at log level 5.  The
first test is that no exception is thrown, the second is that no message is
logged.

This also tests that the previous setting of the sink level to 8 worked.

=cut

is evcheck(sub {
    Log (TESTCHAN1, 5, MESSAGE1);
  }, 'logging between levels (1)'), 1, 'logging between levels (1)';

is scalar(@mess), 0, 'logging between levels (2)';
@mess = ();

=head2 Test 13--14: logging below all levels

This test writes a log messages to channel with the sink at log level 2.  The
first test is that no exception is thrown, the second is that the message is
logged.

=cut

is(evcheck(sub {
             Log (TESTCHAN1, 2, MESSAGE1);
           }, 'logging below all levels (1)'),
   1, 'logging below all levels (1)');

is((( @mess == 1 ) && ( $mess[0] eq MESSAGE1 )),
   1, 'logging below all levels (2)');
@mess = ();

=head2 Test 15: resetting the channel level to undef

This test sets the channel output level to undef.  The test is that no
exception is thrown.

=cut

is(evcheck(sub {
             Log::Info::set_channel_out_level(TESTCHAN1, undef);
           }, 'resetting the channel level to undef'),
   1, 'resetting the channel level to undef');

=head2 Test 16: resetting the sink level to undef

This test sets the sink output level to undef.  The test is that no exception
is thrown.

=cut

is(evcheck(sub {
             Log::Info::set_sink_out_level(TESTCHAN1, SINK1, undef);
           }, 'resetting the sink level to undef'),
   1, 'resetting the sink level to undef');

=head2 Test 17--18: logging a message with channel, sink levels set to undef

This test writes a log messages to channel with the sink at log level 50.  The
first test is that no exception is thrown, the second is that the message is
logged.

=cut

is(evcheck(sub {
             Log (TESTCHAN1, 50, MESSAGE2);
           }, 'logging a message with channel, sink levels set to undef (1)'),
   1, 'logging a message with channel, sink levels set to undef (1)');

is 0+@mess, 1,
   'logging a message with channel, sink levels set to undef (2)';
is $mess[0], MESSAGE2,
   'logging a message with channel, sink levels set to undef (3)';

@mess = ();

=head2 Test 19--20: logging a message at channel -> undef, sink -> 10

This test sets the sink output level to 10.  A message is logged at level 5,
then level 15.  The first test is that no exception is thrown, the second is
that the message is that the first message was logged, the second not, and no
exception thrown.

=cut

is(evcheck(sub {
             Log::Info::set_sink_out_level(TESTCHAN1, SINK1, 10);
             Log(TESTCHAN1, 5, MESSAGE1);
             Log(TESTCHAN1, 15, MESSAGE2);
           }, 'logging a message at channel -> undef, sink -> 10 (1)'),
   1, 'logging a message at channel -> undef, sink -> 10 (1)');

is 0+@mess, 1,
   'logging a message at channel -> undef, sink -> 10 (2)'
  or diag Dumper \@mess;
is $mess[0], MESSAGE1,
   'logging a message at channel -> undef, sink -> 10 (3)';
@mess = ();
