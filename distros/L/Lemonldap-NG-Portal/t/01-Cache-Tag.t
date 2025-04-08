use warnings;
use Test::More;
use strict;
use IO::String;
use MIME::Base64;
use URI;
use URI::QueryParam;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {}
    }
);

ok( my $tag = $client->p->cacheTag, "Asset tag is not null" );
is( length( $client->p->cacheTag ), 8, "Asset tag has expected length" );

$client->ini( {
        %{ $client->ini },
        cacheTagSalt         => "zzz",
        authChoiceModules    => { '1_demo' => 'Demo;Demo;Null' },
    }
);
isnt( $client->p->cacheTag, $tag, "Using a salt changes the tag" );

clean_sessions();

done_testing();
