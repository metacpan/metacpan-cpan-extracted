# SYNOPSIS

    use ICANN::gTLD;

    # get info about a specific gTLD
    my $gtld = ICANN::gTLD->get('org');

    printf(
        "The .%s gTLD is operated by %s and was delegated in %s.\n",
        ($gtld->uLabel || $gtld->gTLD)->name,
        $gtld->registryOperator,
        $gtld->delegationDate->year,
    );

    # get info about all gTLDs
    my @gtlds = ICANN::gTLD->get_all;

# INTRODUCTION

ICANN publishes a machine-readable database of information about generic
top-level domains (TLDs) on its website. This module provides access to that
database.

Note: a _generic_ TLD is a TLD like `.org` or `.机构` (`.xn--nqv7f`), as
distinguished from (a) _country-code_ TLDs such as `.uk` or `.台灣`
(`.xn--kpry57d`), (b) _"sponsored"_ TLDs (specifically `.gov`, `.mil` and
`.edu`), and (c) the special "infrastructure" TLD, `.arpa`.

# INTERNALS

`ICANN::gTLD` uses [Data::Mirror](https://metacpan.org/pod/Data%3A%3AMirror) to synchronise a local copy of the
database of gTLD information from the ICANN website. See the [Data::Mirror](https://metacpan.org/pod/Data%3A%3AMirror)
documentation to find out how to control its behaviour.

# GETTING TLD OBJECTS

    my $tld = ICANN::gTLD->get($name);

    my $tld = ICANN::gTLD->from_domain($name);

    my @all = ICANN::gTLD->get_all;

To get information about a specific gTLD, use `get()`. To get information
about the parent TLD of a domain name, use `from_domain()`. To get a list of
_all_ gTLDs, use `get_all()`.

# OBJECT METHODS

The methods listed below list the available data elements for each TLD. Note
that not all fields are available or applicable for all TLDs, so all of these
methods (except `gTLD()`) may return `undef`.

- `$gtld->gtld` - returns a [Net::DNS::DomainName](https://metacpan.org/pod/Net%3A%3ADNS%3A%3ADomainName) object
representing the gTLD's A-label (eg `org` or `xn--nqv7f`).
- `$gtld->u_label` - returns the U-label (eg `机构`) for an IDN
gTLD.
- `$gtld->registry_operator` - returns the legal name of the Registry
Operator.
- `$gtld->registry_operator_country_code` - returns the 2-character
ISO-3166 code in which the Registry Operator is based. _Note: as of writing,
this field is `null` for all entries in the data source, so this method will
always return `undef` until the data source includes these values._
- `$gtld->date_of_contract_signature` - returns a [DateTime](https://metacpan.org/pod/DateTime) object
corresponding to when the Registry Agreement between ICANN and the Registry
Operator was signed.
- `$gtld->delegation_date` - returns a [DateTime](https://metacpan.org/pod/DateTime) object
corresponding to when the TLD was delegated (if it has been, since new gTLDs
come along from time to time, otherwise `undef`).
- `$gtld->removal_date` - returns a [DateTime](https://metacpan.org/pod/DateTime) object
corresponding to when the TLD was removed from the root zone (if it has been,
otherwise `undef`).
- `$gtld->contract_terminated` - returns a [DateTime](https://metacpan.org/pod/DateTime) object
corresponding to when the Registry Agreement was terminated (if it has been,
otherwise `undef`).
- `$gtld->application_id` - returns the unique ID of the application
for the gTLD received by ICANN (if any).
- `$gtld->specification_13` - returns a boolean indicating whether
the Registry Agreement includes [an exemption from the Registry Operator Code of
Conduct](https://www.icann.org/en/blogs/details/new-gtld-registry-operator-code-of-conduct-12-6-2014-en),
which indicates that the gTLD is a "brand" TLD that is exclusively used by the
Registry Operator, or its affiliates.
- `$gtld->third_or_lower_level_registration` - returns a boolean
indicating whether the gTLD accepts registrations at the third-level or lower
(i.e. accepts registrations of the form `foo.bar.example` rather than
`foo-bar.example`).
- `$gtld->registry_class_domain_name_list` - returns a [URI](https://metacpan.org/pod/URI) object
where a CSV (Comma Separated Values) file containing the list of "registry class
domain names" (see [Section 3.1 of RFC
9022](https://www.rfc-editor.org/rfc/rfc9022.html#section-3.1)) may be found, if
available. `Data::Mirror->mirror_csv()` may be used to retrieve the
contents of this file.
- `$gtld->rdap_record` - returns a [Net::RDAP::Object::Domain](https://metacpan.org/pod/Net%3A%3ARDAP%3A%3AObject%3A%3ADomain)
object containing registration data for the TLD, obtained from the IANA RDAP
Service.
- `$gtld->rdap_server` - returns a [Net::RDAP::Service](https://metacpan.org/pod/Net%3A%3ARDAP%3A%3AService) object
that represents the gTLD's RDAP service, as specified in the RDAP DNS Bootstrap
Registry.

# COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Internet Corporation for Assigned Names
and Number (ICANN).

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.
