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

Version 0.10

# SYNOPSIS

    use Genealogy::ObituaryDailyTimes;
    my $info = Genealogy::ObituaryDailyTimes->new();
    # ...

# SUBROUTINES/METHODS

## new

Creates a Genealogy::ObituaryDailyTimes object.

Takes two optional arguments:
	directory: that is the directory containing obituaries.sql
	logger: an object to send log messages to

## search

    my $obits = Genealogy::ObituaryDailyTimes->new();

    # Returns an array of hashrefs
    my @smiths = $obits->search(last => 'Smith');       # You must at least define the last name to search for

    print $smiths[0]->{'first'}, "\n";

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

# SEE ALSO

The Obituary Daily Times, [https://sites.rootsweb.com/~obituary/](https://sites.rootsweb.com/~obituary/)

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

Copyright 2020-2023 Nigel Horne.

This program is released under the following licence: GPL2
