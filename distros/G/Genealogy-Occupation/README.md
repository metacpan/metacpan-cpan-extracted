# NAME

Genealogy::Occupation - Normalise and translate genealogical occupation strings

# VERSION

Version 0.02

# SYNOPSIS

    use Genealogy::Occupation;

    my $normaliser = Genealogy::Occupation->new();

    my @occupations = $normaliser->normalise(
        occupation => 'Ag Lab',
        sex        => 'M',
    );
    # Returns ('Agricultural Labourer')

    # Or pass an arrayref
    my @more = $normaliser->normalise(
        occupation => ['Ag Lab', 'Ag Lab', 'Retired'],
        sex        => 'M',
    );
    # Returns ('Agricultural Labourer') - deduplicated and filtered

# DESCRIPTION

Normalises occupation strings found in genealogical records, handling
common abbreviations, malformed entries, locale-specific spellings and
translations into French and German.

Designed to handle poor-quality data from genealogy software imports
where occupation strings may be abbreviated, inconsistent or use
archaic terminology.

Processing steps applied in order:

- 1. Filter out non-occupations (Scholar, Retired, Domestic Duties etc)
- 2. Normalise abbreviations and malformed entries to canonical forms
- 3. Deduplicate consecutive identical or equivalent entries (compared on pre-translation normalised forms)
- 4. Apply locale-specific spellings via `Lingua::EN::ABC`
- 5. Translate to French or German if system locale requires it

# METHODS

## new

### Purpose

Constructs a new normaliser object.

### API Specification

#### Input

    {
        warn_on_error => {
            type     => 'boolean',
            optional => 1,
            default  => 0,
        },
    }

#### Output

    { type => 'object', isa => 'Genealogy::Occupation' }

### Arguments

- `warn_on_error` - If true, unknown occupations that cannot be
translated will emit a warning via `carp` rather than silently falling
back to English. Optional, defaults to 0.

### Returns

A blessed `Genealogy::Occupation` object.

### Side Effects

None.

### Notes

The system locale is detected once at construction time and cached for
the lifetime of the object.

### Example

    my $normaliser = Genealogy::Occupation->new({
        warn_on_error => 1,
    });

## normalise

### Purpose

Normalises one or more occupation strings, applying filtering,
deduplication, abbreviation expansion, locale spelling and
translation in order.

### API Specification

#### Input

    {
        occupation => {
            type => ['string', 'arrayref'],
        },
        sex => {
            type     => 'string',
            optional => 1,
            memberof => ['M', 'F'],
        },
    }

#### Output

    {
        type         => 'arrayref',
        element_type => 'string',
    }

### Arguments

- `occupation` - A single occupation string or an arrayref of
occupation strings. Required.
- `sex` - The sex of the person, `'M'` or `'F'`. Optional
but required for correct gendered translations in French and German.
Defaults to `'M'` if not provided when a gendered translation is
needed.

### Returns

An arrayref of normalised occupation strings. May be empty if all
occupations were filtered out.

### Side Effects

If `warn_on_error` was set at construction and an occupation cannot
be translated, emits a warning via `carp`.

### Notes

Deduplication operates across the full list of occupations passed in.
Processing a single occupation at a time will not deduplicate across
multiple calls.

Deduplication compares the pre-translation normalised English forms, not
the translated output.  This means two consecutive identical English
occupations correctly collapse to one entry even in French or German
locales, where the translated results stored in the output array would
otherwise never match the incoming English string.

### Example

    my $result = $normaliser->normalise(
        occupation => ['Ag Lab', 'Ag Lab', 'Retired'],
        sex        => 'M',
    );
    # Returns ['Agricultural Labourer']

    my $result = $normaliser->normalise(
        occupation => 'Platelayer Railway',
    );
    # Returns ['Railway Platelayer']

# AUTHOR

Nigel Horne `<njh@bandsman.co.uk>`

# BUGS

Please report bugs via the GitHub issue tracker:
[https://github.com/nigelhorne/Genealogy-Occupation/issues](https://github.com/nigelhorne/Genealogy-Occupation/issues)

# TODO

- Expand French and German translation tables
- Add support for additional languages
- Add `normalise_place()` equivalent for occupation place strings

# SEE ALSO

- [Test Dashboard](https://nigelhorne.github.io/Genealogy-Occupation/coverage/)
- [Lingua::EN::ABC](https://metacpan.org/pod/Lingua%3A%3AEN%3A%3AABC)
- [Params::Get](https://metacpan.org/pod/Params%3A%3AGet)
- [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict)
- [Return::Set](https://metacpan.org/pod/Return%3A%3ASet)

# LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the following licence: GPL2
If you use it, please let me know.
