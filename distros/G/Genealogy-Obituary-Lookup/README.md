Genealogy::Obituary::Lookup
===========================

[![Appveyor status](https://ci.appveyor.com/api/projects/status/w2kcdehjtofvt55t?svg=true)](https://ci.appveyor.com/project/nigelhorne/genealogy-obituarydailytimes)
[![CPAN](https://img.shields.io/cpan/v/Genealogy-Obituary-Lookup.svg)](http://search.cpan.org/~nhorne/Genealogy-Obituary-Lookup/)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/nigelhorne/genealogy-obituarydailytimes/test.yml?branch=master)
[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/7086407966497872/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/7086407966497872/heads/master/)
[![Kwalitee](https://cpants.cpanauthors.org/dist/Genealogy-Obituary-Lookup.png)](http://cpants.cpanauthors.org/dist/Genealogy-Obituary-Lookup)
[![Travis Status](https://www.travis-ci.com/nigelhorne/Genealogy-Obituary-Lookup.svg?branch=master)](https://www.travis-ci.com/nigelhorne/Genealogy-Obituary-Lookup)
[![Tweet](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://twitter.com/intent/tweet?text=Look+up+an+obituary+#perl+#gedcom+#genealogy&url=https://github.com/nigelhorne/Genealogy-Obituary-Lookup&via=nigelhorne)

# NAME

Genealogy::Obituary::Lookup - Lookup an obituary

# VERSION

Version 0.18

# SYNOPSIS

Looks up obituaries

    use Genealogy::Obituary::Lookup;
    my $info = Genealogy::Obituary::Lookup->new();
    # ...

# SUBROUTINES/METHODS

## new

Creates a Genealogy::Obituary::Lookup object.

    my $obits = Genealogy::Obituary::Lookup->new();

Accepts the following optional arguments:

- `cache` - Passed to [Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction)
- `config_file`

    Points to a configuration file which contains the parameters to `new()`.
    The file can be in any common format including `YAML`, `XML`, and `INI`.
    This allows the parameters to be set at run time.

- `directory`

    The directory containing the file obituaries.sql.
    If only one argument is given to `new()`, it is taken to be `directory`.

- `logger` - Passed to [Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction)

## search

Searches the database.

    # Returns an array of hashrefs
    my @smiths = $obits->search(last => 'Smith');       # You must at least define the last name to search for

    print $smiths[0]->{'first'}, "\n";

Supports two return modes:

- `List context`

    Returns an array of hash references.

- `Scalar context`

    Returns a single hash reference,
    or `undef` if there is no match.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Ancestry has removed the archives.
The first 18 pages are on Wayback machine, but the rest is lost.

# SEE ALSO

[Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction)

- The Obituary Daily Times

    [https://sites.rootsweb.com/~obituary/](https://sites.rootsweb.com/~obituary/)

- Archived Rootsweb data

    [https://wayback.archive-it.org/20669/20231102044925/https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit](https://wayback.archive-it.org/20669/20231102044925/https://mlarchives.rootsweb.com/listindexes/emails?listname=gen-obit)

- Funeral Notices

    [https://www.funeral-notices.co.uk](https://www.funeral-notices.co.uk)

- Recent data

    [https://www.freelists.org/list/obitdailytimes](https://www.freelists.org/list/obitdailytimes)

- Older data

    [https://obituaries.rootsweb.com/obits/searchObits](https://obituaries.rootsweb.com/obits/searchObits)

# SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

    perldoc Genealogy::Obituary::Lookup

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/Genealogy-Obituary-Lookup](https://metacpan.org/release/Genealogy-Obituary-Lookup)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Obituary-Lookup](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-Obituary-Lookup)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Genealogy-Obituary-Lookup](http://matrix.cpantesters.org/?dist=Genealogy-Obituary-Lookup)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Genealogy::Obituary::Lookup](http://deps.cpantesters.org/?module=Genealogy::Obituary::Lookup)

# LICENSE AND COPYRIGHT

Copyright 2020-2025 Nigel Horne.

This program is released under the following licence: GPL2
