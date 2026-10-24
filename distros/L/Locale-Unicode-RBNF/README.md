# NAME

Locale::Unicode::RBNF - Unicode CLDR Rule-Based Number Format, ported from ICU4C

# SYNOPSIS

    use Locale::Unicode::RBNF;
    my $fmt = Locale::Unicode::RBNF->new(
        locale  => 'fr',
        type    => 'spellout',
        cldr    => '/path/to/cldr/common',
    ) || die( Locale::Unicode::RBNF->error );
    say $fmt->format( 1980 );
    # mille neuf cent quatre-vingts
    say $fmt->format( 71, '%spellout-cardinal-feminine' );
    # soixante-et-onze
    say $fmt->format( 3.14 );
    # trois virgule un quatre
    my $n = $fmt->parse( 'deux mille vingt-six' );
    # 2026

    # Japanese, for instance for amounts written in kanji
    my $ja = Locale::Unicode::RBNF->new( locale => 'ja', cldr => '/path/to/cldr/common' );
    say $ja->format( 3000000, '%spellout-cardinal-financial' );

    # Custom rules, as with ICU's RuleBasedNumberFormat( description, locale )
    my $custom = Locale::Unicode::RBNF->new(
        locale  => 'en',
        rules   => "%main: 0: zero; 1: one; 2: two; 3: =#,##0=;",
    );

# VERSION

    v0.1.0

# DESCRIPTION

This is a port from ICU4C `RuleBasedNumberFormat` (ICU 79.1), that is `rbnf.cpp`, `nfrs.cpp`, `nfrule.cpp` and `nfsubs.cpp`, using the RBNF data of the Unicode CLDR.

It formats numbers using rules, typically to spell them out ("one thousand two hundred"), to produce ordinals ("1st", "1er"), or to write them in numbering systems such as Roman numerals or Hebrew numbers, and it parses such text back into numbers, in strict or lenient mode.

The rules, decimal format symbols, numbering system digits and plural rules are read from a CLDR `common` directory; see [Locale::Unicode::RBNF::CLDR](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3ARBNF%3A%3ACLDR).

# CONSTRUCTOR

## new

