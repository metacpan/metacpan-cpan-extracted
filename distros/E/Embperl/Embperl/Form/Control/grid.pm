
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

package Embperl::Form::Control::grid ;

use strict ;
use base 'Embperl::Form::ControlMultValue' ;

use vars qw{%fdat $epreq} ;

use Embperl::Inline ;
use Data::Clone ;

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

    $self -> {header_bottom} = 10 if (!exists ($self -> {header_bottom})) ;
    $self -> {width} = 1 if (!$self -> {width}) ;
    
    my $flat   = $self -> {flatopt} ;
    my @flat   = split /\s*;\s*/, $flat ;
    # make sure we do not change another instance of this grid
    my $fields = $self -> {fields} = clone ($self -> {fields})  ;
    if (@flat)
        {
        foreach (@$fields)
            {
            my $name = $_ -> {name} ;
            for (my $i = 0 ; $i < @flat; $i+=3)
                {
                $_ -> {$flat[$i+1]} = $flat[$i+2] if ($name eq $flat[$i]);        
                }
            }
        }
    my $form = $self -> form ;
    my $options = $form -> {options} ;
    $form -> new_controls ($fields, $options, undef, undef, $options -> {masks}, $options -> {defaults}, 1) ;
    if ($self -> {line2})
        {
        my $ctl = [$self -> {line2}] ;
        $form -> new_controls ($ctl, $options, undef, undef, $options -> {masks}, $options -> {defaults}, 1)  ;
        $self -> {line2} = $ctl -> [0] ;
        }
        
    return $self ;
    }



# ------------------------------------------------------------------------------------------
#
#   init_data_hash
#

sub init_data_hash
    {
    my ($rowno, $fdat, $name, $fields) = @_ ;
    
    my $data ;
    map
        {
        $data = $fdat->{$name}{$_} ;
        my @data ;
        if (ref $data eq 'HASH')
            {
            $data -> {'_key'} = $_ ;    
            foreach (@$fields)
                {
                push @data, $data -> {$_ -> {name}} ;    
                }
            }
        elsif (ref $data eq 'ARRAY')
            {
            push @data, $_, @$data ;    
            }
        else
            {
            push @data, $_, $data ;    
            }
                    
        [$rowno++, @data ]
        } keys %{$fdat->{$name}} ;
    
    }

# ------------------------------------------------------------------------------------------
#
#   init_data - daten aufteilen
#

sub init_data
    {
    my ($self, $req) = @_ ;
    
    my $fdat  = $req -> {docdata} || \%fdat ;
    my $ldap    = $req->{ldap};
    my $name    = $self->{name} ;
    my $rowno   = 1 ;
    my $fields  = $self -> {fields} ;
    my @entries = ref $fdat->{$name} eq 'ARRAY'?@{$fdat->{$name}}:
                  ref $fdat->{$name} eq 'HASH' ?init_data_hash ($rowno, $fdat, $name, $fields):
                                                split("\t",$fdat->{$name});
    my $line2   = $self -> {line2} ;
    my $order   = $self -> {order} ;
    my $order_desc   = $self -> {order_desc} ;
    
    if ($order)
        {
        if ($order !~ /^\d+$/)
            {
            my $i = 1 ;        
            foreach (@$fields)
                {
                $order = $i if ($_ -> {name} eq $order) ;
                $i++ ;
                }
            }

        if ($order_desc)
            {
            @entries = sort { $b -> [$order] cmp $a -> [$order] } @entries ;
            }
        else
            {
            @entries = sort { $a -> [$order] cmp $b -> [$order] } @entries ;
            }
        }

    my $coloffset = defined ($self -> {coloffset})?$self -> {coloffset}:1 ;
    my $data;
    my $i = 0 ;
    my $j ;
    my $col ;
    my $colval ;
    my @rowclass ;
    foreach my $entry (@entries)
        {
        $data = ref $entry eq 'ARRAY'?$entry:[$ldap?ecos::LdapBase -> splitAttrValue($entry):$entry];
        if (ref $self -> {rowclass} eq 'CODE')
            {
            $rowclass[$i] = &{$self -> {rowclass}}($data, $self) ;
            }
        #my $co = $coloffset ;
        #shift @$data while ($co-- > 0) ;
        $j = 0 ;
        foreach my $field ((@$fields, ($line2?($line2):())))
            {
            $col = exists $field -> {col}?$field -> {col}:$j ;
            if ($colval = $field -> {colval})
                {
                $fdat->{"__${name}_${j}_$i"} = $data->[$col+$coloffset] =~ /\Q$colval\E/?1:0 ;
                }
            else
                {
                $fdat->{"__${name}_${j}_$i"} = $data->[$col+$coloffset] ;
                }
            
            if ($field -> can ('init_data'))
                {
                local $field->{name} = "__${name}_${j}_$i" ;
                local $field -> {fullid} = "$self->{fullid}_${j}_$i" ;
                local $field->{dataprefix} ;
                $field -> init_data ($req, $self)  ;
                }
            $j++ ;    
            }
        $i++ ;
        }
    $fdat->{"__${name}_max"} = $i?$i:1;
    $self -> {rowclasses} ||= \@rowclass ;
    }

