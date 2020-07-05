# NAME

Getopt::EX::i18n - General i18n module

# SYNOPSIS

command -Mi18n \[ options \]

# DESCRIPTION

This module **i18n** provide an easy way to set locale environment
before executing arbitrary command.  Locale list is taken from the
system by `locale -a` command.  Next list is a sample locales
available on macOS 10.15 (Catalina).

    af_ZA    Afrikaans / South Africa
    am_ET    Amharic / Ethiopia
    be_BY    Belarusian / Belarus
    bg_BG    Bulgarian / Bulgaria
    ca_ES    Catalan; Valencian / Spain
    cs_CZ    Czech / Czech Republic
    da_DK    Danish / Denmark
    de_AT    German / Austria
    de_CH    German / Switzerland
    de_DE    German / Germany
    el_GR    Greek, Modern (1453-) / Greece
    en_AU    English / Australia
    en_CA    English / Canada
    en_GB    English / United Kingdom
    en_IE    English / Ireland
    en_NZ    English / New Zealand
    en_US    English / United States
    es_ES    Spanish / Spain
    et_EE    Estonian / Estonia
    eu_ES    Basque / Spain
    fi_FI    Finnish / Finland
    fr_BE    French / Belgium
    fr_CA    French / Canada
    fr_CH    French / Switzerland
    fr_FR    French / France
    he_IL    Hebrew / Israel
    hr_HR    Croatian / Croatia
    hu_HU    Hungarian / Hungary
    hy_AM    Armenian / Armenia
    is_IS    Icelandic / Iceland
    it_CH    Italian / Switzerland
    it_IT    Italian / Italy
    ja_JP    Japanese / Japan
    kk_KZ    Kazakh / Kazakhstan
    ko_KR    Korean / Korea, Republic of
    lt_LT    Lithuanian / Lithuania
    nl_BE    Dutch / Belgium
    nl_NL    Dutch / Netherlands
    no_NO    Norwegian / Norway
    pl_PL    Polish / Poland
    pt_BR    Portuguese / Brazil
    pt_PT    Portuguese / Portugal
    ro_RO    Romanian / Romania
    ru_RU    Russian / Russian Federation
    sk_SK    Slovak / Slovakia
    sl_SI    Slovenian / Slovenia
    sr_YU    Serbian / Yugoslavia
    sv_SE    Swedish / Sweden
    tr_TR    Turkish / Turkey
    uk_UA    Ukrainian / Ukraine
    zh_CN    Chinese / China
    zh_HK    Chinese / Hong Kong
    zh_TW    Chinese / Taiwan, Province of China

As for Japanese locale `ja_JP`, following options are defined by
default, and set `LANG` environment as `ja_JP`.

    LOCALE:     --ja_JP  (raw)
                --ja-JP  (dash)
                --jaJP   (long)
                --jajp   (long_lc)
    LANGUAGE:   --ja     (language)
    TERRITORY:  --JP     (territory)
                --jp     (territory_lc)

Short language option (`--ja`) is defined in the alphabetical order
of the territory code, so the option `--en` is assigned to `en_AU`.
But if the same territory name is found as language, it takes
precedence; German is used in three locales (`de_AT`, `de_CH`,
`de_DE`) but option `--de` is defined as `de_DE`.

Territory options (`--JP` and `--jp`) are defined only when the same
language option is not defined by other entry, and only single entry
can be found for the territory.  Option for Switzerland is not defined
because there are three entries (`de_CH`, `fr_CH`, `it_CH`).
Territory option `--AM` is assigned to `hy_AM`, but language option
`--am` is assigned to `am_ET`.

# OPTION

Option parameter can be given with **setopt** function called with
module declaration.

    command -Mi18n::setopt(name[=value])

- **raw**
- **dash**
- **long**
- **long\_lc**
- **lang**
- **territory**
- **territory\_lc**

    These parameter tells which option is defined.  All options are
    enabled by default.  You can disable territory option like this:

        command -Mi18n::setopt(territory=0,territory_lc=0)

        command -Mi18n::setopt=territory=0,territory_lc=0

- **verbose**

    Show locale information.

        $ optex -Mi18n::setopt=verbose date --it
        LANG=it_IT (Italian / Italy)
        Gio  4 Giu 2020 16:47:33 JST

- **list**

    Show option list.

- **listopt**=_option_

    Set the option to display option list and exit.  You can introduce a
    new option **-l** to show available option list:

        -Mi18n::setopt(listopt=-l)

- **prefix**=_string_

    Specify prefix string.  Default is `--`.

# BUGS

Support only UTF-8.

# SEE ALSO

- [Getopt::EX](https://metacpan.org/pod/Getopt::EX)

    [https://github.com/kaz-utashiro/Getopt-EX](https://github.com/kaz-utashiro/Getopt-EX)

- [optex](https://metacpan.org/pod/App::optex)

    You can execute arbitrary command on the system getting the benefit of
    **Getopt::EX** using **optex**.

        $ optex -Mi18n cal 2020 --am

    [https://github.com/kaz-utashiro/optex](https://github.com/kaz-utashiro/optex)

    [https://qiita.com/kaz-utashiro/items/2df8c7fbd2fcb880cee6](https://qiita.com/kaz-utashiro/items/2df8c7fbd2fcb880cee6)

# LICENSE

Copyright (C) 2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kazumasa Utashiro <kaz@utashiro.com>
