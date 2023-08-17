package Lab::Connection::VISA;
#ABSTRACT: VISA-type connection
$Lab::Connection::VISA::VERSION = '3.881';
use v5.20;

use strict;
use Lab::Bus::VISA;
use Lab::Connection;
use Lab::Exception;

our @ISA = ("Lab::Connection");

our %fields = (
    bus_class     => 'Lab::Bus::VISA',
    resource_name => undef,
    wait_status   => 0,                  # sec;
    wait_query    => 10e-6,              # sec;
    read_length   => 1000,               # bytes
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

1;

#
# That's all, all that was needed was the additional field "resource_name".
#


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Connection::VISA - VISA-type connection

=head1 VERSION

version 3.881

=head1 SYNOPSIS

Ths general VISA Connection class for Lab::Bus::VISA digests VISA resource names.

This is not called directly. To make a VISA suppporting instrument use Lab::Connection::VISA, set
the connection_type parameter accordingly:

$instrument = new HP34401A(
   connection_type => 'VISA',
   resource_name => 'GPIB0::14::INSTR',
)

=head1 DESCRIPTION

C<Lab::Connection::VISA> provides a VISA-type connection with L<Lab::Bus::VISA> using 
NI VISA (L<Lab::VISA>) as backend.

It inherits from L<Lab::Connection>.

=head1 CONSTRUCTOR

=head2 new

 my $connection = new Lab::Connection::VISA(
   connection_type => 'VISA',
   resource_name => 'GPIB0::14::INSTR',
 }

=head1 METHODS

This just falls back on the methods inherited from L<Lab::Connection>.

=head2 config

Provides unified access to the fields in initial @_ to all the child classes.
E.g.

 $GPIB_Address=$instrument->Config(gpib_address);

Without arguments, returns a reference to the complete $self->Config aka @_ of the constructor.

 $Config = $connection->Config();
 $GPIB_Address = $connection->Config()->{'gpib_address'};

=head1 CAVEATS/BUGS

Probably few. Mostly because there's not a lot to be done here. Please report.

=head1 SEE ALSO

=over 4

=item * L<Lab::Connection>

=item * L<Lab::Connection::GPIB>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2010       Andreas K. Huettel
            2011       Andreas K. Huettel, Florian Olbrich
            2012       Florian Olbrich
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
