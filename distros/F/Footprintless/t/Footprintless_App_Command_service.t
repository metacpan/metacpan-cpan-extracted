use strict;
use warnings;

use lib 't/lib';

use App::Cmd::Tester;
use Data::Dumper;
use Footprintless;
use Footprintless::Util qw(dumper slurp spurt);
use File::Basename;
use File::Path qw(make_path);
use File::Spec;
use File::Temp;
use Test::More tests => 6;

BEGIN { use_ok('Footprintless::App') }

eval {
    require Getopt::Long;
    Getopt::Long::Configure( 'pass_through', 'bundling' );
    my $level = 'error';
    Getopt::Long::GetOptions( 'log:s' => \$level );

    require Log::Any::Adapter;
    Log::Any::Adapter->set(
        '+Footprintless::Test::Log::Any::Adapter::Handle',
        handle    => \*STDERR,
        log_level => Log::Any::Adapter::Util::numeric_level($level)
    );
};

my $logger = Log::Any->get_logger();
$logger->trace("All logging sent to stderr to avoid conflict with output");

my $test_dir = dirname( File::Spec->rel2abs($0) );

sub footprintless {
    my ($temp_dir) = @_;

    my $entities_dir = File::Spec->catdir( $temp_dir, 'config', 'entities' );
    make_path($entities_dir);
    my $foo = File::Spec->catfile( $entities_dir, 'foo.pm' );
    spurt( <<"    FOO", $foo );
    return {
        bar => {
            service => {
                command => 'bar.sh'
            },
        },
        baz => {
            service => {
                command => 'baz.sh'
            },
        },
    }
    FOO
    my $fpl = File::Spec->catfile( $entities_dir, 'footprintless.pm' );
    spurt( <<"    FPL", $fpl );
    return {
        factory => 'Footprintless::EchoCommandRunnerTestFactory'
    }
    FPL

    # Get the current entities
    $ENV{FPL_CONFIG_DIRS} = File::Spec->catdir($entities_dir);
    delete( $ENV{FPL_CONFIG_PROPS} );

    return Footprintless->new();
}

my $temp_dir      = File::Temp->newdir();
my $footprintless = footprintless($temp_dir);
ok( $footprintless, 'footprintless' );
is( ref( $footprintless->command_runner() ),
    'Footprintless::CommandRunner::Echo',
    'mock command runner'
);
is( test_app( 'Footprintless::App' => [ 'service', 'foo.bar.service', 'start' ] )->stdout(),
    $footprintless->entities()->get_entity('foo.bar.service.command') . ' start',
    'start bar'
);
is( test_app( 'Footprintless::App' => [ 'service', 'foo.baz.service', 'start' ] )->stdout(),
    $footprintless->entities()->get_entity('foo.baz.service.command') . ' start',
    'start baz'
);
is( test_app(
        'Footprintless::App' => [ 'service', 'foo', 'start', 'bar.service', 'baz.service' ]
        )->stdout(),
    $footprintless->entities()->get_entity('foo.bar.service.command')
        . ' start'
        . $footprintless->entities()->get_entity('foo.baz.service.command')
        . ' start',
    'start bar and baz'
);
