use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Healthchecks
);

my $ec = Healthchecks->new ({url => 'http://hc.example.com', apikey => 'password'});
isa_ok ($ec, 'Healthchecks');

is ($ec->url, 'http://hc.example.com');

is ($ec->apikey, 'password');

isa_ok($ec->ua, 'Mojo::UserAgent');

isa_ok($ec->user('bender'), 'Healthchecks');

is ($ec->user, 'bender');

isa_ok($ec->password('beer'), 'Healthchecks');

is ($ec->password, 'beer');

isa_ok($ec->proxy({ http => 'localhost:8000' }), 'Healthchecks');

is_deeply($ec->proxy, { http => 'localhost:8000' });

done_testing (11);
