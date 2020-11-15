# NAME

Lingua::EN::NameCase - Correctly case a person's name from UPERCASE or lowcase

# VERSION

Version 0.70

# SYNOPSIS

    # Working with scalars; complementing lc and uc.

    use Lingua::EN::NameCase qw( nc );

    $FixedCasedName  = nc( $OriginalName );

    $FixedCasedName  = nc( \$OriginalName );

    # Working with arrays or array references.

    use Lingua::EN::NameCase 'NameCase';

    $FixedCasedName  = NameCase( $OriginalName );
    @FixedCasedNames = NameCase( @OriginalNames );

    $FixedCasedName  = NameCase( \$OriginalName );
    @FixedCasedNames = NameCase( \@OriginalNames );

    NameCase( \@OriginalNames ) ; # In-place.

    # NameCase will not change a scalar in-place, i.e.
    NameCase( \$OriginalName ) ; # WRONG: null operation.

    $Lingua::EN::NameCase::SPANISH = 1;
    # Now 'El' => 'El' instead of (default) Greek 'El' => 'el'.
    # Now 'La' => 'La' instead of (default) French 'La' => 'la'.

    $Lingua::EN::NameCase::HEBREW = 0;
    # Now 'Aharon BEN Amram Ha-Kohein' => 'Aharon Ben Amram Ha-Kohein'
    #   instead of (default) => 'Aharon ben Amram Ha-Kohein'.

    $Lingua::EN::NameCase::ROMAN = 0;
    # Now 'Li' => 'Li' instead of (default) 'Li' => 'LI'.

    $Lingua::EN::NameCase::POSTNOMINAL = 0;
    # Now 'PHD' => 'PhD' instead of (default) 'PHD' => 'Phd'.

# DESCRIPTION

Forenames and surnames are often stored either wholly in UPPERCASE
or wholly in lowercase. This module allows you to convert names into
the correct case where possible.

Although forenames and surnames are normally stored separately if they
do appear in a single string, whitespace separated, NameCase and nc deal
correctly with them.

NameCase currently correctly name cases names which include any of the
following:

    Mc, Mac, al, el, ap, da, de, delle, della, di, du, del, der,
    la, le, lo, van and von.

It correctly deals with names which contain apostrophes and hyphens too.

## EXAMPLE FIXES

    Original            Name Case
    --------            ---------
    KEITH               Keith
    LEIGH-WILLIAMS      Leigh-Williams
    MCCARTHY            McCarthy
    O'CALLAGHAN         O'Callaghan
    ST. JOHN            St. John

plus "son (daughter) of" etc. in various languages, e.g.:

    VON STREIT          von Streit
    VAN DYKE            van Dyke
    AP LLWYD DAFYDD     ap Llwyd Dafydd
    etc.

plus names with roman numerals (up to 89, LXXXIX), e.g.:

    henry viii          Henry VIII
    louis xiv           Louis XIV

# METHODS

- NameCase

    Takes a scalar, scalarref, array or arrayref, and changes the case of the
    contents, as appropriate. Essentially a wrapper around nc().

- nc

    Takes a scalar or scalarref, and change the case of the name in the
    corresponding string appropriately.

# BUGS

The module covers the rules that I know of. There are probably a lot
more rules, exceptions etc. for "Western"-style languages which could be
incorporated.

There are probably lots of exceptions and problems - but as a general
data 'cleaner' it may be all you need.

Use Kim Ryan's [Lingua::EN::NameParse](https://metacpan.org/pod/Lingua%3A%3AEN%3A%3ANameParse) for any really sophisticated name parsing.

# AUTHOR

    1998-2014    Mark Summerfield <summer@qtrac.eu>
    2014-present Barbie <barbie@cpan.org>

    2020- Maintained by Nigel Horne, C<< <njh at bandsman.co.uk> >>

# ACKNOWLEDGEMENTS

Thanks to Kim Ryan <kimaryan@ozemail.com.au> for his Mc/Mac solution.

# COPYRIGHT

Copyright (c) Mark Summerfield 1998-2014. All Rights Reserved.
Copyright (c) Barbie 2014-2015. All Rights Reserved.

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.
