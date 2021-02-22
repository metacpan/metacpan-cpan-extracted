[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/4663014674766170/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/4663014674766170/heads/master/)

# NAME

Locale::Places - Translate places using http://download.geonames.org/

# VERSION

Version 0.04

# METHODS

## new

Create a Locale::Places object.

Takes one optional parameter, directory,
which tells the object where to find the file GB.sql
If that parameter isn't given,
the module will attempt to find the databases,
but that can't be guaranteed.
Any other options are passed to the underlying database driver.

## translate

Translate a city into a different language.
Takes one mandatory argument: 'place'.
It also takes two other arguments:
'from' and 'to',
at least one of which must be given.
If neither $to nor $from is given,
the code makes a best guess based on the environment.

    use Locale::Places;

    # Prints "Douvres"
    print Locale::Places->new()->translate({ place => 'Dover', from => 'en', to => 'fr' });

    # Prints "Douvres" if we're working on a French system
    print Locale::Places->new()->translate('Dover');

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

- GitHub

    [https://github.com/nigelhorne/Locale-Places](https://github.com/nigelhorne/Locale-Places)

- CPANTS

    [http://cpants.cpanauthors.org/dist/Locale-Places](http://cpants.cpanauthors.org/dist/Locale-Places)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Locale-Places](http://matrix.cpantesters.org/?dist=Locale-Places)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Locale-Places](http://cpanratings.perl.org/d/Locale-Places)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Locale::Places](http://deps.cpantesters.org/?module=Locale::Places)

# LICENCE AND COPYRIGHT

Copyright 2020-2021 Nigel Horne.

This program is released under the following licence: GPL2

This product uses data from geonames, [http://download.geonames.org](http://download.geonames.org).
