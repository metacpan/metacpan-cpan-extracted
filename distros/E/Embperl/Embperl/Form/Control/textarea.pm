
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

package Embperl::Form::Control::textarea ;

use strict ;
use base 'Embperl::Form::Control' ;

use Embperl::Inline ;



1 ;

__EMBPERL__
    
[# ---------------------------------------------------------------------------
#
#   show - output the control
#]

[$ sub show ($self, $req)

$]

[$if !$self -> {fullwidth} $]
[- $self -> SUPER::show ($req) -]
[$else$]

<table class="ef-element ef-element-width-[+ $self -> {width_percent} +] ef-element-[+ $self -> {type} +] [+ $self -> {state} +]" style="width: 348px">
  <tr>
    <td class="ef-label-box ef-label-box-width-full  [$ if $self->{labelclass} $][+ " $self->{labelclass}" +][$ endif $]">
  [-
    $fdat{$name} = $self -> {default} if ($fdat{$name} eq '' && exists ($self -> {default})) ;
    my $span = 0 ;
    $self -> show_label ($req);
  -]
  </td>
  </tr>
  <tr>
  <td  class="ef-control-box ef-control-box-width-full">
  [-
  local $self -> {width_percent} = 'full' ;
  $self -> show_control ($req)
  -]
  </td>
  </tr>
  </table>
[$endif$]
[$endsub$]
  
[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show_control ($self, $req) 
my $class = $self -> {class} ||= '' ;
my ($attrs, $ctrlid, $name) = $self -> get_std_control_attr($req)  ;
$]

<textarea type="text" name="[+ $self -> {force_name} || $self -> {name} +]"  [+ do { local $escmode = 0 ; $attrs} +]
[# [$if $self -> {cols} $]cols="[+ $self->{cols} +]"[$endif$] #]
[$if $self -> {rows} $]rows="[+ $self->{rows} +]"[$endif$]
></textarea>
[* return $ctrlid ; *]
[$endsub$]


[# ---------------------------------------------------------------------------
#
#   show_control_readonly - output the control as readonly
#]

[$ sub show_control_readonly ($self, $req, $value, $class) $]
[- 
$value //= $fdat{$self -> {name}} ;
$value =~ s/\s*$// ;
$value =~ s/^\s*// ;
@value = split (/\n/, $value) ;
$i = 0 ;
-][$ foreach my $val (@value) $]
[$ if $val =~ /^\s*$/ $]<br>[$else$]
[- $self -> SUPER::show_control_readonly ($req, $val, $class) -][# $ if ($i < @value - 1) $]<br>[$endif$ #]
[$endif$] 
[$endforeach$]
[$endsub$]
__END__

=pod

=head1 NAME

Embperl::Form::Control::textarea - A textarea input control inside an Embperl Form


=head1 SYNOPSIS

  { 
  type => 'textarea',
  text => 'blabla', 
  name => 'foo',
  id   => 'id_foo',
  rows => 10,
  cols => 80,
  }

=head1 DESCRIPTION

Used to create an input control inside an Embperl Form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'textarea'

=head3 text 

Will be used as label for the text input control

=head3 name 

Will be used as field name for the text input control

=head3 name 

Will be used as id of the text input control

=head3 cols

Number of columns

=head3 rows

Number of rows

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


