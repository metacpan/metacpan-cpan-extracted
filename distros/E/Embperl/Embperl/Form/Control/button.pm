
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

package Embperl::Form::Control::button ;

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

my $span = ($self->{width_percent})  ;
$self->{button} ||= [{}] ;
my $state   = $self -> {state} ;
$]<table class="ef-element ef-element-width-[+ $self -> {width_percent} +] ef-element-[+ $self -> {type} +] [+ $self -> {state} +]">
  <tr>  <td class="ui-label-box" >
[$ foreach my $button (@{$self->{button}}) $]
  [$if $self -> {symbol} $]
    <div class="cControlButtonDiv" 
  title="[+ $self -> {showtext}?($self->{text}):$self -> form -> convert_label ($self, undef, undef, $req) +]"
  [$if $self -> {onclick} $] onClick="[+ do { local $escmode = 0 ; $self -> {onclick} } +]" [$endif$]
    [+ do { local $escmode = 0 ; $self -> {eventattrs} } +]><img class="cControlButtonSymbol" src="[+ $self -> {symbol} +]">
   [+ $self -> {showvalue}?($self -> {value} || $self->{text}):$self -> form -> convert_label ($self, undef, undef, $req) +]
    </div>	
[$else$]
  [# Workaround around segfault in Embperl 2.1.1-dev *grmpf* #]
  <[# #]input
  class="cBase cControl cControlButton"  name="[+ $self->{name} +]"
  value="[+ $self -> {showvalue}?($self -> {value} || $self->{text}):$self -> form -> convert_label ($self, undef, undef, $req) +]"
  title="[+ $self -> {showtext}?($self->{text}):$self -> form -> convert_label ($self, undef, undef, $req) +]"
  [$if $self -> {onclick} $] onClick="[+ do { local $escmode = 0 ; $self -> {onclick} } +]" [$endif$]
  [+ do { local $escmode = 0 ; $self -> {eventattrs} } +]
  [$if $self -> {image} $]
  type="image" src="[+ $self -> {image} +]"
  [$else$]
  type="button"
  [$endif$]
  style="[+ $self->{style} || 'text-align: center;' +]"
  [#    onMouseOver="buttonover(this);" onMouseOut="buttonout(this);" #]
    [$ foreach my $attr (keys %$button) $]
      [$ if exists $button->{"__$attr".'_escmode'} $]
        [+ $attr +]="[+ do { local $escmode = int $button->{"__${attr}_escmode"}; $button->{$attr}; } +]"
      [$ else $]
        [+ $attr +]="[+ $button->{$attr} +]"
      [$ endif $]
    [$ endforeach $]>
  [$endif$]
[$ endforeach $]

  </td></tr>
  </table>[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::submit - A button inside an Embperl Form


=head1 SYNOPSIS

  { 
  type => 'submit',
  text => 'send', 
  name => 'foo',
  value => 'xxx',
  image => 'xxx',
  onclick => 'window.open (...)',

  button => [
             {
             onclick     => 'do_something()',
             style       => 'border: 1px solid black;',
             },
             {
             name        => 'foobar',
             value       => 'Click here, too',
             onclick     => 'do_something()',
             class       => 'HurzCSSClass',
             onmouseover => 'do(this)';
             onmouseout  => 'do(that)';
             }
            ]

  }

=head1 DESCRIPTION

Used to create an submit control inside an Embperl Form.
If an image is given it will create an image button.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'button'

=head3 name

Name of the button

=head3 text 

Will be used as label for the submit button or tool tip
in case of an image button

=head3 value

Gives the value to send

=head3 image

URL of an image. If given an image button will be created,
if absent, an normal submit button will be created.

=head3 onclick

Javascript that should be executed when the users clicks on the button.

=head3 button

hashref of the key-value pairs of all attribute the button needs.

=head1 Author

G. Richter (richter at embperl dot org), A. Beckert (beckert@ecos.de)

=head1 See Also

perl(1), Embperl, Embperl::Form


