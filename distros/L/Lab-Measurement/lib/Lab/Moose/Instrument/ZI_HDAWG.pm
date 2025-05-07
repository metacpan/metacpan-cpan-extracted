package Lab::Moose::Instrument::ZI_HDAWG;
$Lab::Moose::Instrument::ZI_HDAWG::VERSION = '3.931';
#ABSTRACT: Zurich Instruments HDAWG Arbitrary Waveform Generator

# Notes for further developement:

	# out-commented functions
		# All functions that are uncommented have been tested, all out-commented
		# functions were not tested because of missing features or other issues.
		# In particular, functions that set connectivity options could not be tested
		# as they result in a lost of connection to the device.
	# Modules:
		# Implementation is missing Module controll as it is not supported by Lab::Zhinst.
		# This driver has to be expanded once Lab::Zhinst functionality is incremented.
		# In particular the use of the sequencere module is very limited for lack of controll
		# over internal scripts and compiler options
	# Vector functions:
		# A total of 11 functions that make use of datatype ZIVectorData have been omitted,
		# this again for lack of support from Lab::Zhinst or Zhinst.pl connection type.
use v5.20;
use Moose;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/validated_setter validated_getter/;
use namespace::autoclean;
extends 'Lab::Moose::Instrument::Zhinst';





sub set_awgs_auxtriggers_channel {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		auxtrigger=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	my $auxtrigger=delete $args{auxtrigger};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/auxtriggers/$auxtrigger/channel",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_auxtriggers_channel {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		auxtrigger=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	my $auxtrigger =delete $args{auxtrigger};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/auxtriggers/$auxtrigger/channel",
			type=>'I',
		);
}



sub set_awgs_auxtriggers_slope {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		auxtrigger=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	my $auxtrigger=delete $args{auxtrigger};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/auxtriggers/$auxtrigger/slope",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_auxtriggers_slope {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		auxtrigger=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	my $auxtrigger =delete $args{auxtrigger};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/auxtriggers/$auxtrigger/slope",
			type=>'I',
		);
}



sub get_awgs_auxtriggers_state {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		auxtrigger=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	my $auxtrigger =delete $args{auxtrigger};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/auxtriggers/$auxtrigger/state",
			type=>'I',
		);
}



sub set_awgs_commandtable_clear {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/commandtable/clear",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_commandtable_clear {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/commandtable/clear",
			type=>'I',
		);
}



sub get_awgs_commandtable_status {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/commandtable/status",
			type=>'I',
		);
}



sub set_awgs_dio_delay_index {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/dio/delay/index",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_dio_delay_index {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/dio/delay/index",
			type=>'I',
		);
}



sub set_awgs_dio_delay_value {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/dio/delay/value",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_dio_delay_value {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/dio/delay/value",
			type=>'I',
		);
}



sub set_awgs_dio_error_timing {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/dio/error/timing",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_dio_error_timing {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/dio/error/timing",
			type=>'I',
		);
}



sub set_awgs_dio_error_width {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/dio/error/width",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_dio_error_width {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/dio/error/width",
			type=>'I',
		);
}



sub set_awgs_dio_highbits {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/dio/highbits",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_dio_highbits {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/dio/highbits",
			type=>'I',
		);
}



sub set_awgs_dio_lowbits {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/dio/lowbits",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_dio_lowbits {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/dio/lowbits",
			type=>'I',
		);
}



sub set_awgs_dio_mask_shift {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/dio/mask/shift",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_dio_mask_shift {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/dio/mask/shift",
			type=>'I',
		);
}



sub set_awgs_dio_mask_value {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/dio/mask/value",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_dio_mask_value {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/dio/mask/value",
			type=>'I',
		);
}



sub set_awgs_dio_state {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/dio/state",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_dio_state {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/dio/state",
			type=>'I',
		);
}



sub set_awgs_dio_strobe_index {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/dio/strobe/index",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_dio_strobe_index {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/dio/strobe/index",
			type=>'I',
		);
}



sub set_awgs_dio_strobe_slope {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/dio/strobe/slope",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_dio_strobe_slope {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/dio/strobe/slope",
			type=>'I',
		);
}



sub set_awgs_dio_strobe_width {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/dio/strobe/width",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_dio_strobe_width {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/dio/strobe/width",
			type=>'I',
		);
}



sub set_awgs_dio_valid_index {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/dio/valid/index",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_dio_valid_index {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/dio/valid/index",
			type=>'I',
		);
}



sub set_awgs_dio_valid_polarity {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/dio/valid/polarity",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_dio_valid_polarity {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/dio/valid/polarity",
			type=>'I',
		);
}



sub set_awgs_dio_valid_width {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/dio/valid/width",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_dio_valid_width {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/dio/valid/width",
			type=>'I',
		);
}



sub get_awgs_elf_checksum {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/elf/checksum",
			type=>'I',
		);
}



sub get_awgs_elf_length {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/elf/length",
			type=>'I',
		);
}



sub get_awgs_elf_memoryusage {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/elf/memoryusage",
			type=>'D',
		);
}



sub get_awgs_elf_progress {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/elf/progress",
			type=>'D',
		);
}



sub set_awgs_enable {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/enable",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_enable {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/enable",
			type=>'I',
		);
}



sub set_awgs_outputs_amplitude {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		output=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	my $output=delete $args{output};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/outputs/$output/amplitude",
			type=>'D',
			value =>$value
		);
}

sub get_awgs_outputs_amplitude {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		output=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	my $output =delete $args{output};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/outputs/$output/amplitude",
			type=>'D',
		);
}



sub get_awgs_outputs_enables_k {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		output=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	my $output =delete $args{output};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/outputs/$output/enables/k",
			type=>'I',
		);
}



sub set_awgs_outputs_gains {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		output=>{isa => 'Int'},
        gain =>{isa => 'Int'},
		value =>{isa =>'Num'},
	);
    my $awg=delete $args{awg};
	my $output=delete $args{output};
    my $gain =delete $args{gain};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/outputs/$output/gains/$gain",
			type=>'D',
			value =>$value
		);
}

sub get_awgs_outputs_gains {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		output=>{isa => 'Int'},
        gain=> { isa=> 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	my $output =delete $args{output};
    my $gain =delete $args{gain};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/outputs/$output/gains/$gain",
			type=>'D',
		);
}



sub set_awgs_outputs_hold {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		output=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	my $output=delete $args{output};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/outputs/$output/hold",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_outputs_hold {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		output=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	my $output =delete $args{output};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/outputs/$output/hold",
			type=>'I',
		);
}


 


sub get_awgs_outputs_modulation_carriers_freq {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		output=>{isa => 'Int'},
        carrier =>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	my $output =delete $args{output};
    my $carrier = delete $args{carrier};
    print($self->device()."/awgs/$awg/outputs/$output/modulation/carriers/$carrier/freq\n");
	return $self->get_value(
			path => $self->device()."/awgs/$awg/outputs/$output/modulation/carriers/$carrier/freq",
			type=>'D',
		);
}





sub set_awgs_outputs_modulation_carriers_harmonic {
        my ($self, $value, %args) = validated_setter(
                \@_,
                awg=>{isa => 'Int'},
                output=>{isa => 'Int'},
                carrier=>{isa => 'Int'},
                value =>{isa =>'Num'},
        );
        my $awg=delete $args{awg};
        my $output=delete $args{output};
        my $carrier = delete $args{carrier};
        return $self->sync_set_value(
                        path => $self->device()."/awgs/$awg/outputs/$output/modulation/carriers/$carrier/harmonic",
                        type=>'I',
                        value =>$value
                );
}



sub get_awgs_outputs_modulation_carriers_harmonic {
        my ($self, $value, %args) = validated_setter(
                \@_,
                awg=>{isa => 'Int'},
                output=>{isa => 'Int'},
                carrier=>{isa => 'Int'},
                value =>{isa =>'Num',optional=>1},
        );
        my $awg =delete $args{awg};
        my $output =delete $args{output};
        my $carrier = delete $args{carrier};
        return $self->get_value(
                        path => $self->device()."/awgs/$awg/outputs/$output/modulation/carriers/$carrier/harmonic",
                        type=>'I',
                );
}





sub set_awgs_outputs_modulation_carriers_k_oscselect {
        my ($self, $value, %args) = validated_setter(
                \@_,
                awg=>{isa => 'Int'},
                output=>{isa => 'Int'},
                carrier=>{isa=>'Int'},
                value =>{isa =>'Num'},
        );
        my $awg=delete $args{awg};
        my $output=delete $args{output};
        my $carrier = delete $args{carrier};
        return $self->sync_set_value(
                        path => $self->device()."/awgs/$awg/outputs/$output/modulation/carriers/$carrier/oscselect",
                        type=>'I',
                        value =>$value
                );
}



sub get_awgs_outputs_modulation_carriers_k_oscselect {
        my ($self, $value, %args) = validated_setter(
                \@_,
                awg=>{isa => 'Int'},
                output=>{isa => 'Int'},
                carrier=>{isa => 'Int'},
                value =>{isa =>'Num',optional=>1},
        );
        my $awg =delete $args{awg};
        my $output =delete $args{output};
        my $carrier = delete $args{carrier};
        return $self->get_value(
                        path => $self->device()."/awgs/$awg/outputs/$output/modulation/carriers/$carrier/oscselect",
                        type=>'I',
                );
}





sub set_awgs_outputs_modulation_carriers_phaseshift {
        my ($self, $value, %args) = validated_setter(
                \@_,
                awg=>{isa => 'Int'},
                output=>{isa => 'Int'},
                carrier => {isa=> 'Int'},
                value =>{isa =>'Num'},
        );
        my $awg=delete $args{awg};
        my $output=delete $args{output};
        my $carrier = delete $args{carrier};
        return $self->sync_set_value(
                        path => $self->device()."/awgs/$awg/outputs/$output/modulation/carriers/$carrier/phaseshift",
                        type=>'D',
                        value =>$value
                );
}



sub get_awgs_outputs_modulation_carriers_phaseshift {
        my ($self, $value, %args) = validated_setter(
                \@_,
                awg=>{isa => 'Int'},
                output=>{isa => 'Int'},
                carrier=>{isa=> 'Int'},
                value =>{isa =>'Num',optional=>1},
        );
        my $awg =delete $args{awg};
        my $output =delete $args{output};
        my $carrier = delete $args{carrier};
        return $self->get_value(
                        path => $self->device()."/awgs/$awg/outputs/$output/modulation/carriers/$carrier/phaseshift",
                        type=>'D',
                );
}



sub set_awgs_outputs_modulation_mode {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		output=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	my $output=delete $args{output};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/outputs/$output/modulation/mode",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_outputs_modulation_mode {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		output=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	my $output =delete $args{output};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/outputs/$output/modulation/mode",
			type=>'I',
		);
}



sub get_awgs_ready {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/ready",
			type=>'I',
		);
}



sub set_awgs_reset {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/reset",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_reset {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/reset",
			type=>'I',
		);
}



sub set_awgs_rtlogger_clear {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/rtlogger/clear",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_rtlogger_clear {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/rtlogger/clear",
			type=>'I',
		);
}



sub set_awgs_rtlogger_enable {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/rtlogger/enable",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_rtlogger_enable {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/rtlogger/enable",
			type=>'I',
		);
}



sub set_awgs_rtlogger_mode {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/rtlogger/mode",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_rtlogger_mode {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/rtlogger/mode",
			type=>'I',
		);
}



sub set_awgs_rtlogger_starttimestamp {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/rtlogger/starttimestamp",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_rtlogger_starttimestamp {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/rtlogger/starttimestamp",
			type=>'I',
		);
}



sub get_awgs_rtlogger_status {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/rtlogger/status",
			type=>'I',
		);
}



sub get_awgs_rtlogger_timebase {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/rtlogger/timebase",
			type=>'D',
		);
}



sub set_awgs_sequencer_continue {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/sequencer/continue",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_sequencer_continue {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/sequencer/continue",
			type=>'I',
		);
}



sub get_awgs_sequencer_memoryusage {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/sequencer/memoryusage",
			type=>'D',
		);
}



sub set_awgs_sequencer_next {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/sequencer/next",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_sequencer_next {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/sequencer/next",
			type=>'I',
		);
}



sub get_awgs_sequencer_pc {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/sequencer/pc",
			type=>'I',
		);
}



sub get_awgs_sequencer_status {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/sequencer/status",
			type=>'I',
		);
}



sub get_awgs_sequencer_triggered {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/sequencer/triggered",
			type=>'I',
		);
}



sub set_awgs_single {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/single",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_single {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/single",
			type=>'I',
		);
}



sub set_awgs_sweep_awgtrigs {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
        trig=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);
    my $awg=delete $args{awg};
    my $trig = delete $args{trig};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/sweep/awgtrigs/$trig",
			type=>'D',
			value =>$value
		);
}

sub get_awgs_sweep_awgtrigs {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
        trig => {isa=> 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
    my $trig = delete $args{trig};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/sweep/awgtrigs/m",
			type=>'D',
		);
}



sub set_awgs_time {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/time",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_time {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/time",
			type=>'I',
		);
}



sub set_awgs_userregs {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
        userregs =>{isa=> 'Int'},
		value =>{isa =>'Num'},
	);
    my $awg=delete $args{awg};
    my $userregs = delete $args{userregs};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/userregs/$userregs",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_userregs {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
        userregs =>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
    my $userregs = delete $args{userregs};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/userregs/$userregs",
			type=>'I',
		);
}



sub get_awgs_waveform_memoryusage {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/waveform/memoryusage",
			type=>'D',
		);
}



sub get_awgs_waveform_playing {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/waveform/playing",
			type=>'I',
		);
}



sub set_awgs_zsync_decoder_mask {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/zsync/decoder/mask",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_zsync_decoder_mask {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/zsync/decoder/mask",
			type=>'I',
		);
}



sub set_awgs_zsync_decoder_offset {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/zsync/decoder/offset",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_zsync_decoder_offset {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/zsync/decoder/offset",
			type=>'I',
		);
}



sub set_awgs_zsync_decoder_shift {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/zsync/decoder/shift",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_zsync_decoder_shift {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/zsync/decoder/shift",
			type=>'I',
		);
}



sub set_awgs_zsync_register_mask {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/zsync/register/mask",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_zsync_register_mask {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/zsync/register/mask",
			type=>'I',
		);
}



sub set_awgs_zsync_register_offset {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/zsync/register/offset",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_zsync_register_offset {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/zsync/register/offset",
			type=>'I',
		);
}



sub set_awgs_zsync_register_shift {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $awg=delete $args{awg};
	return $self->sync_set_value(
			path => $self->device()."/awgs/$awg/zsync/register/shift",
			type=>'I',
			value =>$value
		);
}

