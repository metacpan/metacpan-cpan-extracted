package Lab::Moose::Instrument::SCPI::Sense::NPLC;
$Lab::Moose::Instrument::SCPI::Sense::NPLC::VERSION = '3.682';
#ABSTRACT: Role for the SCPI SENSe:$function:NPLC subsystem

use Moose::Role;
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;

use namespace::autoclean;


requires 'cached_sense_function';

cache sense_nplc => ( getter => 'sense_nplc_query' );

sub sense_nplc_query {
    my ( $self, %args ) = validated_getter( \@_ );

    my $func = $self->cached_sense_function();

    return $self->cached_sense_nplc(
        $self->query( command => "SENS:$func:NPLC?", %args ) );
}

sub sense_nplc {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );

    my $func = $self->cached_sense_function();

    $self->write( command => "SENS:$func:NPLC $value", %args );

    $self->cached_sense_nplc($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Sense::NPLC - Role for the SCPI SENSe:$function:NPLC subsystem

=head1 VERSION

version 3.682

=head1 METHODS

=head2 sense_nplc_query

=head2 sense_nplc

 $self->sense_nplc(value => '0.001');

Query/Set the input nplc.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017-2018  Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
