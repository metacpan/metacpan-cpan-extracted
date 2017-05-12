package KinoSearch1::Util::IntMap;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

sub new {
    my ( $class, $map ) = @_;
    $class = ref($class) || $class;
    return bless $map, $class;
}

1;

__END__

__XS__

MODULE = KinoSearch1 PACKAGE = KinoSearch1::Util::IntMap

=for comment

Return either the remapped number, or undef if orig has been removed.

=cut

SV* 
get(int_map_ref, orig);
    SV  *int_map_ref;
    I32  orig;
PREINIT:
    I32 result;
CODE:
    result = Kino1_IntMap_get(int_map_ref, orig);
    RETVAL = result == -1 
        ? &PL_sv_undef
        : newSViv(result);
OUTPUT: RETVAL

__H__

#ifndef H_KINOSEARCH_INT_MAP
#define H_KINOSEARCH_INT_MAP 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

I32 Kino1_IntMap_get(SV*, I32);

#endif /* include guard */

__C__

#include "KinoSearch1UtilIntMap.h"

I32
Kino1_IntMap_get(SV* int_map_ref, I32 orig) {
    SV     *int_map_sv;
    I32    *map;
    STRLEN  len;
    
    int_map_sv = SvRV(int_map_ref);
    map = (I32*)SvPV(int_map_sv, len);
    if (orig * sizeof(I32) > len) {
        return -1;
    }
    return map[orig];
}

__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Util::IntMap - compact array of integers

==head1 DESCRIPTION

An IntMap is a C array of I32, stored in a scalar.  The get() method returns
either the number present at the index requested, or undef if either the index
is out of range or the number at the index is -1.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