sub get_awgs_zsync_register_shift {
	my ($self, $value, %args) = validated_setter(
		\@_,
		awg=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $awg =delete $args{awg};
	return $self->get_value(
			path => $self->device()."/awgs/$awg/zsync/register/shift",
			type=>'I',
		);
}



sub get_clockbase {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/clockbase",
			type=>'D',
		);
}


sub set_cnts_enable {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $cnt=delete $args{cnt};
	return $self->sync_set_value(
			path => $self->device()."/cnts/$cnt/enable",
			type=>'I',
			value =>$value
		);
}

sub get_cnts_enable {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $cnt =delete $args{cnt};
	return $self->get_value(
			path => $self->device()."/cnts/$cnt/enable",
			type=>'I',
		);
}



sub set_cnts_gateselect {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $cnt=delete $args{cnt};
	return $self->sync_set_value(
			path => $self->device()."/cnts/$cnt/gateselect",
			type=>'I',
			value =>$value
		);
}

sub get_cnts_gateselect {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $cnt =delete $args{cnt};
	return $self->get_value(
			path => $self->device()."/cnts/$cnt/gateselect",
			type=>'I',
		);
}



sub set_cnts_inputselect {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $cnt=delete $args{cnt};
	return $self->sync_set_value(
			path => $self->device()."/cnts/$cnt/inputselect",
			type=>'I',
			value =>$value
		);
}

sub get_cnts_inputselect {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $cnt =delete $args{cnt};
	return $self->get_value(
			path => $self->device()."/cnts/$cnt/inputselect",
			type=>'I',
		);
}



sub set_cnts_integrate {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $cnt=delete $args{cnt};
	return $self->sync_set_value(
			path => $self->device()."/cnts/$cnt/integrate",
			type=>'I',
			value =>$value
		);
}

sub get_cnts_integrate {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $cnt =delete $args{cnt};
	return $self->get_value(
			path => $self->device()."/cnts/$cnt/integrate",
			type=>'I',
		);
}



sub set_cnts_mode {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $cnt=delete $args{cnt};
	return $self->sync_set_value(
			path => $self->device()."/cnts/$cnt/mode",
			type=>'I',
			value =>$value
		);
}

sub get_cnts_mode {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $cnt =delete $args{cnt};
	return $self->get_value(
			path => $self->device()."/cnts/$cnt/mode",
			type=>'I',
		);
}



sub set_cnts_operation {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $cnt=delete $args{cnt};
	return $self->sync_set_value(
			path => $self->device()."/cnts/$cnt/operation",
			type=>'I',
			value =>$value
		);
}

sub get_cnts_operation {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $cnt =delete $args{cnt};
	return $self->get_value(
			path => $self->device()."/cnts/$cnt/operation",
			type=>'I',
		);
}



sub set_cnts_period {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $cnt=delete $args{cnt};
	return $self->sync_set_value(
			path => $self->device()."/cnts/$cnt/period",
			type=>'D',
			value =>$value
		);
}

sub get_cnts_period {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $cnt =delete $args{cnt};
	return $self->get_value(
			path => $self->device()."/cnts/$cnt/period",
			type=>'D',
		);
}



sub set_cnts_trigfalling {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $cnt=delete $args{cnt};
	return $self->sync_set_value(
			path => $self->device()."/cnts/$cnt/trigfalling",
			type=>'I',
			value =>$value
		);
}

sub get_cnts_trigfalling {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $cnt =delete $args{cnt};
	return $self->get_value(
			path => $self->device()."/cnts/$cnt/trigfalling",
			type=>'I',
		);
}



sub set_cnts_trigrising {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $cnt=delete $args{cnt};
	return $self->sync_set_value(
			path => $self->device()."/cnts/$cnt/trigrising",
			type=>'I',
			value =>$value
		);
}

sub get_cnts_trigrising {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $cnt =delete $args{cnt};
	return $self->get_value(
			path => $self->device()."/cnts/$cnt/trigrising",
			type=>'I',
		);
}



