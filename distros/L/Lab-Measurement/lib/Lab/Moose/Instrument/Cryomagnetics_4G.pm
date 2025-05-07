package Lab::Moose::Instrument::Cryomagnetics_4G;
$Lab::Moose::Instrument::Cryomagnetics_4G::VERSION = '3.931';
#ABSTRACT: Cryomagnetics 4G superconducting magnet power supply

use v5.20;

use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/
    validated_getter validated_setter setter_params /;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;
use Lab::Moose::Countdown;

extends 'Lab::Moose::Instrument';

with qw(
    Lab::Moose::Instrument::Common
);

has verbose => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

has heater_delay => (
	is		=> 'ro',
	isa		=> 'Lab::Moose::PosInt',
	default => 60
);

has max_field_deviation => (
	is		=> 'ro',
	isa		=> 'Num',
	default => 0.0001
);

has field_constant => (
	is		=> 'ro',
	isa		=> 'Num',
	required => 1,
);

sub BUILD {
    my $self  = shift;
    my $units = $self->get_units();
    if ( $units eq 'A' ) {
        carp
            'Warning: Cryomagnetics 4G Power supply uses current units (A) not field units';
		carp 'Switch to Gauss (but everything will be given in Tesla) units!';
		$self->set_units(value => 'G');
    }
}


sub _remove_unit {
    my $rv = shift;
    $rv =~ s/[a-zA-Z]*$//;
    return $rv;
}

sub _kG_to_tesla {
    my $kG = shift;
    return 0.1 * $kG;
}

sub _tesla_to_kG {
    my $tesla = shift;
    return 10 * $tesla;
}

sub _tesla_to_amp {
	my ($self, $value, %args) = validated_setter(
		\@_,
		value => { isa => 'num' },
	);

	return $value * $self->field_constant();
}
	



sub get_field {
    my $self = shift;
    return _kG_to_tesla( $self->get_iout(@_) );
}


sub get_persistent_field {
    my $self = shift;
    return _kG_to_tesla( $self->get_imag(@_) );
}


sub sweep_to_field {
    my ( $self, %args ) = validated_getter(
        \@_,
        target => { isa => 'Num' },
        rate   => { isa => 'Num' },
    );

    my $point = delete $args{target};
    my $rate  = delete $args{rate};

    $self->config_sweep( point => $point, rate => $rate, %args );

    $self->trg(%args);

    $self->wait(%args);
    return $self->get_field(%args);
}


sub config_sweep {
    my ( $self, %args ) = validated_hash(
        \@_,
        point => { isa => 'Num' },
        rate  => { isa => 'Num' },
    );
    my $target = delete $args{point};
    my $rate   = delete $args{rate};

	say "config sweep with target $target and rate $rate";

	$self->set_field_sweep_rate( value => $rate);
    $self->set_target_field( value => $target);

    my $current_field = $self->get_field();
    #$self->_check_sweep_parameters(
    #    current => $current_field, target => $target,
    #    rate    => $rate
    #);
    if ( $self->verbose() ) {
        say "config_sweep: target: $target (T), rate: $rate (T/min)";
    }
}


sub set_target_field {
	my ( $self, $value, %args) = validated_setter( 
		\@_,
		value => { isa => 'Num' },
	);
	$value = _tesla_to_kG($value);
	$self->set_setpoint(value => $value);
}

sub get_target_field {
	my ( $self, %args) = validated_getter( \@_ );
	return _kG_to_tesla($self->get_setpoint());
}


sub set_field_sweep_rate {
	my ( $self, $value, %args) = validated_setter( 
		\@_,
		value => { isa => 'Num' },
	);
	my $amprate = $self->_tesla_to_amp($value) / 60;
	#my $gausrate = _tesla_to_kG($value) / 60;
	for my $range (0 .. 4) {
		$self->set_rate(range => $range, rate => $amprate);
	};
};


sub to_setpoint {
	my ( $self, %args) = validated_getter( \@_ );
	if ($self->get_pshtr() == 0) {
		$self->set_sweep( value => 'UP FAST' );
	} else {
		$self->set_sweep( value => 'UP SLOW' );
	}
}

