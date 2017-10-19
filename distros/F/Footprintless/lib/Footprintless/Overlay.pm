use strict;
use warnings;

package Footprintless::Overlay;
$Footprintless::Overlay::VERSION = '1.26';
# ABSTRACT: An overlay manager
# PODNAME: Footprintless::Overlay

use parent qw(Footprintless::MixableBase);

use Carp;
use Footprintless::Mixins qw (
    _clean
    _command_options
    _entity
    _extract_resource
    _local_template
    _push_to_destination
    _sub_coordinate
    _sub_entity
);
use Footprintless::Util qw(
    dynamic_module_new
    invalid_entity
    temp_dir
);
use Log::Any;
use File::Find;
use File::Spec;
use Template::Resolver;
use Template::Overlay;

my $logger = Log::Any->get_logger();

sub clean {
    my ($self) = @_;
    $self->_clean();
}

sub _dirs_template {
    my ( $self, $to_dir, $with_dirs_work ) = @_;

    my $base_dir     = $self->_sub_entity('base_dir');
    my $template_dir = $self->_sub_entity('template_dir');

    my $unpack_dir;
    my $resource = $self->_sub_entity('resource');
    if ($resource) {
        $unpack_dir = temp_dir();
        $self->_extract_resource( $resource, $unpack_dir );

        if ($base_dir) {
            $base_dir = File::Spec->catdir( $unpack_dir, $base_dir );
        }
        if ($template_dir) {
            $template_dir =
                ref($template_dir) eq 'ARRAY'
                ? [ map { File::Spec->catdir( $unpack_dir, $_ ) } @$template_dir ]
                : File::Spec->catdir( $unpack_dir, $template_dir );
        }
    }

    &$with_dirs_work( $base_dir, $template_dir, $to_dir );
}

sub _dot_footprintless_resolver {
    my ($self) = @_;
    return sub {
        my ( $template, $destination ) = @_;
        if ( $template =~ /\/\.footprintless$/ ) {
            $self->_resolve_footprintless( $template, $destination );
            return 1;
        }
        return 0;
    };
}

sub initialize {
    my ( $self, %options ) = @_;

    $self->clean();

    if ( $options{to_dir} ) {
        $self->_dirs_template(
            $options{to_dir},
            sub {
                $self->_initialize(@_);
            }
        );
    }
    else {
        $self->_local_with_dirs_template(
            sub {
                $self->_initialize(@_);
            }
        );
    }
}

sub _initialize {
    my ( $self, $base_dir, $template_dir, $to_dir ) = @_;
    $self->_overlay($base_dir)->overlay(
        $template_dir,
        resolver => $self->_dot_footprintless_resolver(),
        to       => $to_dir
    );
}

sub _local_with_dirs_template {
    my ( $self, $local_work ) = @_;
    $self->_local_template(
        sub {
            $self->_dirs_template( $_[0], $local_work );
        }
    );
}

sub _overlay {
    my ( $self, $base_dir ) = @_;

    my @overlay_opts = ();
    my $key          = $self->_sub_entity('key');
    push( @overlay_opts, key => $key ) if ($key);

    return Template::Overlay->new( $base_dir, $self->_resolver(), @overlay_opts );
}

sub _resolver {
    my ($self) = @_;

    my @resolver_opts = ();
    my $os            = $self->_sub_entity('os');
    push( @resolver_opts, os => $os ) if ($os);

    my $resolver_coordinate = $self->_sub_entity('resolver_coordinate');
    my $resolver_spec =
          $resolver_coordinate
        ? $self->_entity($resolver_coordinate)
        : $self->_entity();

    my $resolver;
    my $resolver_factory = $self->_entity('footprintless.overlay.resolver_factory');
    if ($resolver_factory) {
        $logger->tracef( "using resolver_factory: %s", $resolver_factory );
        $resolver =
            dynamic_module_new($resolver_factory)->new_resolver( $resolver_spec, @resolver_opts );
    }
    else {
        $resolver = Template::Resolver->new( $resolver_spec, @resolver_opts );
    }
    return $resolver;
}

sub _resolve_footprintless {
    my ( $self, $template, $footprintless_path ) = @_;
    my $destination = ( File::Spec->splitpath($footprintless_path) )[1];
    $logger->debugf( "resolving [%s]->[%s]", $template, $destination );

    my $spec = do($template) || return;
    croak("invalid $template") unless ( ref($spec) eq 'HASH' );

    if ( $spec->{clean} ) {
        my @to_be_cleaned =
            map { File::Spec->catdir( $destination, $_ ) . ( /\/$/ ? '/' : '' ); }
            ref( $spec->{clean} ) ? @{ $spec->{clean} } : ( $spec->{clean} );

        Footprintless::Util::clean(
            \@to_be_cleaned,
            command_runner  => $self->{factory}->command_runner(),
            command_options => $self->_command_options()
        );
    }

    if ( $spec->{resources} ) {
        my $resource_manager = $self->{factory}->resource_manager();
        foreach my $resource ( keys( %{ $spec->{resources} } ) ) {
            $resource_manager->download( $spec->{resources}{$resource}, to => $destination );
        }
    }
}

sub update {
    my ( $self, %options ) = @_;

    if ( $options{to_dir} ) {
        $self->_dirs_template(
            $options{to_dir},
            sub {
                $self->_update(@_);
            }
        );
    }
    else {
        $self->_local_with_dirs_template(
            sub {
                $self->_update(@_);
            }
        );
    }
}

