# vim:set sw=4 ts=4 sts=4 ft=perl expandtab:
use strict;
use warnings;
use Test::More;

BEGIN { use_ok( 'Etherpad' ); }

my $ec = Etherpad->new ({url => 'http://pad.example.com', apikey => 'password'});
isa_ok ($ec, 'Etherpad');

is ($ec->url, 'http://pad.example.com');

is ($ec->apikey, 'password');

isa_ok($ec->ua, 'Mojo::UserAgent');

isa_ok($ec->user('bender'), 'Etherpad');

is ($ec->user, 'bender');

isa_ok($ec->password('beer'), 'Etherpad');

is ($ec->password, 'beer');

isa_ok($ec->proxy({http => 'localhost:8000'}), 'Etherpad');

is_deeply ($ec->proxy, {http => 'localhost:8000'});

done_testing(11);
