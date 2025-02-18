# NAME

Genealogy::ChroniclingAmerica - Find URLs for a given person on the Library of Congress Newspaper Records

# VERSION

Version 0.05

# SYNOPSIS

    use HTTP::Cache::Transparent;  # be nice
    use Genealogy::ChroniclingAmerica;

    HTTP::Cache::Transparent::init({
        BasePath => '/tmp/cache'
    });
    my $loc = Genealogy::ChroniclingAmerica->new({
        firstname => 'John',
        lastname => 'Smith',
        state => 'Indiana',
        date_of_death => 1862
    });

    while(my $url = $loc->get_next_entry()) {
        print "$url\n";
    }

# DESCRIPTION

The \*\*Genealogy::ChroniclingAmerica\*\* Perl module allows users to search for historical newspaper records from the \*\*Chronicling America\*\* archive,
maintained by the Library of Congress.
By providing a person's first name,
last name,
and state,
the module constructs and executes search queries,
retrieving URLs to relevant newspaper pages in JSON format.
It supports additional filters like date of birth and date of death,
enforces \*\*rate-limiting\*\* to comply with API request limits,
and includes robust error handling and validation.
Ideal for genealogy research,
this module streamlines access to historical newspaper archives with an easy-to-use interface.

- Rate-Limiting

    A minimum interval between successive API calls can be enforced to ensure that the API is not overwhelmed and to comply with any request throttling requirements.

    Rate-limiting is implemented using [Time::HiRes](https://metacpan.org/pod/Time%3A%3AHiRes).
    A minimum interval between API
    calls can be specified via the `min_interval` parameter in the constructor.
    Before making an API call,
    the module checks how much time has elapsed since the
    last request and,
    if necessary,
    sleeps for the remaining time.

# SUBROUTINES/METHODS

## new

Creates a Genealogy::ChroniclingAmerica object.

It takes three mandatory arguments:

- `firstname`
- `lastname`
- `state` - Must be the full name,
not an abbreviation.

Accepts the following optional arguments:

- `middlename`
- `date_of_birth`
- `date_of_death`
- `host` - The domain of the site to search, the default is [https://chroniclingamerica.loc.gov](https://chroniclingamerica.loc.gov).
- `ua` - An object that understands get and env\_proxy messages,
such as [LWP::UserAgent::Throttled](https://metacpan.org/pod/LWP%3A%3AUserAgent%3A%3AThrottled).
- `min_interval` - Amount to rate limit.

## get\_next\_entry

Returns the next match as a URL.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

If a middle name is given and no match is found,
it should search again without the middle name.

# SEE ALSO

[https://github.com/nigelhorne/gedcom](https://github.com/nigelhorne/gedcom)
[https://chroniclingamerica.loc.gov](https://chroniclingamerica.loc.gov)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-genealogy-chroniclingamerica at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Genealogy-ChroniclingAmerica](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Genealogy-ChroniclingAmerica).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Genealogy::ChroniclingAmerica

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-ChroniclingAmerica](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-ChroniclingAmerica)

- Search CPAN

    [https://metacpan.org/release/Genealogy-ChroniclingAmerica](https://metacpan.org/release/Genealogy-ChroniclingAmerica)

# LICENSE AND COPYRIGHT

Copyright 2018-2025 Nigel Horne.

This program is released under the following licence: GPL2