sub get_cnts_value {
	my ($self, $value, %args) = validated_setter(
		\@_,
		cnt=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $cnt =delete $args{cnt};
	return $self->get_value(
			path => $self->device()."/cnts/$cnt/value",
			type=>'I',
		);
}



sub set_dios_drive {
	my ($self, $value, %args) = validated_setter(
		\@_,
		dio=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $dio=delete $args{dio};
	return $self->sync_set_value(
			path => $self->device()."/dios/$dio/drive",
			type=>'I',
			value =>$value
		);
}

sub get_dios_drive {
	my ($self, $value, %args) = validated_setter(
		\@_,
		dio=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $dio =delete $args{dio};
	return $self->get_value(
			path => $self->device()."/dios/$dio/drive",
			type=>'I',
		);
}



sub get_dios_input {
	my ($self, $value, %args) = validated_setter(
		\@_,
		dio=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $dio =delete $args{dio};
	return $self->get_value(
			path => $self->device()."/dios/$dio/input",
			type=>'I',
		);
}



sub set_dios_interface {
	my ($self, $value, %args) = validated_setter(
		\@_,
		dio=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $dio=delete $args{dio};
	return $self->sync_set_value(
			path => $self->device()."/dios/$dio/interface",
			type=>'I',
			value =>$value
		);
}

sub get_dios_interface {
	my ($self, $value, %args) = validated_setter(
		\@_,
		dio=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $dio =delete $args{dio};
	return $self->get_value(
			path => $self->device()."/dios/$dio/interface",
			type=>'I',
		);
}



sub set_dios_mode {
	my ($self, $value, %args) = validated_setter(
		\@_,
		dio=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $dio=delete $args{dio};
	return $self->sync_set_value(
			path => $self->device()."/dios/$dio/mode",
			type=>'I',
			value =>$value
		);
}

sub get_dios_mode {
	my ($self, $value, %args) = validated_setter(
		\@_,
		dio=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $dio =delete $args{dio};
	return $self->get_value(
			path => $self->device()."/dios/$dio/mode",
			type=>'I',
		);
}



sub set_dios_output {
	my ($self, $value, %args) = validated_setter(
		\@_,
		dio=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $dio=delete $args{dio};
	return $self->sync_set_value(
			path => $self->device()."/dios/$dio/output",
			type=>'I',
			value =>$value
		);
}

sub get_dios_output {
	my ($self, $value, %args) = validated_setter(
		\@_,
		dio=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $dio =delete $args{dio};
	return $self->get_value(
			path => $self->device()."/dios/$dio/output",
			type=>'I',
		);
}




sub set_features_code {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Str'},
	);
	return $self->sync_set_value(
			path => $self->device()."/features/code",
			type=>'B',
			value =>$value
		);
}



sub get_features_devtype {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
		read_length => {isa=>'Int'},
	);
	my $read_length = delete $args{read_length};

	return $self->connection->get_value(
			path => $self->device()."/features/devtype",
			type=>'B',
			read_length =>$read_length
		);
}



sub get_features_options {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
		read_length => {isa=>'Num'}
	);
	my $read_length = delete $args{read_length};
	return $self->connection->get_value(
			path => $self->device()."/features/options",
			type=>'B',
			read_length => $read_length
		);
}



sub get_features_serial {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
		read_length =>{isa=>'Int'}
	);
	my $read_length = delete $args{read_length};

	return $self->connection->get_value(
			path => $self->device()."/features/serial",
			type=>'B',
			read_length=>$read_length
		);
}



sub set_oscs_freq {
	my ($self, $value, %args) = validated_setter(
		\@_,
		osc=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $osc=delete $args{osc};
	return $self->sync_set_value(
			path => $self->device()."/oscs/$osc/freq",
			type=>'D',
			value =>$value
		);
}

sub get_oscs_freq {
	my ($self, $value, %args) = validated_setter(
		\@_,
		osc=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $osc =delete $args{osc};
	return $self->get_value(
			path => $self->device()."/oscs/$osc/freq",
			type=>'D',
		);
}



sub get_oscs_freqawg {
	my ($self, $value, %args) = validated_setter(
		\@_,
		osc=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $osc =delete $args{osc};
	return $self->get_value(
			path => $self->device()."/oscs/$osc/freqawg",
			type=>'D',
		);
}



sub get_sigouts_busy {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sigout=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $sigout =delete $args{sigout};
	return $self->get_value(
			path => $self->device()."/sigouts/$sigout/busy",
			type=>'I',
		);
}



sub set_sigouts_delay {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sigout=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $sigout=delete $args{sigout};
	return $self->sync_set_value(
			path => $self->device()."/sigouts/$sigout/delay",
			type=>'D',
			value =>$value
		);
}

sub get_sigouts_delay {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sigout=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $sigout =delete $args{sigout};
	return $self->get_value(
			path => $self->device()."/sigouts/$sigout/delay",
			type=>'D',
		);
}



sub set_sigouts_direct {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sigout=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $sigout=delete $args{sigout};
	return $self->sync_set_value(
			path => $self->device()."/sigouts/$sigout/direct",
			type=>'I',
			value =>$value
		);
}

sub get_sigouts_direct {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sigout=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $sigout =delete $args{sigout};
	return $self->get_value(
			path => $self->device()."/sigouts/$sigout/direct",
			type=>'I',
		);
}



sub set_sigouts_filter {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sigout=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $sigout=delete $args{sigout};
	return $self->sync_set_value(
			path => $self->device()."/sigouts/$sigout/filter",
			type=>'I',
			value =>$value
		);
}

sub get_sigouts_filter {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sigout=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $sigout =delete $args{sigout};
	return $self->get_value(
			path => $self->device()."/sigouts/$sigout/filter",
			type=>'I',
		);
}



sub get_sigouts_max {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sigout=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $sigout =delete $args{sigout};
	return $self->get_value(
			path => $self->device()."/sigouts/$sigout/max",
			type=>'D',
		);
}



sub get_sigouts_min {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sigout=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $sigout =delete $args{sigout};
	return $self->get_value(
			path => $self->device()."/sigouts/$sigout/min",
			type=>'D',
		);
}



sub set_sigouts_offset {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sigout=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $sigout=delete $args{sigout};
	return $self->sync_set_value(
			path => $self->device()."/sigouts/$sigout/offset",
			type=>'D',
			value =>$value
		);
}

sub get_sigouts_offset {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sigout=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $sigout =delete $args{sigout};
	return $self->get_value(
			path => $self->device()."/sigouts/$sigout/offset",
			type=>'D',
		);
}



sub set_sigouts_on {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sigout=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $sigout=delete $args{sigout};
	return $self->sync_set_value(
			path => $self->device()."/sigouts/$sigout/on",
			type=>'I',
			value =>$value
		);
}

sub get_sigouts_on {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sigout=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $sigout =delete $args{sigout};
	return $self->get_value(
			path => $self->device()."/sigouts/$sigout/on",
			type=>'I',
		);
}



sub get_sigouts_over {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sigout=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $sigout =delete $args{sigout};
	return $self->get_value(
			path => $self->device()."/sigouts/$sigout/over",
			type=>'I',
		);
}

# =head3 /DEV/SIGOUTS/n/PRECOMPENSATION/BOUNCES/m/DELAY 
# Properties: Read Write Setting 
# Type: Double(D)
# Unit: s

#  set_sigouts_precompensation_bounces_delay(sigout => $sigout, bounce => $bounce, value => $value)
#  get_sigouts_precompensation_bounces_delay(sigout => $sigout, bounce => $bounce)

# Sets the delay of the bounce correction filter.
# Note: This option was not available in the device used for developement, it is therefore untested.
# =cut 


# sub set_sigouts_precompensation_bounces_delay {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		sigout=>{isa => 'Int'},
# 		bounce=>{isa => 'Int'},
# 		value =>{isa =>'Num'},
# 	);my $sigout=delete $args{sigout};
# 	my $bounce=delete $args{bounce};
# 	return $self->sync_set_value(
# 			path => $self->device()."/sigouts/$sigout/precompensation/bounces/$bounce/delay",
# 			type=>'D',
# 			value =>$value
# 		);
# }

# sub get_sigouts_precompensation_bounces_delay {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		sigout=>{isa => 'Int'},
# 		bounce=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $sigout =delete $args{sigout};
# 	my $bounce =delete $args{bounce};
# 	return $self->get_value(
# 			path => $self->device()."/sigouts/$sigout/precompensation/bounces/$bounce/delay",
# 			type=>'D',
# 		);
# }

# =head3 /DEV/SIGOUTS/n/PRECOMPENSATION/BOUNCES/m/ENABLE 
# Properties: Read Write Setting 
# Type: Integer (64 bit)(I)
# Unit: None

#  set_sigouts_precompensation_bounces_enable(sigout => $sigout, bounce => $bounce, value => $value)
#  get_sigouts_precompensation_bounces_enable(sigout => $sigout, bounce => $bounce)

# Enables (1) or disables (0) the bounce correction filter.
# Note: This option was not available in the device used for developement, it is therefore untested.
# =cut 


# sub set_sigouts_precompensation_bounces_enable {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		sigout=>{isa => 'Int'},
# 		bounce=>{isa => 'Int'},
# 		value =>{isa =>'Num'},
# 	);my $sigout=delete $args{sigout};
# 	my $bounce=delete $args{bounce};
# 	return $self->sync_set_value(
# 			path => $self->device()."/sigouts/$sigout/precompensation/bounces/$bounce/enable",
# 			type=>'I',
# 			value =>$value
# 		);
# }

# sub get_sigouts_precompensation_bounces_enable {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		sigout=>{isa => 'Int'},
# 		bounce=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $sigout =delete $args{sigout};
# 	my $bounce =delete $args{bounce};
# 	return $self->get_value(
# 			path => $self->device()."/sigouts/$sigout/precompensation/bounces/$bounce/enable",
# 			type=>'I',
# 		);
# }

# =head3 /DEV/SIGOUTS/n/PRECOMPENSATION/BOUNCES/m/STATUS 
# Properties: Read 
# Type: Integer (64 bit)(I)
# Unit: None

#  get_sigouts_precompensation_bounces_status(sigout => $sigout, bounce => $bounce)

# Indicates the status of the bounce correction filter: 0 = normal, 1 = overflow during the last update
# period (~100 ms), 2 = overflowed in the past.
# Note: This option was not available in the device used for developement, it is therefore untested.
# =cut 


# sub get_sigouts_precompensation_bounces_status {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		sigout=>{isa => 'Int'},
# 		bounce=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $sigout =delete $args{sigout};
# 	my $bounce =delete $args{bounce};
# 	return $self->get_value(
# 			path => $self->device()."/sigouts/$sigout/precompensation/bounces/$bounce/status",
# 			type=>'I',
# 		);
# }

# =head3 /DEV/SIGOUTS/n/PRECOMPENSATION/ENABLE 
# Properties: Read Write Setting 
# Type: Integer (64 bit)(I)
# Unit: None

#  set_sigouts_precompensation_enable(sigout => $sigout, value => $value)
#  get_sigouts_precompensation_enable(sigout => $sigout)

# Enables (1) or disables (0) the entire precompensation filter chain.
# Note: This option was not available in the device used for developement, it is therefore untested.
# /DEV/SIGOUTS/n/PRECOMPENSATION/EXPONENTIALS/m/AMPLITUDE
# Properties:Read, Write, Setting
# Type:Double
# Unit: None
# Sets the amplitude of the exponential overshoot compensation filter relative to the signal
# amplitude.
# /DEV/SIGOUTS/n/PRECOMPENSATION/EXPONENTIALS/m/ENABLE
# Properties:Read, Write, Setting
# Type:Integer (64 bit)
# Unit: None
# Enables (1) or disables (0) the exponential overshoot compensation filter.
# /DEV/SIGOUTS/n/PRECOMPENSATION/EXPONENTIALS/m/STATUS
# Properties:Read
# Type:Integer (64 bit)
# Unit: None
# Indicates the status of the exponential overshoot compensation filter: 0 = normal, 1 = overflow
# during the last update period (~100 ms), 2 = overflowed in the past.
# /DEV/SIGOUTS/n/PRECOMPENSATION/EXPONENTIALS/m/
# TIMECONSTANT
# Properties:Read, Write, Setting
# Type:Double
# Unit: s
# Sets the characteristic time constant of the exponential overshoot compensation filter.
# =cut 


# sub set_sigouts_precompensation_enable {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		sigout=>{isa => 'Int'},
# 		value =>{isa =>'Num'},
# 	);my $sigout=delete $args{sigout};
# 	return $self->sync_set_value(
# 			path => $self->device()."/sigouts/$sigout/precompensation/enable",
# 			type=>'I',
# 			value =>$value
# 		);
# }

# sub get_sigouts_precompensation_enable {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		sigout=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $sigout =delete $args{sigout};
# 	return $self->get_value(
# 			path => $self->device()."/sigouts/$sigout/precompensation/enable",
# 			type=>'I',
# 		);
# }

# =head3 /DEV/SIGOUTS/n/PRECOMPENSATION/FIR/ENABLE 
# Properties: Read Write Setting 
# Type: Integer (64 bit)(I)
# Unit: None

#  set_sigouts_precompensation_fir_enable(sigout => $sigout, value => $value)
#  get_sigouts_precompensation_fir_enable(sigout => $sigout)

# Enables (1) or disables (0) the finite impulse response (FIR) precompensation filter.
# =cut 


# sub set_sigouts_precompensation_fir_enable {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		sigout=>{isa => 'Int'},
# 		value =>{isa =>'Num'},
# 	);my $sigout=delete $args{sigout};
# 	return $self->sync_set_value(
# 			path => $self->device()."/sigouts/$sigout/precompensation/fir/enable",
# 			type=>'I',
# 			value =>$value
# 		);
# }

# sub get_sigouts_precompensation_fir_enable {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		sigout=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $sigout =delete $args{sigout};
# 	return $self->get_value(
# 			path => $self->device()."/sigouts/$sigout/precompensation/fir/enable",
# 			type=>'I',
# 		);
# }

# =head3 /DEV/SIGOUTS/n/PRECOMPENSATION/FIR/STATUS 
# Properties: Read 
# Type: Integer (64 bit)(I)
# Unit: None

#  get_sigouts_precompensation_fir_status(sigout => $sigout)

# Indicates the status of the finite impulse response (FIR) precompensation filter: 0 = normal, 1 =
# overflow during the last update period (~100 ms), 2 = overflowed in the past.
# /DEV//SIGOUTS/n/PRECOMPENSATION/HIGHPASS/m/CLEARING/
# SLOPE
# Properties:Read, Write, Setting
# Type:Integer (enumerated)
# Unit: None
# When to react to a clearing pulse generated after the AWG Sequencer setPrecompClear
# instruction.
# entire_clearing_pulse0
# During the entire clearing pulse (Level).
# rising_edge1
# At the rising edge of clearing pulse.
# falling_edge2
# At the falling edge of the clearing pulse.
# both_egdes3
# Both, at the rising and falling edge of the clearing pulse.
# =cut 


# sub get_sigouts_precompensation_fir_status {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		sigout=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $sigout =delete $args{sigout};
# 	return $self->get_value(
# 			path => $self->device()."/sigouts/$sigout/precompensation/fir/status",
# 			type=>'I',
# 		);
# }

# =head3 /DEV/SIGOUTS/n/PRECOMPENSATION/HIGHPASS/m/ENABLE 
# Properties: Read Write Setting 
# Type: Integer (64 bit)(I)
# Unit: None

#  set_sigouts_precompensation_highpass_enable(sigout => $sigout, highpas => $highpas, value => $value)
#  get_sigouts_precompensation_highpass_enable(sigout => $sigout, highpas => $highpas)

# Enables (1) or disables (0) the high-pass compensation filter.
# =cut 


# sub set_sigouts_precompensation_highpass_enable {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		sigout=>{isa => 'Int'},
# 		highpas=>{isa => 'Int'},
# 		value =>{isa =>'Num'},
# 	);my $sigout=delete $args{sigout};
# 	my $highpas=delete $args{highpas};
# 	return $self->sync_set_value(
# 			path => $self->device()."/sigouts/$sigout/precompensation/highpass/$highpas/enable",
# 			type=>'I',
# 			value =>$value
# 		);
# }

# sub get_sigouts_precompensation_highpass_enable {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		sigout=>{isa => 'Int'},
# 		highpas=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $sigout =delete $args{sigout};
# 	my $highpas =delete $args{highpas};
# 	return $self->get_value(
# 			path => $self->device()."/sigouts/$sigout/precompensation/highpass/$highpas/enable",
# 			type=>'I',
# 		);
# }

# =head3 /DEV/SIGOUTS/n/PRECOMPENSATION/HIGHPASS/m/STATUS 
# Properties: Read 
# Type: Integer (64 bit)(I)
# Unit: None

#  get_sigouts_precompensation_highpass_status(sigout => $sigout, highpas => $highpas)

# Indicates the status of the high-pass compensation filter: 0 = normal, 1 = overflow during the last
# update period (~100 ms), 2 = overflowed in the past.
# /DEV/SIGOUTS/n/PRECOMPENSATION/HIGHPASS/m/TIMECONSTANT
# Properties:Read, Write, Setting
# Type:Double
# Unit: s
# Sets the characteristic time constant of the high-pass compensation filter.
# =cut 


# sub get_sigouts_precompensation_highpass_status {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		sigout=>{isa => 'Int'},
# 		highpas=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $sigout =delete $args{sigout};
# 	my $highpas =delete $args{highpas};
# 	return $self->get_value(
# 			path => $self->device()."/sigouts/$sigout/precompensation/highpass/$highpas/status",
# 			type=>'I',
# 		);
# }

# =head3 /DEV/SIGOUTS/n/PRECOMPENSATION/LATENCY 
# Properties: Read 
# Type: Double(D)
# Unit: s

#  get_sigouts_precompensation_latency(sigout => $sigout)

# The total latency introduced by the entire precompensation filter chain.
# =cut 


# sub get_sigouts_precompensation_latency {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		sigout=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $sigout =delete $args{sigout};
# 	return $self->get_value(
# 			path => $self->device()."/sigouts/$sigout/precompensation/latency",
# 			type=>'D',
# 		);
# }

# =head3 /DEV/SIGOUTS/n/PRECOMPENSATION/STATUS/RESET 
# Properties: Read Write 
# Type: Integer (64 bit)(I)
# Unit: None

#  set_sigouts_precompensation_status_reset(sigout => $sigout, value => $value)
#  get_sigouts_precompensation_status_reset(sigout => $sigout)

# Resets the status flags of all precompensation filters of this output channel.
# =cut 


# sub set_sigouts_precompensation_status_reset {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		sigout=>{isa => 'Int'},
# 		value =>{isa =>'Num'},
# 	);my $sigout=delete $args{sigout};
# 	return $self->sync_set_value(
# 			path => $self->device()."/sigouts/$sigout/precompensation/status/reset",
# 			type=>'I',
# 			value =>$value
# 		);
# }

# sub get_sigouts_precompensation_status_reset {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		sigout=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $sigout =delete $args{sigout};
# 	return $self->get_value(
# 			path => $self->device()."/sigouts/$sigout/precompensation/status/reset",
# 			type=>'I',
# 		);
# }



sub set_sigouts_range {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sigout=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $sigout=delete $args{sigout};
	return $self->sync_set_value(
			path => $self->device()."/sigouts/$sigout/range",
			type=>'D',
			value =>$value
		);
}

sub get_sigouts_range {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sigout=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $sigout =delete $args{sigout};
	return $self->get_value(
			path => $self->device()."/sigouts/$sigout/range",
			type=>'D',
		);
}



sub set_sines_amplitudes{
	my ($self, $value, %args) = validated_setter(
		\@_,
		sine=>{isa => 'Int'},
		amplitude => {isa=>'Int'},
		value =>{isa =>'Num'},
	);
	my $sine=delete $args{sine};
	my $amplitude = delete $args{amplitude};
	return $self->sync_set_value(
			path => $self->device()."/sines/$sine/amplitudes/$amplitude",
			type=>'D',
			value =>$value

		);
}

sub get_sines_amplitudes {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sine=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
		amplitude => {isa=>'Int'}
	);
	my $sine =delete $args{sine};
	my $amplitude = delete $args{amplitude};
	return $self->get_value(
			path => $self->device()."/sines/$sine/amplitudes/$amplitude",
			type=>'D',

		);
}



sub set_sines_enables {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sine=>{isa => 'Int'},
		value =>{isa =>'Num'},
		amplitude => {isa=>'Int'}
	);
	my $sine=delete $args{sine};
	my $amplitude = delete $args{amplitude};
	return $self->sync_set_value(
			path => $self->device()."/sines/$sine/enables/$amplitude",
			type=>'I',
			value =>$value
		);
}

sub get_sines_enables {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sine=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
		amplitude => {isa=>'Int'}
	);
	my $sine =delete $args{sine};
	my $amplitude = delete $args{amplitude};
	return $self->get_value(
			path => $self->device()."/sines/$sine/enables/$amplitude",
			type=>'I',
		);
}



sub set_sines_harmonic {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sine=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $sine=delete $args{sine};
	return $self->sync_set_value(
			path => $self->device()."/sines/$sine/harmonic",
			type=>'I',
			value =>$value
		);
}

sub get_sines_harmonic {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sine=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $sine =delete $args{sine};
	return $self->get_value(
			path => $self->device()."/sines/$sine/harmonic",
			type=>'I',
		);
}



sub set_sines_oscselect {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sine=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $sine=delete $args{sine};
	return $self->sync_set_value(
			path => $self->device()."/sines/$sine/oscselect",
			type=>'I',
			value =>$value
		);
}

sub get_sines_oscselect {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sine=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $sine =delete $args{sine};
	return $self->get_value(
			path => $self->device()."/sines/$sine/oscselect",
			type=>'I',
		);
}



sub set_sines_phaseshift {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sine=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $sine=delete $args{sine};
	return $self->sync_set_value(
			path => $self->device()."/sines/$sine/phaseshift",
			type=>'D',
			value =>$value
		);
}

sub get_sines_phaseshift {
	my ($self, $value, %args) = validated_setter(
		\@_,
		sine=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $sine =delete $args{sine};
	return $self->get_value(
			path => $self->device()."/sines/$sine/phaseshift",
			type=>'D',
		);
}



sub get_stats_cmdstream_bandwidth {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/cmdstream/bandwidth",
			type=>'D',
		);
}



sub get_stats_cmdstream_bytesreceived {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/cmdstream/bytesreceived",
			type=>'I',
		);
}



sub get_stats_cmdstream_bytessent {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/cmdstream/bytessent",
			type=>'I',
		);
}



sub get_stats_cmdstream_packetslost {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/cmdstream/packetslost",
			type=>'I',
		);
}



sub get_stats_cmdstream_packetsreceived {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/cmdstream/packetsreceived",
			type=>'I',
		);
}



sub get_stats_cmdstream_packetssent {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/cmdstream/packetssent",
			type=>'I',
		);
}



sub get_stats_cmdstream_pending {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/cmdstream/pending",
			type=>'I',
		);
}



sub get_stats_cmdstream_processing {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/cmdstream/processing",
			type=>'I',
		);
}



sub get_stats_datastream_bandwidth {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/datastream/bandwidth",
			type=>'D',
		);
}



sub get_stats_datastream_bytesreceived {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/datastream/bytesreceived",
			type=>'I',
		);
}



sub get_stats_datastream_packetslost {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/datastream/packetslost",
			type=>'I',
		);
}



sub get_stats_datastream_packetsreceived {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/datastream/packetsreceived",
			type=>'I',
		);
}



sub get_stats_datastream_pending {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/datastream/pending",
			type=>'I',
		);
}



sub get_stats_datastream_processing {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/datastream/processing",
			type=>'I',
		);
}



sub get_stats_physical_fpga_aux {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/physical/fpga/aux",
			type=>'D',
		);
}



sub get_stats_physical_fpga_core {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/physical/fpga/core",
			type=>'D',
		);
}



sub get_stats_physical_fpga_temp {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/physical/fpga/temp",
			type=>'D',
		);
}



sub get_stats_physical_overtemperature {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/stats/physical/overtemperature",
			type=>'I',
		);
}



sub get_stats_physical_power_currents {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
		current =>{isa=>'Int'}
	);
	my $current = delete $args{current};
	return $self->get_value(
			path => $self->device()."/stats/physical/power/currents/$current",
			type=>'D',
		);
}



sub get_stats_physical_power_temperatures{
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
		temperature => {isa=>'Int'}
	);
	my $temperature = delete $args{temperature};
	return $self->get_value(
			path => $self->device()."/stats/physical/power/temperatures/$temperature",
			type=>'D',
		);
}



sub get_stats_physical_power_voltages{
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
		voltage => {isa => 'Int'}
	);
	my $voltage = delete $args{voltage};
	return $self->get_value(
			path => $self->device()."/stats/physical/power/voltages/$voltage",
			type=>'D',
		);
}



sub get_stats_physical_slavefpgas_aux {
	my ($self, $value, %args) = validated_setter(
		\@_,
		slavefpga=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $slavefpga =delete $args{slavefpga};
	return $self->get_value(
			path => $self->device()."/stats/physical/slavefpgas/$slavefpga/aux",
			type=>'D',
		);
}



sub get_stats_physical_slavefpgas_core {
	my ($self, $value, %args) = validated_setter(
		\@_,
		slavefpga=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $slavefpga =delete $args{slavefpga};
	return $self->get_value(
			path => $self->device()."/stats/physical/slavefpgas/$slavefpga/core",
			type=>'D',
		);
}



sub get_stats_physical_slavefpgas_temp {
	my ($self, $value, %args) = validated_setter(
		\@_,
		slavefpga=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $slavefpga =delete $args{slavefpga};
	return $self->get_value(
			path => $self->device()."/stats/physical/slavefpgas/$slavefpga/temp",
			type=>'D',
		);
}



sub get_stats_physical_temperatures {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
		temperature =>{isa=>'Int'}
	);
	my $temperature = delete $args{temperature};
	return $self->get_value(
			path => $self->device()."/stats/physical/temperatures/$temperature",
			type=>'D',
		);
}



sub get_stats_physical_voltages {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
		voltage=>{isa =>'Int'}
	);
	my $voltage = delete $args{voltage};
	return $self->get_value(
			path => $self->device()."/stats/physical/voltages/$voltage",
			type=>'D',
		);
}



sub get_status_adc0max {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/status/adc0max",
			type=>'I',
		);
}



