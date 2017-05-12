use strict;
use warnings;

use lib 't/lib';

use Config::Entities;
use File::Basename;
use File::Path qw(make_path);
use File::Spec;
use File::Temp;
use Footprintless::CommandOptionsFactory;
use Footprintless::Localhost;
use Footprintless::Util qw(
    default_command_runner
    dumper
    factory
    slurp
    spurt
);
use Test::More tests => 55;

BEGIN { use_ok('Footprintless::Overlay') }

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

sub temp_dirs {
    File::Temp::cleanup();

    my $temp_dir     = File::Temp->newdir();
    my $base_dir     = File::Spec->catdir( $temp_dir, 'base' );
    my $to_dir       = File::Spec->catdir( $temp_dir, 'to' );
    my $template_dir = File::Spec->catdir( $temp_dir, 'template' );
    make_path( $base_dir, $to_dir, $template_dir );

    return $temp_dir, $base_dir, $to_dir, $template_dir;
}

{
    $logger->info('Verify initialize');
    my ( $temp_dir, $base_dir, $to_dir, $template_dir ) = temp_dirs();
    my $hostname = 'localhost';
    my $overlay  = Footprintless::Overlay->new(
        factory(
            {   system => {
                    hostname => $hostname,
                    app      => {
                        'Config::Entities::inherit' => ['hostname'],
                        overlay                     => {
                            'Config::Entities::inherit' => [ 'hostname', 'sudo_username' ],
                            base_dir                    => $base_dir,
                            clean                       => ["$to_dir/"],
                            key                         => 'T',
                            os                          => $^O,
                            resolver_coordinate         => 'system',
                            template_dir                => $template_dir,
                            to_dir                      => $to_dir
                        }
                    }
                }
            }
        ),
        'system.app.overlay'
    );
    ok( $overlay, 'overlay constructed' );

    my $name          = 'foo';
    my $template_file = File::Spec->catfile( $template_dir, $name );
    my $to_file       = File::Spec->catfile( $to_dir, $name );
    spurt( 'hostname=[${T{app.hostname}}]', $template_file );
    my $base_template_file = File::Spec->catfile( $base_dir, $name );
    spurt( 'i should be overlayed', $base_template_file );
    my $base_name = 'bar';
    my $base_file = File::Spec->catfile( $base_dir, $base_name );
    spurt( 'bar', $base_file );
    $overlay->initialize();
    is( slurp($to_file), "hostname=[$hostname]", 'initialize template' );
    is( slurp($base_file), "bar", 'initialize base' );
}

{
    $logger->info('Verify update');
    my ( $temp_dir, $base_dir, $to_dir, $template_dir ) = temp_dirs();
    my $hostname = 'localhost';
    my $overlay  = Footprintless::Overlay->new(
        factory(
            {   system => {
                    hostname => $hostname,
                    app      => {
                        'Config::Entities::inherit' => ['hostname'],
                        overlay                     => {
                            'Config::Entities::inherit' => [ 'hostname', 'sudo_username' ],
                            base_dir                    => $base_dir,
                            clean                       => ["$to_dir/"],
                            key                         => 'T',
                            os                          => $^O,
                            resolver_coordinate         => 'system',
                            template_dir                => $template_dir,
                            to_dir                      => $to_dir
                        }
                    }
                }
            }
        ),
        'system.app.overlay'
    );
    ok( $overlay, 'overlay constructed' );

    my $name          = 'foo';
    my $template_file = File::Spec->catfile( $template_dir, $name );
    my $to_file       = File::Spec->catfile( $to_dir, $name );
    spurt( 'hostname=[${T{app.hostname}}]', $template_file );
    $overlay->update();
    is( slurp($to_file), "hostname=[$hostname]", 'update' );
}

{
    $logger->info('Verify clean');
    my ( $temp_dir, $base_dir, $to_dir, $template_dir ) = temp_dirs();
    my $overlay = Footprintless::Overlay->new(
        factory(
            {   overlay => {
                    hostname            => 'localhost',
                    base_dir            => $base_dir,
                    clean               => ["$to_dir/"],
                    key                 => 'T',
                    os                  => $^O,
                    resolver_coordinate => 'system',
                    template_dir        => $template_dir,
                    to_dir              => $to_dir
                }
            }
        ),
        'overlay'
    );
    my $to_file = File::Spec->catfile( $to_dir, 'bar' );
    spurt( 'foo', $to_file );
    ok( -f $to_file, 'clean test to_file created' );
    $overlay->clean();
    ok( !-e $to_file, 'clean test' );
}