sub _update {
    my ( $self, $base_dir, $template_dir, $to_dir ) = @_;
    $logger->tracef( "update to=[%s], template=[%s]", $to_dir, $template_dir );
    $self->_overlay($to_dir)
        ->overlay( $template_dir, resolver => $self->_dot_footprintless_resolver() );
}

1;

__END__

=pod

=head1 NAME

Footprintless::Overlay - An overlay manager

=head1 VERSION

version 1.26

=head1 SYNOPSIS

    # Standard way of getting an overlay
    use Footprintless;
    my $overlay = Footprintless->new()->overlay('overlay');

    $overlay->clean();

    $overlay->initialize();

    $overlay->update();

=head1 DESCRIPTION

Overlays are a combination of a directory of static files and a directory 
of templated files that will be merged to an output directory.  This
is implemented in L<Template::Overlay>.  

Additionally, any folder under the C<template_dir> can contain a 
C<.footprintless> file containing a C<clean> and/or C<resources> entities:

    return {
        clean => [
            'foo.jar',
            'bar.jar',
            'ext/'
        ],
        resources => {
            foo => 'com.pastdev:foo:1.0.0',
            bar => 'com.pastdev:bar:1.0.0'
        }
    };

The C<clean> entity is an arrayref containing a list of paths to clean out.
These paths will be added to the path of the directory containing the
C<.footprintless> file.  The C<resources> entity is a list of resources to
download into the same directory as the C<.footprintless> file.

=head1 ENTITIES

A simple overlay: 

    overlay => {
        base_dir => "/home/me/foo/base",
        clean => [
            "/opt/tomcat/"
        ],
        hostname => 'localhost',
        key => 'T',
        os => 'linux',
        template_dir => "/home/me/foo/template",
        to_dir => '/opt/foo/tomcat'
    }

A more complex example:

    foo => {
        hostname => 'test.pastdev.com',
        overlay => {
            'Config::Entities::inherit' => ['hostname', 'sudo_username'],
            base_dir => '/home/me/foo/base',
            clean => [
                '/opt/foo/tomcat/'
            ],
            key => 'T',
            os => 'linux',
            resolver_coordinate => 'foo',
            template_dir => '/home/me/foo/template',
            to_dir => '/opt/foo/tomcat'
        },
        sudo_username => 'developer',
        tomcat => {
            'Config::Entities::inherit' => ['hostname', 'sudo_username'],
            catalina_base => '/opt/foo/tomcat',
            http => {
                port => 20080
            },
            service => {
                action => {
                    'kill' => { command_args => 'stop -force' },
                    'status' => { use_pid => 1 }
                },
                command => '/opt/foo/tomcat/bin/catalina.sh',
                pid_file => '/opt/foo/tomcat/bin/.catalina.pid',
            },
            shutdown => {
                port => 8505,
                password => $properties->{'foo.tomcat.shutdown.password'},
            },
            trust_store => {
                'Config::Entities::inherit' => ['hostname', 'sudo_username'],
                file => '/opt/foo/tomcat/certs/truststore.jks',
                include_java_home_cacerts => 1,
                password => $properties->{'foo.tomcat.trust_store.password'},
            }
        }
    }

An overlay can obtain base/template content from a resource.  When
initialize or update are called, the resource will be downloaded (if not
already local) and extracted to a temp folder.  The C<base_dir> and
C<template_dir> paths will be appended to the extract temp folder:

    overlay => {
        base_dir => 'base',
        clean => [
            '/opt/tomcat/'
        ],
        hostname => 'localhost',
        key => 'T',
        os => 'linux',
        resource => 'com.pastdev:app-overlay:zip:package:1.0.0',
        template_dir => 'template',
        to_dir => '/opt/foo/tomcat'
    }

An overlay can have multiple template folders.  If it does, they will
be processed in the order they are listed:

    overlay => {
        base_dir => 'base',
        clean => [
            '/opt/tomcat/'
        ],
        hostname => 'localhost',
        key => 'T',
        os => 'linux',
        template_dir => [
            'first/template_dir',
            'second/template_dir',
        ],
        to_dir => '/opt/foo/tomcat'
    }

=head1 CONSTRUCTORS

=head2 new($entity, $coordinate)

Constructs a new overlay configured by C<$entities> at C<$coordinate>.  

=head1 METHODS

=head2 clean()

Cleans the overlay.  Each path in the C<clean> entity, will be removed 
from the destination.  If the path ends in a C</>, then after being 
removed, the directory will be recreated.

=head2 initialize()

Will call C<clean>, then C<overlay> on an instance of L<Template::Overlay>
configured to this entity.  

=head2 update()

Will overlay I<ONLY> the templated files.  It will not C<clean>, nor copy 
any files from C<base_dir> like C<initialize> does.

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

L<Footprintless|Footprintless>

=item *

L<Config::Entities|Config::Entities>

=item *

L<Footprintless|Footprintless>

=item *

L<Footprintless::Mixins|Footprintless::Mixins>

=item *

L<Template::Overlay|Template::Overlay>

=item *

L<Template::Resolver|Template::Resolver>

=back

=head1 CONFIGURATION

This module can optionally be configured to use a customized resolver.  To
do so, configure a resolver factory in your entities:

    footprintless => {
        overlay => {
            resolver_factory => 'My::ResolverFactory'
        }
    }

The resolver factory must have a C<new_resolver> method that takes a spec and
a list of options and returns a C<Template::Resolver>, for example:

    sub new_resolver {
        my ($self, $resolver_spec, %resolver_opts) = @_;
        return Template::Resolver->new(
            $resolver_spec,
            %resolver_opts,
            additional_transforms => {
                random => sub {
                    my ($resolver_self, $value) = @_;
                    return $value . rand();
                }
            });
    }

=cut
