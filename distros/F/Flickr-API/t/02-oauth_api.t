use strict;
use warnings;
use Test::More tests => 32;
use Test::Script;
use File::Temp ();

use Flickr::API;


########################################################
#
# create a generic flickr api with oauth consumer object
#

my $key    = 'My_Made_up_Key';
my $secret = 'My_little_secret';

my $api = Flickr::API->new({
						 'consumer_key'    => $key,
						 'consumer_secret' => $secret,
						});

isa_ok($api, 'Flickr::API');
is($api->is_oauth, 1, 'Does Flickr::API object identify as OAuth');
is($api->get_oauth_request_type(), 'consumer', 'Does Flickr::API object identify as consumer request');

is($api->api_type, 'oauth', 'Does Flickr::API object correctly specify its type as oauth');

########################################################
#
# make sure it returns the required message params
#

my %config = $api->export_config('consumer', 'message');
is($config{'consumer_key'}, $key,
   'Did export_config return the consumer_key in consumer/message request');
is($config{'signature_method'}, 'HMAC-SHA1',
   'Did export_config return the correct signature_method in consumer/message request');
like($config{'nonce'}, qr/[0-9a-f]+/i,
	  'Did export_config return a nonce in consumer/message request');
like($config{'timestamp'}, qr/[0-9]+/i,
	  'Did export_config return a timestamp in consumer/message request');

########################################################
#
# make sure it returns the required api params
#

undef %config;
%config = $api->export_config('consumer', 'api');
is($config{'consumer_secret'}, $secret,
   'Did export_config return the consumer_secret in consumer/api request');
is($config{'request_method'}, 'GET',
   'Did export_config return the correct request_method in consumer/api request');
is($config{'request_url'}, 'https://api.flickr.com/services/rest/',
   'Did export_config return the correct request_url in consumer/api request');






undef %config;
undef $api;

##################################################################
#
# create a generic flickr api with oauth protected resource object
#

my $token        = 'a-fake-oauth-token-for-generic-tests';
my $token_secret = 'my-embarassing-secret-exposed';

$api = Flickr::API->new({
							'consumer_key'    => $key,
							'consumer_secret' => $secret,
							'token'           => $token,
							'token_secret'    => $token_secret,
						});

isa_ok($api, 'Flickr::API');
is($api->is_oauth, 1, 'Does Flickr::API object identify as OAuth');
is($api->get_oauth_request_type(), 'protected resource',
   'Does Flickr::API object identify as protected resource request');


##################################################################
#
# make sure it also returns the required message params
#

%config = $api->export_config('protected resource', 'message');
is($config{'consumer_key'}, $key,
   'Did export_config return the consumer_key in protected resource/message request');
is($config{'token'}, $token,
   'Did export_config return the token in protected resource/message request');
is($config{'signature_method'}, 'HMAC-SHA1',
   'Did export_config return the correct signature_method in protected resource/message request');
like($config{'nonce'}, qr/[0-9a-f]+/i,
	  'Did export_config return a nonce in protected resource/message request');
like($config{'timestamp'}, qr/[0-9]+/i,
	 'Did export_config return a timestamp in protected resource/message request');



########################################################
#
# make sure it also returns the required api params
#

undef %config;
%config = $api->export_config('protected resource', 'api');
is($config{'consumer_secret'}, $secret,
   'Did export_config return the consumer_secret in protected resource/api request');
is($config{'token_secret'}, $token_secret,
   'Did export_config return the token_secret in protected resource/api request');
is($config{'request_method'}, 'GET',
   'Did export_config return the correct request_method in protected resource/api request');
is($config{'request_url'}, 'https://api.flickr.com/services/rest/',
   'Did export_config return the correct request_url in protected resource/api request');

my $FH    = File::Temp->new();
my $fname = $FH->filename;

$api->export_storable_config($fname);

my $fileflag=0;
if (-r $fname) { $fileflag = 1; }
is($fileflag, 1, "Did export_storable_config produce a readable config");

my $api2 = Flickr::API->import_storable_config($fname);

isa_ok($api2, 'Flickr::API');

is_deeply($api2->{oauth}, $api->{oauth}, "Did import_storable_config get back the config we stored");


script_compiles('script/flickr_make_stored_config.pl','Does flickr_make_stored_config.pl compile');
script_compiles('script/flickr_dump_stored_config.pl','Does flickr_dump_stored_config.pl compile');
script_compiles('script/flickr_make_test_values.pl','Does flickr_make_test_values.pl compile');

my @runtime = ('script/flickr_dump_stored_config.pl', '--config_in='.$fname);

script_runs(\@runtime, "Did flickr_dump_stored_config.pl run");


########################################################
#
# check private method
#

my $apiex = $api->_export_api();

is($apiex->{'oauth'}->{'consumer_key'}, $key,
   'Did _export_api return the consumer_key when asked');


my $nonce = $api->_make_nonce();
like( $nonce, qr/[0-9a-f]+/i,
	  'Did _make_nonce return a nonce when asked');


exit;

# Local Variables:
# mode: Perl
# End:
