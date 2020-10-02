# NAME

Geo::Coder::Abbreviations - Quick and Dirty Interface to https://github.com/mapbox/geocoder-abbreviations

# VERSION

Version 0.02

# SYNOPSIS

Provides an interface to https://github.com/mapbox/geocoder-abbreviations.
One small function for now, I'll add others later.

# SUBROUTINES/METHODS

## new

Creates a Geo::Coder::Abbreviations object.
It takes no arguments.

## abbreviate

Abbreviate a place.

    use Geo::Coder::Abbreviations;

    my $abbr = Geo::Coder::Abbreviations->new();
    print $abbr->abbreviate('Road'), "\n";      # prints 'RD'

# SEE ALSO

[https://github.com/mapbox/geocoder-abbreviations](https://github.com/mapbox/geocoder-abbreviations)

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

If you give an an already abbreviated text, it returns undef.
It would be better to return the given text.

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

Copyright 2020 Nigel Horne.

This program is released under the following licence: GPL2
