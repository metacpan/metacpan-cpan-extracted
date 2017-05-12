# NAME

Locale::Country::Multilingual - Map ISO codes to localized country names

# VERSION

version 0.25

# SYNOPSIS

    use Locale::Country::Multilingual {use_io_layer => 1};

    my $lcm = Locale::Country::Multilingual->new();
    my $country = $lcm->code2country('JP');        # $country gets 'Japan'
    $country = $lcm->code2country('CHN');       # $country gets 'China'
    $country = $lcm->code2country('250');       # $country gets 'France'
    my $code    = $lcm->country2code('Norway');    # $code gets 'NO'

    $lcm->set_lang('zh'); # set default language to Chinese
    $country = $lcm->code2country('CN');        # $country gets '中国'
    $code    = $lcm->country2code('日本');      # $code gets 'JP'

    my @codes   = $lcm->all_country_codes();
    my @names   = $lcm->all_country_names();

    # more heavy call
    my $lang = 'en';
    $country = $lcm->code2country('CN', $lang);        # $country gets 'China'
    $lang = 'zh';
    $country = $lcm->code2country('CN', $lang);        # $country gets '中国'

    my $CODE = 'LOCALE_CODE_ALPHA_2'; # by default
    $code    = $lcm->country2code('Norway', $CODE);    # $code gets 'NO'
    $CODE = 'LOCALE_CODE_ALPHA_3';
    $code    = $lcm->country2code('Norway', $CODE);    # $code gets 'NOR'
    $CODE = 'LOCALE_CODE_NUMERIC';
    $code    = $lcm->country2code('Norway', $CODE);    # $code gets '578'
    $code    = $lcm->country2code('挪威', $CODE, 'zh');    # with lang=zh

    $CODE = 'LOCALE_CODE_ALPHA_3';
    $lang = 'zh';
    @codes   = $lcm->all_country_codes($CODE);         # return codes with 3alpha
    @names   = $lcm->all_country_names($lang);         # get all Chinese Countries Names

# DESCRIPTION