sub get_status_adc0min {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/status/adc0min",
			type=>'I',
		);
}



sub get_status_adc1max {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/status/adc1max",
			type=>'I',
		);
}



sub get_status_adc1min {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/status/adc1min",
			type=>'I',
		);
}



sub get_status_fifolevel {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/status/fifolevel",
			type=>'D',
		);
}



sub get_status_flags_binary {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/status/flags/binary",
			type=>'I',
		);
}



sub get_status_flags_packetlosstcp {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/status/flags/packetlosstcp",
			type=>'I',
		);
}



sub get_status_flags_packetlossudp {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/status/flags/packetlossudp",
			type=>'I',
		);
}



sub get_status_time {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/status/time",
			type=>'I',
		);
}



sub get_system_activeinterface {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
		read_length => {isa=>'Int'}
	);
	my $read_length = delete $args{read_length};
	return $self->connection->get_value(
			path => $self->device()."/system/activeinterface",
			type=>'B',
			read_length=>$read_length
		);
}



sub set_system_awg_channelgrouping {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num'},
	);
	return $self->sync_set_value(
			path => $self->device()."/system/awg/channelgrouping",
			type=>'I',
			value =>$value
		);
}

sub get_system_awg_channelgrouping {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/awg/channelgrouping",
			type=>'I',
		);
}



sub set_system_awg_oscillatorcontrol {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num'},
	);
	return $self->sync_set_value(
			path => $self->device()."/system/awg/oscillatorcontrol",
			type=>'I',
			value =>$value
		);
}

sub get_system_awg_oscillatorcontrol {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/awg/oscillatorcontrol",
			type=>'I',
		);
}



sub get_system_boardrevisions {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
		boardrevision => {isa=>'Int'},
		read_length => {isa=>'Int'}
	);
	my $boardrevision = delete $args{boardrevision};
	my $read_length = delete $args{read_length};
	return $self->connection->get_value(
			path => $self->device()."/system/boardrevisions/$boardrevision",
			type=>'B',
			read_length => $read_length
		);
}



sub get_system_clocks_referenceclock_freq {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/clocks/referenceclock/freq",
			type=>'D',
		);
}



sub set_system_clocks_referenceclock_source {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num'},
	);
	return $self->sync_set_value(
			path => $self->device()."/system/clocks/referenceclock/source",
			type=>'I',
			value =>$value
		);
}

sub get_system_clocks_referenceclock_source {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/clocks/referenceclock/source",
			type=>'I',
		);
}



sub get_system_clocks_referenceclock_status {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/clocks/referenceclock/status",
			type=>'I',
		);
}



sub set_system_clocks_sampleclock_freq {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num'},
	);
	return $self->sync_set_value(
			path => $self->device()."/system/clocks/sampleclock/freq",
			type=>'D',
			value =>$value
		);
}

sub get_system_clocks_sampleclock_freq {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/clocks/sampleclock/freq",
			type=>'D',
		);
}



sub set_system_clocks_sampleclock_outputenable {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num'},
	);
	return $self->sync_set_value(
			path => $self->device()."/system/clocks/sampleclock/outputenable",
			type=>'I',
			value =>$value
		);
}

sub get_system_clocks_sampleclock_outputenable {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/clocks/sampleclock/outputenable",
			type=>'I',
		);
}



sub get_system_clocks_sampleclock_status {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/clocks/sampleclock/status",
			type=>'I',
		);
}



sub get_system_fpgarevision {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/fpgarevision",
			type=>'I',
		);
}

# =head3 /DEV/SYSTEM/FWLOG 
# Properties: Read 
# Type: String(B)
# Unit: None

#  get_system_fwlog()

# Returns log output of the firmware.
# =cut 


# sub get_system_fwlog {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		value =>{isa =>'Num',optional=>1},
# 		read_length=>{isa=>'Int'}
# 	);
# 	my $read_length = delete $args{read_length};
# 	return $self->connection->get_value(
# 			path => $self->device()."/system/fwlog",
# 			type=>'B',
# 			read_length=>$read_length

# 		);
# }



sub set_system_fwlogenable {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num'},
	);
	return $self->sync_set_value(
			path => $self->device()."/system/fwlogenable",
			type=>'I',
			value =>$value
		);
}

sub get_system_fwlogenable {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/fwlogenable",
			type=>'I',
		);
}



sub get_system_fwrevision {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/fwrevision",
			type=>'I',
		);
}



sub get_system_fx3revision {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/fx3revision",
			type=>'B',
		);
}



sub set_system_identify {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num'},
	);
	return $self->sync_set_value(
			path => $self->device()."/system/identify",
			type=>'I',
			value =>$value
		);
}

sub get_system_identify {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/identify",
			type=>'I',
		);
}



sub get_system_interfacespeed {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
		read_length => {isa=>'Int'}
	);
	my $read_length = delete $args{read_length};
	return $self->connection->get_value(
			path => $self->device()."/system/interfacespeed",
			type=>'B',
			read_length => $read_length

		);
}



sub get_system_kerneltype {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
		read_length => {isa=>'Int'}
	);
	my $read_length = delete $args{read_length};
	return $self->connection->get_value(
			path => $self->device()."/system/kerneltype",
			type=>'B',
			read_length => $read_length
		);
}

# =head3 /DEV/SYSTEM/NICS/n/DEFAULTGATEWAY 
# Properties: Read Write 
# Type: String(B)
# Unit: None

#  set_system_nics_defaultgateway(nic => $nic, value => $value)
#  get_system_nics_defaultgateway(nic => $nic)

# Default gateway configuration for the network connection.
# =cut 


# sub set_system_nics_defaultgateway {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		nic=>{isa => 'Int'},
# 		value =>{isa =>'Str'},
# 	);my $nic=delete $args{nic};
# 	return $self->sync_set_value(
# 			path => $self->device()."/system/nics/$nic/defaultgateway",
# 			type=>'B',
# 			value =>$value
# 		);
# }

# sub get_system_nics_defaultgateway {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		nic=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $nic =delete $args{nic};
# 	return $self->get_value(
# 			path => $self->device()."/system/nics/$nic/defaultgateway",
# 			type=>'B',
# 		);
# }

# =head3 /DEV/SYSTEM/NICS/n/DEFAULTIP4 
# Properties: Read Write 
# Type: String(B)
# Unit: None

#  set_system_nics_defaultip4(nic => $nic, value => $value)
#  get_system_nics_defaultip4(nic => $nic)

# IPv4 address of the device to use if static IP is enabled.
# =cut 


# sub set_system_nics_defaultip4 {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		nic=>{isa => 'Int'},
# 		value =>{isa =>'Str'},
# 	);my $nic=delete $args{nic};
# 	return $self->sync_set_value(
# 			path => $self->device()."/system/nics/$nic/defaultip4",
# 			type=>'B',
# 			value =>$value
# 		);
# }

# sub get_system_nics_defaultip4 {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		nic=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $nic =delete $args{nic};
# 	return $self->get_value(
# 			path => $self->device()."/system/nics/$nic/defaultip4",
# 			type=>'B',
# 		);
# }

# =head3 /DEV/SYSTEM/NICS/n/DEFAULTMASK 
# Properties: Read Write 
# Type: String(B)
# Unit: None

#  set_system_nics_defaultmask(nic => $nic, value => $value)
#  get_system_nics_defaultmask(nic => $nic)

# IPv4 mask in case of static IP.
# =cut 


# sub set_system_nics_defaultmask {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		nic=>{isa => 'Int'},
# 		value =>{isa =>'Str'},
# 	);my $nic=delete $args{nic};
# 	return $self->sync_set_value(
# 			path => $self->device()."/system/nics/$nic/defaultmask",
# 			type=>'B',
# 			value =>$value
# 		);
# }

# sub get_system_nics_defaultmask {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		nic=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $nic =delete $args{nic};
# 	return $self->get_value(
# 			path => $self->device()."/system/nics/$nic/defaultmask",
# 			type=>'B',
# 		);
# }

# =head3 /DEV/SYSTEM/NICS/n/GATEWAY 
# Properties: Read 
# Type: String(B)
# Unit: None

#  get_system_nics_gateway(nic => $nic)

# Current network gateway.
# =cut 


# sub get_system_nics_gateway {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		nic=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $nic =delete $args{nic};
# 	return $self->get_value(
# 			path => $self->device()."/system/nics/$nic/gateway",
# 			type=>'B',
# 		);
# }

# =head3 /DEV/SYSTEM/NICS/n/IP4 
# Properties: Read 
# Type: String(B)
# Unit: None

#  get_system_nics_ip4(nic => $nic)

# Current IPv4 of the device.
# =cut 


# sub get_system_nics_ip4 {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		nic=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $nic =delete $args{nic};
# 	return $self->get_value(
# 			path => $self->device()."/system/nics/$nic/ip4",
# 			type=>'B',
# 		);
# }

# =head3 /DEV/SYSTEM/NICS/n/MAC 
# Properties: Read 
# Type: String(B)
# Unit: None

#  get_system_nics_mac(nic => $nic)

# Current MAC address of the device network interface.
# =cut 


# sub get_system_nics_mac {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		nic=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $nic =delete $args{nic};
# 	return $self->get_value(
# 			path => $self->device()."/system/nics/$nic/mac",
# 			type=>'B',
# 		);
# }

# =head3 /DEV/SYSTEM/NICS/n/MASK 
# Properties: Read 
# Type: String(B)
# Unit: None

#  get_system_nics_mask(nic => $nic)

# Current network mask.
# =cut 


# sub get_system_nics_mask {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		nic=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $nic =delete $args{nic};
# 	return $self->get_value(
# 			path => $self->device()."/system/nics/$nic/mask",
# 			type=>'B',
# 		);
# }

# =head3 /DEV/SYSTEM/NICS/n/SAVEIP 
# Properties: Read Write 
# Type: Integer (64 bit)(I)
# Unit: None

#  set_system_nics_saveip(nic => $nic, value => $value)
#  get_system_nics_saveip(nic => $nic)

# If written, this action will program the defined static IP address to the device.
# =cut 


# sub set_system_nics_saveip {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		nic=>{isa => 'Int'},
# 		value =>{isa =>'Num'},
# 	);my $nic=delete $args{nic};
# 	return $self->sync_set_value(
# 			path => $self->device()."/system/nics/$nic/saveip",
# 			type=>'I',
# 			value =>$value
# 		);
# }

# sub get_system_nics_saveip {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		nic=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $nic =delete $args{nic};
# 	return $self->get_value(
# 			path => $self->device()."/system/nics/$nic/saveip",
# 			type=>'I',
# 		);
# }

# =head3 /DEV/SYSTEM/NICS/n/STATIC 
# Properties: Read Write 
# Type: Integer (64 bit)(I)
# Unit: None

#  set_system_nics_static(nic => $nic, value => $value)
#  get_system_nics_static(nic => $nic)

# Enable this flag if the device is used in a network with fixed IP assignment without a DHCP server.
# =cut 


# sub set_system_nics_static {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		nic=>{isa => 'Int'},
# 		value =>{isa =>'Num'},
# 	);my $nic=delete $args{nic};
# 	return $self->sync_set_value(
# 			path => $self->device()."/system/nics/$nic/static",
# 			type=>'I',
# 			value =>$value
# 		);
# }

# sub get_system_nics_static {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		nic=>{isa => 'Int'},
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	my $nic =delete $args{nic};
# 	return $self->get_value(
# 			path => $self->device()."/system/nics/$nic/static",
# 			type=>'I',
# 		);
# }



sub get_system_owner {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
		read_length => {isa=>'Int'}
	);
	my $read_length = delete $args{read_length};
	return $self->connection->get_value(
			path => $self->device()."/system/owner",
			type=>'B',
			read_length=>$read_length
		);
}

# =head3 /DEV/SYSTEM/PORTTCP 
# Properties: Read Write 
# Type: Integer (64 bit)(I)
# Unit: None

#  set_system_porttcp(value => $value)
#  get_system_porttcp()

# Returns the current TCP port used for communication to the dataserver.
# =cut 


# sub set_system_porttcp {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		value =>{isa =>'Num'},
# 	);
# 	return $self->sync_set_value(
# 			path => $self->device()."/system/porttcp",
# 			type=>'I',
# 			value =>$value
# 		);
# }

# sub get_system_porttcp {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	return $self->get_value(
# 			path => $self->device()."/system/porttcp",
# 			type=>'I',
# 		);
# }

# =head3 /DEV/SYSTEM/PORTUDP 
# Properties: Read Write 
# Type: Integer (64 bit)(I)
# Unit: None

#  set_system_portudp(value => $value)
#  get_system_portudp()

# Returns the current UDP port used for communication to the dataserver.
# =cut 


# sub set_system_portudp {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		value =>{isa =>'Num'},
# 	);
# 	return $self->sync_set_value(
# 			path => $self->device()."/system/portudp",
# 			type=>'I',
# 			value =>$value
# 		);
# }

# sub get_system_portudp {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	return $self->get_value(
# 			path => $self->device()."/system/portudp",
# 			type=>'I',
# 		);
# }



sub get_system_powerconfigdate {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/powerconfigdate",
			type=>'I',
		);
}



sub get_system_preset_busy {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/preset/busy",
			type=>'I',
		);
}



sub get_system_preset_error {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/preset/error",
			type=>'I',
		);
}



sub set_system_preset_load {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num'},
	);
	return $self->sync_set_value(
			path => $self->device()."/system/preset/load",
			type=>'I',
			value =>$value
		);
}

sub get_system_preset_load {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/preset/load",
			type=>'I',
		);
}



sub get_system_properties_freqresolution {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/properties/freqresolution",
			type=>'I',
		);
}



sub get_system_properties_freqscaling {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/properties/freqscaling",
			type=>'D',
		);
}



sub get_system_properties_maxfreq {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/properties/maxfreq",
			type=>'D',
		);
}



sub get_system_properties_maxtimeconstant {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/properties/maxtimeconstant",
			type=>'D',
		);
}



sub get_system_properties_minfreq {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/properties/minfreq",
			type=>'D',
		);
}



sub get_system_properties_mintimeconstant {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/properties/mintimeconstant",
			type=>'D',
		);
}



sub get_system_properties_negativefreq {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/properties/negativefreq",
			type=>'I',
		);
}



