#######################################
# Module  : Tissue.pm
# Author  : Jaap Voets
# Date    : 04-05-2006 
# $Revision$
#######################################
package Deco::Tissue;

use strict;
use warnings;
use Carp;
use POSIX qw( pow );
our $VERSION = '0.5';

# water vapor at 37 degrees celsius (i.e. our lungs)
use constant WATER_VAPOR_PRESSURE => 0.0627; 

# carbon dioxide pressure for normal persons
use constant CO2_PRESSURE => 0.0534;

# properties of the object that can be set by the user
our @PROPERTIES = ('halftime','m0', 'deltam', 'o2fraction', 'waterfactor','topsidepressure','offgasfactor','RQ', 'nr');

# supported GASES, with fractions in breathing mix
our %GASES = ( 'o2' => 0.21,
	       'n2' => 0.78,
	       'he' => 0);

# Constructor
sub new {
    my $class = shift;
    my %args  = @_;

    my $self = {};

    # defaults
    # O2 fraction
    $self->{o2}->{fraction} = 0.21;
    
    # N2 fraction
    $self->{n2}->{fraction} = 0.78;
    
    # pressure at start of dive, normally 1 bar sea level
    $self->{topsidepressure} = 1; #bar
  	
    # specific weight for the type of water, fresh = 1.000, salt = 1.030
    $self->{waterfactor} = 1.000;

    # offgassing might be slower than ongassing
    $self->{offgasfactor} = 1;
    
    # respiratory quotient RQ. This is the amount of CO2 produced per O2
    # schreiner uses 0.8 (more conservative), US Navy 0.9 , Buhlmann 1.0
    $self->{RQ} = 0.8;
    
    $self->{nr} = 0;
    
    # we need a few things for a valid tissue
    # half time (in minutes)
    # M0 and deltaM value (in bar)
    foreach my $arg (keys %args) {
	if ( grep {/$arg/i} @PROPERTIES) {
	    $self->{ lc($arg) } = $args{ $arg };
	} else {
	    carp "Argument $arg is not valid";
	}
    }
    
    bless $self, $class;


    # additional properties, these are for finetuning
    
    # current internal pressure for N2, assumes equilibrium at current level (sea or higher)
    $self->{n2}->{pressure} = $self->_alveolarPressure( depth=>0 , gas=>'n2');

    # defaults to sea level in bar
    $self->{ambientpressure} = $self->{topsidepressure};

    # current depth in meters
    $self->{depth} = 0;

    # previous depth
    $self->{previousdepth} = 0;

    # some timestamps in seconds
    $self->{time}->{current}  = 0;
    $self->{time}->{previous} = 0;
    $self->{time}->{lastdepthchange} = 0;

    # oxygen exposure tracking through OTU's
    $self->{otu}   = 0;

    # haldane formula for current parameters, returns a ref to a sub
    $self->{haldane} = $self->_haldanePressure();

    return $self;
}

# get the tissue nr
sub nr {
    my $self = shift;
    croak "Tissue numbers not set yet" unless ($self->{nr});
    return $self->{nr};
}

# return the current internal for requested gas pressure
sub internalpressure {
    my $self = shift;
    my %opt  = @_;
    my $gas  = lc($opt{gas}) || 'n2';
    croak "Asking for unsupported gas $gas" unless exists $GASES{$gas};
    return $self->{$gas}->{pressure};
}

# percentage of tissue pressure compared to allowed M0
sub percentage {
    my $self = shift;
    my %opt  = @_;
    my $gas  = lc($opt{gas}) || 'n2';
    return ( 100 * $self->internalpressure( gas => $gas) / $self->{m0}) ;
}

# return the current OTU (Oxygen Toxicity Unit)
sub otu {
    my $self = shift;
    return $self->{otu};
}

# calculate otu's, should be called after changing depth/time
# if pO2 > 0.5 then OTU = minutes x ( ( pO2 -0.5 ) / 0.5) ^ 0.83
sub calculate_otu {
    my $self = shift;
    my $minutes = ($self->{time}->{current} - $self->{time}->{previous} ) / 60;
    my $otu = 0;
    my $pO2 = $self->ambientpressure() * $self->{o2}->{fraction};
    if ($pO2 > 0.5) {
	$otu = $minutes * POSIX::pow( 2 * $pO2 - 1,  0.83);
    }
    $self->{otu} += $otu;
    return $self->{otu};
}

