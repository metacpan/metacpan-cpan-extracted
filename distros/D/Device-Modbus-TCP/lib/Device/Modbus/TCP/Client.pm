package Device::Modbus::TCP::Client;

use parent 'Device::Modbus::Client';
use Role::Tiny::With;
use Carp;
use strict;
use warnings;

with 'Device::Modbus::TCP';

sub new {
    my ($class, %args) = @_;

    $args{host}    //= '127.0.0.1';
    $args{port}    //= 502;
    $args{timeout} //= 2;

    return bless \%args, $class;
}

sub socket {
    my $self = shift;
    if (@_) {
        $self->{socket} = shift;
    }
    if (!defined $self->{socket}) {
        $self->_build_socket || croak "Unable to open a connection";
    }
    return $self->{socket};
}

sub connected {
    my $self = shift;
    return defined $self->{socket} && $self->{socket}->connected;
}

sub _build_socket {
    my $self = shift;
    my $sock = IO::Socket::INET->new(
        PeerAddr  => $self->{host},
        PeerPort  => $self->{port},
        Blocking  => $self->{blocking},
        Timeout   => $self->{timeout},
        Proto     => 'tcp',
    );
    return undef unless $sock;
    $self->socket($sock);
    return 1;
}

#### Transaction ID
my $trans_id = 0;

sub next_trn_id {
    my $self = shift;
    $trans_id++;
    $trans_id = 1 if $trans_id > 65_535;
    return $trans_id;
}

1;

__END__

=head1 NAME

Device::Modbus::TCP::Client - Perl client for Modbus TCP communications

=head1 SYNOPSIS

#! /usr/bin/perl

use Device::Modbus::TCP::Client;
use Data::Dumper;
use strict;
use warnings;
use v5.10;

my $client = Device::Modbus::TCP::Client->new(
    host => '192.168.1.34',
);

my $req = $client->read_holding_registers(
    unit     => 3,
    address  => 2,
    quantity => 1
);

say Dumper $req;
$client->send_request($req) || die "Send error: $!";
my $response = $client->receive_response;
say Dumper $response;

$client->disconnect;

=head1 DESCRIPTION

This module is part of L<Device::Modbus::TCP>, a distribution which implements the Modbus TCP protocol on top of L<Device::Modbus>.

Device::Modbus::TCP::Client inherits from L<Device::Modbus::Client>, and adds the capability of communicating via TCP sockets. As such, Device::Modbus::TCP::Client implements the constructor only. Please see L<Device::Modbus::Client> for most of the documentation.

=head1 METHODS

=head2 new

This method creates and returns a Device::Modbus::TCP::Client object. It takes the following arguments:

=over

=item host

127.0.0.1 by default

=item port

502 by default.

=item timeout

Defaults to 2 seconds.

=back

=head2 socket

Returns the IO::Socket::INET object used by the client.

=head2 connected

Returns true if the socket object exists and if it is connected.

=head2 disconnect

This method closes the socket connection:

 $client->disconnect;

=head1 SEE ALSO

Most of the functionality is described in L<Device::Modbus::Client>.

=head2 Other distributions

These are other implementations of Modbus in Perl which may be well suited for your application:
L<Protocol::Modbus>, L<MBclient>, L<mbserverd|https://github.com/sourceperl/mbserverd>.

=head1 GITHUB REPOSITORY

You can find the repository of this distribution in L<GitHub|https://github.com/jfraire/Device-Modbus-TCP>.

=head1 AUTHOR

Julio Fraire, E<lt>julio.fraire@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Julio Fraire
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
