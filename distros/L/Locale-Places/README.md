## Name

Locale::Places - Translate places between different languages using http://download.geonames.org/

## Version

Version 0.17

## Synopsis

Provides the functionality for translating place names between different languages using data from GeoNames.
It currently supports places in Great Britain (GB) and the United States (US) and relies on localized databases.
For example, London is Londres in French.

## Methods

### New

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

### Translate

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

```perl
# Prints "Douvres"
print Locale::Places->new()->translate({ place => 'Dover', country => 'GB', from => 'en', to => 'fr' });
```

#### Translation Resolution Order

- 1. Preferred names
- 2. Non-preferred names
- 3. Short names
- 4. Non-short names
- 5. Single-translation disambiguation
- 6. Identity fallback

#### Api Specification

##### Input

```perl
{
  'place' => { 'type' => 'string', 'min' => 2, 'max' => 64 },
  'from' => { 'type' => 'string', 'min' => 2, 'max' => 64, optional => 1 },
  'to' => { 'type' => 'string', 'min' => 2, 'max' => 64, optional => 1 },
  'country' => { 'type' => 'string', 'min' => 2, 'max' => 64, optional => 1 }
}
```

##### Output

Argument error: croak
No matches found: undef

```perl
{
  'type' => 'string',
  'min' => 1
}
```

### Autoload

Translate to the given language, where the routine's name will be the target language.

```perl
# Prints 'Virginie', since that's Virginia in French
print $places->fr({ place => 'Virginia', from => 'en', country => 'US' });
```

Extracts the target language from the method name and calls `translate()` internally.

Returns a string containing the translated name if found, or undef if no translation exists.

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Bugs

Only supports places in GB and the US at the moment.

Canterbury no longer translates to Cantorbéry in French.
This is a problem with the data, which has this line:

```
16324587    2653877 fr      Canterbury      1
```

which overrides the translation by setting the 'isPreferredName' flag

Can't specify below the country level.
For example, is Virginia a state, a town in Illinois or one in Minnesota?

## See Also

- [Test Coverage Report](https://nigelhorne.github.io/Locale-Places/coverage/)
- [Locale::Country::Multilingual](https://metacpan.org/pod/Locale%3A%3ACountry%3A%3AMultilingual) to translate country names.

## Support

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

```
perldoc Locale::Places
```

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

## Licence and Copyright

Copyright 2020-2026 Nigel Horne.

This program is released under the following licence: GPL2

This product uses data from Geonames, available at [http://download.geonames.org](http://download.geonames.org).
