package Lab::Instrument::OI_Mercury::Level;
#ABSTRACT: Oxford Instruments Mercury Cryocontrol level meter
$Lab::Instrument::OI_Mercury::Level::VERSION = '3.613';
use strict;
use Lab::Instrument;
use Lab::Instrument::MagnetSupply;

our @ISA = ('Lab::Instrument');

our %fields
    = (  supported_connections => [ 'IsoBus', 'Socket', 'GPIB', 'VISA' ], );

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


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::OI_Mercury::Level - Oxford Instruments Mercury Cryocontrol level meter

=head1 VERSION

version 3.613

=head1 SYNOPSIS

    use Lab::Instrument::OI_Mercury::Level;
    
    my $m=new Lab::Instrument::OI_Mercury::Level(
      connection_type=>'Socket', 
      remote_port=>7020, 
      remote_addr=>1.2.3.4,
    );

=head1 DESCRIPTION

The Lab::Instrument::OI_Mercury::Level class implements an interface to the Oxford 
Instruments Mercury cryostat control level meter.

The Mercury uses a command language that looks a bit like SCPI but is actually
incompatible with that specification.

=head1 METHODS

=head2 get_he_level

   $he=$m->get_he_level('DB5.L1');

Read out the designated liquid helium level meter channel. Result is in percent as calibrated.

=head2 get_he_level_resistance

   $he=$m->get_he_level_resistance('DB5.L1');

Read out the designated liquid helium level meter channel. Result is the raw sensor resistance.

=head2 get_n2_level

   $he=$m->get_n2_level('DB5.L1');

Read out the designated liquid nitrogen level meter channel. Result is in percent as calibrated.

=head2 get_n2_level_frequency

   $he=$m->get_n2_level_frequency('DB5.L1');

Read out the designated liquid nitrogen level meter channel. Result is the raw internal frequency value.

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

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the Lab::Measurement team; in detail:

  Copyright 2017       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
