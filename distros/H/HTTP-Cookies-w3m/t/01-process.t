#!perl -T
use strict;
use warnings;
use FindBin;
use HTTP::Cookies::w3m;
use Test::More tests => 1;

my $cookie_jar = HTTP::Cookies::w3m->new( file => $FindBin::Bin . '/cookie' );
ok($cookie_jar->as_string eq qq(Set-Cookie3: key=value; path="/"; domain=.example.jp; path_spec; expires="2035-11-21 01:39:54Z"; version=0\n));
