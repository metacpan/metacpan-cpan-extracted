use Test::Integration::Setup;

use Test::Most tests => 3;

use aliased "Google::RestApi";

# use Carp::Always;
# init_logger($DEBUG);

my $api;
$api = RestApi->new(config_file => config_file());
isa_ok $api, "Google::RestApi", "New api";

my $about;
is_hash $about = $api->api(
  uri => 'https://www.googleapis.com/drive/v3/about',
  params => { fields => 'user' },
), "Api login should succeed";
is_hash $about->{user}, "About drive.user";
