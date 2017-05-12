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

package Embperl::Form::Control::scriptcode ;

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



1 ;

__EMBPERL__

[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show ($self, $req)

my $name = $self -> {name};
my $type = $self -> {scripttype} || 'text/javascript' ;

$]
<script type="[+ $type +]">
//<!--
[+ do { local $escmode = 0 ; $self -> {code} } +]
//-->
</script>
[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::scriptcode - A control to add script code to an Embperl Form


=head1 SYNOPSIS

  { 
  type   => 'scriptcode',
  code   => 'function onEvent { .... }',
  }

=head1 DESCRIPTION

Used to create a script code blockinside an Embperl Form.
The code block is added to the end of the form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be set to 'scriptcode'.

=head3 name 

optional

=head3 scripttype

Type of script code. Default: text/javascript

=head3 code

The actual script code. 


=head1 Author

G. Richter (richter at embperl dot org), A. Beckert (beckert@ecos.de)

=head1 See Also

perl(1), Embperl, Embperl::Form


