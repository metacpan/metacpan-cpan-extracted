# NAME

Geo::Address::Parser - Lightweight country-aware address parser from flat text

# VERSION

Version 0.05

# METHODS

# SYNOPSIS

    use Geo::Address::Parser;

    my $parser = Geo::Address::Parser->new(country => 'US');

    my $result = $parser->parse("Mastick Senior Center, 1525 Bay St, Alameda, CA");

# DESCRIPTION

This module extracts address components from flat text input. It supports
lightweight parsing for the US, UK, Canada, Australia, and New Zealand, using
country-specific regular expressions.

The class can be configured at runtime using environments and configuration files,
for example,
setting `$ENV{'GEO__ADDRESS__PARSER__carp_on_warn'}` causes warnings to use [Carp](https://metacpan.org/pod/Carp).
For more information about runtime configuration,
see [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure).

## new(country => $code)

Creates a new parser for a specific country (US, UK, CA, AU, NZ).

### FORMAL SPECIFICATION

    [COUNTRY]

    GeoAddressParserNew
    ====================
    country? : COUNTRY
    supported : ℙ COUNTRY
    parser! : Parser

    supported = {US, UK, CA, AU, NZ}
    country? ∈ supported
    parser! = parserFor(country?)

## parse($text)

Parses a flat string and returns a hashref with the following fields:

- name
- street
- city
- region
- country

### FORMAL SPECIFICATION

    [TEXT, COUNTRY, FIELD, VALUE]

    GeoAddressParserState
    ======================
    country : COUNTRY
    parser : COUNTRY ↛ (TEXT ↛ FIELD ↛ VALUE)

    GeoAddressParserParse
    ======================
    ΔGeoAddressParserState
    text? : TEXT
    result! : FIELD ↛ VALUE

    text? ≠ ∅
    country ∈ dom parser
    result! = (parser(country))(text?)
    result!("country") = country

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-geo-address-parser at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Address-Parser](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Address-Parser).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

- [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure)

# LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
