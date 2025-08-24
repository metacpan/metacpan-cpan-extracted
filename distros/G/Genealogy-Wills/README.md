# NAME

Genealogy::Wills - Lookup in a database of wills

# VERSION

Version 0.10

# DESCRIPTION

This module provides a convenient interface to search through a database of historical wills,
primarily focused on the Kent Wills Transcript.
It handles database connections, caching, and result formatting.

\- Results are cached for 1 day by default
\- Database connections are lazy-loaded
\- Large result sets may consume significant memory

# SYNOPSIS

    # See https://freepages.rootsweb.com/~mrawson/genealogy/wills.html
    use Genealogy::Wills;
    my $wills = Genealogy::Wills->new();
    # ...

# SUBROUTINES/METHODS

## new

Creates a Genealogy::Wills object.

Takes three optional arguments,
which can be hash, hash-ref or key-value pairs.

- `config_file`

    Points to a configuration file which contains the parameters to `new()`.
    The file can be in any common format,
    including `YAML`, `XML`, and `INI`.
    This allows the parameters to be set at run time.

- `directory`

    That is the directory containing wills.sql.
    If not given, the use the module's data directory.

- `logger`

    An object to send log messages to

## search

Last (last name) is a mandatory parameter.

Return a list of hash references in list context,
or a hash reference in scalar context.

Each record includes a formatted `url` field.

    my $wills = Genealogy::Wills->new();

    # Returns an array of hashrefs
    my @smiths = $wills->search(last => 'Smith');       # You must at least define the last name to search for

    print $smiths[0]->{'first'}, "\n";

# FORMAL SPECIFICATION

    [NAME, URL, DIRECTORY]

    WillRecord == [
        first: NAME;
        last: NAME;
        url: URL;
        additional_fields: ℙ(NAME × seq CHAR)
    ]

    WillsDatabase == [
        directory: DIRECTORY;
        cache_duration: ℕ;
        logger: LOGGER
    ]

    SearchParams == [
        last: NAME;
        first: NAME;
        optional_params: ℙ(NAME × seq CHAR)
    ]

    │ last ≠ ∅  -- last name cannot be empty
    │ |last| > 0  -- last name must have positive length

    search: WillsDatabase × SearchParams → ℙ WillRecord

    ∀ db: WillsDatabase; params: SearchParams •
        params.last ≠ ∅ ⇒
        search(db, params) = {r: WillRecord | r.last = params.last ∧ matches(r, params)}

    ∀ db: WillsDatabase; params: SearchParams •
        params.last = ∅ ⇒
        search(db, params) = ∅

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

# SEE ALSO

The Kent Wills Transcript, [https://freepages.rootsweb.com/~mrawson/genealogy/wills.html](https://freepages.rootsweb.com/~mrawson/genealogy/wills.html)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Genealogy::Wills

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/Genealogy-Wills](https://metacpan.org/release/Genealogy-Wills)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Wills](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Wills)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Genealogy-Wills](http://matrix.cpantesters.org/?dist=Genealogy-Wills)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Genealogy::Wills](http://deps.cpantesters.org/?module=Genealogy::Wills)

# LICENSE AND COPYRIGHT

Copyright 2023-2025 Nigel Horne.

This program is released under the following licence: GPL2
