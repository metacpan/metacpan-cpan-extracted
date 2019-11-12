use strict;
use warnings;
use Test::More;

use HTTP::Cookies;
use HTTP::Request;
use HTTP::Response;

my $req  = HTTP::Request->new(GET => "http://example.com");
my $resp = HTTP::Response->new(200, 'OK', ['Set-Cookie', q!a="b;c;\\"d"; expires=Fri, 06-Nov-2999 08:58:34 GMT; domain=example.com; path=/!]);
$resp->request($req);

my $c = HTTP::Cookies->new;
$c->extract_cookies($resp);
is $c->as_string, 'Set-Cookie3: a="b;c;\"d"; path="/"; domain=example.com; path_spec; expires="2999-11-06 08:58:34Z"; version=0' . "\n";

# test the implementation of the split function in isolation.
# should probably name the function better too.
my $simple = 'b;c;d';
is_deeply HTTP::Cookies::_split_text($simple), [qw/b c  d/], "Parse $simple";
my $complex = '"b;c;\\"d";blah=32;foo="/"';
is_deeply HTTP::Cookies::_split_text($complex), ['b;c;"d','blah=32','foo=/'], "Parse $complex";

done_testing;
