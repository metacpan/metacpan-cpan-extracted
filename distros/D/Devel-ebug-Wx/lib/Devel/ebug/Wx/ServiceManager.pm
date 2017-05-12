package Devel::ebug::Wx::ServiceManager;

use strict;
use base qw(Class::Accessor::Fast);
use Devel::ebug::Wx::Plugin qw(:manager);

=head1 NAME

Devel::ebug::Wx::Service::ServiceManager - manage services

=head1 SYNOPSIS

  my $sm = $wxebug->service_manager; # or find it elsewhere
  my $service = $sm->get_service( $service_name );
  # use the $service

  # alternate ways of getting a service
  my $srv = $wxebug->service_manager->get_service( 'foo_frobnicate' );
  my $srv = $wxebug->foo_frobnicate_service;

=head1 DESCRIPTION

The service manager is responsible for finding, initializing and
terminating services.  Users of the service usually need just to call
C<get_service> to retrieve a service instance.

=head1 METHODS

=cut

load_plugins( search_path => 'Devel::ebug::Wx::Service' );

__PACKAGE__->mk_ro_accessors( qw(_active_services _wxebug) );

=head2 services

  my @service_classes = Devel::ebug::Wx::ServiceManager->services;

Returns a list of service classes known to the service manager.

=head2 active_services

  my @services = $sm->active_services;

Returns a list of services currently registered with the service manager.

=cut

sub active_services { @{$_[0]->_active_services} }
sub services { Devel::ebug::Wx::Plugin->service_classes }
sub add_service { push @{$_[0]->_active_services}, $_[1] }

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new;
    my @services = map $_->new, $self->services;

    $self->{_active_services} = \@services;

    return $self;
}

=head2 initialize

  $sm->initialze( $wxebug );

Calls C<initialize> on all service instances and sets their
C<initialized> property to true.

=cut

sub initialize {
    my( $self ) = @_;

    foreach my $service ( $self->active_services ) {
        next if $service->initialized;
        $service->service_manager( $self )
          if $service->can( 'service_manager' );
        $service->initialize( $self );
        $service->initialized( 1 );
    }
}

=head2 load_configuration

  $sm->load_configuration;

Calls C<load_configuration> on all service instances.

=head2 maybe_call_method

  $sm->maybe_call_method( $method, @args );

Calls method C<$method> on all active services that provide it, passing
C<@args> as arguments.

=cut

sub load_configuration {
    my( $self ) = @_;

    $_->load_configuration foreach $self->active_services;
}

sub maybe_call_method {
    my( $self, $method, @args ) = @_;

    $_->$method( @args ) foreach grep $_->can( $method ),
                                      $self->active_services;
}

=head2 finalize

  $sm->finalize( $wxebug );

Calls C<save_configuration> on all service instances, then calls C<finalize>
on them and sets their C<finalized> property to true.

Important: the C<initialized> property is still true even after
C<finalize> has been called..

=cut

sub finalize {
    my( $self, $wxebug ) = @_;

    # distinguish between explicit and implicit state saving?
    $_->save_configuration foreach $self->active_services;
    foreach my $service ( $self->active_services ) {
        next if $service->finalized;
        $service->finalize;
        $service->finalized( 1 );
    }
}

=head2 get_service

  my $service_instance = $sm->get_service( 'service_name' );

Returns an active service with the given name, or C<undef> if none is
found.  If the service has not been initialized, calls C<inititialize>
as well, but not C<load_configuration>.

=cut

sub get_service {
    my( $self, $name ) = @_;
    my( $service, @rest ) = grep $_->service_name eq $name,
                                 $self->active_services;

    # @rest can be nonempty only if two clashing services exist
    unless( $service->initialized ) {
        $service->service_manager( $self )
          if $service->can( 'service_manager' );
        $service->initialize( $self );
        $service->initialized( 1 );
    }
    return $service;
}

=head1 SEE ALSO

L<Devel::ebug::Wx::Service::Base>

=cut

# FIXME document
package Devel::ebug::Wx::ServiceManager::Holder;

use strict;
use base qw(Exporter);

our( @EXPORT, %EXPORT_TAGS );
BEGIN {
    $INC{'Devel/ebug/Wx/ServiceManager/Holder.pm'} = __FILE__;
    @EXPORT = qw(AUTOLOAD service_manager get_service);
    %EXPORT_TAGS = ( 'noautoload' => [ qw(service_manager get_service) ] );
}

sub service_manager { # the usual getter/setter
    return $_[0]->{service_manager} = $_[1] if @_ > 1;
    return $_[0]->{service_manager};
}

# remap ->xxx_yy_service to ->get_service( 'xxx_yy' )
our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    return if $AUTOLOAD =~ /::DESTROY$/;
    ( my $sub = $AUTOLOAD ) =~ s/.*::(\w+)_service$/$1/;
    return $self->get_service( $1 );
}

sub get_service { $_[0]->service_manager->get_service( $_[1] ) }

1;
