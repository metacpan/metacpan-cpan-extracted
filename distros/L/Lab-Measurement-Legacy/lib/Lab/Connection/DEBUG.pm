package Lab::Connection::DEBUG;
#ABSTRACT: Connection to the DEBUG bus
$Lab::Connection::DEBUG::VERSION = '3.899';
use v5.20;

use strict;
use Time::HiRes qw (usleep sleep);
use Lab::Connection;
use Data::Dumper;
use Carp;

use parent 'Lab::Connection';

our %fields = (
    bus_class         => "Lab::Bus::DEBUG",
    brutal            => 0,                   # brutal as default?
    type              => 'DEBUG',
    wait_status       => 10e-6,               # sec;
    wait_query        => 10e-6,               # sec;
    query_length      => 300,                 # bytes
    query_long_length => 10240,               #bytes
    read_length       => 1000,                # bytesx
    instrument_index  => 0,
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Connection::DEBUG - Connection to the DEBUG bus (deprecated)

=head1 VERSION

version 3.899

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, Florian Olbrich
            2012       Florian Olbrich
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
