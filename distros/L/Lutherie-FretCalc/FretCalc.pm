# Copyright (c) 2001 Douglas Sparling. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

package Lutherie::FretCalc;

use strict;
use vars qw($VERSION);

$VERSION = '0.33';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    if (defined $_[0]) {
        $self->{scale} = $_[0];
    } else {
        $self->{scale} = 25;
    }
    if (defined $_[1]) {
        $self->{num_frets} = $_[1];
    } else {
        $self->{num_frets} = 24;
    }
    #$self->{num_frets}  = 24;
    $self->{fret_num}    = 12;
    $self->{in_units}    = 'in';
    $self->{out_units}   = 'in';
    $self->{calc_method} = 't';
    $self->{tet}         = 12;
    $self->{precision}   = 4; # Precision for 'in'
    #$self->{half_fret}   = ();

    bless($self, $class);
    return $self;
}

sub scale {
    my($self) = shift;
    if(@_) { $self->{scale} = shift }
    return $self->{scale};
}

sub num_frets {
    my($self) = shift;
    if(@_) { $self->{num_frets} = shift }
    return $self->{num_frets};
}

sub fret_num {
    my($self) = shift;
    if(@_) { $self->{fret_num} = shift }
    return $self->{fret_num};
}

sub in_units {
    my($self) = shift;
    if(@_) { $self->{in_units} = shift }
    return $self->{in_units};
}

sub out_units {
    my($self) = shift;
    if(@_) { 
        my $out_units = shift;
        # Set precision defaults
        if( $out_units eq 'in' ) {
            $self->{precision} = 4;
        } else {
            $self->{precision} = 1;
        }
        $self->{out_units} = $out_units; 
    }
    return $self->{out_units};
}

sub calc_method {
    my($self) = shift;
    if(@_) { $self->{calc_method} = shift }
    return $self->{calc_method};
}

sub tet {
    my($self) = shift;
    if(@_) { $self->{tet} = shift }
    return $self->{tet};
}

sub precision {
    my($self) = shift;
    if(@_) { 
        my $prec = shift;
        $prec = 4 if $prec < 0 or $prec > 6;
        $self->{precision} = $prec; 
    }
    return $self->{precision};
}

sub half_fret {
    my($self) = shift;
    #if(@_) { $self->{half_fret} = shift }
    if(@_) { 
        if($self->{half_fret}) {
            $self->{half_fret} = join(',', $self->{half_fret},shift);
        } else {
            $self->{half_fret} = shift;
        }
    }
    return $self->{half_fret};
}


sub fretcalc {

    my($self) = shift;

    if(@_) { $self->{num_frets} = shift }

    my $distance_from_nut = 0;
    my $distance_from_nut_formatted;

    my @chart = ();
    # Set precision
    my $prec;
    $prec = '%8.0f' if $self->{precision} == 0;
    $prec = '%8.1f' if $self->{precision} == 1;
    $prec = '%8.2f' if $self->{precision} == 2;
    $prec = '%8.3f' if $self->{precision} == 3;
    $prec = '%8.4f' if $self->{precision} == 4;
    $prec = '%8.5f' if $self->{precision} == 5;
    $prec = '%8.6f' if $self->{precision} == 6;
    $chart[0] = sprintf("$prec",0);

    for my $i (1..$self->{num_frets}) {
        if ($self->{calc_method} eq 't') {
            $distance_from_nut = ($self->{scale} - $self->{scale}/2 ** ($i/$self->{tet}));
        } elsif ($self->{calc_method} eq 'ec') {
            my $x = ($self->{scale} - $distance_from_nut) / 17.817;
            $distance_from_nut += $x;
        } elsif ($self->{calc_method} eq 'es') {
            my $x = ($self->{scale} - $distance_from_nut) / 17.835;
            $distance_from_nut += $x;
        } elsif ($self->{calc_method} eq 'ep') {
            my $x = ($self->{scale} - $distance_from_nut) / 18;
            $distance_from_nut += $x;
        } else {
            $distance_from_nut = ($self->{scale} - $self->{scale}/2 ** ($i/12));
        }

        ### input scale: in, output scale: in
        if( ($self->{in_units} eq 'in') && ($self->{out_units} eq 'in') ) {
            $distance_from_nut_formatted = sprintf("$prec",$distance_from_nut);
        ### input scale: in, output scale: mm
        } elsif( ($self->{in_units} eq 'in') && ($self->{out_units} eq 'mm') ) {
            $distance_from_nut *= 25.4;
            $distance_from_nut_formatted = sprintf("$prec",$distance_from_nut);
        ### input scale: mm, output scale: in
        } elsif( ($self->{in_units} eq 'mm') && ($self->{out_units} eq 'in') ) {
            $distance_from_nut /=  25.4;
            $distance_from_nut_formatted = sprintf("$prec",$distance_from_nut);
        #### input scale: mm, out_units: mm
        } else {
            $distance_from_nut_formatted = sprintf("$prec",$distance_from_nut);
        }
        push @chart, $distance_from_nut_formatted;
    }

    return @chart;

}

