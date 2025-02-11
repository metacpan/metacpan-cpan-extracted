# NAME

Locale::Codes::Country::FR - French countries

# VERSION

Version 0.02

# SYNOPSIS

DO NOT USE YET - THIS IS STILL P.O.C. code.

`Locale::Codes::Country::FR` is a Perl module that extends [Locale::Codes::Country](https://metacpan.org/pod/Locale%3A%3ACodes%3A%3ACountry) by adding French translations of country names and determining their grammatical gender based on naming conventions.
It provides an easy-to-use interface for converting English country names into French and classifying them as masculine or feminine.
The module supports both object-oriented and procedural usage.
This module will be useful for applications requiring localized country names and gender classification in French.

# SUBROUTINES/METHODS

## new

Creates a Locale::Codes::Country::FR object.

## en\_country2gender

Take a country (in English) and return 'M' and 'F'.
Can be used in OO or procedural mode.

## country2fr

Given a country in English, translate into French.
Can be used in OO or procedural mode.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Please report any bugs or feature requests to the author.
This module is provided as-is without any warranty.

Lots of countries to be done.
This initial release is a POC.
While it covers a basic set of country names,
future improvements may include handling gender exceptions and expanding the dataset.

Gender exceptions aren't handled fully.

Please report any bugs or feature requests to `bug-locale-codes-country at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Locale-Codes-Country-FR](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Locale-Codes-Country-FR).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

params() returns a ref which means that calling routines can change the hash
for other routines.
Take a local copy before making amendments to the table if you don't want unexpected
things to happen.

# SEE ALSO

[Locale::Codes](https://metacpan.org/pod/Locale%3A%3ACodes)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Locale::Codes::Country::FR

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-Codes-Country-FR](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-Codes-Country-FR)

- Search CPAN

    [http://search.cpan.org/dist/Locale-Codes-Country-FR/](http://search.cpan.org/dist/Locale-Codes-Country-FR/)

# LICENSE AND COPYRIGHT

Copyright 2019-2025 Nigel Horne.

This program is released under the following licence: GPL2
