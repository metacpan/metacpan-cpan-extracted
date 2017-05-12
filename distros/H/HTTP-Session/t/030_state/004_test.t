use strict;
use warnings;
use Test::More tests => 1;
use HTTP::Session::State::Test;

my $state = HTTP::Session::State::Test->new(
    session_id => 'foobar',
);
is $state->get_session_id(), 'foobar';
$state->response_filter(); # nop.