# ------------------------------------------------------------------------------------------
#
#   init_markup
#

sub init_markup
    {
    my ($self, $req, $grid, $method) = @_ ;
    
    my $fdat  = $req -> {docdata} || \%fdat ;
    my $name    = $self->{name} ;
    my $i ;
    my $j ;
    my $max = $fdat->{"__${name}_max"} ;
    my $fields  = $self -> {fields} ;
    my $line2   = $self -> {line2} ;

    foreach $i (0..$max, '%row%')
        {
        $j = 0 ;
        foreach my $field ((@$fields, ($line2?($line2):())))
            {
            if ($field -> can ('init_markup'))
                {
                local $field->{name} = "__${name}_${j}_$i" ;
                local $field -> {fullid} = "$self->{fullid}_${j}_$i" ;
                local $field->{dataprefix} ;
                $field -> init_markup ($req, $self, 'show_control')  ;
                }
            $j++ ;    
            }
        }
    }

# ------------------------------------------------------------------------------------------
#
#   prepare_fdat_sub - wird aufgerufen nachdem die einzelen Controls abgearbeitet sind abd
#                   bevor die daten zusammenfuehrt werden
#

sub prepare_fdat_sub
    {
    my ($self, $req) = @_ ;
    
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
    my $ldap    = $req->{ldap};
    my $name    = $self->{name} ;
    return if (!exists $fdat->{"__${name}_max"}) ;

    my $fields  = $self -> {fields} ;
    my $line2   = $self -> {line2} ;
    my $max     = $fdat->{"__${name}_max"} ;

    my @rows;
    my $j ;
    my $i ;
    my $val ;
    my $col ;
    my $colval ;
    my %orders ;
    my $order ;
    for (my $i = 0; $i < $max; $i++)
        {
        my $ok = 0 ;
        my $j = 0 ;
        foreach my $field (@$fields, $line2?($line2):())
            {
            if ((ref ($field) =~ /::/) && $field -> can ('prepare_fdat'))
                {
                local $field->{name} = "__${name}_${j}_$i" ;
                local $field -> {fullid} = "$self->{fullid}_${j}_$i" ;
                local $field->{dataprefix} ;
                $field -> prepare_fdat ($req)  ;
                }
            $ok++ ;
            $j++ ;
            }
        
        next if (!$ok) ;

        $order = $fdat->{"__${name}_#row#_$i"} ;
        next if (!defined($order)) ;
        $order = $i + 10000 if (!defined($order)) ;
        $orders{$order} = $i ;
        }

    $self -> prepare_fdat_sub ($req) if ((ref ($self) =~ /::/));

    my $coloffset = defined ($self -> {coloffset})?$self -> {coloffset}:1 ;
    foreach my $order (sort { $a <=> $b } keys %orders)
        {
        $i = $orders{$order} ;
        $j = 0 ;
        my $empty = 1 ;
        my @data = $coloffset?($i+1):() ;
        foreach my $field (@$fields)
            {
            $col = exists $field -> {col}?$field -> {col}:$j ;
            if ($colval = $field -> {colval})
                {
                $data[$col+$coloffset] .= $colval if ($fdat->{"__${name}_${j}_$i"}) ;
                }
            else
                {
                $data[$col+$coloffset] = $fdat->{"__${name}_${j}_$i"} ;
                }
            $empty = 0 if ($data[$col+$coloffset] ne '') ;
            $j++ ;
            }
        $val = $ldap?ecos::LdapBase -> joinAttrValue(\@data):\@data ;
        push @rows, $val if (!$empty) ;    
        }
    if ($self -> {datatype} eq 'hash')
        {
        $fdat->{$name} = { map { ($_->[1] => $_->[2]) } @rows } ;
        }
    else
        {
        $fdat->{$name} = \@rows ;
        }
        
    foreach my $key (keys %$fdat)
        {
        delete $fdat->{$key} if ($key =~ /^__\Q$name\E_/) ;
        }

    }

