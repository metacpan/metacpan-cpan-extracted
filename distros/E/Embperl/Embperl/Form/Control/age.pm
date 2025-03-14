
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

package Embperl::Form::Control::age ;

use strict ;
use base 'Embperl::Form::Control::number' ;

use Embperl::Inline ;

use vars qw{%fdat} ;

use Date::Calc qw{Delta_DHMS};
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
#   get_sort_value - returns the value that should be used to sort
#

sub get_sort_value
    {
    my ($self, $req, $value) = @_ ;
    
    $value = $self -> get_value ($req) if (!defined ($value)) ;
    return $value ;
    }

# ------------------------------------------------------------------------------------------
#
#   get_display_text - returns the text that should be displayed
#

sub get_display_text
    {
    my ($self, $req, $time) = @_ ;
    
    $time = $self -> get_value ($req) if (!defined ($time)) ;

    return if ($time eq '') ;

    #20060914041444Z
    my ($year, $mon, $mday, $hour, $min, $sec, $tz) = ($time =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(.)$/) ;
    my ($sec2, $min2, $hour2, $mday2, $mon2, $year2) = gmtime ;
    $mon2++ ;
    $year2+=1900 ;
    #warn "$_[0] $year,$mon,$mday, $hour,$min,$sec,$year2,$mon2,$mday2, $hour2,$min2,$sec2" ;
    my ($Dd,$Dh,$Dm,$Ds) = eval { Delta_DHMS($year,$mon,$mday, $hour,$min,$sec,
                                      $year2,$mon2,$mday2, $hour2,$min2,$sec2) } ;

    my $age     = $Dd > 0?"${Dd}Tage":sprintf ('%d:%02dh', $Dh, $Dm) ;
    my $tooltip = sprintf('%d.%02d.%04d %d:%02d', $mday, $mon, $year, $hour, $min) ;
    return wantarray?($age, $tooltip):$age ;
    }

# ------------------------------------------------------------------------------------------
#
#   init_data - daten aufteilen
#

sub init_data
    {
    my ($self, $req, $parentctrl, $force) = @_ ;
    
    my $fdat  = $req -> {docdata} || \%fdat ;
    my $name    = $self->{name} ;
    my $val     = $fdat->{$name} ;
    return if ($val eq '' || ($req -> {"ef_age_init_done_$name"} && !$force)) ;

    my ($age, $tooltip) = $self -> $self -> get_display_text ($req, $val) ;

    $fdat->{$name} = $age;
    $fdat->{'_tt_' . $name} = $tooltip ;
    $req -> {"ef_age_init_done_$name"} = 1 ;
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
    
    }

1 ;

__EMBPERL__


__END__

=pod

=head1 NAME

Embperl::Form::Control::age - A age input control with optional unit inside an Embperl Form


=head1 SYNOPSIS

  {
  type => 'age',
  text => 'blabla',
  name => 'foo',
  unit => 'sec',
  }

=head1 DESCRIPTION

Used to create an age input control inside an Embperl Form.
Will format date as days:hours:minutes from current time.
Optionally it can display an unit after the input field.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'age'

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
(



=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


