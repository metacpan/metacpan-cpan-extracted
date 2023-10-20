package Lab::Instrument::TCD;
#ABSTRACT: Temperature control for our Oxford Instruments TLM dilution fridge
$Lab::Instrument::TCD::VERSION = '3.899';
use v5.20;

use strict;
use Lab::Instrument;

our @ISA = ("Lab::Instrument");

our %fields = (
    supported_connections => [ 'VISA_RS232', 'RS232', 'IsoBus', 'DEBUG' ],

    connection_settings => {
        baudrate  => 9600,
        databits  => 8,
        stopbits  => 1,
        parity    => 'none',
        handshake => 'none',

        #rs232_echo => 'character',
        termchar => "\r",
        timeout  => 1
    },

    device_settings => { read_default => 'device' },

    device_cache => {
        id => 'Temperature Control',

        #T => undef
        }

);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    return $self;
}

sub get_value {
    my $self = shift;
    return $self->get_T(@_);
}

sub get_T {
    my $self = shift;
    my ($read_mode) = $self->_check_args( \@_, ['read_mode'] );
    my $temperature = "xxxxxxxx";

    if (   not defined $read_mode
        or not $read_mode =~ /device|cache|request|fetch/ ) {
        $read_mode = $self->device_settings()->{read_default};
    }

    if ( $read_mode eq 'cache' and defined $self->{'device_cache'}->{'T'} ) {
        return $self->{'device_cache'}->{'T'};
    }
    elsif ( $read_mode eq 'request' ) {
        if ( $self->{'request'} != 0 ) {
            eval "$self->read();";
        }
        while ( ( $self->write("getTemp\r\n") < 0 ) ) {

            #print "repeat sending\n";
        }
        $self->{'request'} = 1;
    }
    elsif ( $read_mode eq 'fetch' and $self->{'request'} == 1 ) {
        $self->{'request'} = 0;

        my $temperature;
        while (1) {
            eval '$temperature = $self->read()';
            if ($@) {
                next;
            }
            elsif ( $temperature < 0 or $temperature > 1.5 ) {

                #print "from cache";
                return $self->{'device_cache'}->{'T'};
            }
            else {
                chomp $temperature;
                $self->{'device_cache'}->{'T'} = $temperature;
                return $self->{'device_cache'}->{'T'};
            }
        }

    }

    else {
        for ( my $i = 0; $i < 3; $i++ ) {
            $self->write("getTemp\r\n");

            for ( my $j = 0; $j < 3; $j++ ) {
                eval '$temperature = $self->read()';
                if ($@) {
                    next;
                }
                elsif ( $temperature < 0 or $temperature > 1.5 ) {

                    #print "from cache";
                    return $self->{'device_cache'}->{'T'};
                }
                else {
                    chomp $temperature;
                    $self->{'device_cache'}->{'T'} = $temperature;
                    return $self->{'device_cache'}->{'T'};
                }
            }

        }

        return $self->{'device_cache'}->{'T'};
    }

}

sub set_T {
    my $self = shift;
    my ($temperature) = $self->_check_args( \@_, ['temperaure'] );

    my $temp = $self->query("setTemp\r\n$temperature\r\n");

    chomp $temp;

    #sleep(1);

    return $temp;
}

sub set_heateroff {
    my $self = shift;

    $self->write("heaterOff\r\n");

}

sub set_heatercontrol {
    my $self = shift;

    return;
}

# sub stabilize_T {
# 	my $self = shift;
# 	my $external_sensor = shift;

# 	my $T = $self->get_T();
# 	my $Idc = $external_sensor->get_value();

# 	push(@{$self->{data_buffer_T}}, $T);
# 	push(@{$self->{data_buffer_Idc}}, $Idc);

# 	@{$self->{data_buffer_T}}= sort(@{$self->{data_buffer_T}});
# 	@{$self->{data_buffer_Idc}} = sort(@{$self->{data_buffer_Idc}});

# 	my $length = @{$self->{data_buffer_T}};

# 	my $median_T = @{$self->{data_buffer_T}}[$length/2];
# 	my $median_Idc = @{$self->{data_buffer_Idc}}[$length/2];

# 	my $range_T = abs(@{$self->{data_buffer_T}}[-1]-@{$self->{data_buffer_T}}[0]);
# 	my $range_Idc = abs(@{$self->{data_buffer_Idc}}[-1]-@{$self->{data_buffer_Idc}}[0]);

# 	print "Legth of buffer = $length\n";
# 	print "Median T = $median_T\n";
# 	print "Range T = $range_T\n";
# 	print "Median Idc = $median_Idc\n";
# 	print "Range Idc = $range_Idc\n";
# 	print "\n";
# 	print "T = $T\n";
# 	print "Idc = $Idc\n";

# 	if ( $length > 30 )
# 		{
# 		#print abs($median_T - @{$self->{data_buffer_T}}[-1])." ?= ".(0.01*$range_T)."\n";
# 		if ( $range_T <= abs(0.05*$T) )
# 			{
# 			print "T stable\n";
# 			if ( $range_Idc <= abs(0.01*$Idc) )
# 				{
# 				print "Idc stable\n";
# 				return 0;
# 				}
# 			return 1;
# 			}

# 		shift @{$self->{data_buffer_T}};
# 		shift @{$self->{data_buffer_Idc}};
# 		}

# 	print "===============================\n\n\n";

# 	return 1;

# }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::TCD - Temperature control for our Oxford Instruments TLM dilution fridge (deprecated)

=head1 VERSION

version 3.899

=head1 SYNOPSIS

	use Lab::Instrument::RS232;
	my $rs232=new Lab::Instrument::RS232();

	use Lab::Instrument::TCD;
	my $tcd=new Lab::Instrument::TCD($rs232,$addr);

=head1 DESCRIPTION

This module belongs to a deprecated legacy module stack, frozen and not under development anymore. Please port your code to the new API; its documentation can be found on the Lab::Measurement homepage, L<https://www.labmeasurement.de/>.

The Lab::Instrument::ITC class implements an interface to our Oxford Dilution Fridge

=head1 CONSTRUCTOR

	my $tcd=new Lab::Instrument::TCD($rs232,$addr);

Instantiates a new object attached to the RS232 port.

=head1 METHODS

=head2 get_T

	$temperature=$tcd->get_T();

Returns the current temperature of the mixing chamber.

=head2 set_T

	$temperature=$tcd->set_T($temperature);

Set target value for the temperature control circuit.

=over 4

=item $temperature

TEMPERATURE can be between 0 ... 1 K.

=back

=head2 set_heateroff

	$temperature=$tcd->set_heateroff();

Switch OFF the heater for the mixing chamber

=head1 CAVEATS/BUGS

probably many

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2013       Christian Butschkow
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
