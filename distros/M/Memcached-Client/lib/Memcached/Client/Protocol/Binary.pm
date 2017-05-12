package Memcached::Client::Protocol::Binary;
BEGIN {
  $Memcached::Client::Protocol::Binary::VERSION = '2.01';
}
# ABSTRACT: Implements new binary memcached protocol

use strict;
use warnings;
use AnyEvent::Handle qw{};
use Config;
use Memcached::Client::Log qw{DEBUG LOG};
use bytes;

use base qw{Memcached::Client::Protocol};

use constant HEADER_SIZE => 24;
use constant HAS_64BIT => ($Config{use64bitint} || $Config{use64bitall});

# Constants
use constant +{
               #    Magic numbers
               REQ_MAGIC       => 0x80,
               RES_MAGIC       => 0x81,

               #    Status Codes
               #    0x0000  No error
               #    0x0001  Key not found
               #    0x0002  Key exists
               #    0x0003  Value too large
               #    0x0004  Invalid arguments
               #    0x0005  Item not stored
               #    0x0006  Incr/Decr on non-numeric value.
               ST_SUCCESS      => 0x0000,
               ST_NOT_FOUND    => 0x0001,
               ST_EXISTS       => 0x0002,
               ST_TOO_LARGE    => 0x0003,
               ST_INVALID      => 0x0004,
               ST_NOT_STORED   => 0x0005,
               ST_NON_NUMERIC  => 0x0006,

               #    Opcodes
               MEMD_GET        => 0x00,
               MEMD_SET        => 0x01,
               MEMD_ADD        => 0x02,
               MEMD_REPLACE    => 0x03,
               MEMD_DELETE     => 0x04,
               MEMD_INCREMENT  => 0x05,
               MEMD_DECREMENT  => 0x06,
               MEMD_QUIT       => 0x07,
               MEMD_FLUSH      => 0x08,
               MEMD_GETQ       => 0x09,
               MEMD_NOOP       => 0x0A,
               MEMD_VERSION    => 0x0B,
               MEMD_GETK       => 0x0C,
               MEMD_GETKQ      => 0x0D,
               MEMD_APPEND     => 0x0E,
               MEMD_PREPEND    => 0x0F,
               MEMD_STAT       => 0x10,
               MEMD_SETQ       => 0x11,
               MEMD_ADDQ       => 0x12,
               MEMD_REPLACEQ   => 0x13,
               MEMD_DELETEQ    => 0x14,
               MEMD_INCREMENTQ => 0x15,
               MEMD_DECREMENTQ => 0x16,
               MEMD_QUITQ      => 0x17,
               MEMD_FLUSHQ     => 0x18,
               MEMD_APPENDQ    => 0x19,
               MEMD_PREPENDQ   => 0x1A,
               RAW_BYTES       => 0x00,
              };

my $OPAQUE;
BEGIN {
    $OPAQUE = 0xffffffff;
}

# binary protocol read type
AnyEvent::Handle::register_read_type memcached_bin => sub {
    my ($self, $cb) = @_;

    my %state = ( waiting_header => 1 );
    sub {
        return unless $_[0]{rbuf};

        my $rbuf_ref = \$_[0]{rbuf};
        if ($state{waiting_header}) {
            return if length $$rbuf_ref < HEADER_SIZE;

            my $header = substr $$rbuf_ref, 0, HEADER_SIZE, '';
            my ($i1, $i2, $i3, $i4, $i5, $i6) = unpack('N6', $header);
            $state{magic}             = $i1 >> 24;
            $state{opcode}            = ($i1 & 0x00ff0000) >> 16;
            $state{key_length}        = ($i1 & 0x0000ffff);
            $state{extra_length}      = ($i2 & 0xff000000) >> 24;
            $state{data_type}         = ($i2 & 0x00ff0000) >> 8;
            $state{status}            = ($i2 & 0x0000ffff);
            $state{total_body_length} = $i3;
            $state{opaque}            = $i4;

            if (HAS_64BIT) {
                $state{cas} = $i5 << 32 + $i6;
            } else {
                warn "overflow on CAS" if ($i5 || 0) != 0;
                $state{cas} = $i6;
            }

            delete $state{waiting_header};
        }

        if ($state{total_body_length}) {
            return if length $$rbuf_ref < $state{total_body_length};

            $state{extra} = substr $$rbuf_ref, 0, $state{extra_length}, '';
            $state{key} = substr $$rbuf_ref, 0, $state{key_length}, '';


            my $value_len = $state{total_body_length} - ($state{key_length} + $state{extra_length});
            $state{value} = substr $$rbuf_ref, 0, $value_len, '';
        }

        $cb->( \%state );
        undef %state;
        1;
    }
};

