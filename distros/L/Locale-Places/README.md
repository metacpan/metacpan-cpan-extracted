# NAME

Locale::Places - Translate places between different languages using http://download.geonames.org/

# VERSION

Version 0.15

# SYNOPSIS

Provides the functionality for translating place names between different languages using data from GeoNames.
It currently supports places in Great Britain (GB) and the United States (US) and relies on localized databases.
For example, London is Londres in French.

# METHODS

## new

Create a Locale::Places object.

Arguments:

Takes different argument formats (hash or positional)

- `cache`

    Place to store results.
    If none is given, the results will be stored in a temporary internal cache.

- `config_file`

    Points to a configuration file which contains the parameters to `new()`.
    The file can be in any common format,
    including `YAML`, `XML`, and `INI`.
    This allows the parameters to be set at run time.

- `directory`

    Tells the object where to find a directory called 'data' containing GB.sql and US.sql
    If that parameter isn't given,
    the module will attempt to find the databases,
    but that can't be guaranteed.

Any other options are passed to the underlying database driver.

## translate

Translate a city into a different language.

Parameters:
\- place (mandatory): The name of the place to translate.
\- from: The source language (optional; defaults to environment language).
\- to: The target language (mandatory).
\- country: The country where the place is located (optional; defaults to 'GB').

Returns:
\- Translated name if found, or undef if no translation exists.

Example:
    use Locale::Places;

    # Prints "Douvres"
    print Locale::Places->new()->translate({ place => 'Dover', country => 'GB', from => 'en', to => 'fr' });

## AUTOLOAD

Translate to the given language, where the routine's name will be the target language.

    # Prints 'Virginie', since that's Virginia in French
    print $places->fr({ place => 'Virginia', from => 'en', country => 'US' });

Extracts the target language from the method name and calls `translate()` internally.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Only supports places in GB and US at the moment.

Canterbury no longer translates to Cantorbéry in French.
This is a problem with the data, which has this line:

    16324587    2653877 fr      Canterbury      1

which overrides the translation by setting the 'isPreferredName' flag

Can't specify below the country level.
For example, is Virginia a state, a town in Illinois or one in Minnesota?

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

Copyright 2020-2025 Nigel Horne.

This program is released under the following licence: GPL2

This product uses data from geonames, [http://download.geonames.org](http://download.geonames.org).
