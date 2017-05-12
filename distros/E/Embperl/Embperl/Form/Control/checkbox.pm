
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

package Embperl::Form::Control::checkbox ;

use strict ;
use vars qw{%fdat} ;

use base 'Embperl::Form::Control' ;

use Embperl::Inline ;


# ---------------------------------------------------------------------------
#
#   get_active_id - get the id of the value which is currently active
#

sub get_active_id

    {
    my ($self)   = @_ ;

    my $name     = $self -> {name} ;
    my $val      = $self -> {value} || 1 ;

    return $val eq $fdat{$name}?"$name-0":"$name-1" ;
    }


# ---------------------------------------------------------------------------
#
#   has_auto_label_size - returns true if label should be auto sized for this control
#

sub has_auto_label_size
    {
    return 0 ;
    }

# ------------------------------------------------------------------------------------------
#
#   init_data - daten aufteilen
#

sub init_data
    {
    my ($self, $req, $grid) = @_ ;
    
    return if (!$self -> is_readonly() && (!$grid || !$grid -> is_readonly())) ;
    
    my $val = $self -> get_value ($req) ;
    my $value      = $self -> {value} ;
    $value = 1 if ($value eq '') ;
    my $fdat       = $req -> {docdata} || \%Embperl::fdat ;
    $fdat -> {"_opt_$self->{name}"} = $value eq $val?'X':'-' ;
    }

# ---------------------------------------------------------------------------
#
#   show_control_readonly - output readonly control
#

sub show_control_readonly
    {
    my ($self, $req) = @_ ;

    my $name     = $self -> {name} ;
    my $val      = $self -> {value} ;
    $val = 1 if ($val eq '') ;

    local $self -> {force_name} = '_opt_' . $self -> {name} ;
    $self -> SUPER::show_control_readonly ($req, $fdat{$name} eq $val?'X':'-') ;
    }



1 ;

__EMBPERL__

[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show_control ($self, $req)

    my $name     = $self -> {name} ;
    my $val      = $self -> {value} || 1 ;
    my $nsprefix = $self -> form -> {jsnamespace} ;

    $val =~ s/%%%name%%%/$fdat{$name}/g ; 
    $val =~ s/%%(.+?)%%/$fdat{$1}/g ;

    my ($ctlattrs, $ctlid, $ctlname) =  $self -> get_std_control_attr($req) ;
    push @{$self -> form -> {fields2empty}}, $name ;
$]
<input type="checkbox"  name="[+ $ctlname +]" [+ do { local $escmode = 0 ; $ctlattrs } +] value="[+ $val +]"
[$if ($self -> {trigger}) $]_ef_attach="ef_checkbox"[$endif$]
>
[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::checkbox - A checkbox control inside an Embperl Form


=head1 SYNOPSIS

  {
  type  => 'checkbox',
  text  => 'blabla',
  name  => 'foo',
  value => 'bar'
  }

=head1 DESCRIPTION

Used to create an checkbox control inside an Embperl Form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'checkbox'

=head3 name

Specifies the name of the checkbox control

=head3 force_name

overwrites the name of the control. This is especially useful
inside grids, where you can force the name of all checkboxes 
in all rows to be the same name.

=head3 text

Will be used as label for the checkbox control

=head3 value

Gives the value for the checkbox.

%%<xx>%% is replaced by $fdat{<xx>}

%%%name%%% is replaced by $fdat{<name>}, where <name> is the value that
is given with name parameter. Is is especially useful inside of grids
where the actual name of the html control is computed dynamicly.

=head3 class

Extra css class

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