`Locale::Country::Multilingual` is an OO replacement for
[Locale::Country](https://metacpan.org/pod/Locale::Country), and supports country names in several
languages.

## Language Codes

A language is selected by a two-letter language code as described by
ISO 639-1 [http://en.wikipedia.org/wiki/List\_of\_ISO\_639-1\_codes](http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes).
This code can be amended by a two-letter region code, that is described by
ISO 3166-1 [http://en.wikipedia.org/wiki/ISO\_3166-1\_alpha-2](http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2).
This combination of language and region is also described in RFC 4646
[http://www.ietf.org/rfc/rfc4646.txt](http://www.ietf.org/rfc/rfc4646.txt) and RFC 4647
[http://www.ietf.org/rfc/rfc4647.txt](http://www.ietf.org/rfc/rfc4647.txt), and is commonly used for
HTTP 1.1 [http://www.ietf.org/rfc/rfc2616.txt](http://www.ietf.org/rfc/rfc2616.txt) and the POSIX
[setlocale(3)](http://man.he.net/man3/setlocale) function. Codes can be given in small or capital letters
and be divided by an arbitrary string of none-letter ASCII bytes (but
`"-"` or `"_"` is recommended).

## Language Selection Fallback

In case a language code contains a region, language selection falls back to
the two-letter language code if no specific language file for the region
exists. Example: For `"zh_CN"` selection will fall back to `"zh"` since
there is no file `"zh-cn.dat"` - actually `"zh.dat"` happens to contain
the country names in Simplified (Han) Chinese.

# INCOMPATIBILITY NOTICE

## ISO Compliance

`ISO-3166` defines _country_ codes in upper case letters. `ISO-639`
defines _language_ codes in lower case letters. This facilitates
differentiation between language and country codes.

Beginning with release version 0.20 method ["country2code"](#country2code) returns country
codes in capital letters. On the input side all methods accept country and
language codes in any case for maximum convenience.

This document uses upper case letters for country codes and lower case
letters for language codes.

## Unicode Support

Unicode implementation before release 0.07 was broken. In fact it still is
for the benefit of downwards compatibility, but can be fixed by using the
`use_io_layer` option. If you use this module without `use_io_layer`,
then your code is broken.

Beginning with release 0.30 `use_io_layer` will be enabled by default.

Beginning with release 0.40 `use_io_layer` will be removed.

## Deprecated Languages

Releases before 0.09 of this module offered languages `"cn"` and `"tw"`.
Those were replaced by `"zh"` and `"zh-tw"` to comply with the ISO 639
standard and RFC 2616. `"cn"` and `"tw"` are still supported, but will be
removed in a near future - probably in release 0.30.

# METHODS

## import

    use Locale::Country::Multilingual 'en', 'fr', {use_io_layer => 1};

The `import` class method is called when a module is `use`'d.
Language files can be pre-loaded at compile time, by specifying their
language codes. This can be useful when several processes are forked
from the main application, e.g. in an Apache `mod_perl` environment -
language data that is loaded before forking is shared by all processes and
thus saving memory.

The last argument can be a reference to a hash of options.

The only option ATM is `use_io_layer` and works for Perl 5.8 and higher. See
[Locale::Country::Multilingual::Unicode](https://metacpan.org/pod/Locale::Country::Multilingual::Unicode)
for more information.

## new

    $lcm = Locale::Country::Multilingual->new;
    $lcm = Locale::Country::Multilingual->new(
      lang => 'es',
      use_io_layer => 1,
    );

Constructor method. Accepts optional list of named arguments:

- lang

    The language to use. See ["AVAILABLE LANGAUGES"](#available-langauges) for what codes are
    accepted.

- use\_io\_layer

    Set this `true` if you need correct encoding behavior. See
    [Locale::Country::Multilingual::Unicode](https://metacpan.org/pod/Locale::Country::Multilingual::Unicode)
    for more information.

## set\_lang

    $lcm->set_lang('de');

Set the current language. Only argument is a language code as described in
the ["DESCRIPTION"](#description) above.

See ["AVAILABLE LANGAUGES"](#available-langauges) for what codes are accepted.

This method does not actually load the language data. Use ["assert\_lang"](#assert_lang)
if you really need to know for sure if a language is supported.

## assert\_lang

    $lang = $lcm->assert_lang('es', 'it', 'fr');

Tries to load any of the given languages. Returns the language code for
the first language that was successfully loaded. Returns `undef` if none
of the given languages could be loaded. Actually loads the language data,
but does not [set the language](#set_lang), so you probably want to use it
this way:

    $lang = $lcm->assert_lang(qw/es it fr en/)
      and $lcm->set_lang($lang)
      or die "unable to load any language\n";

## code2country

    $country = $lcm->code2country('GB');
    $country = $lcm->code2country('GB', 'zh');

Turns an ISO 3166-1 code into a country name in the current language.
The default language is `"en"`.

Accepts either two-letter or a three-letter code or a 3 digit numerical code.

A language might be given as second argument to set the output language only
for this call - it does not change the current language, that was set with
["set\_lang"](#set_lang).

Returns the country name.

This method [croaks](https://metacpan.org/pod/Carp) if the language is not available.

## country2code

    $code = $lcm->country2code(
      'République tchèque', 'LOCALE_CODE_ALPHA_2', 'fr'
    );

Take a country name and return the two-letter code when available.
Aside from being case-insensitive the country must be written exactly the
way how ["code2country"](#code2country) returns it.

The second argument is optional and can be one of `"LOCALE_CODE_ALPHA_2"`,
`"LOCALE_CODE_ALPHA_3"` and `"LOCALE_CODE_NUMERIC"`. The default is
`"LOCALE_CODE_ALPHA2"`.

The third argument is the language to use for the country name and is
optional too.

Returns an ISO-3166 code or `undef` if search fails.

This method [croaks](https://metacpan.org/pod/Carp) if the language is not available.

## all\_country\_codes

    @countrycodes = $lcm->all_country_codes;
    @countrycodes = $lcm->all_country_codes($codeset);

Returns an unsorted list of all ISO-3166 codes.

The argument is optional and can be one of `"LOCALE_CODE_ALPHA_2"`,
`"LOCALE_CODE_ALPHA_3"` and `"LOCALE_CODE_NUMERIC"`. The default is
`"LOCALE_CODE_ALPHA2"`.

## all\_country\_names

    @countrynames = $lcm->all_country_names;
    @countrynames = $lcm->all_country_names('fr');

Returns an unsorted list of country names in the current or given locale.

# AVAILABLE LANGAUGES

- en English
- bg Bulgarian
- bn Bengali
- ca Catalan
- cs Czech
- cy Welsh
- da Danish
- de German
- dz Dzongkha
- el Greek
- eo Esperanto
- es Spanish
- et Estonian
- eu Basque
- fa Persian
- fi Finnish
- fo Faroese
- fr French
- ga Irish
- gl Galician
- gu Gujarati
- he Hebrew
- hi Hindi
- hr Croatian
- hu Hungarian
- hy Armenian
- id Indonesian
- ii Sichuan Yi
- is Icelandic
- it Italian
- ja Japanese
- ka Georgian
- km Central Khmer
- kn Kannada
- ko Korean
- ln Lingala
- lo Lao
- lt Lithuanian
- lv Latvian
- mk Macedonian
- ml Malayalam
- mn Mongolian
- ms Malay
- mt Maltese
- my Burmese
- nb Norwegian Bokmål
- ne Nepali
- nl Dutch
- nn Norwegian Nynorsk
- no Norwegian
- pl Polish
- ps Pushto
- pt Portuguese
- ro Romanian
- ru Russian
- se Northern Sami
- sk Slovak
- sl Slovenian
- so Somali
- sq Albanian
- sr Serbian
- sv Swedish
- sw Swahili
- ta Tamil
- te Telugu
- th Thai
- to Tonga
- tr Turkish
- uk Ukrainian
- ur Urdu
- uz Uzbek
- vi Vietnamese
- zh (zh-cn) Chinese Simp.
- zh-tw Chinese Trad.

Language files are more or less (in-)complete and fall back to English.
Corrections, additions and more languages are highly appreciated.

# SUPPORTS

- GitHub

    [https://github.com/maxmind/Locale-Country-Multilingual](https://github.com/maxmind/Locale-Country-Multilingual)

# SEE ALSO

[Locale::Country](https://metacpan.org/pod/Locale::Country),
ISO 639 [http://en.wikipedia.org/wiki/ISO\_639](http://en.wikipedia.org/wiki/ISO_639),
ISO 3166 [http://en.wikipedia.org/wiki/ISO\_3166](http://en.wikipedia.org/wiki/ISO_3166),
RFC 2616 [http://www.ietf.org/rfc/rfc2616.txt](http://www.ietf.org/rfc/rfc2616.txt)
RFC 4646 [http://www.ietf.org/rfc/rfc4646.txt](http://www.ietf.org/rfc/rfc4646.txt),
RFC 4647 [http://www.ietf.org/rfc/rfc4647.txt](http://www.ietf.org/rfc/rfc4647.txt),
Unicode CLDR Project [http://unicode.org/cldr/](http://unicode.org/cldr/)

# ACKNOWLEDGEMENTS

Thanks to michele ongaro for Italian/Spanish/Portuguese/German/French/Japanese dat files.

Thanks to Andreas Marienborg for Norwegian dat file.

Thanks to all contributors of the Unicode CLDR Project.

# CLDR LICENSE

Part of the data used for this module is generated from data provided by
the CLDR project. See the LICENSE.cldr in this distribution for details
on the CLDR data's license.

# AUTHORS

- Bernhard Graf <graf@cpan.org>
- Fayland Lam <fayland@gmail.com>
- Greg Oschwald <oschwald@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
