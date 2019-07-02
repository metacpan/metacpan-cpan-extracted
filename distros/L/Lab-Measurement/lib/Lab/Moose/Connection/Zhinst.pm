package Lab::Moose::Connection::Zhinst;
$Lab::Moose::Connection::Zhinst::VERSION = '3.682';
#ABSTRACT: Connection back end to Zurich Instrument's LabOne measurement control API


use 5.010;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw(enum);
use Carp;

use Lab::Zhinst;
use YAML::XS 'Load';
use Data::Dumper;
use namespace::autoclean;

has host => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has port => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has connection => (
    is       => 'ro',
    isa      => 'Lab::Zhinst',
    init_arg => undef,
    writer   => '_connection',
);

sub _handle_error {
    my $rv = shift;
    if ($rv) {
        my ( undef, $msg ) = ziAPIGetError($rv);
        croak "Error in Zhinst backend. Value: $rv. Message: $msg.";
    }

    my $value = shift;
    return $value;
}

sub BUILD {
    my $self = shift;

    # Will croak on error.
    my $connection = _handle_error( Lab::Zhinst->Init() );
    $self->_connection($connection);
    _handle_error( $connection->Connect( $self->host(), $self->port() ) );
}

sub Query {
    my $self = shift;
    my ($command) = validated_list(
        \@_,
        command => { isa => 'Str' },
    );
    my %args   = %{ Load $command};
    my $method = delete $args{method};
    if ( $method eq 'ListNodes' ) {

        # result length is ~ 12000 for MFIA. Be generous.
        my $read_length = 100000;
        my $connection  = $self->connection();
        return _handle_error(
            $connection->ListNodes( $args{path}, $read_length, $args{mask} )
        );
    }
    elsif ( $method eq 'Get' ) {
        return $self->get_value(%args);
    }
    elsif ( $method eq 'SyncSet' ) {
        return $self->sync_set_value(%args);
    }
    elsif ( $method eq 'SyncPoll' ) {
        return $self->sync_poll(%args);
    }
    else {
        croak "unknown method $method";
    }
}

sub sync_set_value {
    my $self = shift;
    my ( $path, $type, $value ) = validated_list(
        \@_,
        path  => { isa => 'Str' },
        type  => { isa => enum( [qw/I D B/] ) },
        value => { isa => 'Str' },
    );
    my $method     = "SyncSetValue$type";
    my $connection = $self->connection();
    return _handle_error( $connection->$method( $path, $value ) );
}

sub get_value {
    my $self = shift;
    my ( $path, $type, $read_length ) = validated_list(
        \@_,
        path        => { isa => 'Str' },
        type        => { isa => enum( [qw/I D B Demod AuxIn DIO/] ) },
        read_length => { isa => 'Int', optional => 1 },

    );

    my $method = 'Get';
    $method .=
          $type eq 'I'     ? 'ValueI'
        : $type eq 'D'     ? 'ValueD'
        : $type eq 'B'     ? 'ValueB'
        : $type eq 'Demod' ? 'DemodSample'
        : $type eq 'AuxIn' ? 'AuxInSample'
        :                    'DIOSample';

    my $connection = $self->connection();
    if ( $type eq 'B' ) {
        if ( not defined $read_length ) {
            croak "Need read_length arg to set byte string.";
        }
        return _handle_error( $connection->$method( $path, $read_length ) );
    }
    return _handle_error( $connection->$method($path) );
}

sub _timeout_arg {
    my $self    = shift;
    my %arg     = @_;
    my $timeout = $arg{timeout} // $self->timeout();
    return sprintf( "%.0f", $timeout * 1000 );
}

sub sync_poll {
    my ( $self, %args ) = validated_hash(
        \@_,
        path    => { isa => 'Str' },
        timeout => { isa => 'Num', optional => 1 },
    );
    my $timeout    = $self->_timeout_arg(%args);
    my $path       = $args{path};
    my $connection = $self->connection();

    my $event = ziAPIAllocateEventEx();
    _handle_error( $connection->Subscribe($path) );

    # Ensure that we get a recent value. See LabOne manual
    # '1.4.4. Obtaining Data from the Instrument'
    _handle_error( $connection->Sync() );

    my $data = _handle_error( $connection->PollDataEx( $event, $timeout ) );
    _handle_error( $connection->UnSubscribe($path) );

    if ( $data->{valueType} == ZI_VALUE_TYPE_NONE ) {
        croak
            "Possible timeout in PollDataEx. Got event type ZI_VALUE_TYPE_NONE .";
    }
    if ( $data->{count} == 0 ) {

        # Never reached?
        croak "Event with zero count.";
    }

    # Return only last (most recent) event.
    return $data->{values}[-1];
}

sub Write {
    croak "not implemented";
}

sub Read {
    croak "not implemented";
}

sub Clear {
    croak "not implemented";
}

# Get timeout attribute.
with qw/Lab::Moose::Connection/;

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Connection::Zhinst - Connection back end to Zurich Instrument's LabOne measurement control API

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose;
 my $instrument = instrument(
     type => 'Random',
     connection_type => 'Zhinst',
     connection_options => {host => ..., port => ...}
 );

=head1 DESCRIPTION

This module translates between YAML text commands and L<Lab::Zhinst>
method calls. The YAML commands are produced in Lab::Moose::Instrument::Zhinst.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