sub __prepare_handle {
    my ($self, $fh) = @_;
    binmode $fh;
}

AnyEvent::Handle::register_write_type memcached_bin => sub {
    my ($self, $opcode, $key, $extras, $body, $cas, $data_type, $reserved ) = @_;
    my $key_length = defined $key ? length($key) : 0;
    # first 4 bytes (long)
    my $i1 = 0;
    $i1 ^= REQ_MAGIC << 24;
    $i1 ^= $opcode << 16;
    $i1 ^= $key_length;

    # second 4 bytes
    my $i2 = 0;
    my $extra_length = 
      ($opcode != MEMD_PREPEND && $opcode != MEMD_APPEND && defined $extras) ?
        length($extras) :
          0
            ;
    if ($extra_length) {
        $i2 ^= $extra_length << 24;
    }
    # $data_type and $reserved are not used currently

    # third 4 bytes
    my $body_length  = defined $body ? length($body) : 0;
    my $i3 = $body_length + $key_length + $extra_length;

    # this is the opaque value, which will be returned with the response
    my $i4 = $OPAQUE;
    if ($OPAQUE == 0xffffffff) {
        $OPAQUE = 0;
    } else {
        $OPAQUE++;
    }

    # CAS is 64 bit, which is troublesome on 32 bit architectures.
    # we will NOT allow 64 bit CAS on 32 bit machines for now.
    # better handling by binary-adept people are welcome
    $cas ||= 0;
    my ($i5, $i6);
    if (HAS_64BIT) {
        no warnings;
        $i5 = 0xffffffff00000000 & $cas;
        $i6 = 0x00000000ffffffff & $cas;
    } else {
        $i5 = 0x00000000;
        $i6 = $cas;
    }

    my $message = pack( 'N6', $i1, $i2, $i3, $i4, $i5, $i6 );
    if (length($message) > HEADER_SIZE) {
        Carp::confess "header size assertion failed";
    }

    if ($extra_length) {
        $message .= $extras;
    }
    if ($key_length) {
        $message .= pack('a*', $key);
    }
    if ($body_length) {
        $message .= pack('a*', $body);
    }

    return $message;
};

sub _status_str {
    my $status = shift;
    my %strings = (
                   ST_SUCCESS() => "Success",
                   ST_NOT_FOUND() => "Not found",
                   ST_EXISTS() => "Exists",
                   ST_TOO_LARGE() => "Too Large",
                   ST_INVALID() => "Invalid Arguments",
                   ST_NOT_STORED() => "Not Stored",
                   ST_NON_NUMERIC() => "Incr/Decr on non-numeric variables"
                  );
    return $strings{$status};
}

my %opcodes = (add => MEMD_ADD,
               append => MEMD_APPEND,
               decr => MEMD_DECREMENT,
               incr => MEMD_INCREMENT,
               prepend => MEMD_PREPEND,
               replace => MEMD_REPLACE,
               set => MEMD_SET);

sub __connect {
    my ($self, $c, $r) = @_;
    $self->rlog ($c, $r, "Connected") if DEBUG;
    $r->result (1);
    $c->complete;
}

