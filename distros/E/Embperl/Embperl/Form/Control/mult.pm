
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

package Embperl::Form::Control::mult ;

use strict ;
use base 'Embperl::Form::Control::grid' ;

use vars qw{%fdat $epreq} ;

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
    
    $self -> init ;
    
    return $self ;
    }

# ---------------------------------------------------------------------------
#
#   init - init the new control
#

sub init

    {
    my ($self) = @_ ;
    
    my $form = $self -> form ;
    $self -> {fields} ||= [$self -> {field}] ;
    $self -> {class}  ||= 'ef-control-mult' ;
    my $options = $form -> {options} ;
    $form -> new_controls ($self -> {fields}, $options, undef, undef, $options -> {masks}, $options -> {defaults}, 1) ;

    return $self ;
    }

# ------------------------------------------------------------------------------------------
#
#   init_data - daten aufteilen
#

sub init_data
    {
    my ($self, $req) = @_ ;
    
    my $fdat  = $req -> {docdata} || \%fdat ;
    my $name    = $self->{name} ;
    my @entries = ref $fdat->{$name} eq 'ARRAY'?@{$fdat->{$name}}:split("\t",$fdat->{$name});

    my $field = $self -> {fields}[0] ;    
    my $i = 0 ;
    foreach my $entry (@entries)
        {
        $fdat->{"__${name}__$i"} = $entry ;
        if ($field -> can ('init_data'))
            {
            local $field->{name} = "__${name}__$i" ;
            local $field -> {fullid} = "$self->{fullid}__$i" ;
            $field -> init_data ($req, $self)  ;
            }
            
        $i++ ;
        }
    $fdat->{"__${name}_max"} = $i?$i:1;
    }

# ------------------------------------------------------------------------------------------
#
#   prepare_fdat - daten zusammenfuehren
#

sub prepare_fdat
    {
    my ($self, $req) = @_ ;
    my $fdat  = $req -> {form} || \%fdat ;
    my $name    = $self->{name} ;
    my $max     = $fdat->{"__${name}_max"} || 1 ;

    my $field = $self -> {fields}[0] ;    
    my @rows;
    my $val ;
    for (my $i = 0; $i < $max; $i++)
        {
        if ((ref ($field) =~ /::/) && $field -> can ('prepare_fdat'))
            {
            local $field->{name} = "__${name}__$i" ;
            local $field -> {fullid} = "$self->{fullid}__$i" ;
            $field -> prepare_fdat ($req)  ;
            }

        $val = $fdat->{"__${name}__$i"} ;
        push @rows, $val if ($val ne '') ;
        }
    $fdat->{$name} = \@rows if (@rows > 1 || defined ($rows[0]) || $fdat->{"__${name}_max"} > 0) ;    

    foreach my $key (keys %$fdat)
        {
        delete $fdat->{$key} if ($key =~ /^__\Q$name\E__/) ;
        }
    }

# ------------------------------------------------------------------------------------------
#
#   get_display_text - returns the text that should be displayed
#

sub get_display_text
    {
    my ($self, $req, $value) = @_ ;

    my $field = $self -> {fields}[0] ;
    return if (!$field) ;
    
    return $field -> get_display_text ($req, $value) ;
    }

# ------------------------------------------------------------------------------------------

sub show 
    { 
    $_[0] -> {fullid} = $_[1] -> {uuid} . '_' . $_[0] -> {id} ;
    Embperl::Form::Control::show (@_) 
    }
    
#sub show_control_readonly { my $self = shift ; $self -> show_control (@_) }

1 ;

__EMBPERL__