sub get_system_properties_timebase {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/properties/timebase",
			type=>'D',
		);
}



sub set_system_saveports {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num'},
	);
	return $self->sync_set_value(
			path => $self->device()."/system/saveports",
			type=>'I',
			value =>$value
		);
}

sub get_system_saveports {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/saveports",
			type=>'I',
		);
}

# =head3 /DEV/SYSTEM/SHUTDOWN 
# Properties: Read Write 
# Type: Integer (64 bit)(I)
# Unit: None

#  set_system_shutdown(value => $value)
#  get_system_shutdown()

# Sending a '1' to this node initiates a shutdown of the operating system on the device. It is
# recommended to trigger this shutdown before switching the device off with the hardware switch
# at the back side of the device.
# =cut 


# sub set_system_shutdown {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		value =>{isa =>'Num'},
# 	);
# 	return $self->sync_set_value(
# 			path => $self->device()."/system/shutdown",
# 			type=>'I',
# 			value =>$value
# 		);
# }

# sub get_system_shutdown {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	return $self->get_value(
# 			path => $self->device()."/system/shutdown",
# 			type=>'I',
# 		);
# }



sub get_system_slaverevision {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value =>{isa =>'Num',optional=>1},
	);
	return $self->get_value(
			path => $self->device()."/system/slaverevision",
			type=>'I',
		);
}

# =head3 /DEV/SYSTEM/STALL 
# Properties: Read Write 
# Type: Integer (64 bit)(I)
# Unit: None

#  set_system_stall(value => $value)
#  get_system_stall()

# Indicates if the network connection is stalled.
# =cut 


# sub set_system_stall {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		value =>{isa =>'Num'},
# 	);
# 	return $self->sync_set_value(
# 			path => $self->device()."/system/stall",
# 			type=>'I',
# 			value =>$value
# 		);
# }

# sub get_system_stall {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	return $self->get_value(
# 			path => $self->device()."/system/stall",
# 			type=>'I',
# 		);
# }

# =head3 /DEV/SYSTEM/UPDATE 
# Properties: Read Write 
# Type: Integer (64 bit)(I)
# Unit: None

#  set_system_update(value => $value)
#  get_system_update()

# Requests update of the device firmware and bitstream from the dataserver.
# =cut 


# sub set_system_update {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		value =>{isa =>'Num'},
# 	);
# 	return $self->sync_set_value(
# 			path => $self->device()."/system/update",
# 			type=>'I',
# 			value =>$value
# 		);
# }

# sub get_system_update {
# 	my ($self, $value, %args) = validated_setter(
# 		\@_,
# 		value =>{isa =>'Num',optional=>1},
# 	);
# 	return $self->get_value(
# 			path => $self->device()."/system/update",
# 			type=>'I',
# 		);
# }



