
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
#   $Id: Embperl.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################


package Embperl::Recipe::Embperl ;

use strict ;
use vars qw{@ISA} ;

@ISA = ('Embperl::Recipe') ;

# ---------------------------------------------------------------------------------
#
#   Create a new recipe by converting request parameter
#
# ---------------------------------------------------------------------------------


sub get_recipe

    {
    my ($class, $r, $recipe, $src, $syntax) = @_ ;

    my $self ;
    my $param  = $r -> component -> param  ;
    my @recipe ;

    if (!$src)
        {
        push @recipe, {'type'   =>  ref ($param -> input)?'memory':($param -> subreq?'apoutfilter':'file') } ;
        }
    else
        {
        push @recipe, ref $src eq 'ARRAY'?@$src:$src ;
        }

    push @recipe, {'type'   =>  'epparse', $syntax?(syntax => $syntax):()   } ;
    push @recipe, {'type'   =>  'epcompile', cache => 1 } ;
    push @recipe, {'type'   =>  'eprun'     } if ($param -> import < 0) ;

    return \@recipe ;
    }

1;

__END__

=pod

=head1 NAME

Embperl::Recipe::Embperl - the default Embperl recipe

=head1 SYNOPSIS


=head1 DESCRIPTION

Defines the default recipe for Embperl.

=head1 Author

G. Richter (richter at embperl dot org)

=head1 See Also

L<Embperl::Recipe|EmbperlRecipe.pod>
