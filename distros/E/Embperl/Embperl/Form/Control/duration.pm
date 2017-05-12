
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
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

package Embperl::Form::Control::duration ;

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

    $self->{unit}      ||= '' ;
    
    return $self ;
    }
    
# ------------------------------------------------------------------------------------------
#
#   init_data - daten aufteilen
#

sub init_data
    {
    my ($self, $req, $parentctrl) = @_ ;
    
    my $fdat  = $req -> {docdata} || \%fdat ;
    my $name    = $self->{name} ;
    my $val     = $fdat->{$name} ;
    return if ($val eq '') ;

    my $aval = abs ($val) ;
    my $sec = $aval % 60 ;
    my $min = int ($aval / 60) % 60 ;
    my $hour = int($aval / 3600) ;
    
    my $duration = ($val<0?'-':'') . ($hour?sprintf('%d:%02d', $hour, $min):$min) ;
    if ($sec != 0)
	{
	$duration .= sprintf (':%02d', $sec) ;
	}
    $fdat->{$name} = $duration ;
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
    my $val     = $fdat->{$name} ;
    return if ($val eq '') ;
    
    my $neg = 0 ;
    $neg = 1 if ($val =~ s/^\s*-//) ;
    my @vals = split (/:/, $val, 3) ;
     

        
    $fdat->{$name} = @vals == 1?$vals[0] * 60:$vals[0] * 3600 + $vals[1] * 60 + $vals[2] ;
    $fdat->{$name} = - $fdat{$name} if ($neg) ;
    }

# ---------------------------------------------------------------------------
#
#   get_validate_auto_rules - get rules for validation, in case user did
#                             not specify any
#

sub get_validate_auto_rules
    {
    my ($self, $req) = @_ ;
    
    return [ $self -> {required}?(required => 1):(emptyok => 1), -type => 'Duration' ] ;
    }


1 ;

__EMBPERL__


__END__

=pod

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
Optionaly it can display an unit after the input field.
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
(Default: €)

=head3 use_comma

If set the decimal character is comma instead of point (Default: on)

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


