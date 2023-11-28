
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2015 Gerald Richter
#   Embperl - Copyright (c) 2015-2023 actevy.io
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id$
#
###################################################################################

package Embperl::Form::Control::price ;

use strict ;
use base 'Embperl::Form::Control::number' ;

use Embperl::Inline ;

use vars qw{%fdat} ;

# ---------------------------------------------------------------------------
#
#   init - init the new control
#

sub init

    {
    my ($self) = @_ ;

    $self -> {use_comma} = 1 if (!defined $self -> {use_comma}) ;
    $self -> {unit}      = 'euro' if (!defined ($self->{unit} ));
    $self -> {decimals}  = 2 if (!defined ($self->{decimals} ));
    
    return $self ;
    }

# ------------------------------------------------------------------------------------------
#
#   get_display_text - returns the text that should be displayed
#

sub get_display_text
    {
    my ($self, $req, $val, $compact) = @_ ;
    
    $val = $self -> get_value ($req) if (!defined ($val)) ;
    
    my $decimals = $self -> {decimals} ;
    my $sep ;
    my $dec ;
    my $int ;
    my @int ;
    my $frac ;
    my $minus = $val =~ s/^-// ;
    ($int, $frac) = split (/\./, $val, 2) ;
    if ($self -> {use_comma})
        {
        $sep = '.' ;
        $dec = ',' ;
        }
    else
        {
        $sep = ',' ;
        $dec = '.' ;
        }
    
    $int = '0' x ((3 - length($int)) % 3) . $int;

    while ($int =~ /(...)/g)
        {
        push @int, $1  ;
        }
    
    $int[0] =~ s/^0+// ;
    $int[0] = '0' if (@int == 1 && !$int[0]) ;
    $frac   = substr ($frac . '00000', 0, $decimals) ;
    my $result = ($minus?'-':'') . join ($sep, @int) . ( $decimals ? $dec . $frac : '') ;
    return $result if ($compact || $val eq '') ;
    
    my $unit = $self->{unit} ;
    my $unittext = !$unit?'':$self -> form -> convert_text ($self, ($unit =~ /:/)?$unit:'unit:' . lc($unit), $unit, $req) ;
    $unittext =~ s/^unit:// ;

    return $result . ' ' . $unittext ;        
    }
    
    


# ------------------------------------------------------------------------------------------
#
#   prepare_fdat - daten zusammenfuehren
#

sub prepare_fdat
    {
    my ($self, $req) = @_ ;

    my $fdat  = $req -> {form} || \%fdat ;
    my $name    = $self->{name} ;
    return if (!exists $fdat->{$name}) ;
    my $val     = $fdat->{$name} ;
    return if ($val eq '') ;
    
    $val =~ s/\s+//g ;
    if ($self -> {use_comma})
        {
        $val =~ s/\.//g ;
        $val =~ s/\,/./ ;
        }
        
    $fdat->{$name} = $val + 0 ;
    }
    
# ---------------------------------------------------------------------------
#
#   get_validate_auto_rules - get rules for validation, in case user did
#                             not specify any
#

sub get_validate_auto_rules
    {
    my ($self, $req) = @_ ;
    
    return [ $self -> {required}?(required => 1):(emptyok => 1), -type => 'Number' ] ;
    }

1 ;

__EMBPERL__


__END__

=pod

=encoding iso8859-1

=head1 NAME

Embperl::Form::Control::price - A price input control with optional unit inside an Embperl Form


=head1 SYNOPSIS

  {
  type => 'price',
  text => 'blabla',
  name => 'foo',
  unit => 'sec',
  }

=head1 DESCRIPTION

Used to create a price input control inside an Embperl Form.
Will format number as a money ammout.
Optionally it can display an unit after the input field.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'price'

=head3 name

Specifies the name of the control

=head3 text

Will be used as label for the numeric input control

=head3 size

Gives the size in characters. (Default: 10)

=head3 maxlength

Gives the maximun length in characters

=head3 unit

Gives a string that should be displayed right of the input field.

=head3 use_comma

If set the decimal character is comma instead of point (Default: on)

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


