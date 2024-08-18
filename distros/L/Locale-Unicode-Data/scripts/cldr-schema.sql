/*
The difference between a language and a locale is subttle and often confusing, admitedly so by the Unicode LDML specifications itself.
A language is a 2 to 3-characters code, such as fr or fra for French
A locale, or locale identified is a language with possibly a script, a region and a variant.
The LDML specifications also includes a set of extensive extensions that are part of what constitute a locale identifier, but for the sake of our data here a locale is limited to the definition aforementioned.
See, for more information: <https://unicode.org/reports/tr35/#Language_and_Locale_IDs>

Reference:
Table syntax; <https://www.sqlite.org/lang_createtable.html>
Foreign keys: <https://sqlite.org/foreignkeys.html>
Reserved keywords: <https://www.sqlite.org/lang_keywords.html>
*/

CREATE TABLE metainfos (
     meta_id            INTEGER
    ,property           VARCHAR(20) NOT NULL
    ,value              varchar(50) NOT NULL
    ,PRIMARY KEY(meta_id)
);
CREATE UNIQUE INDEX idx_metainfo_unique ON metainfos(property);

-- NOTE: Tables primary keys are alias for ROWID: <https://www.sqlite.org/lang_createtable.html#rowid>
-- NOTE: File camel case name is converted to lower case with underscore: territoryInfo -> territory_info

-- NOTE: Source: supplemental->supplementalData.xml->currencyData/fractions/info[@iso4217]
-- NOTE: Source: supplemental->supplementalData.xml->currencyData/region[@iso3166]/currency[@iso4217]
CREATE TABLE currencies (
     currency_id        INTEGER
     -- Example: EUR, JPY
    ,currency           VARCHAR(3) NOT NULL COLLATE NOCASE
    -- CLDR supplemental data only has digits and rounding information for 72 currencies
    ,digits             INTEGER
    ,rounding           INTEGER
    ,cash_digits        INTEGER
    ,cash_rounding      INTEGER
    ,is_obsolete        BOOLEAN DEFAULT FALSE
    -- regular, deprecated, unknown
    ,status             VARCHAR(20)
    ,PRIMARY KEY(currency_id)
    ,CHECK( currency REGEXP '^[a-zA-Z]{3}$' )
    ,CHECK( status REGEXP '^[a-zA-Z][a-zA-Z0-9\_]+$' )
);
CREATE UNIQUE INDEX idx_currencies_unique ON currencies(currency);

-- NOTE: Source: supplemental->supplementalData.xml->calendarData
CREATE TABLE calendars (
     calendar_id        INTEGER
     -- Example: japanese
    ,calendar           VARCHAR(20) NOT NULL COLLATE NOCASE
    -- Example: solar, lunar, other, lunisolar
    ,system             VARCHAR(20)
    -- Example: gregorian
    ,inherits           VARCHAR(20)
    ,description        TEXT
    ,PRIMARY KEY(calendar_id)
    ,CHECK( calendar REGEXP '^[a-zA-Z][a-zA-Z0-9]+(?:\-[a-zA-Z]+)*$' )
);
CREATE UNIQUE INDEX idx_calendars_unique ON calendars(calendar);

-- NOTE: Source: supplemental->supplementalData.xml->calendarData/calendar[@type]/eras/era
CREATE TABLE calendar_eras (
     calendar_era_id    INTEGER
     -- Example: japanese
    ,calendar           VARCHAR(20) NOT NULL COLLATE NOCASE
    -- 0, 1, 2...
    ,sequence           INTEGER NOT NULL
    -- japanese -> reiwa
    ,code               VARCHAR(20) COLLATE NOCASE
    -- Example: islamic-civil -> ["islamicc", "ah"]
    ,aliases            TEXT[]
    ,start              DATE
    ,until              DATE
    ,PRIMARY KEY(calendar_era_id)
    ,FOREIGN KEY(calendar) REFERENCES calendars(calendar) ON UPDATE CASCADE ON DELETE RESTRICT
    ,CHECK( code REGEXP '^[a-zA-Z]+(?:\-[a-zA-Z]+)*$' )
);
CREATE UNIQUE INDEX idx_calendar_eras_unique ON calendar_eras(calendar,sequence);

-- NOTE: Source: supplemental->supplementalData.xml->territoryInfo
CREATE TABLE territories (
     territory_id       INTEGER
     -- Example: FR, JP, GB, etc, or a 3-digits territory code
    ,territory          VARCHAR(3) NOT NULL COLLATE NOCASE
    ,parent             VARCHAR(3) COLLATE NOCASE
    ,gdp                INTEGER
    -- ex: 99 for 99%
    ,literacy_percent   DECIMAL
    -- As is. Example: JP = 125507000
    ,population         INTEGER
    ,languages          TEXT[]
    ,contains           TEXT[]
    ,currency           VARCHAR(3)
    ,calendars          TEXT[] DEFAULT '{"gregorian"}'
    -- Example: 1, 4
    ,min_days           INTEGER DEFAULT 1
    -- First day of the week: 1 = Monday.., 7 = Sunday
    ,first_day          INTEGER
    -- 2 digits, 1 (Monday( to 7 (Sunday). First digit is week-end start, and second one is week-end stop
    ,weekend            INTEGER[] DEFAULT '{6,7}'
    -- grouping (not used. see 'macroregion' instead), deprecated, special, macroregion
    ,status             VARCHAR(20)
    ,PRIMARY KEY(territory_id)
    ,CHECK( territory REGEXP '^([a-zA-Z]{2}|\d{3})$' )
    ,CHECK( status REGEXP '^[a-zA-Z][a-zA-Z0-9\_]+$' )
    ,FOREIGN KEY(currency) REFERENCES currencies(currency) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_territories_unique ON territories(territory);

-- NOTE: Source: supplemental->supplementalData.xml//currencyData/region[@iso3166]/currency[@iso4217]
CREATE TABLE currencies_info (
     currency_info_id   INTEGER
    ,territory          VARCHAR(3) NOT NULL COLLATE NOCASE
     -- Example: EUR, JPY
    ,currency           VARCHAR(3) NOT NULL COLLATE NOCASE
    -- Almost all would have a start date, except for some such as XXX, which is not a real currency and set for AQ (Antartica), because this terrtory has no currency.
    -- Instead, the 'currency' field of the territories table should be left NULL, but this is CLDR's choice
    ,start              DATE
    ,until              DATE
    -- Whether this currency was a legal tender, i.e. whether it bore the force of law to settle a public or private debt or meet a financial obligation.
    ,is_tender          BOOLEAN DEFAULT TRUE
    -- Integer representing the historical order. CLDR uses the attributes 'tz' and then 'to-tz' to link to following historical record when the old 'to' date overlaps the new 'from' date. Example: territory SX
    ,hist_sequence      INTEGER
    ,is_obsolete        BOOLEAN DEFAULT FALSE
    ,PRIMARY KEY(currency_info_id)
    ,FOREIGN KEY(territory) REFERENCES territories(territory) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(currency) REFERENCES currencies(currency) ON UPDATE CASCADE ON DELETE RESTRICT
    -- There is no foreign key on currency on purpose as this table is for historical records, and some currency do not exist anymore, and are not part of the data provided by CLDR
);
CREATE UNIQUE INDEX idx_currencies_info_unique ON currencies_info(territory, currency, start);

-- All known locales formed from the languages added
CREATE TABLE locales (
     locale_id          INTEGER
     -- Example: fr-FR, ja, ja-JP, en, en-GB, etc
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    -- Sourced from common/supplemental/supplementalData.xml/supplementalData/parentLocales/parentLocale
    -- See <https://unicode.org/reports/tr35/tr35.html#Parent_Locales>
    ,parent             VARCHAR(20) COLLATE NOCASE
    -- regular, deprecated, special, reserved, private_use, unknown
    ,status             VARCHAR(20)
    ,PRIMARY KEY(locale_id)
    ,CHECK( locale REGEXP '^[a-zA-Z][a-zA-Z]{1,2}(\-[a-zA-Z0-9]+)*$' )
    ,CHECK( status REGEXP '^[a-zA-Z][a-zA-Z0-9\_]+$' )
);
CREATE UNIQUE INDEX idx_locales_unique ON locales(locale);

-- NOTE: Source: common/supplemental/supplementalData.xml/supplementalData/languageData/language
-- Language related information (scripts and territories), that, together, form a locale
CREATE TABLE languages (
     language_id        INTEGER
     -- Example: fr, ja, en, etc
    ,language           VARCHAR(20) NOT NULL COLLATE NOCASE
    ,scripts            TEXT[]
    ,territories        TEXT[]
    -- Source: <supplemental/languageGroup.xml>
    -- See <https://www.loc.gov/standards/iso639-5/langhome5.html>
    ,parent             VARCHAR(3)
    -- e.g. secondary
    ,alt                VARCHAR(12)
    -- regular, deprecated, special, reserved, private_use, unknown
    ,status             VARCHAR(20)
    ,PRIMARY KEY(language_id)
    ,CHECK( language REGEXP '^[a-zA-Z]{2,3}(\-[a-zA-Z]+)*$' )
    ,CHECK( parent REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( alt REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( status REGEXP '^[a-zA-Z][a-zA-Z0-9\_]+$' )
);
-- Unique language made of language code + alt (secondary)
CREATE UNIQUE INDEX idx_languages_unique ON languages(language,IFNULL(alt, ''));

-- NOTE: Source: properties/scriptMetadata.txt
CREATE TABLE scripts (
     script_id          INTEGER
     -- Example: fr, ja, en, etc
    ,script             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,rank               INTEGER
    ,sample_char        VARCHAR(1)
    ,id_usage           VARCHAR(12)
    ,rtl                BOOLEAN
    ,lb_letters         BOOLEAN
    ,has_case           BOOLEAN
    ,shaping_req        BOOLEAN
    ,ime                BOOLEAN
    ,density            INTEGER
    ,origin_country     VARCHAR(3)
    ,likely_language    VARCHAR(20)
    -- regular, deprecated, special, reserved, private_use, unknown
    ,status             VARCHAR(20)
    ,PRIMARY KEY(script_id)
    ,CHECK( script REGEXP '^[a-zA-Z][a-zA-Z0-9]+$' )
    ,CHECK( status REGEXP '^[a-zA-Z][a-zA-Z0-9\_]+$' )
    ,FOREIGN KEY(origin_country) REFERENCES territories(territory) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(likely_language) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_scripts_unique ON scripts(script);

CREATE TABLE variants (
     variant_id         INTEGER
     -- Example: valencia
    ,variant             VARCHAR(20) NOT NULL COLLATE NOCASE
    -- regular, deprecated, special, reserved, private_use, unknown
    ,status             VARCHAR(20)
    ,PRIMARY KEY(variant_id)
    ,CHECK( variant REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( status REGEXP '^[a-zA-Z][a-zA-Z0-9\_]+$' )
);
CREATE UNIQUE INDEX idx_variants_unique ON variants(variant);

-- NOTE: Source: supplemental->supplementalData.xml->//timeData/hours
CREATE TABLE time_formats (
     time_format_id     INTEGER
    -- JP or ml_IN
    -- territory and locale provides the breakdown of the field 'region'
    ,region             VARCHAR(20) NOT NULL COLLATE NOCASE
     -- Example: FR, JP, GB, etc, or a 3-digits territory code
    ,territory          VARCHAR(3) NOT NULL COLLATE NOCASE
    ,locale             VARCHAR(20) COLLATE NOCASE
    -- Default values as defined in the specifications
    ,time_format        VARCHAR(1) DEFAULT 'H'
    ,time_allowed       TEXT[] DEFAULT '{"H", "h"}'
    ,PRIMARY KEY(time_format_id)
    ,CHECK( region REGEXP '^[a-zA-Z0-9\-]+$' )
    ,CHECK( time_format REGEXP '^[a-zA-Z]$' )
    ,FOREIGN KEY(territory) REFERENCES territories(territory) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_time_formats_unique ON time_formats(region);

-- NOTE: Source: common/supplemental/supplementalData.xml/supplementalData/territoryInfo/territory
CREATE TABLE language_population (
     language_pop_id    INTEGER
    ,territory          VARCHAR(3) NOT NULL
    ,locale             VARCHAR(20) NOT NULL
    -- ex: 99 for 99%
    ,population_percent DECIMAL
    ,literacy_percent   DECIMAL
    ,writing_percent    DECIMAL
    -- Example: official, de_facto_official, official_regional
    ,official_status    TEXT
    ,PRIMARY KEY(language_pop_id)
    ,FOREIGN KEY(territory) REFERENCES territories(territory) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_language_population_unique ON language_population(territory, locale);

-- NOTE: Source: common/supplemental/likelySubtags.xml
CREATE TABLE likely_subtags (
     likely_subtag_id   INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,target             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,PRIMARY KEY(likely_subtag_id)
    ,CHECK( locale REGEXP '^[a-zA-Z][a-zA-Z]{1,2}(\-[a-zA-Z0-9]+)*$' )
    ,CHECK( target REGEXP '^[a-zA-Z][a-zA-Z]{1,2}(\-[a-zA-Z0-9]+)*$' )
);
CREATE UNIQUE INDEX idx_likely_subtags_unique ON likely_subtags(locale, target);

CREATE TABLE aliases (
     alias_id           INTEGER
    -- i_klingon, zh-cmn-Hant, twkhq, Qaai, AN, 200, ANT, frtf, polytoni, America/Santa_Isabel
    ,alias              VARCHAR(42) NOT NULL COLLATE NOCASE
    -- ['CZ', 'SK'], ["CW", "SX", "BQ"]
    ,replacement        TEXT[] NOT NULL COLLATE NOCASE
    -- Example: deprecated, overlong, macrolanguage, bibliographic, legacy
    ,reason             VARCHAR(17)
    -- language, script, territory, subdivision, variant, zone
    ,type               VARCHAR(17)
    ,comment            TEXT
    ,PRIMARY KEY(alias_id)
    ,CHECK( alias REGEXP '^[a-zA-Z0-9\/\_\-]+$' )
);
CREATE UNIQUE INDEX idx_aliases_unique ON aliases(alias,type);

-- Source: supplemental/metaZones.xml/supplementalData/metaZones/metazoneInfo/timezone[@type]
-- Source: bcp47/timezone.xml/ldmlBCP47/keyword/key[name="tz"]/type
CREATE TABLE metazones (
     metazone_id        INTEGER
     -- Europe_Central, Japan, Israel, Korea
    ,metazone           VARCHAR(42) NOT NULL COLLATE NOCASE
    ,territories        TEXT[] NOT NULL COLLATE NOCASE
    ,timezones          TEXT[] NOT NULL COLLATE NOCASE
    ,PRIMARY KEY(metazone_id)
    ,CHECK( metazone REGEXP '^[a-zA-Z0-9\_]+$' )
);
CREATE UNIQUE INDEX idx_metazones_unique ON metazones(metazone);

-- Source: supplemental/metaZones.xml/supplementalData/metaZones/mapTimezones/mapZone[@other]
CREATE TABLE timezones (
     timezone_id        INTEGER
     -- Example: Asia/Tokyo
    ,timezone           VARCHAR(42) NOT NULL COLLATE NOCASE
    -- Example: GB, JP
    ,territory          VARCHAR(3) NOT NULL
    -- Example: Europe, Asia
    ,region             VARCHAR(20) NOT NULL
    -- Example: japa
    ,tzid               VARCHAR(4) COLLATE NOCASE
    -- Example: Europe_Central, Japan, Korea
    ,metazone           VARCHAR(20) COLLATE NOCASE
    ,tz_bcpid           VARCHAR(10) COLLATE NOCASE
    -- CLDR misuses the territory code '001' as a mean to specify whether a time zone is 'golden'.
    -- See <https://www.unicode.org/reports/tr35/tr35-dates.html#Using_Time_Zone_Names>
    ,is_golden          BOOLEAN DEFAULT FALSE
    -- Is the preferred time zone for this territory
    ,is_preferred       BOOLEAN DEFAULT FALSE
    -- Is this timezone the canonical one?
    -- <https://unicode.org/reports/tr35/tr35.html#Time_Zone_Identifiers>
    ,is_canonical       BOOLEAN DEFAULT FALSE
    ,alias              TEXT[]
    ,PRIMARY KEY(timezone_id)
    ,CHECK( timezone REGEXP '^[a-zA-Z0-9\/\_\-\+]+$' )
    ,CHECK( region REGEXP '^[a-zA-Z0-9\-]+$' )
    ,CHECK( tzid REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( tz_bcpid REGEXP '^[a-zA-Z0-9]+$' )
    ,FOREIGN KEY(territory) REFERENCES territories(territory) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(metazone) REFERENCES metazones(metazone) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_timezones_unique ON timezones(timezone);

-- Source: metaZones.xml/supplementalData/metaZones/metazoneInfo/timezone
CREATE TABLE timezones_info (
     tzinfo_id          INTEGER
     -- Example: Asia/Tokyo
    ,timezone           VARCHAR(42) NOT NULL COLLATE NOCASE
    ,metazone           VARCHAR(20) COLLATE NOCASE
    -- Either the start or until field is provided, so we cannot set them as NOT NULL
    ,start              DATETIME
    ,until              DATETIME
    ,PRIMARY KEY(tzinfo_id)
    ,FOREIGN KEY(timezone) REFERENCES timezones(timezone) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_timezones_info_unique ON timezones_info(timezone, start, until);

CREATE TABLE subdivisions (
     subdivision_id     INTEGER
    ,territory          VARCHAR(3) NULL COLLATE NOCASE
    ,subdivision        VARCHAR(10) NOT NULL COLLATE NOCASE
    -- Normally there should be a parent, but we also add all the known subdivisions from 
    -- validity/subdivision.xml and we do not have parent information there.
    ,parent             VARCHAR(10)
    ,is_top_level       BOOLEAN DEFAULT FALSE
    -- regular, deprecated, special, reserved, private_use, unknown
    ,status             VARCHAR(20)
    ,PRIMARY KEY(subdivision_id)
    ,CHECK( subdivision REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( parent REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( status REGEXP '^[a-zA-Z][a-zA-Z0-9\_]+$' )
    ,FOREIGN KEY(territory) REFERENCES territories(territory) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_subdivisions_unique ON subdivisions(subdivision);

-- NOTE: Source: subdivisions/*.xml
CREATE TABLE subdivisions_l10n (
     subdiv_l10n_id     INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,subdivision        VARCHAR(10) NOT NULL COLLATE NOCASE
    ,locale_name        TEXT NOT NULL
    ,PRIMARY KEY(subdiv_l10n_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(subdivision) REFERENCES subdivisions(subdivision) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_subdivisions_l10n_unique ON subdivisions_l10n(locale,subdivision);

-- NOTE: Source: supplemental/numberingSystems.xml//numberingSystems/numberingSystem
CREATE TABLE number_systems (
     numsys_id          INTEGER
    -- Example: arabext, hant, jpan, jpanfin, jpanyear
    ,number_system      VARCHAR(10) NOT NULL COLLATE NOCASE
    -- Example: 0..9
    ,digits             TEXT[]
    -- Example: numeric, algorithmic
    ,type               VARCHAR(12) NOT NULL
    ,PRIMARY KEY(numsys_id)
    ,CHECK( number_system REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( type REGEXP '^[a-zA-Z0-9]+$' )
);
CREATE UNIQUE INDEX idx_number_systems_unique ON number_systems(number_system);

-- NOTE: Source: supplemental/supplementalData.xml->//weekData/weekOfPreference
CREATE TABLE week_preferences (
     week_pref_id       INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    -- weekOfYear weekOfDate weekOfMonth
    ,ordering           TEXT[] NOT NULL COLLATE NOCASE
    ,PRIMARY KEY(week_pref_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_week_preferences_unique ON week_preferences(locale);

-- NOTE: Source: supplemental/dayPeriods.xml//dayPeriodRuleSet/dayPeriodRules
-- See also <https://unicode.org/reports/tr35/tr35-dates.html#Day_Period_Rule_Sets>
-- For localised day periods, see table calendar_terms
CREATE TABLE day_periods (
     day_period_id      INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,day_period         VARCHAR(20) NOT NULL COLLATE NOCASE
    -- If start and until have the same value, this means this is an 'at' day period type
    -- For example: midnight starts at 00:00 until 00:00
    -- CLDR could use seconds, but it does not, and it really is not needed either
    ,start              VARCHAR(5)
    ,until              VARCHAR(5)
    ,PRIMARY KEY(day_period_id)
    ,CHECK( day_period REGEXP '^[a-zA-Z0-9]+$' )
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_day_periods_unique ON day_periods(locale, day_period);

-- NOTE: Source: supplemental/supplementalData.xml//codeMappings/*[locale-name()="territoryCodes" or locale-name()="currencyCodes"]
-- NOTE: Should this be split into 2 separate tables, with a foreign key pointing to the territories table and the currencies table ?
CREATE TABLE code_mappings (
     code_mapping_id    INTEGER
    -- ISO 3166 territory code are 2-characters codes and ISO 4217 currency codes are 3-characters codes
    ,code               VARCHAR(3) NOT NULL COLLATE NOCASE
    ,alpha3             VARCHAR(3) COLLATE NOCASE
    ,numeric            INTEGER
    ,fips10             VARCHAR(2) COLLATE NOCASE
    -- territory, currency
    ,type               VARCHAR(10) NOT NULL
    ,CHECK( code REGEXP '^[a-zA-Z0-9]{2,3}$' )
    ,CHECK( type REGEXP '^(territory|currency)$' )
    ,PRIMARY KEY(code_mapping_id)
);
CREATE UNIQUE INDEX idx_code_mappings_unique ON code_mappings(code,type);

-- NOTE: Source: supplemental/supplementalData.xml//personNamesDefaults/nameOrderLocalesDefault
CREATE TABLE person_name_defaults (
     pers_name_def_id   INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    -- givenFirst, surnameFirst
    ,value              VARCHAR(12) NOT NULL COLLATE NOCASE
    ,PRIMARY KEY(pers_name_def_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,CHECK( value REGEXP '^[a-zA-Z]+$' )
);
CREATE UNIQUE INDEX idx_person_name_defaults_unique ON person_name_defaults(locale,value);

-- NOTE: Source: supplemental/supplementalData.xml//references/reference
CREATE TABLE refs (
     ref_id             INTEGER
    ,code               VARCHAR(5) NOT NULL COLLATE NOCASE
    ,uri                VARCHAR(1048)
    ,description        TEXT
    ,PRIMARY KEY(ref_id)
    ,CHECK( code REGEXP '^[a-zA-Z0-9]+' )
    ,CHECK( uri REGEXP '^(?:http|https):\/\/' )
);
CREATE UNIQUE INDEX idx_refs_unique ON refs(code);

-- NOTE: Source: bcp47/timezone.xml//ldmlBCP47/keyword/key/type[@name]
CREATE TABLE bcp47_timezones (
     bcp47_tz_id        INTEGER
    -- Example: jptyo
    ,tzid               VARCHAR(10) NOT NULL COLLATE NOCASE
    -- Example: ["America/Phoenix", "US/Arizona"]
    ,alias              TEXT[]
    ,preferred          VARCHAR(10)
    ,description        TEXT
    ,deprecated         BOOLEAN DEFAULT FALSE
    ,PRIMARY KEY(bcp47_tz_id)
    ,CHECK( tzid REGEXP '^[a-z0-9]+$' )
    ,CHECK( preferred REGEXP '^[a-z0-9]+$' )
);
CREATE UNIQUE INDEX idx_bcp47_timezones_unique ON bcp47_timezones(tzid);

-- NOTE: Source: bcp47/currency.xml//ldmlBCP47/keyword/key/type[@name]
CREATE TABLE bcp47_currencies (
     bcp47_curr_id      INTEGER
    -- Example: jptyo
    ,currid             VARCHAR(10) NOT NULL COLLATE NOCASE
    -- ISO 4217 3-characters code
    ,code               VARCHAR(3) NOT NULL
    ,description        TEXT
    -- Is flagged as obsolete if this was an old currency code
    ,is_obsolete        BOOLEAN DEFAULT FALSE
    ,PRIMARY KEY(bcp47_curr_id)
    ,CHECK( currid REGEXP '^[a-z0-9]+$' )
    ,FOREIGN KEY(code) REFERENCES currencies(currency) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_bcp47_currencies_unique ON bcp47_currencies(currid);

-- TODO: check actual size of the columns
-- NOTE: Source: bcp47/*.xml//ldmlBCP47/keyword/key[@name]
CREATE TABLE bcp47_extensions (
     bcp47_ext_id       INTEGER
    ,category           VARCHAR(20) NOT NULL
    -- ex: ca, co
    ,extension          VARCHAR(2) NOT NULL COLLATE NOCASE
    ,alias              VARCHAR(20) COLLATE NOCASE
    ,value_type         VARCHAR(20) COLLATE NOCASE
    ,description        TEXT
    ,deprecated         BOOLEAN DEFAULT FALSE
    ,PRIMARY KEY(bcp47_ext_id)
    ,CHECK( category REGEXP '^[a-zA-Z][a-zA-Z\_]+$' )
    ,CHECK( extension REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( alias REGEXP '^[a-zA-Z0-9]+$' )
);
CREATE UNIQUE INDEX idx_bcp47_extensions_unique ON bcp47_extensions(category,extension);

CREATE TABLE bcp47_values (
     bcp47_value_id     INTEGER
    ,category           VARCHAR(20) NOT NULL
    ,extension          VARCHAR(2) NOT NULL COLLATE NOCASE
    ,value              VARCHAR(20) NOT NULL COLLATE NOCASE
    ,description        TEXT
    ,PRIMARY KEY(bcp47_value_id)
    ,FOREIGN KEY(category,extension) REFERENCES bcp47_extensions(category,extension) ON UPDATE CASCADE ON DELETE RESTRICT
    ,CHECK( value REGEXP '^[a-zA-Z0-9][a-zA-Z0-9\-\_]+$' )
);
CREATE UNIQUE INDEX idx_bcp47_values_unique ON bcp47_values(extension, value);

-- NOTE: Source: annotations/*.xml
CREATE TABLE annotations (
     annotation_id      INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,annotation         VARCHAR(3) NOT NULL
    ,defaults           TEXT[] NOT NULL
    ,tts                TEXT
    ,PRIMARY KEY(annotation_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_annotations_unique ON annotations(locale, annotation);

-- Rule-Based Number Format
-- NOTE: Source: rbnf/*.xml
CREATE TABLE rbnf (
     rbnf_id            INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,grouping           VARCHAR(20) NOT NULL COLLATE NOCASE
    ,ruleset            VARCHAR(42) NOT NULL COLLATE NOCASE
    ,rule_id            VARCHAR(42) NOT NULL COLLATE NOCASE
    ,rule_value         TEXT NO NULL
    ,PRIMARY KEY(rbnf_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_rbnf_unique ON rbnf(locale, grouping, ruleset, rule_id);

-- NOTE: Source: casing/*.xml
CREATE TABLE casings (
     casing_id          INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,token              VARCHAR(2) NOT NULL COLLATE NOCASE
    ,value              VARCHAR(20) NOT NULL COLLATE NOCASE
    ,PRIMARY KEY(casing_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_casings_unique ON casings(locale, token);

-- NOTE: Source: main/*.xml->localeDisplayNames->languages
CREATE TABLE locales_l10n (
     locales_l10n_id    INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,locale_id          VARCHAR(20) NOT NULL COLLATE NOCASE
    ,locale_name        TEXT NOT NULL
    -- Example: long, menu, secondary, short, variant
    ,alt                VARCHAR(20)
    ,PRIMARY KEY(locales_l10n_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(locale_id) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,CHECK( alt REGEXP '^[a-z][a-z\-]+$' )
);
CREATE UNIQUE INDEX idx_locales_l10n_unique ON locales_l10n(locale, locale_id, IFNULL(alt, ''));

-- NOTE: Source: main/*.xml->localeDisplayNames->scripts
CREATE TABLE scripts_l10n (
     scripts_l10n_id    INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,script             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,locale_name        TEXT NOT NULL
    -- Example: secondary, short, stand-alone, variant
    ,alt                VARCHAR(20)
    ,PRIMARY KEY(scripts_l10n_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(script) REFERENCES scripts(script) ON UPDATE CASCADE ON DELETE RESTRICT
    ,CHECK( alt REGEXP '^[a-z][a-z\-]+$' )
);
CREATE UNIQUE INDEX idx_scripts_l10n_unique ON scripts_l10n(locale,script, IFNULL(alt, ''));

-- NOTE: Source: main/*.xml->localeDisplayNames->territories
CREATE TABLE territories_l10n (
     terr_l10n_id       INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,territory          VARCHAR(3) NOT NULL COLLATE NOCASE
    ,locale_name        TEXT NOT NULL
    -- Example: biot, chagos, short, variant
    ,alt                VARCHAR(20)
    ,PRIMARY KEY(terr_l10n_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(territory) REFERENCES territories(territory) ON UPDATE CASCADE ON DELETE RESTRICT
    ,CHECK( alt REGEXP '^[a-z][a-z\-]+$' )
);
CREATE UNIQUE INDEX idx_territories_l10n_unique ON territories_l10n(locale,territory, IFNULL(alt, ''));

-- NOTE: Source: main/*.xml->localeDisplayNames->variants
CREATE TABLE variants_l10n (
     var_l10n_id        INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,variant            VARCHAR(20) NOT NULL COLLATE NOCASE
    ,locale_name        TEXT NOT NULL
    -- Example: variant
    ,alt                VARCHAR(20)
    ,PRIMARY KEY(var_l10n_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(variant) REFERENCES variants(variant) ON UPDATE CASCADE ON DELETE RESTRICT
    ,CHECK( alt REGEXP '^[a-z][a-z\-]+$' )
);
CREATE UNIQUE INDEX idx_variants_l10n_unique ON variants_l10n(locale,variant, IFNULL(alt, ''));

-- NOTE: Source: main/*.xml->//currencies/currency/displayName
CREATE TABLE currencies_l10n (
     curr_l10n_id       INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,currency           VARCHAR(3) NOT NULL COLLATE NOCASE
    -- This is used to spell singular or plural: one, other
    ,count              VARCHAR(7)
    ,locale_name        TEXT NOT NULL
    ,symbol             VARCHAR(5)
    ,PRIMARY KEY(curr_l10n_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(currency) REFERENCES currencies(currency) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_currencies_l10n_unique ON currencies_l10n(locale, currency, count);

-- NOTE: Source: main/*.xml->/ldml/dates/timeZoneNames/zone[@type]
CREATE TABLE timezones_cities (
     tz_city_id         INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,timezone           VARCHAR(42) NOT NULL COLLATE NOCASE
    ,city               TEXT NOT NULL
    ,alt                VARCHAR(20)
    ,PRIMARY KEY(tz_city_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(timezone) REFERENCES timezones(timezone) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_timezones_cities_unique ON timezones_cities(locale, timezone, IFNULL(alt, ''));

-- NOTE: Source: main/*.xml->/ldml/dates/timeZoneNames/zone[@type]
CREATE TABLE timezones_formats (
     tz_fmt_id          INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,type               VARCHAR(12) NOT NULL COLLATE NOCASE
    ,subtype            VARCHAR(12) COLLATE NOCASE
    ,format_pattern     TEXT NOT NULL
    ,PRIMARY KEY(tz_fmt_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_timezones_formats_unique ON timezones_formats(locale, type, format_pattern, IFNULL(subtype, ''));

-- NOTE: Source: main/*.xml->/ldml/dates/timeZoneNames/zone[@type]
CREATE TABLE timezones_names (
     tz_name_id         INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,timezone           VARCHAR(42) NOT NULL COLLATE NOCASE
    -- long, short
    ,width              VARCHAR(7) NOT NULL
    ,generic            TEXT
    ,standard           TEXT
    ,daylight           TEXT
    ,PRIMARY KEY(tz_name_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(timezone) REFERENCES timezones(timezone) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_timezones_names_unique ON timezones_names(locale, timezone, width);

-- NOTE: Source: main/*.xml->/ldml/dates/timeZoneNames/metazone[@type]
CREATE TABLE metazones_names (
     metatz_name_id     INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,metazone           VARCHAR(42) NOT NULL COLLATE NOCASE
    -- long, short
    ,width              VARCHAR(7) NOT NULL
    ,generic            TEXT
    ,standard           TEXT
    ,daylight           TEXT
    ,PRIMARY KEY(metatz_name_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(metazone) REFERENCES metazones(metazone) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_metazones_names_unique ON metazones_names(locale, metazone, width);

-- Contains the localised terms used in different parts of a calendar system
-- Source: main/*.xml/ldml/dates/calendars/calendar[@type]/*[local-name()="months" or local-name()="days" or local-name()="quarters" or local-name()="dayPeriods"]
CREATE TABLE calendar_terms (
     cal_term_id        INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,calendar           VARCHAR(20) NOT NULL COLLATE NOCASE
    -- day, month, quarter, day_period, cyclic_day, cyclic_solar, cyclic_year, cyclic_zodiac for the Chinese calendar
    ,term_type          VARCHAR(10) NOT NULL
    -- Example: format, stand-alone
    ,term_context       VARCHAR(12) NOT NULL
    -- Example: abbreviated, short, wide, narrow, 
    ,term_width         VARCHAR(12) NOT NULL
    ,alt                VARCHAR(12)
    -- leap
    ,yeartype           VARCHAR(12)
    -- 1, 2... 12 for months
    -- mon, tue, ... sun for days
    -- 1, 2, 3, 4 for quarters
    -- midnight, am, noon, pm, morning1, afternoon1, evening1, night1 for day periods
    ,term_name          VARCHAR(20) NOT NULL COLLATE NOCASE
    -- Example: January, February, ... December
    -- Example: Monday, Tuesday etc... Sunday
    ,term_value         TEXT NOT NULL
    ,PRIMARY KEY(cal_term_id)
    ,CHECK( term_type REGEXP '^[a-zA-Z][a-zA-Z0-9\_]+$' )
    ,CHECK( term_context REGEXP '^[a-zA-Z][a-zA-Z0-9]+(?:\-[a-zA-Z0-9]+)*$' )
    ,CHECK( term_width REGEXP '^[a-zA-Z][a-zA-Z0-9\_]+$' )
    ,CHECK( alt REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( term_name REGEXP '^[a-zA-Z0-9]+$' )
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(calendar) REFERENCES calendars(calendar) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_calendar_terms_unique ON calendar_terms(locale, calendar, term_type, term_context, term_width, IFNULL(alt, ''), IFNULL(yeartype, ''), term_name);

CREATE TABLE calendar_eras_l10n (
     cal_era_l10n_id    INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,calendar           VARCHAR(20) NOT NULL COLLATE NOCASE
    -- Example: abbreviated, short, wide, narrow, 
    -- This is determined by the tag itself: eraNames -> wide, eraAbbr -> abbreviated, eraNarrow -> narrow
    -- Unicode could have used a common tag with a descriptive attribute value like they did for other parts, but they chose to use different tags
    ,era_width          VARCHAR(12) NOT NULL
    -- Example: 0, 1
    ,era_id             VARCHAR(10) NOT NULL COLLATE NOCASE
    ,alt                VARCHAR(12)
    -- Example: Before Christ
    ,locale_name        TEXT NOT NULL
    ,PRIMARY KEY(cal_era_l10n_id)
    ,CHECK( era_width REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( era_id REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( alt REGEXP '^[a-zA-Z0-9]+$' )
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(calendar) REFERENCES calendars(calendar) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_calendar_eras_l10n_unique ON calendar_eras_l10n(locale, calendar, era_width, era_id, IFNULL(alt, ''));

-- Source: main/*.xml->dates/calendars/calendar/dateFormats
-- Source: main/*.xml->dates/calendars/calendar/timeFormats
CREATE TABLE calendar_formats_l10n (
     cal_fmt_l10n_id    INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,calendar           VARCHAR(20) NOT NULL COLLATE NOCASE
    -- date, time
    ,format_type        VARCHAR(10) NOT NULL
    -- full, long, medium short
    ,format_length      VARCHAR(10) NOT NULL
    -- ascii
    ,alt                VARCHAR(12)
    -- "The id attribute is a so-called "skeleton""
    -- <https://www.unicode.org/reports/tr35/tr35-dates.html#availableFormats_appendItems>
    -- ahmmsszzzz
    ,format_id          VARCHAR(20) NOT NULL
    -- h:mm:ss a zzzz
    ,format_pattern     VARCHAR(20) NOT NULL
    ,PRIMARY KEY(cal_fmt_l10n_id)
    ,CHECK( format_type REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( format_length REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( alt REGEXP '^[a-zA-Z0-9]+$' )
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(calendar) REFERENCES calendars(calendar) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_calendar_formats_l10n_unique ON calendar_formats_l10n(locale, calendar, format_type, format_length, IFNULL(alt, ''), format_id);

-- Source: main/*.xml->dates/calendars/calendar/dateTimeFormats/dateTimeFormatLength/dateTimeFormat/pattern
CREATE TABLE calendar_datetime_formats (
     cal_dt_fmt_id      INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,calendar           VARCHAR(20) NOT NULL COLLATE NOCASE
    -- full, long, medium short
    ,format_length      VARCHAR(10) NOT NULL
    -- atTime, standard (when non-existent in XML)
    ,format_type        VARCHAR(10) NOT NULL
    ,format_pattern     VARCHAR(20) NOT NULL
    ,PRIMARY KEY(cal_dt_fmt_id)
    ,CHECK( format_length REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( format_type REGEXP '^[a-zA-Z0-9][a-zA-Z0-9\-]+$' )
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(calendar) REFERENCES calendars(calendar) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_calendar_datetime_formats_unique ON calendar_datetime_formats(locale, calendar, format_length, format_type, format_pattern);

-- Source: main/*.xml->dates/calendars/calendar/dateTimeFormats/availableFormats/dateFormatItem
CREATE TABLE calendar_available_formats (
     cal_avail_fmt_id   INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,calendar           VARCHAR(20) NOT NULL COLLATE NOCASE
    -- GyMMM
    ,format_id          VARCHAR(20) NOT NULL
    -- U年MMM
    ,format_pattern     VARCHAR(20) NOT NULL
    -- Example: one, other
    ,count              VARCHAR(10) COLLATE NOCASE
    -- Example: ascii
    ,alt                VARCHAR(12)
    ,PRIMARY KEY(cal_avail_fmt_id)
    ,CHECK( format_id REGEXP '^[a-zA-Z0-9]+$' )
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(calendar) REFERENCES calendars(calendar) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_calendar_available_formats_unique ON calendar_available_formats(locale, calendar, format_id, IFNULL(count, ''), IFNULL(alt, ''));

-- Source: main/*.xml->dates/calendars/calendar/dateTimeFormats/appendItems/appendItem
CREATE TABLE calendar_append_formats (
     cal_append_fmt_id  INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,calendar           VARCHAR(20) NOT NULL COLLATE NOCASE
    ,format_id          VARCHAR(20) NOT NULL
    ,format_pattern     VARCHAR(20) NOT NULL
    ,PRIMARY KEY(cal_append_fmt_id)
    ,CHECK( format_id REGEXP '^[a-zA-Z0-9]+(\-[a-zA-Z0-9]+)*$' )
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(calendar) REFERENCES calendars(calendar) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_calendar_append_formats_unique ON calendar_append_formats(locale, calendar, format_id);

-- Source: main/*.xml->dates/calendars/calendar/dateTimeFormats/intervalFormats/intervalFormatItem
CREATE TABLE calendar_interval_formats (
     cal_int_fmt_id     INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,calendar           VARCHAR(20) NOT NULL COLLATE NOCASE
    -- 'Hm'; For 'intervalFormatFallback', the value here would be 'default'
    ,format_id          VARCHAR(20) NOT NULL
    -- 'H'; Would be 'default' if this is the default format
    ,greatest_diff_id   VARCHAR(10) NOT NULL
    -- H時mm分～H時mm分
    ,format_pattern     VARCHAR(20) NOT NULL
    -- variant
    ,alt                VARCHAR(12)
    -- The next 3 columns are a break-down of the format_pattern and placed here for convenience
    -- so the developer does not have to compute it
    ,part1              VARCHAR(20) NOT NULL
    ,separator          VARCHAR(5) NOT NULL
    ,part2              VARCHAR(20) NOT NULL
    ,repeating_field    VARCHAR(10)
    ,PRIMARY KEY(cal_int_fmt_id)
    ,CHECK( format_id REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( greatest_diff_id REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( alt REGEXP '^[a-zA-Z0-9]+$' )
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(calendar) REFERENCES calendars(calendar) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_calendar_interval_formats_unique ON calendar_interval_formats(locale, calendar, format_id, greatest_diff_id, IFNULL(alt, ''));

-- Source: main/*.xml->cyclicNameSets/cyclicNameSet
-- This is used for Chinese calendar with Zodiac, lunar system
CREATE TABLE calendar_cyclics_l10n (
     cal_int_fmt_id     INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,calendar           VARCHAR(20) NOT NULL COLLATE NOCASE
    -- dayParts, solarTerms, years, zodiacs
    ,format_set         VARCHAR(20) NOT NULL
    -- format
    ,format_type        VARCHAR(10) NOT NULL
    -- abbreviated
    ,format_length      VARCHAR(10) NOT NULL
    -- 1, 2, 3... 10
    ,format_id          INTEGER NOT NULL
    ,format_pattern     VARCHAR(20) NOT NULL
    ,PRIMARY KEY(cal_int_fmt_id)
    ,CHECK( format_set REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( format_type REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( format_length REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( format_id REGEXP '^[a-zA-Z0-9]+$' )
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(calendar) REFERENCES calendars(calendar) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_calendar_cyclics_l10n_unique ON calendar_cyclics_l10n(locale, calendar, format_set, format_type, format_length, format_id);

-- Source: main/*.xml/ldml/dates/fields
CREATE TABLE date_fields_l10n (
     date_field_id      INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    -- Example: era, year, quarter, month, week, weekOfMonth, day, dayOfYear, weekday, weekdayOfMonth, mon..sun, dayperiod, hour, minute, second, zone and for each *-short. *-narrow
    ,field_type         VARCHAR(10) NOT NULL COLLATE NOCASE
    -- standard (if none defined), short, narrow
    ,field_length       VARCHAR(10) NOT NULL
    ,relative           INTEGER NOT NULL
    ,locale_name        TEXT NOT NULL
    ,PRIMARY KEY(date_field_id)
    ,CHECK( field_type REGEXP '^[a-zA-Z][a-zA-Z0-9]+(?:\-[a-zA-Z][a-zA-Z0-9]+)*$' )
    ,CHECK( field_length REGEXP '^[a-zA-Z][a-zA-Z0-9]+$' )
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_date_fields_l10n_unique ON date_fields_l10n(locale, field_type, field_length, relative);

-- Source: main/*.xml->//layout/orientation/characterOrder
-- left-to-right or right-to-left
CREATE TABLE locales_info (
     locales_info_id    INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    -- char_orientation (ltr, rtl) //layout/orientation
    -- quote_start, quote_end //delimiters/*[local-name()="quotationStart" or local-name()="quotationEnd" or local-name()="alternateQuotationStart" or local-name()="alternateQuotationEnd"]
    -- decimal, group, list, percent, minus, exponent, super_script, per_mile, inifinity //numbers/symbols/*
    ,property           VARCHAR(20) NOT NULL
    ,value              TEXT
    ,PRIMARY KEY(locales_info_id)
    ,CHECK( property REGEXP '^[a-zA-Z][a-zA-Z0-9\_]+$' )
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_locales_info_unique ON locales_info(locale, property);

-- Source: supplemental/languageInfo.xml/supplementalData/languageMatching/languageMatches/languageMatch
CREATE TABLE languages_match (
     lang_match_id      INTEGER
    -- Example: en-GB, "en-(?<script>[a-zA-Z0-9]+)-(?<territory>(?!AS|CA|GU|MH|MP|PH|PR|UM|US|VI)[a-zA-Z0-9]+)"
    ,desired            VARCHAR(200) NOT NULL COLLATE NOCASE
    -- Example: en-Latn, "en\-$+{script}\-$+{territory}"
    ,supported          VARCHAR(200) NOT NULL COLLATE NOCASE
    -- Used to be a percentage (100 to 0), and now is a distance (0 to 100)
    ,distance           INTEGER NOT NULL
    -- desired <-> supported, supported <-> desired
    ,is_symetric        BOOLEAN DEFAULT TRUE
    -- desired and suported can be a scalar, or a regular expression. This boolean helps when making query
    ,is_regexp          BOOLEAN DEFAULT FALSE
    -- A sequence used to process regular expression in the right order, so it is only set for regexp
    ,sequence           INTEGER
    ,PRIMARY KEY(lang_match_id)
);
CREATE UNIQUE INDEX idx_languages_match_unique ON languages_match(desired, supported);

-- Source: supplemental/units.xml/supplementalData/unitPrefixes/unitPrefix
CREATE TABLE unit_prefixes (
     unit_prefix_id     INTEGER
    -- Example: micro, milli, centi, kilo, mega, giga, etc..
    ,unit_id            VARCHAR(10) NOT NULL COLLATE NOCASE
    ,symbol             VARCHAR(3) NOT NULL COLLATE NOCASE
    ,power              INTEGER NOT NULL
    ,factor             INTEGER NOT NULL
    ,PRIMARY KEY(unit_prefix_id)
    ,CHECK( unit_id REGEXP '^[a-z]+$' )
);
CREATE UNIQUE INDEX idx_unit_prefixes_unique ON unit_prefixes(unit_id);

-- Source: supplemental/units.xml/supplementalData/unitConstants/unitConstant
CREATE TABLE unit_constants (
     unit_constant_id   INTEGER
    -- Example: lb_to_kg, ft2_to_m2
    ,constant           VARCHAR(10) NOT NULL COLLATE NOCASE
    -- Example: gravity, PI, G, ft_to_m*ft_to_m
    ,expression         TEXT NOT NULL COLLATE NOCASE
    -- The computed value from the expression
    ,value              DECIMAL NOT NULL
    ,description        TEXT
    -- Example: approximate
    ,status             VARCHAR(20)
    ,PRIMARY KEY(unit_constant_id)
    ,CHECK( constant REGEXP '^[a-zA-Z](?:[a-zA-Z0-9]+(?:\_[a-zA-Z0-9]+)*)?$' )
    ,CHECK( status REGEXP '^[a-zA-Z][a-zA-Z0-9\_]+$' )
);
CREATE UNIQUE INDEX idx_unit_constants_unique ON unit_constants(constant);

-- Source: supplemental/units.xml/supplementalData/unitQuantities/unitQuantity
CREATE TABLE unit_quantities (
     unit_quantity_id   INTEGER
    -- Example: kilogram-square-meter-per-square-second-square-ampere
    ,base_unit          VARCHAR(70) NOT NULL COLLATE NOCASE
    -- Example: electric-resistance
    ,quantity           VARCHAR(30) NOT NULL COLLATE NOCASE
    -- Example: simple
    ,status             VARCHAR(20)
    -- Possibly some circumstantial comments
    ,comment            TEXT
    ,PRIMARY KEY(unit_quantity_id)
    ,CHECK( base_unit REGEXP '^[a-zA-Z][a-zA-Z0-9]+(?:\-[a-zA-Z0-9]+)*$' )
    ,CHECK( status REGEXP '^[a-zA-Z][a-zA-Z0-9\_]+$' )
);
CREATE UNIQUE INDEX idx_unit_quantities_unique ON unit_quantities(base_unit);

-- Source: supplemental/units.xml/supplementalData/convertUnits/convertUnit
CREATE TABLE unit_conversions (
     unit_conversion_id INTEGER
    -- Example: candela, earth-mass, etc
    ,source             VARCHAR(70) NOT NULL COLLATE NOCASE
    ,base_unit          VARCHAR(70) NOT NULL COLLATE NOCASE
    -- Optional. There may not be an expression, but insteance a one-to-one value
    -- Example: 1000*item_per_mole/glucose_molar_mass
    ,expression         TEXT NULL COLLATE NOCASE
    -- If expression is NULL, this too, would be NULL
    ,factor             DECIMAL NULL
    -- ["si_acceptable", "metric", "prefixable"]
    ,systems            TEXT[]
    -- luminous-intensity, mass, volume, area, length, time, year-duration, electric-current, temperature, angle, substance-amount, portion, digital, graphics, typewidth, frequency, force, pressure, pressure-per-length, energy, th, power, voltage, electric-resistance, electric-charge, electric-capacitance, electric-inductance, electric-conductance, radioactivity, ionizing-radiation, catalytic-activity, solid-angle, speed, magnetic-induction, magnetic-flux, acceleration, luminance, luminous-flux, concentration-mass, japanese additions, 
    ,category           VARCHAR(20)
    ,PRIMARY KEY(unit_conversion_id)
    ,CHECK( category REGEXP '^[a-zA-Z][a-zA-Z0-9]+(?:\-[a-zA-Z0-9]+)*$' )
    ,FOREIGN KEY(base_unit) REFERENCES unit_quantities(base_unit) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_unit_conversions_unique ON unit_conversions(source, base_unit);

-- Source: supplemental/units.xml/supplementalData/unitPreferenceData/unitPreferences/unitPreference
-- <https://cldr-smoke.unicode.org/spec/main/ldml/tr35-info.html#Unit_Preferences_Data>
CREATE TABLE unit_prefs (
     unit_pref_id       INTEGER
    -- Example: cubic-centimeter. One would expect this is a foreign key to unit_quantities, but it is not unfortunately
    ,unit_id            VARCHAR(70) NOT NULL COLLATE NOCASE
    ,territory          VARCHAR(3) NOT NULL
    -- Example: area, concentration, consumption, duration, energy, length, power, pressure, speed, temperature, volume, year-duration
    ,category           VARCHAR(20)
    -- Example: default, geograph, land, floor, blood-glucose, etc
    ,usage              VARCHAR(20)
    -- Example: 2.5
    ,geq                DECIMAL
    -- Example: precision-increment/50
    -- <https://github.com/unicode-org/icu/blob/main/docs/userguide/format_parse/numbers/skeletons.md#precision>
    ,skeleton           VARCHAR(70)
    ,PRIMARY KEY(unit_pref_id)
    ,CHECK( unit_id REGEXP '^[a-zA-Z][a-zA-Z0-9]+(?:\-[a-zA-Z0-9]+)*$' )
    ,CHECK( category REGEXP '^[a-zA-Z]+(?:\-[a-zA-Z0-9]+)*$' )
    ,CHECK( usage REGEXP '^[a-zA-Z]+(?:\-[a-zA-Z0-9]+)*$' )
    ,CHECK( skeleton REGEXP '^[a-zA-Z]+(?:\-[a-zA-Z0-9\/]+)*$' )
    ,FOREIGN KEY(territory) REFERENCES territories(territory) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_unit_prefs_unique ON unit_prefs(category, usage, unit_id, territory, geq);

-- Source: supplemental/units.xml/supplementalData/metadata/alias/unitAlias
CREATE TABLE unit_aliases (
     unit_alias_id      INTEGER
    ,alias              VARCHAR(70) NOT NULL COLLATE NOCASE
    ,target             VARCHAR(70) NOT NULL COLLATE NOCASE
    ,reason             VARCHAR(20)
    ,PRIMARY KEY(unit_alias_id)
    ,CHECK( alias REGEXP '^[a-zA-Z][a-zA-Z0-9]+(?:\-[a-zA-Z0-9]+)*$' )
    ,CHECK( target REGEXP '^[a-zA-Z][a-zA-Z0-9]+(?:\-[a-zA-Z0-9]+)*$' )
    ,CHECK( reason REGEXP '^[a-zA-Z][a-zA-Z0-9]+$' )
);
CREATE UNIQUE INDEX idx_unit_aliases_unique ON unit_aliases(alias);

-- Source: main/*.xml/ldml/units/unitLength/compoundUnit
-- Source: main/*.xml/ldml/units/unitLength/unit
-- Source: main/*.xml/ldml/units/unitLength/coordinateUnit
CREATE TABLE units_l10n (
     units_l10n_id      INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    -- Example: long, short, narrow
    ,format_length      VARCHAR(10) NOT NULL COLLATE NOCASE
    -- Example: compound, regular
    ,unit_type          VARCHAR(20) NOT NULL COLLATE NOCASE
    -- Example: 10p-1, torque-newton-meter
    ,unit_id            VARCHAR(70) NOT NULL COLLATE NOCASE
    ,unit_pattern       VARCHAR(70) NOT NULL COLLATE NOCASE
    -- regular, prefix, per-unit
    ,pattern_type       VARCHAR(10) COLLATE NOCASE
    -- An optional locale display name
    ,locale_name        TEXT
    ,count              VARCHAR(10) COLLATE NOCASE
    -- Example: masculine, feminine, neuter, inanimate, common
    ,gender             VARCHAR(10) DEFAULT 'masculine' COLLATE NOCASE
    -- Example: nominative, accusative, genitive, dative
    ,gram_case          VARCHAR(10) COLLATE NOCASE
    ,PRIMARY KEY(units_l10n_id)
    ,CHECK( format_length REGEXP '^[a-zA-Z][a-zA-Z0-9]+$' )
    ,CHECK( unit_type REGEXP '^[a-zA-Z][a-zA-Z0-9]+$' )
    ,CHECK( unit_id REGEXP '^[a-zA-Z0-9]+(?:\-[a-zA-Z0-9]+)*$' )
    ,CHECK( pattern_type REGEXP '^[a-zA-Z][a-zA-Z0-9]+(?:\-[a-zA-Z0-9]+)*$' )
    ,CHECK( count REGEXP '^[a-zA-Z][a-zA-Z0-9]+$' )
    ,CHECK( gender REGEXP '^[a-zA-Z][a-zA-Z0-9]+$' )
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_units_l10n_unique ON units_l10n(locale, format_length, unit_type, unit_id, IFNULL(count, ''), IFNULL(gender, ''), IFNULL(gram_case, ''));

-- Source: main/*.xml/ldml/numbers/defaultNumberingSystem
-- Source: main/*.xml/ldml/numbers/otherNumberingSystems/*[local-name()="native" or local-name()="traditional" or local-name()="finance"]
-- <https://unicode.org/reports/tr35/tr35-numbers.html#defaultNumberingSystem>
-- <https://unicode.org/reports/tr35/tr35-numbers.html#otherNumberingSystems>
CREATE TABLE locale_number_systems (
     locale_num_sys_id  INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    -- The default numbering system for this locale
    ,number_system      VARCHAR(10)
    ,native             VARCHAR(10)
    ,traditional        VARCHAR(10)
    ,finance            VARCHAR(10)
    ,PRIMARY KEY(locale_num_sys_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(number_system) REFERENCES number_systems(number_system) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(native) REFERENCES number_systems(number_system) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(traditional) REFERENCES number_systems(number_system) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(finance) REFERENCES number_systems(number_system) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_locale_number_systems_unique ON locale_number_systems(locale, IFNULL(number_system, ''));

-- Source: main/*.xml/ldml/numbers/symbols
CREATE TABLE number_symbols_l10n (
     number_symbol_id   INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,number_system      VARCHAR(10) NOT NULL COLLATE NOCASE
    -- Example: approximately, currency_decimal, currency_group, decimal, decimal, etc...
    ,property           VARCHAR(20) NOT NULL COLLATE NOCASE
    ,value              VARCHAR(5) NOT NULL
    -- Example: variant
    ,alt                VARCHAR(12)
    ,PRIMARY KEY(number_symbol_id)
    ,CHECK( property REGEXP '^[a-zA-Z][a-zA-Z0-9_]+$' )
    ,CHECK( alt REGEXP '^[a-zA-Z0-9]+$' )
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(number_system) REFERENCES number_systems(number_system) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_number_symbols_l10n_unique ON number_symbols_l10n(locale, number_system, property, IFNULL(alt, ''));

-- Source: main/*.xml/ldml/numbers/decimalFormats
-- Source: main/*.xml/ldml/numbers/scientificFormats
-- Source: main/*.xml/ldml/numbers/percentFormats
-- Source: main/*.xml/ldml/numbers/currencyFormats
-- Source: main/*.xml/ldml/numbers/miscPatterns
CREATE TABLE number_formats_l10n (
     number_format_id   INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,number_system      VARCHAR(10) NOT NULL COLLATE NOCASE
    -- Example: decimal, scientific, percent, currency, misc
    ,number_type        VARCHAR(70) NOT NULL COLLATE NOCASE
    -- Example: long, short, narrow
    ,format_length      VARCHAR(10) NOT NULL COLLATE NOCASE
    -- Example: standard, default (if nothing specified)
    -- <currencyFormat type="accounting">
    ,format_type        VARCHAR(10) NOT NULL
    -- Example: 'default' if none is provided
    ,format_id          VARCHAR(25) NOT NULL
    ,format_pattern     VARCHAR(20) NOT NULL
    -- Example: noCurrency
    ,alt                VARCHAR(12)
    -- This is used to spell singular or plural: one, other
    ,count              VARCHAR(7)
    ,PRIMARY KEY(number_format_id)
    ,CHECK( number_type REGEXP '^[a-zA-Z][a-zA-Z0-9]+$' )
    ,CHECK( format_length REGEXP '^[a-zA-Z][a-zA-Z0-9]+$' )
    ,CHECK( format_type REGEXP '^[a-zA-Z][a-zA-Z0-9]+$' )
    ,CHECK( format_id REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( alt REGEXP '^[a-zA-Z0-9]+$' )
    ,CHECK( count REGEXP '^[a-zA-Z0-9]+$' )
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(number_system) REFERENCES number_systems(number_system) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_number_formats_l10n_unique ON number_formats_l10n(locale, number_system, number_type, format_length, format_type, format_id, IFNULL(alt, ''), IFNULL(count, ''));

-- Source: main/*.xml/ldml/localeDisplayNames/types[@type="numbers"]
CREATE TABLE number_systems_l10n (
     num_sys_l10n_id    INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,number_system      VARCHAR(10) NOT NULL COLLATE NOCASE
    ,locale_name        TEXT
    ,alt                VARCHAR(12)
    ,PRIMARY KEY(num_sys_l10n_id)
    ,CHECK( alt REGEXP '^[a-zA-Z0-9]+$' )
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(number_system) REFERENCES number_systems(number_system) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_number_systems_l10n_unique ON number_systems_l10n(locale, number_system, IFNULL(alt, ''));

-- Source: main/*.xml/ldml/localeDisplayNames/types[@type="calendar"]
CREATE TABLE calendars_l10n (
     calendar_l10n_id   INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,calendar           VARCHAR(20) NOT NULL COLLATE NOCASE
    ,locale_name        TEXT
    ,PRIMARY KEY(calendar_l10n_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    ,FOREIGN KEY(calendar) REFERENCES calendars(calendar) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_calendars_l10n_unique ON calendars_l10n(locale, calendar);

CREATE VIEW collations AS SELECT
     value AS "collation"
    ,description
FROM bcp47_values
WHERE extension='co';

-- Source: main/*.xml/ldml/localeDisplayNames/types[@type="collation"]
CREATE TABLE collations_l10n (
     collation_l10n_id  INTEGER
    ,locale             VARCHAR(20) NOT NULL COLLATE NOCASE
    ,collation          VARCHAR(10) NOT NULL COLLATE NOCASE
    ,locale_name        TEXT
    ,CHECK( collation REGEXP '^[a-zA-Z][a-zA-Z0-9]+$' )
    ,PRIMARY KEY(collation_l10n_id)
    ,FOREIGN KEY(locale) REFERENCES locales(locale) ON UPDATE CASCADE ON DELETE RESTRICT
    -- Unfortunately, SQLite does not allow a foreign key reference to a view
    -- ,FOREIGN KEY(collation) REFERENCES collations(collation) ON UPDATE CASCADE ON DELETE RESTRICT
);
CREATE UNIQUE INDEX idx_collations_l10n_unique ON collations_l10n(locale, collation);