[# ---------------------------------------------------------------------------
#
#   show - output the whole control including the label
#]

[$sub show ($self, $req) 

$fdat{$self -> {name}} = $self -> {default} if ($fdat{$self -> {name}} eq '' && exists ($self -> {default})) ;
my $span = 0 ;

$]<table class="ef-element ef-element-width-[+ $self -> {width_percent} +] ef-element-[+ $self -> {type} +] [+ $self -> {state} +]"
    [$     if (!$self -> is_readonly($req) ) $]_ef_attach="ef_mult"[$endif$] >
  <tr>
    [-
    $span += $self -> show_label_cell ($req, $span);
    $self -> show_control_cell ($req, $span) ;
    -]
  </tr>
  </table>[$  
 endsub $]

[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show_control ($self, $req)

    my $name     = $self -> {name} ;
    my $max    = $fdat{"__${name}_max"} ||= 1 ;

    my $span = ($self->{width_percent})  ;
    my $nsprefix = $self -> form -> {jsnamespace} ;
    my $jsname = $name ;
    $jsname =~ s/[^a-zA-Z0-9]/_/g ;
    $jsname .= 'Grid' ;
$]
[$     if ($max == 1 && $self -> is_readonly($req) ) $]
[-
        my $field = $self -> {fields}[0] ;    
        local $field -> {name} = "__${name}__0" ;
        $field -> show_control_readonly ($req) ;
-]
[$else$]

  [-
    $fdat{$name} = $self -> {default} if ($fdat{$name} eq '' && exists ($self -> {default})) ;
    my $span = 0 ;
  -]
  <div [+ do { local $escmode = 0 ; $self -> get_std_control_attr($req) } +]>
  <input type="hidden" class="ef-control-mult-max" name="__[+ $self -> {name} +]_max" >
  <table class="ef-control-mult-table" >
    [- $self -> show_grid_table ($req) ; -]
  </table>
  <table class="ef-control-mult-newrow" style="display: none">
    [-
    local $req -> {epf_no_script} = 1 ;
    $self -> show_grid_table_row ($req, '%row%') ;
    -]
  </table>
  </div>
[$endif$]  
[$endsub$]
  


[# ---------------------------------------------------------------------------
#
#    show_grid_table_row     Erzeugt eine Grid-Tabelle-Zeile
#]

[$ sub show_grid_table_row ($self, $req, $i) 

    $field = $self -> {fields}[0] ;
    $id     = $self -> {fullid};
    $name   = $self -> {name} ;
    my $jsname = $name ;
    $jsname =~ s/[^a-zA-Z0-9]/_/g ;
    $jsname .= 'Grid' ;
    my $ro = $self -> is_readonly ($req) ;
    $]

    <tr class="cGridRow" id="[+ "${id}_mult-row-$i" +]">

            <td class="[+ $self -> {class} +]Cell">
              [-
                local $field -> {name} = "__${name}__$i" ;
                if ($ro)
                    {
                    $field -> show_control_readonly ($req)
                    }
                else    
                    {
                    $field -> show_control ($req)
                    }
                -]
            </td>
    </tr>             
[$ endsub $]


[$ sub show_label_icon ($self)
    $name   = $self -> {name} ;
    my $jsname = $name ;
    $jsname =~ s/[^a-zA-Z0-9]/_/g ;
    $jsname .= 'Grid' ;
 
 
 $]
[$if (! $self -> is_readonly ($req)) $]
              <span class="ui-icon ui-icon-circle-plus ef-icon ef-control-mult-add" title="Zeile Hinzuf&uuml;gen"></span>
              <span class="ui-icon ui-icon-circle-minus ef-icon ef-control-mult-del" title="Zeile L&ouml;schen"></span>
              
[$endif$]              
[$endsub$]
             
[# ---------------------------------------------------------------------------
#
#    show_grid_table     Erzeugt eine Grid-Tabelle
#]

[$ sub show_grid_table ($self, $req) 
    my $name    = $self->{name} ;
    my $fields = $self -> {fields} ;
    my $id     = $self -> {fullid};
    my $i      = 0 ;
    my $max    = $fdat{"__${name}_max"} || 1 ;
    $]

    [* for ($i = 0; $i < $max ; $i++ ) { *]
        [- $self -> show_grid_table_row ($req, $i) ; -]
    [* } *]
    
[$endsub$]



__END__

=pod

=head1 NAME

Embperl::Form::Control::grid - A grid control inside an Embperl Form


=head1 SYNOPSIS


=head1 DESCRIPTION

Used to create a grid control inside an Embperl Form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'grid'

=head3 fields

Array ref with field definitions

=head3 header_bottom

If grid has more rows as given in this parameter,
a header line is also displayed at the bottom of the
grid. Default is 10. Set to -1 to always get a
header at the bottom.

=head2 Example

     {
     name => 'provider-path',
     text => 'Suchpfad',
     type => 'grid', 
     fields =>
        [
        { name => 'active', text => 'Aktiv', type => 'checkbox', width => '30' },
        { name => 'path',   text => 'Pfad' },
        ],
    },

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


