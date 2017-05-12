#!perl

use Test::More tests => 2;

use Games::EveOnline::EveCentral;
use Games::EveOnline::EveCentral::Request;

my $o = Games::EveOnline::EveCentral::Request->new;
isa_ok($o, 'Games::EveOnline::EveCentral::Request');

my $r = $o->http_request('path/to/method');
isa_ok($r, 'HTTP::Request');
