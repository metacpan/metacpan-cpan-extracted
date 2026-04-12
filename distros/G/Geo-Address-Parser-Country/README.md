# NAME

Geo::Address::Parser::Country - Resolve a place string component to a
canonical country name

# VERSION

Version 0.02

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

- Add `normalise_place()` to handle missing commas before
country and state names in raw uncleaned input strings. Poor data
import means strings like `"Houston TX USA"` or
`"Some Place England"` need comma insertion before component
extraction can work correctly. This should be implemented before
relying on `resolve()` for raw uncleaned input.

# METHODS

## new

### Purpose

Constructs a new resolver object. The locale objects are used for
state and province lookups and are retained for the lifetime of the
object.

### API Specification

#### Input

    {
        us    => { type => 'object', can => 'new' },  # Locale::US instance
        ca_en => { type => 'object', can => 'new' },  # Locale::CA English instance
        ca_fr => { type => 'object', can => 'new' },  # Locale::CA French instance
        au    => { type => 'object', can => 'new' },  # Locale::AU instance
        geonames => {                                  # Optional Geo::GeoNames instance
            type     => 'object',
            can      => 'search',
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
        component => { type => 'string', min => 1 },
        place     => { type => 'string', min => 1 },
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

- `component` - The last comma-separated component of the place
string, e.g. `"England"`, `"TX"`, `"NSW"`. Required.
- `place` - The full place string, e.g.
`"Ramsgate, Kent, England"`. May be modified by appending a country
suffix where needed. Required.

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

    my $result = $resolver->resolve(
        component => 'TX',
        place     => 'Houston, TX',
    );

    # $result->{country}     eq 'United States'
    # $result->{place}       eq 'Houston, TX, USA'
    # $result->{warnings}[0] eq 'TX: assuming country is United States'
    # $result->{unknown}     is 0

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

- The direct lookup table contains `nl` as an abbreviation for the
Netherlands.  This conflicts with `NL`, the ISO 3166-2 code for the Canadian
province of Newfoundland and Labrador.  Because the direct table is consulted
before the `Locale::CA` province-code path, passing `component => 'NL'`
currently resolves to `Netherlands` rather than `Canada`.  The workaround
is to pass the full province name (`Newfoundland and Labrador`) or to ensure
the place string includes an explicit `Canada` suffix before calling
`resolve()`.
- `Geo::GeoNames` generates its query methods via `AUTOLOAD`, so
`can('search')` returns false at the Perl level even though
`$geonames->search(...)` works correctly at runtime.  The constructor
schema currently validates the optional `geonames` argument with
`can => 'search'`, which rejects a real `Geo::GeoNames` object.
Until this is resolved, pass a wrapper object that defines `search` as a
named method, or subclass `Geo::GeoNames` and add a stub:

        package My::GeoNames;
        use parent 'Geo::GeoNames';
        sub search { my $self = shift; $self->SUPER::search(@_) }

Please report additional bugs via the GitHub issue tracker:
[https://github.com/nigelhorne/Geo-Address-Parser-Country/issues](https://github.com/nigelhorne/Geo-Address-Parser-Country/issues)

# SEE ALSO

- [Geo::Address::Parser](https://metacpan.org/pod/Geo%3A%3AAddress%3A%3AParser)
- [Locale::US](https://metacpan.org/pod/Locale%3A%3AUS)
- [Locale::CA](https://metacpan.org/pod/Locale%3A%3ACA)
- [Locale::AU](https://metacpan.org/pod/Locale%3A%3AAU)
- [Locale::Object::Country](https://metacpan.org/pod/Locale%3A%3AObject%3A%3ACountry)
- [Geo::GeoNames](https://metacpan.org/pod/Geo%3A%3AGeoNames)
- [Params::Get](https://metacpan.org/pod/Params%3A%3AGet)
- [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict)
- [Return::Set](https://metacpan.org/pod/Return%3A%3ASet)

# LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
