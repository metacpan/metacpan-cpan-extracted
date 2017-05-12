use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Storable;

use Flickr::API;

if (defined($ENV{MAKETEST_FLICKR_CFG})) {
	plan( tests => 5 );
}
else {
	plan(skip_all => 'These tests require that MAKETEST_FLICKR_CFG points to a valid config, see README.');
}

my $config_file  = $ENV{MAKETEST_FLICKR_CFG};
my $config_ref;
my $fileflag=0;
if (-r $config_file) { $fileflag = 1; }
is($fileflag, 1, "Is the config file: $config_file, readable?");


SKIP: {

	skip "Skipping request_auth_url tests, flickr config isn't there or is not readable", 4
	  if $fileflag == 0;

	my $api = Flickr::API->import_storable_config($config_file);
	isa_ok($api, 'Flickr::API');

	is($api->is_oauth, 0, 'Does Flickr::API object identify as Flickr');

	like($api->{api_key}, qr/[0-9a-f]+/i,
		 "Did we get a hexadecimal api key in the config");

	like($api->{api_secret}, qr/[0-9a-f]+/i,
		 "Did we get a hexadecimal api secret in the config");


} #skip request_auth_url tests


# Local Variables:
# mode: Perl
# End:

