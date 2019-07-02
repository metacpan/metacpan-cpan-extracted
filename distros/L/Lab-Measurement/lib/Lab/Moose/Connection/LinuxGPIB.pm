package Lab::Moose::Connection::LinuxGPIB;
$Lab::Moose::Connection::LinuxGPIB::VERSION = '3.682';
#ABSTRACT: Connection back end to the LinuxGpib library and kernel drivers


use 5.010;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw(enum);
use Carp;

use Lab::Moose::Instrument qw/timeout_param read_length_param/;

use Time::HiRes qw/gettimeofday tv_interval/;

use YAML::XS;

use namespace::autoclean;

use LinuxGpib qw/
    ibdev
    ibrd
    ibwrt
    ibtmo
    ibclr
    ibconfig
    /;


has pad => (
    is        => 'ro',
    isa       => enum( [ ( 0 .. 30 ) ] ),
    predicate => 'has_pad',
    writer    => '_pad'
);

has gpib_address => (
    is        => 'ro',
    isa       => enum( [ ( 0 .. 30 ) ] ),
    predicate => 'has_gpib_address'
);

has sad => (
    is      => 'ro',
    isa     => enum( [ 0, ( 96 .. 126 ) ] ),
    default => 0,
);

has board_index => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

# Timeout set on controller
has current_timeout => (
    is       => 'ro',
    isa      => 'Num',
    init_arg => undef,
    writer   => '_current_timeout',
);

has device_descriptor => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
    writer   => '_device_descriptor'
);

sub BUILD {
    my $self = shift;

    if ( $self->has_gpib_address() ) {
        $self->_pad( $self->gpib_address() );
    }

    if ( not $self->has_pad() ) {
        croak "no primary GPIB address provided";
    }

    my $timeout     = $self->timeout;
    my $ibtmo_value = _timeout_to_ibtmo($timeout);
    $self->_current_timeout($timeout);

    my $device_descriptor = ibdev(
        $self->board_index,
        $self->pad,
        $self->sad,
        $ibtmo_value,
        1,    # Assert EOI line after transfer.
        0     # Do not use eos character.
    );

    if ( $device_descriptor < 0 ) {
        croak(
            "ibdev failed with params:\n",
            Dump(
                {
                    board_index => $self->board_index,
                    pad         => $self->pad,
                    sad         => $self->sad,
                    timeout     => $self->timeout,
                    timo        => $ibtmo_value,
                }
            )
        );
    }

    $self->_device_descriptor($device_descriptor);

}


sub Read {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param,
        read_length_param,
    );

    my $timeout = $self->_timeout_arg(%args);

    my $result_string = "";

    $self->_set_timeout( timeout => $timeout );

    my $ibsta_hash;

    my $start_time = [gettimeofday];

    while (1) {
        my $elapsed_time = tv_interval($start_time);

        if ( $elapsed_time > $self->current_timeout() ) {
            croak(
                "timeout in Read with args:\n",
                Dump( \%args )
            );
        }

        my $buffer;

        my $ibsta = ibrd(
            $self->device_descriptor,
            $buffer,
            32768    # buffer length
        );

        $self->_croak_on_err(
            ibsta => $ibsta,
            name  => "ibrd with args:\n" . Dump( \%args )
        );

        $result_string .= $buffer;

        $ibsta_hash = _ibsta_to_hash($ibsta);
        if ( $ibsta_hash->{END} ) {
            last;
        }
    }

    return $result_string;
}


sub Write {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param,
        command => { isa => 'Str' },
    );
    my $command = $args{command};
    my $timeout = $self->_timeout_arg(%args);

    $self->_set_timeout( timeout => $timeout );

    my $ibsta = ibwrt(
        $self->device_descriptor,
        $command,
        length($command)
    );

    $self->_croak_on_err(
        ibsta => $ibsta,
        name  => "ibwrt with args:\n" . Dump( \%args )
    );
}


sub Clear {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param,
    );

    my $timeout = $self->_timeout_arg(%args);

    $self->_set_timeout( timeout => $timeout );

    my $ibsta = ibclr( $self->device_descriptor() );

    $self->_croak_on_err( ibsta => $ibsta, name => 'ibclr' );

}


sub set_termchar {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param,
        termchar => { isa => 'Str' },
    );
    my $timeout = $self->_timeout_arg(%args);
    $self->_set_timeout( timeout => $timeout );
    my $termchar = ord( $args{termchar} );
    my $ibsta = ibconfig( $self->device_descriptor, 0xf, $termchar );
    $self->_croak_on_err( ibsta => $ibsta, name => 'ibconfig set_termchar' );
}


# With default LinuxGPIB configuration, the END bit of ibsta will be set
# when the eos char is received (see IbcEndBitIsNormal mode of ibconfig).

sub enable_read_termchar {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param
    );
    my $timeout = $self->_timeout_arg(%args);
    $self->_set_timeout( timeout => $timeout );
    my $ibsta = ibconfig( $self->device_descriptor, 0xc, 1 );
    $self->_croak_on_err(
        ibsta => $ibsta,
        name  => 'ibconfig enable_termchar'
    );
}

