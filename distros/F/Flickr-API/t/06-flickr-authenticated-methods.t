use strict;
use warnings;
use Test::More;
use Storable;
use Flickr::API;

if (defined($ENV{MAKETEST_FLICKR_CFG})) {
	plan( tests => 15 );
}
else {
	plan(skip_all => 'These tests require that MAKETEST_FLICKR_CFG points to a valid config, see README.');
}



my $config_file  = $ENV{MAKETEST_FLICKR_CFG};
my $config_ref;
my $api;
my $proceed = 0;

my $fileflag=0;
if (-r $config_file) { $fileflag = 1; }
is($fileflag, 1, "Is the config file: $config_file, readable?");

SKIP: {

	skip "Skipping authentication tests, flickr config isn't there or is not readable", 15
	  if $fileflag == 0;

	$api = Flickr::API->import_storable_config($config_file);

	isa_ok($api, 'Flickr::API');
	is($api->is_oauth, 0, 'Does Flickr::API object identify as Flickr');

	like($api->{fauth}->{api_key},  qr/[0-9a-f]+/i, "Did we get an api key from $config_file");
	like($api->{fauth}->{api_secret}, qr/[0-9a-f]+/i, "Did we get an api secret from $config_file");

	if (defined($api->{fauth}->{token}) and $api->{fauth}->{token} =~ m/^[0-9]+-[0-9a-f]+$/i) {

		$proceed = 1;

	}

	  SKIP: {

			skip "Skipping authentication tests, flickr access token missing or seems wrong", 10
			  if $proceed == 0;

			my $rsp = $api->execute_method('flickr.auth.checkToken', {auth_token => $api->{fauth}->{token}});

			is($rsp->success(), 1, "Did flickr.auth.checkToken complete sucessfully");
			my $ref = $rsp->as_hash();

			is($ref->{stat}, 'ok', "Did flickr.auth.checkToken complete sucessfully");

			isnt($ref->{auth}->{user}->{nsid}, undef, "Did flickr.auth.checkToken return nsid");
			isnt($ref->{auth}->{user}->{username}, undef, "Did flickr.auth.checkToken return username");


			$rsp = $api->execute_method('flickr.test.login', {auth_token => $api->{fauth}->{token}});
			$ref = $rsp->as_hash();

			is($ref->{stat}, 'ok', "Did flickr.test.login complete sucessfully");

			isnt($ref->{user}->{id}, undef, "Did flickr.test.login return id");
			isnt($ref->{user}->{username}, undef, "Did flickr.test.login return username");


			$rsp = $api->execute_method('flickr.prefs.getPrivacy', {auth_token => $api->{fauth}->{token}});
			$ref = $rsp->as_hash();

			is($ref->{stat}, 'ok', "Did flickr.prefs.getPrivacy complete sucessfully");

			isnt($ref->{person}->{nsid}, undef, "Did flickr.prefs.getPrivacy return nsid");
			isnt($ref->{person}->{privacy}, undef, "Did flickr.prefs.getPrivacy return privacy");

		}
}



exit;

__END__


# Local Variables:
# mode: Perl
# End:
