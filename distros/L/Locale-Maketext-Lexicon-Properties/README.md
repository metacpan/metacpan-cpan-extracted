[![Build Status](https://travis-ci.org/moznion/Locale-Maketext-Lexicon-Properties.png?branch=master)](https://travis-ci.org/moznion/Locale-Maketext-Lexicon-Properties) [![Coverage Status](https://coveralls.io/repos/moznion/Locale-Maketext-Lexicon-Properties/badge.png?branch=master)](https://coveralls.io/r/moznion/Locale-Maketext-Lexicon-Properties?branch=master)
# NAME

Locale::Maketext::Lexicon::Properties - Properties file parser for Maketext

# SYNOPSIS

Called via [Locale::Maketext::Lexicon](https://metacpan.org/pod/Locale::Maketext::Lexicon):

    package Hello::I18N;
    use parent 'Locale::Maketext';
    use Locale::Maketext::Lexicon {
        en => [ Properties => "en_US/hello.properties" ],
    };

    package main;
    my $lh = Hello::I18N->get_handle('en');
    print $lh->maketext('foo');

Directly calling `Locale::Maketext::Lexicon::Properties::parse()`:

    use Locale::Maketext::Lexicon::Properties;
    my %lexicon = %{ Locale::Maketext::Lexicon::Properties->parse(<DATA>) };
    __DATA__
    foo=bar
    baz=qux

# DESCRIPTION

This module parses the properties file (from Java) for [Locale::Maketext](https://metacpan.org/pod/Locale::Maketext) by using [Locale::Maketext::Lexicon](https://metacpan.org/pod/Locale::Maketext::Lexicon). And it can also return a Lexicon hash.

You are able to look up the property value by specifying key to `maketext()` or Lexcon hash.

# NOTES

Properties file can use colon (:) as delimiter as an alternative to equal (=), however this module cannot.
And properties file allows multi-line property, but this module cannot handle it.

# SEE ALSO

[Locale::Maketext](https://metacpan.org/pod/Locale::Maketext), [Locale::Maketext::Lexicon](https://metacpan.org/pod/Locale::Maketext::Lexicon)

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Tokuhiro Matsuno <tokuhirom@gmail.com>

moznion <moznion@gmail.com>
