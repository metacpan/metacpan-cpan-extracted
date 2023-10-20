package Lab::Connection::IsoBus;
#ABSTRACT: Oxford Instruments IsoBus connection
$Lab::Connection::IsoBus::VERSION = '3.899';
use v5.20;

use strict;
use Lab::Bus::VISA;
use Lab::Connection;
use Lab::Exception;

our @ISA = ("Lab::Connection");

our %fields = (
    bus_class      => 'Lab::Bus::IsoBus',
    isobus_address => undef,
    wait_status    => 0,                    # usec;
    wait_query     => 10e-6,                # sec;
    read_length    => 1000,                 # bytes
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;
    my $self  = $class->SUPER::new(@_)
        ;  # getting fields and _permitted from parent class, parameter checks
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    return $self;
}

sub _configurebus {    # $self->setbus() create new or use existing bus
    my $self = shift;

    my $base = $self->config('base_connection');

    # add predefined connection settings to connection config:
    # no overwriting of user defined connection settings

    my $new_config = $base->config();
    for my $key ( keys %{ $self->config() } ) {
        if ( not defined $base->config($key) ) {
            $new_config->{$key} = $self->config($key);
        }
    }
    $new_config->{'base_connection'}
        = undef;    # aviod recursive definition of bas_connection
    $base->config($new_config);
    $self->config('base_connection')->_configurebus();

}

sub block_connection {
    my $self = shift;

    $self->{connection_blocked} = 1;
    $self->{config}->{base_connection}->block_connection();

}

sub unblock_connection {
    my $self = shift;

    $self->{connection_blocked} = undef;
    $self->{config}->{base_connection}->unblock_connection();

}

sub is_blocked {
    my $self = shift;

    if (   $self->{connection_blocked} == 1
        or $self->{config}->{base_connection}->is_blocked() ) {
        return 1;
    }
    else {
        return 0;
    }

}

1;


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Connection::IsoBus - Oxford Instruments IsoBus connection (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

This is not called directly. To make an Isobus instrument use Lab::Connection::IsoBus, set
the connection_type parameter accordingly:

$instrument = new ILM210(
   connection_type => 'IsoBus',
   isobus_address => 3,
)

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

C<Lab::Connection::IsoBus> provides a connection with L<Lab::Bus::IsoBus>, 
transparently handled via a pre-existing bus and connection object (e.g. serial or GPIB).

It inherits from L<Lab::Connection>.

=head1 CONSTRUCTOR

=head2 new

 my $connection = new Lab::Connection::IsoBus(
   connection_type => 'IsoBus',
   isobus_address => 3,
 }

=head1 METHODS

This just falls back on the methods inherited from L<Lab::Connection>.

=head2 config

Provides unified access to the fields in initial @_ to all the child classes.
E.g.

 $IsoBus_Address=$instrument->Config(isobus_address);

Without arguments, returns a reference to the complete $self->Config aka @_ of the constructor.

 $Config = $connection->Config();
 $IsoBus_Address = $connection->Config()->{'isobus_address'};

=head1 CAVEATS/BUGS

Probably few. Mostly because there's not a lot to be done here. Please report.

=head1 SEE ALSO

=over 4

=item * L<Lab::Connection>

=item * L<Lab::Bus::IsoBus>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, Florian Olbrich
            2012       David Kalok, Florian Olbrich, Stefan Geissler
            2013       Stefan Geissler
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
