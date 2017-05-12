use strict;
use warnings;
use Test::More;
use Flickr::API;
use Flickr::API::Upload;

if (defined($ENV{MAKETEST_OAUTH_CFG})) {

    plan( tests => 8 );
}
else {
    plan(skip_all => 'Upload tests require that MAKETEST_OAUTH_CFG points to a valid config, see README.');
}


my $config_file  = $ENV{MAKETEST_OAUTH_CFG};
my $config_ref;
my $test_image   = "t/10-upload.jpg";

my $api;

my $fileflag=0;
if (-r $config_file) { $fileflag = 1; }
is(
    $fileflag,
    1,
    "Is the config file: $config_file, readable?"
);


SKIP: {

    skip "Skipping upload tests, oauth config isn't there or is not readable", 7   ##############
        if $fileflag == 0;

    $api = Flickr::API->import_storable_config($config_file);

    isa_ok($api, 'Flickr::API');

    is(
        $api->is_oauth,
        1,
        'Does this Flickr::API object identify as OAuth'
    );

    is(
        $api->api_success,
        1,
        'Did api initialize successful'
    );

    my $apiperms = $api->api_permissions();
    my $imageflag=0;
    my $permsflag=0;

    if ($apiperms eq 'write' or $apiperms eq 'delete') { $permsflag=1; }
    is(
        $permsflag,
        1,
        "Do we have write or delete permissions"
    );

  SKIP: {
        skip "Skipping some upload tests, not enough permission to upload with the API", 3   ##########
            if $permsflag == 0;

        if (-r $test_image) { $imageflag = 1; }
        is(
            $imageflag,
            1,
            "Is the test image: $test_image, readable?"
        );

      SKIP: {
            skip "Skipping some upload tests, test image file isn't there or is not readable", 2   ##########
                if $imageflag == 0;

            my $sendargs  =  {
                'photo'       => $test_image,
                'tags'        => 'Perl,"Flickr::API"',
                'async'       => 0,
                'title'       => 'Perl Flickr::API test',
                'description' => 'Small test image for testing Flickr::API upload',
            };
            my $response = $api->upload($sendargs);
            my $apihash = $response->as_hash;

            is(
                $api->api_success,
                1,
                'Did upload record API success'
            );

            my $photoid = $apihash->{photoid};
            isnt(
                $photoid,
                undef,
                'Did we get a photoid'
            );

        } # image file

    } # perms

} # oauth config


exit;

__END__


# Local Variables:
# mode: Perl
# End:
