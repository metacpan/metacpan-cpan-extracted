package Lab::Moose::Instrument::Rigol_DSA815;
$Lab::Moose::Instrument::Rigol_DSA815::VERSION = '3.682';
#ABSTRACT: Rigol DSA815 Spectrum Analyzer

use 5.010;

use PDL::Core qw/pdl cat nelem/;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    timeout_param
    precision_param
    validated_getter
    validated_setter
    validated_channel_getter
    validated_channel_setter
    /;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

with 'Lab::Moose::Instrument::SpectrumAnalyzer', qw(
    Lab::Moose::Instrument::Common

    Lab::Moose::Instrument::SCPI::Format

    Lab::Moose::Instrument::SCPI::Sense::Bandwidth
    Lab::Moose::Instrument::SCPI::Sense::Frequency
    Lab::Moose::Instrument::SCPI::Sense::Sweep
    Lab::Moose::Instrument::SCPI::Sense::Power
    Lab::Moose::Instrument::SCPI::Display::Window
    Lab::Moose::Instrument::SCPI::Unit

    Lab::Moose::Instrument::SCPI::Initiate

    Lab::Moose::Instrument::SCPIBlock

);

sub BUILD {
    my $self = shift;

    # limitation of hardware
    $self->capable_to_query_number_of_X_points_in_hardware(0);
    $self->capable_to_set_number_of_X_points_in_hardware(0);
    $self->hardwired_number_of_X_points(601);

    $self->clear();
    $self->cls();
    sleep 1; # for Rigol Spectrum Analyzer we need to wait otherwise instrument is not ready
}


sub validate_trace_param {
    my ( $self, $trace ) = @_;
    if ( $trace < 1 || $trace > 3 ) {
        confess "trace has to be in (1..3)";
    }
    return $trace;
}


sub sense_sweep_points_query {
    confess(
        "sub sense_sweep_points_query is not implemented by hardware, we should not be here"
    );
}

sub sense_sweep_points {
    confess(
        "sub sense_sweep_points is not implemented by hardware, we should not be here"
    );
}


__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Rigol_DSA815 - Rigol DSA815 Spectrum Analyzer

=head1 VERSION

version 3.682

=head1 Driver for Rigol DSA800 series spectrum analyzers

=head1 METHODS

=head2 validate_trace_param

Validates or applies hardware friendly  aliases to trace parameter.
Trace has to be in (1..3).

=head1 Missing SCPI functionality

Rigol DSA815 has no Sense:Sweep:Points implementation

=head2 sense_sweep_points_query

=head2 sense_sweep_points

=head1 Consumed Roles

This driver consumes the following roles:

=over

=item L<Lab::Moose::Instrument::Common>

=item L<Lab::Moose::Instrument::SCPI::Format>

=item L<Lab::Moose::Instrument::SCPI::Sense::Bandwidth>

=item L<Lab::Moose::Instrument::SCPI::Sense::Frequency>

=item L<Lab::Moose::Instrument::SCPI::Sense::Sweep>

=item L<Lab::Moose::Instrument::SCPI::Initiate>

=item L<Lab::Moose::Instrument::SCPIBlock>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Eugeniy E. Mikhailov


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
