use strict;
use warnings;

package Footprintless;
$Footprintless::VERSION = '1.29';
# ABSTRACT: A utility for managing systems with minimal installs
# PODNAME: Footprintless

use Carp;
use Config::Entities;
use Footprintless::Util qw(factory);
use Log::Any;

our $AUTOLOAD;

my $logger = Log::Any->get_logger();

sub new {
    return bless( {}, shift )->_init(@_);
}

sub agent {
    my ( $self, @options ) = @_;
    $self->{factory}->agent(@options);
}

sub AUTOLOAD {
    my ( $self, @args ) = @_;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    $self->{factory}->$method(@args) if ( $self->{factory} );
}

sub command_options_factory {
    my ( $self, @args ) = @_;
    $self->{factory}->command_options_factory(@args);
}

sub command_runner {
    my ( $self, @args ) = @_;
    $self->{factory}->command_runner(@args);
}

sub deployment {
    my ( $self, @args ) = @_;
    $self->{factory}->deployment(@args);
}

sub entities {
    my ( $self, @args ) = @_;
    $self->{factory}->entities(@args);
}

sub _init {
    my ( $self, %options ) = @_;

    $logger->debugf( 'creating new Footprintless: %s', \%options );

    if ( $options{factory} ) {
        $self->{factory} = $options{factory};
    }
    else {
        my $entities;
        if ( $options{entities} ) {
            if ( ref( $options{entities} ) eq 'HASH' ) {
                $entities = Config::Entities->new( { entity => $options{entities} } );
            }
            elsif ( $options{entities}->isa('Config::Entities') ) {
                $entities = $options{entities};
            }
            else {
                croak('illegal entities, must be hashref, or Config::Entities');
            }
        }
        else {
            my $fpl_home;
            if ( $options{fpl_home} ) {
                $fpl_home = $options{fpl_home};
            }
            elsif ( $ENV{FPL_HOME} ) {
                $fpl_home = $ENV{FPL_HOME};
            }
            else {
                $fpl_home = File::Spec->catdir( $ENV{HOME}, '.footprintless' );
            }

            my @config_dirs = ();
            if ( $options{config_dirs} ) {
                @config_dirs =
                    ref( $options{config_dirs} ) eq 'ARRAY'
                    ? @{ $options{config_dirs} }
                    : ( $options{config_dirs} );
            }
            elsif ( $ENV{FPL_CONFIG_DIRS} ) {
                @config_dirs = _split_dirs( $ENV{FPL_CONFIG_DIRS} );
            }
            else {
                my $default = File::Spec->catdir( $fpl_home, 'config' );
                if ( -d $default ) {
                    @config_dirs = ($default);
                }
            }

            my @config_options = ();
            if ( $options{config_properties} ) {
                push( @config_options, properties_file => $options{config_properties} );
            }
            elsif ( $ENV{FPL_CONFIG_PROPS} ) {
                my @properties = _split_dirs( $ENV{FPL_CONFIG_PROPS} );
                push( @config_options, properties_file => \@properties );
            }
            else {
                my $default = File::Spec->catdir( $fpl_home, 'properties.pl' );
                if ( -f $default ) {
                    push( @config_options, properties_file => $default );
                }
            }

            $logger->tracef(
                "constructing entities with\n\tconfig_dirs: %s\n\tconfig_options: %s)",
                \@config_dirs, {@config_options} );
            $entities = Config::Entities->new( @config_dirs, {@config_options} );
        }

        $self->{factory} = factory($entities);
    }

    return $self;
}

sub localhost {
    my ( $self, @args ) = @_;
    $self->{factory}->localhost(@args);
}

sub log {
    my ( $self, @args ) = @_;
    $self->{factory}->log(@args);
}

sub plugins {
    my ($self) = @_;
    $self->{factory}->plugins();
}

sub overlay {
    my ( $self, @args ) = @_;
    $self->{factory}->overlay(@args);
}

sub resource_manager {
    my ( $self, @args ) = @_;
    $self->{factory}->resource_manager(@args);
}

sub service {
    my ( $self, @args ) = @_;
    $self->{factory}->service(@args);
}

sub tunnel {
    my ( $self, @args ) = @_;
    $self->{factory}->tunnel(@args);
}

sub _split_dirs {
    my ($dirs_string) = @_;

    my @dirs = ();
    my $separator = ( $^O eq 'MSWin32' ) ? ';' : ':';
    foreach my $dir ( split( /$separator/, $dirs_string ) ) {
        $dir =~ s/^\s+//;
        $dir =~ s/\s+$//;
        push( @dirs, $dir );
    }

    return @dirs;
}

1;

__END__

=pod

=head1 NAME

Footprintless - A utility for managing systems with minimal installs

=head1 VERSION

version 1.29

