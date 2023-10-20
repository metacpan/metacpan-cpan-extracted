package Lab::Connection::TCPraw;
#ABSTRACT: Raw TCP connection; deprecated, use Socket instead
$Lab::Connection::TCPraw::VERSION = '3.899';
use v5.20;

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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Connection::TCPraw - Raw TCP connection; deprecated, use Socket instead (deprecated)

=head1 VERSION

version 3.899

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2011       Andreas K. Huettel, Florian Olbrich
            2012       Florian Olbrich, Hermann Kraus
            2013       Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
