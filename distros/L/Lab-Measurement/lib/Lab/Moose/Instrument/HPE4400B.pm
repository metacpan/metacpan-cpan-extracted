package Lab::Moose::Instrument::HPE4400B;
$Lab::Moose::Instrument::HPE4400B::VERSION = '3.770';
#ABSTRACT: HP E4400B Series Spectrum Analyzer

use v5.20;


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
    my $firmware = $self->idn_firmware;
    my $model = $self->idn_model;
    if (!$firmware ||
         $firmware !~ /^A\.(\d+)\.\d+$/ ||
         $1 < 4)
    {
         $self->capable_to_query_number_of_X_points_in_hardware(0);
    }

    if (!$model || $model !~ /^E440[12457]B$/) {
        print STDERR "Model $model does not support setting X points\n";
        $self->capable_to_set_number_of_X_points_in_hardware(0);
        $self->hardwired_number_of_X_points(401);
    }

    $self->clear();
    $self->cls();
}


sub validate_trace_param {
    my ( $self, $trace ) = @_;
    if ( $trace < 1 || $trace > 3 ) {
        confess "trace has to be in (1..3)";
    }
    return $trace;
}


__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::HPE4400B - HP E4400B Series Spectrum Analyzer

=head1 VERSION

version 3.770

=head1 Driver for HP E4400B series spectrum analyzers

=head1 METHODS

=head2 validate_trace_param

Validates or applies hardware friendly  aliases to trace parameter.
Trace has to be in (1..3).

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

This software is copyright (c) 2021 by the Lab::Measurement team; in detail:

  Copyright 2020       Andreas K. Huettel, Sam Bingner


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
