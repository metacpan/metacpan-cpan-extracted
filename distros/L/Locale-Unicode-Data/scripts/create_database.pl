#!/usr/bin/env perl
##----------------------------------------------------------------------------
## Unicode Locale Identifier - ~/scripts/create_database.pl
## Version v0.2.0
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2024/06/15
## Modified 2025/01/01
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# If you want to know more about this script, and how to use it, do: perldoc create_database.pl
# or, if you prefer, ./create_database.pl --man or ./create_database.pl --help for a short help
use strict;
use warnings;
use open ':std' => ':utf8';
use utf8;
use vars qw( $VERSION $DEBUG $VERBOSE $LOG_LEVEL $PROG_NAME $MAINTAINER
             $opt $opts
             $out $err @argv
             $topdir $basedir $cldr_version
         );
use Clone ();
use Data::Pretty qw( dump );
use DateTime;
use DateTime::Format::Strptime;
use DBD::SQLite;
use DBI qw( :sql_types );
use Getopt::Class v0.102.6;
use HTML::Entities qw( decode_entities );
use IPC::Run;
use JSON;
use List::Util qw( uniq );
use Locale::Unicode;
use Module::Generic::File qw( file stdout stderr tempfile );
use Module::Generic::Array;
use Pod::Usage;
use Scalar::Util qw( looks_like_number );
use XML::LibXML;
our $VERSION = 'v0.2.0';
our $DEBUG = 0;
our $VERBOSE = 0;
our $LOG_LEVEL = 0;
our $MAINTAINER = 'Jacques Deguest';
our $PROG_NAME = file( $0 )->basename( '.pl' );

our $out = stdout( binmode => ':utf8', autoflush => 1 );
our $err = stderr( binmode => ':utf8', autoflush => 1 );
my $logfile = file( $0 )->extension( 'log' );
my $tmpfile = tempfile( suffix => 'sqlite3', cleanup => 0 );
my $lib_dir = file( $0 )->parent->parent->child( 'lib' );
my $live_db_file;
our( $cldr_version, $topdir, $basedir, $patch_dir );

my $credit = <<EOT;
 
  
          Locale::Unicode::Data database builder v.$VERSION
               Jacques Deguest <jack\@deguest.jp>
         
         Copyright(c) 2024-2025 DEGUEST Pte. Ltd..
         This program is free software; you can redistribute it and/or modify it
         under the same terms as Perl itself.
EOT

my $dict =
{
    apply_patch                 => { type => 'boolean', default => 1 },
    cldr_version                => { type => 'string' },
    created                     => { type => 'datetime' },
    db_file                     => { type => 'file', default => $tmpfile },
    extend                      => { type => 'boolean', default => 0, action => 1 },
    extended_timezones_cities   => { type => 'file' },
    log_file                    => { type => 'file', default => $logfile },
    maintainer                  => { type => 'string', default => \$MAINTAINER },
    patch_only                  => { type => 'boolean', default => 0, action => 1 },
    replace                     => { type => 'boolean', default => 0 },
    use_log                     => { type => 'boolean', default => 0 },

    # Generic options
    quiet                       => { type => 'boolean', default => 0 },
    debug                       => { type => 'integer', alias => [qw(d)], default => \$DEBUG },
    verbose                     => { type => 'integer', default => \$VERBOSE },
    v                           => { type => 'code', code => sub{ printf( STDOUT "2f\n", $VERSION ); } },
    # help                => { type => 'code', alias => [qw(?)], code => sub{ pod2usage(1); } },
    help                        => { type => 'code', alias => [qw(?)], code => sub{ pod2usage( -exitstatus => 1, -verbose => 99, -sections => [qw( NAME SYNOPSIS DESCRIPTION COMMANDS OPTIONS AUTHOR COPYRIGHT )] ); } },
    man                         => { type => 'code', code => sub{ pod2usage( -exitstatus => 0, -verbose => 2 ); } },
};
# Create backup of arguments
our @argv = @ARGV;
our $opt = Getopt::Class->new({ dictionary => $dict }) || die( "Error instantiating Getopt::Class object: ", Getopt::Class->error, "\n" );
$opt->usage( sub{ pod2usage(2) } );
our $opts = $opt->exec || die( "An error occurred executing Getopt::Class: ", $opt->error, "\n" );
my @errors = ();
my $opt_errors = $opt->configure_errors;
push( @errors, @$opt_errors ) if( $opt_errors->length );
if( $opts->{quiet} )
{
    $DEBUG = $VERBOSE = 0;
}

# Unless the log level has been set directly with a command line option
unless( $LOG_LEVEL )
{
    $LOG_LEVEL = 1 if( $VERBOSE );
    $LOG_LEVEL = ( 1 + $DEBUG ) if( $DEBUG );
}
$err->print( "options check " ) if( $LOG_LEVEL );
if( length( $opts->{created} ) )
{
    $opts->{created_time} = $opts->{created}->epoch;
    $err->print( "Creating unix time from string $opts->{created} => $opts->{created_time}\n" ) if( $LOG_LEVEL );
}
else
{
    $opts->{created_time} = time();
}

if( $opts->{replace} )
{
    $live_db_file = $lib_dir->child( 'Locale/Unicode/unicode_cldr.sqlite3' );
    if( !$lib_dir->exists )
    {
        push( @errors, "Unable to find the lib directory ${lib_dir}" );
    }
    elsif( !$live_db_file->parent->exists )
    {
        push( @errors, "Parent directory for live SQLite database file ${live_db_file} does not exist!" );
    }
}

$err->print( @errors ? " not ok\n" : " ok\n" ) if( $LOG_LEVEL );
if( @errors )
{
    my $error = join( "\n", map{ "\t* $_" } @errors );
    substr( $error, 0, 0, "\n\tThe following arguments are mandatory and missing.\n" );
    if( !$opts->{quiet} )
    {
        $err->print( <<EOT );
$credit
    $error
    Please, use option '-h' or '--help' to find out and properly call
    this program in interactive mode:
    
    $PROG_NAME -h
EOT
    }
    exit(1);
}
$opts->{use_log} = 1 if( $DEBUG );

my $script_dir = file( $0 )->parent;
my $log_fh;
if( $opts->{use_log} )
{
    $logfile = $opts->{log_file};
    $log_fh = $logfile->open( '>', { binmode => ':utf8', autoflush => 1 }) ||
        die( $logfile->error );
}

local $SIG{__DIE__} = sub
{
    $err->print( @_ );
    $err->print( "Temporary SQLite database file not cleaned up upon exception: $tmpfile\n" );
    exit(1);
};
local $SIG{INT} = $SIG{TERM} = sub
{
    my $sig = shift( @_ );
    $err->print( "Caught a ${sig} signal.\n" );
    $err->print( "Temporary SQLite database file not cleaned up upon exception: $tmpfile\n" );
    exit(1);
};
my @files;
our $json = JSON->new->relaxed->allow_nonref->allow_blessed->convert_blessed;

$tmpfile = $opts->{db_file};
&log( "Using database file ${tmpfile}" );
&log( "Making SQL connection to ${tmpfile}" );
my $dbh = DBI->connect( "dbi:SQLite:dbname=${tmpfile}", '', '' ) ||
    die( "Unable to make connection to SQLite database file ${tmpfile}: ", $DBI::errstr );
# Enable the use of foreign keys
$dbh->do("PRAGMA foreign_keys = ON");
# $dbh->{sqlite_string_mode} = DBD::SQLite::Constants::DBD_SQLITE_STRING_MODE_UNICODE_FALLBACK;
$dbh->{sqlite_string_mode} = DBD::SQLite::Constants::DBD_SQLITE_STRING_MODE_UNICODE_STRICT;
$dbh->{sqlite_see_if_its_a_number} = 1;
$out->print( "Connection established to temporary SQLite database file ${tmpfile}\n" ) if( $DEBUG || !$opts->{replace} );
# NOTE: key variables declaration
my( $xml, $doc, $sth, $ref );
my $lang_vars = {};
# NOTE: Find out what action to take
my $action_found = '';
my @actions = grep{ exists( $dict->{ $_ }->{action} ) } keys( %$opts );
foreach my $action ( @actions )
{
    $action =~ tr/-/_/;
    next if( ref( $opts->{ $action } ) eq 'CODE' );
    if( $opts->{ $action } && $action_found && $action_found ne $action )
    {
        push( @errors, "You have opted for \"$action\", but \"$action_found\" is already selected." );
    }
    elsif( $opts->{ $action } && !length( $action_found ) )
    {
        $action_found = $action;
        die( "Unable to find a subroutne for '$action'" ) if( !main->can( $action ) );
    }
}

if( !$action_found )
{
    $action_found = 'process';
}
my $coderef = ( exists( $dict->{ $action_found }->{code} ) && ref( $dict->{ $action_found }->{code} ) eq 'CODE' )
    ? $dict->{ $action_found }->{code}
    : main->can( $action_found );
if( !defined( $coderef ) )
{
    die( "There is no sub for action \"$action_found\"\n" );
}
# exit( $coderef->() ? 0 : 1 );
&_cleanup_and_exit( $coderef->() ? 0 : 1 );

sub process
{
    if( !scalar( @ARGV ) )
    {
        die( "$0 /some/where/cldr-common-45.0" );
    }
    # Already declared as a global variable
    $topdir = file( shift( @ARGV ) );
    if( !$topdir->exists )
    {
        die( "CLDR top directory provided ${topdir} does not exist." );
    }
    elsif( !$topdir->is_dir )
    {
        die( "CLDR top directory provided ${topdir} is not a directory." );
    }
    # Already declared as a global variable
    $basedir = $topdir->child( 'common' );
    if( !$basedir->exists )
    {
        die( "CLDR JSON base directory ${basedir} does not exist." );
    }

    my $iana_timezone_file = $script_dir->child( 'zone1970.tab' );
    my $iana_alias_file = $script_dir->child( 'backward' );
    my $cache_tz_corrections_file = $script_dir->child( 'tz_corrections.json' );
    if( !$iana_timezone_file->exists )
    {
        die( "The IANA Olson time zone database file 'zone1970.tab' does not exist. Please download it from ftp://ftp.iana.org/tz/tzdata-latest.tar.gz and place it in the 'scripts' folder." );
    }
    # $patch_dir is used by the subroutine 'apply_patch'
    $patch_dir = $script_dir->child( "patches/${cldr_version}" );
    my $anno_dir = $basedir->child( 'annotations' );
    my $bcp47_dir = $basedir->child( 'bcp47' );
    my $casings_dir = $basedir->child( 'casing' );
    my $collation_dir = $basedir->child( 'collation' );
    my $main_dir = $basedir->child( 'main' );
    my $rbnf_dir = $basedir->child( 'rbnf' );
    my $subdivisions_l10n_dir = $basedir->child( 'subdivisions' );
    for( $anno_dir, $bcp47_dir, $casings_dir, $collation_dir, $main_dir, $rbnf_dir, $subdivisions_l10n_dir )
    {
        die( "No diectory ${_} found." ) if( !$_->exists );
    }

    my $n = 0;
    local $@;
    &log( "Creating SQL schema." );
    my $tables = load_schema( file( $0 )->parent->child( 'cldr-schema.sql' ) );
    &log( "Loaded ", scalar( @$tables ), " tables schema." );
    my $tables_to_query_check = {};
    @$tables_to_query_check{ @$tables } = (1) x scalar( @$tables );
    my $boolean_map =
    {
        'true'  => 1,
        'false' => 0,
    };
    
    # NOTE: Preparing all SQL queries
    &log( "Preparing all SQL queries." );
    my $queries =
    [
        aliases => "INSERT INTO aliases (alias, replacement, reason, type, comment) VALUES(?, ?, ?, ?, ?)",
        annotations => "INSERT INTO annotations (locale, annotation, defaults, tts) VALUES(?, ?, ?, ?)",
        bcp47_currencies => "INSERT INTO bcp47_currencies (currid, code, description, is_obsolete) VALUES(?, ?, ?, ?)",
        bcp47_extensions => "INSERT INTO bcp47_extensions (category, extension, alias, value_type, description, deprecated) VALUES(?, ?, ?, ?, ?, ?)",
        bcp47_timezones => "INSERT INTO bcp47_timezones (tzid, alias, preferred, description, deprecated) VALUES(?, ?, ?, ?, ?)",
        bcp47_values => "INSERT INTO bcp47_values (category, extension, value, description) VALUES(?, ?, ?, ?)",
        calendar_append_formats => "INSERT INTO calendar_append_formats (locale, calendar, format_id, format_pattern) VALUES(?, ?, ?, ?)",
        calendar_available_formats => "INSERT INTO calendar_available_formats (locale, calendar, format_id, format_pattern, count, alt) VALUES(?, ?, ?, ?, ?, ?)",
        calendar_cyclics_l10n => "INSERT INTO calendar_cyclics_l10n (locale, calendar, format_set, format_type, format_length, format_id, format_pattern) VALUES(?, ?, ?, ?, ?, ?, ?)",
        calendar_datetime_formats => "INSERT INTO calendar_datetime_formats (locale, calendar, format_length, format_type, format_pattern) VALUES(?, ?, ?, ?, ?)",
        calendar_eras => "INSERT INTO calendar_eras (calendar, sequence, code, aliases, start, until) VALUES(?, ?, ?, ?, ?, ?)",
        calendar_eras_l10n => "INSERT INTO calendar_eras_l10n (locale, calendar, era_width, era_id, alt, locale_name) VALUES(?, ?, ?, ?, ?, ?)",
        calendar_formats_l10n => "INSERT INTO calendar_formats_l10n (locale, calendar, format_type, format_length, alt, format_id, format_pattern) VALUES(?, ?, ?, ?, ?, ?, ?)",
        calendar_interval_formats => "INSERT INTO calendar_interval_formats (locale, calendar, format_id, greatest_diff_id, format_pattern, alt, part1, separator, part2, repeating_field) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        calendar_terms => "INSERT INTO calendar_terms (locale, calendar, term_type, term_context, term_width, alt, yeartype, term_name, term_value) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)",
        calendars => "INSERT INTO calendars (calendar, system, inherits, description) VALUES(?, ?, ?, ?)",
        calendars_l10n => "INSERT INTO calendars_l10n (locale, calendar, locale_name) VALUES(?, ?, ?)",
        casings => "INSERT INTO casings (locale, token, value) VALUES(?, ?, ?)",
        collations_l10n => "INSERT INTO collations_l10n (locale, collation, locale_name) VALUES(?, ?, ?)",
        code_mappings => "INSERT INTO code_mappings (code, alpha3, numeric, fips10, type) VALUES(?, ?, ?, ?, ?)",
        currencies => "INSERT INTO currencies (currency, digits, rounding, cash_digits, cash_rounding, is_obsolete, status) VALUES(?, ?, ?, ?, ?, ?, ?)",
        currencies_info => "INSERT INTO currencies_info (territory, currency, start, until, is_tender, hist_sequence, is_obsolete) VALUES(?, ?, ?, ?, ?, ?, ?)",
        currencies_l10n => "INSERT INTO currencies_l10n (locale, currency, count, locale_name, symbol) VALUES(?, ?, ?, ?, ?)",
        date_fields_l10n => "INSERT INTO date_fields_l10n (locale, field_type, field_length, relative, locale_name) VALUES(?, ?, ?, ?, ?)",
        date_terms => "INSERT INTO date_terms (locale, term_type, term_length, display_name) VALUES(?, ?, ?, ?)",
        day_periods => "INSERT INTO day_periods (locale, day_period, start, until) VALUES(?, ?, ?, ?)",
        language_population => "INSERT INTO language_population (territory, locale, population_percent, literacy_percent, writing_percent, official_status) VALUES(?, ?, ?, ?, ?, ?)",
        languages => "INSERT OR IGNORE INTO languages (language, scripts, territories, parent, alt, status) VALUES(?, ?, ?, ?, ?, ?)",
        languages_match => "INSERT INTO languages_match (desired, supported, distance, is_symetric, is_regexp, sequence) VALUES(?, ?, ?, ?, ?, ?)",
        likely_subtags => "INSERT INTO likely_subtags (locale, target) VALUES(?, ?)",
        locales => "INSERT INTO locales (locale, parent, collations, status) VALUES(?, ?, ?, ?)",
        locales_info => "INSERT INTO locales_info (locale, property, value) VALUES(?, ?, ?)",
        locales_l10n => "INSERT INTO locales_l10n (locale, locale_id, locale_name, alt) VALUES(?, ?, ?, ?)",
        locale_number_systems => "INSERT INTO locale_number_systems (locale, number_system, native, traditional, finance) VALUES(?, ?, ?, ?, ?)",
        metainfos => "INSERT INTO metainfos (property, value) VALUES(?, ?)",
        metazones => "INSERT INTO metazones (metazone, territories, timezones) VALUES(?, ?, ?)",
        metazones_names => "INSERT INTO metazones_names (locale, metazone, width, generic, standard, daylight) VALUES(?, ?, ?, ?, ?, ?)",
        number_formats_l10n => "INSERT INTO number_formats_l10n (locale, number_system, number_type, format_length, format_type, format_id, format_pattern, alt, count) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?)",
        number_symbols_l10n => "INSERT INTO number_symbols_l10n (locale, number_system, property, value, alt) VALUES(?, ?, ?, ?, ?)",
        number_systems => "INSERT INTO number_systems (number_system, digits, type) VALUES(?, ?, ?)",
        number_systems_l10n => "INSERT INTO number_systems_l10n (locale, number_system, locale_name, alt) VALUES(?, ?, ?, ?)",
        person_name_defaults => "INSERT INTO person_name_defaults (locale, value) VALUES(?, ?)",
        plural_ranges => "INSERT INTO plural_ranges (locale, aliases, start, stop, result) VALUES(?, ?, ?, ?, ?)",
        plural_rules => "INSERT INTO plural_rules (locale, aliases, count, rule) VALUES(?, ?, ?, ?)",
        rbnf => "INSERT INTO rbnf (locale, grouping, ruleset, rule_id, rule_value) VALUES(?, ?, ?, ?, ?)",
        refs => "INSERT INTO refs (code, uri, description) VALUES(?, ?, ?)",
        regions => "INSERT OR IGNORE INTO territories (territory, contains, status) VALUES(?, ?, ?)",
        scripts => "INSERT INTO scripts (script, rank, sample_char, id_usage, rtl, lb_letters, has_case, shaping_req, ime, density, origin_country, likely_language, status) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        scripts_l10n => "INSERT INTO scripts_l10n (locale, script, locale_name, alt) VALUES(?, ?, ?, ?)",
        subdivisions => "INSERT INTO subdivisions (territory, subdivision, parent, is_top_level, status) VALUES(?, ?, ?, ?, ?)",
        subdivisions_l10n => "INSERT INTO subdivisions_l10n (locale, subdivision, locale_name) VALUES(?, ?, ?)",
        territories => "INSERT INTO territories (territory, parent, gdp, literacy_percent, population, languages, contains, currency, calendars, min_days, first_day, weekend, status) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        territories_l10n => "INSERT INTO territories_l10n (locale, territory, locale_name, alt) VALUES(?, ?, ?, ?)",
        time_formats => "INSERT INTO time_formats (region, territory, locale, time_format, time_allowed) VALUES(?, ?, ?, ?, ?)",
        time_relative_l10n => "INSERT INTO time_relative_l10n (locale, field_type, field_length, relative, format_pattern, count) VALUES(?, ?, ?, ?, ?, ?)",
        timezones => "INSERT INTO timezones (timezone, territory, region, tzid, metazone, tz_bcpid, is_golden, is_primary, is_preferred, is_canonical,  alias) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        timezones_cities => "INSERT INTO timezones_cities (locale, timezone, city, alt) VALUES(?, ?, ?, ?)",
        # This is defined in the extend_timezones_cities() function
        timezones_cities_supplemental => undef,
        timezones_formats => "INSERT INTO timezones_formats (locale, type, subtype, format_pattern) VALUES(?, ?, ?, ?)",
        timezones_info => "INSERT INTO timezones_info (timezone, metazone, start, until) VALUES(?, ?, ?, ?)",
        timezones_names => "INSERT INTO timezones_names (locale, timezone, width, generic, standard, daylight) VALUES(?, ?, ?, ?, ?, ?)",
        unit_aliases => "INSERT INTO unit_aliases (alias, target, reason) VALUES(?, ?, ?)",
        unit_constants => "INSERT INTO unit_constants (constant, expression, value, description, status) VALUES(?, ?, ?, ?, ?)",
        unit_conversions => "INSERT INTO unit_conversions (source, base_unit, expression, factor, systems, category) VALUES(?, ?, ?, ?, ?, ?)",
        units_l10n => "INSERT INTO units_l10n (locale, format_length, unit_type, unit_id, unit_pattern, pattern_type, locale_name, count, gender, gram_case) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        unit_prefixes => "INSERT INTO unit_prefixes (unit_id, symbol, power, factor) VALUES(?, ?, ?, ?)",
        unit_prefs => "INSERT INTO unit_prefs (unit_id, territory, category, usage, geq, skeleton) VALUES(?, ?, ?, ?, ?, ?)",
        unit_quantities => "INSERT INTO unit_quantities (base_unit, quantity, status, comment) VALUES(?, ?, ?, ?)",
        variants => "INSERT INTO variants (variant, status) VALUES(?, ?)",
        variants_l10n => "INSERT INTO variants_l10n (locale, variant, locale_name, alt) VALUES(?, ?, ?, ?)",
        week_preferences => "INSERT INTO week_preferences (locale, ordering) VALUES(?, ?)",
    ];
    my $sths = {};
    
    for( my $i = 0; $i < scalar( @$queries ); $i += 2 )
    {
        my $id = $queries->[$i];
        $out->print( "[${id}] " ) if( $DEBUG );
        my $sql = $queries->[$i + 1];
        # It is listed, but we skip it to make the 'tables_to_query_check' happy
        if( !defined( $sql ) )
        {
            delete( $tables_to_query_check->{ $id } );
            next;
        }
        elsif( exists( $sths->{ $id } ) )
        {
            die( "There is already a statement object for ID '${id}' with SQL: ", $sths->{ $id }->{Statement} );
        }
        my $sth = $dbh->prepare( $sql ) ||
            die( "Error preparing query '", $sql, "': ", $dbh->errstr );
        $sths->{ $id } = $sth;
        $out->print( "ok\n" ) if( $DEBUG );
        if( exists( $tables_to_query_check->{ $id } ) )
        {
            delete( $tables_to_query_check->{ $id } );
        }
        else
        {
            warn( "Warning only: No table '$id' found in our a tables-to-query map check." );
        }
    }
    
    if( scalar( keys( %$tables_to_query_check ) ) )
    {
        die( sprintf( "There are %d tables with no statement defined: %s", scalar( keys( %$tables_to_query_check ) ), join( ', ', sort( keys( %$tables_to_query_check ) ) ) ) );
    }
    else
    {
        &log( "All tables have a statement defined." );
    }
    
    # NOTE: Add meta information
    &log( "Add meta information." );
    my $today = DateTime->from_epoch( epoch => $opts->{created_time} );
    # $cldr_version is already declared as a global variable
    # cldr-common-45.0
    if( $opts->{cldr_version} )
    {
        $cldr_version = $opts->{cldr_version};
    }
    elsif( $topdir =~ /\-(\d+(?:\.\d+)*)$/ )
    {
        $cldr_version = $1;
    }
    else
    {
        die( "Unable to figure out the CLDR version from the directory of its data: ${topdir}" );
    }
    $sth = $sths->{metainfos} || die( "Unable to get a statement object for table metainfos" );
    my $meta =
    [
        { property => 'cldr_version', value => $cldr_version },
        { property => 'built_on', value => $today->iso8601 },
        { property => 'maintainer', value => $opts->{maintainer} },
    ];
    foreach my $def ( @$meta )
    {
        eval
        {
            $sth->execute( @$def{ qw( property value ) } );
        } || die( "Error adding meta information property '$def->{property}' with value '$def->{value}': ", ( $@ || $sth->errstr ), "\nwith SQL query: ", $sth->{Statement}, "\n", dump( $def ) );
    }
    
    # NOTE: Pre-loading all known currencies, languages, regions, scripts, subdivisions, variants
    &log( "Pre-loading all known currencies, languages, regions, scripts, subdivisions, variants." );
    my $known = {};
    my $known_data =
    {
        currencies  => 
            {
                file => $basedir->child( "validity/currency.xml" ),
                type => 'currency',
            },
        languages   =>
            {
                file => $basedir->child( "validity/language.xml" ),
                type => 'language',
            },
        territories =>
            {
                file => $basedir->child( "validity/region.xml" ),
                type => 'region',
            },
        scripts     =>
            {
                file => $basedir->child( "validity/script.xml" ),
                type => 'script',
            },
        subdivisions    =>
            {
                file => $basedir->child( "validity/subdivision.xml" ),
                type => 'subdivision',
            },
        variants    =>
            {
                file => $basedir->child( "validity/variant.xml" ),
                type => 'variant',
            },
    };
    
    # Sorting does not really matter, but it is just so I get the same order of output
    foreach my $prop ( sort( keys( %$known_data ) ) )
    {
        $out->print( "[${prop}] " ) if( $DEBUG );
        $n = 0;
        my $def = $known_data->{ $prop };
        my $validDom = load_xml( $def->{file} );
        my $validRes = $validDom->findnodes( "/supplementalData/idValidity/id[\@type=\"$def->{type}\"]" ) ||
            die( "Unable to find any data of type '$def->{type}' in file $def->{file}" );
        my $hash = {};
        while( my $el = $validRes->shift )
        {
            my $status = $el->getAttribute( 'idStatus' );
            my $data = trim( $el->textContent );
            my $ids = [split( /[[:blank:]\h\v]+/, $data )];
            foreach my $id ( @$ids )
            {
                if( index( $id, '~' ) != -1 )
                {
                    $id =~ s{
                        (?<prefix>[a-zA-Z0-9]+)(?<start>[a-zA-Z0-9])\~(?<end>[a-zA-Z0-9]+)
                    }
                    {
                        my $re = {%+};
                        foreach my $c ( $re->{start}..$re->{end} )
                        {
                            my $r = $re->{prefix} . $c;
                            # $out->print( "Adding '${r}'\n" );
                            $hash->{ $r } =
                            {
                                status => $status,
                            };
                            $n++;
                        }
                        '';
                    }exs;
                }
                else
                {
                    $hash->{ $id } =
                    {
                        status => $status,
                    };
                    $n++;
                }
            }
        }
        $known->{ $prop } = $hash;
        $out->print( "ok. ${n} ${prop} added.\n" ) if( $DEBUG );
    }
    
    my $supplemental_data_file = $basedir->child( 'supplemental/supplementalData.xml' );
    my $suppDoc = load_xml( $supplemental_data_file );
    
    # NOTE: Pre-loading currencies data (BCP47 and locale data)
    &log( "Pre-loading currencies data (BCP47 and locale data)" );
    my $bcp_currency_file = $basedir->child( 'bcp47/currency.xml' );
    my $eng_locale_data_file = $basedir->child( 'main/en.xml' );
    my $bcpCurrDoc = load_xml( $bcp_currency_file );
    my $engLocaleDoc = load_xml( $eng_locale_data_file );
    my $bcpCurrRes = $bcpCurrDoc->findnodes( '/ldmlBCP47/keyword/key[@name="cu"]/type[@name]' );
    # $out->print( $bcpCurrRes->size, " currency BCP47 IDs found.\n" );
    my $bcpCurrIds = {};
    my $bcpCurrDesc2id = {};
    while( my $el = $bcpCurrRes->shift )
    {
        my $id = $el->getAttribute( 'name' );
        my $desc = $el->getAttribute( 'description' );
        $desc =~ s/[[:blank:]\h\v]/ /gs;
        $desc =~ s/\((\d{4})\D(\d{4})\)$/\($1-$2\)/;
        $bcpCurrIds->{ $id } = $desc;
        if( exists( $bcpCurrDesc2id->{ $desc } ) )
        {
            die( "There already exist the currency '", $bcpCurrDesc2id->{ $desc }, "' for the description '${desc}' that this currency '${id}' also has." );
        }
        else
        {
            $bcpCurrDesc2id->{ lc( $desc ) } = $id;
        }
    }
    my $engCurrRes = $engLocaleDoc->findnodes( '/ldml/numbers/currencies/currency' );
    # $out->print( $engCurrRes->size, " locale currencies found.\n" );
    my $currMap = {};
    my $currBCPMap = {};
    my $currUnknown = {};
    while( my $el = $engCurrRes->shift )
    {
        my $code = $el->getAttribute( 'type' );
        # my $disp = $el->getChildrenByTagName( 'displayName' );
        my $disp = $el->findnodes( './displayName[not(@count)]' );
        # $out->print( "Found ", $disp->size, " name(s) for this currency ${code}\n" ) if( $DEBUG );
        my $desc = $disp->shift->textContent;
        $desc = decode_entities( $desc ) if( index( $desc, '&' ) != -1 );
        # Switch commercial and (&) to regular and
        $desc =~ s/[[:blank:]\h]\&[[:blank:]\h]/ and /g if( index( $desc, '&' ) != -1 );
        my $is_obsolete = 0;
        if( $desc =~ s/\((\d{4})\D(\d{4})\)$/\($1-$2\)/ )
        {
            $is_obsolete++;
        }
        $desc =~ s/[[:blank:]\h\v]/ /gs;
        # Afghan Afghani (1927–2002) -> Afghan Afghani (1927–2002)
        $desc =~ s/\–/\–/g;
        my $test = lc( $desc );
        # $out->print( "Checking currency code '${code}' with description '${desc}'\n" ) if( $DEBUG );
        if( exists( $bcpCurrDesc2id->{ $test } ) )
        {
            # I prefer the spelling of the BCP47 which keeps the casing proper, i.e. first letter upper case for each word
            $currMap->{ $code } = 
            {
                id => $bcpCurrDesc2id->{ $test },
                description => $bcpCurrIds->{ $bcpCurrDesc2id->{ $test } },
                is_obsolete => $is_obsolete,
            };
            $currBCPMap->{ $bcpCurrDesc2id->{ $test } } =
            {
                code => $code,
                description => $bcpCurrIds->{ $bcpCurrDesc2id->{ $test } },
                is_obsolete => $is_obsolete,
            };
            delete( $bcpCurrIds->{ $bcpCurrDesc2id->{ $test } } );
        }
        elsif( exists( $bcpCurrIds->{ lc( $code ) } ) )
        {
            $currMap->{ $code } = 
            {
                id => lc( $code ),
                description => $bcpCurrIds->{ lc( $code ) },
                is_obsolete => $is_obsolete,
            };
            $currBCPMap->{ lc( $code ) } =
            {
                code => $code,
                description => $bcpCurrIds->{ lc( $code ) },
                is_obsolete => $is_obsolete,
            };
            delete( $bcpCurrIds->{ lc( $code ) } );
        }
        else
        {
            if( $desc =~ /\((\d{4})\D(\d{4})\)$/ )
            {
                $out->print( "\tThis is an old currency in use from $1 to $2\n" ) if( $DEBUG );
            }
            $currUnknown->{ $code }++;
        }
    }
    $out->print( "Could map out ", scalar( keys( %$currMap ) ), " currencies while ", scalar( keys( %$currUnknown ) ), " were left unknown.\n" ) if( $DEBUG );
    # $out->print( dump( $currMap ), "\n" ) if( $DEBUG >= 4 );
    if( scalar( keys( %$currUnknown ) ) )
    {
        $out->print( "Fatal: unknowns: ", join( ', ', sort( keys( %$currUnknown ) ) ), "\n" ) if( $DEBUG );
        exit(1);
    }
    if( scalar( keys( %$bcpCurrIds ) ) )
    {
        $out->print( "Fatal: unmapped BCP47 IDs: ", scalar( keys( %$bcpCurrIds ) ), ":\n" ) if( $DEBUG );
        foreach my $id ( sort( keys( %$bcpCurrIds ) ) )
        {
            $out->print( "${id}: ", $bcpCurrIds->{ $id }, "\n" ) if( $DEBUG );
        }
        exit(1);
    }
    
    # NOTE: Loading currencies
    &log( "Loading currencies." );
    $n = 0;
    my $currRes = $suppDoc->findnodes( '/supplementalData/currencyData/fractions/info[not(@iso4217="DEFAULT")]' ) ||
        die( "Unable to get the currencies information from ${supplemental_data_file}" );
    if( !$currRes->size )
    {
        die( "No currencies information was found in ${supplemental_data_file}" );
    }
    $sth = $sths->{currencies} || die( "No SQL statement object for currencies" );
    # We load up the initial set of data in the currencies dictionary
    my $currenciesData = {};
    while( my $el = $currRes->shift )
    {
        my $def =
        {
            currency => ( $el->getAttribute( 'iso4217' ) || die( "No attribute 'iso4217' found for this currency element: ", $el->toString() ) ),
            digits => $el->getAttribute( 'digits' ),
            rounding => $el->getAttribute( 'rounding' ),
            cash_digits => $el->getAttribute( 'cashDigits' ),
            cash_rounding => $el->getAttribute( 'cashRounding' ),
        };
        foreach my $prop ( qw( digits rounding ) )
        {
            if( !defined( $def->{ $prop } ) ||
                !length( $def->{ $prop } ) )
            {
                die( "No attribute '${prop}' could be found for this currency '", $def->{currency}, "': ", $el->toString() );
            }
        }
        if( exists( $currMap->{ $def->{currency} } ) )
        {
            $def->{is_obsolete} = $currMap->{ $def->{currency} }->{is_obsolete};
        }
        $currenciesData->{ $def->{currency} } = $def;
    }
    
    # Now, we merge our main currencies data to ensure we have a complete set, although many will not have the rounding or digits information provided.
    foreach my $code ( keys( %$currMap ) )
    {
        if( !exists( $currenciesData->{ $code } ) )
        {
            $currenciesData->{ $code } = 
            {
                currency => $code,
                is_obsolete => $currMap->{ $code }->{is_obsolete},
            }
        }
    }
    
    # Add missing currencies and set the status using the known currencies we loaded at the beginning.
    foreach my $code ( keys( %{$known->{currencies}} ) )
    {
        if( !exists( $currenciesData->{ $code } ) )
        {
            $currenciesData->{ $code } = { currency => $code };
        }
        $currenciesData->{ $code }->{status} = $known->{currencies}->{ $code }->{status};
    }
    
    foreach my $code ( sort( keys( %$currenciesData ) ) )
    {
        my $def = $currenciesData->{ $code };
        $out->print( "[", $def->{currency}, "] " ) if( $DEBUG );
    
        eval
        {
            $sth->execute( @$def{qw( currency digits rounding cash_digits cash_rounding is_obsolete status )} );
        } || die( "Error adding currency '", $def->{currency}, "' information to table currencies: ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
        $out->print( "ok\n" ) if( $DEBUG );
        $n++;
    }
    &log( "${n} currencies added." );
    
    # NOTE: Loading BCP47 currencies
    &log( "Loading BCP47 currencies." );
    $n = 0;
    $sth = $sths->{bcp47_currencies} || die( "No SQL statement object for bcp47_currencies" );
    foreach my $id ( sort( keys( %$currBCPMap ) ) )
    {
        my $def = $currBCPMap->{ $id };
        $out->print( "[${id}] " ) if( $DEBUG );
        eval
        {
            $sth->execute( $id, @$def{qw( code description is_obsolete )} );
        } || die( "Error adding BCP47 currency '${id}' information and ISO 4217 currency code '$def->{code}' to table bcp47_currencies: ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
        $out->print( "ok\n" ) if( $DEBUG );
        $n++;
    }
    &log( "${n} BCP47 currencies added." );
    
    # NOTE: Pre-loading core regional territories
    &log( "Pre-loading core regional territories" );
    my $containersRes = $suppDoc->findnodes( '//territoryContainment/group' ) ||
        die( "Unable to get territories containers information in ${supplemental_data_file}" );
    if( !$containersRes->size )
    {
        die( "No territories containers information could be found in ${supplemental_data_file}" );
    }
    $n = 0;
    # We need to ensure the locale we use in territoryInfo exists since we need to satisfy the foreign key.
    # So we add the locale to the hash reference $known_locales so it can be added
    my $known_locales = {};
    my $territoryInfo = {};
    while( my $el = $containersRes->shift )
    {
        my $code = $el->getAttribute( 'type' );
        # Example: 030 (Eastern Asia) contains CN HK JP KP KR MN MO TW
        my $contains = $el->getAttribute( 'contains' ) ||
            die( "Unable to get the value of contained territories in attribute 'contains' for this element: ", $el->toString() );
        $contains = [split( /[[:blank:]\h\v]+/, $contains )];
        # grouping, deprecated
        my $status = $el->getAttribute( 'status' );
        $out->print( "[${code}] " ) if( $DEBUG );
        # We need to ensure territory code such as 001 is treated as a string and not end up as 1
        $code = sprintf( '%03d', $code ) if( $code =~ /^\d{1,2}$/ );
        if( !exists( $territoryInfo->{ $code } ) )
        {
            $territoryInfo->{ $code } =
            {
                contains => $contains,
                status => $status,
            };
            $out->print( "ok\n" ) if( $DEBUG );
            &log( "Pre-loaded core regional territory ${code}" );
            $n++;
        }
        # There is another entry, but with attribute 'grouping' or 'status', so we add the contained territories to the stack
        elsif( $el->hasAttribute( 'grouping' ) ||
               $el->hasAttribute( 'status' ) )
        {
            $out->print( "adding territories: ", join( ', ', @$contains ), "\n" ) if( $DEBUG );
            push( @{$territoryInfo->{ $code }->{contains}}, @$contains );
        }
        else
        {
            $out->print( "ignored (duplicate?)\n" ) if( $DEBUG );
        }
    }
    &log( "${n} core regional territories pre-loaded." );
    
    # NOTE: Collecting territories data
    &log( "Collecting territories data." );
    $n = 0;
    my $terrRes = $suppDoc->findnodes( '/supplementalData/territoryInfo/territory' ) ||
        die( "Unable to get the territories information in ${supplemental_data_file}" );
    if( !$terrRes->size )
    {
        die( "No territories information found in ${supplemental_data_file}" );
    }
    while( my $el = $terrRes->shift )
    {
        my $code = $el->getAttribute( 'type' );
        if( exists( $territoryInfo->{ $code } ) )
        {
            die( "This territory code '${code}' seems to already exists and thus have already been defined as a container region during our previous pass." );
        }
        $territoryInfo->{ $code } = 
        {
            gdp => $el->getAttribute( 'gdp' ),
            literacy_percent => $el->getAttribute( 'literacyPercent' ),
            population => $el->getAttribute( 'population' ),
        };
        my $langs = {};
        my $langs_order = [];
        my @langPop = $el->getElementsByTagName( 'languagePopulation' );
        foreach my $lel ( @langPop )
        {
            my $lang = $lel->getAttribute( 'type' );
            # Some languages used here use underscore. Not sure why, but we need to harmonize and standardize this with the rest of the data.
            $lang =~ tr/_/-/;
            # Make sure to add that locale to satisfy the foreign key requirement
            $known_locales->{ $lang } = { locale => $lang } if( !exists( $known_locales->{ $lang } ) );
            $langs->{ $lang } =
            {
                population_percent => $lel->getAttribute( 'populationPercent' ),
                literacy_percent => $lel->getAttribute( 'literacyPercent' ),
                writing_percent => $lel->getAttribute( 'writingPercent' ),
                official_status => $lel->getAttribute( 'officialStatus' ),
            };
            push( @$langs_order, $lang );
        }
        $territoryInfo->{ $code }->{language_population} = $langs;
        $territoryInfo->{ $code }->{_langs} = $langs_order;
    }
    
    # NOTE: Adding missing territory codes
    &log( "Adding missing territory codes." );
    my $missingButRequiredTerritoryCodes =
    {
        # Used in supplemental/supplementalData.xml//weekData/minDays
        AN => { status => 'deprecated' },
    };
    
    foreach my $code ( keys( %$missingButRequiredTerritoryCodes ) )
    {
        if( !exists( $territoryInfo->{ $code } ) )
        {
            $out->print( "Adding ${code}\n" ) if( $DEBUG );
            $territoryInfo->{ $code } = $missingButRequiredTerritoryCodes->{ $code };
        }
    }
    
    # NOTE: Processing territories currencies historical data to derive current currency code for each territory
    &log( "Pre-loading territories currency historical data." );
    $n = 0;
    my $currencyRegionsRes = $suppDoc->findnodes( '//currencyData/region[@iso3166]' ) ||
        die( "Unable to get the currency region nodes in file ${supplemental_data_file}" );
    if( !$currencyRegionsRes->size )
    {
        die( "No currency region nodes found in file ${supplemental_data_file}" );
    }
    my $o = 0;
    my $currenciesInfo = {};
    my $dtParser = DateTime::Format::Strptime->new(
        pattern     => '%Y-%m-%d',
        locale      => 'en_GB',
        time_zone   => 'GMT',
    );
    # See <https://en.wikipedia.org/wiki/ISO_3166-3#Current_codes>
    my $deprecatedTerritories =
    {
        # "Burma (BU) was renamed to Myanmar (MM)"
        BU  => { status => 'deprecated' },
        # Czechoslovakia
        CS  => { status => 'deprecated' },
        # "East Germany merged with West Germany, and no longer exists as "DD". DDM was an ISO-4217 code."
        DD  => { status => 'deprecated' },
        # Soviet Union. "It split into RU and several other regions."
        SU  => { status => 'deprecated' },
        # East Timor. Renamed to TL
        # <https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Transitional_reservations>
        TP  => { status => 'deprecated' },
        # Yemen, Democratic
        # <https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Deleted_codes>
        YD  => { status => 'deprecated' },
        # Yugoslavia
        # <https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Transitional_reservations>
        YU  => { status => 'deprecated' },
        # "Zaire (ZR) was renamed to Democratic Republic of Congo (CD)."
        ZR  => { status => 'deprecated' },
    };
    my $currencyException =
    {
        # Unknown or Invalid Territory
        # Currency code for transations where no currency is involved
        ZZ => 'XXX',
    };
    while( my $el = $currencyRegionsRes->shift )
    {
        my $code = $el->getAttribute( 'iso3166' ) ||
            die( "No attribute 'iso3166' found for this element: ", $el->toString() );
        $out->print( "[${code}] " ) if( $DEBUG );
        my $infoRes = $el->findnodes( './currency[@iso4217]' ) ||
            die( "Unable to get the 'currency' nodes for the region code '${code}': ", $el->toString() );
        my $totalCurrInfos = $infoRes->size;
        if( !exists( $territoryInfo->{ $code } ) )
        {
            if( exists( $deprecatedTerritories->{ $code } ) )
            {
                $territoryInfo->{ $code } = $deprecatedTerritories->{ $code };
                $out->print( "deprecated, and has ${totalCurrInfos} historical currency information found.\n" ) if( $DEBUG );
                # This is an old territory code with no historical currency data
                next if( !$totalCurrInfos );
            }
            else
            {
                die( "Territory code '${code}' used in historical currency information is unknown, not in the list of defined territories. You may want to add it to the list of exceptions in the \$deprecatedTerritories hash reference here." );
            }
        }
        elsif( exists( $territoryInfo->{ $code }->{contains} ) )
        {
            $out->print( "is a container territory: " ) if( $DEBUG );
        }
        $currenciesInfo->{ $code } = [];
        # The CLDR list those historical records with the latest on top, but we do the opposite, especially since in SQL it does not matter that much.
        # And we use the field hist_sequence to keep track of the sequence
        my $seq = 0;
        my $activeCurrency;
        my $lastEndDate;
        while( my $el_curr = $infoRes->shift )
        {
            my $curr = $el_curr->getAttribute( 'iso4217' ) ||
                die( "No attribute 'iso4217' found for this territory code '${code}': ", $el_curr->toString() );
            my $from = $el_curr->getAttribute( 'from' );
            if( !length( $from // '' ) )
            {
                warn( "Warning: no attribute 'from' found for this currency code '${curr}' for the territory code '${code}': " . $el_curr->toString() );
            }
            my $to;
            if( $el_curr->hasAttribute( 'to' ) )
            {
                $to = $el_curr->getAttribute( 'to' ) ||
                    die( "Attribute 'to' is defined, but is empty for this currency '${curr}' historical record for the territory '${code}': ", $el_curr->toString() );
            }
            foreach( $from, $to )
            {
                if( defined( $_ ) )
                {
                    if( /^(?<year>\d{4})\D(?<month>\d{1,2})$/ )
                    {
                        warn( "Missing 'day' for '$_' for territory '${code}' and currency '${curr}', defaulting to 1: $_" );
                        $_ = sprintf( '%04d-%02d-%02d', $+{year}, $+{month}, 1 );
                    }
                    elsif( /^(?<year>\d{4})$/ )
                    {
                        warn( "Missing 'month' and 'day' for '$_' for territory '${code}' and currency '${curr}', defaulting to 1: $_" );
                        $_ = sprintf( '%04d-%02d-%02d', $+{year}, 1, 1 );
                    }
                    elsif( !length( $_ // '' ) )
                    {
                        $_ = undef;
                    }
                }
            }
    
            # If there is no end date for this currency, this means it is still active.
            if( defined( $from ) && !defined( $to ) )
            {
                if( defined( $activeCurrency ) )
                {
                    if( defined( $lastEndDate ) )
                    {
                        my $fromDt = $dtParser->parse_datetime( $from );
                        my $prevDt = $dtParser->parse_datetime( $lastEndDate );
                        if( $fromDt >= $prevDt )
                        {
                            warn( "Warning: Found previously set active currency '${activeCurrency}' for this territory code '${code}', but this currency '${curr}' has a start date '${from}' higher or equal to the previous one end date '${lastEndDate}'. Using '${curr}' instead." );
                            $activeCurrency = $curr;
                        }
                        else
                        {
                            warn( "Warning: Found previously set active currency '${activeCurrency}' for this territory code '${code}', but this currency '${curr}' has a start date '${from}' lower than the previous one end or start date '${lastEndDate}'. Not using '${curr}' as the territory default currency." );
                        }
                    }
                    else
                    {
                        die( "Found currency '${curr}' with start date '", ( $from // 'undef' ), "' and no end date for this territory code '${code}', but another one is already defined: '${activeCurrency}'" );
                    }
                }
                else
                {
                    $activeCurrency = $curr;
                    $lastEndDate = $from;
                }
            }
            elsif( defined( $to ) )
            {
                $lastEndDate = $to;
                # For historical currency that are singleton and are part of an deprecated territory like BU
                if( exists( $deprecatedTerritories->{ $code } ) &&
                    !defined( $activeCurrency ) )
                {
                    $activeCurrency = $curr;
                }
            }
            elsif( defined( $from ) )
            {
                $lastEndDate = $from;
            }
            # For territories with no active currency, such as AQ
            elsif( !defined( $from ) &&
                   !defined( $to ) &&
                   $totalCurrInfos == 1 )
            {
                $activeCurrency = $curr;
            }
    
            my $is_tender = 0;
            if( $el_curr->hasAttribute( 'tender' ) )
            {
                my $this = $el_curr->getAttribute( 'tender' ) ||
                    die( "Attribute 'tender' is defined for this currency '${curr}', but its value is empty: ", $el_curr->toString() );
                $this = lc( $this );
                if( exists( $boolean_map->{ $this } ) )
                {
                    $is_tender = $boolean_map->{ $this };
                }
                else
                {
                    die( "Value for attribute 'tender' (${this}) for this currency '${curr}' is unsupported. I was expecting either 'true' or 'false': ", $el_curr->toString() );
                }
            }
    
            push( @{$currenciesInfo->{ $code }},
            {
                code        => $code,
                currency    => $curr,
                start       => $from,
                until       => $to,
                is_tender   => $is_tender,
                hist_sequence   => ++$seq,
                is_obsolete => ( defined( $to ) ? 1 : 0 ),
            });
    
            $o++;
        }
        if( defined( $activeCurrency ) )
        {
            $territoryInfo->{ $code }->{currency} = $activeCurrency;
        }
        elsif( exists( $currencyException->{ $code } ) )
        {
            $territoryInfo->{ $code }->{currency} = $currencyException->{ $code };
        }
        else
        {
            die( "No active currency found for this territory '${code}'" );
        }
        $out->print( "ok\n" ) if( $DEBUG );
        $n++;
    }
    &log( "${n} territory currencies pre-loaded for ${o} historical records" );
    
    # NOTE: Pre-loading BCP47 calendar names
    &log( "Pre-loading BCP47 calendar names." );
    $n = 0;
    my $bcp_calendar_file = $basedir->child( 'bcp47/calendar.xml' );
    my $calDom = load_xml( $bcp_calendar_file );
    my $calRes = $calDom->findnodes( '//keyword/key[@name="ca"]/type' ) ||
        die( "Failed to get nodes for BCP calendars" );
    my $cals_names = {};
    while( my $el = $calRes->shift )
    {
        # <type name="japanese" description="Japanese Imperial calendar"/>
        my $id = $el->getAttribute( 'name' ) ||
            die( "Unable to get the attribute 'name' for this BCP47 calendar: ", $el->toString() );
        my $desc = $el->getAttribute( 'description' ) ||
            die( "Unable to get the attribute 'description' for this BCP47 calendar: ", $el->toString() );
        $cals_names->{ $id } = $desc;
        $out->print( "[${id}] ${desc}\n" ) if( $DEBUG );
    }
    
    # NOTE: Loading calendars
    &log( "Loading calendars." );
    $n = 0;
    my $era_n = 0;
    my $calendarRes = $suppDoc->findnodes( '//calendarData/calendar' ) ||
        die( "Unable to get the calendar information in ${supplemental_data_file}" );
    if( !$calendarRes->size )
    {
        die( "No calendar information was found in ${supplemental_data_file}" );
    }
    $sth = $sths->{calendars} || die( "No SQL statement object for calendars" );
    my $sth_era = $sths->{calendar_eras} || die( "No SQL statement object for calendar_eras" );
    # Used to check the calendar associated with a territory actually exists
    my $calendars = {};
    while( my $el = $calendarRes->shift )
    {
        my $calendar = $el->getAttribute( 'type' ) ||
            die( "No attribute value for 'type' in this calendar element: ", $el->toString() );
        $calendars->{ $calendar }++;
        $out->print( "[${calendar}] " ) if( $DEBUG );
        my $def =
        {
            calendar => $calendar,
        };
        # <calendar type="generic"/> has no child node
        if( $el->hasChildNodes )
        {
            if( my $calSys = $el->findnodes( './calendarSystem/@type' )->shift )
            {
                $def->{system} = $calSys->getValue();
            }
            # Example: Japanese calendar -> <inheritEras calendar="gregorian" />
            if( my $inheritRes = $el->findnodes( './inheritEras[@calendar]' )->shift )
            {
                $def->{inherits} = $inheritRes->getAttribute( 'calendar' );
            }
        }
    
        if( exists( $cals_names->{ $def->{calendar} } ) )
        {
            $def->{description} = $cals_names->{ $def->{calendar} };
        }
    
        eval
        {
            $sth->execute( @$def{qw( calendar system inherits description )} );
        } || die( "Error adding data for calendar code '${calendar}': ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
    
        my $erasRes = $el->findnodes( './eras/era[@type]' );
        if( $erasRes->size )
        {
            my $data = [];
            while( my $el_era = $erasRes->shift )
            {
                my $def_era =
                {
                    calendar    => $calendar,
                    sequence    => $el_era->getAttribute( 'type' ),
                    code        => $el_era->getAttribute( 'code' ),
                    aliases     => $el_era->getAttribute( 'aliases' ),
                    start       => $el_era->getAttribute( 'start' ),
                    until       => $el_era->getAttribute( 'end' ),
                };
                if( !defined( $def_era->{sequence} ) ||
                    !length( $def_era->{sequence} ) )
                {
                    die( "No sequence is defined for this era of the calendar '", ( $def_era->{calendar} // 'undef' ), "': ", $el_era->toString() );
                }
                $def_era->{aliases} = [split( /[[:blank:]\h\v]+/, $def_era->{aliases} )] if( defined( $def_era->{aliases} ) );
                eval
                {
                    $sth_era->execute( @$def_era{qw( calendar sequence code )}, to_array( $def_era->{aliases} ), @$def_era{qw( start until )} );
                } || die( "Error adding data for calendar era sequence '", ( $def_era->{sequence} // 'undef' ), "': ", ( $@ || $sth_era->errstr ), "\n", $el_era->toString(), "\n", dump( $def_era ) );
                $era_n++;
            }
        }
        $out->print( "ok\n" ) if( $DEBUG );
    }
    &log( "${n} calendars and ${era_n} eras added." );
    $sth_era->finish;
    
    # NOTE: Adding some more calendars from main/en.xml
    &log( "Adding some more calendars from main/en.xml" );
    $n = 0;
    my $en_file = $main_dir->child( 'en.xml' ) || die( "Unable to get the file object for $main_dir/en.xml" );
    my $enDom = load_xml( $en_file );
    my $enCalendarsRes = $enDom->findnodes( '/ldml/localeDisplayNames/types/type[@key="calendar"]' );
    &log( sprintf( "\t%d calendars found in main/en.xml", $enCalendarsRes->size ) );
    while( my $el = $enCalendarsRes->shift )
    {
        my $calendar = $el->getAttribute( 'type' ) || die( "Unable to get the calendar ID for locale en in file ${en_file} for this element: ", $el->toString() );
        next if( exists( $calendars->{ $calendar } ) );
        $out->print( "\tAdding missing calendar ID ${calendar}: " ) if( $DEBUG );
        my $def =
        {
            calendar    => $calendar,
            description => trim( $el->textContent ),
        };
        eval
        {
            $sth->execute( @$def{qw( calendar system inherits description )} );
        } || die( "Error adding data for calendar code '${calendar}': ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
        $out->print( "ok\n" ) if( $DEBUG );
        $calendars->{ $calendar }++;
        $n++;
    }
    &log( "${n} additional calendar IDs added." );
    
    # NOTE: Loading territories calendars preferences
    &log( "Loading territories calendars preferences." );
    $n = 0;
    my $calPrefsRes = $suppDoc->findnodes( '//calendarPreferenceData/calendarPreference' ) ||
        die( "Unable to get calendar preferences information in ${supplemental_data_file}" );
    if( !$calPrefsRes->size )
    {
        die( "No calendar preferences information found in ${supplemental_data_file}" );
    }
    while( my $el = $calPrefsRes->shift )
    {
        my $codes = $el->getAttribute( 'territories' ) ||
            die( "No attribute 'territories' found for this calendar preferences element: ", $el->toString() );
        my $cals = $el->getAttribute( 'ordering' ) ||
            die( "No attribute 'ordering' found for this calendar preferences element: ", $el->toString() );
        foreach( $codes, $cals )
        {
            $_ = [split( /[[:blank:]\h\v]+/, $_ )];
        }
    
        # Check calendars actually exist
        foreach my $cal ( @$cals )
        {
            if( !exists( $calendars->{ $cal } ) )
            {
                die( "Calendar '${cal}' is unknown. Used in element: ", $el->toString() );
            }
        }
    
        foreach my $code ( @$codes )
        {
            # 'World' is used to define a default value. That default value is set in the SQL schema
            # if( $code eq '001' )
            # {
            #     next;
            # }
            # elsif( !exists( $territoryInfo->{ $code } ) )
            if( !exists( $territoryInfo->{ $code } ) )
            {
                die( "Calendar preference for territory '${code}', but this territory is not defined in CLDR." );
            }
            $territoryInfo->{ $code }->{calendars} = $cals;
            $n++;
        }
    }
    &log( "${n} territories were associated calendar preferences. The rest defaults to 'gregorian'" );
    
    # NOTE: Loading week data
    &log( "Loading week data." );
    my $week_map =
    [
        { xpath => '//weekData/minDays', attribute => 'count', property => 'min_days' },
        { xpath => '//weekData/firstDay', attribute => 'day', property => 'first_day' },
        { xpath => '//weekData/weekendStart', attribute => 'day', property => 'weekend', is_array => 1 },
        { xpath => '//weekData/weekendEnd', attribute => 'day', property => 'weekend', is_array => 1 },
    ];
    my $day_map =
    {
        mon => 1,
        tue => 2,
        wed => 3,
        thu => 4,
        fri => 5,
        sat => 6,
        sun => 7,
    };
    foreach my $def ( @$week_map )
    {
        my $data = $def->{data};
        my $weekRes = $suppDoc->findnodes( $def->{xpath} ) ||
            die( "Unable to get week data for xpath $def->{xpath} in ${supplemental_data_file}" );
        if( !$weekRes->size )
        {
            die( "No week data found for xpath $def->{xpath} in ${supplemental_data_file}" );
        }
        while( my $el = $weekRes->shift )
        {
            # Ignore an exception made just for one case....
            # <firstDay day="sun" territories="GB" alt="variant" references="Shorter Oxford Dictionary (5th edition, 2002)"/>
            if( $el->hasAttribute( 'alt' ) )
            {
                next;
            }
            my $val = $el->getAttribute( $def->{attribute} ) ||
                die( "No attribute value '$def->{attribute}' for this element: ", $el->toString() );
            if( exists( $day_map->{ lc( $val ) } ) )
            {
                $val = $day_map->{ lc( $val ) };
            }
            my $codes = $el->getAttribute( 'territories' ) ||
                die( "No attribute value 'territories' for this element: ", $el->toString() );
            $codes = trim( $codes );
            $codes = [split( /[[:blank:]\h\v]+/, $codes )];
            foreach my $code ( @$codes )
            {
                # This is used by CLDR to define the default value, and we define the default value in the SQL schema
                # next if( $code eq '001' );
                if( !exists( $territoryInfo->{ $code } ) )
                {
                    die( "Unknown territory code '${code}' for this element: ", $el->toString() );
                }
                elsif( exists( $def->{property} ) )
                {
                    if( $def->{is_array} )
                    {
                        unless( exists( $territoryInfo->{ $code }->{ $def->{property} } ) &&
                                ref( $territoryInfo->{ $code }->{ $def->{property} } ) eq 'ARRAY' )
                        {
                            $territoryInfo->{ $code }->{ $def->{property} } = [];
                        }
                        push( @{$territoryInfo->{ $code }->{ $def->{property} }}, $val );
                    }
                    else
                    {
                        $territoryInfo->{ $code }->{ $def->{property} } = $val;
                    }
                }
                else
                {
                    die( "No property value set for this week data in our internal map!" );
                }
            }
        }
    }
    
    # NOTE: Loadding missing territories from the known territories dictionary
    &log( "Loadding missing territories from the known territories dictionary." );
    $n = 0;
    foreach my $code ( sort( keys( %{$known->{territories}} ) ) )
    {
        $out->print( "[${code}] " ) if( $DEBUG );
        if( exists( $territoryInfo->{ $code } ) )
        {
            if( $territoryInfo->{ $code }->{status} )
            {
                if( $territoryInfo->{ $code }->{status} ne $known->{territories}->{ $code }->{status} )
                {
                    die( "A status with value '", $territoryInfo->{ $code }->{status}, " is already set for territory '${code}', but it does not match with that from the known territories dictionary: '", $known->{territories}->{ $code }->{status}, "'" );
                }
            }
            else
            {
                $territoryInfo->{ $code }->{status} = $known->{territories}->{ $code }->{status};
                $out->print( "ok, status set.\n" ) if( $DEBUG );
            }
        }
        else
        {
            $territoryInfo->{ $code } = $known->{territories}->{ $code };
            $territoryInfo->{ $code }->{territory} = $code;
            $out->print( "ok, added missing\n" ) if( $DEBUG );
            $n++;
        }
    }
    &log( sprintf( "%d territories missing (%.2f%%) added out of %d\n", $n, ( ( $n / scalar( keys( %{$known->{territories}} ) ) ) * 100 ), scalar( keys( %{$known->{territories}} ) ) ) );
    
    # NOTE: Loading possible additional territories from the locale data files
    &log( "Loading possible additional territories from the locale data files." );
    $n = 0;
    my $territoriesFromLocaleDataRes = $engLocaleDoc->findnodes( '//localeDisplayNames/territories/territory' ) ||
        die( "Unable to get territories data from locale data file ${eng_locale_data_file}" );
    &log( sprintf( "Processing %d territories from ${eng_locale_data_file}", $territoriesFromLocaleDataRes->size ) );
    while( my $el = $territoriesFromLocaleDataRes->shift )
    {
        # Example: <territory type="JP">Japan</territory>
        my $code = $el->getAttribute( 'type' ) ||
            die( "Unable to get the territory code from the 'type' attribute in this element: ", $el->toString() );
        if( !exists( $territoryInfo->{ $code } ) )
        {
            $territoryInfo->{ $code } = { territory => $code };
            $n++;
        }
    }
    &log( "${n} additional territories added to known territories." );
    
    my $territory_parent_lookup = sub
    {
        my $code = shift( @_ );
        # We sort so we get the 3-digits regions first
        foreach my $region ( sort( keys( %$territoryInfo ) ) )
        {
            my $def = $territoryInfo->{ $region };
            if( exists( $def->{contains} ) &&
                defined( $def->{contains} ) &&
                ref( $def->{contains} ) eq 'ARRAY' )
            {
                if( scalar( grep( $_ eq $code, @{$def->{contains}} ) ) )
                {
                    return( $region );
                }
            }
        }
        return;
    };
    
    # NOTE: Loading territories
    &log( "Loading territories." );
    $n = 0;
    $sth = $sths->{territories} || die( "No SQL statement object for territories" );
    foreach my $code ( sort( keys( %$territoryInfo ) ) )
    {
        my $def = $territoryInfo->{ $code };
        # This territory languages sorted by usage popularity
        # Too unreliable
        # my $langs = [sort{ $def->{language_population}->{ $b }->{population_percent} <=> $def->{language_population}->{ $a }->{population_percent} } keys( %{$def->{language_population}} )];
        # A private property in which we stored the language in the order it was in the XML file
        my $langs = $def->{_langs};
        $out->print( "[${code}] " ) if( $DEBUG );
        if( !defined( $def->{parent} ) ||
            !length( $def->{parent} // '' ) )
        {
            my $region = $territory_parent_lookup->( $code );
            if( defined( $region ) )
            {
                $def->{parent} = $region;
                $out->print( "parent set to ${region} " ) if( $DEBUG );
            }
            else
            {
                $out->print( "no parent region found " ) if( $DEBUG );
            }
        }
        eval
        {
            $code = sprintf( '%03d', $code ) if( $code =~ /^\d{1,2}$/ );
            $def->{parent} = sprintf( '%03d', $def->{parent} ) if( defined( $def->{parent} ) && $def->{parent} =~ /^\d{1,2}$/ );
            $sth->bind_param( 1, "$code", SQL_VARCHAR );
            $sth->bind_param( 2, $def->{parent}, SQL_VARCHAR );
            $sth->bind_param( 3, $def->{gdp}, SQL_INTEGER );
            $sth->bind_param( 4, $def->{literacy_percent}, SQL_FLOAT );
            $sth->bind_param( 5, $def->{population}, SQL_INTEGER );
            $sth->bind_param( 6, to_array( $langs ), SQL_VARCHAR );
            $sth->bind_param( 7, to_array( $def->{contains} ), SQL_VARCHAR );
            $sth->bind_param( 8, $def->{currency}, SQL_VARCHAR );
            $sth->bind_param( 9, to_array( $def->{calendars} ), SQL_VARCHAR );
            $sth->bind_param( 10, $def->{min_days}, SQL_INTEGER );
            $sth->bind_param( 11, $def->{first_day}, SQL_INTEGER );
            $sth->bind_param( 12, to_array( $def->{weekend} ), SQL_VARCHAR );
            $sth->bind_param( 13, $def->{status}, SQL_VARCHAR );
            $sth->execute; 
        } || die( "Error adding data for country code '${code}': ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
        $out->print( "ok\n" ) if( $DEBUG );
        $n++;
    }
    &log( "${n} territories added." );
    
    # NOTE: Loading territories currency historical data
    &log( "Loading territories currency historical data." );
    $n = 0;
    $o = 0;
    $sth = $sths->{currencies_info} || die( "No SQL statement object for currencies_info" );
    foreach my $code ( sort( keys( %$currenciesInfo ) ) )
    {
        $n++;
        for( my $i = 0; $i < scalar( @{$currenciesInfo->{ $code }} ); $i++ )
        {
            my $def = $currenciesInfo->{ $code }->[$i];
            eval
            {
                $sth->execute( @$def{qw( code currency start until is_tender hist_sequence is_obsolete )} );
            } || die( "Error adding currency historical data for currency code '$def->{currency}' and territory code '${code}': ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
            $o++;
        }
    }
    &log( "${n} territory currencies added for ${o} historical records" );
    
    # NOTE: Pre-loading language information
    &log( "Pre-loading language information." );
    my $languageDataRes = $suppDoc->findnodes( '//languageData/language' ) ||
        die( "Unable to get language information in ${supplemental_data_file}" );
    if( !$languageDataRes->size )
    {
        die( "No language information found in ${supplemental_data_file}" );
    }
    my $known_langs = {};
    while( my $el = $languageDataRes->shift )
    {
        my $lang = $el->getAttribute( 'type' ) ||
            die( "No type attribute set for this language tag" );
        my $def =
        {
            language => $lang,
            territories => [split( /[[:blank:]\h\v]+/, ( $el->getAttribute( 'territories' ) || '' ) )],
            scripts => [split( /[[:blank:]\h\v]+/, ( $el->getAttribute( 'scripts' ) || '' ) )],
            alt => $el->getAttribute( 'alt' ),
        };
        if( exists( $known_langs->{ $lang } ) )
        {
            if( !$def->{alt} && !$known_langs->{ $lang }->{alt} )
            {
                die( "Redefining language '${lang}', but neither the previous entry nor this one has an 'alt' attribute set, which would normally make them distinctive. Previous entry: ", dump( $known_langs->{ $lang } ), "\nCurrent entry: ", dump( $def ) );
            }
            $known_langs->{ $lang } = [$known_langs->{ $lang }];
            push( @{$known_langs->{ $lang }}, $def );
        }
        else
        {
            $known_langs->{ $lang } = $def;
        }
    
        my $hasScripts = scalar( @{$def->{scripts}} );
        if( scalar( @{$def->{territories}} ) )
        {
            foreach my $territory ( @{$def->{territories}} )
            {
                if( $hasScripts )
                {
                    foreach my $sc ( @{$def->{scripts}} )
                    {
                        $known_locales->{ "${lang}-${sc}-${territory}" } = { locale => "${lang}-${sc}-${territory}" };
                    }
                }
                else
                {
                    $known_locales->{ "${lang}-${territory}" } = { locale => "${lang}-${territory}" };
                }
            }
        }
        elsif( $hasScripts )
        {
            foreach my $sc ( @{$def->{scripts}} )
            {
                $known_locales->{ "${lang}-${sc}" } = { locale => "${lang}-${sc}" };
            }
        }
        else
        {
            $known_locales->{ $lang } = { locale => $lang };
        }
    }
    
    # NOTE: Adding missing languages
    &log( "Adding missing languages." );
    $n = 0;
    foreach my $code ( sort( keys( %{$known->{languages}} ) ) )
    {
        $out->print( "[${code}] " ) if( $DEBUG );
        if( !exists( $known_langs->{ $code } ) )
        {
            $known_langs->{ $code } = { language => $code };
            $n++;
            $out->print( "added." ) if( $DEBUG );
        }
        if( ref( $known_langs->{ $code } ) eq 'ARRAY' )
        {
            foreach my $this ( @{$known_langs->{ $code }} )
            {
                $this->{status} = $known->{languages}->{ $code }->{status};
            }
        }
        else
        {
            $known_langs->{ $code }->{status} = $known->{languages}->{ $code }->{status};
        }
        $out->print( "\n" ) if( $DEBUG );
    }
    &log( sprintf( "%d languages added (%.2f%%) out of %d", $n, ( ( $n / scalar( keys( %{$known->{languages}} ) ) ) * 100 ), scalar( keys( %{$known->{languages}} ) ) ) );
    
    # NOTE: Processing language groups to derive parent (iso-639-5)
    &log( "Processing language groups to derive parent (iso-639-5)." );
    # See <https://www.loc.gov/standards/iso639-5/id.php>
    $n = 0;
    my $lang_group_file = $basedir->child( 'supplemental/languageGroup.xml' );
    my $langGroupDoc = load_xml( $lang_group_file );
    my $langGroupRes = $langGroupDoc->findnodes( '/supplementalData/languageGroups/languageGroup[@parent]' ) ||
        die( "Unable to get language groups from ${lang_group_file}" );
    &log( $langGroupRes->size, " language groups found." );
    while( my $el = $langGroupRes->shift )
    {
        my $parent = $el->getAttribute( 'parent' );
        my $data = trim( $el->textContent );
        my $langs = [split( /[[:blank:]\h\v]+/, $data )];
        foreach my $lang ( @$langs )
        {
            if( exists( $known_langs->{ $lang } ) )
            {
                if( ref( $known_langs->{ $lang } ) eq 'ARRAY' )
                {
                    foreach my $this ( @{$known_langs->{ $lang }} )
                    {
                        $this->{parent} = $parent;
                    }
                }
                else
                {
                    $known_langs->{ $lang }->{parent} = $parent;
                }
                $n++;
            }
            else
            {
                die( "Unknown language found \"${lang}\" with parent \"${parent}\". This means it did not exist in ", $known_data->{languages}->{file} );
            }
        }
    }
    &log( "${n} languages allocated a parent." );
    
    # NOTE: Loading language information
    &log( "Loading language information." );
    $n = 0;
    $sth = $sths->{languages} || die( "No SQL statement object for languages" );
    foreach my $lang ( sort( keys( %$known_langs ) ) )
    {
        $out->print( "[${lang}] " ) if( $DEBUG );
        # my $def = $known_langs->{ $lang };
        my $defs = ref( $known_langs->{ $lang } ) eq 'ARRAY' ? $known_langs->{ $lang } : [$known_langs->{ $lang }];
        foreach my $def ( @$defs )
        {
            eval
            {
                $sth->execute( $lang, to_array( $def->{scripts} ), to_array( $def->{territories} ), @$def{qw( parent alt status )} );
            } || die( "Error adding data for language '${lang}': ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
        }
        $out->print( "ok\n" ) if( $DEBUG );
        $n++;
    }
    &log( "${n} languages added." );
    
    my $possibly_missing =
    {
        'zh-Hant-TW' => { language => 'zh', scripts => ['Hant'], territories => ['TW'] },
        'zh-TW' => { language => 'zh', territories => ['TW'] },
        'zh-HK' => { language => 'zh', territories => ['HK'] },
        'zh-MO' => { language => 'zh', territories => ['MO'] },
        'zh-SG' => { language => 'zh', territories => ['SG'] },
    };
    
    # NOTE: Adding possibly missing languages
    &log( "Adding possibly missing languages." );
    $n = 0;
    foreach my $lang ( sort( keys( %$possibly_missing ) ) )
    {
        my $def = $possibly_missing->{ $lang };
        $out->print( "[${lang}] " ) if( $DEBUG );
        eval
        {
            $sth->execute( $def->{language}, to_array( $def->{scripts} ), to_array( $def->{territories} ), @$def{qw( parent alt status )} );
        } || die( "Error adding additional language '${lang}': ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
        $out->print( "ok\n" ) if( $DEBUG );
        $n++ if( $sth->rows );
        $known_locales->{ $lang } = { locale => $lang };
    }
    &log( "${n} additional languages added." );
    
    # NOTE: Loading known locales
    &log( "Loading known locales" );
    my $supp_meta_file = $basedir->child( 'supplemental/supplementalMetadata.xml' );
    my $metaDoc = load_xml( $supp_meta_file );
    my $metaDefaultLangsRes = $metaDoc->findnodes( '/supplementalData/metadata/defaultContent/@locales' )->shift ||
        die( "Unable to get the known locales in ${supp_meta_file}" );
    my $default_locales = trim( $metaDefaultLangsRes->getValue() );
    my @defaultLangs = split( /[[:blank:]\h\v]+/, $default_locales );
    scalar( @defaultLangs ) || die( "No default locales found in file $supp_meta_file" );
    foreach my $locale ( @defaultLangs )
    {
        $locale =~ tr/_/-/;
        # Should not be needed but better safe than sorry
        if( index( $locale, 'root' ) != -1 )
        {
            if( length( $locale ) > 4 )
            {
                my $loc = Locale::Unicode->new( $locale );
                $loc->language( 'und' );
                $locale = $loc->as_string;
            }
            else
            {
                $locale = 'und';
            }
        }
        $known_locales->{ $locale } = { locale => $locale };
    }
    
    # NOTE: Adding more locales from the known languages
    &log( "Adding more locales from the known languages." );
    $n = 0;
    foreach my $code ( sort( keys( %{$known->{languages}} ) ) )
    {
        if( !exists( $known_locales->{ $code } ) )
        {
            $known_locales->{ $code } = { locale => $code };
            $n++;
        }
        $known_locales->{ $code }->{status} = $known->{languages}->{ $code }->{status};
    }
    &log( sprintf( "%d languages were added as locales (%.2f%%) out of %d", $n, ( ( $n / scalar( keys( %{$known->{languages}} ) ) ) * 100 ), scalar( keys( %{$known->{languages}} ) ) ) );
    
    # NOTE: Adding even more locales from the locale data files
    &log( "Adding even more locales from the locale data files." );
    $n = 0;
    my $localesFromLocaleDataRes = $engLocaleDoc->findnodes( '//localeDisplayNames/languages/language' ) ||
        die( "Unable to get locales data from locale data file ${eng_locale_data_file}" );
    &log( sprintf( "Processing %d locales from ${eng_locale_data_file}", $localesFromLocaleDataRes->size ) );
    while( my $el = $localesFromLocaleDataRes->shift )
    {
        # Example: <language type="ja">Japanese</language>
        my $code = $el->getAttribute( 'type' ) ||
            die( "Unable to get the locale from the 'type' attribute in this element: ", $el->toString() );
        $code =~ tr/_/-/;
        if( !exists( $known_locales->{ $code } ) )
        {
            $known_locales->{ $code } = { locale => $code };
            $n++;
        }
    }
    &log( "${n} additional locales added to known locales." );
    
    # NOTE: Adding possibly missing locales from the the main identities
    &log( "Adding possibly missing locales from the the main identities." );
    $n = 0;
    $main_dir->open || die( $main_dir->error );
    # while( my $f = $main_dir->read( as_object => 1, exclude_invisible => 1 ) )
    @files = $main_dir->read( as_object => 1, exclude_invisible => 1, 'sort' => 1 );
    foreach my $f ( @files )
    {
        next unless( $f->extension eq 'xml' );
        my $basename = $f->basename;
        my $mainDoc = load_xml( $f );
        my $locale = identity_to_locale( $mainDoc );
        ( my $locale2 = $f->basename( '.xml' ) ) =~ tr/_/-/;
        if( lc( $locale ) ne lc( $locale2 ) &&
            $locale2 ne 'root' )
        {
            warn( "XML identity says the locale is '${locale}', but the file basename says it should be '${locale2}', and I think the file basename is correct for file $f" );
            $locale = $locale2;
        }
        if( index( $locale, 'root' ) != -1 )
        {
            if( length( $locale ) > 4 )
            {
                my $loc = Locale::Unicode->new( $locale );
                $loc->language( 'und' );
                $locale = $loc->as_string;
            }
            else
            {
                $locale = 'und';
            }
        }
        $out->print( "[${basename}] -> ${locale} " ) if( $DEBUG );
        if( !exists( $known_locales->{ $locale } ) )
        {
            $known_locales->{ $locale } = { locale => $locale };
            $out->print( "added." ) if( $DEBUG );
            $n++;
        }
        $out->print( "\n" ) if( $DEBUG );
    }
    &log( "${n} additional locales added to known locales." );
    $main_dir->close;
    
    # NOTE: Adding parent information to locales
    &log( "Adding parent information to locales." );
    my $localesParentsRes = $suppDoc->findnodes( '/supplementalData/parentLocales/parentLocale' );
    if( !$localesParentsRes->size )
    {
        die( "No locale parent information found in supplemental data file ${supplemental_data_file} in xpath /supplementalData/parentLocales/parentLocale" );
    }
    $n = 0;
    while( my $el = $localesParentsRes->shift )
    {
        my $parent = $el->getAttribute( 'parent' ) ||
            die( "No 'parent' value found in attribute 'parent' for this locale parent in element: ", $el->toString );
        # Standardise the locale as per the standard
        $parent =~ tr/_/-/;
        if( index( $parent, 'root' ) != -1 )
        {
            if( length( $parent ) > 4 )
            {
                my $loc = Locale::Unicode->new( $parent );
                $loc->language( 'und' );
                $parent = $loc->as_string;
            }
            else
            {
                $parent = 'und';
            }
        }
        my $locales = $el->getAttribute( 'locales' ) ||
            die( "No list of locales associated with parent ${parent} found in attribute 'locales' for this locale parent in element: ", $el->toString );
        $locales = trim( $locales );
        $locales = [split( /[[:blank:]\h]+/, $locales )];
        $out->printf( "[${parent}] for %d child locales ", scalar( @$locales ) ) if( $DEBUG );
        foreach my $locale ( @$locales )
        {
            # Standardise the locale as per the standard
            $locale =~ tr/_/-/;
            if( index( $locale, 'root' ) != -1 )
            {
                if( length( $locale ) > 4 )
                {
                    my $loc = Locale::Unicode->new( $locale );
                    $loc->language( 'und' );
                    $locale = $loc->as_string;
                }
                else
                {
                    $locale = 'und';
                }
            }
            if( !exists( $known_locales->{ $locale } ) )
            {
                warn( "Warning only: unknown locale '${locale}' (adding it now) to set its parent locale in supplemental data file ${supplemental_data_file} for this element: ", $el->toString );
                $known_locales->{ $locale } = { locale => $locale };
            }
            $known_locales->{ $locale }->{parent} = $parent;
        }
        $out->print( "ok\n" ) if( $DEBUG );
    }

    # NOTE: Adding collations information to locales
    &log( "Adding collations information to locales." );
    $n = 0;
    $collation_dir->open || die( $collation_dir->error );
    # while( my $f = $main_dir->read( as_object => 1, exclude_invisible => 1 ) )
    @files = $collation_dir->read( as_object => 1, exclude_invisible => 1, 'sort' => 1 );
    foreach my $f ( @files )
    {
        next unless( $f->extension eq 'xml' );
        my $basename = $f->basename;
        my $collationDoc = load_xml( $f );
        my $locale = identity_to_locale( $collationDoc );
        ( my $locale2 = $f->basename( '.xml' ) ) =~ tr/_/-/;
        if( lc( $locale ) ne lc( $locale2 ) &&
            $locale2 ne 'root' )
        {
            warn( "XML identity says the locale is '${locale}', but the file basename says it should be '${locale2}', and I think the file basename is correct for file $f" );
            $locale = $locale2;
        }
        if( index( $locale, 'root' ) != -1 )
        {
            if( length( $locale ) > 4 )
            {
                my $loc = Locale::Unicode->new( $locale );
                $loc->language( 'und' );
                $locale = $loc->as_string;
            }
            else
            {
                $locale = 'und';
            }
        }
        $out->print( "[${basename}] -> ${locale} " ) if( $DEBUG );
        my $collationTypesRes = $collationDoc->findnodes( '/ldml/collations/collation[@type]' );
        if( !$collationTypesRes->size )
        {
            $out->print( "\tnothing found. This locale inherits collation from root (und)\n" ) if( $DEBUG );
            next;
        }
        my @collations = ();
        while( my $el = $collationTypesRes->shift )
        {
            my $name = $el->getAttribute( 'type' );
            if( !length( $name // '' ) )
            {
                warn( "The locale ${locale} is missing the 'type' attribute for collation in file ${f}." );
                next;
            }
            push( @collations, $name );
        }
        if( !exists( $known_locales->{ $locale } ) )
        {
            $known_locales->{ $locale } = { locale => $locale };
        }
        if( scalar( @collations ) )
        {
            @collations = uniq( @collations );
            $known_locales->{ $locale }->{collations} = \@collations;
            $out->print( "ok" );
            $n++;
        }
        else
        {
            $out->print( "nothing found" );
        }
        $out->print( "\n" ) if( $DEBUG );
    }
    &log( "${n} locales were added collation information." );
    $collation_dir->close;

    $n = 0;
    $sth = $sths->{locales} || die( "No SQL statement object for locales" );
    foreach my $locale ( sort( keys( %$known_locales ) ) )
    {
        my $def =
        {
            locale => $locale,
        };
        if( ref( $known_locales->{ $locale } ) eq 'HASH' )
        {
            $def->{parent} = $known_locales->{ $locale }->{parent};
            $def->{status} = $known_locales->{ $locale }->{status};
        }
        if( exists( $known_locales->{ $locale }->{collations} ) &&
            defined( $known_locales->{ $locale }->{collations} ) &&
            ref( $known_locales->{ $locale }->{collations} ) eq 'ARRAY' )
        {
            $def->{collations} = to_array( $known_locales->{ $locale }->{collations} );
        }
        $out->print( "[${locale}] " ) if( $DEBUG );
        eval
        {
            $sth->execute( @$def{qw( locale parent collations status )} );
        } || die( "Error adding locale '${locale}' to table 'locales': ", ( $@ || $sth->errstr ), "\nfor SQL query $sth->{Statement}", "\n", dump( $def ) );
        $out->print( "ok\n" ) if( $DEBUG );
        $n++;
    }
    &log( "${n} locales added." );
    
    # NOTE: Loading likely subtags
    &log( "Loading likely subtags." );
    my $likely_file = $basedir->child( 'supplemental/likelySubtags.xml' );
    my $likelyDoc = load_xml( $likely_file );
    my $rulesRes = $likelyDoc->findnodes( '//likelySubtags/likelySubtag' ) ||
        die( "Unable to get the likely subtags in ${likely_file}" );
    if( !$rulesRes->size )
    {
        die( "No likely subtags found in ${likely_file}" );
    }
    $sth = $sths->{likely_subtags} || die( "No SQL statement object for likely_subtags" );
    # This is going to take some memory...
    my $likely = {};
    $n = 0;
    while( my $el = $rulesRes->shift )
    {
        my $locale = $el->getAttribute( 'from' ) || die( "No 'from' attribute found!" );
        my $target = $el->getAttribute( 'to' ) || die( "No 'to' attribute found!" );
        my $this = $el->nextNonBlankSibling;
        my $comment;
        # Example: <!--{ Japanese; ?; ? } => { Japanese; Japanese; Japan }-->
        if( $this && $this->isa( 'XML::LibXML::Comment' ) )
        {
            my $data = $this->data;
            if( $data =~ /\{[[:blank:]\h]*(?<from>[^\}]+)\}[[:blank:]\h]*\=\>[[:blank:]\h]*\{[[:blank:]\h]*(?<to>[^\}]+)\}/ )
            {
                $comment = "from $+{from} to $+{to}";
            }
        }
        $locale =~ tr/_/-/;
        $target =~ tr/_/-/;
        $out->print( "[${locale} -> ${target} ", ( defined( $comment ) ? "($comment) " : '' ) ) if( $DEBUG );
        eval
        {
            $sth->execute( $locale, $target );
        } || die( "Error adding likely subtags rule for locale '${locale}' and target '${target}': ", ( $@ || $sth->errstr ) );
        $out->print( "ok\n" ) if( $DEBUG );
        $n++;
        $likely->{ $locale } = $target;
    }
    
    # Ref: <cldr-common-45.0/common/properties/scriptMetadata.txt>
    # 1 - Web Rank:
    #               The approximate rank of this script from a large sample of the web,
    #               in terms of the number of characters found in that script.
    #               Below 32 the ranking is not statistically significant.
    # 2 - Sample Character:
    #               A sample character for use in "Last Resort" style fonts.
    #               For printing the combining mark for Zinh in a chart, U+25CC can be prepended.
    #               See http://unicode.org/policies/lastresortfont_eula.html
    # 3 - Origin country:
    #               The approximate area where the script originated, expressed as a BCP47 region code.
    # 4 - Density:
    #               The approximate information density of characters in this script, based on comparison of bilingual texts.
    # 5 - ID Usage:
    #               The usage for IDs (tables 4-7) according to UAX #31.
    #               For a description of values, see
    #               http://unicode.org/reports/tr31/#Table_Candidate_Characters_for_Exclusion_from_Identifiers
    # 6 - RTL:
    #               YES if the script is RTL
    #               Derived from whether the script contains RTL letters according to the Bidi_Class property
    # 7 - LB letters:
    #               YES if the major languages using the script allow linebreaks between letters (excluding hyphenation).
    #               Derived from LB property.
    # 8 - Shaping Required:
    #               YES if shaping is required for the major languages using that script for NFC text.
    #                       This includes not only ligation (and Indic conjuncts), Indic vowel splitting/reordering, and
    #                       Arabic-style contextual shaping, but also cases where NSM placement is required, like Thai.
    #               MIN if NSM placement is sufficient, not the more complex shaping.
    #                       The NSM placement may only be necessary for some major languages using the script.
    # 9 - Input Method Engine Required:
    #               YES if the major languages using the script require IMEs.
    #               In particular, users (of languages for that script) would be accustomed to using IMEs (such as Japanese)
    #               and typical commercial products for those languages would need IME support in order to be competitive.
    # 10- Cased
    #               YES if in modern (or most recent) usage case distinctions are customary.
    
    # NOTE: Pre-loading scripts
    &log( "Pre-loading scripts." );
    $n = 0;
    my $scripts_file = $basedir->child( 'properties/scriptMetadata.txt' );
    my $known_scripts = {};
    my $script_fh = $scripts_file->open( '<', { binmode => ':utf8' }) ||
        die( "Unable to open $scripts_file in read mode: ", $scripts_file->error );
    my $bool_map =
    {
        'NO' => 0,
        'YES' => 1,
        'UNKNOWN' => undef,
        'MIN' => 'MIN',
    };
    my @bool_fields = qw( rtl lb_letters has_case shaping_req ime  );
    my @script_fields = qw( script rank sample_char origin_country density id_usage rtl lb_letters shaping_req ime has_case );
    my $lineno = 0;
    while( defined( my $l = $script_fh->getline ) )
    {
        ++$lineno;
        next if( $l =~ /^[[:blank:]\h]*(?:\Z|\#)/ );
        chomp( $l );
        # Remove any possible trailing comment
        $l =~ s/[[:blank:]\h]+\#(?:.*?)$// if( index( $l, '#' ) != -1 );
        my @values = split( /[[:blank:]\h]*\;[[:blank:]\h]*/, $l, -1 );
        # likelyLanguage
        my $def = {};
        @$def{ @script_fields } = @values;
        # Ensure standard formatting
        $def->{script} = ucfirst( lc( $def->{script} ) );
        $out->print( "[$def->{script}] " ) if( $DEBUG );
        if( scalar( @values ) != scalar( @script_fields ) )
        {
            die( "Incorrect number of columns retrieved (", scalar( @values ), ") where ", scalar( @script_fields ), " were expected at line $lineno in file $scripts_file" );
        }
    
        foreach my $bool_field ( @bool_fields )
        {
            if( !defined( $def->{ $bool_field } ) ||
                !length( $def->{ $bool_field } ) )
            {
                $def->{ $bool_field } = undef;
            }
            elsif( exists( $bool_map->{ $def->{ $bool_field } } ) )
            {
                $def->{ $bool_field } = $bool_map->{ $def->{ $bool_field } };
            }
            else
            {
                die( "Unknown value '", $def->{ $bool_field }, "' for boolean field '${bool_field}' for script '$def->{script}' in file ${scripts_file}" );
            }
        }
    
        # Find out the likely language
        my $likely_lang = 'und-' . $def->{script};
        if( exists( $likely->{ $likely_lang } ) )
        {
            $def->{likely_language} = [split( /-/, $likely->{ $likely_lang } )]->[0];
        }
        $known_scripts->{ $def->{script} } = $def;
        $out->print( "ok\n" ) if( $DEBUG );
        $n++;
    }
    &log( "${n} scripts pre-loaded." );
    
    # NOTE: Adding possible missing scripts
    &log( "Adding possible missing scripts." );
    $n = 0;
    foreach my $code ( sort( keys( %{$known->{scripts}} ) ) )
    {
        if( !exists( $known_scripts->{ $code } ) )
        {
            $known_scripts->{ $code } = { script => $code };
            $n++;
        }
        $known_scripts->{ $code }->{status} = $known->{scripts}->{ $code }->{status};
    }
    &log( sprintf( "%d missing scripts added (%.2f%%) out of %d", $n, ( ( $n / scalar( keys( %{$known->{scripts}} ) ) ) * 100 ), scalar( keys( %{$known->{scripts}} ) ) ) );
    
    # NOTE: Adding even more scripts from the locale data files
    &log( "Adding even more scripts from the locale data files." );
    $n = 0;
    my $scriptsFromLocaleDataRes = $engLocaleDoc->findnodes( '//localeDisplayNames/scripts/script' ) ||
        die( "Unable to get scripts data from locale data file ${eng_locale_data_file}" );
    &log( sprintf( "Processing %d scripts from ${eng_locale_data_file}", $scriptsFromLocaleDataRes->size ) );
    while( my $el = $scriptsFromLocaleDataRes->shift )
    {
        # Example: <script type="Jpan">Japanese</script>
        my $code = $el->getAttribute( 'type' ) ||
            die( "Unable to get the script from the 'type' attribute in this element: ", $el->toString() );
        $code = ucfirst( lc( $code ) );
        if( !exists( $known_scripts->{ $code } ) )
        {
            $known_scripts->{ $code } = { script => $code };
            $n++;
        }
    }
    &log( "${n} additional scripts added to known scripts." );
    
    # NOTE: Loading scripts
    &log( "Loading scripts." );
    $sth = $sths->{scripts} || die( "No SQL statement object for scripts" );
    $n = 0;
    foreach my $code ( sort( keys( %$known_scripts ) ) )
    {
        my $def = $known_scripts->{ $code };
        $out->print( "[$def->{script}] " ) if( $DEBUG );
        eval
        {
            $sth->execute( @$def{qw( script rank sample_char id_usage rtl lb_letters has_case shaping_req ime density origin_country likely_language status )} );
        } || die( "Error at line ${lineno} adding script '$def->{script}' information to table 'scripts': ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
        $out->print( "ok\n" ) if( $DEBUG );
        $n++;
    }
    &log( "${n} scripts added." );
    %$known_scripts = ();
    
    # NOTE: Pre-loading variants
    &log( "Pre-loading variants." );
    $n = 0;
    my $known_variants = {};
    my $variantsFromLocaleDataRes = $engLocaleDoc->findnodes( '//localeDisplayNames/variants/variant' ) ||
        die( "Unable to get variants data from locale data file ${eng_locale_data_file}" );
    if( !$variantsFromLocaleDataRes->size )
    {
        die( "No variant nodes found in file ${eng_locale_data_file}" );
    }
    &log( sprintf( "Processing %d variants from ${eng_locale_data_file}", $variantsFromLocaleDataRes->size ) );
    while( my $el = $variantsFromLocaleDataRes->shift )
    {
        # Example: <variant type="VALENCIA">Valencian</variant>
        my $code = $el->getAttribute( 'type' ) ||
            die( "Unable to get the variant from the 'type' attribute in this element: ", $el->toString() );
        $code = lc( $code );
        $known_variants->{ $code } = { variant => $code };
        $n++;
    }
    &log( "${n} variants pre-loaded." );
    
    # NOTE: Adding even more variants from the locale data files
    &log( "Adding even more variants from the locale data files." );
    $n = 0;
    &log( "${n} additional variants added to known variants." );
    
    
    # NOTE: Adding possibly missing variants
    &log( "Adding possibly missing variants." );
    $n = 0;
    foreach my $code ( sort( keys( %{$known->{variants}} ) ) )
    {
        if( !exists( $known_variants->{ $code } ) )
        {
            $known_variants->{ $code } = { variant => $code };
            $n++;
        }
        $known_variants->{ $code }->{status} = $known->{variants}->{ $code }->{status};
    }
    &log( sprintf( "%d missing variants added (%.2f%%) out of %d", $n, ( ( $n / scalar( keys( %{$known->{variants}} ) ) ) * 100 ), scalar( keys( %{$known->{variants}} ) ) ) );
    
    # NOTE: Loading variants
    &log( "Loading variants." );
    $n = 0;
    $sth = $sths->{variants} || die( "No SQL statement object for variants" );
    foreach my $code ( sort( keys( %$known_variants ) ) )
    {
        my $def = $known_variants->{ $code };
        my $status = $def->{status};
        $out->print( "[${code}] " ) if( $DEBUG );
        eval
        {
            $sth->execute( $code, $status );
        } || die( "Error adding variant information for variant '${code}': ", ( $@ || $sth->errstr ) );
        $out->print( "ok\n" ) if( $DEBUG );
        $n++;
    }
    &log( "${n} variants added." );
    %$known_variants = ();
    
    # NOTE: Loading language population
    &log( "Loading language population" );
    $n = 0;
    $sth = $sths->{language_population} || die( "No SQL statement object for language_population" );
    foreach my $code ( sort( keys( %$territoryInfo ) ) )
    {
        my $def = $territoryInfo->{ $code };
        if( !exists( $def->{language_population} ) )
        {
            next;
        }
        elsif( ref( $def->{language_population} ) ne 'HASH' )
        {
            die( "Property 'language_population' value for territory code '${code}' exists, but is not an hash reference in $supplemental_data_file" );
        }
        $out->print( "[${code}] " ) if( $DEBUG );
        my $langpop = $def->{language_population};
        foreach my $locale ( sort{ $langpop->{ $b }->{population_percent} <=> $langpop->{ $a }->{population_percent} } keys( %$langpop ) )
        {
            my $this = $langpop->{ $locale };
            eval
            {
                $sth->execute( $code, $locale, @$this{qw( population_percent literacy_percent writing_percent official_status )} );
            } || die( "Error adding language population information for territory '${code}' and locale '${locale}': ", ( $@ || $sth->errstr ), "\n", dump( $this ) );
            $out->print( "${locale} " ) if( $DEBUG );
            $n++;
        }
        $out->print( "\n" ) if( $DEBUG );
    }
    &log( "${n} language populations added." );
    
    # NOTE: Loading aliases
    &log( "Processing aliases." );
    $sth = $sths->{aliases} || die( "No SQL statement object for aliases" );
    my $alias_map =
    [
        { xpath => '//alias/languageAlias', type => 'language' },
        { xpath => '//alias/scriptAlias', type => 'script' },
        { xpath => '//alias/territoryAlias', type => 'territory' },
        { xpath => '//alias/subdivisionAlias', type => 'subdivision' },
        { xpath => '//alias/variantAlias', type => 'variant' },
        { xpath => '//alias/zoneAlias', type => 'zone' },
    ];
    foreach my $def ( @$alias_map )
    {
        my $type = $def->{type};
        &log( "Loading ${type} aliases." );
        $n = 0;
        my $aliasRes = $metaDoc->findnodes( $def->{xpath} ) ||
            die( "Unable to get ${type} aliases in ${supp_meta_file}" );
        if( !$aliasRes->size )
        {
            die( "No alias ${type} found in ${supp_meta_file}" );
        }
        while( my $el = $aliasRes->shift )
        {
            my $alias = $el->getAttribute( 'type' ) ||
                die( "No 'type' attribute found for this ${type} alias element: ", $el->toString() );
            my $replacement = $el->getAttribute( 'replacement' ) ||
                die( "No 'replacement' attribute found for this ${type} alias element: ", $el->toString() );
            # Normalise
            $replacement =~ tr/_/-/;
            $replacement = [split( /[[:blank:]\h\v]+/, $replacement )];
            my $reason = $el->getAttribute( 'reason' );
            my $comment;
            if( my $this = $el->nextNonBlankSibling )
            {
                if( $this->isa( 'XML::LibXML::Comment' ) )
                {
                    $comment = $this->data;
                    $comment = trim( $comment ) if( defined( $comment ) );
                    $comment = undef if( $comment eq 'null' );
                }
            }
            # Normalise the alias
            $alias =~ tr/_/-/;
            $out->print( "[${type} / ${alias} -> ", join( ', ', @$replacement ), "] ", ( defined( $comment ) ? "(${comment}) " : '' ) ) if( $DEBUG );
            eval
            {
                $sth->execute( $alias, to_array( $replacement ), $reason, $type, $comment );
            } || die( "Error adding alias information for ${type} '${alias}' and replacement '", join( ', ', @$replacement ), "': ", ( $@ || $sth->errstr ) );
            $out->print( "ok\n" ) if( $DEBUG );
            $n++;
        }
        &log( "${n} ${type} aliases added." );
    }
    
    my $zone_file = $basedir->child( 'supplemental/metaZones.xml' );
    my $zoneDoc = load_xml( $zone_file );

    # NOTE: Loading metazones
    &log( "Loading metazones." );
    my $metazonesRes = $zoneDoc->findnodes( '/supplementalData/metaZones/mapTimezones/mapZone[@type]' );
    if( !$metazonesRes->size )
    {
        die( "No metazone data found in file ${zone_file}" );
    }
    $sth = $sths->{metazones} || die( "Unable to get the statement object for table \"metazones\"." );
    my $metazones = {};
    # <mapZone other="Acre" territory="001" type="America/Rio_Branco"/>
    while( my $el = $metazonesRes->shift )
    {
        my $id = $el->getAttribute( 'other' ) || die( "Unable to get the metazone from the attribute 'other' for this element: ", $el->toString() );
        my $territory = $el->getAttribute( 'territory' );
        my $timezone = $el->getAttribute( 'type' );
        $metazones->{ $id } ||= 
        {
            metazone => $id,
            territories => [],
            timezones => [],
        };
        push( @{$metazones->{ $id }->{territories}}, $territory );
        push( @{$metazones->{ $id }->{timezones}}, $timezone );
    }
    foreach my $zone ( sort( keys( %$metazones ) ) )
    {
        my $def = $metazones->{ $zone };
        eval
        {
            $sth->execute( $def->{metazone}, to_array( $def->{territories} ), to_array( $def->{timezones} ) );
        } || die( "Error adding metazone information for metazone '$def->{metazone}': ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
    }

    # NOTE: Loading the IANA Olson time zone database
    &log( "Loading the IANA Olson time zone database." );
    # Those time zones have the territory set to 001, because the CLDR misuses that property to flag them as "golden" time zones. We instead set a 'is_golden' field in the timezones table
    my $tz_corrections = {};
    if( $cache_tz_corrections_file->exists )
    {
        &log( "Loading time zones corrections from cache file ${cache_tz_corrections_file}" );
        $tz_corrections = $cache_tz_corrections_file->load_json ||
            die( $cache_tz_corrections_file->error );
    }
    else
    {
        &log( "Computing time zones corrections." );
        my $iana_tzdb_alias = {};
        my $iana_tzdb_map = {};
        my $fh = $iana_alias_file->open( '<', { binmode => ':utf8' }) ||
            die( $iana_alias_file->error );
        while( defined( $_ = $fh->getline ) )
        {
            chomp;
            next if( /^[[:blank:]\h]*(?:\Z|\#)/ );
            my( $dummy, $from, $to, $comment ) = split( /[[:blank:]\h]+/, $_ );
            $out->print( "Aliasing ${from} -> ${to}\n" ) if( $DEBUG );
            $iana_tzdb_alias->{ $to } = $from;
        }
        $fh = $iana_timezone_file->open( '<', { binmode => ':utf8' }) ||
            die( $iana_timezone_file->error );
        local $" = ', ';
        while( defined( $_ = $fh->getline ) )
        {
            chomp;
            next if( /^[[:blank:]\h]*(?:\Z|\#)/ );
            my( $codes, $coordinates, $tz, $comment ) = split( /[[:blank:]\h]+/, $_ );
            $codes = [split( /\,/, $codes )];
            $out->print( "[${tz}] -> @$codes\n" ) if( $DEBUG );
            foreach my $code ( @$codes )
            {
                $iana_tzdb_map->{ $tz } = $code;
            }
        }
        $fh->close;
        
        my $worldTerritoriesRes = $zoneDoc->findnodes( '/supplementalData/metaZones/mapTimezones/mapZone[@territory="001"]' );
        $out->printf( "Found %d time zones with incorrect territories.\n", $worldTerritoriesRes->size ) if( $DEBUG );
        while( my $el = $worldTerritoriesRes->shift )
        {
            # Example: <mapZone other="Acre" territory="001" type="America/Rio_Branco"/>
            my $tz = $el->getAttribute( 'type' ) ||
                die( "Unable to get the 'type' attribute for this mapZone element: ", $el->toString() );
            if( !exists( $iana_tzdb_map->{ $tz } ) )
            {
                if( exists( $iana_tzdb_alias->{ $tz } ) &&
                    exists( $iana_tzdb_map->{ $iana_tzdb_alias->{ $tz } } ) )
                {
                    warn( "No value found for time zone ${tz}, but found in alias: ${tz} -> ", $iana_tzdb_alias->{ $tz } );
                    $tz_corrections->{ $tz } = $iana_tzdb_map->{ $iana_tzdb_alias->{ $tz } };
                    next;
                }
                else
                {
                    warn( "No value found for time zone ${tz}" );
                }
            }
            $tz_corrections->{ $tz } = $iana_tzdb_map->{ $tz };
        }
        $cache_tz_corrections_file->unload_json( $tz_corrections => {
            pretty => 1,
            canonical => 1,
        }) || die( $cache_tz_corrections_file->error );
    }
    &log( sprintf( "%d time zone corrections loaded.", scalar( keys( %$tz_corrections ) ) ) );
    
    # NOTE: Building map of territory name to territory code
    &log( "Building map of territory name to territory code." );
    my $engTerritoriesRes = $engLocaleDoc->findnodes( '//localeDisplayNames/territories/territory' ) ||
        die( "Unable to get the nodes of English territories names from ${eng_locale_data_file}" );
    &log( sprintf( "%d English locale territories names found.", $engTerritoriesRes->size ) );
    my $eng_territories_names_to_code = {};
    while( my $el = $engTerritoriesRes->shift )
    {
        # Example: <territory type="AQ">Antarctica</territory>
        my $code = $el->getAttribute( 'type' ) ||
            die( "Unable to get the territory code from attribute 'type' for this element: ", $el->toString() );
        my $name = $el->textContent;
        if( !defined( $name ) ||
            !length( $name ) )
        {
            die( "Territory name for '${code}' is empty: ", $el->toString() );
        }
        if( index( $name, '&' ) != -1 )
        {
            $name = decode_entities( $name );
        }
        if( exists( $eng_territories_names_to_code->{ $name } ) )
        {
            # This is a variation, which we ignore.
            if( $el->hasAttribute( 'alt' ) )
            {
                next;
            }
            else
            {
                die( "Found another territory (", $eng_territories_names_to_code->{ $name }, ") with the same name '${name}' for our code '${code}'" );
            }
        }
        $eng_territories_names_to_code->{ $name } = $code;
    }
    
    # NOTE: Pre-loading time zones
    &log( "Pre-loading time zones." );
    $n = 0;
    my $tzMapRes = $zoneDoc->findnodes( '//metaZones/mapTimezones/mapZone' ) ||
        die( "Unable to get the map timezones in ${zone_file}" );
    if( !$tzMapRes->size )
    {
        die( "No map timezones found in ${zone_file}" );
    }
    my $metazoneIdsRes = $zoneDoc->findnodes( '//metaZones/metazoneIds/metazoneId' ) ||
        die( "Unable to get the timezone IDs in ${zone_file}" );
    if( !$metazoneIdsRes->size )
    {
        die( "No timezone IDs found in ${zone_file}" );
    }
    my $primaryZonesRes = $zoneDoc->findnodes( '//primaryZones/primaryZone' ) ||
        die( "Unable to get the primary timezones in ${zone_file}" );
    if( !$primaryZonesRes->size )
    {
        die( "No primary timezones found in ${zone_file}" );
    }
    my $tzs = 
    {
        # Default value used in localised data
        'Etc/Unknown' => 
        {
            timezone => 'Etc/Unknown',
            territory => 'ZZ',
            region => 'Etc',
            is_golden => 0,
        }
    };
    
    # NOTE: Pre-loading time zone information
    &log( "Pre-loading time zone information." );
    my $timezonesRes = $zoneDoc->findnodes( '//metaZones/metazoneInfo/timezone' ) ||
        die( "Unable to get the meta timezones information in ${zone_file}" );
    if( !$timezonesRes->size )
    {
        die( "No meta timezones information found in ${zone_file}" );
    }
    my $tzRe = qr/(?<year>\d{4})\D(?<month>\d{1,2})\D(?<day>\d{1,2})[[:blank:]\h]+(?<hour>\d{1,2})\D(?<minute>\d{1,2})/;
    $n = 0;
    my $tz_infos = {};
    # NOTE: Collecting timezones from metaZones.xml//metaZones/metazoneInfo/timezone
    &log( "Collecting timezones from metaZones.xml//metaZones/metazoneInfo/timezone" );
    while( my $el = $timezonesRes->shift )
    {
        my $tz = $el->getAttribute( 'type' ) ||
            die( "Unable to find the attribute 'type' on this timezone tag: ", $el->toString() );
        $tz_infos->{ $tz } = [];
        if( !exists( $tzs->{ $tz } ) )
        {
            $tzs->{ $tz } = { timezone => $tz, is_golden => 0 };
            $tzs->{ $tz }->{region} = [split( /\//, $tz )]->[0] if( index( $tz, '/' ) != -1 );
            $out->print( "Collected ${tz}\n" ) if( $DEBUG );
        }
        # We set the value of metazone to the most recent one, and for that we use DateTime to compare DateTime object.
        my( $metazone, $metazone_from, $metazone_to );
        my @metaZones = $el->getChildrenByTagName( 'usesMetazone' );
        # Example: <usesMetazone to="1979-10-25 23:00" from="1977-10-20 23:00" mzone="Europe_Central"/>
        foreach my $el_meta ( @metaZones )
        {
            my $def =
            {
                timezone => $tz,
                metazone => ( $el_meta->getAttribute( 'mzone' ) || die( "No attribute 'mzone' found on this 'usesMetazone' tag: ", $el_meta->toString() ) ),
                ( $el_meta->hasAttribute( 'from' ) ? ( start => $el_meta->getAttribute( 'from' ) ) : () ),
                ( $el_meta->hasAttribute( 'to' ) ? ( 'until' => $el_meta->getAttribute( 'to' ) ) : () ),
            };
            # The first 'usesMetazone' is the most recent, so if it is already set, we ignore
            # This turned out to be too simple.
            # $tzs->{ $tz }->{metazone} = $def->{metazone} unless( $tzs->{ $tz }->{metazone} );
            my $metadt = {};
            foreach my $prop ( qw( start until ) )
            {
                if( exists( $def->{ $prop } ) &&
                    defined( $def->{ $prop } ) )
                {
                    if( $def->{ $prop } =~ /^$tzRe$/ )
                    {
                        my $re = {%+};
                        $def->{ $prop } = sprintf( '%4d-%02d-%02dT%02d:%02d:00', @$re{qw( year month day hour minute )} );
                        $metadt->{ $prop } = DateTime->new( %$re, time_zone => 'floating' );
                    }
                    else
                    {
                        die( "Property '${prop}' for time zone '${tz}' seems to have an invalid datetime format '", $def->{ $prop }, "'" );
                    }
                }
            }
            push( @{$tz_infos->{ $tz }}, $def );
            if( exists( $metadt->{start} ) ||
                exists( $metadt->{until} ) )
            {
                if( !defined( $metazone_from ) &&
                    !defined( $metazone_to ) )
                {
                    $metazone_from = $metadt->{start};
                    $metazone_to = $metadt->{until};
                    $metazone = $def->{metazone};
                }
                elsif( defined( $metadt->{start} ) )
                {
                    if( defined( $metazone_to ) &&
                        $metadt->{start} >= $metazone_to )
                    {
                        $metazone = $def->{metazone};
                    }
                    else
                    {
                        warn( "Warning only: weirdly enough, this meta zone '$def->{metazone}' for the zone ID '$def->{timezone}' is not historically the first one, and yet its start datetime ($def->{from}) is not higher than the previous metazone end datetime (", $metazone_to->iso8601, "): ", dump( $def ) );
                    }
                }
                else
                {
                    die( "Time zone ID ${tz} has metazone $def->{metazone}, which is not historically the first one, and yet I could not get a start datetime: ", dump( $def ) );
                }
            }
            else
            {
                $metazone = $def->{metazone};
            }
            ++$n;
        }
        # End checking each metazone for this timezone
        $tzs->{ $tz }->{metazone} = $metazone;
    }
    &log( "${n} time zone information pre-loaded." );
    
    # Now check the primary zones that also are golden zones.
    # See the specs: <https://www.unicode.org/reports/tr35/tr35-dates.html#Using_Time_Zone_Names>
    # NOTE: Collecting primary (golden) timezones from metaZones.xml//primaryZones/primaryZone
    &log( "Collecting primary (golden) timezones from metaZones.xml//primaryZones/primaryZone" );
    while( my $el = $primaryZonesRes->shift )
    {
        my $tz = $el->textContent || die( "No text content could be found for this primary time zone: ", $el->toString() );
        unless( defined( $tz ) &&
                length( $tz ) &&
                index( $tz, '/' ) != -1 )
        {
            die( "Textual content for this prime zone element is either empty or malformed: ", $el->toString() );
        }
        if( !exists( $tzs->{ $tz } ) )
        {
            die( "Unable to find the primary time zone '${tz}' in our previously built dictionary." );
        }
        my $territory = $el->getAttribute( 'iso3166' ) ||
            die( "No territory code defined for this primary zone '${tz}': ", $el->toString() );
        $tzs->{ $tz }->{is_primary} = 1;
        $tzs->{ $tz }->{territory} = $territory unless( $tzs->{ $tz }->{territory} );
    }
    
    # We use it so we can add the CLDR 4-characters time zone id in a separate iteration
    # NOTE: Collecting metazones from metaZones.xml//metaZones/mapTimezones/mapZone
    &log( "Collecting metazones from metaZones.xml//metaZones/mapTimezones/mapZone" );
    my $metazone_to_dict = {};
    while( my $el = $tzMapRes->shift )
    {
        my $tz = $el->getAttribute( 'type' ) ||
            die( "Unable to get the attribute 'type' for this element: ", $el->toString() );
        my $def =
        {
            timezone => $tz,
            territory => ( $el->getAttribute( 'territory' ) || die( "No attribute 'territory' for this time zone '${tz}': ", $el->toString() ) ),
            metazone => ( $el->getAttribute( 'other' ) || die( "No attribute 'other' for this time zone '${tz}': ", $el->toString() ) ),
            # By default
            is_golden => 0,
            is_primary => 0,
        };
        if( index( $tz, '/' ) != -1 )
        {
            $def->{region} = [split( '/', $tz )]->[0];
        }
        elsif( index( $def->{metazone}, '_' ) != -1 )
        {
            $def->{region} = [split( '_', $def->{region} )]->[0];
        }
        else
        {
            die( "Neither the time zone (${tz}) nor the metazone ($def->{metazone}) have any region information." );
        }
        # Perl converted it to an integer, and removed any leading zeros.
        if( $def->{territory} =~ /^\d{1,3}$/ )
        {
            $def->{territory} = sprintf( '%03d', int( $def->{territory} ) );
            # "The golden zones are those in mapZone supplemental data under the territory "001"."
            # <https://unicode.org/reports/tr35/tr35-dates.html#Using_Time_Zone_Names>
            $def->{is_golden} = 1;
        }
        else
        {
            # This is the preferred timezone for this territory
            # <https://unicode.org/reports/tr35/tr35-dates.html#Time_Zone_Format_Terminology>
            $def->{is_preferred} = 1;
        }

        foreach my $prop ( keys( %$def ) )
        {
            if( $prop eq 'is_golden' ||
                !exists( $tzs->{ $tz }->{ $prop } ) ||
                !length( $tzs->{ $tz }->{ $prop } // '' ) )
            {
                $tzs->{ $tz }->{ $prop } = $def->{ $prop };
            }
        }
        $metazone_to_dict->{ $def->{metazone} } ||= [];
        push( @{$metazone_to_dict->{ $def->{metazone} }}, $def );
    }

    # Associating metazone information to timezone that somehow were left out from the metazone to timezone mapping
    &log( "Setting timezones missing 'territory' and 'is_golden' data" );
    foreach my $tz ( keys( %$tzs ) )
    {
        my $this = $tzs->{ $tz };
        if( $this->{metazone} && 
            !$this->{territory} &&
            exists( $metazone_to_dict->{ $this->{metazone} } ) &&
            ref( $metazone_to_dict->{ $this->{metazone} } ) &&
            scalar( @{$metazone_to_dict->{ $this->{metazone} }} ) == 1 )
        {
            $out->print( "\tTimezone '${tz}' does not have a territory set, using the entry for metazone '", $this->{metazone}, "' to get the information.\n" ) if( $DEBUG );
            $this->{territory} = $metazone_to_dict->{ $this->{metazone} }->[0]->{territory};
            # $this->{is_golden} = $metazone_to_dict->{ $this->{metazone} }->[0]->{is_golden};
        }
    }
    
    # NOTE: Collecting timezone IDs from metaZones.xml//metaZones/metazoneIds/metazoneId
    &log( "Collecting timezone IDs from metaZones.xml//metaZones/metazoneIds/metazoneId" );
    while( my $el = $metazoneIdsRes->shift )
    {
        my $metazone = $el->getAttribute( 'longId' ) || die( "No attribute 'longId' for this meta zone element: ", $el->toString() );
        my $id = $el->getAttribute( 'shortId' ) || die( "No attribute 'shortId' for this meta zone '${metazone}': ", $el->toString() );
        if( !exists( $metazone_to_dict->{ $metazone } ) )
        {
            die( "Unable to find the meta zone '${metazone}' in our previously built map." );
        }
        foreach my $tz_ref ( @{$metazone_to_dict->{ $metazone }} )
        {
            my $tz = $tz_ref->{timezone} || die( "Error: no timezone is set: ", dump( $tz_ref ) );
            $tzs->{ $tz }->{tzid} = $id;
            $out->print( "Set ID '${id}' to metazone '${metazone}' (", $tzs->{ $tz }->{timezone}, "). Time zone now has this tzid (", $tzs->{ $tz }->{tzid}, ")\n" ) if( $DEBUG );
        }
    }
    
    # NOTE: Loading additional information from windowsZones
    &log( "Loading additional information from windowsZones." );
    my $windows_zones_file = $basedir->child( 'supplemental/windowsZones.xml' );
    my $windZonesDom = load_xml( $windows_zones_file );
    my $windZonesRes = $windZonesDom->findnodes( '/supplementalData/windowsZones/mapTimezones/mapZone' ) ||
        die( "Unable to get windows zones from ${windows_zones_file}" );
    $n = 0;
    while( my $el = $windZonesRes->shift )
    {
        # Example: <mapZone other="Aleutian Standard Time" territory="001" type="America/Adak"/>
        #          <mapZone other="Alaskan Standard Time" territory="US" type="America/Anchorage America/Juneau America/Metlakatla America/Nome America/Sitka America/Yakutat"/>
        my $territory = $el->getAttribute( 'territory' ) ||
            die( "Unable to get the 'territory' attribute value for this windows zone: ", $el->toString() );
        my $zones = $el->getAttribute( 'type' ) ||
            die( "Unable to get the 'type' attribute value for this windows zone: ", $el->toString() );
        $zones = [split( /[[:blank:]\h]+/, $zones )];
        foreach my $zone ( @$zones )
        {
            $out->print( "[${zone}] " ) if( $DEBUG );
            if( exists( $tzs->{ $zone } ) )
            {
                if( !exists( $tzs->{ $zone }->{territory} ) ||
                    !length( $tzs->{ $zone }->{territory} // '' ) ||
                    (
                        # territory for a time zone may have been set to 001 (World), or some region code,
                        # but next iteration could allocate a more accurate territory, such as an ISO3166 code
                        length( $tzs->{ $zone }->{territory} // '' ) &&
                        $tzs->{ $zone }->{territory} =~ /^\d{1,3}$/
                    ) )
                {
                    $tzs->{ $zone }->{territory} = $territory;
                    $tzs->{ $zone }->{region} = [split( /\//, $zone )]->[0] if( index( $zone, '/' ) != -1 );
                    $n++;
                    $out->print( "added territory ${territory}\n" ) if( $DEBUG );
                }
                else
                {
                    $out->print( "already have territory '", ( $tzs->{ $zone }->{territory} // 'undef' ), "'\n" ) if( $DEBUG );
                }
            }
            else
            {
                $tzs->{ $zone } =
                {
                    timezone => $zone,
                    territory => $territory,
                    region => ( index( $zone, '/' ) != -1 ? [split( /\//, $zone )]->[0] : undef ),
                };
                $out->print( "missing time zone added\n" ) if( $DEBUG );
            }
        }
    }
    &log( "${n} additional time zone information added." );
    
    # NOTE: Loading BCP47 timezones
    &log( "Loading BCP47 timezones." );
    $n = 0;
    my $bcp47_tz_file = $basedir->child( 'bcp47/timezone.xml' );
    my $bcp47_tzDoc = load_xml( $bcp47_tz_file );
    my $tzKeysRes = $bcp47_tzDoc->findnodes( '//keyword/key/type' ) ||
        die( "Unable to get BCP47 timezones in ${bcp47_tz_file}" );
    if( !$tzKeysRes->size )
    {
        die( "No BCP47 timezones found in ${bcp47_tz_file}" );
    }
    $sth = $sths->{bcp47_timezones} || die( "No SQL statement object for bcp47_timezones" );
    my $tz_bool_map =
    {
        'true'  => 1,
        'false' => 0,
    };
    while( my $el = $tzKeysRes->shift )
    {
        my $def =
        {
            tzid        => ( $el->getAttribute( 'name' ) || die( "Unable to get the attribute 'name' for this timezone element: ", $el->toString() ) ),
            alias       => $el->getAttribute( 'alias' ),
            preferred   => $el->getAttribute( 'preferred' ),
            description => $el->getAttribute( 'description' ),
        };
        $out->print( "[$def->{tzid}] " ) if( $DEBUG );
        if( $el->hasAttribute( 'deprecated' ) )
        {
            my $bool = $el->getAttribute( 'deprecated' );
            if( exists( $tz_bool_map->{ $bool } ) )
            {
                $def->{deprecated} = $tz_bool_map->{ $bool };
            }
            else
            {
                die( "Unknown boolean value for deprecated: '", ( $bool // 'undef' ), "'" );
            }
        }
        if( defined( $def->{alias} ) &&
            length( $def->{alias} ) )
        {
            $def->{alias} = [split( /[[:blank:]\h\v]+/, $def->{alias} )];
            # We check each of the IANA timezone ID, and if we find it in the list of timezones previously built, we add our BCP47 timezone ID to it dictionary definition.
            my $main_tz;
            foreach my $tz ( @{$def->{alias}} )
            {
                if( exists( $tzs->{ $tz } ) )
                {
                    $tzs->{ $tz }->{tz_bcpid} = $def->{tzid};
                    $tzs->{ $tz }->{alias} = [grep( $_ ne $tz, @{$def->{alias}} )];
                    $tzs->{ $tz }->{is_primary} = 0 unless( defined( $tzs->{ $tz }->{is_primary} ) );
                    $tzs->{ $tz }->{is_preferred} = 0 unless( defined( $tzs->{ $tz }->{is_preferred} ) );
                    $tzs->{ $tz }->{is_canonical} = 0 unless( defined( $tzs->{ $tz }->{is_canonical} ) );
                    $out->print( "alias added to time zone '${tz}'. " ) if( $DEBUG );
                    $main_tz = $tz if( !defined( $main_tz ) );
                }
                else
                {
                    $out->print( "Unknown time zone '${tz}' found in BCP47 time zones for BCP47 tz ID '$def->{tzid}', adding it to our list of known timezones.\n" ) if( $DEBUG );
                    unless( defined( $main_tz ) )
                    {
                        foreach my $tz ( @{$def->{alias}} )
                        {
                            if( exists( $tzs->{ $tz } ) )
                            {
                                $main_tz = $tz;
                                last;
                            }
                        }
                    }
                    if( !defined( $main_tz ) )
                    {
                        die( "This timezone ID '${tz}' is not known to us yet, and none of its aliases are either: '", join( "', '", @{$def->{alias}} ), "'" );
                    }
                    my $tz_info = Clone::clone( $tzs->{ $main_tz } );
                    $tz_info->{timezone} = $tz;
                    # $tz_info->{region} = [split( '/', $tz )]->[0];
                    $tz_info->{region} = [split( '/', $tz )]->[0] if( index( $tz, '/' ) != -1 );
                    $tz_info->{tz_bcpid} = $def->{tzid};
                    $tz_info->{alias} = [grep( $_ ne $tz, @{$def->{alias}} )];
                    $tz_info->{is_primary} = 0;
                    $tz_info->{is_preferred} = 0;
                    $tz_info->{is_canonical} = 0;
                    $tzs->{ $tz } = $tz_info;
                }
            }
            # The first one is the canonical timezone as per the LDML specifications
            $tzs->{ $def->{alias}->[0] }->{is_canonical} = 1;
        }
    
        eval
        {
            $sth->execute( $def->{tzid}, to_array( $def->{alias} ), @$def{qw( preferred description deprecated )} );
        } || die( "Error adding BCP47 timezone information for TZ ID '$def->{tzid}': ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
        $out->print( "ok\n" ) if( $DEBUG );
        $n++;
    }
    &log( "${n} BCP47 timezones added." );
    
    # NOTE: Dumping timezones to JSON
    my $tz_debug_file = $script_dir->child( 'timezones.json' );
    $tz_debug_file->unload_json( $tzs => { pretty => 1, canonical => 1 } ) || die( $tz_debug_file->error );
    
    # NOTE: Loading time zones
    &log( "Loading time zones." );
    $n = 0;
    $sth = $sths->{timezones} || die( "No SQL statement object for timezones" );
    foreach my $tz ( sort( keys( %$tzs ) ) )
    {
        my $def = $tzs->{ $tz };
        $out->print( "[${tz}] " ) if( $DEBUG );
        $def->{timezone} = $tz if( !exists( $def->{timezone} ) || !length( $def->{timezone} // '' ) );
        if( !exists( $def->{territory} ) ||
            !defined( $def->{territory} ) ||
            !length( $def->{territory} ) )
        {
            # For example, Antarctica/Troll -> Antarctica -> AQ
            if( $def->{region} &&
                exists( $eng_territories_names_to_code->{ $def->{region} } ) )
            {
                $def->{territory} = $eng_territories_names_to_code->{ $def->{region} };
            }
            elsif( index( $tz, '/' ) == -1 )
            {
                $def->{territory} = '001';
                $def->{region} = 'World';
            }
            elsif( lc( [split( '/', $tz )]->[0] ) eq 'etc' )
            {
                $def->{territory} = '001';
                $def->{region} = 'World';
            }
            else
            {
                die( "Missing 'territory' property for time zone '${tz}': ", dump( $def ) );
            }
        }
        elsif( substr( $tz, 0, 3 ) eq 'GMT' || 
               substr( $tz, 0, 3 ) eq 'UTC' ||
               substr( $tz, 0, 7 ) eq 'Etc/GMT' ||
               substr( $tz, 0, 7 ) eq 'Etc/UTC' ||
               substr( $tz, 0, 7 ) eq 'Etc/UCT' ||
               $tz eq 'Etc/Universal' )
        {
            $def->{region} = 'World';
        }
        # No region has been set so far, and this is because this is a zone that belongs to the World, such as CST6CDT or Greenwich
        elsif( !length( $def->{region} // '' ) )
        {
            $def->{region} = 'World';
        }
        $def->{is_primary} //= 0;
        eval
        {
            $sth->bind_param( 1, $def->{timezone}, SQL_VARCHAR );
            $sth->bind_param( 2, $def->{territory}, SQL_VARCHAR );
            $sth->bind_param( 3, $def->{region}, SQL_VARCHAR );
            $sth->bind_param( 4, $def->{tzid}, SQL_VARCHAR );
            $sth->bind_param( 5, $def->{metazone}, SQL_VARCHAR );
            $sth->bind_param( 6, $def->{tz_bcpid}, SQL_VARCHAR );
            $sth->bind_param( 7, $def->{is_golden}, SQL_BOOLEAN );
            $sth->bind_param( 8, $def->{is_primary}, SQL_BOOLEAN );
            $sth->bind_param( 9, $def->{is_preferred}, SQL_BOOLEAN );
            $sth->bind_param( 10, $def->{is_canonical}, SQL_BOOLEAN );
            $sth->bind_param( 11, to_array( $def->{alias} ), SQL_VARCHAR );
            $sth->execute;
        } || die( "Error adding time zone information for time zone '${tz}': ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
        $out->print( "ok\n" ) if( $DEBUG );
        $n++;
    }
    &log( "${n} timezones added." );
    
    # NOTE: Loading time zone information
    &log( "Loading time zone historical records." );
    $sth = $sths->{timezones_info} || die( "No SQL statement object for timezones_info" );
    $n = 0;
    foreach my $tz ( sort( keys( %$tz_infos ) ) )
    {
        foreach my $def ( @{$tz_infos->{ $tz }} )
        {
            $out->print( "[${tz} -> ", ( $def->{metazone} // 'no metazone' ), ' ', 
                         ( $def->{start} ? "(from $def->{start}" : '' ),
                         ( $def->{until} ? " -> $def->{until}) " : ') ' )
                       ) if( $DEBUG );
            eval
            {
                $sth->execute( @$def{ qw( timezone metazone start until ) } );
            } || die( "Error adding time zone historical record for time zone '${tz}': ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
            $out->print( "ok\n" ) if( $DEBUG );
            ++$n;
        }
    }
    &log( "${n} historical records added." );
    
    # NOTE: Pre-loading subdivisions
    &log( "Pre-loading subdivisions." );
    $n = 0;
    my $subdiv_file = $basedir->child( 'supplemental/subdivisions.xml' );
    my $subdivDoc = load_xml( $subdiv_file );
    my $subgroupsRes = $subdivDoc->findnodes( '//subdivisionContainment/subgroup' ) ||
        die( "Unable to get subgroup from file ${subdiv_file}" );
    if( !$subgroupsRes->size )
    {
        die( "No subdivisions found in file ${subdiv_file}" );
    }
    my $known_subdivisions = {};
    my $territories_having_subdivisions = {};
    while( my $el = $subgroupsRes->shift )
    {
        my $parent = $el->getAttribute( 'type' ) ||
            die( "No 'type' property found for this subdivision: ", $el->toString() );
        my $kids = $el->getAttribute( 'contains' ) ||
            die( "No 'contains' property found for this subdivision: ", $el->toString() );
        $kids = [split( /[[:blank:]\h\v]+/, $kids )];
        my $is_top = 0;
        my $territory;
        if( $parent =~ /^[A-Z]{2}$/ )
        {
            $is_top = 1;
            if( !exists( $territoryInfo->{ $parent } ) )
            {
                die( "Parent territory code '${parent}' does not exist in table territories." );
            }
            $territories_having_subdivisions->{ $parent }++;
            $territory = $parent;
        }
    
        foreach my $kid ( @$kids )
        {
            $known_subdivisions->{ $kid } =
            {
                subdivision => $kid,
                parent => $parent,
                is_top_level => $is_top,
                ( defined( $territory ) ? ( territory => $territory ) : () ),
            };
        }
        $n += scalar( @$kids );
    }
    &log( "${n} subdivisions pre-loaded." );
    my $leftout = [];
    foreach my $code ( sort( keys( %$territoryInfo ) ) )
    {
        push( @$leftout, $code ) if( !exists( $territories_having_subdivisions->{ $code } ) );
    }
    &log( scalar( @$leftout ), " territories did not have subdivision: ", join( ', ', @$leftout ) );
    
    # NOTE: Adding possibly missing subdivisions
    &log( "Adding possibly missing subdivisions." );
    $n = 0;
    foreach my $code ( sort( keys( %{$known->{subdivisions}} ) ) )
    {
        if( !exists( $known_subdivisions->{ $code } ) )
        {
            $known_subdivisions->{ $code } = { subdivision => $code };
            $n++;
        }
        $known_subdivisions->{ $code }->{status} = $known->{subdivisions}->{ $code }->{status};
    }
    &log( sprintf( "%d missing subdivisions added (%.2f%%) out of %d", $n, ( ( $n / scalar( keys( %{$known->{subdivisions}} ) ) ) * 100 ), scalar( keys( %{$known->{subdivisions}} ) ) ) );
    
    # NOTE: Associating a territory code for each subdivision by looking up its associated territory
    &log( "Associating a territory code for each subdivision by looking up its associated territory." );
    $n = 0;
    my $subdiv_lookup;
    $subdiv_lookup = sub
    {
        my $code = shift( @_ );
        if( exists( $known_subdivisions->{ $code } ) )
        {
            if( exists( $known_subdivisions->{ $code }->{territory} ) &&
                defined( $known_subdivisions->{ $code }->{territory} ) &&
                length( $known_subdivisions->{ $code }->{territory} ) )
            {
                return( $known_subdivisions->{ $code }->{territory} );
            }
            elsif( exists( $known_subdivisions->{ $code }->{parent} ) &&
                   length( $known_subdivisions->{ $code }->{parent} // '' ) )
            {
                return( $subdiv_lookup->( $known_subdivisions->{ $code }->{parent} ) );
            }
            else
            {
                return;
            }
        }
        else
        {
            die( "Subdivision code '${code}' is unknown." );
        }
    };
    
    foreach my $sub ( sort( keys( %$known_subdivisions ) ) )
    {
        if( !exists( $known_subdivisions->{ $sub }->{territory} ) ||
            !length( $known_subdivisions->{ $sub }->{territory} // '' ) )
        {
            my $code;
            if( $known_subdivisions->{ $sub }->{status} eq 'unknown' )
            {
                $code = 'ZZ';
            }
            else
            {
                $code = $subdiv_lookup->( $known_subdivisions->{ $sub }->{parent} || $sub );
                if( !$code && 
                    $known_subdivisions->{ $sub }->{status} ne 'deprecated' &&
                    $known_subdivisions->{ $sub }->{parent} ne 'unknown' )
                {
                    die( "Unable to find an associated territory for the subdivision '${sub}' with status '", $known_subdivisions->{ $sub }->{status}, "' and parent '", $known_subdivisions->{ $sub }->{parent}, "'" );
                }
            }
            $known_subdivisions->{ $sub }->{territory} = $code if( defined( $code ) && length( $code // '' ) );
        }
    }
    &log( "${n} territory code associated for subdivisions." );
    
    my @missing_subdivision_territory = ();
    foreach my $sub ( sort( keys( %$known_subdivisions ) ) )
    {
        if( !exists( $known_subdivisions->{ $sub }->{territory} ) ||
            !length( $known_subdivisions->{ $sub }->{territory} // '' ) )
        {
            push( @missing_subdivision_territory, $sub );
        }
    }
    
    if( scalar( @missing_subdivision_territory ) )
    {
        warn( scalar( @missing_subdivision_territory ), " deprecated or unknown subdivisions found without an asociated territory: ", join( ', ', @missing_subdivision_territory ) );
    }
    else
    {
        $out->print( "All ", scalar( keys( %$known_subdivisions ) ), " subdivisions have an associated territory.\n" ) if( $DEBUG );
    }
    
    # NOTE: Loading subdivisions
    &log( "Loading subdivisions." );
    $n = 0;
    $sth = $sths->{subdivisions} || die( "No SQL statement object for subdivisions" );
    foreach my $code ( sort( keys( %$known_subdivisions ) ) )
    {
        $out->print( "[${code}] " ) if( $DEBUG );
        my $def = $known_subdivisions->{ $code };
        eval
        {
            $sth->execute( @$def{qw( territory subdivision parent is_top_level status )} );
        } || die( "Error adding subdivision information for subdivision '$def->{subdivision}', territory '$def->{territory}' and parent '", ( $def->{parent} // 'undef' ), "': ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
        $out->print( "ok\n" ) if( $DEBUG );
        $n++;
    }
    &log( "${n} subdivisions added." );
    %$known_subdivisions = ();
    
    # NOTE: Loading localised subdivisions
    &log( "Loading localised subdivisions." );
    $n = 0;
    my $x = 0;
    my $total_localised = 0;
    $subdivisions_l10n_dir->open || die( "Unable to open directory $subdivisions_l10n_dir: ", $subdivisions_l10n_dir->error );
    $sth = $sths->{subdivisions_l10n} || die( "No SQL statement object for subdivisions_l10n" );
    # while( my $f = $subdivisions_l10n_dir->read( as_object => 1, exclude_invisible => 1 ) )
    @files = $subdivisions_l10n_dir->read( as_object => 1, exclude_invisible => 1, 'sort' => 1 );
    foreach my $f ( @files )
    {
        next unless( $f->extension eq 'xml' );
        my $basename = $f->basename;
        next if( $basename eq 'root.xml' );
        $out->print( "[${basename}] " ) if( $DEBUG );
        my $locDoc = load_xml( $f );
        # Returned an XML::LibXML::Attr
        
        # my $langAttr = $locDoc->findnodes( '//identity/language/@type' ) ||
        #     die( "No language node with attribute could be found in the XML file $f" );
        # my $locale = $langAttr->getValue();
        my $locale = identity_to_locale( $locDoc );
        ( my $locale2 = $f->basename( '.xml' ) ) =~ tr/_/-/;
        if( lc( $locale ) ne lc( $locale2 ) &&
            $locale2 ne 'root' )
        {
            warn( "XML identity says the locale is '${locale}', but the file basename says it should be '${locale2}', and I think the file basename is correct for file $f" );
            $locale = $locale2;
        }
        if( index( $locale, 'root' ) != -1 )
        {
            if( length( $locale ) > 4 )
            {
                my $loc = Locale::Unicode->new( $locale );
                $loc->language( 'und' );
                $locale = $loc->as_string;
            }
            else
            {
                $locale = 'und';
            }
        }
        my $namesRes = $locDoc->findnodes( '//localeDisplayNames/subdivisions/subdivision' );
        unless( $namesRes->size )
        {
            warn( "Warning only: No localised subdivision names found for language ${locale} in file ${f}" );
            next;
        }
        while( my $el = $namesRes->shift )
        {
            my $id = $el->getAttribute( 'type' ) ||
                die( "No subdivision ID found with attribute 'type' in file ${f} for this element: ", $el->toString() );
            # Somehow, the XML file also contains some territory codes like AS, AW, AX
            # We need to filter them out
            if( length( $id ) == 2 &&
                $id =~ /^[A-Z]{2}$/ &&
                exists( $territoryInfo->{ $id } ) )
            {
                next;
            }
            my $name = $el->textContent;
            if( index( $name, '&' ) != -1 &&
                index( $name, ';' ) != -1 )
            {
                $name = decode_entities( $name );
            }
    
            eval
            {
                $sth->execute( $locale, $id, $name );
            } || die( "Error adding localised subdivision name information in file ${f} with id '${id}' and locale '${locale}': ", ( $@ || $sth->errstr ) );
            $x++;
        }
        $out->print( "ok (${x})\n" ) if( $DEBUG );
        $total_localised += $x;
        $x = 0;
        $n++;
    }
    &log( "${n} locales processed adding a total of ${total_localised} localised subdivisions." );
    
    # NOTE: Loading core numbering systems rules
    &log( "Loading core numbering systems rules." );
    $n = 0;
    my $root_num_sys_file = $basedir->child( 'rbnf/root.xml' );
    my $rootSysNumDoc = load_xml( $root_num_sys_file );
    my $sysNumRulesRes = $rootSysNumDoc->findnodes( '/ldml/rbnf/rulesetGrouping[@type="NumberingSystemRules"]/ruleset' ) ||
        die( "Unable to get the core numbering systems in file ${root_num_sys_file}" );
    &log( sprintf( "%d rules found.", $sysNumRulesRes->size ) );
    my $numbering_systems = {};
    my $fetch_numbers;
    $fetch_numbers = sub
    {
        my $el = shift( @_ );
        my $args = shift( @_ ) // {};
        my $start = $args->{start} // 0;
        my $lang = $args->{locale} // 'und';
        my $rbnfDoc = $args->{doc} // $rootSysNumDoc;
        my $rbnf_file = $args->{file} // $root_num_sys_file;
        my $group = $args->{group} // 'NumberingSystemRules';
        my $id = $el->getAttribute( 'id' );
        my $numRulesRes = $el->findnodes( "./rbnfrule[\@value >= \"${start}\" and \@value < \"10\"]" );
        my @numbers = ();
        if( !$numRulesRes->size )
        {
            die( "No number found in the RBNF file ${rbnf_file} for the numbering system id '${id}' with rulesetGrouping 'NumberingSystemRules' and ruleset type '${id}'" );
        }
        # All is good
        elsif( $numRulesRes->size == 10 )
        {
            @numbers = map( [split( ';', $_->textContent )]->[0], $numRulesRes->get_nodelist );
        }
        # <rbnfrule value="1">=%%cyrillic-lower-1-10=҃;</rbnfrule>
        else
        {
            foreach my $node ( $numRulesRes->get_nodelist )
            {
                # my $node = $nodes[$i];
                my $val = $node->textContent;
                $out->print( "\tFound value '${val}'\n" ) if( $DEBUG );
                if( index( $val, '%' ) != -1 )
                {
                    # =%%cyrillic-lower-1-10=;
                    # >҃=%%cyrillic-lower-1-10=;
                    if( $val =~ /^(?<prefix>.*)\=\%{1,2}(?<target>[^\=]+)\=/ )
                    {
                        my $target = $+{target};
                        # Actually, we ignore it, because I am not that sure this is really a prefix.
                        my $prefix = $+{prefix};
                        $out->print( "\tFound alias pointing to ${target} with prefix '", ( $prefix // 'undef' ), "'\n" ) if( $DEBUG );
                        if( exists( $numbering_systems->{ $target } ) )
                        {
                            $out->printf( "\tFound cached data with %d elements for number system ${target}\n", scalar( @{$numbering_systems->{ $target }} ) ) if( $DEBUG );
                            # if( defined( $prefix ) )
                            # {
                            #     push( @numbers, map( $prefix . $_, @{$numbering_systems->{ $target }} ) );
                            # }
                            # else
                            # {
                                push( @numbers, @{$numbering_systems->{ $target }} );
                            # }
                        }
                        else
                        {
                            my $resolverRes = $rbnfDoc->findnodes( '/ldml/rbnf/rulesetGrouping[@type="' . $group . '"]/ruleset[@type="' . $target . '"]' );
                            if( !$resolverRes->size )
                            {
                                die( "RBNF alias points to ${target}, but I was unable to find it in file ${rbnf_file}" );
                            }
                            my $el_target = $resolverRes->shift;
                            $args->{start} = $start;
                            my $nums = $fetch_numbers->( $el_target, $args );
                            $out->print( "\tResolved for element with ID '", $el->getAttribute( 'type' ), "' pointing to ${target} returned ", scalar( @$nums ), ": ", join( ', ', @$nums ), "\n" ) if( $DEBUG );
                            push( @numbers, @$nums );
                        }
                    }
                    else
                    {
                        die( "Unknown RBFN alias found in string '${val}' in file ${rbnf_file}" );
                    }
                }
                else
                {
                    my $rule_id = $node->getAttribute( 'value' );
                    if( $rule_id =~ /^\d$/ )
                    {
                        push( @numbers, [split( ';', $val )]->[0] );
                    }
                    else
                    {
                        die( "I was expecting a number, but instead found '${id}'" );
                    }
                }
                $start++;
            }
        }
        $out->print( "\treturning: ", join( ', ', @numbers ), "\n" ) if( $DEBUG );
        return( \@numbers );
    };
    
    while( my $el = $sysNumRulesRes->shift )
    {
        # Example: <ruleset type="roman-upper">
        my $id = $el->getAttribute( 'type' ) ||
            die( "No ruleset name value found with attribute 'type': ", $el->toString() );
        $out->print( "[${id}] \n" ) if( $DEBUG );
        my $nums = $fetch_numbers->( $el );
        $numbering_systems->{ $id } = $nums;
        $n++;
        $out->print( "\t@$nums\n" ) if( $DEBUG );
    }
    &log( "${n} numbering systems loaded." );
    
    # NOTE: Loading numbering systems
    &log( "Loading numbering systems." );
    $n = 0;
    my $num_sys_file = $basedir->child( 'supplemental/numberingSystems.xml' );
    my $numsysDoc = load_xml( $num_sys_file );
    my $nsysRes = $numsysDoc->findnodes( '//numberingSystems/numberingSystem' ) ||
        die( "Unable to get the numbering system nodes from file $num_sys_file" );
    $sth = $sths->{number_systems} || die( "No SQL statement object for number_systems" );
    # We use this hash to check if a number system is known to us when we add its localised version in number_systems_l10n
    my $number_systems = {};
    while( my $el = $nsysRes->shift )
    {
        my $id = $el->getAttribute( 'id' ) ||
            die( "Unable to get the attribute 'id' for this numbering system element: ", $el->toString() );
        $number_systems->{ $id }++;
        $out->print( "[${id}] " ) if( $DEBUG );
        my $type = $el->getAttribute( 'type' ) ||
            die( "Unable to get the attribute 'type' for this numbering system element: ", $el->toString() );
        my @numbers;
        if( $el->hasAttribute( 'digits' ) )
        {
            my $str = $el->getAttribute( 'digits' ) ||
                die( "Unable to get the attribute 'digits' for this numbering system element: ", $el->toString() );
            if( index( $str, '&' ) != -1 )
            {
                @numbers = map( decode_entities( $_ ), split( //, $str ) );
            }
            else
            {
                @numbers = split( //, $str );
            }
        }
        # Example: <numberingSystem id="jpan" type="algorithmic" rules="ja/SpelloutRules/spellout-cardinal"/>
        #          <numberingSystem id="hebr" type="algorithmic" rules="hebrew"/>
        #          <numberingSystem id="cyrl" type="algorithmic" rules="cyrillic-lower"/>
        elsif( $el->hasAttribute( 'rules' ) )
        {
            my $rules = $el->getAttribute( 'rules' ) ||
                die( "Unable to get the attribute 'rules' for this numbering system element: ", $el->toString() );
            if( index( $rules, '/' ) != -1 )
            {
                my( $locale, $rbnfType, $ruleType ) = split( '/', $rules, 3 );
                for( $locale, $rbnfType, $ruleType )
                {
                    if( !defined( $_ ) )
                    {
                        die( "Missing key RBNF XML path information to retrieve the digits for the numbering system '${id}': ", $el->toString() );
                    }
                }
                my $rbnfFile = $basedir->child( "rbnf/${locale}.xml" );
                if( !$rbnfFile->exists )
                {
                    die( "RBNF file ${rbnfFile} for locale ${locale} does not exist." );
                }
                my $rbnfDoc = load_xml( $rbnfFile );
                my $numRulesRes = $rbnfDoc->findnodes( "/ldml/rbnf/rulesetGrouping[\@type=\"${rbnfType}\"]/ruleset[\@type=\"${ruleType}\"]" );
                if( !$numRulesRes->size )
                {
                    die( "No number found in the RBNF file ${rbnfFile} for the numbering system id '${id}' with rulesetGrouping '${rbnfType}' and ruleset type '${ruleType}'" );
                }
                my $el_rule = $numRulesRes->shift;
                my $nums = $fetch_numbers->( $el_rule,
                {
                    locale => $locale,
                    file => $rbnfFile,
                    doc => $rbnfDoc,
                    group => $rbnfType,
                });
                # @numbers = map( [split( ';', $_->textContent )]->[0], $numRulesRes->get_nodelist );
                @numbers = @$nums;
            }
            elsif( $rules =~ /^[a-z][a-zA-Z\-]+$/ )
            {
                if( exists( $numbering_systems->{ $rules } ) )
                {
                    @numbers = @{$numbering_systems->{ $rules }};
                }
                else
                {
                    die( "Unknown rule value '${rules}'. Was not found in the core numbering systems file ${root_num_sys_file}" );
                }
            }
            else
            {
                die( "Unsupported numbering systems rule value '${rules}': ", $el->toString() );
            }
        }
        else
        {
            die( "This numbering system has no 'digits' nor 'rules' attribute defined: ", $el->toString() );
        }
        my $digits = \@numbers;
    
        eval
        {
            $sth->execute( $id, to_array( $digits ), $type );
        } || die( "Error adding number system information for id '${id}': ", ( $@ || $sth->errstr ) );
        $out->print( "ok\n" ) if( $DEBUG );
        $n++;
    }
    
    # NOTE: Loading time formats
    &log( "Loading time formats." );
    $n = 0;
    my $timeHoursRes = $suppDoc->findnodes( '//timeData/hours' ) ||
        die( "Unable to get the time hours preferred formats in ${supplemental_data_file}" );
    if( !$timeHoursRes->size )
    {
        die( "No time hours preferred formats found in file ${supplemental_data_file}" );
    }
    $sth = $sths->{time_formats} || die( "No SQL statement object for time_formats" );
    while( my $el = $timeHoursRes->shift )
    {
        my $pref = $el->getAttribute( 'preferred' ) ||
            die( "Unable to get the attribute 'preferred' in preferred time element: ", $el->toString() );
        my $allowed = $el->getAttribute( 'allowed' ) ||
            die( "Unable to get the attribute 'allowed' in preferred time element: ", $el->toString() );
        my $codes = $el->getAttribute( 'regions' ) ||
            die( "Unable to get the attribute 'regions' in preferred time element: ", $el->toString() );
        $codes = [split( /[[:blank:]\h\v]+/, $codes )];
        $allowed = [split( /[[:blank:]\h\v]+/, $allowed )] if( defined( $allowed ) );
        foreach my $code ( @$codes )
        {
            $out->print( "[{${code}] " ) if( $DEBUG );
            # This is messed up. The CLDR XML file for time formatting has a property 'region', which, sometimes, contains locales. They should have used a different property name, such as 'locale'
            my( $territory, $locale );
            if( index( $code, '_' ) != -1 )
            {
                $code =~ tr/_/-/;
            }
            if( index( $code, '-' ) != -1 )
            {
                ( $locale, $territory ) = split( '-', $code, 2 );
            }
            else
            {
                $territory = $code;
            }
            # A 3-digits code like 001 that got truncated, because it turned into an integer
            if( $code =~ /^\d{1,2}$/ )
            {
                $code = sprintf( '%03d', $code );
            }
            # The CLDR uses 001 (World) to signify the default value.
            # We set the default value in the SQL schema, so we do not need this.
            # if( $code eq '001' )
            # {
            #     next;
            # }
            # elsif( !exists( $territoryInfo->{ $territory } ) )
            if( !exists( $territoryInfo->{ $territory } ) )
            {
                die( "Unknown territory territory code '${territory}' for property 'region' with value '${code}'. Not previous defined in CLDR as a territory." );
            }
    
            eval
            {
                $sth->bind_param( 1, "$code", SQL_VARCHAR );
                $sth->bind_param( 2, $territory, SQL_VARCHAR );
                $sth->bind_param( 3, $locale, SQL_VARCHAR );
                $sth->bind_param( 4, $pref, SQL_VARCHAR );
                $sth->bind_param( 5, to_array( $allowed ), SQL_VARCHAR );
                $sth->execute;
            } || die( "Error adding time formatting information for region '${code}': ", ( $@ || $sth->errstr ) );
            $n++;
            $out->print( "ok\n" ) if( $DEBUG );
        }
    }
    &log( "Time formatting added to ${n} territories." );
    
    # NOTE: Loading week of preference
    &log( "Loading week of preference." );
    $n = 0;
    my $weekPrefsRest = $suppDoc->findnodes( '//weekData/weekOfPreference' ) ||
        die( "Unable to get week of preferences information from ${supplemental_data_file}" );
    if( !$weekPrefsRest->size )
    {
        die( "No week of preferences information found in ${supplemental_data_file}" );
    }
    $sth = $sths->{week_preferences} || die( "No SQL statement object for week_preferences" );
    # Example: <weekOfPreference ordering="weekOfYear weekOfDate weekOfMonth" locales="fi zh_TW"/>
    while( my $el = $weekPrefsRest->shift )
    {
        my $locales = $el->getAttribute( 'locales' ) ||
            die( "No attribute 'locales' for this element: ", $el->toString() );
        # Example: <weekOfPreference ordering="weekOfYear weekOfDate weekOfMonth" locales="fi zh_TW"/>
        $locales =~ tr/_/-/;
        $locales = [split( /[[:blank:]\h\v]+/, $locales )];
        my $prefs = $el->getAttribute( 'ordering' ) ||
            die( "No attribute 'ordering' for this element: ", $el->toString() );
        $prefs = [split( /[[:blank:]\h\v]+/, $prefs )];
        foreach my $locale ( @$locales )
        {
            # Should not be needed, but better safe than sorry
            if( index( $locale, 'root' ) != -1 )
            {
                if( length( $locale ) > 4 )
                {
                    my $loc = Locale::Unicode->new( $locale );
                    $loc->language( 'und' );
                    $locale = $loc->as_string;
                }
                else
                {
                    $locale = 'und';
                }
            }
    
            $out->print( "[${locale}] " ) if( $DEBUG );
            eval
            {
                $sth->execute( $locale, to_array( $prefs ) );
            } || die( "Error adding week of preference information for locale '${locale}': ", ( $@ || $sth->errstr ) );
            $out->print( "ok\n" ) if( $DEBUG );
            $n++;
        }
    }
    &log( "${n} week of preference information added." );
    
    # NOTE: Loading code mappings
    &log( "Loading code mappings." );
    $n = 0;
    $sth = $sths->{code_mappings} || die( "No SQL statement object for code_mappings" );
    my $code_mappings =
    [
        { type => 'territory', xpath => '//codeMappings/territoryCodes' },
        { type => 'currency', xpath => '//codeMappings/currencyCodes' },
    ];
    foreach my $this ( @$code_mappings )
    {
        my $mapRes = $suppDoc->findnodes( $this->{xpath} ) ||
            die( "Unable to get the $this->{type} information in file ${supplemental_data_file}" );
        if( !$mapRes->size )
        {
            die( "No $this->{type} information found in file ${supplemental_data_file}" );
        }
        while( my $el = $mapRes->shift )
        {
            my $def =
            {
                code => ( $el->getAttribute( 'type' ) || die( "Unable to get attribute 'type' for this code mapping element: ", $el->toString() ) ),
                alpha3 => $el->getAttribute( 'alpha3' ),
                numeric => $el->getAttribute( 'numeric' ),
                fips10 => $el->getAttribute( 'fips10' ),
                type => $this->{type},
            };
            $out->print( "$def->{type} / [$def->{code}] " ) if( $DEBUG );
            eval
            {
                $sth->execute( @$def{qw( code alpha3 numeric fips10 type )} );
            } || die( "Error adding code mapping information for code '$def->{code}' of type $this->{type}: ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
            $out->print( "ok\n" ) if( $DEBUG );
            $n++;
        }
    }
    &log( "${n} code mappings added." );
    
    # NOTE: Loading person name defaults
    &log( "Loading person name defaults." );
    $n = 0;
    my $nameOrderRes = $suppDoc->findnodes( '//personNamesDefaults/nameOrderLocalesDefault' ) ||
        die( "Unable to get the name order locale information from file ${supplemental_data_file}" );
    if( !$nameOrderRes->size )
    {
        die( "No name order locale information found in file ${supplemental_data_file}" );
    }
    $sth = $sths->{person_name_defaults} || die( "No SQL statement object for person_name_defaults" );
    # Example: <nameOrderLocalesDefault order="surnameFirst">hu ja km ko mn si ta te vi yue zh</nameOrderLocalesDefault>
    while( my $el = $nameOrderRes->shift )
    {
        my $value = $el->getAttribute( 'order' ) ||
            die( "No attribute 'order' found for this person name defaults element: ", $el->toString() );
        $out->print( "[${value}] " ) if( $DEBUG );
        my $locales = $el->textContent ||
            die( "No text content found for this person name defaults element: ", $el->toString() );
        $locales = [split( /[[:blank:]\h\v]+/, $locales )];
        foreach my $locale ( @$locales )
        {
            # There should be no need, but that might change in future release of CLDR
            $locale =~ tr/_/-/;
            # Should not be needed, but better safe than sorry
            if( index( $locale, 'root' ) != -1 )
            {
                if( length( $locale ) > 4 )
                {
                    my $loc = Locale::Unicode->new( $locale );
                    $loc->language( 'und' );
                    $locale = $loc->as_string;
                }
                else
                {
                    $locale = 'und';
                }
            }
            eval
            {
                $sth->execute( $locale, $value );
            } || die( "Error adding person name defaults information for value '${value}' and locale '${locale}': ", ( $@ || $sth->errstr ) );
            $n++;
        }
        $out->print( "ok\n" ) if( $DEBUG );
    }
    &log( "${n} person name defaults added." );
    
    # NOTE: Loading Rule-Based Number Formats
    &log( "Loading Rule-Based Number Formats." );
    $n = 0;
    $rbnf_dir->open || die( $rbnf_dir->error );
    $sth = $sths->{rbnf} || die( "No SQL statement object for rbnf" );
    # while( my $f = $rbnf_dir->read( as_object => 1, exclude_invisible => 1 ) )
    @files = $rbnf_dir->read( as_object => 1, exclude_invisible => 1, 'sort' => 1 );
    foreach my $f ( @files )
    {
        next unless( $f->extension eq 'xml' );
        my $rbnfDoc = load_xml( $f );
        my $locale = identity_to_locale( $rbnfDoc );
        ( my $locale2 = $f->basename( '.xml' ) ) =~ tr/_/-/;
        if( lc( $locale ) ne lc( $locale2 ) &&
            $locale2 ne 'root' )
        {
            warn( "XML identity says the locale is '${locale}', but the file basename says it should be '${locale2}', and I think the file basename is correct for file $f" );
            $locale = $locale2;
        }
        if( index( $locale, 'root' ) != -1 )
        {
            if( length( $locale ) > 4 )
            {
                my $loc = Locale::Unicode->new( $locale );
                $loc->language( 'und' );
                $locale = $loc->as_string;
            }
            else
            {
                $locale = 'und';
            }
        }
        $out->print( "[${locale}] " ) if( $DEBUG );
        my $rbnfRes = $rbnfDoc->findnodes( '//rbnf/rulesetGrouping' );
        if( !$rbnfRes->size )
        {
            warn( "Warning only: no RBNF grouping found for locale '${locale}' in file $f" );
            $out->print( "ignored\n" ) if( $DEBUG );
            next;
        }
        while( my $el = $rbnfRes->shift )
        {
            my $grouping = $el->getAttribute( 'type' ) ||
                die( "Unable to get the attribute 'type' for this grouping element: ", $el->toString() );
            my @sets = $el->getChildrenByTagName( 'ruleset' );
            foreach my $set ( @sets )
            {
                my $ruleset = $set->getAttribute( 'type' ) ||
                    die( "Unable to get the attribute 'type' for this ruleset: ", $set->toString() );
                my @rules = $set->getChildrenByTagName( 'rbnfrule' );
                foreach my $rule ( @rules )
                {
                    my $id;
                    if( !length( ( $id = $rule->getAttribute( 'value' ) ) // '' ) )
                    {
                        die( "Unable to get the attribute 'value' for this rule: ", $rule->toString() );
                    }
                    my $value = $rule->textContent;
                    if( !defined( $value ) ||
                        !length( $value ) )
                    {
                        die( "Unable to get the rule value for the rule id '${id}' in grouping '${grouping}': ", $rule->toString() );
                    }
                    eval
                    {
                        $sth->execute( $locale, $grouping, $ruleset, $id, $value );
                    } || die( "Error adding RBNF information for groupind '${grouping}, locale '${locale}', rule set '${ruleset}', and id '${id}': ", ( $@ || $sth->errstr ) );
                    $n++;
                }
            }
        }
        $out->print( "ok\n" ) if( $DEBUG );
    }
    &log( "${n} RBNF rules added." );
    
    # NOTE: Loading references
    &log( "Loading references." );
    $n = 0;
    my $refsRes = $suppDoc->findnodes( '//references/reference' ) ||
        die( "Unable to get the 'reference' nodes in ${supplemental_data_file}" );
    if( !$refsRes->size )
    {
        die( "No 'reference' node could be found in ${supplemental_data_file}" );
    }
    $sth = $sths->{refs} || die( "No SQL statement object for refs" );
    while( my $el = $refsRes->shift )
    {
        my $def =
        {
            code => ( $el->getAttribute( 'type' ) || die( "No attribute 'type' found for this reference element: ", $el->toString() ) ),
            uri => $el->getAttribute( 'uri' ),
            description => $el->textContent,
        };
        $out->print( "[$def->{code}] " ) if( $DEBUG );
        $def->{description} = undef if( $def->{description} eq '[missing]' );
        # Decode HTML entities if there is a description and the character '&' is contained
        if( defined( $def->{description} ) &&
            index( $def->{description}, '&' ) != -1 &&
            index( $def->{description}, ';' ) != -1 )
        {
            $def->{description} = decode_entities( $def->{description} );
        }
    
        if( defined( $def->{description} ) &&
            length( $def->{description} ) )
        {
            $def->{description} = trim( $def->{description} );
        }
        $def->{description} = undef unless( length( $def->{description} // '' ) );
    
        eval
        {
            $sth->execute( @$def{qw( code uri description )} );
        } || die( "Error adding reference information for code '$def->{code}': ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
        $out->print( "ok\n" ) if( $DEBUG );
        $n++;
    }
    &log( "${n} references added." );
    
    # NOTE: Loading BCP47 extensions
    &log( "Loading BCP47 extensions and values." );
    $n = 0;
    $bcp47_dir->open || die( "Unable to open BCP47 directory: ", $bcp47_dir->error );
    $sth = $sths->{bcp47_extensions} || die( "No SQL statement object for bcp47_extensions" );
    my $sth_bcp_sth = $sths->{bcp47_values} || die( "No SQL statement object for bcp47_values" );
    # while( my $f = $bcp47_dir->read( as_object => 1, exclude_invisible => 1 ) )
    @files = $bcp47_dir->read( as_object => 1, exclude_invisible => 1, 'sort' => 1 );
    foreach my $f ( @files )
    {
        next unless( $f->extension eq 'xml' );
        my $cat = $f->basename( '.xml' );
        $cat =~ tr/-/_/;
        $out->print( "[${cat}] " ) if( $DEBUG );
        my $extDom = load_xml( $f );
        my $classesRes = $extDom->findnodes( '//keyword/key' ) ||
            die( "Error getting the BCP47 classes from file $f" );
        die( "No information found for category '${cat}' in file $f" ) if( !$classesRes->size );
        # <key name="ca" description="Calendar algorithm key" valueType="incremental" alias="calendar">
        # <key name="kh" deprecated="true" description="Collation parameter key for special Hiragana handling" alias="colHiraganaQuaternary">
        while( my $el = $classesRes->shift )
        {
            my $def =
            {
                category => $cat,
                extension => ( $el->getAttribute( 'name' ) || die( "Unable to get the attribute 'name' from file ${f} on this element: ", $el->toString() ) ),
                alias => $el->getAttribute( 'alias' ),
                value_type => $el->getAttribute( 'valueType' ),
                description => $el->getAttribute( 'description' ),
                deprecated => $el->getAttribute( 'deprecated' ),
            };
            if( defined( $def->{deprecated} ) &&
                length( $def->{deprecated} // '' ) )
            {
                if( exists( $boolean_map->{ $def->{deprecated} } ) )
                {
                    $def->{deprecated} = $boolean_map->{ $def->{deprecated} };
                }
                else
                {
                    die( "The BCP47 extension $def->{extension} has a deprecated status ($def->{deprecated}), but its value is unknown (neither true or false): ", dump( $def ) );
                }
            }
    
            eval
            {
                $sth->execute( @$def{qw( category extension alias value_type description deprecated )} );
            } || die( "Error adding BCP47 extension information for category '$def->{category}' and extension '$def->{extension}' from file ${f}: ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
            $n++;
    
            my @values = $el->getChildrenByTagName( 'type' );
            scalar( @values ) || die( "No data found for BCP47 extension '$def->{extension}' in category '${cat}' in file ${f}" );
            # <type name="japanese" description="Japanese Imperial calendar"/>
            foreach my $el_val ( @values )
            {
                my $val = $el_val->getAttribute( 'name' ) ||
                    die( "Unable to get an extension value attribute for category '${cat}' and extension '$def->{extension}' from file ${f} for element: ", $el_val->toString() );
                my $desc = $el_val->getAttribute( 'description' ) ||
                    die( "Unable to get an extension description attribute for category '${cat}' and extension '$def->{extension}' from file ${f} for element: ", $el_val->toString() );
                eval
                {
                    $sth_bcp_sth->execute( $cat, $def->{extension}, $val, $desc );
                } || die( "Error adding BCP47 extension value information for value '${val}' and category '$def->{category}' and extension '$def->{extension}' from file ${f}: ", ( $@ || $sth_bcp_sth->errstr ) );
            }
        }
        $out->print( "ok\n" ) if( $DEBUG );
        $n++;
    }
    &log( "${n} extensions data added." );
    
    # NOTE: Loading casings
    &log( "Loading casings." );
    $casings_dir->open || die( "Unable to open directory $casings_dir: ", $casings_dir->error );
    $n = 0;
    $sth = $sths->{casings} || die( "No SQL statements object for casings table." );
    # while( my $f = $casings_dir->read( as_object => 1, exclude_invisible => 1 ) )
    @files = $casings_dir->read( as_object => 1, exclude_invisible => 1, 'sort' => 1 );
    foreach my $f ( @files )
    {
        next unless( $f->extension eq 'xml' );
        my $basename = $f->basename( '.xml' );
        my $locDoc = load_xml( $f );
        my $locale = identity_to_locale( $locDoc );
        ( my $locale2 = $basename ) =~ tr/_/-/;
        if( lc( $locale ) ne lc( $locale2 ) &&
            $locale2 ne 'root' )
        {
            warn( "XML identity says the locale is '${locale}', but the file basename says it should be '${locale2}', and I think the file basename is correct for file $f" );
            $locale = $locale2;
        }
        if( index( $locale, 'root' ) != -1 )
        {
            if( length( $locale ) > 4 )
            {
                my $loc = Locale::Unicode->new( $locale );
                $loc->language( 'und' );
                $locale = $loc->as_string;
            }
            else
            {
                $locale = 'und';
            }
        }
        $out->print( "[${locale}] " ) if( $DEBUG );
        my $elemsRes = $locDoc->findnodes( '//casingData/casingItem' );
        if( !$elemsRes->size )
        {
            warn( "Warning only: no casing items found for locale '${locale}' in file $f" );
            $out->print( "ignored. No data\n" ) if( $DEBUG );
            next;
        }
        # <casingItem type="calendar_field">lowercase</casingItem>
        # There should be 22 to 24 of those casing tokens
        my $cnt = 0;
        while( my $el = $elemsRes->shift )
        {
            my $token = $el->getAttribute( 'type' ) ||
                die( "No attribute 'type' found for this casing element: ", $el->toString() );
            my $value = $el->textContent ||
                die( "No value found for this casing element '${token}': ", $el->toString() );
            eval
            {
                $sth->execute( $locale, $token, $value );
            } || die( "Error adding casing information for locale '${locale}' and token '${token}' and value '${value}' for file ${f}: ", ( $@ || $sth->errstr ) );
            $cnt++;
        }
        $out->print( "ok -> ${cnt} rows\n" ) if( $DEBUG );
        $n++;
    }
    &log( "${n} locale casing information added." );
    
    # NOTE: Loading day periods
    &log( "Loading day periods." );
    $n = 0;
    my $total_locales = 0;
    my $day_periods_file = $basedir->child( 'supplemental/dayPeriods.xml' );
    my $dayPeriodsDoc = load_xml( $day_periods_file );
    $sth = $sths->{day_periods} || die( "No SQL statement object for day_periods" );
    my $rules = $dayPeriodsDoc->findnodes( '//dayPeriodRuleSet[not(@type)]/dayPeriodRules' ) ||
        die( "Unable to find day periods ruleset in file $day_periods_file" );
    if( !$rules->size )
    {
        die( "No rules found in day period XML file $day_periods_file" );
    }
    # Example: <dayPeriodRules locales="nb nn no">
    while( my $el = $rules->shift )
    {
        my $locales = $el->getAttribute( 'locales' ) || die( "No attribute 'locales' found for this day period element: ", $el->toString() );
        $locales = [split( /[[:blank:]\h\v]+/, $locales )];
        # Example: <dayPeriodRule type="midnight" at="00:00"/>
        # <dayPeriodRule type="morning1" from="06:00" before="10:00"/>
        my $dpRules = $el->findnodes( './dayPeriodRule' );
        if( !$dpRules->size )
        {
            warn( "Warning only: unable to find child elements 'dayPeriodRule' for locale '", join( ', ', @$locales ), "' for this day period rule set in file ${day_periods_file}: ", $el->toString() );
        }
        while( my $el_rule = $dpRules->shift )
        {
            my $token = $el_rule->getAttribute( 'type' ) ||
                die( "No attribute 'type' for this day period rule element: ", $el_rule->toString() );
            my( $from, $before );
            if( $el_rule->hasAttribute( 'at' ) )
            {
                $from = $before = $el_rule->getAttribute( 'at' ) ||
                    die( "Unable to get attribute 'at' for this day period element: ", $el_rule->toString() );
            }
            else
            {
                $from = $el_rule->getAttribute( 'from' ) ||
                    die( "Unable to get attribute 'from' for this day period element: ", $el_rule->toString() );
                $before = $el_rule->getAttribute( 'before' ) ||
                    die( "Unable to get attribute 'before' for this day period element: ", $el_rule->toString() );
            }

            foreach my $locale ( @$locales )
            {
                # Should not be needed, but better safe than sorry
                $locale =~ tr/_/-/;
                if( index( $locale, 'root' ) != -1 )
                {
                    if( length( $locale ) > 4 )
                    {
                        my $loc = Locale::Unicode->new( $locale );
                        $loc->language( 'und' );
                        $locale = $loc->as_string;
                    }
                    else
                    {
                        $locale = 'und';
                    }
                }
    
                eval
                {
                    $sth->execute( $locale, $token, $from, $before );
                } || die( "Error adding day period information for locale '${locale}' and token '${token}': ", ( $@ || $sth->errstr ) );
                $n++;
            }
            $total_locales += scalar( @$locales );
        }
    }

    &log( "${n} day periods added for ${total_locales} locales." );

    # NOTE: Loading localised data
    &log( "Loading localised data." );
    $n = 0;
    $main_dir->open || die( $main_dir->error );
    my $sth_locale = $sths->{locales_l10n} || die( "No SQL statement object for locales_l10n" );
    my $sth_script = $sths->{scripts_l10n} || die( "No SQL statement object for scripts_l10n" );
    my $sth_territory = $sths->{territories_l10n} || die( "No SQL statement object for territories_l10n" );
    my $sth_variant = $sths->{variants_l10n} || die( "No SQL statement object for variants_l10n" );
    my $sth_currency = $sths->{currencies_l10n} || die( "No SQL statement object for currencies_l10n" );
    my $sth_cal_term = $sths->{calendar_terms} || die( "No SQL statement object for calendar_terms" );
    my $sth_cal_era = $sths->{calendar_eras_l10n} || die( "No SQL statement object for calendar_eras_l10n" );
    my $sth_dt_fmt = $sths->{calendar_formats_l10n} || die( "No SQL statement object for calendar_formats_l10n" );
    my $sth_dt_pat_fmt = $sths->{calendar_datetime_formats} || die( "No SQL statement object for calendar_datetime_formats" );
    my $sth_avail_fmt = $sths->{calendar_available_formats} || die( "No SQL statement object for calendar_available_formats" );
    my $sth_append_fmt = $sths->{calendar_append_formats} || die( "No SQL statement object for calendar_append_formats" );
    my $sth_inter_fmt = $sths->{calendar_interval_formats} || die( "No SQL statement object for calendar_interval_formats" );
    my $sth_cyclic = $sths->{calendar_cyclics_l10n} || die( "No SQL statement object for calendar_cyclics_l10n" );
    my $sth_field = $sths->{date_fields_l10n} || die( "No SQL statement object for date_fields_l10n" );
    my $sth_time_rel = $sths->{time_relative_l10n} || die( "No SQL statement object for time_relative_l10n" );
    my $sth_date_term = $sths->{date_terms} || die( "No SQL statement object for date_terms" );
    my $sth_locale_info = $sths->{locales_info} || die( "No SQL statement object for locales_info" );
    my $sth_locale_num_sys = $sths->{locale_number_systems} || die( "No SQL statement object for locale_number_systems" );
    my $sth_num_sys_l10n = $sths->{number_systems_l10n} || die( "No SQL statement object for number_systems_l10n" );
    my $sth_cals_l10n = $sths->{calendars_l10n} || die( "No SQL statement object for calendars_l10n" );
    my $sth_collation_l10n = $sths->{collations_l10n} || die( "No SQL statement object for collations_l10n" );
    my $sth_timezone_city = $sths->{timezones_cities} || die( "No SQL statement object for timezones_cities" );
    my $sth_tz_formats = $sths->{timezones_formats} || die( "No SQL statement object for timezones_formats" );
    my $sth_tz_names = $sths->{timezones_names} || die( "No SQL statement object for timezones_names" );
    my $sth_metatz_names = $sths->{metazones_names} || die( "No SQL statement object for metazones_names" );
    my $patch =
    {
        '45.0' =>
        {
            calendar_interval_formats =>
            {
                'an' =>
                {
                    'yMEd' =>
                    {
                        # See CLDR bug report No 17800
                        # <https://unicode-org.atlassian.net/browse/CLDR-17800>
                        'M' => 'E, d/M/y – E, d/M/y',
                    },
                },
                'brx' =>
                {
                    'Md' =>
                    {
                        # See CLDR bug report No 17808
                        # <https://unicode-org.atlassian.net/browse/CLDR-17808>
                        'M' => 'd/M – d/M',
                    },
                },
                'hi' =>
                {
                    'GyM' =>
                    {
                        # See CLDR bug report No 17809
                        # <https://unicode-org.atlassian.net/browse/CLDR-17809>
                        'M' => 'GGGGG M/y – M/y',
                    },
                },
            },
        },
    };
    my $localesRes;
    #while( my $f = $main_dir->read( as_object => 1, exclude_invisible => 1, 'sort' => 1 ) )
    @files = $main_dir->read( as_object => 1, exclude_invisible => 1, 'sort' => 1 );
    # We need to process root.xml first, as it hold some core default values such as for date/time format skeletons that are not always present in other locales
    my $root_file;
    for( my $i = 0; $i < scalar( @files ); $i++ )
    {
        my $f = $files[$i];
        if( $f->basename eq 'root.xml' )
        {
            $root_file = $f;
            splice( @files, $i, 1 );
            last;
        }
    }
    if( !defined( $root_file ) )
    {
        die( "I was unable to find the root.xml file in ${main_dir}" );
    }
    unshift( @files, $root_file );

    # calendar_id -> date|time -> full|long|medium|short = datetimeSkeleton
    my $calendars_date_time_skeletons = {};
    $out->printf( "Processing %d localised data files.\n", scalar( @files ) ) if( $DEBUG );
    foreach my $f ( @files )
    {
        next unless( $f->extension eq 'xml' );
        my $mainDoc = load_xml( $f );
        my $locale = identity_to_locale( $mainDoc );
        ( my $locale2 = $f->basename( '.xml' ) ) =~ tr/_/-/;
        if( lc( $locale ) ne lc( $locale2 ) &&
            $locale2 ne 'root' )
        {
            warn( "XML identity says the locale is '${locale}', but the file basename says it should be '${locale2}', and I think the file basename is correct for file $f" );
            $locale = $locale2;
        }
        if( index( $locale, 'root' ) != -1 )
        {
            if( length( $locale ) > 4 )
            {
                my $loc = Locale::Unicode->new( $locale );
                $loc->language( 'und' );
                $locale = $loc->as_string;
            }
            else
            {
                $locale = 'und';
            }
        }
        $out->print( "Processing ${locale} data from file ${f}\n" ) if( $DEBUG );
        my $added = {};
        # Check whether there is any data at all. Some XML file, such as the one for ja_JP.xml contains only the 'identity' tag
        my $hasData = $mainDoc->findnodes( '//localeDisplayNames' );
        if( $hasData->size )
        {
            # NOTE: Loading locales L10N
            &log( "[${locale}] Loading Locales L10N for locale ${locale}." );
            $localesRes = $mainDoc->findnodes( '//localeDisplayNames/languages/language[@type and not(@menu)]' );
            if( !$localesRes->size )
            {
                warn( "Warning only: no locales localised names found for locale '${locale}' in file $f" );
            }
            # Example: <language type="ja">japonais</language>
            while( my $el = $localesRes->shift )
            {
                my $id = $el->getAttribute( 'type' ) ||
                    die( "Unable to get the attribute 'type' value for this element in file $f: ", $el->toString() );
                my $val = $el->textContent;
                if( index( $val, '&' ) != -1 &&
                    index( $val, ';' ) != -1 )
                {
                    $val = decode_entities( $val );
                }
                # Unfortunately, it seems that they are not 'languages', but 'locales', so this is a misnomer
                # And, it is formatted with underscore when the canonical version is with a dash ('-')
                $id =~ tr/_/-/;
                if( index( $id, 'root' ) != -1 )
                {
                    if( length( $id ) > 4 )
                    {
                        my $loc = Locale::Unicode->new( $id );
                        $loc->language( 'und' );
                        $id = $loc->as_string;
                    }
                    else
                    {
                        $id = 'und';
                    }
                    
                    my $hasUndLocaleRes = $mainDoc->findnodes( '/ldml/localeDisplayNames/languages/language[@type="und"]' );
                    if( $id eq 'und' &&
                        $hasUndLocaleRes->size )
                    {
                        warn( "Found locale ID 'root', but there is already a locale ID 'und' that is also defined for locale ${locale} in file ${f}, skipping." );
                        next;
                    }
                }
                my $def =
                {
                    locale      => $locale,
                    locale_id   => $id,
                    locale_name => $val,
                };
                if( $el->hasAttribute( 'alt' ) )
                {
                    $def->{alt} = $el->getAttribute( 'alt' );
                }

                eval
                {
                    $sth_locale->execute( @$def{qw( locale locale_id locale_name alt )} );
                } || die( "Error adding localised information from file ${f} for locale ${locale} and locale ID '${id}': ", ( $@ || $sth_locale->errstr ), "\nwith query: ", $sth_locale->{Statement}, "\n", dump( $def )  );
                $added->{languages}++;
            }

            # NOTE: Loading script L10N
            &log( "\tLoading script L10N." );
            $localesRes = $mainDoc->findnodes( '//localeDisplayNames/scripts/script[@type]' );
            if( !$localesRes->size )
            {
                warn( "Warning only: no scripts localised names found for locale '${locale}' in file $f" );
            }
            # Example: <script type="Jpan">japonais</script>
            while( my $el = $localesRes->shift )
            {
                my $id = $el->getAttribute( 'type' ) ||
                    die( "Unable to get the attribute 'type' value for this element in file $f: ", $el->toString() );
                my $val = $el->textContent;
                if( index( $val, '&' ) != -1 &&
                    index( $val, ';' ) != -1 )
                {
                    $val = decode_entities( $val );
                }
                my $alt;
                if( $el->hasAttribute( 'alt' ) )
                {
                    $alt = $el->getAttribute( 'alt' );
                }
        
                eval
                {
                    $sth_script->execute( $locale, $id, $val, $alt );
                } || die( "Error adding localised information from file ${f} for locale ${locale} and for script ${id}: ", ( $@ || $sth_script->errstr ), "\nwith query: ", $sth_script->{Statement} );
                $added->{scripts}++;
            }
        
            # NOTE: Loading territories L10N
            &log( "\tLoading territories L10N." );
            $localesRes = $mainDoc->findnodes( '//localeDisplayNames/territories/territory[@type]' );
            if( !$localesRes->size )
            {
                warn( "Warning only: no territories localised names found for locale '${locale}' in file $f" );
            }
            # Example: <territory type="JP">Japon</territory>
            while( my $el = $localesRes->shift )
            {
                my $id = $el->getAttribute( 'type' ) ||
                    die( "Unable to get the attribute 'type' value for this element in file $f: ", $el->toString() );
                my $val = $el->textContent;
                if( index( $val, '&' ) != -1 &&
                    index( $val, ';' ) != -1 )
                {
                    $val = decode_entities( $val );
                }
                my $alt;
                if( $el->hasAttribute( 'alt' ) )
                {
                    $alt = $el->getAttribute( 'alt' );
                }
        
                eval
                {
                    $sth_territory->bind_param( 1, $locale, SQL_VARCHAR );
                    $sth_territory->bind_param( 2, "$id", SQL_VARCHAR );
                    $sth_territory->bind_param( 3, $val, SQL_VARCHAR );
                    $sth_territory->bind_param( 4, $alt, SQL_VARCHAR );
                    $sth_territory->execute;
                } || die( "Error adding localised information from file ${f} for locale ${locale} and for territory ${id}: ", ( $@ || $sth_territory->errstr ), "\nwith query: ", $sth_territory->{Statement} );
                $added->{territories}++;
            }
        
            # NOTE: Loading variants L10N
            &log( "\tLoading variants L10N." );
            $localesRes = $mainDoc->findnodes( '//localeDisplayNames/variants/variant[@type]' );
            if( !$localesRes->size )
            {
                warn( "Warning only: no variants localised names found for locale '${locale}' in file $f" );
            }
            # Example: <variant type="VALENCIA">valencien</variant>
            while( my $el = $localesRes->shift )
            {
                my $id = $el->getAttribute( 'type' ) ||
                    die( "Unable to get the attribute 'type' value for this element in file $f: ", $el->toString() );
                my $val = $el->textContent;
                if( index( $val, '&' ) != -1 &&
                    index( $val, ';' ) != -1 )
                {
                    $val = decode_entities( $val );
                }
                $id = lc( $id );
                my $alt;
                if( $el->hasAttribute( 'alt' ) )
                {
                    $alt = $el->getAttribute( 'alt' );
                }
        
                eval
                {
                    $sth_variant->execute( $locale, $id, $val, $alt );
                } || die( "Error adding localised information from file ${f} for locale ${locale} and for variant ${id}: ", ( $@ || $sth_variant->errstr ), "\nwith query: ", $sth_variant->{Statement} );
                $added->{variants}++;
            }
        
            # NOTE: Loading currencies L10N
            &log( "\tLoading currencies L10N." );
            $localesRes = $mainDoc->findnodes( '//numbers/currencies/currency[@type]' );
            if( !$localesRes->size )
            {
                warn( "Warning only: unable to get the localised names for locale '${locale}' for currencies in file $f" );
            }
            # Example:
            # <currency type="JPY">
            #     <displayName>Japanese Yen</displayName>
            #     <displayName count="one">Japanese yen</displayName>
            #     <displayName count="other">Japanese yen</displayName>
            #     <symbol>¥</symbol>
            # </currency>
            while( my $el = $localesRes->shift )
            {
                my $id = $el->getAttribute( 'type' ) ||
                    die( "Unable to get the attribute 'type' value for this element in file $f: ", $el->toString() );
                my $def =
                {
                    locale      => $locale,
                    currency    => $id,
                };
                my $symbolRes = $el->findnodes( './symbol' );
                if( $symbolRes->size )
                {
                    my $el_symbol = $symbolRes->shift;
                    $def->{symbol} = trim( $el_symbol->textContent );
                }
                my $namesRes = $el->findnodes( './displayName' );
                if( !$namesRes->size )
                {
                    warn( "Warning only: currency '${id}' exists for locale ${locale}, but no localised names is defined in file $f for this element: ", $el->toString() ) unless( $locale eq 'und' );
                }
                while( my $el_name = $namesRes->shift )
                {
                    if( $el_name->hasAttribute( 'count' ) )
                    {
                        $def->{count} = $el_name->getAttribute( 'count' ) ||
                            die( "No value provided for 'count' for this currency '${id}' locale name value in file $f: ", $el_name->toString() );
                    }
                    else
                    {
                        $def->{count} = undef;
                    }
                    my $val = $el_name->textContent;
                    if( index( $val, '&' ) != -1 &&
                        index( $val, ';' ) != -1 )
                    {
                        $val = decode_entities( $val );
                    }
                    $def->{locale_name} = $val;
        
                    eval
                    {
                        $sth_currency->execute( @$def{qw( locale currency count locale_name symbol )} );
                    } || die( "Error adding localised information from file ${f} for locale ${locale} and for currency ${id}: ", ( $@ || $sth_currency->errstr ), "\nwith query: ", $sth_currency->{Statement}, "\n", dump( $def ) );
                    $added->{currencies}++;
                }
            }
        }
        else
        {
            $out->print( "no data, skipping.\n" ) if( $DEBUG );
            # next;
        }
    
        # NOTE: Load calendar terms, locale eras, formats, timezones and more
        &log( "\tLoad calendar terms, locale eras, formats and more." );
        my $calLocalesDatesRes = $mainDoc->findnodes( '/ldml/dates' );
        if( $calLocalesDatesRes->size )
        {
            my $el_dates = $calLocalesDatesRes->shift;
            my $calLocalesCalendarsRes = $el_dates->findnodes( './calendars/calendar' );
            if( !$calLocalesCalendarsRes->size )
            {
                warn( "Warning only: unable to get the localised terms for locale '${locale}' for calendars in file $f" );
            }
            # <calendar type="gregorian">
            while( my $el = $calLocalesCalendarsRes->shift )
            {
                my $cal_id = $el->getAttribute( 'type' ) ||
                    die( "Unable to get the calendar ID value from attribute 'type' for this element in file $f: ", $el->toString() );
                # NOTE: Check for calendar terms
                my $cal_term_types =
                {
                    month =>
                        {
                            xpath_container => './months',
                            xpath_context   => './monthContext',
                            xpath_width     => './monthWidth',
                            xpath_terms     => './month',
                        },
                    day =>
                        {
                            xpath_container => './days',
                            xpath_context   => './dayContext',
                            xpath_width     => './dayWidth',
                            xpath_terms     => './day',
                        },
                    quarter =>
                        {
                            xpath_container => './quarters',
                            xpath_context   => './quarterContext',
                            xpath_width     => './quarterWidth',
                            xpath_terms     => './quarter',
                        },
                    day_period =>
                        {
                            xpath_container => './dayPeriods',
                            xpath_context   => './dayPeriodContext',
                            xpath_width     => './dayPeriodWidth',
                            xpath_terms     => './dayPeriod',
                        },
                };
                foreach my $type ( sort( keys( %$cal_term_types ) ) )
                {
                    my $this = $cal_term_types->{ $type };
                    my $calTermContainerRes = $el->findnodes( $this->{xpath_container} );
                    if( !$calTermContainerRes->size )
                    {
                        $out->print( "\tNo terms container of type ${type} found for calendar ${cal_id} for locale ${locale} in file ${f}\n" ) if( $DEBUG );
                        next;
                    }
                    my $el_container = $calTermContainerRes->shift;
                    # Example:
                    # <days>
                    #     <alias source="locale" path="../../calendar[@type='gregorian']/days"/>
                    # </days>
                    # <quarters>
                    #     <alias source="locale" path="../../calendar[@type='gregorian']/quarters"/>
                    # </quarters>
                    # <dayPeriods>
                    #     <alias source="locale" path="../../calendar[@type='gregorian']/dayPeriods"/>
                    # </dayPeriods>
                    my $calTermContainerHasAliasRes = $el_container->findnodes( './alias[@path]' );
                    if( $calTermContainerHasAliasRes->size )
                    {
                        $out->print( "\tCalendar ${cal_id} terms container of type ${type} is aliased. Resolving it... " ) if( $DEBUG );
                        $el_container = resolve_alias( $calTermContainerHasAliasRes ) ||
                            die( "Calendar ${cal_id} terms containers of type ${type} is aliased, but the resolved element contains nothing for locale ${locale} in file ${f}" );
                        $out->print( "ok\n" ) if( $DEBUG );
                    }
                    my $calTermContextRes = $el_container->findnodes( $this->{xpath_context} );
                    # <monthContext type="format">
                    while( my $el_context = $calTermContextRes->shift )
                    {
                        my $context = $el_context->getAttribute( 'type' ) ||
                            die( "This calendar ${cal_id} ${type} context has no attribute 'type' value in file $f: ", $el_context->toString() );
                        my $calTermContextHasAliasRes = $el_context->findnodes( './alias[@path]' );
                        if( $calTermContextHasAliasRes->size )
                        {
                            $out->print( "\tCalendar ${cal_id} terms context of type ${type} is aliased. Resolving it... " ) if( $DEBUG );
                            $el_context = resolve_alias( $calTermContextHasAliasRes ) ||
                                die( "Calendar ${cal_id} terms context of type ${type} is aliased, but the resolved element contains nothing for locale ${locale} in file ${f}" );
                            $out->print( "ok\n" ) if( $DEBUG );
                        }
                        my $calTermWidthRes = $el_context->findnodes( $this->{xpath_width} );
                        # <monthWidth type="abbreviated">
                        while( my $el_term_width = $calTermWidthRes->shift )
                        {
                            my $width = $el_term_width->getAttribute( 'type' );
                            my $calTermWidthHasAliasRes = $el_term_width->findnodes( './alias[@path]' );
                            if( $calTermWidthHasAliasRes->size )
                            {
                                $out->print( "\tCalendar ${cal_id} terms width of type ${type} is aliased. Resolving it... " ) if( $DEBUG );
                                $el_term_width = resolve_alias( $calTermWidthHasAliasRes ) ||
                                    die( "Calendar ${cal_id} terms width of type ${type} for context ${context} is aliased, but the resolved element contains nothing for locale ${locale} in file ${f}" );
                                $out->print( "ok\n" ) if( $DEBUG );
                            }
                            my $calTermsRes = $el_term_width->findnodes( $this->{xpath_terms} );
                            # <month type="1">Jan</month>
                            while( my $el_term = $calTermsRes->shift )
                            {
                                my $def =
                                {
                                    locale          => $locale,
                                    calendar        => $cal_id,
                                    term_type       => $type,
                                    term_context    => $context,
                                    term_width      => $width,
                                    term_name       => $el_term->getAttribute( 'type' ),
                                    term_value      => trim( $el_term->textContent ),
                                };
                                foreach my $att ( qw( alt yeartype ) )
                                {
                                    if( $el_term->hasAttribute( $att ) )
                                    {
                                        $def->{ $att } = $el_term->getAttribute( $att );
                                    }
                                }

                                eval
                                {
                                    $sth_cal_term->execute( @$def{qw( locale calendar term_type term_context term_width alt yeartype term_name term_value )} );
                                } || die( "Error executing query to add calendar ${cal_id} term of type '${type}' for locale '${locale}' and for calendar '${cal_id}' from file ${f}: ", ( $@ || $sth_cal_term->errstr ), "\nwith query: ", $sth_cal_term->{Statement}, "\n", dump( $def ) );
                                $added->{cal_terms}++;
                            }
                        }
                    }
                }
        
                # NOTE: Check for calendar eras
                &log( "\tCheck for calendar eras." );
                my $calErasRes = $el->findnodes( './eras' );
                if( $calErasRes->size )
                {
                    my $el_eras = $calErasRes->shift;
                    my $cal_eras_map =
                    {
                        wide =>  './eraNames',
                        abbreviated => './eraAbbr',
                        narrow => './eraNarrow',
                    };
                    foreach my $width ( sort( keys( %$cal_eras_map ) ) )
                    {
                        my $xpath = $cal_eras_map->{ $width };
                        my $calErasWidthRes = $el_eras->findnodes( $xpath );
                        if( !$calErasWidthRes->size )
                        {
                            $out->print( "\tno era width ${width} found, skipping.\n" ) if( $DEBUG );
                            next;
                        }
                        my $el_eras_width = $calErasWidthRes->shift;
                        my $calErasWidthHasAliasRes = $el_eras_width->findnodes( './alias[@path]' );
                        if( $calErasWidthHasAliasRes->size )
                        {
                            $el_eras_width = resolve_alias( $calErasWidthHasAliasRes ) ||
                                die( "Unable to resolve alias for calendar ${cal_id} of width ${width} for locale ${locale} in file ${f} for this element: ", $el_eras->toString() );
                        }
                        my $calErasDataRes = $el_eras_width->findnodes( './era' );
                        # <era type="0">Before Christ</era>
                        while( my $el_cal_era = $calErasDataRes->shift )
                        {
                            my $def =
                            {
                                locale      => $locale,
                                calendar    => $cal_id,
                                era_width   => $width,
                                era_id      => $el_cal_era->getAttribute( 'type' ),
                                locale_name => $el_cal_era->textContent,
                            };
                            if( $el_cal_era->hasAttribute( 'alt' ) )
                            {
                                $def->{alt} = $el_cal_era->getAttribute( 'alt' );
                            }
                            eval
                            {
                                $sth_cal_era->execute( @$def{qw( locale calendar era_width era_id alt locale_name )} );
                            } || die( "Error executing query to add calendar era of width '${width}' for locale '${locale}' and for calendar '${cal_id}' from file ${f}: ", ( $@ || $sth_cal_era->errstr ), "\nwith query: ", $sth_cal_era->{Statement}, "\n", dump( $def ) );
                            $added->{cal_era}++;
                        }
                    }
                }
                else
                {
                    $out->print( "\tno era found for calendar ${cal_id} in locale ${locale}\n" ) if( $DEBUG );
                }
        
                # NOTE: Check for calendar date/time formats
                &log( "\tCheck for calendar date/time formats." );
                my $cal_date_time_map =
                {
                    date =>
                        {
                            xpath_container => './dateFormats',
                            xpath_len       => './dateFormatLength',
                            xpath_fmt       => './dateFormat',
                            xpath_pat       => './pattern',
                            xpath_skel      => './datetimeSkeleton',
                        },
                    'time' =>
                        {
                            xpath_container => './timeFormats',
                            xpath_len       => './timeFormatLength',
                            xpath_fmt       => './timeFormat',
                            xpath_pat       => './pattern',
                            xpath_skel      => './datetimeSkeleton',
                        },
                };
                # <dateFormatLength type="full">
                # <timeFormatLength type="long">
                foreach my $type ( sort( keys( %$cal_date_time_map ) ) )
                {
                    $out->print( "\t\tChecking for formats for ${type}\n" ) if( $DEBUG );
                    my $this = $cal_date_time_map->{ $type };
                    # A cache of pattern value to their ID (skeleton) so we can lookup a missing skeleton for an identical pattern
                    my $cache_values = {};
                    my $calDateOrTimeContainerRes = $el->findnodes( $this->{xpath_container} );
                    if( !$calDateOrTimeContainerRes->size )
                    {
                        $out->print( "\t\tno format of type ${type} found for locale ${locale} for calendar ${cal_id}\n" ) if( $DEBUG );
                        next;
                    }
                    my $el_container = $calDateOrTimeContainerRes->shift;
                    my $calDtContainerHasAliasRes = $el_container->findnodes( './alias[@path]' );
                    if( $calDtContainerHasAliasRes->size )
                    {
                        $el_container = resolve_alias( $calDtContainerHasAliasRes ) ||
                            die( "The calendar formats container for ${type} is aliased, but could not get the resolved path for calendar ${cal_id} for locale ${locale} for this element in file $f: ", $el->toString() );
                    }
                    my $calDateOrTimeLengthRes = $el_container->findnodes( $this->{xpath_len} );
                    if( !$calDateOrTimeLengthRes->size )
                    {
                        die( "No calendar ${cal_id} format length tag found for locale ${locale} in file ${f} for this element: ", $el->toString() );
                    }
                    while( my $el_len = $calDateOrTimeLengthRes->shift )
                    {
                        my $len = $el_len->getAttribute( 'type' ) ||
                            die( "Unable to get the ${type} length type for locale ${locale} in file ${f} for this element in file $f: ", $el_len->toString() );
                        my $calDtLengthHasAliasRes = $el_len->findnodes( './alias[@path]' );
                        if( $calDtLengthHasAliasRes->size )
                        {
                            $el_len = resolve_alias( $calDtLengthHasAliasRes ) ||
                                die( "The calendar ${cal_id} format length ${len} is aliased, but I am unable to get the resolved path for locale ${locale} in file ${f} for this element: ", $el_container->toString() );
                        }
                        my $calDateOrTimeFormatRes = $el_len->findnodes( $this->{xpath_fmt} );
                        if( !$calDateOrTimeFormatRes->size )
                        {
                            $out->print( "\t\t\tno calendar ${cal_id} formats found for length ${len} for locale ${locale}\n" ) if( $DEBUG );
                            next;
                        }
                        my $el_fmt = $calDateOrTimeFormatRes->shift;
                        my $calDtFormatHasAliasRes = $el_fmt->findnodes( './alias[@path]' );
                        if( $calDtFormatHasAliasRes->size )
                        {
                            $el_fmt = resolve_alias( $calDtFormatHasAliasRes ) ||
                                die( "The Date or time format of type ${type} for length ${len} in calendar ${cal_id} is aliased, but I cannot resolve its path for locale ${locale} in file ${f} for this element: ", $el_len->toString() );
                        }
                        # <datetimeSkeleton>yMMMd</datetimeSkeleton>
                        my $calFormatIdRes = $el_fmt->findnodes( $this->{xpath_skel} );
                        # <pattern>MMM d, y</pattern>
                        my $calFormatValueRes = $el_fmt->findnodes( $this->{xpath_pat} );
                        my $pattern_id;
                        # if( !$calFormatIdRes->size )
                        # {
                        #     warn( "Warning only: no ID (skeleton) for this ${type} format for locale ${locale} in file ${f} for this element. Skipping: ", $el_len->toString() );
                        #     next;
                        # }
                        # elsif( $calFormatIdRes->size > 1 )
                        if( $calFormatIdRes->size > 1 )
                        {
                            die( "More than one ID (skeleton) found (", $calFormatValueRes->size, ") for this ${type} format for locale ${locale} in file ${f} for this element: ", $el_len->toString() );
                        }
                        elsif( $calFormatIdRes->size )
                        {
                            my $el_cal_fmt_id = $calFormatIdRes->shift ||
                                die( "No ${type} format ID (skeleton) element could be retrieved for locale ${locale} in file ${f} for this element: ", $el_len->toString() );
                            $pattern_id = $el_cal_fmt_id->textContent;
                            # NOTE: Save the pattern ID for this calendar date/time length for other locales missing it
                            # If we are processing the root locale, we keep a record of the pattern ID for this length and calendar
                            if( $locale eq 'und' )
                            {
                                $out->print( "\t\t\t[root] Saving pattern ID '${pattern_id}' for length '${len}' for type '${type}', and calendar ID '${cal_id}'\n" ) if( $DEBUG );
                                $calendars_date_time_skeletons->{ $cal_id } ||= {};
                                $calendars_date_time_skeletons->{ $cal_id }->{ $type } ||= {};
                                $calendars_date_time_skeletons->{ $cal_id }->{ $type }->{ $len } = $pattern_id;
                            }
                        }
    
                        if( !$calFormatValueRes->size )
                        {
                            die( "No value (pattern) for this ${type} format for locale ${locale} in file ${f} for this element: ", $el_len->toString() );
                        }
                        # my $pattern_id = $el_cal_fmt_id->textContent;
                        while( my $el_dt_val = $calFormatValueRes->shift )
                        {
                            my $pat_val = $el_dt_val->textContent;
                            if( !defined( $pattern_id ) )
                            {
                                if( exists( $calendars_date_time_skeletons->{ $cal_id }->{ $type }->{ $len } ) )
                                {
                                    $pattern_id = $calendars_date_time_skeletons->{ $cal_id }->{ $type }->{ $len };
                                    warn( "Warning only: ID (skeleton) for this type ${type} and length '${len}' and calendar '${cal_id}' and locale '${locale}' was missing, but could get it from the root cache." );
                                }
                                elsif( exists( $cache_values->{ $pat_val } ) )
                                {
                                    warn( "Warning only: no ID (skeleton) for this ${type} format for locale ${locale} in file ${f} for this element, but found a cache value (", $cache_values->{ $pat_val } , ") for pattern value '${pat_val}': ", $el_len->toString() );
                                    $pattern_id = $cache_values->{ $pat_val };
                                }
                                else
                                {
                                    warn( "Warning only: no ID (skeleton) for this ${type} format for locale ${locale} in file ${f} for this element and no cache value found either. Skipping: ", $el_len->toString() );
                                    next;
                                }
                            }
                            my $def =
                            {
                                locale          => $locale,
                                calendar        => $cal_id,
                                format_type     => $type,
                                format_length   => $len,
                                format_id       => $pattern_id,
                                format_pattern  => $pat_val,
                            };
                            $cache_values->{ $pat_val } = $pattern_id;
                            if( $el_dt_val->hasAttribute( 'alt' ) )
                            {
                                $def->{alt} = $el_dt_val->getAttribute( 'alt' );
                            }
        
                            eval
                            {
                                $sth_dt_fmt->execute( @$def{qw( locale calendar format_type format_length alt format_id format_pattern )} );
                            } || die( "Error executing query to add calendar ${type} format for ID '$def->{format_id}' for locale '${locale}' and for calendar '${cal_id}' from file ${f}: ", ( $@ || $sth_dt_fmt->errstr ), "\nwith query: ", $sth_dt_fmt->{Statement}, "\n", dump( $def ) );
                            $added->{cal_date_or_time_format}++;
                        }
                    }
                }
        
                # NOTE: Checking datetime formats
                &log( "\tChecking datetime formats." );
                my $calDateTimeContainerRes = $el->findnodes( './dateTimeFormats' );
                if( $calDateTimeContainerRes->size )
                {
                    my $el_container = $calDateTimeContainerRes->shift;
                    my $calDateTimeHasAliasRes = $el_container->findnodes( './alias[@path]' );
                    if( $calDateTimeHasAliasRes->size )
                    {
                        $out->print( "\t\tDateTime container for calendar ${cal_id} is aliased for locale ${locale}, resolving it.\n" ) if( $DEBUG );
                        $el_container = resolve_alias( $calDateTimeHasAliasRes ) ||
                            die( "DateTime container for calendar ${cal_id} is aliased, but could not resolve its path for locale ${locale} in file ${f}" );
                    }
                    my $calDateTimeLengthRes = $el_container->findnodes( './dateTimeFormatLength' );
                    # <dateTimeFormatLength type="full">
                    # full, long, medium, short
                    while( my $el_len = $calDateTimeLengthRes->shift )
                    {
                        my $len = $el_len->getAttribute( 'type' );
                        my $calDtLengthHasAliasRes = $el_len->findnodes( './alias[@path]' );
                        if( $calDtLengthHasAliasRes->size )
                        {
                            $out->print( "\t\t\tthe DateTime format length ${len} tag is aliased, resolving it.\n" ) if( $DEBUG );
                            $el_len = resolve_alias( $calDtLengthHasAliasRes ) ||
                                die( "The DateTime format length ${len} for calendar ${cal_id} is aliased, but I am unable to resolve it for locale ${locale} in file ${f} for this element: ", $el_len->toString() );
                        }
                        my $calFmtRes = $el_len->findnodes( './dateTimeFormat' );
                        while( my $el_fmt = $calFmtRes->shift )
                        {
                            # <dateTimeFormat type="atTime">
                            my $type = $el_fmt->hasAttribute( 'type' ) ? $el_fmt->getAttribute( 'type' ) : 'standard';
                            # Compensate for a bug (reported) where a 'type' attribute is missing on 'dateTimeFormat' tag, which would prevent any alias from resolving
                            # For example in file main/root.xml, <alias source="locale" path="../dateTimeFormat[@type='standard']"/> would fail, because there is no dateTimeFormat with 'type' attribute with value 'standard'
                            if( !$el_fmt->hasAttribute( 'type' ) )
                            {
                                $el_fmt->setAttribute( type => 'standard' );
                            }
                            $type = $el_fmt->getAttribute( 'type' );
                            my $calDtFormatHasAliasRes = $el_fmt->findnodes( './alias[@path]' );
                            if( $calDtFormatHasAliasRes->size )
                            {
                                $out->print( "\t\t\t\tThe calendar ${cal_id} DateTime format length ${len} format is aliased, resolving it.\n" ) if( $DEBUG );
                                $el_fmt = resolve_alias( $calDtFormatHasAliasRes ) ||
                                    die( "The calendar ${cal_id} DateTime format length ${len} format is aliased, but I am unable to resolve it for locale ${locale} in file ${f} for this element: ", $el_len->toString() );
                            }
                            my $calPatternsRes = $el_fmt->findnodes( './pattern' );
                            # <pattern>{1}, {0}</pattern>
                            while( my $el_pat = $calPatternsRes->shift )
                            {
                                my $def =
                                {
                                    locale          => $locale,
                                    calendar        => $cal_id,
                                    format_length   => $len,
                                    format_type     => $type,
                                    format_pattern  => $el_pat->textContent,
                                };
                                eval
                                {
                                    $sth_dt_pat_fmt->execute( @$def{qw( locale calendar format_length format_type format_pattern )} );
                                } || die( "Error executing query to add calendar ${type} format pattern '", ( $def->{format_pattern} // 'undef' ), "' for locale '${locale}' and for calendar '${cal_id}' from file ${f}: ", ( $@ || $sth_dt_pat_fmt->errstr ), "\nwith query: ", $sth_dt_pat_fmt->{Statement}, "\n", dump( $def ) );
                                $added->{cal_datetime_format}++;
                            }
                        }
                    }
        
                    # NOTE: Checking available datetime formats
                    &log( "\tChecking available datetime formats." );
                    my $calAvailableFormatsRes = $el_container->findnodes( './availableFormats' );
                    if( $calAvailableFormatsRes->size )
                    {
                        my $el_available = $calAvailableFormatsRes->shift;
                        my $calAvailableHasAliasRes = $el_available->findnodes( './alias[@path]' );
                        if( $calAvailableHasAliasRes->size )
                        {
                            $el_available = resolve_alias( $calAvailableHasAliasRes ) ||
                                die( "Calendard ${cal_id} available formats is aliased, but I could not resolve it for locale ${locale} in file ${f} for this element: ", $el_container->toString() );
                        }
                        my $calAvailableFormatsItemsRes = $el_available->findnodes( './dateFormatItem' );
                        # <dateFormatItem id="Bhms">h:mm:ss B</dateFormatItem>
                        while( my $el_item = $calAvailableFormatsItemsRes->shift )
                        {
                            my $def =
                            {
                                locale          => $locale,
                                calendar        => $cal_id,
                                format_id       => ( $el_item->getAttribute( 'id' ) ||
                                    die( "Unable to get the available format ID from the attribute 'id' in this element in file $f: ", $el_item->toString() ) ),
                                format_pattern  => $el_item->textContent,
                            };
                            if( !defined( $def->{format_pattern} ) ||
                                !length( $def->{format_pattern} // '' ) )
                            {
                                die( "No pattern found for this available format with id '$def->{format_id}' for calendar '${cal_id}' and locale '${locale}' in file $f: ", $el_item->toString() );
                            }
                
                            if( $el_item->hasAttribute( 'count' ) )
                            {
                                $def->{count} = $el_item->getAttribute( 'count' );
                            }
                
                            if( $el_item->hasAttribute( 'alt' ) )
                            {
                                $def->{alt} = $el_item->getAttribute( 'alt' );
                            }
                
                            eval
                            {
                                $sth_avail_fmt->execute( @$def{qw( locale calendar format_id format_pattern count alt )} );
                            } || die( "Error executing query to add calendar available format '", ( $def->{format_pattern} // 'undef' ), "' with id '$def->{format_id}' for locale '${locale}' and for calendar '${cal_id}' from file ${f}: ", ( $@ || $sth_avail_fmt->errstr ), "\nwith query: ", $sth_avail_fmt->{Statement}, "\n", dump( $def ) );
                            $added->{cal_available_format}++;
                        }
                    }
        
                    # NOTE: Checking calendar append items
                    &log( "\tChecking calendar append items." );
                    my $calDateTimeAppendRes = $el_container->findnodes( './appendItems' );
                    if( $calDateTimeAppendRes->size )
                    {
                        my $el_append = $calDateTimeAppendRes->shift;
                        my $calDateTimeAppendHasAliasRes = $el_append->findnodes( './alias[@path]' );
                        if( $calDateTimeAppendHasAliasRes->size )
                        {
                            $out->print( "\t\tCalendar ${cal_id} append formats is aliased, resolving it.\n" ) if( $DEBUG );
                            $el_append = resolve_alias( $calDateTimeAppendHasAliasRes ) ||
                                die( "Calendar ${cal_id} append formats is aliased, but I cannot resolve it for locale ${locale} in file ${f} for this element: ", $el_container->toString() );
                        }
                        my $calAppendItemsRes = $el_append->findnodes( './appendItem' );
                        # <appendItem request="Day-Of-Week">{0} {1}</appendItem>
                        while( my $el_append = $calAppendItemsRes->shift )
                        {
                            my $def =
                            {
                                locale          => $locale,
                                calendar        => $cal_id,
                                format_id       => ( $el_append->getAttribute( 'request' ) ||
                                    die( "Unable to get the append format pattern from the attribute 'request' in this element in file $f: ", $el_append->toString() ) ),
                                format_pattern  => $el_append->textContent,
                            };
                            if( !defined( $def->{format_pattern} ) ||
                                !length( $def->{format_pattern} // '' ) )
                            {
                                die( "No pattern found for this append item format with id '$def->{format_id}' for calendar '${cal_id}' and locale '${locale}' in file $f: ", $el_append->toString() );
                            }
                            eval
                            {
                                $sth_append_fmt->execute( @$def{qw( locale calendar format_id format_pattern )} );
                            } || die( "Error executing query to add calendar append item format '", ( $def->{format_pattern} // 'undef' ), "' with id '$def->{format_id}' for locale '${locale}' and for calendar '${cal_id}' from file ${f}: ", ( $@ || $sth_append_fmt->errstr ), "\nwith query: ", $sth_append_fmt->{Statement}, "\n", dump( $def ) );
                            $added->{cal_append_format}++;
                        }
                    }
            
                    # NOTE: Checking calendar interval formats
                    &log( "\tChecking calendar interval formats." );
                    my $calIntervalFormatRes = $el_container->findnodes( './intervalFormats' );
                    if( $calIntervalFormatRes->size )
                    {
                        my $el_int = $calIntervalFormatRes->shift;
                        my $calIntervalFormatHasAliasRes = $el_int->findnodes( './alias[@path]' );
                        if( $calIntervalFormatHasAliasRes->size )
                        {
                            $el_int = resolve_alias( $calIntervalFormatHasAliasRes ) ||
                                die( "Calendar ${cal_id} interval format is aliased, but I cannot resolve it for locale ${locale} in file ${f} for this element: ", $el_container->toString() );
                        }
                        my $calIntervalFormatItemsRes = $el_int->findnodes( './intervalFormatItem' );
                        # <intervalFormatItem id="Bh">
                        while( my $el_item = $calIntervalFormatItemsRes->shift )
                        {
                            my $int_id = $el_item->getAttribute( 'id' ) ||
                                die( "Unable to get the interval ID value from the attribute 'id' in this element in file $f: ", $el_item->toString() );
                            # <greatestDifference id="B">h B – h B</greatestDifference>
                            my $calDiffFormatRes = $el_item->findnodes( './greatestDifference' );
                            while( my $el_diff = $calDiffFormatRes->shift )
                            {
                                my $def =
                                {
                                    locale              => $locale,
                                    calendar            => $cal_id,
                                    format_id           => $int_id,
                                    greatest_diff_id    => $el_diff->getAttribute( 'id' ),
                                    format_pattern      => $el_diff->textContent,
                                };
    
                                if( $opts->{apply_patch} &&
                                    exists( $patch->{ $cldr_version } ) &&
                                    ref( $patch->{ $cldr_version } ) eq 'HASH' &&
                                    exists( $patch->{ $cldr_version }->{calendar_interval_formats} ) &&
                                    ref( $patch->{ $cldr_version }->{calendar_interval_formats} ) eq 'HASH' &&
                                    exists( $patch->{ $cldr_version }->{calendar_interval_formats}->{ $locale } ) &&
                                    ref( $patch->{ $cldr_version }->{calendar_interval_formats}->{ $locale } ) eq 'HASH' &&
                                    exists( $patch->{ $cldr_version }->{calendar_interval_formats}->{ $locale }->{ $def->{format_id} } ) &&
                                    ref( $patch->{ $cldr_version }->{calendar_interval_formats}->{ $locale }->{ $def->{format_id} } ) eq 'HASH' &&
                                    exists( $patch->{ $cldr_version }->{calendar_interval_formats}->{ $locale }->{ $def->{format_id} }->{ $def->{greatest_diff_id} } ) )
                                {
                                    warn( "Warning only: Datetime interval with format ID '$def->{format_id}' and greatest difference ID '$def->{greatest_diff_id}' has a patch (", $patch->{ $cldr_version }->{calendar_interval_formats}->{ $locale }->{ $def->{format_id} }->{ $def->{greatest_diff_id} }, "), applying it instead of the default pattern (", $def->{format_pattern}, ")" );
                                    $def->{format_pattern} = $patch->{ $cldr_version }->{calendar_interval_formats}->{ $locale }->{ $def->{format_id} }->{ $def->{greatest_diff_id} };
                                }
    
                                foreach my $prop ( qw( greatest_diff_id format_pattern ) )
                                {
                                    if( !defined( $def->{ $prop } ) ||
                                        !length( $def->{ $prop } // '' ) )
                                    {
                                        die( "No pattern found for this append item format with id '$def->{format_id}' for calendar '${cal_id}' and locale '${locale}' in file $f: ", $el_diff->toString() );
                                    }
                                }
        
                                if( $el_diff->hasAttribute( 'alt' ) )
                                {
                                    $def->{alt} = $el_diff->getAttribute( 'alt' );
                                }
    
                                my( $p1, $sep, $p2, $repeating_field ) = find_interval_repeating_field({
                                    pattern => $def->{format_pattern},
                                    greatest_diff => $def->{greatest_diff_id},
                                });
                                unless( defined( $p1 ) )
                                {
                                    warn( "Warning only: failed to find the repeating field for pattern '$def->{format_pattern}', with locale '${locale}' and format ID '$def->{format_id}' from file ${f}: ", dump( $ref ) );
                                    next;
                                }
                                if( "${p1}${sep}${p2}" ne $def->{format_pattern} )
                                {
                                    die( "Reconstructed string '${p1}${sep}${p2}' does not match original string '$def->{format_pattern}' for locale '${locale}' in file ${f} for element: ", $el_diff->toString() );
                                }
                                @$def{qw( part1 separator part2 repeating_field )} = ( $p1, $sep, $p2, $repeating_field );
    
                                eval
                                {
                                    $sth_inter_fmt->execute( @$def{qw( locale calendar format_id greatest_diff_id format_pattern alt part1 separator part2 repeating_field )} );
                                } || die( "Error executing query to add calendar interval format '", ( $def->{format_pattern} // 'undef' ), "' with id '$def->{format_id}' and greatest difference ID '", ( $def->{greatest_diff_id} // 'undef' ), "' for locale '${locale}' and for calendar '${cal_id}' from file ${f}: ", ( $@ || $sth_inter_fmt->errstr ), "\nwith query: ", $sth_inter_fmt->{Statement}, "\n", dump( $def ) );
                                $added->{cal_interval_format}++;
                            }
                        }
                        my $defIntervalFormatRes = $el_int->findnodes( './intervalFormatFallback' );
                        # <intervalFormatFallback>{0} – {1}</intervalFormatFallback>
                        if( $defIntervalFormatRes->size )
                        {
                            my $el_interval_default_fmt = $defIntervalFormatRes->shift ||
                                die( "No default interval format element found for calendar '${cal_id}' and locale '${locale}' in file ${f}" );
                            my $def =
                            {
                                locale              => $locale,
                                calendar            => $cal_id,
                                format_id           => 'default',
                                greatest_diff_id    => 'default',
                                format_pattern      => $el_interval_default_fmt->textContent,
                            };
        
                            if( $el_interval_default_fmt->hasAttribute( 'alt' ) )
                            {
                                $def->{alt} = $el_interval_default_fmt->getAttribute( 'alt' );
                            }
    
                            my( $p1, $sep, $p2, $repeating_field ) = find_interval_repeating_field({
                                pattern => $def->{format_pattern},
                                greatest_diff => $def->{greatest_diff_id},
                            });
                            unless( defined( $p1 ) )
                            {
                                warn( "Warning only: failed to find the repeating field for pattern '$def->{format_pattern}', with locale '${locale}' and format ID '$def->{format_id}' from file ${f}: ", dump( $ref ) );
                                next;
                            }
                            if( "${p1}${sep}${p2}" ne $def->{format_pattern} )
                            {
                                die( "Reconstructed string '${p1}${sep}${p2}' does not match original string '$def->{format_pattern}' for locale '${locale}' in file ${f} for element: ", $el_interval_default_fmt->toString() );
                            }
                            @$def{qw( part1 separator part2 repeating_field )} = ( $p1, $sep, $p2, $repeating_field );
    
                            eval
                            {
                                $sth_inter_fmt->execute( @$def{qw( locale calendar format_id greatest_diff_id format_pattern alt part1 separator part2 repeating_field )} );
                            } || die( "Error executing query to add calendar default interval format '", ( $def->{format_pattern} // 'undef' ), "' with id '$def->{format_id}' and greatest difference ID '", ( $def->{greatest_diff_id} // 'undef' ), "' for locale '${locale}' and for calendar '${cal_id}' from file ${f}: ", ( $@ || $sth_inter_fmt->errstr ), "\nwith query: ", $sth_inter_fmt->{Statement}, "\n", dump( $def ) );
                            $added->{cal_interval_format}++;
                        }
                    }
                }
                # Done with DateTime formats
        
                # NOTE: Checking calendar cyclic name sets
                &log( "\tChecking calendar cyclic name sets." );
                my $calCyclicContainerRes = $el->findnodes( './cyclicNameSets' );
                if( $calCyclicContainerRes->size )
                {
                    my $el_container = $calCyclicContainerRes->shift;
                    my $calCyclicContainerHasAliasRes = $el_container->findnodes( './alias[@path]' );
                    if( $calCyclicContainerHasAliasRes->size )
                    {
                        $el_container = resolve_alias( $calCyclicContainerHasAliasRes ) ||
                            die( "The calendar ${cal_id} cyclic container is aliased, but I could not resolve it for locale ${locale} in file ${f}" );
                    }
                    my $calCyclicNameSetRes = $el_container->findnodes( './cyclicNameSet' );
                    while( my $el_cyclic = $calCyclicNameSetRes->shift )
                    {
                        my $set = $el_cyclic->getAttribute( 'type' ) ||
                            die( "Unable to get the calendar cyclic set type value from the attribute 'type' in this element in file $f: ", $el_cyclic->toString() );
                        my $calCyclicNameSetHasAliasRes = $el_cyclic->findnodes( './alias[@path]' );
                        if( $calCyclicNameSetHasAliasRes->size )
                        {
                            $el_cyclic = resolve_alias( $calCyclicNameSetHasAliasRes ) ||
                                die( "Calendar ${cal_id} cyclic name set is aliased, but I could not resolve it for locale ${locale} in file ${f} for this element: ", $el_container->toString() );
                        }
                        # <cyclicNameContext type="format">
                        my $calCyclicContextRes = $el_cyclic->findnodes( './cyclicNameContext' );
                        while( my $el_ctx = $calCyclicContextRes->shift )
                        {
                            my $context = $el_ctx->getAttribute( 'type' ) ||
                                die( "Unable to get the calendar cyclic set context value from the attribute 'type' in this element in file $f: ", $el_ctx->toString() );
                            my $calCyclicContextHasAliasRes = $el_ctx->findnodes( './alias[@path]' );
                            if( $calCyclicContextHasAliasRes->size )
                            {
                                $el_ctx = resolve_alias( $calCyclicContextHasAliasRes ) ||
                                    die( "Calendar ${cal_id} cyclic context with set ${set} and context ${context} is aliased, but I could not resolve it for locale ${locale} in file ${f} for this element: ", $el_cyclic->toString() );
                            }
                            my $calCyclicLengthRes = $el_ctx->findnodes( './cyclicNameWidth' );
                            # <cyclicNameWidth type="abbreviated">
                            while( my $el_len = $calCyclicLengthRes->shift )
                            {
                                my $len = $el_len->getAttribute( 'type' ) ||
                                    die( "Unable to get the calendar cyclic set length value from the attribute 'type' in this element in file $f: ", $el_len->toString() );
                                my $calCyclicWidthHasAliasRes = $el_len->findnodes( './alias[@path]' );
                                if( $calCyclicWidthHasAliasRes->size )
                                {
                                    $el_len = resolve_alias( $calCyclicWidthHasAliasRes ) ||
                                        die( "Calendar ${cal_id} cyclic length ${len} with set ${set} and context ${context} is aliased, but I could not resolve it for locale ${locale} in file ${f} for this element: ", $el_cyclic->toString() );
                                }
                                my $calCyclicNamesRes = $el_len->findnodes( './cyclicName' );
                                # <cyclicName type="3">Tiger</cyclicName>
                                while( my $el_name = $calCyclicNamesRes->shift )
                                {
                                    my $def =
                                    {
                                        locale          => $locale,
                                        calendar        => $cal_id,
                                        format_set      => $set,
                                        format_type     => $context,
                                        format_length   => $len,
                                        format_id       => $el_name->getAttribute( 'type' ),
                                        format_pattern  => $el_name->textContent,
                                    };
            
                                    eval
                                    {
                                        $sth_cyclic->execute( @$def{qw( locale calendar format_set format_type format_length format_id format_pattern )} );
                                    } || die( "Error executing query to add calendar cyclick set '${set}' with type '${context}', length '${len}', id '", ( $def->{format_id} // 'undef' ), "' and pattern '", ( $def->{format_pattern} // 'undef' ), "' for locale '${locale}' and for calendar '${cal_id}' from file ${f}: ", ( $@ || $sth_cyclic->errstr ), "\nwith query: ", $sth_cyclic->{Statement}, "\n", dump( $def ) );
                                    $added->{cal_cyclic}++;
                                }
                            }
                        }
                    }
                }
                else
                {
                    $out->print( "\tno cyclic data for this calendar ${cal_id} for locale ${locale}\n" ) if( $DEBUG );
                }
            }
            # End looping through all calendar systems
    
            # NOTE: Checking locale date fields
            &log( "\tChecking locale date fields." );
            my $calDateFieldsRes = $el_dates->findnodes( './fields' );
            if( $calDateFieldsRes->size )
            {
                &log( sprintf( "\t%d locale date fields found.", $calDateFieldsRes->size ) );
                my $el_fields = $calDateFieldsRes->shift;
                my $calDateFieldRes = $el_fields->findnodes( './field[@type]' );
                while( my $el_field = $calDateFieldRes->shift )
                {
                    my $type = $el_field->getAttribute( 'type' ) ||
                        die( "Unable to get the field type from attribute 'type' for locale ${locale} in file ${f} for this element: ", $el_fields->toString() );
                    my( $field_type, $field_length ) = split( /[^a-zA-Z0-9]/, $type, 2 );
                    $field_length //= 'standard';
                    my $calDateFieldHasAliasRes = $el_field->findnodes( './alias[@path]' );
                    if( $calDateFieldHasAliasRes->size )
                    {
                        $el_field = resolve_alias( $calDateFieldHasAliasRes ) ||
                            die( "This date field of type ${type} is aliased, but I could not resolve it for locale ${locale} in file ${f}." );
                    }
                    my $displayNameRes = $el_field->findnodes( './displayName' );
                    my $display_name;
                    if( !$displayNameRes->size )
                    {
                        warn( "Warning only: missing display name for this field of type '${type}' for locale '${locale}' in file ${f}" );
                    }
                    else
                    {
                        $display_name = trim( $displayNameRes->shift->textContent );
                        my $def =
                        {
                            locale          => $locale,
                            term_type       => $field_type,
                            term_length     => $field_length,
                            display_name    => $display_name,
                        };
                        eval
                        {
                            $sth_date_term->execute( @$def{qw( locale term_type term_length display_name )} );
                        } || die( "Error executing query to add date term for locale ${locale} and term type $def->{term_type} and term length $def->{term_length} from file ${f}: ", ( $@ || $sth_date_term->errstr ), "\nwith query: ", $sth_date_term->{Statement}, "\n", dump( $def ) );
                        $added->{date_term}++;
                    }
                    my $calDateFieldItemsRes = $el_field->findnodes( './relative[@type]' );
                    while( my $el_item = $calDateFieldItemsRes->shift )
                    {
                        my $def =
                        {
                            locale          => $locale,
                            field_type      => $field_type,
                            field_length    => $field_length,
                            relative        => $el_item->getAttribute( 'type' ),
                            locale_name     => $el_item->textContent,
                        };
                        eval
                        {
                            $sth_field->execute( @$def{qw( locale field_type field_length relative locale_name )} );
                        } || die( "Error executing query to add date field for locale ${locale} and field type ${field_type} and field length ${field_length} from file ${f}: ", ( $@ || $sth_field->errstr ), "\nwith query: ", $sth_field->{Statement}, "\n", dump( $def ) );
                        $added->{cal_field}++;
                    }
                    # And now, we process the 'relativeTime' elements, such as:
                    # <relativeTime type="future">
                    #     <relativeTimePattern count="one">in {0} year</relativeTimePattern>
                    #     <relativeTimePattern count="other">in {0} years</relativeTimePattern>
                    # </relativeTime>
                    # <relativeTime type="past">
                    #     <relativeTimePattern count="one">{0} year ago</relativeTimePattern>
                    #     <relativeTimePattern count="other">{0} years ago</relativeTimePattern>
                    # </relativeTime>
                    my $calDateTimeRelItemsRes = $el_field->findnodes( './relativeTime[@type]' );
                    while( my $el_time_rel = $calDateTimeRelItemsRes->shift )
                    {
                        # This can either be 'future' or 'past', which we translate to 1 or -1
                        my $time_relative_position = $el_time_rel->getAttribute( 'type' ) // '';
                        my $calDateTimeRelHasAliasRes = $el_time_rel->findnodes( './alias[@path]' );
                        if( $calDateTimeRelHasAliasRes->size )
                        {
                            $el_time_rel = resolve_alias( $calDateTimeRelHasAliasRes ) ||
                                die( "This date time relative of type ${type} is aliased, but I could not resolve it for locale ${locale} in file ${f}." );
                        }
                        my $calDateTimeRelPatternItemsRes = $el_time_rel->findnodes( './relativeTimePattern' );
                        while( my $el_time_rel_pat = $calDateTimeRelPatternItemsRes->shift )
                        {
                            my $def =
                            {
                                locale          => $locale,
                                field_type      => $field_type,
                                field_length    => $field_length,
                                relative        => ( $time_relative_position eq 'future' ? 1 : $time_relative_position eq 'past' ? -1 : undef ),
                                pattern         => $el_time_rel_pat->textContent,
                            };
                            if( $el_time_rel_pat->hasAttribute( 'count' ) )
                            {
                                $def->{count} = $el_time_rel_pat->getAttribute( 'count' );
                            }

                            eval
                            {
                                $sth_time_rel->execute( @$def{qw( locale field_type field_length relative pattern count )} );
                            } || die( "Error executing query to add date field for locale ${locale} and field type ${field_type} and field length ${field_length} from file ${f}: ", ( $@ || $sth_time_rel->errstr ), "\nwith query: ", $sth_time_rel->{Statement}, "\n", dump( $def ) );
                            $added->{cal_time_rel}++;
                        }
                    }
                }
            }
            else
            {
                $out->print( "\tno localised date fields for locale ${locale} in file ${f}\n" ) if( $DEBUG );
            }

            my $tzNamesContainerRes = $el_dates->findnodes( './timeZoneNames' );
            if( $tzNamesContainerRes->size )
            {
                my $el = $tzNamesContainerRes->shift;
                my $tzNamesAliasRes = $el->findnodes( './alias[@path]' );
                # Example: <alias source="locale" path="../symbols[@numberSystem='latn']"/>
                if( $tzNamesAliasRes->size )
                {
                    # XXX Remove this
                    die( "I found an alias for the locale timezone/metazones for locale '${locale}' in file ${f}" );
                    $el = resolve_alias( $tzNamesAliasRes ) ||
                        die( "This timezones and metazones names is aliased, but I could not resolve it for locale ${locale} in file ${f} for this element." );
                }

                # NOTE: Checking locale time zone formats
                &log( "\tChecking locale time zone formats." );
                # <https://unicode.org/reports/tr35/tr35-dates.html#Time_Zone_Names>
                # <regionFormat type="daylight">{0} Daylight Time</regionFormat>
                my $tzFormatsRes = $el->findnodes( './*[local-name()="hourFormat" or local-name()="gmtFormat" or local-name()="gmtZeroFormat" or local-name()="regionFormat" or local-name()="fallbackFormat"]' );
                if( $tzFormatsRes->size )
                {
                    $out->printf( "\t\tProcessing %d time zone formats for locale '${locale}'\n", $tzFormatsRes->size ) if( $DEBUG );
                    my $tz_fmt_map =
                    {
                        hourFormat => 'hour',
                        gmtFormat => 'gmt',
                        gmtZeroFormat => 'gmt_zero',
                        regionFormat => 'region',
                        fallbackFormat => 'fallback',
                    };
                    my $c = 0;
                    while( my $el_tz_fmt = $tzFormatsRes->shift )
                    {
                        my $tag = $el_tz_fmt->nodeName;
                        $out->print( "\t\tAdding time zone format of type '${tag}': " ) if( $DEBUG );
                        if( !exists( $tz_fmt_map->{ $tag } ) )
                        {
                            die( "Tag \"${tag}\" is not in our internal type map in file $f." );
                        }
                        my $def = 
                        {
                            locale => $locale,
                            type => $tz_fmt_map->{ $tag },
                            format_pattern => trim( $el_tz_fmt->textContent ),
                        };
                        if( $el_tz_fmt->hasAttribute( 'type' ) )
                        {
                            $def->{subtype} = $el_tz_fmt->getAttribute( 'type' );
                        }
    
                        eval
                        {
                            $sth_tz_formats->execute( @$def{qw( locale type subtype format_pattern )} );
                        } || die( "Error executing query to add timezone format of type '$def->{type}' for locale '${locale}' from file ${f}: ", ( $@ || $sth_tz_formats->errstr ), "\nwith query: ", $sth_tz_formats->{Statement}, "\n", dump( $def ) );
                        $c++;
                        $out->print( "ok\n" );
                    }
                    $out->print( "\t\t${c} time zone format(s) added.\n" ) if( $DEBUG );
                }
                else
                {
                    $out->print( "\t\tthe locale ${locale} has no time zone formats set.\n" ) if( $DEBUG );
                }

                # NOTE: Checking locale time zone sample cities
                &log( "\tChecking locale time zone sample cities for locale ${locale}." );
                my $TimeZonesRes = $el->findnodes( './zone[@type]' );
                my $tz_tags_map =
                {
                    exemplarCity => 'city',
                    long => 'long',
                    short => 'short',
                };
                if( $TimeZonesRes->size )
                {
                    &log( sprintf( "\t\t%d locale time zone sample cities found for locale ${locale}.", $TimeZonesRes->size ) );
                    while( my $el_tz = $TimeZonesRes->shift )
                    {
                        my $timezone = $el_tz->getAttribute( 'type' ) ||
                            die( "No timezone ID value defined for this element in file $f: ", $el->toString() );
                        $out->print( "\t\t\t[${timezone}]\n" ) if( $DEBUG );
                        my @kids = $el_tz->nonBlankChildNodes;
                        $out->printf( "\t\t\t\t%d children nodes found: %s\n", scalar( @kids ), join( ', ', map{ $_->nodeName } @kids ) ) if( $DEBUG );
                        foreach my $el_kid ( @kids )
                        {
                            my $tag = $el_kid->nodeName;
                            if( !exists( $tz_tags_map->{ $tag } ) )
                            {
                                die( "Found tag ${tag} as child of this time zones list, but it is unknown to us for time zone '${timezone}' for locale ${locale} in file ${f} for this element: ", $el_kid->toString() );
                            }
                            my $prop = $tz_tags_map->{ $tag } ||
                                die( "Unable to find an equivalence in our timezone map for the tag ${tag} in file $f: ", $el->toString() );
                            if( $prop eq 'city' )
                            {
                                my $def =
                                {
                                    locale => $locale,
                                    timezone => $timezone,
                                    city => trim( $el_kid->textContent ),
                                };
                                if( $el_kid->hasAttribute( 'alt' ) )
                                {
                                    $def->{alt} = $el_kid->getAttribute( 'alt' );
                                }
                                $out->print( "\t\t\t\tFound sample city '$def->{city}' for timezone '${timezone}' for locale ${locale}\n" ) if( $DEBUG );

                                eval
                                {
                                    $sth_timezone_city->execute( @$def{qw( locale timezone city alt )} );
                                } || die( "Error executing query to add timezone $def->{timezone} sample city '$def->{city}' for locale '${locale}' from file ${f}: ", ( $@ || $sth_timezone_city->errstr ), "\nwith query: ", $sth_timezone_city->{Statement}, "\n", dump( $def ) );
                                $added->{timezones_cities}++;
                            }
                            elsif( $prop eq 'short' || $prop eq 'long' )
                            {
                                my $def =
                                {
                                    locale => $locale,
                                    timezone => $timezone,
                                    width => $prop,
                                };
                                my @tz_name_kids = $el_kid->nonBlankChildNodes;
                                $out->printf( "\t\t\t\tFound ${prop} timezone name definition for timezone '${timezone}' for locale ${locale} with %d children\n", scalar( @tz_name_kids ) ) if( $DEBUG );
                                if( !scalar( @tz_name_kids ) )
                                {
                                    die( "Locale '${locale}' has the time zone '${timezone}' set with time zone name of width '$def->{width}', but no data could be found in file ${f} for this element: ", $el_tz->toString() );
                                }
                                foreach my $el_tz_kid ( @tz_name_kids )
                                {
                                    my $name_type = $el_tz_kid->nodeName;
                                    my $name_value = trim( $el_tz_kid->textContent );
                                    $def->{ $name_type } = $name_value;
                                }
                                eval
                                {
                                    $sth_tz_names->execute( @$def{qw( locale timezone width generic standard daylight )} );
                                } || die( "Error executing query to add timezone $def->{timezone} locale names for locale '${locale}' from file ${f}: ", ( $@ || $sth_tz_names->errstr ), "\nwith query: ", $sth_tz_names->{Statement}, "\n", dump( $def ) );
                            }
                        }
                    }
                }
                else
                {
                    $out->print( "\tno localised time zone sample cities for locale ${locale} in file ${f}\n" ) if( $DEBUG );
                }
    
                # NOTE: Checking for locale metazones
                &log( "\tChecking for locale metazones." );
                my $MetazonesRes = $el_dates->findnodes( './timeZoneNames/metazone[@type]' );
                if( $MetazonesRes->size )
                {
                    &log( sprintf( "\t%d locale metazone found.", $MetazonesRes->size ) );
                    while( my $el_metatz = $MetazonesRes->shift )
                    {
                        my $metazone = $el_metatz->getAttribute( 'type' ) ||
                            die( "No value found for metazone attribute 'type' for this element in file $f: ", $el->toString() );
                        my $MetaTzNamesRes = $el_metatz->findnodes( './*[local-name()="long" or local-name()="short"]' );
                        $out->printf( "\t\tfound %d metazone long/short localised name(s) for metazone '${metazone}'\n", $MetaTzNamesRes->size ) if( $DEBUG );
                        while( my $el_tz_width = $MetaTzNamesRes->shift )
                        {
                            # 'long' or 'short'
                            my $tz_name_width = $el_tz_width->nodeName;
                            my $def =
                            {
                                locale => $locale,
                                metazone => $metazone,
                                width => $tz_name_width,
                            };
                            my $tzNamesTypesRes = $el_tz_width->findnodes( './*[local-name()="generic" or local-name()="standard" or local-name()="daylight"]' );
                            if( !$tzNamesTypesRes->size )
                            {
                                die( "Locale '${locale}' has the metazone '${metazone}' set with metazone name of width '${tz_name_width}', but no data could be found in file ${f} for this element: ", $el->toString() );
                            }
                            while( my $el_tz_name = $tzNamesTypesRes->shift )
                            {
                                my $name_type = $el_tz_name->nodeName;
                                my $name_value = trim( $el_tz_name->textContent );
                                $def->{ $name_type } = $name_value;
                            }
                            
                            eval
                            {
                                $sth_metatz_names->execute( @$def{qw( locale metazone width generic standard daylight )} );
                            } || die( "Error executing query to add timezone $def->{timezone} locale names for locale '${locale}' from file ${f}: ", ( $@ || $sth_metatz_names->errstr ), "\nwith query: ", $sth_metatz_names->{Statement}, "\n", dump( $def ) );
                        }
                    }
                }
                else
                {
                    $out->print( "\t\tno localised metazone found for locale ${locale} in file ${f}\n" ) if( $DEBUG );
                }
            }
            else
            {
                $out->print( "\t\tno localised timezones and metazones for locale ${locale} in file ${f}\n" ) if( $DEBUG );
            }
        }
    
        $out->printf( "\tok, added %d locales, %d scripts, %d territories, %d variants, %d currencies, %d calendar terms, %d eras, %d date or time formats, %d datetime formats, %d available formats, %d appended formats, %d interval formats, %d cyclic, %d fields\n", @$added{qw( languages scripts territories variants currencies cal_terms cal_era cal_date_or_time_format cal_datetime_format cal_available_format cal_append_format cal_interval_format cal_cyclic cal_field )} ) if( $DEBUG );
    
        # NOTE: Checking for layout orientation (left-to-right)
        &log( "\tChecking for layout orientation (left-to-right)." );
        my $layoutLTRRes = $mainDoc->findnodes( '//layout/orientation/characterOrder' );
        if( $layoutLTRRes->size )
        {
            # <characterOrder>right-to-left</characterOrder>
            my $ltr = trim( $layoutLTRRes->shift->textContent );
            if( !defined( $ltr ) ||
                !length( $ltr // '' ) )
            {
                die( "Unable to get the value for the layout orientation for the locale ${locale} in file ${f} with xpath //layout/orientation/characterOrder" );
            }
            eval
            {
                $sth_locale_info->execute( $locale, 'char_orientation', $ltr );
            } || die( "Error executing query to add locale information for layout orientation (char_orientation) and value '${ltr}' in file $f: ", ( $@ || $sth_locale_info->errstr ), "\nwith query: ", $sth_locale_info->{Statement} );
            $out->printf( "\t%d element added.\n", $sth_locale_info->rows ) if( $DEBUG );
        }
        else
        {
            $out->print( "\tNo layout orientation found.\n" ) if( $DEBUG );
        }
    
        # NOTE: Checking for quotation marks
        &log( "\tChecking for quotation marks." );
        # Example:
        # <delimiters>
        #     <quotationStart>「</quotationStart>
        #     <quotationEnd>」</quotationEnd>
        #     <alternateQuotationStart>『</alternateQuotationStart>
        #     <alternateQuotationEnd>』</alternateQuotationEnd>
        # </delimiters>
        my $quotationsRes = $mainDoc->findnodes( '//delimiters/*[local-name()="quotationStart" or local-name()="quotationEnd" or local-name()="alternateQuotationStart" or local-name()="alternateQuotationEnd"]' );
        my $quotation_map =
        {
            quotationStart          => 'quotation_start',
            quotationEnd            => 'quotation_end',
            alternateQuotationStart => 'quotation2_start',
            alternateQuotationEnd   => 'quotation2_end',
        };
        my $j = 0;
        while( my $el = $quotationsRes->shift )
        {
            my $tag = $el->nodeName;
            if( !exists( $quotation_map->{ $tag } ) )
            {
                die( "Quotation tag found (${tag}) for locale '${locale}' does not exist in our internal property map in file ${f} for this element in file $f: ", $el->toString() );
            }
            my $val = $el->textContent;
            eval
            {
                $sth_locale_info->execute( $locale, $quotation_map->{ $tag }, $val );
            } || die( "Error executing query to add locale information for quotation mark (${tag} -> ", $quotation_map->{ $tag }, ") for locale ${locale} in file ${f}: ", ( $@ || $sth_locale_info->errstr ), "\nwith query: ", $sth_locale_info->{Statement} );
            $j++;
        }
        $out->printf( "\t%d quotation mark information added.\n", $j ) if( $DEBUG );
    
        # NOTE: Checking for POSIX yes/no string
        &log( "\tChecking for POSIX yes/no string." );
        # Example:
        # <posix>
        #     <messages>
        #         <yesstr>はい:y</yesstr>
        #         <nostr>いいえ:n</nostr>
        #     </messages>
        # </posix>
        my $yesNoRes = $mainDoc->findnodes( '//posix/messages/*[local-name()="yesstr" or local-name()="nostr"]' );
        my $yes_no_map =
        {
            yesstr  => 'yes',
            nostr   => 'no',
        };
        $j = 0;
        while( my $el = $yesNoRes->shift )
        {
            my $tag = $el->nodeName;
            if( !exists( $yes_no_map->{ $tag } ) )
            {
                die( "Yes/No string tag found (${tag}) for locale '${locale}' does not exist in our internal property map in file ${f} for this element: ", $el->toString() );
            }
            my $val = $el->textContent;
            if( !defined( $val ) ||
                !length( $val // '' ) )
            {
                die( "Found a yes/no string value, but its content is empty for locale '${locale}' in file ${f} for this element: ", $el->toString() );
            }
            elsif( index( $val, ':' ) == -1 )
            {
                warn( "Warning only: found a yes/no string value, but its content is malformed. I could not find a ':' separator for locale '${locale}' in file ${f} for this element: ", $el->toString() );
            }
            $val = [split( ':', $val )]->[0];
            if( !length( $val // '' ) )
            {
                die( "Found a yes/no string value, but its content after spliting it is empty for locale '${locale}' in file ${f} for this element: ", $el->toString() );
            }
    
            eval
            {
                $sth_locale_info->execute( $locale, $yes_no_map->{ $tag }, $val );
            } || die( "Error executing query to add locale information for yes/no string (${tag} -> ", $yes_no_map->{ $tag }, ") in file $f: ", ( $@ || $sth_locale_info->errstr ), "\nwith query: ", $sth_locale_info->{Statement} );
            $j++;
        }
        $out->printf( "\t%d yes/no string information added.\n", $j ) if( $DEBUG );
    
        # NOTE: Adding locale number system properties (punctuation, percent, group, etc)
        &log( "\tAdding locale number system symbols (punctuation, percent, group, etc)." );
        my $localeNumberSymbolRes = $mainDoc->findnodes( '/ldml/numbers/symbols[@numberSystem]' );
        $j = 0;
        if( $localeNumberSymbolRes->size )
        {
            $sth = $sths->{number_symbols_l10n} || die( "No statement object set for table 'number_symbols_l10n' in file $f." );
            # Example:
            # <symbols numberSystem="latn">
            #     <decimal>.</decimal>
            #     <group>,</group>
            #     <list>;</list>
            #     <percentSign>%</percentSign>
            #     <plusSign>+</plusSign>
            #     <minusSign>-</minusSign>
            #     <approximatelySign>~</approximatelySign>
            #     <exponential>E</exponential>
            #     <superscriptingExponent>×</superscriptingExponent>
            #     <perMille>‰</perMille>
            #     <infinity>∞</infinity>
            #     <nan>NaN</nan>
            #     <timeSeparator>:</timeSeparator>
            # </symbols>
    
            my $symbols_map =
            {
                approximatelySign       => 'approximately',
                currencyDecimal         => 'currency_decimal',
                currencyGroup           => 'currency_group',
                decimal                 => 'decimal',
                exponential             => 'exponential',
                group                   => 'group',
                infinity                => 'infinity',
                list                    => 'list',
                minusSign               => 'minus',
                nan                     => 'nan',
                nativeZeroDigit         => 'native_zero_digit',
                patternDigit            => 'pattern_digit',
                percentSign             => 'percent',
                perMille                => 'per_mille',
                plusSign                => 'plus',
                special                 => 'special',
                superscriptingExponent  => 'superscript',
                timeSeparator           => 'time_separator',
            };
            my $symbols_data = {};
            while( my $el = $localeNumberSymbolRes->shift )
            {
                my $sys_id = $el->getAttribute( 'numberSystem' ) ||
                    die( "Unable to get the number system ID for this symbol in attribute 'numberSystem' for locale ${locale} in file ${f} for this element: ", $el->toString() );
                my $numSymbolAliasRes = $el->findnodes( './alias[@path]' );
                # Example: <alias source="locale" path="../symbols[@numberSystem='latn']"/>
                if( $numSymbolAliasRes->size )
                {
                    $el = resolve_alias( $numSymbolAliasRes ) ||
                        die( "This number symbol with number system '${sys_id}' is aliased, but I could not resolve it for locale ${locale} in file ${f} for this element." );
                }
    
                if( !exists( $symbols_data->{ $sys_id } ) )
                {
                    $symbols_data->{ $sys_id } = {}
                }
                else
                {
                    die( "Symbols for number system '${sys_id}' is being redefined for number system ${sys_id} and for locale ${locale} in file ${f} for this element: ", $el->toString() );
                }

                my @kids = $el->nonBlankChildNodes;
                foreach my $el_kid ( @kids )
                {
                    my $tag = $el_kid->nodeName;
                    if( !exists( $symbols_map->{ $tag } ) )
                    {
                        die( "Found tag ${tag} as child of this symbols list, but it is unknown to us for number system ${sys_id} and for locale ${locale} in file ${f} for this element: ", $el->toString() );
                    }
                    my $prop = $symbols_map->{ $tag };
                    my $val = trim( $el_kid->textContent );
                    my $def =
                    {
                        locale          => $locale,
                        number_system   => $sys_id,
                        property        => $prop,
                        value           => $val,
                    };
                    if( $el_kid->hasAttribute( 'alt' ) )
                    {
                        $def->{alt} = $el_kid->getAttribute( 'alt' );
                    }
    
                    my $prop_key = join( ';', map( $_ // '', @$def{qw( property alt )} ) );
                    if( exists( $symbols_data->{ $sys_id }->{ $prop_key } ) )
                    {
                        die( "Symbol property ${tag} ('${prop}') is being redefined for number system ${sys_id} and locale ${locale} in file ${f} for this element: ", $el->toString() );
                    }
                    $symbols_data->{ $sys_id }->{ $prop_key } = $val;
    
                    eval
                    {
                        $sth->execute( @$def{qw( locale number_system property value alt )} );
                    } || die( "Error executing query to add locale numbering system symbol ${prop} for locale ${locale} in file ${f}: ", ( $@ || $sth->errstr ), "\nwith query: ", $sth->{Statement}, "\nwith data: ", dump( $def ) );
                    $j++;
                }
            }
            $out->printf( "\t%d locale symbols added.\n", $j ) if( $DEBUG );
        }
        else
        {
            &log( "\tNo numbering system symbols for locale ${locale} in file ${f}" );
        }
    
        # NOTE: Adding formats for decimal, scientific, percent, currency and miscellaneous
        &log( "\tAdding formats for decimal, scientific, percent, currency and miscellaneous." );
        $j = 0;
        my $number_format_map =
        {
            currencyFormats =>
                {
                    xpath_container => './currencyFormats',
                    xpath_len       => './currencyFormatLength',
                    xpath_fmt       => './currencyFormat',
                    xpath_pat       => './pattern',
                    type            => 'currency',
                    regexp          => qr/currencyFormats\[\@numberSystem=["']([a-zA-Z0-9\_\-]+)["']\]/,
                },
            decimalFormats =>
                {
                    xpath_container => './decimalFormats',
                    xpath_len       => './decimalFormatLength',
                    xpath_fmt       => './decimalFormat',
                    xpath_pat       => './pattern',
                    type            => 'decimal',
                    regexp          => qr/decimalFormats\[\@numberSystem=["']([a-zA-Z0-9\_\-]+)["']\]/,
                },
            miscPatterns =>
                {
                    xpath_container => './miscPatterns',
                    xpath_pat       => './pattern',
                    type            => 'misc',
                    regexp          => qr/miscPatterns\[\@numberSystem=["']([a-zA-Z0-9\_\-]+)["']\]/,
                },
            percentFormats =>
                {
                    xpath_container => './percentFormats',
                    xpath_len       => './percentFormatLength',
                    xpath_fmt       => './percentFormat',
                    xpath_pat       => './pattern',
                    type            => 'percent',
                    regexp          => qr/percentFormats\[\@numberSystem=["']([a-zA-Z0-9\_\-]+)["']\]/,
                },
            scientificFormats =>
                {
                    xpath_container => './scientificFormats',
                    xpath_len       => './scientificFormatLength',
                    xpath_fmt       => './scientificFormat',
                    xpath_pat       => './pattern',
                    type            => 'scientific',
                    regexp          => qr/scientificFormats\[\@numberSystem=["']([a-zA-Z0-9\_\-]+)["']\]/,
                },
        };
        $sth = $sths->{number_formats_l10n} || die( "No statement object set for table 'number_formats_l10n' in file $f." );
        my $numbersRes = $mainDoc->findnodes( '/ldml/numbers' );
        if( $numbersRes->size )
        {
            my $el = $numbersRes->shift;
            my( $default_num_system, $other_num_system );
            # NOTE: Checking for locale default and other numbering systems
            &log( "Checking for locale default and other numbering systems." );
            # More than one may be defined, but we use only the first one
            my $defNumberingSysRes = $el->findnodes( './defaultNumberingSystem' );
            if( $defNumberingSysRes->size )
            {
                my $el_def_num_sys = $defNumberingSysRes->shift;
                $default_num_system = trim( $el_def_num_sys->textContent );
                if( !defined( $default_num_system ) ||
                    !length( $default_num_system // '' ) )
                {
                    die( "A default numbering system ID has been declared with tag 'defaultNumberingSystem', but is actually empty for locale ${locale} in file ${f}" );
                }
            }
            my $otherNumberingSysRes = $el->findnodes( './otherNumberingSystems' );
            if( $otherNumberingSysRes->size )
            {
                my $el_other_num_sys = $otherNumberingSysRes->shift;
                my $otherNumberingSysHasAliasRes = $el_other_num_sys->findnodes( './alias[@path]' );
                if( $otherNumberingSysHasAliasRes->size )
                {
                    $el_other_num_sys = resolve_alias( $otherNumberingSysHasAliasRes ) ||
                        die( "Unable to resolve alias for locale other number system for locale ${locale} in file ${f}" );
                }
                my @other_num_sys = $el_other_num_sys->nonBlankChildNodes;
                # <otherNumberingSystems>
                #     <traditional>jpan</traditional>
                #     <finance>jpanfin</finance>
                # </otherNumberingSystems>
                foreach my $el_other_num_sys ( @other_num_sys )
                {
                    my $num_sys_name = $el_other_num_sys->nodeName;
                    if( $num_sys_name ne 'native' &&
                        $num_sys_name ne 'traditional' &&
                        $num_sys_name ne 'finance' )
                    {
                        die( "Unknown other numbering system '${num_sys_name}' declared in locale '${locale}' in file ${f} for this element: ", $el_other_num_sys->toString() );
                    }
                    $other_num_system //= {};
                    $other_num_system->{ $num_sys_name } = trim( $el_other_num_sys->textContent );
                    if( !length( $other_num_system->{ $num_sys_name } // '' ) )
                    {
                        die( "Other numbering system ID '${num_sys_name}' has been declared, but is actually empty for locale ${locale} in file ${f} for this element: ", $el_other_num_sys->toString() );
                    }
                }
                if( defined( $default_num_system ) || defined( $other_num_system ) )
                {
                    my $def =
                    {
                        locale => $locale,
                        number_system => $default_num_system,
                        native => $other_num_system->{native},
                        traditional => $other_num_system->{traditional},
                        finance => $other_num_system->{finance},
                    };
                    eval
                    {
                        $sth_locale_num_sys->execute( @$def{qw( locale number_system native traditional finance )} );
                    } || die( "Error executing SQL query to add locale's numbering systems used for locale ${locale} in file ${f}: ", ( $@ || $sth_locale_num_sys->errstr ), "\nSQL Query: ", $sth_locale_num_sys->{Statement}, "\n", dump( $def ) );
                }
            }
            elsif( defined( $default_num_system ) )
            {
                my $def =
                {
                    locale => $locale,
                    number_system => $default_num_system,
                };
                eval
                {
                    $sth_locale_num_sys->execute( @$def{qw( locale number_system native traditional finance )} );
                } || die( "Error executing SQL query to add locale's numbering systems used for locale ${locale} in file ${f}: ", ( $@ || $sth_locale_num_sys->errstr ), "\nSQL Query: ", $sth_locale_num_sys->{Statement}, "\n", dump( $def ) );
            }

            foreach my $n_type ( sort( keys( %$number_format_map ) ) )
            {
                $j = 0;
                my $this = $number_format_map->{ $n_type };
                my $numberContainerRes = $el->findnodes( $this->{xpath_container} );
                my $type = $this->{type};
                while( my $el_container = $numberContainerRes->shift )
                {
                    # <decimalFormats numberSystem="latn">
                    my $sys_id;
                    if( $el_container->hasAttribute( 'numberSystem' ) )
                    {
                        $sys_id = $el_container->getAttribute( 'numberSystem' ) ||
                            die( "Unable to get the numbering system value from the attribute 'numberSystem' for number format of type ${n_type} (${type}) for locale ${locale} in file ${f} for this element: ", $el_container->toString() );
                    }
                    elsif( defined( $default_num_system ) )
                    {
                        my $isDeuplicateRes = $el->findnodes( $this->{xpath_container} . '[@numberSystem="' . $default_num_system . '"]' );
                        if( $isDeuplicateRes->size )
                        {
                            &log( "The number format of type ${type} has no 'numberSystem' attribute set, and the default 'numberSystem' value '${default_num_system}' exists already, so we skip it to avoid creating a duplicate in the database for locale ${locale} in file ${f}" );
                            next;
                        }
                        else
                        {
                            $sys_id = $default_num_system;
                        }
                    }
                    elsif( defined( $other_num_system ) && $other_num_system->{native} )
                    {
                        my $isDeuplicateRes = $el->findnodes( $this->{xpath_container} . '[@numberSystem="' . $other_num_system->{native} . '"]' );
                        if( $isDeuplicateRes->size )
                        {
                            &log( "The number format of type ${type} has no 'numberSystem' attribute set, and the default 'numberSystem' value '$other_num_system->{native}' exists already, so we skip it to avoid creating a duplicate in the database for locale ${locale} in file ${f}" );
                            next;
                        }
                        else
                        {
                            $sys_id = $other_num_system->{native};
                        }
                    }
                    else
                    {
                        warn( "Warning only: no attribute 'numberSystem' found for this number format of type ${n_type} (${type}), and no default (defaultNumberingSystem) or other (otherNumberingSystems) number system declared for locale ${locale} in file ${f} for this element'. Skipping: ", $el_container->toString() );
                        next;
                    }
                    my $numFormatAliasRes = $el_container->findnodes( './alias[@path]' );
                    # Example: <alias source="locale" path="../symbols[@numberSystem='latn']"/>
                    if( $numFormatAliasRes->size )
                    {
                        $el_container = resolve_alias( $numFormatAliasRes ) ||
                            die( "This number format of type ${n_type} (${type}) is aliased, but could not resolve it for number system ${sys_id} and for locale ${locale} in file ${f} for this element: ", $el->toString() );
                    }
                    my $format_data = [];
                    # <decimalFormats numberSystem="latn">
                    #     <decimalFormatLength>
                    #         <decimalFormat>
                    #             <pattern>#,##0.###</pattern>
                    #         </decimalFormat>
                    #     </decimalFormatLength>
                    #     <decimalFormatLength type="long">
                    #         <alias source="locale" path="../decimalFormatLength[@type='short']"/>
                    #     </decimalFormatLength>
                    #     <decimalFormatLength type="short">
                    #         <decimalFormat>
                    #             <pattern type="1000" count="other">0K</pattern>
                    #             <pattern type="10000" count="other">00K</pattern>
                    #             <pattern type="100000" count="other">000K</pattern>
                    #             <pattern type="1000000" count="other">0M</pattern>
                    #             <pattern type="10000000" count="other">00M</pattern>
                    #             <pattern type="100000000" count="other">000M</pattern>
                    #             <pattern type="1000000000" count="other">0G</pattern>
                    #             <pattern type="10000000000" count="other">00G</pattern>
                    #             <pattern type="100000000000" count="other">000G</pattern>
                    #             <pattern type="1000000000000" count="other">0T</pattern>
                    #             <pattern type="10000000000000" count="other">00T</pattern>
                    #             <pattern type="100000000000000" count="other">000T</pattern>
                    #         </decimalFormat>
                    #     </decimalFormatLength>
                    # </decimalFormats>
                    
                    # <currencyFormats numberSystem="arab">
                    #     <currencySpacing>
                    #         <alias source="locale" path="../../currencyFormats[@numberSystem='latn']/currencySpacing"/>
                    #     </currencySpacing>
                    #     <currencyFormatLength>
                    #         <currencyFormat type="standard">
                    #             <pattern>#,##0.00 ¤</pattern>
                    #             <pattern alt="noCurrency">#,##0.00</pattern>
                    #         </currencyFormat>
                    #         <currencyFormat type="accounting">
                    #             <alias source="locale" path="../currencyFormat[@type='standard']"/>
                    #         </currencyFormat>
                    #     </currencyFormatLength>
                    # </currencyFormats>
                    my $process_pattern = sub
                    {
                        my( $el_pat, $def ) = @_;
                        $def->{format_id} = 'default';
                        if( $el_pat->hasAttribute( 'type' ) )
                        {
                            $def->{format_id} = $el_pat->getAttribute( 'type' );
                            if( !defined( $def->{format_id} ) ||
                                !length( $def->{format_id} // '' ) )
                            {
                                die( "Unable to get the number format ID for number format of type ${n_type} (${type}) for this numbering system ID ${sys_id} for this locale ${locale} in file ${f} for this element: ", $el_pat->toString() );
                            }
                        }
                        if( $el_pat->hasAttribute( 'alt' ) )
                        {
                            $def->{alt} = $el_pat->getAttribute( 'alt' ) ||
                                die( "Unable to get the number format pattern alt value from attribute 'alt' for this number format of type ${n_type} (${type}) for numbering system ID ${sys_id} for locale ${locale} in file ${f} for this element: ", $el_pat->toString() );
                        }
                        else
                        {
                            $def->{alt} = undef;
                        }
                        if( $el_pat->hasAttribute( 'count' ) )
                        {
                            $def->{count} = $el_pat->getAttribute( 'count' ) ||
                                die( "Unable to get the number format pattern count value from attribute 'count' for this number format of type ${n_type} (${type}) for numbering system ID ${sys_id} for locale ${locale} in file ${f} for this element: ", $el_pat->toString() );
                        }
                        else
                        {
                            $def->{count} = undef;
                        }
                        $def->{format_pattern} = $el_pat->textContent;
                        push( @$format_data, $def );
                    };
                    if( exists( $this->{xpath_len} ) &&
                        length( $this->{xpath_len} // '' ) )
                    {
                        my $numFormatLengthRes = $el_container->findnodes( $this->{xpath_len} );
                        while( my $el_len = $numFormatLengthRes->shift )
                        {
                            my $len = 'default';
                            if( $el_len->hasAttribute( 'type' ) )
                            {
                                $len = $el_len->getAttribute( 'type' ) ||
                                    die( "Unable to get the number format length type from attribute 'type' for this number format of type ${n_type} (${type}) for this locale ${locale} in file ${f} for this element: ", $el_len->toString() );
                            }
                            my $numFormatLengthHasAliasRes = $el_len->findnodes( './alias[@path]' );
                            if( $numFormatLengthHasAliasRes->size )
                            {
                                $el_len = resolve_alias( $numFormatLengthHasAliasRes ) ||
                                    die( "This number format of type ${n_type} (${type}) for length ${len} is aliased, but I could not resolve it for this element in file $f: ", $el_container->toString() );
                            }
                            my $numFormatRes = $el_len->findnodes( $this->{xpath_fmt} ) ||
                                die( "Unable to get any number format tag for number format of type ${n_type} (${type}) for this numbering system ID ${sys_id} for locale ${locale} in file ${f} for this element: ", $el_len->toString() );
                            while( my $el_fmt_actual = $numFormatRes->shift )
                            {
                                my $fmt_type = 'default';
                                if( $el_fmt_actual->hasAttribute( 'type' ) )
                                {
                                    $fmt_type = $el_fmt_actual->getAttribute( 'type' ) ||
                                        die( "Unable to get the number formatting type from attribute 'type' for this number format of type ${n_type} (${type}) for numbering system ID ${sys_id} for locale ${locale} in file ${f} for this element: ", $el_fmt_actual->toString() );
                                }
                                my $numFormatPatternsRes = $el_fmt_actual->findnodes( $this->{xpath_pat} );
                                while( my $el_pat = $numFormatPatternsRes->shift )
                                {
                                    my $def =
                                    {
                                        locale          => $locale,
                                        number_system   => $sys_id,
                                        number_type     => $type,
                                        format_length   => $len,
                                        format_type     => $fmt_type,
                                    };
                                    $process_pattern->( $el_pat, $def );
                                }
                            }
                        }
                    }
                    # The number format patterns are directly defined under the numbering system ID, such as with miscellaneous
                    else
                    {
                        my $numFormatPatternsRes = $el_container->findnodes( $this->{xpath_pat} );
                        while( my $el_pat = $numFormatPatternsRes->shift )
                        {
                            my $def =
                            {
                                locale          => $locale,
                                number_system   => $sys_id,
                                number_type     => $type,
                                format_length   => 'long',
                                format_type     => 'default',
                            };
                            $process_pattern->( $el_pat, $def );
                        }
                    }
                    my $total = scalar( @$format_data );
                    &log( "\tLoading ${total} ${type} number format patterns for number system ${sys_id}." );
                    my $k = 0;
                    foreach my $def ( @$format_data )
                    {
                        eval
                        {
                            # We need to force DBD::SQLite to treat the format_id as a text and not as an integer, otherwise, the check constraint on format_id would fail on ID such as 10000000000000000000 for locale 'ja'
                            my @keys = qw( locale number_system number_type format_length format_type format_id format_pattern alt count );
                            for( my $i = 0; $i < scalar( @keys ); $i++ )
                            {
                                $sth->bind_param( $i + 1, $def->{ $keys[$i] }, SQL_VARCHAR );
                            }
                            # $sth->execute( @$def{qw( locale number_system number_type format_length format_type format_id format_pattern alt count )} );
                            $sth->execute;
                        } || die( "Error executing query to add locale numbering system pattern for locale ${locale} in file ${f}: ", ( $@ || $sth->errstr ), "\nwith query: ", $sth->{Statement}, "\n", dump( $def ) );
                        $j++;
                        $k++;
                        $out->print( "${k}/${total}\r" ) if( $DEBUG > 1 );
                    }
                    $out->print( "\n" ) if( $DEBUG > 1 );
                }
                $out->printf( "\t%d ${type} number format patterns added.\n", $j ) if( $DEBUG );
            }
        }
        else
        {
            $out->print( "\tno number formats defined for this locale ${locale} in file ${f}\n" ) if( $DEBUG );
        }
    
        # NOTE: Adding locale units
        &log( "\tAdding locale units." );
        $j = 0;
        my $unit_locale_map =
        {
            compoundUnit =>
                {
                    type        => 'compound',
                    xpath_unit  => './compoundUnit',
                    xpath_pat   => './*[local-name()="unitPrefixPattern" or local-name()="compoundUnitPattern" or local-name()="compoundUnitPattern1"]',
                },
            unit =>
                {
                    type        => 'regular',
                    xpath_unit  => './unit',
                    xpath_pat   => './*[local-name()="unitPattern" or local-name()="perUnitPattern"]',
                },
        };
        my $pattern_type_map =
        {
            compoundUnitPattern     => 'regular',
            compoundUnitPattern1    => 'regular',
            unitPrefixPattern       => 'prefix',
            unitPattern             => 'regular',
            perUnitPattern          => 'per-unit',
        };
        $sth = $sths->{units_l10n} || die( "Unable to get a statement object for table 'units_l10n' in file $f." );
        my $process_unit = sub
        {
            my( $def, $kids ) = @_;
            my $patterns = [];
            foreach my $el_kid ( @$kids )
            {
                my $tag = $el_kid->nodeName;
                if( $tag eq 'displayName' )
                {
                    $def->{locale_name} = $el_kid->textContent;
                }
                elsif( exists( $pattern_type_map->{ $tag } ) )
                {
                    $def->{pattern_type} = $pattern_type_map->{ $tag };
                    $def->{unit_pattern} = trim( $el_kid->textContent );
                    if( $el_kid->hasAttribute( 'count' ) )
                    {
                        $def->{count} = $el_kid->getAttribute( 'count' );
                    }
                    if( $el_kid->hasAttribute( 'gender' ) )
                    {
                        $def->{gender} = $el_kid->getAttribute( 'gender' );
                    }
                    push( @$patterns, { %$def } );
                }
                else
                {
                    die( "Unknown element tag for this unit ID $def->{unit_id} for unit length $def->{format_length} for locale ${locale} in file ${f} for this element: ", $el_kid->toString() );
                }
            }
            return( $patterns );
        };
        my $unitsRes = $mainDoc->findnodes( '/ldml/units/unitLength' );
        &log( sprintf( "\t%d locale unit information found.", $unitsRes->size ) );
        while( my $el = $unitsRes->shift )
        {
            my $len = $el->getAttribute( 'type' ) ||
                die( "Unable to get this unit length from the attribute 'type' for locale ${locale} in file ${f}" );
            my $unitsAliasRes = $el->findnodes( './alias[@path]' );
            # Example: <alias source="locale" path="../unitLength[@type='short']"/>
            # <alias source="locale" path="../unit[@type='energy-kilocalorie']"/>
            if( $unitsAliasRes->size )
            {
                $el = resolve_alias( $unitsAliasRes ) ||
                    die( "Unit length is aliased, but I could not resolve it for locale ${locale} in file ${f}" );
            }
            foreach my $u_type ( sort( keys( %$unit_locale_map ) ) )
            {
                my $this = $unit_locale_map->{ $u_type };
                my $type = $this->{type};
                my $unitsRes = $el->findnodes( $this->{xpath_unit} );
                if( !$unitsRes->size )
                {
                    warn( "Warning only: no unit definition found for units of type ${type} with length ${len} for locale ${locale} in file ${f}" );
                    next;
                }
                # Example: <compoundUnit type="10p-1">
                #          <unit type="acceleration-g-force">
                while( my $el_unit = $unitsRes->shift )
                {
                    my $id = $el_unit->getAttribute( 'type' ) ||
                        die( "Unable to get the unit ID from the attribute 'type' with length ${len} for this locale ${locale} in file ${f} for this element: ", $el_unit->toString() );
                    my $unitAliasRes = $el_unit->findnodes( './alias[@path]' );
                    # If this unit is aliased
                    if( $unitAliasRes->size )
                    {
                        $el_unit = resolve_alias( $unitAliasRes ) ||
                            die( "This unit length with ID ${id} is aliased, but could not resolve it with length ${len} for this locale ${locale} in file ${f} for this element: ", $el->toString() );
                    }
    
                    my @kids = $el_unit->nonBlankChildNodes;
                    if( !scalar( @kids ) )
                    {
                        warn( "Warning only: no definition elements for this unit ID ${id} with length ${len} for locale ${locale} in file ${f} for this element: ", $el_unit->toString() );
                    }
    
                    my $patterns = [];
                    my( $locale_name, $gender );
                    foreach my $el_kid ( @kids )
                    {
                        my $tag = $el_kid->nodeName;
                        if( $tag eq 'displayName' )
                        {
                            $locale_name = $el_kid->textContent;
                        }
                        elsif( $tag eq 'gender' )
                        {
                            $gender = trim( $el_kid->textContent );
                            if( $gender ne 'feminine' &&
                                $gender ne 'masculine' && 
                                $gender ne 'neuter' &&
                                $gender ne 'inanimate' &&
                                $gender ne 'common' )
                            {
                                die( "The gender for this unit ID ${id} with length ${len} is '${gender}', but I expected either 'masculine', 'feminine', 'neuter' or 'inanimate' for locale ${locale} in file ${f} for this element: ", $el_unit->toString() );
                            }
                        }
                        elsif( exists( $pattern_type_map->{ $tag } ) )
                        {
                            my $def =
                            {
                                locale          => $locale,
                                format_length   => $len,
                                unit_type       => $type,
                                unit_id         => $id,
                                locale_name     => $locale_name,
                            };
                            $def->{pattern_type} = $pattern_type_map->{ $tag };
                            $def->{unit_pattern} = trim( $el_kid->textContent );
                            if( $el_kid->hasAttribute( 'count' ) )
                            {
                                $def->{count} = $el_kid->getAttribute( 'count' );
                            }
                            if( $el_kid->hasAttribute( 'gender' ) )
                            {
                                $def->{gender} = $el_kid->getAttribute( 'gender' );
                            }
                            elsif( defined( $gender ) )
                            {
                                $def->{gender} = $gender;
                            }
                            if( $el_kid->hasAttribute( 'case' ) )
                            {
                                $def->{gram_case} = $el_kid->getAttribute( 'case' );
                            }
                            push( @$patterns, $def );
                        }
                        else
                        {
                            die( "Unknown element tag '${tag}' for this unit ID ${id} for unit length ${len} for locale ${locale} in file ${f} for this element: ", $el_kid->toString() );
                        }
                    }
    
                    foreach my $def ( @$patterns )
                    {
                        eval
                        {
                            $sth->execute( @$def{qw( locale format_length unit_type unit_id unit_pattern pattern_type locale_name count gender gram_case )} );
                        } || die( "Error executing SQL query to add unit information with id ${id} with length ${len} for locale ${locale} in file ${f}: ", ( $@ || $sth->errstr ), "\nSQL Query: ", $sth->{Statement}, "\n", dump( $def ) );
                        $j++;
                    }
                }
                # Done checking all the unit definitions
            }
            # Done checking each known unit types (compound and regular)
        }
        # Done checking all unit length definitions
        $out->printf( "\t%d locale unit information added.\n", $j ) if( $DEBUG );
    
        # NOTE: Checking localised names for calendar IDs
        &log( "Checking localised names for calendar IDs." );
        my $calendarNamesRes = $mainDoc->findnodes( '/ldml/localeDisplayNames/types/type[@key="calendar" and @type and not(@scope) and not(@alt)]' );
        $j = 0;
        while( my $el = $calendarNamesRes->shift )
        {
            my $def =
            {
                locale => $locale,
                calendar => ( $el->getAttribute( 'type' ) || die( "Localised calendar is missing its ID for locale ${locale} in file ${f} for this element: ", $el->toString() ) ),
                locale_name => trim( $el->textContent ),
            };
            eval
            {
                $sth_cals_l10n->execute( @$def{qw( locale calendar locale_name )} );
            } || die( "Error executing SQL query to add localised calendar ID information with calendar id $def->{calendar} for locale ${locale} in file ${f}: ", ( $@ || $sth_cals_l10n->errstr ), "\nSQL Query: ", $sth_cals_l10n->{Statement}, "\n", dump( $def ) );
            $j++;
        }
        $out->printf( "\t%d locale calendar ID information added.\n", $j ) if( $DEBUG );
    
        # NOTE: Checking localised names for number system IDs
        &log( "Checking localised names for number system IDs." );
        # /ldml/localeDisplayNames/types/type[@key="calendar" and @type and not(@scope)]
        my $numberSystemNamesRes = $mainDoc->findnodes( '/ldml/localeDisplayNames/types/type[@key="numbers" and @type and not(@scope) and not(@alt)]' );
        $j = 0;
        while( my $el = $numberSystemNamesRes->shift )
        {
            my $def =
            {
                locale => $locale,
                number_system => ( $el->getAttribute( 'type' ) || die( "Localised number system is missing its ID for locale ${locale} in file ${f} for this element: ", $el->toString() ) ),
                locale_name => trim( $el->textContent ),
            };
            if( $el->hasAttribute( 'alt' ) )
            {
                $def->{alt} = $el->getAttribute( 'alt' );
            }
            $out->print( "\t[$def->{number_system}] " ) if( $DEBUG );

            # finance, native and traditional are part of other possible numbering systems, but undefined in the CLDR
            # <https://unicode.org/reports/tr35/tr35-numbers.html#otherNumberingSystems>
            if( !exists( $number_systems->{ $def->{number_system} } ) )
            {
                warn( "Warning only: the number system '$def->{number_system}' used in localised data for locale '${locale}' is unknown to us in file ${f} for element: ", $el->toString() ) unless( $def->{number_system} eq 'native' || $def->{number_system} eq 'traditional' or $def->{number_system} eq 'finance' );
                $out->print( "unknown, skipping.\n" ) if( $DEBUG );
                next;
            }
    
            eval
            {
                $sth_num_sys_l10n->execute( @$def{qw( locale number_system locale_name alt )} );
            } || die( "Error executing SQL query to add localised number system ID information with number system id $def->{number_system} for locale ${locale} in file ${f}: ", ( $@ || $sth_num_sys_l10n->errstr ), "\nSQL Query: ", $sth_num_sys_l10n->{Statement}, "\n", dump( $def ) );
            $j++;
            $out->print( "ok\n" ) if( $DEBUG );
        }
        $out->printf( "\t%d locale number system ID information added.\n", $j ) if( $DEBUG );
    
        # NOTE: Checking localised names for collation IDs
        &log( "Checking localised names for collation IDs." );
        my $collationNamesRes = $mainDoc->findnodes( '/ldml/localeDisplayNames/types/type[@key="collation" and @type and not(@scope)]' );
        $j = 0;
        while( my $el = $collationNamesRes->shift )
        {
            my $def =
            {
                locale => $locale,
                collation => ( $el->getAttribute( 'type' ) || die( "Localised collation is missing its ID for locale ${locale} in file ${f} for this element: ", $el->toString() ) ),
                locale_name => trim( $el->textContent ),
            };
            eval
            {
                $sth_collation_l10n->execute( @$def{qw( locale collation locale_name )} );
            } || die( "Error executing SQL query to add localised collation ID information with collation id $def->{collation} for locale ${locale} in file ${f}: ", ( $@ || $sth_collation_l10n->errstr ), "\nSQL Query: ", $sth_collation_l10n->{Statement}, "\n", dump( $def ) );
            $j++;
        }
        $out->printf( "\t%d locale collation ID information added.\n", $j ) if( $DEBUG );
        $n++;
    }
    &log( "${n} locales information processed." );
    
    # NOTE: Loading annotations
    &log( "Loading annotations." );
    $n = 0;
    my $l = 0;
    $anno_dir->open || die( "Unable to open annotation directory ${anno_dir}: ", $anno_dir->error );
    # add_missing_to_dir( $anno_dir );
    $sth = $sths->{annotations} || die( "No SQL statement object for annotations" );
    # while( my $f = $anno_dir->read( as_object => 1, exclude_invisible => 1 ) )
    @files = $anno_dir->read( as_object => 1, exclude_invisible => 1, 'sort' => 1 );
    foreach my $f ( @files )
    {
        next if( $f->extension ne 'xml' );
        my $annoDoc = load_xml( $f );
        my $locale = identity_to_locale( $annoDoc );
        ( my $locale2 = $f->basename( '.xml' ) ) =~ tr/_/-/;
        if( lc( $locale ) ne lc( $locale2 ) &&
            $locale2 ne 'root' )
        {
            warn( "XML identity says the locale is '${locale}', but the file basename says it should be '${locale2}', and I think the file basename is correct for file $f" );
            $locale = $locale2;
        }
        if( index( $locale, 'root' ) != -1 )
        {
            if( length( $locale ) > 4 )
            {
                my $loc = Locale::Unicode->new( $locale );
                $loc->language( 'und' );
                $locale = $loc->as_string;
            }
            else
            {
                $locale = 'und';
            }
        }
        $out->print( "[${locale}] " ) if( $DEBUG );
        $l++;
        my $annoRes = $annoDoc->findnodes( '//annotations/annotation' );
        if( !$annoRes->size )
        {
            warn( "Warning only: unable to get the annotation data for locale '${locale}' in file $f" );
        }
        my $i = 0;
        while( my $el = $annoRes->get_node(++$i) )
        {
            my $id = $el->getAttribute( 'cp' );
            if( !defined( $id ) ||
                !length( $id ) )
            {
                die( "No ID set for this annotation element in file $f: ", $el->toString() );
            }
            # Example: &lt; or &amp;
            if( index( $id, '&' ) != -1 &&
                index( $id, ';' ) != -1 )
            {
                $id = decode_entities( $id );
            }
            my $val = $el->textContent;
            if( index( $val, '&' ) != -1 &&
                index( $val, ';' ) != -1 )
            {
                $val = decode_entities( $val );
            }
            my $defaults = [split( /[[:blank:]\h]*\|[[:blank:]\h]*/, $val )];
            my $tts;
            my $sibling = $annoRes->get_node( $i + 1 );
            if( $sibling &&
                $sibling->getAttribute( 'cp' ) eq $id &&
                $sibling->hasAttribute( 'type' ) &&
                ( $sibling->getAttribute( 'type' ) || '' ) eq 'tts' )
            {
                $tts = $sibling->textContent;
                $i++;
                if( !defined( $tts ) ||
                    !length( $tts ) )
                {
                    die( "TTS definition exists for this annotation '${id}' at position ${i}, but the TTS value is empty in file $f." );
                }
                elsif( index( $tts, '|' ) != -1 )
                {
                    die( "It seems this TTS value is designed to contain multiple values. This is unexpected, and would require a change in the database schema to reflect that, in file $f." );
                }
            }
            eval
            {
                $sth->execute( $locale, $id, to_array( $defaults ), $tts );
            } || die( "Error adding localised information for annotation No ${i} (${id}) in file $f: ", ( $@ || $sth->errstr ) );
            $n += ( defined( $tts ) ? 2 : 1 );
        }
        $out->print( "ok ${i} annotations added.\n" ) if( $DEBUG );
    }
    &log( "${n} annotations added for ${l} locales." );
    
    # NOTE: Loading languages match rules
    &log( "Loading languages match rules." );
    $n = 0;
    $sth = $sths->{languages_match} || die( "No SQL statement object for languages_match" );
    my $lang_match_file = $basedir->child( 'supplemental/languageInfo.xml' );
    my $langMatchDoc = load_xml( $lang_match_file );
    my $langMatchVar = $langMatchDoc->findnodes( '/supplementalData/languageMatching/languageMatches/matchVariable' ) ||
        die( "Unable to get the language match variables in ${lang_match_file}" );
    $out->print( $langMatchVar->size, " language match variables found.\n" ) if( $DEBUG );
    my $langMatchRes = $langMatchDoc->findnodes( '/supplementalData/languageMatching/languageMatches/languageMatch' ) ||
        die( "Unable to get the language matches in ${lang_match_file}" );
    # Transform separator from '_' to '-'
    my $normalise_sep = 1;
    my $seq = 0;
    my $lang_match_bool_map =
    {
        true => 1,
        false => 0,
    };
    # By default, desired and supported are symmetric:
    # <http://web.archive.org/web/20220723011210/https://unicode-org.github.io/cldr-staging/charts/37/supplemental/language_matching.html>
    while( my $el = $langMatchVar->shift )
    {
        # <matchVariable id="$enUS" value="AS+CA+GU+MH+MP+PH+PR+UM+US+VI"/>
        my $var = $el->getAttribute( 'id' ) ||
            die( "No variable name set in attribute 'id' for this element in file $lang_match_file: ", $el->toString() );
        my $data = $el->getAttribute( 'value' ) ||
            die( "No variable value set in attribute 'value' for this element in file $lang_match_file: ", $el->toString() );
        # The algorithm is actually more versatile with '+' adding to the set and '-' removing from set
        # Luckily, the latter is not used, so we can just simply add all to the set
        # Might need to improve on that in the future through, as this might become a liability
        my $val = [split( /\+/, $data )];
        $var =~ s/^\$//;
        $out->print( "Found variable '${var}' with values: ", join( ', ', @$val ), "\n" ) if( $DEBUG );
        $lang_vars->{ $var } = $val;
    }
    
    while( my $el = $langMatchRes->shift )
    {
        # <languageMatch desired="hr"	supported="bs"	distance="4"/>
        my $def = {};
        foreach my $prop ( qw( desired supported distance ) )
        {
            my $val = $el->getAttribute( $prop );
            if( !defined( $val ) ||
                !length( $val ) )
            {
                die( "No variable value set in attribute '${prop}' for this element in file $lang_match_file: ", $el->toString() );
            }
            $val =~ s/_/-/gs if( ( $prop eq 'desired' or $prop eq 'supported' ) && $normalise_sep );
            $def->{ $prop } = $val;
        }
        if( $el->hasAttribute( 'oneway' ) )
        {
            my $bool = $el->getAttribute( 'oneway' ) ||
                die( "No boolean value set in attribute 'oneway' for this element in file $lang_match_file: ", $el->toString() );
            if( !exists( $lang_match_bool_map->{ $bool } ) )
            {
                die( "No match found in boolean map for value '${bool}' in file $lang_match_file" );
            }
            # We reverse the value, since the XML specifies whether this entry is asymmetric
            $def->{is_symetric} = ( $lang_match_bool_map->{ $bool } ? 0 : 1 );
        }
        $out->print( "[$def->{desired} -> $def->{supported}] " ) if( $DEBUG );
        # <languageMatch desired="en_*_$enUS"	supported="en_*_$enUS"	distance="4"/>
        # <languageMatch desired="en_*_$!enUS"	supported="en_*_GB"	distance="3"/>
        # There is a match variable embedded
        if( index( $def->{desired}, '*' ) != -1 ||
            index( $def->{desired}, '$' ) != -1 )
        {
            $def->{sequence} = ++$seq;
            # $def->{was} = { desired => $def->{desired} };
            # <languageMatch desired="*_*_*"	supported="*_*_*"	distance="4"/>
            # <languageMatch desired="pt_*_*"	supported="pt_*_*"	distance="5"/>
            # <languageMatch desired="en_*_*"	supported="en_*_*"	distance="5"/>
            # <languageMatch desired="*_*"	supported="*_*"	distance="50"/>
            # <languageMatch desired="en_*_$enUS"	supported="en_*_$enUS"	distance="4"/>
            # <languageMatch desired="en_*_$!enUS"	supported="en_*_GB"	distance="3"/>
            # <languageMatch desired="zh_Hant_*"	supported="zh_Hant_*"	distance="5"/>
            $def->{desired} =~ s{
                ^
                (?:
                    (?<language>\*|[a-zA-Z0-9]+)
                    |
                    (?:
                        (?<language>\*|[a-zA-Z0-9]+)
                        (?<sep1>[^\*a-zA-Z0-9]+)
                        (?:
                            (?:
                                (?<script>\*|[a-zA-Z0-9]+)
                                (?<sep2>[^\*\$a-zA-Z0-9]+)
                                (?<territory>\*|[a-zA-Z0-9]+|\$(?<var_negative>\!)?(?<var_name>[a-zA-Z][a-zA-Z0-9]+))
                            )
                            |
                            (?:
                                (?<territory>\*|[a-zA-Z0-9]+|\$(?<var_negative>\!)?(?<var_name>[a-zA-Z][a-zA-Z0-9]+))
                            )
                        )
                    )
                )
                $
            }
            {
                my $re = {%+};
                ( $re->{language} eq '*' ? "(?<language>[a-zA-Z0-9]+)" : $re->{language} ) .
                ( ( $re->{script} || $re->{territory} )
                    ?
                        (
                            $re->{sep1} .
                            ( $re->{script}
                                ?
                                    (
                                        ( $re->{script} eq '*' ? "(?<script>[a-zA-Z0-9]+)" : $re->{script} ) .
                                        $re->{sep2} . 
                                        ( $re->{territory} eq '*' ? "(?<territory>[a-zA-Z0-9]+)" : &process_lang_match_territory( $re ) )
                                    )
                                :
                                ( $re->{territory} eq '*' ? "(?<territory>[a-zA-Z0-9]+)" : &process_lang_match_territory( $re ) )
                            )
                        )
                    : ''
                );
            }exs;
            $def->{is_regexp} = 1;
            $out->print( " becomes [$def->{desired}] -> " ) if( $DEBUG );
        }
        if( index( $def->{supported}, '*' ) != -1 ||
            index( $def->{supported}, '$' ) != -1 )
        {
            # $def->{was}->{supported} = $def->{supported};
            $def->{supported} =~ s{
                ^
                (?:
                    (?<language>\*|[a-zA-Z0-9]+)
                    |
                    (?:
                        (?<language>\*|[a-zA-Z0-9]+)
                        (?<sep1>[^\*a-zA-Z0-9]+)
                        (?:
                            (?:
                                (?<script>\*|[a-zA-Z0-9]+)
                                (?<sep2>[^\*\$a-zA-Z0-9]+)
                                (?<territory>\*|[a-zA-Z0-9]+|\$(?<var_negative>\!)?(?<var_name>[a-zA-Z][a-zA-Z0-9]+))
                            )
                            |
                            (?:
                                (?<territory>\*|[a-zA-Z0-9]+|\$(?<var_negative>\!)?(?<var_name>[a-zA-Z][a-zA-Z0-9]+))
                            )
                        )
                    )
                )
                $
            }
            {
                my $re = {%+};
                ( $re->{language} eq '*' ? '$+{language}' : $re->{language} ) .
                ( ( $re->{script} || $re->{territory} )
                    ?
                        (
                            '\\' . $re->{sep1} .
                            ( $re->{script}
                                ?
                                    (
                                        ( $re->{script} eq '*' ? '$+{script}' : $re->{script} ) .
                                        '\\' . $re->{sep2} . 
                                        ( ( $re->{territory} eq '*' || $re->{var_name} ) ? '$+{territory}' : $re->{territory} )
                                    )
                                :
                                ( ( $re->{territory} eq '*' || $re->{var_name} ) ? '$+{territory}' : $re->{territory} )
                            )
                        )
                    : ''
                );
            }exs;
            $out->print( "[$def->{supported}] " ) if( $DEBUG );
        }
    
        eval
        {
            $sth->execute( @$def{qw( desired supported distance is_symetric is_regexp sequence )} );
        } || die( "Error adding rule information for language match $def->{desired} -> $def->{supported} in file $lang_match_file: ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
        $n++;
        $out->print( "ok\n" ) if( $DEBUG );
    }
    &log( "${n} languages match rules added." );
    
    # NOTE: Loading units
    &log( "Loading units." );
    $n = 0;
    my $units_file = $basedir->child( 'supplemental/units.xml' );
    my $unitsDoc = load_xml( $units_file );
    my $unitsPrefixesRes = $unitsDoc->findnodes( '/supplementalData/unitPrefixes/unitPrefix' ) ||
        die( "Unable to get any unit prefixes data from file ${units_file}" );
    my $unitsConstRes = $unitsDoc->findnodes( '/supplementalData/unitConstants/unitConstant' ) ||
        die( "Unable to get any unit constants data from file ${units_file}" );
    my $unitsQuantitiesRes = $unitsDoc->findnodes( '/supplementalData/unitQuantities/unitQuantity' ) ||
        die( "Unable to get any unit quantities data from file ${units_file}" );
    my $unitsConvertRes = $unitsDoc->findnodes( '/supplementalData/convertUnits/convertUnit' ) ||
        die( "Unable to get any unit conversion data from file ${units_file}" );
    my $unitsPrefsRes = $unitsDoc->findnodes( '/supplementalData/unitPreferenceData/unitPreferences' ) ||
        die( "Unable to get any unit preferences data from file ${units_file}" );
    my $unitsAliasesRes = $unitsDoc->findnodes( '/supplementalData/metadata/alias/unitAlias' ) ||
        die( "Unable to get any unit aliases data from file ${units_file}" );
    my $j = 0;
    # NOTE: Loading unit prefixes
    &log( "Loading unit prefixes." );
    $sth = $sths->{unit_prefixes} || die( "No statement object for 'unit_prefixes'" );
    while( my $el = $unitsPrefixesRes->shift )
    {
        my $def =
        {
            unit_id => ( $el->getAttribute( 'type' ) || die( "Unable to get the unit prefix ID in the attribute 'type' for this element in file $units_file: ", $el->toString() ) ),
            symbol => ( $el->getAttribute( 'symbol' ) || die( "Unable to get the unit symbol in the attribute 'symbol' for this element in file $units_file: ", $el->toString() ) ),
        };
        $out->print( "[$def->{unit_id}] " ) if( $DEBUG );
        if( $el->hasAttribute( 'power10' ) )
        {
            $def->{power} = 10;
            $def->{factor} = $el->getAttribute( 'power10' );
        }
        elsif( $el->hasAttribute( 'power2' ) )
        {
            $def->{power} = 2;
            $def->{factor} = $el->getAttribute( 'power2' );
        }
        else
        {
            die( "This element has no power10 or power2 attribute in file $units_file: ", $el->toString() );
        }
    
        eval
        {
            $sth->execute( @$def{qw( unit_id symbol power factor )} );
        } || die( "Error adding unit prefix information for unit ID '$def->{unit_id}' in file $units_file: ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
        $n++;
        $j++;
        $out->print( "ok\n" ) if( $DEBUG );
    }
    &log( "${j} unit prefixes added." );
    
    # NOTE: Loading unit constants
    &log( "Loading unit constants." );
    $j = 0;
    $sth = $sths->{unit_constants} || die( "No statement object for 'unit_constants'" );
    my $unit_constants = {};
    while( my $el = $unitsConstRes->shift )
    {
        my $def =
        {
            constant => ( $el->getAttribute( 'constant' ) || die( "Unable to get the unit constant in the attribute 'constant' for this element in file $units_file: ", $el->toString() ) ),
            expression => ( $el->getAttribute( 'value' ) || die( "Unable to get the unit constant value in the attribute 'value' for this element in file $units_file: ", $el->toString() ) ),
        };
        $out->print( "[$def->{constant}] " ) if( $DEBUG );
        # From the longest to the shortest
        my @constants = reverse( sort( keys( %$unit_constants ) ) );
        if( scalar( @constants ) )
        {
            my $constants_re = join( '|', @constants );
            my $expr = $def->{expression};
            if( $expr =~ s/($constants_re)/$unit_constants->{ $1 }/g )
            {
                local $@;
                $def->{value} = eval( $expr );
                if( $@ )
                {
                    die( "Error evaluating the constant expression '${expr}' (originally '$def->{expression}') in file $units_file: $@" );
                }
            }
            elsif( index( $expr, '*' ) != -1 ||
                   index( $expr, '/' ) != -1 )
            {
                local $@;
                $def->{value} = eval( $expr );
                if( $@ )
                {
                    die( "Error evaluating the constant expression '${expr}' (originally '$def->{expression}') in file $units_file: $@" );
                }
            }
            else
            {
                $def->{value} = $def->{expression};
            }
        }
        elsif( index( $def->{expression}, '*' ) != -1 ||
               index( $def->{expression}, '/' ) != -1 )
        {
            local $@;
            $def->{value} = eval( $def->{expression} );
            if( $@ )
            {
                die( "Error evaluating the constant expression '$def->{expression}' in file $units_file: $@" );
            }
        }
        else
        {
            $def->{value} = $def->{expression};
        }
    
        $unit_constants->{ $def->{constant} } = $def->{value};
    
        if( $el->hasAttribute( 'status' ) )
        {
            $def->{status} = $el->getAttribute( 'status' );
        }
        $def->{description} = $el->getAttribute( 'description' );
    
        eval
        {
            $sth->execute( @$def{qw( constant expression value description status )} );
        } || die( "Error adding unit constant information for constant '$def->{constant}' in file $units_file: ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
        $n++;
        $j++;
        $out->print( "ok\n" ) if( $DEBUG );
    }
    &log( "${j} unit constants added." );
    
    # NOTE: Loading unit quantities
    &log( "Loading unit quantities." );
    $j = 0;
    $sth = $sths->{unit_quantities} || die( "No statement object for 'unit_quantities'" );
    while( my $el = $unitsQuantitiesRes->shift )
    {
        my $def =
        {
            base_unit => ( $el->getAttribute( 'baseUnit' ) || die( "Unable to get the unit base unit in the attribute 'baseUnit' for this element in file $units_file: ", $el->toString() ) ),
            quantity => ( $el->getAttribute( 'quantity' ) || die( "Unable to get the unit quantity value in the attribute 'quantity' for this element in file $units_file: ", $el->toString() ) ),
        };
        $out->print( "[$def->{base_unit}] " ) if( $DEBUG );
    
        if( $el->hasAttribute( 'status' ) )
        {
            $def->{status} = $el->getAttribute( 'status' );
        }
        my $this = $el->nextNonBlankSibling;
        if( $this && $this->isa( 'XML::LibXML::Comment' ) )
        {
            $def->{comment} = $this->data;
            $def->{comment} = trim( $def->{comment} ) if( defined( $def->{comment} ) );
            $def->{comment} = undef if( $def->{comment} eq 'null' );
        }
    
        eval
        {
            $sth->execute( @$def{qw( base_unit quantity status comment )} );
        } || die( "Error adding unit quantity information for base unit '$def->{base_unit}' in file $units_file: ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
        $n++;
        $j++;
        $out->print( "ok\n" ) if( $DEBUG );
    }
    &log( "${j} unit quantities added." );
    
    # NOTE: Loading unit conversions
    &log( "Loading unit conversions." );
    $j = 0;
    $sth = $sths->{unit_conversions} || die( "No statement object for 'unit_conversions'" );
    my $units_constants_re = join( '|', reverse( sort( keys( %$unit_constants ) ) ) );
    my $cat;
    while( my $el = $unitsConvertRes->shift )
    {
        my $def =
        {
            source => ( $el->getAttribute( 'source' ) || die( "Unable to get the unit source in the attribute 'source' for this element in file $units_file: ", $el->toString() ) ),
            base_unit => ( $el->getAttribute( 'baseUnit' ) || die( "Unable to get the base unit value in the attribute 'baseUnit' for this element in file $units_file: ", $el->toString() ) ),
        };
        $out->print( "[$def->{base_unit}] " ) if( $DEBUG );
    
        my $this = $el->previousNonBlankSibling;
        if( $this && $this->isa( 'XML::LibXML::Comment' ) )
        {
            my $temp_cat = trim( $this->data );
            if( defined( $temp_cat ) &&
                $temp_cat =~ /^[a-zA-Z][a-zA-Z]+(?:\-[a-zA-Z][a-zA-Z0-9]+)*$/ )
            {
                $cat = $temp_cat;
            }
        }
        $def->{category} = $cat if( defined( $cat ) );
        $out->print( defined( $cat ) ? "-> ${cat} " : '-> no category ' ) if( $DEBUG );
    
        if( $el->hasAttribute( 'factor' ) )
        {
            my $expr = $def->{expression} = $el->getAttribute( 'factor' ) ||
                die( "Unable to get the unit conversion expression from the attribute 'factor' for this element: ", $el->toString() );
            if( $expr =~ s/($units_constants_re)/$unit_constants->{ $1 }/g )
            {
                local $@;
                $def->{factor} = eval( $expr );
                if( $@ )
                {
                    die( "Error evaluating the constant expression '${expr}' (originally '$def->{expression}') in file $units_file: $@" );
                }
            }
            elsif( index( $def->{expression}, '*' ) != -1 ||
                   index( $def->{expression}, '/' ) != -1 )
            {
                local $@;
                $def->{factor} = eval( $def->{expression} );
                if( $@ )
                {
                    die( "Error evaluating the constant expression '$def->{expression}' in file $units_file: $@" );
                }
            }
        }
    
        $def->{systems} = [split( /[[:blank:]\h]+/, ( $el->getAttribute( 'systems' ) || '' ) )];
    
        eval
        {
            $sth->execute( @$def{qw( source base_unit expression factor )}, to_array( $def->{systems} ), $def->{category} );
        } || die( "Error adding unit conversion information for source '$def->{source}' and base unit '$def->{base_unit}' in file $units_file: ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
        $n++;
        $j++;
        $out->print( "ok\n" ) if( $DEBUG );
    }
    &log( "${j} unit conversions added." );
    
    # NOTE: Loading unit preferences
    &log( "Loading unit preferences." );
    $j = 0;
    $sth = $sths->{unit_prefs} || die( "No statement object for 'unit_prefs'" );
    while( my $el = $unitsPrefsRes->shift )
    {
        my $cat = $el->getAttribute( 'category' ) ||
            die( "Unable to get the unit preferences category from attribute 'category' for this element in file $units_file: ", $el->toString() );
        my $usage = $el->getAttribute( 'usage' ) ||
            die( "Unable to get the unit preferences usage from attribute 'usage' for this element in file $units_file: ", $el->toString() );
        my $prefsRes = $el->findnodes( './unitPreference' ) ||
            die( "Unable to get unit preferences for the category '${cat}' and usage '${usage}' for this element in file $units_file: ", $el->toString() );
        # Example: <unitPreference regions="001" geq="10" skeleton="precision-increment/10">meter</unitPreference>
        while( my $el_pref = $prefsRes->shift )
        {
            my $def =
            {
                unit_id => ( $el_pref->textContent || die( "No content found for this preference element in file $units_file: ", $el_pref->toString() ) ),
                category => $cat,
                usage => $usage,
            };
            $out->print( "[$def->{unit_id}] " ) if( $DEBUG );
            if( $el_pref->hasAttribute( 'geq' ) )
            {
                $def->{geq} = $el_pref->getAttribute( 'geq' );
            }
            if( $el_pref->hasAttribute( 'skeleton' ) )
            {
                $def->{skeleton} = $el_pref->getAttribute( 'skeleton' );
            }
            my $regions = [split( /[[:blank:]\h]+/, ( $el_pref->getAttribute( 'regions' ) || '' ) )];
            foreach my $region ( @$regions )
            {
                $def->{territory} = $region;
                $out->print( "${region} " ) if( $DEBUG );
                eval
                {
                    $sth->bind_param( 1, $def->{unit_id}, SQL_VARCHAR );
                    $sth->bind_param( 2, "$def->{territory}", SQL_VARCHAR );
                    $sth->bind_param( 3, $def->{category}, SQL_VARCHAR );
                    $sth->bind_param( 4, $def->{usage}, SQL_VARCHAR );
                    $sth->bind_param( 5, $def->{geq}, SQL_FLOAT );
                    $sth->bind_param( 6, $def->{skeleton}, SQL_VARCHAR );
                    $sth->execute;
                } || die( "Error adding unit preference information for category '$def->{category}', usage '$def->{usage}', unit ID '$def->{unit_id}' and territory '$def->{territory}' in file $units_file: ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
                $n++;
                $j++;
            }
            $out->print( "ok\n" ) if( $DEBUG );
        }
    }
    &log( "${j} unit conversions added." );
    
    # NOTE: Loading unit aliases
    &log( "Loading unit aliases." );
    $j = 0;
    $sth = $sths->{unit_aliases} || die( "No statement object for 'unit_aliases'" );
    # Example: <unitAlias type="inch-hg" replacement="inch-ofhg" reason="deprecated"/>
    while( my $el = $unitsAliasesRes->shift )
    {
        my $def =
        {
            alias => ( $el->getAttribute( 'type' ) || die( "Unable to get the unit alias in the attribute 'type' for this element in file $units_file: ", $el->toString() ) ),
            target => ( $el->getAttribute( 'replacement' ) || die( "Unable to get the alias replacement value in the attribute 'replacement' for this element in file $units_file: ", $el->toString() ) ),
            reason => ( $el->getAttribute( 'reason' ) || die( "Unable to get the alias replacement reason value in the attribute 'reason' for this element in file $units_file: ", $el->toString() ) ),
        };
        $out->print( "[$def->{alias} -> $def->{target}] " ) if( $DEBUG );
    
        eval
        {
            $sth->execute( @$def{qw( alias target reason )} );
        } || die( "Error adding unit alias information for alias '$def->{alias}' and target '$def->{target}' in file $units_file: ", ( $@ || $sth->errstr ), "\n", dump( $def ) );
        $n++;
        $j++;
        $out->print( "ok\n" ) if( $DEBUG );
    }
    &log( "${j} unit conversions added." );
    
    &log( "${n} units data added." );

    # NOTE: Loading plural rules
    &log( "Loading plural rules." );
    $n = 0;
    $total_locales = 0;
    my $plural_rules_file = $basedir->child( 'supplemental/plurals.xml' );
    my $pluralRulesDoc = load_xml( $plural_rules_file );
    $sth = $sths->{plural_rules} || die( "No SQL statement object for plural_rules" );
    $rules = $pluralRulesDoc->findnodes( '/supplementalData/plurals/pluralRules[@locales]' ) ||
        die( "Unable to find plural ruleset in file $plural_rules_file" );
    if( !$rules->size )
    {
        die( "No rules found in plural rules XML file $plural_rules_file" );
    }
    # Example: <pluralRules locales="am as bn doi fa gu hi kn pcm zu">
    while( my $el = $rules->shift )
    {
        my $locales = $el->getAttribute( 'locales' ) || die( "No attribute 'locales' found for this plural rule in file $plural_rules_file: ", $el->toString() );
        &log( "\tChecking plural rules for locales ${locales}" );
        my $pluralRulesHasAliasRes = $el->findnodes( './alias[@path]' );
        if( $pluralRulesHasAliasRes->size )
        {
            $out->print( "\tPlural rules for locales ${locales} is aliased. Resolving it... " ) if( $DEBUG );
            $el = resolve_alias( $pluralRulesHasAliasRes ) ||
                die( "Plural rules for locales ${locales} is aliased, but the resolved element contains nothing in file ${plural_rules_file}" );
            $out->print( "ok\n" ) if( $DEBUG );
        }

        $locales = [split( /[[:blank:]\h\v]+/, $locales )];
        for( my $i = 0; $i < scalar( @$locales ); $i++ )
        {
            my $locale = $locales->[$i];
            # Should not be needed, but better safe than sorry
            $locale =~ tr/_/-/;
            if( index( $locale, 'root' ) != -1 )
            {
                if( length( $locale ) > 4 )
                {
                    my $loc = Locale::Unicode->new( $locale );
                    $loc->language( 'und' );
                    $locale = $loc->as_string;
                }
                else
                {
                    $locale = 'und';
                }
            }
            $locales->[$i] = $locale;
        }

        # Example: <pluralRule count="one">i = 0 or n = 1 @integer 0, 1 @decimal 0.0~1.0, 0.00~0.04</pluralRule>
        my $pluralRules = $el->findnodes( './pluralRule' );
        if( !$pluralRules->size )
        {
            warn( "Warning only: unable to find child elements 'pluralRules' for locale '", join( ', ', @$locales ), "' for this plural rule set in file ${plural_rules_file}: ", $el->toString() );
        }
        while( my $el_rule = $pluralRules->shift )
        {
            my $def = {};
            $def->{count} = $el_rule->getAttribute( 'count' ) ||
                die( "No attribute 'count' for this plural rule in file $plural_rules_file: ", $el_rule->toString() );
            $def->{rule} = $el_rule->textContent ||
                die( "No value found for this plural rule '$def->{count}' for locales @$locales in file $plural_rules_file: ", $el_rule->toString() );
            
            foreach my $locale ( @$locales )
            {
                $def->{locale} = $locale;
                $def->{aliases} = to_array( [grep{ $_ ne $locale } @$locales] );
                # 3728

                eval
                {
                    $sth->execute( @$def{ qw( locale aliases count rule ) } );
                } || die( "Error adding plural rule '$def->{count}' with rule '$def->{rule}' for locales @$locales in file $plural_rules_file: ", ( $@ || $sth->errstr ), "\nwith SQL query: ", $sth->{Statement}, "\n", dump( $def ) );
                $n++;
            }
            $total_locales += scalar( @$locales );
        }
    }
    &log( "${n} plural rules added for ${total_locales} locales." );

    # NOTE: Loading plural ranges
    &log( "Loading plural ranges." );
    $n = 0;
    $total_locales = 0;
    my $plural_ranges_file = $basedir->child( 'supplemental/pluralRanges.xml' );
    my $pluralRangesDoc = load_xml( $plural_ranges_file );
    $sth = $sths->{plural_ranges} || die( "No SQL statement object for plural_ranges" );
    # Example:
    # <pluralRanges locales="id ja km ko lo ms my th vi yue zh">
    #     <pluralRange start="other" end="other" result="other"/>
    # </pluralRanges>
    $rules = $pluralRangesDoc->findnodes( '/supplementalData/plurals/pluralRanges[@locales]' ) ||
        die( "Unable to find plural range ruleset in file $plural_ranges_file" );
    if( !$rules->size )
    {
        die( "No rules found in plural range rules XML file $plural_ranges_file" );
    }
    while( my $el = $rules->shift )
    {
        my $locales = $el->getAttribute( 'locales' ) || die( "No attribute 'locales' found for this plural range rule: ", $el->toString() );
        &log( "\tChecking plural range rules for locales ${locales}" );
        my $pluralRangeRulesHasAliasRes = $el->findnodes( './alias[@path]' );
        if( $pluralRangeRulesHasAliasRes->size )
        {
            $out->print( "\tPlural rules for locales ${locales} is aliased. Resolving it... " ) if( $DEBUG );
            $el = resolve_alias( $pluralRangeRulesHasAliasRes ) ||
                die( "Plural rules for locales ${locales} is aliased, but the resolved element contains nothing in file ${plural_ranges_file}" );
            $out->print( "ok\n" ) if( $DEBUG );
        }

        $locales = [split( /[[:blank:]\h\v]+/, $locales )];
        for( my $i = 0; $i < scalar( @$locales ); $i++ )
        {
            my $locale = $locales->[$i];
            # Should not be needed, but better safe than sorry
            $locale =~ tr/_/-/;
            if( index( $locale, 'root' ) != -1 )
            {
                if( length( $locale ) > 4 )
                {
                    my $loc = Locale::Unicode->new( $locale );
                    $loc->language( 'und' );
                    $locale = $loc->as_string;
                }
                else
                {
                    $locale = 'und';
                }
            }
            $locales->[$i] = $locale;
        }

        # Example: <pluralRange start="other" end="other" result="other"/>
        my $pluralRanges = $el->findnodes( './pluralRange' );
        if( !$pluralRanges->size )
        {
            warn( "Warning only: unable to find child elements 'pluralRange' for locale '", join( ', ', @$locales ), "' for this plural range rule set in file ${plural_ranges_file}: ", $el->toString() );
        }
        my $map =
        {
            start => 'start',
            end => 'stop',
            result => 'result',
        };
        while( my $el_range = $pluralRanges->shift )
        {
            my $def = {};
            foreach my $t ( sort( keys( %$map ) ) )
            {
                $def->{ $map->{ $t } } = $el_range->getAttribute( $t ) ||
                    die( "No attribute '${t}' for this plural range: ", $el_range->toString() );
            }
            
            foreach my $locale ( @$locales )
            {
                $def->{locale} = $locale;
                $def->{aliases} = to_array( [grep{ $_ ne $locale } @$locales] );
                # 3728

                eval
                {
                    $sth->execute( @$def{ qw( locale aliases start stop result ) } );
                } || die( "Error adding plural range from '$def->{start}' to end '$def->{stop}' for locales @$locales: ", ( $@ || $sth->errstr ), "\nwith SQL query: ", $sth->{Statement}, "\n", dump( $def ) );
                $n++;
            }
            $total_locales += scalar( @$locales );
        }
    }
    &log( "${n} plural ranges added for ${total_locales} locales." );

    
    # NOTE: Apply fixes on missing languages in territories and vice versa
    if( $opts->{apply_patch} )
    {
        &patch_territories_languages;
    }

    if( $opts->{extended_timezones_cities} )
    {
        &extend;
    }
    
    # NOTE: Done !
    $out->print( "Data import into SQLite database ${tmpfile} is complete.\n" ) if( $DEBUG || !$opts->{replace} );
    if( $opts->{replace} )
    {
        $tmpfile->move( $live_db_file, overwrite => 1 ) || die( $tmpfile->error );
    }
    return(1);
}

sub apply_patch
{
    # $file is a Module::Generic::File object
    my( $file ) = @_;
    # $basedir is a Module::Generic::File object and something like /tmp/cldr-common-48/common
    # $patch_dir is a global variable

    # Would provide the path relative to the base directory, which is something like '/tmp/cldr-common-48/common', so the relative path would be something like 'supplemental/supplementalData.xml'
    my $rel_path   = $file->relative( $basedir );
    # Use the relative path derived to make the local path under the 'patches' directories, and change the resulting file extension to 'patch'. 
    my $patch_file = $patch_dir->child( $rel_path )->extension( 'patch' );
    return( $file ) if( !$patch_file->exists );
    $out->print( "Applying patch ${patch_file} to ${file}\n" );
    my $backup = $file->copy( "${file}.bak" ) ||
        die( "Unable to create backup file \"${file}.bak\": ", $file->error );
    my @cmd = ( 'patch', '--silent', $file, $patch_file );
    my( $out, $err );
    # Nothing in STDIN so we use undef
    my $ok = IPC::Run::run( \@cmd, \undef, \$out, \$err );
    unless( $ok )
    {
        # Rollback the backup
        $backup->copy( "$file", { overwrite => 1 } );
        die( "Rolling back. Patch failed for patch $file < $patch_file:\n$err" );
    }
    $out->print( "Applied patch ${patch_file}\n" );
    return( $file );
}

sub extend
{
    &extend_timezones_cities;
}

sub extend_timezones_cities
{
    &log( "Adding extended time zones cities data." );
    my $file = $opts->{extended_timezones_cities};
    if( !$file )
    {
        warn( "No extended time zones cities JSON data file was provided." );
        return(0);
    }
    elsif( !$file->exists )
    {
        warn( "The extended time zones cities JSON data file provided (${$file}) does not exist." );
        return(0);
    }
    elsif( $file->is_empty )
    {
        warn( "The extended time zones cities JSON data file provided (${$file}) is empty." );
        return(0);
    }
    elsif( !$file->can_read )
    {
        warn( "The extended time zones cities JSON data file provided (${$file}) is missing read privilege for user ID $>." );
        return(0);
    }

    my $cities = $file->load_json;
    if( !$cities )
    {
        warn( "Error decoding JSON data: ", $file->error );
        return(0);
    }
    elsif( ref( $cities ) ne 'HASH' )
    {
        warn( "I was expecting the time zones cities extended data JSON file to be an hash reference, but it is not. Please check." );
        return(0);
    }
    &log( "Preparing SQL query to add the time zones cities extended data." );
    # We do not use the column 'alt'
    my $sth = $dbh->prepare( "INSERT OR IGNORE INTO timezones_cities_supplemental (locale, timezone, city) VALUES(?, ?, ?)" );
    if( !$sth )
    {
        warn( "Error preparing SQL query to add the time zones cities extended data: ", $dbh->errstr );
        return(0);
    }
    $dbh->begin_work;
    my $added = 0;
    foreach my $tz ( sort( keys( %$cities ) ) )
    {
        my $def = $cities->{ $tz };
        if( !exists( $def->{locales} ) )
        {
            warn( "The entry for the time zone '${tz}' is missing the property 'locales'. Please check the JSON file format." );
            $dbh->rollback;
            return(0);
        }
        elsif( !defined( $def->{locales} ) )
        {
            warn( "Found a property 'locales' for the time zone '${tz}', but its value is undefined! Please check the JSON file format." );
            $dbh->rollback;
            return(0);
        }
        elsif( ref( $def->{locales} ) ne 'HASH' )
        {
            warn( "The value for the property 'locales' for the time zone '${tz}' is not an hash reference. Please check the JSON file format." );
            $dbh->rollback;
            return(0);
        }
        foreach my $key ( sort( keys( %{$def->{locales}} ) ) )
        {
            ( my $locale = $key ) =~ tr/_/-/;
            if( $locale !~ /^[a-z]{2,3}(?:\-(?:[A-Z]{2}|\d{3}))?$/ )
            {
                warn( "Bad locale '${locale}' found for time zone '${tz}'. Please check the JSON data." );
                $dbh->rollback;
                return(0);
            }
            elsif( !length( $def->{locales}->{ $key } // '' ) )
            {
                warn( "City value is empty for the locale '${locale}' in the time zone '${tz}'. Please check the JSON data." );
                $dbh->rollback;
                return(0);
            }

            local $@;
            # try-catch
            my $rv = eval
            {
                $sth->execute( $locale, $tz, $def->{locales}->{ $key } );
            };
            if( !$rv )
            {
                warn( "An error occurred while trying to add the extended city for locale '${locale}' and for time zone '${tz}' into table 'timezones_cities_supplemental': ", ( $@ || $sth->errstr ) );
                $dbh->rollback;
                return(0);
            }
            $added += $sth->rows;
        }
    }
    $dbh->commit;
    &log( "${added} time zones extended cities added." );
    return(1);
}

sub find_interval_repeating_field
{
    my $ref = shift( @_ );
    my $greatest_diff = $ref->{greatest_diff};
    my $pat = $ref->{pattern};
    $out->print( "Checking string '$pat' with greatest difference '${greatest_diff}'\n" ) if( $DEBUG > 1 );
    # {0} – {1}
    if( $pat =~ /^(?<p1>\{\d\})(?<sep>[^\{]+)(?<p2>\{\d\})$/ )
    {
        return( $+{p1}, $+{sep}, $+{p2} );
    }
    # First, remove the quoted literals from our string so they do not interfer
    my $literals = {};
    my $spaces = [];
    if( index( $pat, "'" ) != -1 )
    {
        $out->print( "Removing quoted literals from pattern: ${pat}\n" ) if( $DEBUG > 1 );
        my $n = 0;
        $pat =~ s{
            (?<!\')(\'(?:[^\']+(?!=\'))\')
        }
        {
            if( !exists( $literals->{ $1 } ) )
            {
                $literals->{ $1 } = ++$n;
            }
            $literals->{ $1 } . '__';
        }gexs;
        $out->print( "Pattern string is now: ${pat}\n" ) if( $DEBUG > 1 );
    }
    $pat =~ s{
        ([[:blank:]\h]+)
    }
    {
        push( @$spaces, $1 );
        ' ';
    }gexs;
    my $len = length( $pat );
    my $matches = {};
    my( $part1, $part2, $sep );
    my $equivalent =
    {
    'L'      => 'M',
    'LL'     => 'MM',
    'LLL'    => 'MMM',
    'LLLL'   => 'MMMM',
    'LLLLL'  => 'MMMMM',
    'LLLLLL' => 'MMMMMM',
    'M'      => 'L',
    'MM'     => 'LL',
    'MMM'    => 'LLL',
    'MMMM'   => 'LLLL',
    'MMMM'   => 'LLLLL',
    'MMMMM'  => 'LLLLLL',
    };
    OUTER: for( my $i = 0; $i < $len; $i++ )
    {
        INNER: for( my $j = 1; $j < ( $len - $i ); $j++ )
        {
            my $check = substr( $pat, $i, $j );
            # next OUTER if( $check =~ /^[[:blank:]\h]$/ );
            next OUTER if( $check =~ /^[^a-zA-Z]$/ );
            $out->print( "\tChecking '${check}' from offset $i to $j on or after offset ", ( $i + length( $check ) ), "\n" ) if( $DEBUG >= 4 );
            my $pos = index( $pat, $check, $i + length( $check ) );
            if( exists( $equivalent->{ $check } ) &&
                $pos == -1 )
            {
                $out->print( "\tFound an equivalent string '", $equivalent->{ $check }, "' for '$check'\n" ) if( $DEBUG > 1 );
                $pos = index( $pat, $equivalent->{ $check }, $i + length( $equivalent->{ $check } ) );
                $check = $equivalent->{ $check } if( $pos != -1 );
            }
            if( $pos != -1 )
            {
                if( $DEBUG >= 4 )
                {
                    $out->print( "\tFound a match for '${check}' at offset ${pos}: '", substr( $pat, $pos, length( $check ) ), "'\n" );
                    $out->print( $pat, "\n" );
                    $out->print( '-' x ( $pos + 1 ), "^\n" );
                }
                $matches->{ substr( $pat, $pos, length( $check ) ) } = [$i, $pos];
            }
        }
    }

    if( !scalar( keys( %$matches ) ) )
    {
        warn( "Failed to find the repeating field in pattern '${pat}'" );
        return;
    }
    # my $best = [sort{ length( $b ) <=> length( $a ) } @matches]->[0];
    # my $best = [sort{ length( $b ) <=> length( $a ) } keys( %$matches )]->[0];
    my @bests = sort{ length( $b ) <=> length( $a ) } keys( %$matches );
    my $max_len = length( $bests[0] );
    my $best;
    if( scalar( @bests ) > 1 && length( $bests[1] ) == $max_len )
    {
        $out->printf( "\tFound %d best candidates, checking which is the real best using the greatest difference field '${greatest_diff}'\n", scalar( @bests ) ) if( $DEBUG > 1 );
        my $found;
        foreach my $this ( @bests )
        {
            if( index( $this, $greatest_diff ) != -1 )
            {
                $found = $this;
                last;
            }
        }
        if( !defined( $found ) )
        {
            die( "Found ", scalar( @bests ), " candidates, but none had the greatest difference field ${greatest_diff}" );
        }
        else
        {
            $best = $found;
        }
    }
    else
    {
        $best = $bests[0];
    }
    $out->print( "\tBest match is '$best'\n" ) if( $DEBUG > 1 );
    my( $start1, $start2 ) = @{$matches->{ $best }};
    if( $DEBUG >= 4 )
    {
        $out->print( "Offset 1: $start1\n" );
        $out->print( $pat, "\n" );
        $out->print( '-' x ( $start1 + 1 ), "^\n" );
        $out->print( "Offset 2: $start2\n" );
        $out->print( $pat, "\n" );
        $out->print( '-' x ( $start2 + 1 ), "^\n" );
    }
    $part1 = substr( $pat, 0, ( $start1 + length( $best ) ) );
    $part2 = substr( $pat, $start2 );
    $sep = substr( $pat, $start1 + length( $best ), ( $start2 - ( $start1 + length( $best ) ) ) );

    if( scalar( @$spaces ) )
    {
        my $c = 0;
        for( $part1, $sep, $part2 )
        {
            s/([[:blank:]\h]+)/$spaces->[$c++]/g;
        }
    }

    if( scalar( keys( %$literals ) ) )
    {
        my $vals = { map{ $literals->{ $_ } => $_ } keys( %$literals ) };
        for( $part1, $part2, $sep )
        {
            s/(\d+)__/$vals->{ $1 }/g;
        }
    }

    $out->print( "\tFirst part is '$part1' and second part is '$part2'\n" ) if( $DEBUG > 1 );
    $out->print( "\tSeparator is: '", $sep, "' (", length( $sep ), " bytes)\n" ) if( $DEBUG > 1 );
    return( $part1, $sep, $part2, $best );
}

sub identity_to_locale
{
    # An XML::LibXML::Node
    my $doc = shift( @_ );
    my $id = $doc->findnodes( '//identity' )->shift || die( "Error getting the identity tag" );
    my $parts = [];
    my $names = [qw( language script territory variant )];
    foreach my $token ( @$names )
    {
        if( my $el = $id->findnodes( "./${token}" )->shift )
        {
            my $val = $el->getAttribute( 'type' ) || die( "Unable to get attribute 'type' for element: ", $el->toString() );
            if( $token eq 'language' &&
                defined( $val ) &&
                length( $val ) &&
                $val eq 'root' )
            {
                $val = 'und';
            }
            elsif( $token eq 'script' )
            {
                $val = ucfirst( lc( $val ) ) if( length( $val // '' ) );
            }
            elsif( $token eq 'territory' )
            {
                $val = uc( $val ) if( length( $val // '' ) );
            }
            elsif( $token eq 'variant' )
            {
                $val = lc( $val ) if( length( $val // '' ) );
            }
            push( @$parts, $val );
        }
    }
    die( "No locale tokens found!" ) if( !scalar( @$parts ) );
    return( join( '-', @$parts ) );
}

sub load_schema
{
    my $schema_file = shift( @_ ) ||
        die( "No schema file provided." );
    my $sql = $schema_file->load_utf8 ||
        die( $schema_file->error );
    my @parts = split( /\n(?=CREATE\s)/, $sql );
    my $tables = [];
    for( my $i = 0; $i < scalar( @parts ); $i++ )
    {
        # $out->print( "Loading part $i\n", $parts[$i], "\n" ) if( $DEBUG );
        if( $parts[$i] =~ /^CREATE[[:blank:]\h]+TABLE[[:blank:]\h]+(\S+)/ )
        {
            push( @$tables, $1 );
        }
        if( !defined( $dbh->do( $parts[$i] ) ) )
        {
            die( "Error loading part $i: ", $dbh->errstr, "\n", $parts[$i] );
        }
    }
    return( $tables );
}

sub load_xml
{
    my $xml_file = shift( @_ );
    # Apply patch to the underlying file, if any.
    &apply_patch( $xml_file );
    my $xml = $xml_file->load_utf8 || die( $xml_file->error );
    my $doc = XML::LibXML->load_xml( string => $xml );
    return( $doc );
}

sub log
{
    if( $DEBUG || defined( $log_fh ) )
    {
        my $txt = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : ( $_ // '' ), @_ ) );
        $out->print( $txt, "\n" ) if( $DEBUG );
        $log_fh->print( $txt, "\n" ) if( defined( $log_fh ) );
    }
}

sub patch_only
{
    &patch_territories_languages;
}

sub patch_territories_languages
{
    &log( "Apply fixes on missing languages in territories and vice versa." );
    my $get_territories_sth = $dbh->prepare_cached( "SELECT * FROM territories" ) ||
        die( "Error preparing statement to get all territories information: ", $dbh->error );
    my $get_languages_sth = $dbh->prepare_cached( "SELECT * FROM languages" ) ||
        die( "Error preparing statement to get all languages information: ", $dbh->error );
    $get_territories_sth->execute || die( "Error executing SQL query to get all territories: ", $get_territories_sth->errstr );
    my $territories = $get_territories_sth->fetchall_arrayref({});
    $get_territories_sth->finish;
    $get_languages_sth->execute || die( "Error executing SQL query to get all languages: ", $get_languages_sth->errstr );
    my $langs_ref = $get_languages_sth->fetchall_arrayref({});
    $get_languages_sth->finish;
    local $@;
    $out->print( "\tDecoding territory languages array.\n" );
    foreach my $ref ( @$territories )
    {
        next if( !defined( $ref->{languages} ) );
        my $array = eval
        {
            $json->decode( $ref->{languages} );
        } || die( "Error decoding SQL array: $@" );
        $ref->{languages} = $array;
    }
    $out->print( "\tDecoding territory languages array.\n" );
    foreach my $ref ( @$langs_ref )
    {
        next if( !defined( $ref->{territories} ) );
        my $array = eval
        {
            $json->decode( $ref->{territories} );
        } || die( "Error decoding SQL array: $@" );
        $ref->{territories} = $array;
    }
    $out->printf( "%d territories and %d languages found.\n", scalar( @$territories ), scalar( @$langs_ref ) ) if( $DEBUG );
    my $missing_territory_in_languages = {};
    my $missing_language_in_territories = {};
    my $lang2territory = {};
    my $territory2langs = {};
    foreach my $ref ( @$territories )
    {
        $out->print( "\tChecking territory $ref->{territory}\n" ) if( $DEBUG );
        if( defined( $ref->{languages} ) )
        {
            $territory2langs->{ $ref->{territory} } = $ref->{languages};
            foreach my $lang ( @{$ref->{languages}} )
            {
                $lang2territory->{ $lang } ||= [];
                push( @{$lang2territory->{ $lang }}, $ref->{territory} );
            }
        }
    }
    $out->print( "\tDone building the language to territory map.\n" ) if( $DEBUG );
    
    $out->print( "\tChecking languages territory value now.\n" ) if( $DEBUG );
    
    my $langs = {};
    $out->print( "Pre-processing languages.\n" ) if( $DEBUG );
    foreach my $ref ( @$langs_ref )
    {
        $langs->{ $ref->{language} } ||= [];
        push( @{$langs->{ $ref->{language} }}, $ref );
    }
    
    foreach my $lang ( sort( keys( %$langs ) ) )
    {
        my $expected_territories = $lang2territory->{ $lang } || [];
        foreach my $ref ( @{$langs->{ $lang }} )
        {
            if( defined( $ref->{territories} ) )
            {
                $out->printf( "Checking %d expected territories for language ${lang}\n", scalar( @$expected_territories ) ) if( $DEBUG );
                my $done = {};
                TERRITORY: for( my $i = 0; $i < scalar( @$expected_territories ); $i++ )
                {
                    foreach my $territory ( @{$ref->{territories}} )
                    {
                        next if( exists( $done->{ $territory } ) );
                        $out->print( "\tCheck '", ( $territory // 'undef' ), "' vs '", ( $expected_territories->[$i] // 'undef' ), "'\n" ) if( $DEBUG );
                        if( lc( $territory ) eq lc( $expected_territories->[$i] ) )
                        {
                            splice( @$expected_territories, $i, 1 );
                            $i--;
                            $done->{ $territory }++;
                            next TERRITORY;
                        }
                    }
                }
        
                foreach my $territory ( @{$ref->{territories}} )
                {
                    my $expected_langs = $territory2langs->{ $territory } || [];
                    if( !scalar( grep( /^$ref->{language}$/i, @$expected_langs ) ) )
                    {
                        $out->print( "\tLanguage $ref->{language} is missing from the territory ${territory} known languages: ", join( ', ', @$expected_langs ), "\n" ) if( $DEBUG );
                        $missing_language_in_territories->{ $territory } ||= [];
                        push( @{$missing_language_in_territories->{ $territory }}, $ref->{language} );
                    }
                }
            }
#             elsif( scalar( @$expected_territories ) )
#             {
#                 $out->print( "\tLanguage ${lang} with ", scalar( @{$langs->{ $lang }} ), " set(s) of scripts, has no territory defined, but its expected territories are: ", join( ', ', @$expected_territories ), "\n" ) if( $DEBUG );
#                 $missing_territory_in_languages->{ $ref->{language} } = $expected_territories;
#             }
        }
    
        if( scalar( @$expected_territories ) )
        {
            $out->print( "\tExpected territories missing from language ${lang}: ", join( ', ', @$expected_territories ), "\n" ) if( $DEBUG );
            $missing_territory_in_languages->{ $lang } = $expected_territories;
        }
    }
    
    foreach my $territory ( keys( %$missing_language_in_territories ) )
    {
        @{$missing_language_in_territories->{ $territory }} = uniq( @{$missing_language_in_territories->{ $territory }} );
    }
    
    if( scalar( keys( %$missing_territory_in_languages ) ) ||
        scalar( keys( %$missing_language_in_territories ) ) )
    {
        $out->printf( "%d missing languages in territory definition and %d missing territories in languages definition.\n", scalar( keys( %$missing_language_in_territories ) ), scalar( keys( %$missing_territory_in_languages ) ) ) if( $DEBUG );
        my $json_file = file( $0 )->parent->child( 'fix_territories_languages.json' );
        $json_file->unload_json({
            missing_territories => $missing_territory_in_languages,
            missing_languages => $missing_language_in_territories,
        }, pretty => 1, canonical => 1 ) || die( $json_file->error );
        $out->print( "Errors saved in JSON file $json_file\n" ) if( $DEBUG );
        my $update_territory_sth = $dbh->prepare_cached( "UPDATE territories SET languages = ? WHERE territory = ?" ) ||
            die( "Error preparing SQL query to update territory languages: ", $dbh->errstr );
        my $update_languages_sth = $dbh->prepare_cached( "UPDATE languages SET territories = ? WHERE language_id = ?" ) ||
            die( "Error preparing SQL query to update languages territories: ", $dbh->errstr );
        $out->printf( "Updating %d territories languages.\n", scalar( keys( %$missing_language_in_territories ) ) ) if( $DEBUG );
        foreach my $territory ( sort( keys( %$missing_language_in_territories ) ) )
        {
            my $missing_langs = $missing_language_in_territories->{ $territory };
            my $terr_langs = [@{$territory2langs->{ $territory }}, @$missing_langs];
            $out->printf( "\t[${territory}] '%s' -> '%s'\n", join( "', '", @{$territory2langs->{ $territory }} ), join( "', '", @$terr_langs ) ) if( $DEBUG );
            $update_territory_sth->execute( to_array( $terr_langs ), $territory ) ||
                die( "Error updating the languages array for territory '${territory}': ", $update_territory_sth->errstr );
        }
        $out->printf( "Updating %d languages territories.\n", scalar( keys( %$missing_territory_in_languages ) ) ) if( $DEBUG );
        foreach my $lang ( sort( keys( %$missing_territory_in_languages ) ) )
        {
            my $missing_territories = $missing_territory_in_languages->{ $lang };
            my $current_territories = [];
            my $lang_id;
            if( scalar( @{$langs->{ $lang }} ) == 1 )
            {
                $current_territories = $langs->{ $lang }->[0]->{territories} if( ref( $langs->{ $lang }->[0]->{territories} // '' ) );
                $lang_id = $langs->{ $lang }->[0]->{language_id};
            }
            else
            {
                foreach my $ref ( @{$langs->{ $lang }} )
                {
                    # We want to update the primary language, i.e. the one that has no 'alt' field value set.
                    # There is always a language with no 'alt' value set
                    if( !length( $ref->{alt} // '' ) )
                    {
                        $current_territories = $ref->{territories} if( ref( $ref->{territories} // '' ) );
                        $lang_id = $ref->{language_id};
                        last;
                    }
                }
            }
            $out->print( "\tPatching missing territories for language '${lang}' with id ${lang_id}: ", join( ', ', @$missing_territories ), "\n" );
            my $lang_territories = [@$current_territories, @$missing_territories];
            $out->printf( "\t[${lang}] '%s' -> '%s'\n", join( "', '", @$current_territories ), join( "', '", @$lang_territories ) ) if( $DEBUG );
            $update_languages_sth->execute( to_array( $lang_territories ), $lang_id ) ||
                die( "Error updating the territories array for language '${lang}': ", $update_territory_sth->errstr );
        }
        $update_territory_sth->finish;
        $update_languages_sth->finish;
    }
    else
    {
        $out->print( "No error found.\n" ) if( $DEBUG );
    }
}

sub process_lang_match_territory
{
    my $re = shift( @_ );
    if( $re->{var_name} )
    {
        if( exists( $lang_vars->{ $re->{var_name} } ) )
        {
            my $vals = join( '|', @{$lang_vars->{ $re->{var_name} }} );
            if( $re->{var_negative} )
            {
                return( "(?<territory>(?!$vals)[a-zA-Z0-9]+)" );
            }
            else
            {
                return( "(?<territory>$vals)" );
            }
        }
        else
        {
            die( "No variable $re->{var_name} defined." );
        }
    }
    else
    {
        die( "No variable name provided: ", dump( $re ) );
    }
}

sub resolve_alias
{
    my $resultSet = shift( @_ );
    my $el_alias = $resultSet->shift;
    my $xpath = $el_alias->getAttribute( 'path' ) ||
        die( "The alias element has no 'path' attribute: ", $el_alias->toString() );
    $out->print( "Resolving xpath ${xpath}\n" ) if( $DEBUG );
    my $el_parent = $el_alias->parentNode ||
        die( "The alias node provided has no parent: ", $el_alias->toString );
    my $aliasResolutionRes = $el_parent->findnodes( $xpath );
    if( !$aliasResolutionRes->size )
    {
        warn( "Element points to ${xpath}, but the attempted resolution points to nowhere." );
        return;
    }
    my $el_resolved = $aliasResolutionRes->shift;
    if( !$el_resolved )
    {
        warn( "Resolved alias for xpath ${xpath} resulted in no element found.\n" );
        return;
    }
    # "Aliases must be resolved recursively."
    # <https://www.unicode.org/reports/tr35/#Alias_Elements>
    # Maybe the resolved alias itself is aliased?
    # For example main/root.xml/ldml/dates/fields
    # week-narrow -> week-short -> week
    my $aliasHasAliasRes = $el_resolved->findnodes( './alias[@path]' );
    if( $aliasHasAliasRes->size )
    {
        warn( "The resolved alias with xpath '${xpath}' points to another alias (", $aliasHasAliasRes->get_node(1)->getAttribute( 'path' ), "), following it." );
        return( resolve_alias( $aliasHasAliasRes ) );
    }
    return( $el_resolved );
}

sub to_array
{
    my $ref = shift( @_ );
    if( defined( $ref ) &&
        ref( $ref ) ne 'ARRAY' )
    {
        die( "Value provided (", overload::StrVal( $ref ), ") is not an array." );
    }
    elsif( !defined( $ref ) )
    {
        return( undef );
    }
    elsif( !scalar( @$ref ) )
    {
        return( undef );
    }
    else
    {
        # return( '{' . join( ', ', map( ( looks_like_number( $_ ) ? $_ : q{"} . $_ . q{"} ), @$ref ) ) . '}' );
        # return( '[' . join( ', ', map( ( q{"} . $_ . q{"} ), @$ref ) ) . ']' );
        my $encoded = eval{
            $json->encode( $ref );
        } || die( "Unable to encode array to JSON for array values @$ref: $@" );
        return( $encoded );
    }
}

sub trim
{
    my $str = shift( @_ );
    return( $str ) if( !defined( $str ) || !length( $str ) );
    $str =~ s/^[[:blank:]\h\v]+|[[:blank:]\h\v]+$//gs;
    return( $str );
}

sub _cleanup_and_exit
{
    my $exit = shift( @_ );
    $exit = 0 if( !length( $exit // '' ) || $exit !~ /^\d+$/ );
    exit($exit);
}

# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

create_database.pl - Build CLDR SQLite Database

=head1 SYNOPSIS

    # From https://github.com/unicode-org/cldr
    # Or, from https://cldr.unicode.org/index/downloads
    # download the archive, and open it, and point this script to its directory
    create_database.pl /some/where/cldr-common-45.0
    create_database.pl --debug 4 /some/where/cldr-common-45.0
    create_database.pl --debug 4 \
        --maintainer John Doe \
        --replace \
        --extended-timezones-cities /some/where/timezones_supplemental_cities.json \
        --db-file /some/where/db.sqlite3 \
        --created 2024-07-01 /some/where/cldr-common-45.0
    create_database.pl --noapply-patch /some/where/cldr-common-45.0
    create_database.pl --debug 4 \
        --extend \
        --extended-timezones-cities /some/where/timezones_supplemental_cities.json \
        --db-file /some/where/db.sqlite3 \

Get help:

    create_database.pl --help

Access this documentation:

    create_database.pl --man

or:

    perldoc create_database.pl

Beware, the output on STDOUT is quite verbose, so you may want to do instead:

    create_database.pl /some/where/cldr-common-45.0 >/tmp/cldr_debug.log 2>/tmp/cldr_debug.err

=head1 DESCRIPTION

This script build the SQLite database into a database file by reading from the C<CLDR> (Common Locale Data Repository) repository and collecting all data and storing them into various SQL tables as documented in L<Locale::Unicode::Data>

It requires the following files from IANA zones database: C<zone1970.tab> and C<backward>, which you need to place in the C<scripts> directory before running this script.

This script is unforgiving by nature, which means it has hard expectations about the types of data it expects, and will die if those expectations are not met. If this happens, it most likely means something has changed in the C<CLDR> data, and this script, and possibly the module L<Locale::Unicode::Data>, need to be adjusted accordingly.

Please note that building the database can take some time depending on your computer CPU. However, you should not have to build it, since one is already shipped with this distribution.

Once the SQLite database has been built, you should move it to C<./lib/Locale/Unicode/unicode_cldr.sqlite3> where L<Locale::Unicode::Data> expects to find it.

Then, you can install the distribution, as usual:

    perl Makefile.PL
    make
    make test
    make install

=head1 OPTIONS

=head2 --apply-patch

Boolean value whether to apply known corrections to the CLDR data or not.

Right now, this includes a few fixes for calendar interval formats, and missing languages in territories data and missing territories in languages data.

=head2 --cldr-version

The C<CLDR> version number. If not provided, this will be derived from the data directory name.

=head2 --created

The SQLite database creation date, for example C<2017-11-10>

This defaults to the current datetime

=head2 --db-file

The file path to the SQLite database that will be created.

This defaults to a system temporary location. You will need to move it to its final location once done, unless you have enabled the option C<--replace>

If the option C<--replace> is not enabled, this script will tell you the location of the temporary SQLite database, so you can move it yourself.

=head2 --debug

    create_database.pl --debug 1

Enable debug mode with considerable verbosity using an integer. Above 4, the debugging output is more extensive.

=head2 --nodebug

Disable debug mode.

=head2 --extend

Extends the existing SQLite database by adding the time zones extended cities data, and then quits.

This command requires that the option C<--extended-timezones-cities> be also provided.

=head2 --extended-timezones-cities

Path to a JSON-formatted file containing extended data for time zones cities.

By default, the Unicode CLDR data provide very few time zone cities that are used with the C<v> or C<V> format pattern characters. Using this option, you can tell this script to load those data onto the table C<timezones_cities_supplemental>, and those data will automatically be made available from the SQL view C<timezones_cities_extended>, which is built as a union between the original table C<timezones_cities> and the supplemental data in table C<timezones_cities_supplemental>

The format of the JSON data must be as follows:

    {
       "Asia/Tokyo" : {
          "locales" : {
             "ar" : "طوكيو",
             "az" : "Tokio",
             "be" : "Токіо",
             "bg" : "Токио",
             "bn" : "টোকিও",
             # etc...
          }
        }
    }

You can get a list of all known time zones with the method L<timezones_cities|Locale::Unicode::Data/timezones_cities>

=head2 --help, -h, -?

Print a short help message.

=head2 --log-file

File path to a log file to write to. Defaults to C<create_database.log> in the same directory as this script.

This is only used if the option C<--use-log> is enabled.

=head2 --maintainer

    create_database.pl --maintainer John Doe

=head2 --man

Print this help as man page.

=head2 --replace

Boolean whether to move the temporary SQLite database built to its location in the module lib directory at C<lib/Locale/Unicode/unicode_cldr.sqlite3>

Defaults to false.

By default, it will show the file path of the temporary SQLite database file.

=head2 --use-log

Boolean whether to write verbose output to a log file.

This is automatically enabled if debugging is enabled. See option C<--debug>

=head2 -v

Show version number and exits.

=head2 --verbose

Enable verbose mode.

Actually, this has no effect.

=head2 --noverbose

Disable verbose mode.

Actually, this has no effect.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2024 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