# set time, depth combination
# this way we control the order of time/depth changes
# during descent, we want to change depth first, the time
# during ascent we want to change the time first then the depth
# this way we calculate the 'outer' profile in rectangles of the real profile
# and thus we are more conservative
sub point {
    my $self = shift;
    my ($time, $depth) = @_;

    if ( $depth > $self->{previousdepth} ) {
	# descending, so depth first 
	$self->depth( $depth );
	$self->time( $time );

    } elsif ( $depth < $self->{previousdepth} ) {
	# ascending, so time first
	$self->time( $time );
	$self->depth( $depth );
    } else {
	# same depth, only time change
	$self->time( $time );
    }

    return 1;
}

# set gas fractions
sub gas {
    my $self = shift;
    my %gaslist = @_;
    foreach my $keygas (keys %gaslist) {
	my $gas = lc($keygas);
	if (! exists $GASES{$gas} ) {
	    croak "Can't use gas $gas";
	}
	my $fraction = $gaslist{$keygas};
	# if using percentage, convert to fractions
	if ($fraction > 1) {
	    $fraction = $fraction / 100;
	}

	$self->{$gas}->{fraction} = $fraction;
    }
    return 1;
}

# set new depth point
sub depth {
    my $self = shift;
    my $depth = shift;
    
    croak "Depth can not be negative" unless($depth >= 0);

    if ($depth != $self->{depth} ) {
	$self->{previousdepth} = $self->{depth};
        $self->{depth}         = $depth;
	
	# remember this depthchange on the time scale
	$self->{time}->{lastdepthchange} = $self->{time}->{current};
	#print "Time of last depth change is: " . $self->{time}->{lastdepthchange} ."\n";

	# when depth changes we need to recalculate the Haldane formula
	$self->{haldane} = $self->_haldanePressure();
    }

    return $self->{depth};
}

# set new timestamp in seconds

sub time {
    my $self = shift;
    my $time = shift;
    
    croak "Time can not be negative" unless($time >= 0);
    if ($time != $self->{time}->{current} ) {
	$self->{time}->{previous} = $self->{time}->{current};
	$self->{time}->{current}  = $time;
	
	# when time changes, we need to recalculate the internal pressure
	my $minutes = ($time - $self->{time}->{lastdepthchange}) / 60;
	#print "Minutes passed since last depth change: $minutes\n";
	$self->{n2}->{pressure} = &{ $self->{haldane} }( $minutes );
	#print "So internal N2 is now: " . $self->{n2}->{pressure} . "\n";
    }

    return $self->{time}->{current};
}


# set or get halftime
sub halftime {
    my $self = shift;
    my $newvalue = shift;
    
    if ($newvalue) {
	croak "Halftimes need to be entered in positives minutes" unless($newvalue >= 1);
	$self->{halftime} = $newvalue;
    }
    
    return $self->{halftime};
}

# set or get Respiratory Quotient (RQ)
sub rq {
    my $self = shift;
    my $newvalue = shift;
    
    if ($newvalue) {
	croak "RQ (Respiratory Quotient) needs to be entered in the range 0.7 - 1.1" unless($newvalue >= 0.7 and $newvalue <= 1.1);
	$self->{RQ} = $newvalue;
    }
    
    return $self->{RQ};
}

# get the K value = ln(2) / halftime
sub k {
    my $self = shift;
    return log(2) / $self->{halftime};	
}

# give ambient total pressure
sub ambientpressure {
    my $self = shift;
    my $depth = shift;

    $depth = $self->{depth} unless defined $depth;

    my $press = $self->{topsidepressure} + $self->_depth2pressure( $depth );
    $self->{ambientpressure} = $press;

    return $press;
}

# print info about tissue
sub info {
	my $self = shift;
	my $gaslist = '';
	foreach my $gas (keys %GASES) {
	    my $fraction = $self->{$gas}->{fraction} || 0;
	    $gaslist .= " $gas at " . sprintf("%.1f", 100 * $fraction) . "%  "; 
	}
	
	my $info = "============================================================
=   TISSUE INFO
=
= Halftime (min)     : " . $self->{halftime} ."
= k  (min^-1)        : " . $self->k ."
= RQ                 : " . $self->{RQ} ."
= M0 (bar)           : " . $self->{m0} ."
= delta M (bar/m)    : " . $self->{deltam} ."
= Ambient (bar)      : " . $self->ambientpressure() ."
= Depth (m)          : " . $self->{depth} ."
= Total time (s)     : " . $self->{time}->{current} ."
= Tissue N2 (bar)    : " . $self->{n2}->{pressure} . "
= Alveo. N2 (bar)    : " . $self->_alveolarPressure( gas => 'n2', depth => $self->{depth} ) ."
= M (bar)            : " . $self->M( depth => $self->{depth}) ."
= Safe depth (m)     : " . $self->safe_depth( gas => 'n2') ."
= No deco time (min) : " . $self->nodeco_time( gas => 'n2') ."
= OTU's              : " . $self->{otu} ."
= Gas list           : $gaslist  
===========================================================\n";

	return $info;
}

