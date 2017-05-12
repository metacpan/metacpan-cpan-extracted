#!perl

use Test::More tests => 3;

use Games::EveOnline::EveCentral;

my $o = Games::EveOnline::EveCentral->new;
isa_ok($o, 'Games::EveOnline::EveCentral');

isa_ok($o->ua, 'LWP::UserAgent::Determined');
isa_ok($o->libxml, 'XML::LibXML');
