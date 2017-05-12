
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

package Embperl::Form::Control::submit ;

use strict ;
use base 'Embperl::Form::Control' ;

use Embperl::Inline ;

1 ;

__EMBPERL__
    
[# ---------------------------------------------------------------------------
#
#   show - output the control
#]

[$ sub show ($self, $data)

my $span = ($self->{width_percent})  ;
$]
<td class="cBase cControlBox cControlButtonBox" colspan="[+ $span +]">
<input class="cBase cControl cControlButton"  name="[+ $self->{name} +]"
value="[+ $self->{value} || $self->{text} +]"
title="[+ $self->{text} +]"
[$if $self -> {novalidate} $] onClick="doValidate = 0;" [$endif$]
[$if $self -> {image} $]
type="image" src="[+ $self -> {image} +]"
[$else$]
type="submit"
[$endif$]
>
</td>
[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::submit - A submit button inside an Embperl Form


=head1 SYNOPSIS

  { 
  type => 'submit',
  text => 'send', 
  name => 'foo',
  value => 'xxx',
  image => 'xxx',
  }

=head1 DESCRIPTION

Used to create an submit control inside an Embperl Form.
If an image is given it will create an image button.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'submit'

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


=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


