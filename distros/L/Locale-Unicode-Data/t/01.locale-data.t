#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use vars qw( $DEBUG );
    use utf8;
    use version;
    use Config;
    use Test::More;
    use DBD::SQLite;
    if( version->parse( $DBD::SQLite::sqlite_version ) < version->parse( '3.6.19' ) )
    {
        plan skip_all => 'SQLite driver version 3.6.19 or higher is required. You have version ' . $DBD::SQLite::sqlite_version;
    }
    elsif( $^O eq 'openbsd' && ( $^V >= v5.12.0 && $^V <= v5.12.5 ) )
    {
        plan skip_all => 'Weird memory bug out of my control on OpenBSD for v5.12.0 to 5';
    }
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Locale::Unicode::Data' ) || BAIL_OUT( 'Unable to load Locale::Unicode::Data' );
};

use strict;
use warnings;
use utf8;

my $cldr = Locale::Unicode::Data->new;
isa_ok( $cldr, 'Locale::Unicode::Data' );

# To generate this list:
# perl -lnE '/^sub (?!new|[A-Z]|_)/ and say "can_ok( \$cldr, \''", [split(/\s+/, $_)]->[1], "\'' );"' ./lib/Locale/Unicode/Data.pm
can_ok( $cldr, 'alias' );
can_ok( $cldr, 'aliases' );
can_ok( $cldr, 'annotation' );
can_ok( $cldr, 'annotations' );
can_ok( $cldr, 'bcp47_currency' );
can_ok( $cldr, 'bcp47_currencies' );
can_ok( $cldr, 'bcp47_extension' );
can_ok( $cldr, 'bcp47_extensions' );
can_ok( $cldr, 'bcp47_timezone' );
can_ok( $cldr, 'bcp47_timezones' );
can_ok( $cldr, 'bcp47_value' );
can_ok( $cldr, 'bcp47_values' );
can_ok( $cldr, 'calendar' );
can_ok( $cldr, 'calendars' );
can_ok( $cldr, 'calendar_append_format' );
can_ok( $cldr, 'calendar_append_formats' );
can_ok( $cldr, 'calendar_available_format' );
can_ok( $cldr, 'calendar_available_formats' );
can_ok( $cldr, 'calendar_cyclic_l10n' );
can_ok( $cldr, 'calendar_cyclics_l10n' );
can_ok( $cldr, 'calendar_datetime_format' );
can_ok( $cldr, 'calendar_datetime_formats' );
can_ok( $cldr, 'calendar_era' );
can_ok( $cldr, 'calendar_eras' );
can_ok( $cldr, 'calendar_era_l10n' );
can_ok( $cldr, 'calendar_eras_l10n' );
can_ok( $cldr, 'calendar_format_l10n' );
can_ok( $cldr, 'calendar_formats_l10n' );
can_ok( $cldr, 'calendar_interval_format' );
can_ok( $cldr, 'calendar_interval_formats' );
can_ok( $cldr, 'calendar_l10n' );
can_ok( $cldr, 'calendars_l10n' );
can_ok( $cldr, 'calendar_term' );
can_ok( $cldr, 'calendar_terms' );
can_ok( $cldr, 'casing' );
can_ok( $cldr, 'casings' );
can_ok( $cldr, 'cldr_built' );
can_ok( $cldr, 'cldr_maintainer' );
can_ok( $cldr, 'cldr_version' );
can_ok( $cldr, 'code_mapping' );
can_ok( $cldr, 'code_mappings' );
can_ok( $cldr, 'collation' );
can_ok( $cldr, 'collations' );
can_ok( $cldr, 'collation_l10n' );
can_ok( $cldr, 'collations_l10n' );
can_ok( $cldr, 'currency' );
can_ok( $cldr, 'currencies' );
can_ok( $cldr, 'currency_info' );
can_ok( $cldr, 'currencies_info' );
can_ok( $cldr, 'currency_l10n' );
can_ok( $cldr, 'currencies_l10n' );
can_ok( $cldr, 'database_handler' );
can_ok( $cldr, 'datafile' );
can_ok( $cldr, 'date_field_l10n' );
can_ok( $cldr, 'date_fields_l10n' );
can_ok( $cldr, 'date_term' );
can_ok( $cldr, 'date_terms' );
can_ok( $cldr, 'day_period' );
can_ok( $cldr, 'day_periods' );
can_ok( $cldr, 'decode_sql_arrays' );
can_ok( $cldr, 'error' );
can_ok( $cldr, 'extend_timezones_cities' );
can_ok( $cldr, 'fatal' );
can_ok( $cldr, 'interval_formats' );
can_ok( $cldr, 'l10n' );
can_ok( $cldr, 'language' );
can_ok( $cldr, 'languages' );
can_ok( $cldr, 'language_population' );
can_ok( $cldr, 'language_populations' );
can_ok( $cldr, 'likely_subtag' );
can_ok( $cldr, 'likely_subtags' );
can_ok( $cldr, 'locale' );
can_ok( $cldr, 'locales' );
can_ok( $cldr, 'locale_l10n' );
can_ok( $cldr, 'locales_l10n' );
can_ok( $cldr, 'locales_info' );
can_ok( $cldr, 'locales_infos' );
can_ok( $cldr, 'locale_number_system' );
can_ok( $cldr, 'locale_number_systems' );
can_ok( $cldr, 'make_inheritance_tree' );
can_ok( $cldr, 'metazone' );
can_ok( $cldr, 'metazones' );
can_ok( $cldr, 'metazone_names' );
can_ok( $cldr, 'metazones_names' );
can_ok( $cldr, 'normalise' );
can_ok( $cldr, 'number_format_l10n' );
can_ok( $cldr, 'number_formats_l10n' );
can_ok( $cldr, 'number_symbol_l10n' );
can_ok( $cldr, 'number_symbols_l10n' );
can_ok( $cldr, 'number_system' );
can_ok( $cldr, 'number_systems' );
can_ok( $cldr, 'number_system_l10n' );
can_ok( $cldr, 'number_systems_l10n' );
can_ok( $cldr, 'pass_error' );
can_ok( $cldr, 'person_name_default' );
can_ok( $cldr, 'person_name_defaults' );
can_ok( $cldr, 'rbnf' );
can_ok( $cldr, 'rbnfs' );
can_ok( $cldr, 'reference' );
can_ok( $cldr, 'references' );
can_ok( $cldr, 'script' );
can_ok( $cldr, 'scripts' );
can_ok( $cldr, 'script_l10n' );
can_ok( $cldr, 'scripts_l10n' );
can_ok( $cldr, 'split_interval' );
can_ok( $cldr, 'subdivision' );
can_ok( $cldr, 'subdivisions' );
can_ok( $cldr, 'subdivision_l10n' );
can_ok( $cldr, 'subdivisions_l10n' );
can_ok( $cldr, 'territory' );
can_ok( $cldr, 'territories' );
can_ok( $cldr, 'territory_l10n' );
can_ok( $cldr, 'territories_l10n' );
can_ok( $cldr, 'time_format' );
can_ok( $cldr, 'time_formats' );
can_ok( $cldr, 'timezone' );
can_ok( $cldr, 'timezones' );
can_ok( $cldr, 'timezone_canonical' );
can_ok( $cldr, 'timezone_city' );
can_ok( $cldr, 'timezones_cities' );
can_ok( $cldr, 'timezone_formats' );
can_ok( $cldr, 'timezones_formats' );
can_ok( $cldr, 'timezone_info' );
can_ok( $cldr, 'timezones_info' );
can_ok( $cldr, 'timezone_names' );
can_ok( $cldr, 'timezones_names' );
can_ok( $cldr, 'unit_alias' );
can_ok( $cldr, 'unit_aliases' );
can_ok( $cldr, 'unit_constant' );
can_ok( $cldr, 'unit_constants' );
can_ok( $cldr, 'unit_conversion' );
can_ok( $cldr, 'unit_conversions' );
can_ok( $cldr, 'unit_l10n' );
can_ok( $cldr, 'units_l10n' );
can_ok( $cldr, 'unit_prefix' );
can_ok( $cldr, 'unit_prefixes' );
can_ok( $cldr, 'unit_pref' );
can_ok( $cldr, 'unit_prefs' );
can_ok( $cldr, 'unit_quantity' );
can_ok( $cldr, 'unit_quantities' );
can_ok( $cldr, 'variant' );
can_ok( $cldr, 'variants' );
can_ok( $cldr, 'variant_l10n' );
can_ok( $cldr, 'variants_l10n' );
can_ok( $cldr, 'week_preference' );
can_ok( $cldr, 'week_preferences' );