# get the current M-values
sub M {
    my $self = shift;
    my %opt = @_;
   
    my $depth = $opt{depth} || $self->{depth};  # meters
    my $M = $self->{m0} + $self->{deltam} * $depth / ( 10 * $self->{waterfactor} );  # bar
    $self->{M} = $M;
    return $M;
}

# calculate the minimal depth to which we can safely ascend
# without exceeding the M0 value for the tissue

sub safe_depth {
	my $self = shift;
	my %opt  = @_;
	
	my $gas = lc($opt{gas}) || 'n2';	
	croak "The Delta M value has not been set for this tissue" unless ($self->{deltam} > 0);
	my $safe_depth = ( $self->{$gas}->{pressure} - $self->{m0} ) / $self->{deltam};
	
	# negative values mean we can go to the surface
	if ($safe_depth < 0 ) {
		$safe_depth = 0;
	}
	
	return $safe_depth;
}

# calculate how long this tissue is allowed to stay at the current depth
# without getting into Deco
# note: time is returned in minutes
sub nodeco_time {
    my $self = shift;
    my %opt = @_;

    my $gas = lc($opt{gas}) || 'n2';

    # shortcut: take P_no_deco to be M0 (instant go to surface)
    # unless a specific pressure was specified (for time_until function)
    my $p_end = $self->{m0};
    my $time = $self->time_until_pressure( pressure => $p_end, gas => $gas );
    
    return $time;

}

# calculate how many minutes this tissue
# can stay at the present depth until the
# given pressure (in bar) will be reached
#  
# a special case of this function is d
# this is practically the same as the no_deco_time function
# but there we take some surfacing pressure 
sub time_until_pressure {
    my $self = shift;
    my %opt = @_;
    
    my $gas = lc($opt{gas}) || 'n2';
    my $pressure = $opt{pressure};
	
    # alveolar pressure
    my $p_alv = $self->_alveolarPressure( gas => $gas , depth => $self->{depth} );
	
    my $k = $self->k();
    my $time_until = '-';
    
    my $depth = $self->{'depth'};
    my $current_pressure = $self->{$gas}->{pressure};
    
    if ($current_pressure >= $pressure) {
		# already at or over the wanted pressure
		$time_until = 0;
    } else {
		my $denominator = $current_pressure - $p_alv;
	    
		if ( $denominator ) {
			my $nominator = $pressure - $p_alv;
			my $fraction = $nominator / $denominator;
	
			if ($fraction > 0 ) {
			    $time_until = -1 / $k * log( $fraction );
			    # round it to whole minutes
			    $time_until = sprintf('%.0f', $time_until);
			}
	    } 
	}
    
    return $time_until;
}


##########################################
# PRIVATE FUNCTIONS
##########################################

# convert meters to bar
# this does NOT include the starting pressure
# so 0 meters = 0 bar water pressure
sub _depth2pressure {
    my $self = shift;
    my $depth = shift;
    my $press =  $depth  * $self->{waterfactor} / 10;
    return $press;
}

# use haldanian formula to solve the current pressure in tissue
# as long as the depth remains constant, this formula is still valid
sub _haldanePressure {
    my $self = shift;
    my $gas  = lc(shift) || 'n2';
    croak "Asking for unsupported gas $gas" unless exists $GASES{$gas};

    # we need the current tissure pressure, at t=0 for the depth
    my $tissue_press0 = $self->{$gas}->{pressure};
    #print "recalculating haldane formula. tissue pressure at t0 = $tissue_press0\n";

    # and the alveolar pressure
    my $alveolar = $self->_alveolarPressure( depth => $self->{depth} );

    # the time in minutes we have been at this depth, note that internal times are in seconds!
    return sub {
		my $t = shift;
		$alveolar + ($tissue_press0 - $alveolar ) * exp( -1 * $self->k() * $t );
    }
	
}

# return alvealor pressure for N2 (or other inert gas specified)
# see the Deco.pdf document for explanation on this calculation
sub _alveolarPressure {
    my $self = shift;
    my %opt  = @_;

    my $depth = $opt{depth} || 0;
    my $gas  = lc($opt{gas}) || 'n2';
    croak "Asking for unsupported gas $gas" unless exists $GASES{$gas};
    
    my $press = $self->{$gas}->{fraction} * ( $self->ambientpressure( $depth ) - WATER_VAPOR_PRESSURE +  ( ( 1 - $self->{RQ} ) / $self->{RQ} ) * CO2_PRESSURE );
    return $press;	
}