# ------------------------------------------------------------------------------------------
#
#   get_display_text - returns the text that should be displayed
#

sub get_display_text
    {
    my ($self, $req, $value) = @_ ;
    
    return '' if (!ref $value) ;
    
    my $name       = $self -> {name} ;
    my $fields     = $self -> {'fields'};
    my $showfields = $req -> {'grid_gtf_' . $name} ;
    my $allfields  = $req -> {'grid_gta_' . $name} ;
    if (!$showfields)
        {
        my $fdat = $req -> {docdata} || \%Embperl::fdat ;
        my $max    = $fdat -> {"__${name}_max"}  ||= 0 ;
        my $flat   = $self -> {flat} ;
        my @flat   = split /\s*;\s*/, $flat ;
        my $i = 0 ;
        my @fields ;
        my %fields ;
        foreach my $field (@$fields)
            {
            $fields{$field -> {name}} = $i ;
            push @fields, $field -> {name} ;
            $i++ ;
            }
        @fields = @flat if (@flat) ;
        $req -> {'grid_gtf_' . $name} = $showfields = \@fields ;
        $req -> {'grid_gta_' . $name} = $allfields  = \%fields ;
        }
        
    my @data ;
    my $fieldname ;
    my $j ;
    my @row ;
    my $field ;
    my $text ;
    foreach $fieldname (@$showfields)
        {
        $j     = $allfields -> {$fieldname}  ;
        $field = $fields -> [$j] ;
        next if $field -> is_hidden ;
        $text = $field -> get_display_text ($req, $value -> [$j+1]) ; 
        push @row, $text if ($text ne '') ;
        }
    return join (', ', @row) ;
    }
1 ;

__EMBPERL__

