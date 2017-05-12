use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 5;
use File::Basename;
use File::Spec;

BEGIN { use_ok('Footprintless::Plugin::Atlassian::Confluence::RequestBuilder') }

eval {
    require Getopt::Long;
    Getopt::Long::Configure( 'pass_through', 'bundling' );
    my $level = 'error';
    Getopt::Long::GetOptions( 'log:s' => \$level );

    require Log::Any::Adapter;
    Log::Any::Adapter->set( 'Stdout',
        log_level => Log::Any::Adapter::Util::numeric_level($level) );
};

my $logger = Log::Any->get_logger();

my $test_dir = dirname( File::Spec->rel2abs($0) );

my $base_url = 'http://pastdev.com';
my $request_builder =
    Footprintless::Plugin::Atlassian::Confluence::RequestBuilder->new($base_url);

is( $request_builder->get_content( id => '1234' )->url(),
    "$base_url/rest/api/content/1234",
    'get_content id only'
);
is( $request_builder->get_content( id => '1234', expand => 'space,body.view,version,container' )
        ->url(),
    "$base_url/rest/api/content/1234?expand=space%2Cbody.view%2Cversion%2Ccontainer",
    'get_content id and expand'
);
is( $request_builder->get_content(
        expand => 'space,body.view,version,container',
        id     => '1234',
        status => 'any'
        )->url(),
    "$base_url/rest/api/content/1234?expand=space%2Cbody.view%2Cversion%2Ccontainer&status=any",
    'get_content id, expand and status'
);
is( $request_builder->get_content(
        expand   => 'space,body.view,version,container',
        spaceKey => 'Foo',
        title    => 'Bar'
        )->url(),
    "$base_url/rest/api/content?expand=space%2Cbody.view%2Cversion%2Ccontainer&spaceKey=Foo&title=Bar",
    'get_content spaceKey, title, and expand'
);
