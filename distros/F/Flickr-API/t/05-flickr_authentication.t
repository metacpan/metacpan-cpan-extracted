use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Storable;
use Term::ReadLine;

use Flickr::API;

if (defined($ENV{MAKETEST_FLICKR_AUTHED})) {

    plan(skip_all => 'These tests are being bypassed because MAKETEST_FLICKR_AUTHED is defined, see README.');

}

if (defined($ENV{MAKETEST_FLICKR_CFG})) {
	plan( tests => 15 );
}
else {
	plan(skip_all => 'These tests require that MAKETEST_FLICKR_CFG points to a valid config, see README.');
}

my $config_file  = $ENV{MAKETEST_FLICKR_CFG};

my $useperms = 'read';

if (defined($ENV{MAKETEST_PERMS}) && $ENV{MAKETEST_PERMS} =~ /^(read|write|delete)$/) {

    $useperms = $ENV{MAKETEST_PERMS};

}

my $api;
my $term;
my $key='fail';
my $frob;

my $fileflag=0;
if (-r $config_file) { $fileflag = 1; }
is($fileflag, 1, "Is the config file: $config_file, readable?");

SKIP: {

	skip "Skipping authentication tests, flickr config isn't there or is not readable", 14
	  if $fileflag == 0;

	$term   = Term::ReadLine->new('Testing Flickr::API');
	$term->ornaments(0);

	$api = Flickr::API->import_storable_config($config_file);

	isa_ok($api, 'Flickr::API');
	is($api->is_oauth, 0, 'Does Flickr::API object identify as Flickr');

	like($api->{api_key},  qr/[0-9a-f]+/i, "Did we get an api key from $config_file");
	like($api->{api_secret}, qr/[0-9a-f]+/i, "Did we get an api secret from $config_file");

  SKIP: {

		skip "Skip getting a frob, we already have " . $api->{fauth}->{frob} , 1
		  if (defined($api->{fauth}->{frob}) and $api->{fauth}->{frob} =~ m/^[0-9a-f\-]+/i);

		my $url = $api->request_auth_url($useperms);

		my $uri = $url->as_string();

        my $which_rl = $term->ReadLine;

        if ($which_rl eq "Term::ReadLine::Perl" or $which_rl eq "Term::ReadLine::Perl5") {

            diag "\n\nTerm::ReadLine::Perl and Term::ReadLine::Perl5 may display prompts" .
                 "\nincorrectly. If this is the case for you, try adding \"PERL_RL=Stub\"" .
                 "\nto the environment variables passed in with make test\n\n";

        }
		my $prompt = "\n\n$uri\n\n" .
		  "Copy the above url to a browser, and authenticate with Flickr\n" .
		  "Press [ENTER] once you get the redirect (or error): ";
		my $input = $term->readline($prompt);

		$prompt = "\n\nCopy the redirect URL from your browser and enter it\n" .
            "(or if there was an error, or a non-web-based API Key, just press [Enter]\n" .
            "\nURL Here: ";
		$input = $term->readline($prompt);

		chomp($input);

    SKIP: {
            skip "Skip frob input test, no frob input. Desktop API?", 1
                unless $input =~ m/.*frob=.*/;

		    my ($callback_returned,$frob_received) = split(/\?/,$input);

            ($key,$frob) = split(/\=/,$frob_received);

            is($key, 'frob', "Was the returned key 'frob'");

        }
	}

	if ( defined($key) and
             $key ne 'frob' and
             defined($api->{fauth}->{frob}) and
             $api->{fauth}->{frob} =~ m/^[0-9a-f\-]+/i) {

		$key  = 'frob';
		$frob = $api->{fauth}->{frob};

 	}

  SKIP: {

		skip "Skip frob to token tests, no frob received. Desktop API?", 9
		  if $key ne 'frob';

		like($frob, qr/^[0-9a-f\-]+/i,  "Is the returned frob, frob-shaped");

	  SKIP: {

			skip "Skip getting a token, we already have " . $api->{fauth}->{token} , 3
			  if defined($api->{fauth}->{token}) and $api->{fauth}->{token} =~ m/^[0-9a-f\-]+/i;

			my $rc = $api->flickr_access_token($frob);

			is($rc, 'ok', 'Was flickr_access_token successful');

			like($api->{fauth}->{token}, qr/^[0-9a-f\-]+/i, 'Is the token received token shaped');
			like($api->{fauth}->{user}->{nsid}, qr/^[0-9]+\@[0-9a-z]/i, 'Did we get back an nsid');

		}

		$fileflag=0;
		if (-w $config_file) { $fileflag = 1; }
		is($fileflag, 1, "Is the config file: $config_file, writable?");

	  SKIP: {

			skip "Skip saving of flickr config, ",$config_file," is not writeable", 4
			  if $fileflag == 0;

			$api->export_storable_config($config_file);

			my $api2 = Flickr::API->import_storable_config($config_file);

			isa_ok($api2, 'Flickr::API');
			is($api2->{api_key}, $api->{api_key}, 'were we able to import our api key');
			is($api2->{api_secret}, $api->{api_secret}, 'were we able to import our api secret');
			is($api2->{fauth}->{token},$api->{fauth}->{token}, 'What about the token');

		}
	}
} # skipping auth tests


exit;


__END__

# Local Variables:
# mode: Perl
# End:

