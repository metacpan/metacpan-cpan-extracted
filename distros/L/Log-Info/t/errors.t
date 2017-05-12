# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Log::Info functions

This package tests the error-checking in Log::Info

=cut

use Test                  qw( ok plan );

use FindBin               qw( $Bin );
use lib  "$Bin/../lib";

# Channel names for playing with
use constant TESTCHAN1 => 'testchan1';

# Badly formed channel names
use constant BADCHAN1  => 'foo:bar';

# Badly formed sink names
use constant BADSINK1  => ' bingo';

BEGIN {
  plan tests  => 3;
       todo   => [],
       ;
}

use Log::Info;

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

ok 1, 1, 'compilation';

=head2 Test 2: adding a badly-named channel

This test adds a badly-named channel.  The test is that an exception is
thrown.

=cut

{
  my $ok = 0;
  eval {
    Log::Info::add_channel (BADCHAN1);
  }; if ( $@ ) {
#    print STDERR "Test failed:\n$@\n"
#      if $ENV{TEST_DEBUG};
    $ok = 1;
  }

  ok $ok, 1, 'adding a badly-named channel';
}

=head2 Test 3: adding a badly-named sink

This test adds a new channel, and a badly-named sink.  The test is that the
channel is added successfully, and an exception is thrown when the sink is
added.

=cut

{
  my $ok = 0;
  eval {
    Log::Info::add_channel(TESTCHAN1);
    $ok++;
    Log::Info::add_sink(BADSINK1)
  }; if ( $@ ) {
#    print STDERR "Test failed:\n$@\n"
#      if $ENV{TEST_DEBUG};
    $ok++;
  }

  ok $ok, 2, 'adding a badly-named sink';
}

