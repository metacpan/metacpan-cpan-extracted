# NAME

Genealogy::ChroniclingAmerica - Find URLs for a given person on the Library of Congress Newspaper Records

# VERSION

Version 0.01

# SYNOPSIS

    use HTTP::Cache::Transparent;  # be nice
    use Genealogy::ChroniclingAmerica;

    HTTP::Cache::Transparent::init({
        BasePath => '/var/cache/loc'
    });
    my $f = Genealogy::ChroniclingAmerica->new({
        firstname => 'John',
        lastname => 'Smith',
        country => 'Indiana',
        date_of_death => 1862
    });

    while(my $url = $f->get_next_entry()) {
        print "$url\n";
    }
}

# SUBROUTINES/METHODS

## new

## get\_next\_entry

Returns the next match as a URL.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

Please report any bugs or feature requests to `bug-genealogy-chroniclingamerica at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Genealogy-ChroniclingAmerica](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Genealogy-ChroniclingAmerica).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SEE ALSO

[https://github.com/nigelhorne/gedcom](https://github.com/nigelhorne/gedcom)
[https://chroniclingamerica.loc.gov](https://chroniclingamerica.loc.gov)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Genealogy::ChroniclingAmerica

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-ChroniclingAmerica](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-ChroniclingAmerica)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Genealogy-ChroniclingAmerica](http://cpanratings.perl.org/d/Genealogy-ChroniclingAmerica)

- Search CPAN

    [https://metacpan.org/release/Genealogy-ChroniclingAmerica](https://metacpan.org/release/Genealogy-ChroniclingAmerica)

# LICENSE AND COPYRIGHT

Copyright 2018 Nigel Horne.

This program is released under the following licence: GPL2
