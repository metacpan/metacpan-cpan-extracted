
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

package Embperl::Form::Control::select ;

use strict ;
use vars qw{%fdat} ;
use base 'Embperl::Form::ControlMultValue' ;

use Embperl::Inline ;



1 ;

__EMBPERL__

[# ---------------------------------------------------------------------------
#
#   show_hidden - out hidden field
#]

[$ sub show_hidden ($self, $req) $]
<input type="hidden" name="[+ $self -> {name} +]">
[$endsub$]

[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show_control ($self, $req, $filter)

    my $name     = $self -> {name} ;
    $filter      ||= $self -> {filter} ;
    my $nsprefix = $self -> form -> {jsnamespace} ;
    my $val ;
    my $i = 0 ;
    my ($values, $options) = $self -> get_all_values ($req) ;
    my ($ctlattrs, $ctlid, $ctlname) =  $self -> get_std_control_attr($req) ;
    $values ||= [] ;
$]
<select name="[+ $ctlname +]" [+ $self->{multiple}?'multiple':''+] [+ do { local $escmode = 0 ; $ctlattrs } +] 
[$if ($self -> {rows}) $] size="[+ $self->{rows} +]" [$endif$]
[$if ($self -> {trigger}) $]_ef_attach="ef_select"[$endif$]
>
[* $i = 0 ; *]
[$ foreach $val (@$values) $]
    [$if !defined ($filter) || ($val =~ /$filter/i) $]
    <option value="[+ $val +]">[+ $options ->[$i] || $val +]</option>
    [$endif$]
    [* $i++ ; *]
[$endforeach$]
</select>
[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::select - A select control inside an Embperl Form


=head1 SYNOPSIS

  {
  type    => 'select',
  text    => 'blabla',
  name    => 'foo',
  values  => [1,2,3],
  options => ['foo', 'bar', 'none'],
  rows    => 5
  }

=head1 DESCRIPTION

Used to create an select control inside an Embperl Form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'select'

=head3 name

Specifies the name of the select control

=head3 text

Will be used as label for the select control

=head3 values

Gives the values as an array ref of the select control.

=head3 options

Gives the options as an array ref that should be displayed to the user.
If no options are given, the values from values are used.

=head3 rows

If specified a select box is display with the given number of lines.
If not specified or undef, a drop down list is shown.

=head3 addtop

Array ref which contains items that should be added at the top
of the select box. Each item consists of an array ref with two
entries, the first is the value and the second is the option
that is displayed on the page. If the second is missing the
value (first entry)is displayed. Example:

    addtop => [ [1 => 'first item'], [2 => 'second item']]

=head3 addbottom

Array ref which contains items that should be added at the bottom
of the select box. Each item consists of an array ref with two
entries, the first is the value and the second is the option
that is displayed on the page. If the second is missing the
value (first entry)is displayed. Example:

    addbottom => [ [9999 => 'last item'], [9999 => 'very last item']]

=head3 filter

If given, only items where the value matches the regex given in
C<filter> are displayed.

=head3 multiple

If set to true, allows multiple selections.

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


