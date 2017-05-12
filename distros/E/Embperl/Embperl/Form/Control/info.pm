
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

package Embperl::Form::Control::info ;

use strict ;
use base 'Embperl::Form::Control' ;

use Embperl::Inline ;

1 ;

__EMBPERL__
    
[# ---------------------------------------------------------------------------
#
#   show - output the control
#]

[$ sub show ($self, $req)

my $span = ($self->{width_percent});
my $state   = $self -> {state} ;
$state =~ s/[^-a-zA-Z0-9_]/_/g ;
$]<table class="ef-element ef-element-width-[+ $self -> {width_percent} +][+ ' '+][+ $state +]">
  <tr>
<td [+ do { local $escmode = 0 ; $self -> get_std_control_attr($req, undef, 'readonly', 'ef-control-info') } +] >[$ if $self -> {image} $]<img class="cControlButtonSymbol" src="[+ $self -> {image} +]">[$endif$][+ $self -> {showtext}?($self->{text}):$self -> form -> convert_text ($self, undef, undef, $req) +]&nbsp;</td>
</tr>
  </table>[$endsub$]


__END__

=pod

=head1 NAME

Embperl::Form::Control::blank - A info area inside an Embperl Form


=head1 SYNOPSIS

  { 
  type => 'info',
  text => 'blabla',
  image => '/images/symbol.png'
  }

=head1 DESCRIPTION

Used to create a info area with optional text inside an Embperl Form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be 'info'

=head3 text (optional)

Could be used to give a text that should be displayed inside the blank area

=head3 image (optional)

Add image to start of info area

=head3 class

css class

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

perl(1), Embperl, Embperl::Form


