
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

package Embperl::Form::Control::inputjoin ;

use strict ;
use base 'Embperl::Form::Control' ;

use Embperl::Inline ;

use vars qw{%fdat} ;

# ------------------------------------------------------------------------------------------
#
#   init_data - daten aufteilen
#

sub init_data
    {
    my ($self, $req) = @_ ;
    
    my $fdat  = $req -> {docdata} || \%fdat ;
    my $name  = $self -> {name} ;
    my $split = $self -> {split} || $self -> {join} ;
    my $num   = $self -> {numinputs} || 1 ;
    my $i     = 0 ;
    my @vals  = split /$split/, $fdat->{$name} ;
    for (my $i = 0; $i < $num; $i++)
	{
	$fdat->{"$name-_-$i"} = $vals[$i] ;
	}
    }

# ------------------------------------------------------------------------------------------
#
#   prepare_fdat - daten zusammenfuehren
#

sub prepare_fdat
    {
    my ($self, $req) = @_ ;
    
    my $fdat  = $req -> {form} || \%fdat ;
    my $name  = $self -> {name} ;
    my $join  = $self -> {join} ;
    my $num   = $self -> {numinputs} || 1 ;
    my @vals ;
    for (my $i = 0; $i < $num; $i++)
	{
	push @vals, $fdat->{"$name-_-$i"} ;
	}
    $fdat->{$name} = join ($join, @vals) ;
    }



1 ;

__EMBPERL__
    
[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show_control ($self) 

my $class     = $self -> {class} ;
my $numinputs = $self -> {numinputs} ;
my $size      = $self -> {size} ||= 80 / ($self -> {width} || 2) / $numinputs ;
my $sep       = $self -> {separator} || ' ' ; 
my $i         = 0 ;
$]
[$ while ($i < $numinputs) $]
<input type="text"  class="cBase cControl [+ $class +]"  name="[+ $self->{name} +]-_-[+ $i +]"
[$if $size $]size="[+ $size +]"[$endif$]
[$if $self -> {maxlength} $]maxlength="[+ $self->{maxlength} +]"[$endif$]
[+ do { local $escmode = 0 ; $self -> {eventattrs} } +]>[+ $i + 1 < $numinputs?$sep:'' +]
[- $i++ -]
[$endwhile$]
[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::inputjoin - A number of text input controls inside an Embperl Form


=head1 SYNOPSIS

  { 
  type      => 'input',
  text      => 'blabla', 
  name      => 'foo',
  size      => 10,
  maxlength => 50,
  numinputs => 4
  }

=head1 DESCRIPTION

Used to create a number of input control inside an Embperl Form,
which contents are joined.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'input'

=head3 name

Specifies the name of the control

=head3 text 

Will be used as label for the text input control

=head3 size

Gives the size in characters

=head3 maxlength

Gives the maximum possible input length in characters

=head3 class

Alternative CSS class name

=head3 numinputs

Number of input boxes

=head3 join

Strings which is used to join the input fields

=head3 split

Regex which is used to split the data into the input fields.
Default is /join/

=head3 separator

String to display between the input boxes

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


