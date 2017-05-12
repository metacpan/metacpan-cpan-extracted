package Lab::Moose::Instrument::SCPI::Format;
use Moose::Role;
use Lab::Moose::Instrument qw/setter_params getter_params validated_getter/;
use Lab::Moose::Instrument::Cache;
use MooseX::Params::Validate;
use Carp;

our $VERSION = '3.542';

cache format_data => ( getter => 'format_data_query' );

sub format_data_query {
    my ( $self, %args ) = validated_getter( \@_ );

    my $format = $self->query( command => 'FORM?', %args );

    if ( $format !~ /^(?<format>\w+),(?<length>\d+)$/ ) {
        croak "illegal value of DATA:FORMat: $format";
    }

    return $self->cached_format_data( [ $+{format}, $+{length} ] );
}

sub format_data {
    my ( $self, %args ) = validated_hash(
        \@_,
        setter_params(),
        format => { isa => 'Str' },
        length => { isa => 'Int' }
    );
    my $format = delete $args{format};
    my $length = delete $args{length};

    $self->write( command => "FORM $format, $length", %args );

    return $self->cached_format_data( [ $format, $length ] );
}

cache format_border => ( getter => 'format_border_query' );

sub format_border_query {
    my ( $self, %args ) = validated_getter( \@_ );

    return $self->cached_format_border(
        $self->query( command => 'FORM:BORD?', %args ) );
}

sub format_border {
    my ( $self, $value, %args ) = validated_setter( \@_ );

    $self->write( command => "FORM:BORD $value", %args );
    return $self->cached_format_border($value);
}

1;
