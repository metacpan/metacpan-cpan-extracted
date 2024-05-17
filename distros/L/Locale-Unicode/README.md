# NAME

Locale::Unicode - Unicode Locale Identifier compliant with BCP47 and CLDR

# SYNOPSIS

    use Locale::Unicode;
    my $locale = Locale::Unicode->new( 'ja-Kana-t-it' ) ||
        die( Locale::Unicode->error, "\n" );
    say $locale; # ja-Kana-t-it

    # Some undefined locale in Cyrillic script
    my $locale = Locale::Unicode->new( 'und-Cyrl' );
    $locale->transform( 'und-latn' );
    $locale->mechanism( 'ungegn-2007' );
    say $locale; # und-Cyrl-t-und-latn-m0-ungegn-2007
    # A locale in Cyrillic, transformed from Latin, according to a UNGEGN specification dated 2007.

# VERSION

    v0.1.0

# DESCRIPTION

This module implements the [Unicode LDML (Locale Data Markup Language) extensions](https://unicode.org/reports/tr35/#u_Extension)

It does not enforce the standard, and is merely an API to construct, access and modify locales. It is your responsibility to set the right values.

For your convenience, summary of key elements of the standard can be found in this documentation.

It is lightweight and fast with no dependency outside of [Scalar::Util](https://metacpan.org/pod/Scalar%3A%3AUtil) and [Want](https://metacpan.org/pod/Want). It requires perl `v5.10` minimum to operate.

The objects stringifies, and once its string value is computed, it is cached and re-used until it is changed. Thus repetitive call to [as\_string](#as_string) or to stringification does not incur any speed penalty by recomputing what has not changed.

# CONSTRUCTOR

## new

    my $locale = Locale::Unicode->new( 'en' );
    my $locale = Locale::Unicode->new( 'en-GB' );
    my $locale = Locale::Unicode->new( 'en-Latn-AU' );
    my $locale = Locale::Unicode->new( 'he-IL-u-ca-hebrew-tz-jeruslm' );
    my $locale = Locale::Unicode->new( 'ja-Kana-t-it' );
    my $locale = Locale::Unicode->new( 'und-Latn-t-und-cyrl' );
    my $locale = Locale::Unicode->new( 'und-Cyrl-t-und-latn-m0-ungegn-2007' );
    my $locale = Locale::Unicode->new( 'de-u-co-phonebk-ka-shifted' );
    # Machine translated from German to Japanese using an undefined vendor
    my $locale = Locale::Unicode->new( 'ja-t-de-t0-und' );
    $locale->script( 'Kana' );
    $locale->country_code( 'JP' );
    # Now: ja-Kana-JP-t-de-t0-und

This takes a `locale` as compliant with the BCP47 standard, and an optional hash or hash reference of options and this returns a new object.

The `locale` provided is parsed and its components can be accessed and modified using all the methods of this class API.

If an hash or hash reference of options are provided, it will be used to set or modify the components from the `locale` provided.

If an error occurs, an [exception object](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3AException) is set and `undef` is returned in scalar context, or an empty list in list context. The [exception object](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3AException) can then be retrieved using [error](#error), such as:

    my $locale = Locale::Unicode->new( $somthing_bad ) ||
        die( Locale::Unicode->error );

# METHODS

All the methods below are context sensitive.

If they are called in an object context, they will return the current `Locale::Unicode` object for chaining, otherwise, they will return the current value. And if that value is `undef`, it will return `undef` in scalar context, but an empty list in list context.

Also, if an error occurs, it will set an [exception object](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3AException) and returns `undef` in scalar context, or an empty list in list context.

## apply

    my $hash_reference = Locale::Unicode->parse( 'ja-Kana-t-it' );
    $locale->apply( $hash_reference );

Provided with an hash reference of key-value pairs, and this will set each corresponding method with the associated value.

If a property provided has no corresponding method, it emits a warning if [warnings are enabled](https://metacpan.org/pod/warnings#warnings::enabled)

It returns the current object upon success, or sets an [error object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) upon error and returns `undef` in scalar context, or an empty list in list context.

## as\_string

Returns the Locale object as a string, based on its latest attributes set.

The string value returned is computed only once and further call to `as_string` returns a cached value unless changes were made to the Locale attributes.

## break\_exclusion

    my $locale = Locale::Unicode->new( 'ja' );
    $locale->break_exclusion( 'hani-hira-kata' );
    # Now: ja-dx-hani-hira-kata

This is a Unicode Dictionary Break Exclusion Identifier that specifies scripts to be excluded from dictionary-based text break (for words and lines).

Sets or gets the Unicode extension `dx`

See also [dx](#dx)

This specifies scripts to be excluded from dictionary-based text break.

## ca

This is an alias for ["calendar"](#calendar)

## calendar

    my $locale = Locale::Unicode->new( 'th' );
    $locale->calendar( 'buddhist' );
    # or:
    # $locale->ca( 'buddhist' );
    # Now: th-u-ca-buddhist
    # which is the Thai with Buddist calendar

Sets or gets the Unicode extension `ca`, which is a [calendar identifier](https://unicode.org/reports/tr35/#UnicodeCalendarIdentifier).

See the section on ["BCP47 EXTENSIONS"](#bcp47-extensions) for the proper values.

## cf

This is an alias for ["cu\_format"](#cu_format)

## co

    my $locale = Locale::Unicode->new( 'de' );
    $locale->collation( 'phonebk' );
    $locale->ka( 'shifted' );
    # Now: de-u-co-phonebk-ka-shifted

This is a Unicode collation identifier that specifies a type of collation (sort order).

This is an alias for ["collation"](#collation)

## colAlternate

    my $locale = Locale::Unicode->new( 'de' );
    $locale->collation( 'phonebk' );
    $locale->ka( 'shifted' );
    # Now: de-u-co-phonebk-ka-shifted

    $locale->collation( 'noignore' );
    # or similarly:
    $locale->collation( 'non-ignorable' );

Sets alternate handling for variable weights.

Sets or gets the Unicode extension `ka`

See ["Collation Options"](#collation-options) for more information.

## colBackwards

    $locale->colBackwards(1); # true
    # Now: kb-true
    $locale->colBackwards(0); # false
    # Now: kb-false

Sets collation boolean value for backward collation weight.

Sets or gets the Unicode extension `kb`

See ["Collation Options"](#collation-options) for more information.

## colCaseFirst

Sets or gets the Unicode extension `kf`

## colCaseLevel

    $locale->colCaseLevel(1); # true
    # Now: kc-true
    $locale->colCaseLevel(0); # false
    # Now: kc-false

Sets collation boolean value for case level.

Sets or gets the Unicode extension `kc`

See ["Collation Options"](#collation-options) for more information.

## colHiraganaQuaternary

    $locale->colHiraganaQuaternary(1); # true
    # Now: kh-true
    $locale->colHiraganaQuaternary(0); # false
    # Now: kh-false

Sets collation parameter key for special Hiragana handling.

Sets or gets the Unicode extension `kh`

See ["Collation Options"](#collation-options) for more information.

## collation

    my $locale = Locale::Unicode->new( 'fr' );
    $locale->collation( 'emoji' );
    # Now: fr-u-co-emoji

    my $locale = Locale::Unicode->new( 'de' );
    $locale->collation( 'phonebk' );
    # Now: de-u-co-phonebk
    # which is: German using Phonebook sorting

Sets or gets the Unicode extension `co`

This specifies a type of collation (sort order).

See ["Unicode extensions"](#unicode-extensions) for possible values and more information on standard.

See also ["Collation Options"](#collation-options) for more on collation options.

## colNormalisation

This is an alias for [colNormalization](#colnormalization)

## colNormalization

    $locale->colNormalization(1); # true
    # Now: kk-true
    $locale->colNormalization(0); # false
    # Now: kk-false

Sets collation parameter key for normalisation.

Sets or gets the Unicode extension `kk`

See ["Collation Options"](#collation-options) for more information.

## colNumeric

    $locale->colNumeric(1); # true
    # Now: kn-true
    $locale->colNumeric(0); # false
    # Now: kn-false

Sets collation parameter key for numeric handling.

Sets or gets the Unicode extension `kn`

See ["Collation Options"](#collation-options) for more information.

## colReorder

    my $locale = Locale::Unicode->new( 'en' );
    $locale->colReorder( 'latn-digit' );
    # Now: en-u-kr-latn-digit
    # Reorder digits after Latin characters.

    my $locale = Locale::Unicode->new( 'en' );
    $locale->colReorder( 'arab-cyrl-others-symbol' );
    # Now: en-u-kr-arab-cyrl-others-symbol
    # Reorder Arabic characters first, then Cyrillic, and put
    # symbols at the end—after all other characters.

Sets collation reorder codes.

Sets or gets the Unicode extension `kr`

See ["Collation Options"](#collation-options) for more information.

## shiftedGroup

This is an alias for ["colValue"](#colvalue)

## colStrength

    $locale->colStrength( 'level1' );
    # Now: ks-level1
    # or, equivalent:
    $locale->colStrength( 'primary' );

    $locale->colStrength( 'level2' );
    # or, equivalent:
    $locale->colStrength( 'secondary' );

    $locale->colStrength( 'level3' );
    # or, equivalent:
    $locale->colStrength( 'tertiary' );

    $locale->colStrength( 'level4' );
    # or, equivalent:
    $locale->colStrength( 'quaternary' );
    $locale->colStrength( 'quarternary' );

    $locale->colStrength( 'identic' );
    $locale->colStrength( 'identic' );
    $locale->colStrength( 'identical' );

Sets the collation parameter key for collation strength used for comparison.

Sets or gets the Unicode extension `ks`

See ["Collation Options"](#collation-options) for more information.

## colValue

    $locale->colValue( 'currency' );
    $locale->colValue( 'punct' );
    $locale->colValue( 'space' );
    $locale->colValue( 'symbol' );

Sets the collation value for the last reordering group to be affected by [ka-shifted](#colalternate).

Sets or gets the Unicode extension `kv`

See ["Collation Options"](#collation-options) for more information.

## colVariableTop

Sets the string value for the variable top.

Sets or gets the Unicode extension `vt`

See ["Collation Options"](#collation-options) for more information.

## country\_code

    my $locale = Locale::Unicode->new( 'en' );
    $locale->country_code( 'US' );
    # Now: en-US
    $locale->country_code( 'GB' );
    # Now: en-GB

Sets or gets the country code part of the `locale`.

A country code should be an ISO 3166 2-letters code, but keep in mind that the LDML (Locale Data Markup Language) accepts old data to ensure stability.

## cu

    my $locale = Locale::Unicode->new( 'ja' );
    $locale->cu( 'jpy' );
    # Now: ja-u-cu-jpy
    # which is the Japanese Yens

This is a Unicode currency identifier that specifies a type of currency (ISO 4217 code.

This is an alias for ["currency"](#currency)

## cu\_format

    # Using minus sign symbol for negative numbers
    $locale->cf( 'standard' );
    # Using parentheses for negative numbers
    $locale->cf( 'account' );

This is a currency format identifier such as `standard` or `account`

Sets or gets the Unicode extension `cf`

See the section on ["BCP47 EXTENSIONS"](#bcp47-extensions) for the proper values.

## currency

    my $locale = Locale::Unicode->new( 'ja' );
    $locale->currency( 'jpy' );
    # or
    # $locale->cu( 'jpy' );
    # Now: ja-u-cu-jpy
    # which is the Japanese yens

Sets or gets the Unicode extension `cu`

This specifies a type of ISO4217 currency code.

## d0

This is an alias for ["destination"](#destination)

## dest

This is an alias for ["destination"](#destination)

## destination

Sets or gets the Transformation extension `d0` for destination.

See the section on ["Transform extensions"](#transform-extensions) for more information.

## dx

This is an alias for ["break\_exclusion"](#break_exclusion)

## em

This is an alias for ["emoji"](#emoji)

## emoji

This is a Unicode Emoji Presentation Style Identifier that specifies a request for the preferred emoji presentation style.

Sets or gets the Unicode extension `em`.

## false

This is read-only and returns a [Locale::Unicode::Boolean](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3ABoolean) object representing a false value.

## fw

This is an alias for ["first\_day"](#first_day)

## first\_day

This is a Unicode First Day Identifier that specifies the preferred first day of the week for calendar display.

Sets or gets the Unicode extension `fw`.

Its values are `sun`, `mon`, etc... `sat`

## h0

This is an alias for ["hybrid"](#hybrid)

## hc

This is an alias for ["hour\_cycle"](#hour_cycle)

## hour\_cycle

This is a Unicode Hour Cycle Identifier that specifies the preferred time cycle.

Sets or gets the Unicode extension `hc`.

## hybrid

    my $locale = Locale::Unicode->new( 'ru' );
    $locale->transform( 'en' );
    $locale->hybrid(1); # true
    # or
    # $locale->hybrid( 'hybrid' );
    # or
    # $locale->h0( 'hybrid' );
    # Now: ru-t-en-h0-hybrid
    # Hybrid Cyrillic - Runglish

    my $locale = Locale::Unicode->new( 'en' );
    $locale->transform( 'zh-hant' );
    $locale->hybrid( 'hybrid' );
    # Now: en-t-zh-hant-h0-hybrid
    # which is Hybrid Latin - Chinglish

Those are Hybrid Locale Identifiers indicating that the `t` value is a language that is mixed into the main language tag to form a hybrid.

Sets or gets the Transformation extension `h0`.

See the section on ["Transform extensions"](#transform-extensions) for more information.

## i0

This is an alias for ["input"](#input)

## k0

This is an alias for ["keyboard"](#keyboard)

## input

    my $locale = Locale::Unicode->new( 'zh' );
    $locale->input( 'pinyin' );
    # Now: zh-t-i0-pinyin

This is an Input Method Engine transformation.

Sets or gets the Transformation extension `i0`.

See the section on ["Transform extensions"](#transform-extensions) for more information.

## ka

This is an alias for ["colAlternate"](#colalternate)

## kb

This is an alias for ["colBackwards"](#colbackwards)

## kc

This is an alias for ["colCaseLevel"](#colcaselevel)

## keyboard

    my $locale = Locale::Unicode->new( 'en' );
    $locale->keyboard( 'dvorak' );
    # Now: en-t-k0-dvorak

This is a keyboard transformation, such as used by client-side virtual keyboards.

Sets or gets the Transformation extension `k0`.

See the section on ["Transform extensions"](#transform-extensions) for more information.

## kf

This is an alias for ["colCaseFirst"](#colcasefirst)

## kh

This is an alias for ["colHiraganaQuaternary"](#colhiraganaquaternary)

## kk

This is an alias for ["colNormalization"](#colnormalization)

## kn

This is an alias for ["colNumeric"](#colnumeric)

## kr

This is an alias for ["colReorder"](#colreorder)

## ks

This is an alias for ["colStrength"](#colstrength)

## kv

This is an alias for ["colValue"](#colvalue)

## lang

    # current value: fr-FR
    $obj->lang( 'de' );
    # Now: de-FR

Sets or gets the `locale` part of this Local object.

See also ["locale"](#locale)

## lb

This is an alias for ["line\_break"](#line_break)

## line\_break

This is a Unicode Line Break Style Identifier that specifies a preferred line break style corresponding to the CSS level 3 line-break option.

Sets or gets the Unicode extension `lb`.

## line\_break\_word

This is a Unicode Line Break Word Identifier that specifies a preferred line break word handling behavior corresponding to the CSS level 3 word-break option

Sets or gets the Unicode extension `lw`.

## locale

This is an alias for ["lang"](#lang)

## locale3

    my $locale = Locale::Unicode->new( 'jpn' );
    $locale->script( 'Kana' );
    # Now: jpn-Kana

Sets or gets the [3-letter ISO 639-2 code](https://www.loc.gov/standards/iso639-2/php/code_list.php/). Keep in mind, however, that to ensure stability, the LDML (Locale Data Markup Language) also uses old data.

## lw

This is an alias for ["line\_break\_word"](#line_break_word)

## m0

This is an alias for ["mechanism"](#mechanism)

## machine

    my $locale = Locale::Unicode->new( 'ja' );
    $locale->transform( 'de' );
    $locale->machine( 'und' );
    # Now: ja-t-de-t0-und
    # Japanese translated from Germany by an undefined vendor

This is used to indicate content that has been machine translated, or a request for a particular type of machine translation of content.

Sets or gets the Transformation extension `t0`.

See the section on ["Transform extensions"](#transform-extensions) for more information.

## measurement

This is a Unicode Measurement System Identifier that specifies a preferred measurement system.

Sets or gets the Unicode extension `ms`.

## mechanism

    my $locale = Locale::Unicode->new( 'und-Latn' );
    $locale->transform( 'ru' );
    $locale->mechanism( 'ungegn-2007' );
    # Now: und-Latn-t-ru-m0-ungegn-2007
    # representing a transformation from United Nations Group of Experts on 
    # Geographical Names in 2007

This is a transformation mechanism referencing an authority or rules for a type of transformation.

Sets or gets the Transformation extension `m0`.

See the section on ["Transform extensions"](#transform-extensions) for more information.

## ms

This is an alias for ["measurement"](#measurement)

## mu

This is an alias for ["unit"](#unit)

## nu

This is an alias for ["number"](#number)

## number

This is a Unicode Number System Identifier that specifies a type of number system.

Sets or gets the Unicode extension `nu`.

## private

    my $locale = Locale::Unicode->new( 'ja-JP' );
    $locale->private( 'something-else' );
    # Now: ja-JP-x-something-else

This serves to set or get the value for a private subtag.

## region

    # current value: fr-FR
    $locale->region( 'DE' );
    # Now: fr-DE

Sets or gets the `region` part of a Unicode locale.

This is normally an ISO3166-1 country code.

## region\_override

    my $locale = Locale::Unicode->new( 'en-GB' );
    $locale->region_override( 'uszzzz' );
    # Now: en-GB-u-rg-uszzzz
    # which is a locale for British English but with region-specific defaults set to US.

This is a Unicode Region Override that specifies an alternate region to use for obtaining certain region-specific default values.

Sets or gets the Unicode extension `rg`.

## reset

When provided with any argument, this will reset the cached value computed by ["as\_string"](#as_string)

## rg

This is an alias for ["region\_override"](#region_override)

## s0

This is an alias for ["source"](#source)

## script

    # current value: zh-Hans
    $locale->script( 'Hant' );
    # Now: zh-Hant

Sets or gets the `script` part of the Locale identifier.

## sd

This is an alias for ["subdivision"](#subdivision)

## sentence\_break

This is a Unicode Sentence Break Suppressions Identifier that specifies a set of data to be used for suppressing certain sentence breaks.

Sets or gets the Unicode extension `ss`.

## source

This is a transformation source for non-languages or scripts, such as fullwidth-halfwidth conversion.

Sets or gets the Transformation extension `s0`.

See the section on ["Transform extensions"](#transform-extensions) for more information.

## ss

This is an alias for ["sentence\_break"](#sentence_break)

## subdivision

    my $locale = Locale::Unicode->new( 'gsw' );
    $locale->subdivision( 'chzh' );
    # or
    # $locale->sd( 'chzh' );
    # Now: gsw-u-sd-chzh

    my $locale = Locale::Unicode->new( 'en-US' );
    $locale->sd( 'usca' );
    # Now: en-US-u-sd-usca

This is a Unicode Subdivision Identifier that specifies a regional subdivision used for locale. This is typically the States in the U.S., or prefectures in France or Japan, or provinces in Canada.

Sets or gets the Unicode extension `sd`.

Be careful of the rule in the standard. For example, `en-CA-u-sd-gbsct` would be invalid because `gb` in `gbsct` does not match the region subtag `CA`

## t0

This is an alias for ["machine"](#machine)

## t\_private

    my $locale = Locale::Unicode->new( 'ja' );
    $locale->transform( 'und' );
    $locale->t_private( 'medical' );
    # Now: ja-t-de-t0-und-x0-medical

This is a private transformation subtag.

Sets or gets the Transformation private subtag `x0`.

## t\_x0

This is an alias for ["t\_private"](#t_private)

## time\_zone

This is a Unicode Timezone Identifier that specifies a time zone.

Sets or gets the Unicode extension `tz`.

## timezone

This is an alias for ["time\_zone"](#time_zone)

## transform

    my $locale = Locale::Unicode->new( 'ja' );
    $locale->transform( 'it' );
    # Now: ja-t-it
    # which is Japanese, transformed from Italian

    my $locale = Locale::Unicode->new( 'ja-Kana' );
    $locale->transform( 'it' );
    # Now: ja-Kana-t-it
    # which is Japanese Katakana, transformed from Italian

    # 'und' is undefined and is perfectly valid
    my $locale = Locale::Unicode->new( 'und-Latn' );
    $locale->transform( 'und-cyrl' );
    # Now: und-Latn-t-und-cyrl
    # which is Latin script, transformed from the Cyrillic script

Sets or gets the Transformation extension `t`.

## transform\_locale

    my $locale = Locale::Unicode->new( 'ja' );
    my $locale2 = Locale::Unicode->new( 'it' );
    $locale->transform_locale( $locale2 );
    # Now: ja-t-it
    my $object = $locale->transform_locale;

Sets or gets a [Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode) object used to indicate the original locale subject to transformation.

This will trigger an [exception](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3AException) if a value, other than `Locale::Unicode` or an inheriting class object, is set.

See the section on ["Transform extensions"](#transform-extensions) for more information.

## translation

Sets or gets the Transformation extension `t0`.

## true

This is read-only and returns a [Locale::Unicode::Boolean](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3ABoolean) object representing a true value.

## tz

This is an alias for ["time\_zone"](#time_zone)

## unit

This is a Measurement Unit Preference Override that specifies an override for measurement unit preference.

Sets or gets the Unicode extension `mu`.

## va

This is an alias for ["variant"](#variant)

## variant

This is a Unicode Variant Identifier that specifies a special variant used for locales.

Sets or gets the Unicode extension `va`.

## vt

This is an alias for ["colVariableTop"](#colvariabletop)

# CLASS FUNCTIONS

## matches

Provided with a BCP47 locale, and this returns an hash reference of its components if it matches the BCP47 regular expression, which can be accessed as global class variable `$LOCALE_RE`.

If nothing matches, it returns an empty string in scalar context, or an empty list in list context.

If an error occurs, its sets an [error object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) and returns `undef` in scalar context, or an empty list in list context.

## parse

    my $hash_ref = Locale::Unicode->parse( 'ja-Kana-t-it' );
    # Transcription in Japanese Katakana of an Italian word:
    # {
    #     ext_transform => "t-it",
    #     ext_transform_subtag => "it",
    #     locale => "ja",
    #     script => "Kana",
    # }
    my $hash_ref = Locale::Unicode->parse( 'he-IL-u-ca-hebrew-tz-jeruslm' );
    # Represents Hebrew as spoken in Israel, using the traditional Hebrew calendar, 
    # and in the "Asia/Jerusalem" time zone
    # {
    #     country_code => "IL",
    #     ext_unicode => "u-ca-hebrew-tz-jeruslm",
    #     ext_unicode_subtag => "ca-hebrew-tz-jeruslm",
    #     locale => "he",
    # }

Provided with a BCP47 locale, and an optional hash reference like the one returned by [matches](#matches), and this will return an hash reference with detailed broken down of the locale embedded information, as per the Unicode BCP47 standard.

## tz\_id2name

Provided with a CLDR timezone ID, such as `jptyo` for `Asia/Tokyo`, and this returns the IANA Olson name equivalent, which, in this case, would be `Asia/Tokyo`

If an error occurs, its sets an [error object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) and returns `undef` in scalar context, or an empty list in list context.

## tz\_id2names

    my $ref = Locale::Unicode->tz_id2names( 'unknown' );
    # yields an empty array object
    my $ref = Locale::Unicode->tz_id2names( 'jptyo' );
    # Asia/Tokyo

Provided with a CLDR timezone ID, such as `ausyd`, which stands primarily for `Australia/Sydney`, and this returns an [array object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AArray) of IANA Olson timezone names, which, in this case, would yield: `['Australia/Sydney', 'Australia/ACT', 'Australia/Canberra', 'Australia/NSW']`

The order is set by [BCP47 timezone data](https://github.com/unicode-org/cldr/blob/main/common/bcp47/timezone.xml)

If an error occurs, its sets an [error object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) and returns `undef` in scalar context, or an empty list in list context.

## tz\_info

    my $def = Locale::Unicode->tz_id2names( 'jptyo' );
    # yields the following hash reference:
    # {
    #     alias => [qw( Asia/Tokyo Japan )],
    #     desc => "Tokyo, Japan",
    #     tz => "Asia/Tokyo",
    # }
    my $def = Locale::Unicode->tz_id2names( 'unknown' );
    # yields an empty string (not undef)

Provided with a CLDR timezone ID, such as `jptyo` and this returns an hash reference representing the dictionary entry for that ID.

If no information exists for the given timezone ID, an empty string is returned. `undef` is returned only for errors.

If an error occurs, its sets an [error object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) and returns `undef` in scalar context, or an empty list in list context.

## tz\_name2id

    my $id = Locale::Unicode->tz_name2id( 'Asia/Tokyo' );
    # jptyo
    my $id = Locale::Unicode->tz_name2id( 'Australia/Canberra' );
    # ausyd

Provided with an IANA Olson timezone name, such as `Asia/Tokyo` and this returns its CLDR equivalent, which, in this case, would be `jptyo`

If none exists, an empty string is returned.

If an error occurs, its sets an [error object](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AException) and returns `undef` in scalar context, or an empty list in list context.

# OVERLOADING

Any object from this class is overloaded and stringifies to its locale representation.

For example:

    my $locale = Locale::Unicode->new('ja-Kana-t-it' );
    say $locale; # ja-Kana-t-it
    $locale->transform( 'de' );
    say $locale; # ja-Kana-t-de

# BCP47 EXTENSIONS

## Unicode extensions

Example:

- `gsw-u-sd-chzh`

Known [BCP47 language extensions](https://unicode.org/reports/tr35/#u_Extension) as defined in [RFC6067](https://datatracker.ietf.org/doc/html/rfc6067) are as follows:

- `ca`

    A [Unicode calendar identifier](https://unicode.org/reports/tr35/#UnicodeCalendarIdentifier) that specifies a type of calendar used for formatting and parsing, such as date/time symbols and patterns; it also selects supplemental calendarData used for calendrical calculations. The value can affect the computation of the first day of the week.

    For example:

    - `ja-u-ca-japanese`

        Japanese Imperial calendar

    - `th-u-ca-buddhist`

        Thai with Buddist calendar

    Possible [values](https://github.com/unicode-org/cldr/blob/main/common/bcp47/calendar.xml) are:

    - `buddhist`

        Thai Buddhist calendar

    - `chinese`

        Traditional Chinese calendar

    - `coptic`

        Coptic calendar

    - `dangi`

        Traditional Korean calendar

    - `ethioaa`

        Ethiopic calendar, Amete Alem (epoch approx. 5493 B.C.E)

    - `ethiopic`

        Ethiopic calendar, Amete Mihret (epoch approx, 8 C.E.)

    - `gregory`

        Gregorian calendar

    - `hebrew`

        Traditional Hebrew calendar

    - `indian`

        Indian calendar

    - `islamic`

        Hijri calendar

    - `islamic-civil`

        Hijri calendar, tabular (intercalary years \[2,5,7,10,13,16,18,21,24,26,29\] - civil epoch)

    - `islamic-rgsa`

        Hijri calendar, Saudi Arabia sighting

    - `islamic-tbla`

        Hijri calendar, tabular (intercalary years \[2,5,7,10,13,16,18,21,24,26,29\] - astronomical epoch)

    - `islamic-umalqura`

        Hijri calendar, Umm al-Qura

    - `islamicc`

        Civil (algorithmic) Arabic calendar

    - `iso8601`

        ISO calendar (Gregorian calendar using the ISO 8601 calendar week rules)

    - `japanese`

        Japanese Imperial calendar

    - `persian`

        Persian calendar

    - `roc`

        Republic of China calendar

- `cf`

    A [Unicode currency format identifier](https://unicode.org/reports/tr35/#UnicodeCurrencyFormatIdentifier)

    Typical values are:

    - `standard`

        Default value. Negative numbers use the minusSign symbol.

    - `account`

        Negative numbers use parentheses or equivalent.

- `co`

    A [Unicode collation identifier](https://unicode.org/reports/tr35/#UnicodeCollationIdentifier) that specifies a type of collation (sort order).

    Possible [values](https://github.com/unicode-org/cldr/blob/main/common/bcp47/collation.xml) are:

    - `big5han`

        Pinyin ordering for Latin, big5 charset ordering for CJK characters (used in Chinese)

    - `compat`

        A previous version of the ordering, for compatibility

    - `dict`

        Dictionary style ordering (such as in Sinhala)

    - `direct`

        Binary code point order (used in Hindi)

    - `ducet`

        The default Unicode collation element table order

    - `emoji`

        Recommended ordering for emoji characters

    - `eor`

        European ordering rules

    - `gb2312`

        Pinyin ordering for Latin, gb2312han charset ordering for CJK characters (used in Chinese)

    - `phonebk`

        Phonebook style ordering (such as in German)

    - `phonetic`

        Phonetic ordering (sorting based on pronunciation)

    - `pinyin`

        Pinyin ordering for Latin and for CJK characters (used in Chinese)

    - `reformed`

        Reformed ordering (such as in Swedish)

    - `search`

        Special collation type for string search

    - `searchjl`

        Special collation type for Korean initial consonant search

    - `standard`

        Default ordering for each language

    - `stroke`

        Pinyin ordering for Latin, stroke order for CJK characters (used in Chinese)

    - `trad`

        Traditional style ordering (such as in Spanish)

    - `unihan`

        Pinyin ordering for Latin, Unihan radical-stroke ordering for CJK characters (used in Chinese)

    - `zhuyin`

        Pinyin ordering for Latin, zhuyin order for Bopomofo and CJK characters (used in Chinese)

    For example: `de-u-co-phonebk-ka-shifted` (German using Phonebook sorting, ignore punct.)

- `cu`

    A [Unicode Currency Identifier](https://unicode.org/reports/tr35/#UnicodeCurrencyIdentifier) that specifies a type of currency ([ISO 4217 code](https://github.com/unicode-org/cldr/blob/main/common/bcp47/currency.xml)) consisting of 3 ASCII letters that are or have been valid in ISO 4217, plus certain additional codes that are or have been in common use.

    For example: `ja-u-cu-jpy` (Japanese yens)

- `dx`

    A [Unicode Dictionary Break Exclusion Identifier](https://unicode.org/reports/tr35/#UnicodeDictionaryBreakExclusionIdentifier) specifies scripts to be excluded from dictionary-based text break (for words and lines).

    A proper value is one or more Unicode script subtags separated by hyphen. Their order is not important, but canonical order is alphabetical, such as `dx-hani-thai`

    For example:

    - `dx-hani-hira-kata`
    - `dx-thai-hani`

- `em`

    A [Unicode Emoji Presentation Style Identifier](https://unicode.org/reports/tr35/#UnicodeEmojiPresentationStyleIdentifier) specifies a request for the preferred emoji presentation style.

    Possible [values](https://github.com/unicode-org/cldr/blob/main/common/bcp47/variant.xml) are:

    - `emoji`

        Use an emoji presentation for emoji characters if possible.

    - `text`

        Use a text presentation for emoji characters if possible.

    - `default`

        Use the default presentation for emoji characters as specified in [UTR #51](https://www.unicode.org/reports/tr51/#Presentation_Style)

- `fw`

    A [Unicode First Day Identifier](https://unicode.org/reports/tr35/#UnicodeFirstDayIdentifier) defines the preferred first day of the week for calendar display.

    Possible [values](https://github.com/unicode-org/cldr/blob/main/common/bcp47/calendar.xml) are:

    - `sun`

        Sunday

    - `mon`

        Monday

    - `tue`

        Tuesday

    - `wed`

        Wednesday

    - `thu`

        Thursday

    - `fri`

        Friday

    - `sat`

        Saturday

- `hc`

    A [Unicode Hour Cycle Identifier](https://unicode.org/reports/tr35/#UnicodeHourCycleIdentifier) defines the preferred time cycle.

    Possible [values](https://github.com/unicode-org/cldr/blob/main/common/bcp47/calendar.xml) are:

    - `h12`

        Hour system using 1–12; corresponds to `h` in patterns

    - `h23`

        Hour system using 0–23; corresponds to `H` in patterns

    - `h11`

        Hour system using 0–11; corresponds to `K` in patterns

    - `h24`

        Hour system using 1–24; corresponds to `k` in pattern

- `lb`

    A [Unicode Line Break Style Identifier](https://unicode.org/reports/tr35/#UnicodeLineBreakStyleIdentifier) defines a preferred line break style corresponding to the [CSS level 3 line-break option](https://drafts.csswg.org/css-text/#line-break-property).

    Possible [values](https://github.com/unicode-org/cldr/blob/10ed3348d56be1c9fdadeb0a793a9b909eac3151/common/bcp47/segmentation.xml#L16) are:

    - `strict`

        CSS level 3 line-break=strict, e.g. treat CJ as NS

    - `normal`

        CSS level 3 line-break=normal, e.g. treat CJ as ID, break before hyphens for ja,zh

    - `loose`

        CSS lev 3 line-break=loose

- `lw`

    A [Unicode Line Break Word Identifier](https://unicode.org/reports/tr35/#UnicodeLineBreakWordIdentifier) defines preferred line break word handling behavior corresponding to the [CSS level 3 word-break option](https://drafts.csswg.org/css-text/#word-break-property).

    Possible [values](https://github.com/unicode-org/cldr/blob/main/common/bcp47/segmentation.xml) are:

    - `normal`

        CSS level 3 word-break=normal, normal script/language behavior for midword breaks

    - `breakall`

        CSS level 3 word-break=break-all, allow midword breaks unless forbidden by lb setting

    - `keepall`

        CSS level 3 word-break=keep-all, prohibit midword breaks except for dictionary breaks

    - `phrase`

        Prioritise keeping natural phrases (of multiple words) together when breaking, used in short text like title and headline

- `ms`

    A [Unicode Measurement System Identifier](https://unicode.org/reports/tr35/#UnicodeMeasurementSystemIdentifier) defines a preferred measurement system. Specifying "ms" in a locale identifier overrides the default value specified by supplemental measurement system data for the region

    Possible [values](https://github.com/unicode-org/cldr/blob/main/common/bcp47/measure.xml) are:

    - `metric`

        Metric System

    - `ussystem`

        US System of measurement: feet, pints, etc.; pints are 16oz

    - `uksystem`

        UK System of measurement: feet, pints, etc.; pints are 20oz

- `mu`

    A [Measurement Unit Preference Override](https://unicode.org/reports/tr35/#MeasurementUnitPreferenceOverride) defines an override for measurement unit preference.

    Possible [values](https://github.com/unicode-org/cldr/blob/main/common/bcp47/measure.xml) are:

    - `celsius`

        Celsius as temperature unit

    - `kelvin`

        Kelvin as temperature unit

    - `fahrenhe`

        Fahrenheit as temperature unit

- `nu`

    A [Unicode Number System Identifier](https://unicode.org/reports/tr35/#UnicodeNumberSystemIdentifier) defines a type of number system.

    For example: `ar-u-nu-native` (Arabic with native digits such as "٠١٢٣٤"), or `ar-u-nu-latn` (Arabic with Western digits such as "01234")

    Possible [values](https://github.com/unicode-org/cldr/blob/main/common/bcp47/number.xml) are:

    - `4-letters Unicode script subtag`
    - `arabext`

        Extended Arabic-Indic digits ("arab" means the base Arabic-Indic digits)

    - `armnlow`

        Armenian lowercase numerals

    - `finance`

        Financial numerals

    - `fullwide`

        Full width digits

    - `greklow`

        Greek lower case numerals

    - `hanidays`

        Han-character day-of-month numbering for lunar/other traditional calendars

    - `hanidec`

        Positional decimal system using Chinese number ideographs as digits

    - `hansfin`

        Simplified Chinese financial numerals

    - `hantfin`

        Traditional Chinese financial numerals

    - `jpanfin`

        Japanese financial numerals

    - `jpanyear`

        Japanese first-year Gannen numbering for Japanese calendar

    - `lanatham`

        Tai Tham Tham (ecclesiastical) digits

    - `mathbold`

        Mathematical bold digits

    - `mathdbl`

        Mathematical double-struck digits

    - `mathmono`

        Mathematical monospace digits

    - `mathsanb`

        Mathematical sans-serif bold digits

    - `mathsans`

        Mathematical sans-serif digits

    - `mymrepka`

        Myanmar Eastern Pwo Karen digits

    - `mymrpao`

        Myanmar Pao digits

    - `mymrshan`

        Myanmar Shan digits

    - `mymrtlng`

        Myanmar Tai Laing digits

    - `native`

        Native digits

    - `outlined`

        Legacy computing outlined digits

    - `roman`

        Roman numerals

    - `romanlow`

        Roman lowercase numerals

    - `segment`

        Legacy computing segmented digits

    - `tamldec`

        Modern Tamil decimal digits

    - `traditio`

        Traditional numerals

- `rg`

    A [Region Override](https://unicode.org/reports/tr35/#RegionOverride) specifies an alternate region to use for obtaining certain region-specific default values

    For example: `en-GB-u-rg-uszzzz` representing a locale for British English but with region-specific defaults set to US.

- `sd`

    A [Unicode Subdivision Identifier](https://unicode.org/reports/tr35/#UnicodeSubdivisionIdentifier) defines a [regional subdivision](https://unicode.org/reports/tr35/#Unicode_Subdivision_Codes) used for locales.

    They are called various names, such as a state in the United States, or a prefecture in Japan or France, or a province in Canada.

    For example:

    - `en-u-sd-uszzzz`

        Subdivision codes for unknown values are the region code plus `zzzz`, such as here with `uszzzz` for an unknown subdivision of the US.

    - `en-US-u-sd-usca`

        English as used in California, USA

    `en-CA-u-sd-gbsct` would be invalid because `gb` in `gbsct` does not match the region subtag `CA`

- `ss`

    A [Unicode Sentence Break Suppressions Identifier](https://unicode.org/reports/tr35/#UnicodeSentenceBreakSuppressionsIdentifier) defines a set of data to be used for suppressing certain sentence breaks

    Possible [values](https://github.com/unicode-org/cldr/blob/10ed3348d56be1c9fdadeb0a793a9b909eac3151/common/bcp47/segmentation.xml#L29) are:

    - `none` (default)

        Do not use sentence break suppressions data

    - `standard`

        Use sentence break suppressions data of type `standard`

- `tz`

    A [Unicode Timezone Identifier](https://unicode.org/reports/tr35/#UnicodeTimezoneIdentifier) defines a timezone.

    To access those values, check the class functions ["tz\_id2name"](#tz_id2name), [tz\_id2names](https://metacpan.org/pod/tz_id2names), ["tz\_info"](#tz_info) and ["tz\_name2id"](#tz_name2id)

    Possible [values](https://github.com/unicode-org/cldr/blob/main/common/bcp47/timezone.xml) are:

    - `adalv`

        Name: Andorra

        Time zone: `Europe/Andorra`

    - `aedxb`

        Name: Dubai, United Arab Emirates

        Time zone: `Asia/Dubai`

    - `afkbl`

        Name: Kabul, Afghanistan

        Time zone: `Asia/Kabul`

    - `aganu`

        Name: Antigua

        Time zone: `America/Antigua`

    - `aiaxa`

        Name: Anguilla

        Time zone: `America/Anguilla`

    - `altia`

        Name: Tirane, Albania

        Time zone: `Europe/Tirane`

    - `amevn`

        Name: Yerevan, Armenia

        Time zone: `Asia/Yerevan`

    - `ancur`

        Name: Curaçao

        Time zone: `America/Curacao`

    - `aolad`

        Name: Luanda, Angola

        Time zone: `Africa/Luanda`

    - `aqams`

        Amundsen-Scott Station, South Pole

        Deprecated. See instead `nzakl`

    - `aqcas`

        Name: Casey Station, Bailey Peninsula

        Time zone: `Antarctica/Casey`

    - `aqdav`

        Name: Davis Station, Vestfold Hills

        Time zone: `Antarctica/Davis`

    - `aqddu`

        Name: Dumont d'Urville Station, Terre Adélie

        Time zone: `Antarctica/DumontDUrville`

    - `aqmaw`

        Name: Mawson Station, Holme Bay

        Time zone: `Antarctica/Mawson`

    - `aqmcm`

        Name: McMurdo Station, Ross Island

        Time zone: `Antarctica/McMurdo`

    - `aqplm`

        Name: Palmer Station, Anvers Island

        Time zone: `Antarctica/Palmer`

    - `aqrot`

        Name: Rothera Station, Adelaide Island

        Time zone: `Antarctica/Rothera`

    - `aqsyw`

        Name: Syowa Station, East Ongul Island

        Time zone: `Antarctica/Syowa`

    - `aqtrl`

        Name: Troll Station, Queen Maud Land

        Time zone: `Antarctica/Troll`

    - `aqvos`

        Name: Vostok Station, Lake Vostok

        Time zone: `Antarctica/Vostok`

    - `arbue`

        Name: Buenos Aires, Argentina

        Time zone: `America/Buenos_Aires`, `America/Argentina/Buenos_Aires`

    - `arcor`

        Name: Córdoba, Argentina

        Time zone: `America/Cordoba`, `America/Argentina/Cordoba`, `America/Rosario`

    - `arctc`

        Name: Catamarca, Argentina

        Time zone: `America/Catamarca`, `America/Argentina/Catamarca`, `America/Argentina/ComodRivadavia`

    - `arirj`

        Name: La Rioja, Argentina

        Time zone: `America/Argentina/La_Rioja`

    - `arjuj`

        Name: Jujuy, Argentina

        Time zone: `America/Jujuy`, `America/Argentina/Jujuy`

    - `arluq`

        Name: San Luis, Argentina

        Time zone: `America/Argentina/San_Luis`

    - `armdz`

        Name: Mendoza, Argentina

        Time zone: `America/Mendoza`, `America/Argentina/Mendoza`

    - `arrgl`

        Name: Río Gallegos, Argentina

        Time zone: `America/Argentina/Rio_Gallegos`

    - `arsla`

        Name: Salta, Argentina

        Time zone: `America/Argentina/Salta`

    - `artuc`

        Name: Tucumán, Argentina

        Time zone: `America/Argentina/Tucuman`

    - `aruaq`

        Name: San Juan, Argentina

        Time zone: `America/Argentina/San_Juan`

    - `arush`

        Name: Ushuaia, Argentina

        Time zone: `America/Argentina/Ushuaia`

    - `asppg`

        Name: Pago Pago, American Samoa

        Time zone: `Pacific/Pago_Pago`, `Pacific/Samoa`, `US/Samoa`

    - `atvie`

        Name: Vienna, Austria

        Time zone: `Europe/Vienna`

    - `auadl`

        Name: Adelaide, Australia

        Time zone: `Australia/Adelaide`, `Australia/South`

    - `aubhq`

        Name: Broken Hill, Australia

        Time zone: `Australia/Broken_Hill`, `Australia/Yancowinna`

    - `aubne`

        Name: Brisbane, Australia

        Time zone: `Australia/Brisbane`, `Australia/Queensland`

    - `audrw`

        Name: Darwin, Australia

        Time zone: `Australia/Darwin`, `Australia/North`

    - `aueuc`

        Name: Eucla, Australia

        Time zone: `Australia/Eucla`

    - `auhba`

        Name: Hobart, Australia

        Time zone: `Australia/Hobart`, `Australia/Tasmania`, `Australia/Currie`

    - `aukns`

        Currie, Australia

        Deprecated. See instead `auhba`

    - `auldc`

        Name: Lindeman Island, Australia

        Time zone: `Australia/Lindeman`

    - `auldh`

        Name: Lord Howe Island, Australia

        Time zone: `Australia/Lord_Howe`, `Australia/LHI`

    - `aumel`

        Name: Melbourne, Australia

        Time zone: `Australia/Melbourne`, `Australia/Victoria`

    - `aumqi`

        Name: Macquarie Island Station, Macquarie Island

        Time zone: `Antarctica/Macquarie`

    - `auper`

        Name: Perth, Australia

        Time zone: `Australia/Perth`, `Australia/West`

    - `ausyd`

        Name: Sydney, Australia

        Time zone: `Australia/Sydney`, `Australia/ACT`, `Australia/Canberra`, `Australia/NSW`

    - `awaua`

        Name: Aruba

        Time zone: `America/Aruba`

    - `azbak`

        Name: Baku, Azerbaijan

        Time zone: `Asia/Baku`

    - `basjj`

        Name: Sarajevo, Bosnia and Herzegovina

        Time zone: `Europe/Sarajevo`

    - `bbbgi`

        Name: Barbados

        Time zone: `America/Barbados`

    - `bddac`

        Name: Dhaka, Bangladesh

        Time zone: `Asia/Dhaka`, `Asia/Dacca`

    - `bebru`

        Name: Brussels, Belgium

        Time zone: `Europe/Brussels`

    - `bfoua`

        Name: Ouagadougou, Burkina Faso

        Time zone: `Africa/Ouagadougou`

    - `bgsof`

        Name: Sofia, Bulgaria

        Time zone: `Europe/Sofia`

    - `bhbah`

        Name: Bahrain

        Time zone: `Asia/Bahrain`

    - `bibjm`

        Name: Bujumbura, Burundi

        Time zone: `Africa/Bujumbura`

    - `bjptn`

        Name: Porto-Novo, Benin

        Time zone: `Africa/Porto-Novo`

    - `bmbda`

        Name: Bermuda

        Time zone: `Atlantic/Bermuda`

    - `bnbwn`

        Name: Brunei

        Time zone: `Asia/Brunei`

    - `bolpb`

        Name: La Paz, Bolivia

        Time zone: `America/La_Paz`

    - `bqkra`

        Name: Bonaire, Sint Estatius and Saba

        Time zone: `America/Kralendijk`

    - `braux`

        Name: Araguaína, Brazil

        Time zone: `America/Araguaina`

    - `brbel`

        Name: Belém, Brazil

        Time zone: `America/Belem`

    - `brbvb`

        Name: Boa Vista, Brazil

        Time zone: `America/Boa_Vista`

    - `brcgb`

        Name: Cuiabá, Brazil

        Time zone: `America/Cuiaba`

    - `brcgr`

        Name: Campo Grande, Brazil

        Time zone: `America/Campo_Grande`

    - `brern`

        Name: Eirunepé, Brazil

        Time zone: `America/Eirunepe`

    - `brfen`

        Name: Fernando de Noronha, Brazil

        Time zone: `America/Noronha`, `Brazil/DeNoronha`

    - `brfor`

        Name: Fortaleza, Brazil

        Time zone: `America/Fortaleza`

    - `brmao`

        Name: Manaus, Brazil

        Time zone: `America/Manaus`, `Brazil/West`

    - `brmcz`

        Name: Maceió, Brazil

        Time zone: `America/Maceio`

    - `brpvh`

        Name: Porto Velho, Brazil

        Time zone: `America/Porto_Velho`

    - `brrbr`

        Name: Rio Branco, Brazil

        Time zone: `America/Rio_Branco`, `America/Porto_Acre`, `Brazil/Acre`

    - `brrec`

        Name: Recife, Brazil

        Time zone: `America/Recife`

    - `brsao`

        Name: São Paulo, Brazil

        Time zone: `America/Sao_Paulo`, `Brazil/East`

    - `brssa`

        Name: Bahia, Brazil

        Time zone: `America/Bahia`

    - `brstm`

        Name: Santarém, Brazil

        Time zone: `America/Santarem`

    - `bsnas`

        Name: Nassau, Bahamas

        Time zone: `America/Nassau`

    - `btthi`

        Name: Thimphu, Bhutan

        Time zone: `Asia/Thimphu`, `Asia/Thimbu`

    - `bwgbe`

        Name: Gaborone, Botswana

        Time zone: `Africa/Gaborone`

    - `bymsq`

        Name: Minsk, Belarus

        Time zone: `Europe/Minsk`

    - `bzbze`

        Name: Belize

        Time zone: `America/Belize`

    - `cacfq`

        Name: Creston, Canada

        Time zone: `America/Creston`

    - `caedm`

        Name: Edmonton, Canada

        Time zone: `America/Edmonton`, `Canada/Mountain`, `America/Yellowknife`

    - `caffs`

        Rainy River, Canada

        Deprecated. See instead `cawnp`

    - `cafne`

        Name: Fort Nelson, Canada

        Time zone: `America/Fort_Nelson`

    - `caglb`

        Name: Glace Bay, Canada

        Time zone: `America/Glace_Bay`

    - `cagoo`

        Name: Goose Bay, Canada

        Time zone: `America/Goose_Bay`

    - `cahal`

        Name: Halifax, Canada

        Time zone: `America/Halifax`, `Canada/Atlantic`

    - `caiql`

        Name: Iqaluit, Canada

        Time zone: `America/Iqaluit`, `America/Pangnirtung`

    - `camon`

        Name: Moncton, Canada

        Time zone: `America/Moncton`

    - `camtr`

        Montreal, Canada

        Deprecated. See instead `cator`

    - `capnt`

        Pangnirtung, Canada

        Deprecated. See instead `caiql`

    - `careb`

        Name: Resolute, Canada

        Time zone: `America/Resolute`

    - `careg`

        Name: Regina, Canada

        Time zone: `America/Regina`, `Canada/East-Saskatchewan`, `Canada/Saskatchewan`

    - `casjf`

        Name: St. John's, Canada

        Time zone: `America/St_Johns`, `Canada/Newfoundland`

    - `canpg`

        Nipigon, Canada

        Deprecated. See instead `cator`

    - `cathu`

        Thunder Bay, Canada

        Deprecated. See instead `cator`

    - `cator`

        Name: Toronto, Canada

        Time zone: `America/Toronto`, `America/Montreal`, `Canada/Eastern`, `America/Nipigon`, `America/Thunder_Bay`

    - `cavan`

        Name: Vancouver, Canada

        Time zone: `America/Vancouver`, `Canada/Pacific`

    - `cawnp`

        Name: Winnipeg, Canada

        Time zone: `America/Winnipeg`, `Canada/Central`, `America/Rainy_River`

    - `caybx`

        Name: Blanc-Sablon, Canada

        Time zone: `America/Blanc-Sablon`

    - `caycb`

        Name: Cambridge Bay, Canada

        Time zone: `America/Cambridge_Bay`

    - `cayda`

        Name: Dawson, Canada

        Time zone: `America/Dawson`

    - `caydq`

        Name: Dawson Creek, Canada

        Time zone: `America/Dawson_Creek`

    - `cayek`

        Name: Rankin Inlet, Canada

        Time zone: `America/Rankin_Inlet`

    - `cayev`

        Name: Inuvik, Canada

        Time zone: `America/Inuvik`

    - `cayxy`

        Name: Whitehorse, Canada

        Time zone: `America/Whitehorse`, `Canada/Yukon`

    - `cayyn`

        Name: Swift Current, Canada

        Time zone: `America/Swift_Current`

    - `cayzf`

        Yellowknife, Canada

        Deprecated. See instead `caedm`

    - `cayzs`

        Name: Atikokan, Canada

        Time zone: `America/Coral_Harbour`, `America/Atikokan`

    - `cccck`

        Name: Cocos (Keeling) Islands

        Time zone: `Indian/Cocos`

    - `cdfbm`

        Name: Lubumbashi, Democratic Republic of the Congo

        Time zone: `Africa/Lubumbashi`

    - `cdfih`

        Name: Kinshasa, Democratic Republic of the Congo

        Time zone: `Africa/Kinshasa`

    - `cfbgf`

        Name: Bangui, Central African Republic

        Time zone: `Africa/Bangui`

    - `cgbzv`

        Name: Brazzaville, Republic of the Congo

        Time zone: `Africa/Brazzaville`

    - `chzrh`

        Name: Zurich, Switzerland

        Time zone: `Europe/Zurich`

    - `ciabj`

        Name: Abidjan, Côte d'Ivoire

        Time zone: `Africa/Abidjan`

    - `ckrar`

        Name: Rarotonga, Cook Islands

        Time zone: `Pacific/Rarotonga`

    - `clipc`

        Name: Easter Island, Chile

        Time zone: `Pacific/Easter`, `Chile/EasterIsland`

    - `clpuq`

        Name: Punta Arenas, Chile

        Time zone: `America/Punta_Arenas`

    - `clscl`

        Name: Santiago, Chile

        Time zone: `America/Santiago`, `Chile/Continental`

    - `cmdla`

        Name: Douala, Cameroon

        Time zone: `Africa/Douala`

    - `cnckg`

        Chongqing, China

        Deprecated. See instead `cnsha`

    - `cnhrb`

        Harbin, China

        Deprecated. See instead `cnsha`

    - `cnkhg`

        Kashgar, China

        Deprecated. See instead `cnurc`

    - `cnsha`

        Name: Shanghai, China

        Time zone: `Asia/Shanghai`, `Asia/Chongqing`, `Asia/Chungking`, `Asia/Harbin`, `PRC`

    - `cnurc`

        Name: Ürümqi, China

        Time zone: `Asia/Urumqi`, `Asia/Kashgar`

    - `cobog`

        Name: Bogotá, Colombia

        Time zone: `America/Bogota`

    - `crsjo`

        Name: Costa Rica

        Time zone: `America/Costa_Rica`

    - `cst6cdt`

        Name: POSIX style time zone for US Central Time

        Time zone: `CST6CDT`

    - `cuhav`

        Name: Havana, Cuba

        Time zone: `America/Havana`, `Cuba`

    - `cvrai`

        Name: Cape Verde

        Time zone: `Atlantic/Cape_Verde`

    - `cxxch`

        Name: Christmas Island

        Time zone: `Indian/Christmas`

    - `cyfmg`

        Name: Famagusta, Cyprus

        Time zone: `Asia/Famagusta`

    - `cynic`

        Name: Nicosia, Cyprus

        Time zone: `Asia/Nicosia`, `Europe/Nicosia`

    - `czprg`

        Name: Prague, Czech Republic

        Time zone: `Europe/Prague`

    - `deber`

        Name: Berlin, Germany

        Time zone: `Europe/Berlin`

    - `debsngn`

        Name: Busingen, Germany

        Time zone: `Europe/Busingen`

    - `djjib`

        Name: Djibouti

        Time zone: `Africa/Djibouti`

    - `dkcph`

        Name: Copenhagen, Denmark

        Time zone: `Europe/Copenhagen`

    - `dmdom`

        Name: Dominica

        Time zone: `America/Dominica`

    - `dosdq`

        Name: Santo Domingo, Dominican Republic

        Time zone: `America/Santo_Domingo`

    - `dzalg`

        Name: Algiers, Algeria

        Time zone: `Africa/Algiers`

    - `ecgps`

        Name: Galápagos Islands, Ecuador

        Time zone: `Pacific/Galapagos`

    - `ecgye`

        Name: Guayaquil, Ecuador

        Time zone: `America/Guayaquil`

    - `eetll`

        Name: Tallinn, Estonia

        Time zone: `Europe/Tallinn`

    - `egcai`

        Name: Cairo, Egypt

        Time zone: `Africa/Cairo`, `Egypt`

    - `eheai`

        Name: El Aaiún, Western Sahara

        Time zone: `Africa/El_Aaiun`

    - `erasm`

        Name: Asmara, Eritrea

        Time zone: `Africa/Asmera`, `Africa/Asmara`

    - `esceu`

        Name: Ceuta, Spain

        Time zone: `Africa/Ceuta`

    - `eslpa`

        Name: Canary Islands, Spain

        Time zone: `Atlantic/Canary`

    - `esmad`

        Name: Madrid, Spain

        Time zone: `Europe/Madrid`

    - `est5edt`

        Name: POSIX style time zone for US Eastern Time

        Time zone: `EST5EDT`

    - `etadd`

        Name: Addis Ababa, Ethiopia

        Time zone: `Africa/Addis_Ababa`

    - `fihel`

        Name: Helsinki, Finland

        Time zone: `Europe/Helsinki`

    - `fimhq`

        Name: Mariehamn, Åland, Finland

        Time zone: `Europe/Mariehamn`

    - `fjsuv`

        Name: Fiji

        Time zone: `Pacific/Fiji`

    - `fkpsy`

        Name: Stanley, Falkland Islands

        Time zone: `Atlantic/Stanley`

    - `fmksa`

        Name: Kosrae, Micronesia

        Time zone: `Pacific/Kosrae`

    - `fmpni`

        Name: Pohnpei, Micronesia

        Time zone: `Pacific/Ponape`, `Pacific/Pohnpei`

    - `fmtkk`

        Name: Chuuk, Micronesia

        Time zone: `Pacific/Truk`, `Pacific/Chuuk`, `Pacific/Yap`

    - `fotho`

        Name: Faroe Islands

        Time zone: `Atlantic/Faeroe`, `Atlantic/Faroe`

    - `frpar`

        Name: Paris, France

        Time zone: `Europe/Paris`

    - `galbv`

        Name: Libreville, Gabon

        Time zone: `Africa/Libreville`

    - `gaza`

        Gaza Strip, Palestinian Territories

        Deprecated. See instead `gazastrp`

    - `gazastrp`

        Name: Gaza Strip, Palestinian Territories

        Time zone: `Asia/Gaza`

    - `gblon`

        Name: London, United Kingdom

        Time zone: `Europe/London`, `Europe/Belfast`, `GB`, `GB-Eire`

    - `gdgnd`

        Name: Grenada

        Time zone: `America/Grenada`

    - `getbs`

        Name: Tbilisi, Georgia

        Time zone: `Asia/Tbilisi`

    - `gfcay`

        Name: Cayenne, French Guiana

        Time zone: `America/Cayenne`

    - `gggci`

        Name: Guernsey

        Time zone: `Europe/Guernsey`

    - `ghacc`

        Name: Accra, Ghana

        Time zone: `Africa/Accra`

    - `gigib`

        Name: Gibraltar

        Time zone: `Europe/Gibraltar`

    - `gldkshvn`

        Name: Danmarkshavn, Greenland

        Time zone: `America/Danmarkshavn`

    - `glgoh`

        Name: Nuuk (Godthåb), Greenland

        Time zone: `America/Godthab`, `America/Nuuk`

    - `globy`

        Name: Ittoqqortoormiit (Scoresbysund), Greenland

        Time zone: `America/Scoresbysund`

    - `glthu`

        Name: Qaanaaq (Thule), Greenland

        Time zone: `America/Thule`

    - `gmbjl`

        Name: Banjul, Gambia

        Time zone: `Africa/Banjul`

    - `gmt`

        Name: Greenwich Mean Time

        Time zone: `Etc/GMT`, `Etc/GMT+0`, `Etc/GMT-0`, `Etc/GMT0`, `Etc/Greenwich`, `GMT`, `GMT+0`, `GMT-0`, `GMT0`, `Greenwich`

    - `gncky`

        Name: Conakry, Guinea

        Time zone: `Africa/Conakry`

    - `gpbbr`

        Name: Guadeloupe

        Time zone: `America/Guadeloupe`

    - `gpmsb`

        Name: Marigot, Saint Martin

        Time zone: `America/Marigot`

    - `gpsbh`

        Name: Saint Barthélemy

        Time zone: `America/St_Barthelemy`

    - `gqssg`

        Name: Malabo, Equatorial Guinea

        Time zone: `Africa/Malabo`

    - `grath`

        Name: Athens, Greece

        Time zone: `Europe/Athens`

    - `gsgrv`

        Name: South Georgia and the South Sandwich Islands

        Time zone: `Atlantic/South_Georgia`

    - `gtgua`

        Name: Guatemala

        Time zone: `America/Guatemala`

    - `gugum`

        Name: Guam

        Time zone: `Pacific/Guam`

    - `gwoxb`

        Name: Bissau, Guinea-Bissau

        Time zone: `Africa/Bissau`

    - `gygeo`

        Name: Guyana

        Time zone: `America/Guyana`

    - `hebron`

        Name: West Bank, Palestinian Territories

        Time zone: `Asia/Hebron`

    - `hkhkg`

        Name: Hong Kong SAR China

        Time zone: `Asia/Hong_Kong`, `Hongkong`

    - `hntgu`

        Name: Tegucigalpa, Honduras

        Time zone: `America/Tegucigalpa`

    - `hrzag`

        Name: Zagreb, Croatia

        Time zone: `Europe/Zagreb`

    - `htpap`

        Name: Port-au-Prince, Haiti

        Time zone: `America/Port-au-Prince`

    - `hubud`

        Name: Budapest, Hungary

        Time zone: `Europe/Budapest`

    - `iddjj`

        Name: Jayapura, Indonesia

        Time zone: `Asia/Jayapura`

    - `idjkt`

        Name: Jakarta, Indonesia

        Time zone: `Asia/Jakarta`

    - `idmak`

        Name: Makassar, Indonesia

        Time zone: `Asia/Makassar`, `Asia/Ujung_Pandang`

    - `idpnk`

        Name: Pontianak, Indonesia

        Time zone: `Asia/Pontianak`

    - `iedub`

        Name: Dublin, Ireland

        Time zone: `Europe/Dublin`, `Eire`

    - `imdgs`

        Name: Isle of Man

        Time zone: `Europe/Isle_of_Man`

    - `inccu`

        Name: Kolkata, India

        Time zone: `Asia/Calcutta`, `Asia/Kolkata`

    - `iodga`

        Name: Chagos Archipelago

        Time zone: `Indian/Chagos`

    - `iqbgw`

        Name: Baghdad, Iraq

        Time zone: `Asia/Baghdad`

    - `irthr`

        Name: Tehran, Iran

        Time zone: `Asia/Tehran`, `Iran`

    - `isrey`

        Name: Reykjavik, Iceland

        Time zone: `Atlantic/Reykjavik`, `Iceland`

    - `itrom`

        Name: Rome, Italy

        Time zone: `Europe/Rome`

    - `jeruslm`

        Name: Jerusalem

        Time zone: `Asia/Jerusalem`, `Asia/Tel_Aviv`, `Israel`

    - `jesth`

        Name: Jersey

        Time zone: `Europe/Jersey`

    - `jmkin`

        Name: Jamaica

        Time zone: `America/Jamaica`, `Jamaica`

    - `joamm`

        Name: Amman, Jordan

        Time zone: `Asia/Amman`

    - `jptyo`

        Name: Tokyo, Japan

        Time zone: `Asia/Tokyo`, `Japan`

    - `kenbo`

        Name: Nairobi, Kenya

        Time zone: `Africa/Nairobi`

    - `kgfru`

        Name: Bishkek, Kyrgyzstan

        Time zone: `Asia/Bishkek`

    - `khpnh`

        Name: Phnom Penh, Cambodia

        Time zone: `Asia/Phnom_Penh`

    - `kicxi`

        Name: Kiritimati, Kiribati

        Time zone: `Pacific/Kiritimati`

    - `kipho`

        Name: Enderbury Island, Kiribati

        Time zone: `Pacific/Enderbury`, `Pacific/Kanton`

    - `kitrw`

        Name: Tarawa, Kiribati

        Time zone: `Pacific/Tarawa`

    - `kmyva`

        Name: Comoros

        Time zone: `Indian/Comoro`

    - `knbas`

        Name: Saint Kitts

        Time zone: `America/St_Kitts`

    - `kpfnj`

        Name: Pyongyang, North Korea

        Time zone: `Asia/Pyongyang`

    - `krsel`

        Name: Seoul, South Korea

        Time zone: `Asia/Seoul`, `ROK`

    - `kwkwi`

        Name: Kuwait

        Time zone: `Asia/Kuwait`

    - `kygec`

        Name: Cayman Islands

        Time zone: `America/Cayman`

    - `kzaau`

        Name: Aqtau, Kazakhstan

        Time zone: `Asia/Aqtau`

    - `kzakx`

        Name: Aqtobe, Kazakhstan

        Time zone: `Asia/Aqtobe`

    - `kzala`

        Name: Almaty, Kazakhstan

        Time zone: `Asia/Almaty`

    - `kzguw`

        Name: Atyrau (Guryev), Kazakhstan

        Time zone: `Asia/Atyrau`

    - `kzksn`

        Name: Qostanay (Kostanay), Kazakhstan

        Time zone: `Asia/Qostanay`

    - `kzkzo`

        Name: Kyzylorda, Kazakhstan

        Time zone: `Asia/Qyzylorda`

    - `kzura`

        Name: Oral, Kazakhstan

        Time zone: `Asia/Oral`

    - `lavte`

        Name: Vientiane, Laos

        Time zone: `Asia/Vientiane`

    - `lbbey`

        Name: Beirut, Lebanon

        Time zone: `Asia/Beirut`

    - `lccas`

        Name: Saint Lucia

        Time zone: `America/St_Lucia`

    - `livdz`

        Name: Vaduz, Liechtenstein

        Time zone: `Europe/Vaduz`

    - `lkcmb`

        Name: Colombo, Sri Lanka

        Time zone: `Asia/Colombo`

    - `lrmlw`

        Name: Monrovia, Liberia

        Time zone: `Africa/Monrovia`

    - `lsmsu`

        Name: Maseru, Lesotho

        Time zone: `Africa/Maseru`

    - `ltvno`

        Name: Vilnius, Lithuania

        Time zone: `Europe/Vilnius`

    - `lulux`

        Name: Luxembourg

        Time zone: `Europe/Luxembourg`

    - `lvrix`

        Name: Riga, Latvia

        Time zone: `Europe/Riga`

    - `lytip`

        Name: Tripoli, Libya

        Time zone: `Africa/Tripoli`, `Libya`

    - `macas`

        Name: Casablanca, Morocco

        Time zone: `Africa/Casablanca`

    - `mcmon`

        Name: Monaco

        Time zone: `Europe/Monaco`

    - `mdkiv`

        Name: Chişinău, Moldova

        Time zone: `Europe/Chisinau`, `Europe/Tiraspol`

    - `metgd`

        Name: Podgorica, Montenegro

        Time zone: `Europe/Podgorica`

    - `mgtnr`

        Name: Antananarivo, Madagascar

        Time zone: `Indian/Antananarivo`

    - `mhkwa`

        Name: Kwajalein, Marshall Islands

        Time zone: `Pacific/Kwajalein`, `Kwajalein`

    - `mhmaj`

        Name: Majuro, Marshall Islands

        Time zone: `Pacific/Majuro`

    - `mkskp`

        Name: Skopje, Macedonia

        Time zone: `Europe/Skopje`

    - `mlbko`

        Name: Bamako, Mali

        Time zone: `Africa/Bamako`, `Africa/Timbuktu`

    - `mmrgn`

        Name: Yangon (Rangoon), Burma

        Time zone: `Asia/Rangoon`, `Asia/Yangon`

    - `mncoq`

        Name: Choibalsan, Mongolia

        Time zone: `Asia/Choibalsan`

    - `mnhvd`

        Name: Khovd (Hovd), Mongolia

        Time zone: `Asia/Hovd`

    - `mnuln`

        Name: Ulaanbaatar (Ulan Bator), Mongolia

        Time zone: `Asia/Ulaanbaatar`, `Asia/Ulan_Bator`

    - `momfm`

        Name: Macau SAR China

        Time zone: `Asia/Macau`, `Asia/Macao`

    - `mpspn`

        Name: Saipan, Northern Mariana Islands

        Time zone: `Pacific/Saipan`

    - `mqfdf`

        Name: Martinique

        Time zone: `America/Martinique`

    - `mrnkc`

        Name: Nouakchott, Mauritania

        Time zone: `Africa/Nouakchott`

    - `msmni`

        Name: Montserrat

        Time zone: `America/Montserrat`

    - `mst7mdt`

        Name: POSIX style time zone for US Mountain Time

        Time zone: `MST7MDT`

    - `mtmla`

        Name: Malta

        Time zone: `Europe/Malta`

    - `muplu`

        Name: Mauritius

        Time zone: `Indian/Mauritius`

    - `mvmle`

        Name: Maldives

        Time zone: `Indian/Maldives`

    - `mwblz`

        Name: Blantyre, Malawi

        Time zone: `Africa/Blantyre`

    - `mxchi`

        Name: Chihuahua, Mexico

        Time zone: `America/Chihuahua`

    - `mxcun`

        Name: Cancún, Mexico

        Time zone: `America/Cancun`

    - `mxcjs`

        Name: Ciudad Juárez, Mexico

        Time zone: `America/Ciudad_Juarez`

    - `mxhmo`

        Name: Hermosillo, Mexico

        Time zone: `America/Hermosillo`

    - `mxmam`

        Name: Matamoros, Mexico

        Time zone: `America/Matamoros`

    - `mxmex`

        Name: Mexico City, Mexico

        Time zone: `America/Mexico_City`, `Mexico/General`

    - `mxmid`

        Name: Mérida, Mexico

        Time zone: `America/Merida`

    - `mxmty`

        Name: Monterrey, Mexico

        Time zone: `America/Monterrey`

    - `mxmzt`

        Name: Mazatlán, Mexico

        Time zone: `America/Mazatlan`, `Mexico/BajaSur`

    - `mxoji`

        Name: Ojinaga, Mexico

        Time zone: `America/Ojinaga`

    - `mxpvr`

        Name: Bahía de Banderas, Mexico

        Time zone: `America/Bahia_Banderas`

    - `mxstis`

        Santa Isabel (Baja California), Mexico

        Deprecated. See instead `mxtij`

    - `mxtij`

        Name: Tijuana, Mexico

        Time zone: `America/Tijuana`, `America/Ensenada`, `Mexico/BajaNorte`, `America/Santa_Isabel`

    - `mykch`

        Name: Kuching, Malaysia

        Time zone: `Asia/Kuching`

    - `mykul`

        Name: Kuala Lumpur, Malaysia

        Time zone: `Asia/Kuala_Lumpur`

    - `mzmpm`

        Name: Maputo, Mozambique

        Time zone: `Africa/Maputo`

    - `nawdh`

        Name: Windhoek, Namibia

        Time zone: `Africa/Windhoek`

    - `ncnou`

        Name: Noumea, New Caledonia

        Time zone: `Pacific/Noumea`

    - `nenim`

        Name: Niamey, Niger

        Time zone: `Africa/Niamey`

    - `nfnlk`

        Name: Norfolk Island

        Time zone: `Pacific/Norfolk`

    - `nglos`

        Name: Lagos, Nigeria

        Time zone: `Africa/Lagos`

    - `nimga`

        Name: Managua, Nicaragua

        Time zone: `America/Managua`

    - `nlams`

        Name: Amsterdam, Netherlands

        Time zone: `Europe/Amsterdam`

    - `noosl`

        Name: Oslo, Norway

        Time zone: `Europe/Oslo`

    - `npktm`

        Name: Kathmandu, Nepal

        Time zone: `Asia/Katmandu`, `Asia/Kathmandu`

    - `nrinu`

        Name: Nauru

        Time zone: `Pacific/Nauru`

    - `nuiue`

        Name: Niue

        Time zone: `Pacific/Niue`

    - `nzakl`

        Name: Auckland, New Zealand

        Time zone: `Pacific/Auckland`, `Antarctica/South_Pole`, `NZ`

    - `nzcht`

        Name: Chatham Islands, New Zealand

        Time zone: `Pacific/Chatham`, `NZ-CHAT`

    - `ommct`

        Name: Muscat, Oman

        Time zone: `Asia/Muscat`

    - `papty`

        Name: Panama

        Time zone: `America/Panama`

    - `pelim`

        Name: Lima, Peru

        Time zone: `America/Lima`

    - `pfgmr`

        Name: Gambiera Islands, French Polynesia

        Time zone: `Pacific/Gambier`

    - `pfnhv`

        Name: Marquesas Islands, French Polynesia

        Time zone: `Pacific/Marquesas`

    - `pfppt`

        Name: Tahiti, French Polynesia

        Time zone: `Pacific/Tahiti`

    - `pgpom`

        Name: Port Moresby, Papua New Guinea

        Time zone: `Pacific/Port_Moresby`

    - `pgraw`

        Name: Bougainville, Papua New Guinea

        Time zone: `Pacific/Bougainville`

    - `phmnl`

        Name: Manila, Philippines

        Time zone: `Asia/Manila`

    - `pkkhi`

        Name: Karachi, Pakistan

        Time zone: `Asia/Karachi`

    - `plwaw`

        Name: Warsaw, Poland

        Time zone: `Europe/Warsaw`, `Poland`

    - `pmmqc`

        Name: Saint Pierre and Miquelon

        Time zone: `America/Miquelon`

    - `pnpcn`

        Name: Pitcairn Islands

        Time zone: `Pacific/Pitcairn`

    - `prsju`

        Name: Puerto Rico

        Time zone: `America/Puerto_Rico`

    - `pst8pdt`

        Name: POSIX style time zone for US Pacific Time

        Time zone: `PST8PDT`

    - `ptfnc`

        Name: Madeira, Portugal

        Time zone: `Atlantic/Madeira`

    - `ptlis`

        Name: Lisbon, Portugal

        Time zone: `Europe/Lisbon`, `Portugal`

    - `ptpdl`

        Name: Azores, Portugal

        Time zone: `Atlantic/Azores`

    - `pwror`

        Name: Palau

        Time zone: `Pacific/Palau`

    - `pyasu`

        Name: Asunción, Paraguay

        Time zone: `America/Asuncion`

    - `qadoh`

        Name: Qatar

        Time zone: `Asia/Qatar`

    - `rereu`

        Name: Réunion

        Time zone: `Indian/Reunion`

    - `robuh`

        Name: Bucharest, Romania

        Time zone: `Europe/Bucharest`

    - `rsbeg`

        Name: Belgrade, Serbia

        Time zone: `Europe/Belgrade`

    - `ruasf`

        Name: Astrakhan, Russia

        Time zone: `Europe/Astrakhan`

    - `rubax`

        Name: Barnaul, Russia

        Time zone: `Asia/Barnaul`

    - `ruchita`

        Name: Chita Zabaykalsky, Russia

        Time zone: `Asia/Chita`

    - `rudyr`

        Name: Anadyr, Russia

        Time zone: `Asia/Anadyr`

    - `rugdx`

        Name: Magadan, Russia

        Time zone: `Asia/Magadan`

    - `ruikt`

        Name: Irkutsk, Russia

        Time zone: `Asia/Irkutsk`

    - `rukgd`

        Name: Kaliningrad, Russia

        Time zone: `Europe/Kaliningrad`

    - `rukhndg`

        Name: Khandyga Tomponsky, Russia

        Time zone: `Asia/Khandyga`

    - `rukra`

        Name: Krasnoyarsk, Russia

        Time zone: `Asia/Krasnoyarsk`

    - `rukuf`

        Name: Samara, Russia

        Time zone: `Europe/Samara`

    - `rukvx`

        Name: Kirov, Russia

        Time zone: `Europe/Kirov`

    - `rumow`

        Name: Moscow, Russia

        Time zone: `Europe/Moscow`, `W-SU`

    - `runoz`

        Name: Novokuznetsk, Russia

        Time zone: `Asia/Novokuznetsk`

    - `ruoms`

        Name: Omsk, Russia

        Time zone: `Asia/Omsk`

    - `ruovb`

        Name: Novosibirsk, Russia

        Time zone: `Asia/Novosibirsk`

    - `rupkc`

        Name: Kamchatka Peninsula, Russia

        Time zone: `Asia/Kamchatka`

    - `rurtw`

        Name: Saratov, Russia

        Time zone: `Europe/Saratov`

    - `rusred`

        Name: Srednekolymsk, Russia

        Time zone: `Asia/Srednekolymsk`

    - `rutof`

        Name: Tomsk, Russia

        Time zone: `Asia/Tomsk`

    - `ruuly`

        Name: Ulyanovsk, Russia

        Time zone: `Europe/Ulyanovsk`

    - `ruunera`

        Name: Ust-Nera Oymyakonsky, Russia

        Time zone: `Asia/Ust-Nera`

    - `ruuus`

        Name: Sakhalin, Russia

        Time zone: `Asia/Sakhalin`

    - `ruvog`

        Name: Volgograd, Russia

        Time zone: `Europe/Volgograd`

    - `ruvvo`

        Name: Vladivostok, Russia

        Time zone: `Asia/Vladivostok`

    - `ruyek`

        Name: Yekaterinburg, Russia

        Time zone: `Asia/Yekaterinburg`

    - `ruyks`

        Name: Yakutsk, Russia

        Time zone: `Asia/Yakutsk`

    - `rwkgl`

        Name: Kigali, Rwanda

        Time zone: `Africa/Kigali`

    - `saruh`

        Name: Riyadh, Saudi Arabia

        Time zone: `Asia/Riyadh`

    - `sbhir`

        Name: Guadalcanal, Solomon Islands

        Time zone: `Pacific/Guadalcanal`

    - `scmaw`

        Name: Mahé, Seychelles

        Time zone: `Indian/Mahe`

    - `sdkrt`

        Name: Khartoum, Sudan

        Time zone: `Africa/Khartoum`

    - `sesto`

        Name: Stockholm, Sweden

        Time zone: `Europe/Stockholm`

    - `sgsin`

        Name: Singapore

        Time zone: `Asia/Singapore`, `Singapore`

    - `shshn`

        Name: Saint Helena

        Time zone: `Atlantic/St_Helena`

    - `silju`

        Name: Ljubljana, Slovenia

        Time zone: `Europe/Ljubljana`

    - `sjlyr`

        Name: Longyearbyen, Svalbard

        Time zone: `Arctic/Longyearbyen`, `Atlantic/Jan_Mayen`

    - `skbts`

        Name: Bratislava, Slovakia

        Time zone: `Europe/Bratislava`

    - `slfna`

        Name: Freetown, Sierra Leone

        Time zone: `Africa/Freetown`

    - `smsai`

        Name: San Marino

        Time zone: `Europe/San_Marino`

    - `sndkr`

        Name: Dakar, Senegal

        Time zone: `Africa/Dakar`

    - `somgq`

        Name: Mogadishu, Somalia

        Time zone: `Africa/Mogadishu`

    - `srpbm`

        Name: Paramaribo, Suriname

        Time zone: `America/Paramaribo`

    - `ssjub`

        Name: Juba, South Sudan

        Time zone: `Africa/Juba`

    - `sttms`

        Name: São Tomé, São Tomé and Príncipe

        Time zone: `Africa/Sao_Tome`

    - `svsal`

        Name: El Salvador

        Time zone: `America/El_Salvador`

    - `sxphi`

        Name: Sint Maarten

        Time zone: `America/Lower_Princes`

    - `sydam`

        Name: Damascus, Syria

        Time zone: `Asia/Damascus`

    - `szqmn`

        Name: Mbabane, Swaziland

        Time zone: `Africa/Mbabane`

    - `tcgdt`

        Name: Grand Turk, Turks and Caicos Islands

        Time zone: `America/Grand_Turk`

    - `tdndj`

        Name: N'Djamena, Chad

        Time zone: `Africa/Ndjamena`

    - `tfpfr`

        Name: Kerguelen Islands, French Southern Territories

        Time zone: `Indian/Kerguelen`

    - `tglfw`

        Name: Lomé, Togo

        Time zone: `Africa/Lome`

    - `thbkk`

        Name: Bangkok, Thailand

        Time zone: `Asia/Bangkok`

    - `tjdyu`

        Name: Dushanbe, Tajikistan

        Time zone: `Asia/Dushanbe`

    - `tkfko`

        Name: Fakaofo, Tokelau

        Time zone: `Pacific/Fakaofo`

    - `tldil`

        Name: Dili, East Timor

        Time zone: `Asia/Dili`

    - `tmasb`

        Name: Ashgabat, Turkmenistan

        Time zone: `Asia/Ashgabat`, `Asia/Ashkhabad`

    - `tntun`

        Name: Tunis, Tunisia

        Time zone: `Africa/Tunis`

    - `totbu`

        Name: Tongatapu, Tonga

        Time zone: `Pacific/Tongatapu`

    - `trist`

        Name: Istanbul, Türkiye

        Time zone: `Europe/Istanbul`, `Asia/Istanbul`, `Turkey`

    - `ttpos`

        Name: Port of Spain, Trinidad and Tobago

        Time zone: `America/Port_of_Spain`

    - `tvfun`

        Name: Funafuti, Tuvalu

        Time zone: `Pacific/Funafuti`

    - `twtpe`

        Name: Taipei, Taiwan

        Time zone: `Asia/Taipei`, `ROC`

    - `tzdar`

        Name: Dar es Salaam, Tanzania

        Time zone: `Africa/Dar_es_Salaam`

    - `uaiev`

        Name: Kyiv, Ukraine

        Time zone: `Europe/Kiev`, `Europe/Kyiv`, `Europe/Zaporozhye`, `Europe/Uzhgorod`

    - `uaozh`

        Zaporizhia (Zaporozhye), Ukraine

        Deprecated. See instead `uaiev`

    - `uasip`

        Name: Simferopol, Ukraine

        Time zone: `Europe/Simferopol`

    - `uauzh`

        Uzhhorod (Uzhgorod), Ukraine

        Deprecated. See instead `uaiev`

    - `ugkla`

        Name: Kampala, Uganda

        Time zone: `Africa/Kampala`

    - `umawk`

        Name: Wake Island, U.S. Minor Outlying Islands

        Time zone: `Pacific/Wake`

    - `umjon`

        Johnston Atoll, U.S. Minor Outlying Islands

        Deprecated. See instead `ushnl`

    - `ummdy`

        Name: Midway Islands, U.S. Minor Outlying Islands

        Time zone: `Pacific/Midway`

    - `unk`

        Name: Unknown time zone

        Time zone: `Etc/Unknown`

    - `usadk`

        Name: Adak (Alaska), United States

        Time zone: `America/Adak`, `America/Atka`, `US/Aleutian`

    - `usaeg`

        Name: Marengo (Indiana), United States

        Time zone: `America/Indiana/Marengo`

    - `usanc`

        Name: Anchorage, United States

        Time zone: `America/Anchorage`, `US/Alaska`

    - `usboi`

        Name: Boise (Idaho), United States

        Time zone: `America/Boise`

    - `uschi`

        Name: Chicago, United States

        Time zone: `America/Chicago`, `US/Central`

    - `usden`

        Name: Denver, United States

        Time zone: `America/Denver`, `America/Shiprock`, `Navajo`, `US/Mountain`

    - `usdet`

        Name: Detroit, United States

        Time zone: `America/Detroit`, `US/Michigan`

    - `ushnl`

        Name: Honolulu, United States

        Time zone: `Pacific/Honolulu`, `US/Hawaii`, `Pacific/Johnston`

    - `usind`

        Name: Indianapolis, United States

        Time zone: `America/Indianapolis`, `America/Fort_Wayne`, `America/Indiana/Indianapolis`, `US/East-Indiana`

    - `usinvev`

        Name: Vevay (Indiana), United States

        Time zone: `America/Indiana/Vevay`

    - `usjnu`

        Name: Juneau (Alaska), United States

        Time zone: `America/Juneau`

    - `usknx`

        Name: Knox (Indiana), United States

        Time zone: `America/Indiana/Knox`, `America/Knox_IN`, `US/Indiana-Starke`

    - `uslax`

        Name: Los Angeles, United States

        Time zone: `America/Los_Angeles`, `US/Pacific`, `US/Pacific-New`

    - `uslui`

        Name: Louisville (Kentucky), United States

        Time zone: `America/Louisville`, `America/Kentucky/Louisville`

    - `usmnm`

        Name: Menominee (Michigan), United States

        Time zone: `America/Menominee`

    - `usmtm`

        Name: Metlakatla (Alaska), United States

        Time zone: `America/Metlakatla`

    - `usmoc`

        Name: Monticello (Kentucky), United States

        Time zone: `America/Kentucky/Monticello`

    - `usnavajo`

        Shiprock (Navajo), United States

        Deprecated. See instead `usden`

    - `usndcnt`

        Name: Center (North Dakota), United States

        Time zone: `America/North_Dakota/Center`

    - `usndnsl`

        Name: New Salem (North Dakota), United States

        Time zone: `America/North_Dakota/New_Salem`

    - `usnyc`

        Name: New York, United States

        Time zone: `America/New_York`, `US/Eastern`

    - `usoea`

        Name: Vincennes (Indiana), United States

        Time zone: `America/Indiana/Vincennes`

    - `usome`

        Name: Nome (Alaska), United States

        Time zone: `America/Nome`

    - `usphx`

        Name: Phoenix, United States

        Time zone: `America/Phoenix`, `US/Arizona`

    - `ussit`

        Name: Sitka (Alaska), United States

        Time zone: `America/Sitka`

    - `ustel`

        Name: Tell City (Indiana), United States

        Time zone: `America/Indiana/Tell_City`

    - `uswlz`

        Name: Winamac (Indiana), United States

        Time zone: `America/Indiana/Winamac`

    - `uswsq`

        Name: Petersburg (Indiana), United States

        Time zone: `America/Indiana/Petersburg`

    - `usxul`

        Name: Beulah (North Dakota), United States

        Time zone: `America/North_Dakota/Beulah`

    - `usyak`

        Name: Yakutat (Alaska), United States

        Time zone: `America/Yakutat`

    - `utc`

        Name: UTC (Coordinated Universal Time)

        Time zone: `Etc/UTC`, `Etc/UCT`, `Etc/Universal`, `Etc/Zulu`, `UCT`, `UTC`, `Universal`, `Zulu`

    - `utce01`

        Name: 1 hour ahead of UTC

        Time zone: `Etc/GMT-1`

    - `utce02`

        Name: 2 hours ahead of UTC

        Time zone: `Etc/GMT-2`

    - `utce03`

        Name: 3 hours ahead of UTC

        Time zone: `Etc/GMT-3`

    - `utce04`

        Name: 4 hours ahead of UTC

        Time zone: `Etc/GMT-4`

    - `utce05`

        Name: 5 hours ahead of UTC

        Time zone: `Etc/GMT-5`

    - `utce06`

        Name: 6 hours ahead of UTC

        Time zone: `Etc/GMT-6`

    - `utce07`

        Name: 7 hours ahead of UTC

        Time zone: `Etc/GMT-7`

    - `utce08`

        Name: 8 hours ahead of UTC

        Time zone: `Etc/GMT-8`

    - `utce09`

        Name: 9 hours ahead of UTC

        Time zone: `Etc/GMT-9`

    - `utce10`

        Name: 10 hours ahead of UTC

        Time zone: `Etc/GMT-10`

    - `utce11`

        Name: 11 hours ahead of UTC

        Time zone: `Etc/GMT-11`

    - `utce12`

        Name: 12 hours ahead of UTC

        Time zone: `Etc/GMT-12`

    - `utce13`

        Name: 13 hours ahead of UTC

        Time zone: `Etc/GMT-13`

    - `utce14`

        Name: 14 hours ahead of UTC

        Time zone: `Etc/GMT-14`

    - `utcw01`

        Name: 1 hour behind UTC

        Time zone: `Etc/GMT+1`

    - `utcw02`

        Name: 2 hours behind UTC

        Time zone: `Etc/GMT+2`

    - `utcw03`

        Name: 3 hours behind UTC

        Time zone: `Etc/GMT+3`

    - `utcw04`

        Name: 4 hours behind UTC

        Time zone: `Etc/GMT+4`

    - `utcw05`

        Name: 5 hours behind UTC

        Time zone: `Etc/GMT+5`, `EST`

    - `utcw06`

        Name: 6 hours behind UTC

        Time zone: `Etc/GMT+6`

    - `utcw07`

        Name: 7 hours behind UTC

        Time zone: `Etc/GMT+7`, `MST`

    - `utcw08`

        Name: 8 hours behind UTC

        Time zone: `Etc/GMT+8`

    - `utcw09`

        Name: 9 hours behind UTC

        Time zone: `Etc/GMT+9`

    - `utcw10`

        Name: 10 hours behind UTC

        Time zone: `Etc/GMT+10`, `HST`

    - `utcw11`

        Name: 11 hours behind UTC

        Time zone: `Etc/GMT+11`

    - `utcw12`

        Name: 12 hours behind UTC

        Time zone: `Etc/GMT+12`

    - `uymvd`

        Name: Montevideo, Uruguay

        Time zone: `America/Montevideo`

    - `uzskd`

        Name: Samarkand, Uzbekistan

        Time zone: `Asia/Samarkand`

    - `uztas`

        Name: Tashkent, Uzbekistan

        Time zone: `Asia/Tashkent`

    - `vavat`

        Name: Vatican City

        Time zone: `Europe/Vatican`

    - `vcsvd`

        Name: Saint Vincent, Saint Vincent and the Grenadines

        Time zone: `America/St_Vincent`

    - `veccs`

        Name: Caracas, Venezuela

        Time zone: `America/Caracas`

    - `vgtov`

        Name: Tortola, British Virgin Islands

        Time zone: `America/Tortola`

    - `vistt`

        Name: Saint Thomas, U.S. Virgin Islands

        Time zone: `America/St_Thomas`, `America/Virgin`

    - `vnsgn`

        Name: Ho Chi Minh City, Vietnam

        Time zone: `Asia/Saigon`, `Asia/Ho_Chi_Minh`

    - `vuvli`

        Name: Efate, Vanuatu

        Time zone: `Pacific/Efate`

    - `wfmau`

        Name: Wallis Islands, Wallis and Futuna

        Time zone: `Pacific/Wallis`

    - `wsapw`

        Name: Apia, Samoa

        Time zone: `Pacific/Apia`

    - `yeade`

        Name: Aden, Yemen

        Time zone: `Asia/Aden`

    - `ytmam`

        Name: Mayotte

        Time zone: `Indian/Mayotte`

    - `zajnb`

        Name: Johannesburg, South Africa

        Time zone: `Africa/Johannesburg`

    - `zmlun`

        Name: Lusaka, Zambia

        Time zone: `Africa/Lusaka`

    - `zwhre`

        Name: Harare, Zimbabwe

        Time zone: `Africa/Harare`

    See the [standard documentation](https://unicode.org/reports/tr35/#Time_Zone_Identifiers) for more information.

- `va`

    A [Unicode Variant Identifier](https://unicode.org/reports/tr35/#UnicodeVariantIdentifier) defines a special variant used for locales.

## Transform extensions

This is used for transliterations, transcriptions, translations, etc, as per [RFC6497](https://datatracker.ietf.org/doc/html/rfc6497)>

For example:

- `ja-t-it`

    The content is Japanese, transformed from Italian.

- `ja-Kana-t-it`

    The content is Japanese Katakana, transformed from Italian.

- `und-Latn-t-und-cyrl`

    The content is in the Latin script, transformed from the Cyrillic script.

- `und-Cyrl-t-und-latn-m0-ungegn-2007`

    The content is in Cyrillic, transformed from Latin, according to a UNGEGN specification dated 2007.

    The date is of format `YYYYMMDD` all without space, and the month and day information should be provided only when necessary for clarification, as per the [RFC6497, section 2.5(c)](https://datatracker.ietf.org/doc/html/rfc6497#section-2.5)

- `und-Cyrl-t-und-latn-m0-ungegn`

    Same, but without year.

The complete list of valid subtags is as follows. They are all two to eight alphanumeric characters.

- `d0`

    Transform destination: for non-languages/scripts, such as fullwidth-halfwidth conversion

    See also `s0`

    Possible [values](https://github.com/unicode-org/cldr/blob/maint/maint-41/common/bcp47/transform-destination.xml) are:

    - `accents`

        Map base + punctuation, etc to accented characters

    - `ascii`

        Map as many characters to the closest ASCII character as possible

    - `casefold`

        Apply Unicode case folding

    - `charname`

        Map each character to its Unicode name

    - `digit`

        Convert to digit form of accent

    - `fcc`

        Map string to the FCC format; [http://unicode.org/notes/tn5](http://unicode.org/notes/tn5)

    - `fcd`

        Map string to the FCD format; [http://unicode.org/notes/tn5](http://unicode.org/notes/tn5)

    - `fwidth`

        Map characters to their fullwidth equivalents

    - `hex`

        Map characters to a hex equivalents, eg `a` to `\u0061`; for hex variants see [transform.xml](https://github.com/unicode-org/cldr/blob/maint/maint-41/common/bcp47/transform.xml)

    - `hwidth`

        Map characters to their halfwidth equivalents

    - `lower`

        Apply Unicode full lowercase mapping

    - `morse`

        Map Unicode to Morse Code encoding

    - `nfc`

        Map string to the Unicode NFC format

    - `nfd`

        Map string to the Unicode NFD format

    - `nfkc`

        Map string to the Unicode NFKC format

    - `nfkd`

        Map string to the Unicode NFKD format

    - `npinyin`

        Map pinyin written with tones to the numeric form

    - `null`

        Make no change in the string

    - `publish`

        Map to preferred forms for publishing, such as `, `, `—`

    - `remove`

        Remove every character in the string

    - `title`

        Apply Unicode full titlecase mapping

    - `upper`

        Apply Unicode full uppercase mapping

    - `zawgyi`

        Map Unicode to Zawgyi Myanmar encoding

- `h0`

    Hybrid Locale Identifiers: `h0` with the value `hybrid` indicates that the `-t-` value is a language that is mixed into the main language tag to form a hybrid.

    For [example](https://unicode.org/reports/tr35/#Hybrid_Locale):

    - `hi-t-en-h0-hybrid`

        Hybrid Deva - Hinglish

        Hindi-English hybrid where the script is Devanagari\*

    - `hi-Latn-t-en-h0-hybrid`

        Hybrid Latin - Hinglish

        Hindi-English hybrid where the script is Latin\*

    - `ru-t-en-h0-hybrid`

        Hybrid Cyrillic - Runglish

        Russian with an admixture of American English

    - `ru-t-en-gb-h0-hybrid`

        Hybrid Cyrillic - Runglish

        Russian with an admixture of British English

    - `en-t-zh-h0-hybrid`

        Hybrid Latin - Chinglish

        American English with an admixture of Chinese (Simplified Mandarin Chinese)

    - `en-t-zh-hant-h0-hybrid`

        Hybrid Latin - Chinglish

        American English with an admixture of Chinese (Traditional Mandarin Chinese)

- `i0`

    Input Method Engine transform: used to indicate an input method transformation, such as one used by a client-side input method. The first subfield in a sequence would typically be a `platform` or vendor designation.

    For example: `zh-t-i0-pinyin`

    Possible [values](https://github.com/unicode-org/cldr/blob/maint/maint-41/common/bcp47/transform_ime.xml) are:

    - `handwrit`

        Handwriting input: used when the only information known (or requested) is that the text was (or is to be) converted using an handwriting input.

    - `pinyin`

        Pinyin input: for simplified Chinese characters. See also [http://en.wikipedia.org/wiki/Pinyin\_method](http://en.wikipedia.org/wiki/Pinyin_method).

    - `und`

        The choice of input method is not specified. Used when the only information known (or requested) is that the text was (or is to be) converted using an input method engine

    - `wubi`

        Wubi input: for simplified Chinese characters. For background information, see [http://en.wikipedia.org/wiki/Wubi\_method](http://en.wikipedia.org/wiki/Wubi_method)

- `k0`

    Keyboard transform: used to indicate a keyboard transformation, such as one used by a client-side virtual keyboard. The first subfield in a sequence would typically be a `platform` designation, representing the platform that the keyboard is intended for.

    For example: `en-t-k0-dvorak`

    Possible [values](https://github.com/unicode-org/cldr/blob/maint/maint-41/common/bcp47/transform_keyboard.xml) are:

    - `101key`

        101 key layout.

    - `102key`

        102 key layout.

    - `600dpi`

        Keyboard for a 600 dpi device.

    - `768dpi`

        Keyboard for a 768 dpi device.

    - `android`

        Android keyboard.

    - `azerty`

        A AZERTY-based keyboard or one that approximates AZERTY in a different script.

    - `chromeos`

        ChromeOS keyboard.

    - `colemak`

        Colemak keyboard layout. The Colemak keyboard is an alternative to the QWERTY and dvorak keyboards. http://colemak.com/.

    - `dvorak`

        Dvorak keyboard layout. See also [http://en.wikipedia.org/wiki/Dvorak\_Simplified\_Keyboard](http://en.wikipedia.org/wiki/Dvorak_Simplified_Keyboard).

    - `dvorakl`

        Dvorak left-handed keyboard layout. See also [http://en.wikipedia.org/wiki/File:KB\_Dvorak\_Left.svg](http://en.wikipedia.org/wiki/File:KB_Dvorak_Left.svg).

    - `dvorakr`

        Dvorak right-handed keyboard layout. See also [http://en.wikipedia.org/wiki/File:KB\_Dvorak\_Right.svg](http://en.wikipedia.org/wiki/File:KB_Dvorak_Right.svg).

    - `el220`

        Greek 220 keyboard. See also [http://www.microsoft.com/resources/msdn/goglobal/keyboards/kbdhela2.html](http://www.microsoft.com/resources/msdn/goglobal/keyboards/kbdhela2.html).

    - `el319`

        Greek 319 keyboard. See also [ftp://ftp.software.ibm.com/software/globalization/keyboards/KBD319.pdf](ftp://ftp.software.ibm.com/software/globalization/keyboards/KBD319.pdf).

    - `extended`

        A keyboard that has been enhanced with a large number of extra characters.

    - `googlevk`

        Google virtual keyboard.

    - `isiri`

        Persian ISIRI keyboard. Based on ISIRI 2901:1994 standard. See also [http://behdad.org/download/Publications/persiancomputing/a007.pdf](http://behdad.org/download/Publications/persiancomputing/a007.pdf).

    - `legacy`

        A keyboard that has been replaced with a newer standard but is kept for legacy purposes.

    - `lt1205`

        Lithuanian standard keyboard, based on the LST 1205:1992 standard. See also [http://www.kada.lt/litwin/](http://www.kada.lt/litwin/).

    - `lt1582`

        Lithuanian standard keyboard, based on the LST 1582:2000 standard. See also [http://www.kada.lt/litwin/](http://www.kada.lt/litwin/).

    - `nutaaq`

        Inuktitut Nutaaq keyboard. See also [http://www.pirurvik.ca/en/webfm\_send/15](http://www.pirurvik.ca/en/webfm_send/15).

    - `osx`

        Mac OSX keyboard.

    - `patta`

        Thai Pattachote keyboard. This is a less frequently used layout in Thai (Kedmanee layout is more popular). See also [http://www.nectec.or.th/it-standards/keyboard\_layout/thai-key.htm](http://www.nectec.or.th/it-standards/keyboard_layout/thai-key.htm).

    - `qwerty`

        QWERTY-based keyboard or one that approximates QWERTY in a different script.

    - `qwertz`

        QWERTZ-based keyboard or one that approximates QWERTZ in a different script.

    - `ta99`

        Tamil 99 keyboard. See also [http://www.tamilvu.org/Tamilnet99/annex1.htm](http://www.tamilvu.org/Tamilnet99/annex1.htm).

    - `und`

        The vender for the keyboard is not specified. Used when the only information known (or requested) is that the text was (or is to be) converted using an keyboard.

    - `var`

        A keyboard layout with small variations from the default.

    - `viqr`

        Vietnamese VIQR layout, based on [http://tools.ietf.org/html/rfc1456](http://tools.ietf.org/html/rfc1456).

    - `windows`

        Windows keyboard.

- `m0`

    Transform extension mechanism: to reference an authority or rules for a type of transformation.

    For example: `und-Latn-t-ru-m0-ungegn-2007`

    Possible [values](https://github.com/unicode-org/cldr/blob/maint/maint-41/common/bcp47/transform.xml) are:

    - `aethiopi`

        Encylopedia Aethiopica Transliteration

    - `alaloc`

        American Library Association-Library of Congress

    - `betamets`

        Beta Maṣāḥǝft Transliteration

    - `bgn`

        US Board on Geographic Names

    - `buckwalt`

        Buckwalter Arabic transliteration system

    - `c11`

        for hex transforms, using the C11 syntax: \\u0061\\U0001F4D6

    - `css`

        for hex transforms, using the CSS syntax: \\61 \\01F4D6, spacing where necessary

    - `din`

        Deutsches Institut für Normung

    - `es3842`

        Ethiopian Standards Agency ES 3842:2014 Ethiopic-Latin Transliteration

    - `ewts`

        Extended Wylie Transliteration Scheme

    - `gost`

        Euro-Asian Council for Standardization, Metrology and Certification

    - `gurage`

        Gurage Legacy to Modern Transliteration

    - `gutgarts`

        Yaros Gutgarts Ethiopic-Cyrillic Transliteration

    - `iast`

        International Alphabet of Sanskrit Transliteration

    - `iesjes`

        IES/JES Amharic Transliteration

    - `iso`

        International Organization for Standardization

    - `java`

        for hex transforms, using the Java syntax: \\u0061\\uD83D\\uDCD6

    - `lambdin`

        Thomas Oden Lambdin Ethiopic-Latin Transliteration

    - `mcst`

        Korean Ministry of Culture, Sports and Tourism

    - `mns`

        Mongolian National Standard

    - `percent`

        for hex transforms, using the percent syntax: %61%F0%9F%93%96

    - `perl`

        for hex transforms, using the perl syntax: \\x{61}\\x{1F4D6}

    - `plain`

        for hex transforms, with no surrounding syntax, spacing where necessary: 0061 1F4D6

    - `prprname`

        transform variant for proper names

    - `satts`

        Standard Arabic Technical Transliteration System (SATTS)

    - `sera`

        System for Ethiopic Representation in ASCII

    - `tekieali`

        Tekie Alibekit Blin-Latin Transliteration

    - `ungegn`

        United Nations Group of Experts on Geographical Names

    - `unicode`

        to hex with the Unicode syntax: U+0061 U+1F4D6, spacing where necessary

    - `xaleget`

        Eritrean Ministry of Education Blin-Latin Transliteration

    - `xml`

        for hex transforms, using the xml syntax: &amp;#x61;&amp;#x1F4D6;

    - `xml10`

        for hex transforms, using the xml decimal syntax: &amp;#97;&amp;#128214;

- `s0`

    Transform source: for non-languages/scripts, such as fullwidth-halfwidth conversion

    See also `d0`

    Possible [values](https://github.com/unicode-org/cldr/blob/maint/maint-41/common/bcp47/transform-destination.xml) are:

    - `accents`

        Accented characters to map base + punctuation, etc

    - `ascii`

        Map from ASCII to the target, perhaps using different conventions

    - `hex`

        Map characters from hex equivalents, trying all variants, eg `U+0061` to `a`; for hex variants see [transform.xml](https://github.com/unicode-org/cldr/blob/maint/maint-41/common/bcp47/transform.xml)

    - `morse`

        Map Morse Code to Unicode encoding

    - `npinyin`

        Map the numeric form of pinyin to the tone format

    - `publish`

        Map publishing characters, such as `, `, `—`, to from vanilla characters

    - `zawgyi`

        Map Zawgyi Myanmar encoding to Unicode

- `t0`

    Machine Translation: used to indicate content that has been machine translated, or a request for a particular type of machine translation of content. The first subfield in a sequence would typically be a `platform` or vendor designation.

    For example: `ja-t-de-t0-und`

- `x0`

    Private Use.

    For example: `ja-t-de-t0-und-x0-medical`

## Collation Options

[Parametric settings](https://unicode.org/reports/tr35/tr35-collation.html#Setting_Options) can be specified in language tags or in rule syntax (in the form \[keyword value\] ). For example, -ks-level2 or \[strength 2\] will only compare strings based on their primary and secondary weights.

The options description below is taken from the LDML standard, and reflect how the algorithm works when implemented by web browser, or other runtime environment. This module does not do any of those algorithms. The documentation is only here for your benefit and convenience.

See the [standard documentation](https://unicode.org/reports/tr35/tr35-collation.html) and the [DUCET (Default Unicode Collation Element Table)](https://www.unicode.org/reports/tr10/#Default_Unicode_Collation_Element_Table) for more information.

- `ka` or `colAlternate`

    Sets alternate handling for variable weights.

    Possible [values](https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L34) are optional and can be:

    - `noignore` or `non-ignorable`

        Default value.

    - `shifted`

- `kb` or `colBackwards`

    Sets collation parameter key for backward collation weight.

    Sets alternate handling for variable weights.

    Possible [values](https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L39) are optional and can be: `true` or `yes`, `false` (default) or `no`

- `kc` or `colCaseLevel`

    Sets collation parameter key for case level.

    Specifies a boolean. If `on`, a level consisting only of case characteristics will be inserted in front of tertiary level, as a "Level 2.5". To ignore accents but take case into account, set strength to `primary` and case level to `on`.

    Possible [values](https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L44) are optional and can be: `true` or `yes`, `false` (default) or `no`

- `kf` or `colCaseFirst`

    Sets collation parameter key for ordering by case.

    If set to upper, causes upper case to sort before lower case. If set to lower, causes lower case to sort before upper case.

    Possible [values](https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L49) are: `upper`, `lower`, `false` (default) or `no`

- `kh` or `colHiraganaQuaternary`

    Sets collation parameter key for special Hiragana handling.

    This is deprecated by the LDML standard.

    Specifies a boolean. Controls special treatment of Hiragana code points on quaternary level. If turned on, Hiragana codepoints will get lower values than all the other non-variable code points in shifted.

    Possible [values](https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L55) are optional and can be: `true` (default) or `yes`, `false` or `no`

- `kk` or `colNormalization`

    Sets collation parameter key for normalisation.

    Specifies a boolean. If on, then the normal [UCA](https://www.unicode.org/reports/tr41/#UTS10) algorithm is used.

    Possible [values](https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L60) are optional and can be: `true` (default) or `yes`, `false` or `no`

- `kn` or `colNumeric`

    Sets collation parameter key for numeric handling.

    Specifies a boolean. If set to on, any sequence of Decimal Digits is sorted at a primary level with its numeric value.

    Possible [values](https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L65) are optional and can be: `true` or `yes`, `false` (default) or `no`

- `kr` or `colReorder`

    Sets collation reorder codes.

    Specifies a reordering of scripts or other significant blocks of characters such as symbols, punctuation, and digits.

    Possible [values](https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L70) are: `currency`, `digit`, `punct`, `space`, `symbol`, or any BCP47 script ID.

    Also possible: `others` where all codes not explicitly mentioned should be ordered. The script code Zzzz (Unknown Script) is a synonym for others.

    For example:

    - `en-u-kr-latn-digit`

        Reorder digits after Latin characters.

    - `en-u-kr-arab-cyrl-others-symbol`

        Reorder Arabic characters first, then Cyrillic, and put symbols at the end—after all other characters.

    - `en-u-kr-others`

        Remove any locale-specific reordering, and use DUCET order for reordering blocks.

- `ks` or `colStrength`

    Sets the collation parameter key for collation strength used for comparison.

    Possible [values](https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L79) are:

    - `level1` or `primary`
    - `level2` or `secondary`
    - `level3` (default) or `tertiary`
    - `level4` or `quaternary` or `quarternary`
    - `identic` or `identical`

- `kv`

    Sets the collation parameter key for `maxVariable`, the last reordering group to be affected by `ka-shifted`.

    Possible values are:

    - `currency`

        Spaces, punctuation and all symbols are affected by ka-shifted.

    - `punct`

        Spaces and punctuation are affected by ka-shifted (CLDR default).

    - `space`

        Only spaces are affected by ka-shifted.

    - `symbol`

        Spaces, punctuation and symbols except for currency symbols are affected by ka-shifted (UCA default).

- `vt`

    Sets the parameter key for the variable top.

    **This is deprecated by the LDML standard.**

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# SEE ALSO

[https://github.com/unicode-org/cldr/tree/main/common/bcp47](https://github.com/unicode-org/cldr/tree/main/common/bcp47), [https://en.wikipedia.org/wiki/IETF\_language\_tag](https://en.wikipedia.org/wiki/IETF_language_tag)

[https://www.rfc-editor.org/info/bcp47](https://www.rfc-editor.org/info/bcp47)

[Unicode Locale Data Markup Language](https://unicode.org/reports/tr35/)

[BCP47](https://www.rfc-editor.org/rfc/bcp/bcp47.txt)

[RFC6067 on the Unicode extensions](https://datatracker.ietf.org/doc/html/rfc6067)

[RFC6497 on the transformation extension](https://datatracker.ietf.org/doc/html/rfc6497)

# COPYRIGHT & LICENSE

Copyright(c) 2024 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
