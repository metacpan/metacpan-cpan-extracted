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
use Template::Resolver;
use Test::More tests => 21;

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

sub match {
    my ( $file, $footprintless, $coordinate, $action ) = @_;

    my $overlay = $footprintless->entities()->get_entity($coordinate);
    my $got_file = File::Spec->catdir( File::Spec->catdir( $overlay->{to_dir}, $file ) );
    ok( -f $got_file, "$action: $file is file" );

    my $original_content;
    my $original_file =
        File::Spec->catdir( File::Spec->catdir( $overlay->{template_dir}, $file ) );
    if ( -f $original_file ) {
        my @resolver_opts = ();
        if ( $overlay->{os} ) {
            push( @resolver_opts, os => $overlay->{os} );
        }
        my $resolver_spec =
              $overlay->{resolver_coordinate}
            ? $footprintless->entities()->get_entity( $overlay->{resolver_coordinate} )
            : $overlay;

        $original_content = Template::Resolver->new( $resolver_spec, @resolver_opts )->resolve(
            content => slurp($original_file),
            key     => $overlay->{key}
        );
    }
    else {
        $original_content = slurp( File::Spec->catdir( $overlay->{base_dir}, $file ) );
    }

    $logger->debugf( 'checking %s', $got_file );
    is( slurp($got_file), $original_content, "$action: $file matches expected" );
}

sub test_overlay {
    my ( $coordinate, $action, %options ) = @_;

    my $temp_dir = File::Temp->newdir();
    my $overlay_dir = File::Spec->catdir( $temp_dir, 'overlay' );
    make_path($overlay_dir);

    my $footprintless = footprintless( $temp_dir, $overlay_dir );
    my $overlay = $footprintless->entities()->get_entity($coordinate);

    unless ( $overlay->{base_dir} eq File::Spec->catfile( $test_dir, 'data', 'base' )
        && $overlay->{template_dir} eq File::Spec->catfile( $test_dir, 'data', 'template' )
        && $overlay->{to_dir} =~ /^$overlay_dir/ )
    {
        ;
        $logger->errorf(
            "%s=[%s]\n%s=[%s]\n%s starts with [%s]", $overlay->{base_dir},
            File::Spec->catfile( $test_dir, 'data', 'base' ),     $overlay->{template_dir},
            File::Spec->catfile( $test_dir, 'data', 'template' ), $overlay->{to_dir},
            $overlay_dir
        );
        BAIL_OUT('environment configuration broken, could be dangerous to proceed...');
    }
    $logger->debug('environment looks good, proceed...');

    if ( $logger->is_trace ) {
        $logger->tracef( 'overlay: %s', Data::Dumper->new( [$overlay] )->Indent(1)->Dump() );
    }

    Footprintless::App::clear_pretend_self();
    my $result = test_app(
        'Footprintless::App' => [
            'overlay', $coordinate,
            $action, ( $options{command_args} ? @{ $options{command_args} } : () )
        ]
    );
    is( $result->exit_code(), 0, "overlay completed succesfully" );
    if ( $logger->is_debug() ) {
        $logger->debugf(
            "exit_code=[%s],error=[%s]\n----- STDOUT ----\n%s\n---- STDERR ----\n%s\n---- END ----",
            $result->exit_code(), $result->error(), $result->stdout(), $result->stderr()
        );
    }

    &{ $options{validator} }($footprintless) if ( $options{validator} );
}

my $coordinate = 'dev.foo.overlay';
test_overlay(
    $coordinate,
    'update',
    validator => sub {
        my ($footprintless) = @_;
        match( 'bin/catalina.sh',         $footprintless, $coordinate, 'update' );
        match( 'bin/setenv.sh',           $footprintless, $coordinate, 'update' );
        match( 'conf/jndi-resources.xml', $footprintless, $coordinate, 'update' );
        match( 'conf/server.xml',         $footprintless, $coordinate, 'update' );
    }
);

test_overlay(
    $coordinate,
    'initialize',
    validator => sub {
        my ($footprintless) = @_;

        match( 'bin/catalina.sh',          $footprintless, $coordinate, 'initialize' );
        match( 'bin/setenv.sh',            $footprintless, $coordinate, 'initialize' );
        match( 'conf/jndi-resources.xml',  $footprintless, $coordinate, 'initialize' );
        match( 'conf/server.xml',          $footprintless, $coordinate, 'initialize' );
        match( 'conf/catalina.properties', $footprintless, $coordinate, 'initialize' );
    }
);