sub fret {

    my $self = shift;

    # Check if fret_num was passed
    if(@_) { $self->{fret_num} = shift }

    # Set precision
    my $prec;
    $prec = '%8.0f' if $self->{precision} == 0;
    $prec = '%8.1f' if $self->{precision} == 1;
    $prec = '%8.2f' if $self->{precision} == 2;
    $prec = '%8.3f' if $self->{precision} == 3;
    $prec = '%8.4f' if $self->{precision} == 4;
    $prec = '%8.5f' if $self->{precision} == 5;
    $prec = '%8.6f' if $self->{precision} == 6;

    my $distance_from_nut = 0;
    my $distance_from_nut_formatted;
    if ($self->{calc_method} eq 't') {
        $distance_from_nut = ($self->{scale} - $self->{scale}/2 ** ($self->{fret_num}/$self->{tet}));
    } elsif ($self->{calc_method} eq 'ec') {
        for my $i (1..$self->{fret_num}) {
            my $x = ($self->{scale} - $distance_from_nut) / 17.817;
            $distance_from_nut += $x;
        }
    } elsif ($self->{calc_method} eq 'es') {
        for my $i (1..$self->{fret_num}) {
            my $x = ($self->{scale} - $distance_from_nut) / 17.835;
            $distance_from_nut += $x;
        }
    } elsif ($self->{calc_method} eq 'ep') {
        for my $i (1..$self->{fret_num}) {
            my $x = ($self->{scale} - $distance_from_nut) / 18;
            $distance_from_nut += $x;
        }
    } else {
        $distance_from_nut = ($self->{scale} - $self->{scale}/2 ** ($self->{fret_num}/$self->{tet}));
    }

    ### in_units: in, out_units: in
    if( ($self->{in_units} eq 'in') && ($self->{out_units} eq 'in') ) {
        $distance_from_nut_formatted = sprintf("$prec",$distance_from_nut);
    ### in_units: in, out_units: mm
    } elsif( ($self->{in_units} eq 'in') && ($self->{out_units} eq 'mm') ) { 
        $distance_from_nut *= 25.4;
        $distance_from_nut_formatted = sprintf("$prec",$distance_from_nut);
    ### in_units: mm, out_units: in
    } elsif( ($self->{in_units} eq 'mm') && ($self->{out_units} eq 'in') ) {
        $distance_from_nut /= 25.4;
        $distance_from_nut_formatted = sprintf("$prec",$distance_from_nut);
    ### in_units: mm, out_units: mm
    } else {
        $distance_from_nut_formatted = sprintf("$prec",$distance_from_nut);
    }
    return $distance_from_nut_formatted;

}

sub dulc_calc {
    my($self) = shift;
    my %dulc;
    my @frets = $self->fretcalc(24); # Use 24 frets for dulcimer

    # Set standard frets
    $dulc{1} = $frets[2];
    $dulc{2} = $frets[4];
    $dulc{3} = $frets[5];
    $dulc{4} = $frets[7];
    $dulc{5} = $frets[9];
    $dulc{6} = $frets[10];
    $dulc{7} = $frets[12];

    $dulc{8} = $frets[14];
    $dulc{9} = $frets[16];
    $dulc{10} = $frets[17];
    $dulc{11} = $frets[19];
    $dulc{12} = $frets[21];
    $dulc{13} = $frets[22];
    $dulc{14} = $frets[24];

    # Add the half frets (valid = 1,6,8,13)
    my @half_frets = split(/,/,$self->{half_fret});
    foreach my $half( @half_frets ) {
        if( $half == 1 ) {
            $dulc{1.5} = $frets[3];
        } elsif( $half == 6 ) {
            $dulc{6.5} = $frets[11];
        } elsif( $half == 8 ) {
            $dulc{8.5} = $frets[15];
        } elsif( $half == 13 ) {
            $dulc{13.5} = $frets[23];
        }
    }

    return %dulc;

}


