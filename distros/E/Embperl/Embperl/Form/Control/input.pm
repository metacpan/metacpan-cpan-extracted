
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

package Embperl::Form::Control::input ;

use strict ;
use base 'Embperl::Form::Control' ;

use Embperl::Inline ;

1 ;

__EMBPERL__
    
[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show_control ($self, $req) 

#$self -> {size} ||= 80 / ($self -> {width} || 2) ;
my $class = $self -> {class} ;
$]
<input type="text" name="[+ $self -> {force_name} || $self -> {name} +]" [+ do { local $escmode = 0 ; $self -> get_std_control_attr($req) } +]
[$if $self -> {size} $]size="[+ $self->{size} +]"[$endif$]
[$if $self -> {maxlength} $]maxlength="[+ $self->{maxlength} +]"[$endif$]
>
[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::input - A text input control inside an Embperl Form


=head1 SYNOPSIS

  { 
  type      => 'input',
  text      => 'blabla', 
  name      => 'foo',
  size      => 10,
  maxlength => 50,
  }

=head1 DESCRIPTION

Used to create an input control inside an Embperl Form.
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

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


