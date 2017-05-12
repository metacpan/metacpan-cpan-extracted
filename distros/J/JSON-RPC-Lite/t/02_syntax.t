use strict;
use Test::More 0.98;
use Plack::Test;
use HTTP::Request::Common;

use JSON::RPC::Lite;

eval <<EOM;
method 'echo' => sub {
    return $_[0];
};
as_psgi_app;
EOM

ok !$@, 'sinatra-ish syntax.';

done_testing;
