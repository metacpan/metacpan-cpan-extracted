use strict;
use warnings;

use lib 't/lib';

use File::Spec;
use File::Temp;
use Footprintless::Resource::UrlProvider;
use Footprintless::Test::Util qw(
    test_dir
);
use Footprintless::Util qw(
    slurp
);
use LWP::UserAgent;
use Test::More tests => 14;

BEGIN { use_ok('Footprintless::ResourceManager') }

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

sub factory {
    my ($providers) = @_;
    return Footprintless::Util::factory(
        {   footprintless =>
                { resource_manager => { ( $providers ? ( providers => $providers ) : () ) } }
        }
    );
}

my $lwp = LWP::UserAgent->new();
$lwp->env_proxy();

my $path = test_dir( 'config', 'properties.pl' );
my $url = "file://$path";

{
    $logger->info('invalid provider');
    eval { Footprintless::ResourceManager->new( factory( ['Foo'] ) ); };
    ok( $@, 'fails to load invalid provider' );
}

{
    $logger->info('default provider');
    my $manager = Footprintless::ResourceManager->new( factory() );
    is( $manager->resource($url)->get_url(), $url,         'default resolve' );
    is( slurp( $manager->download($url) ),   slurp($path), 'defaultdownload' );
}

{
    $logger->info('invalid provider');
    eval { Footprintless::ResourceManager->new( factory( ['Foo'] ) ); };
    ok( $@, 'fails to load invalid provider' );
}

{
    $logger->info('url provider');
    my $manager = Footprintless::ResourceManager->new(
        factory( ['Footprintless::Resource::UrlProvider'] ) );
    is( $manager->resource($url)->get_url(), $url,         'UrlProvider resolve' );
    is( slurp( $manager->download($url) ),   slurp($path), 'UrlProvider download' );

    my $http_url = "http://www.google.com/foo";
    is( $manager->resource($http_url)->get_url(), $http_url, 'UrlProvider resolve http' );
}

SKIP: {
    my $test_count = 6;
    my $coordinate = 'com.pastdev:foo:pom:1.0.1';

    eval { require Footprintless::Resource::MavenProvider; };
    skip( "unable to require MavenProvider: $@", $test_count ) if ($@);

    my $manager = Footprintless::ResourceManager->new(
        factory( ['Footprintless::Test::Resource::MavenProvider'] ) );

    my $expected_artifact;
    eval { $expected_artifact = $manager->resource($coordinate)->get_artifact(); };
    skip( 'maven environment not setup', $test_count ) if ($@);

    ok( $expected_artifact, 'MavenProvider resolve' );
    my $local_repo_artifact_path = test_dir(
        'data',       'maven', 'HOME',    'dot_m2',
        'repository', 'com',   'pastdev', 'foo',
        '1.0.1',      'foo-1.0.1.pom'
    );
    my $download_path = $manager->download($coordinate);
    ok( -f $download_path, 'file found in local repo' );
    is( slurp($download_path), slurp($local_repo_artifact_path), 'artifact download matches' );

    $manager = Footprintless::ResourceManager->new(
        factory(
            [   'Footprintless::Test::Resource::MavenProvider',
                'Footprintless::Resource::UrlProvider',
            ]
        )
    );
    is( $manager->resource($coordinate)->get_artifact(),
        $expected_artifact, 'both MavenProvider resolve' );
    is( $manager->resource($path)->get_url(), $url, 'both UrlProvider resolve path' );
    is( $manager->resource($url)->get_url(),  $url, 'both UrlProvider resolve url' );
}