[# ---------------------------------------------------------------------------
#
#   show_control_readonly - output readonly grid
#]

[$ sub xshow_control_readonly ($self, $req)

    my $name     = $self -> {name} ;
    my $max    = $fdat{"__${name}_max"}  ||= 0 ;

    my $flat   = $self -> {flat} ;
    my @flat   = split /\s*;\s*/, $flat ;
    my $fields = $self -> {'fields'};
    my $i = 0 ;
    my @fields ;
    my %fields ;
    foreach my $field (@$fields)
        {
        $fields{$field -> {name}} = $i ;
        push @fields, $field -> {name} ;
        $i++ ;
        }
    @fields = @flat if (@flat) ;

    my @data ;
    for ($i = 0; $i < $max ; $i++)
        {
        my $j ;
        my @row ;
        foreach $fieldname (@fields)
            {
            my $field = $fields -> [$fields{$fieldname}] ;
            next if $field -> is_hidden ;
            $j = $fields{$fieldname} ;
            if ($field -> {datasrcobj})
                {
                push @row, $field -> get_option_from_value ($fdat{"__${name}_${j}_$i"}, $req) ;
                }
            else
                {
                push @row, $fdat{"__${name}_${j}_$i"} ;
                }
            }
        push @data, join (' ', @row) if (grep /\S/, @row) ;
        }
    my $value = join (' / ', @data) ;    
    $]
<div [+ do { local $escmode = 0 ; $self -> get_std_control_attr($req, '', 'readonly') } +]>[+ $value +]</div>
[$endsub$]
  

[# ---------------------------------------------------------------------------
#
#   show - output the control
#]

[$ sub show ($self, $req)

    my $name     = $self -> {name} ;
    my $span = ($self->{width_percent})  ;
    my $nsprefix = $self -> form -> {jsnamespace} ;
    my $max    = $fdat{"__${name}_max"} ||= 1 ;
    $self -> {fullid} = $req -> {uuid} . '_' . $self -> {id} ;
$]<table class="ef-element ef-element-width-[+ $self -> {width_percent} +][+ ' ' +][+ $self -> {state} +]" _ef_attach="ef_grid">
  <tr>
  <td class="ui-label-box" colspan="[+ $span +]">
  [-
    $fdat{$name} = $self -> {default} if ($fdat{$name} eq '' && exists ($self -> {default})) ;
    my $span = 0 ;
    $self -> show_grid_title ($req);
  -]
  <input type="hidden" name="__[+ $self -> {name} +]_max" class="ef-control-grid-max">
  <table class="cGridTable cBase ef-control-grid-table [+ $self -> {state} +]" >
    [- $self -> show_grid_header ($req); -]
    [- $self -> show_grid_table ($req) ; -]
  </table>
  [- $self -> show_grid_title ($req)
            if ($max > $self -> {header_bottom} && !$self -> {disable_controls}) -]
  <table class="ef-control-grid-newrow" style="display: none">
    [-
    local $req -> {epf_no_script} = 1 ;
    $self -> show_grid_table_row ($req, '%row%') ;
    -]
  </table>
  </td>
  </tr>
  </table>
[$endsub$]
  

[# -----------------------------------------------------------------------------
#
#   show_grid_title - Zeigt den Titel der Tabelle an
#]

[$ sub show_grid_title ($self, $req)
$]
<table class="cBase cGridTitle [+ $self -> {state} +]">
  <tr class="cTableRow">
    <td class="cBase cGridLabelBox">[+ $self -> form -> convert_label ($self, undef, undef, $req) +]</td>
    [$if !($self -> is_readonly ($req))  && !$self -> {disable_controls} $]
    <td class="cBase cGridControlBox">
      <div>
      <span class="ui-icon ui-icon-circle-triangle-n ef-icon ef-control-grid-up" title="Zeile Hoch"></span>
      <span class="ui-icon ui-icon-circle-triangle-s ef-icon ef-control-grid-down" title="Zeile Runter"></span>
      <span class="ui-icon ui-icon-circle-plus ef-icon ef-control-grid-add" title="Zeile Hinzuf&uuml;gen"></span>
      <span class="ui-icon ui-icon-circle-minus ef-icon ef-control-grid-del" title="Markierte Zeile L&ouml;schen"></span>
      </div>
    </td>
    [$endif$]
  </tr>
</table>
[$ endsub $]
  
[# ---------------------------------------------------------------------------
#
#    show_grid_header    Erzeugt den Tabellenkopf
#]

[$ sub show_grid_header ($self, $req)

  my $fields = $self->{'fields'};
 $]
         <thead>
         <tr class="cGridHeader">
         [$ foreach my $field (@$fields) $]
            [* next if ($field -> is_hidden ) ; *]
            <td class="cGridHeader" style="[$if($width = $field->{width})$]width: [+$width+];[$endif$] [$if($width = $field->{min_width})$]min-width: [+$width+];[$endif$]" _colattr="[+ $field->{name} +]">[+ $self -> form -> convert_label ($self, $field->{name}, $field->{text}, $req) +]</td>
         [$ endforeach $]
         </tr>
         </thead>
[$ endsub $]

[# ---------------------------------------------------------------------------
#
#    show_grid_footer    Erzeugt den Tabellenfuß (Summenzeile)
#]

[$ sub show_grid_footer ($self, $req)

  my $fields = $self->{'fields'};
  my $name   = $self -> {name} ;
  my $i      = $fdat{"__${name}_footer"}  ;
  my $j      = 0 ;
 $]

 <tfoot>
         <tr class="cGridFooter">
         [$ foreach my $field (@$fields)  $]
            [* next if ($field -> is_hidden ) ; *]
            <td class="cGridFooter cGridCellReadonly">[-
                local $field -> {name}  = "__${name}_${j}_$i" ;
                local $field -> {state} = $field -> {state} . ' ' . $self -> {state} ;
                local $field -> {fullid} = "$self->{fullid}_${j}_$i" ;
                local $field->{dataprefix} ;
                $field -> show_control_readonly_array ($req) if (!$field -> {nofooter}) ; 
                $j++ ;
                -]</td>
         [$ endforeach $]
         </tr>
         </tfoot>
[$ endsub $]

[# ---------------------------------------------------------------------------
#
#    show_grid_table_row     Erzeugt eine Grid-Tabelle-Zeile
#]

[$ sub show_grid_table_row ($self, $req, $i) 

    my $fields = $self -> {fields} ;
    my $line2  = $self -> {line2} ;
    my $id     = $self -> {fullid};
    my $name   = $self -> {name} ;
    my $n      = 0 ;
    my $gridro = $self -> is_readonly ($req) ;
    my $ro ;
    my $j = 0 ;
    $]

    <tr class="cGridRow [+ $self -> {rowclasses}[$i] +]" id="[+ "$id-row-$i" +]">
        [$foreach $field (@$fields)$]
            [$if $field -> is_hidden $][-
                local $field -> {name}  = "__${name}_${j}_$i" ;
                local $field -> {state} = $self -> {state} ;
                local $field -> {fullid} = "${id}_${j}_$i" ;
                local $field->{dataprefix} ;
                $field -> show_control ($req) ;
                $j++ ;
            -][$else$]
            [- $ro = $gridro || $field -> is_readonly () ; -]
            <td class="[+ $ro?'cGridCellReadonly':'cGridCell' +]" style="[$if($width = $field->{width})$]width: [+$width+];[$endif$]">[$if $n++ == 0$]<input type="hidden" name="[+ "__${name}_#row#_$i" +]" value="[+ $i +]">[$endif$][-
                local $field -> {name}  = "__${name}_${j}_$i" ;
                local $field -> {state} = $self -> {state} ;
                local $field -> {fullid} = "${id}_${j}_$i" ;
                local $field->{dataprefix} ;
                if ($ro)
                    {
                    $field -> show_control_readonly_array ($req)
                    }
                else    
                    {
                    $field -> show_control ($req)
                    }
                $j++ ;
                -]</td>
            [$endif$]   
        [$endforeach$]     
    </tr>
    [$if $line2 $]
        [- $ro = $gridro || $line2 -> is_readonly ; -]
        [$if (!$ro || $fdat{"__${name}_${j}_$i"} !~ /^\s*$/) $]
        <tr class="cGridRow2" id="[+ "$id-row2-$i" +]">
            
            <td colspan="[+ scalar(@$fields) +]" class="[+ $ro?'cGridCellReadonly':'cGridCell' +]">[$if $n++ == 0$]<input type="hidden" name="[+ "__${name}_#row#_$i" +]" value="[+ $i +]">[$endif$][-
                local $line2 -> {name}  = "__${name}_${j}_$i" ;
                local $line2 -> {state} = $self -> {state} ;
                local $field -> {fullid} = "${id}_${j}_$i" ;
                local $field->{dataprefix} ;
                if ($ro)
                    {
                    $line2 -> show_control_readonly_array ($req)
                    }
                else    
                    {
                    $line2 -> show_control ($req)
                    }
                $j++ ;
                -]</td>
        </tr>
        [$endif$]
    [$endif$]
[$ endsub $]
             
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
    my $order  = $self -> {order_indices} ;
    $]

    <tbody>
    [* for ($i = 0; $i < $max ; $i++ ) { *]
        [- $self -> show_grid_table_row ($req, $order?$order -> [$i]:$i) ; -]
    [* } *]
    </tbody>
    
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

Array ref with field definitions. Should look like any normal field definition.

The following extra attributes are available:

=over

=item col

Column number inside the @data array, which should be used for this cell

=item colval

If given this value is added to the column. This allows one to have multiple
checkboxes all writing to the same column, each appending a character or
string if set.

=back

=head3 line2

field defintion wich is show in a second line, full width.

=head3  disable_controls

If true, controls for add, delete, up and down will not be shown

=head3 header_bottom

If grid has more rows as given in this parameter,
a header line is also displayed at the bottom of the
grid. Default is 10. Set to -1 to always get a
header at the bottom.

=head3 order

Number of column to use as sort key

=head3 order_desc

Sort descending

=head3 coloffset

Offset added to column number. Default: 1
If > 1, column number will set to the rownumber

=head3 flat

This can be used for readonly view of grid. Normaly readonly view will show
the content as one large string. The flat attribute can contain a semikolon
delimited list of fields that should be show in readony view. That allows
to selectivly show fields in readonly view. 
This can be used to show a readonly view of a grid inside of another grid.

=head3 flatopt

Semikolon delimited list of tripels that add special options for flat view:

<name of fields>;<option name>;<option value>


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


