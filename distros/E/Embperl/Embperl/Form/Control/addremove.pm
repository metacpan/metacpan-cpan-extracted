
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

package Embperl::Form::Control::addremove ;

use strict ;
use base 'Embperl::Form::Control' ;

use Embperl::Inline ;


# ---------------------------------------------------------------------------
#
#   new - create a new control
#


sub new

    {
    my ($class, $args) = @_ ;

    my $self = Embperl::Form::Control -> new($args) ;
    bless $self, $class ;

    $self -> {removesource} ||= 0 ;
    $self -> form -> add_code_at_bottom("ef_addremoveInitOptions (document, document.getElementsByName('$self->{src}')[0], document.getElementsByName('$self->{dest}')[0], document.getElementsByName('$self->{name}')[0], $self->{removesource})") ;
    return $self ;
    }



1 ;

__EMBPERL__


[# ---------------------------------------------------------------------------
#
#   show - output the control
#]

[$ sub show ($self, $req)

my $name = $self -> {name} ;

$]<table class="ef-element ef-element-width-[+ $self -> {width_percent} +] ef-element-[+ $self -> {type}  +] [+ ' ' . $self -> {state} +]">
  <tr>
    <td class="cBase cControlBox cControlAddRemoveBox">
<input type="hidden" id="[+ $name +]" name="[+ $name +]">
<img src="[+ $self -> {imagedir} +]/toleft.gif" title="Hinzufügen" onClick="ef_addremoveAddOption (document, document.getElementsByName('[+ $self->{src} +]')[0], document.getElementsByName('[+ $self->{dest} +]')[0], document.getElementsByName('[+ $name +]')[0], [+ $self->{removesource} +])">
<img src="[+ $self -> {imagedir} +]/toright.gif" title="Entfernen" onClick="ef_addremoveRemoveOption (document, document.getElementsByName('[+ $self->{src} +]')[0], document.getElementsByName('[+ $self->{dest} +]')[0], document.getElementsByName('[+ $name +]')[0], [+ $self->{removesource} +])">

</td>
</tr>
</table>
[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::addremove - A control to add and remove items from two select boxes inside an Embperl Form


=head1 SYNOPSIS

  {
  type         => 'addremove',
  name         => 'foo',
  src          => 'src_select_name',
  dest         => 'dest_select_name',
  removesource => 1,
  }

=head1 DESCRIPTION

A control to add and remove items from two select boxes
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'addremove'

=head3 name

Specifies the name of the addremove control

=head3 src

Gives the name of the select box which serves as source of the data items

=head3 dest

Gives the name of the select box which serves as destionations of the data items

=head3 removesource

If set to a true value the items will be removed from the source select box and
move to the destionation box. If set to false, the items will be copied.

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


