package Geo::Routing;
BEGIN {
  $Geo::Routing::AUTHORITY = 'cpan:AVAR';
}
BEGIN {
  $Geo::Routing::VERSION = '0.11';
}
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
use warnings FATAL => "all";
use Data::Dumper;
use Class::Load qw(load_class);

=encoding utf8

=head1 NAME

Geo::Routing - Interface to the L<gosmore(1)> and L<OSRM|http://routed.sourceforge.net/> routing libraries

=head1 DESCRIPTION

This is experimental software with an unstable API. It'll be better
soon, but for now don't trust anything here.

=head1 ATTRIBUTES

=cut

=head2 driver

What driver should we be using to do the routing?

=cut

enum GeoRoutingDrivers => qw(
    OSRM
    Gosmore
);

has driver => (
    is            => 'ro',
    isa           => 'GeoRoutingDrivers',
    required      => 1,
    documentation => '',
);

=head2 driver_args

ArrayRef of arguments to pass to the driver.

=cut

has driver_args => (
    is => 'ro',
    isa => 'HashRef',
);

has _driver_object => (
    is         => 'rw',
    lazy_build => 1,
);

sub _build__driver_object {
    my ($self) = @_;

    my $driver        = $self->driver;
    my $module        = "Geo::Routing::Driver::$driver";
    load_class($module);
    my $driver_object = $module->new($self->driver_args);

    return $driver_object;
}

=head1 METHODS

=cut

=head2 route

Find a route based on the L<attributes|/ATTRIBUTES> you've passed
in. Takes a L<Geo::Gosmore::Query> object with your query, returns a
L<Geo::Gosmore::Route> object.

=cut

sub query {
    my ($self, %query) = @_;

    # TODO: Make this lazy
    my $driver        = $self->driver;
    my $module        = "Geo::Routing::Driver::${driver}::Query";
    load_class($module);

    my $query_object = $module->new(%query);

    return $query_object;
}

sub route {
    my ($self, $query) = @_;

    my $route = $self->_driver_object->route($query);

    return $route;
}

1;

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Ævar Arnfjörð Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

