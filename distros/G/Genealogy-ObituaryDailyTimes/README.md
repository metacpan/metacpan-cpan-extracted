# NAME

Genealogy::ObituaryDailyTimes - Compare a Gedcom against the Obituary Daily Times

# VERSION

Version 0.04

# SYNOPSIS

    use Genealogy::ObituaryDailyTimes;
    my $info = Genealogy::ObituaryDailyTimes->new();
    # ...

# SUBROUTINES/METHODS

## new

Creates a Genealogy::ObituaryDailyTimes object.

Takes an optional argument, directory, that is the directory containing obituaries.sql.

## search

    my $obits = Genealogy::ObituaryDailyTimes->new();

    my @smiths = $obits->search(last => 'Smith');

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

- CPANTS

    [http://cpants.cpanauthors.org/dist/Genealogy-ObituaryDailyTimes](http://cpants.cpanauthors.org/dist/Genealogy-ObituaryDailyTimes)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Genealogy-ObituaryDailyTimes](http://matrix.cpantesters.org/?dist=Genealogy-ObituaryDailyTimes)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Genealogy-ObituaryDailyTimes](http://cpanratings.perl.org/d/Genealogy-ObituaryDailyTimes)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Genealogy::ObituaryDailyTimes](http://deps.cpantesters.org/?module=Genealogy::ObituaryDailyTimes)

# LICENSE AND COPYRIGHT

Copyright 2020 Nigel Horne.

This program is released under the following licence: GPL2
