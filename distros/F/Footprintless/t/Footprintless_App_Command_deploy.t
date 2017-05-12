use strict;
use warnings;

use lib 't/lib';

use App::Cmd::Tester;
use Data::Dumper;
use Footprintless;
use Footprintless::Util qw(
    dumper
    slurp
    spurt
);
use File::Basename;
use File::Path qw(make_path);
use File::Spec;
use File::Temp;
use Test::More tests => 7;

BEGIN { use_ok('Footprintless::App') }

eval {
    require Getopt::Long;
    Getopt::Long::Configure( 'pass_through', 'bundling' );
    my $level = 'error';
    Getopt::Long::GetOptions( 'log:s' => \$level );

    require Log::Any::Adapter;
    Log::Any::Adapter->set(
        '+Footprintless::Test::Log::Any::Adapter::Handle',
        handle    => \*STDOUT,
        log_level => Log::Any::Adapter::Util::numeric_level($level)
    );
};

my $logger = Log::Any->get_logger();
$logger->trace("All logging sent to stderr to avoid conflict with output");

my $test_dir = dirname( File::Spec->rel2abs($0) );

sub footprintless {
    my ( $temp_dir, $root_dir ) = @_;

    my $temp_config_dir = File::Spec->catdir( $temp_dir, 'config' );
    make_path($temp_config_dir);
    my $environment_dot_pl = File::Spec->catdir( $temp_config_dir, 'environment.pl' );
    spurt( <<"    EPL", $environment_dot_pl );
    return {
        'dev.foo.deployment.resources.dir' => '$test_dir/data/resources',
        'dev.foo.hostname' => 'localhost',
        'dev.foo.overlay.dir' => '$test_dir/data',
        'dev.foo.sudo_username' => undef,
        'dev.os' => '$^O',
        'dev.root.dir' => '$root_dir',
    }
    EPL

    # Get the current entities
    $ENV{FPL_CONFIG_DIRS} = File::Spec->catdir( $test_dir, 'config', 'entities' );
    $ENV{FPL_CONFIG_PROPS} =
          File::Spec->catfile( $test_dir, 'config', 'properties.pl' )
        . ( ( $^O eq 'MSWin32' ) ? ';' : ':' )
        . $environment_dot_pl;

    return Footprintless->new();
}

sub test_deployment {
    my ( $coordinate, $action, %options ) = @_;

    my $temp_dir = File::Temp->newdir();
    my $deployment_dir = File::Spec->catdir( $temp_dir, 'deployment' );
    make_path($deployment_dir);

    my $footprintless = footprintless( $temp_dir, $deployment_dir );
    &{ $options{before} }($footprintless) if ( $options{before} );

    my $deployment = $footprintless->entities()->get_entity($coordinate);
    $logger->trace( 'deployment ', dumper($deployment) ) if ( $logger->is_trace() );

    Footprintless::App::clear_pretend_self();
    my $result = test_app(
        'Footprintless::App' => [
            'deployment', $coordinate,
            $action, ( $options{command_args} ? @{ $options{command_args} } : () )
        ]
    );
    is( $result->exit_code(), 0, "deployment completed succesfully" );
    if ( $logger->is_debug() ) {
        $logger->debugf(
            "exit_code=[%s],error=[%s]\n----- STDOUT ----\n%s\n---- STDERR ----\n%s\n---- END ----",
            $result->exit_code(), $result->error(), $result->stdout(), $result->stderr()
        );
    }

    &{ $options{validator} }($footprintless) if ( $options{validator} );
}

my $coordinate = 'dev.foo.deployment';
test_deployment(
    $coordinate,
    'clean',
    before => sub {
        my ($footprintless) = @_;
        my $webapps_dir = $footprintless->entities()->get_entity("$coordinate.to_dir");
        make_path($webapps_dir);
        spurt( 'content', File::Spec->catfile( $webapps_dir, 'bar.war' ) );
    },
    validator => sub {
        my ($footprintless) = @_;
        my $webapps_dir = $footprintless->entities()->get_entity("$coordinate.to_dir");
        ok( -d $webapps_dir, 'cleaned webapps' );
        ok( !-f File::Spec->catfile( $webapps_dir, 'bar.war' ), 'cleaned bar.war' );
    }
);

test_deployment(
    $coordinate,
    'deploy',
    validator => sub {
        my ($footprintless) = @_;
        my $webapps_dir = $footprintless->entities()->get_entity("$coordinate.to_dir");
        ok( -f File::Spec->catfile( $webapps_dir, 'bar.war' ), 'deployed bar.war' );
        ok( -f File::Spec->catfile( $webapps_dir, 'baz.war' ), 'deployed baz.war' );
    }
);
