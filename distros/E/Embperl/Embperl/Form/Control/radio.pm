
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

package Embperl::Form::Control::radio ;

use strict ;
use vars qw{%fdat} ;
use base 'Embperl::Form::ControlMultValue' ;

use Embperl::Inline ;


# ---------------------------------------------------------------------------

sub show_control_addons
    {
    my ($self, $req) = @_ ;

    }

1 ;

__EMBPERL__

[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show_control ($self, $req, $filter, $values, $options)

    ($values, $options) = $self -> get_values ($req) if (!$values) ;
    my $name     = $self -> {name} ;
    my $ignorecase= $self -> {ignorecase} ;
    my $max      = @$values ;
    my $set      = !defined ($fdat{$name})?1:0 ;
    my $nsprefix = $self -> form -> {jsnamespace} ;
    my $ctrlid  = ($req -> {uuid} . '_' . $name) ;
    my $val ;
    my $i = 0 ;

if ($self -> {vert})
    {
    $tr = '<tr>' ;
    $trend = '</tr>' ;
    $trglob = '' ;
    $trendglob = '' ;
    }
else
    {
    $tr = '' ;
    $trend = '' ;
    $trglob = '<tr>' ;
    $trendglob = '</tr>' ;
    }

$]
<table class="ef-control-radiotab  [+ $self -> {state} +]"
[$if ($self -> {trigger}) $]_ef_attach="ef_radio" name="[+ $self -> {force_name} || $self -> {name} +]"[$endif$]
>[+ do { local $escmode = 0 ; $trglob }+]
[$ foreach $val (@$values) $][- $x = ($val =~ /$filter/i) -]
    [- $fdat{$name} = $val, $set = 0 if ($set) ;
       $fdat{$name} = $val if ($ignorecase && lc($fdat{$name}) eq lc($val)) ; -]
    [+ do { local $escmode = 0 ; $tr }+]<td><input type="radio"  name="[+ $self -> {force_name} || $self -> {name} +]" [+ do { local $escmode = 0 ; $self -> get_std_control_attr($req, "$ctlid-_-$val") } +] value="[+ $val +]" 
    ></td><td>[+ $options ->[$i] || $val +]</td>[+ do { local $escmode = 0 ; $trend }+]
    [* $i++ ; *]
[$endforeach$]
[+ do { local $escmode = 0 ; $trendglob }+]</table>
[$endsub$]



__END__

=pod

=head1 NAME

Embperl::Form::Control::radio - A radio control inside an Embperl Form


=head1 SYNOPSIS

  {
  type    => 'radio',
  text    => 'blabla',
  name    => 'foo',
  values  => [1,2,3],
  options => ['foo', 'bar', 'none'],
  }

=head1 DESCRIPTION

Used to create an radio control inside an Embperl Form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'radio'

=head3 name

Specifies the name of the radio control

=head3 text

Will be used as label for the radio control

=head3 values

Gives the values as an array ref of the radio control.

=head3 options

Gives the options as an array ref that should be displayed to the user.
If no options are given, the values from values are used.

=head3 vert

If specified arranges the radio button vertically. The number given specifies
the number of <br>'s used the separate the radio buttons.

=head3 ignorecase

If given, ignore the case of the posted values in %fdat, when selecting
a radio button.

=head3 addtop

Array ref which contains items that should be added at the left or top
of the radio buttons. Each item consists of an array ref with two
entries, the first is the value and the second is the option
that is displayed on the page. If the second is missing the
value (first entry)is displayed. Example:

    addtop => [ [1 => 'first item'], [2 => 'second item']]

=head3 addbottom

Array ref which contains items that should be added at the right or bottom
of the radio buttons. Each item consists of an array ref with two
entries, the first is the value and the second is the option
that is displayed on the page. If the second is missing the
value (first entry)is displayed. Example:

    addbottom => [ [9999 => 'last item'], [9999 => 'very last item']]

=head3 filter

If given, only items where the value matches the regex given in
C<filter> are displayed.

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