sub set_setpoint {
	my ( $self, $value, %args) = validated_setter( 
		\@_,
		value => { isa => 'Num' },
	);
	my $lowerlimit = $self->get_llim();
	# my upperlimit = $self->get_ulim();
	if ($value < $lowerlimit) {
		$self->set_llim(value => $value);
		$self->set_ulim(value => $value);
	} else {
		$self->set_ulim(value => $value);
		$self->set_llim(value => $value);
	}
}

sub get_setpoint {
	my ( $self, %args) = validated_getter( \@_ );
	return $self->get_ulim( @_ );
}

sub trg {
	my ( $self, %args) = validated_getter( \@_ );
	$self->to_setpoint();	
}

sub wait {
	my ( $self, %args) = validated_getter( \@_ );
    my $target  = $self->get_target_field();
    my $verbose = $self->verbose();
    # enable autoflush
    my $autoflush = STDOUT->autoflush();
    my $last_field;
    my $time_step = 1;
    while (1) {
        sleep $time_step;
        my $field = $self->get_field(%args);
        if ($verbose) {
            my $rate;
            if ( defined $last_field ) {
                $rate = ( $field - $last_field ) * 60 / $time_step;
                $rate = sprintf( "%.5g", $rate );
            }
            else {
                $rate = "unknown";
            }
            printf(
                "Field: %.6e T, Estimated rate: $rate T/min       \r",
                $field
            );
            $last_field = $field;
        }
        if ( abs( $field - $target ) < $self->max_field_deviation() ) {
			$self->hold();
            last;
        }
    }
    if ($verbose) {
        print " " x 70 . "\r";
    }
    # reset autoflush to previous value
    STDOUT->autoflush($autoflush);
}

# sub active {

# }


sub to_zero {
	my ( $self, %args) = validated_getter( \@_ );
	$self->set_sweep(value => 'ZERO', @_);
}


sub hold {
	my ( $self, %args) = validated_getter( \@_ );
	$self->set_sweep(value => 'PAUSE', @_);
}


sub in_persistent_mode {
    my ( $self, %args ) = validated_getter( \@_ );
	my $rv   = $self->get_pshtr(@_);
    if ( $rv eq 1 ) {
        return 0;
    }
    elsif ( $rv eq 0 ) {
        return 1;
    }
    else {
        croak("unknown heater setting $rv");
    }
}


sub unset_persistent_mode {
	my ( $self, %args ) = validated_getter( \@_ );
	if ($self->in_persistent_mode()) {
		my $pers_field = $self->get_persistent_field();
		my $powerline_field = $self->get_field();

		if (abs($powerline_field - $pers_field) < $self->max_field_deviation()) {
			$self->heater_on();
			return;
		} else {
			$self->set_target_field( value => $pers_field );
			$self->set_sweep(value => 'UP FAST');
			countdown(120/5);
			$self->set_sweep(value => 'UP');
			#$self->wait();
			$self->heater_on();
			return;
		};
	} else {
		return;
	};
}


sub set_persistent_mode {
	my ( $self, %args) = validated_getter( \@_ );
	if ($self->in_persistent_mode()) {
		return;
	} else {
		$self->heater_off();
		$self->to_zero();
		# $self->wait();
		return;
	};
}


sub heater_on {
	my ( $self, %args) = validated_getter( \@_ );
	$self->set_pshtr(value => 'On', @_);
	countdown( $self->heater_delay(), "Activated switch heater. Waiting for: ");
}

sub heater_off {
	my ( $self, %args) = validated_getter( \@_ );
	$self->set_pshtr(value => 'Off', @_);
	countdown( $self->heater_delay(), "Deactivated switch heater. Waiting for: ");
}


sub get_imag {
    my ( $self, %args ) = validated_getter( \@_ );
    my $rv = $self->query( command => "IMAG?", %args );
	return _remove_unit($rv);
}


sub get_iout {
    my ( $self, %args ) = validated_getter( \@_ );
    my $rv = $self->query( command => 'IOUT?', %args );
    return _remove_unit($rv);
}


