package Lab::Moose::Instrument::SCPI::Source::Range;
$Lab::Moose::Instrument::SCPI::Source::Range::VERSION = '3.682';
#ABSTRACT: Role for the SCPI SOURce:RANGe subsystem.

use Moose::Role;
use Moose::Util::TypeConstraints 'enum';
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;

use namespace::autoclean;


with 'Lab::Moose::Instrument::SCPI::Source::Function';

cache source_range => ( getter => 'source_range_query' );

sub source_range_query {
    my ( $self, %args ) = validated_getter( \@_ );

    my $function = $self->cached_source_function();
    return $self->cached_source_range(
        $self->query( command => "SOUR:$function:RANG?", %args ) );
}

sub source_range {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
    );

    my $function = $self->cached_source_function();
    $self->write( command => "SOUR:$function:RANG $value", %args );

    $self->cached_source_range($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Source::Range - Role for the SCPI SOURce:RANGe subsystem.

=head1 VERSION

version 3.682

=head1 METHODS

=head2 source_range_query

=head2 source_range

 $self->source_range(value => '0.001');

Query/Set the output range.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017-2018  Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
