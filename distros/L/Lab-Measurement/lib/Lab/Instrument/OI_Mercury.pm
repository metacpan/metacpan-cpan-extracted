package Lab::Instrument::OI_Mercury;
#ABSTRACT: Oxford Instruments Mercury Cryocontrol (level meter and magnet power supply)
$Lab::Instrument::OI_Mercury::VERSION = '3.600';
use strict;
use Lab::Instrument;

our @ISA = ('Lab::Instrument::MagnetSupply');

our %fields
    = ( supported_connections => [ 'IsoBus', 'Socket', 'GPIB', 'VISA' ], );

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    return $self;
}


sub get_he_level {
    my $self    = shift;
    my $channel = shift;
    $channel = "DB5.L1" unless defined($channel);

    my $level = $self->query("READ:DEV:$channel:LVL:SIG:HEL\n");

    # typical response: STAT:DEV:DB5.L1:LVL:SIG:HEL:LEV:56.3938%:RES:47.8665O

    $level =~ s/^.*:LEV://;
    $level =~ s/%.*$//;
    return $level;
}


sub get_he_level_resistance {
    my $self    = shift;
    my $channel = shift;
    $channel = "DB5.L1" unless defined($channel);

    my $level = $self->query("READ:DEV:$channel:LVL:SIG:HEL\n");

    # typical response: STAT:DEV:DB5.L1:LVL:SIG:HEL:LEV:56.3938%:RES:47.8665O

    $level =~ s/^.*:RES://;
    $level =~ s/:.*$//;
    return $level;
}

sub get_n2_level {
    my $self    = shift;
    my $channel = shift;
    $channel = "DB5.L1" unless defined($channel);

    my $level = $self->query("READ:DEV:$channel:LVL:SIG:NIT\n");

    # typical response: STAT:DEV:DB5.L1:LVL:SIG:NIT:COUN:10125.0000n:FREQ:472867:LEV:52.6014%

    $level =~ s/^.*:LEV://;
    $level =~ s/%.*$//;
    return $level;
}

sub get_n2_level_frequency {
    my $self    = shift;
    my $channel = shift;
    $channel = "DB5.L1" unless defined($channel);

    my $level = $self->query("READ:DEV:$channel:LVL:SIG:NIT\n");

    # typical response: STAT:DEV:DB5.L1:LVL:SIG:NIT:COUN:10125.0000n:FREQ:472867:LEV:52.6014%

    $level =~ s/^.*:FREQ://;
    $level =~ s/:.*$//;
    return $level;
}

sub get_n2_level_counter {
    my $self    = shift;
    my $channel = shift;
    $channel = "DB5.L1" unless defined($channel);

    my $level = $self->query("READ:DEV:$channel:LVL:SIG:NIT\n");

    # typical response: STAT:DEV:DB5.L1:LVL:SIG:NIT:COUN:10125.0000n:FREQ:472867:LEV:52.6014%

    $level =~ s/^.*:COUN://;
    $level =~ s/n:.*$//;
    return $level;
}

sub get_temperature {
    my $self    = shift;
    my $channel = shift;
    $channel = "MB1.T1" unless defined($channel);

    my $level = $self->query("READ:DEV:$channel:TEMP:SIG:TEMP\n");

    # typical response: STAT:DEV:MB1.T1:TEMP:SIG:TEMP:813.1000K

    $level =~ s/^.*:SIG:TEMP://;
    $level =~ s/K.*$//;
    return $level;
}


sub get_catalogue {
    my $self = shift;

    my $catalogue = $self->query("READ:SYS:CAT\n");

    return $catalogue;
}


#
# now follow the core magnet functions
#

sub oim_get_current {
  my $self = shift; 
  
  my $current = $self->query("READ:DEV:GRPZ:PSU:SIG:CURR\n");
  # typical response:
  # STAT:DEV:GRPZ:PSU:SIG:CURR:0.0002A
  
  my $current =~ s/^STAT:DEV:GRPZ:PSU:SIG:CURR://;
  my $current =~ s/A$//;
  return $current;
}



