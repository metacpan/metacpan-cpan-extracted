package Lab::Moose::Connection::VXI11;
$Lab::Moose::Connection::VXI11::VERSION = '3.682';
#ABSTRACT: Connection backend to VXI-11 (Lan/TCP)

use 5.010;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints 'enum';
use Carp;

use Lab::Moose::Instrument qw/timeout_param read_length_param/;
use Lab::VXI11;
use namespace::autoclean;

use constant {
    WAITLOCK_OPERATION_FLAG   => 1 << 0,
    END_OPERATION_FLAG        => 1 << 3,
    TERMCHRSET_OPERATION_FLAG => 1 << 7,

    END_REASON    => 1 << 2,
    CHR_REASON    => 1 << 1,
    REQCNT_REASON => 1 << 0,
};

has client => (
    is       => 'ro',
    isa      => 'Lab::VXI11',
    writer   => '_client',
    init_arg => undef,
);

has lid => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_lid',
    init_arg => undef
);

has host => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has proto => (
    is      => 'ro',
    isa     => enum( [qw/tcp udp/] ),
    default => 'tcp'
);

has device => (
    is      => 'ro',
    isa     => 'Str',
    default => "inst0",
);

sub _timeout_arg {
    my $self    = shift;
    my %arg     = @_;
    my $timeout = $arg{timeout} // $self->timeout();
    return sprintf( "%.0f", $timeout * 1000 );
}

sub BUILD {
    my $self   = shift;
    my $host   = $self->host();
    my $proto  = $self->proto();
    my $device = $self->device();
    my $client
        = Lab::VXI11->new( $host, DEVICE_CORE, DEVICE_CORE_VERSION, $proto )
        or croak "cannot open VXI-11 connection with $host: $!";
    $self->_client($client);

    my $clientId     = 0;
    my $lockDevice   = 0;
    my $lock_timeout = 0;
    my ( $error, $lid, $abortPort, $maxRecvSize ) = $client->create_link(
        $client, $lockDevice, $lock_timeout,
        $device
    );
    if ($error) {
        croak "Cannot create VXI-11 link. error: $error";
    }
    $self->_lid($lid);
}

sub Write {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param,
        command => { isa => 'Str' },
    );

    my $command = $args{command};
    my $timeout = $self->_timeout_arg(%args);

    my $client = $self->client();
    my $lid    = $self->lid();

    my $lock_timeout = 0;
    my $flags        = END_OPERATION_FLAG;

    my ( $error, $size ) = $client->device_write(
        $lid, $timeout, $lock_timeout, $flags,
        $command
    );
    if ($error) {
        croak "VXI-11 device_write failed with error $error.";
    }
    my $command_length = length($command);
    if ( $size != $command_length ) {
        croak
            "VXI-11 device_write incomplete: write size: $size, expected: $command_length.";
    }
}

sub Read {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param(),
        read_length_param(),
    );
    my $timeout     = $self->_timeout_arg(%args);
    my $read_length = $self->_read_length_arg(%args);

    my $client = $self->client();
    my $lid    = $self->lid();

    my $lock_timeout = 0;
    my $flags        = 0;
    my $termChar     = 0;    # not used

    my $result = '';
    while ($read_length) {
        my ( $error, $reason, $data ) = $client->device_read(
            $lid,          $read_length, $timeout,
            $lock_timeout, $flags,       $termChar
        );
        if ($error) {
            croak "VXI-11 device_read failed with error $error.";
        }
        $result .= $data;
        $read_length -= length($data);

        if ( $reason & END_REASON or $reason & REQCNT_REASON ) {
            last;
        }
    }
    return $result;
}

sub Clear {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param(),
    );
    my $timeout = $self->_timeout_arg(%args);

    my $client = $self->client();
    my $lid    = $self->lid();

    my $flags        = 0;
    my $lock_timeout = 0;

    my ($error)
        = $client->device_clear( $lid, $flags, $lock_timeout, $timeout );
    if ($error) {
        croak "VXI-11 device_clear failed with error $error.";
    }
}

sub DEMOLISH {
    my $self   = shift;
    my $client = $self->client();
    my $lid    = $self->lid();

    if ( $client && $lid ) {
        my ($error) = $client->destroy_link($lid);

        if ($error) {
            croak "VXI-11 destroy_link failed with error $error.";
        }
    }
}

with qw/
    Lab::Moose::Connection
    /;

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Connection::VXI11 - Connection backend to VXI-11 (Lan/TCP)

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose;

 my $instrument = instrument(
     type => 'random_instrument',
     connection_type => 'VXI11',
     connection_options => {host => '132.199.11.2'}
 );

=head1 DESCRIPTION

Connection backend based on L<Lab::VXI11>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
