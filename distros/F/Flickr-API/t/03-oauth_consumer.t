use strict;
use warnings;
use Test::More;
use Storable;

use Flickr::API;

if (defined($ENV{MAKETEST_OAUTH_CFG})) {
	plan( tests => 7 );
}
else {
	plan(skip_all => 'These tests require that MAKETEST_OAUTH_CFG points to a valid config, see README.');
}


my $config_file = $ENV{MAKETEST_OAUTH_CFG};
my $config_ref;

my $fileflag=0;
if (-r $config_file) { $fileflag = 1; }
is($fileflag, 1, "Is the config file: $config_file, readable?");

SKIP: {

    skip "Skipping consumer message tests, oauth config isn't there or is not readable", 6
	  if $fileflag == 0;

	my $rsp;
	my $ref;

 	my $api = Flickr::API->import_storable_config($config_file);

	isa_ok($api, 'Flickr::API');
	is($api->is_oauth, 1, 'Does Flickr::API object identify as OAuth');

	$rsp =  $api->execute_method('flickr.test.echo', {format => 'fake'});

  SKIP: {
		skip "skipping error code check, since we couldn't reach the API", 1
		  if $rsp->rc() ne '200';
		is($rsp->error_code(), 111, 'checking the error code for "format not found"');
	}

	$rsp =  $api->execute_method('flickr.reflection.getMethods');
	$ref = $rsp->as_hash();

  SKIP: {
		skip "skipping method call check, since we couldn't reach the API", 1
		  if $rsp->rc() ne '200';
		is($ref->{'stat'}, 'ok', 'Check for ok status from flickr.reflection.getMethods');
	}

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
