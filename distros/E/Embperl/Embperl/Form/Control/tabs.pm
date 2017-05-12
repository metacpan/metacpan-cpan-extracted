
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

package Embperl::Form::Control::tabs ;

use strict ;
use vars qw{%fdat} ;

use Embperl::Form::ControlMultValue ;
use base 'Embperl::Form::ControlMultValue' ;

use Embperl::Inline ;

# ---------------------------------------------------------------------------
#
#   new - create a new control
#


sub new

    {
    my ($class, $args) = @_ ;

    my $self = Embperl::Form::ControlMultValue -> new($args) ;
    bless $self, $class ;

    $self -> {width} = 1 ;
    $self -> {nameprefix} ||= 'tab:' ;

    return $self ;
    }

# ---------------------------------------------------------------------------
#
#   noframe - do not draw frame border if this is the first control
#


sub noframe

    {
    return 1 ;
    }

# ---------------------------------------------------------------------------
#
#   get_active_id - get the id of the value which is currently active
#

sub get_active_id

    {
    my ($self, $req)   = @_ ;

    my $key = "active_id:$self" ;
    my $id ;
    return $id if ($id = $req -> {$key}) ;
    
    my ($values, $options) = $self -> get_values ($req) ;
    my $name     = $self -> {name} ;
    my $dataval  = $fdat{$name} || $req -> {query}{$name} || $values -> [0] ;
    my $activeid ;

    my $i = 0 ;
    foreach my $val (@$values)
        {
        if ($val eq $dataval || $self -> {subids}[$i] eq $dataval)
            {
            $activeid = $self -> {subids}[$i] ;
            last ;
            }
        $i++ ;
        }
    return $req -> {$key} = $activeid || $self -> {subids}[0];
    }


1 ;

__EMBPERL__

[$ syntax EmbperlBlocks $]

[ ---------------------------------------------------------------------------
#
#   show_controls_begin - output begin of form controls area
#]

[$ sub show_subform_controls_begin  ($self, $form, $req, $activeid)

my $parent = $form -> parent_form ;
my $class  = $parent -> {noframe}?'ef-tabs-border-u':'ef-tabs-border' ;
$]

<div _ef_name="[+ $form->{id} +]" class="ef-tabs-content"
[$if ($activeid && $form->{id} ne $activeid) $] style="display: none" [$endif$]
>

[$if (!$form -> {noframe}) $]
    <div class="ef-tabs-separator ui-accordion-header ui-helper-reset ui-state-default ui-accordion-icons ui-corner-top"><span class="ui-accordion-header-icon ui-icon ui-icon-triangle-1-s ef-icon" title="Verstecken/Anzeigen"></span><span class="ef-tabs-separator-header-text">[+ $form -> {text} +]</span></div>
                             [#<table class="ef-tabs-border-cell [+ $class +]"><tr><td class="ef-tabs-content-cell"> #]
    <div class="ef-tabs-border-cell [+ $class +]"><div class="ef-tabs-content-cell">
                              
[$endif$]

[$endsub$]

[# ---------------------------------------------------------------------------
#
#   show_controls_end - output end of form controls area
#]

[$sub show_subform_controls_end ($self, $form, $req)
 $]

[# [$ if (!$form -> {noframe}) $]</td></tr></table> [$endif$] #]
[$ if (!$form -> {noframe}) $]</div></div> [$endif$]
</div>
[$endsub$]



[# ---------------------------------------------------------------------------
#
#   show - output the control
#]

[$ sub show ($self, $req)

    my ($values, $options) = $self -> get_values ($req)  ;
    my $span = ($self->{width_percent})  ;
    my $name     = $self -> {name} ;
    my $dataval  = $fdat{$name} || $values -> [0] ;
    my $activeid = $self -> get_active_id ($req) ;
    my $form     = $self -> form ;
    my $nsprefix = $form -> {jsnamespace} ;
    my $tabs_per_line = $self -> {'tabs_per_line'} || 99;
    $tabs_per_line = [$tabs_per_line, $tabs_per_line, $tabs_per_line, $tabs_per_line] 
        if (!ref $tabs_per_line) ;

    my $val ;
    my $i = 0 ;
    my $j = 0 ;
    my $more = 1 ;
    my $start_i = 0 ;
    my $line = 0 ;
$]

<div class="ef-tabs-content-cell" colspan="[+ $span +]" _ef_attach="ef_tabs">
    [$ while ($more) $]
      <table  class="ef-tabs-selector" ><tr  class="ef-tabs-selector-row">
      [* 
      $more = 0 ; 
      my $tabs = $tabs_per_line -> [$line++] ;
      *]
      [$ while ($j < @$values) $]
        [*
        if ($self -> {subobjects}[ $j ] -> is_disabled ($req))
            {
            $j++ ;
            next ;
            }
        $val = $values -> [$j] ;
        my $id        = $self -> {subids}[$j] ;
        my $cellclass = $id eq $activeid?'ef-tabs-cell-on':'ef-tabs-cell-off' ;
        my $divclass  = $id eq $activeid?'ef-tabs-div-on':'ef-tabs-div-off' ;

        my @switch_code ;

        foreach my $sub (@{$form -> {controls}})
            {
            my $code = $sub -> get_on_show_code ;
            push @switch_code, $code if ($code) ;
            }
        my $js = join (';', @switch_code) ;
        *]
        <td class="[+ $cellclass +]"><div class="ef-tabs-div [+ $divclass +]" 
              [$ if $i - $start_i == 0 $]style="border-left: black 1px solid" [$endif$]
              >[+ $options ->[$j] || $val +]
        </div></td>
        [* $i++ ;
           $j++ ;
           if ($i - $start_i >= $tabs && @$values > $j)
              {
              $more = 1 ;
              $start_i = $i ;
              last ;
              }
        *]
      [$endwhile $]
      [$if ($j == @$values) $]<td class="ef-tabs-cell-blank ef-tabs-view-all">&nbsp;</td>[$endif$]
      </tr></table>
    [$endwhile$]
    [#<input type="hidden" name="[+ $name +]" id="[+ $fullname +]" class="ef-field-tab_select" value="[+ $uid +]_[+ $activeid +]">#]
</div>
[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::tabs - A tab control inside an Embperl Form


=head1 SYNOPSIS

            Embperl::Form -> add_tabs (
                [
                    {
                    text => 'First Tab',
                    fields => [
                              ...
                              ]
                    },
                    {
                    text => 'Second Tab',
                    fields => [
                              ...
                              ]
                    }
                ])



=head1 DESCRIPTION

Control to display tabs at the top of the form and control the switching between sub forms.
The switching is done by Javascript, so it can only be used in environment where
Javascript is available.

You can use the method Embperl::Form -> add_tabs
to setup a tabbed form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER


=head3 text

Text that will be displayed on the tab

=head3 fields

List of fields that should be displayed in this subform.
Given in the same form as form Embperl::Form.


=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


