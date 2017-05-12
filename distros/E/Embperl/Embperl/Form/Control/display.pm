
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

package Embperl::Form::Control::display ;

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
    my ($self, $req, $parentctrl) = @_ ;

    return if (!$self -> {value2text}) ;

    
    my $fdat    = $req -> {docdata} || \%fdat ;
    my $name    = $self->{name} ;
    my $value   = $fdat->{$name} ;

    my $val ;
    my $txt ;
    if (ref $value eq 'ARRAY')
        {
        foreach (@$value)
            {
            $val = $self -> {value2text} . $_ ;
            $txt = $self -> form -> convert_text ($self, $val, undef, $req) ;
            $_ = $txt if ($txt ne $val) ;
            }
        }
    else
        {
        $val = $self -> {value2text} . $value ;
        $txt = $self -> form -> convert_text ($self, $val, undef, $req) ;
        $fdat->{$name} = $txt if ($txt ne $val) ;
        }
    }

# ------------------------------------------------------------------------------------------


sub show_control_readonly  { $_[0] -> show_control ($_[1], $_[2]) }


1 ;

__EMBPERL__
    
[# ---------------------------------------------------------------------------
#
#   show_control - output the control
#]

[$ sub show_control ($self, $req, $value)
my $name = $self->{name};
my $id   = $self->{id};
$value = exists $self->{value} ? $self->{value} : $fdat{$name} if (!defined ($value)) ;
$value = [ split /\t/, $value ] if $self->{split};
$value = [ split /\n/, $value ] if $self->{splitlines};

$]<div [+ do { local $escmode = 0 ; $self -> get_std_control_attr($req, '', 'readonly') } +] _ef_divname="[+$name+]">[$ if ref $value eq 'ARRAY' $][$ foreach $v (@$value) $][+ $v +]<br />[$ endforeach
$][$ elsif ref $value eq 'HASH' $][$ foreach $k (keys %$value) $][+ $k +]: [+ $value->{$k} +]<br />[$ endforeach
$][$ elsif ref $value $]<em>[+ ref $value +]</em>[$ 
     else $][+ $value +][$ endif $]</div> 

[$ if $self->{hidden} $]
<input type="hidden" name="[+ $name +]" value="[+ $value +]">
[$endif$]
[$endsub$]

__END__

=pod

=head1 NAME

Embperl::Form::Control::display - A text display control inside an Embperl Form


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

Needs to be set to 'display'.

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

=head3 value2text

Will run the value prefixed with the given paramenter through convert_text,
so it can be translated.

=head1 Author

G. Richter (richter at embperl dot org), A. Beckert (beckert@ecos.de)

=head1 See Also

perl(1), Embperl, Embperl::Form


