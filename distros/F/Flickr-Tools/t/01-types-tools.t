use strict;
use warnings;
use Test::More  tests => 6;
use Test::TypeTiny;
use Types::Standard qw( HashRef );
use Flickr::API;
use Flickr::Types::Tools qw( FlickrAPI FlickrAPIargs HexNum );
use Type::Params qw(compile);
use 5.010;

my $config_file  = $ENV{MAKETEST_OAUTH_CFG} || '/no/file/by/this/name.is.there?';
my $config_ref;

my $api;

my $fileflag=0;
if (-r $config_file) { $fileflag = 1; }

SKIP: {

    skip "Skipping API types, oauth config isn't there or is not readable", 3
        if $fileflag == 0;

    $api = Flickr::API->import_storable_config($config_file);

    isa_ok($api, 'Flickr::API');

    is($api->is_oauth, 1, 'Does the Flickr::API object identify as OAuth');

    my $api2 = apicheck($api);
    sub apicheck {
        state $check = compile(FlickrAPI);
        my ($apis) = $check->(@_);
        return $apis;
    }

    is_deeply($api2, $api, 'Did the FlickrAPI type pass reasonable values');


}


my $arg1 = {
    'token_secret'    => 'cafe00123210beef',
    'consumer_key'    => 'ea7a7beefcafe0001112223334445556',
    'consumer_secret' => 'feef11f0e0001111',
    'token'           => '86753090008675309-bee1ca1f24004003',
};

my $arg2 = argcheck($arg1);
sub argcheck {
    state $check = compile(FlickrAPIargs);
    my ($args) = $check->(@_);
    return $args
}

is_deeply($arg2, $arg1, 'Did the FlickrAPIargs type pass reasonable values');


my $consumer_key = 'cafefeedbeef13579246801234567890';
my $consumer_oop = 'cafefeedbeef1_oh_no_3579246801234567890';

should_pass($consumer_key,  HexNum, 'check good consumer_key against HexNum');
should_fail($consumer_oop,  HexNum, 'check bad consumer_key against HexNum');


exit;

__END__


# Local Variables:
# mode: Perl
# End:
