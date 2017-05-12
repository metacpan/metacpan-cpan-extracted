**Format::Util** - Miscellaneous routines to do with manipulating on Numbers and Strings

[![Build Status](https://travis-ci.org/binary-com/perl-Format-Util.svg?branch=master)](https://travis-ci.org/binary-com/perl-Format-Util)
[![codecov](https://codecov.io/gh/binary-com/perl-Format-Util/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Format-Util)
[![Gitter chat](https://badges.gitter.im/binary-com/perl-Format-Util.png)](https://gitter.im/binary-com/perl-Format-Util)


**SYNOPSIS**

    use Format::Util::Strings qw( defang defang_lite set_selected_item )
    use Format::Util::Numbers qw( commas to_monetary_number_format roundnear )

**METHODS**


- **defang($string)**

    Removes potentially dangerous characters from input strings.

    You should probably be using Untaint.

- **defang_lite($string)**

    Removes potentially dangerous characters from input strings.

    You should probably be using Untaint.

    defang_lite is a lighter version that is not so restrictive as defang

- **set_selected_item($selecteditem,$optionlist)**

    Sets the selected item in an <option> list.

    Params  :

    - $selecteditem : the value of the item (usually taken from %input)

    - $optionlist : The option list, as either an HTML string or a hash ref.

    Returns : If hash ref given, 1 if selected item is set, false otherwise

    If HTML given, the altered HTML

- **commas($number, $decimal_point)**

    Produce a more human readbale number with a provided number of decimal points

    commas(12345.679, 1) => 12,345.7

- **to_monetary_number_format($number,$remove_decimal_for_ints)**

    Produce a nice human readable number which looks like a currency

    to_monetary_number_format(123456789) => 123,456,789.00

- **roundnear($target, $input)**

    Round a number near the precision of the supplied one.

    roundnear( 0.01, 12345.678) => 12345.68


**AUTHOR**

binary.com, C<< <rakesh at binary.com> >>

**SUPPORT**

You can find documentation for this module with the perldoc command.

    perldoc Math::Util::CalculatedValue


You can also look for information at:


RT: CPAN's request tracker (report bugs here)

<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Format-Util>

AnnoCPAN: Annotated CPAN documentation

<http://annocpan.org/dist/Format-Util>

CPAN Ratings

<http://cpanratings.perl.org/d/Format-Util>

Search CPAN

<http://search.cpan.org/dist/Format-Util/>

