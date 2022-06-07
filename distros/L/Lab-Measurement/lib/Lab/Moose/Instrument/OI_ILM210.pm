package Lab::Moose::Instrument::OI_ILM210;
$Lab::Moose::Instrument::OI_ILM210::VERSION = '3.820';
#ABSTRACT: Oxford Instruments ILM Intelligent Helium Level Meter

use v5.20;

use Moose;
use Lab::Moose::Instrument qw/
    validated_no_param_setter
    /;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

sub BUILD {
    my $self = shift;

    warn "The ILM driver is work in progress. You have been warned\n";

    # Unlike modern GPIB equipment, this device does not assert the EOI
    # at end of message. The controller shell stop reading when receiving the
    # eos byte.

    $self->connection->set_termchar( termchar => "\r" );
    $self->connection->enable_read_termchar();
    $self->clear();

}

sub get_level {
    my ( $self, %args ) = validated_no_param_setter(
        \@_,
        channel => { isa => 'Int', default => 1 },
    );

    my $channel = delete $args{channel};

    my $level = $self->query( command => "R$channel\r" );
    $level =~ s/^R//;
    $level /= 10;
    return $level;
}

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::OI_ILM210 - Oxford Instruments ILM Intelligent Helium Level Meter

=head1 VERSION

version 3.820

=head1 DESCRIPTION

Driver for the Oxford Instruments ILM210 Intelligent Level Meter.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by the Lab::Measurement team; in detail:

  Copyright 2021       Andreas K. Huettel, Fabian Weinelt, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
