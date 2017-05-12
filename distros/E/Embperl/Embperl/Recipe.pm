
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
#   $Id: Recipe.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################
 


package Embperl::Recipe ;

use strict ;
use vars qw{@ISA @EXPORT_OK %EXPORT_TAGS %Recipes} ;


# ---------------------------------------------------------------------------------
#
#   Get/create named recipe
#
# ---------------------------------------------------------------------------------


sub get_recipe

    {
    my ($r, $name) = @_ ;

    $r -> app -> get_recipe ($r, $name) ;
    }


# ---------------------------------------------------------------------------------
#
#   Execute
#
# ---------------------------------------------------------------------------------



sub Execute

    {
    my ($self) = @_ ;

    return Embperl::Execute ({recipe => $self}) ;
    }


1;


__END__        


=pod

=head1 NAME

Embperl::Recipe - base class for defining custom recipes

=head1 SYNOPSIS

   EMBPERL_RECIPE "XSLT Embperl"

=head1 DESCRIPTION

Embperl::Recipe provides basic features that are necessary for createing 
your own recipes.
To do so you have to create a class that provides a C<get_recipe> method which returns
a array reference that contains the description what to do.

=head2 get_recipe ($class, $r, $recipe)

=over 4

=item $class

The class name

=item $r

The Embperl request record object (Embperl::Req), maybe a derived
object when running under EmbperlObject.

=item $recipe

The name of the recipe

=back

The function must return an array that describes the desired action.
The array contains a tree structure of providers. 

=head2 Providers

=over 4


=item file

read file data

Parameter:

=over 4

=item filename

Gives the file to read

=back


=item memory

get data from a scalar

Parameter:

=over 4

=item source

Gives the source as a scalar reference

=item name

Gives the name under which this item should be cache

=back


=item epparse

parse file into a Embperl tree structure

Parameter:

=over 4

=item source

Gives the source 

=item syntax

Syntax to use

=back


=item epcompile

compile Embperl tree structure

Parameter:

=over 4

=item source

Gives the source 

=back


=item eprun

execute Embperl tree structure

Parameter:

=over 4

=item source

Gives the source 

=item cache_key

See description of cacheing

=item cache_key_options

See description of cacheing

=item cache_key_func

See description of cacheing

=back


=item eptostring

convert Embperl tree structure to string

Parameter:

=over 4

=item source

Gives the source 

=back


=item libxslt-parse-xml

parse xml source for libxslt

Parameter:

=over 4

=item source

Gives the xml source 

=back


=item libxslt-compile-xsl   

parse and compile stylesheet for libxslt

Parameter:

=over 4

=item stylesheet

Gives the stylesheet source 

=back


=item libxslt

do a xsl transformation via libxslt

Parameter:

=over 4

=item source

Gives the parsed xml source 

=item stylesheet

Gives the compiled stylesheet source 

=item param

Gives the parameters as hash ref

=back


=item xalan-parse-xml

parse xml source for xalan

Parameter:

=over 4

=item source

Gives the xml source 

=back



=item xalan-compile-xsl

parse and compile stylesheet for xalan

Parameter:

=over 4

=item stylesheet

Gives the stylesheet source 

=back


=item xalan

do a xsl transformation via xalan

Parameter:

=over 4

=item source

Gives the parsed xml source 

=item stylesheet

Gives the compiled stylesheet source 

=item param

Gives the parameters as hash ref

=back


=back

=head2 Cache parameter

=over 4

=item expires_in

=item expires_func

=item expires_filename

=item cache

=back


=head2 Format

Heres an example that show how the recipe must be build:

  sub get_recipe

    {
    my ($class, $r, $recipe) = @_ ;

    my $param  = $r -> component -> param  ;
    my @recipe ;

    push @recipe, {'type'   =>  'file'      } ;
    push @recipe, {'type'   =>  'epparse'   } ;
    push @recipe, {'type'   =>  'epcompile', cache => 1 } ;
    push @recipe, {'type'   =>  'eprun'     }  ;

    my $config = $r -> component -> config  ;
    my $xsltproc = $config -> xsltproc ;

    my @stylesheet =
        (
        { type => 'file',  filename  => $config -> xsltstylesheet, },
        { type =>  $xsltproc . '-compile-xsl', cache => 1 },
        ) ;


    push @recipe, {'type'   =>  'eptostring' } ;
    push @recipe, {'type'   =>  $xsltproc . '-parse-xml', } ;
    push @recipe, {'type'   =>  $xsltproc,   stylesheet => \@stylesheet } ;

    return \@recipe ;
    }

This corresponds to the following diagramm (when xsltproc = xalan):



    +-------------------+   +--------------------+           
    + file {inputfile}  +   +file{xsltstylesheet}+           
    +-------------------+   +--------------------+           
          |                         |                         
          v                         v                         
    +-------------------+   +-------------------+           
    + xalan-parse-xml   +   + xalan-compile-xsl +           
    +-------------------+   +-------------------+           
          |                         | 
          |                         |
          |         +-----------+   |
          +-------> + xalan     + <-+
                    +-----------+

Take a look at the recipes that comes with Embperl to get more
ideas what can be done.

