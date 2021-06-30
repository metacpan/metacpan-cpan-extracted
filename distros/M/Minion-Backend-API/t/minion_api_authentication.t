use Test::More tests => 81;
use Test::Mojo;
use Mojo::URL;
use lib './t';

use_ok('AppAuthentication');

my $t = Test::Mojo->new('AppAuthentication');

$t->put_ok(url('/broadcast') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 1});

$t->post_ok(url('/dequeue') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 2});

$t->post_ok(url('/enqueue') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 3});

$t->patch_ok(url('/fail-job') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 4});

$t->patch_ok(url('/finish-job') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 5});

$t->get_ok(url('/history'))
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 6});

$t->get_ok(url('/list-jobs') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 7});

$t->get_ok(url('/list-locks') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 8});

$t->get_ok(url('/list-workers') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 9});

$t->get_ok(url('/lock') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 10});

$t->patch_ok(url('/note') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 11});

$t->patch_ok(url('/receive') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 12});

$t->post_ok(url('/register-worker') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 13});

$t->delete_ok(url('/remove-job') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 14});

$t->post_ok(url('/repair'))
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 15});

$t->post_ok(url('/reset') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 16});

$t->put_ok(url('/retry-job') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 17});

$t->get_ok(url('/stats') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 18});

$t->delete_ok(url('/unlock') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 19});

$t->delete_ok(url('/unregister-worker') => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 20});

sub url {
    my $path_info = shift;

    return Mojo::URL->new($path_info)->userinfo('foo:baz');
}

done_testing();
