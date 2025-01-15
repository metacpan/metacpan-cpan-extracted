[![Linux Build Status](https://travis-ci.org/nigelhorne/WWW-Scrape-FindaGrave.svg?branch=master)](https://travis-ci.org/nigelhorne/WWW-Scrape-FindaGrave)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/ra6839k5wpno9xf0?svg=true)](https://ci.appveyor.com/project/nigelhorne/www-scrape-findagrave)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/WWW-Scrape-FindaGrave/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/WWW-Scrape-FindaGrave?branch=master)
<!---
[![Dependency Status](https://dependencyci.com/github/nigelhorne/WWW-Scrape-FindaGrave/badge)](https://dependencyci.com/github/nigelhorne/WWW-Scrape-FindaGrave)
-->

# NAME

Genealogy::FindaGrave - Find URLs on FindaGrave for a person

# VERSION

Version 0.08

# SYNOPSIS

    use HTTP::Cache::Transparent;  # be nice
    use Genealogy::FindaGrave;

    HTTP::Cache::Transparent::init({
        BasePath => '/var/cache/loc'
    });
    my $f = Genealogy::ChroniclingAmerica->new({
        firstname => 'John',
        lastname => 'Smith',
        state => 'Maryland',
        date_of_death => 1862
    });

    while(my $url = $f->get_next_entry()) {
        print "$url\n";
    }
}

# SUBROUTINES/METHODS

## new

Creates a Genealogy::FindaGrave object.

It takes two mandatory arguments firstname and lastname.

Also one of either date\_of\_birth and date\_of\_death must be given.
FIXME: Note that these are years, and should have been called year\_of\_\*.

There are four optional arguments: middlename, country, ua and host.

host is the domain of the site to search, the default is www.findagrave.com.

ua is a pointer to an object that understands get and env\_proxy messages, such
as [LWP::UserAgent::Throttled](https://metacpan.org/pod/LWP%3A%3AUserAgent%3A%3AThrottled).

## get\_next\_entry

Returns the next match as a URL to the Find-A-Grave page.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Please report any bugs or feature requests to `bug-genealogy-findagrave at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Genealogy-FindaGrave](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Genealogy-FindaGrave).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

[https://github.com/nigelhorne/gedcom](https://github.com/nigelhorne/gedcom)
[https://www.findagrave.com](https://www.findagrave.com)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Genealogy::FindaGrave

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-FindaGrave](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-FindaGrave)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Genealogy-FindaGrave](http://annocpan.org/dist/Genealogy-FindaGrave)

- Search CPAN

    [https://metacpan.org/release/Genealogy-FindaGrave](https://metacpan.org/release/Genealogy-FindaGrave)

# LICENSE AND COPYRIGHT

Copyright 2016-2025 Nigel Horne.

This program is released under the following licence: GPL2
