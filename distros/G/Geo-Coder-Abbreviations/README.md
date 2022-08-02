# NAME

Geo::Coder::Abbreviations - Quick and Dirty Interface to https://github.com/mapbox/geocoder-abbreviations

# VERSION

Version 0.05

# SYNOPSIS

Provides an interface to https://github.com/mapbox/geocoder-abbreviations.
One small function for now, I'll add others later.

# SUBROUTINES/METHODS

## new

Creates a Geo::Coder::Abbreviations object.
It takes no arguments.
If you have [HTTP::Cache::Transparent](https://metacpan.org/pod/HTTP%3A%3ACache%3A%3ATransparent) installed it will load much faster,
otherwise it will download the database from the Internet
when the class is first instantiated.

## abbreviate

Abbreviate a place.

    use Geo::Coder::Abbreviations;

    my $abbr = Geo::Coder::Abbreviations->new();
    print $abbr->abbreviate('Road'), "\n";      # prints 'RD'
    print $abbr->abbreviate('RD'), "\n";        # prints 'RD'

# SEE ALSO

[https://github.com/mapbox/geocoder-abbreviations](https://github.com/mapbox/geocoder-abbreviations)
[HTTP::Cache::Transparent](https://metacpan.org/pod/HTTP%3A%3ACache%3A%3ATransparent)
[https://www.mapbox.com/](https://www.mapbox.com/)

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

You may need to ensure you don't translate "Cross Street" to "X ST".
See t/abbreviations.t.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::Abbreviations

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-Abbreviations](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-Abbreviations)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Geo-Coder-Abbreviations](http://cpanratings.perl.org/d/Geo-Coder-Abbreviations)

- Search CPAN

    [http://search.cpan.org/dist/Geo-Coder-Abbreviations/](http://search.cpan.org/dist/Geo-Coder-Abbreviations/)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2020-2022 Nigel Horne.

This program is released under the following licence: GPL2
