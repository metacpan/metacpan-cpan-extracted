use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Storable;

use Flickr::API;


if (defined($ENV{MAKETEST_OAUTH_CFG})) {
	plan( tests => 11 );
}
else {
	plan(skip_all => 'These tests require that MAKETEST_OAUTH_CFG points to a valid config, see README.');
}

my $config_file  = $ENV{MAKETEST_OAUTH_CFG};
my $config_ref;

my $fileflag=0;
if (-r $config_file) { $fileflag = 1; }
is($fileflag, 1, "Is the config file: $config_file, readable?");

SKIP: {

	skip "Skipping request token tests, oauth config isn't there or is not readable", 10
	  if $fileflag == 0;


	my $api = Flickr::API->import_storable_config($config_file);

	isa_ok($api, 'Flickr::API');
	is($api->is_oauth, 1, 'Does Flickr::API object identify as OAuth');

  SKIP: {

		skip "Skipping request token tests, oauth config already has accesstoken", 8
		  if $api->get_oauth_request_type() =~ m/protected resource/i;

		is($api->get_oauth_request_type(), 'consumer', 'Does Flickr::API object identify as consumer request');

		my $request_req = $api->oauth_request_token({'callback' => $config_ref->{callback}});

		is($request_req, 'ok', "Did oauth_request_token complete successfully");

	  SKIP: {
			skip "Skipping request token tests, oauth_request_token returns $request_req", 6
			  if $request_req ne 'ok';

			my %config = $api->export_config();
			$config{'continue-to-access'} = $request_req;

			$fileflag=0;
			if (-w $config_file) { $fileflag = 1; }
			is($fileflag, 1, "Is the config file: $config_file, writeable?");

			$api->export_storable_config($config_file);

			my $api2 = Flickr::API->import_storable_config($config_file);

			isa_ok($api2, 'Flickr::API');

			is_deeply($api2->{oauth}, $api->{oauth}, "Did import_storable_config get back the config we stored");

			isa_ok($api2->{oauth}->{request_token}, 'Net::OAuth::V1_0A::RequestTokenResponse');
			is($api->{oauth}->{request_token}->{callback_confirmed}, 'true',
			   'Is the callback confirmed in the request token'); #10
			like($api2->{oauth}->{request_token}->{token_secret}, qr/[0-9a-f]+/i,
				 'Was a request token received and are we good to go to to access token tests?');
			print "\n\nOAuth Config:\n\n",Dumper($api2->{oauth}),"\n\n";
		}
	}
}


exit;


# Local Variables:
# mode: Perl
# End:
