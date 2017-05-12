
package Lab::Instrument::MagnetSupply;
our $VERSION = '3.542';

use Lab::Measurement::KeyboardHandling qw(labkey_soft_check);
use strict;

# about the coding and calling conventions
#
# convention is, all control of magnet power supplies is done via current values,
# never via field values. (we dont know where exactly the sample is anyway!)
#
# if a field constant can be obtained from the instrument, it will be read out
# and used by default.
# if not, it has to be set on initialization, otherwise the program aborts if
# it needs it
#
# persistent mode is not handled yet, i.e. the heater is left completely untouched
#
# all values are given in si base units, i.e. AMPS, TESLA, SECONDS, and their
# derivatives. I.e., a sweep rate is given in AMPS/SECOND.

our @ISA = ('Lab::Instrument');

our %fields = (
    supported_connections => [],

    # supported config options
    device_settings => {
        soft_fieldconstant       => undef,    # T / A
        max_current              => undef,    # A
        max_current_deviation    => 0.01,     # A
        max_sweeprate            => undef,    # A / sec
        max_sweeprate_persistent => undef,    # A / sec
        has_heater               => undef,    # 0 or 1
        heater_delaytime         => undef,    # sec
        can_reverse              => undef,    # 0 or 1
        can_use_negative_current => undef,    # 0 or 1
        use_persistentmode       => undef,    # 0 or 1
    },

    # Config hash passed to subchannel objects or $self->configure()
    default_device_settings => {},
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    #
    # Temporary workaround to get max_current. This should happen in _construct().
    #
    $self->configure( $self->config() );

    if ( $self->get_max_current() ) {
        print
            "Magnet power supply support is experimental. You have been warned.\n";
        return $self;
    }
    else {
        die
            "MagnetSupply.pm: You have to set max_current for safety reasons. Aborting.\n";
    }
}

sub get_fieldconstant {
    my $self = shift;

    my $sw = $self->get_soft_fieldconstant();
    my $hw;

    if ($sw) {
        return $sw;
    }
    else {
        # no value for the field constant stored in the software
        # read value from the hardware
        $hw = $self->_get_fieldconstant();
        if ($hw) {
            $self->set_soft_fieldconstant($hw);
            return $hw;
        }
        else {
            die "Field constant required but not set\n!";
        }
    }
}

# converts the argument in AMPS to TESLA
sub ItoB {
    my $self    = shift;
    my $current = shift;
    return ( $self->get_fieldconstant() * $current );
}

# converts the argument in TESLA to AMPS
sub BtoI {
    my $self  = shift;
    my $field = shift;
    return ( $field / $self->get_fieldconstant() );
}

# field in TESLA
sub set_field {
    my $self    = shift;
    my $field   = shift;
    my $current = $self->BtoI($field);

    # print "set_field: target field $field T, target current $current A \n";
    $field = $self->ItoB( $self->set_current($current) );
    return $field;
}

# current in AMPS
# any value can be supplied, zero transition is handled automatically
sub set_current {
    my $self          = shift;
    my $targetcurrent = shift;

    my $max = $self->get_max_current();

    if ( $targetcurrent > $max )  { $targetcurrent = $max; }
    if ( $targetcurrent < -$max ) { $targetcurrent = -$max; }

    if ( ( $targetcurrent < 0 ) && ( !$self->get_can_reverse() ) ) {
        die "Reverse magnetic field direction not supported by instrument\n";
    }

    if ( $self->get_can_use_negative_current() ) {

        # in this case we dont have to care about anything, just feed the power supply with the
        # target value and wait

        $self->start_sweep_to_current($targetcurrent);

        my $currentcurrent;
        do {
            sleep(5);
            $currentcurrent = $self->get_current();

            if ( labkey_soft_check() eq "DIE" ) {

                # now what do we do here best? we cannot be sure that set_hold is
                # implemented, and failing is not an option.
                print
                    "Setting sweep target to current value I=$currentcurrent\n";
                $self->start_sweep_to_current($currentcurrent);
                print "Terminating on keyboard request.\n";
                exit;
            }

            } while (
            abs( $targetcurrent - $currentcurrent )
            > $self->get_max_current_deviation() );
        sleep(5);
        return $self->get_current();

    }
    else {
        die "fixme: not programmed yet\n";
    }
}