sub set_triggers_in_imp50 {
	my ($self, $value, %args) = validated_setter(
		\@_,
		in=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $in=delete $args{in};
	return $self->sync_set_value(
			path => $self->device()."/triggers/in/$in/imp50",
			type=>'I',
			value =>$value
		);
}

sub get_triggers_in_imp50 {
	my ($self, $value, %args) = validated_setter(
		\@_,
		in=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $in =delete $args{in};
	return $self->get_value(
			path => $self->device()."/triggers/in/$in/imp50",
			type=>'I',
		);
}



sub set_triggers_in_level {
	my ($self, $value, %args) = validated_setter(
		\@_,
		in=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $in=delete $args{in};
	return $self->sync_set_value(
			path => $self->device()."/triggers/in/$in/level",
			type=>'D',
			value =>$value
		);
}

sub get_triggers_in_level {
	my ($self, $value, %args) = validated_setter(
		\@_,
		in=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $in =delete $args{in};
	return $self->get_value(
			path => $self->device()."/triggers/in/$in/level",
			type=>'D',
		);
}



sub get_triggers_in_value {
	my ($self, $value, %args) = validated_setter(
		\@_,
		in=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $in =delete $args{in};
	return $self->get_value(
			path => $self->device()."/triggers/in/$in/value",
			type=>'I',
		);
}



sub set_triggers_out_delay {
	my ($self, $value, %args) = validated_setter(
		\@_,
		out=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $out=delete $args{out};
	return $self->sync_set_value(
			path => $self->device()."/triggers/out/$out/delay",
			type=>'D',
			value =>$value
		);
}

sub get_triggers_out_delay {
	my ($self, $value, %args) = validated_setter(
		\@_,
		out=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $out =delete $args{out};
	return $self->get_value(
			path => $self->device()."/triggers/out/$out/delay",
			type=>'D',
		);
}



sub set_triggers_out_source {
	my ($self, $value, %args) = validated_setter(
		\@_,
		out=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $out=delete $args{out};
	return $self->sync_set_value(
			path => $self->device()."/triggers/out/$out/source",
			type=>'I',
			value =>$value
		);
}

sub get_triggers_out_source {
	my ($self, $value, %args) = validated_setter(
		\@_,
		out=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $out =delete $args{out};
	return $self->get_value(
			path => $self->device()."/triggers/out/$out/source",
			type=>'I',
		);
}



sub set_triggers_streams_enable {
	my ($self, $value, %args) = validated_setter(
		\@_,
		stream=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $stream=delete $args{stream};
	return $self->sync_set_value(
			path => $self->device()."/triggers/streams/$stream/enable",
			type=>'I',
			value =>$value
		);
}

sub get_triggers_streams_enable {
	my ($self, $value, %args) = validated_setter(
		\@_,
		stream=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $stream =delete $args{stream};
	return $self->get_value(
			path => $self->device()."/triggers/streams/$stream/enable",
			type=>'I',
		);
}



sub set_triggers_streams_holdofftime {
	my ($self, $value, %args) = validated_setter(
		\@_,
		stream=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $stream=delete $args{stream};
	return $self->sync_set_value(
			path => $self->device()."/triggers/streams/$stream/holdofftime",
			type=>'D',
			value =>$value
		);
}

sub get_triggers_streams_holdofftime {
	my ($self, $value, %args) = validated_setter(
		\@_,
		stream=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $stream =delete $args{stream};
	return $self->get_value(
			path => $self->device()."/triggers/streams/$stream/holdofftime",
			type=>'D',
		);
}



sub set_triggers_streams_mask {
	my ($self, $value, %args) = validated_setter(
		\@_,
		stream=>{isa => 'Int'},
		value =>{isa =>'Num'},
	);my $stream=delete $args{stream};
	return $self->sync_set_value(
			path => $self->device()."/triggers/streams/$stream/mask",
			type=>'I',
			value =>$value
		);
}

sub get_triggers_streams_mask {
	my ($self, $value, %args) = validated_setter(
		\@_,
		stream=>{isa => 'Int'},
		value =>{isa =>'Num',optional=>1},
	);
	my $stream =delete $args{stream};
	return $self->get_value(
			path => $self->device()."/triggers/streams/$stream/mask",
			type=>'I',
		);
}


__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::ZI_HDAWG - Zurich Instruments HDAWG Arbitrary Waveform Generator

=head1 VERSION

version 3.931

=head1 Tested

=head2 AWGS

=head3 /DEV/AWGS/n/AUXTRIGGERS/m/CHANNEL 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_awgs_auxtriggers_channel(awg => $awg, auxtrigger => $auxtrigger, value => $value)
 get_awgs_auxtriggers_channel(awg => $awg, auxtrigger => $auxtrigger)

Selects the digital trigger source signal.
trigin0, trigger_input0 0
Trigger In 1
trigin1, trigger_input1 1
Trigger In 2
trigin2, trigger_input2 2
Trigger In 3
trigin3, trigger_input3 3
Trigger In 4
trigout0 , trigger_output0 4
Trigger Out 1
trigout1 , trigger_output1 5
Trigger Out 2
trigout2 , trigger_output2 6
Trigger Out 3
trigout3 , trigger_output3 7
Trigger Out 4

=head3 /DEV/AWGS/n/AUXTRIGGERS/m/SLOPE 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_awgs_auxtriggers_slope(awg => $awg, auxtrigger => $auxtrigger, value => $value)
 get_awgs_auxtriggers_slope(awg => $awg, auxtrigger => $auxtrigger)

Select the signal edge that should activate the trigger. The trigger will be level sensitive when the
Level option is selected.
level_sensitive0
Level sensitive trigger
rising_edge1
Rising edge trigger
2falling_edge
Falling edge trigger
both_edges3
Rising or falling edge trigger

=head3 /DEV/AWGS/n/AUXTRIGGERS/m/STATE 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_awgs_auxtriggers_state(awg => $awg, auxtrigger => $auxtrigger)

State of the Auxiliary Trigger: No trigger detected/trigger detected.

=head3 /DEV/AWGS/n/COMMANDTABLE/CLEAR 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_commandtable_clear(awg => $awg, value => $value)
 get_awgs_commandtable_clear(awg => $awg)

Writing to this node clears all data previously loaded to the command table of the device.

=head3 /DEV/AWGS/n/COMMANDTABLE/STATUS 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_awgs_commandtable_status(awg => $awg)

Status of the command table on the instrument. Bit 0: data uploaded to the command table; Bit
1, Bit 2: reserved; Bit 3: uploading of data to the command table failed due to a JSON parsing error.

=head3 /DEV/AWGS/n/DIO/DELAY/INDEX 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_dio_delay_index(awg => $awg, value => $value)
 get_awgs_dio_delay_index(awg => $awg)

Index of the bit on the DIO interface for which the delay should be changed.

=head3 /DEV/AWGS/n/DIO/DELAY/VALUE 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_dio_delay_value(awg => $awg, value => $value)
 get_awgs_dio_delay_value(awg => $awg)

Corresponding delay value to apply to the given bit of the DIO interface in units of 150 MHz clock
cycles. Valid values are 0 to 3.

=head3 /DEV/AWGS/n/DIO/ERROR/TIMING 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_dio_error_timing(awg => $awg, value => $value)
 get_awgs_dio_error_timing(awg => $awg)

A 32-bit value indicating which bits on the DIO interface may have timing errors. A timing error is
defined as an event where either the VALID or any of the data bits on the DIO interface change
value at the same time as the STROBE bit.

=head3 /DEV/AWGS/n/DIO/ERROR/WIDTH 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_dio_error_width(awg => $awg, value => $value)
 get_awgs_dio_error_width(awg => $awg)

Indicates a width (i.e. jitter) error on either the STROBE (bit 0 of the value) or VALID bit (bit 1 of
the result). A width error indicates that there was jitter detected on the given bit, meaning that
an active period was either shorter or longer than the configured expected width.

=head3 /DEV/AWGS/n/DIO/HIGHBITS 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_dio_highbits(awg => $awg, value => $value)
 get_awgs_dio_highbits(awg => $awg)

32-bit value indicating which bits on the 32-bit interface are detected as having a logic high value.

=head3 /DEV/AWGS/n/DIO/LOWBITS 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_dio_lowbits(awg => $awg, value => $value)
 get_awgs_dio_lowbits(awg => $awg)

32-bit value indicating which bits on the 32-bit interface are detected as having a logic low value.

=head3 /DEV/AWGS/n/DIO/MASK/SHIFT 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_dio_mask_shift(awg => $awg, value => $value)
 get_awgs_dio_mask_shift(awg => $awg)

Defines the amount of bit shifting to apply for the DIO wave selection in connection with
playWaveDIO().

=head3 /DEV/AWGS/n/DIO/MASK/VALUE 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_dio_mask_value(awg => $awg, value => $value)
 get_awgs_dio_mask_value(awg => $awg)

Selects the DIO bits to be used for waveform selection in connection with playWaveDIO().

=head3 /DEV/AWGS/n/DIO/STATE 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_dio_state(awg => $awg, value => $value)
 get_awgs_dio_state(awg => $awg)

When asserted, indicates that triggers are generated from the DIO interface to the AWG.

=head3 /DEV/AWGS/n/DIO/STROBE/INDEX 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_dio_strobe_index(awg => $awg, value => $value)
 get_awgs_dio_strobe_index(awg => $awg)

Select the DIO bit to use as the STROBE signal.

=head3 /DEV/AWGS/n/DIO/STROBE/SLOPE 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_awgs_dio_strobe_slope(awg => $awg, value => $value)
 get_awgs_dio_strobe_slope(awg => $awg)

Select the signal edge of the STROBE signal for use in timing alignment.
off0
Off
rising_edge1
Rising edge trigger
falling_edge2
Falling edge trigger
both_edges3
Rising or falling edge trigger

=head3 /DEV/AWGS/n/DIO/STROBE/WIDTH 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_dio_strobe_width(awg => $awg, value => $value)
 get_awgs_dio_strobe_width(awg => $awg)

Specifies the expected width of active pulses on the STROBE bit.

=head3 /DEV/AWGS/n/DIO/VALID/INDEX 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_dio_valid_index(awg => $awg, value => $value)
 get_awgs_dio_valid_index(awg => $awg)

Select the DIO bit to use as the VALID signal to indicate a valid input is available.

=head3 /DEV/AWGS/n/DIO/VALID/POLARITY 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_awgs_dio_valid_polarity(awg => $awg, value => $value)
 get_awgs_dio_valid_polarity(awg => $awg)

Polarity of the VALID bit that indicates that a valid input is available.
0none
None: VALID bit is ignored.
low1
Low: VALID bit must be logical zero.
high2
High: VALID bit must be logical high.
both3
Both: VALID bit may be logical high or zero.

=head3 /DEV/AWGS/n/DIO/VALID/WIDTH 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_dio_valid_width(awg => $awg, value => $value)
 get_awgs_dio_valid_width(awg => $awg)

Expected width of an active pulse on the VALID bit.

=head3 /DEV/AWGS/n/ELF/CHECKSUM 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_awgs_elf_checksum(awg => $awg)

Checksum of the uploaded ELF file.

=head3 /DEV/AWGS/n/ELF/LENGTH 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_awgs_elf_length(awg => $awg)

Length of the compiled ELF file.

=head3 /DEV/AWGS/n/ELF/MEMORYUSAGE 
Properties: Read 
Type: Double(D)
Unit: None

 get_awgs_elf_memoryusage(awg => $awg)

Size of the uploaded ELF file relative to the size of the main memory.

=head3 /DEV/AWGS/n/ELF/PROGRESS 
Properties: Read 
Type: Double(D)
Unit: %

 get_awgs_elf_progress(awg => $awg)

The percentage of the sequencer program already uploaded to the device.

=head3 /DEV/AWGS/n/ENABLE 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_enable(awg => $awg, value => $value)
 get_awgs_enable(awg => $awg)

Activates the AWG.

=head3 /DEV/AWGS/n/OUTPUTS/m/AMPLITUDE 
Properties: Read Write Setting 
Type: Double(D)
Unit: None

 set_awgs_outputs_amplitude(awg => $awg, output => $output, value => $value)
 get_awgs_outputs_amplitude(awg => $awg, output => $output)

Amplitude in units of full scale of the given AWG Output. The full scale corresponds to the Range
voltage setting of the Signal Outputs.

=head3 /DEV/AWGS/n/OUTPUTS/m/ENABLES/k 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_awgs_outputs_enables_k(awg => $awg, output => $output)

Enables the driving of the given AWG output channel.

=head3 /DEV/AWGS/n/OUTPUTS/m/GAINS/k 
Properties: Read Write Setting 
Type: Double(D)
Unit: None

 set_awgs_outputs_gains(awg => $awg, output => $output, gain=>$gain, value => $value)
 get_awgs_outputs_gains(awg => $awg, output => $output, gain=>$gain)

Gain factor applied to the AWG Output at the given output multiplier stage. The final signal
amplitude is proportional to the Range voltage setting of the Wave signal outputs.

=head3 /DEV/AWGS/n/OUTPUTS/m/HOLD 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_outputs_hold(awg => $awg, output => $output, value => $value)
 get_awgs_outputs_hold(awg => $awg, output => $output)

Keep the last sample (constant) on the output even after the waveform program finishes.

=head3 /DEV/AWGS/n/OUTPUTS/m/MODULATION/CARRIERS/k/FREQ 
Properties: Read 
Type: Double(D)
Unit: Hz

 get_awgs_outputs_modulation_carriers_freq(awg => $awg, output => $output, carrier=>$carrier)

Indicates the frequency used for this carrier. The frequency is calculated with oscillator frequency
times the harmonic factor.
Note: This option was not available in the device used for developement, it is therefore untested.

=head3 /DEV/AWGS/n/OUTPUTS/m/MODULATION/CARRIERS/k/HARMONIC
Properties: Read Write Setting
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_outputs_modulation_carriers_harmonic(awg => $awg, output => $output, carrier=>$carrier, value => $value)
 get_awgs_outputs_modulation_carriers_harmonic(awg => $awg, output => $output, carrier=>$carrier)

Multiplies the carrier reference frequency with the integer factor defined by this field.
Note: This option was not available in the device used for developement, it is therefore untested.

=head3 /DEV/AWGS/n/OUTPUTS/m/MODULATION/CARRIERS/k/OSCSELECT
Properties: Read Write Setting
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_outputs_modulation_carriers_oscselect(awg => $awg, output => $output, carrier=>$carrier, value => $value)
 get_awgs_outputs_modulation_carriers_oscselect(awg => $awg, output => $output, carrier=>$carrier)

Select oscillator for generation of this carrier.
Note: This option was not available in the device used for developement, it is therefore untested.

=head3 /DEV/AWGS/n/OUTPUTS/m/MODULATION/CARRIERS/k/PHASESHIFT
Properties: Read Write Setting
Type: Double(D)
Unit: deg

 set_awgs_outputs_modulation_carriers_phaseshift(awg => $awg, output => $output, carrier=>$carrier, value => $value)
 get_awgs_outputs_modulation_carriers_phaseshift(awg => $awg, output => $output)

Phase shift applied to carrier signal.
Note: This option was not available in the device used for developement, it is therefore untested.

=head3 /DEV/AWGS/n/OUTPUTS/m/MODULATION/MODE 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_awgs_outputs_modulation_mode(awg => $awg, output => $output, value => $value)
 get_awgs_outputs_modulation_mode(awg => $awg, output => $output)

Select modulation mode between off, sine modulation and advanced.
off0
Modulation Off: AWG Output goes directly to Signal Output.
sine001
Sine 11: AWG Outputs 0 and 1 are both multiplied with Sine Generator signal 0.
sine112
Sine 22: AWG Outputs 0 and 1 are both multiplied with Sine Generator signal 1.
sine013
Sine 12: AWG Outputs 0 and 1 are multiplied with Sine Generator signal 0 and 1,
respectively.
sine104
Sine 21: AWG Outputs 0 and 1 are multiplied with Sine Generator signal 1 and 0,
respectively.
advanced5
Advanced: Output modulates corresponding sines from modulation carriers.
mixer6
Mixer Calibration: The AWG outputs are multiplied with the sum or difference
of Sine Generators multiplied by gains specified. The resulting output signal is
AWG1*(Sine1*Gain1 - Sine2*Gain2) + AWG2*(Sine1*Gain2 + Sine2*Gain1).

=head3 /DEV/AWGS/n/READY 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_awgs_ready(awg => $awg)

AWG has a compiled wave form and is ready to be enabled.

=head3 /DEV/AWGS/n/RESET 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_reset(awg => $awg, value => $value)
 get_awgs_reset(awg => $awg)

Clears the configured AWG program and resets the state to not ready.

=head3 /DEV/AWGS/n/RTLOGGER/CLEAR 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_rtlogger_clear(awg => $awg, value => $value)
 get_awgs_rtlogger_clear(awg => $awg)

Clears the logger data.

=head3 /DEV/AWGS/n/RTLOGGER/ENABLE 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_rtlogger_enable(awg => $awg, value => $value)
 get_awgs_rtlogger_enable(awg => $awg)

Activates the Real-time Logger.

=head3 /DEV/AWGS/n/RTLOGGER/MODE 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_awgs_rtlogger_mode(awg => $awg, value => $value)
 get_awgs_rtlogger_mode(awg => $awg)

Selects the operation mode.
normal0
Normal: Logger starts with the AWG and overwrites old values as soon as the
memory limit of 1024 entries is reached.
timestamp1
Timestamp-triggered: Logger starts with the AWG, waits for the first valid trigger, and
only starts recording data after the time specified by the starttimestamp. Recording
stops as soon as the memory limit of 1024 entries is reached.

=head3 /DEV/AWGS/n/RTLOGGER/STARTTIMESTAMP 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_rtlogger_starttimestamp(awg => $awg, value => $value)
 get_awgs_rtlogger_starttimestamp(awg => $awg)

Timestamp at which to start logging for timestamp-triggered mode.

=head3 /DEV/AWGS/n/RTLOGGER/STATUS 
Properties: Read 
Type: Integer (enumerated)(I)
Unit: None

 get_awgs_rtlogger_status(awg => $awg)

Operation state.
idle0
Idle: Logger is not running.
normal1
Normal: Logger is running in normal mode.
ts_wait2
Wait for timestamp: Logger is in timestamp-triggered mode and waits for start
timestamp.
ts_active3
Active: Logger is in timestamp-triggered mode and logging.
ts_full4
Log Full: Logger is in timestamp-triggered mode and has stopped logging because
log is full.
erasing5
Erasing: Log is being erased

=head3 /DEV/AWGS/n/RTLOGGER/TIMEBASE 
Properties: Read 
Type: Double(D)
Unit: s

 get_awgs_rtlogger_timebase(awg => $awg)

Minimal time difference between two timestamps. The value matches the awg execution rate.

=head3 /DEV/AWGS/n/SEQUENCER/CONTINUE 
Properties: Read Write 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_sequencer_continue(awg => $awg, value => $value)
 get_awgs_sequencer_continue(awg => $awg)

Reserved for future use.

=head3 /DEV/AWGS/n/SEQUENCER/MEMORYUSAGE 
Properties: Read 
Type: Double(D)
Unit: None

 get_awgs_sequencer_memoryusage(awg => $awg)

Size of the current Sequencer program relative to the available instruction memory of 16
kInstructions (16'384 instructions).

=head3 /DEV/AWGS/n/SEQUENCER/NEXT 
Properties: Read Write 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_sequencer_next(awg => $awg, value => $value)
 get_awgs_sequencer_next(awg => $awg)

Reserved for future use.

=head3 /DEV/AWGS/n/SEQUENCER/PC 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_awgs_sequencer_pc(awg => $awg)

Current position in the list of sequence instructions during execution.

=head3 /DEV/AWGS/n/SEQUENCER/STATUS 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_awgs_sequencer_status(awg => $awg)

Status of the sequencer on the instrument. Bit 0: sequencer is running; Bit 1: reserved; Bit 2:
sequencer is waiting for a trigger to arrive; Bit 3: AWG has detected an error; Bit 4: reserved.

=head3 /DEV/AWGS/n/SEQUENCER/TRIGGERED 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_awgs_sequencer_triggered(awg => $awg)

When 1, indicates that the AWG Sequencer has been triggered.

=head3 /DEV/AWGS/n/SINGLE 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_single(awg => $awg, value => $value)
 get_awgs_single(awg => $awg)

Puts the AWG into single shot mode.

=head3 /DEV/AWGS/n/SWEEP/AWGTRIGS/m 
Properties: Read Write 
Type: Double(D)
Unit: Dependent

 set_awgs_sweep_awgtrigs(awg => $awg, trig => $trig value => $value)
 get_awgs_sweep_awgtrigs(awg => $awg, trig => $trig)

Node used by the sweeper module for fast index sweeps. When selected as sweep grid the
sweeper module will switch into a fast index based scan mode. This mode can be up to 1000 times
faster than conventional node sweeps. The sequencer program must support this functionality.
See section 'AWG Index Sweep' of the UHF user manual for more information.
Note: This option was not available in the device used for developement, it is therefore untested.

=head3 /DEV/AWGS/n/TIME 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_awgs_time(awg => $awg, value => $value)
 get_awgs_time(awg => $awg)

AWG sampling rate. The numeric values here are an example when the base sample rate is the
default value of 2.4 GHz and are rounded for display purposes. The exact values are equal to
the base sampling rate divided by 2^n, where n is the node value. The base sample clock is the
node /DEV/SYSTEM/CLOCKS/SAMPLECLOCK/FREQ. This value is used by default and can be
overridden in the Sequence program.
02.4 GHz
11.2 GHz
2600 MHz
3300 MHz
4150 MHz
575 MHz
637.50 MHz
718.75 MHz
89.38 MHz
94.69 MHz
102.34 MHz
111.17 MHz
12585.94 kHz
13292.97 kHz

=head3 /DEV/AWGS/n/USERREGS/m 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_userregs(awg => $awg, userregs=>$userregs, value => $value)
 get_awgs_userregs(awg => $awg, userregs=>$userregs)

Integer user register value. The sequencer has reading and writing access to the user register
values during run time.

=head3 /DEV/AWGS/n/WAVEFORM/MEMORYUSAGE 
Properties: Read 
Type: Double(D)
Unit: %

 get_awgs_waveform_memoryusage(awg => $awg)

Amount of the used waveform data relative to the device cache memory. The cache memory
provides space for 256 kSa (262'144 Sa) per-channel of waveform data. Memory Usage over 100%
means that waveforms must be loaded from the main memory of 64 or 512 MSa (67'108'864 Sa
or 536'870'912 Sa) per-channel during playback.

=head3 /DEV/AWGS/n/WAVEFORM/PLAYING 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_awgs_waveform_playing(awg => $awg)

When 1, indicates if a waveform is being played currently.

=head3 /DEV/AWGS/n/ZSYNC/DECODER/MASK 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_zsync_decoder_mask(awg => $awg, value => $value)
 get_awgs_zsync_decoder_mask(awg => $awg)

8-bit value to select the bits of the message received on ZSync interface coming from the PQSC
error decoder.

=head3 /DEV/AWGS/n/ZSYNC/DECODER/OFFSET 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_zsync_decoder_offset(awg => $awg, value => $value)
 get_awgs_zsync_decoder_offset(awg => $awg)

The additive offset applied to the message received on ZSync interface coming from the PQSC
error decoder.

=head3 /DEV/AWGS/n/ZSYNC/DECODER/SHIFT 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_zsync_decoder_shift(awg => $awg, value => $value)
 get_awgs_zsync_decoder_shift(awg => $awg)

The bit shift applied to the message received on ZSync interface coming from the PQSC error
decoder.

=head3 /DEV/AWGS/n/ZSYNC/REGISTER/MASK 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_zsync_register_mask(awg => $awg, value => $value)
 get_awgs_zsync_register_mask(awg => $awg)

4-bit value to select the bits of the message received on ZSync interface coming from the PQSC
readout registers.

=head3 /DEV/AWGS/n/ZSYNC/REGISTER/OFFSET 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_zsync_register_offset(awg => $awg, value => $value)
 get_awgs_zsync_register_offset(awg => $awg)

The additive offset applied to the message received on ZSync interface coming from the PQSC
readout registers.

=head3 /DEV/AWGS/n/ZSYNC/REGISTER/SHIFT 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_awgs_zsync_register_shift(awg => $awg, value => $value)
 get_awgs_zsync_register_shift(awg => $awg)

The bit shift applied to the message received on ZSync interface coming from the PQSC readout
registers.

=head2 ClOCKBASE
=head3 /DEV/CLOCKBASE 
Properties: Read 
Type: Double(D)
Unit: Hz

 get_clockbase()

Returns the internal clock frequency of the device.

=head2 CNT
Note: None of the functionality could be tested here since the module was missing in developement.
=head3 /DEV/CNTS/n/ENABLE 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_cnts_enable(cnt => $cnt, value => $value)
 get_cnts_enable(cnt => $cnt)

Enable the pulse counter unit.
Note: This option was not available in the device used for developement, it is therefore untested.

=head3 /DEV/CNTS/n/GATESELECT 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_cnts_gateselect(cnt => $cnt, value => $value)
 get_cnts_gateselect(cnt => $cnt)

Select the signal source used for enabling the counter in the Gated Free Running and Gated
modes.
trigin0, trigger_input0 0
Trigger/Ref Input 1 (front panel).
trigin1, trigger_input1 1
Trigger/Ref Input 2 (front panel).
trigin2, trigger_input2 2
Trigger Input 3 (rear panel).
trigin3, trigger_input3 3
Trigger Input 4 (rear panel).
awg_trigger04
AWG Trigger 1.
awg_trigger15
AWG Trigger 2.
awg_trigger26
AWG Trigger 3.
awg_trigger37
AWG Trigger 4.

=head3 /DEV/CNTS/n/INPUTSELECT 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_cnts_inputselect(cnt => $cnt, value => $value)
 get_cnts_inputselect(cnt => $cnt)

Select the counter signal source.
0DIO Bit 0.
1DIO Bit 1.
2DIO Bit 2.
3DIO Bit 3.
4DIO Bit 4.
5DIO Bit 5.
6DIO Bit 6.
7DIO Bit 7.
8DIO Bit 8.
9DIO Bit 9.
10DIO Bit 10.
11DIO Bit 11.
12DIO Bit 12.
13DIO Bit 13.
14DIO Bit 14.
15DIO Bit 15.
16DIO Bit 16.
17DIO Bit 17.
18DIO Bit 18.
19DIO Bit 19.
20DIO Bit 20.
21DIO Bit 21.
22DIO Bit 22.
23DIO Bit 23.
24DIO Bit 24.
25DIO Bit 25.
26DIO Bit 26.
27DIO Bit 27.
28DIO Bit 28.
29DIO Bit 29.
30DIO Bit 30.
31DIO Bit 31.
trigin0, trigger_input0 32
Trigger/Ref Input 1 (front panel).
trigin1, trigger_input1 33
Trigger/Ref Input 2 (front panel).
trigin2, trigger_input2 34
Trigger Input 3 (rear panel).
trigin3, trigger_input3 35
Trigger Input 4 (rear panel).

=head3 /DEV/CNTS/n/INTEGRATE 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_cnts_integrate(cnt => $cnt, value => $value)
 get_cnts_integrate(cnt => $cnt)

Sum up counter values over time.

=head3 /DEV/CNTS/n/MODE 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_cnts_mode(cnt => $cnt, value => $value)
 get_cnts_mode(cnt => $cnt)

Select the run mode of the counter unit.
free_running1
Free Running: The counter runs on a repetitive time base defined by the Period
field. At the beginning of each period the counter is reset, and at the end, the
accumulated number of counts is output.
gated_free_running2
Gated Free Running: The counter runs on a repetitive time base defined by the
Period field. The Gate Input signal controls when the unit counter is allowed to
run. The counter as well as the timer is reset when the Gate Input signal is low. The
counter will only deliver new values if the Gate Input signal is high for a time longer
than the configured Period.
gated3
Gated: The counter is controlled with the Gate Input signal. The counter is enabled
at the rising edge of the Gate Input signal and disabled at the falling edge. Pulses are
counted as long as the counter is enabled. The accumulated number of counts is
output on the falling edge of the Gate Input signal.
time_tagging4
Time Tagging: Every pulse is detected individually and tagged with the time of the
event. The Period defines the minimum hold-off time between the tagging of two
subsequent pulses. If more than one pulse occurs within the window defined by the
Period, then the pulses are accumulated and output at the end of the window. The
Period effectively determines the maximum rate at which pulse information can be
transmitted to the host PC.

=head3 /DEV/CNTS/n/OPERATION 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_cnts_operation(cnt => $cnt, value => $value)
 get_cnts_operation(cnt => $cnt)

Select the arithmetic operation (addition, subtraction) applied to the counter unit outputs. 'Other
counter' refers to the grouping of the counter units: 1 with 2, and 3 with 4.
none0
None
add_other_counter1
Add Other Counter
subtract_other_counter2
Subtract Other Counter

=head3 /DEV/CNTS/n/PERIOD 
Properties: Read Write Setting 
Type: Double(D)
Unit: s

 set_cnts_period(cnt => $cnt, value => $value)
 get_cnts_period(cnt => $cnt)

Set the period used for the Free Running and Gated Free Running modes. Also sets the hold-off
time for the Time Tagging mode.

=head3 /DEV/CNTS/n/TRIGFALLING 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_cnts_trigfalling(cnt => $cnt, value => $value)
 get_cnts_trigfalling(cnt => $cnt)

Performs a trigger event when the source signal crosses the trigger level from high to low. For
dual edge triggering, select also the rising edge.

=head3 /DEV/CNTS/n/TRIGRISING 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_cnts_trigrising(cnt => $cnt, value => $value)
 get_cnts_trigrising(cnt => $cnt)

Performs a trigger event when the source signal crosses the trigger level from low to high. For
dual edge triggering, select also the falling edge.

=head3 /DEV/CNTS/n/VALUE 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_cnts_value(cnt => $cnt)

Counter output value.

=head2 DIOS
=head3 /DEV/DIOS/n/DRIVE 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_dios_drive(dio => $dio, value => $value)
 get_dios_drive(dio => $dio)

When on (1), the corresponding 8-bit bus is in output mode. When off (0), it is in input mode. Bit
0 corresponds to the least significant byte. For example, the value 1 drives the least significant
byte, the value 8 drives the most significant byte.

=head3 /DEV/DIOS/n/INPUT 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_dios_input(dio => $dio)

Gives the value of the DIO input for those bytes where drive is disabled.

=head3 /DEV/DIOS/n/INTERFACE 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_dios_interface(dio => $dio, value => $value)
 get_dios_interface(dio => $dio)

Selects the interface standard to use on the 32-bit DIO interface. A value of 0 means that a 3.3 V
CMOS interface is used. A value of 1 means that an LVDS compatible interface is used.

=head3 /DEV/DIOS/n/MODE 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_dios_mode(dio => $dio, value => $value)
 get_dios_mode(dio => $dio)

Select DIO mode
manual0
Enables manual control of the DIO output bits.
awg_sequencer_commands1
Enables setting the DIO output values by AWG sequencer commands and forwards
DIO input values to the AWG sequencer. The DIO interface operates at a clock
frequency of 150 MHz.
dio_codeword2
Enables setting the DIO output values by AWG sequencer commands and forwards
DIO input values to the AWG sequencer. This mode is equivalent to the mode AWG
Sequencer, except for the DIO interface clock frequency which is set to 50 MHz.
qccs3
Enables setting the DIO output values by the ZSync input values. Forwards the ZSync
input values to the AWG sequencer. Forwards the DIO input values to the ZSync
output. Select this mode when the instrument is connected via ZSync to a PQSC.

=head3 /DEV/DIOS/n/OUTPUT 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_dios_output(dio => $dio, value => $value)
 get_dios_output(dio => $dio)

Sets the value of the DIO output for those bytes where 'drive' is enabled.

=head2 FEATURES

=head3 /DEV/FEATURES/CODE 
Properties: Write 
Type: String(B)
Unit: None

 set_features_code(value => $value)

Node providing a mechanism to write feature codes.
Could not test as no feature code had to be installed.

=head3 /DEV/FEATURES/DEVTYPE 
Properties: Read 
Type: String(B)
Unit: None

 get_features_devtype()

Returns the device type.

=head3 /DEV/FEATURES/OPTIONS 
Properties: Read 
Type: String(B)
Unit: None

 get_features_options()

Returns enabled options.

=head3 /DEV/FEATURES/SERIAL 
Properties: Read 
Type: String(B)
Unit: None

 get_features_serial()

Device serial number.

=head3 /DEV/OSCS/n/FREQ 
Properties: Read Write Setting 
Type: Double(D)
Unit: Hz

 set_oscs_freq(osc => $osc, value => $value)
 get_oscs_freq(osc => $osc)

Frequency control for each oscillator.

=head3 /DEV/OSCS/n/FREQAWG 
Properties: Read 
Type: Double(D)
Unit: Hz

 get_oscs_freqawg(osc => $osc)

Frequency as set by the AWG sequencer.

=head3 /DEV/SIGOUTS/n/BUSY 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_sigouts_busy(sigout => $sigout)

Boolean value indicating whether a blocking process is being executed on the device. For
example, locking to the external reference clock.

=head3 /DEV/SIGOUTS/n/DELAY 
Properties: Read Write Setting 
Type: Double(D)
Unit: s

 set_sigouts_delay(sigout => $sigout, value => $value)
 get_sigouts_delay(sigout => $sigout)

This value allows to delay the output of the signal in order to align waves.

=head3 /DEV/SIGOUTS/n/DIRECT 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_sigouts_direct(sigout => $sigout, value => $value)
 get_sigouts_direct(sigout => $sigout)

Enables the direct output path. If enabled the signal will be fed directly from the DAC, reducing
delay and noise. However, the range will be fixed and offset is not available any more.
amplified_path0
Amplified Path
direct_path1
Direct Path

=head3 /DEV/SIGOUTS/n/FILTER 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_sigouts_filter(sigout => $sigout, value => $value)
 get_sigouts_filter(sigout => $sigout)

Enables a filter stage in the amplified path.

=head3 /DEV/SIGOUTS/n/MAX 
Properties: Read 
Type: Double(D)
Unit: None

 get_sigouts_max(sigout => $sigout)

Maximum value transmitted to the DAC represented as a 16-bit integer in two's complement
format.

=head3 /DEV/SIGOUTS/n/MIN 
Properties: Read 
Type: Double(D)
Unit: None

 get_sigouts_min(sigout => $sigout)

Minimum value transmitted to the DAC represented as a 16-bit integer in twos complement
format.

=head3 /DEV/SIGOUTS/n/OFFSET 
Properties: Read Write Setting 
Type: Double(D)
Unit: V

 set_sigouts_offset(sigout => $sigout, value => $value)
 get_sigouts_offset(sigout => $sigout)

Defines the DC voltage that is added to the dynamic part of the output signal.

=head3 /DEV/SIGOUTS/n/ON 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_sigouts_on(sigout => $sigout, value => $value)
 get_sigouts_on(sigout => $sigout)

Enabling/Disabling the Signal Output. Corresponds to the blue LED indicator on the instrument
front panel.

=head3 /DEV/SIGOUTS/n/OVER 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_sigouts_over(sigout => $sigout)

Indicates that the signal output is overloaded.
/DEV/SIGOUTS/n/PRECOMPENSATION/BOUNCES/m/AMPLITUDE
Properties:Read, Write, Setting
Type:Double
Unit: None
Sets the amplitude of the bounce correction filter relative to the signal amplitude.

=head3 /DEV/SIGOUTS/n/RANGE 
Properties: Read Write Setting 
Type: Double(D)
Unit: V

 set_sigouts_range(sigout => $sigout, value => $value)
 get_sigouts_range(sigout => $sigout)

Sets the output voltage range. The instrument selects the next higher available range.

=head3 /DEV/SINES/n/AMPLITUDES/m 
Properties: Read Write Setting 
Type: Double(D)
Unit: None

 set_sines_amplitudes(sine => $sine, amplitude=> $amplitude, value => $value)
 get_sines_amplitudes(sine => $sine, amplitude=>$amplitude)

Sets the peak amplitude that the sine signal contributes to the signal output. Note that the last
index is either 0 or 1 and will map to the pair of outputs given by the first index. (e.g. sines/3/
amplitudes/0 corresponds to wave output 2)

=head3 /DEV/SINES/n/ENABLES/m 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_sines_enables(sine => $sine, amplitude=>$amplitude,value => $value)
 get_sines_enables(sine => $sine, amplitude=>$amplitude)

Enables the sine signal to the signal output. Note that the last index is either 0 or 1 and will map
to the pair of outputs given by the first index. (e.g. sines/3/amplitudes/0 corresponds to wave
output 2)

=head3 /DEV/SINES/n/HARMONIC 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_sines_harmonic(sine => $sine, value => $value)
 get_sines_harmonic(sine => $sine)

Multiplies the sine signals reference frequency with the integer factor defined by this field.

=head3 /DEV/SINES/n/OSCSELECT 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_sines_oscselect(sine => $sine, value => $value)
 get_sines_oscselect(sine => $sine)

Select oscillator for generation of this sine signal.

=head3 /DEV/SINES/n/PHASESHIFT 
Properties: Read Write Setting 
Type: Double(D)
Unit: deg

 set_sines_phaseshift(sine => $sine, value => $value)
 get_sines_phaseshift(sine => $sine)

Phase shift applied to sine signal.

=head3 /DEV/STATS/CMDSTREAM/BANDWIDTH 
Properties: Read 
Type: Double(D)
Unit: Mbit/s

 get_stats_cmdstream_bandwidth()

Command streaming bandwidth usage on the physical network connection between device and
data server.

=head3 /DEV/STATS/CMDSTREAM/BYTESRECEIVED 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: B

 get_stats_cmdstream_bytesreceived()

Number of bytes received on the command stream from the device since session start.

=head3 /DEV/STATS/CMDSTREAM/BYTESSENT 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: B

 get_stats_cmdstream_bytessent()

Number of bytes sent on the command stream from the device since session start.

=head3 /DEV/STATS/CMDSTREAM/PACKETSLOST 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_stats_cmdstream_packetslost()

Number of command packets lost since device start. Command packets contain device settings
that are sent to and received from the device.

=head3 /DEV/STATS/CMDSTREAM/PACKETSRECEIVED 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_stats_cmdstream_packetsreceived()

Number of packets received on the command stream from the device since session start.

=head3 /DEV/STATS/CMDSTREAM/PACKETSSENT 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_stats_cmdstream_packetssent()

Number of packets sent on the command stream to the device since session start.

=head3 /DEV/STATS/CMDSTREAM/PENDING 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_stats_cmdstream_pending()

Number of buffers ready for receiving command packets from the device.

=head3 /DEV/STATS/CMDSTREAM/PROCESSING 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_stats_cmdstream_processing()

Number of buffers being processed for command packets. Small values indicate proper
performance. For a TCP/IP interface, command packets are sent using the TCP protocol.

=head3 /DEV/STATS/DATASTREAM/BANDWIDTH 
Properties: Read 
Type: Double(D)
Unit: Mbit/s

 get_stats_datastream_bandwidth()

Data streaming bandwidth usage on the physical network connection between device and data
server.

=head3 /DEV/STATS/DATASTREAM/BYTESRECEIVED 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: B

 get_stats_datastream_bytesreceived()

Number of bytes received on the data stream from the device since session start.

=head3 /DEV/STATS/DATASTREAM/PACKETSLOST 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_stats_datastream_packetslost()

Number of data packets lost since device start. Data packets contain measurement data.

=head3 /DEV/STATS/DATASTREAM/PACKETSRECEIVED 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_stats_datastream_packetsreceived()

Number of packets received on the data stream from the device since session start.

=head3 /DEV/STATS/DATASTREAM/PENDING 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_stats_datastream_pending()

Number of buffers ready for receiving data packets from the device.

=head3 /DEV/STATS/DATASTREAM/PROCESSING 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_stats_datastream_processing()

Number of buffers being processed for data packets. Small values indicate proper performance.
For a TCP/IP interface, data packets are sent using the UDP protocol.

=head3 /DEV/STATS/PHYSICAL/FPGA/AUX 
Properties: Read 
Type: Double(D)
Unit: V

 get_stats_physical_fpga_aux()

Supply voltage of the FPGA.

=head3 /DEV/STATS/PHYSICAL/FPGA/CORE 
Properties: Read 
Type: Double(D)
Unit: V

 get_stats_physical_fpga_core()

Core voltage of the FPGA.

=head3 /DEV/STATS/PHYSICAL/FPGA/TEMP 
Properties: Read 
Type: Double(D)
Unit: Celsius

 get_stats_physical_fpga_temp()

Internal temperature of the FPGA.

=head3 /DEV/STATS/PHYSICAL/OVERTEMPERATURE 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_stats_physical_overtemperature()

This flag is set to 1 if the temperature of the FPGA exceeds 85 Celsius. It will be reset to 0 after a restart
of the device.

=head3 /DEV/STATS/PHYSICAL/POWER/CURRENTS/n 
Properties: Read 
Type: Double(D)
Unit: A

 get_stats_physical_power_currents(current => $current)

Currents of the main power supply.

=head3 /DEV/STATS/PHYSICAL/POWER/TEMPERATURES/n 
Properties: Read 
Type: Double(D)
Unit: Celsius

 get_stats_physical_power_temperatures(temperature =>$temperature)

Temperatures of the main power supply.

=head3 /DEV/STATS/PHYSICAL/POWER/VOLTAGES/n 
Properties: Read 
Type: Double(D)
Unit: V

 get_stats_physical_power_voltages(voltage => $voltage)

Voltages of the main power supply.

=head3 /DEV/STATS/PHYSICAL/SLAVEFPGAS/n/AUX 
Properties: Read 
Type: Double(D)
Unit: V

 get_stats_physical_slavefpgas_aux(slavefpga => $slavefpga)

Supply voltage of the FPGA.

=head3 /DEV/STATS/PHYSICAL/SLAVEFPGAS/n/CORE 
Properties: Read 
Type: Double(D)
Unit: V

 get_stats_physical_slavefpgas_core(slavefpga => $slavefpga)

Core voltage of the FPGA.

=head3 /DEV/STATS/PHYSICAL/SLAVEFPGAS/n/TEMP 
Properties: Read 
Type: Double(D)
Unit: Celsius

 get_stats_physical_slavefpgas_temp(slavefpga => $slavefpga)

Internal temperature of the FPGA.

=head3 /DEV/STATS/PHYSICAL/TEMPERATURES/n 
Properties: Read 
Type: Double(D)
Unit: Celsius

 get_stats_physical_temperatures(temperature => $temperature)

Internal temperature measurements.

=head3 /DEV/STATS/PHYSICAL/VOLTAGES/n 
Properties: Read 
Type: Double(D)
Unit: V

 get_stats_physical_voltages(voltage => $voltage)

Internal voltage measurements.

=head3 /DEV/STATUS/ADC0MAX 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_status_adc0max()

The maximum value on Signal Input 1 (ADC0) during 100 ms.

=head3 /DEV/STATUS/ADC0MIN 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_status_adc0min()

The minimum value on Signal Input 1 (ADC0) during 100 ms

=head3 /DEV/STATUS/ADC1MAX 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_status_adc1max()

The maximum value on Signal Input 2 (ADC1) during 100 ms.

=head3 /DEV/STATUS/ADC1MIN 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_status_adc1min()

The minimum value on Signal Input 2 (ADC1) during 100 ms

=head3 /DEV/STATUS/FIFOLEVEL 
Properties: Read 
Type: Double(D)
Unit: None

 get_status_fifolevel()

USB FIFO level: Indicates the USB FIFO fill level inside the device. When 100%, data is lost

=head3 /DEV/STATUS/FLAGS/BINARY 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_status_flags_binary()

A set of binary flags giving an indication of the state of various parts of the device. Bit 11: Sample
Loss.

=head3 /DEV/STATUS/FLAGS/PACKETLOSSTCP 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_status_flags_packetlosstcp()

Flag indicating if tcp packages have been lost.

=head3 /DEV/STATUS/FLAGS/PACKETLOSSUDP 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_status_flags_packetlossudp()

Flag indicating if udp packages have been lost.

=head3 /DEV/STATUS/TIME 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_status_time()

The current timestamp.

=head3 /DEV/SYSTEM/ACTIVEINTERFACE 
Properties: Read 
Type: String(B)
Unit: None

 get_system_activeinterface()

Currently active interface of the device.

=head3 /DEV/SYSTEM/AWG/CHANNELGROUPING 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_system_awg_channelgrouping(value => $value)
 get_system_awg_channelgrouping()

Sets the channel grouping mode of the device.
groups_of_20
Use the outputs in groups of 2. One sequencer program controls 2 outputs (use 
/dev/awgs/0..4/).
groups_of_41
Use the outputs in groups of 4. One sequencer program controls 4 outputs (use 
/dev/awgs/0/ and /dev/awgs/2/)
2groups_of_8
Use the outputs in groups of 8. One sequencer program controls 8 outputs (use 
/dev/awgs/0/). Requires 8 channel device.

=head3 /DEV/SYSTEM/AWG/OSCILLATORCONTROL 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_system_awg_oscillatorcontrol(value => $value)
 get_system_awg_oscillatorcontrol()

Sets the oscillator control mode.
api0
Oscillators are controlled by the UI/API.
awg_sequencer1
Oscillators are controlled by the AWG sequencer.

=head3 /DEV/SYSTEM/BOARDREVISIONS/n 
Properties: Read 
Type: String(B)
Unit: None

 get_system_boardrevisions()

Hardware revision of the FPGA base board

=head3 /DEV/SYSTEM/CLOCKS/REFERENCECLOCK/FREQ 
Properties: Read 
Type: Double(D)
Unit: Hz

 get_system_clocks_referenceclock_freq()

Indicates the frequency of the reference clock.

=head3 /DEV/SYSTEM/CLOCKS/REFERENCECLOCK/SOURCE 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_system_clocks_referenceclock_source(value => $value)
 get_system_clocks_referenceclock_source()

Reference clock source.
internal0
The internal clock is used as the frequency and time base reference.
external1
An external clock is intended to be used as the frequency and time base reference.
Provide a clean and stable 10MHz or 100MHz reference to the appropriate back panel
connector.
2zsync
A ZSync clock is intended to be used as the frequency and time base reference.

=head3 /DEV/SYSTEM/CLOCKS/REFERENCECLOCK/STATUS 
Properties: Read 
Type: Integer (enumerated)(I)
Unit: None

 get_system_clocks_referenceclock_status()

Status of the reference clock.
0Reference clock has been locked on.
1There was an error locking onto the reference clock signal. After an error the source
is automatically switched back to internal reference clock.
2The device is busy trying to lock onto the reference clock signal.

=head3 /DEV/SYSTEM/CLOCKS/SAMPLECLOCK/FREQ 
Properties: Read Write Setting 
Type: Double(D)
Unit: Hz

 set_system_clocks_sampleclock_freq(value => $value)
 get_system_clocks_sampleclock_freq()

Indicates the frequency of the sample clock. Changing the sample clock temporarily interrupts
the AWG sequencers.

=head3 /DEV/SYSTEM/CLOCKS/SAMPLECLOCK/OUTPUTENABLE 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_system_clocks_sampleclock_outputenable(value => $value)
 get_system_clocks_sampleclock_outputenable()

Enable the sampleclock output.
on0
Sample clock output is disabled.
off1
Sample clock output is enabled.

=head3 /DEV/SYSTEM/CLOCKS/SAMPLECLOCK/STATUS 
Properties: Read 
Type: Integer (enumerated)(I)
Unit: None

 get_system_clocks_sampleclock_status()

Status of the sample clock.
0Sample clock signal is valid and has been locked on.
1There was an error adjusting the sample clock.
2The device is busy trying to adjust the sample clock.

=head3 /DEV/SYSTEM/FPGAREVISION 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_system_fpgarevision()

HDL firmware revision.

=head3 /DEV/SYSTEM/FWLOGENABLE 
Properties: Read Write 
Type: Integer (64 bit)(I)
Unit: None

 set_system_fwlogenable(value => $value)
 get_system_fwlogenable()

Enables logging to the fwlog node.

=head3 /DEV/SYSTEM/FWREVISION 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_system_fwrevision()

Revision of the device-internal controller software.

=head3 /DEV/SYSTEM/FX3REVISION 
Properties: Read 
Type: String(B)
Unit: None

 get_system_fx3revision()

USB firmware revision.

=head3 /DEV/SYSTEM/IDENTIFY 
Properties: Read Write 
Type: Integer (64 bit)(I)
Unit: None

 set_system_identify(value => $value)
 get_system_identify()

Setting this node to 1 will cause the device to blink the power led for a few seconds.

=head3 /DEV/SYSTEM/INTERFACESPEED 
Properties: Read 
Type: String(B)
Unit: None

 get_system_interfacespeed()

Speed of the currently active interface (USB only).

=head3 /DEV/SYSTEM/KERNELTYPE 
Properties: Read 
Type: String(B)
Unit: None

 get_system_kerneltype()

Returns the type of the data server kernel (mdk or hpk).

=head3 /DEV/SYSTEM/OWNER 
Properties: Read 
Type: String(B)
Unit: None

 get_system_owner()

Returns the current owner of the device (IP).

=head3 /DEV/SYSTEM/POWERCONFIGDATE 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_system_powerconfigdate()

Contains the date of power configuration (format is: (year << 16) | (month << 8) | day)

=head3 /DEV/SYSTEM/PRESET/BUSY 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_system_preset_busy()

Indicates if presets are currently loaded.

=head3 /DEV/SYSTEM/PRESET/ERROR 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_system_preset_error()

Indicates if the last operation was illegal. Successful: 0, Error: 1.

=head3 /DEV/SYSTEM/PRESET/LOAD 
Properties: Read Write 
Type: Integer (64 bit)(I)
Unit: None

 set_system_preset_load(value => $value)
 get_system_preset_load()

Load the selected preset.

=head3 /DEV/SYSTEM/PROPERTIES/FREQRESOLUTION 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_system_properties_freqresolution()

The number of bits used to represent a frequency.

=head3 /DEV/SYSTEM/PROPERTIES/FREQSCALING 
Properties: Read 
Type: Double(D)
Unit: None

 get_system_properties_freqscaling()

The scale factor to use to convert a frequency represented as a freqresolution-bit integer to a
floating point value.

=head3 /DEV/SYSTEM/PROPERTIES/MAXFREQ 
Properties: Read 
Type: Double(D)
Unit: None

 get_system_properties_maxfreq()

The maximum oscillator frequency that can be set.

=head3 /DEV/SYSTEM/PROPERTIES/MAXTIMECONSTANT 
Properties: Read 
Type: Double(D)
Unit: s

 get_system_properties_maxtimeconstant()

The maximum demodulator time constant that can be set. Only relevant for lock-in amplifiers.

=head3 /DEV/SYSTEM/PROPERTIES/MINFREQ 
Properties: Read 
Type: Double(D)
Unit: None

 get_system_properties_minfreq()

The minimum oscillator frequency that can be set.

=head3 /DEV/SYSTEM/PROPERTIES/MINTIMECONSTANT 
Properties: Read 
Type: Double(D)
Unit: s

 get_system_properties_mintimeconstant()

The minimum demodulator time constant that can be set. Only relevant for lock-in amplifiers.

=head3 /DEV/SYSTEM/PROPERTIES/NEGATIVEFREQ 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_system_properties_negativefreq()

Indicates whether negative frequencies are supported.

=head3 /DEV/SYSTEM/PROPERTIES/TIMEBASE 
Properties: Read 
Type: Double(D)
Unit: s

 get_system_properties_timebase()

Minimal time difference between two timestamps. The value is equal to 1/(maximum sampling
rate).

=head3 /DEV/SYSTEM/SAVEPORTS 
Properties: Read Write 
Type: Integer (64 bit)(I)
Unit: None

 set_system_saveports(value => $value)
 get_system_saveports()

Flag indicating that the TCP and UDP ports should be saved.

=head3 /DEV/SYSTEM/SLAVEREVISION 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_system_slaverevision()

HDL firmware revision of the slave FPGA.

=head3 /DEV/TRIGGERS/IN/n/IMP50 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_triggers_in_imp50(in => $in, value => $value)
 get_triggers_in_imp50(in => $in)

Trigger input impedance: When on, the trigger input impedance is 50 Ohm, when off 1 k Ohm.

=head3 /DEV/TRIGGERS/IN/n/LEVEL 
Properties: Read Write Setting 
Type: Double(D)
Unit: V

 set_triggers_in_level(in => $in, value => $value)
 get_triggers_in_level(in => $in)

Trigger voltage level at which the trigger input toggles between low and high. Use 50% amplitude
for digital input and consider the trigger hysteresis.

=head3 /DEV/TRIGGERS/IN/n/VALUE 
Properties: Read 
Type: Integer (64 bit)(I)
Unit: None

 get_triggers_in_value(in => $in)

Shows the trigger input. The value integrated over some time. Values are 1: low, 2: high, 3: was low
and high in the period.

=head3 /DEV/TRIGGERS/OUT/n/DELAY 
Properties: Read Write Setting 
Type: Double(D)
Unit: s

 set_triggers_out_delay(out => $out, value => $value)
 get_triggers_out_delay(out => $out)

Trigger delay, controls the fine delay of the trigger output. The resolution is 78 ps.

=head3 /DEV/TRIGGERS/OUT/n/SOURCE 
Properties: Read Write Setting 
Type: Integer (enumerated)(I)
Unit: None

 set_triggers_out_source(out => $out, value => $value)
 get_triggers_out_source(out => $out)

Assign a signal to a marker.
awg_trigger00
Trigger output is assigned to AWG Trigger 1, controlled by AWG sequencer
commands.
awg_trigger11
Trigger output is assigned to AWG Trigger 2, controlled by AWG sequencer
commands.
awg_trigger22
Trigger output is assigned to AWG Trigger 3, controlled by AWG sequencer
commands.
awg_trigger33
Trigger output is assigned to AWG Trigger 4, controlled by AWG sequencer
commands.
output0_marker04
Output is assigned to Output 1 Marker 1.
output0_marker15
Output is assigned to Output 1 Marker 2.
6output1_marker0
Output is assigned to Output 2 Marker 1.
output1_marker17
Output is assigned to Output 2 Marker 2.
trigin0, trigger_input0 8
Output is assigned to Trigger Input 1.
trigin1, trigger_input1 9
Output is assigned to Trigger Input 2.
trigin2, trigger_input2 10
Output is assigned to Trigger Input 3.
trigin3, trigger_input3 11
Output is assigned to Trigger Input 4.
trigin4, trigger_input4 12
Output is assigned to Trigger Input 5.
trigin5, trigger_input5 13
Output is assigned to Trigger Input 6.
trigin6, trigger_input6 14
Output is assigned to Trigger Input 7.
trigin7, trigger_input7 15
Output is assigned to Trigger Input 8.
high17
Output is set to high.
low18
Output is set to low.

=head3 /DEV/TRIGGERS/STREAMS/n/ENABLE 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_triggers_streams_enable(stream => $stream, value => $value)
 get_triggers_streams_enable(stream => $stream)

Enables trigger streaming.

=head3 /DEV/TRIGGERS/STREAMS/n/HOLDOFFTIME 
Properties: Read Write Setting 
Type: Double(D)
Unit: s

 set_triggers_streams_holdofftime(stream => $stream, value => $value)
 get_triggers_streams_holdofftime(stream => $stream)

Sets the holdoff time of the trigger unit.

=head3 /DEV/TRIGGERS/STREAMS/n/MASK 
Properties: Read Write Setting 
Type: Integer (64 bit)(I)
Unit: None

 set_triggers_streams_mask(stream => $stream, value => $value)
 get_triggers_streams_mask(stream => $stream)

Masks triggers for the current stream. The mask is bit encoded where bit 0..7 are the input triggers
and bit 8..11 are AWG triggers.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by the Lab::Measurement team; in detail:

  Copyright 2023       Andreas K. Huettel, Erik Fabrizzi


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
