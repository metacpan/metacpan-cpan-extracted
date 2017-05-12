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

package Embperl::Form::Control::hidden ;

use strict ;
use base 'Embperl::Form::Control' ;

use Embperl::Inline ;

sub noframe { return 1; }

# ---------------------------------------------------------------------------
#
#   is_hidden - returns true if this is a hidden control
#

sub is_hidden

    {
    my ($self, $req) = @_ ;

    return  1 ;
    }

sub show_control { show (@_) ; }
sub show_control_readonly { show (@_) ; }


1 ;

__EMBPERL__

[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show ($self, $req)

my $name = $self->{name};
my $value = exists $self->{value} ? $self->{value} : $fdat{$name};

$]
<input type="hidden" name="[+ $name +]" value="[+ $value +]" id="[+ $self->{id} +]">
[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::hidden - A hidden form field control inside an Embperl Form


=head1 SYNOPSIS

  { 
  type   => 'hidden',
  name   => 'foo',
  }

=head1 DESCRIPTION

Used to create a hidden form field control inside an Embperl Form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be set to 'hidden'.

=head3 name 

Will be used as name for the hidden input field.

=head1 Author

G. Richter (richter at embperl dot org), A. Beckert (beckert@ecos.de)

=head1 See Also

perl(1), Embperl, Embperl::Form


