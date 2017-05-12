
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

package Embperl::Form::Control::number ;

use strict ;
use base 'Embperl::Form::Control::input' ;

use Embperl::Inline ;

# ------------------------------------------------------------------------------------------

sub get_std_control_attr
    {
    my ($self, $req, $id, $type, $addclass) = @_ ;

    return $self -> SUPER::get_std_control_attr ($req, $id, $type, $type eq 'readonly'?'ef-control-number-readonly':$addclass) ;
    }
    

# ---------------------------------------------------------------------------
#
#   show_control_readonly - output the control as readonly
#

sub show_control_readonly 
    {
    my ($self, $req, $value) = @_ ;

    my $unit = $self->{unit} ;
    my $unittext = !$unit?'':$self -> form -> convert_text ($self, ($unit =~ /:/)?$unit:'unit:' . lc($unit), $unit, $req) ;
    $unittext =~ s/^unit:// ;
    $value = $self -> {value} || $Embperl::fdat{$self -> {name}} if (!defined($value)) ;
    $value .= $unittext if ($unit && $value ne '') ;

    $self -> SUPER::show_control_readonly ($req, $value) ;
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
Optionaly it can display an unit after the input field.
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


