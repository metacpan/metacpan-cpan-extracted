package Lab::Moose::Instrument::SCPI::Sense::Range;
$Lab::Moose::Instrument::SCPI::Sense::Range::VERSION = '3.682';
#ABSTRACT: Role for the SCPI SENSe:$function:RANGe subsystem.

use Moose::Role;
use Moose::Util::TypeConstraints 'enum';
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;

use namespace::autoclean;


requires 'cached_sense_function';

cache sense_range => ( getter => 'sense_range_query' );

sub sense_range_query {
    my ( $self, %args ) = validated_getter( \@_ );

    my $func = $self->cached_sense_function();

    return $self->cached_sense_range(
        $self->query( command => "SENS:$func:RANG?", %args ) );
}

sub sense_range {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
    );

    my $func = $self->cached_sense_function();

    $self->write( command => "SENS:$func:RANG $value", %args );

    $self->cached_sense_range($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Sense::Range - Role for the SCPI SENSe:$function:RANGe subsystem.

=head1 VERSION

version 3.682

=head1 METHODS

=head2 sense_range_query

=head2 sense_range

 $self->sense_range(value => '0.001');

Query/Set the input range.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017-2018  Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
