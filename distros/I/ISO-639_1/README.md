# NAME

ISO::639\_1 - ISO 639-1 Language informations

# SYNOPSIS

    use ISO::639_1;
    print get_iso639_1('zu')->{'639-1'};    # zu
    print get_iso639_1('zu')->{'639-2'};    # zul
    print get_iso639_1('zu')->{family};     # Niger–Congo
    print get_iso639_1('zu')->{name};       # Zulu
    print get_iso639_1('zu')->{nativeName}; # isiZulu
    print get_iso639_1('zu')->{wikiUrl};    # https://en.wikipedia.org/wiki/Zulu_language

    print get_iso639_1('fr')->{nativeName};    # Français
    print get_iso639_1('fr-BE')->{nativeName}; # Français (BE)
    print get_iso639_1('ur')->{nativeName};    # اردو

# DESCRIPTION

ISO::639\_1 provides informations about a language from its ISO639-1 code.

It differs from [ISO::639](https://metacpan.org/pod/ISO::639) which is about ISO639-2.

The informations are extracted from [https://github.com/haliaeetus/iso-639/](https://github.com/haliaeetus/iso-639/) (MIT license).

# METHODS

ISO::639\_1 exports the following methods:

## get\_iso639\_1

    Usage    : get_iso639_1('zu')
    Returns  : a hashref providing the informations described below.
              {
                  "639-1"      => "zu",          # ISO 639-1 code
                  "639-2"      => "zul",         # ISO 639-2 code
                  "family"     => "Niger–Congo", # family of language
                  "name"       => "Zulu",        # english name of the language
                  "nativeName" => "isiZulu",     # native name of the language
                  "wikiUrl"    => "https://en.wikipedia.org/wiki/Zulu_language" # wikipedia URL about the language
              }
    Argument : an ISO639-1 code with or without localization code.
               If a localization code is provided, (think "fr-BE", or "fr_BE"), the localization is
               appended to the name and nativeName informations (like "Français (BE)").
               Localization must be separated from the language code by "-" or "_".

# INSTALL

After getting the tarball on https://metacpan.org/release/ISO::639\_1, untar it, go to the directory and:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

# BUGS and SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ISO::639_1

Bugs and feature requests will be tracked on:

    https://framagit.org/luc/iso-639_1/issues

The latest source code can be browsed and fetched at:

    https://framagit.org/luc/iso-639_1
    git clone https://framagit.org/luc/iso-639_1.git

Source code mirror:

    https://github.com/ldidry/iso-639_1

You can also look for information at:

    AnnoCPAN: Annotated CPAN documentation

    http://annocpan.org/dist/ISO::639_1
    CPAN Ratings

    http://cpanratings.perl.org/d/ISO::639_1
    Search CPAN

    http://search.cpan.org/dist/ISO::639_1

# LICENSE

Copyright (C) Luc Didry.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

# SEE ALSO

[ISO::639](https://metacpan.org/pod/ISO::639)

# AUTHOR

Luc Didry <luc@didry.org>
[https://fiat-tux.fr](https://fiat-tux.fr)