1;

__END__

=head1 NAME

Lutherie::FretCalc - Calculate stringed instrument fret locations

=head1 SYNOPSIS

  use Lutherie::FretCalc;

  my $fretcalc = Lutherie::FretCalc->new($scale_length);
  $fretcalc->in_units('in');
  $fretcalc->out_units('in');
  my $fret = $fretcalc->fret($fret_num);
  my @chart = $fretcalc->fretcalc($num_frets);
                       


=head1 DESCRIPTION

C<Lutherie::FretCalc> provides two methods for calculating fret spacing 
locations for stringed musical instruments. C<fret()> will find the distance 
from the nut for a given fret number. C<fretcalc()> will generate an array 
containing the fret locations for the given number of frets.

=head1 OVERVIEW

=over 4

=item TODO

=back

=head1 CONSTRUCTOR

=over 4

=item new ( [SCALE_LENGTH[, NUM_FRETS]] );

This is the constructor for a new Lutherie::FretCalc object. C<SCALE_LENGTH>
is the numeric value for the scale length to be used for the calculation.
The default value for scale length is 25.
C<NUM_FRETS> is the number of frets to be calculated.
The default value is 24.
The unit can be set with the C<in_units()> and C<out_units()> methods. 
The default is 'in' (inches).

=back

=head1 METHODS

=over 4

=item scale ( [ SCALE_LENGTH ] )

If C<SCALE_LENGTH> is passed, this method will set the scale length. 
The default value is 25. The scale length is returned. 

=item num_frets ( [ NUM_FRETS ] )

If C<NUM_FRETS> is passed, this method will set the number of frets.  
The default value is 24. The number of frets is returned.

=item fret_num ( [ FRET_NUM ] )

If C<FRET_NUM> is passed, this method will set the fret number.
The default value is 12. The fret number is returned.

=item in_units ( [ IN_UNITS ] )

If C<IN_UNITS> is passed, this method will set the in units.
The default is 'in' (inches). The in unit is returned.
'in' - Inches, 'mm' - Millimeters

=item out_units ( [ OUT_UNITS ] )

If C<OUT_UNITS> is passed, this method will set the out units.
The default is 'in' (inches). The out unit is returned.
'in' - Inches, 'mm' - Millimeters

=item calc_method ( [ CALC_METHOD ] )

If C<CALC_METHOD> is passed, this method will set the calc method.
The default is 't' (tempered). The calc method is returned.
't': tempered - power of $i/$tet (default),
'ec': classic - 17.817,
'es': Sloane - 17.835,
'ep': Primative - 18

=item tet ( [ TET ] )

If C<TET> is passed, this method will set the tones per octave.
The default is 12. The number of tones per ocatave is returned.
This value is only valid when using calc_method = 't'.

=item precision ( [ PRECISION ] )

If C<PRECISION> is passed, this method will set the precision of
the displayed calculations. The default is 4 for 'in' and
1 for 'mm'. The precision is returned.
0: "%8.0f" 
1: "%8.1f" 
2: "%8.2f" 
3: "%8.3f" 
4: "%8.4f" 
5: "%8.5f" 
6: "%8.6f" 

=item half_fret ( [ FRET_NUM ] )

If C<FRET_NUM> is passed, this method will calculate the half fret for this fret number. Valid values are 1, 6, 8 and 13. Only used with C<dulc_calc()>. A comma separated list of half frets is returned.

=item fret ( [ FRET_NUM ] )

Calculate the distance from the nut to the fret number. A scalar containing the fret location for C<FRET_NUM> is returned.

=item fretcalc ( [ NUM_FRETS ] )

Calculate fret locations for given scale length, number of frets, calc type
and tet. An ordered array containing fret locations from 1 to C<NUM_FRETS> is returned.

=item dulc_calc ( )

Calculate fret locations for mountain dulcimer. Number of frets is set at 14.
Half frets may be added by using C<half_fret> function. Valid half frets are 1+, 6+, 8+ and 13+. C<num_frets> will be ignored when using C<dulc_calc>. A hash containing fret locations from 1 to 14 is returned.

=back

=head1 AUTHOR

Douglas Sparling, doug@dougsparling.com

=head1 COPYRIGHT

Copyright (c) 2001-2002 Douglas Sparling. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut
