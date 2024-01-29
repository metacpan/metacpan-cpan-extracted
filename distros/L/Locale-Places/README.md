# NAME

Locale::Places - Translate places between different languages using http://download.geonames.org/

# VERSION

Version 0.09

# SYNOPSIS

Translates places between different languages, for example
London is Londres in French.

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
If no translation can be found, returns place in the original language.
Takes an optional argument 'country' which can be either GB (the default) or US
which is the country of that 'place' is in.

    use Locale::Places;

    # Prints "Douvres"
    print Locale::Places->new()->translate({ place => 'Dover', country => 'GB', from => 'en', to => 'fr' });

    # Prints "Douvres" if we're working on a French system
    print Locale::Places->new()->translate('Dover');

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Only supports places in GB and US at the moment.

Canterbury no longer translates to Cantorbéry in French.
This is a problem with the data, which has this line:

    16324587    2653877 fr      Canterbury      1

which overrides the translation by setting the 'isPreferredName' flag

# SEE ALSO

[Locale::Country::Multilingual](https://metacpan.org/pod/Locale%3A%3ACountry%3A%3AMultilingual) to translate country names.

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

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Locale::Places](http://deps.cpantesters.org/?module=Locale::Places)

- Geonames Discussion Group

    [https://groups.google.com/g/geonames](https://groups.google.com/g/geonames)

# LICENCE AND COPYRIGHT

Copyright 2020-2024 Nigel Horne.

This program is released under the following licence: GPL2

This product uses data from geonames, [http://download.geonames.org](http://download.geonames.org).
