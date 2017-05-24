package Device::Modbus::TCP;

use Device::Modbus::TCP::ADU;
use IO::Socket::INET;
use Errno qw(:POSIX);
use Time::HiRes qw(time);
use Try::Tiny;
use Role::Tiny;
use Carp;
use strict;
use warnings;

our $VERSION = '0.026';

####

sub read_port {
    my ($self, $bytes) = @_;

    return unless $bytes;

    my $sock = $self->socket;
    croak "Disconnected" unless $sock->connected;

    local $SIG{'ALRM'} = sub { croak "Connection timed out\n" };
    alarm $self->{timeout};

    my $msg = '';
    do {
        my $read;
        my $rc = $self->socket->recv($read, $bytes - length($msg));
        $msg .= $read;
        if ($!{EINTR} || length($msg) == 0) {
            # Shutdowns socket in case of timeout
            $self->socket->shutdown(2);
        }
        if (!defined $rc) {
            croak "Communication error while receiving data: $!";
        }
    }
    while ($self->socket->connected && length($msg) < $bytes);        
    alarm 0;

#    say STDERR "Bytes: " . length($msg) . " MSG: " . unpack 'H*', $msg;
    $self->{buffer} = $msg;
    return $msg;
}

sub write_port {
    my ($self, $adu) = @_;

    local $SIG{'ALRM'} = sub { die "Connection timed out\n" };
    my $attempts = 0;
    my $rc;
    SEND: {
        my $sock = $self->socket;
        try {
            alarm $self->{timeout};
            $rc = $sock->send($adu->binary_message);
            alarm 0;
            if (!defined $rc) {
                die "Communication error while sending request: $!";
            }
        }
        catch {
            if ($_ =~ /timed out/) {
                $sock->close;
                $self->_build_socket;
                $attempts++;
            }
            else {
                croak $_;
            }
        };
        last SEND if $attempts >= 5 || $rc == length($adu->binary_message);
        redo SEND;
    }
    return $rc;
}

sub disconnect {
    my $self = shift;
    $self->socket->close;
}

sub parse_buffer {
    my ($self, $bytes, $pattern) = @_;
    $self->read_port($bytes);
    croak "Time out error" unless
        defined $self->{buffer} && length($self->{buffer}) >= $bytes;    
    return unpack $pattern, substr $self->{buffer},0,$bytes,'';
}

sub new_adu {
    my ($self, $msg) = @_;
    my $adu = Device::Modbus::TCP::ADU->new;
    if (defined $msg) {
        $adu->message($msg);
        $adu->unit($msg->{unit}) if defined $msg->{unit};
        $adu->id( $self->next_trn_id );
    }
    return $adu;
}

### Parsing a message

sub parse_header {
    my ($self, $adu) = @_;
    my ($id, $proto, $length, $unit) = $self->parse_buffer(7, 'nnnC');
    
    $adu->id($id);
    $adu->length($length);
    $adu->unit($unit);

    return $adu;
}

sub parse_footer {
    my ($self, $adu) = @_;
   return $adu;
}

1;

__END__

=head1 NAME

Device::Modbus::TCP - Distribution for Modbus TCP communications

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

Device::Modbus::TCP is a distribution which implements the Modbus TCP protocol on top of L<Device::Modbus>; it adds the capability of communicating via TCP sockets. Please see Device::Modbus to learn about its functionality, and L<Device::Modbus::TCP::Client> or L<Device::Modbus::TCP::Server> to see the particularities of the Modbus TCP implementation.

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