sub start_sweep_to_field {
    my $self  = shift;
    my $field = shift;
    $self->start_sweep_to_current( $self->BtoI($field) );
}

sub start_sweep_to_current {

    # this does not do any special zero handling, just error checking
    # if the impossible is requested, it just dies...

    my $self          = shift;
    my $targetcurrent = shift;

    my $max = $self->get_max_current();
    my $now = $self->get_current();

    if ( $targetcurrent > $max )  { $targetcurrent = $max; }
    if ( $targetcurrent < -$max ) { $targetcurrent = -$max; }

    if ( ( $targetcurrent < 0 ) && ( !$self->get_can_reverse() ) ) {
        die "Reverse magnetic field direction not supported by instrument\n";
    }

    if (   ( $targetcurrent * $now < 0 )
        && ( !$self->get_can_use_negative_current() ) ) {

        # current value and target have different sign
        die
            "You're trying to sweep across zero and it is not supported by the device!\n";
    }

    $self->_set_sweep_target_current($targetcurrent);
    $self->_set_hold(0);

    # pause OFF, so sweeping begins
    # now return, while sweeping continues
}

sub get_field {

    # returns the field in TESLA
    my $self  = shift;
    my $field = $self->ItoB( $self->_get_current() );
    return $field;
}

sub get_current {

    # returns the current in AMPS
    my $self    = shift;
    my $current = $self->_get_current();
    return $current;
}

sub _get_current {
    die 'get_current not implemented for this instrument';
}

# returns:
# 0 == Off (switch closed)
# 1 == On (switch open)
sub get_heater() {
    my $self   = shift;
    my $heater = $self->_get_heater();
    return $heater;
}

sub _get_heater {
    die 'get_heater not implemented for this instrument';
}

# parameter:
# 0  == off
# 1  == on iff PSU=Magnet
# 99 == on (no checks)
sub set_heater() {
    my $self  = shift;
    my $value = shift;
    return $self->_set_heater($value);
}

sub _set_heater {
    die 'set_heater not implemented for this instrument';
}

# returns sweeprate in AMPS/SEC
sub get_sweeprate() {
    my $self = shift;
    my $rate = $self->_get_sweeprate();
    return $rate;
}

sub _get_sweeprate {
    die 'get_sweeprate not implemented for this instrument';
}

# rate in AMPS/MINUTE
sub set_sweeprate() {
    my $self = shift;
    my $rate = shift;
    if ( $rate > $self->get_max_sweeprate() ) {
        $rate = $self->get_max_sweeprate();
    }
    my $newrate = $self->_set_sweeprate($rate);
    return $newrate;
}

sub _set_sweeprate {
    die 'set_sweeprate not implemented for this instrument';
}

sub set_hold {
    my $self     = shift;
    my $value    = shift;
    my $newvalue = $self->_set_hold($value);
    return $newvalue;
}

sub _set_hold {
    die '_set_hold not implemented for this instrument';
}

sub get_hold {
    my $self = shift;
    my $hold = $self->_get_hold();
    return $hold;
}

sub _get_hold {
    die '_get_hold not implemented for this instrument';
}

sub _set_sweep_target_current {
    die '_set_sweep_target_current not implemented for this instrument';
}

sub _get_fieldconstant {
    return 0;
}

1;

=encoding utf8

=head1 NAME

Lab::Instrument::MagnetSupply - base class for magnet power supply instruments

  (c) 2010 David Borowsky, Andreas K. Hüttel
      2011 Andreas K. Hüttel

=cut