Takes a hash or an hash reference of options, and returns a new object, or, upon error, sets an error that can be retrieved with ["error"](#error) and returns `undef` in scalar context, or an empty list in list context.

- `capitalization`

    The capitalisation context. See ["capitalization"](#capitalization).

- `cldr`

    The path to the CLDR `common` directory. It defaults to the environment variable `LOCALE_UNICODE_RBNF_CLDR`. It is required, unless `rules` are provided, in which case root symbols and plural rules are used without it.

- `default_rule_set`

    The name of the public rule set to use by default.

- `fatal`

    Boolean. If true, errors are fatal, which means that the [Locale::Unicode::RBNF::Exception](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3ARBNF%3A%3AException) object is passed to `die` instead of being returned.
    The default follows the value set with `$Locale::Unicode::RBNF::FATAL_EXCEPTIONS`, which is false by default.
    See ["ERROR HANDLING"](#error-handling).

- `lenient`

    Boolean. Enables lenient parsing. Default false.

- `locale`

    A locale, can be a BCP 47 identifier such as `fr`, `fr-CH` or `zh-Hant-TW`, but also a CLDR identifier such as `fr_CH`, or also a [Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode) object.

    It is parsed and canonicalised with [Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode), thus `fr-ch` becomes `fr-CH`.
    A `-u-nu-` extension selects the numbering system, as in `ja-JP-u-nu-hanidec`.
    The default is `root`.

    If [Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode) cannot parse a given locale, or if that locale does not have a language subtag, it will return an error.

    The ICU keyword syntax, such as `fr_CH@numbers=latn`, is not supported. You must use the BCP 47 extension instead.

- `localizations`

    Localised display names of the rule sets, in the ICU syntax, such as `<<%main, %other>, <en, Main, Other>, <fr, Principal, Autre>>`. When provided, the first rule set listed becomes the default one.

- `max_fraction_digits`

    The maximum number of fraction digits used when rounding, if a rounding mode other than `unnecessary` is set. Default 3.

- `numbering_system`

    Overrides the numbering system whose symbols and digits are used by decimal patterns in the rules. Default: the locale's default numbering system.

- `rounding_mode`

    One of `ceiling`, `floor`, `down`, `up`, `half_even`, `half_down`, `half_up`, `half_odd`, `half_ceiling`, `half_floor` or `unnecessary` (the default, under which numbers are not rounded before formatting).

- `rules`

    A rule description in the ICU syntax, instead of the CLDR rules.

- `type`

    The CLDR rule set grouping: `spellout` (the default), `ordinal`, `numbering_system` or `duration`.

# METHODS

## capitalization

Sets or gets the capitalisation context: `none` (default), `middle_of_sentence`, `beginning_of_sentence`, `ui_list_or_menu` or `standalone`. For the last two, the first word is titlecased only if the CLDR `number-spellout` context transforms of the locale say so.

## default\_rule\_set

Sets or gets the name of the default rule set. An empty string restores the original default.

## error

    my $fmt = Locale::Unicode::RBNF->new( locale => 'fr', type => 'nonsense' ) ||
        die( Locale::Unicode::RBNF->error );
    say $fmt->error->message;

In accessor mode, this returns the last error, as a [Locale::Unicode::RBNF::Exception](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3ARBNF%3A%3AException) object, or possibly `undef` if there were none.

When called as a class method, this returns the last error of any object.

When called mutator mode the arguments provided are concatenated, and a new error is set.
It then returns `undef` in scalar context, or an empty list in list context. In object context, such as `$fmt->format( 'abc' )->length`, it returns a [Locale::Unicode::RBNF::NullObject](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3ARBNF%3A%3ANullObject) instead, so that the chain of method calls does not die.

If ["fatal"](#fatal) is true, it dies with the exception instead.

See ["ERROR HANDLING"](#error-handling).

## fatal

Sets or gets the boolean value for this option.
If true, the exceptions will be fatal. By default, it follows the value set with `$Locale::Unicode::RBNF::FATAL_EXCEPTIONS`, which itself is false by default.

See ["ERROR HANDLING"](#error-handling).

## format

    my $text = $fmt->format( $number );
    my $text = $fmt->format( $number, '%spellout-ordinal' );

Formats a number, using the given public rule set or the default one. Integers within the `int64` range use ICU's integer code path, other numbers its double code path. Larger integers are formatted with the locale's decimal pattern, as ICU does.

## format\_double

Formats a number with ICU's double code path, even if it is integral.

## format\_int

Formats an integer with ICU's integer code path.

## lenient

Sets or gets the lenient parsing mode.

## locale

    my $locale = $fmt->locale;
    say $locale;
    # fr-CH

Returns the canonical locale of the formatter as a [Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode) object, which stringifies as a BCP 47 identifier, such as `fr-CH` or `ja-JP-u-nu-hanidec`, extensions included.

The locale `root` is returned as `root`, rather than as its canonical form `und`.

## max\_fraction\_digits

Sets or gets the maximum number of fraction digits used for rounding.

## numbering\_system

Returns the numbering system used.

## parse

    my $n = $fmt->parse( $text );
    my( $n, $index, $error_index ) = $fmt->parse( $text, $start );

Parses text into a number, trying every public and parseable rule set, and keeping the result that consumed the most characters. In list context, it returns the value, the index after the parsed text, and the error index (`-1` on success).

## pass\_error

    return( $self->pass_error( $other->error ) );
    return( $self->pass_error );

Propagates the error stored in another object (or the class-level error) into the current object's error slot, without constructing a new exception, and then returns `undef` in scalar context, or an empty list in list context, or a [Locale::Unicode::RBNF::NullObject](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3ARBNF%3A%3ANullObject) in object context, just like ["error"](#error) does.

Without any argument, the last error is passed on.

If the error is not an object, ["error"](#error) is called with it.

If an hash reference is passed with the key `class` it will bless the error into that exception class provided.

Supported options are:

- `class`

    The name of a class name to re-bless the error object provided.

- `code`

    The error code to set in the error object being passed.

- `error`

    The error object to be passed on.

    If this is not provided, it will get it with the object `error` method, or the class global variable `$ERROR`

## rounding\_mode

Sets or gets the rounding mode.

## rule\_set\_display\_name

    my $name = $fmt->rule_set_display_name( '%main', 'fr' );

Returns the localised name of a rule set, given by name or index, when `localizations` were provided.

## rule\_set\_display\_name\_locales

Returns an array reference of the locales of the localised names.

## rule\_set\_names

Returns an array reference of the public rule set names.

## rule\_sets\_from\_description

    my $r = Locale::Unicode::RBNF->rule_sets_from_description( $description );
    # {
    #     lenient_parse => undef,
    #     rule_sets => [
    #         {
    #             name      => '%spellout-numbering-year',
    #             type      => 'spellout-numbering-year',
    #             private   => 0,
    #             parseable => 1,
    #             rules     => [ { descriptor => 'x.x', text => '=0.0=' }, ... ],
    #         },
    #         ...
    #     ],
    # }

Divides a rule description into its rule sets and rules, without compiling them, exactly as ICU does when it reads them: same whitespace stripping, same extraction of the `%%lenient-parse` rules, same division into rule sets and rules, and same separation of the rule descriptor from the rule text. It uses the very code of the constructor. This is meant for storing the rules, for instance in a database. It can be called as a class method, and returns `undef` upon error.

The rule text is kept as it is in the description, including a leading apostrophe, but without the terminating semicolon. See also ["rbnf\_groupings" in Locale::Unicode::RBNF::CLDR](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3ARBNF%3A%3ACLDR#rbnf_groupings).

## rules

Returns a textual description of the rules in use, equivalent to the original one.

## symbols

Sets or gets the decimal format symbols, as an hash reference with the keys `decimal`, `group`, `minus`, `plus`, `percent`, `per_mille`, `infinity`, `nan` and `digits` (an array reference of 10 digits).

## valid\_locale

    my $fmt = Locale::Unicode::RBNF->new( locale => 'fr-FR', cldr => $cldr );
    say $fmt->valid_locale;
    # fr

Returns the locale built using the CLDR rules, and found by following the locale inheritance chain, as a [Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode) object, such as `fr` or `root`.

It returns `undef` when the rules were provided with the `rules` option.

# ERROR HANDLING

Exceptions are built as [Locale::Unicode::RBNF::Exception](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3ARBNF%3A%3AException) objects, which stringify as their message followed by the package, line and file where they occurred.

By default, a method that fails sets an error, retrievable with ["error"](#error), emits it as a warning if the warnings category `Locale::Unicode::RBNF` is enabled in the caller, and returns `undef` in scalar context, an empty list in list context, or a [Locale::Unicode::RBNF::NullObject](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3ARBNF%3A%3ANullObject) in object context.

If the `fatal` option, or ["fatal"](#fatal), is true, the error is raised with `die` instead, and can be caught with `eval` or `try-catch` if you are using Perl version `5.34.0`, or higher. The global variable `$Locale::Unicode::RBNF::FATAL_EXCEPTIONS` sets the default for new objects, and applies to errors of class methods, such as those of the constructor.

    {
        local $Locale::Unicode::RBNF::FATAL_EXCEPTIONS = 1;
        my $fmt = eval{ Locale::Unicode::RBNF->new( locale => 'x-private' ) };
        warn( $@->message ) if( $@ );
    }

# PARSING ENGINE

Parsing is costly: as in ICU, it tries every rule of every public rule set, recursively. This distribution therefore includes a port to C of the parsing code path (`Locale-Unicode-RBNF.xs`), built when a C compiler is available, and used automatically. Formatting remains in Perl, since it is fast.

The pure Perl implementation, in [Locale::Unicode::RBNF::PP](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3ARBNF%3A%3APP), is the fallback: it is loaded automatically when the XS shared object cannot be loaded, such as when the distribution was installed without a C compiler, or when the environment variable `PERL_LOCALE_UNICODE_RBNF_PP` is set to a true value before the module is loaded. The variable `$Locale::Unicode::RBNF::IsPurePerl` tells which one is in use. Both give the same results; the test suite checks it.

The C engine is the internal class `Locale::Unicode::RBNF::XS`, created by the formatter when parsing first needs it. Its constructor `new` takes an hash reference of the rule sets, rules, substitutions, plural patterns and decimal formats of the formatter, flattened into arrays of hashes, together with the Perl callbacks it uses for lenient matching (case folding, separators, NFC boundaries and normalisation, and digit values), whose results it caches per code point. Its method `parse`, given the text and the lenient flag, returns the value, the number of characters matched and the error index. You should not normally use this class directly.

# DIFFERENCES WITH ICU

- Lenient parsing uses ICU 79's NFC and case-folding matching. ICU additionally falls back on a collator tailored with `%%lenient-parse` rules when a rule description provides some; collation tailoring is not available here, so that fallback never matches. Current CLDR data has no such rules.
- Where ICU creates a `NumberFormat` for the default locale, during lenient parsing, the decimal format of the formatter's locale is used.
- Decimal patterns support the subset needed by rule-based formats: `#`, `0`, `,`, `.`, literal affixes, percent and per mille. Significant digits, exponents and rounding increments are rejected.
- Contextual capitalisation titlecases the first character, without a sentence break iterator.
- Parse results are computed with doubles, as ICU does. Beyond 2^53, the pure Perl engine may keep integer precision where ICU and the C engine round.
- Where ICU converts an out of range double to an `int32_t` to select a plural form, which is undefined behaviour in C++, the saturating semantics of Java and aarch64 are used.

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# SEE ALSO

[https://unicode-org.github.io/icu/userguide/format\_parse/numbers/rbnf.html](https://unicode-org.github.io/icu/userguide/format_parse/numbers/rbnf.html), [https://www.unicode.org/reports/tr35/tr35-numbers.html#Rule-Based\_Number\_Formatting](https://www.unicode.org/reports/tr35/tr35-numbers.html#Rule-Based_Number_Formatting)

# COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

Portions are derived from ICU, Copyright (C) 2016 and later Unicode, Inc. and others, under the Unicode License ([https://www.unicode.org/copyright.html](https://www.unicode.org/copyright.html)). Its text is in the `LICENSE-UNICODE` file of this distribution.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
