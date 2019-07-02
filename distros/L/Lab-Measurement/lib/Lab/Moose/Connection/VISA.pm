package Lab::Moose::Connection::VISA;
$Lab::Moose::Connection::VISA::VERSION = '3.682';
#ABSTRACT: Connection back end to National Instruments' VISA library.


use 5.010;

use Moose;
use MooseX::Params::Validate;
use Carp;

use Lab::Moose::Instrument qw/timeout_param read_length_param/;

use Lab::VISA;

use namespace::autoclean;

use constant {
    VI_TRUE              => $Lab::VISA::VI_TRUE,
    VI_NULL              => $Lab::VISA::VI_NULL,
    VI_SUCCESS           => $Lab::VISA::VI_SUCCESS,
    VI_SUCCESS_TERM_CHAR => $Lab::VISA::VI_SUCCESS_TERM_CHAR,
    VI_SUCCESS_MAX_CNT   => $Lab::VISA::VI_SUCCESS_MAX_CNT,
    VI_ATTR_TMO_VALUE    => $Lab::VISA::VI_ATTR_TMO_VALUE,
    VI_ATTR_TERMCHAR     => $Lab::VISA::VI_ATTR_TERMCHAR,
    VI_ATTR_TERMCHAR_EN  => $Lab::VISA::VI_ATTR_TERMCHAR_EN,
};

has resource_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has handle => (
    is       => 'ro',
    isa      => 'Int',
    writer   => '_handle',
    init_arg => undef,
);

# Timeout set on controller
has current_timeout => (
    is       => 'ro',
    isa      => 'Num',
    init_arg => undef,
    writer   => '_current_timeout',
);

# FIXME: do timeout stuff like LinuxGPIB connection.

sub _timeout_to_ms {
    my $timeout = shift;
    return sprintf( "%.0f", $timeout * 1000 );
}

sub _set_timeout {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout => { isa => 'Num' },
    );

    my $timeout          = $args{timeout};
    my $ms_value         = _timeout_to_ms($timeout);
    my $current_timeout  = $self->current_timeout();
    my $current_ms_value = _timeout_to_ms($current_timeout);

    if ( $ms_value != $current_ms_value ) {
        $self->_set_visa_attribute( VI_ATTR_TMO_VALUE, $ms_value );
        $self->_current_timeout($timeout);
    }
}

sub _handle_status {
    my $self   = shift;
    my $status = shift;
    if ( $status != VI_SUCCESS ) {
        if (@_) {
            croak( "Lab::VISA error $status: ", @_ );
        }
        else {
            croak("Lab::VISA error $status");
        }
    }
}

sub _set_visa_attribute {
    my $self = shift;
    my ( $attribute, $value ) = validated_list(
        attribute => { isa => 'Int' },
        value     => { isa => 'Int' },
    );
    my $handle = $self->handle();
    my $status = Lab::VISA::viSetAttribute( $handle, $attribute, $value );
    $self->_handle_status( $status, "viSetAttribute" );
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
    $self->_set_visa_attribute( attribute => VI_ATTR_TERMCHAR, $termchar );
}


sub enable_read_termchar {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param
    );
    my $timeout = $self->_timeout_arg(%args);
    $self->_set_timeout( timeout => $timeout );
    $self->_set_visa_attribute( attribute => VI_ATTR_TERMCHAR_EN, VI_TRUE );
}

sub gen_resource_name {
    return shift->resource_name();
}

sub BUILD {
    my $self          = shift;
    my $resource_name = $self->gen_resource_name();
    my ( $status, $rm ) = Lab::VISA::viOpenDefaultRM();
    $self->_handle_status( $status, "viOpenDefaultRM" );

    ( $status, my $handle )
        = Lab::VISA::viOpen( $rm, $resource_name, VI_NULL, VI_NULL );
    $self->_handle_status( $status, "viOpen" );
    $self->_handle($handle);

    my $timeout = $self->timeout();
    $self->_current_timeout($timeout);
}


sub Read {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param,
        read_length_param,
    );

    my $timeout = $self->_timeout_arg(%args);
    $self->_set_timeout( timeout => $timeout );

    my $read_length = $self->_read_length_arg(%args);
    my $handle      = $self->handle();
    my $result      = '';
    while ($read_length) {
        my ( $status, $data, $length )
            = Lab::VISA::viRead( $handle, $read_length );
        if (    $status != VI_SUCCESS
            and $status != VI_SUCCESS_TERM_CHAR
            and $status != VI_SUCCESS_MAX_CNT ) {
            croak("Lab::VISA error $status: viRead");
        }

        if ( length($data) != $length ) {
            croak "length(data) != length";
        }

        $result .= $data;
        $read_length -= length($data);

        if (   $status == VI_SUCCESS
            or $status == VI_SUCCESS_TERM_CHAR
            or $status == VI_SUCCESS_MAX_CNT ) {
            last;
        }
    }
    return $result;
}

sub Write {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param,
        command => { isa => 'Str' },
    );

    my $timeout = $self->_timeout_arg(%args);
    $self->_set_timeout( timeout => $timeout );

    my $command = $args{command};
    my $length  = length($command);

    my $handle = $self->handle();
    my ( $status, $bytes_written )
        = Lab::VISA::viWrite( $handle, $command, $length );
    $self->_handle_status( $status, "viWrite" );
    if ( $bytes_written != $length ) {
        croak "viWrite: written: $bytes_written, length: $length";
    }
}

sub Clear {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param,
    );

    my $timeout = $self->_timeout_arg(%args);
    $self->_set_timeout( timeout => $timeout );

    my $handle = $self->handle();
    my $status = Lab::VISA::viClear($handle);
    $self->_handle_status( $status, "viClear" );
}

with 'Lab::Moose::Connection';

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Connection::VISA - Connection back end to National Instruments' VISA library.

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose
 
 my $instrument = instrument(
     type => 'random_instrument',
     connection_type => 'VISA',
     connection_options => {resource_name => $resource_name}
 );

=head2 set_termchar

 $connection->set_termchar(termchar => "\r");

Set the end-of-string byte

=head2 enable_read_termchar

 $connection->enable_read_termchar();

Enable termination of reads when eos character is received.

=head1 METHODS

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Simon Reinhardt
            2019       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
