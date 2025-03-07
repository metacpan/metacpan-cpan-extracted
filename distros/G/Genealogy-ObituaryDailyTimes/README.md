[![Appveyor status](https://ci.appveyor.com/api/projects/status/w2kcdehjtofvt55t?svg=true)](https://ci.appveyor.com/project/nigelhorne/genealogy-obituarydailytimes)
[![CPAN](https://img.shields.io/cpan/v/Genealogy-ObituaryDailyTimes.svg)](http://search.cpan.org/~nhorne/Genealogy-ObituaryDailyTimes/)
[![Github Actions Status](https://github.com/nigelhorne/Genealogy-ObituaryDailyTimes/workflows/.github/workflows/all.yml/badge.svg)](https://github.com/nigelhorne/Genealogy-ObituaryDailyTimes/actions)
[![Kritika Analysis Status](https://kritika.io/users/nigelhorne/repos/7086407966497872/heads/master/status.svg)](https://kritika.io/users/nigelhorne/repos/7086407966497872/heads/master/)
[![Kwalitee](https://cpants.cpanauthors.org/dist/Genealogy-ObituaryDailyTimes.png)](http://cpants.cpanauthors.org/dist/Genealogy-ObituaryDailyTimes)
[![Travis Status](https://www.travis-ci.com/nigelhorne/Genealogy-ObituaryDailyTimes.svg?branch=master)](https://www.travis-ci.com/nigelhorne/Genealogy-ObituaryDailyTimes)
[![Tweet](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://twitter.com/intent/tweet?text=Look+up+an+obituary+#perl+#gedcom+#genealogy&url=https://github.com/nigelhorne/Genealogy-ObituaryDailyTimes&via=nigelhorne)

# NAME

Genealogy::ObituaryDailyTimes - Lookup an entry in the Obituary Daily Times

# VERSION

Version 0.15

# SYNOPSIS

    use Genealogy::ObituaryDailyTimes;
    my $info = Genealogy::ObituaryDailyTimes->new();
    # ...

# SUBROUTINES/METHODS

## new

Creates a Genealogy::ObituaryDailyTimes object.

    my $obits = Genealogy::ObituaryDailyTimes->new();

Accepts the following optional arguments:

- `cache` - Passed to [Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction)
- `directory` - The directory containing the file obituaries.sql
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

You can find documentation for this module with the perldoc command.

    perldoc Genealogy::ObituaryDailyTimes

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/Genealogy-ObituaryDailyTimes](https://metacpan.org/release/Genealogy-ObituaryDailyTimes)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-ObituaryDailyTimes](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-ObituaryDailyTimes)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Genealogy-ObituaryDailyTimes](http://matrix.cpantesters.org/?dist=Genealogy-ObituaryDailyTimes)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Genealogy::ObituaryDailyTimes](http://deps.cpantesters.org/?module=Genealogy::ObituaryDailyTimes)

# LICENSE AND COPYRIGHT

Copyright 2020-2025 Nigel Horne.

This program is released under the following licence: GPL2
