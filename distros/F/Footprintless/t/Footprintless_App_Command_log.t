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
        logs => {
            bar => '$temp_dir/bar.log',
            baz => '$temp_dir/baz.log'
        }
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
is( test_app( 'Footprintless::App' => [ 'log', 'foo.logs.bar', 'cat' ] )->stdout(),
    "cat " . $footprintless->entities()->get_entity('foo.logs.bar'),
    'cat bar'
);
is( test_app( 'Footprintless::App' => [ 'log', 'foo.logs.bar', 'cat', '--arg', '-n' ] )->stdout(),
    "cat -n " . $footprintless->entities()->get_entity('foo.logs.bar'),
    'cat -n bar'
);
is( test_app( 'Footprintless::App' => [ 'log', 'foo.logs.bar', 'cat', '--arg', '-n -v' ] )
        ->stdout(),
    "cat -n -v " . $footprintless->entities()->get_entity('foo.logs.bar'),
    'cat -n -v bar'
);
is( test_app(
        'Footprintless::App' =>
            [ 'log', 'foo.logs.bar', 'grep', '--arg', '--color', '--arg', '"foo/bar"' ]
        )->stdout(),
    'grep --color "foo/bar" ' . $footprintless->entities()->get_entity('foo.logs.bar'),
    'grep color foobar'
);