{
    $logger->info('Verify resolver factory');
    my ( $temp_dir, $base_dir, $to_dir, $template_dir ) = temp_dirs();
    my $hostname = 'localhost';
    my $overlay  = Footprintless::Overlay->new(
        factory(
            {   system => {
                    hostname => $hostname,
                    app      => {
                        'Config::Entities::inherit' => ['hostname'],
                        overlay                     => {
                            'Config::Entities::inherit' => [ 'hostname', 'sudo_username' ],
                            base_dir                    => $base_dir,
                            clean                       => ["$to_dir/"],
                            key                         => 'T',
                            os                          => $^O,
                            resolver_coordinate         => 'system',
                            template_dir                => $template_dir,
                            to_dir                      => $to_dir
                        },
                        web => {
                            'Config::Entities::inherit' => ['hostname'],
                            https                       => 1,
                            port                        => 8443,
                            context_path                => '/foo'
                        },
                    },
                },
                footprintless =>
                    { overlay => { resolver_factory => 'Footprintless::WebUrlResolverFactory' } }
            }
        ),
        'system.app.overlay'
    );
    ok( $overlay, 'overlay constructed with resolver factory' );

    my $name          = 'foo';
    my $template_file = File::Spec->catfile( $template_dir, $name );
    my $to_file       = File::Spec->catfile( $to_dir, $name );
    spurt( 'url=[${T_web_url{app.web}}]', $template_file );
    $overlay->update();
    is( slurp($to_file), "url=[https://$hostname:8443/foo]", 'update with resolver factory' );
}

{
    $logger->info('Verify resolve .footprintless placeholders');
    my ( $temp_dir, $base_dir, $to_dir, $template_dir ) = temp_dirs();
    my $hostname = 'localhost';

    my @downloads = ();
    {

        package Mock::ResourceManager;

        sub download {
            my ( $self, @args ) = @_;
            push( @downloads, \@args );
        }
    }

    my $overlay = Footprintless::Overlay->new(
        factory(
            {   system => {
                    hostname => $hostname,
                    app      => {
                        'Config::Entities::inherit' => ['hostname'],
                        overlay                     => {
                            'Config::Entities::inherit' => [ 'hostname', 'sudo_username' ],
                            base_dir                    => $base_dir,
                            clean                       => ["$to_dir/"],
                            key                         => 'T',
                            os                          => $^O,
                            resolver_coordinate         => 'system',
                            template_dir                => $template_dir,
                            to_dir                      => $to_dir
                        },
                        web => {
                            'Config::Entities::inherit' => ['hostname'],
                            https                       => 1,
                            port                        => 8443,
                            context_path                => '/foo'
                        },
                    },
                }
            },
            resource_manager => bless( {}, 'Mock::ResourceManager' )
        ),
        'system.app.overlay'
    );
    ok( $overlay, 'overlay constructed with mock resource manager' );

    my $dot_footprintless = File::Spec->catfile( $template_dir, '.footprintless' );
    spurt( 'return {clean => ["./"], resources => {foo => "bar"}};', $dot_footprintless );
    $overlay->initialize();
    is( @downloads == 1 && $downloads[0][0], 'bar', 'bar was downloaded by initialize' );

    my $baz = File::Spec->catfile( $to_dir, 'baz' );
    spurt( 'testing...', $baz );
    ok( -f $baz, 'baz is ready to be cleaned' );
    $overlay->update();
    ok( !-e $baz, 'clean worked' );
    is( @downloads == 2 && $downloads[1][0], 'bar', 'bar was downloaded by update' );
}

