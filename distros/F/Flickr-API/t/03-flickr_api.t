use strict;
use warnings;
use Test::More;
use Storable;

use Flickr::API;

if (defined($ENV{MAKETEST_FLICKR_CFG})) {
	plan( tests => 11 );
}
else {
	plan(skip_all => 'These tests require that MAKETEST_FLICKR_CFG points to a valid config, see README.');
}


my $config_file = $ENV{MAKETEST_FLICKR_CFG};
my $config_ref;

my $fileflag=0;
if (-r $config_file) { $fileflag = 1; }
is($fileflag, 1, "Is the config file: $config_file, readable?");

SKIP: {

	skip "Skipping api tests, Flickr config isn't there or is not readable", 9
	  if $fileflag == 0;

	$config_ref = retrieve($config_file);

	like($config_ref->{api_key}, qr/[0-9a-f]+/i,
		 "Did we get a hexadecimal api key in the config");

	like($config_ref->{api_secret}, qr/[0-9a-f]+/i,
		 "Did we get a hexadecimal api secret in the config");

	my $api;
	my $rsp;
	my $ref;

	$api= Flickr::API->new({
							'api_key'    => $config_ref->{api_key},
							'api_secret' => $config_ref->{api_secret},
						   });

	isa_ok($api, 'Flickr::API');
	is($api->is_oauth, 0, 'Does Flickr::API object identify as Flickr authentication');

	$rsp = $api->execute_method('fake.method', {});
	isa_ok $rsp, 'Flickr::API::Response';



  SKIP: {
		skip "skipping error code check, since we couldn't reach the API", 1
		  if $rsp->rc() ne '200';
		# this error code may change in future!
		is($rsp->error_code(), 112, 'checking the error code for "method not found"');
	}



##################################################
#
# check the 'format not found' error is working
#

	$rsp = $api->execute_method('flickr.test.echo', {format => 'fake'});

  SKIP: {
		skip "skipping error code check, since we couldn't reach the API", 1
		  if $rsp->rc() ne '200';
		is($rsp->error_code(), 111, 'checking the error code for "format not found"');
	}

	$rsp = $api->execute_method('flickr.reflection.getMethods');

	$ref = $rsp->as_hash();

  SKIP: {
		skip "skipping method call check, since we couldn't reach the API", 1
		  if $rsp->rc() ne '200';
		is($ref->{'stat'}, 'ok', 'Check for ok status from flickr.reflection.getMethods');
	}

	undef $rsp;
	undef $ref;

	$rsp =  $api->execute_method('flickr.test.echo', { 'foo' => 'barred' } );
	$ref = $rsp->as_hash();


  SKIP: {
		skip "skipping method call check, since we couldn't reach the API", 2
		  if $rsp->rc() ne '200';
		is($ref->{'stat'}, 'ok', 'Check for ok status from flickr.test.echo');
		is($ref->{'foo'}, 'barred', 'Check result from flickr.test.echo');
	}


}



exit;

# Local Variables:
# mode: Perl
# End:
