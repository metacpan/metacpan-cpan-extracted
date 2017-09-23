package Lab::Moose::Instrument::SCPI::Calculate::Data;
#ABSTRACT: ???
$Lab::Moose::Instrument::SCPI::Calculate::Data::VERSION = '3.600';
use 5.010;
use Moose::Role;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints;
use Lab::Moose::Instrument::Cache;
use Data::Dumper;

use Lab::Moose::Instrument qw/
    channel_param
    getter_params
    validated_channel_getter
    validated_channel_setter
    /;

use namespace::autoclean;

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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Calculate::Data - ???

=head1 VERSION

version 3.600

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
