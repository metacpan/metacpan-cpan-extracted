
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

package Embperl::Form::Control::number ;

use strict ;
use base 'Embperl::Form::Control::input' ;

use Embperl::Inline ;

use vars qw{%fdat} ;

# ------------------------------------------------------------------------------------------

sub get_std_control_attr
    {
    my ($self, $req, $id, $type, $addclass) = @_ ;

    return $self -> SUPER::get_std_control_attr ($req, $id, $type, $type eq 'readonly'?'ef-control-number-readonly':$addclass) ;
    }
    
# ------------------------------------------------------------------------------------------
#
#   get_display_text - returns the text that should be displayed
#

sub get_display_text
    {
    my ($self, $req, $value, $compact) = @_ ;
    
    $value = $self -> get_value ($req) if (!defined ($value)) ;

    return if ($value eq '') ;
    if ($compact)
        {
        return $value + 0 if (!$self -> {allow_unit}) ;
        return $value ;
        }
    
    my $unit = $self->{unit} ;
    my $unittext = !$unit?'':$self -> form -> convert_text ($self, ($unit =~ /:/)?$unit:'unit:' . lc($unit), $unit, $req) ;
    $unittext =~ s/^unit:// ;

    return $value . ' ' . $unittext ;        
    }
    
# ------------------------------------------------------------------------------------------
#
#   get_sort_value - returns the value that should be used to sort
#

sub get_sort_value
    {
    my ($self, $req, $value) = @_ ;
    
    $value = $self -> get_value ($req) if (!defined ($value)) ;
    return $value + 0 ;
    }
    

# ---------------------------------------------------------------------------
#
#   show_control_readonly - output the control as readonly
#

sub xshow_control_readonly 
    {
    my ($self, $req, $value) = @_ ;

    my $unit = $self->{unit} ;
    my $unittext = !$unit?'':$self -> form -> convert_text ($self, ($unit =~ /:/)?$unit:'unit:' . lc($unit), $unit, $req) ;
    $unittext =~ s/^unit:// ;
    $value = $self -> get_value ($req) if (!defined ($value)) ;

    $self -> SUPER::show_control_readonly ($req, $value, $unit && $value ne ''?$unittext:'') ;
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
    return if ($val eq '' || (!$force && $req -> {"ef_number_init_done_$name"})) ;

    my $num = $self -> get_display_text ($req, $val, 1) ;

    $fdat->{$name} = $num ;
    $req -> {"ef_number_init_done_$name"} = 1 ;
    }

# ---------------------------------------------------------------------------
#
#   init_markup - add any dynamic markup to the form data
#

sub init_markup

    {
    my ($self, $req, $parentctl, $method) = @_ ;

    return if (!$self -> is_readonly($req) && (! $parentctl || ! $parentctl -> is_readonly($req))) ;
    
    my $fdat  = $req -> {docdata} || \%fdat ;
    my $name    = $self->{name} ;
    my $val     = $fdat->{$name} ;
    return if ($val eq '' || ($req -> {"ef_number_init_done_$name"})) ;

    my $num = $self -> get_display_text ($req, $val) ;

    $fdat->{$name} = $num ;
    $req -> {"ef_number_init_done_$name"} = 1 ;
    }

# ---------------------------------------------------------------------------
#
#   get_validate_auto_rules - get rules for validation, in case user did
#                             not specify any
#

sub get_validate_auto_rules
    {
    my ($self, $req) = @_ ;
    
    return [ $self -> {required}?(required => 1):(emptyok => 1), -type => 'PosInteger' ] ;
    }

1 ;

__EMBPERL__

[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show_control ($self, $req)

    $self->{size}      ||= 10 ;

    my $unit = $self->{unit} ;
    my $unittext = !$unit?'':$self -> form -> convert_text ($self, ($unit =~ /:/)?$unit:'unit:' . lc($unit), $unit, $req) ;
    $unittext =~ s/^unit:// ;
$]
[-     $self -> SUPER::show_control ; -]
[$if ($unit) $][+ $unittext +][$endif$]
[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::number - A numeric input control with optional unit inside an Embperl Form


=head1 SYNOPSIS

  {
  type => 'input',
  text => 'blabla',
  name => 'foo',
  unit => 'sec',
  }

=head1 DESCRIPTION

Used to create a numeric input control inside an Embperl Form.
Optionally it can display an unit after the input field.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'number'

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


=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


