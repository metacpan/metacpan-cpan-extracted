# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Log::Info functions

This package tests the basic functionality of Log::Info

=cut

use Test::More            tests => 10, import => [qw( diag is ok )];

use FindBin               qw( $Bin );
use lib  "$Bin/../lib";

# Channel names for playing with
use constant TESTCHAN1 => 'testchan1';
use constant TESTCHAN2 => 'testchan2';

use Log::Info;

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

is 1, 1, 'compilation';

=head2 Test 2: adding a channel

This test adds a channel.  The test is that all this occurs without error.

=cut

Log::Info::add_channel (TESTCHAN1);
ok 1, 'adding a channel';

=head2 Test 3: channel exists

The test is that the channel just created exists as per Log::Info

=cut

ok Log::Info::channel_exists (TESTCHAN1), 'channel exists';

=head2 Test 4: writing to an open channel

This test checks that:

=over 4

=item *

we can write to the channel just created

=item *

writing in the presence of no sinks

=item *

Log() is imported by default

=back

The test is that a write occurs without throwing an exception

=cut

Log (TESTCHAN1, 5, 'random text');
ok 1, 'writing to an open channel';

=head2 Test 5: adding a channel again

This test adds the same channel again.  The test is that an exception is
thrown.

=cut

{
  my $ok = 0;
  eval {
    Log::Info::add_channel (TESTCHAN1);
  }; if ( $@ ) {
    $ok = ( $@ =~ /^Channel already exists: / )
      or diag "\$\@: $@";
  }
  ok $ok, 'adding a channel again';
}

=head2 Test 6: deleting a known channel

This test deletes the added channel.  The test is that no exception is thrown.

=cut

Log::Info::delete_channel (TESTCHAN1);
ok 1, 'deleting a known channel';

=head2 Test 7: channel does not exist

The test is that the channel just deleted does not exist as per Log::Info

=cut

ok ! Log::Info::channel_exists (TESTCHAN1), 'channel does not exist';

=head2 Test 8: deleting an unknown channel

This test deletes the added channel again.  The test is that an exception is
thrown.

=cut

{
  my $ok = 0;
  eval {
    Log::Info::delete_channel (TESTCHAN1);
  }; if ( $@ ) {
    $ok = ( $@ =~ /^Channel does not exist: / )
      or diag "\$\@: $@";
  }
  ok $ok, 'deleting an unknown channel';
}

=head2 Test 9: writing to a deleted channel

This test writes to the deleted channel.  The test is that an exception is
thrown.

=cut

{
  my $ok = 0;
  eval {
    Log (TESTCHAN1, 5, 'random text');
  }; if ( $@ ) {
    $ok = ( $@ =~ /^no such Log::Info channel / )
      or diag "\$\@: $@";
  }
  ok $ok, 'writing to a deleted channel';
}

=head2 Test 10: writing to a never-existed channel

This test writes to a channel that never existed.  The test is that an
exception is thrown.

=cut

{
  my $ok = 0;
  eval {
    Log (TESTCHAN2, 5, 'random text');
  }; if ( $@ ) {
    $ok = ( $@ =~ /^no such Log::Info channel / )
      or diag "\$\@: $@";
  }
  ok $ok, 'writing to a never-existed channel';
}

