# NAME

Geo::Address::Parser::Country - Resolve a place string component to a
canonical country name

# VERSION

Version 0.04

# SYNOPSIS

    use Geo::Address::Parser::Country;
    use Locale::US;
    use Locale::CA;
    use Locale::AU;

    my $resolver = Geo::Address::Parser::Country->new({
        us    => Locale::US->new(),
        ca_en => Locale::CA->new(lang => 'en'),
        ca_fr => Locale::CA->new(lang => 'fr'),
        au    => Locale::AU->new(),
    });

    # Simple form: component extracted automatically from place
    my $result = $resolver->resolve(
        place => 'Ramsgate, Kent, England',
    );

    # Explicit form: caller supplies the component directly
    my $result = $resolver->resolve(
        component => 'England',
        place     => 'Ramsgate, Kent, England',
    );

    # $result->{country}  eq 'United Kingdom'
    # $result->{place}    eq 'Ramsgate, Kent, England'
    # $result->{warnings} is []
    # $result->{unknown}  is 0

# DESCRIPTION

Resolves the last comma-separated component of a place string into a
canonical country name. Handles common variants, abbreviations, and
historical names found in genealogy data and other poorly-normalised
address sources.

Designed specifically to tolerate poor-quality data from software
imports where place strings may be inconsistent, abbreviated, or use
historical country names no longer in common use.

Resolution proceeds through the following steps in order:

- 1. Direct lookup table (covers historical names, abbreviations,
common variants)
- 2. US state code or name via Locale::US
- 3. Canadian province code or name via Locale::CA (English and French)
- 4. Australian state code or name via Locale::AU
- 5. Locale::Object::Country by name
- 6. Geo::GeoNames search (optional, only if object provided at
construction)
- 7. Unknown - returns with `unknown => 1`

# TODO

- Complete `normalise_place()` to handle missing commas before
country and state names in raw uncleaned input strings. Poor data
import means strings like `"Houston TX USA"` or
`"Some Place England"` need comma insertion before component
extraction can work correctly. This should be called before
`resolve()` for raw uncleaned input.

# METHODS

## new

### Purpose

Constructs a new resolver object. The locale objects are used for
state and province lookups and are retained for the lifetime of the
object.

### API Specification

#### Input

    {
        us    => { type => 'object' },  # Locale::US instance
        ca_en => { type => 'object' },  # Locale::CA English instance
        ca_fr => { type => 'object' },  # Locale::CA French instance
        au    => { type => 'object' },  # Locale::AU instance
        geonames => {                   # Optional Geo::GeoNames instance
            type     => 'object',
            optional => 1,
        },
    }

#### Output

    { type => 'object', isa => 'Geo::Address::Parser::Country' }

### Arguments