sub set_llim {
    my ( $self, $value, %args ) = validated_setter( \@_ );
    $self->write( command => "LLIM $value", %args );
}

sub get_llim {
    my ( $self, %args ) = validated_getter( \@_ );
    my $rv = $self->query( command => 'LLIM?', %args );
    return _remove_unit($rv);
}


sub local {
    my ( $self, %args ) = validated_getter( \@_ );
    $self->write( command => "LOCAL", %args );
}


sub get_mode {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => 'MODE?', %args );
}


sub set_pshtr {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/On Off/] ) },
    );
    $self->write( command => "PSHTR $value", %args );
}

sub get_pshtr {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "PSHTR?", %args );
}


sub set_range {
    my ( $self, %args ) = validated_getter(
        \@_,
        select => { isa => enum( [ ( 0 .. 4 ) ] ) },
        limit => { isa => 'Num' },
    );
    my $select = delete $args{select};
    my $limit  = delete $args{limit};
    $self->write( command => "RANGE $select $limit", %args );
}

sub get_range {
    my ( $self, %args ) = validated_getter(
        \@_,
        select => { isa => enum( [ ( 0 .. 4 ) ] ) },
    );
    my $select = delete $args{select};
    return $self->query( command => "RANGE? $select", %args );
}


sub set_rate {
    my ( $self, %args ) = validated_getter(
        \@_,
        range => { isa => enum( [ ( 0 .. 5 ) ] ) },
        rate => { isa => 'Num' },
    );
    my $range = delete $args{range};
    my $rate  = delete $args{rate};
    $self->write( command => "RATE $range $rate", %args );
}

sub get_rate {
    my ( $self, %args ) = validated_getter(
        \@_,
        range => { isa => enum( [ ( 0 .. 5 ) ] ) },
    );
    my $range = delete $args{range};
    return $self->query( command => "RATE? $range", %args );
}


sub set_sweep {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => {
            isa => enum(
                [ qw/UP DOWN PAUSE ZERO LIMIT/, 'UP SLOW', 'DOWN SLOW', 'UP FAST', 'DOWN FAST' ]
            )
        },
    );

    $self->write( command => "SWEEP $value", %args );
}

sub get_sweep {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "SWEEP?", %args );
}


sub set_ulim {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );

    $self->write( command => "ULIM $value", %args );
}

sub get_ulim {
    my ( $self, %args ) = validated_getter( \@_ );
    return _remove_unit( $self->query( command => "ULIM?", %args ) );
}


cache units => ( getter => 'get_units' );

sub set_units {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => enum( [qw/A G/] ) },
    );
    $self->write( command => "UNITS $value", %args );
}

sub get_units {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "UNITS?", %args );
}


sub set_vlim {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );

    $self->write( command => "VLIM $value", %args );
}

sub get_vlim {
    my ( $self, %args ) = validated_getter( \@_ );
    return _remove_unit( $self->query( command => "VLIM?", %args ) );
}


sub get_vmag {
    my ( $self, %args ) = validated_getter( \@_ );
    return _remove_unit( $self->query( command => "VMAG?", %args ) );
}


sub get_vout {
    my ( $self, %args ) = validated_getter( \@_ );
    return _remove_unit( $self->query( command => "VOUT?", %args ) );
}


__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Cryomagnetics_4G - Cryomagnetics 4G superconducting magnet power supply

=head1 VERSION

version 3.931

=head1 SYNOPSIS

  use Lab::Moose;
 
  # Constructor
  my $magnet = instrument(
      type => 'Cryomagnetics_4G',
      connection_type => 'VISA::GPIB',
      connection_options => {'gpib_address' => 10},
	  field_constant => 18.7047 # A/T
  );

Eventhough the magnet power supply does support ethernet and USB besides GPIB, 
both connectiontypes do not seem to work properly (on linux at least...).
Ramp rates are internally set with a ramp current and therefore one needs to 
supply the field constant of the magnet in units of A/T. 

=head1 METHODS

List of all high level methods. These are recommended to use for normal operation!

=head2 get_field

  $magnet->get_field();

Returns current powerline field in units of Tesla.

