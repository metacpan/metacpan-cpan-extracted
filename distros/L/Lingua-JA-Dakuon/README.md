# NAME

Lingua::JA::Dakuon - Convert between dakuon/handakuon and seion for Japanese

# SYNOPSIS

    use utf8;
    use Lingua::JA::Dakuon ':all';

    # Convert char to dakuon/handakuon
    dakuon('か');    #=> 'が'(\x{304c})
    dakuon('ﾀ');     #=> 'ﾀﾞ'(\x{ff80}\x{ff9e})
    dakuon('あ');    #=> 'あ'(\x{3042})
    handakuon('は'); #=> 'ぱ'(\x{3071})
    {
        local $Lingua::JA::Dakuon::EnableCombining = 1;
        dakuon('あ'); #=> "\x{3042}\x{3099}"
    }
    {
        local $Lingua::JA::Dakuon::PreferCombining = 1;
        dakuon('か');    #=> "\x{304b}\x{3099}"
        handakuon('は'); #=> "\x{306f}\x{309a}"
    }

    # Convert char to seion
    seion('が');         #=> 'か'(\x{304b})
    seion('か゛');       #=> 'か'(\x{304b})
    seion('あ');         #=> 'あ'(\x{3042})
    seion("あ\x{3099}"); #=> 'あ'(\x{3042})
    seion('ﾀﾞ');         #=> 'ﾀ' (\x{ff80})
    seion('ぱ');         #=> 'は'(\x{306f})
    seion('は゜');       #=> 'は'(\x{306f})
    seion('ﾀﾟ');         #=> 'ﾀ' (\x{ff80})

    # Normalize dakuon/handakuon expression in string
    dakuon_normalize("あがさ\x{3099}た゛なぱま\x{3099}ゔﾊﾋﾞﾌ\x{3099}");
        #=> 'あがざだなぱまゔﾊﾋﾞﾌﾞ'
    handakuon_normalize("あぱひ\x{309a}ひ゜がま\x{309a}ﾊﾋﾟﾌ\x{309a}");
        #=> 'あぱぴぴがまﾊﾋﾟﾌﾟ'
    {
        local $Lingua::JA::Dakuon::PreferCombining = 1;
        dakuon_normalize("あがさ\x{3099}た゛なぱま\x{3099}ゔﾊﾋﾞﾌ\x{3099}");
           #=> "あか\x{3099}さ\x{3099}た\x{3099}なぱま\x{3099}う\x{3099}ﾊﾋﾞﾌﾞ"
        handakuon_normalize("あぱひ\x{309a}ひ゜がま\x{309a}ﾊﾋﾟﾌ\x{309a}");
           #=> "あは\x{309a}ひ\x{309a}ひ\x{309a}がま\x{309a}ﾊﾋﾟﾌﾟ"
    }

    all_dakuon_normalize($string);
        #=> equivalent to dakuon_normalize(handakuon_normalize($string));

# DESCRIPTION

This module provide routines to handle dakuon/handakuon in Japanese
which is expressed by Unicode.

# VARIABLES

## $Lingua::JA::Dakuon::EnableCombining (default: 0)

If this variable set to true, use unicode combining character if needed.
For example, there is no code corresponding to dakuon for 'あ'(\\x{3042}).
But it can be forcely expressed with combining character "\\x{3099}" as
"\\x{3042}\\x{3099}" if this flag was enabled.

## $Lingua::JA::Dakuon::PreferCombining (default: 0)

If this variable set to true, use combining character instead of dakuon
character code even if it is avaiable.
For example, calling dakuon() with argument 'か' will return "か\\x{3099}"
instead of returning "\\x{304c}".

## $Lingua::JA::Dakuon::AllDakuonRE

Regex \*STRING\*(not compiled) that matches all dakuon character(s)
can be passed to seion().

## $Lingua::JA::Dakuon::AllHandakuonRE

Regex \*STRING\*(not compiled) that matches all handakuon character(s)
can be passed to seion().

# FUNCTIONS

## dakuon($char)

Convert passed character to dakuon character if it is possible.
Return undef if passed argument has more than 1 character.

    dakuon('か');   #=> 'が'(\x{304c})

## handakuon($char)

Convert passed character to handakuon character if it is possible.
Return undef if passed argument has more than 1 character.

    handakuon('は'); #=> 'ぱ'(\x{3071})

## seion($char)

Convert passed character to seion character if it is possible.
Return undef if passed argument has more than 2 character or second
character isn't a mark charactor which expresses dakuon/handakuon.

    seion('が'); #=> 'か'(\x{304b})
    seion('ぱ'); #=> 'は'(\x{306f})

## dakuon\_normalize($string)

Normalize string that maybe contains multiple expression of dakuon.

    dakuon_normalize("あがさ\x{3099}た゛なぱま\x{3099}ゔﾊﾋﾞﾌ\x{3099}");
        #=> 'あがざだなぱまゔﾊﾋﾞﾌﾞ'

## handakuon\_normalize($string)

Normalize string that maybe contains multiple expression of handakuon.

    handakuon_normalize("あぱひ\x{309a}ひ゜がま\x{309a}ﾊﾋﾟﾌ\x{309a}");
        #=> 'あぱぴぴがまﾊﾋﾟﾌﾟ'

## all\_dakuon\_normalize($string)

Equivalent to calling dakuon\_normalize(handakuon\_normalize($string));

# SEE ALSO

- [濁点 - Wikipedia](http://ja.wikipedia.org/wiki/%E6%BF%81%E7%82%B9)
- [半濁点 - Wikipedia](http://ja.wikipedia.org/wiki/%E5%8D%8A%E6%BF%81%E7%82%B9)
- [清音 - Wikipedia](http://ja.wikipedia.org/wiki/%E6%B8%85%E9%9F%B3)

# LICENSE

Copyright (C) Yuto KAWAMURA(kawamuray).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yuto KAWAMURA(kawamuray) <kawamuray.dadada@gmail.com>
