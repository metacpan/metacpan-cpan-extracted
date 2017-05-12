
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

package Embperl::Form::Control::dump ;

use strict ;
use base 'Embperl::Form::Control' ;

use Embperl::Inline ;
use Data::Dumper;
1 ;

__EMBPERL__
    
[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show_control ($self)

my $name = $self->{name};
my $value = exists $self->{value} ? $self->{value} : exists $fdat{$name} ? $fdat{$name} : \%fdat;

$]
<pre>[+ Dumper($value) +]</pre>
[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::dump - A debug control inside an Embperl Form


=head1 SYNOPSIS

  { 
  type   => 'dump',
  text   => 'blabla', 
  data   => $some_data_structure_to_be_displayed
  }

=head1 DESCRIPTION

Used to create a debug control inside an Embperl Form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be set to 'dump'.

=head3 text 

Will be used as label for the debug control.

=head3 data 

Some data structure to be displayed, e.g. hashref, arrayref or scalar.

=head1 Author

G. Richter (richter at embperl dot org), A. Beckert (beckert@ecos.de)

=head1 See Also

perl(1), Embperl, Embperl::Form


