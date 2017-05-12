
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

package Embperl::Form::Control::show ;

use strict ;
use base 'Embperl::Form::Control' ;

use Embperl::Inline ;

1 ;

__EMBPERL__
    
[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show_control ($self, $req, $value)

my $name    = $self->{name};
my $value   = exists $self->{value} ? $self->{value} : $fdat{$name};

$value = int($value) if ($self -> {int}) ;
$value = $value?1:0 if ($self -> {bool}) ;

my $options = $value ;
$options = [ split /\t/, $value ] if $self->{split};
$options = [ split /\n/, $value ] if $self->{splitlines};
$options = [$options] if (!ref $options) ;

$options = $self -> form -> convert_options ($self, $options, $options, $req) 
           if (ref $options eq 'ARRAY' && !$self -> {showoptions}) ;

$][$ if ref $options eq 'ARRAY' $][- $n = @$options -][$ foreach $v (@$options) $][+ $v +][$ if $n-- > 1 $]<br />[$endif$][$ endforeach
$][$ elsif ref $value eq 'HASH' $][$ foreach $k (keys %$value) $][+ $k +]: [+ $value->{$k} +]<br />[$ endforeach
$][$ elsif ref $value $]<em>[+ ref $value +]</em>[$ 
     else $][+ $value +][$ endif $] 

[$ if $self->{hidden} $]
<input type="hidden" name="[+ $name +]" value="[+ $value +]">
[$endif$]
[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::show - A text display control inside an Embperl Form


=head1 SYNOPSIS

  { 
  type   => 'display',
  text   => 'blabla', 
  hidden => 1,
  name   => 'foo',
  split  => 1
  }

=head1 DESCRIPTION

Used to create a display only control inside an Embperl Form.
See Embperl::Form on how to specify parameters.

=head2 PARAMETER

=head3 type

Needs to be set to 'show'.

=head3 text 

Will be used as label for the text display control.

=head3 value

value to display. If not given $fdat{<name>} will be used. 
If the data given within value is an arrayref, every element will be displayed
on a separate line.

=head3 hidden 

If set, an appropriate hidden input field will be created
automatically.

=head3 name 

Will be used as name for the hidden input field.

=head3 split 

Splits the value into an array at \t if set and displays every array element
on a new line.

=head3 splitlines

Splits the value into an array at \n if set and displays every array element
on a new line.

=head1 Author

G. Richter (richter at embperl dot org), A. Beckert (beckert@ecos.de)

=head1 See Also

perl(1), Embperl, Embperl::Form


