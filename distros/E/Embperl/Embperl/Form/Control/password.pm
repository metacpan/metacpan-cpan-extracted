
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

package Embperl::Form::Control::password ;

use strict ;
use base 'Embperl::Form::Control' ;

use vars qw{%fdat} ;

use Embperl::Inline ;


    
# ------------------------------------------------------------------------------------------
#
#   init_data - daten aufteilen
#

sub init_data
    {
    my ($self, $req, $parentctrl) = @_ ;

    my $fdat  = $req -> {docdata} || \%fdat ;
    my $name    = $self->{name} ;

    $fdat->{$name} = $fdat->{$name}?'********':'' ;
    
    my $retype_name = $self->{retype_name} ;
    $fdat->{$retype_name} = $fdat->{$name} if ($retype_name) ;
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

    delete $fdat -> {$name} if ($fdat -> {$name} eq '********') ;
    }

# ---------------------------------------------------------------------------
#
#   get_validate_auto_rules - get rules for validation, in case user did
#                             not specify any
#

sub get_validate_auto_rules
    {
    my ($self, $req) = @_ ;
    
    return [ ($self -> {required}?(required => 1):(emptyok => 1)), length_min => 4 ] if (!$self->{retype_name}) ;
    return [ "same", $self->{retype_name}, ($self -> {required}?(required => 1):(emptyok => 1)), length_min => 4 ] ;
    }


1 ;

__EMBPERL__
    
[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show_control ($self, $req) $]

<input type="password" name="[+ $self -> {force_name} || $self -> {name} +]" [+ do { local $escmode = 0 ; $self -> get_std_control_attr($req) } +]
[$if $self -> {size} $]size="[+ $self->{size} +]"[$endif$]
[$if $self -> {maxlength} $]size="[+ $self->{maxlength} +]"[$endif$]
>
[$endsub$]


[# ---------------------------------------------------------------------------
#
#   show_control_readonly - output the control as readonly
#]

[$ sub show_control_readonly ($self) $][$ if ($fdat{$self->{name}}) $]********[$endif$][$endsub$]



__END__

=pod

=head1 NAME

Embperl::Form::Control::password - A password input control inside an Embperl Form


=head1 SYNOPSIS

  { 
  type => 'password',
  text => 'blabla', 
  name => 'foo',
  size => 10,
  }

=head1 DESCRIPTION

Used to create a password control inside an Embperl Form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'password'

=head3 name

Specifies the name of the control

=head3 text 

Will be used as label for the text input control

=head3 size

Gives the size in characters

=head3 retype_name

Name of control that is used to repeat the password.
An automatic validation rule will be generated, to make
sure both inputs are equal.


=head3 maxlength

Gives the maximun length in characters

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