1;
__END__

=head1 NAME

Tissue - Models a Tissue for decompression calculations

=head1 SYNOPSIS

  use Deco::Tissue;
my $tissue = new Deco::Tissue( halftime => 5, m0 => 1.52);

=head1 DESCRIPTION

This module can be used to mimick the behaviour of a theoretical body tissue when Scuba Diving with air or nitrox. It will model a hypothetical body tissue in a Haldanian fashion. The 2 parameters that determine the tissue behaviour are the B<halftime> T (in minutes) and the surfacing maximum Tissue tension M0 ( in bar ).

=head2 METHODS

=over 4

=item new( halftime => 10, m0 => 1.234, .... )

Constructor of the class. You can create a tissue with specific parameters
Allowed parameters are:
halftime
m0
deltam
o2fraction
waterfactor
topsidepressure
offgasfactor
RQ
nr

=item $tissue->info()

Returns a string with information about initial settings and current state of the tissue

=item $tissue->rq();

=item $tissue->nodeco_time( gas => 'n2' );

Calculates the time left in minutes before a tissue has reached the critical surface tension. 
In that case you can no longer return directly to the surface but will need to stop at a certain depth first.
 
=item $tissue->safe_depth( gas => 'n2' );

Returns the safe depth in meters to which you can ascend without exceeding one of the critical tissue tensions.
These values are positive or 0. A value of 0 means you can surface without having any deco stops.

 
=item $tissue->M( depth => $depth );

Get the M-value for the specified depth. The M-value for sea-level is the famous M0. At depth you are allowed to
have a greater tissue tension, which scales linearly with the depth.

 
=item $tissue->k( );

Returns the k-parameter (kind of the reverse of the tissue halftime)

=item $tissue->nr();

Returns the tissue number as found in the config file for this model.

=item $tissue->halftime();

Returns the halftime (in minutes) of the tissue.

=item $tissue->otu;

Returns the Oxygen Toxicity Units acquired during the dive sofar.

=item $tissue->calculate_otu;

Update the OTU value. You have to call this function after every time / depth change. It will add the found value to the internal otu counter and return the total value.

=item $tissue->gas(  'n2' => 34, '02' => 0.66 );

Set the fractions or percentages of the gases used. Supported gases  are 'n2', 'o2' and 'he'. You can either enter percentages or fractions. Note that you are responsible for adding up the gases correctly to 100%.

=item $tissue->ambientpressure( $depth );

Returns the ambientpressure (in Bar) for the given depth (in meters). In case a depth is not supplied, the last internal depth stored into the tissue object will be used.

=item $tissue->internalpressure( gas => 'n2' );

Returns the internal pressure (in Bar) of the given gas. Of the gas is omitted, nitrogen (N2) will be used.

=item $tissue->percentage( gas => 'n2' );

Returns the percentage of tissue saturation for the given gas (N2 is default when gas parameter is omitted).
This percentage is the pressure of the gas compared to the allowed M0 surfacing tension.

=item $tissue->point( $time, $depth);

Set a time (in seconds) , depth (in meters) combination for the tissue. Used when entering a dive profile.
This routine will call the time() and depth() functions. You can call those individually as well, but the point() function
makes sure that these functions are called in the right order, so that the most conservative calculation will be performed internally.

=item $tissue->time( $seconds )

Set the time of the the tissue. That is, the dive starts at 0 seconds, and you want to know how much nitrogen the tissue contains after 10 minutes at 20 meters, then you would call $tissue->depth(20) and $tissue->time( 600 );

=item $tissue->time_until_pressure( gas => 'N2', pressure => 1.34);

Calculates the time in minutes until the provided pressure in bar is reached for the provided gas.
This function is very similar to the nodeco_time function (in fact it uses that one), but instead of the maximum
allowed pressure used to calculate the no-deco time, you can provide your own pressure.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Deco>, L<Deco::Dive>, L<Deco::Dive::Plot>. L<SCUBA::Table::NoDeco> might be of interest to you as well.

In the docs directory you will find an extensive treatment of decompression theory in the file Deco.pdf. A lot of it has been copied from the www.deepocean.net website.

=head1 AUTHOR

Jaap Voets, E<lt>narked@xperience-automatisering.nlE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jaap Voets

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
