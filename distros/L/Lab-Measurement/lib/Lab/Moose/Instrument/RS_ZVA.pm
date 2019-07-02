package Lab::Moose::Instrument::RS_ZVA;
$Lab::Moose::Instrument::RS_ZVA::VERSION = '3.682';
#ABSTRACT: Rohde & Schwarz ZVA Vector Network Analyzer

use 5.010;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument
    qw/validated_getter validated_channel_getter validated_channel_setter /;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::VNASweep

    Lab::Moose::Instrument::SCPI::Output::State
);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}

cache calculate_data_call_catalog => (
    getter => 'calculate_data_call_catalog',
    isa    => 'ArrayRef'
);

sub calculate_data_call_catalog {
    my ( $self, $channel, %args ) = validated_channel_getter( \@_ );

    my $string
        = $self->query( command => "CALC${channel}:DATA:CALL:CAT?", %args );
    $string =~ s/'//g;

    return $self->cached_calculate_data_call_catalog(
        [ split ',', $string ] );
}

sub calculate_data_call {
    my ( $self, $channel, %args ) = validated_channel_getter(
        \@_,
        format => { isa => 'Str' }    # {isa => enum([qw/FDATA SDATA MDATA/])}
    );

    my $format = delete $args{format};

    return $self->binary_query(
        command => "CALC${channel}:DATA:CALL? $format",
        %args
    );

}

sub sparam_catalog {
    my $self = shift;

    my $catalog = $self->cached_calculate_data_call_catalog();
    my @complex_catalog;

    for my $sparam ( @{$catalog} ) {
        push @complex_catalog, "Re($sparam)", "Im($sparam)";
    }

    return \@complex_catalog;
}

sub sparam_sweep_data {
    my ( $self, %args ) = validated_getter( \@_ );

    my $byte_order = $self->cached_format_border();
    if ( $byte_order ne 'SWAP' ) {
        carp 'setting network byteorder to little endian.';
        $self->format_border( value => 'SWAP' );
    }

    # Start single sweep.
    $self->initiate_immediate();

    # Wait until single sweep is finished.
    $self->wai();

    return $self->calculate_data_call( format => 'SDATA', %args );
}



__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::RS_ZVA - Rohde & Schwarz ZVA Vector Network Analyzer

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 my $data = $zva->sparam_sweep(timeout => 10);
 my $matrix = $data->matrix;

=head1 METHODS

See L<Lab::Moose::Instrument::VNASweep> for the high-level C<sparam_sweep> and
C<sparam_catalog> methods.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
