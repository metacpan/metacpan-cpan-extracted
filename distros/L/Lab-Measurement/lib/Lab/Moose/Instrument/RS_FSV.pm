package Lab::Moose::Instrument::RS_FSV;
$Lab::Moose::Instrument::RS_FSV::VERSION = '3.682';
#ABSTRACT: Rohde & Schwarz FSV Signal and Spectrum Analyzer

use 5.010;

use PDL::Core qw/pdl cat/;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/timeout_param precision_param/;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::Common

    Lab::Moose::Instrument::SCPI::Format

    Lab::Moose::Instrument::SCPI::Sense::Bandwidth
    Lab::Moose::Instrument::SCPI::Sense::Frequency
    Lab::Moose::Instrument::SCPI::Sense::Sweep

    Lab::Moose::Instrument::SCPI::Initiate

    Lab::Moose::Instrument::SCPIBlock

);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}



sub get_spectrum {
    my ( $self, %args ) = validated_hash(
        \@_,
        timeout_param(),
        precision_param(),
        trace => { isa => 'Int', default => 1 },
    );

    my $precision = delete $args{precision};

    my $trace = delete $args{trace};

    if ( $trace < 1 || $trace > 6 ) {
        croak "trace has to be in (1..6)";
    }

    my $freq_array = $self->sense_frequency_linear_array();

    # Ensure single sweep mode.
    if ( $self->cached_initiate_continuous() ) {
        $self->initiate_continuous( value => 0 );
    }

    # Ensure correct data format
    $self->set_data_format_precision( precision => $precision );

    # Get data.
    my $num_points = @{$freq_array};
    $args{read_length} = $self->block_length(
        precision  => $precision,
        num_points => $num_points
    );
    $self->initiate_immediate();
    $self->wai();
    my $binary = $self->binary_query(
        command => "TRAC? TRACE$trace",
        %args
    );
    my $points_ref = pdl $self->block_to_array(
        binary    => $binary,
        precision => $precision
    );

    return cat( ( pdl $freq_array), $points_ref );

}


#
#
# Stuff from legacy Lab::Instrument::SpectrumSCPI
# Needs cleanup and docs.
#
#

# sub selftest {
#     my $self = shift;
#     return $self->query("*TST");
# }

# sub reset {
#     my $self = shift;
#     $self->write("*RST");
# }

# sub set_power_unit {
#     my $self = shift;
#     my $unit = shift || "DBM";    #DBM, W
#     $self->write("UNIT:POW $unit");
# }

# sub set_frequency {
#     my $self = shift;
#     my $freq = shift || "DEF";    #Hz
#     $self->write("FREQ:CENT $freq");
# }

# sub set_span {
#     my $self = shift;
#     my $span = shift || "DEF";    #Hz
#     $self->write("FREQ:SPAN $span");
# }

# sub set_bandwidth {
#     my $self = shift;
#     my $bw = shift || "DEF";    #Hz
#     $self->write("BAND:RES $bw");
# }

# sub set_sweep_time {
#     my $self = shift;
#     my $time = shift || "DEF";    #Hz
#     $self->write("SWE:Time $time");
# }

# sub set_continous {
#     my $self = shift;
#     my $cont = shift || "ON";    #ON, OFF
#     $self->write("INIT:CONT $cont");
# }

# sub auto_adjust_level {
#     my $self = shift;
#     $self->write(command => "SENSe:ADJ:LEVel");
# }

# #NOTE: In auto attenation mode this function also switches attenuators.
# sub set_reference_level {
#     my $self = shift;
#     my $level = shift || "0";    #in dBm
#     $self->write(command => "DISP:TRACe:Y:RLEVel $level");
# }

# sub set_preamp {
#     my $self = shift;
#     my $state = shift || "OFF";    #ON, OFF
#     $self->write(command => "INPut:GAIN:STATe $state");
# }

# sub set_marker_auto_peak {
#     my $self   = shift;
#     my $state  = shift || "ON";
#     my $marker = shift || 1;
#     $self->write(command => "CALC:MARKer$marker:MAX:AUTO $state");
# }

# sub get_marker_frequency {
#     my $self = shift;
#     my $marker = shift || 1;
#     return $self->query(command => "CALC:MARK:X?");
# }

# sub get_marker_level {
#     my $self = shift;
#     my $marker = shift || 1;
#     return $self->query(command => "CALC:MARK:Y?");
# }

# sub set_time_domain {
#     my $self = shift;
#     my $freq = shift;
#     my $bw   = shift;
#     $self->set_continous("OFF");
#     $self->set_frequency($freq);
#     $self->set_span("0 Hz");
#     $self->set_bandwidth($bw);
#     $self->set_sweep_time("2000 US");    #TODO
# }

# sub single_sweep {
#     my $self = shift;
#     $self->write(command => "INIT;*WAI");
# }

# sub read_rms {
#     my $self = shift;
#     $self->single_sweep();
#     $self->write(command => "CALC:MARK:FUNC:SUMM:RMS ON");
#     return $self->query(command => ":CALC:MARK:FUNC:SUMM:RMS:RES?");
# }

# sub read {
#     my $self = shift;

#     #TODO: Check other modes
#     return $self->query(command => "READ?");

# }

# sub get_error {
#     my $self          = shift;
#     my $current_error = "";
#     my $all_errors    = "";
#     my $max_errors    = 5;
#     while ( $max_errors-- ) {
#         $current_error = $self->query(command => 'SYST:ERR?');
#         if ( $current_error eq "" ) {
#             $all_errors .= "Could not read error message!\n";
#             last;
#         }
#         if ( $current_error =~ m/^\+?0,/ ) { last; }
#         $all_errors .= $current_error . "\n";
#     }
#     if ( !$max_errors ) { $all_errors .= "Maximum Error count reached!\n"; }
#     $self->write(command => "*CLS");    #Clear errors
#     chomp($all_errors);
#     return $all_errors;
# }

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::RS_FSV - Rohde & Schwarz FSV Signal and Spectrum Analyzer

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 my $data = $fsv->get_spectrum(timeout => 10);

=head1 METHODS

This driver implements the following high-level method:

=head2 get_spectrum

 $data = $fsv->get_spectrum(timeout => 10, trace => 2, precision => 'double');

Perform a single sweep and return the resulting spectrum as a 2D PDL:

 [
  [freq1,  freq2,  freq3,  ...,  freqN],
  [power1, power2, power3, ..., powerN],
 ]

I.e. the first dimension runs over the sweep points.

This method accepts a hash with the following options:

=over

=item B<timeout>

timeout for the sweep operation. If this is not given, use the connection's
default timeout.

=item B<trace>

number of the trace (1..6). Defaults to 1.

=item B<precision>

floating point type. Has to be 'single' or 'double'. Defaults to 'single'.

=back

=head2 Consumed Roles

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

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
