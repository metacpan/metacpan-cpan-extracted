package KinoSearch1::Util::StringHelper;

1;

__END__

__H__

#ifndef H_KINO_STRING_HELPER
#define H_KINO_STRING_HELPER 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "KinoSearch1UtilCarp.h"

I32 Kino1_StrHelp_string_diff(char*, char*, STRLEN, STRLEN);
I32 Kino1_StrHelp_compare_strings(char*, char*, STRLEN, STRLEN);
I32 Kino1_StrHelp_compare_svs(SV*, SV*);

#endif /* include guard */

__C__

#include "KinoSearch1UtilStringHelper.h"

/* return the number of bytes that two strings have in common */

I32
Kino1_StrHelp_string_diff(char *str1, char *str2, STRLEN len1, STRLEN len2) {
    STRLEN i, len;

    len = len1 <= len2 ? len1 : len2;

    for (i = 0; i < len; i++) {
        if (*str1++ != *str2++) 
            break;
    }
    return i;
}

/* memcmp, but with lengths for both pointers, not just one */
I32
Kino1_StrHelp_compare_strings(char *a, char *b, STRLEN a_len, STRLEN b_len) {
    STRLEN len;
    I32 comparison = 0;

    if (a == NULL  || b == NULL)
        Kino1_confess("Internal error: can't compare unallocated pointers");
    
    len = a_len < b_len? a_len : b_len;
    if (len > 0)
        comparison = memcmp(a, b, len);

    /* if a is a substring of b, it's less than b, so return a neg num */
    if (comparison == 0) 
        comparison = a_len - b_len;

    return comparison;
}

/* compare the PVs of two scalars */
I32
Kino1_StrHelp_compare_svs(SV *sva, SV *svb) {
    char   *a, *b;
    STRLEN  a_len, b_len;

    a = SvPV(sva, a_len);
    b = SvPV(svb, b_len);

    return Kino1_StrHelp_compare_strings(a, b, a_len, b_len);
}

__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Util::StringHelper - String related utilities

==head1 DESCRIPTION

String related utilities, e.g. string comparison functions.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