my $db_file = $cldr->datafile;
ok( defined( $db_file ) && length( $db_file // '' ), 'database file' );
SKIP:
{
    if( !$db_file )
    {
        skip( "No file object returned", 1 );
    }
    ok( -e( $db_file ), "Database file exists" );
};
my $dbh = $cldr->database_handler;
isa_ok( $dbh, 'DBI::db' );
SKIP:
{
    if( !$dbh )
    {
        skip( "Unable to get a database handler.", 1 );
    }
    my $sth_list_tables = eval
    {
        $dbh->prepare( q{SELECT name FROM sqlite_master WHERE type IN ('table','view') AND name NOT LIKE 'sqlite_%' UNION ALL SELECT name FROM sqlite_temp_master WHERE type IN ('table','view') ORDER BY name} )
    } || BAIL_OUT( "Error preparing statement to retrieve a list of all tables: ", ( $@ || $dbh->errstr ) );
    $sth_list_tables->execute;
    my @tables = map( $_->[0], @{$sth_list_tables->fetchall_arrayref} );
    my $expected = [qw(
        aliases annotations bcp47_currencies bcp47_extensions
        bcp47_timezones bcp47_values calendar_append_formats
        calendar_available_formats calendar_cyclics_l10n
        calendar_datetime_formats calendar_eras
        calendar_eras_l10n calendar_formats_l10n
        calendar_interval_formats calendar_terms calendars
        calendars_l10n casings code_mappings collations
        collations_l10n currencies currencies_info
        currencies_l10n date_fields_l10n date_terms day_periods
        language_population languages languages_match
        likely_subtags locale_number_systems locales
        locales_info locales_l10n metainfos metazones
        metazones_names number_formats_l10n number_symbols_l10n
        number_systems number_systems_l10n person_name_defaults
        rbnf refs scripts scripts_l10n subdivisions
        subdivisions_l10n territories territories_l10n
        time_formats timezones timezones_cities
        timezones_cities_extended timezones_cities_supplemental
        timezones_formats timezones_info timezones_names
        unit_aliases unit_constants unit_conversions
        unit_prefixes unit_prefs unit_quantities units_l10n
        variants variants_l10n week_preferences
     )];
    is_deeply( \@tables, $expected, 'tables' );
};
my $vers = $cldr->cldr_version;
is( $vers, '46.0', 'CLDR version' );

my $tests =
{
    # NOTE: aliases
    aliases =>
    [
        {
            method  => 'alias',
            args    => [qw( alias i-klingon type language )],
            expect  => 
            {
                alias       => 'i-klingon',
                replacement => [qw( tlh )],
                reason      => 'deprecated',
                type        => 'language',
                comment     => 'Klingon',
            },
        },
        {
            method  => 'alias',
            args    => [qw( alias USA type territory )],
            expect  => 
            {
                alias       => 'USA',
                replacement => [qw( US )],
                reason      => 'overlong',
                type        => 'territory',
                comment     => 'United States',
            },
        },
        {
            method  => 'alias',
            args    => [qw( alias heploc type variant )],
            expect  => 
            {
                alias       => 'heploc',
                replacement => [qw( alalc97 )],
                reason      => 'deprecated',
                type        => 'variant',
                comment     => 'heploc',
            },
        },
        {
            method  => 'alias',
            args    => [qw( alias Qaai type script )],
            expect  => 
            {
                alias       => 'Qaai',
                replacement => [qw( Zinh )],
                reason      => 'deprecated',
                type        => 'script',
                comment     => 'deprecated ISO territories in 3066 + CLDR ones (older deprecated ISO codes',
            },
        },
        {
            method  => 'aliases',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'aliases',
            args    => [qw( type language )],
            expect  => 'array',
        },
        {
            method  => 'aliases',
            args    => [qw( type script )],
            expect  => 'array',
        },
        {
            method  => 'aliases',
            args    => [qw( type subdivision )],
            expect  => 'array',
        },
        {
            method  => 'aliases',
            args    => [qw( type territory )],
            expect  => 'array',
        },
        {
            method  => 'aliases',
            args    => [qw( type variant )],
            expect  => 'array',
        },
        {
            method  => 'aliases',
            args    => [qw( type zone )],
            expect  => 'array',
        },
    ],
    # NOTE: annotations
    annotations =>
    [
        {
            method  => 'annotation',
            args    => [qw( locale en annotation { )],
            expect  =>
            {
                locale      => 'en',
                annotation  => '{',
                defaults    => ["brace", "bracket", "curly", "gullwing", "open"],
                tts         => 'open curly bracket',
            },
        },
        {
            method  => 'annotations',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'annotations',
            args    => [qw( locale en )],
            expect  => 'array',
        },
    ],
    # NOTE: bcp47_currencies
    bcp47_currencies =>
    [
        {
            method  => 'bcp47_currency',
            args    => [currid => 'jpy'],
            expect  =>
            {
                currid      => 'jpy',
                code        => 'JPY',
                description => 'Japanese Yen',
                is_obsolete => 0,
            },
        },
        {
            method  => 'bcp47_currencies',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'bcp47_currencies',
            args    => [code => 'JPY'],
            expect  => 'array',
        },
        {
            method  => 'bcp47_currencies',
            args    => [is_obsolete => 1],
            expect  => 'array',
        },
    ],
    # NOTE: bcp47_extensions
    bcp47_extensions =>
    [
        {
            method  => 'bcp47_extension',
            args    => [extension => 'ca'],
            expect  =>
            {
                category    => 'calendar',
                extension   => 'ca',
                alias       => 'calendar',
                value_type  => 'incremental',
                description => 'Calendar algorithm key',
            },
        },
        {
            method  => 'bcp47_extensions',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'bcp47_extensions',
            args    => [extension => 'ca'],
            expect  => 'array',
        },
        {
            method  => 'bcp47_extensions',
            args    => [deprecated => 0],
            expect  => 'array',
        },
    ],
    # NOTE: bcp47_timezones
    bcp47_timezones =>
    [
        {
            method  => 'bcp47_timezone',
            args    => [tzid => 'jptyo'],
            expect  =>
            {
                tzid        => 'jptyo',
                alias       => ["Asia/Tokyo", "Japan"],
                preferred   => undef,
                description => 'Tokyo, Japan',
                deprecated  => undef,
            },
        },
        {
            method  => 'bcp47_timezones',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'bcp47_timezones',
            args    => [deprecated => 0],
            expect  => 'array',
        },
    ],
    # NOTE: bcp47_values
    bcp47_values =>
    [
        {
            method  => 'bcp47_value',
            args    => [value => 'japanese'],
            expect  =>
            {
                category        => 'calendar',
                extension       => 'ca',
                value           => 'japanese',
                description     => 'Japanese Imperial calendar',
            },
        },
        {
            method  => 'bcp47_values',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'bcp47_values',
            args    => [category => 'calendar'],
            expect  => 'array',
        },
        {
            method  => 'bcp47_values',
            args    => [extension => 'ca'],
            expect  => 'array',
        },
    ],
    # NOTE: calendars
    calendars =>
    [
        {
            method  => 'calendar',
            args    => [calendar => 'gregorian'],
            expect  =>
            {
                calendar    => 'gregorian',
                system      => 'solar',
                inherits    => undef,
                description => undef,
            },
        },
        {
            method  => 'calendars',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'calendars',
            args    => [system => 'solar'],
            expect  => 'array',
        },
        {
            method  => 'calendars',
            args    => [inherits => 'gregorian'],
            expect  => 'array',
        },
    ],
    # NOTE: calendar_append_formats
    calendar_append_formats =>
    [
        {
            method  => 'calendar_append_format',
            args    => [qw( locale en calendar gregorian format_id Day )],
            expect  => 
            {
                locale          => 'en',
                calendar        => 'gregorian',
                format_id       => 'Day',
                format_pattern  => '{0} ({2}: {1})',
            },
        },
        {
            method  => 'calendar_append_formats',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'calendar_append_formats',
            args    => [locale => 'en'],
            expect  => 'array',
        },
        {
            method  => 'calendar_append_formats',
            args    => [calendar => 'gregorian'],
            expect  => 'array',
        },
        {
            method  => 'calendar_append_formats',
            args    => [locale => 'en', calendar => 'gregorian'],
            expect  => 'array',
        },
    ],
    # NOTE: calendar_available_formats
    calendar_available_formats =>
    [
        {
            method  => 'calendar_available_format',
            args    => [qw( locale en calendar gregorian format_id Hms )],
            expect  => 
            {
                locale              => 'en',
                calendar            => 'gregorian',
                format_id           => 'Hms',
                format_pattern      => 'HH:mm:ss',
                count               => undef,
                alt                 => undef,
            },
        },
        {
            method  => 'calendar_available_formats',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'calendar_available_formats',
            args    => [locale => 'en'],
            expect  => 'array',
        },
        {
            method  => 'calendar_available_formats',
            args    => [calendar => 'gregorian'],
            expect  => 'array',
        },
        {
            method  => 'calendar_available_formats',
            args    => [locale => 'en', calendar => 'gregorian'],
            expect  => 'array',
        },
    ],
    # NOTE: calendar_cyclics_l10n
    calendar_cyclics_l10n =>
    [
        {
            method  => 'calendar_cyclic_l10n',
            args    => [qw( locale und calendar chinese format_set dayParts format_type format format_length abbreviated format_id 1 )],
            expect  => 
            {
                locale          => 'und',
                calendar        => 'chinese',
                format_set      => 'dayParts',
                format_type     => 'format',
                format_length   => 'abbreviated',
                format_id       => 1,
                format_pattern  => 'zi',
            },
        },
        {
            method  => 'calendar_cyclics_l10n',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'calendar_cyclics_l10n',
            args    => [locale => 'en'],
            expect  => 'array',
        },
        {
            method  => 'calendar_cyclics_l10n',
            args    => [calendar => 'gregorian'],
            expect  => 'array',
        },
        {
            method  => 'calendar_cyclics_l10n',
            args    => [qw( locale en calendar chinese format_set dayParts format_length abbreviated )],
            expect  => 'array',
        },
    ],
    # NOTE: calendar_datetime_formats
    calendar_datetime_formats =>
    [
        {
            method  => 'calendar_datetime_format',
            args    => [qw( locale en calendar gregorian format_length full format_type atTime )],
            expect  => 
            {
                locale          => 'en',
                calendar        => 'gregorian',
                format_length   => 'full',
                format_type     => 'atTime',
                format_pattern  => "{1} 'at' {0}",
            },
        },
        {
            method  => 'calendar_datetime_formats',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'calendar_datetime_formats',
            args    => [locale => 'en'],
            expect  => 'array',
        },
        {
            method  => 'calendar_datetime_formats',
            args    => [calendar => 'gregorian'],
            expect  => 'array',
        },
        {
            method  => 'calendar_datetime_formats',
            args    => [locale => 'en', calendar => 'gregorian'],
            expect  => 'array',
        },
    ],
    # NOTE: calendar_eras_l10n
    calendar_eras_l10n =>
    [
        {
            method  => 'calendar_era_l10n',
            args    => [qw( locale ja calendar gregorian era_width abbreviated era_id 0 )],
            expect  => 
            {
                locale          => 'ja',
                calendar        => 'gregorian',
                era_width       => 'abbreviated',
                era_id          => 0,
                alt             => undef,
                locale_name     => '紀元前',
            },
        },
        {
            method  => 'calendar_eras_l10n',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'calendar_eras_l10n',
            args    => [locale => 'en'],
            expect  => 'array',
        },
        {
            method  => 'calendar_eras_l10n',
            args    => [calendar => 'gregorian'],
            expect  => 'array',
        },
        {
            method  => 'calendar_eras_l10n',
            args    => [locale => 'en', calendar => 'gregorian', era_width => 'abbreviated', alt => undef],
            expect  => 'array',
        },
    ],
    # NOTE: calendar_formats_l10n
    calendar_formats_l10n =>
    [
        {
            method  => 'calendar_format_l10n',
            args    => [qw( locale ja calendar gregorian format_type date format_length full format_id yMEEEEd )],
            expect  => 
            {
                locale          => 'ja',
                calendar        => 'gregorian',
                format_type     => 'date',
                format_length   => 'full',
                alt             => undef,
                format_id       => 'yMEEEEd',
                format_pattern  => 'y年M月d日EEEE',
            },
        },
        {
            method  => 'calendar_formats_l10n',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'calendar_formats_l10n',
            args    => [locale => 'en'],
            expect  => 'array',
        },
        {
            method  => 'calendar_formats_l10n',
            args    => [calendar => 'gregorian'],
            expect  => 'array',
        },
        {
            method  => 'calendar_formats_l10n',
            args    => [locale => 'en', calendar => 'gregorian', format_type => 'date', format_length => 'full'],
            expect  => 'array',
        },
    ],
    # NOTE: calendar_interval_formats
    calendar_interval_formats =>
    [
        {
            method  => 'calendar_interval_format',
            args    => [qw( locale en calendar gregorian greatest_diff_id d format_id GyMMMEd )],
            expect  => 
            {
                locale              => 'en',
                calendar            => 'gregorian',
                format_id           => 'GyMMMEd',
                greatest_diff_id    => 'd',
                format_pattern      => 'E, MMM d – E, MMM d, y G',
                alt                 => undef,
                part1               => 'E, MMM d',
                separator           => ' – ',
                part2               => 'E, MMM d, y G',
                repeating_field     => 'E, MMM d',
            },
        },
        {
            method  => 'calendar_interval_formats',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'calendar_interval_formats',
            args    => [locale => 'en'],
            expect  => 'array',
        },
        {
            method  => 'calendar_interval_formats',
            args    => [calendar => 'gregorian'],
            expect  => 'array',
        },
        {
            method  => 'calendar_interval_formats',
            args    => [locale => 'en', calendar => 'gregorian'],
            expect  => 'array',
        },
    ],
    # NOTE: calendars_l10n
    calendars_l10n =>
    [
        {
            method  => 'calendar_l10n',
            args    => [qw( locale en calendar japanese )],
            expect  => 
            {
                locale              => 'en',
                calendar            => 'japanese',
                locale_name         => 'Japanese Calendar',
            },
        },
        {
            method  => 'calendars_l10n',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'calendars_l10n',
            args    => [locale => 'en'],
            expect  => 'array',
        },
    ],
    # NOTE: calendar_terms
    calendar_terms =>
    [
        {
            method  => 'calendar_term',
            args    => [qw( locale und calendar gregorian term_context format term_width abbreviated term_name am )],
            expect  => 
            {
                locale          => 'und',
                calendar        => 'gregorian',
                term_type       => 'day_period',
                term_context    => 'format',
                term_width      => 'abbreviated',
                alt             => undef,
                yeartype        => undef,
                term_name       => 'am',
                term_value      => 'AM',
            },
        },
        {
            method  => 'calendar_term',
            args    => [qw( locale und calendar gregorian term_context format term_width abbreviated ), term_name => [qw( am pm )]],
            expect  => 'array',
        },
        {
            method  => 'calendar_terms',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'calendar_terms',
            args    => [locale => 'und', calendar => 'japanese'],
            expect  => 'array',
        },
        {
            method  => 'calendar_terms',
            args    => [locale => 'und', calendar => 'japanese', term_type => 'day', term_context => 'format', term_width => 'abbreviated'],
            expect  => 'array',
        },
    ],
    # NOTE: casings
    casings =>
    [
        {
            method  => 'casing',
            args    => [locale => 'fr', token => 'currencyName'],
            expect  =>
            {
                locale      => 'fr',
                token       => 'currencyName',
                value       => 'lowercase',
            },
        },
        {
            method  => 'casings',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'casings',
            args    => [locale => 'fr'],
            expect  => 'array',
        }
    ],
    # NOTE: code_mappings
    code_mappings =>
    [
        {
            method  => 'code_mapping',
            args    => [code => 'US'],
            expect  =>
            {
                code    => 'US',
                alpha3  => 'USA',
                numeric => 840,
                fips10  => undef,
                type    => 'territory',
            },
        },
        {
            method  => 'code_mappings',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'code_mappings',
            args    => [type => 'territory'],
            expect  => 'array',
        },
        {
            method  => 'code_mappings',
            args    => [type => 'currency'],
            expect  => 'array',
        },
        {
            method  => 'code_mappings',
            args    => [alpha3 => 'USA'],
            expect  => 'array',
        },
        {
            method  => 'code_mappings',
            args    => [numeric => 840],
            expect  => 'array',
        },
        {
            method  => 'code_mappings',
            args    => [fips => 'JP'],
            expect  => 'array',
        },
        {
            method  => 'code_mappings',
            args    => [fips => undef, type => 'currency'],
            expect  => 'array',
        }
    ],
    # NOTE: collations
    collations =>
    [
        {
            method  => 'collation',
            args    => [collation => 'ducet'],
            expect  => 
            {
                collation   => 'ducet',
                description => 'The default Unicode collation element table order',
            }
        },
        {
            method  => 'collations',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'collations',
            args    => [description => qr/Chinese/],
            expect  => 'array',
        },
    ],
    # NOTE: collations_l10n
    collations_l10n =>
    [
        {
            method  => 'collation_l10n',
            args    => [qw( locale en collation ducet )],
            expect  => 
            {
                locale      => 'en',
                collation   => 'ducet',
                locale_name => 'Default Unicode Sort Order',
            }
        },
        {
            method  => 'collations_l10n',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'collations_l10n',
            args    => [locale => 'en'],
            expect  => 'array',
        },
    ],
    # NOTE: currencies
    currencies =>
    [
        {
            method  => 'currency',
            args    => [currency => 'JPY'],
            expect  => 
            {
                currency        => 'JPY',
                digits          => 0,
                rounding        => 0,
                cash_digits     => undef,
                cash_rounding   => undef,
                is_obsolete     => 0,
                status          => 'regular',
            }
        },
        {
            method  => 'currencies',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'currencies',
            args    => [is_obsolete => 1],
            expect  => 'array',
        },
    ],
    # NOTE: currencies_info
    currencies_info =>
    [
        {
            method  => 'currency_info',
            args    => [qw( currency EUR territory FR )],
            expect  => 
            {
                territory           => 'FR',
                currency            => 'EUR',
                start               => '1999-01-01',
                until               => undef,
                is_tender           => 0,
                hist_sequence       => 1,
                is_obsolete         => 0,
            },
        },
        {
            method  => 'currencies_info',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'currencies_info',
            args    => [territory => 'FR'],
            expect  => 'array',
        },
        {
            method  => 'currencies_info',
            args    => [currency => 'EUR'],
            expect  => 'array',
        },
    ],
    # NOTE: currencies_l10n
    currencies_l10n =>
    [
        {
            method  => 'currency_l10n',
            args    => [qw( locale en currency JPY )],
            expect  => 
            {
                locale          => 'en',
                currency        => 'JPY',
                count           => undef,
                locale_name     => 'Japanese Yen',
                symbol          => '¥',
            },
        },
        {
            method  => 'currencies_l10n',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'currencies_l10n',
            args    => [locale => 'en'],
            expect  => 'array',
        },
        {
            method  => 'currencies_l10n',
            args    => [locale => 'en', currency => 'JPY'],
            expect  => 'array',
        },
    ],
    # NOTE: date_fields_l10n
    date_fields_l10n =>
    [
        {
            method  => 'date_field_l10n',
            args    => [qw( locale en field_type day field_length narrow relative -1 )],
            expect  =>
            {
                locale          => 'en',
                field_type      => 'day',
                field_length    => 'narrow',
                relative        => -1,
                locale_name     => 'yesterday',
            }
        },
        {
            method  => 'date_fields_l10n',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'date_fields_l10n',
            args    => [locale => 'en'],
            expect  => 'array',
        },
        {
            method  => 'date_fields_l10n',
            args    => [locale => 'en', field_type => 'day', field_length => 'narrow'],
            expect  => 'array',
        },
    ],
    # NOTE: day_periods
    day_periods =>
    [
        {
            method  => 'day_period',
            args    => [locale => 'fr', day_period => 'noon'],
            expect  =>
            {
                locale          => 'fr',
                day_period      => 'noon',
                start           => '12:00',
                until           => '12:00',
            }
        },
        {
            method  => 'day_periods',
            args    => [],
            expect  => 'array',
        },
        {
            method  => 'day_periods',
            args    => [locale => 'ja'],
            expect  => 'array',
        },
        {
            method  => 'day_periods',
            args    => [day_period => 'noon'],
            expect  => 'array',
        },
    ],
    # NOTE: l10n
    l10n =>
    [
        {
            method  => 'l10n',
            args    => 
            [
                type        => 'annotation',
                locale      => 'en',
                annotation  => '{',
            ],
            expect =>
            [{
                locale      => 'en',
                annotation  => '{',
                defaults    => ["brace", "bracket", "curly brace", "curly bracket", "gullwing", "open curly bracket"],
                tts         => 'open curly bracket',
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type        => 'calendar_append_format',
                locale      => 'en',
                calendar    => 'gregorian',
                format_id   => 'Day',
            ],
            expect =>
            [{
                locale          => 'en',
                calendar        => 'gregorian',
                format_id       => 'Day',
                format_pattern  => '{0} ({2}: {1})',
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type        => 'calendar_available_format',
                locale      => 'ja',
                calendar    => 'japanese',
                format_id   => 'GyMMMEEEEd',
            ],
            expect =>
            [{
                locale          => 'ja',
                calendar        => 'japanese',
                format_id       => 'GyMMMEEEEd',
                format_pattern  => 'Gy年M月d日EEEE',
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type        => 'calendar_cyclic',
                locale      => 'ja',
                calendar    => 'chinese',
                format_set  => 'dayParts',
                format_id   => 1,
            ],
            expect =>
            [{
                locale          => 'ja',
                calendar        => 'chinese',
                format_set      => 'dayParts',
                format_type     => 'format',
                format_length   => 'abbreviated',
                format_id       => '1',
                format_pattern  => '子',
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type        => 'calendar_era',
                locale      => 'ja',
                calendar    => 'japanese',
                era_width   => 'abbreviated',
                era_id      => 236,
            ],
            expect =>
            [{
                locale          => 'ja',
                calendar        => 'japanese',
                era_width       => 'abbreviated',
                era_id          => 236,
                alt             => undef,
                locale_name     => '令和',
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type        => 'calendar_format',
                locale      => 'ja',
                calendar    => 'gregorian',
                format_id   => 'yMEEEEd',
            ],
            expect =>
            [{
                locale          => 'ja',
                calendar        => 'gregorian',
                format_type     => 'date',
                format_length   => 'full',
                alt             => undef,
                format_id       => 'yMEEEEd',
                format_pattern  => 'y年M月d日EEEE',
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type                => 'calendar_interval_format',
                locale              => 'ja',
                calendar            => 'gregorian',
                format_id           => 'yMMM',
            ],
            expect =>
            [{
                locale              => 'ja',
                calendar            => 'gregorian',
                format_id           => 'yMMM',
                format_pattern      => 'y年M月～M月',
                alt                 => undef,
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type                => 'calendar_term',
                locale              => 'ja',
                calendar            => 'gregorian',
                term_name           => 'mon',
            ],
            expect =>
            [{
                locale              => 'ja',
                calendar            => 'gregorian',
                term_type           => 'day',
                term_context        => 'format',
                term_width          => 'abbreviated',
                alt                 => undef,
                yeartype            => undef,
                term_name           => 'mon',
                term_value          => '月',
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type                => 'casing',
                locale              => 'fr',
                token               => 'currencyName',
            ],
            expect =>
            [{
                locale              => 'fr',
                token               => 'currencyName',
                value               => 'lowercase',
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type                => 'currency',
                locale              => 'ja',
                currency            => 'EUR',
            ],
            expect =>
            [{
                locale              => 'ja',
                currency            => 'EUR',
                count               => undef,
                locale_name         => 'ユーロ',
                symbol              => undef,
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type                => 'date_field',
                locale              => 'ja',
                field_type          => 'day',
                relative            => 1,
            ],
            expect =>
            [{
                locale              => 'ja',
                field_type          => 'day',
                field_length        => 'standard',
                relative            => 1,
                locale_name         => '明日',
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type                => 'locale',
                locale              => 'ja',
                locale_id           => 'fr',
            ],
            expect =>
            [{
                locale              => 'ja',
                locale_id           => 'fr',
                locale_name         => 'フランス語',
                alt                 => undef,
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type                => 'number_format',
                locale              => 'ja',
                number_type         => 'currency',
                format_id           => '10000',
            ],
            expect =>
            [{
                locale              => 'ja',
                number_system       => 'latn',
                number_type         => 'currency',
                format_length       => 'short',
                format_type         => 'standard',
                format_id           => '10000',
                format_pattern      => '¤0万',
                alt                 => undef,
                count               => 'other',
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type                => 'number_symbol',
                locale              => 'en',
                number_system       => 'latn',
                property            => 'decimal',
            ],
            expect =>
            [{
                locale              => 'en',
                number_system       => 'latn',
                property            => 'decimal',
                value               => '.',
                alt                 => undef,
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type                => 'script',
                locale              => 'ja',
                script              => 'Kore',
            ],
            expect =>
            [{
                locale              => 'ja',
                script              => 'Kore',
                locale_name         => '韓国語の文字',
                alt                 => undef,
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type                => 'subdivision',
                locale              => 'en',
                subdivision         => 'jp13',
            ],
            expect =>
            [{
                locale              => 'en',
                subdivision         => 'jp13',
                locale_name         => 'Tokyo',
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type                => 'territory',
                locale              => 'en',
                territory           => 'JP',
            ],
            expect =>
            [{
                locale              => 'en',
                territory           => 'JP',
                locale_name         => 'Japan',
                alt                 => undef,
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type                => 'unit',
                locale              => 'en',
                unit_id             => 'power3',
            ],
            expect =>
            [{
                locale              => 'en',
                format_length       => 'long',
                unit_type           => 'compound',
                unit_id             => 'power3',
                unit_pattern        => 'cubic {0}',
                pattern_type        => 'regular',
                locale_name         => undef,
                count               => undef,
                gender              => undef,
                gram_case           => undef,
            }],
        },
        {
            method  => 'l10n',
            args    => 
            [
                type                => 'variant',
                locale              => 'en',
                variant             => 'valencia',
            ],
            expect =>
            [{
                locale              => 'en',
                variant             => 'valencia',
                locale_name         => 'Valencian',
                alt                 => undef,
            }],
        },
    ],
    # NOTE: languages
    languages =>
    [
        {
            method      => 'language',
            args        => [language => 'ryu'],
            expect      =>
            {
                language    => 'ryu',
                scripts     => ["Kana"],
                territories => ["JP"],
                # This is highly doubtful, and is now part of an issue submitted to Unicode
                # It should just be undef, as it was in version 45.0
                # <https://unicode-org.atlassian.net/browse/CLDR-18095>
                parent      => 'tut',
                alt         => undef,
                status      => 'regular',
            },
        },
        {
            method      => 'languages',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'languages',
            args        => [parent => 'gmw'],
            expect      => 'array',
        },
    ],
    # NOTE: language_populations
    language_populations =>
    [
        {
            method      => 'language_population',
            args        => [territory => 'JP'],
            expect      =>
            [
                {
                    territory           => 'JP',
                    locale              => 'ja',
                    population_percent  => 95,
                    literacy_percent    => undef,
                    writing_percent     => undef,
                    official_status     => 'official',
                },
                {
                    territory           => 'JP',
                    locale              => 'ryu',
                    population_percent  => 0.77,
                    literacy_percent    => undef,
                    writing_percent     => 5,
                    official_status     => undef,
                },
                {
                    territory           => 'JP',
                    locale              => 'ko',
                    population_percent  => 0.52,
                    literacy_percent    => undef,
                    writing_percent     => undef,
                    official_status     => undef,
                },
            ],
        },
        {
            method      => 'language_populations',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'language_populations',
            args        => [official_status => 'official'],
            expect      => 'array',
        },
    ],
    # NOTE: likely_subtags
    likely_subtags =>
    [
        {
            method      => 'likely_subtag',
            args        => [locale => 'ja'],
            expect      =>
            {
                locale  => 'ja',
                target  => 'ja-Jpan-JP',
            },
        },
        {
            method      => 'likely_subtags',
            args        => [],
            expect      => 'array',
        },
    ],
    # NOTE: locales
    locales =>
    [
        {
            method      => 'locale',
            args        => [locale => 'ja'],
            expect      =>
            {
                locale  => 'ja',
                status  => 'regular',
            },
        },
        {
            method      => 'locales',
            args        => [],
            expect      => 'array',
        },
    ],
    # NOTE: locales_l10n
    locales_l10n =>
    [
        {
            method      => 'locale_l10n',
            args        => [qw( locale en locale_id ja )],
            expect      =>
            {
                locale          => 'en',
                locale_id       => 'ja',
                locale_name     => 'Japanese',
                alt             => undef,
            },
        },
        {
            method      => 'locales_l10n',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'locales_l10n',
            args        => [locale => 'en'],
            expect      => 'array',
        },
        {
            method      => 'locales_l10n',
            args        => [locale_id => 'ja'],
            expect      => 'array',
        },
        {
            method      => 'locales_l10n',
            args        => [locale => 'en', locale_id => 'ja', alt => undef],
            expect      => 'array',
        },
    ],
    # NOTE: locales_infos
    locales_infos =>
    [
        {
            method      => 'locales_info',
            args        => [property => 'quotation_start', locale => 'ja'],
            expect      =>
            {
                locale      => 'ja',
                property    => 'quotation_start',
                value       => '「',
            },
        },
        {
            method      => 'locales_infos',
            args        => [],
            expect      => 'array',
        },
    ],
    # NOTE: metazones
    metazones =>
    [
        {
            method      => 'metazone',
            args        => [metazone => 'Japan'],
            expect      =>
            {
                metazone    => 'Japan',
                territories => ["001"],
                timezones   => ["Asia/Tokyo"],
            },
        },
        {
            method      => 'metazones',
            args        => [],
            expect      => 'array',
        },
    ],
    # NOTE: metazone_names
    metazones_names =>
    [
        {
            method      => 'metazone_names',
            args        => [metazone => 'Japan', locale => 'en', width => 'long'],
            expect      =>
            {
                locale      => 'en',
                metazone    => 'Japan',
                width       => 'long',
                generic     => 'Japan Time',
                standard    => 'Japan Standard Time',
                daylight    => 'Japan Daylight Time',
            },
        },
        {
            method      => 'metazones_names',
            args        => [],
            expect      => 'array',
        },
    ],
    # NOTE: number_formats_l10n
    number_formats_l10n =>
    [
        {
            method      => 'number_format_l10n',
            args        => [qw( locale en number_system latn number_type currency format_length short format_type standard count one format_id 1000 )],
            expect      =>
            {
                locale              => 'en',
                number_system       => 'latn',
                number_type         => 'currency',
                format_length       => 'short',
                format_type         => 'standard',
                format_id           => 1000,
                format_pattern      => '¤0K',
                alt                 => undef,
                count               => 'one',
            },
        },
        {
            method      => 'number_formats_l10n',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'number_formats_l10n',
            args        => [locale => 'en'],
            expect      => 'array',
        },
        {
            method      => 'number_formats_l10n',
            args        => [locale => 'en', number_system => 'latn', number_type => 'currency', format_length => 'short', format_type => 'standard'],
            expect      => 'array',
        },
    ],
    # NOTE: number_systems
    number_symbols_l10n =>
    [
        {
            method      => 'number_symbol_l10n',
            args        => [qw( locale en number_system latn property decimal )],
            expect      =>
            {
                locale              => 'en',
                number_system       => 'latn',
                property            => 'decimal',
                value               => '.',
                alt                 => undef,
            },
        },
        {
            method      => 'number_symbols_l10n',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'number_symbols_l10n',
            args        => [locale => 'en'],
            expect      => 'array',
        },
        {
            method      => 'number_symbols_l10n',
            args        => [locale => 'en', number_system => 'latn'],
            expect      => 'array',
        },
    ],
    # NOTE: number_systems
    number_systems =>
    [
        {
            method      => 'number_system',
            args        => [number_system => 'jpan'],
            expect      =>
            {
                number_system   => 'jpan',
                digits          => ["〇", "一", "二", "三", "四", "五", "六", "七", "八", "九"],
                type            => 'algorithmic',
            },
        },
        {
            method      => 'number_systems',
            args        => [],
            expect      => 'array',
        },
    ],
    # NOTE: number_systems_l10n
    number_systems_l10n =>
    [
        {
            method      => 'number_system_l10n',
            args        => [qw( number_system jpan locale en )],
            expect      =>
            {
                locale          => 'en',
                number_system   => 'jpan',
                locale_name     => 'Japanese Numerals',
                alt             => undef,
            },
        },
        {
            method      => 'number_systems_l10n',
            args        => [],
            expect      => 'array',
        },
    ],
    # NOTE: person_name_defaults
    person_name_defaults =>
    [
        {
            method      => 'person_name_default',
            args        => [locale => 'ja'],
            expect      =>
            {
                locale  => 'ja',
                value   => 'surnameFirst',
            },
        },
        {
            method      => 'person_name_defaults',
            args        => [],
            expect      => 'array',
        },
    ],
    # NOTE: rbnfs
    rbnfs =>
    [
        {
            method      => 'rbnf',
            args        => [locale => 'ja', ruleset => 'spellout-cardinal', rule_id => 7],
            expect      =>
            {
                locale      => 'ja',
                grouping    => 'SpelloutRules',
                ruleset     => 'spellout-cardinal',
                rule_id     => '7',
                rule_value  => '七;',
            },
        },
        {
            method      => 'rbnfs',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'rbnfs',
            args        => [locale => 'ko'],
            expect      => 'array',
        },
        {
            method      => 'rbnfs',
            args        => [grouping => 'SpelloutRules'],
            expect      => 'array',
        },
        {
            method      => 'rbnfs',
            args        => [ruleset => 'spellout-cardinal-native'],
            expect      => 'array',
        },
    ],
    # NOTE: references
    references =>
    [
        {
            method      => 'reference',
            args        => [code => 'R1131'],
            expect      =>
            {
                code    => 'R1131',
                uri     => 'http://en.wikipedia.org/wiki/Singapore',
                description => 'English is the first language learned by half the children by the time they reach preschool age; using 92.6% of pop for the English figure',
            },
        },
        {
            method      => 'references',
            args        => [],
            expect      => 'array',
        },
    ],
    # NOTE: scripts
    scripts =>
    [
        {
            method      => 'script',
            args        => [script => 'Jpan'],
            expect      =>
            {
                script          => 'Jpan',
                rank            => 5,
                sample_char     => '304B',
                id_usage        => 'RECOMMENDED',
                rtl             => 0,
                lb_letters      => 1,
                has_case        => 0,
                shaping_req     => 0,
                ime             => 1,
                density         => 2,
                origin_country  => 'JP',
                likely_language => 'ja',
                status          => 'regular',
            },
        },
        {
            method      => 'scripts',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'scripts',
            args        => [rtl => 1],
            expect      => 'array',
        },
        {
            method      => 'scripts',
            args        => [origin_country => 'FR'],
            expect      => 'array',
        },
        {
            method      => 'scripts',
            args        => [likely_language => 'fr'],
            expect      => 'array',
        },
    ],
    # NOTE: scripts_l10n
    scripts_l10n =>
    [
        {
            method      => 'script_l10n',
            args        => [qw( locale en script Latn )],
            expect      =>
            {
                locale          => 'en',
                script          => 'Latn',
                locale_name     => 'Latin',
                alt             => undef,
            },
        },
        {
            method      => 'scripts_l10n',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'scripts_l10n',
            args        => [locale => 'en'],
            expect      => 'array',
        },
        {
            method      => 'scripts_l10n',
            args        => [locale => 'en', alt => undef],
            expect      => 'array',
        },
    ],
    # NOTE: subdivisions
    subdivisions =>
    [
        {
            method      => 'subdivision',
            args        => [subdivision => 'jp12'],
            expect      =>
            {
                territory       => 'JP',
                subdivision     => 'jp12',
                parent          => 'JP',
                is_top_level    => 1,
                status          => 'regular',
            },
        },
        {
            method      => 'subdivisions',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'subdivisions',
            args        => [territory => 'JP'],
            expect      => 'array',
        },
        {
            method      => 'subdivisions',
            args        => [parent => 'US'],
            expect      => 'array',
        },
        {
            method      => 'subdivisions',
            args        => [is_top_level => 1],
            expect      => 'array',
        },
    ],
    # NOTE: subdivisions_l10n
    subdivisions_l10n =>
    [
        {
            method      => 'subdivision_l10n',
            args        => [qw( locale en subdivision ustx )],
            expect      =>
            {
                locale          => 'en',
                subdivision     => 'ustx',
                locale_name     => 'Texas',
            },
        },
        {
            method      => 'subdivisions_l10n',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'subdivisions_l10n',
            args        => [locale => 'en'],
            expect      => 'array',
        },
    ],
    # NOTE: territories
    territories =>
    [
        {
            method      => 'territory',
            args        => [territory => 'FR'],
            expect      =>
            {
                territory           => 'FR',
                parent              => 155,
                gdp                 => 3764000000000,
                literacy_percent    => 99,
                population          => 68374600,
                languages           => ["fr","en","es","de","oc","it","pt","pcd","gsw","br","co","hnj","ca","nl","eu","frp","ia"],
                contains            => undef,
                currency            => 'EUR',
                calendars           => undef,
                min_days            => 4,
                first_day           => 1,
                weekend             => undef,
                status              => 'regular',
            },
        },
        {
            method      => 'territories',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'territories',
            args        => [parent => 150],
            expect      => 'array',
        },
    ],
    # NOTE: territories_l10n
    territories_l10n =>
    [
        {
            method      => 'territory_l10n',
            args        => [qw( locale en territory JP )],
            expect      =>
            {
                locale          => 'en',
                territory       => 'JP',
                locale_name     => 'Japan',
                alt             => undef,
            },
        },
        {
            method      => 'territories_l10n',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'territories_l10n',
            args        => [locale => 'en'],
            expect      => 'array',
        },
        {
            method      => 'territories_l10n',
            args        => [locale => 'en', alt => undef],
            expect      => 'array',
        },
    ],
    # NOTE: time_formats
    time_formats =>
    [
        {
            method      => 'time_format',
            args        => [region => 'JP'],
            expect      =>
            {
                region          => 'JP',
                territory       => 'JP',
                locale          => undef,
                time_format     => 'H',
                time_allowed    =>  ["H", "K", "h"],
            },
        },
        {
            method      => 'time_formats',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'time_formats',
            args        => [region => 'US'],
            expect      => 'array',
        },
        {
            method      => 'time_formats',
            args        => [territory => 'JP'],
            expect      => 'array',
        },
        {
            method      => 'time_formats',
            args        => [locale => undef],
            expect      => 'array',
        },
        {
            method      => 'time_formats',
            args        => [locale => 'en'],
            expect      => 'array',
        },
    ],
    # NOTE: timezones
    timezones =>
    [
        {
            method      => 'timezone',
            args        => [timezone => 'Asia/Tokyo'],
            expect      =>
            {
                region          => 'JP',
                timezone        => 'Asia/Tokyo',
                territory       => 'JP',
                region          => 'Asia',
                tzid            => 'japa',
                metazone        => 'Japan',
                tz_bcpid        => 'jptyo',
                is_golden       => 1,
                is_preferred    => 0,
                alias           => ["Japan"],
            },
        },
        {
            method      => 'timezones',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'timezones',
            args        => [territory => 'JP'],
            expect      => 'array',
        },
        {
            method      => 'timezones',
            args        => [region => 'Asia'],
            expect      => 'array',
        },
        {
            method      => 'timezones',
            args        => [tzid => 'japa'],
            expect      => 'array',
        },
        {
            method      => 'timezones',
            args        => [tz_bcpid => 'jptyo'],
            expect      => 'array',
        },
        {
            method      => 'timezones',
            args        => [metazone => 'Japan'],
            expect      => 'array',
        },
        {
            method      => 'timezones',
            args        => [is_golden => 1],
            expect      => 'array',
        },
    ],
    # NOTE: timezones_l10n
    timezones_cities =>
    [
        {
            method      => 'timezone_city',
            args        => [timezone => 'Etc/Unknown', locale => 'en'],
            expect      =>
            {
                locale      => 'en',
                timezone    => 'Etc/Unknown',
                city        => 'Unknown City',
            },
        },
        {
                method      => 'timezones_cities',
            args        => [],
            expect      => 'array',
        },
    ],
    # NOTE: timezones_formats
    timezones_formats =>
    [
        {
            method      => 'timezone_formats',
            args        => [locale => 'en', type => 'fallback'],
            expect      =>
            {
                locale          => 'en',
                type            => 'fallback',
                subtype         => undef,
                format_pattern  => '{1} ({0})',
            },
        },
        {
            method      => 'timezone_formats',
            args        => [locale => 'en', type => 'gmt'],
            expect      =>
            {
                locale          => 'en',
                type            => 'gmt',
                subtype         => undef,
                format_pattern  => 'GMT{0}',
            },
        },
        {
            method      => 'timezone_formats',
            args        => [locale => 'en', type => 'gmt_zero'],
            expect      => '',
        },
        {
            method      => 'timezone_formats',
            args        => [locale => 'en', type => 'hour'],
            expect      =>
            {
                locale          => 'en',
                type            => 'hour',
                subtype         => undef,
                format_pattern  => '+HH:mm;-HH:mm',
            },
        },
        {
            method      => 'timezone_formats',
            args        => [locale => 'en', type => 'region'],
            expect      =>
            {
                locale          => 'en',
                type            => 'region',
                subtype         => undef,
                format_pattern  => '{0} Time',
            },
        },
        {
            method      => 'timezone_formats',
            args        => [locale => 'en', type => 'region', subtype => 'daylight'],
            expect      =>
            {
                locale          => 'en',
                type            => 'region',
                subtype         => 'daylight',
                format_pattern  => '{0} Daylight Time',
            },
        },
        {
            method      => 'timezone_formats',
            args        => [locale => 'en', type => 'region', subtype => 'standard'],
            expect      =>
            {
                locale          => 'en',
                type            => 'region',
                subtype         => 'standard',
                format_pattern  => '{0} Standard Time',
            },
        },
        {
            method      => 'timezones_formats',
            args        => [],
            expect      => 'array',
        },
    ],
    # NOTE: timezones_info
    timezones_info =>
    [
        {
            method      => 'timezone_info',
            args        => [qw( timezone Europe/Simferopol start 1994-04-30T21:00:00 )],
            expect      => 
            {
                timezone    => 'Europe/Simferopol',
                metazone    => 'Moscow',
                start       => '1994-04-30T21:00:00',
                'until'     => '1997-03-30T01:00:00'
            },
        },
        {
            method      => 'timezone_info',
            args        => [timezone => 'Europe/Simferopol', start => ['>1992-01-01', '<1995-01-01']],
            expect      => 
            {
                timezone    => 'Europe/Simferopol',
                metazone    => 'Moscow',
                start       => '1994-04-30T21:00:00',
                'until'     => '1997-03-30T01:00:00'
            },
        },
        {
            method      => 'timezones_info',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'timezones_info',
            args        => [timezone => 'Europe/Simferopol'],
            expect      => 'array',
        },
        {
            method      => 'timezones_info',
            args        => [metazone => 'Singapore'],
            expect      => 'array',
        },
        {
            method      => 'timezones_info',
            args        => [start => undef],
            expect      => 'array',
        },
        {
            method      => 'timezones_info',
            args        => ['until' => undef],
            expect      => 'array',
        },
    ],
    # NOTE: timezones_names
    timezones_names =>
    [
        {
            method      => 'timezone_names',
            args        => [timezone => 'Europe/London', locale => 'en', width => 'long'],
            expect      =>
            {
                locale      => 'en',
                timezone    => 'Europe/London',
                width       => 'long',
                generic     => undef,
                standard    => undef,
                daylight    => 'British Summer Time',
            },
        },
        {
            method      => 'timezones_names',
            args        => [],
            expect      => 'array',
        },
    ],
    # NOTE: unit_aliases
    unit_aliases =>
    [
        {
            method      => 'unit_alias',
            args        => [alias => 'meter-per-second-squared'],
            expect      =>
            {
                alias   => 'meter-per-second-squared',
                target  => 'meter-per-square-second',
                reason  => 'deprecated',
            },
        },
        {
            method      => 'unit_alias',
            args        => [alias => '~^meter.*'],
            expect      =>
            {
                alias   => 'meter-per-second-squared',
                target  => 'meter-per-square-second',
                reason  => 'deprecated',
            },
        },
        {
            method      => 'unit_aliases',
            args        => [],
            expect      => 'array',
        },
    ],
    # NOTE: unit_constants
    unit_constants =>
    [
        {
            method      => 'unit_constant',
            args        => [constant => 'lb_to_kg'],
            expect      =>
            {
                constant        => 'lb_to_kg',
                expression      => 0.45359237,
                value           => 0.45359237,
                description     => undef,
                status          => undef,
            },
        },
        {
            method      => 'unit_constants',
            args        => [],
            expect      => 'array',
        },
    ],
    # NOTE: unit_conversions
    unit_conversions =>
    [
        {
            method      => 'unit_conversion',
            args        => [source => 'kilogram'],
            expect      =>
            {
                source      => 'kilogram',
                base_unit   => 'kilogram',
                expression  => undef,
                factor      => undef,
                systems     => ["si", "metric"],
                category    => 'mass',
            },
        },
        {
            method      => 'unit_conversions',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'unit_conversions',
            args        => [base_unit => 'kilogram'],
            expect      => 'array',
        },
        {
            method      => 'unit_conversions',
            args        => [category => 'mass'],
            expect      => 'array',
        },
    ],
    # NOTE: units_l10n
    units_l10n =>
    [
        {
            method      => 'unit_l10n',
            args        => [qw( unit_id length-kilometer locale en format_length long unit_type regular count one )],
            expect      =>
            {
                locale          => 'en',
                format_length   => 'long',
                unit_type       => 'regular',
                unit_id         => 'length-kilometer',
                unit_pattern    => '{0} kilometer',
                pattern_type    => 'regular',
                locale_name     => 'kilometers',
                count           => 'one',
                gender          => undef,
                gram_case       => undef,
            },
        },
        {
            method      => 'units_l10n',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'units_l10n',
            args        => [locale => 'en'],
            expect      => 'array',
        },
        {
            method      => 'units_l10n',
            args        => [locale => 'en', format_length => 'long', unit_type => 'regular', unit_id => 'length-kilometer', pattern_type => 'regular'],
            expect      => 'array',
        },
    ],
    # NOTE: unit_prefixes
    unit_prefixes =>
    [
        {
            method      => 'unit_prefix',
            args        => [unit_id => 'micro'],
            expect      =>
            {
                unit_id => 'micro',
                symbol  => 'μ',
                power   => 10,
                factor  => -6,
            },
        },
        {
            method      => 'unit_prefixes',
            args        => [],
            expect      => 'array',
        },
    ],
    # NOTE: unit_prefs
    unit_prefs =>
    [
        {
            method      => 'unit_pref',
            args        => [unit_id => 'square-meter'],
            expect      =>
            {
                unit_id         => 'square-meter',
                territory       => '001',
                category        => 'area',
                usage           => 'default',
                geq             => undef,
                skeleton        => undef,
            },
        },
        {
            method      => 'unit_prefs',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'unit_prefs',
            args        => [territory => 'US'],
            expect      => 'array',
        },
        {
            method      => 'unit_prefs',
            args        => [category => 'area'],
            expect      => 'array',
        },
    ],
    # NOTE: unit_quantities
    unit_quantities =>
    [
        {
            method      => 'unit_quantity',
            args        => [base_unit => 'kilogram'],
            expect      =>
            {
                base_unit   => 'kilogram',
                quantity    => 'mass',
                status      => 'simple',
                comment     => undef,
            },
        },
        {
            method      => 'unit_quantities',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'unit_quantities',
            args        => [quantity => 'mass'],
            expect      => 'array',
        },
    ],
    # NOTE: variants
    variants =>
    [
        {
            method      => 'variant',
            args        => [variant => 'valencia'],
            expect      =>
            {
                variant     => 'valencia',
                status      => 'regular',
            },
        },
        {
            method      => 'variants',
            args        => [],
            expect      => 'array',
        },
    ],
    # NOTE: variants_l10n
    variants_l10n =>
    [
        {
            method      => 'variant_l10n',
            args        => [qw( variant valencia locale en )],
            expect      =>
            {
                locale      => 'en',
                variant     => 'valencia',
                locale_name => 'Valencian',
                alt         => undef,
            },
        },
        {
            method      => 'variants_l10n',
            args        => [],
            expect      => 'array',
        },
        {
            method      => 'variants_l10n',
            args        => [locale => 'en'],
            expect      => 'array',
        },
    ],
    # NOTE: week_preferences
    week_preferences =>
    [
        {
            method      => 'week_preference',
            args        => [qw( locale ja )],
            expect      => 
            {
                locale      => 'ja',
                ordering    => ["weekOfDate", "weekOfMonth"],
            },
        },
        {
            method      => 'week_preferences',
            args        => [],
            expect      => 'array',
        },
    ],
};

# NOTE: core tests
foreach my $test_name ( sort( keys( %$tests ) ) )
{
    # Taking a cue at how perl itself handled this issue:
    # <https://github.com/Perl/perl5/issues/17134>
    # <https://github.com/Perl/perl5/issues/17853>
    if( exists( $Config{uselongdouble} ) && 
        ( $Config{uselongdouble} || !defined( $Config{uselongdouble} ) ) && 
        ( $test_name eq 'language_populations' || $test_name eq 'unit_constants' ) )
    {
        pass( "Skipping test ${test_name} under $^O due to perl compilation with 'uselongdouble'" );
        next;
    }

    subtest $test_name => sub
    {
        my $test_data = $tests->{ $test_name };
        foreach my $def ( @$test_data )
        {
            foreach my $param ( qw( method args expect ) )
            {
                if( !exists( $def->{ $param } ) )
                {
                    die( "Missing parameter \"${param}\" in test configuration for \"${test_name}\"." );
                }
            }

            SKIP:
            {
                can_ok( $cldr, $def->{method} );
                my $code = $cldr->can( $def->{method} );
                if( !$code )
                {
                    skip( "Unsupported method \"$def->{method}\" in Locale::Unicode::Data", 1 );
                }
                my $rv = $code->( $cldr, @{$def->{args}} );
                ok( ( defined( $rv ) || ( !defined( $rv ) && !$cldr->error ) ), "Calling $def->{method} with " . ( scalar( @{$def->{args}} ) ? "arguments '" . join( "', '", map( $_ // 'undef', @{$def->{args}} ) ) . "'" : 'no argument' ) );
                if( !defined( $rv ) && $cldr->error )
                {
                    diag( "Error occurred calling $def->{method}: ", $cldr->error );
                    skip( "Error with $def->{method}", 1 );
                }
                my $expect = $def->{expect};
                if( ref( $expect ) eq 'HASH' )
                {
                    is( ref( $rv ) => 'HASH', "$def->{method}() -> \$rv is an hash" );
                    if( ref( $rv ) ne 'HASH' )
                    {
                        skip( "Data returned by $def->{method} is not an hash reference.", 1 );
                    }
                    foreach my $prop ( sort( keys( %$expect ) ) )
                    {
                        ok( exists( $rv->{ $prop } ), "$def->{method}() -> \$rv->{ ${prop} } exists." );
                        if( !exists( $rv->{ $prop } ) )
                        {
                            next;
                        }
                        # Array
                        if( ref( $expect->{ $prop } ) )
                        {
                            is( ref( $rv->{ $prop } ) => ref( $expect->{ $prop } ), "Value for $def->{method}() -> \$rv->{ ${prop} } is an " . lc( ref( $expect->{ $prop } ) ) . " reference." );
                            if( ref( $rv->{ $prop } ) )
                            {
                                is_deeply( $rv->{ $prop }, $expect->{ $prop }, "Content for $def->{method}() -> \$rv->{ ${prop} } matches" );
                            }
                        }
                        else
                        {
                            is( $rv->{ $prop } => $expect->{ $prop }, "Value for $def->{method}() -> \$rv->{ ${prop} } matches" );
                        }
                    }
                }
                elsif( ref( $expect ) eq 'ARRAY' )
                {
                    is( ref( $rv ) => 'ARRAY', "$def->{method} is expected to return an array" );
                    if( ref( $rv ) ne 'ARRAY' )
                    {
                        skip( "Data returned by $def->{method} is ", ref( $rv ), ", but I was expecting an array.", 1 );
                    }
                    for( my $i = 0; $i < scalar( @$expect ); $i++ )
                    {
                        if( $expect->[$i] )
                        {
                            if( ref( $expect->[$i] ) ne 'HASH' )
                            {
                                BAIL_OUT( "Misconfiguration for test ${test_name} for method $def->{method}. I was expecting an hash reference inside this array reference, but instead I got ", ref( $expect->[$i] ) );
                            }
                            is( ref( $rv->[$i] ) => 'HASH', "$def->{method}() -> \$rv->[$i] is an hash" );
                            if( ref( $rv->[$i] ) ne 'HASH' )
                            {
                                skip( "Data returned by $def->{method} at offset $i is not an hash reference.", 1 );
                            }
                            foreach my $prop ( sort( keys( %{$expect->[$i]} ) ) )
                            {
                                ok( exists( $rv->[$i]->{ $prop } ), "$def->{method}() -> \$rv->[$i]->{ ${prop} } exists." );
                                if( !exists( $rv->[$i]->{ $prop } ) )
                                {
                                    next;
                                }
                                if( ref( $expect->[$i]->{ $prop } ) )
                                {
                                    is( ref( $rv->[$i]->{ $prop } // '' ), ref( $expect->[$i]->{ $prop } // '' ), "Reference value for $def->{method}() -> \$rv->[$i]->{ ${prop} } matches" );
                                }
                                else
                                {
                                    is( $rv->[$i]->{ $prop } => $expect->[$i]->{ $prop }, "Value for $def->{method}() -> \$rv->[$i]->{ ${prop} } matches" );
                                }
                            }
                        }
                    }
                }
                # string 'array'
                elsif( !ref( $expect ) )
                {
                    is( lc( ref( $rv ) // '' ) => $expect, "$def->{method} returned " . ( $expect // 'undef' ) );
                }
            };
        }
    };
}

# NOTE: inheritance tree
subtest 'inheritance tree' => sub
{
    my $tests =
    [
        { locale => 'ja-JP', expect => ['ja-JP', 'ja', 'und'] },
        { locale => 'pt-FR', expect => ['pt-FR', 'pt-PT', 'pt', 'und'] },
        { locale => 'yue-Hant', expect => ['yue-Hant', 'zh-Hant', 'und'] },
        { locale => 'sr-Cyrl-ME', expect => ['sr-Cyrl-ME', 'sr-ME', 'sr', 'und'] },
        { locale => 'so-Arab', expect => ['so-Arab', 'und'] },
    ];
    foreach my $def ( @$tests )
    {
        my $tree = $cldr->make_inheritance_tree( $def->{locale} );
        is_deeply( $tree, $def->{expect}, $def->{locale} . ' -> ' . join( ', ', @{$def->{expect}} ) );
    }
};

# NOTE: normalise
# <https://unicode.org/reports/tr35/tr35.html#Language_Tag_to_Locale_Identifier>
# <https://unicode.org/reports/tr35/tr35.html#4.-replacement>
subtest 'normalise' => sub
{
    my $tests =
    [
        { locale => 'en-US', expect => 'en-US' },
        { locale => 'iw-FX', expect => 'he-FR' },
        { locale => 'cmn-TW', expect => 'zh-TW' },
        { locale => 'zh-cmn-TW', expect => 'zh-TW' },
        { locale => 'sr-CS', expect => 'sr-RS' },
        { locale => 'sh', expect => 'sr-Latn' },
        { locale => 'sh-Cyrl', expect => 'sr-Latn' },
        { locale => 'hy-SU', expect => 'hy-AM' },
        { locale => 'i-enochian', expect => 'und-x-i-enochian' },
        { locale => 'x-abc', expect => 'und-x-abc' },
        { locale => 'ja-Latn-fonipa-hepburn-heploc', expect => 'ja-Latn-alalc97-fonipa' },
    ];
    foreach my $def ( @$tests )
    {
        my $l = $cldr->normalise( $def->{locale} );
        if( !defined( $l ) )
        {
            diag( "Error normalising locale '$def->{locale}': ", $cldr->error );
        }
        isa_ok( $l => 'Locale::Unicode', 'normalise() returns an Locale::Unicode object' );
        is( "$l", $def->{expect}, "normalise( $def->{locale} ) -> $def->{expect}" );
    }
};

# NOTE: timezone_canonical
subtest 'timezone_canonical' => sub
{
    my $str = $cldr->timezone_canonical( 'Europe/Paris' );
    is( $str => 'Europe/Paris', 'timezone_canonical( "Europe/Paris" ) -> "Europe/Paris"' );
    $str = $cldr->timezone_canonical( 'America/Atka' );
    is( $str => 'America/Adak', 'timezone_canonical( "America/Atka" ) -> "America/Adak"' );
    $str = $cldr->timezone_canonical( 'US/Aleutian' );
    is( $str => 'America/Adak', 'timezone_canonical( "US/Aleutian" ) -> "America/Adak"' );
    $str = $cldr->timezone_canonical( 'Canada/Pacific' );
    is( $str => 'America/Vancouver', 'timezone_canonical( "Canada/Pacific" ) -> "America/Vancouver"' );
};

done_testing();

__END__

