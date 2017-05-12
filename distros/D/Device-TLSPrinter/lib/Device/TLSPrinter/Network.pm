package Device::TLSPrinter::Network;
use strict;
use Carp;
use IO::Socket::INET;
use Socket;

{
    no strict "vars";
    @ISA = qw< Device::TLSPrinter >;
}


#
# init()
# ----
sub init {
    my ($self, %args) = @_;

    # check arguments
    my ($host, $port) = split /:/, $self->_device;
    $port = getservbyname($port, "tcp") || $port;
    croak "error: Please specify a host and a port" if not $host or not $port;

    # connect to the specified host and port
    my $sock = IO::Socket::INET->new(
            PeerHost => $host,  Proto => "tcp",  PeerPort => $port,
            autoflush => 1,  Timeout => $self->_timeout
        ) or croak "error: Can't connect to <$host\:$port>: $!";

    # set socket options
    $sock->sockopt(SO_RCVLOWAT, 1);     # receiving buffer size
    $sock->sockopt(SO_SNDLOWAT, 1);     # sending buffer size

    # store the socket in the object
    $self->_socket($sock);

    return $self
}


#
# read()
# ----
sub read {
    my ($self, %args) = @_;
    my $n = $self->{_socket}->sysread(my $buff, $args{expect});
    return ($n, $buff)
}


#
# write()
# -----
sub write {
    my ($self, %args) = @_;
    my $n = $self->{_socket}->syswrite($args{data});
    return $n
}


#
# connected()
# ---------
sub connected {
    my ($self) = @_;
    return $self->{_socket}->connected ? 1 : 0
}


1;

__END__

=head1 NAME

Device::TLSPrinter::Network - Network driver for Device::TLSPrinter


=head1 SYNOPSIS

    use Device::TLSPrinter;

    my $printer = Device::TLSPrinter->new(type => "network", device => "host:port");


=head1 DESCRIPTION

This module is the network backend driver for C<Device::TLSPrinter>, 
to control a printer accessible on the network through a serial-to-network 
program. 


=head1 BUGS

Please report any bugs or feature requests to
C<bug-device-tlsprinter at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Dist/Display.html?Name=Device-TLSPrinter>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::TLSPrinter

You can also look for information at:

=over

=item * MetaCPAN

L<http://search.cpan.org/dist/Device-TLSPrinter>

=item * Search CPAN

L<http://search.cpan.org/dist/Device-TLSPrinter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-TLSPrinter>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Dist/Display.html?Name=Device-TLSPrinter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Device-TLSPrinter>

=back


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni C<< <sebastien (at) aperghis.net> >>


=head1 COPYRIGHT & LICENSE

Copyright 2006-2012 SE<eacute>bastien Aperghis-Tramoni, all rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