=head1 SYNOPSIS

    use Footprintless;

    my $footprintless = Footprintless->new();

    # Deploy initialize, start, and follow the log of the foo
    $footprintless->overlay('dev.foo.overlay')->initialize();
    $footprintless->service('dev.foo.service')->start();
    $footprintless->log('dev.foo.logs.app')->follow();

=head1 DESCRIPTION

Footprintless is an automation framework with an application frontend for
managing diverse software stacks in a consistent fashion.  It provides a
minimally invasive approach to configuration management.  At its core, 
L<Config::Entities> are used to define the whole
L<system|https://en.wikipedia.org/wiki/System>.  Once defined, the
entities are used by all of the Footprintless modules to decouple the 
environment from the action.  The environment is defined by the 
entities used to create 
L<command options|Footprintless::CommandOptionsFactory>.  Specifically:

    hostname
    ssh
    sudo_username
    username

Each module will have its own entities structure, see them for more 
details.

=head1 ENTITIES

An example system my consist of multiple environments, each defined
in their own file:

    ./fooptintless
                  /entities
                           /foo
                               /dev.pm
                               /qa.pm
                               /prod.pm

Each one of them would likely be rather similar, perhaps a variation of:

    return {
        app => {
            deployment => {
                'Config::Entities::inherit' => ['hostname', 'sudo_username'],
                clean => [
                    '/opt/foo/tomcat/conf/Catalina/localhost/',
                    '/opt/foo/tomcat/temp/',
                    '/opt/foo/tomcat/webapps/',
                    '/opt/foo/tomcat/work/'
                ],
                resources => {
                    bar => 'com.pastdev:bar:war:1.0',
                    baz => 'com.pastdev:baz:war:1.0'
                },
                to_dir => '/opt/foo/tomcat/webapps'
            },
            hostname => 'app.pastdev.com',
            logs => {
                catalina => '/opt/foo/tomcat/logs/catalina.out'
            },
            overlay => {
                'Config::Entities::inherit' => ['hostname', 'sudo_username'],
                base_dir => '/home/me/git/foo/base',
                clean => [
                    '/opt/foo/tomcat/'
                ],
                deployment_coordinate => 'foo.dev.app.deployment',
                key => 'T',
                os => 'linux',
                resolver_coordinate => 'foo.dev',
                template_dir => '/home/me/git/foo/template',
                to_dir => '/opt/foo/tomcat'
            },
            sudo_username => 'tomcat',
            tomcat => {
                'Config::Entities::inherit' => ['hostname', 'sudo_username'],
                catalina_base => '/opt/foo/tomcat',
                http => {
                    port => 20080
                },
                service => {
                    'Config::Entities::inherit' => ['hostname', 'sudo_username'],
                    action => {
                        'kill' => { command_args => 'stop -force' },
                        'status' => { use_pid => 1 }
                    },
                    command => '/opt/foo/tomcat/bin/catalina.sh',
                    pid_file => '/opt/foo/tomcat/bin/.catalina.pid',
                },
                shutdown => {
                    port => 20005,
                    password => $properties->{'foo.dev.app.tomcat.shutdown.password'},
                },
                trust_store => {
                    'Config::Entities::inherit' => ['hostname', 'sudo_username'],
                    file => '/opt/foo/tomcat/certs/truststore.jks',
                    include_java_home_cacerts => 1,
                    password => $properties->{'foo.dev.app.tomcat.trust_store.password'},
                }
            }
        }
        web => {
            hostname => 'web.pastdev.com',
            logs => {
                error => '/var/log/httpd/error_log',
                access => '/var/log/httpd/access_log'
            }
            sudo_username => 'apache'
        }
    }

Then when you decide to perform an action, the environment is just part
of the coordinate:

    fpl log foo.dev.app.tomcat.logs.catalina follow

    fpl service foo.qa.app.tomcat.service status

    fpl deployment foo.prod.app.deployment deploy --clean

If using the framework instead, the story is the same:

    my $permission_denied = Footprintless->new()
        ->log('foo.prod.web.logs.error')
        ->grep(options => 'Permission denied');

=head1 CONSTRUCTORS

=head2 new(\%entity, %options)

Creates a new Footprintless factory.  Available options are:

=over 4

=item config_dirs

The root folder(s) for configuration entities.  Defaults to the 
C<$FPL_CONFIG_DIRS> environment variable if set, C<$FPL_HOME/config> if not.
C<config_dirs> can be a scalar (one directory), or an array ref if there
is more than one directory.  If set via the C<$FPL_CONFIG_DIRS> environment
variable, and you need more than one directory, use a C<;> to delimit on
windows, or a C<:> to delimit on *nix (same as the C<$PATH> variable).

=item config_properties

