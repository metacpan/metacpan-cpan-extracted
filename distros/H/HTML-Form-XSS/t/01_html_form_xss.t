use strict;
use warnings;
use Test::More;
use WWW::Mechanize;
use lib qw(lib ../lib);
use HTML::Form::XSS;
plan(tests => 1);

my $mech = WWW::Mechanize->new();
my $xss = HTML::Form::XSS->new($mech, config => 'root/config.xml');
#1
isa_ok($xss, "HTML::Form::XSS");