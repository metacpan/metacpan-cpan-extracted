package Lab::Moose::Instrument::SCPI::Output::State;
$Lab::Moose::Instrument::SCPI::Output::State::VERSION = '3.682';
#ABSTRACT: Role for the SCPI OUTPut:STATe subsystem

use Moose::Role;
use Moose::Util::TypeConstraints 'enum';
use Lab::Moose::Instrument::Cache;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;

use namespace::autoclean;


cache output_state => ( getter => 'output_state_query' );

sub output_state_query {
    my ( $self, %args ) = validated_getter( \@_ );

    return $self->cached_output_state(
        $self->query( command => "OUTP:STAT?", %args ) );
}

sub output_state {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/ON OFF/] ) }
    );

    $self->write( command => "OUTP:STAT $value", %args );
    $self->cached_output_state($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::SCPI::Output::State - Role for the SCPI OUTPut:STATe subsystem

=head1 VERSION

version 3.682

=head1 METHODS

=head2 output_state_query

=head2 output_state

 $self->output_state(value => 'ON');
 $self->output_state(value => 'OFF');

Query/Set whether output is on or off. Allowed values: C<ON, OFF>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
