# NAME

Genealogy::Military::Branch - Extract military branch from free-text genealogy notes

# VERSION

Version 0.01

# SYNOPSIS

    use Genealogy::Military::Branch;

    my $detector = Genealogy::Military::Branch->new();

    my $branch = $detector->detect(
        text => 'He served in the Royal Navy from 1914 to 1918',
    );
    # Returns 'navy'

    my $branch = $detector->detect(
        text => 'Served with the RAF in Bomber Command',
    );
    # Returns 'RAF'

    my $branch = $detector->detect(
        text => 'Some unrelated text',
    );
    # Returns 'military'

# DESCRIPTION

Scans free-text military service notes from genealogy records and returns
the name of the military branch mentioned.  Returns `'military'` (localised)
when no specific branch is recognised.

Designed to replace the `service()` helper in the `gedcom` and `ged2site`
distributions, which contain duplicate implementations of the same logic.

Detection patterns cover British, US and Commonwealth branches.  The returned
string is localised to the system locale, which is detected from the
environment at construction time.

# METHODS

## new

### Purpose

Constructs a new branch detector object.

### API Specification

#### Input

    {
        language => {
            type     => 'string',
            optional => 1,
        },
        warn_on_error => {
            type     => 'boolean',
            optional => 1,
            default  => 0,
        },
    }

#### Output

    { type => 'object', isa => 'Genealogy::Military::Branch' }

### Arguments

- `language` - BCP-47 primary subtag e.g. `'en'`, `'fr'`, `'de'`.
If not given, the language is detected from the environment using
`I18N::LangTags::Detect` and the standard locale environment variables,
falling back to `'en'`.  Optional.
- `warn_on_error` - If true, `carp` is called when `detect()` is
called and no branch is identified in the supplied text.  Optional, defaults
to 0.

### Returns

A blessed `Genealogy::Military::Branch` object.

### Side Effects

None.

### Notes

The language is detected and cached once at construction time.

### Example

    my $detector = Genealogy::Military::Branch->new({
        language      => 'fr',
        warn_on_error => 1,
    });

## detect

### Purpose

Scans a free-text string for references to military branches and returns
the localised branch name.

### API Specification

#### Input

    {
        text => {
            type => 'string',
        },
    }

#### Output

    { type => 'string' }

### Arguments

- `text` - The free-text string to scan.  Required.  May be passed
positionally as a single string.

### Returns

A string containing the detected branch name, localised to the language
supplied at construction.  Returns `'military'` (or its localised
equivalent) when no branch is detected.  Never returns `undef`.

### Side Effects

If `warn_on_error` was set true at construction and no branch is detected,
emits a warning via `carp`.

### Notes

Detection patterns are tried in order of specificity.  The first pattern
to match wins, so `'Merchant Navy'` is correctly identified as
`'Merchant Navy'` rather than `'navy'`.

### Example

    # Named argument form
    my $branch = $detector->detect(
        text => 'He served in the Royal Engineers during the Great War',
    );
    # Returns 'Royal Engineers'

    # Positional form
    my $branch = $detector->detect('Private in the Infantry');
    # Returns 'army'

# AUTHOR

Nigel Horne `<njh@nigelhorne.com>`

# BUGS

Please report bugs via the GitHub issue tracker:
[https://github.com/nigelhorne/Genealogy-Military-Branch/issues](https://github.com/nigelhorne/Genealogy-Military-Branch/issues)

# TODO

- Add Australian, Canadian and other Commonwealth branch patterns
- Add more US-specific patterns (Space Force etc)
- Consider a companion `Genealogy::Military::Rank` module

# SEE ALSO

- [Test Dashboard](https://nigelhorne.github.io/Genealogy-Military-Branch/coverage/)
- [Genealogy::Occupation](https://metacpan.org/pod/Genealogy%3A%3AOccupation)
- [Params::Get](https://metacpan.org/pod/Params%3A%3AGet)
- [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict)
- [Return::Set](https://metacpan.org/pod/Return%3A%3ASet)

# LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the following licence: GPL2
If you use it, please let me know.