sub __add {
    my ($self, $c, $r) = @_;
    $self->rlog ($c, $r, $r->{command}) if DEBUG;
    my ($data, $flags) = $self->encode ($r->{command}, $r->{value});
    $c->{handle}->push_write (memcached_bin => $opcodes{$r->{command}}, $r->{nskey}, pack ('N2', $flags, $r->{expiration}), $data);
    $c->{handle}->push_read (memcached_bin => sub {
                                 my ($msg) = @_;
                                 $r->result (0 == $msg->{status} ? 1 : 0);
                                 $c->complete;
                             });
}

sub __decr {
    my ($self, $c, $r) = @_;
    $self->rlog ($c, $r, $r->{command}) if DEBUG;
    $r->{expire} = defined $r->{data} ? 0 : 0xffffffff;
    $r->{data} ||= 0;
    my $extras = HAS_64BIT ? pack('Q2L', $r->{delta}, $r->{data}, $r->{expire}) : pack('N5', 0, $r->{delta}, 0, $r->{data}, $r->{expire});
    $c->{handle}->push_write (memcached_bin => $opcodes{$r->{command}}, $r->{nskey}, $extras, undef, undef, undef, undef);
    $c->{handle}->push_read (memcached_bin => sub {
                                 my ($msg) = @_;
                                 $self->log ("Our message: %s", $msg) if DEBUG;
                                 my $delta;
                                 if (HAS_64BIT) {
                                     $delta = unpack ('Q', $msg->{value});
                                 } else {
                                     (undef, $delta) = unpack ('N2', $msg->{value});
                                 }
                                 $r->result (0 == $msg->{status} ? $delta : undef);
                                 $c->complete;
                             });
}

sub __delete {
    my ($self, $c, $r) = @_;
    $self->rlog ($c, $r, "delete") if DEBUG;
    $c->{handle}->push_write (memcached_bin => MEMD_DELETE, $r->{nskey});
    $c->{handle}->push_read (memcached_bin => sub {
                                 my ($msg) = @_;
                                 $r->result (0 == $msg->{status} ? 1 : 0);
                                 $c->complete;
                             });
}

sub __flush_all {
    my ($self, $c, $r) = @_;
    $self->rlog ($c, $r, "flush_all") if DEBUG;
    $c->{handle}->push_write (memcached_bin => MEMD_FLUSH);
    $c->{handle}->push_read (memcached_bin => sub {
                                 my ($msg) = @_;
                                 $r->result (1);
                                 $c->complete;
                             });
}

sub __get {
    my ($self, $c, $r) = @_;
    $self->rlog ($c, $r, "get") if DEBUG;
    $c->{handle}->push_write (memcached_bin => MEMD_GETK, $r->{nskey});
    $c->{handle}->push_read (memcached_bin => sub {
                                 my ($msg) = @_;
                                 $self->log ("Our message: %s", $msg) if DEBUG;
                                 my ($flags, $exptime) = unpack('N2', $msg->{extra});
                                 if (0 == $msg->{status} and exists $msg->{key} && exists $msg->{value}) {
                                     $r->result ($self->decode ($msg->{value}, $flags));
                                 } else {
                                     $r->result;
                                 }
                                 $c->complete;
                             });
}

sub __version {
    my ($self, $c, $r) = @_;
    $self->rlog ($c, $r, "version") if DEBUG;
    $c->{handle}->push_write (memcached_bin => MEMD_VERSION);
    $c->{handle}->push_read (memcached_bin => sub {
                                 my ($msg) = @_;
                                 if (0 == $msg->{status}) {
                                     my $value = unpack ('a*', $msg->{value});
                                     $r->result ($value);
                                 }
                                 $c->complete
                             });
}

1;

__END__
=pod

=head1 NAME

Memcached::Client::Protocol::Binary - Implements new binary memcached protocol

=head1 VERSION

version 2.01

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Alan Dorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

