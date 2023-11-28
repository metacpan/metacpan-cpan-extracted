
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2015 Gerald Richter
#   Embperl - Copyright (c) 2015-2023 actevy.io
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED 'AS IS' AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
###################################################################################
 


package Embperl::Recipe::XSLT ;

use strict ;
use vars qw{@ISA} ;

use Embperl::Recipe ;

no warnings "uninitialized" ;

@ISA = ('Embperl::Recipe') ;

# ---------------------------------------------------------------------------------
#
#   Create a new recipe by converting request parameter
#
# ---------------------------------------------------------------------------------


sub get_recipe

    {
    my ($class, $r, $recipe, $src) = @_ ;

    my $param  = $r -> component -> param  ;
    my $config = $r -> component -> config  ;
    my $xsltproc = $config -> xsltproc ;
    my @recipe ;

    my @stylesheet =
        (
        { type => 'file', 'filename'  => $config -> xsltstylesheet, },
        { type =>  $xsltproc . '-compile-xsl', cache => 1 },
        ) ;

    if (!$src)
        {
        push @recipe, {'type'   =>  ref ($param -> input)?'memory':'file' } ;
        }
    else
        {
        push @recipe, ref $src eq 'ARRAY'?@$src:$src ;
        }

    push @recipe, {'type'   =>  $xsltproc . '-parse-xml', } ;
    push @recipe, {'type'   =>  $xsltproc, stylesheet => \@stylesheet } ;

    return \@recipe ;
    }

1 ;


__END__

=pod

=head1 NAME

Embperl::Recipe::XSLT - recipe for performing an XSLT transformation

=head1 SYNOPSIS


=head1 DESCRIPTION

This recipe does an XSLT transformation.

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

L<Embperl::Recipe|EmbperlRecipe.pod>

L<Embperl::Recipe::EmbperlXSLT|EmbperlRecipe/XSLT.pod>
