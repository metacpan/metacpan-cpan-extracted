package Lab::Moose::Instrument::Common;

use Moose::Role;
use MooseX::Params::Validate;

use Lab::Moose::Instrument qw/
    validated_getter
    validated_setter
    validated_no_param_setter
    /;
use Carp;

use namespace::autoclean;

our $VERSION = '3.542';

=head1 NAME

Lab::Moose::Instrument::Common - Role for common commands declared mandatory by
IEEE 488.2.

=head1 METHODS

=head2 cls

Send I<*CLS> command.

=cut

sub cls {
    my ( $self, %args ) = validated_no_param_setter( \@_ );
    return $self->write( command => '*CLS', %args );
}

=head2 idn

Return result of I<*IDN?> query.

=cut

sub idn {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => '*IDN?', %args );
}

=head2 opc

Send I<*OPC> command.

=cut

sub opc {
    my ( $self, %args ) = validated_no_param_setter( \@_ );
    return $self->write( command => '*OPC', %args );
}

=head2 opc_query

Return result of I<*OPC?> query.

=cut

sub opc_query {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => '*OPC?', %args );
}

=head2 opc_sync

Perform C<opc_query> and croak if it does not return '1'. Make sure to provide
a sufficient timeout.

=cut

sub opc_sync {
    my ( $self, %args ) = validated_getter( \@_ );
    my $one = $self->opc_query(%args);
    if ( $one ne '1' ) {
        croak "OPC query did not return '1'";
    }
    return $one;
}

=head2 RST

Send I<*RST> command.

=cut

sub rst {
    my ( $self, %args ) = validated_no_param_setter( \@_ );
    return $self->write( command => '*RST', %args );
}

=head2 WAI

Send I<*WAI> command.

=cut

sub wai {
    my ( $self, %args ) = validated_no_param_setter( \@_ );
    return $self->write( command => '*WAI', %args );
}

1;
