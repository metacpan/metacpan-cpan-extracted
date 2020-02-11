use Test::More tests => 81;
use Test::Mojo;
use lib './t';

use_ok('MyApp');

my $t = Test::Mojo->new('MyApp');

$t->put_ok('/broadcast' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 1});
  
$t->post_ok('/dequeue' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 2});
  
$t->post_ok('/enqueue' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 3});
  
$t->patch_ok('/fail-job' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 4});
  
$t->patch_ok('/finish-job' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 5});
  
$t->get_ok('/history')
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 6});
  
$t->get_ok('/list-jobs' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 7});
  
$t->get_ok('/list-locks' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 8});
  
$t->get_ok('/list-workers' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 9});
  
$t->get_ok('/lock' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 10});
  
$t->patch_ok('/note' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 11});
  
$t->patch_ok('/receive' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 12});
  
$t->post_ok('/register-worker' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 13});
  
$t->delete_ok('/remove-job' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 14});
  
$t->post_ok('/repair')
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 15});
  
$t->post_ok('/reset' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 16});
  
$t->put_ok('/retry-job' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 17});
  
$t->get_ok('/stats' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 18});
  
$t->delete_ok('/unlock' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 19});
  
$t->delete_ok('/unregister-worker' => json => {})
  ->status_is(200)
  ->content_type_like(qr!application/json!)
  ->json_is({success => 1, result => 20});  

done_testing();