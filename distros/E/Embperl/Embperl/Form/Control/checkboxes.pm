
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

package Embperl::Form::Control::checkboxes ;

use strict ;
use vars qw{%fdat} ;
use base 'Embperl::Form::ControlMultValue' ;

use Embperl::Inline ;

# ---------------------------------------------------------------------------
#
#   show_control_readonly - output readonly control
#

sub show_control_readonly
    {
    my ($self, $req) = @_ ;

    my $name     = $self -> {name} ;
    my @values = split (/\t/, $fdat{$name}) ;
    $self -> show_control ($req, "^(?:" . join ('|', map { "\Q$_\E" } @values) . ")\$") ;
    }

# ---------------------------------------------------------------------------

sub show_control_addons
    {
    my ($self, $req) = @_ ;

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
    if (ref $fdat -> {$name})
        {
        $fdat -> {$name} = join ("\t", @{$fdat -> {$name}}) ;    
        }

    }
1 ;

__EMBPERL__

[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show_control ($self, $req, $filter)

    my $name     = $self -> {name} ;
    $filter      ||= $self -> {filter} ;
    my $val ;
    my $i = 0 ;
    my ($values, $options) = $self -> get_all_values ($req) ;
    my ($ctlattrs, $ctlid, $ctlname) =  $self -> get_std_control_attr($req) ;
    my $tab      = $self -> {tab} ;

$]
[$if $tab $]<[# #]table style="width: 100%">[$ endif $]
[* $i = 0 ; *]
[$ foreach $val (@$values) $]
    [$if !defined ($filter) || ($val =~ /$filter/i) $]
    [$ if $tab $][$ if $colcnt == 0 $]<[# #]tr>[- $colcnt = $tab -][$endif$]<td style="width: 3%">[$endif$] 
    <input type="checkbox" name="[+ $name +]" value="[+ $val +]" [+ do { local $escmode = 0 ; $ctlattrs } +]
    [$if ($self -> {trigger}) $]_ef_attach="ef_checkbox"[$endif$] >
    [$ if $tab $]</td><td style="width: [+ int((100 - ($tab * 3)) / $tab) +]%">[$endif$] 
    [+ $options ->[$i] || $val +]
    [- $vert = $self -> {vert} -][$while $vert-- > 0 $]<br/>[$endwhile$]
    [$ if $tab $]</td>[$ if $colcnt-- < 1 $]<[# #]/tr>[$endif$][$endif$] 
    [$endif$]
    [* $i++ ; *]
[$endforeach$]
[$if $tab $]<[# #]/table>[$ endif $]
[$endsub$]


[$ sub xxshow_control ($self, $req, $filter)

    my ($values, $options) = $self -> get_values ($req) ;
    my $name     = $self -> {name} ;
    $filter    ||= $self -> {filter} ;
    my $addtop   = $self -> {addtop} || [] ;
    my $addbottom= $self -> {addbottom} || [] ;
    my $max      = @$values ;
    my $set      = !defined ($fdat{$name})?1:0 ;
    my $tab      = $self -> {tab} ;
    my $colcnt   = 0 ;
    push @{$self -> form -> {fields2empty}}, $name ;

    my $val ;
    my $i = 0 ;
$]
[$if $tab $]<[# #]table width=100% style="width: 100%" >[$ endif $]
[$ foreach $val (@$addtop) $]
    [$if !defined ($filter) || ($val->[0] =~ /$filter/i) $]
    [$ if $tab $][$ if $colcnt == 0 $]<[# #]tr>[- $colcnt = $tab -][$endif$]<td>[$endif$] 
    [#- $fdat{$name} = $val -> [0], $set = 0 if ($set) ; -#]
    <input type="checkbox" name="[+ $name +]" value="[+ $val -> [0] +]"
    >
    [$ if $tab $]</td><td>[$endif$] 
    [+ $val ->[1] || $val -> [0] +]
    [$ if $tab $]</td>[$ if $colcnt-- < 1 $]<[# #]/tr>[$endif$][$endif$] 
    [$endif$]
[$endforeach$]
[$ foreach $val (@$values) $]
    [$if !defined ($filter) || ($val =~ /$filter/i) $]
    [$ if $tab $][$ if $colcnt == 0 $]<[# #]tr>[- $colcnt = $tab -][$endif$]<td>[$endif$] 
    [#- $fdat{$name} = $val, $set = 0 if ($set) ; -#]
    <input type="checkbox" name="[+ $name +]" value="[+ $val +]"
    [$if ($self -> {sublines} || $self -> {subobjects}) $] OnClick="show_checkboxes_checked(this,[+ $i +],[+ $max +])" [$endif$]
    >
    [$ if $tab $]</td><td>[$endif$] 
    [+ $options ->[$i] || $val +]
    [- $vert = $self -> {vert} -][$while $vert-- > 0 $]<br/>[$endwhile$]
    [$ if $tab $]</td>[$ if $colcnt-- < 1 $]<[# #]/tr>[$endif$][$endif$] 
    [$endif$]
    [* $i++ ; *]
[$endforeach$]
[$ foreach $val (@$addbottom) $]
    [$if !defined ($filter) || ($val->[0] =~ /$filter/i) $]
    [$ if $tab $][$ if $colcnt == 0 $]<[# #]tr>[- $colcnt = $tab -][$endif$]<td>[$endif$] 
    [#- $fdat{$name} = $val -> [0], $set = 0 if ($set) ; -#]
    <input type="checkbox" name="[+ $name +]" value="[+ $val -> [0] +]"
    >
    [$ if $tab $]</td><td>[$endif$] 
    [+ $val ->[1] || $val -> [0] +]
    [$ if $tab $]</td>[$ if $colcnt-- < 1 $]<[# #]/tr>[$endif$][$endif$] 
    [$endif$]
[$endforeach$]
[$if $tab $]<[# #]/table>[$ endif $]

[$endsub$]



__END__

=pod

=head1 NAME

Embperl::Form::Control::checkboxes - A multiple checkbox control inside an Embperl Form


=head1 SYNOPSIS

  {
  type    => 'checkboxes',
  text    => 'blabla',
  name    => 'foo',
  values  => [1,2,3],
  options => ['foo', 'bar', 'none'],
  }

=head1 DESCRIPTION

Used to create an checkboxes control inside an Embperl Form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'checkboxes'

=head3 name

Specifies the name of the checkboxes control

=head3 text

Will be used as label for the checkboxes control

=head3 values

Gives the values as an array ref of the checkboxes control.

=head3 options

Gives the options as an array ref that should be displayed to the user.
If no options are given, the values from values are used.

=head3 vert

If specified arranges the checkboxes button vertically. The number given specifies
the number of <br>'s used the separate the checkboxes buttons.

=head3 tab

if specified arranges the checkboxes in a table. The number given 
specifies the number of columns in one table row.

=head3 addtop

Array ref which contains items that should be added at the left or top
of the checkboxes buttons. Each item consists of an array ref with two
entries, the first is the value and the second is the option
that is displayed on the page. If the second is missing the
value (first entry)is displayed. Example:

    addtop => [ [1 => 'first item'], [2 => 'second item']]

=head3 addbottom

Array ref which contains items that should be added at the right or bottom
of the checkboxes buttons. Each item consists of an array ref with two
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


