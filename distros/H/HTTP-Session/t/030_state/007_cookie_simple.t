use strict;
use warnings;
use Test::More;
use t::CookieTest;
use CGI::Simple;
plan skip_all => "this test requires CGI::Simple" unless eval "use CGI::Simple; 1";
plan tests => 18;

# XXX use CGI::Simple::Cookie
$HTTP::Session::State::Cookie::COOKIE_CLASS = 'CGI::Simple::Cookie';

t::CookieTest->test('CGI::Simple');

ok !$INC{'CGI.pm'};
ok !$INC{'CGI/Cookie.pm'};
ok $INC{'CGI/Simple.pm'};
ok $INC{'CGI/Simple/Cookie.pm'};
