# NAME

Locale::Codes::Country::FR - French countries

# VERSION

Version 0.01

# SYNOPSIS

A sub-class of [Locale::Codes](https://metacpan.org/pod/Locale::Codes) which adds country names in French and
genders of the countries.

# SUBROUTINES/METHODS

## new

## en\_country2gender

Take a country and return 'M' and 'F'.

## country2fr

Given a country in English, translate into French.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Lots of countries to be done.

Gender exceptions aren't handled.

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

[<Locale::Codes](https://metacpan.org/pod/<Locale::Codes)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Locale::Codes::Country::FR

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-Codes-Country-FR](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-Codes-Country-FR)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Locale-Codes-Country-FR](http://cpanratings.perl.org/d/Locale-Codes-Country-FR)

- Search CPAN

    [http://search.cpan.org/dist/Locale-Codes-Country-FR/](http://search.cpan.org/dist/Locale-Codes-Country-FR/)

# LICENSE AND COPYRIGHT

Copyright 2019 Nigel Horne.

This program is released under the following licence: GPL2
