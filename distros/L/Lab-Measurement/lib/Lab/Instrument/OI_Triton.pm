package Lab::Instrument::OI_Triton;
#ABSTRACT: Oxford Instruments Triton dilution refrigerator control
$Lab::Instrument::OI_Triton::VERSION = '3.881';
use v5.20;

use strict;
use Lab::Instrument;
use Carp;

our @ISA = ("Lab::Instrument");

our %fields = (
    supported_connections => [ 'Socket', 'VISA' ],

    # default settings for the supported connections
    connection_settings => {
        remote_port => 33576,
        remote_addr => 'triton',
    },
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    return $self;
}

sub get_temperature {
    my $self    = shift;
    my $channel = shift;
    $channel = "1" unless defined($channel);

    my $temp = $self->query("READ:DEV:T$channel:TEMP:SIG:TEMP\n");

    # typical response: STAT:DEV:T1:TEMP:SIG:TEMP:1.47628K

    $temp =~ s/^.*:SIG:TEMP://;
    $temp =~ s/K.*$//;
    return $temp;
}

sub enable_control {
    my $self = shift;
    my $temp = $self->query("SET:SYS:USER:NORM\n");

    # typical response: STAT:SET:SYS:USER:NORM:VALID
    return $temp;
}

sub disable_control {
    my $self = shift;
    my $temp = $self->query("SET:SYS:USER:GUEST\n");

    # typical response: STAT:SET:SYS:USER:GUEST:VALID
    return $temp;
}

sub enable_temp_pid {
    my $self = shift;
    my $temp = $self->query("SET:DEV:T5:TEMP:LOOP:MODE:ON\n");

    # typical response: STAT:SET:DEV:T5:TEMP:LOOP:MODE:ON:VALID
    return $temp;
}

sub disable_temp_pid {
    my $self = shift;
    my $temp = $self->query("SET:DEV:T5:TEMP:LOOP:MODE:OFF\n");

    # typical response: STAT:SET:DEV:T5:TEMP:LOOP:MODE:OFF:VALID
    return $temp;
}

sub get_T {
    my $self = shift;
    my $temp = $self->get_temperature("5");
    return $temp;
}

sub waitfor_T {
    my $self   = shift;
    my $target = shift;
    my $now    = 10000000;

    do {
        sleep(10);
        $now = get_T();
        print "Waiting for T=$target ; current temperature is T=$now\n";
    } unless ( abs( $now - $target ) / $target < 0.05 );
}

sub set_T {
    my $self        = shift;
    my $temp = shift;
    
    if ( $temp > 0.7 ) { croak "OI_Triton::set_T: setting temperatures above 0.7K is forbidden\n"; };
    
    if ( $temp < 0.035 ) {
      $self->set_Imax(0.000316);
    } elsif ( $temp < 0.07 ) {
      $self->set_Imax(0.001);
    } elsif ( $temp < 0.35 ) {
      $self->set_Imax(0.00316); 
    } else {
      $self->set_Imax(0.01);
    };
    
    my $temp = $self->query("SET:DEV:T5:TEMP:LOOP:TSET:$temp\n");
    # typical reply: STAT:SET:DEV:T5:TEMP:LOOP:TSET:0.1:VALID
    
    $self->enable_temp_pid();

    my $temp = $self->query("SET:DEV:T5:TEMP:LOOP:TSET:$temp\n");
    # typical reply: STAT:SET:DEV:T5:TEMP:LOOP:TSET:0.1:VALID
}

sub set_Imax {
    my $self = shift;
    my $imax = shift;  # in Ampere
    
    if ($imax > 0.0101) { croak "OI_Triton::set_Imax: Setting too large heater current limit\n"; };
    
    $imax=$imax*1000; # in mA
    
    return $self->query("SET:DEV:T5:TEMP:LOOP:RANGE:$imax\n");
};


sub get_P {
    my $self = shift;
    my $power = $self->query("READ:DEV:H1:HTR:SIG:POWR\n");
    
    $power =~ s/^.*SIG:POWR://;
    $power =~ s/uW$//;
    return $power;
}

sub set_P {
    my $self = shift;
    my $power = shift;
    
    return $self->query("SET:DEV:H1:HTR:SIG:POWR:$power\n");
}



# now follows the temperature sweep interface for XPRESS

sub set_heatercontrol {
    my $self = shift;

    my $mode = shift;
    # assumption: MAN=no control loop, AUTO=internal PID loop
    
    if ( $mode eq 'AUTO' ) {
        $self->enable_temp_pid();
    } else {
        $self->disable_temp_pid();
    };
    
    return;
}

sub set_heateroutput {
    my $self = shift;

    $self->disable_temp_pid();
    $self->set_P(0);
    
    return;
}

sub get_value {
    my $self = shift;
    return $self->get_T(@_);
}




# requires set_T


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Lab::Instrument::OI_Triton - Oxford Instruments Triton dilution refrigerator control

=head1 VERSION

version 3.881

=head1 SYNOPSIS

    use Lab::Instrument::OI_Triton;
    
    my $m=new Lab::Instrument::OI_Triton(
      connection_type=>'Socket', 
      remote_port=>33576, 
      remote_addr=>'triton',
    );

=head1 DESCRIPTION

The Lab::Instrument::OI_Triton class implements an interface to the Oxford Instruments 
Triton dilution refrigerator control system.

=head1 METHODS

=head2 get_temperature

   $t=$m->get_temperature('1');

Read out the designated temperature channel. Result is in Kelvin (?).

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2014       
            2015       Andreas K. Huettel
            2016       Andreas K. Huettel, Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