- `us` - A [Locale::US](https://metacpan.org/pod/Locale%3A%3AUS) instance. Required.
- `ca_en` - A [Locale::CA](https://metacpan.org/pod/Locale%3A%3ACA) instance with `lang => 'en'`. Required.
- `ca_fr` - A [Locale::CA](https://metacpan.org/pod/Locale%3A%3ACA) instance with `lang => 'fr'`. Required.
- `au` - A [Locale::AU](https://metacpan.org/pod/Locale%3A%3AAU) instance. Required.
- `geonames` - An optional [Geo::GeoNames](https://metacpan.org/pod/Geo%3A%3AGeoNames) instance used as a
last-resort fallback when all other resolution methods fail.

### Returns

A blessed `Geo::Address::Parser::Country` object.

### Side Effects

None.

### Notes

The locale objects are stored by reference and shared for all calls to
`resolve()`. Constructing them once and reusing the resolver object
is more efficient than constructing a new resolver for each lookup.

`Object::Configure` is used after validation to allow locale objects
to be supplied via environment variables or a config file rather than
always being passed explicitly.

### Example

    my $resolver = Geo::Address::Parser::Country->new({
        us    => Locale::US->new(),
        ca_en => Locale::CA->new(lang => 'en'),
        ca_fr => Locale::CA->new(lang => 'fr'),
        au    => Locale::AU->new(),
    });

## resolve

### Purpose

Resolves the last comma-separated component of a place string to a
canonical country name, and returns the (possibly modified) place
string alongside any warnings generated during resolution.

### API Specification

#### Input

    {
        place     => { type => 'string', min => 1 },           # required
        component => { type => 'string', min => 1, optional => 1 },
    }

#### Output

    {
        type   => 'hashref',
        schema => {
            country  => { type => 'string',   optional => 1 },
            place    => { type => 'string',   min => 1 },
            warnings => { type => 'arrayref' },
            unknown  => { type => 'boolean' },
        },
    }

### Arguments

- `place` - The full place string, e.g.
`"Ramsgate, Kent, England"`. Required. May be modified by appending a
country suffix where needed.
- `component` - The last comma-separated component of the place
string, e.g. `"England"`, `"TX"`, `"NSW"`. Optional. When absent,
`resolve()` extracts it automatically as the last comma-separated
token of `place`. When `place` contains no comma, the entire
`place` string is used as the component. Supplying `component`
explicitly is useful when the caller already has it available from a
structured data source.

### Returns

A hashref containing:

- `country` - The canonical country name as a string, e.g.
`"United Kingdom"`. `undef` if resolution failed.
- `place` - The full place string, possibly with a country
suffix appended (e.g. `", USA"`). Always returned even if unmodified.
- `warnings` - An arrayref of warning strings generated during
resolution. May be empty. The caller is responsible for acting on
these, e.g. by passing them to a `complain()` function.
- `unknown` - A boolean. True if the country could not be
resolved by any method.

### Side Effects

None. All warnings are returned to the caller rather than emitted
directly.

### Notes

Resolution order is: direct lookup, US state, Canadian province,
Australian state, Locale::Object::Country, GeoNames (if available).
The first successful match wins.

When a US state, Canadian province, or Australian state is recognised,
the appropriate country string (`", USA"`, `", Canada"`,
`", Australia"`) is appended to `place` if not already present.

### Example

    # Simple form - component extracted automatically
    my $result = $resolver->resolve(
        place => 'Houston, TX',
    );

    # Explicit form - component supplied by caller
    my $result = $resolver->resolve(
        component => 'TX',
        place     => 'Houston, TX',
    );

    # $result->{country}     eq 'United States'
    # $result->{place}       eq 'Houston, TX, USA'
    # $result->{warnings}[0] eq 'TX: assuming country is United States'
    # $result->{unknown}     is 0

## normalise\_place

### Purpose

Inserts missing commas into a raw, uncleaned place string so that
`resolve()` can reliably extract the last component. Raw input from
poor-quality data imports frequently omits the commas that separate
city, state, and country tokens.

### API Specification

#### Input

    {
        place => { type => 'string', min => 1 },
    }

#### Output

    {
        type   => 'hashref',
        schema => {
            place    => { type => 'string', min => 1 },
            warnings => { type => 'arrayref' },
        },
    }

### Arguments

- `place` - The raw place string to normalise, e.g.
`"Houston TX USA"` or `"Some Place England"`. Required.

### Returns

A hashref containing:

- `place` - The normalised place string with commas inserted
where they were missing, e.g. `"Houston, TX, USA"`. Always returned
even if no changes were made.
- `warnings` - An arrayref of warning strings generated during
normalisation, e.g. noting where commas were inserted. May be empty.

### Side Effects

None.

### Notes

This method is not yet fully implemented. It currently returns the
place string unchanged. Implementation requires scanning the token
sequence against the locale tables (US states, Canadian provinces,
Australian states, and the %DIRECT country table) to identify where
comma boundaries belong.

Call this method before `resolve()` when working with raw input that
may lack commas:

    my $norm   = $resolver->normalise_place(place => 'Houston TX USA');
    my $result = $resolver->resolve(place => $norm->{place});

### Example

    my $norm = $resolver->normalise_place(place => 'Some Place England');
    # $norm->{place}    eq 'Some Place, England'   (once implemented)
    # $norm->{warnings} contains a note about comma insertion

# AUTHOR

Nigel Horne `<njh@nigelhorne.com>`

# REPOSITORY

[https://github.com/nigelhorne/Geo-Address-Parser-Country](https://github.com/nigelhorne/Geo-Address-Parser-Country)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-geo-address-parser at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Address-Parser-Country](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Address-Parser-Country).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# BUGS

- `normalise_place()` is not yet implemented. It currently
returns the place string unchanged. See ["normalise\_place"](#normalise_place) for
details of the planned behaviour.
- The step 6 Australian state code lookup uses the raw,
un-normalised component as the hash key, making it case-sensitive
unlike steps 2-5. Lowercase codes such as `nsw` will not match.
A fix to apply `uc($component)` consistently is pending.
- `Geo::GeoNames` generates its query methods via `AUTOLOAD`,
so `can('search')` returns false at the Perl level even though
`$geonames->search(...)` works correctly at runtime. The
`can => 'search'` schema check has been commented out as a
temporary workaround pending a fix to `Geo::GeoNames` itself.

Please report additional bugs via the GitHub issue tracker:
[https://github.com/nigelhorne/Geo-Address-Parser-Country/issues](https://github.com/nigelhorne/Geo-Address-Parser-Country/issues)

# SEE ALSO

- [Test Dashboard](https://nigelhorne.github.io/Geo-Address-Parser-Country/coverage/)
- [Geo::Address::Parser](https://metacpan.org/pod/Geo%3A%3AAddress%3A%3AParser)
- [Locale::US](https://metacpan.org/pod/Locale%3A%3AUS)
- [Locale::CA](https://metacpan.org/pod/Locale%3A%3ACA)
- [Locale::AU](https://metacpan.org/pod/Locale%3A%3AAU)
- [Locale::Object::Country](https://metacpan.org/pod/Locale%3A%3AObject%3A%3ACountry)
- [Geo::GeoNames](https://metacpan.org/pod/Geo%3A%3AGeoNames)
- [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Params::Get](https://metacpan.org/pod/Params%3A%3AGet)
- [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict)
- [Return::Set](https://metacpan.org/pod/Return%3A%3ASet)

# LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to GPL2 licence terms.
If you use it, please let me know.
