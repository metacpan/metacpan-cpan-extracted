
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

package Embperl::Form::Control::line ;

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
my $state   = $self -> {state} ;
$]
<table class="ef-element ef-element-width-[+ $self -> {width_percent} +] ef-element-[+ $self -> {type} +] [+ $self -> {state} +]">
  <tr>  <td class="cBase cTransparentBox" colspan="[+ $span +] [+ $state +]"><hr class="cControlLine"></td>
  </tr></table>
[$endsub$]


__END__

=pod

=head1 NAME

Embperl::Form::Control::line - A horizontal line an Embperl Form


=head1 SYNOPSIS

  {
  type => 'line',
  }

=head1 DESCRIPTION

Used to create a horizontal line inside an Embperl Form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'line'


=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