sub oim_get_heater {
  my $self = shift; 
  
  my $heater = $self->query("READ:DEV:GRPZ:PSU:SIG:SWHT\n");
  # typical response:
  # STAT:DEV:GRPZ:PSU:SIG:SWHT:OFF
  
  my $heater =~ s/^STAT:DEV:GRPZ:PSU:SIG:SWHT://;
  return $heater;
}



sub oim_set_heater {
  my $self = shift; 
  my $onoff= shift;
  
  my $heater = $self->query("SET:DEV:GRPZ:PSU:SIG:SWHT:$onoff\n");
  # typical response:
  # STAT:DEV:GRPZ:PSU:SIG:SWHT:OFF
  
  my $heater =~ s/^STAT:DEV:GRPZ:PSU:SIG:SWHT://;
  return $heater;
}



sub oim_force_heater {
  my $self = shift; 
  my $onoff= shift;
  
  my $heater = $self->query("SET:DEV:GRPZ:PSU:SIG:SWHN:$onoff\n");
  # typical response:
  # STAT:DEV:GRPZ:PSU:SIG:SWHN:OFF
  
  my $heater =~ s/^STAT:DEV:GRPZ:PSU:SIG:SWHN://;
  return $heater;
}



sub oim_get_sweeprate {
  my $self = shift; 

  my $sweeprate=$self->query("READ:DEV:GRPZ:PSU:SIG:RCST\n");
  # this returns amps per minute
  $sweeprate =~ s/^STAT:DEV:GRPZ:PSU:SIG:RCST://;
  $sweeprate =~ s/A\/m$//;
  return $sweeprate;
}



sub oim_set_sweeprate {
  my $self = shift; 
  my $sweeprate = shift;

  my $result=$self->query("SET:DEV:GRPZ:PSU:SIG:RCST:$sweeprate\n");
  # this returns amps per minute
  $result =~ s/^STAT:DEV:GRPZ:PSU:SIG:RCST://;
  $result =~ s/A\/m$//;
  return $result;
}



sub oim_set_activity {
  my $self = shift;
  my $action = shift;
  my $result = $self->query("SET:DEV:GRPZ:PSU:SIG:ACTN:$action\n");
  $result =~ s/^STAT:DEV:GRPZ:PSU:SIG:ACTN://;
  return $result;
}



sub oim_get_activity {
  my $self = shift;
  my $action = $self->query("GET:DEV:GRPZ:PSU:SIG:ACTN\n");
  $action  =~ s/^STAT:DEV:GRPZ:PSU:SIG:ACTN://;
  return $action;
}



sub oim_set_setpoint {
  my $self = shift;
  my $targeti = shift;
  
  my $result = $self->query("SET:DEV:GRPZ:PSU:SIG:CSET:$targeti\n");
  $result =~ s/^STAT:DEV:GRPZ:PSU:SIG:CSET://;
  $result =~ s/A$//;
  return $result;
}



# now follows the magnet interface for Lab::Instrument::MagnetSupply

sub _get_current {
    my $self = shift;
    return($self->oim_get_current());
}

sub _get_heater {
    my $self = shift;
    my $heater = $self->oim_get_heater();
    
    if ( $heater eq "OFF" ) { return 0; };
    if ( $heater eq "ON" ) { return 1; };
    die "Unknown heater status \'$heater\'\n";
}

sub _set_heater {
    my $self = shift;
    my $mode = shift;
    
    if ( $mode == 0 ) {
      my $result=$self->oim_set_heater("OFF");
      if ( $result eq "OFF" ) { return 0; } else { die "Heater set off error"; };
    };
    if ( $mode == 1 ) {
      my $result=$self->oim_set_heater("ON");
      if ( $result eq "ON" ) { return 1; } else { die "Heater set on error"; };
    };
    if ( $mode == 99 ) {
      my $result=$self->oim_force_heater("ON");
      if ( $result eq "ON" ) { return 1; } else { die "Heater force on error"; };
    };
    die "Unknown heater mode $mode";
}    

sub _get_sweeprate {
    my $self = shift;

    # the Mercury returns AMPS/MIN
    return ( $self->oim_get_sweeprate() / 60.0 );
}

