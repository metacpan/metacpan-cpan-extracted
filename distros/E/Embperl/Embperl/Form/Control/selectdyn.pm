
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

package Embperl::Form::Control::selectdyn ;

use strict ;
use vars qw{%fdat} ;
use base 'Embperl::Form::ControlMultValue' ;

use Embperl::Inline ;

# ------------------------------------------------------------------------------------------

sub get_std_control_attr
    {
    my ($self, $req, $id, $type, $addclass) = @_ ;

    if ($type eq 'readonly')
        {
        $id = $req -> {uuid} . '_' . $self -> {name} ;
        my $url  = $self -> {showurl} ;
        $url =~ s/<id>/$self -> get_id_from_value ($Embperl::fdat{$self -> {name}})/e ;
        my $attr = $self -> SUPER::get_std_control_attr ($req, $id, $type, 'ef-control-selectdyn-readonly') ;
        return $attr . qq{ onDblClick="\$('#$self->{use_ajax}').ef_document ('load', '$url');"} ;
        }
	
    return $self -> SUPER::get_std_control_attr ($req, $id, $type, $addclass) ;
    }
    
# ------------------------------------------------------------------------------------------
#
#   init_data - daten aufteilen
#

sub init_data
    {
    my ($self, $req) = @_ ;

    my $val = $self -> get_value ($req) ;
    if ($val ne '')
        {
        my $name = $self -> {name} ;
        my $fdat = $req -> {docdata} || \%Embperl::fdat ;
        $fdat -> {'_opt_' . $name} = $self -> get_option_from_value ($val, $req) ;
        $fdat -> {'_id_' .  $name} = $self -> get_id_from_value ($val, $req) ;
        }
    }
    
# ------------------------------------------------------------------------------------------
#
#   prepare_fdat - daten zusammenfuehren
#

sub prepare_fdat
    {
    my ($self, $req) = @_ ;

    return if ($self -> is_readonly ($req)) ;

    my $fdat  = $req -> {form} || \%fdat ;
    my $name    = $self->{name} ;
    $fdat -> {$name} = '' if (exists ($fdat -> {"_opt_$name"}) && $fdat -> {"_opt_$name"} eq '') ;
    delete $fdat -> {"_opt_$name"} ;
    delete $fdat -> {"_id_$name"} ;
    }

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

[$ sub show_control ($self, $req, $filter)

my $name     = $self -> {name} ;
my $class = $self -> {class} ;
$]

<input name="_opt_[+ $name +]" [+ do { local $escmode = 0 ; $self -> get_std_control_attr($req) } +]
type="text" _ef_attach="ef_selectdyn"
[$if $self -> {size}            $]size="[+ $self->{size} +]" [$endif$]
[$if $self -> {showurl}         $]_ef_show_url="[+ $self -> {showurl} +]" [$endif$] 
[$if $self -> {popupurl}        $]_ef_popup_url="[+ $self -> {popupurl} +]" [$endif$] 
[$if $self -> {datasrcurl}      $]_ef_datasrc_url="[+ $self -> {datasrcurl} +]" [$endif$] 
[$if $self -> {datasrc}         $]_ef_datasrc_nam="[+ $self -> {datasrc} +]" [$endif$] 
[$if $self -> {datasrctermmax}  $]_ef_datasrc_term_max="[+ $self -> {datasrctermmax} +]" [$endif$] 
[$if $self -> {use_ajax}        $]_ef_use_ajax="[+ $self -> {use_ajax} +]" [$endif$] 
[$if $self -> {show_on_select}  $]_ef_show_on_select="[+ $self -> {show_on_select}?'1':'' +]" [$endif$] 
>
<input type="hidden" name="[+ $name +]">
<input type="hidden" name="_id_[+ $name +]">
[$endsub$]


__END__

=pod

=head1 NAME

Embperl::Form::Control::selectdyn - A dynamic select control inside an Embperl Form


=head1 SYNOPSIS

  {
  type    => 'selectdyn',
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

=head3 showurl

This URL will be requested if the user clicks on SHOW in the popup or
double clicks the control. The value of the selected option will be
appended to that url. Should be something like '/foo/bar.epl?id='.
NOTE: This URL is not encoded in anyway, so make sure it is properly
url encoded.

=head3 datasrcurl

This URL will be requested when the user types any input to request
the data for the control. The characters the users has typed will be
passed by the parameter query and the name of the datasrc attribute
will be passed in the datasrc parameter.
NOTE: This URL is not encoded in anyway, so make sure it is properly
url encoded.

=head3 show_on_select

If true show the selected item as soon as it is selected (useses showurl)

=head3 use_ajax

If set to an id of an html element, documents that are loaded via showurl
are fetch via ajax into this html container, instead of fetching a whole page.

=head3 $fdat{-init-<name>}

If set this value is used to prefill the input box, if not set get_values
method of the datasource object is call, which might be take a long time
in case of many options.


=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


