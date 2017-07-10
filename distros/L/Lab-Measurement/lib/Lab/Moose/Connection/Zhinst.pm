
=head1 NAME

Lab::Moose::Connection::Zhinst - Connection back end to Zurich Instrument's
LabOne measurement control API.

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

=cut

package Lab::Moose::Connection::Zhinst;
$Lab::Moose::Connection::Zhinst::VERSION = '3.553';
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

sub BUILD {
    my $self = shift;

    # Will croak on error.
    my $connection
        = Lab::Zhinst->new( $self->host(), $self->port() );
    $self->_connection($connection);
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
        return $self->connection()->ListNodes( $args{path}, $args{mask} );
    }
    elsif ( $method eq 'Get' ) {
        return $self->get_value(%args);
    }
    elsif ( $method eq 'SyncSet' ) {
        return $self->sync_set_value(%args);
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
        value => { isa => 'Str' }
    );
    my $method = "SyncSetValue$type";
    return $self->connection()->$method( $path, $value );
}

sub get_value {
    my $self = shift;
    my ( $path, $type ) = validated_list(
        \@_,
        path => { isa => 'Str' },
        type => { isa => enum( [qw/I D B Demod AuxIn DIO/] ) },
    );

    my $method = 'Get';
    $method .=
          $type eq 'I'     ? 'ValueI'
        : $type eq 'D'     ? 'ValueD'
        : $type eq 'B'     ? 'ValueB'
        : $type eq 'Demod' ? 'DemodSample'
        : $type eq 'AuxIn' ? 'AuxInSample'
        :                    'DIOSample';
    return $self->connection()->$method($path);
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

__PACKAGE__->meta->make_immutable();

1;