sub _set_sweeprate {
    my $self = shift;
    my $rate = shift;
    $rate = $rate / 60.0;    # we need APS/MIN
    return ( $self->oim_set_sweeprate($rate) / 60.0 );
}

sub _set_hold {
    my $self = shift;
    my $hold = shift;
    
    if ($hold) {
       $self->oim_set_activity("HOLD");    # 0 == hold
    } else {
       $self->oim_set_activity("RTOS");    # 1 == to set point
    };
}

sub _get_hold {
    my $self = shift;
    my $action = $self->oim_get_activity();

    if ( $action eq "RTOS" ) { return 1; }
    if ( $action eq "HOLD" ) { return 0; }
    die "Unknown magnet action $action\n";
}

sub _set_sweep_target_current {
    my $self    = shift;
    my $current = shift;
    $self->oim_set_setpoint($current);
}






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::OI_Mercury - Oxford Instruments Mercury Cryocontrol (level meter and magnet power supply)

=head1 VERSION

version 3.600

=head1 SYNOPSIS

    use Lab::Instrument::OI_Mercury;
    
    my $m=new Lab::Instrument::OI_Mercury(
      connection_type=>'Socket', 
      remote_port=>7020, 
      remote_addr=>1.2.3.4,
    );

=head1 DESCRIPTION

The Lab::Instrument::OI_Mercury class implements an interface to the Oxford Instruments 
Mercury cryostat control system.

=head1 METHODS

=head2 get_he_level

   $he=$m->get_he_level('DB5.L1');

Read out the designated liquid helium level meter channel. Result is in percent as calibrated.

=head2 get_temperature

   $t=$m->get_temperature('MB1.T1');

Read out the designated temperature channel. Result is in Kelvin.

=head2 get_catalogue

   $mcat=$m->get_catalogue();
   print "$mcat\n";

Returns the hardware configuration of the Mercury system. A typical response would be

   STAT:SYS:CAT:DEV:GRPX:PSU:DEV:MB1.T1:TEMP:DEV:GRPY:PSU:DEV:GRPZ:PSU:DEV:PSU.M1:PSU:DEV:PSU.M2:PSU:DEV:GRPN:PSU:DEV:DB5.L1:LVL

Here, each group starting with "DEV:" describes one hardware component.
In this case, we obtain for example:

   DEV:GRPX:PSU     |
   DEV:GRPY:PSU     |- a 3-axis magnet power supply unit
   DEV:GRPZ:PSU     |
   DEV:MB1.T1:TEMP  -- a temperature sensor
   DEV:DB5.L1:LVL   -- a cryogen level sensor

In each of these blocks, the second component after "DEV:" is the UID of the device;
it can be used in other commands such as get_level to address it.

=head2 oim_get_current

Reads out the momentary current of the PSU in Ampere. Only Z for now. 

TODO: what happens if we're in persistent mode?

=head2 oim_get_heater

Returns the persistent mode switch heater status as "ON" or "OFF". 

=head2 oim_set_heater

Switches the persistent mode switch heater. Parameter is "ON" or "OFF". 
Nothing happens if the power supply thinks the magnet current and the lead current
are different.

=head2 oim_force_heater

Switches the persistent mode switch heater. Parameter is "ON" or "OFF". 

Dangerous. Works also if magnet and lead current are differing.

=head2 oim_get_sweeprate

Gets the current target sweep rate (i.e., the sweep rate with which we want to 
go to the target; may be bigger than the actual rate if it is hardware limited), 
in Ampere per minute.

=head2 oim_set_sweeprate

Sets the desired target sweep rate, parameter is in Amperes per minute.

=head2 oim_set_activity

Sets the current activity of the power supply. Values are: 

  HOLD - hold current
  RTOS - ramp to set point
  RTOZ - ramp to zero
  CLMP - clamp output if current is zero

=head2 oim_get_activity

Retrieves the current power supply activity. See oim_set_activity for values.

=head2 oim_set_setpoint

Sets the current set point in Ampere.

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the Lab::Measurement team; in detail:

  Copyright 2013       Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