The properties file(s) used for placeholder replacement for configuration 
entities.  Defaults to the C<$FPL_CONFIG_PROPS> environment variable if set, 
C<$FPL_HOME/properties.pl> if not.  C<config_properties> can be a scalar 
(one file), or an array ref if there is more than one directory.  If set via 
the C<$FPL_CONFIG_PROPS> environment variable, and you need more than one 
directory, use a C<;> to delimit on windows, or a C<:> to delimit on *nix 
(same as the C<$PATH> variable).

=item command_options_factory

Sets the C<command_options_factory> for this instance.  Must be an instance
or subclass of C<Footprintless::CommandOptionsFactory>.

=item command_runner

Sets the C<command_runner> for this instance.  Must be an a subclass of
C<Footprintless::CommandRunner>.

=item entities

If supplied, C<entities> will serve as the configuration for this instance.
All other configuration sources will be ignored.  Must be either a hashref, 
or an instance of L<Config::Entities>.

=item fpl_home

The root folder for footprintless configuration.  Defaults to the
C<$FPL_HOME> environment variable if set, C<~/.footprintless> if not.

=item localhost

Sets the C<localhost> resolver for this instance.  Must be an instance
or subclass of C<Footprintless::Localhost>.

=back

=head1 METHODS

=head2 agent(%options)

Returns a new L<agent|LWP::UserAgent> obtained from C<agent> in
L<Footprintless::Util>. The supported options are:

=over 4

=item cookie_jar

A hashref for storing cookies.  If not supplied, cookies will be ignored.

=item timeout

The http request timeout.

=back

=head2 command_options_factory()

Returns the 
L<command_options_factory|Footprintless::CommandOptionsFactory> used by 
this instance.

=head2 command_runner()

Returns the L<command_runner|Footprintless::CommandRunner> used by 
this instance.

=head2 deployment($coordinate, %options)

Returns a new instance of L<Footprintless::Deployment> preconfigured to
operate on the deployment at C<$coordinate>.  Supported options are

=over 4

=item command_options_factory

A C<command_options_factory> to use instead of that which is supplied by
this footprintless instance.

=item command_runner

A C<command_runner> to use instead of that which is supplied by
this footprintless instance.

=item localhost

A C<localhost> to use instead of that which is supplied by
this footprintless instance.

=item resource_manager

A C<resource_manager> to use instead of that which is supplied by
this footprintless instance.

=back

=head2 entities()

Returns the L<Config::Entities> that were resolved by this footprintless
instance.

=head2 localhost()

Returns the L<localhost|Footprintless::Localhost> resolver used by 
this instance.

=head2 log($coordinate, %options)

Returns a new instance of L<Footprintless::Log> preconfigured to
operate on the log at C<$coordinate>.  Supported options are

=over 4

=item command_options_factory

A C<command_options_factory> to use instead of that which is supplied by
this footprintless instance.

=item command_runner

A C<command_runner> to use instead of that which is supplied by
this footprintless instance.

=item localhost

A C<localhost> to use instead of that which is supplied by
this footprintless instance.

=back

=head2 overlay($coordinate, %options)

Returns a new instance of L<Footprintless::Overlay> preconfigured to
operate on the overlay at C<$coordinate>.  Supported options are

=over 4

=item command_options_factory

A C<command_options_factory> to use instead of that which is supplied by
this footprintless instance.

=item command_runner

A C<command_runner> to use instead of that which is supplied by
this footprintless instance.

=item localhost

A C<localhost> to use instead of that which is supplied by
this footprintless instance.

=item resource_manager

A C<resource_manager> to use instead of that which is supplied by
this footprintless instance.

=back

=head2 plugins()

Returns the registered plugins for this instance.

=head2 resource_manager()

Returns the L<resource_manager|Footprintless::ResourceManager> used by 
this instance.

=head2 service($coordinate, %options)

Returns a new instance of L<Footprintless::Service> preconfigured to
operate on the service at C<$coordinate>.  Supported options are

=over 4

=item command_options_factory

A C<command_options_factory> to use instead of that which is supplied by
this footprintless instance.

=item command_runner

A C<command_runner> to use instead of that which is supplied by
this footprintless instance.

=item localhost

A C<localhost> to use instead of that which is supplied by
this footprintless instance.

=back

=head2 tunnel($coordinate, %options)

Returns a new instance of L<Footprintless::Tunnel> preconfigured 
for C<$coordinate>. 

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless::Deployment|Footprintless::Deployment>

=item *

L<Footprintless::Log|Footprintless::Log>

=item *

L<Footprintless::Overlay|Footprintless::Overlay>

=item *

L<Footprintless::Service|Footprintless::Service>

=item *

L<https://github.com/lucastheisen/footprintless|https://github.com/lucastheisen/footprintless>

=back

=cut
