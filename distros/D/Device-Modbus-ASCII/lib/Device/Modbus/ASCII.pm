package Device::Modbus::ASCII;

use Device::Modbus::ASCII::ADU;
use Carp;
use strict;
use warnings;

our $VERSION = '0.006';

use Role::Tiny;

#### Modbus ASCII Operations

sub new_adu {
    my ($self, $msg) = @_;
    my $adu = Device::Modbus::ASCII::ADU->new;
    if (defined $msg) {
        $adu->message($msg);
        $adu->unit($msg->{unit}) if defined $msg->{unit};
    }
    return $adu;
}

### Parsing a message

sub parse_header {
    my ($self, $adu) = @_;
    my ($col, $unit) = $self->parse_buffer(3, 'AA2');
    croak "Response message must start by ':', but it does not"
        unless $col eq ':';
    $adu->unit(1*$unit);
    return $adu;
}

sub parse_footer {
    my ($self, $adu) = @_;
    # print STDERR "Remaining chars: <", $self->{buffer}, ">\n";
    my $lrc = $self->parse_buffer(2, 'A2');
    my $ln  = $self->parse_buffer(2, 'H4');
    croak "Response message must end by '\r\n', but it does not"
        unless $ln eq '0d0a';  # \r\n
    $adu->lrc( unpack 'C', pack 'H4', $lrc);
    return $adu;
}

1;

__END__

=head1 NAME

Device::Modbus::ASCII - Modbus ASCII communications for Perl

=head1 SYNOPSIS

 #! /usr/bin/env perl

 use Device::Modbus::ASCII::Client;
 use strict;
 use warnings;
 use v5.10;
 
 my $client = Device::Modbus::ASCII::Client->new(
    port     => '/dev/ttyUSB0',
    baudrate => 19200,
    parity   => 'even',
 );
 
 my $req = $client->read_holding_registers(
    unit     => 4,
    address  => 0,
    quantity => 2,
 );

 $client->send_request($req);
 my $resp = $client->receive_response;

=head1 DESCRIPTION

This distribution implements the Modbus ASCII protocol on top of L<Device::Modbus>. It includes only a client, L<Device::Modbus::ASCII::Client>, which is based on L<Device::Modbus::Client>. See this last module for the core of the documentation.

=head1 THANKS

This distribution came to life thanks to Stefan Parvu from Kronometrix. It was his motivation, dedication and support that made this module possible.

=head1 SEE ALSO

=head2 Other distributions

These are other implementations of Modbus in Perl which may be well suited for your application:
L<Protocol::Modbus>, L<MBclient>, L<mbserverd|https://github.com/sourceperl/mbserverd>.

=head1 GITHUB REPOSITORY

You can find the repository of this distribution in L<GitHub|https://github.com/jfraire/Device-Modbus-ASCII>.

=head1 AUTHOR

Julio Fraire, E<lt>julio.fraire@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Julio Fraire
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