{
    $logger->info('Verify alternate to_dir');
    my ( $temp_dir, $base_dir, $to_dir, $template_dir ) = temp_dirs();
    my $alternate_to_dir = File::Spec->catdir( $temp_dir, 'alternate' );
    make_path($alternate_to_dir);

    my $hostname = 'localhost';
    my $overlay  = Footprintless::Overlay->new(
        factory(
            {   system => {
                    hostname => $hostname,
                    app      => {
                        'Config::Entities::inherit' => ['hostname'],
                        overlay                     => {
                            'Config::Entities::inherit' => [ 'hostname', 'sudo_username' ],
                            base_dir                    => $base_dir,
                            clean                       => ["$to_dir/"],
                            key                         => 'T',
                            os                          => $^O,
                            resolver_coordinate         => 'system',
                            template_dir                => $template_dir,
                            to_dir                      => $to_dir
                        }
                    }
                }
            }
        ),
        'system.app.overlay'
    );
    ok( $overlay, 'overlay constructed' );

    my $name              = 'foo';
    my $template_file     = File::Spec->catfile( $template_dir, $name );
    my $to_file           = File::Spec->catfile( $to_dir, $name );
    my $alternate_to_file = File::Spec->catfile( $alternate_to_dir, $name );
    spurt( 'hostname=[${T{app.hostname}}]', $template_file );
    my $base_template_file = File::Spec->catfile( $base_dir, $name );
    spurt( 'i should be overlayed', $base_template_file );
    my $base_name = 'bar';
    my $base_file = File::Spec->catfile( $base_dir, $base_name );
    spurt( 'bar', $base_file );

    $overlay->initialize( to_dir => $alternate_to_dir );
    ok( !-e $to_file, 'configured initialize template does not exist' );
    is( slurp($alternate_to_file), "hostname=[$hostname]", 'alternate initialize template' );
    is( slurp($base_file), "bar", 'configured initialize base' );

    unlink($alternate_to_file);
    ok( !-e $alternate_to_file, 'alternate_to_file deleted' );

    $overlay->update( to_dir => $alternate_to_dir );
    ok( !-e $to_file, 'configured update template does not exist' );
    is( slurp($alternate_to_file), "hostname=[$hostname]", 'alternate update' );
}

SKIP: {
    $logger->info('Verify non-local');
    my $command_runner = default_command_runner();
    eval {
        $command_runner->run_or_die( 'ssh -q -o "StrictHostKeyChecking=yes" localhost echo hello',
            { timeout => 2 } );
    };
    if ($@) {
        skip( "cannot ssh to localhost: $@", 3 );
    }

    my ( $temp_dir, $base_dir, $to_dir, $template_dir ) = temp_dirs();
    my $hostname = 'localhost';
    my $overlay  = Footprintless::Overlay->new(
        factory(
            {   system => {
                    hostname => $hostname,
                    app      => {
                        'Config::Entities::inherit' => ['hostname'],
                        overlay                     => {
                            'Config::Entities::inherit' => [ 'hostname', 'sudo_username' ],
                            base_dir                    => $base_dir,
                            clean                       => ["$to_dir/"],
                            key                         => 'T',
                            os                          => $^O,
                            resolver_coordinate         => 'system',
                            template_dir                => $template_dir,
                            to_dir                      => $to_dir
                        }
                    }
                }
            }
        ),
        'system.app.overlay',
        localhost => Footprintless::Localhost->new( none => 1 )
    );
    ok( $overlay, 'overlay constructed' );

    my $name          = 'foo';
    my $template_file = File::Spec->catfile( $template_dir, $name );
    my $to_file       = File::Spec->catfile( $to_dir, $name );
    spurt( 'hostname=[${T{app.hostname}}]', $template_file );
    my $base_template_file = File::Spec->catfile( $base_dir, $name );
    spurt( 'i should be overlayed', $base_template_file );
    my $base_name = 'bar';
    my $base_file = File::Spec->catfile( $base_dir, $base_name );
    spurt( 'bar', $base_file );
    $overlay->initialize();
    is( slurp($to_file), "hostname=[$hostname]", 'non-local initialize template' );
    is( slurp($base_file), "bar", 'non-local initialize base' );
}

