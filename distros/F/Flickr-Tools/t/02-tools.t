use strict;
use warnings;
use Test::More  tests => 32;
use Flickr::API;
use Flickr::Tools;
use Flickr::Roles::Permissions;
use 5.010;


my $config_file;

if (defined($ENV{MAKETEST_OAUTH_CFG}) && defined ($ENV{MAKETEST_VALUES})) {

    $config_file  = $ENV{MAKETEST_OAUTH_CFG};

}
else {

    diag( 'No MAKETEST_OAUTH_CFG or MAKETEST_VALUES, shallow tests only' );
    $config_file  =  '/no/file/by/this/name.is.there?';
}


my $config_ref;

my $api;
my $ref;
my $rsp;

eval {

    my $tool = Flickr::Tools->new(['123deadbeef456','MyUserName']);

};

isnt($@, undef, 'Did we fail to create object with bad args: Anon Array');


eval {

    my $tool = Flickr::Tools->new();

};

isnt($@, undef, 'Did we fail to create object with bad args: no args at all');

eval {

    my $tool = Flickr::Tools->new('/home/nobody/home/where/is/that_file.wrong');

};

isnt($@, undef, 'Did we fail to create object with bad args: file not there');

eval {

    my $tool = Flickr::Tools->new(
        { version  => '1.0',
          rest_uri => 'https://api.flickr.com/services/rest/',
      }
    );

};

isnt($@, undef, 'Did we fail to create object with bad args: no consumer_key');

my $tool = Flickr::Tools->new(
    { consumer_key    => '012345beefcafe543210',
      consumer_secret => 'a234b345c456feed',
  }
);

isa_ok($tool, 'Flickr::Tools');

is(
    $tool->_api_name,
    "Flickr::API",
    'Are we looking for the correct API'
);

is(
    $tool->consumer_key,
    '012345beefcafe543210',
    'Did we get back our test consumer_key'
);

is(
    $tool->consumer_secret,
    'a234b345c456feed',
    'Did we get back our test consumer_secret'
);

is(
    $tool->auth_uri,
    'https://api.flickr.com/services/oauth/authorize',
    'Did we get back the default oauth authorization uri'
);

is(
    $tool->request_method,
    'GET',
    'Did we get back the default request method'
);

is(
    $tool->rest_uri,
    'https://api.flickr.com/services/rest/',
    'Did we get back the default rest uri'
);

is(
    $tool->request_url,
    'https://api.flickr.com/services/rest/',
    'Did we get back the default request url'
);


is(
    $tool->signature_method,
    'HMAC-SHA1',
    'Did we get back the default oauth signature method'
);

is(
    $tool->unicode,
    0,
    'Did we get back the default unicode setting'
);

is(
    $tool->version,
    '1.0',
    'Did we get back the default api version in our tool'
);

is(
    $tool->has_api,
    '',
    'Are we appropriately missing a Flickr::API object'
);

$api = $tool->api;

isa_ok($api, $tool->_api_name);

is(
    $api->is_oauth,
    1,
    'Does Flickr::API object identify as OAuth'
);


$rsp =  $api->execute_method('flickr.test.echo', { 'foo' => 'barred' } );
$ref = $rsp->as_hash();


SKIP: {
    skip "skipping method call check, since we couldn't reach the API", 4
        if $rsp->rc() ne '200';
    is(
        $ref->{'stat'},
        undef,
        'Check for no status from flickr.test.echo'
    );
    is(
        $ref->{'foo'},
        undef,
        'Check for no result from flickr.test.echo'
    );
    is(
        $tool->connects,
        0,
        'Check that we cannot connect with invalid key'
    );
    is(
        $tool->permissions,
        'none',
        "Note that we have no permissions"
    );
}


undef $api;
undef $rsp;
undef $ref;
undef $tool;


my $fileflag=0;
if (-r $config_file) { $fileflag = 1; }

SKIP: {

    skip "Skipping tool api tests, oauth config isn't there or is not readable", 10 
        if $fileflag == 0;

    $tool = Flickr::Tools->new({config_file => $config_file, test_more_bait => "Find Me iF you can."});

    isa_ok($tool, 'Flickr::Tools');

    is(
        $tool->has_api,
        '',
        'We should not have an API object... yet'
    );

    $api = $tool->api;

    isa_ok($api, $tool->_api_name);

    is(
        $tool->connects,
        1,
        'Check if we can connect with a (we trust) valid key'
    );
    isnt(
        $tool->permissions,
        'none',
        'Check that we have some kind of permission'
    );

    my $user = $tool->user;

    like  ($user->{nsid},     qr/.+/, 'got some kind of nsid');
    like  ($user->{username}, qr/.+/, 'got some kind of username');
    like  ($user->{fullname}, qr/.+/, 'got some kind of fullname');

    $tool->_clear_api;

    my $toggle = 0;
    if ($tool->has_api) { $toggle = 1; }

    is($toggle, 0, 'did we clear the api out of the tool');

    $tool->_build_api;
    $toggle = 0;
    if ($tool->has_api) { $toggle = 1; }

    is($toggle, 1, 'did we build an api in the tool');

}


exit;

__END__


# Local Variables:
# mode: Perl
# End:
