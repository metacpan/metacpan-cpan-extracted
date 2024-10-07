# NAME

Locale::Intl - A Web Intl.Locale Class Implementation

# SYNOPSIS

    use Locale::Intl;
    my $locale = Locale::Intl->new( 'ja-Kana-t-it' ) ||
        die( Locale::Intl->error );

    my $korean = new Locale::Intl('ko', {
        script => 'Kore',
        region => 'KR',
        hourCycle => 'h23',
        calendar => 'gregory',
    });
    
    my $japanese = new Locale::Intl('ja-Jpan-JP-u-ca-japanese-hc-h12');

    say $korean->baseName;
    say $japanese->baseName;
    # Expected output:
    # ko-Kore-KR
    # ja-Jpan-JP

    say $korean->hourCycle;
    say $japanese->hourCycle;
    # Expected output
    # h23
    # h12

# VERSION

    v0.1.0

# DESCRIPTION

This class inherits from [Unicode::Locale](https://metacpan.org/pod/Unicode%3A%3ALocale).

Make sure to check the API of [Unicode::Locale](https://metacpan.org/pod/Unicode%3A%3ALocale) for its constructor and its methods.

It also accesses the Unicode CLDR (Common Locale Data Repository) data using [Locale::Unicode::Data](https://metacpan.org/pod/Locale%3A%3AUnicode%3A%3AData)

It requires perl v5.10.1 minimum to run.

# CONSTRUCTOR

    # American English
    my $us = Locale::Intl->new( 'en-US' );
    # Japanese Katakana
    my $ja = Locale::Intl->new( 'ja-Kana' );
    # Swiss German as spoken in subdivision of Zurich
    my $ch = Locale::Intl->new( 'gsw-u-sd-chzh' );
    # Hebrew as spoken in Israel with Hebrew calendar and Jerusalem time zone
    my $he = Locale::Intl->new( 'he-IL-u-ca-hebrew-tz-jeruslm' );
    # Japanese with Japanese calendar and Tokyo time zone with Japanese Finance numbering
    # translated from Austrian German by an unidentified vendor with private extension 'private-subtag'
    my $ja = Locale::Intl->new( 'ja-t-de-AT-t0-und-u-ca-japanese-tz-jptyo-nu-jpanfin-x-private-subtag' );

Passing some overriding options:

    my $locale = new Locale::Intl( 'en-US', { hourCycle => 'h12' });
    say $locale->hourCycle; # h12

## new

This takes a [Unicode locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode) and an optional hash or hash reference of options, and returns a new instance of [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl). For the syntax of [locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode) strings, see the [Unicode documentation](https://www.unicode.org/reports/tr35/).

A `locale` is composed of a `language`, such as `fr` (French) or `ja` (Japanese) or `gsw` (Swiss German), an optional `script`, such as `Latn` (Latin) or `Kana` (Katanaka), a `region`, which can be a [country code](https://metacpan.org/pod/Locale%3A%3AUnicode#country_code), such as `US` (United States) or a world region, such as `150` (Europe) and a `variant`, such as `valencia` as in `ca-ES-valencia`. Only the `language` part is required.

The supported options are:

- `calendar`

    Any syntactically valid string following the [Unicode type grammar](https://unicode.org/reports/tr35/#Unicode_locale_identifier) (one or more segments of 3–8 alphanumerals, joined by hyphens) is accepted. See [getAllCalendars()](#getallcalendars) for all the supported calendars.

    See also ["calendar" in Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode#calendar)

- `caseFirst`

    This is the case-first sort option. Possible values are `upper`, `lower`, or a false value, such as `undef` or `0`.

    See also ["colCaseFirst" in Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode#colCaseFirst)

- `collation`

    Any syntactically valid string following the [Unicode type grammar](https://unicode.org/reports/tr35/#Unicode_locale_identifier) is accepted. See [getCollations](#getcollations) for a list of supported collations.

    See also ["collation" in Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode#collation)

- `hourCycle`

    Possible values are `h23`, `h12`, `h11`, or the practically unused `h24`, which are explained in [getHourCycles](#gethourcycles)

    See also ["hour\_cycle" in Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode#hour_cycle)

- `language`

    Not to be confused, this is a part of a broader `locale`. Any syntactically valid string following the [Unicode language subtag grammar](https://unicode.org/reports/tr35/#unicode_language_subtag) (2–3 or 5–8 letters) is accepted.

- `numberingSystem`

    Any syntactically valid string following the [Unicode type grammar](https://unicode.org/reports/tr35/#Unicode_locale_identifier) is accepted. See [getNumberingSystems](#getnumberingsystems) for the numbering systems supported for the `locale` set in the object, or [getAllNumberingSystems](#getallnumberingsystems) for the list of all supported numbering systems.

    See also ["number" in Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode#number)

- `numeric`

    The numeric sort option. This takes a boolean value.

    See also ["colNumeric" in Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode#colNumeric)

- `region`

    Any syntactically valid string following the [Unicode region subtag grammar](https://unicode.org/reports/tr35/#unicode_region_subtag) (either 2 letters or 3 digits) is accepted.

- `script`

    Any syntactically valid string following the [Unicode script subtag](https://unicode.org/reports/tr35/#unicode_script_subtag) grammar (4 letters) is accepted, but the implementation only recognizes certain kinds.

    See also ["script" in Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode#script)

# METHODS

## getAllCalendars

This is a read-only method that returns an array of all possible calendar values supported by the current version of [LDML (Locale Data Markup Language)](https://unicode.org/reports/tr35/).

## getAllNumberingSystems

This is a read-only method that returns an array of all possible numbering system values supported by the current version of [LDML (Locale Data Markup Language)](https://unicode.org/reports/tr35/).

## getAllTimeZones

This is a read-only method that returns an array of all possible time zone values supported by the current version of [LDML (Locale Data Markup Language)](https://unicode.org/reports/tr35/). Please note that to ensure consistency, the LDML supports some values that are either outdated or removed from IANA's time zone database.

## getCalendars

    my $jaJP = new Locale::Intl( 'ja-JP' );
    say $jaJP->getCalendars(); # ["gregory", "japanese"]

This method returns an array of one or more unique [calendar](https://metacpan.org/pod/Locale%3A%3AUnicode#calendar) identifiers for this `locale`.

See the [Unicode Locale BCP47 extensions](https://metacpan.org/pod/Locale%3A%3AUnicode#BCP47-EXTENSIONS) for the list of valid calendar values.

## getCollations

    my $locale = Locale::Intl->new( 'zh' );
    say $locale->getCollations(); # ["pinyin", "stroke", "zhuyin", "emoji", "eor"]

The `getCollations()` method returns an array of one or more collation types commonly used for this [locale](https://metacpan.org/pod/Locale%3A%3AUnicode). If the [Locale](https://metacpan.org/pod/Locale%3A%3AUnicode) already has a `collation`, then the returned array contains that single value.

If the [locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode) object does not have a `collation` already, `getCollations()` lists all commonly-used collation types for the given [locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode).

See the [Unicode Locale BCP47 extensions](https://metacpan.org/pod/Locale%3A%3AUnicode#BCP47-EXTENSIONS) for the list of valid collation values.

## getHourCycles

    my $jaJP = Locale::Intl->new( 'ja-JP' );
    say $jaJP->getHourCycles(); # ["h23"]

    my $arEG = Locale::Intl->new( 'ar-EG' );
    say $arEG->getHourCycles(); # ["h12"]

This method returns an array of one or more unique hour cycle identifiers commonly used for this [locale](https://metacpan.org/pod/Locale%3A%3AUnicode), sorted in descending preference. If the Locale already has an hourCycle, then the returned array contains that single value.

If the [locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode) object does not have a `hourCycle` already, this method lists all commonly-used hour cycle identifiers for the given [locale](https://metacpan.org/pod/Locale%3A%3AUnicode).

Below are the valid values:

- `h12`

    Hour system using `1–12`; corresponds to `h` in patterns. The 12 hour clock, with midnight starting at `12:00` am. As used, for example, in the United States.

- `h23`

    Hour system using `0–23`; corresponds to `H` in patterns. The 24 hour clock, with midnight starting at `0:00`.

- `h11`

    Hour system using `0–11`; corresponds to `K` in patterns. The 12 hour clock, with midnight starting at `0:00` am. Mostly used in Japan.

- `h24`

    Hour system using `1–24`; corresponds to `k` in pattern. The 24 hour clock, with midnight starting at `24:00`. Not used anywhere.

Hour cycles usage in the world are:

- `h12 h23`

    115 locales

- `h23 h12`

    95 locales

- `h23`

    60 locales

- `h23 h11 h12`

    1 locale

See also the property [hourCycle](#hourcycle)

## getNumberingSystems

    my $ja = Locale::Intl->new( 'ja' );
    say $ja->getNumberingSystems(); # ["latn"]

    my $arEG = Locale::Intl->new( 'ar-EG' );
    say $arEG->getNumberingSystems(); # ["arab"]

This method returns an array of one or more unique numbering system identifiers commonly used for this [locale](https://metacpan.org/pod/Locale%3A%3AUnicode), sorted in descending preference. If the Locale already has a numberingSystem, then the returned array contains that single value.

See the [Unicode Locale BCP47 extensions](https://metacpan.org/pod/Locale%3A%3AUnicode#BCP47-EXTENSIONS) for the list of valid numbering system values.

## getTextInfo

    my $ar = Locale::Intl->new( 'ar' );
    say $ar->getTextInfo(); # rtl

    my $es = Locale::Intl->new( 'es' );
    say $es->getTextInfo(); # ltr

This method returns a string representing the ordering of characters indicated by either `ltr` (left-to-right) or by `rtl` (right-to-left) for this [locale](https://metacpan.org/pod/Locale%3A%3AUnicode) as specified in [UTS 35 Layouts Elements](https://www.unicode.org/reports/tr35/tr35-general.html#Layout_Elements).

## getTimeZones

    my $jaJP = Locale::Intl->new( 'ja-JP' );
    say $jaJP->getTimeZones(); # ["Asia/Tokyo"]

    my $ar = Locale::Intl->new( 'ar' );
    # This will resolve to Africa/Cairo, because the locale 'ar' 
    3 will maximize to ar-Arab-EG and from there to Egypt
    say $ar->getTimeZones(); # ["Africa/Cairo"]

This method returns an array of supported time zones for this [locale](https://metacpan.org/pod/Locale%3A%3AUnicode).

ach value is an [IANA time zone canonical name](https://en.wikipedia.org/wiki/Daylight_saving_time#IANA_time_zone_database), sorted in alphabetical order. If the [locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode) does not contain a `region` subtag, the returned value is `undef`.

Keep in mind that the values do not necessarily match the IANA database that changes from time to time. The Unicode LDML [keeps old time zones for stability purpose](https://unicode.org/reports/tr35/#Time_Zone_Identifiers).

Also note that this method behaves slightly differently from its JavaScript counter part, as the [JavaScript getTimeZones() method](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Locale/getTimeZones) will return `undef` if only a `language` subtag is provided and not a `locale` tha would include a `country code`. This method, instead, will [maximize](#maximize) the 2-letters `locale` provided and from there will returns the time zone for the default country for that language.

See also [getAllTimeZones](#getalltimezones) to get a list of all available time zones.

## getWeekInfo

    const he = Locale::Intl->new( 'he' );
     say $he->getWeekInfo();
     # { firstDay => 7, weekend => [5, 6], minimalDays => 1 }

    const af = Locale::Intl->new( 'af' );
    say $af->getWeekInfo();
    # { firstDay => 7, weekend => [6, 7], minimalDays => 1 }

    const enGB = Locale::Intl->new( 'en-GB' );
    say $enGB->getWeekInfo();
    # { firstDay => 1, weekend => [6, 7], minimalDays => 4 }

    const msBN = Locale::Intl->new( 'ms-BN' );
    say $msBN->getWeekInfo();
    # { firstDay => 7, weekend => [5, 7], minimalDays => 1 }
    # Brunei weekend is Friday and Sunday but not Saturday

This method returns an hash reference with the properties `firstDay`, `weekend` and `minimalDays` for this [locale](https://metacpan.org/pod/Locale%3A%3AUnicode), as specified in [UTS 35 Week Elements](https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Patterns_Week_Elements).

- `firstDay`

    An integer indicating the first day of the week for the locale. Can be either `1` (Monday) or `7` (Sunday).

- `weekend`

    An array of integers indicating the weekend days for the locale, where `1` is Monday and `7` is Sunday.

- `minimalDays`

    An integer between `1` and `7` indicating the minimal days required in the first week of a month or year, for calendar purposes.

See also the [Unicode LDML specifications](https://unicode-org.github.io/cldr/ldml/tr35-dates.html#Date_Patterns_Week_Elements)

## maximise

This is an alias for [maximise](#maximise)

## maximize

    my $english = Locale::Intl->new( 'en' );
    my $korean = Locale::Intl->new( 'ko' );
    my $arabic = Locale::Intl->new( 'ar' );
    
    say $english->maximize()->baseName;
    # en-Latn-US
    
    say $korean->maximize()->baseName;
    # ko-Kore-KR
    
    say $arabic->maximize()->baseName;
    # ar-Arab-EG

This method gets [the most likely values](https://github.com/unicode-org/cldr-json/blob/main/cldr-json/cldr-core/supplemental/likelySubtags.json) for the `language`, `script`, and `region` of this [locale](https://metacpan.org/pod/Locale%3A%3AUnicode) based on existing values and returns a new [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) object.

Sometimes, it is convenient to be able to identify the most likely [locale language identifier](https://metacpan.org/pod/Locale%3A%3AUnicode) subtags based on an incomplete `language` ID. The [Add Likely Subtags algorithm](https://www.unicode.org/reports/tr35/#Likely_Subtags) gives us this functionality. For instance, given the `language` ID `en`, the algorithm would return `en-Latn-US`, since English can only be written in the Latin script, and is most likely to be used in the United States, as it is the largest English-speaking country in the world. This functionality is provided via this `maximize()` method. `maximize()` only affects the main subtags that comprise the `language` identifier: `language`, `script`, and `region` subtags. Other subtags after the `-u` in the `locale` identifier are [called extension subtags](https://metacpan.org/pod/Locale%3A%3AUnicode#BCP47-EXTENSIONS) and are not affected by the `maximize()` method. Examples of these subtags include [hourCycle](#hourcycle), [calendar](#calendar), and [numeric](#numeric).

Upon error, it sets an [exception object](https://metacpan.org/pod/Locale%3A%3AIntl%3A%3AException) and returns `undef` in scalar context, or an empty list in list context.

Example:

    my $myLocale = Locale::Intl->new( 'fr', {
        hourCycle => 'h12',
        calendar => 'gregory',
    });
    say $myLocale->baseName; # fr
    say $myLocale->toString(); # fr-u-ca-gregory-hc-h12
    my $myLocMaximized = $myLocale->maximize();

    # The "Latn" and "FR" tags are added
    # fr-Latn-FR
    # since French is only written in the Latin script and 
    # is most likely to be spoken in France.
    say $myLocMaximized->baseName;

    # fr-Latn-FR-u-ca-gregory-hc-h12
    # Note that the extension tags (after '-u') remain unchanged.
    say $myLocMaximized->toString();

## minimise

This is an alias for [minimise](#minimise)

## minimize

    my $english = Locale::Intl->new( 'en-Latn-US' );
    my $korean = Locale::Intl->new( 'ko-Kore-KR' );
    my $arabic = Locale::Intl->new( 'ar-Arab-EG' );

    say $english->minimize()->baseName;
    # en

    say $korean->minimize()->baseName;
    # ko

    say $arabic->minimize()->baseName;
    # ar

    my $myLocale = Locale::Intl->new( 'fr-Latn-FR', {
        hourCycle => 'h12',
        calendar => 'gregory',
    });
    say $myLocale->baseName; # fr-Latn-FR
    say $myLocale->toString(); # fr-Latn-FR-u-ca-gregory-hc-h12

    my $myLocMinimized = $myLocale->minimize();

    # Prints 'fr', since French is only written in the Latin script and
    # is most likely to be spoken in France.
    say $myLocMinimized->baseName);

    # fr-u-ca-gregory-hc-h12
    # Note that the extension tags (after '-u') remain unchanged.
    say $myLocMinimized->toString();

This method attempts to remove information about this `locale` that would be added by calling [maximize()](#maximize), which means removing any language, script, or region subtags from the locale language identifier (essentially the contents of baseName).

This is useful when there are superfluous subtags in the language identifier; for instance, `en-Latn` can be simplified to `en`, since `Latn` is the only script used to write English. `minimize()` only affects the main subtags that comprise the [language identifier](https://metacpan.org/pod/Locale%3A%3AUnicode): `language`, `script`, and `region` subtags. Other subtags after the `-u` in the [locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode) are called [extension subtags](https://metacpan.org/pod/Locale%3A%3AUnicode#BCP47-EXTENSIONS) and are not affected by the `minimize()` method. Examples of these subtags include [hourCycle](#hourcycle), [calendar](#calendar), and [numeric](#numeric). 

This returns a new [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) instance whose [baseName](#basename) property returns the result of the [Remove Likely Subtags](https://www.unicode.org/reports/tr35/#Likely_Subtags) algorithm executed against `$locale->baseName`. 

## toString

    my $french = Locale::Intl->new('fr-Latn-FR', {
        calendar => 'gregory',
        hourCycle => 'h12',
    });
    const korean = Locale::Intl->new('ko-Kore-KR', {
        numeric => 'true',
        caseFirst => 'upper',
    });

    say $french->toString();
    # fr-Latn-FR-u-ca-gregory-hc-h12

    say $korean->toString();
    # ko-Kore-KR-u-kf-upper-kn

This method returns this [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl)'s full locale identifier string.

The string value is computed once and is cached until any of the `locale`'s attributes are changed.

# PROPERTIES

## baseName

    # Sets locale to Canadian French
    my $myLoc = Locale::Intl->new( "fr-Latn-CA" );
    say $myLoc->toString(); # fr-Latn-CA-u-ca-gregory
    say $myLoc->baseName; # fr-Latn-CA

    # calendar to Gregorian, hour cycle to 24 hours
    my $japan = Locale::Intl->new( "ja-JP-u-ca-gregory-hc-24" );
    say $japan->toString(); # ja-JP-u-ca-gregory-hc-h24
    $japan->baseName; # ja-JP

    # Dutch and region as Belgium, but options override the region to the Netherlands
    my $dutch = Locale::Intl->new( "nl-Latn-BE", { region => "NL" });
    
    say $dutch->baseName; # nl-Latn-NL

The `baseName` accessor property of [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) instances returns a substring of this `locale`'s string representation, containing core information about this locale.

Specifically, this returns the substring containing the `language`, the `script` and `region` if available.

See [Unicode grammar ID](https://www.unicode.org/reports/tr35/#Identifiers) for more information.

## calendar

This returns the calendar type for this locale.

The `calendar` property's value is set at object instantiation time, either through the `ca` attribute of the `locale` identifier or through the `calendar` option of the [Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode) constructor. The latter takes priority if they are both present; and if neither is present, the property has value `undef`.

For a list of supported calendar types, see ["getCalendars" in Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl#getCalendars).

For example:

Adding a `calendar` through the `locale` attribute.

In the [Unicode locale string specifications](https://www.unicode.org/reports/tr35/), `calendar` era types are `locale` attribute "extension subtags". These subtags add additional data about the `locale`, and are added to `locale` identifiers by using the `-u` extension. Thus, the `calendar` era type can be added to the initial `locale` identifier string that is passed into the [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor. To add the calendar type, first add the `-u` extension to the string. Next, add the [-ca](https://metacpan.org/pod/Locale%3A%3AUnicode#ca) extension to indicate that you are adding a calendar type. Finally, add the calendar era type to the string.

    my $locale = Locale::Intl->new( 'he-IL-u-ca-hebrew-tz-jeruslm' );
    say $locale->calendar; # hebrew

Alternatively, you could also achieve the same results, using the methods inherited from [Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode):

    my $locale = Locale::Intl->new( 'he-IL' );
    $locale->ca( 'hebrew' )->tz( 'jeruslm' );
    say $locale->calendar; # hebrew

Adding a `calendar` type via the optional hash or hash reference of options.

The [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor takes an optional hash or hash reference of options, which can contain any of several extension types, including calendars. Set the `calendar` property of the optional hash or hash reference to your desired `calendar` era, and then pass it into the constructor.

    my $locale = Locale::Intl->new( 'he-IL', { calendar => 'hebrew' } );
    say $locale->calendar; # hebrew

## caseFirst

The `caseFirst` accessor property of [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) instances returns whether case is taken into account for this `locale`'s collation rules.

There are 3 values that the `caseFirst` property can have, outlined in the table below.

- `upper`

    Upper case to be sorted before lower case.

- `lower`

    Lower case to be sorted before upper case.

- `false`

    No special case ordering.

Setting the caseFirst value via the locale string

In the [Unicode locale string specifications](https://www.unicode.org/reports/tr35/), the values that `aseFirst` represents correspond to the attribute [kf](https://metacpan.org/pod/Locale%3A%3AUnicode#kf). `kf` is treated as a `locale` string "extension subtag". These subtags add additional data about the `locale`, and are added to `locale` identifiers by using the `-u` extension attribute. Thus, the `caseFirst` value can be added to the initial `locale` identifier string that is passed into the [Locale](https://metacpan.org/pod/Locale%3A%3AUnicode) constructor. To add the `caseFirst` value, first add the `-u` extension key to the string. Next, add the [-kf](https://metacpan.org/pod/Locale%3A%3AUnicode#kf) extension key to indicate that you are adding a value for `caseFirst`. Finally, add the `caseFirst` value to the string.

    my $locale = Locale::Intl->new( "fr-Latn-FR-u-kf-upper" );
    say $locale->caseFirst; # upper

Setting the `caseFirst` value via the optional hash or hash reference of options.

The [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor takes an optional hash or hash reference of options, which can be used to pass extension types. Set the `caseFirst` property of the configuration object to your desired `caseFirst` value, and then pass it into the constructor.

    my $locale = Locale::Intl->new( "en-Latn-US", { caseFirst => "lower" });
    say $locale->caseFirst; # lower

## collation

The `collation` accessor property of [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) instances returns the `collation` type for this `locale`, which is used to order strings according to the `locale`'s rules.

The `collation` property's value is set at object instantiation time, either through the [co](https://metacpan.org/pod/Locale%3A%3AUnicode#co) attribute of the [locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode) or through the `collation` option of the [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor. The latter takes priority if they are both present; and if neither is present, the property has value `undef`.

For a list of supported collation types, see [getCollations()](https://metacpan.org/pod/Locale%3A%3AIntl#getCollations).

For example:

Adding a collation type via the locale string.

In the [Unicode locale string specifications](https://www.unicode.org/reports/tr35/), `collation` types are `locale` attribute "extension subtags". These subtags add additional data about the `locale`, and are added to [locale identifiers](https://metacpan.org/pod/Locale%3A%3AUnicode) by using the `-u` extension. Thus, the [collation](https://metacpan.org/pod/Locale%3A%3AUnicode#collation) type can be added to the initial [locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode) string that is passed into the [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor. To add the `collation` type, first add the `-u` extension to the string. Next, add the `-co` extension to indicate that you are adding a collation type. Finally, add the collation type to the string.

    my $locale = Locale::Intl->new( "zh-Hant-u-co-zhuyin" );
    say $locale->collation; # zhuyin

Adding a collation type via the configuration object argument.

The [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor has an optional hash or hash reference of options, which can contain any of several extension types, including `collation` types. Set the `collation` property of the configuration object to your desired `collation` type, and then pass it into the constructor.

    my $locale = Locale::Intl->new( "zh-Hant", { collation => "zhuyin" });
    say $locale->collation; # zhuyin

## hourCycle

The `hourCycle` accessor property of [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) instances returns the [hour cycle](https://metacpan.org/pod/Locale%3A%3AUnicode#hour_cycle) type for this [locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode).

There are 2 main types of time keeping conventions (clocks) used around the world: the 12 hour clock and the 24 hour clock. The `hourCycle` property's value is set upon object instantiation, either through the [hc](https://metacpan.org/pod/Locale%3A%3AUnicode#hc) attribute of the [locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode) or through the `hourCycle` option of the [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor. The latter takes priority if they are both present; and if neither is present, the property has value `undef`.

For a list of supported hour cycle types, see [getHourCycles()](https://metacpan.org/pod/Locale%3A%3AIntl#getHourCycles).

For example:

Like other `locale` subtags, the hour cycle type can be added to the [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) object via the locale string, or an option upon object instantiation.

Adding an hour cycle via the locale string

In the [Unicode locale string specifications](https://www.unicode.org/reports/tr35/), [hour cycle](https://metacpan.org/pod/Locale%3A%3AUnicode#hour_cycle) types are locale attribute "extension subtags". These subtags add additional data about the `locale`, and are added to [locale identifiers](https://metacpan.org/pod/Locale%3A%3AUnicode) by using the `-u` extension. Thus, the hour cycle type can be added to the initial [locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode) string that is passed into the [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor. To add the [hour cycle](https://metacpan.org/pod/Locale%3A%3AUnicode#hour_cycle) type, first add the `-u` extension key to the string. Next, add the `-hc` extension to indicate that you are adding an hour cycle. Finally, add the hour cycle type to the string.

    my $locale = Locale::Intl->new( "fr-FR-u-hc-h23" );
    say $locale->hourCycle; # h23

Adding an hour cycle via the configuration object argument

The [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor has an optional hash or hash reference of options, which can contain any of several extension types, including [hour cycle](https://metacpan.org/pod/Locale%3A%3AUnicode#hour_cycle) types. Set the `hourCycle` property of the configuration object to your desired hour cycle type, and then pass it into the constructor.

    my $locale = Locale::Intl->new( "en-US", { hourCycle => "h12" });
    say $locale->hourCycle; # h12

## language

The `language` accessor property of [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) instances returns the `language` associated with this `locale`.

Language is one of the core features of a `locale`. The Unicode specification treats the `language` identifier of a `locale` as the `language` and the `region` together (to make a distinction between dialects and variations, e.g. British English vs. American English). However, the `language` property of an [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) object returns strictly the `locale`'s `language` subtag. This subtag can be a 2 or 3-characters code.

For example:

Setting the `language` in the locale identifier string argument.

In order to be a valid [Unicode locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode), a string must start with the `language` subtag. The main argument to the [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor must be a valid [Unicode locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode), so whenever the constructor is used, it must be passed an identifier with a `language` subtag.

    my $locale = Locale::Intl->new( "en-Latn-US" );
    say $locale->language; # en

Overriding language via the configuration object.

While the `language` subtag must be specified, the [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor takes an hash or hash reference of options, which can override the `language` subtag.

    my $locale = Locale::Intl->new( "en-Latn-US", { language => "es" });
    say $locale->language; # es

## numberingSystem

The `numberingSystem` accessor property of [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) instances returns the numeral system for this `locale`.

A numeral system is a system for expressing numbers. The `numberingSystem` property's value is set upon object instantiation, either through the [nu](https://metacpan.org/pod/Locale%3A%3AUnicode#nu) attribute of the [locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode) or through the `numberingSystem` option of the [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor. The latter takes priority if they are both present; and if neither is present, the property has value `undef`.

For a list of supported numbering system types, see [getNumberingSystems()](https://metacpan.org/pod/Locale%3A%3AIntl#getNumberingSystems).

Adding a numbering system via the locale string.

In the [Unicode locale string specifications](https://www.unicode.org/reports/tr35/), numbering system types are `locale` attribute "extension subtags". These subtags add additional data about the `locale`, and are added to `locale` identifiers by using the `-u` extension. Thus, the numbering system type can be added to the initial `locale` identifier string that is passed into the [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor. To add the numbering system type, first add the `-u` extension attribute to the string. Next, add the [-nu](https://metacpan.org/pod/Locale%3A%3AUnicode#nu) extension to indicate that you are adding a numbering system. Finally, add the numbering system type to the string.

    my $locale = Locale::Intl->new( "fr-Latn-FR-u-nu-mong" );
    say $locale->numberingSystem; # mong

Adding a numbering system via the configuration object argument.

The [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor has an optional hash or hash reference of options, which can contain any of several extension types, including numbering system types. Set the `numberingSystem` property of the hash or hash reference of options to your desired numbering system type, and then pass it into the constructor.

    my $locale = Locale::Intl->new( "en-Latn-US", { numberingSystem => "latn" });
    say $locale->numberingSystem; # latn

## numeric

The `numeric` accessor property of [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) instances returns a [boolean object](https://metacpan.org/pod/Locale%3A%3AIntl%3A%3ABoolean) representing whether this `locale` has special collation handling for `numeric` characters.

Like `caseFirst`, `numeric` represents a modification to the collation rules utilized by the locale. `numeric` is a boolean value, which means that it can be either [true](https://metacpan.org/pod/Locale%3A%3AIntl%3A%3ABoolean#true) or [false](https://metacpan.org/pod/Locale%3A%3AIntl%3A%3ABoolean#false). If `numeric` is set to `false`, there will be no special handling of `numeric` values in strings. If `numeric` is set to `true`, then the `locale` will take `numeric` characters into account when collating strings. This special `numeric` handling means that sequences of decimal digits will be compared as numbers. For example, the string `A-21` will be considered less than `A-123`.

Example:

Setting the numeric value via the locale string.

In the [Unicode locale string specifications](https://www.unicode.org/reports/tr35/), the values that `numeric` represents correspond to the attribute [kn](https://metacpan.org/pod/Locale%3A%3AUnicode#kn). [kn](https://metacpan.org/pod/Locale%3A%3AUnicode#kn) is considered a [locale](https://metacpan.org/pod/Locale%3A%3AUnicode) string extension subtag". These subtags add additional data about the [locale](https://metacpan.org/pod/Locale%3A%3AUnicode), and are added to [locale identifiers](https://metacpan.org/pod/Locale%3A%3AUnicode) by using the -u extension key. Thus, the `numeric` value can be added to the initial [locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode) string that is passed into the [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor. To set the `numeric` value, first add the `-u` extension attribute to the string. Next, add the `-kn` extension attribute to indicate that you are adding a value for `numeric`. Finally, add the `numeric` value to the string. If you want to set `numeric` to true, adding the [kn](https://metacpan.org/pod/Locale%3A%3AUnicode#kn) attribute will suffice. To set the value to false, you must specify in by adding "false" after the [kn](https://metacpan.org/pod/Locale%3A%3AUnicode#kn) attribute.

    my $locale = Locale::Intl->new("fr-Latn-FR-u-kn-false");
    say $locale->numeric); # false

Setting the numeric value via the configuration object argument.

The [Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode) constructor has an optional hash or hash reference of options, which can be used to pass extension types. Set the `numeric` property of the hash or hash reference of options to your desired `numeric` value and pass it into the constructor.

    my $locale = Locale::Intl->new("en-Latn-US", { numeric => $true_value });
    say $locale->numeric; # true

## region

The `region` accessor property of [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) instances returns the `region` of the world (usually a country) associated with this `locale`. This could be a [country code](https://metacpan.org/pod/Locale%3A%3AUnicode#country_code), or a world region represented with a [3-digits code](https://metacpan.org/pod/Locale%3A%3AUnicode#region)

The `region` is an essential part of the [locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode), as it places the `locale` in a specific area of the world. Knowing the `locale`'s region is vital to identifying differences between locales. For example, English is spoken in the United Kingdom and the United States of America, but there are differences in spelling and other `language` conventions between those two countries.

For example:

Setting the region in the locale identifier string argument.

The `region` is the third part of a valid [Unicode language identifier](https://metacpan.org/pod/Locale%3A%3AUnicode) string, and can be set by adding it to the [locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode) string that is passed into the [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor.

    my $locale = Locale::Intl->new( "en-Latn-US" );
    say $locale->region; # US

    my $locale = Locale::Intl->new( "fr-Latn-150" );
    say $locale->region; # 150
    # 150 is the region code for Europe

See the file `territories.json` in the [CLDR repository](https://github.com/unicode-org/cldr-json/tree/main/cldr-json/cldr-localenames-full) for the localised names of those territories.

## script

The `script` accessor property of [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) instances returns the `script` used for writing the particular `language` used in this `locale`.

A `script`, sometimes called writing system, is one of the core attributes of a [locale](https://metacpan.org/pod/Locale%3A%3AUnicode). It indicates the set of symbols, or glyphs, that are used to write a particular `language`. For instance, the `script` associated with English is Latin (`latn`), whereas the `script` used to represent Japanese Katanaka is `Kana` and the one typically associated with Korean is Hangul (`Hang`). In many cases, denoting a `script` is not strictly necessary, since the language (which is necessary) is only written in a single `script`. There are exceptions to this rule, however, and it is important to indicate the `script` whenever possible, in order to have a complete [Unicode language identifier](https://metacpan.org/pod/Locale%3A%3AUnicode).

For example:

Setting the script in the locale identifier string argument.

The `script` is the second part of a valid [Unicode language identifier](https://metacpan.org/pod/Locale%3A%3AUnicode) string, and can be set by adding it to the [locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode) string that is passed into the [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor. Note that the `script` is not a required part of a [locale identifier](https://metacpan.org/pod/Locale%3A%3AUnicode).

    my $locale = Locale::Intl->new( "en-Latn-US" );
    say $locale->script); # Latn

Setting the `script` via the hash or hash reference of options.

The [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) constructor takes an hash or hash reference of options, which can be used to set the `script` subtag and property.

    my $locale = Locale::Intl->new("fr-FR", { script => "Latn" });
    say $locale; # fr-Latn-FR
    say $locale->script; # Latn

# OVERLOADING

Instances of [Locale::Intl](https://metacpan.org/pod/Locale%3A%3AIntl) have the stringification overloaded as inherited from [Locale::Unicode](https://metacpan.org/pod/Locale%3A%3AUnicode)

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# SEE ALSO

[DateTime::Format::Intl](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AIntl)

# CREDITS

Credits to Mozilla for [parts of their documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Locale) I copied here.

# COPYRIGHT & LICENSE

Copyright(c) 2024 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
