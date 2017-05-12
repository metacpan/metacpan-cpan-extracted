use strict;
use warnings;
use HTTP::Session;
use HTTP::Session::State::Test;
use HTTP::Session::Store::Test;
use CGI;
use Test::Requires 'Test::Memory::Cycle';
use Test::More tests => 1;

my $session = HTTP::Session->new(
    state => HTTP::Session::State::Test->new(
        session_id => 'foo',
    ),
    store => HTTP::Session::Store::Test->new(),
    request => CGI->new(),
);
Test::Memory::Cycle::memory_cycle_ok($session);

