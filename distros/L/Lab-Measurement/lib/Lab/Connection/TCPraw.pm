#!/usr/bin/perl -w

package Lab::Connection::TCPraw;
our $VERSION = '3.543';

use strict;
use Scalar::Util qw(weaken);
use Time::HiRes qw (usleep sleep);
use Lab::Connection::GPIB;
use Lab::Exception;

our @ISA = ("Lab::Connection::Socket");

our %fields = (
    bus_class   => 'Lab::Bus::Socket',
    proto       => 'tcp',
    remote_port => '5025',
    wait_status => 0,                    # usec;
    wait_query  => 10e-6,                # sec;
    read_length => 1000,                 # bytes
    timeout     => 1,                    # seconds
);

# basically, we're just calling Socket with decent default port and proto

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;
    my $self  = $class->SUPER::new(@_)
        ;    # getting fields and _permitted from parent class
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    return $self;
}

#
# That's all folks. For now.
#

=pod

=encoding utf-8

=head1 NAME

Lab::Connection::TCPraw - TCPraw connection; deprecated, use Socket instead

=head1 AUTHOR/COPYRIGHT

 Copyright 2012      Hermann Kraus
           2013      Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

1;