sub _set_timeout {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout => { isa => 'Num' },
    );

    my $timeout             = $args{timeout};
    my $ibtmo_value         = _timeout_to_ibtmo($timeout);
    my $current_timeout     = $self->current_timeout();
    my $current_ibtmo_value = _timeout_to_ibtmo($current_timeout);

    if ( $ibtmo_value != $current_ibtmo_value ) {
        my $ibsta = ibtmo( $self->device_descriptor, $ibtmo_value );
        $self->_croak_on_err( ibsta => $ibsta, name => 'ibtmo' );
        $self->_current_timeout($timeout);
    }

}

sub _croak_on_err {
    my ( $self, %args ) = validated_hash(
        \@_,
        ibsta => { isa => 'Int' },
        name  => { isa => 'Str', optional => 1 },
    );
    my $ibsta = $args{ibsta};
    my $name  = $args{name};
    my $hash  = _ibsta_to_hash($ibsta);
    if ( $hash->{ERR} ) {
        croak(
            "LinuxGPIB error:\n$name\nibsta bits:\n",
            Dump($hash)
        );
    }
}

sub _timeout_to_ibtmo {
    my $timeout = shift;

    # See http://linux-gpib.sourceforge.net/doc_html/r2225.html
    return
          $timeout == 0      ? 0
        : $timeout <= 10e-6  ? 1
        : $timeout <= 30e-6  ? 2
        : $timeout <= 100e-6 ? 3
        : $timeout <= 300e-6 ? 4
        : $timeout <= 1e-3   ? 5
        : $timeout <= 3e-3   ? 6
        : $timeout <= 10e-3  ? 7
        : $timeout <= 30e-3  ? 8
        : $timeout <= 100e-3 ? 9
        : $timeout <= 300e-3 ? 10
        : $timeout <= 1      ? 11
        : $timeout <= 3      ? 12
        : $timeout <= 10     ? 13
        : $timeout <= 30     ? 14
        : $timeout <= 100    ? 15
        : $timeout <= 300    ? 16
        :                      17;
}

sub _ibsta_to_hash {
    my $ibsta = shift;

    my $hash = {};
    my @bits = qw/
        DCAS DTAS  LACS  TACS ATN  CIC REM  LOK
        CMPL EVENT SPOLL RQS  SRQI END TIMO ERR
        /;
    foreach my $i ( 0 .. $#bits ) {
        my $name = $bits[$i];
        my $bit  = 1 << $i;
        if ( $ibsta & $bit ) {
            $hash->{$name} = 1;
        }
    }
    return $hash;
}

with 'Lab::Moose::Connection';

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Connection::LinuxGPIB - Connection back end to the LinuxGpib library and kernel drivers

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose
 
 my $instrument = instrument(
     type => 'random_instrument',
     connection_type => 'LinuxGPIB',
     # use primary address '1' and no secondary addressing.
     connection_options => {pad => 1, timeout => 3},
 );

=head1 DESCRIPTION

This module provides a connection interface to
L<Linux-GPIB|http://linux-gpib.sourceforge.net/>. See
L<Lab::Measurement::Backends> for more information on Linux-GPIB and its Perl
backend.

=head1 METHODS

=head2 new

The constructor takes the following attributes. The only required attribute is
B<pad>.

=head3 pad (or gpib_address for backwards compatibility with
L<Lab::Connection::LinuxGPIB>)

Primary address of the device. Required.

=head3 sad

Secondary address of the device. Default is 0 (Do not use secondary
addressing). Valid values are ( 96 .. 126 ).

=head3 board_index

Board index as provided in your F</etc/gpib.conf>. Default is 0.

=head3 timeout

Connection timeout in seconds. Default is 1. LinuxGPIB provides the following
timeout values. The value given to the constructor will be rounded upwards to a
valid timeout.

=over

=item

0 (never timeout)

=item

10e-6

=item

30e-6

=item

100e-6

=item

300e-6

=item

1e-3

=item

3e-3

=item

10e-3

=item

30e-3

=item

100e-3

=item

300e-3

=item

1

=item

3

=item

10

=item

30

=item

100

=item

300

=item

1000

=back

=head1 METHODS

All methods croak if they take longer than the timeout.

The 'timeout' argument is always optional. If given, this overrides the
connection's timeout attribute.

=head2 Read

 my $data = $connection->Read();

Call ibread on the connection. Read an arbitrary amount of data until the 'END'
bit is set in C<ibsta>. Croak on read errors.

The read may requires multiple calls to ibrd. In this case, it will still croak
if the total time of operation does not exceed the timeout.

=head2 Write

 $connection->Write(command => "*CLS");

Takes one mandatory argument 'command'. Write this string to the connection.
Croak on write error.

=head2 Clear

 $connection->Clear();

Call device clear (ibclr) on the connection.

=head2 set_termchar

 $connection->set_termchar(termchar => "\r");

Set the end-of-string byte

=head2 enable_read_termchar

 $connection->enable_read_termchar();

Enable termination of reads when eos character is received.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt
            2019       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
