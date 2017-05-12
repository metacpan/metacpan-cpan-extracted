use strict;
use warnings;

package Footprintless::Factory;
$Footprintless::Factory::VERSION = '1.24';
# ABSTRACT: The default factory for footprintless modules
# PODNAME: Footprintless::Factory

use Carp;
use Footprintless::Util;
use Log::Any;

our $AUTOLOAD;
my $logger = Log::Any->get_logger();

sub new {
    return bless( {}, shift )->_init(@_);
}

sub agent {
    my ( $self, @options ) = @_;

    return Footprintless::Util::agent(@options);
}

sub AUTOLOAD {
    my ( $self, @args ) = @_;
    my $method_name = $AUTOLOAD;
    $method_name =~ s/.*:://;
    foreach my $plugin ( $self->plugins() ) {
        my $method = $plugin->factory_methods()->{$method_name};
        if ($method) {
            return &$method( $self, @args );
        }
    }
    croak("unsupported factory method: [$method_name]");
}

sub command_options {
    my ( $self, @spec ) = @_;
    return $self->command_options_factory()->command_options(@spec);
}

sub command_options_factory {
    my ($self) = @_;

    unless ( $self->{command_options_factory} ) {
        require Footprintless::CommandOptionsFactory;
        $self->{command_options_factory} =
            Footprintless::CommandOptionsFactory->new( localhost => $self->localhost() );
    }

    return $self->{command_options_factory};
}

sub command_runner {
    my ($self) = @_;

    unless ( $self->{command_runner} ) {
        require Footprintless::Util;
        $self->{command_runner} = Footprintless::Util::default_command_runner();
    }

    return $self->{command_runner};
}

sub deployment {
    my ( $self, $coordinate, %options ) = @_;

    require Footprintless::Deployment;
    return Footprintless::Deployment->new( $self, $coordinate, %options );
}

sub DESTROY { }

sub entities {
    return $_[0]->{entities};
}

sub _init {
    my ( $self, $entities, %options ) = @_;

    $self->{entities}                = $entities;
    $self->{agent}                   = $options{agent};
    $self->{command_options_factory} = $options{command_options_factory};
    $self->{command_runner}          = $options{command_runner};
    $self->{localhost}               = $options{localhost};
    $self->{resource_manager}        = $options{resource_manager};

    $self->{plugins} = [];
    if ( $self->{entities}{'footprintless'} ) {
        my $plugin_modules = $self->{entities}{'footprintless'}{plugins};
        if ($plugin_modules) {
            foreach my $plugin_module (@$plugin_modules) {
                $logger->debugf( 'registering plugin %s', $plugin_module );
                $self->register_plugin(
                    Footprintless::Util::dynamic_module_new(
                        $plugin_module, $self->{entities}{'footprintless'}{$plugin_module}
                    )
                );
            }
        }
    }

    return $self;
}

sub localhost {
    my ($self) = @_;

    unless ( $self->{localhost} ) {
        require Footprintless::Localhost;
        $self->{localhost} = Footprintless::Localhost->new()->load_all();
    }

    return $self->{localhost};
}

sub log {
    my ( $self, $coordinate, %options ) = @_;

    require Footprintless::Log;
    return Footprintless::Log->new( $self, $coordinate, %options );
}

sub overlay {
    my ( $self, $coordinate, %options ) = @_;

    require Footprintless::Overlay;
    return Footprintless::Overlay->new( $self, $coordinate, %options );
}

sub plugins {
    return @{ $_[0]->{plugins} };
}

sub register_plugin {
    my ( $self, $plugin ) = @_;

    push( @{ $self->{plugins} }, $plugin );
}

sub resource_manager {
    my ( $self, $coordinate, %options ) = @_;

    unless ( $self->{resource_manager} ) {
        $self->{resource_manager} =
            Footprintless::Util::dynamic_module_new( 'Footprintless::ResourceManager',
            $self, $coordinate );
    }

    return $self->{resource_manager};
}

sub service {
    my ( $self, $coordinate, %options ) = @_;

    require Footprintless::Service;
    return Footprintless::Service->new( $self, $coordinate, %options );
}

sub tunnel {
    my ( $self, $coordinate, %options ) = @_;

    require Footprintless::Tunnel;
    return Footprintless::Tunnel->new( $self, $coordinate, %options );
}

1;

__END__

=pod

=head1 NAME

Footprintless::Factory - The default factory for footprintless modules

=head1 VERSION

version 1.24

=head1 DESCRIPTION

The default factory for footprintless modules.

=head1 CONSTRUCTORS

=head2 new($entities)

Creates a new factory configured by C<$entities>.

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

=head2 command_options(%spec)

Returns a C<Footprintless::Command::CommandOptions> object configured by
C<%spec>.

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

=head2 register_plugin($plugin)

Registers C<$plugin> with this instance.  C<$plugin> must be an instance
of L<Footprintless::Plugin> or a subclass.

=head2 resource_manager()

Returns the L<resource_manager|Footprintless::ResourcManager> used by 
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

L<Footprintless|Footprintless>

=item *

L<Footprintless|Footprintless>

=item *

L<Footprintless::Deployment|Footprintless::Deployment>

=item *

L<Footprintless::Log|Footprintless::Log>

=item *

L<Footprintless::Overlay|Footprintless::Overlay>

=item *

L<Footprintless::Service|Footprintless::Service>

=back

=cut
