package Lab::Moose::Instrument::SCPI::Source::Level;
$Lab::Moose::Instrument::SCPI::Source::Level::VERSION = '3.682';
#ABSTRACT: Role for the SCPI SOURce:(CURRent|VOLTage):Level commands

use Moose::Role;
use Moose::Util::TypeConstraints 'enum';
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;
use namespace::autoclean;


with 'Lab::Moose::Instrument::SCPI::Source::Function';

cache source_level => ( getter => 'source_level_query' );

sub source_level_query {
    my ( $self, %args ) = validated_getter( \@_ );

    my $function = $self->cached_source_function();

    return $self->cached_source_level(
        $self->query( command => "SOUR:$function:LEV?", %args ) );
}

sub source_level {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );

    my $function = $self->cached_source_function();

    $self->write(
        command => sprintf( "SOUR:$function:LEV %.15g", $value ),
        %args
    );
    $self->cached_source_level($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Source::Level - Role for the SCPI SOURce:(CURRent|VOLTage):Level commands

=head1 VERSION

version 3.682

=head1 METHODS

=head2 source_level_query

=head2 source_level

 $self->source_level(value => '0.001');

Query/Set the output level.
The type of output signal is determined with the SCPI::Source::Function role.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
