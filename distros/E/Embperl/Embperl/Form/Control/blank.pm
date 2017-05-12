
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

package Embperl::Form::Control::blank ;

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

$]<table class="ef-element ef-element-width-[+ $self -> {width_percent} +] ef-element-[+ $self -> {type} || 'blank' +] [+ ' ' . $self -> {state} +]">
  <tr>
    [#<td class="ef-label-box ef-label-box-width-100">[+ $self->{text} +]</td>#]
    <td class="ef-control-box ef-control-box-width-100">[+ $self->{text} +]</td>
  </tr>
</table>[$endsub$]



__END__

=pod

=head1 NAME

Embperl::Form::Control::blank - A blank area inside an Embperl Form


=head1 SYNOPSIS

  { 
  type => 'blank',
  text => 'blabla' 
  }

=head1 DESCRIPTION

Used to create a blank area with optional text inside an Embperl Form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'blank'

=head3 text (optional)

Could be used to give a text that should be displayed inside the blank area


=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


