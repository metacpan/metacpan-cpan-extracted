# NAME

HTML::Genealogy::Map - Extract and map genealogical events from GEDCOM file

# VERSION

Version 0.03

# DESCRIPTION

This module parses GEDCOM genealogy files and creates an interactive map showing
the locations of births, marriages, and deaths. Events at the same location are
grouped together in a single marker with a scrollable popup.

# SUBROUTINES/METHODS

## onload\_render

Render the map.
It takes two mandatory and one optional parameter.
It returns an array of two elements, the items for the `head` and `body`.

- **gedcom**

    [GEDCOM](https://metacpan.org/pod/GEDCOM) object to process.

- **geocoder**

    Geocoder to use.

- **google\_key**

    Key to Google's map API.

- **debug**

    Enable print statements of what's going on

# FEATURES

- Extracts births, marriages, and deaths with location data
- Geocodes locations using multiple fallback providers
- Groups events at the same location (within ~0.1m precision)
- Color-coded event indicators (green=birth, blue=marriage, red=death)
- Sorts events chronologically within each category
- Scrollable popups for locations with more than 5 events
- Persistent caching of geocoding results
- For OpenStreetMap: centers on location with most events

### API SPECIFICATION

#### INPUT

    {
      'gedcom' => { 'type' => 'object', 'can' => 'individuals' },
      'geocoder' => { 'type' => 'object', 'can' => 'geocode' },
      'debug' => { 'type' => 'boolean', optional => 1 },
      'google_key' => { 'type' => 'string', optional => 1, min => 39, max => 39, matches => qr/^AIza[0-9A-Za-z_-]{35}$/ },
      'height' => { optional => 1 },
      'width' => { optional => 1 }
    }

#### OUTPUT

Argument error: croak
No matches found: undef

Returns an array of two strings:

    {
      'type' => 'array',
      'min' => 2,
      'max' => 2,
      'schema' => { 'type' => 'string', min => 10 },
    }

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

# SEE ALSO

- Test coverage report: [https://nigelhorne.github.io/HTML-Genealogy-Map/coverage/](https://nigelhorne.github.io/HTML-Genealogy-Map/coverage/)
- [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure)

    The class is fully configurable at runtime with configuration files.

# REPOSITORY

[https://github.com/nigelhorne/HTML-Genealogy-Map](https://github.com/nigelhorne/HTML-Genealogy-Map)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-html-genealogy-map at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Genealogy-Map](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Genealogy-Map).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc HTML::Genalogy::Map

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/HTML-Genealogy-Map](https://metacpan.org/dist/HTML-Genealogy-Map)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Genealogy-Map](https://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Genealogy-Map)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=HTML-Genealogy-Map](http://matrix.cpantesters.org/?dist=HTML-Genealogy-Map)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=HTML::Genalogy::Map](http://deps.cpantesters.org/?module=HTML::Genalogy::Map)

# LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
