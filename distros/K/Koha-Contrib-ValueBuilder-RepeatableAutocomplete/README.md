# NAME

Koha::Contrib::ValueBuilder::RepeatableAutocomplete - Repeatable autcomplete value-builder for Koha

# VERSION

version 1.002

# SYNOPSIS

    Koha::Contrib::ValueBuilder::RepeatableAutocomplete->build_builder_inline(
            {   target => '4',
                data   => [
                  { label => 'ArchitektIn', value => 'arc' },
                  # and more...
                ] ,
            }
        );
    }

# DESCRIPTION

`Koha::Contrib::ValueBuilder::RepeatableAutocomplete` helps building
`Koha Valuebuilder Plugins`. [Koha](https://koha-community.org/) is
the world's first free and open source library system.

This module implements some functions that will generate the
JavaScript / jQuery needed by the Koha Edit Form to enable a simple
autocomplete lookup, while also working with repeatable MARC21 fields.

Please take a look at the helper modules included in this
distribution, which pack all the lookup values and their configuration
into easy to use functions:

- [Koha::Contrib::ValueBuilder::RepeatableAutocomplete::RDA](https://metacpan.org/pod/Koha%3A%3AContrib%3A%3AValueBuilder%3A%3ARepeatableAutocomplete%3A%3ARDA)

    Values for Field `100` and `700` subfields `$e` and `$e`, creator
    and other agents.

## Functions

### build\_builder\_inline

Build JS to handle a short inline autocomplete lookup (data is
provided to the function, not loaded via AJAX etc). The field will be
inferred from the form element the value\_builder is bound to.

    build_builder_inline(
          {   target    => '4',
              minlength => 3.
              data      => [ { label=>"Foo", value=>'foo', ... } ],
          }
      );

Parameters:

- `target`: required

    The subfield of the MARC field into which the selected `value` is stored.

- `data`: required

    An ARRAY of HASHes, each hash has to contain a key `label` (which
    will be what the users enter) and a key `value` which has to contain
    the value to be stored in `target`

- `minlength`; optional, defaults to 3

    Input length that will trigger the autocomplete.

## Usage in Koha

You will need to write a `value_builder` Perl script and put it into
`/usr/share/koha/intranet/cgi-bin/cataloguing/value_builder`. You can
find some example value-builder scripts in ["" in example](https://metacpan.org/pod/example). The should
look something like this:

    #!/usr/bin/perl
    use strict;
    use warnings;
    
    use Koha::Contrib::ValueBuilder::RepeatableAutocomplete::RDA qw(creator);
    
    return creator('de');

You than will have to enable this value\_builder as a Plugin in the
respective MARC21 Framework / field / subfield.

# Thanks

for supporting Open Source and giving back to the community:

- [HKS3](https://koha-support.eu)
- [Steirmärkische Landesbibliothek](https://www.landesbibliothek.steiermark.at/)
- [Camera Austria](https://camera-austria.at/)

# AUTHORS

- Thomas Klausner <domm@plix.at>
- Mark Hofstetter <cpan@trust-box.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
