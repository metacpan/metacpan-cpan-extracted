use strict;
use warnings;
use Test::More;
use Term::ReadLine;

use Flickr::API;

if (defined($ENV{MAKETEST_OAUTH_AUTHED})) {

    plan(skip_all => 'These tests are being bypassed because MAKETEST_OAUTH_AUTHED is defined, see README.');

}

if (defined($ENV{MAKETEST_OAUTH_CFG})) {
    plan( tests => 21 );
}
else {
    plan(skip_all => 'These tests require that MAKETEST_OAUTH_CFG points to a valid config, see README.');
}


my $config_file  = $ENV{MAKETEST_OAUTH_CFG};
my $config_ref;

my $useperms = 'read';

if (defined($ENV{MAKETEST_PERMS}) && $ENV{MAKETEST_PERMS} =~ /^(read|write|delete)$/) {

    $useperms = $ENV{MAKETEST_PERMS};

}

my $api;
my $term;


$term   = Term::ReadLine->new('Testing Flickr::API');
$term->ornaments(0);

my $fileflag=0;
if (-r $config_file) { $fileflag = 1; }
is($fileflag, 1, "Is the config file: $config_file, readable?");

SKIP: {

    skip "Skipping authentication tests, oauth config isn't there or is not readable", 20
      if $fileflag == 0;

    $api = Flickr::API->import_storable_config($config_file);

    isa_ok($api, 'Flickr::API');
    is($api->is_oauth, 1, 'Does Flickr::API object identify as OAuth');

  SKIP: {

        skip "Skip request token and authentication tests, access token exists", 18
          if (defined($api->{oauth}->{token}) and $api->{oauth}->{token} =~ /^[0-9]+-[0-9a-f]+$/);

        like($api->{oauth}->{consumer_key},  qr/[0-9a-f]+/i, "Did we get a consumer key from $config_file");
        like($api->{oauth}->{consumer_secret}, qr/[0-9a-f]+/i, "Did we get a consumer secret from $config_file");

        like($api->{oauth}->{request_token}->{token}, qr/^[0-9]+-[0-9a-f]+$/i,
             "Did we get a request_token token from $config_file");
        like($api->{oauth}->{request_token}->{token_secret}, qr/^[0-9a-f]+$/i,
             "Did we get a request_token token_secret from $config_file");

        my $proceed = 0;
        if ($api->{oauth}->{request_token}->{token} =~ m/^[0-9]+-[0-9a-f]+$/i and
            $api->{oauth}->{request_token}->{token_secret} =~ m/^[0-9a-f]+$/i) {

            $proceed = 1;

        }

      SKIP: {

            skip "Skipping authentication tests, oauth request token seems wrong", 14
              if $proceed == 0;


            my $which_rl = $term->ReadLine;

            if ($which_rl eq "Term::ReadLine::Perl" or $which_rl eq "Term::ReadLine::Perl5") {

                diag "\n\nTerm::ReadLine::Perl and Term::ReadLine::Perl5 may display prompts" .
                     "\nincorrectly. If this is the case for you, try adding \"PERL_RL=Stub\"" .
                     "\nto the environment variables passed in with make test\n\n";

            }

            my $uri = $api->oauth_authorize_uri({ 'perms' => $useperms });
            my $prompt = "\n\n$uri\n\n" .
              "Copy the above url to a browser, and authenticate with Flickr\n" .
              "Press [ENTER] once you get the redirect (or error): ";
            my $input = $term->readline($prompt);

            $prompt = "\n\nCopy the redirect URL from your browser and enter it\n" .
                "(or if there was an error just press [Enter]\n" .
                "\nURL Here: ";
            $input = $term->readline($prompt);

            chomp($input);

            my ($callback_returned,$token_received) = split(/\?/,$input);
            my (@parms) = split(/\&/,$token_received);

            like($callback_returned, qr/^$api->{oauth}->{callback}/i, "Was the redirect to the callback");

            my %request_token;
            foreach my $pair (@parms) {

                my ($key,$val) = split(/=/,$pair);

                $key =~ s/oauth_//;

                $request_token{$key}=$val;

            }

            like($request_token{token}, qr/^[0-9]+-[0-9a-f]+/i, "Is the returned token, token-shaped");
            like($request_token{verifier}, qr/^[0-9a-f]+/i, "Is the returned token verifier a hex number");

            my $access_req = $api->oauth_access_token(\%request_token);

            is($access_req, 'ok', "Did oauth_access_token complete successfully");

            isa_ok($api->{oauth}->{access_token}, 'Net::OAuth::AccessTokenResponse');
            my $access_token  = $api->{oauth}->{access_token}->token();
            my $access_secret = $api->{oauth}->{access_token}->token_secret();
            like($access_token,  qr/^[0-9]+-[0-9a-f]+/i, "Is the access token, token-shaped");
            like($access_secret, qr/^[0-9a-f]+/i,        "Is the access token secret a hex number");

          SKIP: {

                skip "Skipping save of access token bearing api because access token wasn't received", 7
                  if !$access_token;


                $fileflag=0;
                if (-w $config_file) { $fileflag = 1; }
                is($fileflag, 1, "Is the config file: $config_file, writeable?");

                $api->export_storable_config($config_file);

                $fileflag=0;
                if (-r $config_file) { $fileflag = 1; }
                is($fileflag, 1, "Is the config file: $config_file, readable?");

                my $api2 = Flickr::API->import_storable_config($config_file);

                isa_ok($api2, 'Flickr::API');

                is_deeply($api2->{oauth}->{access_token}, $api->{oauth}->{access_token},
                          "Did import_storable_config get back the access token we stored");

                isa_ok($api2->{oauth}->{access_token}, 'Net::OAuth::AccessTokenResponse');
                my $access_token2  = $api2->{oauth}->{access_token}->token();
                my $access_secret2 = $api2->{oauth}->{access_token}->token_secret();
                like($access_token2,  qr/^[0-9]+-[0-9a-f]+/i, "Is the access token, token-shaped");
                like($access_secret2, qr/^[0-9a-f]+/i,        "Is the access token secret a hex number");

            }
        }
    }
}


exit;


__END__

# Local Variables:
# mode: Perl
# End:
