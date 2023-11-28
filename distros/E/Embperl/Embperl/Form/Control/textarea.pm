
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2015 Gerald Richter
#   Embperl - Copyright (c) 2015-2023 actevy.io
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

use vars qw{%fdat} ;

use constant ALLOWED_HTML_TAGS => {map { $_ => 1 } qw{p br img ol ul td th tr td div h1 h2 h3 h4 h5 h6 pre strong em u s sub sup li blockquote caption table tbody tfoot thead hr span big small tt code kbd samp var del ins cite address } };


# ---------------------------------------------------------------------------
#
#   init - init the new control
#

sub init

    {
    my ($self) = @_ ;

    return $self ;
    }

# ------------------------------------------------------------------------------------------
#
#   _filter_html - remove all not allowed html tags
#

sub _filter_html
    {
    my ($self, $dataref) = @_ ;

    $$dataref =~ s/(<\/?(\w+).*?>)/ALLOWED_HTML_TAGS->{$2}?$1:''/ge ;
    }

# ------------------------------------------------------------------------------------------
#
#   _text2html - convert plain text to html
#

sub _text2html
    {
    my ($self, $dataref) = @_ ;

    
    my $is_html =  $self -> {format} eq 'html'  && ($$dataref =~ /^<[-a-zA-Z0-9 "'=:;,]+?>/) ;
    return if ($is_html) ;

    my @text = split (/\n/, $$dataref) ;
    
    $$dataref = '<p>' . join ("<br>\n", @text) . "</p>\n" ;
    }

    
# ------------------------------------------------------------------------------------------
#
#   _text2pre - convert plain text to html pre
#

sub _text2pre
    {
    my ($self, $dataref) = @_ ;

    
    my $is_html =  $self -> {format} eq 'html'  && ($$dataref =~ /^<[-a-zA-Z0-9 "'=:;,]+?>/) ;
    return if ($is_html) ;

    $$dataref =~ s/<\/pre>/<_pre>/g ;
    $$dataref = '<pre>' . $$dataref . "</pre>\n" ;
    }

    
# ------------------------------------------------------------------------------------------
#
#   _html2text - convert html to plain text
#

sub _html2text
    {
    my ($self, $dataref) = @_ ;

    return if ($self -> {format} ne 'html') ;
    
    use utf8 ;
    $$dataref =~ s/<.+?>/ /g ;
    $$dataref =~ s/&auml;/ä/g ;
    $$dataref =~ s/&ouml;/ö/g ;
    $$dataref =~ s/&uuml;/ü/g ;
    $$dataref =~ s/&Auml;/Ä/g ;
    $$dataref =~ s/&Ouml;/Ö/g ;
    $$dataref =~ s/&Uuml;/Ü/g ;
    $$dataref =~ s/&szlig;/ß/g ;
    $$dataref =~ s/&gt;/>/g ;
    $$dataref =~ s/&lt;/</g ;
    $$dataref =~ s/&quot;/"/g ;
    $$dataref =~ s/&apos;/'/g ;
    $$dataref =~ s/&#39;/'/g ;
    $$dataref =~ s/&amp;/&/g ;
    $$dataref =~ s/&nbsp;/ /g ;
    }

# ------------------------------------------------------------------------------------------
#
#   get_display_text - returns the text that should be displayed
#

sub get_display_text
    {
    my ($self, $req, $value, $compact) = @_ ;
    
    $value = $self -> get_value ($req) if (!defined ($value)) ;
    return $value if ($self -> {format} ne 'html') ;    

    if ($compact)
        {
        $self -> _html2text (\$value) ;
        }
    else
        {
        $self -> _filter_html (\$value) ;
        $self -> _text2html (\$value) ;
        }
    
    return $value ;
    }


    
# ------------------------------------------------------------------------------------------
#
#   init_data - daten aufteilen
#

sub init_data
    {
    my ($self, $req, $parentctrl, $force) = @_ ;


    my $fdat  = $req -> {docdata} || \%fdat ;
    my $name  = $self->{name} ;
    return if (!exists $fdat->{$name} || $req -> {"ef_textarea_init_done_$name"}) ;

    if ($self -> {format} ne 'html')
        {
        if ($self -> is_readonly ($req))
            {
            $self -> _text2pre (\$fdat->{$name}) ;
            }
        }
    else
        {
        $self -> _filter_html (\$fdat->{$name}) ;
        $self -> _text2html (\$fdat->{$name}) ;
        }
        
    $req -> {"ef_textarea_init_done_$name"} = 1 ;
    return ;
    }

# ---------------------------------------------------------------------------
#
#   init_markup - add any dynamic markup to the form data
#

sub init_markup

    {
    my ($self, $req, $parentctl, $method) = @_ ;

    return $self -> init_data ($req, $parentctl) ;
    }

# ------------------------------------------------------------------------------------------
#
#   prepare_fdat - daten zusammenfuehren
#

sub prepare_fdat
    {
    my ($self, $req) = @_ ;

    my $fdat  = $req -> {form} || \%Embperl::fdat ;
    my $name  = $self->{name} ;
    return if (!exists $fdat->{$name}) ;

    if ($self -> {format} ne 'html')
        {
        return ;
        }

    $self -> _filter_html (\$fdat->{$name}) ;
    $self -> _text2html (\$fdat->{$name}) ;

    return ;
    }

1 ;

__EMBPERL__
    
[# ---------------------------------------------------------------------------
#
#   show - output the control
#]

[$ sub show ($self, $req)
$]

[$if !$self -> {fullwidth} || $self -> is_readonly ($req) $]
[- $self -> SUPER::show ($req) -]
[$else$]

[#
<table class="ef-element ef-element-width-[+ $self -> {width_percent} +] ef-element-[+ $self -> {type} +] [+ $self -> {state} +]" style="width: 348px">
#]
<table class="ef-element ef-element-width-[+ $self -> {width_percent} +] ef-element-[+ $self -> {type} +] [+ $self -> {state} +]">
  <tr>
    <td class="ef-label-box ef-label-box-width-full  [$ if $self->{labelclass} $][+ " $self->{labelclass}" +][$ endif $]" _ef_attr="[+ $self -> {name} +]">
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
my $ro = $self ->{no_edit} ? 'readOnly="1"' : '' ;
$]

<textarea [+ $ro +]  type="text" name="[+ $self -> {force_name} || $self -> {name} +]"  [+ do { local $escmode = 0 ; $attrs} +]
[# [$if $self -> {cols} $]cols="[+ $self->{cols} +]"[$endif$] #]
[$if $self -> {rows} $]rows="[+ $self->{rows} +]"[$endif$]
[$if $self -> {format} eq 'html' $]_ef_attach="ef_ckeditor"[$endif$]
></textarea>
[* return $ctrlid ; *]
[$endsub$]


[# ---------------------------------------------------------------------------
#
#   show_control_readonly - output the control as readonly
#]

[$ sub show_control_readonly ($self, $req, $value, $suffix) 

my $text  = $self -> get_display_text ($req, $value)  ;
$text =~ s/\s*$// ;
$text =~ s/^\s*// ;
my $name  = $self -> {force_name} || $self -> {name} ;
my $is_html =  $self -> {format} eq 'html'  && ($text =~ /^<[-a-zA-Z0-9 "'=:;,]+?>/) ;
my @text = $is_html?($text):split (/\n/, $text) ;
$]
<div [+ do { local $escmode = 0 ; $self -> get_std_control_attr($req, '', 'readonly') } +] _ef_divname="[+ $name +]">
[$ foreach my $val (@text) $]
[$ if ($val =~ /^\s*$/) $]<br>[$else$]
[$if $is_html $][+ do { local $escmode = 0 ; $val } +][$else$][+ $val +]<br>[$endif$]
[$endif$] 
[$endforeach$]
</div>
[$ if $self->{hidden} $]
<input type="hidden" name="[+ $name +]" value="[+ $value +]">
[$endif$]
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


