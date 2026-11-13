## Name

Genealogy::ChroniclingAmerica - Find URLs for a given person on the Library of Congress Newspaper Records

## Version

Version 0.08

## Synopsis

```perl
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
```

## Description

The **Genealogy::ChroniclingAmerica** module allows users to search for historical newspaper records from the **Chronicling America** archive,
maintained by the Library of Congress.
By providing a person's first name,
last name,
and state,
the module constructs and executes search queries,
retrieving URLs to relevant newspaper pages in JSON format.
It supports additional filters like date of birth and date of death,
enforces **rate-limiting** to comply with API request limits,
local caching,
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

## Subroutines/Methods

### New

Creates a Genealogy::ChroniclingAmerica object.

It takes three mandatory arguments:

- `firstname`
- `lastname`
- `state` - Must be the full name,
not an abbreviation.

Accepts the following optional arguments:

- `cache`

    A caching object.
    If not provided,
    an in-memory cache is created with a default expiration of one hour.

- `middlename`
- `date_of_birth`
- `date_of_death`
- `host` - The domain of the site to search, the default is `www.loc.gov`.
- `ua` - An object that understands get and env\_proxy messages,
such as [LWP::UserAgent::Throttled](https://metacpan.org/pod/LWP%3A%3AUserAgent%3A%3AThrottled).
- `min_interval` - Amount to rate limit.
Defaults to 4 seconds,
inline with [https://libraryofcongress.github.io/data-exploration/loc.gov%20JSON%20API/Chronicling\_America/README.html#rate-limits](https://libraryofcongress.github.io/data-exploration/loc.gov%20JSON%20API/Chronicling_America/README.html#rate-limits)

If a search finds nothing it is repeated once,
since the Library of Congress sometimes answers an identical search inconsistently.

#### Api Specification

##### Input

```perl
{
  firstname => { type => 'string', min => 1, matches => qr/\D/ },
  lastname => { type => 'string', min => 1, matches => qr/\D/ },
  state => { type => 'string', min => 3, matches => qr/^\D+$/ },      # Full name, not an abbreviation
  middlename => { type => 'string', optional => 1 },
  date_of_birth => { type => 'integer', optional => 1 },      # A year
  date_of_death => { type => 'integer', optional => 1 },      # A year
  host => { type => 'string', optional => 1 },
  ua => { type => 'object', can => 'get', optional => 1 },
  cache => { type => 'object', can => ['get', 'set'], optional => 1 },
  min_interval => { type => 'number', optional => 1 },
}
```

The constructor croaks if a mandatory argument is missing or invalid.

##### Output

A blessed `Genealogy::ChroniclingAmerica` object.
Called on an existing object it returns a clone with the new arguments.

### Get\_Next\_Entry

Returns the next match as a URL of a PDF of the newspaper page,
or undef when there are no more matches.

Each call may make up to two requests of the Library of Congress:
one for the item and one for the OCR text of its page.
Items whose text doesn't contain the person's name are skipped.
Both requests honour `min_interval`.

The URL is not checked,
the Library of Congress may refuse (HTTP 403) requests for the PDF from some automated clients.

#### Api Specification

##### Input

None, other than the object.

##### Output

```perl
{
  type => 'string',
  min => 5,
  matches => qr/\.pdf$/,      # A URL
  optional => 1,      # undef when no more matches
}
```

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Bugs

If a middle name is given and no match is found,
it should search again without the middle name.

## See Also

- [https://github.com/nigelhorne/gedcom](https://github.com/nigelhorne/gedcom)
- [https://chroniclingamerica.loc.gov](https://chroniclingamerica.loc.gov)
- [https://github.com/LibraryOfCongress/data-exploration](https://github.com/LibraryOfCongress/data-exploration)

## Support

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-genealogy-chroniclingamerica at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Genealogy-ChroniclingAmerica](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Genealogy-ChroniclingAmerica).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

```
perldoc Genealogy::ChroniclingAmerica
```

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-ChroniclingAmerica](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Genealogy-ChroniclingAmerica)

- Search CPAN

    [https://metacpan.org/release/Genealogy-ChroniclingAmerica](https://metacpan.org/release/Genealogy-ChroniclingAmerica)

## License and Copyright

Copyright 2018-2026 Nigel Horne.

This program is released under the following licence: GPL2
