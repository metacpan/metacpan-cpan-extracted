use strict;
use warnings;
use Test::More tests => 15;
use File::Temp ();

use Flickr::API;
########################################################
#
# create a generic flickr api with oauth consumer object
#

my $key    = 'My_Made_up_Key';
my $secret = 'My_little_secret';

my $api = Flickr::API->new({
						 'key'    => $key,
						 'api_secret' => $secret,
						});

isa_ok($api, 'Flickr::API');
is($api->is_oauth, 0, 'Does Flickr::API object identify as Flickr authentication');

is($api->api_type, 'flickr', 'Does Flickr::API object correctly specify its type as flickr');

########################################################
#
# make sure it returns the required api params
#

my %config = $api->export_config();

is($config{'api_key'}, $key,
   'Did export_config return the api_key');

is ($config{'key'}, undef,
    'Did constructor remove the older key in favor of api_key');

is($config{'api_secret'}, $secret,
   'Did export_config return the api secret');

is ($config{'secret'}, undef,
    'Did constructor remove the older secret in favor of api_secret');

is($config{'frob'}, undef,
   'Did export_config return undef for undefined frob');

is($config{'token'}, undef,
   'Did export_config return undef for undefined token');


########################################################
#
#
#

my $FH    = File::Temp->new();
my $config_file = $FH->filename;

$api->export_storable_config($config_file);

my $fileflag=0;
if (-r $config_file) { $fileflag = 1; }
is($fileflag, 1, "Did export_storable_config produce a readable config");

my $api2 = Flickr::API->import_storable_config($config_file);

isa_ok($api2, 'Flickr::API');

is($api2->{api_key}, $key, 'were we able to import our api key');

is($api2->{key}, undef, "did we sucessfully shake deprecated 'key' argument");

is($api2->{api_secret}, $secret, 'were we able to import our api secret');

is($api2->{secret}, undef, "did we sucessfully shake deprecated 'secret' argument");

exit;

# Local Variables:
# mode: Perl
# End:
