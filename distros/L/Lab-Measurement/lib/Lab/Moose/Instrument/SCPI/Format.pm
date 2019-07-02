package Lab::Moose::Instrument::SCPI::Format;
$Lab::Moose::Instrument::SCPI::Format::VERSION = '3.682';
#ABSTRACT: Role for SCPI FORMat subsystem.

use Moose::Role;
use Lab::Moose::Instrument qw/setter_params getter_params validated_getter/;
use Lab::Moose::Instrument::Cache;
use MooseX::Params::Validate;
use Carp;


cache format_data => ( getter => 'format_data_query' );

sub format_data_query {
    my ( $self, %args ) = validated_getter( \@_ );

    my $format = $self->query( command => 'FORM?', %args );

    if ( $format !~ /^(?<format>\w+)(,(?<length>\d+))?$/ ) {
        croak "illegal value of DATA:FORMat: $format";
    }

    return $self->cached_format_data( [ $+{format}, $+{length} ] );
}

sub format_data {
    my ( $self, %args ) = validated_hash(
        \@_,
        setter_params(),
        format => { isa => 'Str' },
        length => { isa => 'Int', optional => 1 },
    );

    my $format  = delete $args{format};
    my $length  = delete $args{length};
    my $command = "FORM $format";
    if ( defined $length ) {
        $command .= ", $length";
    }

    $self->write( command => $command, %args );

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

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Format - Role for SCPI FORMat subsystem.

=head1 VERSION

version 3.682

=head1 METHODS

=head2 format_data_query

=head2 format_data

 # set to binary single precision
 $instr->format_data(format => 'REAL', length => 32);

 # set to binary double precision
 $instr->format_data(format => 'REAL', length => 64);

 # set to ASCII, 10 significant digits
 $instr->format_data(format => 'ASC', length => 10);

 my $format = $instr->cached_format_data();
 print "format: $format->[0], len: $format->[1]\n";

Set/Get data format.

=head2 format_border_query

=head2 format_border

 $instr->format_border(value => 'NORM'); # or 'SWAP'

Set/Get byte order of transferred data. Normally you want 'SWAP'
(little-endian), which is the native machine format of the measurement PC.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt
            2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
