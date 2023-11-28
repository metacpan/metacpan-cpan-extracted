
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

package Embperl::Form::Control::inputlist ;

use strict ;
use base 'Embperl::Form::Control' ;

use Embperl::Inline ;

use vars qw{%fdat} ;

1 ;

__EMBPERL__
    
[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show_control ($self, $req) 

my $class     = $self -> {class} ;
my $fields     = $self -> {fields} ;
my $sep       = $self -> {separator} || $self -> {seperator};
$sep          ||= ' ';
my            $i = 0;
$]&nbsp;
[$ while ($i < @$fields) $][-
$size  = $fields->[$i]{size} ; $size ||=  $self->{size} ;
$style = $fields->[$i]{textstyle} ; $style ||=  $self->{textstyle} ;
-]<span class="ef-control-inputlist-text" style="[+ $style +]">[+ $self -> form -> convert_label ($self, $fields->[$i]{name}, undef, $req) +]</span> <input type="text" name="[+ $fields->[$i]{name} +]" [+ do { local $escmode = 0 ; $self -> get_std_control_attr($req) } +]
[$if $size $]size="[+ $size +]" maxlength="[+$size+]" [$endif$]
[+ do { local $escmode = 0 ; $self -> {eventattrs} } +]>[+ ($i +1) < @$fields?$sep:'' +]
[- $i++ -]
[$endwhile$]
[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::inputjoin - A number of text input controls inside an Embperl Form


=head1 SYNOPSIS

  { 
  type      => 'inputlist',
  text      => 'blabla', 
  name      => 'foo',
  size      => 10,
  class     => 'bar',
  separator => '.',
  sizes     => [2,4,5],
  }

=head1 DESCRIPTION

Used to create a number of input controls inside an Embperl Form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'inputlist'

=head3 name

Specifies the name of the control

=head3 text 

Will be used as label for the text input control

=head3 size

Gives the default size in characters

=head3 sizes

Gives the size in characters for each input field, this parameter has to be given as an array reference

=head3 class

Alternative CSS class name

=head3 values

Gives the names for each input field, this parameter has to be given as an array reference

=head3 separator

String to display between the input boxes

=head1 Author

H. Jung (jung@dev.ecos.de)

=head1 See Also

perl(1), Embperl, Embperl::Form


