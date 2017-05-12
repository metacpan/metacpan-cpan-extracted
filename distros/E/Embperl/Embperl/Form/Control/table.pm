
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

package Embperl::Form::Control::table ;

use strict ;
use base 'Embperl::Form::Control' ;

use Embperl::Inline ;

sub cellstyle { '' } ;

sub show 

    {
    my ($self, $req) = @_ ;
    
    my $name    = $self -> {name} ;
    my $data    = $Embperl::fdat{$name} ;
    $self -> show_table ($data, $req) ;
    }

1 ;

__EMBPERL__

[$ syntax EmbperlBlocks $]


[# ---------------------------------------------------------------------------
#
#   show_table_head
#]

[$ sub show_table_head ($self, $req) $] 

<table width="100%" id="_table_[+ $self->{id} +]">

[# --- heading columns --- #]
[- $i = 0 -]
<thead>
[$foreach $line (@{$self->{columns}}) $]
<tr style="background: white">
[$foreach $c (@$line) $]
<td colspan="[+ ref $c?$c -> [2] || 1:1 +]" class="[+$self -> {line2} || (@{$self->{columns}} > 1 && $i == 0)?'cGridLabelBox':'cControlBox'+]  cLdapReportColumnHead">[+ $showtext?(ref $c?$c -> [1] || $c -> [0]:$c):$self -> form -> convert_label ($self, undef, ref $c?$c -> [1]:$c, $req) +]</td>
[$endforeach$]
[- $i++ -]
</tr>
[$endforeach$]
</thead>
<tbody>
[$endsub $]


[# ---------------------------------------------------------------------------
#
#   show_table_foot
#]

[$ sub show_table_foot ($self) $] 

</tbody>
</table>
    
[$endsub $]

    

[# ---------------------------------------------------------------------------
#
#   show_table_row
#]

[$ sub show_table_row ($self, $r, $o, $dataprefix) $]

[-
#use Data::Dumper ;
#print STDERR "show_table_row  ", Dumper ($self, $r, $o, $dataprefix) ;
 
 -]


[- $i = 0 -]
[$foreach $line (@{$self->{columns}}) $]
[- $colnum = 0 -]
<tr style="background: white">
[$foreach $c (@$line) $][-
    $attr = ref $c?$c -> [0]:$c ;
    if (ref ($o) eq 'ARRAY')
        {
        $item = $o -> [$attr] ;    
        }
    else
        {
        foreach my $prefix (@$dataprefix)
            {
            last if ($prefix?($item = $o -> {$prefix}{$attr}):($item = $o -> {$attr}))
            }    
        }
    $item = ref $item?join ('; ',@$item):$item ;
    if ($filter = $c -> [6])
	{
	die "unknown filter '$filter'" if (!($filtercode = $self -> {filters}{$filter})) ;
	$item = &{$filtercode}($item, $c, $o, $epreq) ;
	}
    $id   = undef ;
    -]<td colspan="[+ ref $c?$c -> [2] || 1:1 +]" class="[# +$self -> {line2} || (@{$self->{columns}} > 1 && $i == 0)?'cGridLabelBox':'cControlBox'+ #] cLdapReportTd" style="[+ $self -> cellstyle ($item, $o, $r, $i, $attr) +]">
        [$ if $c -> [3] && ($item =~ /^&(.*?),(.*?),(.*)$/) $]
            [$ if $1 eq 'checkbox' $]<input type="checkbox" name="[+ $2 +]" value="[+ $3 +]">[$endif$]
            [$ if $1 eq 'radio' $]<input type="radio" name="[+ $2 +]" value="[+ $3 +]">[$endif$]
        [$else $][-
                $href = undef ;
                $link = $c -> [4] ;
                if (ref $link eq 'CODE')
                    {
                    $href = &$link ($o, $self) ;    
                    }
                elsif ($link)
                    {
                    $href = $o -> {$link} ;    
                    }
                $link = $c -> [7] ;
                if (ref $link eq 'CODE')
                    {
                    $id = &$link ($o, $self) ;    
                    }
             -][$ if ($href && $self->{use_ajax})
                $]<a href="#"  [$if ($id) $] id="[+ "$self->{name}_${attr}_$r" +]" [$endif$] onClick="$('#[+ $self->{use_ajax} +]').load ('[+ $href +]')">[+ ref $item?join ('; ',@$item):$item +]</a>
            [$elsif ($href)
                $]<a href="[+ do { local $escmode = 0 ; $href } +]" target="[+ $c -> [5] +]" [$if ($id) $]id="[+ "$self->{name}_${attr}_$r" +]"[$endif$]>[+ ref $item?join ('; ',@$item):$item +]</a>
            [$else
                $][+ ref $item?join ('; ',@$item):$item
            +][$endif$]
        [$endif$][$
        if ($id) $]<script>add_qtip($('[+ "#$self->{name}_${attr}_$r"+]'), '[+ $id +]')</script>[$endif$]
    </td>
[- $colnum++ -]
[$endforeach$]
[- $i++ -]
</tr>
[$endforeach$]
[$if $self -> {line2} $]
    [-
    $attr = $self -> {line2} ;
    if (ref ($o) eq 'ARRAY')
        {
        $item = $o -> [$attr] ;    
        }
    else
        {
        foreach my $prefix (@$dataprefix)
            {
            last if ($prefix?($item = $o -> {$prefix}{$attr}):($item = $o -> {$attr}))
            }    
        }
    $item = [$item] if (!ref $item) ;
    -]
    <tr>
    <td class="cControlBox" colspan="[+ scalar(@{$self->{columns}})+]">[+ join ('<br>', @$item) +]</td>
    </tr>
[$endif$]


[$endsub $]

    
[# ---------------------------------------------------------------------------
#
#   show_table - output the control
#]

[$ sub show_table ($self, $data, $req) 

    my $span = ($self->{width_percent})  ;
    my $showtext = $self -> {showtext} ;
    my $dataprefix = $self -> {dataprefix} || [''] ;
$]
<td class="cBase cTabTD" colspan="[+ $span +]">
[$if $self -> {text} $]
[# --- heading text --- #]
<table width="100%"><tr><td class="cLabelBox">
[+ $self -> {showtext}?($self->{text} || $self->{name}):$self -> form -> convert_label ($self, undef, undef, $req) +]<br>
</td></tr></table>
[$endif$]

[- $self -> show_table_head ($req)  -]

[# --- data --- #]
[- $r = 0 -]
[$foreach $o (@$data) $]
[- $self -> show_table_row ($r, $o, $dataprefix) -]
[- $r++ -]
[$endforeach$]
[- $self -> show_table_foot  -]
</td>

[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::table - A table which get data from array of arrays or array of hashs


=head1 SYNOPSIS

  { 
  type => 'table',
  text => 'blabla', 
  columns => [['foo', 'Foo item'], 'bar'],
  }

=head1 DESCRIPTION

Used as a base class to create an table control inside an Embperl Form.
See Embperl::Form on how to specify parameters.
In most cases you need to overwrite this class and call the method
show_table. show_table takes an arrayref of hashrefs or
arrayref of arrays as parameter
which is used as data to display.
In case you have this data directly in %fdat you can use this control
directly.

=head2 PARAMETER

=head3 type

Needs to be 'table'

=head3 text 

Will be used as label for the control

=head3 columns

Arraryref which contains an arrayrefs with definition of columns names.
Allows you to specify multiple rows per data entry. Column definition
is either the key name in the data hashref or an arrayref with the name in
the hash ref and the text to display as heading. Example:

    [
     [['email', 'E-Mail Address'], ['phone', 'Phone']],
     [['foo', 'Foo'], ['bar', 'Bar']],
    ]

email and phone will be display on the first line with headings
'E-Mail Address' and 'Phone' and foo and bar will be displayed
on the second line for each entry.
In case your data is an array of arrays you have to specifiy the
array index instead of the hash key name.

It is possible to add additional information. One entry might
contain the following entries:

=over

=item 0

Key for into data hashref

=item 1

Text to display

=item 2

Colspan (how many colums this cell should span)

=item 3

If set a control is displayed instead of a text. Must contain:

radio,<name>,<value> or checkbox,<name>,<value>

=item 4

Display as link. This item contains the name of the key in the data hashref
that holds the href.

=item 5

target for link

=item 6

Name of filter function. The value of the cell is process through this filter.
Filter functions are passed as hashref of subs in the parameter 'filters' .

=back

=head3 line2

Arrayref with names of which the values should concated and displayed
below each entry.

=head3 filters

Hashref of coderefs which contains filter functions. The following example
shows one filter called 'date' which passes the data through the perl
function format_date. The value is passed as first argument to the filter
function. The second argument is the column description (see above), 
the third argument is the row data and the last argument is the 
current Embperl request record.

  filters => 
	{
	'date' => sub
	    {
	    return format_date ($_[0]) ;
	    }
        }

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