SKIP: {
    $logger->info('Verify resource overlay');
    my ( $temp_dir, $base_dir, $to_dir, $template_dir ) = temp_dirs();
    my $hostname = 'localhost';

    my $overlay = Footprintless::Overlay->new(
        factory(
            {   system => {
                    hostname => $hostname,
                    app      => {
                        'Config::Entities::inherit' => ['hostname'],
                        overlay                     => {
                            'Config::Entities::inherit' => [ 'hostname', 'sudo_username' ],
                            base_dir                    => 'base',
                            clean                       => ["$to_dir/"],
                            key                         => 'T',
                            os                          => $^O,
                            resource                    => File::Spec->catfile(
                                $test_dir, 'data', 'resources', 'overlay.zip'
                            ),
                            resolver_coordinate => 'system',
                            template_dir        => 'template/first',
                            to_dir              => $to_dir
                        },
                    },
                }
            }
        ),
        'system.app.overlay'
    );
    ok( $overlay, 'resource overlay constructed' );

    $overlay->initialize();
    my $foo_file = File::Spec->catfile( $to_dir, 'foo.txt' );
    my $bar_file = File::Spec->catfile( $to_dir, 'bar.txt' );
    my $baz_file = File::Spec->catfile( $to_dir, 'baz.txt' );
    ok( -f $foo_file, 'resource overlay initialize foo exists' );
    is( slurp($foo_file), "hostname=[foo]\n", 'resource overlay initialize foo matches' );
    ok( -f $bar_file, 'resource overlay initialize bar exists' );
    is( slurp($bar_file),
        "first.bar.hostname=[$hostname]\n",
        'resource overlay initialize bar matches'
    );
    ok( -f $baz_file, 'resource overlay initialize baz exists' );
    is( slurp($baz_file),
        "first.baz.hostname=[$hostname]\n",
        'resource overlay initialize baz matches'
    );

    $overlay->clean();
    ok( !( -e $foo_file ), 'resource overlay clean foo' );
    ok( !( -e $bar_file ), 'resource overlay clean bar' );
    ok( !( -e $baz_file ), 'resource overlay clean baz' );

    $overlay->update();
    ok( !( -e $foo_file ), 'resource overlay update foo missing' );
    ok( -f $bar_file,      'resource overlay update bar exists' );
    is( slurp($bar_file),
        "first.bar.hostname=[$hostname]\n",
        'resource overlay update bar matches'
    );
    ok( -f $baz_file, 'resource overlay update baz exists' );
    is( slurp($baz_file),
        "first.baz.hostname=[$hostname]\n",
        'resource overlay update baz matches'
    );
}

SKIP: {
    $logger->info('Verify multi-template resource overlay');
    my ( $temp_dir, $base_dir, $to_dir, $template_dir ) = temp_dirs();
    my $hostname = 'localhost';

    my $overlay = Footprintless::Overlay->new(
        factory(
            {   system => {
                    hostname => $hostname,
                    app      => {
                        'Config::Entities::inherit' => ['hostname'],
                        overlay                     => {
                            'Config::Entities::inherit' => [ 'hostname', 'sudo_username' ],
                            base_dir                    => 'base',
                            clean                       => ["$to_dir/"],
                            key                         => 'T',
                            os                          => $^O,
                            resource                    => File::Spec->catfile(
                                $test_dir, 'data', 'resources', 'overlay.zip'
                            ),
                            resolver_coordinate => 'system',
                            template_dir        => [ 'template/first', 'template/second', ],
                            to_dir              => $to_dir
                        },
                    },
                }
            }
        ),
        'system.app.overlay'
    );
    ok( $overlay, 'multi-template resource overlay constructed' );

    $overlay->initialize();
    my $foo_file = File::Spec->catfile( $to_dir, 'foo.txt' );
    my $bar_file = File::Spec->catfile( $to_dir, 'bar.txt' );
    my $baz_file = File::Spec->catfile( $to_dir, 'baz.txt' );
    ok( -f $foo_file, 'multi-template resource overlay initialize foo exists' );
    is( slurp($foo_file), "hostname=[foo]\n",
        'multi-template resource overlay initialize foo matches' );
    ok( -f $bar_file, 'multi-template resource overlay initialize bar exists' );
    is( slurp($bar_file),
        "second.bar.hostname=[$hostname]\n",
        'multi-template resource overlay initialize bar matches'
    );
    ok( -f $baz_file, 'multi-template resource overlay initialize baz exists' );
    is( slurp($baz_file),
        "first.baz.hostname=[$hostname]\n",
        'multi-template resource overlay initialize baz matches'
    );

    $overlay->clean();
    ok( !( -e $foo_file ), 'multi-template resource overlay clean foo' );
    ok( !( -e $bar_file ), 'multi-template resource overlay clean bar' );
    ok( !( -e $baz_file ), 'multi-template resource overlay clean baz' );

    $overlay->update();
    ok( !( -e $foo_file ), 'multi-template resource overlay update foo missing' );
    ok( -f $bar_file,      'multi-template resource overlay update bar exists' );
    is( slurp($bar_file),
        "second.bar.hostname=[$hostname]\n",
        'multi-template resource overlay update bar matches'
    );
    ok( -f $baz_file, 'multi-template resource overlay update baz exists' );
    is( slurp($baz_file),
        "first.baz.hostname=[$hostname]\n",
        'multi-template resource overlay update baz matches'
    );
}
