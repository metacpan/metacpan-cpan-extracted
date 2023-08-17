package Lab::Connection::VICP;
#ABSTRACT: VICP ethernet protocol connection
$Lab::Connection::VICP::VERSION = '3.881';
use v5.20;

use strict;
use Time::HiRes qw (usleep sleep);
use Lab::Connection::GPIB;
use Carp;
use Data::Dumper;

our @ISA = ("Lab::Connection");

our %fields = (
    bus_class   => 'Lab::Bus::VICP',
    wait_status => 0,                  # usec;
    wait_query  => 10e-6,              # sec;
    read_length => 1000,               # bytes
    timeout     => 1,                  # seconds
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;
    my $self  = $class->SUPER::new(@_)
        ;    # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    return $self;
}

sub Write {
    my $self    = shift;
    my $options = undef;
    if   ( ref $_[0] eq 'HASH' ) { $options = shift }
    else                         { $options = {@_} }

    my $timeout = $options->{'timeout'} || $self->{timeout};

    #    $self->bus()->timeout( $self->connection_handle(), $timeout );

    return $self->bus()
        ->connection_write( $self->connection_handle(), $options );
}

sub Read {
    my $self    = shift;
    my $options = undef;
    if   ( ref $_[0] eq 'HASH' ) { $options = shift }
    else                         { $options = {@_} }

    my $timeout = $options->{'timeout'} || $self->{timeout};

    #   $self->bus()->timeout( $self->connection_handle(), $timeout );

    return $self->bus()
        ->connection_read( $self->connection_handle(), $options );
}

sub Query {
    my $self    = shift;
    my $options = undef;
    if   ( ref $_[0] eq 'HASH' ) { $options = shift }
    else                         { $options = {@_} }

    $self->Write($options);
    return $self->Read($options);

    #    return $self->bus()->connection_query( $self->connection_handle(), $options );
}

#
# Query from Lab::Connection is sufficient
# EnableTermChar, SetTermChar from Lab::Connection::GPIB are sufficient.
#


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Connection::VICP - VICP ethernet protocol connection

=head1 VERSION

version 3.881

=head1 SYNOPSIS

Connection class which uses the VICP ethernet protocol backend. 
The communication is primarily GPIB/IEEE-488 syntax.

This is not called directly. To make a GPIB suppporting instrument use Lab::Connection::VICP, set
the connection_type parameter accordingly:

$instrument = new LeCroy640 (
   connection_type => 'VICP',
   host_addr => 192.168.1.100,
)

=head1 DESCRIPTION

C<Lab::Connection::VICP> provides a GPIB-type connection with the bus L<Lab::Bus::VICP>, 
using GPIB over ethernet (with special GPIB-ish header packets) as a backend.

It inherits from L<Lab::Connection::GPIB> and subsequently from L<Lab::Connection>.

For L<Lab::Bus::VICP>, the generic methods of L<Lab::Connection> suffice, so only a few defaults are set:
  wait_status=>0, # usec;
  wait_query=>10, # usec;
  read_length=>1000, # bytes

=head1 CONSTRUCTOR

=head2 new

 my $connection = new Lab::Connection::VICP(
    host_addr => 192.168.1.100,   # or host specified by name
    host_port => 1861,            # default lecroy-vicp port
    timeout => 10,                # timeout, seconds.
 }

=head1 METHODS

This just falls back on the methods inherited from L<Lab::Connection>.

=head2 config

Provides unified access to the fields in initial @_ to all the child classes.
E.g.

Without arguments, returns a reference to the complete $self->Config aka @_ of the constructor.

 $Config = $connection->Config();
 $ipaddr = $connection->Config()->{'host_addr'};

=head1 CAVEATS/BUGS

Probably few. Mostly because there's not a lot to be done here. Please report.

=head1 SEE ALSO

=over 4

=item * L<Lab::Connection>

=item * L<Lab::Connection::GPIB>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2016       Charles Lane
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