=head2 get_persistent_field

  $magnet->get_persistent_field();

Returns current persistent field in the magnet in units of Tesla.

=head2 sweep_to_field

 my $new_field = $magnet->sweep_to_field(
    target => $target_field, # Tesla
    rate => $rate, # Tesla/min
 );

=head1 config_sweep

 $magnet->config_sweep(point => $target, rate => $rate);

Only define setpoints, do not start sweep.

=head2 get/set_target_field

  $magnet->set_target_field(value => 1);

Sets or gets the next target field in Tesla.

=head2 set_field_sweep_rate

  $magnet-set_sweep_rate(value => 1) # T/min

Sets the sweep rate for all ranges to the given value in T/min.

=head2 to_zero 

  $magnet->to_zero();

Sweep magnet to 0 field.

=head2 hold

  $magnet->hold();

Set magnet to hold and stop sweeping field.

=head2 in_persistent_mode

  if ($magnet->in_persistent_mode()) {
    # go to desired filed
  } else {
	# Sweep up powerline field and start switch heater
  };

Check if magnet is in persistent mode (the switch heater is on).

=head2 unset_persistent_mode 

  $magnet->unset_persistent_mode()

Disables the persistent mode by driving up powerline field and starting switch heater

=head2 set_persistent_mode 

  $magnet->set_persistent_mode()

Enables the persistent mode with the current field.

=head2 heater_on/heater_off

  $magnet->heater_on();
  $magnet->heater_off();

Set the switch heater to be active or not active. Waits to let it warm up.

=head1 LOW-LEVEL DEVICE METHODS

=head2 get_imag

 my $value = $magnet->get_imag();

Uses either Amps or kilo Gauss, depending on units setting.

=head2 get_iout

 my $value = $magnet->get_iout();

Uses either Amps or kilo Gauss, depending on units setting.

=head2 set_llim/get_llim

 $magnet->set_llim(value => 10);
 my $value = $magnet->get_llim();

Uses either Amps or kilo Gauss, depending on units setting.

=head2 local

$magnet->local();

=head2 get_mode

 my $mode = $magnet->get_mode();

Possible return values: Shim, Manual

=head2 set_pshtr/get_pshtr

 $magnet->set_pshtr(value => 0);
 my $value = $magnet->get_pshtr();

Returns 0 or 1.

=head2 set_range/get_range

 $magnet->set_range(select => 1, limit => 2); # 2 Amps
 my $range = $magnet->get_range(select => 1);

C<select> is in range 0,..,4. 

=head2 set_rate/get_rate

 $magnet->set_rate(range => 1, rate => 0.001); # 1mA / sec 
 my $rate = $magnet->get_rate(range => 1);

C<range> is in range 0,...5, where 5 specifies the rate in fast sweep mode.
C<rate> arg is given in Amps per second.

=head2 set_sweep/get_sweep

 $magnet->set_sweep(value => 'UP');
 $magnet->set_sweep(value => 'UP FAST'); # with switch heater off
 my $mode = $magnet->get_sweep();

C<value> is one off 'UP', 'UP FAST', 'DOWN', 'DOWN FAST', 'PAUSE', 'ZERO', 'LIMIT'

=head2 set_ulim/get_ulim

 $magnet->set_ulim(value => 10);
 my $value = $magnet->get_ulim();

Uses either Amps or kilo Gauss, depending on units setting.

=head2 set_units/get_units

 $magnet->set_units(value => 'A'); # use Amps
 $magnet->set_units(value => 'G'); # use kiloGauss
 my $units = $magnet->get_units(); # 'A' or 'G'

=head2 set_vlim/get_vlim

 $magnet->set_vlim(value => 2); # 2V
 my $vlim = $magnet->get_vlim();

=head2 get_vmag

 my $vmag = $magnet->get_vmag();

=head2 get_vout

 my $vmag = $magnet->get_vout();

=head2 Consumed Roles

This driver consumes the following roles:

=over

=item L<Lab::Moose::Instrument::Common>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by the Lab::Measurement team; in detail:

  Copyright 2022-2023  Simon Reinhardt
            2025       Deadmansshoe


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
