use strict;
use Test::More (tests => 8);

use HTTP::Date;
use HTTP::Request;
use HTTP::Response::OnDisk;

my $time = time;

my $req = HTTP::Request->new(GET => 'http://www.sn.no');
$req->date($time - 30);

my $r = HTTP::Response::OnDisk->new( 200, "OK" );
$r->client_date($time - 20);
$r->date($time - 25);
$r->last_modified($time - 5000000);
$r->request($req);

my $current_age = $r->current_age;

ok($current_age >= 35 && $current_age <= 40);

my $freshness_lifetime = $r->freshness_lifetime;
ok ($freshness_lifetime >= 12 * 3600);

my $is_fresh = $r->is_fresh;
ok($is_fresh);

# OK, now we add an Expires header
$r->expires($time);

$freshness_lifetime = $r->freshness_lifetime;
is($freshness_lifetime, 25);

$r->remove_header('expires');

# Now we try the 'Age' header and the Cache-Contol:

$r->header('Age', 300);
$r->push_header('Cache-Control', 'junk');
$r->push_header(Cache_Control => 'max-age = 10');

$current_age = $r->current_age;
$freshness_lifetime = $r->freshness_lifetime;

ok($current_age > 300);
ok($freshness_lifetime == 10);
ok($r->fresh_until);  # should return something

my $r2 = HTTP::Response::OnDisk->parse($r->as_string);
my @h = $r2->header('Cache-Control');
ok(scalar @h == 2);
