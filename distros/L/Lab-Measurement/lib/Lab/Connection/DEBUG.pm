#!/usr/bin/perl -w

package Lab::Connection::DEBUG;
our $VERSION = '3.543';

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

=pod

=encoding utf-8

=head1 NAME

Lab::Connection::DEBUG - Debug connection


=head1 DESCRIPTION

Connection to the DEBUG bus.

=head1 AUTHOR/COPYRIGHT

 Copyright 2011      Florian Olbrich

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

1;
