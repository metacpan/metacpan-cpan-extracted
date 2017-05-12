[![Build Status](https://travis-ci.org/tokuhirom/Lingua-JA-Regular-Unicode.svg?branch=master)](https://travis-ci.org/tokuhirom/Lingua-JA-Regular-Unicode) [![MetaCPAN Release](https://badge.fury.io/pl/Lingua-JA-Regular-Unicode.svg)](https://metacpan.org/release/Lingua-JA-Regular-Unicode)
# NAME

Lingua::JA::Regular::Unicode - convert japanese chars.

# SYNOPSIS

    use Lingua::JA::Regular::Unicode qw/alnum_z2h hiragana2katakana space_z2h/;
    alnum_z2h("Ａ１");                                        # => "A1"
    hiragana2katakana("ほげ");                                # => "ホゲ"
    space_z2h("\x{0300}");                                    # => 半角スペース

# DESCRIPTION

Lingua::JA::Regular::Unicode is regularizer.

- alnum\_z2h

    Convert alphabet, numbers and **symbols** ZENKAKU to HANKAKU.

    Symbols contains **>**, **<**.

    Yes, it's bit strange. But so, this behaviour is needed by historical reason.

- alnum\_h2z

    Convert alphabet, numbers and **symbols** HANKAKU to ZENKAKU.

- space\_z2h

    convert spaces ZENKAKU to HANKAKU.

- space\_h2z

    convert spaces HANKAKU to ZENKAKU.

- katakana\_z2h

    convert katakanas ZENKAKU to HANKAKU.

- katakana\_h2z

    convert katakanas HANKAKU to ZENKAKU.

- katakana2hiragana

    convert KATAKANA to HIRAGANA.

    This method ignores following chars:

        KATAKANA LETTER VA
        KATAKANA LETTER SMALL RE
        KATAKANA LETTER SMALL HU
        KATAKANA LETTER SMALL HI
        KATAKANA LETTER SMALL HE
        KATAKANA DIGRAPH KOTO
        KATAKANA LETTER SMALL SU
        KATAKANA LETTER SMALL HO
        KATAKANA LETTER SMALL SI
        KATAKANA LETTER SMALL RI
        KATAKANA LETTER VE
        KATAKANA LETTER SMALL TO
        KATAKANA LETTER SMALL KU
        KATAKANA LETTER VO
        KATAKANA LETTER SMALL RO
        KATAKANA LETTER SMALL RA
        KATAKANA LETTER SMALL MU
        KATAKANA LETTER SMALL HA
        KATAKANA LETTER VI
        KATAKANA LETTER SMALL RU
        KATAKANA LETTER SMALL NU
        KATAKANA MIDDLE DOT
        HALFWIDTH KATAKANA SEMI-VOICED SOUND MARK
        HALFWIDTH KATAKANA VOICED SOUND MARK
        HALFWIDTH KATAKANA MIDDLE DOT

- hiragana2katakana

    convert HIRAGANA to KATAKANA.

    This method ignores following chars:

        HIRAGANA DIGRAPH YORI

# AUTHOR

Tokuhiro Matsuno &lt;tokuhirom AAJKLFJEF@ GMAIL COM>

# THANKS To

    takefumi kimura - the author of L<Lingua::JA::Regular>
    dankogai

# SEE ALSO

[Lingua::JA::Regular](https://metacpan.org/pod/Lingua::JA::Regular)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
