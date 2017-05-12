#!perl
use strict;
use warnings;
use File::Spec ();
use JSON::MaybeXS;
use Metabase::User::Profile ();
use Metabase::User::Secret  ();

use Test::More 0.88;

require_ok('Metabase::Client::Simple');

$Metabase::Client::Simple::VERSION ||= "0.123456"; # for prove in repo dir

my $ver = Metabase::Client::Simple->VERSION;

my $id_file = File::Spec->catfile(qw/t data id.json/);
my $guts    = do { local ( @ARGV, $/ ) = $id_file; <> };
my $id_pair = JSON()->new->decode($guts);

my $profile = Metabase::User::Profile->from_struct( $id_pair->[0] );
my $secret  = Metabase::User::Secret->from_struct( $id_pair->[1] );

my $args = {
    profile => $profile,
    secret  => $secret,
    uri     => 'http://metabase.example.com/',
};

my $client = new_ok( 'Metabase::Client::Simple', [$args] );

is(
    $client->_ua->agent,
    "Metabase::Client::Simple/$ver " . $client->_ua->_agent,
    "UA agent string set correctly"
);

#--------------------------------------------------------------------------#
# No trailing slash
#--------------------------------------------------------------------------#

$args->{uri} = 'http://metabase.example.com',
  $client = new_ok( 'Metabase::Client::Simple', [$args] );
is( $client->uri, 'http://metabase.example.com/', "Trailing slash added" );

#--------------------------------------------------------------------------#-
# Bad scheme
#--------------------------------------------------------------------------#

$args->{uri} = 'fake://metabase.example.com/';
eval { Metabase::Client::Simple->new($args) };
like( $@, qr/Scheme 'fake' is not supported/, "Bad scheme causes new() to die" );

done_testing;
