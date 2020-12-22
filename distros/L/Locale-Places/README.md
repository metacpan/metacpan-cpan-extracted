[![Actions Status](https://github.com/nigelhorne/Locale-Places/workflows/.github/workflows/all.yml/badge.svg)](https://github.com/nigelhorne/Locale-Places/actions)

# NAME

Locale::Places - Translate places using http://download.geonames.org/

# VERSION

Version 0.02

# METHODS

## new

Create a Locale::Places object.

Takes one optional parameter, directory,
which tells the object where to find the file GB.csv.
If that parameter isn't given,
the module will attempt to find the databases,
but that can't be guaranteed.

## translate

Translate a city into a different language.
Takes two mandatory arguments 'place'
and 'from'.
Takes an optional argument 'to'.
If $to isn't given,
the code makes a best guess based on the environment.

    use Locale::Places;

    # Prints "Douvres"
    print Locale::Places->new()->translate({ place => 'Dover', from => 'en', to => 'fr' });

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Only supports towns and cities in GB at the moment.

# SEE ALSO

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Locale::Places

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/Locale-Places](https://metacpan.org/release/Locale-Places)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-Places](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-Places)

- CPANTS

    [http://cpants.cpanauthors.org/dist/Locale-Places](http://cpants.cpanauthors.org/dist/Locale-Places)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Locale-Places](http://matrix.cpantesters.org/?dist=Locale-Places)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Locale-Places](http://cpanratings.perl.org/d/Locale-Places)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Locale::Places](http://deps.cpantesters.org/?module=Locale::Places)

# LICENCE AND COPYRIGHT

Copyright 2020 Nigel Horne.

This program is released under the following licence: GPL2

This product uses data from geonames, [http://download.geonames.org](http://download.geonames.org).
