##----------------------------------------------------------------------------
## Unicode Locale Identifier - ~/lib/Locale/Unicode/Data.pm
## Version v1.4.0
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2024/06/15
## Modified 2025/03/21
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Locale::Unicode::Data;
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use warnings::register;
    use vars qw(
        $ERROR $VERSION $DEBUG $FATAL_EXCEPTIONS
        $CLDR_VERSION $DB_FILE $DBH $STHS
    );
    use version;
    use Exporter ();
    use DBD::SQLite;
    use DBI qw( :sql_types );
    use Encode ();
    use File::Spec;
    use JSON;
    use Locale::Unicode v0.3.5;
    use Scalar::Util ();
    use Want;
    use constant {
        HAS_CONSTANTS => ( version->parse( $DBD::SQLite::VERSION ) >= 1.48 ? 1 : 0 ),
        MISSING_AUTO_UTF8_DECODING => ( version->parse( $DBD::SQLite::VERSION ) < 1.68 ? 1 : 0 ),
    };
    our $CLDR_VERSION = '47.0';
    our $DBH = {};
    our $STHS = {};
    our $VERSION = 'v1.4.0';
};

use strict;
use warnings;

{
    my( $vol, $parent, $file ) = File::Spec->splitpath(__FILE__);
    $DB_FILE = File::Spec->catpath( $vol, $parent, 'unicode_cldr.sqlite3' );
    unless( File::Spec->file_name_is_absolute( $DB_FILE ) )
    {
        $DB_FILE = File::Spec->rel2abs( $DB_FILE );
    }
}

sub new
{
    my $this = shift( @_ );
    my $self = bless( {} => ( ref( $this ) || $this ) );
    $self->{datafile} = $DB_FILE;
    $self->{decode_sql_arrays} = 1;
    $self->{extend_timezones_cities} = 1;
    $self->{fatal} = ( $FATAL_EXCEPTIONS // 0 );
    my @args = @_;
    if( scalar( @args ) == 1 &&
        defined( $args[0] ) &&
        ref( $args[0] ) eq 'HASH' )
    {
        my $opts = shift( @args );
        @args = %$opts;
    }
    elsif( ( scalar( @args ) % 2 ) )
    {
        return( $self->error( sprintf( "Uneven number of parameters provided (%d). Should receive key => value pairs. Parameters provided are: %s", scalar( @args ), join( ', ', @args ) ) ) );
    }

    for( my $i = 0; $i < scalar( @args ); $i += 2 )
    {
        if( $args[$i] eq 'fatal' )
        {
            $self->{fatal} = $args[$i + 1];
            last;
        }
    }

    # Then, if the user provided with an hash or hash reference of options, we apply them
    for( my $i = 0; $i < scalar( @args ); $i++ )
    {
        my $name = $args[ $i ];
        my $val  = $args[ ++$i ];
        my $meth = $self->can( $name );
        if( !defined( $meth ) )
        {
            return( $self->error( "Unknown method \"${meth}\" provided." ) );
        }
        elsif( !defined( $meth->( $self, $val ) ) )
        {
            if( defined( $val ) && $self->error )
            {
                return( $self->pass_error );
            }
        }
    }

    my $file = $self->{datafile} || return( $self->error( "No SQLite data file set." ) );
    my $dbh = $self->_dbh || return( $self->pass_error );
    $self->{_dbh} = $dbh;

    return( $self );
}

sub alias { return( shift->_fetch_one({
    id          => 'get_alias',
    field       => 'alias',
    table       => 'aliases',
    requires    => [qw( type )],
    has_array   => [qw( replacement )],
}, @_ ) ); }

sub aliases { return( shift->_fetch_all({
    id          => 'aliases',
    table       => 'aliases',
    by          => [qw( type )],
    has_array   => [qw( replacement )],
}, @_ ) ); }

sub annotation { return( shift->_fetch_one({
    id          => 'get_annotation',
    field       => 'annotation',
    table       => 'annotations',
    requires    => [qw( locale )],
    has_array   => [qw( defaults )],
}, @_ ) ); }

sub annotations { return( shift->_fetch_all({
    id          => 'annotations',
    table       => 'annotations',
    by          => [qw( locale )],
    has_array   => [qw( defaults )],
}, @_ ) ); }

sub bcp47_currency { return( shift->_fetch_one({
    id      => 'get_bcp47_currency',
    field   => 'currid',
    table   => 'bcp47_currencies',
}, @_ ) ); }

sub bcp47_currencies { return( shift->_fetch_all({
    id          => 'bcp47_currencies',
    table       => 'bcp47_currencies',
    by          => [qw( code is_obsolete )],
}, @_ ) ); }

sub bcp47_extension { return( shift->_fetch_one({
    id      => 'get_bcp47_extension',
    field   => 'extension',
    table   => 'bcp47_extensions',
}, @_ ) ); }

sub bcp47_extensions { return( shift->_fetch_all({
    id          => 'bcp47_extensions',
    table       => 'bcp47_extensions',
    by          => [qw( extension deprecated )],
}, @_ ) ); }

sub bcp47_timezone { return( shift->_fetch_one({
    id          => 'get_bcp47_timezone',
    field       => 'tzid',
    table       => 'bcp47_timezones',
    has_array   => [qw( alias )],
}, @_ ) ); }

sub bcp47_timezones { return( shift->_fetch_all({
    id          => 'bcp47_timezones',
    table       => 'bcp47_timezones',
    by          => [qw( deprecated )],
    has_array   => [qw( alias )],
}, @_ ) ); }

sub bcp47_value { return( shift->_fetch_one({
    id      => 'get_bcp47_value',
    field   => 'value',
    table   => 'bcp47_values',
}, @_ ) ); }

sub bcp47_values { return( shift->_fetch_all({
    id          => 'bcp47_values',
    table       => 'bcp47_values',
    by          => [qw( category extension )],
}, @_ ) ); }

sub calendar { return( shift->_fetch_one({
    id      => 'get_calendar',
    field   => 'calendar',
    table   => 'calendars',
}, @_ ) ); }

sub calendars { return( shift->_fetch_all({
    id      => 'calendars',
    table   => 'calendars',
    by      => [qw( calendar system inherits )],
}, @_ ) ); }

sub calendar_append_format { return( shift->_fetch_one({
    id          => 'get_calendar_append_format',
    field       => 'format_id',
    table       => 'calendar_append_formats',
    requires    => [qw( locale calendar )],
}, @_ ) ); }

sub calendar_append_formats { return( shift->_fetch_all({
    id          => 'calendar_append_formats',
    table       => 'calendar_append_formats',
    by          => [qw( locale calendar )],
}, @_ ) ); }

sub calendar_available_format { return( shift->_fetch_one({
    id          => 'get_calendar_available_format',
    field       => 'format_id',
    table       => 'calendar_available_formats',
    requires    => [qw( locale calendar count alt )],
    default     => { count => undef, alt => undef },
}, @_ ) ); }

sub calendar_available_formats { return( shift->_fetch_all({
    id          => 'calendar_available_formats',
    table       => 'calendar_available_formats',
    by          => [qw( locale calendar count alt )],
}, @_ ) ); }

sub calendar_cyclic_l10n { return( shift->_fetch_one({
    id          => 'get_calendar_cyclic_l10n',
    field       => 'format_id',
    table       => 'calendar_cyclics_l10n',
    requires    => [qw( locale calendar format_set format_type format_length )],
}, @_ ) ); }

sub calendar_cyclics_l10n { return( shift->_fetch_all({
    id          => 'calendar_cyclics_l10n',
    table       => 'calendar_cyclics_l10n',
    by          => [qw( locale calendar format_set format_type format_length )],
}, @_ ) ); }

sub calendar_datetime_format { return( shift->_fetch_one({
    id          => 'get_calendar_datetime_format',
    field       => 'format_type',
    table       => 'calendar_datetime_formats',
    requires    => [qw( locale calendar format_length )],
}, @_ ) ); }

sub calendar_datetime_formats { return( shift->_fetch_all({
    id          => 'calendar_datetime_formats',
    table       => 'calendar_datetime_formats',
    by          => [qw( locale calendar )],
}, @_ ) ); }

sub calendar_era
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{calendar} || return( $self->error( "No calendar ID was provided." ) );
    if( $opts->{calendar} !~ /^[a-zA-Z]+(?:\-[a-zA-Z]+)*$/ )
    {
        return( $self->error( "Calendar ID provided '$opts->{calendar}' contains illegal characters." ) );
    }
    my $sql_arrays_in = [qw( aliases )];
    my $sth;
    local $@;
    if( $opts->{sequence} )
    {
        if( defined( $opts->{sequence} ) &&
            $opts->{sequence} !~ /^\d+$/ )
        {
            return( $self->error( "The calendar era sequence provided (", ( $opts->{sequence} // 'undef' ), ") does not look like an integer." ) );
        }
        unless( $sth = $self->_get_cached_statement( 'calendar_era_with_sequence' ) )
        {
            my $dbh = $self->_dbh || return( $self->pass_error );
            $sth = eval
            {
                $dbh->prepare( "SELECT * FROM calendar_eras WHERE calendar = ? AND sequence = ?" )
            } || return( $self->error( "Unable to prepare SQL query to retrieve calendar era information for a given calendar and sequence: ", ( $@ || $dbh->errstr ) ) );
            $self->_set_cached_statement( calendar_era_with_sequence => $sth );
        }
        eval
        {
            $sth->execute( @$opts{qw( calendar sequence )} )
        } || return( $self->error( "Error executing SQL query '$sth->{Statement}' to retrieve calendar era information for a given calendar and sequence: ", ( $@ || $sth->errstr ) ) );
    }
    elsif( $opts->{code} )
    {
        if( defined( $opts->{code} ) &&
            $opts->{code} !~ /^[a-zA-Z]+(?:\-[a-zA-Z]+)*$/ )
        {
            return( $self->error( "The calendar era code provided (", ( $opts->{code} // 'undef' ), ") contains illegal characters." ) );
        }
        unless( $sth = $self->_get_cached_statement( 'calendar_era_with_code' ) )
        {
            my $dbh = $self->_dbh || return( $self->pass_error );
            $sth = eval
            {
                $dbh->prepare( "SELECT * FROM calendar_eras WHERE calendar = ? AND code = ?" )
            } || return( $self->error( "Unable to prepare SQL query to retrieve calendar era information for a given calendar and code: ", ( $@ || $dbh->errstr ) ) );
            $self->_set_cached_statement( calendar_era_with_code => $sth );
        }
        eval
        {
            $sth->execute( @$opts{qw( calendar code )} )
        } || return( $self->error( "Error executing SQL query '$sth->{Statement}' to retrieve calendar era information for a given calendar and code: ", ( $@ || $sth->errstr ) ) );
    }
    else
    {
        return( $self->error( "No sequence or code parameter provided to retrieve specific era for calendar $opts->{calendar}" ) );
    }
    my $ref = $sth->fetchrow_hashref;
    $self->_decode_utf8( $ref ) if( MISSING_AUTO_UTF8_DECODING );
    $self->_decode_sql_arrays( $sql_arrays_in, $ref ) if( $self->{decode_sql_arrays} );
    return( $ref );
}

sub calendar_eras
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $sql_arrays_in = [qw( aliases )];
    my $sth;
    local $@;
    if( $opts->{calendar} )
    {
        unless( $sth = $self->_get_cached_statement( 'calendar_eras_with_calendar' ) )
        {
            my $dbh = $self->_dbh || return( $self->pass_error );
            $sth = eval
            {
                $dbh->prepare( "SELECT * FROM calendar_eras WHERE calendar = ?" )
            } || return( $self->error( "Unable to prepare SQL query to retrieve all calendar eras information for a given calendar': ", ( $@ || $dbh->errstr ) ) );
            $self->_set_cached_statement( calendar_eras_with_calendar => $sth );
        }
    }
    else
    {
        unless( $sth = $self->_get_cached_statement( 'calendar_eras' ) )
        {
            my $dbh = $self->_dbh || return( $self->pass_error );
            $sth = eval
            {
                $dbh->prepare( "SELECT * FROM calendar_eras" )
            } || return( $self->error( "Unable to prepare SQL query to retrieve all calendar eras information: ", ( $@ || $dbh->errstr ) ) );
            $self->_set_cached_statement( calendar_eras => $sth );
        }
    }

    eval
    {
        $sth->execute( length( $opts->{calendar} // '' ) ? $opts->{calendar} : () )
    } || return( $self->error( "Error executing SQL query '$sth->{Statement}' to retrieve all calendar eras". ( $opts->{calendar} ? " with calendar '$opts->{calendar}'" : '' ), ": ", ( $@ || $sth->errstr ) ) );
    my $all = $sth->fetchall_arrayref({});
    $self->_decode_utf8( $all ) if( MISSING_AUTO_UTF8_DECODING );
    $self->_decode_sql_arrays( $sql_arrays_in, $all ) if( $self->{decode_sql_arrays} );
    return( $all );
}

sub calendar_era_l10n { return( shift->_fetch_one({
    id          => 'get_calendar_era_l10n',
    field       => 'era_id',
    table       => 'calendar_eras_l10n',
    requires    => [qw( locale calendar era_width alt )],
    default     => { alt => undef },
}, @_ ) ); }

sub calendar_eras_l10n { return( shift->_fetch_all({
    id          => 'calendar_eras_l10n',
    table       => 'calendar_eras_l10n',
    by          => [qw( locale calendar era_width alt )],
    order       => 'era_id',
}, @_ ) ); }

sub calendar_format_l10n { return( shift->_fetch_one({
    id          => 'get_calendar_format_l10n',
    field       => 'format_length',
    table       => 'calendar_formats_l10n',
    requires    => [qw( locale calendar format_type )],
}, @_ ) ); }

sub calendar_formats_l10n { return( shift->_fetch_all({
    id          => 'calendar_formats_l10n',
    table       => 'calendar_formats_l10n',
    by          => [qw( locale calendar format_type format_length alt )],
}, @_ ) ); }

sub calendar_interval_format { return( shift->_fetch_one({
    id          => 'get_calendar_interval_format',
    field       => 'format_id',
    table       => 'calendar_interval_formats',
    requires    => [qw( locale calendar greatest_diff_id alt )],
    default     => { alt => undef },
}, @_ ) ); }

sub calendar_interval_formats { return( shift->_fetch_all({
    id          => 'calendar_interval_formats',
    table       => 'calendar_interval_formats',
    by          => [qw( locale calendar greatest_diff_id alt )],
}, @_ ) ); }

sub calendar_l10n { return( shift->_fetch_one({
    id          => 'get_calendar_l10n',
    field       => 'calendar',
    table       => 'calendars_l10n',
    requires    => [qw( locale )],
    default     => { count => undef },
}, @_ ) ); }

sub calendars_l10n { return( shift->_fetch_all({
    id          => 'calendars_l10n',
    table       => 'calendars_l10n',
    by          => [qw( locale )],
}, @_ ) ); }

sub calendar_term { return( shift->_fetch_one({
    # id          => 'get_calendar_term',
    field       => 'term_name',
    table       => 'calendar_terms',
    requires    => [qw( locale calendar term_context term_width alt yeartype )],
    default     => { alt => undef, yeartype => undef },
}, @_ ) ); }

# NOTE: no calendar_term() method, because filtering would return more than one element
sub calendar_terms { return( shift->_fetch_all({
    id      => 'calendars',
    table   => 'calendar_terms',
    by      => [qw( locale calendar term_type term_context term_width alt yeartype )],
}, @_ ) ); }

sub casing { return( shift->_fetch_one({
    id          => 'get_casing',
    field       => 'token',
    table       => 'casings',
    requires    => [qw( locale )],
}, @_ ) ); }

sub casings { return( shift->_fetch_all({
    id      => 'casings',
    table   => 'casings',
    by      => [qw( locale )],
}, @_ ) ); }

sub cldr_built { return( shift->_get_metadata( 'built_on' ) ); }

sub cldr_maintainer { return( shift->_get_metadata( 'maintainer' ) ); }

sub cldr_version { return( shift->_get_metadata( 'cldr_version' ) ); }

sub code_mapping { return( shift->_fetch_one({
    id      => 'get_code_mapping',
    field   => 'code',
    table   => 'code_mappings',
}, @_ ) ); }

sub code_mappings { return( shift->_fetch_all({
    id          => 'code_mappings',
    table       => 'code_mappings',
    by          => [qw( alpha3 numeric fips10 type )],
}, @_ ) ); }

sub collation { return( shift->_fetch_one({
    id      => 'get_collation',
    field   => 'collation',
    table   => 'collations',
}, @_ ) ); }

sub collations { return( shift->_fetch_all({
    id          => 'collations',
    table       => 'collations',
    by          => [qw( collation description )],
    # Important, because this is a view, and without explicitly defining the ordering field, it would fall back to rowid, which does not exist in view and would result in a fatal exception.
    order       => 'collation',
}, @_ ) ); }

sub collation_l10n { return( shift->_fetch_one({
    id          => 'get_collation_l10n',
    field       => 'collation',
    table       => 'collations_l10n',
    requires    => [qw( locale )],
}, @_ ) ); }

sub collations_l10n { return( shift->_fetch_all({
    id          => 'collations_l10n',
    table       => 'collations_l10n',
    by          => [qw( locale collation locale_name )],
}, @_ ) ); }

sub currency { return( shift->_fetch_one({
    id      => 'get_currency',
    field   => 'currency',
    table   => 'currencies',
}, @_ ) ); }

sub currencies { return( shift->_fetch_all({
    id          => 'currencies',
    table       => 'currencies',
    by          => [qw( is_obsolete )],
    has_status  => 1,
}, @_ ) ); }

sub currency_info { return( shift->_fetch_one({
    id          => 'get_currency_info',
    field       => 'currency',
    table       => 'currencies_info',
    requires    => [qw( territory )],
}, @_ ) ); }

sub currencies_info { return( shift->_fetch_all({
    id          => 'currencies',
    table       => 'currencies_info',
    by          => [qw( territory currency )],
}, @_ ) ); }

sub currency_l10n { return( shift->_fetch_one({
    id          => 'get_currency_l10n',
    field       => 'currency',
    table       => 'currencies_l10n',
    requires    => [qw( locale count )],
    default     => { count => undef },
}, @_ ) ); }

sub currencies_l10n { return( shift->_fetch_all({
    id          => 'currencies_l10n',
    table       => 'currencies_l10n',
    by          => [qw( locale currency count )],
}, @_ ) ); }

sub database_handler { return( Scalar::Util::blessed( $_[0] ) ? shift->{_dbh} : undef ); }

sub datafile { return( shift->_set_get_prop( 'datafile', @_ ) ); }

sub date_field_l10n { return( shift->_fetch_one({
    id          => 'get_date_field_l10n',
    field       => 'relative',
    table       => 'date_fields_l10n',
    requires    => [qw( locale field_type field_length )],
}, @_ ) ); }

sub date_fields_l10n { return( shift->_fetch_all({
    id          => 'date_fields_l10n',
    table       => 'date_fields_l10n',
    by          => [qw( locale field_type field_length )],
}, @_ ) ); }

sub date_term { return( shift->_fetch_one({
    id          => 'get_date_term',
    field       => 'term_type',
    table       => 'date_terms',
    requires    => [qw( locale term_length )],
}, @_ ) ); }

sub date_terms { return( shift->_fetch_all({
    id          => 'date_terms',
    table       => 'date_terms',
    by          => [qw( locale term_type term_length )],
}, @_ ) ); }

sub day_period { return( shift->_fetch_one({
    id          => 'get_day_period',
    field       => 'day_period',
    table       => 'day_periods',
    requires    => [qw( locale )],
}, @_ ) ); }

sub day_periods { return( shift->_fetch_all({
    id          => 'day_periods',
    table       => 'day_periods',
    by          => [qw( locale day_period )],
}, @_ ) ); }

sub decode_sql_arrays { return( shift->_set_get_prop({
    field   => 'decode_sql_arrays',
    type    => 'boolean',
}, @_ ) ); }

sub error
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $msg = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : $_, @_ ) );
        $self->{error} = $ERROR = Locale::Unicode::Data::Exception->new({
            skip_frames => 1,
            message => $msg,
        });
        if( $self->fatal )
        {
            die( $self->{error} );
        }
        else
        {
            warn( $msg ) if( warnings::enabled() );
            rreturn( Locale::Unicode::Data::NullObject->new ) if( Want::want( 'OBJECT' ) );
            return;
        }
    }
    return( ref( $self ) ? $self->{error} : $ERROR );
}

sub extend_timezones_cities { return( shift->_set_get_prop({
    field   => 'extend_timezones_cities',
    type    => 'boolean',
}, @_ ) ); }

sub fatal { return( shift->_set_get_prop( 'fatal', @_ ) ); }

sub interval_formats
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $locale = $opts->{locale} ||
        return( $self->error( "No locale provided to get all the interval formats." ) );
    my $cal_id = $opts->{calendar} ||
        return( $self->error( "No calendar ID provided to get all the interval formats." ) );
    my $all = $self->calendar_interval_formats(
        locale => $locale,
        calendar => $cal_id,
    ) || return( $self->pass_error );
    my $formats = {};
    foreach my $ref ( @$all )
    {
        $formats->{ $ref->{format_id} } ||= [];
        push( @{$formats->{ $ref->{format_id} }}, $ref->{greatest_diff_id} );
    }
    return( $formats );
}

sub l10n
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $type = $opts->{type} || return( $self->error( "No localisation type was provided." ) );
    my $type_to_table =
    {
        annotation => 
            {
                table       => 'annotations',
                field       => 'annotation',
                has_array   => [qw( defaults )],
            },
        calendar_append_format => 
            {
                table       => 'calendar_append_formats',
                field       => 'format_id',
                requires    => [qw( locale calendar )],
            },
        calendar_available_format => 
            {
                table       => 'calendar_available_formats',
                field       => 'format_id',
                requires    => [qw( locale calendar )],
            },
        calendar_cyclic =>
            {
                table       => 'calendar_cyclics_l10n',
                field       => 'format_id',
                requires    => [qw( locale calendar format_set )],
            },
        calendar_era => 
            {
                table       => 'calendar_eras_l10n',
                field       => 'era_id',
                requires    => [qw( locale calendar era_width )],
            },
        calendar_format => 
            {
                table       => 'calendar_formats_l10n',
                field       => 'format_id',
                requires    => [qw( locale calendar )],
            },
        calendar_interval_format => 
            {
                table       => 'calendar_interval_formats',
                field       => 'format_id',
                requires    => [qw( locale calendar )],
            },
        calendar_term => 
            {
                table       => 'calendar_terms',
                field       => 'term_name',
                requires    => [qw( locale calendar )],
            },
        casing => 
            {
                table   => 'casings',
                field   => 'token',
            },
        currency => 
            {
                table   => 'currencies_l10n',
                field   => 'currency',
            },
        date_field => 
            {
                table       => 'date_fields_l10n',
                field       => 'relative',
                requires    => [qw( locale field_type )],
            },
        locale => 
            {
                table   => 'locales_l10n',
                field   => 'locale_id',
            },
        number_format => 
            {
                table       => 'number_formats_l10n',
                field       => 'format_id',
                requires    => [qw( locale number_type )],
            },
        number_symbol => 
            {
                table   => 'number_symbols_l10n',
                field   => 'property',
            },
        script => 
            {
                table   => 'scripts_l10n',
                field   => 'script',
            },
        subdivision => 
            {
                table   => 'subdivisions_l10n',
                field   => 'subdivision',
            },
        territory => 
            {
                table   => 'territories_l10n',
                field   => 'territory',
            },
        unit => 
            {
                table   => 'units_l10n',
                field   => 'unit_id',
            },
        variant => 
            {
                table   => 'variants_l10n',
                field   => 'variant',
            },
    };
    $type_to_table->{era} = $type_to_table->{calendar_era};
    $type_to_table->{available} = $type_to_table->{calendar_available_format};
    $type_to_table->{append} = $type_to_table->{calendar_append_format};
    $type_to_table->{cyclic} = $type_to_table->{calendar_cyclics_l10n};
    $type_to_table->{field} = $type_to_table->{date_field};
    $type_to_table->{interval} = $type_to_table->{calendar_interval_format};
    $type_to_table->{symbol} = $type_to_table->{number_symbol};
    if( !exists( $type_to_table->{ $type } ) )
    {
        return( $self->error( "Unknown localisation type '${type}'" ) );
    }
    my $table = $type_to_table->{ $type }->{table};
    my $field = $type_to_table->{ $type }->{field};
    my $key;
    if( exists( $opts->{key} ) )
    {
        $key = $opts->{key};
    }
    elsif( exists( $opts->{ $field } ) )
    {
        $key = $opts->{ $field };
    }
    return( $self->error( "No localisation key was provided." ) ) if( !defined( $key ) || !length( $key // '' ) );
    my $requires = exists( $type_to_table->{ $type }->{requires} )
        ? $type_to_table->{ $type }->{requires}
        : [qw( locale )];
    foreach( @$requires )
    {
        if( !exists( $opts->{ $_ } ) ||
            !defined( $opts->{ $_ } ) ||
            !length( $opts->{ $_ } // '' ) )
        {
            return( $self->error( "No value provided for argument '$_' to retrieve localised data from table ${table}" ) );
        }
    }
    local $@;
    my $sth;
    my $sth_id = "l10n_${table}" . ( scalar( @$requires ) ? '_' . join( '_', @$requires ) : '' );
    unless( $sth = $self->_get_cached_statement( $sth_id ) )
    {
        my $dbh = $self->_dbh || return( $self->pass_error );
        $sth = eval
        {
            $dbh->prepare( "SELECT * FROM ${table} WHERE ${field} = ?" . ( scalar( @$requires ) ? ' AND ' . join( ' AND ', map( "$_ = ?", @$requires ) ) : '' ) . ' ORDER BY rowid' );
        } || return( $self->error( "Unable to prepare SQL query to retrieve data from the table ${table} with field ${field}: ", ( $@ || $dbh->errstr ) ) );
        $self->_set_cached_statement( $sth_id => $sth );
    }
    eval
    {
        $sth->execute( $key, @$opts{ @$requires } );
    } || return( $self->error( "Error executing SQL statement to retrieve data from the table ${table} with field ${field} and arguments '", join( "', '", @$requires ), "': ", ( $@ || $sth->errstr ), " with SQL query: ", $sth->{Statement} ) );
    my $all = $sth->fetchall_arrayref({});
    $self->_decode_utf8( $all ) if( MISSING_AUTO_UTF8_DECODING );
    if( exists( $type_to_table->{ $type }->{has_array} ) &&
        $self->{decode_sql_arrays} )
    {
        $self->_decode_sql_arrays( $type_to_table->{ $type }->{has_array}, $all );
    }
    return( $all );
}

sub language { return( shift->_fetch_one({
    id          => 'get_language',
    field       => 'language',
    table       => 'languages',
    has_array   => [qw( scripts territories )],
}, @_ ) ); }

sub languages { return( shift->_fetch_all({
    id          => 'languages',
    table       => 'languages',
    by          => [qw( parent alt )],
    has_status  => 1,
    has_array   => [qw( scripts territories )],
}, @_ ) ); }

sub language_population { return( shift->_fetch_one({
    id      => 'get_language_population',
    field   => 'territory',
    table   => 'language_population',
    multi   => 1,
}, @_ ) ); }

sub language_populations { return( shift->_fetch_all({
    id          => 'language_population',
    table       => 'language_population',
    has_status  => 'official_status',
}, @_ ) ); }

sub likely_subtag { return( shift->_fetch_one({
    id      => 'get_likely_subtags',
    field   => 'locale',
    table   => 'likely_subtags',
}, @_ ) ); }

sub likely_subtags { return( shift->_fetch_all({
    id          => 'likely_subtags',
    table       => 'likely_subtags',
}, @_ ) ); }

sub locale { return( shift->_fetch_one({
    id      => 'get_locale',
    field   => 'locale',
    table   => 'locales',
    has_array   => [qw( collations )],
}, @_ ) ); }

sub locales { return( shift->_fetch_all({
    id          => 'locales',
    table       => 'locales',
    has_status  => 1,
    has_array   => [qw( collations )],
}, @_ ) ); }

sub locale_l10n { return( shift->_fetch_one({
    id          => 'get_locale_l10n',
    field       => 'locale_id',
    table       => 'locales_l10n',
    requires    => [qw( locale alt )],
    default     => { alt => undef },
}, @_ ) ); }

sub locales_l10n { return( shift->_fetch_all({
    id          => 'locales_l10n',
    table       => 'locales_l10n',
    by          => [qw( locale locale_id alt )],
}, @_ ) ); }

sub locales_info { return( shift->_fetch_one({
    id          => 'get_locales_info',
    field       => 'property',
    table       => 'locales_info',
    requires    => [qw( locale )],
}, @_ ) ); }

sub locales_infos { return( shift->_fetch_all({
    id          => 'locales_info',
    table       => 'locales_info',
}, @_ ) ); }

sub locale_number_system { return( shift->_fetch_one({
    id          => 'get_locale_number_system',
    field       => 'locale',
    table       => 'locale_number_systems',
    requires    => [qw()],
}, @_ ) ); }

sub locale_number_systems { return( shift->_fetch_all({
    id          => 'locale_number_systems',
    table       => 'locale_number_systems',
    by          => [qw( number_system native traditional finance )],
}, @_ ) ); }

# <https://unicode.org/reports/tr35/tr35.html#Locale_Inheritance>
sub make_inheritance_tree
{
    my $self = shift( @_ );
    my $locale = $self->_locale_object( shift( @_ ) ) ||
        return( $self->pass_error );
    $locale = $self->_locale_object( $locale->clone->base ) ||
        return( $self->pass_error );
    my $tree = ["$locale"];
    my $ref;
    if( ( $ref = $self->locale( locale => $locale ) ) &&
        $ref->{parent} )
    {
        my $tree2 = $self->make_inheritance_tree( $ref->{parent} ) || return( $self->pass_error );
        push( @$tree, @$tree2 );
        return( $tree );
    }

    # The locale has something like en-Latn-US, we need to save in the tree en-US
    if( $locale->territory && ( $locale->script || $locale->variant ) )
    {
        my $clone = $locale->clone;
        $clone->script( undef );
        $clone->variant( undef );
        push( @$tree, "$clone" );
        if( ( $ref = $self->locale( locale => $clone ) ) &&
            $ref->{parent} )
        {
            my $tree2 = $self->make_inheritance_tree( $ref->{parent} ) || return( $self->pass_error );
            push( @$tree, @$tree2 );
            return( $tree );
        }
    }

    # "The default search chain is slighly different for multiple variants. In that case, the inheritance chain covers all combinations of variants, with longest number of variants first, and otherwise in alphabetical order."
    # Check if there are more than one variants, in which case, we add each variation by removing one variant at each iteration
    my $variants = $locale->variants;
    if( scalar( @$variants ) )
    {
        if( scalar( @$variants ) > 1 )
        {
            local $" = '-';
            my $seen = { "@$variants" => 1 };
            # We use permutation to produce all possible combinations
            # Credits: <https://stackoverflow.com/questions/10299961/in-perl-how-can-i-generate-all-possible-combinations-of-a-list>
            my $permute;
            $permute = sub
            {
                my( $list, $n ) = @_;
                return( map( [$_], @$list ) ) if( $n <= 1 );
                my @comb;
                for my $i ( 0 .. $#$list )
                {
                    my @rest = @$list;
                    my $val  = splice( @rest, $i, 1 );
                    push( @comb, [$val, @$_] ) for( $permute->( \@rest, $n - 1 ) );
                }
                return( @comb );
            };

            while( scalar( @$variants ) )
            {
                my @variations = $permute->( $variants, scalar( @$variants ) );
                foreach my $ref ( @variations )
                {
                    if( scalar( keys( %$seen ) ) )
                    {
                        # We skip the default set of variants that have been tested at the start.
                        if( exists( $seen->{ "@$ref" } ) )
                        {
                            delete( $seen->{ "@$ref" } );
                            next;
                        }
                    }
                    $locale->variant( "@$ref" );
                    push( @$tree, "$locale" );
                }
                pop( @$variants );
            }
        }

        $locale->variant( undef );
        push( @$tree, "$locale" );
        if( ( $ref = $self->locale( locale => $locale ) ) &&
            $ref->{parent} )
        {
            my $tree2 = $self->make_inheritance_tree( $ref->{parent} ) || return( $self->pass_error );
            push( @$tree, @$tree2 );
            return( $tree );
        }
    }
    
    if( $locale->territory )
    {
        $locale->territory( undef );
        push( @$tree, "$locale" );
        if( ( $ref = $self->locale( locale => $locale ) ) &&
            $ref->{parent} )
        {
            my $tree2 = $self->make_inheritance_tree( $ref->{parent} ) || return( $self->pass_error );
            push( @$tree, @$tree2 );
            return( $tree );
        }
    }

    if( $locale->script )
    {
        $locale->script( undef );
        push( @$tree, "$locale" );
        if( ( $ref = $self->locale( locale => $locale ) ) &&
            $ref->{parent} )
        {
            my $tree2 = $self->make_inheritance_tree( $ref->{parent} ) || return( $self->pass_error );
            push( @$tree, @$tree2 );
            return( $tree );
        }
    }
    # Make sure our last resort is not the same as our initial value
    # For example: fr -> fr
    if( !scalar( grep( $_ eq $locale, @$tree ) ) )
    {
        push( @$tree, "$locale" );
        if( ( $ref = $self->locale( locale => $locale ) ) &&
            $ref->{parent} )
        {
            my $tree2 = $self->make_inheritance_tree( $ref->{parent} ) || return( $self->pass_error );
            push( @$tree, @$tree2 );
            return( $tree );
        }
    }
    push( @$tree, 'und' ) unless( $tree->[-1] eq 'und' );
    return( $tree );
}

sub metazone { return( shift->_fetch_one({
    id          => 'get_metazone',
    field       => 'metazone',
    table       => 'metazones',
    has_array   => [qw( territories timezones )],
}, @_ ) ); }

sub metazones { return( shift->_fetch_all({
    id          => 'metazones',
    table       => 'metazones',
    by          => [],
    has_array   => [qw( territories timezones )],
}, @_ ) ); }

sub metazone_names { return( shift->_fetch_one({
    id          => 'get_metazone_names',
    field       => 'metazone',
    table       => 'metazones_names',
    requires    => [qw( locale width )],
    default     => { start => undef },
}, @_ ) ); }

sub metazones_names { return( shift->_fetch_all({
    id          => 'metazones_names',
    table       => 'metazones_names',
    by          => [qw( locale metazone width )],
}, @_ ) ); }

# <https://unicode.org/reports/tr35/tr35.html#5.-canonicalizing-syntax>
# <https://unicode.org/reports/tr35/tr35.html#4.-replacement>
sub normalise
{
    my $self = shift( @_ );
    my $orig = shift( @_ );
    my $ref;
    unless( Scalar::Util::blessed( $orig ) &&
            $orig->isa( 'Locale::Unicode' ) )
    {
        my $backup = $orig;
        $orig = Locale::Unicode->new( "$orig" );
        if( !defined( $orig ) )
        {
            if( ( $ref = $self->alias( alias => $backup, type => 'language' ) ) &&
                ref( $ref->{replacement} // '' ) eq 'ARRAY' &&
                scalar( @{$ref->{replacement}} ) )
            {
                my $locale = Locale::Unicode->new( $ref->{replacement}->[0] ) ||
                    return( $self->pass_error( Locale::Unicode->error ) );
                return( $locale );
            }
            else
            {
                return( $self->pass_error( Locale::Unicode->error ) );
            }
        }
    }
    # canonical will create a clone
    # my $locale = $orig->canonical;
    my $locale = $orig;

    # <https://unicode.org/reports/tr35/tr35.html#BCP_47_Language_Tag_Conversion>
    # <https://unicode.org/reports/tr35/tr35.html#2.-alias-elements>
    # <https://unicode.org/reports/tr35/tr35.html#Unicode_Locale_Identifier_BCP_47_to_CLDR>
    if( my $privateuse = $locale->privateuse )
    {
        $locale->private( $privateuse );
        $locale->language3( 'und' );
    }
    elsif( my $grandfathered = $locale->grandfathered )
    {
        if( ( $ref = $self->alias( alias => $grandfathered, type => 'language' ) ) &&
            ref( $ref->{replacement} // '' ) eq 'ARRAY' &&
            scalar( @{$ref->{replacement}} ) )
        {
            my $tmp = Locale::Unicode->new( $ref->{replacement}->[0] );
            $tmp = $tmp->canonical;
            # Ensure the aias value we received is, itself, normalised.
            $tmp = $self->normalise( $tmp ) || return( $self->pass_error );
            $locale->merge( $tmp );
            # Do not overwrite it
            $locale->private( $grandfathered ) unless( $locale->private );
        }
    }
    elsif( !$locale->language_id )
    {
        $locale->language3( 'und' );
    }
    elsif( ( $ref = $self->alias( alias => "$locale", type => 'language' ) ) &&
           ref( $ref->{replacement} // '' ) eq 'ARRAY' &&
           scalar( @{$ref->{replacement}} ) )
    {
        my $repl = $ref->{replacement}->[0];
        while( $ref = $self->alias( alias => $repl, type => 'language' ) &&
               ref( $ref->{replacement} // '' ) eq 'ARRAY' &&
               scalar( @{$ref->{replacement}} ) )
        {
            $repl = $ref->{replacement}->[0];
        }

        my $tmp = Locale::Unicode->new( $repl );
        $locale->base( $tmp->base );
    }
    elsif( ( $ref = $self->alias( alias => $locale->language_extended, type => 'language' ) ) &&
           ref( $ref->{replacement} // '' ) eq 'ARRAY' &&
           scalar( @{$ref->{replacement}} ) )
    {
        my $repl = $ref->{replacement}->[0];
        while( $ref = $self->alias( alias => $repl, type => 'language' ) &&
               ref( $ref->{replacement} // '' ) eq 'ARRAY' &&
               scalar( @{$ref->{replacement}} ) )
        {
            $repl = $ref->{replacement}->[0];
        }
        my $tmp = Locale::Unicode->new( $repl );
        $locale->language_id( undef );
        $locale->extended( undef );
        $locale->merge( $tmp );
    }

    # As per the LDML specifications:
    # "If the field = territory, and the replacement.field has more than one value, then look up the most likely territory for the base language code (and script, if there is one). If that likely territory is in the list of replacements, use it. Otherwise, use the first territory in the list."
    # <https://unicode.org/reports/tr35/tr35.html#territory-exception>
    if( $locale->territory && 
        ( $ref = $self->alias( alias => $locale->territory, type => 'territory' ) ) &&
        ref( $ref->{replacement} // '' ) eq 'ARRAY' &&
        scalar( @{$ref->{replacement}} ) )
    {
        if( scalar( @{$ref->{replacement}} ) > 1 )
        {
            my $tree = $self->make_inheritance_tree( $locale ) ||
                return( $self->pass_error );
            my $likely;
            foreach my $loc ( @$tree )
            {
                $likely = $self->likely_subtag( locale => $loc );
                last if( $likely && $likely->{target} );
            }

            if( defined( $likely ) )
            {
                my $tmp = Locale::Unicode->new( $likely->{target} ) ||
                    return( $self->pass_error( Locale::Unicode->error ) );
                my $cc = $tmp->territory;
                if( !$cc )
                {
                    die( "It seems the Locale::Unicode::Data is corrupted as I could get a likely subtag for ${locale}, but the target '${tmp}' does not seem to contain a territory, which is impossible." ); 
                }
                if( scalar( grep( /^${cc}$/i, @{$ref->{replacement}} ) ) )
                {
                    $locale->territory( $cc );
                }
                else
                {
                    $locale->territory( $ref->{replacement}->[0] );
                }
            }
            else
            {
                $locale->territory( $ref->{replacement}->[0] );
            }
        }
        else
        {
            $locale->territory( $ref->{replacement}->[0] );
        }
    }
    
    if( $locale->variant )
    {
        my $variants = [map{ lc( $_ ) } @{$locale->variants}];
        my $permute;
        $permute = sub
        {
            my( $list, $n ) = @_;
            return( map( [$_], @$list ) ) if( $n <= 1 );
            my @comb;
            for my $i ( 0 .. $#$list )
            {
                my @rest = @$list;
                my $val  = splice( @rest, $i, 1 );
                push( @comb, [$val, @$_] ) for( $permute->( \@rest, $n - 1 ) );
            }
            return( @comb );
        };

        my $seen = {};
        my $found = 0;
        local $" = '-';
        my $len = scalar( @$variants );
        VARIANTS: while( $len > 0 )
        {
            $seen->{ $variants->[0] }++ if( scalar( @$variants ) );
            my @variations = $permute->( $variants, $len );
            foreach my $combo ( @variations )
            {
                if( ( $ref = $self->alias( alias => "und-@$combo", type => 'language' ) ) &&
                    ref( $ref->{replacement} ) eq 'ARRAY' &&
                    scalar( @{$ref->{replacement}} ) )
                {
                    MATCH: for( my $i = 0; $i < scalar( @$combo ); $i++ )
                    {
                        for( my $j = 0; $j < scalar( @$variants ); $j++ )
                        {
                            if( $combo->[$i] eq $variants->[$j] )
                            {
                                splice( @$variants, $j, 1 );
                                next MATCH;
                            }
                        }
                    }
                    # Set the new updated variants
                    if( scalar( @$variants ) )
                    {
                        $locale->variant( "@$variants" );
                    }
                    else
                    {
                        $locale->variant( undef );
                    }
                    my $tmp = Locale::Unicode->new( $ref->{replacement}->[0] );
                    # language ID 'und' is just a dummy one used. However, if it is anything else, we need to keep it.
                    $tmp->language_id( undef ) if( $tmp->language_id eq 'und' );
                    $locale->merge( $tmp );
                    $locale->variant( join( '-', sort( @{$locale->variants} ) ) );
                    $found++;
                    last VARIANTS;
                }
            }
            # pop( @$variants );
            $len--;
        }
        unless( $found )
        {
            foreach my $variant ( @{$locale->variants} )
            {
                next if( exists( $seen->{ $variant } ) );
                if( ( $ref = $self->alias( alias => 'und-' . $variant, type => 'language' ) ) &&
                    ref( $ref->{replacement} ) eq 'ARRAY' &&
                    scalar( @{$ref->{replacement}} ) )
                {
                    my $tmp = Locale::Unicode->new( $ref->{replacement}->[0] );
                    $tmp->language_id( undef );
                    $locale->merge( $tmp );
                    $found++;
                    last;
                }
            }
        }
        unless( $found )
        {
            foreach my $variant ( @{$locale->variants} )
            {
                if( ( $ref = $self->alias( alias => $variant, type => 'variant' ) ) &&
                    ref( $ref->{replacement} ) eq 'ARRAY' &&
                    scalar( @{$ref->{replacement}} ) )
                {
                    $locale->variant( $ref->{replacement}->[0] );
                    $found++;
                    last;
                }
            }
        }
    }

    my $script;
    if( ( $script = $locale->script ) &&
        ( $ref = $self->alias( alias => $script, type => 'script' ) ) &&
        ref( $ref->{replacement} ) eq 'ARRAY' &&
        scalar( @{$ref->{replacement}} ) )
    {
        $locale->script( $ref->{replacement}->[0] );
    }

    return( $locale );
}

{
    no warnings 'once';
    *normalize = \&normalise;
}

sub number_format_l10n { return( shift->_fetch_one({
    id          => 'get_number_format_l10n',
    field       => 'format_id',
    table       => 'number_formats_l10n',
    requires    => [qw( locale number_system number_type format_length format_type alt count )],
    default     => { alt => undef, count => undef },
}, @_ ) ); }

sub number_formats_l10n { return( shift->_fetch_all({
    id          => 'number_formats_l10n',
    table       => 'number_formats_l10n',
    by          => [qw( locale number_system number_type format_length format_type alt count )],
}, @_ ) ); }

sub number_symbol_l10n { return( shift->_fetch_one({
    id          => 'getnumber_symbol_l10n',
    field       => 'property',
    table       => 'number_symbols_l10n',
    requires    => [qw( locale number_system alt )],
    default     => { alt => undef },
}, @_ ) ); }

sub number_symbols_l10n { return( shift->_fetch_all({
    id          => 'number_symbols_l10n',
    table       => 'number_symbols_l10n',
    by          => [qw( locale number_system alt )],
}, @_ ) ); }

sub number_system { return( shift->_fetch_one({
    id          => 'get_number_system',
    field       => 'number_system',
    table       => 'number_systems',
    has_array   => [qw( digits )],
}, @_ ) ); }

sub number_systems { return( shift->_fetch_all({
    id          => 'number_systems',
    table       => 'number_systems',
    has_array   => [qw( digits )],
}, @_ ) ); }

sub number_system_l10n { return( shift->_fetch_one({
    id          => 'getnumber_system_l10n',
    field       => 'number_system',
    table       => 'number_systems_l10n',
    requires    => [qw( locale alt )],
    default     => { alt => undef },
}, @_ ) ); }

sub number_systems_l10n { return( shift->_fetch_all({
    id          => 'number_systems_l10n',
    table       => 'number_systems_l10n',
    by          => [qw( locale number_system alt )],
}, @_ ) ); }

sub pass_error
{
    my $self = shift( @_ );
    my $pack = ref( $self ) || $self;
    my $opts = {};
    my( $err, $class, $code );
    no strict 'refs';
    if( scalar( @_ ) )
    {
        # Either an hash defining a new error and this will be passed along to error(); or
        # an hash with a single property: { class => 'Some::ExceptionClass' }
        if( scalar( @_ ) == 1 && ref( $_[0] ) eq 'HASH' )
        {
            $opts = $_[0];
        }
        else
        {
            if( scalar( @_ ) > 1 && ref( $_[-1] ) eq 'HASH' )
            {
                $opts = pop( @_ );
            }
            $err = $_[0];
        }
    }
    $err = $opts->{error} if( !defined( $err ) && CORE::exists( $opts->{error} ) && defined( $opts->{error} ) && CORE::length( $opts->{error} ) );
    # We set $class only if the hash provided is a one-element hash and not an error-defining hash
    $class = $opts->{class} if( CORE::exists( $opts->{class} ) && defined( $opts->{class} ) && CORE::length( $opts->{class} ) );
    $code  = $opts->{code} if( CORE::exists( $opts->{code} ) && defined( $opts->{code} ) && CORE::length( $opts->{code} ) );
    
    # called with no argument, most likely from the same class to pass on an error 
    # set up earlier by another method; or
    # with an hash containing just one argument class => 'Some::ExceptionClass'
    if( !defined( $err ) && ( !scalar( @_ ) || defined( $class ) ) )
    {
        # $error is a previous erro robject
        my $error = ref( $self ) ? $self->{error} : length( ${ $pack . '::ERROR' } ) ? ${ $pack . '::ERROR' } : undef;
        if( !defined( $error ) )
        {
            warn( "No error object provided and no previous error set either! It seems the previous method call returned a simple undef" );
        }
        else
        {
            $err = ( defined( $class ) ? bless( $error => $class ) : $error );
            $err->code( $code ) if( defined( $code ) );
        }
    }
    elsif( defined( $err ) && 
           Scalar::Util::blessed( $err ) && 
           ( scalar( @_ ) == 1 || 
             ( scalar( @_ ) == 2 && defined( $class ) ) 
           ) )
    {
        $self->{error} = ${ $pack . '::ERROR' } = ( defined( $class ) ? bless( $err => $class ) : $err );
        $self->{error}->code( $code ) if( defined( $code ) && $self->{error}->can( 'code' ) );
        
        if( $self->{fatal} || ( defined( ${"${class}\::FATAL_EXCEPTIONS"} ) && ${"${class}\::FATAL_EXCEPTIONS"} ) )
        {
            die( $self->{error} );
        }
    }
    # If the error provided is not an object, we call error to create one
    else
    {
        return( $self->error( @_ ) );
    }
    
    if( Want::want( 'OBJECT' ) )
    {
        rreturn( Locale::Unicode::Data::NullObject->new );
    }
    return;
}

sub person_name_default { return( shift->_fetch_one({
    id      => 'get_person_name_default',
    field   => 'locale',
    table   => 'person_name_defaults',
}, @_ ) ); }

sub person_name_defaults { return( shift->_fetch_all({
    id          => 'person_name_defaults',
    table       => 'person_name_defaults',
}, @_ ) ); }

# NOTE: plural rules for 222 locales based on the Unicode CDR rules set out in supplemental/plurals.xml
# This is for the method plural_count()
my $plural_rules = 
{
    # 1: other
    # bm bo dz hnj id ig ii in ja jbo jv jw kde kea km ko lkt lo ms my nqo osa root sah ses sg su th to tpi vi wo yo yue zh
    bm => { other => sub { 1 } },
    # The other locales in this group are aliased

    # 2: one, other
    # am as bn doi fa gu hi kn pcm zu
    am => 
    {
        one   => sub { $_[0] == 0 || $_[0] == 1 },
        other => sub { 1 },
    },
    # The other locales in this group are aliased

    # ff hy kab
    ff => 
    {
        one   => sub { $_[0] == 0 || $_[0] == 1 },
        other => sub { 1 },
    },
    # The other locales in this group are aliased

    # ast de en et fi fy gl ia io ji lij nl sc sv sw ur yi
    ast => 
    {
        one   => sub { $_[0] == 1 && int( $_[0] ) == $_[0] },
        other => sub { 1 },
    },
    # The other locales in this group are aliased

    # si (Sinhala):
    si => 
    {
        one   => sub 
        { 
            $_[0] == 0 || 
            $_[0] == 1 || 
            # For decimals where the integer part is 0
            ( int( $_[0] ) == 0 && $_[0] != 0 )
        },
        other => sub { 1 },
    },
    # ak bho csw guw ln mg nso pa ti wa
    ak => 
    {
        one   => sub { $_[0] == 0 || $_[0] == 1 },
        other => sub { 1 },
    },
    # The other locales in this group are aliased

    # tzm
    tzm => 
    {
        one   => sub 
        {
            $_[0] == 0 ||
            $_[0] == 1 ||
            (
                $_[0] >= 11 &&
                $_[0] <= 99 &&
                int( $_[0] ) == $_[0]
            )
        },
        other => sub { 1 },
    },
    # af an asa az bal bem bez bg brx ce cgg chr ckb dv ee el eo eu fo fur gsw ha haw hu jgo jmc ka kaj kcg kk kkj kl ks ksb ku ky lb lg mas mgo ml mn mr nah nb nd ne nn nnh no nr ny nyn om or os pap ps rm rof rwk saq sd sdh seh sn so sq ss ssy st syr ta te teo tig tk tn tr ts ug uz ve vo vun wae xh xog
    af => 
    {
        one   => sub { $_[0] == 1 && int( $_[0] ) == $_[0] },
        other => sub { 1 },
    },
    # The other locales in this group are aliased

    # da
    da => 
    {
        one   => sub 
        {
            $_[0] == 1 ||
            (
                int( $_[0] ) != $_[0] &&
                int( $_[0] ) == 0
            )
        },
        other => sub { 1 },
    },
    # is: Icelandic
    is => 
    {
        one   => sub 
        {
            int( $_[0] ) == $_[0] && 
            (
                (
                    $_[0] % 10 == 1 &&
                    $_[0] % 100 != 11
                )
                || 
                (
                    int( $_[0] * 10 ) % 10 == 1 &&
                    int( $_[0] * 100 ) % 100 != 11
                )
            )
            || 
            # Handling decimals
            (
                int( $_[0] ) != $_[0] &&
                $_[0] < 1.1
            )
        },
        other => sub { 1 },
    },
    # mk: Macedonian
    mk => 
    {
        one   => sub 
        {
            int( $_[0] ) == $_[0] && 
            (
                (
                    $_[0] % 10 == 1 &&
                    $_[0] % 100 != 11
                )
                ||
                (
                    int( $_[0] * 10 ) % 10 == 1 &&
                    int( $_[0] * 100 ) % 100 != 11
                )
            )
            || 
            # Handling decimals
            (
                int( $_[0] ) != $_[0] &&
                $_[0] < 1.1
            )
        },
        other => sub { 1 },
    },
    # ceb fil tl
    ceb => 
    {
        one   => sub 
        {
            int( $_[0] ) == $_[0] &&
            (
                (
                    $_[0] == 1 ||
                    $_[0] == 2 ||
                    $_[0] == 3
                )
                ||
                (
                    $_[0] % 10 != 4 &&
                    $_[0] % 10 != 6 &&
                    $_[0] % 10 != 9
                )
            )
            ||
            (
                int( $_[0] ) != $_[0] &&
                int( $_[0] * 10 ) % 10 != 4 &&
                int( $_[0] * 10 ) % 10 != 6 &&
                int( $_[0] * 10 ) % 10 != 9
            )
        },
        other => sub { 1 },
    },
    # The other locales in this group are aliased

    # 3: zero, one, other
    # lv (Latvian) prg
    lv => 
    {
        zero  => sub
        {
            # Check for very small numbers, including 0 and close to zero
            # Slightly larger threshold to catch 0.01 and 0.001
            abs( $_[0] ) < 0.011
            ||
            # Include integers
            (
                int( $_[0] ) == $_[0] &&
                (
                    $_[0] % 10 == 0 || 
                    (
                        $_[0] % 100 >= 11 &&
                        $_[0] % 100 <= 19
                    )
                )
            )
        },
        one   => sub
        { 
            (
                $_[0] % 10 == 1 &&
                $_[0] % 100 != 11
            )
            ||
            # Handle decimals for 'one', excluding numbers very close to zero
            (
                int( $_[0] ) != $_[0] &&
                # Exclude 0.01 explicitly
                $_[0] > 0.01 &&
                $_[0] < 1.1
            )
        },
        other => sub { 1 },
    },
    # The other locales in this group are aliased

    # lag
    lag => 
    {
        zero  => sub { $_[0] == 0 },
        one   => sub 
        {
            $_[0] == 1 ||
            (
                int( $_[0] ) == 0 &&
                int( $_[0] ) != $_[0]
            )
        },
        other => sub { 1 },
    },
    # blo
    blo => 
    {
        zero  => sub { $_[0] == 0 },
        one   => sub { $_[0] == 1 },
        other => sub { 1 },
    },
    # ksh
    ksh => 
    {
        zero  => sub { $_[0] == 0 },
        one   => sub { $_[0] == 1 },
        other => sub { 1 },
    },

    # 3: one, two, other
    # he iw
    he => 
    {
        one   => sub 
        {
            (
                $_[0] == 1 &&
                int( $_[0] ) == $_[0]
            )
            ||
            (
                int( $_[0] ) != $_[0] &&
                $_[0] > 0 &&
                # Include all non-integers between 0 and 2 for 'one'
                $_[0] < 2
            )
        },
        two   => sub { $_[0] == 2 && int( $_[0] ) == $_[0] },
        other => sub { 1 },
    },
    # The other locales in this group are aliased

    # iu naq sat se sma smi smj smn sms
    iu => 
    {
        one   => sub { $_[0] == 1 && int( $_[0] ) == $_[0] },
        two   => sub { $_[0] == 2 && int( $_[0] ) == $_[0] },
        other => sub { 1 },
    },
    # The other locales in this group are aliased

    # 3: one, few, other
    # shi
    shi => 
    {
        one   => sub { $_[0] == 0 || $_[0] == 1 },
        few   => sub 
        {
            $_[0] >= 2 &&
            $_[0] <= 10 &&
            int( $_[0] ) == $_[0]
        },
        other => sub { 1 },
    },
    # mo ro
    mo => 
    {
        one   => sub { $_[0] == 1 && int( $_[0] ) == $_[0] },
        few   => sub 
        {
            int( $_[0] ) != $_[0] ||
            $_[0] == 0 ||
            (
                $_[0] % 100 >= 1 &&
                $_[0] % 100 <= 19 &&
                $_[0] != 1
            )
        },
        other => sub { 1 },
    },
    # The other locales in this group are aliased

    # bs (Bosnian) hr sh sr
    bs => 
    {
        one   => sub
        {
            (
                int( $_[0] ) == $_[0] && 
                (
                    (
                        $_[0] % 10 == 1 &&
                        $_[0] % 100 != 11
                    )
                    ||
                    (
                        int( $_[0] * 10 ) % 10 == 1 &&
                        int( $_[0] * 100 ) % 100 != 11
                    )
                )
            )
            || 
            # Handle decimals for 'one'
            (
                int( $_[0] ) != $_[0] &&
                $_[0] < 1.1 &&
                $_[0] > 0 &&
                # Exclude numbers like 0.2 from being 'one'
                $_[0] < 0.2
            )
        },
        few   => sub
        {
            (
                int( $_[0] ) == $_[0] && 
                (
                    (
                        $_[0] % 10 >= 2 &&
                        $_[0] % 10 <= 4 &&
                        $_[0] % 100 < 10
                    )
                    ||
                    (
                        $_[0] % 10 >= 2 &&
                        $_[0] % 10 <= 4 &&
                        $_[0] % 100 >= 20
                    )
                    ||
                    (
                        int( $_[0] * 10 ) % 10 >= 2 &&
                        int( $_[0] * 10 ) % 10 <= 4 &&
                        int( $_[0] * 100 ) % 100 < 10
                    )
                    ||
                    (
                        int( $_[0] * 10 ) % 10 >= 2 &&
                        int( $_[0] * 10 ) % 10 <= 4 &&
                        int( $_[0] * 100 ) % 100 >= 20
                    )
                )
            )
            ||
            # Handle decimals for 'few' including numbers like 0.2 but not 1.1
            (
                int( $_[0] ) != $_[0] &&
                (
                    $_[0] >= 0.2 && 
                    $_[0] < 1.2 &&
                    # Exclude 1.1 specifically
                    $_[0] != 1.1
                )
            )
        },
        many  => sub
        {
            int( $_[0] ) == $_[0] && 
            (
                (
                    $_[0] % 10 == 0 ||
                    (
                        $_[0] % 10 >= 5 &&
                        $_[0] % 10 <= 9
                    )
                    ||
                    (
                        $_[0] % 100 >= 11 &&
                        $_[0] % 100 <= 14
                    )
                )
                ||
                (
                    int( $_[0] * 10 ) % 10 == 0 ||
                    (
                        int( $_[0] * 10 ) % 10 >= 5 &&
                        int( $_[0] * 10 ) % 10 <= 9
                    )
                    ||
                    (
                        int( $_[0] * 100 ) % 100 >= 11 &&
                        int( $_[0] * 100 ) % 100 <= 14
                    )
                )
            )
            &&
            # Exclude specific cases that should be 'other'
            !( $_[0] == 11 || $_[0] == 5 )
            &&
            # Exclude decimals that should be 'few'
            !( $_[0] >= 1.1 && $_[0] < 1.5 )
        },
        other => sub { 1 },
    },
    # The other locales in this group are aliased

    # 3: one, many, other
    # fr
    fr => 
    {
        one   => sub { $_[0] == 0 || $_[0] == 1 },
        many  => sub 
        {
            (
                int( $_[0] ) != $_[0] && 
                (
                    # Check if there's a fractional part but exclude exact half-integers like 1.5
                    int( $_[0] * 1000000 ) != int( $_[0] ) * 1000000 &&
                    # Explicitly exclude numbers like 1.5 but allow numbers like 1000000.5
                    !($_[0] - int( $_[0]) == 0.5 && int( $_[0] ) % 1000000 != 0)
                )
            )
            ||
            (
                int( $_[0] ) != 0 &&
                (
                    $_[0] % 1000000 == 0 ||
                    # Handle cases like 1000000.5 where the integer part is divisible by 1,000,000
                    (int( $_[0] ) % 1000000 == 0 && $_[0] != int( $_[0] ))
                ) &&
                int( $_[0] ) == $_[0] &&
                $_[0] > 1
            )
        },
        other => sub { 1 },
    },
    # pt
    pt => 
    {
        one   => sub { $_[0] == 0 || $_[0] == 1 },
        many  => sub 
        {
            int( $_[0] ) != $_[0] ||
            (
                int( $_[0] ) != 0 &&
                $_[0] % 1000000 == 0 &&
                int( $_[0] ) == $_[0]
            )
        },
        other => sub { 1 },
    },
    # ca it lld pt_PT scn vec
    ca => 
    {
        one   => sub { $_[0] == 1 && int( $_[0] ) == $_[0] },
        many  => sub 
        {
            int( $_[0] ) != $_[0] ||
            (
                int( $_[0] ) != 0 &&
                $_[0] % 1000000 == 0 &&
                int( $_[0] ) == $_[0]
            )
        },
        other => sub { 1 },
    },
    # The other locales in this group are aliased

    # es
    es => 
    {
        one   => sub { $_[0] == 1 && int( $_[0] ) == $_[0] },
        many  => sub 
        {
            int( $_[0]) != $_[0] ||
            (
                int( $_[0] ) != 0 &&
                $_[0] % 1000000 == 0 &&
                int( $_[0] ) == $_[0]
            )
        },
        other => sub { 1 },
    },

    # 4: one, two, few, other
    # gd
    gd => 
    {
        one   => sub { $_[0] == 1 || $_[0] == 11 },
        two   => sub { $_[0] == 2 || $_[0] == 12 },
        few   => sub 
        {
            $_[0] >= 3 &&
            (
                $_[0] <= 10 ||
                $_[0] >= 13
            )
            && $_[0] <= 19
        },
        other => sub { 1 },
    },
    # sl
    sl => 
    {
        one   => sub { int( $_[0]) == $_[0] && $_[0] % 100 == 1 },
        two   => sub { int( $_[0]) == $_[0] && $_[0] % 100 == 2 },
        few   => sub 
        {
            int( $_[0] ) == $_[0] &&
            (
                $_[0] % 100 == 3 ||
                $_[0] % 100 == 4
            )
            ||
            int( $_[0] ) != $_[0]
        },
        other => sub { 1 },
    },
    # dsb (Lower Sorbian) hsb
    dsb => 
    {
        one   => sub 
        {
            (
                int( $_[0] ) == $_[0] &&
                (
                    ( $_[0] % 100 == 1 )
                    ||
                    ( int( $_[0] * 10 ) % 100 == 1 )
                )
            )
            ||
            # Handle decimals for 'one'
            (
                int( $_[0] ) != $_[0] &&
                $_[0] > 0 &&
                $_[0] < 1.1
            )
        },
        two   => sub 
        {
            int( $_[0] ) == $_[0] &&
            (
                ( $_[0] % 100 == 2 )
                ||
                ( int( $_[0] * 10 ) % 100 == 2 )
            )
        },
        few   => sub 
        {
            int( $_[0] ) == $_[0] &&
            (
                ( $_[0] % 100 >= 3 && $_[0] % 100 <= 4 )
                ||
                (
                    int( $_[0] * 10 ) % 100 >= 3 &&
                    int( $_[0] * 10 ) % 100 <= 4
                )
            )
        },
        other => sub { 1 },
    },
    # The other locales in this group are aliased

    # 4: one, few, many, other
    # cs sk
    cs => 
    {
        one   => sub { $_[0] == 1 && int( $_[0] ) == $_[0] },
        few   => sub 
        {
            $_[0] >= 2 && 
            $_[0] <= 4 && 
            int( $_[0] ) == $_[0]
        },
        many  => sub { int( $_[0] ) != $_[0] },
        other => sub { 1 },
    },
    # The other locales in this group are aliased

    # pl (Polish)
    pl => 
    {
        one   => sub { $_[0] == 1 && int( $_[0] ) == $_[0] },
        few   => sub 
        {
            int( $_[0] ) == $_[0] &&
            $_[0] % 10 >= 2 &&
            $_[0] % 10 <= 4 &&
            (
                $_[0] % 100 < 10 ||
                $_[0] % 100 >= 20
            )
        },
        many  => sub 
        {
            int( $_[0] ) == $_[0] &&
            (
                $_[0] % 10 == 0 ||
                (
                    $_[0] % 10 >= 5 &&
                    $_[0] % 10 <= 9
                )
                ||
                (
                    $_[0] % 100 >= 11 &&
                    $_[0] % 100 <= 14
                )
            )
            ||
            int( $_[0] ) != $_[0]
        },
        other => sub { 1 },
    },
    # be (Belarusian)
    be => 
    {
        one   => sub 
        {
            int( $_[0] ) == $_[0] &&
            $_[0] % 10 == 1 &&
            $_[0] % 100 != 11
        },
        few   => sub 
        {
            int( $_[0] ) == $_[0] &&
            $_[0] % 10 >= 2 &&
            $_[0] % 10 <= 4 &&
            (
                $_[0] % 100 < 10 ||
                $_[0] % 100 >= 20
            )
        },
        many  => sub 
        {
            int( $_[0] ) == $_[0] &&
            (
                (
                    $_[0] % 10 == 0 ||
                    $_[0] % 10 >= 5
                )
                ||
                (
                    $_[0] % 100 >= 11 &&
                    $_[0] % 100 <= 14
                )
            )
        },
        other => sub { int( $_[0] ) != $_[0] },
    },
    # lt (Lithuanian)
    lt => 
    {
        one   => sub 
        {
            int( $_[0] ) == $_[0] &&
            $_[0] % 10 == 1 &&
            !(
                $_[0] % 100 >= 11 &&
                $_[0] % 100 <= 19
            )
        },
        few   => sub 
        {
            int( $_[0] ) == $_[0] &&
            $_[0] % 10 >= 2 &&
            $_[0] % 10 <= 9 &&
            (
                $_[0] % 100 < 10 ||
                $_[0] % 100 >= 20
            )
        },
        many  => sub { int( $_[0] ) != $_[0] },
        other => sub 
        {
            int( $_[0] ) == $_[0] &&
            (
                $_[0] % 100 >= 11 &&
                (
                    $_[0] % 100 <= 19 ||
                    $_[0] % 10 == 0
                )
            )
        },
    },
    # ru (Russian) uk (Ukrainian)
    ru => 
    {
        one   => sub 
        {
            int( $_[0] ) == $_[0] &&
            $_[0] % 10 == 1 &&
            $_[0] % 100 != 11
        },
        few   => sub 
        {
            int( $_[0] ) == $_[0] &&
            $_[0] % 10 >= 2 &&
            $_[0] % 10 <= 4 &&
            (
                $_[0] % 100 < 10 ||
                $_[0] % 100 >= 20
            )
        },
        many  => sub 
        {
            int( $_[0] ) == $_[0] &&
            (
                (
                    $_[0] % 10 == 0 ||
                    $_[0] % 10 >= 5
                )
                ||
                (
                    $_[0] % 100 >= 11 &&
                    $_[0] % 100 <= 14
                )
            )
        },
        other => sub { int( $_[0] ) != $_[0] },
    },
    # The other locales in this group are aliased

    # 5: one, two, few, many, other
    # br
    br => 
    {
        one   => sub 
        {
            int( $_[0] ) == $_[0] &&
            $_[0] % 10 == 1 &&
            $_[0] % 100 != 11 &&
            $_[0] % 100 != 71 &&
            $_[0] % 100 != 91
        },
        two   => sub 
        {
            int( $_[0] ) == $_[0] &&
            $_[0] % 10 == 2 &&
            $_[0] % 100 != 12 &&
            $_[0] % 100 != 72 &&
            $_[0] % 100 != 92
        },
        few   => sub 
        {
            int( $_[0] ) == $_[0] && 
            (
                (
                    $_[0] % 10 >= 3 &&
                    (
                        $_[0] % 10 <= 4 ||
                        $_[0] % 10 == 9
                    )
                )
                &&
                (
                    $_[0] % 100 < 10 ||
                    $_[0] % 100 > 19
                )
                &&
                (
                    $_[0] % 100 < 70 ||
                    $_[0] % 100 > 79
                )
                &&
                (
                    $_[0] % 100 < 90 ||
                    $_[0] % 100 > 99
                )
            )
        },
        many  => sub 
        {
            int( $_[0] ) == $_[0] &&
            $_[0] != 0 &&
            $_[0] % 1000000 == 0
        },
        other => sub { 1 },
    },
    # mt
    mt => 
    {
        one   => sub { $_[0] == 1 && int( $_[0] ) == $_[0] },
        two   => sub { $_[0] == 2 && int( $_[0] ) == $_[0] },
        few   => sub 
        {
            $_[0] == 0 ||
            (
                int( $_[0] ) == $_[0] &&
                $_[0] % 100 >= 3 &&
                $_[0] % 100 <= 10
            )
        },
        many  => sub 
        {
            int( $_[0] ) == $_[0] &&
            $_[0] % 100 >= 11 &&
            $_[0] % 100 <= 19
        },
        other => sub { 1 },
    },
    # ga
    ga => 
    {
        one   => sub { $_[0] == 1 && int( $_[0] ) == $_[0] },
        two   => sub { $_[0] == 2 && int( $_[0] ) == $_[0] },
        few   => sub 
        {
            $_[0] >= 3 &&
            $_[0] <= 6 &&
            int( $_[0] ) == $_[0]
        },
        many  => sub 
        {
            $_[0] >= 7 &&
            $_[0] <= 10 &&
            int( $_[0] ) == $_[0]
        },
        other => sub { 1 },
    },
    # gv
    gv => 
    {
        one   => sub { int( $_[0] ) == $_[0] && $_[0] % 10 == 1 },
        two   => sub { int( $_[0] ) == $_[0] && $_[0] % 10 == 2 },
        few   => sub 
        {
            int( $_[0] ) == $_[0] &&
            (
                $_[0] % 100 == 0 ||
                $_[0] % 100 == 20 ||
                $_[0] % 100 == 40 ||
                $_[0] % 100 == 60 ||
                $_[0] % 100 == 80
            )
        },
        many  => sub { int( $_[0] ) != $_[0] },
        other => sub { 1 },
    },

    # 6: zero, one, two, few, many, other
    # kw (Cornish)
    kw => 
    {
        zero  => sub { $_[0] == 0 },
        one   => sub { $_[0] == 1 },
        two   => sub 
        {
            int( $_[0] ) == $_[0] &&
            (
                # Directly include 2
                $_[0] == 2
                ||
                # Existing conditions for other cases
                (
                    (
                        $_[0] % 100 == 22 ||
                        $_[0] % 100 == 42 ||
                        $_[0] % 100 == 62 ||
                        $_[0] % 100 == 82
                    )
                    ||
                    (
                        $_[0] % 1000 == 0 &&
                        (
                            $_[0] % 100000 >= 1000 &&
                            $_[0] % 100000 <= 20000
                        )
                    )
                    ||
                    (
                        $_[0] % 100000 == 40000 ||
                        $_[0] % 100000 == 60000 ||
                        $_[0] % 100000 == 80000
                    )
                    ||
                    (
                        $_[0] % 1000000 == 100000 &&
                        $_[0] != 0
                    )
                )
            )
        },
        few   => sub 
        {
            int( $_[0] ) == $_[0] &&
            (
                $_[0] % 100 == 3 ||
                $_[0] % 100 == 23 ||
                $_[0] % 100 == 43 ||
                $_[0] % 100 == 63 ||
                $_[0] % 100 == 83
            )
        },
        many  => sub 
        {
            int( $_[0] ) == $_[0] &&
            $_[0] != 1 &&
            (
                $_[0] % 100 == 1 ||
                $_[0] % 100 == 21 ||
                $_[0] % 100 == 41 ||
                $_[0] % 100 == 61 ||
                $_[0] % 100 == 81
            )
        },
        other => sub { 1 },
    },
    # ar ars
    ar => 
    {
        zero  => sub { $_[0] == 0 },
        one   => sub { $_[0] == 1 },
        two   => sub { $_[0] == 2 },
        few   => sub 
        {
            int( $_[0] ) == $_[0] &&
            $_[0] % 100 >= 3 &&
            $_[0] % 100 <= 10
        },
        many  => sub 
        {
            int( $_[0] ) == $_[0] &&
            $_[0] % 100 >= 11 &&
            $_[0] % 100 <= 99
        },
        other => sub { 1 },
    },
    # The other locales in this group are aliased

    # cy
    cy => 
    {
        zero  => sub { $_[0] == 0 },
        one   => sub { $_[0] == 1 },
        two   => sub { $_[0] == 2 },
        few   => sub { $_[0] == 3 },
        many  => sub { $_[0] == 6 },
        other => sub { 1 },
    },
};

# Aliasing
my $aliases =
{
    # 1: other
    bm => [qw( bo dz hnj id ig ii in ja jbo jv jw kde kea km ko lkt lo ms my nqo osa root sah ses sg su th to tpi vi wo yo yue zh )],
    # 2: one, other
    am => [qw( as bn doi fa gu hi kn pcm zu )],
    ff => [qw( hy kab )],
    ast => [qw( de en et fi fy gl ia io ji lij nl sc sv sw ur yi )],
    ak => [qw( bho csw guw ln mg nso pa ti wa )],
    af => [qw( an asa az bal bem bez bg brx ce cgg chr ckb dv ee el eo eu fo fur gsw ha haw hu jgo jmc ka kaj kcg kk kkj kl ks ksb ku ky lb lg mas mgo ml mn mr nah nb nd ne nn nnh no nr ny nyn om or os pap ps rm rof rwk saq sd sdh seh sn so sq ss ssy st syr
ta te teo tig tk tn tr ts ug uz ve vo vun wae xh xog )],
    ceb => [qw( fil tl )],

    # 3: zero,one,other
    lv => [qw( prg )],

    # 3: one,two,other
    he => [qw( iw )],
    iu => [qw( naq sat se sma smi smj smn sms )],

    # 3: one,few,other
    mo => [qw( ro )],
    bs => [qw( hr sh sr )],

    # 3: one,many,other
    ca => [qw( it lld pt-PT scn vec )],

    # 4: one,two,few,other
    dsb => [qw( hsb )],

    # 4: one,few,many,other
    cs => [qw( sk )],
    ru => [qw( uk )],

    # 5: one,two,few,many,other
    # No aliases in this group

    # 6: zero,one,two,few,many,other
    ar => [qw( ars )],
};

foreach my $locale ( keys( %$aliases ) )
{
    $plural_rules->{ $_ } = $plural_rules->{ $locale } for( @{$aliases->{ $locale }} );
}

# https://unicode.org/reports/tr35/tr35-numbers.html#Language_Plural_Rules
# https://cldr.unicode.org/index/cldr-spec/plural-rules
# https://unicode.org/reports/tr35/tr35-dates.html#Contents
sub plural_count
{
    my $self = shift( @_ );
    my $number = shift( @_ );
    my $locale = shift( @_ );
    if( !length( $number // '' ) )
    {
        return( $self->error( "No number was provided to get its plural count." ) );
    }
    elsif( !length( $locale ) )
    {
        return( $self->error( "No locale was provided to get its plural count." ) );
    }
    $locale = $self->_locale_object( $locale ) ||
        return( $self->pass_error );

    my $rules;
    my $tree = $self->make_inheritance_tree( $locale->base ) ||
        return( $self->pass_error );
    foreach my $loc ( @$tree )
    {
        if( exists( $plural_rules->{ $loc } ) )
        {
            $rules = $plural_rules->{ $loc };
            last;
        }
    }
    # I could also write it as $rules //= { one => sub { $_[0] == 1 }, other => sub { 1 } };
    # but I would lose point for readability
    if( !defined( $rules ) )
    {
        $rules = { one => sub { $_[0] == 1 }, other => sub { 1 } };
    }
    foreach my $category ( qw( zero one two few many other ) )
    {
        if( exists( $rules->{ $category } ) && 
            $rules->{ $category }->( $number ) )
        {
            return( $category );
        }
    }
    # It should never reach here
    return( 'other' );
}

sub plural_range { return( shift->_fetch_one({
    id          => 'get_plural_range',
    field       => 'result',
    table       => 'plural_ranges',
    requires    => [qw( locale start stop )],
    default     => { alt => undef },
}, @_ ) ); }

sub plural_ranges { return( shift->_fetch_all({
    id          => 'plural_ranges',
    table       => 'plural_ranges',
    by          => [qw( locale aliases start stop result )],
}, @_ ) ); }

sub plural_rule { return( shift->_fetch_one({
    id          => 'get_plural_rule',
    field       => 'rule',
    table       => 'plural_rules',
    requires    => [qw( locale count )],
}, @_ ) ); }

sub plural_rules { return( shift->_fetch_all({
    id          => 'plural_rules',
    table       => 'plural_rules',
    by          => [qw( locale aliases count rule )],
}, @_ ) ); }

sub rbnf { return( shift->_fetch_one({
    id      => 'get_rbnf',
    field   => 'rule_id',
    table   => 'rbnf',
    requires    => [qw( locale ruleset )],
}, @_ ) ); }

sub rbnfs { return( shift->_fetch_all({
    id          => 'rbnf',
    table       => 'rbnf',
    by          => [qw( locale grouping ruleset )],
}, @_ ) ); }

sub reference { return( shift->_fetch_one({
    id      => 'get_ref',
    field   => 'code',
    table   => 'refs',
}, @_ ) ); }

sub references { return( shift->_fetch_all({
    id          => 'refs',
    table       => 'refs',
}, @_ ) ); }

sub script { return( shift->_fetch_one({
    id      => 'get_script',
    field   => 'script',
    table   => 'scripts',
}, @_ ) ); }

sub scripts { return( shift->_fetch_all({
    id          => 'scripts',
    table       => 'scripts',
    by          => [qw( rtl origin_country likely_language )],
    has_status  => 1,
}, @_ ) ); }

sub script_l10n { return( shift->_fetch_one({
    id          => 'get_script_l10n',
    field       => 'script',
    table       => 'scripts_l10n',
    requires    => [qw( locale alt )],
    default     => { alt => undef },
}, @_ ) ); }

sub scripts_l10n { return( shift->_fetch_all({
    id          => 'scripts_l10n',
    table       => 'scripts_l10n',
    by          => [qw( locale alt )],
}, @_ ) ); }

sub split_interval
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $greatest_diff = $opts->{greatest_diff} ||
        return( $self->error( "No 'greatest_diff' argument value was provided." ) );
    my $pat = $opts->{pattern} ||
        return( $self->error( "No pattern was provided." ) );
    # {0} – {1}
    if( $pat =~ /^(?<p1>\{\d\})(?<sep>[^\{]+)(?<p2>\{\d\})$/ )
    {
        return( [ $+{p1}, $+{sep}, $+{p2} ] );
    }
    # First, remove the quoted literals from our string so they do not interfer
    my $literals = {};
    my $spaces = [];
    if( index( $pat, "'" ) != -1 )
    {
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
            next OUTER if( $check =~ /^[^a-zA-Z]$/ );
            my $pos = index( $pat, $check, $i + length( $check ) );
            if( exists( $equivalent->{ $check } ) &&
                $pos == -1 )
            {
                $pos = index( $pat, $equivalent->{ $check }, $i + length( $equivalent->{ $check } ) );
                $check = $equivalent->{ $check } if( $pos != -1 );
            }
            if( $pos != -1 )
            {
                $matches->{ substr( $pat, $pos, length( $check ) ) } = [$i, $pos];
            }
        }
    }

    if( !scalar( keys( %$matches ) ) )
    {
        warn( "Failed to find the repeating field in pattern '${pat}'" ) if( warnings::enabled() );
        return( [] );
    }
    my @bests = sort{ length( $b ) <=> length( $a ) } keys( %$matches );
    my $max_len = length( $bests[0] );
    my $best;
    if( scalar( @bests ) > 1 && length( $bests[1] ) == $max_len )
    {
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
            return( $self->error( "Found ", scalar( @bests ), " candidates, but none had the greatest difference field ${greatest_diff}" ) );
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
    my( $start1, $start2 ) = @{$matches->{ $best }};
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

    return( [ $part1, $sep, $part2, $best ] );
}

sub subdivision { return( shift->_fetch_one({
    id      => 'get_subdivision',
    field   => 'subdivision',
    table   => 'subdivisions',
}, @_ ) ); }

sub subdivisions { return( shift->_fetch_all({
    id          => 'subdivisions',
    table       => 'subdivisions',
    by          => [qw( territory parent is_top_level )],
    has_status  => 1,
}, @_ ) ); }

sub subdivision_l10n { return( shift->_fetch_one({
    id          => 'get_subdivision_l10n',
    field       => 'subdivision',
    table       => 'subdivisions_l10n',
    requires    => [qw( locale )],
}, @_ ) ); }

sub subdivisions_l10n { return( shift->_fetch_all({
    id          => 'subdivisions_l10n',
    table       => 'subdivisions_l10n',
    by          => [qw( locale )],
}, @_ ) ); }

sub territory { return( shift->_fetch_one({
    id          => 'get_territory',
    field       => 'territory',
    table       => 'territories',
    has_array   => [qw( languages contains calendars weekend )],
}, @_ ) ); }

sub territories { return( shift->_fetch_all({
    id          => 'territories',
    table       => 'territories',
    by          => [qw( parent alt )],
    has_status  => 1,
    has_array   => [qw( languages contains calendars weekend )],
}, @_ ) ); }

sub territory_l10n { return( shift->_fetch_one({
    id          => 'get_territory_l10n',
    field       => 'territory',
    table       => 'territories_l10n',
    requires    => [qw( locale alt )],
    default     => { alt => undef },
}, @_ ) ); }

sub territories_l10n { return( shift->_fetch_all({
    id          => 'territories_l10n',
    table       => 'territories_l10n',
    by          => [qw( locale alt )],
}, @_ ) ); }

sub time_format { return( shift->_fetch_one({
    id          => 'get_time_format',
    field       => 'region',
    table       => 'time_formats',
    has_array   => [qw( time_allowed )],
}, @_ ) ); }

sub time_formats { return( shift->_fetch_all({
    id          => 'time_formats',
    table       => 'time_formats',
    by          => [qw( region territory locale )],
    has_array   => [qw( time_allowed )],
}, @_ ) ); }

sub time_relative_l10n { return( shift->_fetch_one({
    id          => 'get_time_relative_l10n',
    field       => 'relative',
    table       => 'time_relative_l10n',
    requires    => [qw( locale field_type field_length count )],
    default     => { count => 'one' },
}, @_ ) ); }

sub time_relatives_l10n { return( shift->_fetch_all({
    id          => 'time_relative_l10n',
    table       => 'time_relative_l10n',
    by          => [qw( locale field_type field_length count )],
}, @_ ) ); }

sub timezone { return( shift->_fetch_one({
    id          => 'get_timezone',
    field       => 'timezone',
    table       => 'timezones',
    has_array   => [qw( alias )],
}, @_ ) ); }

sub timezones { return( shift->_fetch_all({
    id          => 'timezones',
    table       => 'timezones',
    by          => [qw( territory region tzid tz_bcpid metazone is_golden is_primary is_canonical )],
    has_array   => [qw( alias )],
}, @_ ) ); }

sub timezone_canonical
{
    my $self = shift( @_ );
    my $tz = shift( @_ ) ||
        return( $self->error( "No timezone was provided to get its canonical version." ) );
    my $dbh = $self->_dbh || return( $self->pass_error );
    my $sth_id = 'sth_get_timezone';
    local $@;
    my $sth;
    unless( $sth = $self->_get_cached_statement( $sth_id ) )
    {
        # try-catch
        $sth = eval
        {
            $dbh->prepare( "SELECT * FROM timezones WHERE timezone = ?" )
        } || return( $self->error( "Unable to prepare SQL query with statement ID ${sth_id} to retrieve the given timezone information: ", ( $@ || $dbh->errstr ) ) );
        $self->_set_cached_statement( $sth_id => $sth );
    }

    # try-catch
    eval
    {
        $sth->execute( $tz );
    } || return( $self->error( "Error executing SQL query '$sth->{Statement}' with statement ID ${sth_id} to retrieve the given timezone information:", ( $@ || $sth->errstr ), " with SQL query: ", $sth->{Statement} ) );
    my $ref = $sth->fetchrow_hashref;
    return( $self->error( "No timezone '${tz}' exists in the Locale::Unicode::Data database." ) ) if( !$ref );
    $self->_decode_utf8( $ref ) if( MISSING_AUTO_UTF8_DECODING );
    $self->_decode_sql_arrays( ['alias'], $ref );
    if( $ref->{is_canonical} )
    {
        return( $ref->{timezone} );
    }
    elsif( $ref->{alias} &&
           ref( $ref->{alias} ) eq 'ARRAY' &&
           scalar( @{$ref->{alias}} ) )
    {
        $sth_id = 'sth_get_timezone_multi_' . scalar( @{$ref->{alias}} );
        unless( $sth = $self->_get_cached_statement( $sth_id ) )
        {
            # try-catch
            $sth = eval
            {
                $dbh->prepare( "SELECT * FROM timezones WHERE " . join( ' OR ', map{ "timezone = ?" } @{$ref->{alias}} ) )
            } || return( $self->error( "Unable to prepare SQL query with statement ID ${sth_id} to retrieve one of " . scalar( @{$ref->{alias}} ) . " timezone(s) information: ", ( $@ || $dbh->errstr ) ) );
            $self->_set_cached_statement( $sth_id => $sth );
        }
        # try-catch
        eval
        {
            $sth->execute( @{$ref->{alias}} );
        } || return( $self->error( "Error executing SQL query '$sth->{Statement}' with statement ID ${sth_id} to retrieve one of " . scalar( @{$ref->{alias}} ) . " timezone(s) information:", ( $@ || $sth->errstr ), " with SQL query: ", $sth->{Statement} ) );
        my $all = $sth->fetchall_arrayref({});
        foreach my $this ( @$all )
        {
            return( $this->{timezone} ) if( $this->{is_canonical} );
        }
    }
    return( '' );
}

sub timezone_city
{
    my $self = shift( @_ );
    my $is_extended = $self->extend_timezones_cities;
    return( $self->_fetch_one({
        id          => 'get_timezone_city',
        field       => 'timezone',
        table       => ( $is_extended ? 'timezones_cities_extended' : 'timezones_cities' ),
        requires    => [qw( locale alt )],
        default     => { alt => undef },
    }, @_ ) );
}

sub timezones_cities
{
    my $self = shift( @_ );
    my $is_extended = $self->extend_timezones_cities;
    return( $self->_fetch_all({
        id          => 'timezones_cities',
        table       => ( $is_extended ? 'timezones_cities_extended' : 'timezones_cities' ),
        by          => [qw( locale alt )],
    }, @_ ) );
}

sub timezone_formats { return( shift->_fetch_one({
    id          => 'get_timezone_formats',
    field       => 'type',
    table       => 'timezones_formats',
    requires    => [qw( locale subtype )],
    default     => { subtype => undef },
}, @_ ) ); }

sub timezones_formats { return( shift->_fetch_all({
    id          => 'timezones_formats',
    table       => 'timezones_formats',
    by          => [qw( locale type subtype format_pattern )],
}, @_ ) ); }

sub timezone_info { return( shift->_fetch_one({
    id          => 'get_timezone_info',
    field       => 'timezone',
    table       => 'timezones_info',
    requires    => [qw( start )],
    default     => { start => undef },
}, @_ ) ); }

sub timezones_info { return( shift->_fetch_all({
    id          => 'timezones_info',
    table       => 'timezones_info',
    by          => [qw( timezone metazone start until )],
}, @_ ) ); }

sub timezone_names { return( shift->_fetch_one({
    id          => 'get_timezone_names',
    field       => 'timezone',
    table       => 'timezones_names',
    requires    => [qw( locale width )],
    default     => { start => undef },
}, @_ ) ); }

sub timezones_names { return( shift->_fetch_all({
    id          => 'timezones_names',
    table       => 'timezones_names',
    by          => [qw( locale timezone width )],
}, @_ ) ); }

sub unit_alias { return( shift->_fetch_one({
    id      => 'get_unit_alias',
    field   => 'alias',
    table   => 'unit_aliases',
}, @_ ) ); }

sub unit_aliases { return( shift->_fetch_all({
    id      => 'unit_aliases',
    table   => 'unit_aliases',
}, @_ ) ); }

sub unit_constant { return( shift->_fetch_one({
    id      => 'get_unit_constant',
    field   => 'constant',
    table   => 'unit_constants',
}, @_ ) ); }

sub unit_constants { return( shift->_fetch_all({
    id      => 'unit_constants',
    table   => 'unit_constants',
}, @_ ) ); }

sub unit_conversion { return( shift->_fetch_one({
    id          => 'get_unit_conversion',
    field       => 'source',
    table       => 'unit_conversions',
    has_array   => [qw( systems )],
}, @_ ) ); }

sub unit_conversions { return( shift->_fetch_all({
    id          => 'unit_conversions',
    table       => 'unit_conversions',
    by          => [qw( base_unit category )],
    has_array   => [qw( systems )],
}, @_ ) ); }

sub unit_l10n { return( shift->_fetch_one({
    id          => 'get_unit_l10n',
    field       => 'unit_id',
    table       => 'units_l10n',
    requires    => [qw( locale format_length unit_type count gender gram_case )],
    default     => { count => undef, gender => undef, gram_case => undef },
}, @_ ) ); }

sub units_l10n { return( shift->_fetch_all({
    id          => 'units_l10n',
    table       => 'units_l10n',
    by          => [qw( locale format_length unit_type unit_id pattern_type count gender gram_case )],
}, @_ ) ); }

sub unit_prefix { return( shift->_fetch_one({
    id      => 'get_unit_prefix',
    field   => 'unit_id',
    table   => 'unit_prefixes',
}, @_ ) ); }

sub unit_prefixes { return( shift->_fetch_all({
    id      => 'unit_prefixes',
    table   => 'unit_prefixes',
}, @_ ) ); }

sub unit_pref { return( shift->_fetch_one({
    id      => 'get_unit_pref',
    field   => 'unit_id',
    table   => 'unit_prefs',
}, @_ ) ); }

sub unit_prefs { return( shift->_fetch_all({
    id      => 'unit_prefs',
    table   => 'unit_prefs',
    by      => [qw( territory category )],
}, @_ ) ); }

sub unit_quantity { return( shift->_fetch_one({
    id      => 'get_unit_quantity',
    field   => 'base_unit',
    table   => 'unit_quantities',
}, @_ ) ); }

sub unit_quantities { return( shift->_fetch_all({
    id          => 'unit_quantities',
    table       => 'unit_quantities',
    by          => [qw( quantity )],
    has_status  => 1,
}, @_ ) ); }

sub variant { return( shift->_fetch_one({
    id      => 'get_variant',
    field   => 'variant',
    table   => 'variants',
}, @_ ) ); }

sub variants { return( shift->_fetch_all({
    id      => 'variants',
    table   => 'variants',
    has_status  => 1,
}, @_ ) ); }

sub variant_l10n { return( shift->_fetch_one({
    id          => 'get_variant_l10n',
    field       => 'variant',
    table       => 'variants_l10n',
    requires    => [qw( locale alt )],
    default     => { alt => undef },
}, @_ ) ); }

sub variants_l10n { return( shift->_fetch_all({
    id          => 'variants_l10n',
    table       => 'variants_l10n',
    by          => [qw( locale alt )],
}, @_ ) ); }

sub week_preference { return( shift->_fetch_one({
    id          => 'get_week_preference',
    field       => 'locale',
    table       => 'week_preferences',
    has_array   => [qw( ordering )],
}, @_ ) ); }

sub week_preferences { return( shift->_fetch_all({
    id          => 'week_preferences',
    table       => 'week_preferences',
    has_array   => [qw( ordering )],
}, @_ ) ); }

sub _dbh
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $file = $opts->{datafile} || $self->datafile || $DB_FILE;
    my $dbh;
    if( $DBH &&
        ref( $DBH ) eq 'HASH' &&
        exists( $DBH->{ $file } ) &&
        $DBH->{ $file } &&
        Scalar::Util::blessed( $DBH->{ $file } ) &&
        $DBH->{ $file }->isa( 'DBI::db' ) &&
        $DBH->{ $file }->ping )
    {
        return( $DBH->{ $file } );
    }


    if( !-e( $file ) )
    {
        return( $self->error( "Unicode CLDR SQLite database file ${file} does not exist!" ) );
    }
    elsif( !-f( $file ) )
    {
        return( $self->error( "Unicode CLDR SQLite database file ${file} is not a regular file." ) );
    }
    elsif( -z( $file ) )
    {
        return( $self->error( "Unicode CLDR SQLite database file ${file} is empty!" ) );
    }
    elsif( !-r( $file ) )
    {
        return( $self->error( "Unicode CLDR SQLite database file ${file} is not readable by uid $>" ) );
    }
    elsif( version->parse( $DBD::SQLite::sqlite_version ) < version->parse( '3.6.19' ) )
    {
        return( $self->error( "SQLite driver version 3.6.19 or higher is required. You have version ", $DBD::SQLite::sqlite_version ) );
    }

    if( HAS_CONSTANTS )
    {
        require DBD::SQLite::Constants;
    }

    my $params =
    {
        ( HAS_CONSTANTS ? ( sqlite_open_flags => DBD::SQLite::Constants::SQLITE_OPEN_READONLY ) : () ),
    };
    $dbh = DBI->connect( "dbi:SQLite:dbname=${file}", '', '', $params ) ||
        return( $self->error( "Unable to make connection to Unicode CLDR SQLite database file ${file}: ", $DBI::errstr ) );
    # See: <https://metacpan.org/release/ADAMK/DBD-SQLite-1.27/view/lib/DBD/SQLite.pm#Foreign-Keys>
    $dbh->do("PRAGMA foreign_keys = ON");
    # UTF-8 decoding is done natively from version 1.68 onward
    if( !MISSING_AUTO_UTF8_DECODING )
    {
        $dbh->{sqlite_string_mode} = DBD::SQLite::Constants::DBD_SQLITE_STRING_MODE_UNICODE_FALLBACK;
    }
    return( $DBH->{ $file } = $dbh );
}

sub _decode_sql_arrays
{
    my $self = shift( @_ );
    die( "\$cldr->_decode_sql_arrays( \$array_ref_of_array_fields, \$data )" ) if( @_ != 2 );
    my( $where, $ref ) = @_;
    if( ref( $where ) ne 'ARRAY' )
    {
        die( "\$cldr->_decode_sql_arrays( \$array_ref_of_array_fields, \$data )" );
    }
    elsif( ref( $ref // '' ) ne 'HASH' && Scalar::Util::reftype( $ref // '' ) ne 'ARRAY' )
    {
        die( "\$cldr->_decode_sql_arrays( \$array_ref_of_array_fields, \$data )" );
    }

    my $j = JSON->new->relaxed;
    local $@;
    if( ref( $ref ) eq 'HASH' )
    {
        foreach my $field ( @$where )
        {
            if( exists( $ref->{ $field } ) &&
                defined( $ref->{ $field } ) &&
                length( $ref->{ $field } ) )
            {
                my $decoded = eval
                {
                    $j->decode( $ref->{ $field } );
                };
                if( $@ )
                {
                    warn( "Warning only: error attempting to decode JSON array in field \"${field}\" for value '", $ref->{ $field }, "': $@" );
                    $ref->{ $field } = [];
                }
                else
                {
                    $ref->{ $field } = $decoded;
                }
            }
        }
    }
    elsif( Scalar::Util::reftype( $ref ) eq 'ARRAY' )
    {
        for( my $i = 0; $i < scalar( @$ref ); $i++ )
        {
            if( ref( $ref->[$i] ) ne 'HASH' )
            {
                warn( "SQL data at offset ${i} is not an HASH reference." );
                next;
            }
            $self->_decode_sql_arrays( $where, $ref->[$i] );
        }
    }
    return( $ref );
}

sub _decode_utf8
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    if( ref( $this ) eq 'HASH' )
    {
        foreach my $k ( keys( %$this ) )
        {
            next if( !defined( $this->{ $k } ) );
            if( ref( $this->{ $k } ) eq 'ARRAY' ||
                !ref( $this->{ $k } ) )
            {
                $this->{ $k } = $self->_decode_utf8( $this->{ $k } );
            }
        }
    }
    elsif( ref( $this ) eq 'ARRAY' )
    {
        for( my $i = 0; $i < scalar( @$this ); $i++ )
        {
            next if( !defined( $this->[$i] ) );
            if( ref( $this->[$i] ) eq 'HASH' ||
                !ref( $this->[$i] ) )
            {
                $this->[$i] = $self->_decode_utf8( $this->[$i] );
            }
        }
    }
    elsif( !ref( $this ) )
    {
        my $val = eval
        {
            Encode::decode_utf8( $this, Encode::FB_CROAK );
        };
        if( $@ )
        {
            warn( "Error utf-8 decoding: $@" ) if( warnings::enabled() );
            return( $this );
        }
        else
        {
            return( $val );
        }
    }
    return( $this );
}

sub _fetch_all
{
    my $self = shift( @_ );
    my $def = shift( @_ ) || return( $self->error( "No hash definition provided." ) );
    return( $self->error( "Hash definition is not an hash reference." ) ) if( ref( $def ) ne 'HASH' );
    my $table = $def->{table} || return( $self->error( "No SQL table name was provided." ) );
    my $id = $def->{id} || $table;
    my $what = $def->{what} || $table;
    my $order = exists( $def->{order} ) ? $def->{order} : 'rowid';
    my $opts = $self->_get_args_as_hash( @_ );
    my $status = $def->{has_status}
        ? $def->{has_status} =~ /[a-zA-Z]/
            ? $def->{has_status}
            : 'status'
        : undef;
    my $by = ( exists( $def->{by} ) && ref( $def->{by} ) eq 'ARRAY' ? $def->{by} : [] );
    my $order_by_value = [];
    if( exists( $opts->{order_by_value} ) &&
        defined( $opts->{order_by_value} ) )
    {
        if( ref( $opts->{order_by_value} ) eq 'ARRAY' )
        {
            $order_by_value = $opts->{order_by_value};
        }
        else
        {
            $order_by_value = [$opts->{order_by_value}];
        }
    }

    if( scalar( @$order_by_value ) )
    {
        if( scalar( @$order_by_value ) != 2 )
        {
            die( "Invalid number of parameter for order by field value. You need to provide a field name and an array reference of values." );
        }
        elsif( ref( $order_by_value->[1] ) ne 'ARRAY' )
        {
            die( "Invalid parameters provided for order by field value. The second parameter must be an array reference of value to sort with." );
        }
        elsif( !scalar( @{$order_by_value->[1]} ) )
        {
            die( "The array of value to sort the data for field '", ( $order_by_value->[0] // 'undef' ), "' is empty." );
        }
        my $field = $order_by_value->[0];
        my @cases;
        for( my $i = 0; $i < scalar( @{$order_by_value->[1]} ); $i++ )
        {
            push( @cases, sprintf( "WHEN '%s' THEN %d", $order_by_value->[1]->[$i], $i ) );
        }
        my $case = "CASE ${field} " . join( ' ', @cases ) . ' END';
        $order = $case;
    }
    # order option to override any default order directive
    if( exists( $opts->{order} ) )
    {
        my( $field, $datatype );
        if( ref( $opts->{order} ) eq 'HASH' )
        {
            my @keys = keys( %{$opts->{order}} );
            if( scalar( @keys ) != 1 )
            {
                local $" = ', ';
                die( "You can only specify one order field to cast. Here, you provided: @keys" );
            }
            ( $field, $datatype ) = ( $keys[0], $opts->{order}->{ $keys[0] } );
        }
        elsif( ref( $opts->{order} ) eq 'ARRAY' )
        {
            if( scalar( @{$opts->{order}} ) != 2 )
            {
                die( "You need to provide a 2-elements array. The first element is the field name and the second element the data type. You provided ", scalar( @{$opts->{order}} ), " element(s)." );
            }
            ( $field, $datatype ) = @{$opts->{order}};
        }
        else
        {
            $field = $opts->{order};
        }

        if( defined( $field ) && defined( $datatype ) )
        {
            if( !length( $field // '' ) )
            {
                die( "The order field value provided is empty!" );
            }
            elsif( !length( $datatype // '' ) )
            {
                die( "The order datatype value provided is empty!" );
            }
            elsif( $field !~ /^[a-zA-Z0-9\_]+$/ )
            {
                die( "The order field name provided contains illegal value. It must be an alphanumerical string, with possible '_' character." );
            }
            elsif( $datatype !~ /^[a-zA-Z0-9]+$/ )
            {
                die( "The order field data type contains an illegal value. It must be a string of alpha numeric characters." );
            }
            $order = "CAST(${field} AS \U${datatype}\E)";
        }
        elsif( defined( $field ) )
        {
            die( "The order field value provided is empty!" ) if( !length( $field // '' ) );
            if( $field !~ /^[a-zA-Z0-9\_]+$/ )
            {
                die( "The order field name provided contains illegal value. It must be an alphanumerical string, with possible '_' character." );
            }
        }
    }
    my $sql_arrays_in = ( exists( $def->{has_array} ) && ref( $def->{has_array} ) eq 'ARRAY' ? $def->{has_array} : [] );
    my $sth;
    my $op_map =
    {
        '=' => 'IS',
        '!=' => 'IS NOT',
    };
    my $by_values = [];
    my $skeleton = [];
    my $by_keys = [];
    if( scalar( @$by ) )
    {
        for( @$by )
        {
            return( $self->error( "Table field provided '$_' contains illegal characters." ) ) if( $_ !~ /^[a-z][a-z0-9]+(?:\_[a-z][a-z0-9]+)*$/ );
            next unless( exists( $opts->{ $_ } ) );
            if( ref( $opts->{ $_ } // '' ) eq 'ARRAY' )
            {
                my $and_skels = [];
                for( my $i = 0; $i < scalar( @{$opts->{ $_ }} ); $i++ )
                {
                    my $op = '=';
                    my $val = $opts->{ $_ }->[$i];
                    if( defined( $val ) &&
                        $val =~ s/^[[:blank:]\h]*(?<op>\<|\<=|\>|\>=|=|\!=|\~)[[:blank:]\h]*(?<val>.*?)$/$+{val}/ )
                    {
                        $op = $+{op};
                    }
                    elsif( defined( $val ) &&
                           ref( $val ) eq 'Regexp' )
                    {
                        $op = '~';
                        $val =~ s/^\(\?[^\:]+\:(.*?)\)$/$1/;
                    }

                    $op = $op_map->{ $op } if( exists( $op_map->{ $op } ) );
                    if( $op eq '~' )
                    {
                        push( @$and_skels, "$_ REGEXP(?)" );
                        push( @$by_keys, "regexp_${_}" );
                    }
                    else
                    {
                        push( @$and_skels, "$_ ${op} ?" );
                        push( @$by_keys, "${op}${_}" );
                    }
                    push( @$by_values, defined( $val ) ? ( Scalar::Util::blessed( $val ) && overload::Method( $val => '""' ) ) ? "$val" : $val : $val );
                }
                push( @$skeleton, '( ' . join( ' OR ', @$and_skels ) . ' )' );
            }
            else
            {
                my $op = '=';
                my $val = $opts->{ $_ };
                if( defined( $val ) &&
                    $val =~ s/^[[:blank:]\h]*(?<op>\<|\<=|\>|\>=|=|\!=|\~)[[:blank:]\h]*(?<val>.*?)$/$+{val}/ )
                {
                    $op = $+{op};
                }
                elsif( defined( $val ) &&
                       ref( $val ) eq 'Regexp' )
                {
                    $op = '~';
                    $val =~ s/^\(\?[^\:]+\:(.*?)\)$/$1/;
                }

                $op = $op_map->{ $op } if( exists( $op_map->{ $op } ) );
                if( $op eq '~' )
                {
                    push( @$skeleton, "$_ REGEXP(?)" );
                    push( @$by_keys, "regexp_${_}" );
                }
                else
                {
                    push( @$skeleton, "$_ ${op} ?" );
                    push( @$by_keys, "${op}${_}" );
                }
                push( @$by_values, defined( $val ) ? ( Scalar::Util::blessed( $val ) && overload::Method( $val => '""' ) ) ? "$val" : $val : $val );
            }
        }
    }
    if( defined( $status ) &&
        exists( $opts->{ $status } ) )
    {
        push( @$by, $status );
        push( @$by_values, $opts->{ $status } );
        push( @$skeleton, "${status} = ?" );
        push( @$by_keys, "=${status}" );
    }

    my( $has, $has_keys, $has_values );
    if( $opts->{has} && scalar( @$sql_arrays_in ) )
    {
        my $has_elems = [];
        if( ref( $opts->{has} ) eq 'HASH' )
        {
            @$has_elems = %{$opts->{has}};
        }
        elsif( ref( $opts->{has} ) eq 'ARRAY' )
        {
            $has_elems = $opts->{has};
        }
        elsif( scalar( @$sql_arrays_in ) == 1 )
        {
            $has_elems = [ $sql_arrays_in->[0] => $opts->{has} ];
        }
        else
        {
            return( $self->error( "There are ", scalar( @$sql_arrays_in ), " fields with array. You need to specify which one you want to check for value '", ( $opts->{has} // 'undef' ), "'" ) );
        }
        $has = [];
        $has_keys = [];
        $has_values = [];
        for( my $i = 0; $i < scalar( @$has_elems ); $i += 2 )
        {
            my $f = $has_elems->[$i];
            unless( $f =~ /^[a-zA-z][a-zA-z0-9]+$/ )
            {
                return( $self->error( "Invalid field name '${f}' for table '${table}'. It should only contain alpha numeric characters." ) );
            }
            push( @$has_keys, $f );
            push( @$has_values, $has_elems->[$i + 1] );
            push( @$has, "EXISTS (SELECT * FROM JSON_EACH(${f}) WHERE JSON_EACH.value IS ?)" );
        }
    }

    my $by_key = scalar( @$by_keys ) ? join( '_', @$by_keys ) : '';
    my $sth_id = $by_key
        ? "${id}_with_${by_key}" . ( defined( $has ) ? '_has_' . join( '_', @$has_keys ) : '' ) . "_order_${order}"
        : defined( $has )
            ? "${id}_with_has_" . join( '_', @$has_keys ) . "_order_${order}"
            : "${id}_order_${order}";
    local $" = ', ';
    local $@;
    if( $by_key || defined( $has ) )
    {
        unless( $sth = $self->_get_cached_statement( $sth_id ) )
        {
            my $dbh = $self->_dbh || return( $self->pass_error );
            $sth = eval
            {
                $dbh->prepare( "SELECT * FROM ${table} WHERE " . join( ' AND ', @$skeleton ) . ( defined( $has ) ? ( ( scalar( @$skeleton ) ? ' AND (' : '' ) . join( ' OR ', @$has ) . ( scalar( @$skeleton ) ? ')' : '' ) ) : '' ) . " ORDER BY ${order}" )
            } || return( $self->error( "Unable to prepare SQL query to retrieve all ${what} information for fields @$by: ", ( $@ || $dbh->errstr ) ) );
            $self->_set_cached_statement( $sth_id => $sth );
        }
    }
    else
    {
        unless( $sth = $self->_get_cached_statement( $sth_id ) )
        {
            my $dbh = $self->_dbh || return( $self->pass_error );
            $sth = eval
            {
                $dbh->prepare( "SELECT * FROM ${table} ORDER BY ${order}" )
            } || return( $self->error( "Unable to prepare SQL query to retrieve all ${what} information: ", ( $@ || $dbh->errstr ) ) );
            $self->_set_cached_statement( $sth_id => $sth );
        }
    }

    eval
    {
        $sth->execute( ( scalar( @$by_values ) ? @$by_values : () ), ( defined( $has_values ) ? @$has_values : () ) )
    } || return( $self->error( "Error executing SQL query '$sth->{Statement}' to retrieve all ${what}". ( $by_key ? " with fields @$by" : '' ), ": ", ( $@ || $sth->errstr ), " with SQL query: ", $sth->{Statement} ) );
    my $all = $sth->fetchall_arrayref({});
    $self->_decode_utf8( $all ) if( MISSING_AUTO_UTF8_DECODING );
    if( $all && scalar( @$sql_arrays_in ) )
    {
        $self->_decode_sql_arrays( $sql_arrays_in, $all ) if( $self->{decode_sql_arrays} );
    }
    if( !$all && want( 'ARRAY' ) )
    {
        return( [] );
    }
    return( $all );
}

sub _fetch_one
{
    my $self = shift( @_ );
    my $def = shift( @_ ) || return( $self->error( "No hash definition provided." ) );
    return( $self->error( "Hash definition is not an hash reference." ) ) if( ref( $def ) ne 'HASH' );
    my $field = $def->{field} || return( $self->error( "No table field was provided." ) );
    my $what = $def->{what} || $field;
    my $table = $def->{table} || return( $self->error( "No SQL table name was provided." ) );
    my $defaults = $def->{default} || {};
    my $opts = $self->_get_args_as_hash( @_ );
    return( $self->error( "No ${what} ID provided to retrieve its information." ) ) if( !exists( $opts->{ $field } ) );
    my $id = ref( $opts->{ $field } ) eq 'ARRAY' ? $opts->{ $field } : [$opts->{ $field }];
    my $sql_arrays_in = ( exists( $def->{has_array} ) && ref( $def->{has_array} ) eq 'ARRAY' ? $def->{has_array} : [] );
    my $requires = exists( $def->{requires} ) && ref( $def->{requires} ) eq 'ARRAY'
        ? $def->{requires}
        : [];
    # my $requires_key = scalar( @$requires ) ? join( '_', @$requires ) : '';
    my $required_val  = [];
    my $required_skel = [];
    my $required_keys = [];
    # In SQLite, the expression '= NULL' does not work, and we need to use 'IS NULL'
    my $op_map =
    {
        '=' => 'IS',
        '!=' => 'IS NOT',
    };

    for( @$requires )
    {
        return( $self->error( "Table field provided '$_' contains illegal characters." ) ) if( $_ !~ /^[a-z][a-z0-9]+(?:\_[a-z][a-z0-9]+)*$/ );
        $opts->{ $_ } = $defaults->{ $_ } if( !exists( $opts->{ $_ } ) && exists( $defaults->{ $_ } ) );
        if( !exists( $opts->{ $_ } ) )
        {
            return( $self->error( "No value for $_ was provided." ) );
        }
        
        if( ref( $opts->{ $_ } // '' ) eq 'ARRAY' )
        {
            my $and_skels = [];
            for( my $i = 0; $i < scalar( @{$opts->{ $_ }} ); $i++ )
            {
                my $op = '=';
                my $val = $opts->{ $_ }->[$i];
                if( defined( $val ) &&
                    # $opts->{ $_ }->[$i] =~ s/^[[:blank:]\h]*(?<op>\<|\<=|\>|\>=|=|\!=)[[:blank:]\h]*(?<dt>\-?\d+.*?)$/$+{dt}/ )
                    $val =~ s/^[[:blank:]\h]*(?<op>\<|\<=|\>|\>=|=|\!=|\~)[[:blank:]\h]*(?<val>.*?)$/$+{val}/ )
                {
                    $op = $+{op};
                }
                elsif( defined( $val ) &&
                       ref( $val ) eq 'Regexp' )
                {
                    $op = '~';
                    $val =~ s/^\(\?[^\:]+\:(.*?)\)$/$1/;
                }

                $op = $op_map->{ $op } if( exists( $op_map->{ $op } ) );
                if( $op eq '~' )
                {
                    push( @$and_skels, "$_ REGEXP(?)" );
                    push( @$required_keys, "regexp_${_}" );
                }
                else
                {
                    push( @$and_skels, "$_ ${op} ?" );
                    push( @$required_keys, "${op}${_}" );
                }
                push( @$required_val, defined( $val ) ? ( Scalar::Util::blessed( $val ) && overload::Method( $val => '""' ) ) ? "$val" : $val : $val );
            }
            push( @$required_skel, '( ' . join( ' OR ', @$and_skels ) . ' )' );
        }
        else
        {
            my $op = '=';
            my $val = $opts->{ $_ };
            if( defined( $val ) &&
                # $opts->{ $_ } =~ s/^[[:blank:]\h]*(?<op>\<|\<=|\>|\>=|=|\!=\~)[[:blank:]\h]*(?<dt>\-?\d+.*?)$/$+{dt}/ )
                $val =~ s/^[[:blank:]\h]*(?<op>\<|\<=|\>|\>=|=|\!=|\~)[[:blank:]\h]*(?<val>.*?)$/$+{val}/ )
            {
                $op = $+{op};
            }
            elsif( defined( $val ) &&
                   ref( $val ) eq 'Regexp' )
            {
                $op = '~';
                $val =~ s/^\(\?[^\:]+\:(.*?)\)$/$1/;
            }

            $op = $op_map->{ $op } if( exists( $op_map->{ $op } ) );
            if( $op eq '~' )
            {
                push( @$required_skel, "$_ REGEXP(?)" );
                push( @$required_keys, "regexp_${_}" );
            }
            else
            {
                push( @$required_skel, "$_ ${op} ?" );
                push( @$required_keys, "${op}${_}" );
            }
            push( @$required_val, defined( $val ) ? ( Scalar::Util::blessed( $val ) && overload::Method( $val => '""' ) ) ? "$val" : $val : $val );
        }
    }
    my $requires_key = scalar( @$required_keys ) ? join( '_', @$required_keys ) : '';
    my $field_val = [];
    my $field_skel = [];
    my $field_keys = [];
    for( @$id )
    {
        my $op = '=';
        if( defined( $_ ) &&
            s/^[[:blank:]\h]*(?<op>\<|\<=|\>|\>=|=|\!=|\~)[[:blank:]\h]*(?<val>.*?)$/$+{val}/ )
        {
            $op = $+{op};
        }
        elsif( defined( $_ ) &&
               ref( $_ ) eq 'Regexp' )
        {
            $op = '~';
            s/^\(\?[^\:]+\:(.*?)\)$/$1/;
        }

        $op = $op_map->{ $op } if( exists( $op_map->{ $op } ) );
        if( $op eq '~' )
        {
            push( @$field_skel, "${field} REGEXP(?)" );
            push( @$field_keys, "regexp_field" );
        }
        else
        {
            push( @$field_skel, "${field} ${op} ?" );
            push( @$field_keys, "${op}${field}" );
        }
        push( @$field_val, defined( $_ ) ? ( Scalar::Util::blessed( $_ ) && overload::Method( $_ => '""' ) ) ? "$_" : $_ : $_ );
    }
    my $sth_id = ( $def->{id} ? $def->{id} . '_' : '' ) . join( '_', @$field_keys );
    $sth_id .= '_' . $requires_key if( $requires_key );
    my $sth;
    local $@;
    unless( $sth = $self->_get_cached_statement( $sth_id ) )
    {
        my $dbh = $self->_dbh || return( $self->pass_error );
        $sth = eval
        {
            $dbh->prepare( "SELECT * FROM ${table} WHERE (" . join( ' OR ', @$field_skel ) . ') ' . ( scalar( @$required_skel ) ? ' AND ' . join( ' AND ', @$required_skel ) : '' ) . ( $def->{multi} ? ' ORDER BY rowid' : '' ) )
        } || return( $self->error( "Unable to prepare SQL query with statement ID ${sth_id} to retrieve a ${what} information: ", ( $@ || $dbh->errstr ) ) );
        $self->_set_cached_statement( $sth_id => $sth );
    }

    eval
    {
        $sth->execute( @$field_val, ( scalar( @$required_val ) ? @$required_val : () ) );
    } || return( $self->error( "Error executing SQL query '$sth->{Statement}' with statement ID ${sth_id} to retrieve a ${what} information:", ( $@ || $sth->errstr ), " with SQL query: ", $sth->{Statement} ) );
    my $ref = ( $def->{multi} || scalar( @$id ) > 1 ) ? $sth->fetchall_arrayref({}) : $sth->fetchrow_hashref;
    $self->_decode_utf8( $ref ) if( MISSING_AUTO_UTF8_DECODING );
    if( $ref && scalar( @$sql_arrays_in ) )
    {
        $self->_decode_sql_arrays( $sql_arrays_in, $ref ) if( $self->{decode_sql_arrays} );
    }
    if( !$ref && want( 'HASH' ) )
    {
        return( {} );
    }
    return( $ref );
}

sub _get_cached_statement
{
    my $self = shift( @_ );
    my $id = shift( @_ );
    die( "No statement ID was provided to get its cached object." ) if( !length( $id // '' ) );
    my $file = $self->datafile || $DB_FILE;
    $STHS->{ $file } //= {};
    if( exists( $STHS->{ $file }->{ $id } ) &&
        defined( $STHS->{ $file }->{ $id } ) &&
        Scalar::Util::blessed( $STHS->{ $file }->{ $id } ) &&
        $STHS->{ $file }->{ $id }->isa( 'DBI::st' ) )
    {
        return( $STHS->{ $file }->{ $id } );
    }
    return;
}

sub _get_metadata
{
    my $self = shift( @_ );
    my $prop = shift( @_ ) || die( "No metadata property provided." );
    my $dbh = $self->_dbh || return( $self->pass_error );
    my $sth;
    unless( $sth = $self->_get_cached_statement( 'cldr_metadata' ) )
    {
        $sth = eval
        {
            $dbh->prepare( "SELECT value FROM metainfos WHERE property = ?" )
        } || return( $self->error( "Unable to prepare query to get the CLDR built datetime from the SQLite database at ", $self->datafile, ": ", ( $@ || $dbh->errstr ) ) );
        $self->_set_cached_statement( cldr_metadata => $sth );
    }

    local $@;
    eval
    {
        $sth->execute( $prop );
    } || return( $self->error( "Unable to execute query to get the CLDR property '${prop}' from the SQLite database at ", $self->datafile, ": ", ( $@ || $sth->errstr ) ) );
    my $ref = $sth->fetchrow_arrayref;
    $self->_decode_utf8( $ref ) if( MISSING_AUTO_UTF8_DECODING );
    return( '' ) if( !$ref );
    return( $ref->[0] );
}

sub _locale_object
{
    my $self = shift( @_ );
    my $locale = shift( @_ ) ||
        return( $self->error( "No locale provided to ensure a Locale::Unicode." ) );
    unless( Scalar::Util::blessed( $locale ) &&
            $locale->isa( 'Locale::Unicode' ) )
    {
        $locale = Locale::Unicode->new( $locale ) ||
            return( $self->pass_error( Locale::Unicode->error ) );
    }
    return( $locale );
}
sub _set_cached_statement
{
    my $self = shift( @_ );
    my $id = shift( @_ );
    my $sth = shift( @_ );
    die( "No statement ID was provided to cache its object." ) if( !length( $id // '' ) );
    if( !$sth )
    {
        die( "No DBI statement handler was provided to cache with ID '${id}'" );
    }
    elsif( !Scalar::Util::blessed( $sth ) ||
           !$sth->isa( 'DBI::st' ) )
    {
        die( "Value provided (", overload::StrVal( $sth ), ") is not a DBI statement object." );
    }
    my $file = $self->datafile || $DB_FILE;
    $STHS->{ $file } //= {};
    $STHS->{ $file }->{ $id } = $sth;
    return( $sth );
}

sub _set_get_prop
{
    my $self = shift( @_ );
    my $field = shift( @_ ) ||
        return( $self->error( "No field was provided." ) );
    my( $re, $type, $isa );
    if( ref( $field ) eq 'HASH' )
    {
        my $def = $field;
        $field = $def->{field} || die( "No 'field' property was provided in the field dictionary hash reference." );
        if( exists( $def->{regexp} ) &&
            defined( $def->{regexp} ) &&
            ref( $def->{regexp} ) eq 'Regexp' )
        {
            $re = $def->{regexp};
        }
        elsif( exists( $def->{type} ) &&
               defined( $def->{type} ) &&
               length( $def->{type} ) )
        {
            $type = $def->{type};
        }
        if( exists( $def->{isa} ) &&
            defined( $def->{isa} ) &&
            length( $def->{isa} ) )
        {
            $isa = $def->{isa};
        }
    }
    if( @_ )
    {
        my $val = shift( @_ );
        if( defined( $val ) &&
            length( $val ) )
        {
            if( defined( $re ) &&
                $val !~ /^$re$/ )
            {
                return( $self->error( "Invalid value provided for \"${field}\": ${val}" ) );
            }
            elsif( defined( $type ) &&
                   $type eq 'boolean' )
            {
                $val = lc( $val );
                if( $val =~ /^(?:yes|no)$/i )
                {
                    $self->{_bool_types}->{ $field } = 'literal';
                    $val = ( $val eq 'yes' ? $self->true : $self->false );
                }
                elsif( $val =~ /^(?:true|false)$/i )
                {
                    $self->{_bool_types}->{ $field } = 'logic';
                    $val = ( $val eq 'true' ? $self->true : $self->false );
                }
                elsif( $val =~ /^(?:1|0)$/ )
                {
                    $self->{_bool_types}->{ $field } = 'logic';
                    $val = ( $val ? $self->true : $self->false );
                }
                else
                {
                    warn( "Unexpected value used as boolean for attribute \"${field}\": ${val}" ) if( warnings::enabled() );
                    $val = ( $val ? $self->true : $self->false );
                }
            }
            elsif( defined( $isa ) )
            {
                if( !Scalar::Util::blessed( $val ) ||
                    ( Scalar::Util::blessed( $val ) && !$val->isa( $isa ) ) )
                {
                    return( $self->error( "Value provided is not an ${isa} object." ) );
                }
            }
        }
        $self->{ $field } = $val
    }
    # So chaining works
    rreturn( $self ) if( Want::want( 'OBJECT' ) );
    # Returns undef in scalar context and an empty list in list context
    return if( !defined( $self->{ $field } ) );
    return( $self->{ $field } );
}

sub _get_args_as_hash
{
    my $self = shift( @_ );
    my $ref = {};
    if( scalar( @_ ) == 1 &&
        defined( $_[0] ) &&
        ( ref( $_[0] ) || '' ) eq 'HASH' )
    {
        $ref = shift( @_ );
    }
    elsif( !( scalar( @_ ) % 2 ) )
    {
        $ref = { @_ };
    }
    else
    {
        die( "Uneven number of parameters provided." );
    }
    return( $ref );
}

# NOTE: END
END
{
    if( defined( $STHS ) && ref( $STHS ) eq 'HASH' )
    {
        foreach my $db ( keys( %$STHS ) )
        {
            foreach my $sth ( keys( %{$STHS->{ $db }} ) )
            {
                if( defined( $sth ) &&
                    Scalar::Util::blessed( $sth ) )
                {
                    $sth->finish;
                }
            }
        }
    }
};

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my @keys = qw( datafile decode_sql_arrays fatal );
    my %hash = ();
    @hash{ @keys } = @$self{ @keys };
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, %hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
}

sub STORABLE_freeze { return( shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { return( shift->THAW( @_ ) ); }

# NOTE: CBOR will call the THAW method with the stored classname as first argument, the constant string CBOR as second argument, and all values returned by FREEZE as remaining arguments.
# NOTE: Storable calls it with a blessed object it created followed with $cloning and any other arguments initially provided by STORABLE_freeze
sub THAW
{
    my( $self, undef, @args ) = @_;
    my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
    my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
    my $hash = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};
    my $new;
    # Storable pattern requires to modify the object it created rather than returning a new one
    if( CORE::ref( $self ) )
    {
        foreach( CORE::keys( %$hash ) )
        {
            $self->{ $_ } = CORE::delete( $hash->{ $_ } );
        }
        $new = $self;
    }
    else
    {
        $new = CORE::bless( $hash => $class );
    }
    CORE::return( $new );
}

sub TO_JSON
{
    my $self = CORE::shift( @_ );
    my @keys = qw( datafile decode_sql_arrays );
    my $hash = {};
    @$hash{ @keys } = @$self{ @keys };
    return( $hash );
}

# NOTE: Locale::Unicode::Data::Boolean class
package Locale::Unicode::Data::Boolean;
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $VERSION $true $false );
    use overload
      "0+"     => sub{ ${$_[0]} },
      "++"     => sub{ $_[0] = ${$_[0]} + 1 },
      "--"     => sub{ $_[0] = ${$_[0]} - 1 },
      fallback => 1;
    $true  = do{ bless( \( my $dummy = 1 ) => 'Locale::Unicode::Data::Boolean' ) };
    $false = do{ bless( \( my $dummy = 0 ) => 'Locale::Unicode::Data::Boolean' ) };
    our $VERSION = 'v0.1.0';
};
use strict;
use warnings;

sub new
{
    my $this = shift( @_ );
    my $self = bless( \( my $dummy = ( $_[0] ? 1 : 0 ) ) => ( ref( $this ) || $this ) );
}

sub clone
{
    my $self = shift( @_ );
    unless( ref( $self ) )
    {
        die( "clone() must be called with an object." );
    }
    my $copy = $$self;
    my $new = bless( \$copy => ref( $self ) );
    return( $new );
}

sub false() { $false }

sub is_bool($) { UNIVERSAL::isa( $_[0], 'Locale::Unicode::Data::Boolean' ) }

sub is_true($) { $_[0] && UNIVERSAL::isa( $_[0], 'Locale::Unicode::Data::Boolean' ) }

sub is_false($) { !$_[0] && UNIVERSAL::isa( $_[0], 'Locale::Unicode::Data::Boolean' ) }

sub true() { $true  }

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, $$self] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $$self );
}

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: CBOR will call the THAW method with the stored classname as first argument, the constant string CBOR as second argument, and all values returned by FREEZE as remaining arguments.
# NOTE: Storable calls it with a blessed object it created followed with $cloning and any other arguments initially provided by STORABLE_freeze
sub THAW
{
    my( $self, undef, @args ) = @_;
    my( $class, $str );
    if( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' )
    {
        ( $class, $str ) = @{$args[0]};
    }
    else
    {
        $class = CORE::ref( $self ) || $self;
        $str = CORE::shift( @args );
    }
    # Storable pattern requires to modify the object it created rather than returning a new one
    if( CORE::ref( $self ) )
    {
        $$self = $str;
        CORE::return( $self );
    }
    else
    {
        CORE::return( $class->new( $str ) );
    }
}

sub TO_JSON
{
    # JSON does not check that the value is a proper true or false. It stupidly assumes this is a string
    # The only way to make it understand is to return a scalar ref of 1 or 0
    # return( $_[0] ? 'true' : 'false' );
    return( $_[0] ? \1 : \0 );
}

# NOTE: Locale::Unicode::Data::Exception class
package Locale::Unicode::Data::Exception;
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $VERSION );
    use overload (
        '""'    => 'as_string',
        bool    => sub{ $_[0] },
        fallback => 1,
    );
    our $VERSION = 'v0.1.0';
};
use strict;
use warnings;
use overloading;

sub new
{
    my $this = shift( @_ );
    my $self = bless( {} => ( ref( $this ) || $this ) );
    my @info = caller;
    @$self{ qw( package file line ) } = @info[0..2];
    my $args = {};
    if( scalar( @_ ) == 1 )
    {
        if( ( ref( $_[0] ) || '' ) eq 'HASH' )
        {
            $args = shift( @_ );
            if( $args->{skip_frames} )
            {
                @info = caller( int( $args->{skip_frames} ) );
                @$self{ qw( package file line ) } = @info[0..2];
            }
            $args->{message} ||= '';
            foreach my $k ( qw( package file line message code type retry_after ) )
            {
                $self->{ $k } = $args->{ $k } if( CORE::exists( $args->{ $k } ) );
            }
        }
        elsif( ref( $_[0] ) && $_[0]->isa( 'Locale::Unicode::Data::Exception' ) )
        {
            my $o = $args->{object} = shift( @_ );
            $self->{message} = $o->message;
            $self->{code} = $o->code;
            $self->{type} = $o->type;
            $self->{retry_after} = $o->retry_after;
        }
        else
        {
            die( "Unknown argument provided: '", overload::StrVal( $_[0] ), "'" );
        }
    }
    else
    {
        $args->{message} = join( '', map( ref( $_ ) eq 'CODE' ? $_->() : $_, @_ ) );
    }
    return( $self );
}

# This is important as stringification is called by die, so as per the manual page, we need to end with new line
# And will add the stack trace
sub as_string
{
    no overloading;
    my $self = shift( @_ );
    return( $self->{_cache_value} ) if( $self->{_cache_value} && !CORE::length( $self->{_reset} ) );
    my $str = $self->message;
    $str = "$str";
    $str =~ s/\r?\n$//g;
    $str .= sprintf( " within package %s at line %d in file %s", ( $self->{package} // 'undef' ), ( $self->{line} // 'undef' ), ( $self->{file} // 'undef' ) );
    $self->{_cache_value} = $str;
    CORE::delete( $self->{_reset} );
    return( $str );
}

sub code { return( shift->reset(@_)->_set_get_prop( 'code', @_ ) ); }

sub file { return( shift->reset(@_)->_set_get_prop( 'file', @_ ) ); }

sub line { return( shift->reset(@_)->_set_get_prop( 'line', @_ ) ); }

sub message { return( shift->reset(@_)->_set_get_prop( 'message', @_ ) ); }

sub package { return( shift->reset(@_)->_set_get_prop( 'package', @_ ) ); }

# From perlfunc docmentation on "die":
# "If LIST was empty or made an empty string, and $@ contains an
# object reference that has a "PROPAGATE" method, that method will
# be called with additional file and line number parameters. The
# return value replaces the value in $@; i.e., as if "$@ = eval {
# $@->PROPAGATE(__FILE__, __LINE__) };" were called."
sub PROPAGATE
{
    my( $self, $file, $line ) = @_;
    if( defined( $file ) && defined( $line ) )
    {
        my $clone = $self->clone;
        $clone->file( $file );
        $clone->line( $line );
        return( $clone );
    }
    return( $self );
}

sub reset
{
    my $self = shift( @_ );
    if( !CORE::length( $self->{_reset} ) && scalar( @_ ) )
    {
        $self->{_reset} = scalar( @_ );
    }
    return( $self );
}

sub rethrow 
{
    my $self = shift( @_ );
    return if( !ref( $self ) );
    die( $self );
}

sub retry_after { return( shift->_set_get_prop( 'retry_after', @_ ) ); }

sub throw
{
    my $self = shift( @_ );
    my $e;
    if( @_ )
    {
        my $msg  = shift( @_ );
        $e = $self->new({
            skip_frames => 1,
            message => $msg,
        });
    }
    else
    {
        $e = $self;
    }
    die( $e );
}

sub type { return( shift->reset(@_)->_set_get_prop( 'type', @_ ) ); }

sub _set_get_prop
{
    my $self = shift( @_ );
    my $prop = shift( @_ ) || die( "No object property was provided." );
    $self->{ $prop } = shift( @_ ) if( @_ );
    return( $self->{ $prop } );
}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
    # Return an array reference rather than a list so this works with Sereal and CBOR
    # On or before Sereal version 4.023, Sereal did not support multiple values returned
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' && Sereal::Encoder->VERSION <= version->parse( '4.023' ) );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
}

sub STORABLE_freeze { return( shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { return( shift->THAW( @_ ) ); }

# NOTE: CBOR will call the THAW method with the stored classname as first argument, the constant string CBOR as second argument, and all values returned by FREEZE as remaining arguments.
# NOTE: Storable calls it with a blessed object it created followed with $cloning and any other arguments initially provided by STORABLE_freeze
sub THAW
{
    my( $self, undef, @args ) = @_;
    my $ref = ( CORE::scalar( @args ) == 1 && CORE::ref( $args[0] ) eq 'ARRAY' ) ? CORE::shift( @args ) : \@args;
    my $class = ( CORE::defined( $ref ) && CORE::ref( $ref ) eq 'ARRAY' && CORE::scalar( @$ref ) > 1 ) ? CORE::shift( @$ref ) : ( CORE::ref( $self ) || $self );
    my $hash = CORE::ref( $ref ) eq 'ARRAY' ? CORE::shift( @$ref ) : {};
    my $new;
    # Storable pattern requires to modify the object it created rather than returning a new one
    if( CORE::ref( $self ) )
    {
        foreach( CORE::keys( %$hash ) )
        {
            $self->{ $_ } = CORE::delete( $hash->{ $_ } );
        }
        $new = $self;
    }
    else
    {
        $new = CORE::bless( $hash => $class );
    }
    CORE::return( $new );
}

sub TO_JSON { return( shift->as_string ); }

{
    # NOTE: Locale::Unicode::Data::NullObject class
    package
        Locale::Unicode::Data::NullObject;
    BEGIN
    {
        use strict;
        use warnings;
        use overload (
            '""'    => sub{ '' },
            fallback => 1,
        );
        use Want;
    };
    use strict;
    use warnings;

    sub new
    {
        my $this = shift( @_ );
        my $ref = @_ ? { @_ } : {};
        return( bless( $ref => ( ref( $this ) || $this ) ) );
    }

    sub AUTOLOAD
    {
        my( $method ) = our $AUTOLOAD =~ /([^:]+)$/;
        my $self = shift( @_ );
        if( Want::want( 'OBJECT' ) )
        {
            rreturn( $self );
        }
        # Otherwise, we return undef; Empty return returns undef in scalar context and empty list in list context
        return;
    };
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Locale::Unicode::Data - Unicode CLDR SQL Data

=head1 SYNOPSIS

    use Locale::Unicode::Data;
    my $cldr = Locale::Unicode::Data->new;
    # Do not decode SQL arrays into perl arrays. Defaults to true
    # This uses JSON::XS
    my $cldr = Locale::Unicode::Data->new( decode_sql_arrays => 0 );
    my $datetime = $cldr->cldr_built;
    my $str = $cldr->cldr_maintainer;
    my $version = $cldr->cldr_version;
    my $dbh = $cldr->database_handler;
    my $sqlite_db_file = $cldr->datafile;
    my $bool = $cldr->decode_sql_arrays;
    # Deactivate automatic SQL arrays decoding
    $cldr->decode_sql_arrays(0);
    my $tree = $cldr->make_inheritance_tree( 'ja-JP' );
    # ['ja-JP', 'ja', 'und']
    my $tree = $cldr->make_inheritance_tree( 'es-Latn-001-valencia' );
    # ['es-Latn-001-valencia', 'es-Latn-001', 'es-Latn', 'es', 'und']
    # But...
    my $tree = $cldr->make_inheritance_tree( 'pt-FR' );
    # Because exceptionally, the parent of 'pt-FR' is not 'pt', but 'pt-PT'
    # ['pt-FR', 'pt-PT', 'pt', 'und']
    my $ref = $cldr->split_interval(
        pattern => "E, MMM d, y – E, MMM d, y G",
        greatest_diff => 'y',
    );
    # ["E, MMM d, y", " – ", "E, MMM d, y G", "E, MMM d, y"]

    my $ref = $cldr->alias(
        alias => 'fro',
        type  => 'subdivision',
    ); # For 'Hauts-de-France'
    my $all = $cldr->aliases;
    # 'type' can be one of territory, language, zone, subdivision, variant, script
    my $all = $cldr->aliases( type => 'territory' );
    my $ref = $cldr->annotation( annotation => '{', locale => 'en' );
    my $all = $cldr->annotations;
    # Get all annotations for locale 'en'
    my $all = $cldr->annotations( locale => 'en' );
    my $ref = $cldr->bcp47_currency( currid => 'jpy' );
    my $all = $cldr->bcp47_currencies;
    my $all = $cldr->bcp47_currencies( code => 'JPY' );
    # Get all obsolete BCP47 currencies
    my $all = $cldr->bcp47_currencies( is_obsolete => 1 );
    my $ref = $cldr->bcp47_extension( extension => 'ca' );
    my $all = $cldr->bcp47_extensions;
    # Get all deprecated BCP47 extensions
    my $all = $cldr->bcp47_extensions( deprecated => 1 );
    my $ref = $cldr->bcp47_timezone( tzid => 'jptyo' );
    my $all = $cldr->bcp47_timezones;
    # Get all deprecated BCP47 timezones
    my $all = $cldr->bcp47_timezones( deprecated => 1 );
    # Returns information about Japanese Imperial calendar
    my $ref = $cldr->bcp47_value( value => 'japanese' );
    my $all = $cldr->bcp47_timezones;
    # Get all the BCP47 values for the category 'calendar'
    my $all = $cldr->bcp47_values( category => 'calendar' );
    my $all = $cldr->bcp47_values( extension => 'ca' );
    my $ref = $cldr->calendar( calendar => 'gregorian' );
    my $all = $cldr->calendars;
    # Known 'system' value: undef, lunar, lunisolar, other, solar
    my $all = $cldr->calendars( system => 'solar' );
    my $ref = $cldr->calendar_append_format(
        locale      => 'en',
        calendar    => 'gregorian',
        format_id   => 'Day',
    );
    my $all = $cldr->calendar_append_formats;
    my $all = $cldr->calendar_append_formats(
        locale      => 'en',
        calendar    => 'gregorian',
    );
    my $ref = $cldr->calendar_available_format(
        locale      => 'en',
        calendar    => 'gregorian',
        format_id   => 'Hms',
        count       => undef,
        alt         => undef,
    );
    my $all = $cldr->calendar_available_formats;
    my $all = $cldr->calendar_available_formats( locale => 'en', calendar => 'gregorian' );
    my $ref = $cldr->calendar_cyclic_l10n(
        locale          => 'und',
        calendar        => 'chinese',
        format_set      => 'dayParts',
        format_type     => 'format',
        format_length   => 'abbreviated',
        format_id       => 1,
    );
    my $all = $cldr->calendar_cyclics_l10n;
    my $all = $cldr->calendar_cyclics_l10n( locale => 'en' );
    my $all = $cldr->calendar_cyclics_l10n(
        locale          => 'en',
        calendar        => 'chinese',
        format_set      => 'dayParts',
        # Not really needed since 'format' is the only value being currently used
        # format_type   => 'format',
        format_length   => 'abbreviated',
    );
    my $all = $cldr->calendar_datetime_formats;
    my $all = $cldr->calendar_datetime_formats(
        locale      => 'en',
        calendar    => 'gregorian',
    );
    my $ref = $cldr->calendar_era(
        calendar => 'japanese',
        sequence => 236,
    ); # Current era 'reiwa'
    my $ref = $cldr->calendar_era(
        calendar => 'japanese',
        code => 'reiwa',
    ); # Current era 'reiwa'
    my $all = $cldr->calendar_eras;
    my $all = $cldr->calendar_eras( calendar => 'hebrew' );
    my $ref = $cldr->calendar_format_l10n(
        locale => 'en',
        calendar => 'gregorian',
        format_type => 'date',
        format_length => 'full',
        format_id => 'yMEEEEd',
    );
    my $ref = $cldr->calendar_era_l10n(
        locale => 'ja',
        calendar => 'gregorian',
        era_width => 'abbreviated',
        alt => undef,
        era_id => 0,
    );
    my $array_ref = $cldr->calendar_eras_l10n;
    # Filter based on the 'locale' field value
    my $array_ref = $cldr->calendar_eras_l10n( locale => 'en' );
    # Filter based on the 'calendar' field value
    my $array_ref = $cldr->calendar_eras_l10n( calendar => 'gregorian' );
    # or a combination of multiple fields:
    my $array_ref = $cldr->calendar_eras_l10n(
        locale => 'en',
        calendar => 'gregorian',
        era_width => 'abbreviated',
        alt => undef
    );
    my $ref = $cldr->calendar_format_l10n(
        locale => 'en',
        calendar => 'gregorian',
        # date, time
        format_type => 'date',
        # full, long, medium, short
        format_length => 'full',
        format_id => 'yMEEEEd',
    );
    my $all = $cldr->calendar_formats_l10n;
    my $all = $cldr->calendar_formats_l10n(
        locale      => 'en',
        calendar    => 'gregorian',
    );
    my $all = $cldr->calendar_formats_l10n(
        locale => 'en',
        calendar => 'gregorian',
        format_type => 'date',
        format_length => 'full',
    );
    my $ref = $cldr->calendar_interval_format(
        locale              => 'en',
        calendar            => 'gregorian',
        greatest_diff_id    => 'd',
        format_id           => 'GyMMMEd',
        alt                 => undef,
    );
    my $all = $cldr->calendar_interval_formats;
    my $all = $cldr->calendar_interval_formats(
        locale      => 'en',
        calendar    => 'gregorian',
    );
    my $ref = $cldr->calendar_term(
        locale          => 'und',
        calendar        => 'gregorian',
        # format, stand-alone
        term_context    => 'format',
        # abbreviated, narrow, wide
        term_width      => 'abbreviated',
        term_name       => 'am',
    );
    my $array_ref = $cldr->calendar_terms;
    my $array_ref = $cldr->calendar_terms(
        locale => 'und',
        calendar => 'japanese'
    );
    my $array_ref = $cldr->calendar_terms(
        locale          => 'und',
        calendar        => 'gregorian',
        term_type       => 'day',
        term_context    => 'format',
        term_width      => 'abbreviated',
    );
    my $ref = $cldr->casing( locale => 'fr', token => 'currencyName' );
    my $all = $cldr->casings;
    my $all = $cldr->casings( locale => 'fr' );
    my $ref = $cldr->code_mapping( code => 'US' );
    my $all = $cldr->code_mappings;
    my $all = $cldr->code_mappings( type => 'territory' );
    my $all = $cldr->code_mappings( type => 'currency' );
    my $all = $cldr->code_mappings( alpha3 => 'USA' );
    my $all = $cldr->code_mappings( numeric => 840 ); # U.S.A.
    my $all = $cldr->code_mappings( numeric => [">835", "<850"] ); # U.S.A.
    my $all = $cldr->code_mappings( fips => 'JP' ); # Japan
    my $all = $cldr->code_mappings( fips => undef, type => 'currency' );
    my $ref = $cldr->collation( collation => 'ducet' );
    my $all = $cldr->collations;
    my $all = $cldr->collations( description => qr/Chinese/ );
    my $ref = $cldr->collation_l10n( locale => 'en', collation => 'ducet' );
    my $all = $cldr->collations_l10n( locale => 'en' );
    my $all = $cldr->collations_l10n( locale => 'ja', locale_name => qr/中国語/ );
    my $ref = $cldr->currency( currency => 'JPY' ); # Japanese Yen
    my $all = $cldr->currencies;
    my $all = $cldr->currencies( is_obsolete => 1 );
    my $ref = $cldr->currency_info( territory => 'FR', currency => 'EUR' );
    my $all = $cldr->currencies_info;
    my $all = $cldr->currencies_info( territory => 'FR' );
    my $all = $cldr->currencies_info( currency => 'EUR' );
    my $ref = $cldr->currency_l10n(
        locale      => 'en',
        count       => undef,
        currency    => 'JPY',
    );
    my $all = $cldr->currencies_l10n;
    my $all = $cldr->currencies_l10n( locale => 'en' );
    my $all = $cldr->currencies_l10n(
        locale      => 'en',
        currency    => 'JPY',
    );
    my $ref = $cldr->date_field_l10n(
        locale          => 'en',
        field_type      => 'day',
        field_length    => 'narrow',
        relative        => -1,
    );
    my $all = $cldr->date_fields_l10n;
    my $all = $cldr->date_fields_l10n( locale => 'en' );
    my $all = $cldr->date_fields_l10n(
        locale          => 'en',
        field_type      => 'day',
        field_length    => 'narrow',
    );
    my $ref = $cldr->day_period( locale => 'fr', day_period => 'noon' );
    my $all = $cldr->day_periods;
    my $all = $cldr->day_periods( locale => 'ja' );
    # Known values for day_period: afternoon1, afternoon2, am, evening1, evening2, 
    # midnight, morning1, morning2, night1, night2, noon, pm
    my $all = $cldr->day_periods( day_period => 'noon' );
    my $ids = $cldr->interval_formats(
        locale => 'en',
        calendar => 'gregorian',
    );
    # Retrieve localised information for certain type of data
    # Possible types are: annotation, calendar_append_format, calendar_available_format, 
    # calendar_cyclic, calendar_era, calendar_format, calendar_interval_formats, 
    # calendar_term, casing, currency, date_field, locale, number_format, number_symbol
    # script, subdivision, territory, unit, variant
    my $ref = $cldr->l10n(
        type => 'annotation',
        locale => 'en',
        annotation => '{',
    );
    my $ref = $cldr->l10n(
        # or just 'append'
        type => 'calendar_append_format',
        locale => 'en',
        calendar => 'gregorian',
        format_id => 'Day',
    );
    my $ref = $cldr->l10n(
        # or just 'available'
        type => 'calendar_available_format',
        locale => 'ja',
        calendar => 'japanese',
        format_id => 'GyMMMEEEEd',
    );
    my $ref = $cldr->l10n(
        # or just 'cyclic'
        type => 'calendar_cyclic',
        locale => 'ja',
        calendar => 'chinese',
        format_set => 'dayParts',
        # 1..12
        format_id => 1,
    );
    # Retrieve the information on current Japanese era (Reiwa)
    my $ref = $cldr->l10n(
        # or just 'era'
        type => 'calendar_era',
        locale => 'ja',
        calendar => 'japanese',
        # abbreviated, narrow
        # 'narrow' contains less data than 'abbreviated'
        era_width => 'abbreviated',
        era_id => 236,
    );
    my $ref = $cldr->l10n(
        type => 'calendar_format',
        locale => 'ja',
        calendar => 'gregorian',
        format_id => 'yMEEEEd',
    );
    my $ref = $cldr->l10n(
        # or just 'interval'
        type => 'calendar_interval_format',
        locale => 'ja',
        calendar => 'gregorian',
        format_id => 'yMMM',
    );
    my $ref = $cldr->l10n(
        type => 'calendar_term',
        locale => 'ja',
        calendar => 'gregorian',
        term_name => 'mon',
    );
    my $ref = $cldr->l10n(
        type => 'casing',
        locale => 'fr',
        token => 'currencyName',
    );
    my $ref = $cldr->l10n(
        type => 'currency',
        locale => 'ja',
        currency => 'EUR',
    );
    my $ref = $cldr->l10n(
        # or just 'field'
        type => 'date_field',
        locale => 'ja',
        # Other possible values:
        # day, week, month, quarter, year, hour, minute, second,
        # mon, tue, wed, thu, fri, sat, sun
        field_type  => 'day',
        # -1 for yesterday, 0 for today, 1 for tomorrow
        relative => -1,
    );
    my $ref = $cldr->l10n(
        type => 'locale',
        locale => 'ja',
        locale_id => 'fr',
    );
    my $ref = $cldr->l10n(
        type => 'number_format',
        locale => 'ja',
        number_type => 'currency',
        format_id => '10000',
    );
    my $ref = $cldr->l10n(
        # or just 'symbol'
        type => 'number_symbol',
        locale => 'en',
        number_system => 'latn',
        property => 'decimal',
    );
    my $ref = $cldr->l10n(
        type => 'script',
        locale => 'ja',
        script => 'Kore',
    );
    my $ref = $cldr->l10n(
        type => 'subdivision',
        locale => 'en',
        subdivision => 'jp13', # Tokyo
    );
    my $ref = $cldr->l10n(
        type => 'territory',
        locale => 'en',
        territory => 'JP', # Japan
    );
    my $ref = $cldr->l10n(
        type => 'unit',
        locale => 'en',
        unit_id => 'power3',
    );
    my $ref = $cldr->l10n(
        type => 'variant',
        locale => 'en',
        variant => 'valencia',
    );
    my $ref = $cldr->language( language => 'ryu' ); # Central Okinawan (Ryukyu)
    my $all = $cldr->languages;
    my $all = $cldr->languages( parent => 'gmw' );
    my $all = $cldr->language_population( territory => 'JP' );
    my $all = $cldr->language_populations;
    my $all = $cldr->language_populations( official_status => 'official' );
    my $ref = $cldr->likely_subtag( locale => 'ja' );
    my $all = $cldr->likely_subtags;
    my $ref = $cldr->locale( locale => 'ja' );
    my $all = $cldr->locales;
    my $ref = $cldr->locale_l10n(
        locale      => 'en',
        locale_id   => 'ja',
        alt         => undef,
    );
    my $all = $cldr->locales_l10n;
    # Returns an array reference of all locale information in English
    my $all = $cldr->locales_l10n( locale => 'en' );
    # Returns an array reference of all the way to write 'Japanese' in various languages
    # This would typically return an array reference of something like 267 hash reference
    my $all = $cldr->locales_l10n( locale_id => 'ja' );
    # This is basically the same as with the method locale_l10n()
    my $all = $cldr->locales_l10n(
        locale      => 'en',
        locale_id   => 'ja',
        alt         => undef,
    );
    my $ref = $cldr->locales_info( property => 'quotation_start', locale => 'ja' );
    my $all = $cldr->locales_infos;
    my $ref = $cldr->metazone( metazone => 'Japan' );
    my $all = $cldr->metazones;
    my $ref = $cldr->number_format_l10n(
        locale          => 'en',
        number_system   => 'latn',
        number_type     => 'currency',
        format_length   => 'short',
        format_type     => 'standard',
        alt             => undef,
        count           => 'one',
        format_id       => 1000,
    );
    my $all = $cldr->number_formats_l10n;
    my $all = $cldr->number_formats_l10n( locale => 'en' );
    my $all = $cldr->number_formats_l10n(
        locale          => 'en',
        number_system   => 'latn',
        number_type     => 'currency',
        format_length   => 'short',
        format_type     => 'standard',
    );
    my $ref = $cldr->number_symbol_l10n(
        locale          => 'en',
        number_system   => 'latn',
        property        => 'decimal',
        alt             => undef,
    );
    my $all = $cldr->number_symbols_l10n;
    my $all = $cldr->number_symbols_l10n( locale => 'en' );
    my $all = $cldr->number_symbols_l10n(
        locale          => 'en',
        number_system   => 'latn',
    );
    # See also using rbnf
    my $ref = $cldr->number_system( number_system => 'jpan' );
    my $all = $cldr->number_systems;
    my $ref = $cldr->person_name_default( locale => 'ja' );
    my $all = $cldr->person_name_defaults;
    my $ref = $cldr->rbnf(
        locale  => 'ja',
        ruleset => 'spellout-cardinal',
        rule_id => 7,
    );
    my $all = $cldr->rbnfs;
    my $all = $cldr->rbnfs( locale => 'ko' );
    my $all = $cldr->rbnfs( grouping => 'SpelloutRules' );
    my $all = $cldr->rbnfs( ruleset => 'spellout-cardinal-native' );
    my $ref = $cldr->reference( code => 'R1131' );
    my $all = $cldr->references;
    my $ref = $cldr->script( script => 'Jpan' );
    my $all = $cldr->scripts;
    # 'rtl' ('right-to-left' writing orientation)
    my $all = $cldr->scripts( rtl => 1 );
    my $all = $cldr->scripts( origin_country => 'FR' );
    my $all = $cldr->scripts( likely_language => 'fr' );
    my $ref = $cldr->script_l10n(
        locale  => 'en',
        script   => 'Latn',
        alt     => undef,
    );
    my $all = $cldr->scripts_l10n;
    my $all = $cldr->scripts_l10n( locale => 'en' );
    my $all = $cldr->scripts_l10n(
        locale  => 'en',
        alt     => undef,
    );
    my $ref = $cldr->subdivision( subdivision => 'jp12' );
    my $all = $cldr->subdivisions;
    my $all = $cldr->subdivisions( territory => 'JP' );
    my $all = $cldr->subdivisions( parent => 'US' );
    my $all = $cldr->subdivisions( is_top_level => 1 );
    my $ref = $cldr->subdivision_l10n(
        locale      => 'en',
        # Texas
        subdivision => 'ustx',
    );
    my $all = $cldr->subdivisions_l10n;
    my $all = $cldr->subdivisions_l10n( locale => 'en' );
    my $ref = $cldr->territory( territory => 'FR' );
    my $all = $cldr->territories;
    my $all = $cldr->territories( parent => 150 );
    my $ref = $cldr->territory_l10n(
        locale      => 'en',
        territory   => 'JP',
        alt         => undef,
    );
    my $all = $cldr->territories_l10n;
    my $all = $cldr->territories_l10n( locale => 'en' );
    my $all = $cldr->territories_l10n(
        locale  => 'en',
        alt     => undef,
    );
    my $ref = $cldr->time_format( region => 'JP' );
    my $all = $cldr->time_formats;
    my $all = $cldr->time_formats( region => 'US' );
    my $all = $cldr->time_formats( territory => 'JP' );
    my $all = $cldr->time_formats( locale => undef );
    my $all = $cldr->time_formats( locale => 'en' );
    my $ref = $cldr->timezone( timezone => 'Asia/Tokyo' );
    my $all = $cldr->timezones;
    my $all = $cldr->timezones( territory => 'US' );
    my $all = $cldr->timezones( region => 'Asia' );
    my $all = $cldr->timezones( tzid => 'sing' );
    my $all = $cldr->timezones( tz_bcpid => 'sgsin' );
    my $all = $cldr->timezones( metazone => 'Singapore' );
    my $all = $cldr->timezones( is_golden => undef );
    my $all = $cldr->timezones( is_golden => 1 );
    my $all = $cldr->timezones( is_primary => 1 );
    my $all = $cldr->timezones( is_canonical => 1 );
    my $ref = $cldr->timezone_city(
        locale => 'fr',
        timezone => 'Asia/Tokyo',
    );
    my $all = $cldr->timezones_cities;
    my $ref = $cldr->timezone_info(
        timezone    => 'Asia/Tokyo',
        start       => undef,
    );
    my $ref = $cldr->timezone_info(
        timezone    => 'Europe/Simferopol',
        start       => ['>1991-01-01', '<1995-01-01'],
    );
    my $all = $cldr->timezones_info;
    my $all = $cldr->timezones_info( metazone => 'Singapore' );
    my $all = $cldr->timezones_info( start => undef );
    my $all = $cldr->timezones_info( until => undef );
    my $ref = $cldr->unit_alias( alias => 'meter-per-second-squared' );
    my $all = $cldr->unit_aliases;
    my $ref = $cldr->unit_constant( constant => 'lb_to_kg' );
    my $all = $cldr->unit_constants;
    my $ref = $cldr->unit_conversion( source => 'kilogram' );
    my $all = $cldr->unit_conversions;
    my $all = $cldr->unit_conversions( base_unit => 'kilogram' );;
    my $all = $cldr->unit_conversions( category => 'kilogram' );
    my $ref = $cldr->unit_l10n(
        locale          => 'en',
        # long, narrow, short
        format_length   => 'long',
        # compound, regular
        unit_type       => 'regular',
        unit_id         => 'length-kilometer',
        count           => 'one',
        gender          => undef,
        gram_case       => undef,
    );
    my $all = $cldr->units_l10n;
    my $all = $cldr->units_l10n( locale => 'en' );
    my $all = $cldr->units_l10n(
        locale          => 'en',
        format_length   => 'long',
        unit_type       => 'regular',
        unit_id         => 'length-kilometer',
        pattern_type    => 'regular',
    );
    my $ref = $cldr->unit_prefix( unit_id => 'micro' );
    my $all = $cldr->unit_prefixes;
    my $ref = $cldr->unit_pref( unit_id => 'square-meter' );
    my $all = $cldr->unit_prefs;
    my $all = $cldr->unit_prefs( territory => 'US' );
    my $all = $cldr->unit_prefs( category => 'area' );
    my $ref = $cldr->unit_quantity( base_unit => 'kilogram' );
    my $all = $cldr->unit_quantities;
    my $all = $cldr->unit_quantities( quantity => 'mass' );
    my $ref = $cldr->variant( variant => 'valencia' );
    my $all = $cldr->variants;
    my $ref = $cldr->variant_l10n(
        locale  => 'en',
        alt     => undef,
        variant => 'valencia',
    );
    my $all = $cldr->variants_l10n;
    my $all = $cldr->variants_l10n( locale => 'en' );
    my $all = $cldr->variants_l10n(
        locale  => 'en',
        alt     => undef,
    );
    my $ref = $cldr->week_preference( locale => 'ja' );
    my $all = $cldr->week_preferences;

With advanced search:

    my $all = $cldr->timezone_info(
        timezone => 'Europe/Simferopol',
        start => ['>1991-01-01','<1995-01-01'],
    );
    my $all = $cldr->time_formats(
        region => '~^U.*',
    );
    my $all = $cldr->time_formats(
        region => qr/^U.*/,
    );

Enabling fatal exceptions:

    use v5.34;
    use experimental 'try';
    no warnings 'experimental';
    try
    {
        my $locale = Locale::Unicode::Data->new( fatal => 1 );
        # Missing the 'width' argument
        my $str = $cldr->timezone_names( timezone => 'Asia/Tokyo', locale => 'en' );
        # More code
    }
    catch( $e )
    {
        say "Oops: ", $e->message;
    }

Or, you could set the global variable C<$FATAL_EXCEPTIONS> instead:

    use v5.34;
    use experimental 'try';
    no warnings 'experimental';
    $Locale::Unicode::Data::FATAL_EXCEPTIONS = 1;
    try
    {
        my $locale = Locale::Unicode::Data->new;
        # Missing the 'width' argument
        my $str = $cldr->timezone_names( timezone => 'Asia/Tokyo', locale => 'en' );
        # More code
    }
    catch( $e )
    {
        say "Oops: ", $e->message;
    }

=head1 VERSION

    v1.4.0

=head1 DESCRIPTION

C<Locale::Unicode::Data> provides access to all the data from the Unicode L<CLDR|https://cldr.unicode.org/> (Common Locale Data Repository), using a SQLite database. This is the most extensive up-to-date L<CLDR|https://cldr.unicode.org/> data you will find on C<CPAN>. It is provided as SQLite data with a great many number of methods to access those data and make it easy for you to retrieve them. Thanks to SQLite, it is very fast.

SQLite version C<3.6.19> (2009-10-14) or higher is required, as this module relies on foreign keys, which were not fully supported before. If the version is anterior, the module will return an error upon object instantiation.

It is designed to be extensive in the scope of data that can be accessed, while at the same time, memory-friendly. Access to each method returns data from the SQLite database on a need-basis.

All the data in this SQLite database are sourced directly and exclusively from the Unicode official L<CLDR|https://cldr.unicode.org/> data using a perl script available in this distribution under the C<scripts> directory. Use C<perldoc scripts/create_database.pl> or C<scripts/create_database.pl --man> to access its POD documentation.

The C<CLDR> data includes, by design, outdated ones, such as outdated currencies, country codes, or timezones, that C<CLDR> keeps in order to ensure consistency and reliability. For example, for timezones, the Unicode C<LDML> (Locale Data Markup Language) states that "CLDR contains locale data using a time zone ID from the tz database as the key, stability of the IDs is critical." and "Not all TZDB links are in CLDR aliases. CLDR purposefully does not exactly match the Link structure in the TZDB.". See L<https://unicode.org/reports/tr35/#Time_Zone_Identifiers>

In C<CLDR> parlance, a L<language|https://unicode.org/reports/tr35/tr35.html#Unicode_language_identifier> is a 2 to 3-characters identifier, whereas a C<locale> includes more information, such as a C<language>, a C<script>, a C<territory>, a C<variant>, and possibly much more information. See for that the L<Locale::Unicode> module and the L<LDML specifications|https://unicode.org/reports/tr35/tr35.html#Unicode_language_identifier>

Those locales also inherit data from their respective parents. For example, C<sr-Cyrl-ME> would have the following inheritance tree: C<sr-ME>, C<sr>, and C<und>

You can build a C<locale> inheritance tree using L<make_inheritance_tree|/make_inheritance_tree>, and I recommend L<Locale::Unicode> to build, parse and manipulate locales.

Also, in those C<CLDR> data, there is not always a one-to-one match across all territories (countries) or languages, meaning that some territories or languages have more complete C<CLDR> data than others.

C<CLDR> also uses some default values to avoid repetitions. Those default values are stored in the C<World> territory with code C<001> and special C<language> code C<und> (a.k.a. C<unknown> also referred as C<root>)

Please note that the SQLite database is built to not be case sensitive in line with the C<LDML> specifications.

This module documentation is not meant to be a replacement for the Unicode C<LDML> (C<Locale Data Markup Language>) documentation, so please make sure to read L<the LDML documentation|https://unicode.org/reports/tr35/> and the L<CLDR specifications|https://cldr.unicode.org/index/cldr-spec>.

The data available from the C<CLDR> via this module includes:

=over 4

=item * ISO 4217 L<currencies|/"Table currencies">, including L<BCP47 currencies|/"Table bcp47_currencies">, their L<localised names|/"Table currencies_l10n"> and their L<associated country historical usage|/"Table currencies_info">.

=item * L<Calendar IDs|/"Table calendars"> with description in English

=item * L<Calendar eras|/"Table calendar_eras">, for some calendar systems, such as the C<japanese> one.

=item * L<Territories|/"Table territories"> (countries, or world regions)

This includes, for countries, additional information such as C<GDP> (Gross Domestic Product), literacy percentage, population size, languages spoken, possible other ISO 3166 codes contained by this territory (essentially world regions identified as 3-digits code, or special codes like C<EU> or C<UN>), the official currency, a list of calendar IDs (not always available for all territories), the first day of the week, the first and last day of the week-end

=item * L<Localised territory names|/"Table territories_l10n">

This provides the name of a C<territory> for a given C<locale>

=item * Territories L<currencies history|/"Table currencies_info">

=item * All L<known locales|/"Table locales">

This includes the C<locale> status, which may be C<regular>, C<deprecated>, C<special>, C<reserved>, C<private_use>, or C<unknown>

=item * Localised L<names of locales|/"Table locales_l10n">

This provides the name of a C<locale> for a given C<locale>

=item * All L<known languages|/"Table languages">

This may include its associated C<scripts> and C<territories>, and its C<parent> language, if any.

Its status may be C<regular>, C<deprecated>, C<special>, C<reserved>, C<private_use>, or C<unknown>

=item * All L<known scripts|/"Table scripts">

This includes possibly the C<script> ID, its rank, a sample character, line break letter, whether it is right-to-left direction, if it has casing, if it requires shapping, its density, possibly its origin territory and its likely locale.

=item * L<Localised scripts|/"Table scripts_l10n">

This provides the name of a C<script> for a given C<locale>

=item * All L<known variants|/"Table variants">

This includes the C<variant> status, which may be C<regular>, C<deprecated>, C<special>, C<reserved>, C<private_use>, or C<unknown>

=item * L<Localised variants|/"Table variants_l10n">

This provides the name of a C<variant> for a given C<locale>

=item * L<Time formats|/"Table time_formats">

This includes the associated C<territory> and C<locale>, the default time format, such as C<H> and the time allowed.

=item * L<Language population|/"Table language_population">

This provides information for a given C<territory> and C<locale> about the percentage of the population using that C<locale>, their literacy percentage, and percentage of the population using in writing the C<locale>, and its official status, which may be C<official>, C<de_facto_official>, and C<official_regional>

=item * L<Likely subtags|/"Table likely_subtags">

This provides for a given C<locale> the likely target locale to expand to.

=item * L<Aliases|/"Table aliases">

This provides aliases for C<languages>, C<scripts>, C<territories>, C<subdivisions>, C<variants>, and C<timezones>

=item * L<Time zones|/"Table timezones">

This provides IANA Olson time zones, but also some other time zones, such as C<Etc/GMT>. The CLDR data also includes former time zones for consistency and stability.

The information includes possibly the associated C<territory>, the C<region> such as C<America> or C<Europe>, the time zone ID, such as C<japa>, a meta zone, such as C<Europe_Central>, a BCP47 time zone ID, and a boolean value whether the time zone is a C<golden> time zone or not.

=item * L<Time zone information|/"Table timezones_info">

This provides historical time zone information, such as when it started and ended.

=item * L<Subdivisions|/"Table subdivisions">

Subdivisions are parts of a territory, such as a province like in Canada, a department like in France or a prefecture like in Japan.

The information here includes a C<subdivision> ID, possibly a C<parent>, a boolean whether this is a top level subdivision for the given territory, and a status, which may be C<regular>, C<deprecated>, C<special>, C<reserved>, C<private_use>, or C<unknown>

=item * L<Localised subdivisions|/"Table subdivisions_l10n">

This contains the name of a C<subdivision> for a given C<locale>

=item * L<Numbering systems|"Table number_systems">

This provides information about numbering systems, including the numbering system ID, the digits from C<0> to C<9>

=item * L<Week preference|/Table week_preferences">

This contains the week ordering preferences for a given C<locale>. Possible values are: C<weekOfYear>, C<weekOfDate>, C<weekOfMonth>

=item * L<Day periods|/"Table day_periods">

This contains the time representation of day period ID, such as C<midnight>, C<noon>, C<morning1>, C<morning2>, C<afternoon1>, C<afternoon2>, C<evening1>, C<evening2>, C<night1>, C<night2> with values in hour and minute, such as C<12:00> set in a C<start> and C<until> field.

=item * L<Code mappings|/"Table code_mappings">

This serves to map territory or currency codes with their well known equivalent in ISO and U.S. standard (FIPS10)

=item * L<Person name defaults|/"Table person_name_defaults">

This specifies, for a given C<locale>, whether a person's given name comes first before the surname, or after.

=item * L<References|/"Table refs">

This contains all the references behind the CLDR data.

=item * L<BCP47 time zones|/"Table bcp47_timezones">

This contains BCP 47 time zones along with possible aliases and preferred time zone

=item * L<BCP47 currencies|/"Table bcp47_currencies">

This includes the currency ID, an ISO 4217 code, description and a boolean value whether it is obsolete or not.

=item * L<BCP47 extensions|/"Table bcp47_extensions">

This contains the extension category, extension ID, possibly alias, value type and description, and whether it is deprecated,

=item * L<BCP47 extension values|/"Table bcp47_values">

This includes an extension category, and extension ID, an extension value and description.

=item * L<Annotations|/"Table annotations">

This provide annotations (single character like a symbol or an emoji) and default short description for a given C<locale>

=item * L<RBNF (Rule-Based Number Format)|/"Table rbnf">

This provides RBNF rules with its grouping value, such as C<SpelloutRules> or C<OrdinalRules>, the rule set ID such as C<spellout-numbering-year> or C<spellout-cardinal>, the rule ID such as C<Inf> and the rule value.

=item * L<Casings|/"Table casings">

This provides information about casing for a given C<locale>

It includes the C<locale>, a C<token> such as C<currencyName>, C<language> and a C<value>, such as C<lowercase>, C<titlecase>

=item * L<Localised calendar terms|/"Table calendar_terms">

This provides localised terms used in different parts of a calendar system, for a given C<locale> and C<calendar> ID.

=item * L<Localised calendar eras|/"Table calendar_eras">

This provides the localised era names for a given C<locale> and C<calendar> ID.

=item * Localised L<calendar date, time|/"Table calendar_datetime_formats"> and L<interval formattings|/"Table calendar_interval_formats">

This provides the C<CLDR> C<DateTime> formattings for a given C<locale> and C<calendar> ID.

=item * L<Language matching|/"Table languages_match">

This provides a matching between a desired C<locale> and what is actually supported, and a C<distance> factor, which designed to be the opposite of a percentage, by Unicode. The desired C<locale> can be a perl regular expression.

=item * Unit L<constants|/"Table unit_constants">

Some constant values declared for certain measurement units.

=item * L<Unit quantities|/"Table unit_quantities">

Defines the quantity type for certain units.

=item * L<Unit conversions|/"Table unit_conversions">

Define a list of unit conversion from one unit to another.

=item * L<Unit preferences by territories|/unit_prefs">

Defines what units are preferred by territory.

=item * L<Unit aliases|/"Table unit_aliases">

Provides some aliases for otherwise outdated units.

=item * L<Localised units|/"Table units_l10n">

Localised unit formatting.

=item * Locale L<Number symbols|/"Table number_symbols_l10n">

Value used for each locale for C<approximately>, C<currency_decimal>, C<currency_group>, C<decimal>, C<exponential>, C<group>, C<infinity>, C<list>, C<minus>, C<nan>, C<per_mille>, C<percent>, C<plus>, C<superscript>, and C<time_separator>

Not every C<locale> has a value for each of those properties though.

=item * L<Locale number formatting|/"Table number_formats_l10n">

Localised formatting for currency or decimal numbers.

=back

If you need a more granular access to the data, feel free to access the SQL data directly. You can retrieve a L<database handler|/database_handler>, as an instance of the L<DBI> API, or you can instantiate a connection yourself using the L<database file information|/datafile>

=head1 CONSTRUCTOR

=head2 new

This takes some hash or hash reference of options, instantiates a new L<Locale::Unicode::Data> object, connects to the SQLite database file specified, or the default one, and returns the newly instantiated object.

If an error occurred, an L<error object|Locale::Unicode::Data::Exception> is created and C<undef> is returned in scalar context, or an empty list in list context.

Supported options are as follows. Each option can be later accessed or modified by their associated method.

=over 4

=item * C<datafile>

The file path to the SQLite database file. If this option is not provided, the SQLite database file used will be the one set in the global variable C<$DB_FILE>

=item * C<decode_sql_arrays>

Boolean value to enable or disable automatic decoding of SQL arrays into perl arrays using L<JSON::XS>

This is enabled by default.

If you want to retrieve a lot of data and do not need access to those arrays, you should deactivate decoding to improve speed.

=back

If an error occurs, an L<exception object|Locale::Unicode::Data::Exception> is set and C<undef> is returned in scalar context, or an empty list in list context. The L<exception object|Locale::Unicode::Data::Exception> can then be retrieved using L<error|/error>, such as:

    my $cldr = Locale::Unicode::Data->new( $somthing_bad ) ||
        die( Locale::Unicode::Data->error );

=head1 METHODS

=head2 alias

    my $ref = $cldr->alias(
        alias => 'i_klingon',
        type  => 'language',
    );

This would return an hash reference containing:

    {
        alias_id    => 5,
        alias       => 'i_klingon',
        replacement => ["tlh"],
        reason      => 'deprecated',
        type        => 'language',
        comment     => 'Klingon',
    }

Returns the C<language>, C<script>, C<territory>, C<subdivision>, C<variant>, or C<zone> aliases stored in table L<aliases|/"Table aliases"> for a given C<alias> and an alias C<type>.

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-info.html#Supplemental_Alias_Information> for more information.

The meaning of the fields are as follows:

=over 4

=item * C<alias_id>

A unique incremental value provided by SQLite.

=item * C<alias>

The original value.

=item * C<replacement>

The replacement value for the C<alias>

=item * C<reason>

Reason for the replacement.

Known reasons are C<bibliographic>, C<deprecated>, C<legacy>, C<macrolanguage>, C<overlong>

=item * C<type>

The type of alias.

There are 6 types of aliases:

=over 4

=item 1. C<language>

=item 2. C<script>

=item 3. C<subdivision>

=item 4. C<territory>

=item 5. C<variant>

=item 6. C<zone>

=back

=item * C<comment>

A possible comment

=back

=head2 aliases

    my $array_ref = $cldr->aliases;
    # Filtering based on type
    my $array_ref = $cldr->aliases( type => 'language' );
    my $array_ref = $cldr->aliases( type => 'script' );
    my $array_ref = $cldr->aliases( type => 'subdivision' );
    my $array_ref = $cldr->aliases( type => 'territory' );
    my $array_ref = $cldr->aliases( type => 'variant' );
    my $array_ref = $cldr->aliases( type => 'zone' );

Returns all the data stored in table L<aliases|/"Table aliases"> as an array reference of hash reference.

If an C<type> option is provided, it will return only all the data matching the given C<type>.

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-info.html#Supplemental_Alias_Information> for more information.

=head2 annotation

    my $ref = $cldr->annotation( locale => 'en', annotation => '{' );
    # Returns an hash reference like this:
    {
        annotation_id   => 34686,
        locale          => 'en',
        annotation      => '{',
        defaults        => ["brace", "bracket", "curly brace", "curly bracket", "gullwing", "open curly bracket"],
        tts             => 'open curly bracket',
    }

Returns an hash reference of a C<annotation> information from the table L<annotations|/"Table annotations"> for a given C<locale> ID, and C<annotation> value.

As per the L<LDML specifications|https://unicode.org/reports/tr35/tr35-general.html#Annotations>, "Annotations provide information about characters, typically used in input. For example, on a mobile keyboard they can be used to do completion. They are typically used for symbols, especially emoji characters."

The meaning of the fields are as follows:

=over 4

=item * C<annotation_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale> ID as can be found in the table L<locales|/"Table locales">

=item * C<annotation>

A string representing the C<annotation>

=item * C<defaults>

An array of short strings describing the annotation in the language specified by the C<locale>

=item * C<tts>

A short string describing the C<annotation>

=back

=head2 annotations

    my $array_ref = $cldr->annotations;
    # Get all annotations for locale 'en'
    my $array_ref = $cldr->annotations( locale => 'en' );

Returns all annotations information for all known locales from the L<table annotations|/"Table annotations"> as an array reference of hash reference.

Alternatively, you can provide a C<locale> to return all annotation information for that C<locale>

=head2 bcp47_currency

    my $ref = $cldr->bcp47_currency( currid => 'jpy' );
    # Returns an hash reference like this:
    {
        bcp47_curr_id   => 133,
        currid          => 'jpy',
        code            => 'JPY',
        description     => 'Japanese Yen',
        is_obsolete     => 0,
    }

Returns an hash reference of a BCP47 currency information from the table L<bcp47_currencies|/"Table bcp47_currencies"> for a given BCP47 currency ID C<currid>.

The meaning of the fields are as follows:

=over 4

=item * C<bcp47_curr_id>

A unique incremental value automatically generated by SQLite.

=item * C<currid>

A string representing a BCP47 C<currency> ID.

=item * C<code>

A string representing a ISO 4217 C<currency> code, which could be outdated by the ISO standard, but still valid for C<CLDR>

=item * C<description>

A text describing the C<currency>

=item * C<is_obsolete>

A boolean value defining whether the C<currency> is obsolete or not. Default to false.

=back

=head2 bcp47_currencies

    my $array_ref = $cldr->bcp47_currencies;
    # Filtering based on ISO4217 currency code
    my $array_ref = $cldr->bcp47_currencies( code => 'JPY' );
    # Filtering based on obsolete status: 1 = true, 0 = false
    my $array_ref = $cldr->bcp47_currencies( is_obsolete => 1 );

Returns all BCP47 currencies information from L<table bcp47_currencies|/"Table bcp47_currencies"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<code>

An ISO4217 currency code, such as C<JPY>

=item * C<is_obsolete>

A boolean value. Use 1 for C<true> and 0 for C<false>

=back

=head2 bcp47_extension

    my $ref = $cldr->bcp47_extension( extension => 'ca' );
    # Returns an hash reference like this:
    {
        bcp47_ext_id    => 1,
        category        => 'calendar',
        extension       => 'ca',
        alias           => 'calendar',
        value_type      => 'incremental',
        description     => 'Calendar algorithm key',
    }

Returns an hash reference of a L<BCP47 extension|https://unicode.org/reports/tr35/tr35.html#u_Extension> information from the table L<bcp47_extensions|/"Table bcp47_extensions"> for a given BCP47 extension.

The meaning of the fields are as follows:

=over 4

=item * C<bcp47_ext_id>

A unique incremental value automatically generated by SQLite.

=item * C<category>

A string representing a BCP47 extension category.

Known values are: C<calendar>, C<collation>, C<currency>, C<measure>, C<number>, C<segmentation>, C<timezone>, C<transform>, C<transform_destination>, C<transform_hybrid>, C<transform_ime>, C<transform_keyboard>, C<transform_mt>, C<transform_private_use>, C<variant>

=item * C<extension>

A short string representing a BCP47 extension.

Known values are: C<ca>, C<cf>, C<co>, C<cu>, C<d0>, C<dx>, C<em>, C<fw>, C<h0>, C<hc>, C<i0>, C<k0>, C<ka>, C<kb>, C<kc>, C<kf>, C<kh>, C<kk>, C<kn>, C<kr>, C<ks>, C<kv>, C<lb>, C<lw>, C<m0>, C<ms>, C<mu>, C<nu>, C<rg>, C<s0>, C<sd>, C<ss>, C<t0>, C<tz>, C<va>, C<vt>, C<x0>

=item * C<alias>

A string representing an alias for this extension.

Known values are: C<undef>, C<calendar>, C<colAlternate>, C<colBackwards>, C<colCaseFirst>, C<colCaseLevel>, C<colHiraganaQuaternary>, C<collation>, C<colNormalization>, C<colNumeric>, C<colReorder>, C<colStrength>, C<currency>, C<hours>, C<measure>, C<numbers>, C<timezone>, C<variableTop>

=item * C<value_type>

A string representing a value type.

Known values are: C<undef>, C<any>, C<incremental>, C<multiple>, C<single>

=item * C<description>

A text providing a description for this BCP47 extension.

=back

=head2 bcp47_extensions

    my $array_ref = $cldr->bcp47_extensions;
    # Filter based on the 'extension' field value
    my $array_ref = $cldr->bcp47_extensions( extension => 'ca' );
    # Filter based on the 'deprecated' field value; 1 = true, 0 = false
    my $array_ref = $cldr->bcp47_extensions( deprecated => 0 );

Returns all L<BCP47 extensions|https://unicode.org/reports/tr35/tr35.html#u_Extension> information from L<table bcp47_extensions|/"Table bcp47_extensions"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<deprecated>

A boolean value. Use 1 for C<true> and 0 for C<false>

=item * C<extension>

A BCP47 extension, such as C<ca>, C<cf>, C<co>, C<cu>, C<d0>, C<dx>, C<em>, C<fw>, C<h0>, C<hc>, C<i0>, C<k0>, C<ka>, C<kb>, C<kc>, C<kf>, C<kh>, C<kk>, C<kn>, C<kr>, C<ks>, C<kv>, C<lb>, C<lw>, C<m0>, C<ms>, C<mu>, C<nu>, C<rg>, C<s0>, C<sd>, C<ss>, C<t0>, C<tz>, C<va>, C<vt>, C<x0>

=back

=head2 bcp47_timezone

    my $ref = $cldr->bcp47_timezone( tzid => 'jptyo' );
    # Returns an hash reference like this:
    {
        bcp47_tz_id => 215,
        tzid        => 'jptyo',
        alias       => ["Asia/Tokyo", "Japan"],
        preferred   => undef,
        description => 'Tokyo, Japan',
        deprecated  => undef,
    }

Returns an hash reference of a BCP47 timezone information from the table L<bcp47_timezones|/"Table bcp47_timezones"> for a given BCP47 timezone ID C<tzid>.

The meaning of the fields are as follows:

=over 4

=item * C<bcp47_tz_id>

A unique incremental value automatically generated by SQLite.

=item * C<tzid>

A string representing a BCP47 timezone ID.

=item * C<alias>

An array of L<IANA Olson timezones|https://www.iana.org/time-zones>

=item * C<preferred>

An string representing a preferred BCP47 timezone ID in lieu of the current one.

This is mostly C<undef>

=item * C<description>

A text describing the BCP47 timezone

=item * C<deprecated>

A boolean value defining whether this timezone is deprecated or not. Defaults to false.

=back

=head2 bcp47_timezones

    my $array_ref = $cldr->bcp47_timezones;
    # Filter based on the 'deprecated' field value; 1 = true, 0 = false
    my $array_ref = $cldr->bcp47_timezones( deprecated => 0 );

Returns all BCP47 timezones information from L<table bcp47_timezones|/"Table bcp47_timezones"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<deprecated>

A boolean value. Use 1 for C<true> and 0 for C<false>

=back

=head2 bcp47_value

    my $ref = $cldr->bcp47_value( value => 'japanese' );
    # Returns an hash reference like this:
    {
        bcp47_value_id  => 16,
        category        => 'calendar',
        extension       => 'ca',
        value           => 'japanese',
        description     => 'Japanese Imperial calendar',
    }

Returns an hash reference of a BCP47 value information from the table L<bcp47_values|/"Table bcp47_values"> for a given BCP47 value.

The meaning of the fields are as follows:

=over 4

=item * C<bcp47_value_id>

A unique incremental value automatically generated by SQLite.

=item * C<category>

A string representing a BCP47 value category.

Known values are: C<calendar>, C<collation>, C<currency>, C<measure>, C<number>, C<segmentation>, C<timezone>, C<transform>, C<transform_destination>, C<transform_hybrid>, C<transform_ime>, C<transform_keyboard>, C<transform_mt>, C<transform_private_use>, C<variant>

=item * C<extension>

A short string representing a BCP47 extension.

Known values are: C<ca>, C<cf>, C<co>, C<cu>, C<d0>, C<dx>, C<em>, C<fw>, C<h0>, C<hc>, C<i0>, C<k0>, C<ka>, C<kb>, C<kc>, C<kf>, C<kh>, C<kk>, C<kn>, C<kr>, C<ks>, C<kv>, C<lb>, C<lw>, C<m0>, C<ms>, C<mu>, C<nu>, C<rg>, C<s0>, C<sd>, C<ss>, C<t0>, C<tz>, C<va>, C<vt>, C<x0>

=item * C<value>

Possible value for the current BCP47 extension. One C<extension> may have multiple possible values.

=item * C<description>

A text describing the BCP47 extension value.

=back

=head2 bcp47_values

    my $array_ref = $cldr->bcp47_values;
    # Filter based on the 'category' field value
    my $array_ref = $cldr->bcp47_timezones( category => 'calendar' );
    # Filter based on the 'extension' field value
    my $array_ref = $cldr->bcp47_timezones( extension => 'ca' );

Returns all BCP47 values information from L<table bcp47_values|/"Table bcp47_values"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<category>

A BCP47 category ID, such as C<calendar>, C<collation>, C<currency>, C<measure>, C<number>, C<segmentation>, C<timezone>, C<transform_destination>, C<transform>, C<transform_hybrid>, C<transform_ime>, C<transform_keyboard>, C<transform_mt>, C<transform_private_use>, C<variant>

=item * C<extension>

A BCP47 extension ID, such as C<ca>, C<cf>, C<co>, C<cu>, C<d0>, C<dx>, C<em>, C<fw>, C<h0>, C<hc>, C<i0>, C<k0>, C<ka>, C<kb>, C<kc>, C<kf>, C<kh>, C<kk>, C<kn>, C<kr>, C<ks>, C<kv>, C<lb>, C<lw>, C<m0>, C<ms>, C<mu>, C<nu>, C<rg>, C<s0>, C<sd>, C<ss>, C<t0>, C<tz>, C<va>, C<vt>, C<x0>

=back

=head2 calendar

    my $ref = $cldr->calendar( calendar => 'gregorian' );
    # Returns an hash reference like this:
    {
        calendar_id => 1,
        calendar    => 'gregorian',
        system      => 'solar',
        inherits    => undef,
        description => undef,
    }

Returns an hash reference of a calendar information from the table L<calendars|/"Table calendars"> for a given C<calendar> value.

The meaning of the fields are as follows:

=over 4

=item * C<calendar_id>

A unique incremental value automatically generated by SQLite.

=item * C<calendar>

A string representing a C<calendar> ID.

Known calendar IDs are: C<buddhist>, C<chinese>, C<coptic>, C<dangi>, C<ethiopic>, C<ethiopic-amete-alem>, C<generic>, C<gregorian>, C<hebrew>, C<indian>, C<islamic>, C<islamic-civil>, C<islamic-rgsa>, C<islamic-tbla>, C<islamic-umalqura>, C<iso8601>, C<japanese>, C<persian>, C<roc>

=item * C<system>

A string representing a C<calendar> system.

Known values are: C<undef>, C<lunar>, C<lunisolar>, C<other>, C<solar>

=item * C<inherits>

A string representing the C<calendar> ID from which this calendar inherits from.

Currently, the only one known to use this is the C<japanese> calendar inheriting from the C<gregorian> calendar.

=item * C<description>

A text describing the C<calendar>

=back

=head2 calendars

    my $array_ref = $cldr->calendars;
    # Known 'system' value: undef, lunar, lunisolar, other, solar
    my $array_ref = $cldr->calendars( system => 'solar' );
    my $array_ref = $cldr->calendars( inherits => 'gregorian' );

Returns all calendar information from L<table calendars|/"Table calendars"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<inherits>

A calendar system this calendar inherits from, such as the Japanese calendar.

=item * C<system>

A calendar system, such as C<lunar>, C<lunisolar>, C<other>, C<solar>

=back

=head2 calendar_append_format

    my $ref = $cldr->calendar_append_format(
        locale      => 'en',
        calendar    => 'gregorian',
        format_id   => 'Day',
    );
    # Returns an hash reference like this:
    {
        cal_append_fmt_id   => 12,
        locale              => 'en',
        calendar            => 'gregorian',
        format_id           => 'Day',
        format_pattern      => '{0} ({2}: {1})',
    }

Returns an hash reference of a C<calendar> localised append format information from the table L<calendar_append_formats|/"Table calendar_append_formats"> for a given format ID C<format_id>, C<locale> ID and C<calendar> ID.

The meaning of the fields are as follows:

=over 4

=item * C<cal_append_fmt_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<calendar>

A C<calendar> ID as can be found in the L<table calendars|/"Table calendars">

Known values are: C<buddhist>, C<chinese>, C<coptic>, C<dangi>, C<ethiopic>, C<ethiopic-amete-alem>, C<generic>, C<gregorian>, C<hebrew>, C<indian>, C<islamic>, C<islamic-civil>, C<islamic-rgsa>, C<islamic-tbla>, C<islamic-umalqura>, C<japanese>, C<persian>, C<roc>

=item * C<format_id>

A string representing a format ID.

Known values are: C<Day>, C<Day-Of-Week>, C<Era>, C<Hour>, C<Minute>, C<Month>, C<Quarter>, C<Second>, C<Timezone>, C<Week>, C<Year>

=item * C<format_pattern>

A string representing the localised format pattern.

=back

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#availableFormats_appendItems> for more information.

=head2 calendar_append_formats

    my $array_ref = $cldr->calendar_append_formats;
    # Filter based on the 'locale' field value
    my $array_ref = $cldr->calendar_append_formats( locale => 'en' );
    # Filter based on the 'calendar' field value
    my $array_ref = $cldr->calendar_append_formats( calendar => 'gregorian' );
    # or a combination of those two:
    my $array_ref = $cldr->calendar_append_formats(
        locale => 'en',
        calendar => 'gregorian'
    );

Returns all calendar appended formats information from L<table calendar_append_formats|/"Table calendar_append_formats"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<calendar>

A C<calendar> ID as can be found in table L<calendars|/"Table calendars">, such as: C<buddhist>, C<chinese>, C<coptic>, C<dangi>, C<ethioaa>, C<ethiopic>, C<gregory>, C<hebrew>, C<indian>, C<islamic>, C<islamic-civil>, C<islamic-rgsa>, C<islamic-tbla>, C<islamic-umalqura>, C<islamicc>, C<iso8601>, C<japanese>, C<persian>, C<roc>

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=back

See also the method L<l10n|/l10n>

=head2 calendar_available_format

    my $ref = $cldr->calendar_available_format(
        locale      => 'en',
        calendar    => 'gregorian',
        format_id   => 'Hms',
        # optional
        count       => undef,
        # optional
        alt         => undef,
    );
    # Returns an hash reference like this:
    {
        cal_avail_fmt_id    => 2662,
        locale              => 'en',
        calendar            => 'gregorian',
        format_id           => 'Hms',
        format_pattern      => 'HH:mm:ss',
        count               => undef,
        alt                 => undef,
    }

Returns an hash reference of a C<calendar> localised available format information from the table L<calendar_available_formats|/"Table calendar_available_formats"> for a given format ID C<format_id>, C<calendar> ID and a C<locale> ID.

The meaning of the fields are as follows:

=over 4

=item * C<cal_avail_fmt_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<calendar>

A C<calendar> ID as can be found in the L<table calendars|/"Table calendars">

Known values are: C<buddhist>, C<chinese>, C<coptic>, C<dangi>, C<ethiopic>, C<ethiopic-amete-alem>, C<generic>, C<gregorian>, C<hebrew>, C<indian>, C<islamic>, C<islamic-civil>, C<islamic-rgsa>, C<islamic-tbla>, C<islamic-umalqura>, C<japanese>, C<persian>, C<roc>

=item * C<format_id>

A string representing a format ID.

There are currently 107 known and distinct format IDs.

=item * C<format_pattern>

A string representing a localised format pattern.

=item * C<count>

An optional string used to differentiate identical patterns.

Known values are: C<undef>, C<few>, C<many>, C<one>, C<other>, C<two>, C<zero>

=item * C<alt>

An optional string used to provide alternative patterns.

Known values are: C<undef>, C<ascii>, C<variant>

=back

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#availableFormats_appendItems> for more informations.

=head2 calendar_available_formats

    my $array_ref = $cldr->calendar_available_formats;
    # Filter based on the 'locale' field value
    my $array_ref = $cldr->calendar_available_formats( locale => 'en' );
    # Filter based on the 'calendar' field value
    my $array_ref = $cldr->calendar_available_formats( calendar => 'gregorian' );
    # or a combination of those two:
    my $array_ref = $cldr->calendar_available_formats(
        locale => 'en',
        calendar => 'gregorian',
    );

Returns all calendar available formats information from L<table calendar_available_formats|/"Table calendar_available_formats"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<calendar>

A C<calendar> ID as can be found in table L<calendars|/"Table calendars">, such as: C<buddhist>, C<chinese>, C<coptic>, C<dangi>, C<ethioaa>, C<ethiopic>, C<gregory>, C<hebrew>, C<indian>, C<islamic>, C<islamic-civil>, C<islamic-rgsa>, C<islamic-tbla>, C<islamic-umalqura>, C<islamicc>, C<iso8601>, C<japanese>, C<persian>, C<roc>

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=back

See also the method L<l10n|/l10n>

=head2 calendar_cyclic_l10n

    my $ref = $cldr->calendar_cyclic_l10n(
        locale          => 'und',
        calendar        => 'chinese',
        format_set      => 'dayParts',
        format_type     => 'format',
        format_length   => 'abbreviated',
        format_id       => 1,
    );
    # Returns an hash reference like this:
    {
        cal_int_fmt_id  => 1014,
        locale          => 'und',
        calendar        => 'chinese',
        format_set      => 'dayParts',
        format_type     => 'format',
        format_length   => 'abbreviated',
        format_id       => 1,
        format_pattern  => 'zi',
    }

Returns an hash reference of a C<calendar> cyclic localised information from the table L<calendar_cyclics_l10n|/"Table calendar_cyclics_l10n"> for a given format ID C<format_id>, ID a C<locale> ID, a C<calendar> ID, a format set C<format_set>, a format type C<format_type> and a format length C<format_length>.

This is typical of calendars such as: C<chinese> and C<dangi>

The meaning of the fields are as follows:

=over 4

=item * C<cal_int_fmt_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<calendar>

A C<calendar> ID as can be found in the L<table calendars|/"Table calendars">

Known values are: C<buddhist>, C<chinese>, C<coptic>, C<dangi>, C<ethiopic>, C<ethiopic-amete-alem>, C<generic>, C<gregorian>, C<hebrew>, C<indian>, C<islamic>, C<islamic-civil>, C<islamic-rgsa>, C<islamic-tbla>, C<islamic-umalqura>, C<japanese>, C<persian>, C<roc>

=item * C<format_set>

A format set. Known values are: C<dayParts>, C<days>, C<months>, C<solarTerms>, C<years>, C<zodiacs>

=item * C<format_type>

A format type. The only known value is C<format>

=item * C<format_length>

A format length.

Known values are; C<abbreviated>, C<narrow>, C<wide>

=item * C<format_id>

A string representing a format ID.

=item * C<format_pattern>

A string representing a localised pattern.

=back

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#monthPatterns_cyclicNameSets> for more information.

=head2 calendar_cyclics_l10n

    my $all = $cldr->calendar_cyclics_l10n;
    my $all = $cldr->calendar_cyclics_l10n( locale => 'en' );
    my $all = $cldr->calendar_cyclics_l10n(
        locale          => 'en',
        calendar        => 'chinese',
        format_set      => 'dayParts',
        # Not really needed since 'format' is the only value being currently used
        # format_type   => 'format',
        format_length   => 'abbreviated',
    );

Returns all C<calendar> cyclic localised formats information from L<table calendar_cyclics_l10n|/"Table calendar_cyclics_l10n"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<calendar>

A C<calendar> ID as can be found in table L<calendars|/"Table calendars">, such as: C<buddhist>, C<chinese>, C<coptic>, C<dangi>, C<ethioaa>, C<ethiopic>, C<gregory>, C<hebrew>, C<indian>, C<islamic>, C<islamic-civil>, C<islamic-rgsa>, C<islamic-tbla>, C<islamic-umalqura>, C<islamicc>, C<iso8601>, C<japanese>, C<persian>, C<roc>

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<format_set>

A string representing a format set.

Known values are: C<dayParts>, C<days>, C<months>, C<solarTerms>, C<years>, C<zodiacs>

=item * C<format_type>

A format type. The only known value is C<format>

=item * C<format_length>

A format length.

Known values are; C<abbreviated>, C<narrow>, C<wide>

=back

=head2 calendar_datetime_format

    my $ref = $cldr->calendar_datetime_format(
        locale          => 'en',
        calendar        => 'gregorian',
        format_length   => 'full',
        format_type     => 'atTime',
    );
    # Returns an hash reference like this:
    {
        cal_dt_fmt_id   => 434,
        locale          => 'en',
        calendar        => 'gregorian',
        format_length   => 'full',
        format_type     => 'atTime',
        format_pattern  => "{1} 'at' {0}",
    }

Returns an hash reference of a C<calendar> localised datetime format information from the table L<calendar_datetime_formats|/"Table calendar_datetime_formats"> for a given C<locale> ID, C<calendar> ID, C<format_length>, and C<format_type>.

The meaning of the fields are as follows:

=over 4

=item * C<cal_dt_fmt_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<calendar>

A C<calendar> ID as can be found in the L<table calendars|/"Table calendars">

Known values are: C<buddhist>, C<chinese>, C<coptic>, C<dangi>, C<ethiopic>, C<ethiopic-amete-alem>, C<generic>, C<gregorian>, C<hebrew>, C<indian>, C<islamic>, C<islamic-civil>, C<islamic-rgsa>, C<islamic-tbla>, C<islamic-umalqura>, C<japanese>, C<persian>, C<roc>

=item * C<format_length>

A string representing a format length.

Known values are: C<full>, C<long>, C<medium>, C<short>

=item * C<format_type>

A string representing a format type.

Known values are: C<atTime>, C<standard>

=item * C<format_pattern>

A string representing a localised datetime format pattern according to the format type and C<locale>

=back

=head2 calendar_datetime_formats

    my $array_ref = $cldr->calendar_datetime_formats;
    # Filter based on the 'locale' field value
    my $array_ref = $cldr->calendar_datetime_formats( locale => 'en' );
    # Filter based on the 'calendar' field value
    my $array_ref = $cldr->calendar_datetime_formats( calendar => 'gregorian' );
    # or a combination of those two:
    my $array_ref = $cldr->calendar_datetime_formats(
        locale => 'en',
        calendar => 'gregorian',
    );

Returns all calendar datetime formats information from L<table calendar_datetime_formats|/"Table calendar_datetime_formats"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<calendar>

A C<calendar> ID as can be found in table L<calendars|/"Table calendars">, such as: C<buddhist>, C<chinese>, C<coptic>, C<dangi>, C<ethioaa>, C<ethiopic>, C<gregory>, C<hebrew>, C<indian>, C<islamic>, C<islamic-civil>, C<islamic-rgsa>, C<islamic-tbla>, C<islamic-umalqura>, C<islamicc>, C<iso8601>, C<japanese>, C<persian>, C<roc>

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=back

See also the method L<l10n|/l10n>

=head2 calendar_era_l10n

    my $ref = $cldr->calendar_era_l10n(
        locale => 'ja',
        calendar => 'gregorian',
        era_width => 'abbreviated',
        alt => undef,
        era_id => 0,
    );
    # Returns an hash reference like this:
    {
        cal_era_l10n_id => 2844,
        locale          => 'ja',
        calendar        => 'gregorian',
        era_width       => 'abbreviated',
        era_id          => 0,
        alt             => undef,
        locale_name     => '紀元前',
    }

Returns an hash reference of a calendar era information from the table L<calendar_eras_l10n|/"Table calendar_eras_l10n"> for a given C<calendar> value, a C<locale>, a C<era_width>, and a C<era_id>. If no C<alt> value is provided, it will default to C<undef>

The meaning of the fields are as follows:

=over 4

=item * C<cal_era_l10n_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<calendar>

A C<calendar> ID as can be found in the L<table calendars|/"Table calendars">

Known values used are: C<buddhist>, C<coptic>, C<ethiopic>, C<ethiopic-amete-alem>, C<generic>, C<gregorian>, C<hebrew>, C<indian>, C<islamic>, C<japanese>, C<persian>, C<roc>

=item * C<era_width>

An era width.

Known values are: C<abbreviated>, C<narrow>, C<wide>

=item * C<era_id>

A string representing an era ID. This is actually always an integer with minimum value of C<0> and maximum value of C<99>

=item * C<alt>

A string to provide an alternative value for an era with the same ID.

=item * C<locale_name>

A string providing with a localised name for this era for the current C<locale>

=back

=head2 calendar_eras_l10n

    my $array_ref = $cldr->calendar_eras_l10n;
    # Filter based on the 'locale' field value
    my $array_ref = $cldr->calendar_eras_l10n( locale => 'en' );
    # Filter based on the 'calendar' field value
    my $array_ref = $cldr->calendar_eras_l10n( calendar => 'gregorian' );
    # or a combination of multiple fields:
    my $array_ref = $cldr->calendar_eras_l10n(
        locale => 'en',
        calendar => 'gregorian',
        era_width => 'abbreviated',
        alt => undef
    );

Returns all calendar localised eras information from L<table calendar_eras_l10n|/"Table calendar_eras_l10n"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<alt>

The alternative value, if any, which may be C<variant> or C<undef>, i.e., no value.

=item * C<calendar>

A C<calendar> ID as can be found in table L<calendars|/"Table calendars">, such as: C<buddhist>, C<chinese>, C<coptic>, C<dangi>, C<ethioaa>, C<ethiopic>, C<gregory>, C<hebrew>, C<indian>, C<islamic>, C<islamic-civil>, C<islamic-rgsa>, C<islamic-tbla>, C<islamic-umalqura>, C<islamicc>, C<iso8601>, C<japanese>, C<persian>, C<roc>

=item * C<era_width>

Possible values are: C<abbreviated>, C<narrow>, C<wide>

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=back

See also the method L<l10n|/l10n>

=head2 calendar_format_l10n

    my $ref = $cldr->calendar_format_l10n(
        locale => 'ja',
        calendar => 'gregorian',
        # date, time
        format_type => 'date',
        # full, long, medium, short
        format_length => 'full',
    );
    # Returns an hash reference like this:
    {
        cal_fmt_l10n_id => 906,
        locale          => 'ja',
        calendar        => 'gregorian',
        format_type     => 'date',
        format_length   => 'full',
        alt             => undef,
        format_id       => 'yMEEEEd',
        format_pattern  => 'y年M月d日EEEE',
    }

Returns an hash reference of a calendar format information from the table L<calendar_formats_l10n|/"Table calendar_formats_l10n"> for a given C<calendar> value, a C<locale>, a C<format_type>, and a C<format_length>.

The meaning of the fields are as follows:

=over 4

=item * C<cal_fmt_l10n_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<calendar>

A C<calendar> ID as can be found in the L<table calendars|/"Table calendars">

Known values are: C<buddhist>, C<chinese>, C<coptic>, C<dangi>, C<ethiopic>, C<ethiopic-amete-alem>, C<generic>, C<gregorian>, C<hebrew>, C<indian>, C<islamic>, C<islamic-civil>, C<islamic-rgsa>, C<islamic-tbla>, C<islamic-umalqura>, C<japanese>, C<persian>, C<roc>

=item * C<format_type>

A string representing a format type.

Possible values are: C<date> or C<time>

=item * C<format_length>

A string representing a format length.

Known values are: C<full>, C<long>, C<medium>, C<short>

=item * C<alt>

A string to provide an alternative value for a format with the same ID.

=item * C<format_id>

A string representing a format ID.

=item * C<format_pattern>

A string representing a localised pattern.

=back

=head2 calendar_formats_l10n

    my $array_ref = $cldr->calendar_formats_l10n;
    # Filter based on the 'locale' field value
    my $array_ref = $cldr->calendar_formats_l10n( locale => 'en' );
    # Filter based on the 'calendar' field value
    my $array_ref = $cldr->calendar_formats_l10n( calendar => 'gregorian' );
    # or a combination of multiple fields:
    my $array_ref = $cldr->calendar_formats_l10n(
        locale => 'en',
        calendar => 'gregorian',
        format_type => 'date',
        format_length => 'full',
    );

Returns all calendar localised date and time formats information from L<table calendar_formats_l10n|/"Table calendar_formats_l10n"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<calendar>

A C<calendar> ID as can be found in table L<calendars|/"Table calendars">, such as: C<buddhist>, C<chinese>, C<coptic>, C<dangi>, C<ethioaa>, C<ethiopic>, C<gregory>, C<hebrew>, C<indian>, C<islamic>, C<islamic-civil>, C<islamic-rgsa>, C<islamic-tbla>, C<islamic-umalqura>, C<islamicc>, C<iso8601>, C<japanese>, C<persian>, C<roc>

=item * C<format_length>

Possible values are: C<full>, C<long>, C<medium>, C<short>

=item * C<format_type>

The format type, which may be C<date> or C<time>

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=back

See also the method L<l10n|/l10n>

=head2 calendar_interval_format

    my $ref = $cldr->calendar_interval_format(
        locale              => 'en',
        calendar            => 'gregorian',
        greatest_diff_id    => 'd',
        format_id           => 'GyMMMEd',
        alt                 => undef,
    );
    # Returns an hash reference like this:
    {
        cal_int_fmt_id      => 3846,
        locale              => 'en',
        calendar            => 'gregorian',
        format_id           => 'GyMMMEd',
        greatest_diff_id    => 'd',
        format_pattern      => 'E, MMM d – E, MMM d, y G',
        alt                 => undef,
        part1               => 'E, MMM d',
        separator           => ' – ',
        part2               => 'E, MMM d, y G',
        repeating_field     => 'E, MMM d',
    }

Returns an hash reference of a C<calendar> localised interval information from the table L<calendar_interval_formats|/"Table calendar_interval_formats"> for a given C<calendar> ID and a C<locale> ID. If no C<alt> value is provided, it will default to C<undef>

Pay particular attention to the fields C<part1>, C<separator> and C<part2> that are designed to greatly make it easy for you to format and use the interval format pattern.

Without those special fields, it would not be possible to properly format an interval.

The meaning of the fields are as follows:

=over 4

=item * C<cal_int_fmt_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<calendar>

A C<calendar> ID as can be found in the L<table calendars|/"Table calendars">

Known values are: C<buddhist>, C<chinese>, C<coptic>, C<dangi>, C<ethiopic>, C<ethiopic-amete-alem>, C<generic>, C<gregorian>, C<hebrew>, C<indian>, C<islamic>, C<islamic-civil>, C<islamic-rgsa>, C<islamic-tbla>, C<islamic-umalqura>, C<japanese>, C<persian>, C<roc>

=item * C<format_id>

A string representing a format ID.

=item * C<greatest_diff_id>

A string representing an ID, itself representing the L<interval greatest difference|https://unicode.org/reports/tr35/tr35-dates.html#intervalFormats>

=item * C<format_pattern>

A string representing a localised pattern.

=item * C<alt>

A string representing an alternative value.

=item * C<part1>

This is the first part of the interval format.

=item * C<separator>

This is the string representing the separator between the first and second part.

=item * C<part2>

This is the second part of the interval format.

=item * C<repeating_field>

This is the repeating field that was computed when building this database.

This, along with the C<part1>, C<separator> and C<part2> are designed to make it easier for you to format the interval.

=back

See L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#intervalFormats> for more information.

=head2 calendar_interval_formats

    my $array_ref = $cldr->calendar_interval_formats;
    # Filter based on the 'locale' field value
    my $array_ref = $cldr->calendar_interval_formats( locale => 'en' );
    # Filter based on the 'calendar' field value
    my $array_ref = $cldr->calendar_interval_formats( calendar => 'gregorian' );
    # or a combination of those two:
    my $array_ref = $cldr->calendar_interval_formats(
        locale      => 'en',
        calendar    => 'gregorian',
    );

Returns all calendar interval formats information from L<table calendar_interval_formats|/"Table calendar_interval_formats"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<calendar>

A C<calendar> ID as can be found in table L<calendars|/"Table calendars">, such as: C<buddhist>, C<chinese>, C<coptic>, C<dangi>, C<ethioaa>, C<ethiopic>, C<gregory>, C<hebrew>, C<indian>, C<islamic>, C<islamic-civil>, C<islamic-rgsa>, C<islamic-tbla>, C<islamic-umalqura>, C<islamicc>, C<iso8601>, C<japanese>, C<persian>, C<roc>

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<greatest_diff_id>

A string representing an ID, itself representing the L<interval greatest difference|https://unicode.org/reports/tr35/tr35-dates.html#intervalFormats>

=back

See also the method L<l10n|/l10n>

=head2 calendar_l10n

    my $ref = $cldr->calendar_l10n(
        locale => 'en',
        caendar => 'japanese',
    );
    # Returns an hash reference like:
    {
        calendar_l10n_id => 506,
        locale => 'en',
        calendar => 'japanese',
        locale_name => 'Japanese Calendar',
    }

Returns an hash reference of a calendar localised information from the table L<calendars_l10n|/"Table calendars_l10n"> for a given C<locale> ID, and C<calendar> ID.

The meaning of the fields are as follows:

=over 4

=item * C<calendar_l10n_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<calendar>

A C<calendar> ID as can be found in the L<table calendars|/"Table calendars">

Known values are: C<buddhist>, C<chinese>, C<coptic>, C<dangi>, C<ethiopic>, C<ethiopic-amete-alem>, C<generic>, C<gregorian>, C<hebrew>, C<indian>, C<islamic>, C<islamic-civil>, C<islamic-rgsa>, C<islamic-tbla>, C<islamic-umalqura>, C<japanese>, C<persian>, C<roc>

=item * C<locale_name>

A string representing the localised name of the calendar.

=back

=head2 calendars_l10n

    my $all = $cldr->calendars_l10n;
    my $all = $cldr->calendars_l10n(
        locale => 'en',
    );

Returns all calendar localised information from L<table calendars_l10n|/"Table calendars_l10n"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=back

=head2 calendar_term

    my $ref = $cldr->calendar_term(
        locale          => 'und',
        calendar        => 'gregorian',
        # format, stand-alone
        term_context    => 'format',
        # abbreviated, narrow, wide
        term_width      => 'abbreviated',
        term_name       => 'am',
    );
    # Returns an hash reference like:
    {
        cal_term_id     => 23478,
        locale          => 'und',
        calendar        => 'gregorian',
        term_type       => 'day_period',
        term_context    => 'format',
        term_width      => 'abbreviated',
        alt             => undef,
        yeartype        => undef,
        term_name       => 'am',
        term_value      => 'AM',
    }

Returns an hash reference of a calendar term information from the table L<calendar_terms|/"Table calendar_terms"> for a given C<locale>, C<calendar>, C<term_context>, C<term_width>, C<term_name> value, C<alt> and C<yeartype> value. If no C<alt> or C<yeartype> value is provided, it will default to C<undef>

You can also query for multiple value at the same time, and this will return an array reference of hash reference instead:

    my $all = $cldr->calendar_term(
        locale          => 'und',
        calendar        => 'gregorian',
        # format, stand-alone
        term_context    => 'format',
        # abbreviated, narrow, wide
        term_width      => 'abbreviated',
        term_name       => [qw( am pm )],
    );
    # Returns an array reference like:
    [
        {
            cal_term_id     => 23478,
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
        {
            cal_term_id     => 23479,
            locale          => 'und',
            calendar        => 'gregorian',
            term_type       => 'day_period',
            term_context    => 'format',
            term_width      => 'abbreviated',
            alt             => undef,
            yeartype        => undef,
            term_name       => 'pm',
            term_value      => 'PM',
        },
    ]

See the section on L</"Advanced Search"> for more information.

The meaning of the fields are as follows:

=over 4

=item * C<cal_term_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<calendar>

A C<calendar> ID as can be found in the L<table calendars|/"Table calendars">

Known values are: C<buddhist>, C<chinese>, C<coptic>, C<dangi>, C<ethiopic>, C<ethiopic-amete-alem>, C<generic>, C<gregorian>, C<hebrew>, C<indian>, C<islamic>, C<islamic-civil>, C<islamic-rgsa>, C<islamic-tbla>, C<islamic-umalqura>, C<japanese>, C<persian>, C<roc>

=item * C<term_type>

A string representing a term type.

Known values are: C<day>, C<day_period>, C<month>, C<quarter>

=item * C<term_context>

A string representing a term context.

Known values are: C<format>, C<stand-alone>

=item * C<term_width>

A string representing a term width.

Known values are: C<abbreviated>, C<narrow>, C<short>, C<wide>

=item * C<alt>

A string to provide an alternate representation of a term.

=item * C<yeartype>

A string to provide an alternate representation of a term when this is a leap year.

The usual value for this is C<leap>

=item * C<term_name>

A string representing a term name.

Known values are: C<1>, C<2>, C<3>, C<4>, C<5>, C<6>, C<7>, C<8>, C<9>, C<10>, C<11>, C<12>, C<13>, C<afternoon1>, C<afternoon2>, C<evening1>, C<evening2>, C<midnight>, C<morning1>, C<morning2>, C<night1>, C<night2>, C<noon>, C<am>, C<pm>, C<mon>, C<tue>, C<wed>, C<thu>, C<fri>, C<sat>, C<sun>

=item * C<term_value>

A string representing the term value.

=back

See also the L<Unicode LDMD specifications|https://unicode.org/reports/tr35/tr35-dates.html#months_days_quarters_eras>

=head2 calendar_terms

    my $array_ref = $cldr->calendar_terms;
    my $array_ref = $cldr->calendar_terms(
        locale => 'und',
        calendar => 'japanese'
    );
    my $array_ref = $cldr->calendar_terms(
        locale          => 'und',
        calendar        => 'gregorian',
        term_type       => 'day',
        term_context    => 'format',
        term_width      => 'abbreviated',
    );

Returns all calendar terms information from L<table calendar_terms|/"Table calendar_terms"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<calendar>

A C<calendar> ID as can be found in table L<calendars|/"Table calendars">, such as: C<buddhist>, C<chinese>, C<coptic>, C<dangi>, C<ethioaa>, C<ethiopic>, C<gregory>, C<hebrew>, C<indian>, C<islamic>, C<islamic-civil>, C<islamic-rgsa>, C<islamic-tbla>, C<islamic-umalqura>, C<islamicc>, C<iso8601>, C<japanese>, C<persian>, C<roc>

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=back

See also the L<Unicode LDMD specifications|https://unicode.org/reports/tr35/tr35-dates.html#months_days_quarters_eras>

=head2 casing

    my $ref = $cldr->casing( locale => 'fr', token => 'currencyName' );
    # Returns an hash reference like:
    {
        casing_id   => 926,
        locale      => 'fr',
        token       => 'currencyName',
        value       => 'lowercase',
    }

Returns an hash reference of a calendar information from the table L<casings|/"Table casings"> for a given C<token> value.

The meaning of the fields are as follows:

=over 4

=item * C<casing_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<token>

Known values are: C<calendar_field>, C<currencyName>, C<currencyName_count>, C<day_format_except_narrow>, C<day_narrow>, C<day_standalone_except_narrow>, C<era_abbr>, C<era_name>, C<era_narrow>, C<key>, C<keyValue>, C<language>, C<metazone_long>, C<month_format_except_narrow>, C<month_narrow>, C<month_standalone_except_narrow>, C<quarter_abbreviated>, C<quarter_format_wide>, C<quarter_narrow>, C<quarter_standalone_wide>, C<relative>, C<script>, C<symbol>, C<territory>, C<unit_pattern>, C<variant>, C<zone_exemplarCity>, C<zone_long>, C<zone_short>

=item * C<value>

A casing value.

=back

=head2 casings

    my $all = $cldr->casings;
    my $all = $cldr->casings( locale => 'fr' );

Returns all casing information from L<table casings|/"Table casings"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=back

=head2 cldr_built

    my $datetime = $cldr->cldr_built; # 2024-07-01T05:57:29

Return the ISO8601 datetime in GMT of when this data were built.

Note, this is just a string, not a L<DateTime> object. If you want a L<DateTime> object, maybe do something like:

    use DateTime::Format::Strptime;
    my $fmt = DateTime::Format::Strptime->new( pattern => '%FT%T' );
    my $dt = $fmt->parse_datetime( $cldr->cldr_built );

=head2 cldr_maintainer

    my $str = $cldr->cldr_maintainer; # Jacques Deguest

Returns a string representing the name of the person who created this SQLite database of C<CLDR> data.

=head2 cldr_version

    my $version = $cldr->cldr_version; # 45.0

Return the Unicode CLDR version number of the data.

Note, this is just a string. You may want to turn it into an object for comparison, such as:

    use version;
    my $vers = version->parse( $cldr->cldr_version );

Or, maybe:

    use Changes::Version;
    my $vers = Changes::Version->new( $cldr->cldr_version );

    say $vers > $other_version;

=head2 code_mapping

    my $ref = $cldr->code_mapping( code => 'US' );
    # Returns an hash reference like:
    {
        code_mapping_id => 263,
        code            => 'US',
        alpha3          => 'USA',
        numeric         => 840,
        fips10          => undef,
        type            => 'territory',
    }

Returns an hash reference of a code mapping information from the table L<code_mappings|/"Table code_mappings"> for a given C<code> value.

The meaning of the fields are as follows:

=over 4

=item * C<code_mapping_id>

A unique incremental value automatically generated by SQLite.

=item * C<code>

A C<code> for which there is a mapping with other American standards

=item * C<alpha3>

A 3-characters code

=item * C<numeric>

A numeric code

=item * C<fips10>

An American standard

=item * C<type>

The mapping C<type>

=back

=head2 code_mappings

    my $all = $cldr->code_mappings;
    my $all = $cldr->code_mappings( type => 'territory' );
    my $all = $cldr->code_mappings( type => 'currency' );
    my $all = $cldr->code_mappings( alpha3 => 'USA' );
    my $all = $cldr->code_mappings( numeric => 840 ); # U.S.A.
    my $all = $cldr->code_mappings( fips => 'JP' ); # Japan
    my $all = $cldr->code_mappings( fips => undef, type => 'currency' );

Returns all code mapping information from L<table code_mappings|/"Table code_mappings"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<alpha3>

A 3-characters code.

=item * C<fips>

A C<fips> (U.S. L<Federal Information Processing Standard|https://en.wikipedia.org/wiki/Federal_Information_Processing_Standards>) code

=item * C<numeric>

An integer code.

=item * C<type>

A C<type>, such as C<territory> or C<currency>

=back

=head2 collation

    my $ref = $cldr->collation(
        collation => 'ducet',
    );
    # Returns an hash reference like this:
    {
        collation => 'ducet',
        description => 'Dictionary style ordering (such as in Sinhala)',
    }

Returns an hash reference of a C<collation> information from the table L<collations|/"Table collations"> for a given C<collation> ID.

The meaning of the fields are as follows:

=over 4

=item * C<collation>

A string representing a C<collation> ID.

Known values are: C<big5han>, C<compat>, C<dict>, C<direct>, C<ducet>, C<emoji>, C<eor>, C<gb2312>, C<phonebk>, C<phonetic>, C<pinyin>, C<reformed>, C<search>, C<searchjl>, C<standard>, C<stroke>, C<trad>, C<unihan>, C<zhuyin>

=item * C<description>

A short text describing the collation.

=back

=head2 collations

    my $all = $cldr->collations;
    my $all = $cldr->collations( collation => 'ducet' );
    my $all = $cldr->collations( description => qr/Chinese/ );

Returns all collations information from L<table collations|/"Table collations"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<collation>

A C<collation> ID

=item * C<description>

A short text describing the collation.

See the section on L</"Advanced Search">

=back

=head2 collation_l10n

    my $ref = $cldr->collation_l10n(
        collation => 'ducet',
        locale => 'en',
    );
    # Returns an hash reference like this:
    {
        collation_l10n_id   => 323,
        locale              => 'en',
        collation           => 'ducet',
        locale_name         => 'Default Unicode Sort Order',
    }

Returns an hash reference of a C<collation> localised information from the table L<collations_l10n|/"Table collations_l10n"> for a given C<collation> ID and a C<locale> ID.

The meaning of the fields are as follows:

=over 4

=item * C<collation_l10n_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<collation>

A C<collation> ID as can be found in table L<collations|/"Table collations">

=item * C<locale_name>

A short text representing the localised C<collation> name.

=back

=head2 collations_l10n

    my $all = $cldr->collations_l10n;
    my $all = $cldr->collations_l10n( locale => 'en' );
    my $all = $cldr->collations_l10n(
        locale => 'en',
        collation => 'ducet',
    );

Returns all collations information from L<table collations_l10n|/"Table collations_l10n"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<collation>

A C<collation> ID as can be found in table L<collations|/"Table collations">

=back

=head2 currency

    my $ref = $cldr->currency( currency => 'JPY' ); # Japanese Yen
    # Returns an hash reference like:
    {
        currency_id     => 133,
        currency        => 'JPY',
        digits          => 0,
        rounding        => 0,
        cash_digits     => undef,
        cash_rounding   => undef,
        is_obsolete     => 0,
        status          => 'regular',
    }

Returns an hash reference of a code mapping information from the table L<currencies|/"Table currencies"> for a given C<currency> code.

The meaning of the fields are as follows:

=over 4

=item * C<currency_id>

A unique incremental value automatically generated by SQLite.

=item * C<currency>

A C<currency> code

=item * C<digits>

Number of fractional digits.

=item * C<rounding>

Number of digits used for rounding.

=item * C<cash_digits>

Number of fractional digits for money representation.

=item * C<cash_rounding>

Number of digits used for rounding for money representation.

=item * C<is_obsolete>

A boolean defining whether the currency is obsolete.

=item * C<status>

A string representing the status for this currency.

Known values are: C<deprecated>, C<regular>, C<unknown>

=back

=head2 currencies

    my $all = $cldr->currencies;
    my $all = $cldr->currencies( is_obsolete => 1 );

Returns all currencies information from L<table currencies|/"Table currencies"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<is_obsolete>

A boolean value. Use 1 for C<true> and 0 for C<false>

=item * C<status>

Valid C<status> values are, as per the CLDR:

=over 8

=item * C<regular>

This is the default and means the currency is valid.

=item * C<deprecated>

The currency is deprecated.

=item * C<unknown>

The status is unknown.

=back

=back

=head2 currency_info

    my $ref = $cldr->currency_info(
        currency    => 'EUR',
        territory'  => 'FR',
    );
    # Returns an hash reference like this:
    {
        currency_info_id    => 165,
        territory           => 'FR',
        currency            => 'EUR',
        start               => '1999-01-01',
        until               => undef,
        is_tender           => 0,
        hist_sequence       => undef,
        is_obsolete         => 0,
    }

Returns an hash reference of a C<currency> information from the table L<currencies_info|/"Table currencies_infos"> for a given ]C<locale> ID.

The meaning of the fields are as follows:

=over 4

=item * C<currency_info_id>

A unique incremental value automatically generated by SQLite.

=item * C<territory>

A 2-to-3 characters string representing the territory code, which may be either 2-characters uppercase alphabet, or 3-digits code representing a world region.

=item * C<currency>

A 3-characters currency code.

=item * C<start>

The date at which this currency started to be in use for this C<territory>.

=item * C<until>

The date at which this currency stopped being in use for this C<territory>.

=item * C<is_tender>

Whether this currency was a legal tender, i.e. whether it bore the force of law to settle a public or private debt or meet a financial obligation.

=item * C<hist_sequence>

Integer representing the historical order. C<CLDR> uses the attributes C<tz> and then C<to-tz> to link to following historical record when the old C<to> date overlaps the new C<from> date. Example: territory C<SX>

=item * C<is_obsolete>

A boolean value expressing whether this currency is obsolete or not.

=back

See the L<LDML specifications|https://www.unicode.org/reports/tr35/tr35-61/tr35-numbers.html#Supplemental_Currency_Data> for more information.

=head2 currencies_info

    my $all = $cldr->currencies_info;
    my $all = $cldr->currencies_info( territory => 'FR' );
    my $all = $cldr->currencies_info( currency => 'EUR' );

Returns all currencies information from L<table currencies_info|/"Table currencies_info"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<territory>

A 2-characters code representing a C<territory> as can be found in L<table territories|/"Table territories">

=item * C<currency>

A 3-characters code representing a C<currency> as can be found in L<table currencies|/"Table currencies">

=back

=head2 currency_l10n

    my $ref = $cldr->currency_l10n(
        locale      => 'en',
        count       => undef,
        currency    => 'JPY',
    );
    # Returns an hash reference like this:
    {
        curr_l10n_id    => 20924,
        locale          => 'en',
        currency        => 'JPY',
        count           => undef,
        locale_name     => 'Japanese Yen',
        symbol          => '¥',
    }

Returns an hash reference of a C<currency> localised information from the table L<currencies_l10n|/"Table currencies_l10n"> for a given C<currency> ID, C<locale> ID and C<count> value. If no C<count> value is provided, it will default to C<undef>

The meaning of the fields are as follows:

=over 4

=item * C<curr_l10n_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<currency>

A C<currency> ID as can be found in the L<table currencies|/"Table currencies">

Note that the values used by the C<CLDR> als includes currencies that are deprecated in ISO 4217 standard.

=item * C<count>

A string that specifies a distinctive value.

Known values are: C<undef>, C<few>, C<many>, C<one>, C<other>, C<two>, C<zero>

For example, with the C<EUR> C<currency> in C<locale> C<en>, here are the possible C<count> values and its associated localised string representation.

=over 8

=item * C<undef>

Euro

=item * C<one>

euro

=item * C<other>

euros

=back

And here with the C<JPY> C<currency> and C<locale> C<pl>:

=over 4

=item * C<undef>

jen japoński

=item * C<few>

jeny japońskie

=item * C<many>

jenów japońskich

=item * C<one>

jen japoński

=item * C<other>

jena japońskiego

=back

See the L<LDML specifications about language plural rules|https://unicode.org/reports/tr35/tr35-numbers.html#Language_Plural_Rules> for more information.

=item * C<locale_name>

A string representing a localised currency name based on the value of C<locale>.

=item * C<symbol>

An optional C<currency> symbol.

=back

=head2 currencies_l10n

    my $all = $cldr->currencies_l10n;
    my $all = $cldr->currencies_l10n( locale => 'en' );
    my $all = $cldr->currencies_l10n(
        locale      => 'en',
        currency    => 'JPY',
    );

Returns all currencies localised information from L<table currencies_l10n|/"Table currencies_l10n"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<count>

A string representing a distinctive C<count> for the C<currency>

Known values are: C<undef>, C<few>, C<many>, C<one>, C<other>, C<two>, C<zero>

See the L<LDML specifications about language plural rules|https://unicode.org/reports/tr35/tr35-numbers.html#Language_Plural_Rules> for more information.

=item * C<currency>

A 3-characters C<currency> ID as can be found in the table L<currencies|/"Table currencies">

=back

=head2 database_handler

Returns the current database handler used by the C<Locale::Unicode::Data> object instantiated.

Please note that the database is opened in read-only. If you want to modify it, which I would advise against, you need to instantiate your own L<DBI> connection. Something like this:

    my $db_file = $cldr->datafile;
    $dbh = DBI->connect( "dbi:SQLite:dbname=${db_file}", '', '' ) ||
        die( "Unable to make connection to Unicode CLDR SQLite database file ${db_file}: ", $DBI::errstr );
    # To enable foreign keys:
    # See: <https://metacpan.org/release/ADAMK/DBD-SQLite-1.27/view/lib/DBD/SQLite.pm#Foreign-Keys>
    $dbh->do("PRAGMA foreign_keys = ON");

=head2 datafile

Sets or gets the file path to the SQLite database file. This defaults to the global variable C<$DB_FILE>

=head2 date_field_l10n

    my $ref = $cldr->date_field_l10n(
        locale          => 'en',
        field_type      => 'day',
        field_length    => 'narrow',
        relative        => -1,
    );
    # Returns an hash reference like this:
    {
        date_field_id   => 2087,
        locale          => 'en',
        field_type      => 'day',
        field_length    => 'narrow',
        relative        => -1,
        locale_name     => 'yesterday',
    }

Returns an hash reference of a field localised information from the table L<date_fields_l10n|/"Table date_fields_l10n"> for a given C<locale> ID, C<field_type>, C<field_length> and C<relative> value.

The meaning of the fields are as follows:

=over 4

=item * C<date_field_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<field_type>

A string representing a field type.

Known values are: C<day>, C<fri>, C<hour>, C<minute>, C<mon>, C<month>, C<quarter>, C<sat>, C<second>, C<sun>, C<thu>, C<tue>, C<wed>, C<week>, C<year>

=item * C<field_length>

A string representing a field length.

Known values are: C<narrow>, C<short>, C<standard>

=item * C<relative>

An integer representing the relative value of the field. For example, C<0> being today, C<-1> being a day period preceding the current one, and C<1> being a day period following the current one.

Known values are: C<-2>, C<-1>, C<0>, C<1>, C<2>, C<3>

=item * C<locale_name>

A string containing the localised date field based on the C<locale>

=back

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Calendar_Fields> for more information.

=head2 date_fields_l10n

    my $all = $cldr->date_fields_l10n;
    my $all = $cldr->date_fields_l10n( locale => 'en' );
    my $all = $cldr->date_fields_l10n(
        locale          => 'en',
        field_type      => 'day',
        field_length    => 'narrow',
    );

Returns all date fields localised information from L<table date_fields_l10n|/"Table date_fields_l10n"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<field_type>

A string representing a field type.

Known values are: C<day>, C<fri>, C<hour>, C<minute>, C<mon>, C<month>, C<quarter>, C<sat>, C<second>, C<sun>, C<thu>, C<tue>, C<wed>, C<week>, C<year>

=item * C<field_length>

A string representing a field length.

Known values are: C<narrow>, C<short>, C<standard>

=back

=head2 date_term

    my $ref = $cldr->date_term(
        locale          => 'en',
        term_type       => 'day',
        term_length     => 'narrow',
    );
    # Returns an hash reference like this:
    {
        date_term_id    => 2087,
        locale          => 'en',
        term_type       => 'day',
        term_length     => 'narrow',
        display_name    => 'day',
    }

Returns an hash reference of a date term localised information from the table L<date_terms|/"Table date_terms"> for a given C<locale> ID, C<term_type>, and C<term_length> value.

The meaning of the fields are as follows:

=over 4

=item * C<date_term_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<term_type>

A string representing a field type.

Known values are: C<day>, C<fri>, C<hour>, C<minute>, C<mon>, C<month>, C<quarter>, C<sat>, C<second>, C<sun>, C<thu>, C<tue>, C<wed>, C<week>, C<year>

=item * C<term_length>

A string representing a field length.

Known values are: C<narrow>, C<short>, C<standard>

=item * C<display_name>

The localised string value for the C<term_type>

For example, C<hour> for the locale C<ja> (Japanese) would be C<時>

=back

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Calendar_Fields> for more information.

See also the method L<date_field_l10n|/date_field_l10n>

=head2 date_terms

    my $all = $cldr->date_terms;
    my $all = $cldr->date_terms( locale => 'en' );
    my $all = $cldr->date_terms(
        locale      => 'en',
        term_type   => 'day',
        term_length => 'narrow',
    );

Returns all date terms localised information from L<table date_terms|/"Table date_terms"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<term_type>

A string representing a field type.

Known values are: C<day>, C<fri>, C<hour>, C<minute>, C<mon>, C<month>, C<quarter>, C<sat>, C<second>, C<sun>, C<thu>, C<tue>, C<wed>, C<week>, C<year>

=item * C<term_length>

A string representing a field length.

Known values are: C<narrow>, C<short>, C<standard>

=back

See also the method L<date_fields_l10n|/date_fields_l10n>

=head2 day_period

    my $ref = $cldr->day_period( locale => 'fr', day_period => 'noon' );
    # Returns an hash reference like:
    {
        day_period_id   => 115,
        locale          => 'fr',
        day_period      => 'noon',
        start           => '12:00',
        until           => '12:00',
    }

Returns an hash reference of a day period information from the table L<day_periods|/"Table day_periods"> for a given C<locale> code and C<day_period> code.

The meaning of the fields are as follows:

=over 4

=item * C<day_period_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<day_period>

A string representing a day period.

Known values are: C<afternoon1>, C<afternoon2>, C<am>, C<evening1>, C<evening2>, C<midnight>, C<morning1>, C<morning2>, C<night1>, C<night2>, C<noon>, C<pm>

=item * C<start>

A time from which this day period starts.

Known values go from C<00:00> until C<23:00>

=item * C<until>

A time by which this day period stops.

Known values go from C<00:00> until C<24:00>

=back

=head2 day_periods

    my $all = $cldr->day_periods;
    my $all = $cldr->day_periods( locale => 'ja' );
    # Known values for day_period: afternoon1, afternoon2, am, evening1, evening2,
    # midnight, morning1, morning2, night1, night2, noon, pm
    my $all = $cldr->day_periods( day_period => 'noon' );

Returns all day periods information from L<table day_periods|/"Table day_periods"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<day_period>

A token representing a day period. Valid tokens are: C<afternoon1>, C<afternoon2>, C<am>, C<evening1>, C<evening2>, C<midnight>, C<morning1>, C<morning2>, C<night1>, C<night2>, C<noon>, C<pm>

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=back

=head2 decode_sql_arrays

    my $bool = $cldr->decode_sql_arrays;
    $cldr->decode_sql_arrays(0); # off
    $cldr->decode_sql_arrays(1); # on

Sets or gets the boolean value used to specify whether you want this API to automatically decode SQL arrays into perl arrays using L<JSON::XS>

This is set to true by default, upon object instantiation.

=head2 extend_timezones_cities

    my $bool = $cldr->extend_timezones_cities;
    $cldr->extend_timezones_cities(0); # off
    $cldr->extend_timezones_cities(1); # on

Sets or gets the boolean value used to specify whether you want to use the time zones cities extended data, if any were added, or not.

To add the time zones cities extended data, see the Unicode CLDR SQLite database script option C<--extended-timezones-cities>

Normally, this SQLite database comes by default with an extended set of time zones cities data for 421 time zones and their main city across 88 locales, courtesy of the GeoNames database, and online work the author of this distribution has performed.

See also the method L<timezone_city|/timezone_city> and L<timezones_cities|/timezones_cities>

This is set to true by default, upon object instantiation.

=head2 error

Used as a mutator, this sets and L<exception object|Locale::Unicode::Exception> and returns an C<Locale::Unicode::NullObject> in object context (such as when chaining), or C<undef> in scalar context, or an empty list in list context.

The C<Locale::Unicode::NullObject> class prevents the perl error of C<Can't call method "%s" on an undefined value> (see L<perldiag>). Upon the last method chained, C<undef> is returned in scalar context or an empty list in list context.

For example:

    my $locale = Locale::Unicode->new( 'ja' );
    $locale->translation( 'my-software' )->transform_locale( $bad_value )->tz( 'jptyo' ) ||
        die( $locale->error );

In this example, C<jptyo> will never be set, because C<transform_locale> triggered an exception that returned an C<Locale::Unicode::NullObject> object catching all further method calls, but eventually we get the error and die.

=head2 fatal

    $cldr->fatal(1); # Enable fatal exceptions
    $cldr->fatal(0); # Disable fatal exceptions
    my $bool = $cldr->fatal;

Sets or get the boolean value, whether to die upon exception, or not. If set to true, then instead of setting an L<exception object|Locale::Unicode::Data::Exception>, this module will die with an L<exception object|Locale::Unicode::Data::Exception>. You can catch the exception object then after using C<try>. For example:

    use v.5.34; # to be able to use try-catch blocks in perl
    use experimental 'try';
    no warnings 'experimental';
    try
    {
        my $cldr = Locale::Unicode::Data->new( fatal => 1 );
        # Forgot the 'width':
        my $str = $cldr->timezone_names( timezone => 'Asia/Tokyo', locale => 'en' );
    }
    catch( $e )
    {
        say "Error occurred: ", $e->message;
        # Error occurred: No value for width was provided.
    }

=head2 interval_formats

    my $ref = $cldr->interval_formats(
        locale => 'en',
        calendar => 'gregorian',
    );

This would return something like:

    {
        Bh => [qw( B h )],
        Bhm => [qw( B h m )],
        d => ["d"],
        default => ["default"],
        Gy => [qw( G y )],
        GyM => [qw( G M y )],
        GyMd => [qw( d G M y )],
        GyMEd => [qw( d G M y )],
        GyMMM => [qw( G M y )],
        GyMMMd => [qw( d G M y )],
        GyMMMEd => [qw( d G M y )],
        H => ["H"],
        h => [qw( a h )],
        hm => [qw( a h m )],
        Hm => [qw( H m )],
        hmv => [qw( a h m )],
        Hmv => [qw( H m )],
        Hv => ["H"],
        hv => [qw( a h )],
        M => ["M"],
        Md => [qw( d M )],
        MEd => [qw( d M )],
        MMM => ["M"],
        MMMd => [qw( d M )],
        MMMEd => [qw( d M )],
        y => ["y"],
        yM => [qw( M y )],
        yMd => [qw( d M y )],
        yMEd => [qw( d M y )],
        yMMM => [qw( M y )],
        yMMMd => [qw( d M y )],
        yMMMEd => [qw( d M y )],
        yMMMM => [qw( M y )],
    }

This returns an hash reference of interval format ID with their associated L<greatest difference token|https://unicode.org/reports/tr35/tr35-dates.html#intervalFormats> for the given C<locale> ID and C<calendar> ID.

The C<default> interval format pattern is something like C<{0} – {1}>, but this changes depending on the C<locale> and is not always available.

C<{0}> is the placeholder for the first datetime and C<{1}> is the placeholder for the second one.

=head2 l10n

Returns all localised information for certain type of data as an array reference of hash reference.

The following core parameters must be provided:

=over 4

=item * C<locale>

This is mandatory. This is a C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<type>

A type of data. Valid types are: C<annotation>, C<calendar_append_format>, C<calendar_available_format>, C<calendar_cyclic>, C<calendar_era>, C<calendar_format>, C<calendar_interval_formats>, C<calendar_term>, C<casing>, C<currency>, C<date_field>, C<locale>, C<number_format>, C<number_symbol>, C<script>, C<subdivision>, C<territory>, C<unit>, C<variant>

=back

Below are each type of data and their associated parameters:

=over 4

=item * C<annotation>

    my $ref = $cldr->l10n(
        type => 'annotation',
        locale => 'en',
        annotation => '{',
    );

Returns an hash reference of a annotation information from the table L<annotations|/"Table annotations"> for a given C<locale> code and C<annotation> character.

=item * C<calendar_append_format>

    my $ref = $cldr->l10n(
        type => 'calendar_append_format',
        locale => 'en',
        calendar => 'gregorian',
        format_id => 'Day',
    );

Returns an hash reference of a calendar appended format information from the table L<calendar_append_formats|/"Table calendar_append_formats"> for a given C<locale>, and C<calendar> code and a C<format_id> ID.

=item * C<calendar_available_format>

    my $ref = $cldr->l10n(
        type => 'calendar_available_format',
        locale => 'ja',
        calendar => 'japanese',
        format_id => 'GyMMMEEEEd',
    );

Returns an hash reference of a calendar available format information from the table L<calendar_available_formats|/"Table calendar_available_formats"> for a given C<locale>, and C<calendar> code and a C<format_id> ID.

=item * C<calendar_cyclic>

    my $ref = $cldr->l10n(
        type => 'calendar_cyclic',
        locale => 'ja',
        calendar => 'chinese',
        format_set => 'dayParts',
        # 1..12
        format_id => 1,
    );

Returns an hash reference of a calendar available format information from the table L<calendar_cyclics_l10n|/"Table calendar_cyclics_l10n"> for a given C<locale>, and C<calendar> code and a C<format_set> token and a C<format_id> ID.

=item * C<calendar_era>

    my $ref = $cldr->l10n(
        type => 'calendar_era',
        locale => 'ja',
        calendar => 'japanese',
        # abbreviated, narrow
        # 'narrow' contains less data than 'abbreviated'
        era_width => 'abbreviated',
        era_id => 236,
    );

Returns an hash reference of a calendar available format information from the table L<calendar_eras_l10n|/"Table calendar_eras_l10n"> for a given C<locale>, and C<calendar> code and a C<era_width> width and a C<era_id> ID.

=item * C<calendar_format>

    my $ref = $cldr->l10n(
        type => 'calendar_format',
        locale => 'ja',
        calendar => 'gregorian',
        format_id => 'yMEEEEd',
    );

Returns an hash reference of a calendar date or time format information from the table L<calendar_formats_l10n|/"Table calendar_formats_l10n"> for a given C<locale>, and C<calendar> code and a C<format_id> ID.

=item * C<calendar_interval_format>

    my $ref = $cldr->l10n(
        type => 'calendar_interval_format',
        locale => 'ja',
        calendar => 'gregorian',
        format_id => 'yMMM',
    );

Returns an hash reference of a calendar interval format information from the table L<calendar_interval_formats|/"Table calendar_interval_formats"> for a given C<locale>, and C<calendar> code and a C<format_id> ID.

=item * C<calendar_term>

    my $ref = $cldr->l10n(
        type => 'calendar_term',
        locale => 'ja',
        calendar => 'gregorian',
        term_name => 'mon',
    );

Returns an hash reference of a calendar term information from the table L<calendar_terms|/"Table calendar_terms"> for a given C<locale>, and C<calendar> code and a C<term_name> token.

Known term names are: C<mon>, C<tue>, C<wed>, C<thu>, C<fri>, C<sat>, C<sun>, C<am>, C<pm>, C<1>, C<2>, C<3>, C<4>, C<5>, C<6>, C<7>, C<8>, C<9>, C<10>, C<11>, C<12>, C<13>, C<midnight>, C<morning1>, C<morning2>, C<noon>, C<afternoon1>, C<afternoon2>, C<evening1>, C<evening2>, C<night1>, C<night2>

=item * C<casing>

    my $ref = $cldr->l10n(
        type => 'casing',
        locale => 'fr',
        token => 'currencyName',
    );

Returns an hash reference of a casing information from the table L<casings|/"Table casings"> for a given C<locale> code and a C<token>.

=item * C<currency>

    my $ref = $cldr->l10n(
        type => 'currency',
        locale => 'ja',
        currency => 'EUR',
    );

Returns an hash reference of a currency information from the table L<currencies_l10n|/"Table currencies_l10n"> for a given C<locale> code and a C<currency> code.

=item * C<date_field>

    my $ref = $cldr->l10n(
        type => 'date_field',
        locale => 'ja',
        # Other possible values:
        # day, week, month, quarter, year, hour, minute, second,
        # mon, tue, wed, thu, fri, sat, sun
        field_type  => 'day',
        # -1 for yesterday, 0 for today, 1 for tomorrow
        relative => -1,
    );

Returns an hash reference of a date field information from the table L<date_fields_l10n|/"Table date_fields_l10n"> for a given C<locale>, and a field type C<field_type> and C<relative> value.

=item * C<locale>

    my $ref = $cldr->l10n(
        type => 'locale',
        locale => 'ja',
        locale_id => 'fr',
    );

Returns an hash reference of a locale information from the table L<locales_l10n|/"Table locales_l10n"> for a given C<locale>, and a locale ID C<locale_id>.

=item * C<number_format>

    my $ref = $cldr->l10n(
        type => 'number_format',
        locale => 'ja',
        number_type => 'currency',
        format_id => '10000',
    );

Returns an hash reference of a number format from the table L<number_formats_l10n|/"Table number_formats_l10n"> for a given C<locale>, a number type C<number_type>, and a format ID C<format_id>.

Known value for C<number_type> are: C<currency>, C<decimal>, C<misc>, C<percent>, C<scientific>

=item * C<number_symbol>

    my $ref = $cldr->l10n(
        type => 'number_symbol',
        locale => 'en',
        number_system => 'latn',
        property => 'decimal',
    );

Returns an hash reference of a number symbol information from the table L<number_symbols_l10n|/"Table number_symbols_l10n"> for a given C<locale>, a number system C<number_system> as can be found in the L<table number_systems|/"Table number_systems">, and a C<property> value.

=item * C<script>

    my $ref = $cldr->l10n(
        type => 'script',
        locale => 'ja',
        script => 'Kore',
    );

Returns an hash reference of a script information from the table L<scripts_l10n|/"Table scripts_l10n"> for a given C<locale>, a script value C<script> as can be found in the L<scripts table|/"Table scripts">.

=item * C<subdivision>

    my $ref = $cldr->l10n(
        type => 'subdivision',
        locale => 'en',
        subdivision => 'jp13', # Tokyo
    );

Returns an hash reference of a subdivision information from the table L<subdivisions_l10n|/"Table subdivisions_l10n"> for a given C<locale>, a subdivision value C<subdivision> as can be found in the L<subdivisions table|/"Table subdivisions">.

=item * C<territory>

    my $ref = $cldr->l10n(
        type => 'territory',
        locale => 'en',
        territory => 'JP', # Japan
    );

Returns an hash reference of a territory information from the table L<territories_l10n|/"Table territories_l10n"> for a given C<locale>, and a C<territory> code as can be found in the L<territories table|/"Table territories">.

=item * C<unit>

    my $ref = $cldr->l10n(
        type => 'unit',
        locale => 'en',
        unit_id => 'power3',
    );

Returns an hash reference of a unit information from the table L<units_l10n|/"Table units_l10n"> for a given C<locale>, and a C<unit_id>.

=item * C<variant>

    my $ref = $cldr->l10n(
        type => 'variant',
        locale => 'en',
        variant => 'valencia',
    );

Returns an hash reference of a variant information from the table L<variants_l10n|/"Table variants_l10n"> for a given C<locale>, and a C<variant> as can be found in the L<table variants|/"Table variants">.

=back

=head2 language

    my $ref = $cldr->language( language => 'ryu' ); # Central Okinawan (Ryukyu)
    # Returns an hash reference like this:
    {
        language_id => 6712,
        language    => 'ryu',
        scripts     => ["Kana"],
        territories => ["JPY"],
        parent      => undef,
        alt         => undef,
        status      => 'regular',
    }

Returns an hash reference of a C<language> information from the table L<languages|/"Table languages"> for a given C<language> ID.

The meaning of the fields are as follows:

=over 4

=item * C<language_id>

A unique incremental value automatically generated by SQLite.

=item * C<language>

A C<language> ID, which may be 2 to 3-characters long.

=item * C<scripts>

An array of C<script> IDs as can be found in the L<table scripts|/"Table scripts">, and that are associated with this C<language>.

=item * C<territories>

An array of C<territory> IDs as can be found in the L<table territories|/"Table territories">, and that are associated with this C<language>.

=item * C<format_pattern>

A string representing a localised pattern.

=back

=head2 languages

    my $all = $cldr->languages;
    my $all = $cldr->languages( parent => 'gmw' );

Returns all languages information from L<table languages|/"Table languages"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<parent>

A parent C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

The C<parent> value is set in 63% of the languages (over 8,700) in the table L<languages|/"Table languages">

=back

=head2 language_population

    my $all = $cldr->language_population( territory => 'JP' );
    # Returns an array reference of hash references like this:
    [
        {
            language_pop_id     => 738,
            territory           => 'JP',
            locale              => 'ja',
            population_percent  => 95,
            literacy_percent    => undef,
            writing_percent     => undef,
            official_status     => 'official',
        },
        {
            language_pop_id     => 739,
            territory           => 'JP',
            locale              => 'ryu',
            population_percent  => 0.77,
            literacy_percent    => undef,
            writing_percent     => 5,
            official_status     => undef,
        },
        {
            language_pop_id     => 740,
            territory           => 'JP',
            locale              => 'ko',
            population_percent  => 0.52,
            literacy_percent    => undef,
            writing_percent     => undef,
            official_status     => undef,
        }
    ]

Returns an array reference of hash references of a C<language> population information from the table L<language_population|/"Table language_population"> for a given C<territory> ID.

The meaning of the fields are as follows:

=over 4

=item * C<language_pop_id>

A unique incremental value automatically generated by SQLite.

=item * C<territory>

A C<territory> code as can be found in the L<table territories|/"Table territories">

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<population_percent>

A percentage of the population as decimal.

=item * C<literacy_percent>

A percentage of the population as decimal.

=item * C<writing_percent>

A percentage of the population as decimal.

=item * C<official_status>

A string representing the official status for this usage of this C<locale> in this C<territory>

Known values are: C<undef>, C<official>, C<official_regional>, C<de_facto_officia>

=back

=head2 language_populations

    my $all = $cldr->language_populations;
    my $all = $cldr->language_populations( official_status => 'official' );

Returns all language population information from L<table language_population|/"Table language_population"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<official_status>

A status string, such as C<official>, C<official_regional> or C<de_facto_official>

=back

=head2 likely_subtag

    my $ref = $cldr->likely_subtag( locale => 'ja' );
    # Returns an hash reference like this:
    {
        likely_subtag_id    => 297,
        locale              => 'ja',
        target              => 'ja-Jpan-JP',
    }

Returns an hash reference for a likely C<language> information from the table L<likely_subtags|/"Table likely_subtags"> for a given C<locale> ID.

The meaning of the fields are as follows:

=over 4

=item * C<likely_subtag_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<target>

A string representing the C<target> C<locale>

=back

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35.html#Likely_Subtags> for more information.

=head2 likely_subtags

    my $all = $cldr->likely_subtags;

Returns all likely subtag information from L<table likely_subtags|/"Table likely_subtags"> as an array reference of hash reference.

No additional parameter is needed.

=head2 locale

    my $ref = $cldr->locale( locale => 'ja' );
    # Returns an hash reference like this:
    {
        locale_id   => 3985,
        locale      => 'ja',
        parent      => undef,
        collations  => ["private-kana", "standard", "unihan"],
        status      => 'regular',
    }

Returns an hash reference of C<locale> information from the table L<locales|/"Table locales"> for a given C<locale> ID.

The meaning of the fields are as follows:

=over 4

=item * C<locale_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<parent>

The parent C<locale>, if any.

=item * C<collations>

An array of C<collation> ID, such as one can find from the table L<collations|/"Table collations">

=item * C<status>

A string representing a status for this C<locale>

Known values are: C<undef>, C<deprecated>, C<private_use>, C<regular>, C<reserved>, C<special>, C<unknown>

=back

=head2 locales

    my $all = $cldr->locales;

Returns all locale information from L<table locales|/"Table locales"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<status>

A status string, such as C<deprecated>, C<private_use>, C<regular>, C<reserved>, C<special>, C<unknown> or C<undef> if none is set.

=back

=head2 locale_l10n

    my $ref = $cldr->locale_l10n(
        locale      => 'en',
        locale_id   => 'ja',
        alt         => undef,
    );
    # Returns an hash reference like this:
    {
        locales_l10n_id => 16746,
        locale          => 'en',
        locale_id       => 'ja',
        locale_name     => 'Japanese',
        alt             => undef,
    }

Returns an hash reference of C<locale> localised information from the table L<locales_l10n|/"Table locales_l10n"> for a given C<locale> ID and a C<locale_id> ID and an C<alt> value. If no C<alt> value is provided, it will default to C<undef>.

The C<locale> value is the C<language>, with possibly some additional subtags, in which the information is provided, and the C<locale_id> the C<locale> id whose name will be returned in the language specified by the C<locale> argument.

Valid locales that can be found in the L<table locales_l10n|/"Table locales_l10n"> are, for example: C<asa>, C<az-Arab> (using a C<script>), C<be-tarask> (using a C<variant>), C<ca-ES-valencia> (using a combination of C<territory> and C<variant>), C<de-AT> (using a C<territory>), C<es-419> (using a C<region> code)

See L<Locale::Unicode> for more information on locales.

The meaning of the fields are as follows:

=over 4

=item * C<locales_l10n_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<locale_id>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<locale_name>

A string representing the localised name of the C<locale_id> according to the C<locale> value.

=back

=head2 locales_l10n

    my $all = $cldr->locales_l10n;
    # Returns an array reference of all locale information in English
    my $all = $cldr->locales_l10n( locale => 'en' );
    # Returns an array reference of all the way to write 'Japanese' in various languages
    # This would typically return an array reference of something like 267 hash reference
    my $all = $cldr->locales_l10n( locale_id => 'ja' );
    # This is basically the same as with the method locale_l10n()
    my $all = $cldr->locales_l10n(
        locale      => 'en',
        locale_id   => 'ja',
        alt         => undef,
    );

Returns all locale localised information from L<table locales_l10n|/"Table locales_l10n"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<alt>

This is used to differentiate when alternative values exist.

Known values for C<alt> are C<undef>, i.e. not set, or C<long>, C<menu>, C<secondary>, C<short>, C<variant>

=item * C<locale>

A C<locale> such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

This is generally more a C<language>, i.e. a 2 or 3-characters code than a C<locale>

=item * C<locale_id>

A 2 to 3 characters C<language> ID such as C<en> as can be found in table L<languages|/"Table languages">

=back

=head2 locales_info

    my $ref = $cldr->locales_info(
        property => 'quotation_start',
        locale => 'ja',
    );
    # Returns an hash reference like this:
    {
        locales_info_id => 361,
        locale          => 'ja',
        property        => 'quotation_start',
        value           => '「',
    }

Returns an hash reference of C<locale> properties information from the table L<locales_info|/"Table locales_info"> for a given C<locale> ID and a C<property> value.

The meaning of the fields are as follows:

=over 4

=item * C<locales_info_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<property>

A string representing a property.

Known properties are: C<char_orientation>, C<quotation2_end>, C<quotation2_start>, C<quotation_end>, C<quotation_start>, C<yes> and C<no>

=item * C<value>

The C<property> value for this C<locale>

=back

=head2 locales_infos

     my $all = $cldr->locales_infos;

Returns all locale properties information from L<table locales_info|/"Table locales_info"> as an array reference of hash reference.

No additional parameter is needed.

=head2 locale_number_system

    my $ref = $cldr->locale_number_system( locale => 'ja' );
    # Returns an hash reference like this:
    {
        locale_num_sys_id => 26,
        locale => 'ja',
        number_system => undef,
        native => undef,
        traditional => 'jpan',
        finance => 'jpanfin',
    }

As a reminder, the numbering system can be explicitly specified with the Unicode BCP47 extension C<nu>. For example:

=over 4

=item * C<hi-IN-u-nu-native>

Explicitly specifying the native digits for numeric formatting in Hindi language.

=item * C<zh-u-nu-finance>

Explicitly specifying the appropriate financial numerals in Chinese language.

=item * C<ta-u-nu-traditio>

Explicitly specifying the traditional Tamil numerals in Tamil language.

=item * C<ar-u-nu-latn>

Explicitly specifying the western digits 0-9 in Arabic language.

=back

Returns an hash reference of a given C<locale> number systems available from the table L<locale_number_systems|/"Table locale_number_systems">.

TLDR; if C<number_system> and C<native> are the same, then it is ok to also use C<latn> as numbering system. When C<traditional> is not available, use C<native>. When C<finance> is not available, use the default C<number_system>

The meaning of the fields are as follows:

=over 4

=item * C<locale_num_sys_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<number_system>

A string representing a number system as can be found in the table L<number_systems|/"Table number_systems">, and "used for presentation of numeric quantities in the given locale" (L<LDML specifications|https://unicode.org/reports/tr35/tr35-numbers.html#defaultNumberingSystem>)

In L<LDML specifications|https://unicode.org/reports/tr35/tr35-numbers.html#defaultNumberingSystem>, this is named C<default>, but C<default> is a reserved keyword in SQL terminology.

=item * C<native>

Quoting from the L<LDML specifications|https://unicode.org/reports/tr35/tr35-numbers.html#otherNumberingSystems>: "Defines the L<numbering system|/number_system> used for the native digits, usually defined as a part of the L<script|/script> used to write the language. The C<native> L<numbering system|/number_system> can only be a numeric positional decimal-digit L<numbering system|/number_system>, using digits with General_Category=Decimal_Number. Note: In locales where the C<native> L<numbering system|/number_system> is the default, it is assumed that the L<numbering system|/number_system> C<latn> (Western digits 0-9) is always acceptable, and can be selected using the C<-nu> keyword as part of a L<Unicode locale identifier|/locale>."

=item * C<traditional>

Quoting from the L<LDML specifications|https://unicode.org/reports/tr35/tr35-numbers.html#otherNumberingSystems>: "Defines the C<traditional> numerals for a L<locale|/locale>. This L<numbering system|/number_system> may be numeric or algorithmic. If the C<traditional> L<numbering system|/number_system> is not defined, applications should use the C<native> numbering system as a fallback."

=item * C<finance>

Quoting from the L<LDML specifications|https://unicode.org/reports/tr35/tr35-numbers.html#otherNumberingSystems>: "Defines the L<numbering system|/number_system> used for financial quantities. This L<numbering system|/number_system> may be numeric or algorithmic. This is often used for ideographic languages such as Chinese, where it would be easy to alter an amount represented in the default numbering system simply by adding additional strokes. If the financial L<numbering system|/number_system> is not specified, applications should use the default L<numbering system|/number_system> as a fallback."

=back

=head2 locale_number_systems

    my $all = $cldr->locale_number_systems;

Returns all locales L<numbering systems|/number_system> information from L<table locale_number_systems|/"Table locale_number_systems"> as an array reference of hash reference.

No additional parameter is needed.

=head2 make_inheritance_tree

This takes a C<locale>, such as C<ja> or C<ja-JP>, or C<es-ES-valencia> and it will return an array reference of L<inheritance tree of locales|https://unicode.org/reports/tr35/tr35.html#Locale_Inheritance>. This means the provided C<locale>'s parent, its grand-parent, etc until it reaches the C<root>, which, under the C<LDML> specifications is defined by C<und>

For example:

    # Japanese
    my $tree = $cldr->make_inheritance_tree( 'ja-JP' );

produces:

    ['ja-JP', 'ja', 'und']

However, there are exceptions and the path is not always linear.

For example:

    # Portugese in France
    my $tree = $cldr->make_inheritance_tree( 'pt-FR' );

produces:

    ['pt-FR', 'pt-PT', 'pt', 'und']

Why? Because the C<CLDR> (Common Locale Data Repository) specifies a special parent for locale C<pt-FR>. Those exceptions are defined in L<common/supplemental/supplementalData.xml with xpath /supplementalData/parentLocales/parentLocale|https://github.com/unicode-org/cldr/blob/2dd06669d833823e26872f249aa304bc9d9d2a90/common/supplemental/supplementalData.xml#L5414>

Another example:

    # Traditional Chinese
    my $tree = $cldr->make_inheritance_tree( 'yue-Hant' );

Normally, this parent would be C<yue>, which would lead to simplified Chinese, which would not be appropriate, so instead the C<CLDR> provides C<zh-Hant>

    ['yue-Hant', 'zh-Hant', 'und']

If an error occurred, it will set an L<error object|Locale::Unicode::Data::Exception> and return C<undef> in scalar context and an empty list in list context.

See the L<LDML specifications about inheritance|https://unicode.org/reports/tr35/tr35.html#Inheritance_and_Validity> and about L<locale inheritance and matching|https://unicode.org/reports/tr35/tr35.html#Locale_Inheritance> for more information.

=head2 metazone

    my $ref = $cldr->metazone( metazone => 'Japan' ); # Japan Standard Time
    # Returns an hash reference like this:
    {
        metazone_id => 98,
        metazone    => 'Japan',
        territories => ["001"],
        timezones   => ["Asia/Tokyo"],
    }

Returns an hash reference of a C<metazone> information from the table L<metazones|/"Table metazones"> for a given C<metazone> ID.

Quoting from the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Metazone_Names>: "A metazone is a grouping of one or more internal TZIDs that share a common display name in current customary usage, or that have shared a common display name during some particular time period. For example, the zones Europe/Paris, Europe/Andorra, Europe/Tirane, Europe/Vienna, Europe/Sarajevo, Europe/Brussels, Europe/Zurich, Europe/Prague, Europe/Berlin, and so on are often simply designated Central European Time (or translated equivalent)."

Also: "Metazones are used with the 'z', 'zzzz', 'v', and 'vvvv' date time pattern characters, and not with the 'Z', 'ZZZZ', 'VVVV' and other pattern characters for time zone formatting."

The meaning of the fields are as follows:

=over 4

=item * C<metazone_id>

A unique incremental value automatically generated by SQLite.

=item * C<metazone>

A C<metazone> ID as defined by the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Metazone_Names>

=item * C<territory>

An array of C<territory> IDs as can be found in the L<table territories|/"Table territories">, and that are associated with this C<metazone>.

=item * C<timezones>

An array of C<timezone> IDs as can be found in the L<table timezones|/"Table timezones">, and that are associated with this C<metazone>.

=back

=head2 metazones

    my $all = $cldr->metazones;

Returns all metazones information from L<table metazones|/"Table metazones"> as an array reference of hash reference.

No additional parameter is needed.

=head2 metazone_names

    my $ref = $cldr->metazone_names(
        locale      => 'en',
        metazone    => 'Japan',
        width       => 'long',
    );
    # Returns an hash reference like this:
    {
        metatz_name_id  => 4822,
        locale          => 'ja',
        metazone        => 'Japan',
        width           => 'long',
        generic         => 'Japan Time',
        standard        => 'Japan Standard Time',
        daylight        => 'Japan Daylight Time',
    }

Returns an hash reference of a C<metazone> names localised information from the table L<metazones_names|/"Table metazones_names"> for a given C<locale> ID, C<metazone> and C<width> value.

The meaning of the fields are as follows:

=over 4

=item * C<metatz_name_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<metazone>

A C<metazone> such as can be found in table L<metazones|/"Table metazones">

=item * C<width>

A C<metazone> localised name C<width>, which can be either C<long> or C<short>

Note that not all metazones names have both C<width> defined.

=item * C<generic>

The C<metazone> C<generic> name.

=item * C<standard>

The C<metazone> C<standard> name.

=item * C<standard>

The C<metazone> C<daylight> name defined if the C<metazone> use daylight saving time system.

=back

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Metazone_Names> for more information.

=head2 metazones_names

    my $all = $cldr->metazones_names;
    my $all = $cldr->metazones_names( locale => 'ja' );
    my $all = $cldr->metazones_names( width => 'long' );
    my $all = $cldr->metazones_names(
        locale  => 'ja',
        width   => 'long',
    );

Returns all C<metazone> localised formats from L<table metazones_names|/"Table metazones_names"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<metazone>

A C<metazone> such as can be found in table L<metazones|/"Table metazones">

=item * C<width>

A C<metazone> localised name C<width>, which can be either C<long> or C<short>

Note that not all timezones names have both C<width> defined.

=back

=head2 normalise

This takes a Unicode C<locale>, which can be quite complexe, and normalise it, by replacing outdated elements (C<subtag>) in the C<language>, C<script>, C<territory> or C<variant> part.

it returns a new L<Locale::Unicode> object

You can also call this method as C<normalize>

=for Pod::Coverage normalize

=head2 number_format_l10n

    my $ref = $cldr->number_format_l10n(
        locale          => 'en',
        number_system   => 'latn',
        number_type     => 'currency',
        format_length   => 'short',
        format_type     => 'standard',
        alt             => undef,
        count           => 'one',
        format_id       => 1000,
    );
    # Returns an hash reference like this:
    {
        number_format_id    => 2897,
        locale              => 'en',
        number_system       => 'latn',
        number_type         => 'currency',
        format_length       => 'short',
        format_type         => 'standard',
        format_id           => 1000,
        format_pattern      => '¤0K',
        alt                 => undef,
        count               => 'one',
    }

Returns an hash reference of a number format localised information from the table L<number_formats_l10n|/"Table number_formats_l10n"> for a given C<locale> ID, L<number system|/number_systems>, C<number_type>, C<format_length>, C<format_type>, C<alt>, C<count>, and C<format_id>. If no C<alt> value or C<count> value is provided, it will default to C<undef>

The meaning of the fields are as follows:

=over 4

=item * C<number_format_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<number_system>

A C<number_system> ID as can be found in the L<table number_systems|/"Table number_systems">

=item * C<number_type>

A string representing a number type.

Known values are: C<currency>, C<decimal>, C<misc>, C<percent>, C<scientific>

=item * C<format_length>

A string representing a format length.

Known values are: C<default>, C<long>, C<short>

=item * C<format_type>

A string representing a format type.

Known values are: C<accounting>, C<default>, C<standard>

=item * C<format_id>

A string representing a format ID.

Known values are:

=over 8

=item * C<1000>

Thousand

=item * C<10000>

10 thousand

=item * C<100000>

100 thousand

=item * C<1000000>

Million

=item * C<10000000>

10 million

=item * C<100000000>

100 million

=item * C<1000000000>

Billion

=item * C<10000000000>

10 billion

=item * C<100000000000>

100 billion

=item * C<1000000000000>

Trillion

=item * C<10000000000000>

10 trillion

=item * C<100000000000000>

100 trillion

=item * C<1000000000000000>

Quadrillion

=item * C<10000000000000000>

10 quadrillion

=item * C<100000000000000000>

100 quadrillion

=item * C<1000000000000000000>

Quintillion

=item * C<10000000000000000000>

10 quintillion

=item * C<atLeast>

=item * C<atMost>

=item * C<range>

=item * C<default>

=item * C<approximately>

=back

=item * C<format_pattern>

A string representing a localised pattern.

=item * C<alt>

A string to specify an alternative value for the same C<format_id>

=item * C<count>

A string representing a C<count>

Known values are: C<undef>, C<1>, C<few>, C<many>, C<one>, C<other>, C<two>, C<zero>

=back

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-numbers.html#Number_Formats> for more information.

=head2 number_formats_l10n

    my $all = $cldr->number_formats_l10n;
    my $all = $cldr->number_formats_l10n( locale => 'en' );
    my $all = $cldr->number_formats_l10n(
        locale          => 'en',
        number_system   => 'latn',
        number_type     => 'currency',
        format_length   => 'short',
        format_type     => 'standard',
    );

Returns all number formats localised information from L<table number_formats_l10n|/"Table number_formats_l10n"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<number_system>

A C<number_system> ID as can be found in the L<table number_systems|/"Table number_systems">

=item * C<number_type>

A string representing a number type.

Known values are: C<currency>, C<decimal>, C<misc>, C<percent>, C<scientific>

=item * C<format_length>

A string representing a format length.

Known values are: C<default>, C<long>, C<short>

=item * C<format_type>

A string representing a format type.

Known values are: C<accounting>, C<default>, C<standard>

=back

=head2 number_symbol_l10n

    my $ref = $cldr->number_symbol_l10n(
        locale          => 'en',
        number_system   => 'latn',
        property        => 'decimal',
        alt             => undef,
    );
    # Returns an hash reference like this:
    {
        number_symbol_id    => 113,
        locale              => 'en',
        number_system       => 'latn',
        property            => 'decimal',
        value               => '.',
        alt                 => undef,
    }

Returns an hash reference of a number symbol localised information from the table L<number_symbols_l10n|/"Table number_symbols_l10n"> for a given C<locale> ID, C<number_system>, C<property> value and C<alt> value. If no C<alt> value is provided, it will default to C<undef>

The meaning of the fields are as follows:

=over 4

=item * C<number_symbol_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<number_system>

A C<number_system> ID as can be found in the L<table number_systems|/"Table number_systems">

There are 69 number systems used in this L<table number_symbols_l10n|/"Table number_symbols_l10n"> out of the 88 known in the L<table number_systems|/"Table number_systems">

=item * C<property>

A string representing a number property.

Known values are: C<approximately>, C<currency_decimal>, C<currency_group>, C<decimal>, C<exponential>, C<group>, C<infinity>, C<list>, C<minus>, C<nan>, C<per_mille>, C<percent>, C<plus>, C<superscript>, C<time_separator>

Note that not all locales have all those properties defined.

For example, the C<locale> C<en> has the following properties defined for number system C<latn>: C<decimal>, C<exponential>, C<group>, C<infinity>, C<list>, C<minus>, C<nan>, C<per_mille>, C<percent>, C<plus>, C<superscript>

Whereas, the C<locale> C<ja> only has this property defined and only for the number system C<latn>: C<approximately>

This is because, it inherits from C<root>, i.e. the special C<locale> C<und>

=item * C<alt>

A string specified to provide for an alternative property value for the same property name.

=back

=head2 number_symbols_l10n

    my $all = $cldr->number_symbols_l10n;
    my $all = $cldr->number_symbols_l10n( locale => 'en' );
    my $all = $cldr->number_symbols_l10n(
        locale          => 'en',
        number_system   => 'latn',
    );

Returns all number symbols localised information from L<table number_symbols_l10n|/"Table number_symbols_l10n"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<number_system>

A C<number_system> ID as can be found in the L<table number_systems|/"Table number_systems">

=back

=head2 number_system

    my $ref = $cldr->number_system( number_system => 'jpan' );
    # Returns an hash reference like this:
    {
        numsys_id       => 35,
        number_system   => 'jpan',
        digits          => ["〇", "一", "二", "三", "四", "五", "六", "七", "八", "九"],
        type            => 'algorithmic',
    }

Returns an hash reference of a C<number_system> information from the table L<number_systems|/"Table number_systems"> for a given C<number_system> ID.

There are 88 known number systems.

The meaning of the fields are as follows:

=over 4

=item * C<numsys_id>

A unique incremental value automatically generated by SQLite.

=item * C<number_system>

A string representing a number system ID.

=item * C<digits>

An array of digits in their locale form, from 0 to 9

=item * C<type>

A string representing the type for this number system.

Known types are: C<algorithmic>, C<numeric>

=back

=head2 number_systems

     my $all = $cldr->number_systems;

Returns all number systems information from L<table number_systems|/"Table number_systems"> as an array reference of hash reference.

There are 88 known number systems:

=over 4

=item * C<adlm>

Adlam Digits

=item * C<ahom>

Ahom Digits

=item * C<arab>

Arabic-Indic Digits

=item * C<arabext>

Extended Arabic-Indic Digits

=item * C<arabext>

X Arabic-Indic Digits

=item * C<armn>

Armenian Numerals

=item * C<armnlow>

Armenian Lowercase Numerals

=item * C<bali>

Balinese Digits

=item * C<beng>

Bangla Digits

=item * C<bhks>

Bhaiksuki Digits

=item * C<brah>

Brahmi Digits

=item * C<cakm>

Chakma Digits

=item * C<cham>

Cham Digits

=item * C<cyrl>

Cyrillic Numerals

=item * C<deva>

Devanagari Digits

=item * C<diak>

Dives Akuru Digits

=item * C<ethi>

Ethiopic Numerals

=item * C<fullwide>

Full-Width Digits

=item * C<geor>

Georgian Numerals

=item * C<gong>

Gunjala Gondi digits

=item * C<gonm>

Masaram Gondi digits

=item * C<grek>

Greek Numerals

=item * C<greklow>

Greek Lowercase Numerals

=item * C<gujr>

Gujarati Digits

=item * C<guru>

Gurmukhi Digits

=item * C<hanidays>

Chinese Calendar Day-of-Month Numerals

=item * C<hanidec>

Chinese Decimal Numerals

=item * C<hans>

Simplified Chinese Numerals

=item * C<hansfin>

Simplified Chinese Financial Numerals

=item * C<hant>

Traditional Chinese Numerals

=item * C<hantfin>

Traditional Chinese Financial Numerals

=item * C<hebr>

Hebrew Numerals

=item * C<hmng>

Pahawh Hmong Digits

=item * C<hmnp>

Nyiakeng Puachue Hmong Digits

=item * C<java>

Javanese Digits

=item * C<jpan>

Japanese Numerals

=item * C<jpanfin>

Japanese Financial Numerals

=item * C<jpanyear>

Japanese Calendar Gannen Year Numerals

=item * C<kali>

Kayah Li Digits

=item * C<kawi>

Kawi Digits

=item * C<khmr>

Khmer Digits

=item * C<knda>

Kannada Digits

=item * C<lana>

Tai Tham Hora Digits

=item * C<lanatham>

Tai Tham Tham Digits

=item * C<laoo>

Lao Digits

=item * C<latn>

Western Digits

=item * C<lepc>

Lepcha Digits

=item * C<limb>

Limbu Digits

=item * C<mathbold>

Mathematical Bold Digits

=item * C<mathdbl>

Mathematical Double-Struck Digits

=item * C<mathmono>

Mathematical Monospace Digits

=item * C<mathsanb>

Mathematical Sans-Serif Bold Digits

=item * C<mathsans>

Mathematical Sans-Serif Digits

=item * C<mlym>

Malayalam Digits

=item * C<modi>

Modi Digits

=item * C<mong>

Mongolian Digits

=item * C<mroo>

Mro Digits

=item * C<mtei>

Meetei Mayek Digits

=item * C<mymr>

Myanmar Digits

=item * C<mymrshan>

Myanmar Shan Digits

=item * C<mymrtlng>

Myanmar Tai Laing Digits

=item * C<nagm>

Nag Mundari Digits

=item * C<newa>

Newa Digits

=item * C<nkoo>

N’Ko Digits

=item * C<olck>

Ol Chiki Digits

=item * C<orya>

Odia Digits

=item * C<osma>

Osmanya Digits

=item * C<rohg>

Hanifi Rohingya digits

=item * C<roman>

Roman Numerals

=item * C<romanlow>

Roman Lowercase Numerals

=item * C<saur>

Saurashtra Digits

=item * C<segment>

Segmented Digits

=item * C<shrd>

Sharada Digits

=item * C<sind>

Khudawadi Digits

=item * C<sinh>

Sinhala Lith Digits

=item * C<sora>

Sora Sompeng Digits

=item * C<sund>

Sundanese Digits

=item * C<takr>

Takri Digits

=item * C<talu>

New Tai Lue Digits

=item * C<taml>

Traditional Tamil Numerals

=item * C<tamldec>

Tamil Digits

=item * C<telu>

Telugu Digits

=item * C<thai>

Thai Digits

=item * C<tibt>

Tibetan Digits

=item * C<tirh>

Tirhuta Digits

=item * C<tnsa>

Tangsa Digits

=item * C<vaii>

Vai Digits

=item * C<wara>

Warang Citi Digits

=item * C<wcho>

Wancho Digits

=back

=head2 number_system_l10n

    my $ref = $cldr->number_system_l10n(
        number_system => 'jpan',
        locale => 'en',
    );
    # Returns an hash reference like this:
    {
        num_sys_l10n_id => 1335,
        locale          => 'en',
        number_system   => 'jpan',
        locale_name     => 'Japanese Numerals',
        alt             => undef,
    }

Returns an hash reference of a C<number_system> localised information from the table L<number_systems_l10n|/"Table number_systems_l10n"> for a given C<number_system> ID and a C<locale> ID.

There are 190 known localised information for number systems.

The meaning of the fields are as follows:

=over 4

=item * C<num_sys_l10n_id>

A unique incremental value automatically generated by SQLite.

=item * C<number_system>

A string representing a number system ID.

=item * C<locale_name>

A string representing the number system in the C<locale>

=item * C<alt>

A string specifying an alternative version for an otherwise same number system.

=back

=head2 number_systems_l10n

     my $all = $cldr->number_systems_l10n;

Returns all number systems localised information from L<table number_systems_l10n|/"Table number_systems_l10n"> as an array reference of hash reference.

=head2 person_name_default

    my $ref = $cldr->person_name_default( locale => 'ja' );
    # Returns an hash reference like this:
    {
        pers_name_def_id    => 3,
        locale              => 'ja',
        value               => 'surnameFirst',
    }

Returns an hash reference of a person name defaults information from the table L<person_name_defaults|/"Table person_name_defaults"> for a given C<locale> ID.

Be aware that there are very few data. This is because the entry for locale C<und> (undefined), contains the default value. Thus, if there is no data for the desired locale, you should fallback to C<und>

This is the way the Unicode CLDR data is structured.

=head2 person_name_defaults

    my $all = $cldr->person_name_defaults;

Returns all person name defaults information from L<table person_name_defaults|/"Table person_name_defaults"> as an array reference of hash reference.

=head2 plural_count

    my $str = $cldr->plural_count( 3, 'ja-t-de-t0-und-x0-medical' );
    # "other"
    my $str = $cldr->plural_count( -2, 'he-IL-u-ca-hebrew-tz-jeruslm' );
    # "two"
    my $str = $cldr->plural_count( 3.5, 'ru' );
    # "other"

Provided with a number, and a C<locale>, and this will return a string representing the type of C<count> for the plural value, which may be one of C<zero>, C<one>, C<two>, C<few>, C<many> or C<other>

This is used for example by L<DateTime::Format::RelativeTime> to query L<time_relative_l10n|/time_relative_l10n> to get the localised relative time value.

If an error has occurred, this will set an L<error object|Locale::Unicode::Data::Exception>, and return C<undef> in scalar context, or an empty list in list context.

See also L<plural_range|/plural_range> and L<plural_rule|/plural_rule>

=head2 plural_range

    my $ref = $cldr->plural_range(
        locale => 'am',
        start  => 'one',
        stop   => 'other',
    );
    # Returns an hash reference like this:
    {
        plural_range_id => 1335,
        locale          => 'am',
        aliases         => [qw(as bn gu hi hy kn mr ps zu)],
        start           => 'one',
        stop            => 'other',
        result          => 'other',
    }

Returns an hash reference of a C<plural_range> information from the table L<plural_ranges|/"Table plural_ranges"> for a given C<start> count, a C<stop> count and a C<locale> ID.

For example:

    my $num   = '2-7';
    my $range = [split( /-/, $num, 2 )];
    # Will get a string like: zero, one, two, few, many, or other
    my $start = $cldr->plural_count( $range->[0], $locale );
    my $end   = $cldr->plural_count( $range->[1], $locale );
    my $ref   = $cldr->plural_range( locale => $locale, start => $start, stop => $end );
    # zero, one, two, few, many, or other
    my $count = $ref->{result};
    my $def   = $cldr->time_relative_l10n(
        locale => $locale,
        # For example: second, minute, hour, day, week, month, quarter, or year
        field_type => $unit,
        # long, short or narrow
        field_length => $this_style,
        # -1 for past, or 1 for present or future
        relative => substr( $num, 0, 1 ) eq '-' ? -1 : 1,
        count => $count,
    );
    # Resulting in a pattern containing {0} that needs to be replaced with the range
    $def->{pattern} =~ s/\{0\}/$num/;
    say $def->{pattern};

The meaning of the fields are as follows:

=over 4

=item * C<plural_range_id>

A unique incremental value automatically generated by SQLite.

=item * C<aliases>

An array reference of C<locale> values.

=item * C<start>

A string representing the starting count value.

=item * C<stop>

A string representing the ending count value.

=item * C<result>

A string representing the resulting count value.

=back

=head2 plural_ranges

    my $all = $cldr->plural_ranges;
    my $all = $cldr->plural_ranges( locale => 'he' );
    my $all = $cldr->plural_ranges( start => 'one' );
    my $all = $cldr->plural_ranges( start => 'one', stop => 'many' );
    my $all = $cldr->plural_ranges( result => 'other' );

Returns all plural ranges information from L<table plural_ranges|/"Table plural_ranges"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale> such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<start>

A string representing the starting count value.

=item * C<stop>

A string representing the ending count value.

=item * C<result>

A string representing the resulting count value.

=back

=head2 plural_rule

    my $ref = $cldr->plural_rule(
        locale => 'am',
        count  => 'one',
    );
    # Returns an hash reference like this:
    {
        plural_rule_id => 1335,
        locale          => 'am',
        aliases         => [qw(as bn doi fa gu hi kn pcm zu)],
        count           => 'one',
        rule            => 'i = 0 or n = 1 @integer 0, 1 @decimal 0.0~1.0, 0.00~0.04',
    }

Returns an hash reference of a C<plural_rule> information from the table L<plural_rules|/"Table plural_rules"> for a given C<start> count, a C<stop> count and a C<locale> ID.

The meaning of the fields are as follows:

=over 4

=item * C<plural_rule_id>

A unique incremental value automatically generated by SQLite.

=item * C<aliases>

An array reference of C<locale> values.

=item * C<count>

A string representing the count value.

=item * C<rule>

A string representing the plural rule.

=back

See also the L<Unicode documentation|https://unicode.org/reports/tr35/tr35-numbers.html#Language_Plural_Rules>, and L<also here|https://cldr.unicode.org/index/cldr-spec/plural-rules>, and L<here|https://unicode.org/reports/tr35/tr35-dates.html#Contents>.

=head2 plural_rules

    my $all = $cldr->plural_rules;
    my $all = $cldr->plural_rules( locale => 'he' );
    my $all = $cldr->plural_rules( count => 'one' );

Returns all plural ranges information from L<table plural_rules|/"Table plural_rules"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale> such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<aliases>

An array reference of C<locale> values.

=item * C<count>

A string representing the count value.

=back

See also the L<Unicode documentation|https://unicode.org/reports/tr35/tr35-numbers.html#Language_Plural_Rules>, and L<also here|https://cldr.unicode.org/index/cldr-spec/plural-rules>, and L<here|https://unicode.org/reports/tr35/tr35-dates.html#Contents>.

=head2 rbnf

    my $ref = $cldr->rbnf(
        locale => 'ja',
        ruleset => 'spellout-cardinal',
        rule_id => 7,
    );
    # Returns an hash reference like this:
    {
        rbnf_id     => 7109,
        locale      => 'ja',
        grouping    => 'SpelloutRules',
        ruleset     => 'spellout-cardinal',
        rule_id     => '7',
        rule_value  => '七;',
    }

Returns an hash reference of a RBNF (Rule-Based Number Format) information from the table L<rbnf|/"Table rbnf"> for a given C<locale> ID, a rule set C<ruleset> and a rule ID C<rule_id>.

The meaning of the fields are as follows:

=over 4

=item * C<rbnf_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<grouping>

A string representing a C<RBNF> grouping.

Known values are: C<NumberingSystemRules>, C<OrdinalRules>, C<SpelloutRules>

=item * C<ruleset>

A string representing the rule set name.

=item * C<rule_id>

A string representing the rule ID.

=item * C<rule_value>

A string containing the rule value.

Make sure to read the C<LDML> documentation, as it may contain information to alias this rule on another one.

=back

=head2 rbnfs

    my $all = $cldr->rbnfs;
    my $all = $cldr->rbnfs( locale => 'ko' );
    my $all = $cldr->rbnfs( grouping => 'SpelloutRules' );
    my $all = $cldr->rbnfs( ruleset => 'spellout-cardinal-native' );

Returns all RBNF (Rule-Based Number Format) information from L<table rbnf|/"Table rbnf"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<grouping>

A group value. Known values are: C<NumberingSystemRules>, C<OrdinalRules> and C<SpelloutRules>

=item * C<locale>

A C<locale> such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<ruleset>

The name of a rule set.

=back

=head2 reference

    my $ref = $cldr->reference( code => 'R1131' );
    # Returns an hash reference like this:
    {
        ref_id  => 132,
        code    => 'R1131',
        uri     => 'http://en.wikipedia.org/wiki/Singapore',
        description => 'English is the first language learned by half the children by the time they reach preschool age; using 92.6% of pop for the English figure',
    }

Returns an hash reference of a reference information from the table L<refs|/"Table refs"> for a given C<code>.

=head2 references

    my $all = $cldr->references;

Returns all reference information from L<table refs|/"Table refs"> as an array reference of hash reference.

No additional parameter is needed.

=head2 script

    my $ref = $cldr->script( script => 'Jpan' );
    # Returns an hash reference like this:
    {
        script_id       => 73,
        script          => 'Jpan',
        rank            => 5,
        sample_char     => '3048',
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
    }

Returns an hash reference of a C<script> information from the table L<scripts|/"Table scripts"> for a given C<script> ID.

The meaning of the fields are as follows:

The information is quoted directly from the C<CLDR> data.

=over 4

=item * C<script_id>

A unique incremental value automatically generated by SQLite.

=item * C<script>

A string representing a C<script> ID

=item * C<rank>

"The approximate rank of this script from a large sample of the web, in terms of the number of characters found in that script. Below 32 the ranking is not statistically significant."

=item * C<sample_char>

"A sample character for use in "Last Resort" style fonts. For printing the combining mark for Zinh in a chart, U+25CC can be prepended. See http://unicode.org/policies/lastresortfont_eula.html"

=item * C<id_usage>

"The usage for IDs (tables 4-7) according to UAX #31."

For a description of values, see

L<http://unicode.org/reports/tr31/#Table_Candidate_Characters_for_Exclusion_from_Identifiers>

=item * C<rtl>

True "if the script is RTL. Derived from whether the script contains RTL letters according to the Bidi_Class property"

=item * C<lb_letters>

True "if the major languages using the script allow linebreaks between letters (excluding hyphenation). Derived from LB property."

=item * C<has_case>

True "if in modern (or most recent) usage case distinctions are customary."

=item * C<shaping_req>

True "if shaping is required for the major languages using that script for NFC text. This includes not only ligation (and Indic conjuncts), Indic vowel splitting/reordering, and Arabic-style contextual shaping, but also cases where NSM placement is required, like Thai. MIN if NSM placement is sufficient, not the more complex shaping. The NSM placement may only be necessary for some major languages using the script."

=item * C<ime>

Input Method Engine.

True "if the major languages using the script require IMEs. In particular, users (of languages for that script) would be accustomed to using IMEs (such as Japanese) and typical commercial products for those languages would need IME support in order to be competitive."

=item * C<density>

"The approximate information density of characters in this script, based on comparison of bilingual texts."

=item * C<origin_country>

"The approximate area where the script originated, expressed as a BCP47 region code."

=item * C<likely_language>

The likely C<language> associated with this C<script>

=item * C<status>

A string representing the status for this C<script>

Known values are: C<deprecated>, C<private_use>, C<regular>, C<reserved>, C<special>, C<unknown>

=back

See also the L<Unicode list of known scripts|https://www.unicode.org/iso15924/iso15924-codes.html>

=head2 scripts

    my $all = $cldr->scripts;
    my $all = $cldr->scripts( rtl => 1 );
    my $all = $cldr->scripts( origin_country => 'FR' );
    my $all = $cldr->scripts( likely_language => 'fr' );

Returns all scripts information from L<table scripts|/"Table scripts"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<likely_language>

A C<locale> such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<origin_country>

A C<territory> code as can be found in table L<territories|/"Table territories">

=item * C<rtl>

A boolean value. C<0> for false and C<1> for true.

=back

=head2 script_l10n

    my $ref = $cldr->script_l10n(
        locale  => 'en',
        script  => 'Latn',
        alt     => undef,
    );
    # Returns an hash reference like this:
    {
        scripts_l10n_id => 3636,
        locale          => 'en',
        script          => 'Latn',
        locale_name     => 'Latin',
        alt             => undef,
    }

Returns an hash reference of a C<script> localised information from the table L<scripts_l10n|/"Table scripts_l10n"> for a given C<script> ID and a C<locale> ID and a C<alt> value. If no C<alt> value is provided, it will default to C<undef>

The meaning of the fields are as follows:

=over 4

=item * C<scripts_l10n_id>

This is a unique incremental integer automatically generated by SQLite.

=item * C<locale>

A C<locale> such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<script>

A 3 to 4-characters script ID as can be found in the L<table scripts|/"Table scripts">

=item * C<locale_name>

The localised script name based on the C<locale> specified.

=item * C<alt>

A string, that is optional, and is used to provide an alternative version. Known C<alt> values are: C<undef>, C<secondary>, C<short>, C<stand-alone>, C<variant>

=back

=head2 scripts_l10n

    my $all = $cldr->scripts_l10n;
    my $all = $cldr->scripts_l10n( locale => 'en' );
    my $all = $cldr->scripts_l10n(
        locale  => 'en',
        alt     => undef,
    );

Returns all localised scripts information from L<table scripts_l10n|/"Table scripts_l10n"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale> such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<alt>

A string, that is optional, and is used to provide an alternative version. Known C<alt> values are: C<undef>, C<secondary>, C<short>, C<stand-alone>, C<variant>

=back

=head2 split_interval

    my $ref = $cldr->split_interval(
        pattern => $string,
        greatest_diff => 'd',
    ) || die( $cldr->error );

This takes an hash or hash reference of options and it returns a 4-elements array reference containing:

=over 4

=item 1. first part of the pattern

=item 2. the separator, which may be an empty string

=item 3. second part of the pattern

=item 4. the best repeating pattern found

=back

The required options are:

=over 4

=item * C<greatest_diff>

A token representing the greatest difference.

Known values are: C<B>, C<G>, C<H>, C<M>, C<a>, C<d>, C<h>, C<m>, C<y>

See L</"Format Patterns"> for their meaning.

=item * C<pattern>

A interval pattern, such as one you can get with the method L<calendar_interval_format|/calendar_interval_format>

=back

This method is provided as a convenience, but the L<interval formats data|/calendar_interval_format> in L<the database|/"Table calendar_interval_formats"> have already been pre-processed, so you do not have to do it.

=head2 subdivision

    my $ref = $cldr->subdivision( subdivision => 'jp12' );
    # Returns an hash reference like this:
    {
        subdivision_id  => 2748,
        territory       => 'JP',
        subdivision     => 'jp12',
        parent          => 'JP',
        is_top_level    => 1,
        status          => 'regular',
    }

Returns an hash reference of a subdivision information from the table L<subdivisions|/"Table subdivisions"> for a given C<subdivision> ID.

The meaning of the fields are as follows:

=over 4

=item * C<subdivision_id>

A unique incremental value automatically generated by SQLite.

=item * C<territory>

A C<territory> ID, such as can be found in table L<territories|/"Table territories">

=item * C<subdivision>

A string representing a C<subdivision> ID

=item * C<parent>

A string representing a parent for this C<subdivision>. It can be either another C<subdivision> ID, or a C<territory> ID, if this is a top C<subdivision>

=item * C<is_top_level>

A boolean value representing whether this C<subdivision> is directly under a C<territory> or rather under another C<subdivision>

=item * C<status>

A string representing the status for this C<subdivision>.

Known values are: C<deprecated>, C<regular>, C<unknown>

=back

=head2 subdivisions

    my $all = $cldr->subdivisions;
    my $all = $cldr->subdivisions( territory => 'JP' );
    my $all = $cldr->subdivisions( parent => 'US' );
    my $all = $cldr->subdivisions( is_top_level => 1 );

Returns all subdivisions information from L<table subdivisions|/"Table subdivisions"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<is_top_level>

A boolean value. C<0> for false and C<1> for true.

=item * C<parent>

A C<territory> code as can be found in table L<territories|/"Table territories">

=item * C<territory>

A C<territory> code as can be found in table L<territories|/"Table territories">

=back

=head2 subdivision_l10n

    my $ref = $cldr->subdivision_l10n(
        locale      => 'en',
        # Texas
        subdivision => 'ustx',
    );
    # Returns an hash reference like this:
    {
        subdiv_l10n_id  => 56463,
        locale          => 'en',
        subdivision     => 'ustx',
        locale_name     => 'Texas',
    }

Returns an hash reference of a C<subdivision> localised information from the table L<subdivisions_l10n|/"Table subdivisions_l10n"> for a given C<subdivision> ID and a C<locale> ID.

The meaning of the fields are as follows:

=over 4

=item * C<subdiv_l10n_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<subdivision>

A C<subdivision> ID as can be found from the L<table subdivisions|/"Table subdivision">

=item * C<locale_name>

A string representing the localised name of the C<subdivision> in the C<locale> specified.

=back

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35.html#Unicode_Subdivision_Codes> for more information.

=head2 subdivisions_l10n

    my $all = $cldr->subdivisions_l10n;
    my $all = $cldr->subdivisions_l10n( locale => 'en' );

Returns all subdivisions localised information from L<table subdivisions_l10n|/"Table subdivisions_l10n"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=back

=head2 territory

    my $ref = $cldr->territory( territory => 'FR' );
    # Returns an hash reference like this:
    {
        territory_id        => 118,
        territory           => 'FR',
        parent              => 155,
        gdp                 => 2856000000000,
        literacy_percent    => 99,
        population          => 67848200,
        languages           => ["fr", "en", "es", "de", "oc", "it", "pt", "pcd", "gsw", "br", "co", "hnj", "ca", "eu", "nl", "frp", "ia"],
        contains            => undef,
        currency            => 'EUR',
        calendars           => undef,
        min_days            => 4,
        first_day           => 1,
        weekend             => undef,
        status              => 'regular',
    }

Returns an hash reference of a territory information from the table L<territories|/"Table territories"> for a given C<territory> ID.

The meaning of the fields are as follows:

=over 4

=item * C<territory>

A 2-characters code designating a country code, which may not necessarily be an active ISO 3166 code, because the CLDR keeps outdated ones for consistency.

It can also be a 3-digits world region code.

=item * C<parent>

A C<parent> territory, if one is defined. For example, France (C<FR>) has parent C<155> representing Western Europe, which has parent C<150>, representing Europe, which, itself, has parent C<001>, representing the world.

=item * C<gdp>

The territory GDP (Gross Domestic Product), which may be C<undef>, especially for world region.

=item * C<literacy_percent>

The literacy percentage of the population expressed as a decimal. For example, a value of C<99> means 99%

=item * C<population>

The territory population as an integer.

=item * C<languages>

The languages known to be spoken in this territory, as an array of C<language> IDs. For significant languages, you can get more information, such as their share of the population with L<language_population|/language_population>

=item * C<contains>

An array of C<territory> codes contained by this territory. This may be C<undef>

This value is typically set for world C<region> codes and for special territories like C<EU>, C<EZ>, C<QO> and C<UN>

=item * C<currency>

The official C<currency> used in this territory. This may be C<undef> such as for world regions.

=item * C<calendars>

An array of L<calendar systems|/calendar> used in this C<territory>

=item * C<min_days>

This is used to decide if the week starting with C<first_day> is to ne included in the calendar as the first week of the new yer or last week of the previous year.

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Week_Data>

=item * C<first_day>

The first day of the week. Although in the Unicode LDML, the I<weekday names are identified with short strings, since there is no universally-accepted numeric designation>, here the value used is an integer from C<1> (Monday) to C<7> (Sunday)

=item * C<weekend>

An array of week days (identified by integers as explained in C<first_day>). This value may be null, in which case, the default value to be used is the one set in the World region (C<001>), which is C<[6,7]>, i.e. Saturday and Sunday.

=item * C<status>

A string representing the C<status> for this territory.

Known C<status> values are: C<deprecated>, C<macroregion>, C<private_use>, C<regular>, C<reserved>, C<special>, C<unknown>

=back

=head2 territories

    my $all = $cldr->territories;
    my $all = $cldr->territories( parent => 150 );

Returns all territories information from L<table territories|/"Table territories"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<parent>

A C<territory> code as can be found in table L<territories|/"Table territories">

=back

=head2 territory_l10n

    my $ref = $cldr->territory_l10n(
        locale      => 'en',
        territory   => 'JP',
        alt         => undef,
    );
    # Returns an hash reference like this:
    {
        terr_l10n_id    => 13385,
        locale          => 'en',
        territory       => 'JP',
        locale_name     => 'Japan',
        alt             => undef,
    }

Returns an hash reference of a territory localised information from the table L<territories_l10n|/"Table territories_l10n"> for a given C<territory> ID and a C<locale> ID and an C<alt> value. If no C<alt> value is provided, it will default to C<undef>

The meaning of the fields are as follows:

=over 4

=item * C<terr_l10n_id>

This is a unique incremental integer automatically generated by SQLite.

=item * C<locale>

A C<locale> such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<territory>

A 2-characters country code or a 3-digits region code as can be found in the L<table territories|/"Table territories">

=item * C<locale_name>

The localised territory name based on the C<locale> specified.

=item * C<alt>

A string, that is optional, and is used to provide an alternative version. Known C<alt> values are: C<undef>, C<biot>, C<chagos>, C<short>, C<variant>

=back

=head2 territories_l10n

    my $all = $cldr->territories_l10n;
    my $all = $cldr->territories_l10n( locale => 'en' );
    my $all = $cldr->territories_l10n(
        locale  => 'en',
        alt     => undef,
    );

Returns all localised territories information from L<table territories_l10n|/"Table territories_l10n"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale> such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<alt>

A string, that is optional, and is used to provide an alternative version. Known C<alt> values are: C<undef>, C<biot>, C<chagos>, C<short>, C<variant>

=back

=head2 time_format

    my $ref = $cldr->time_format( region => 'JP' );
    # Returns an hash reference like this:
    {
        time_format_id  => 86,
        region          => 'JP',
        territory       => 'JP',
        locale          => undef,
        time_format     => 'H',
        time_allowed    =>  ["H", "K", "h"],
    }

Returns an hash reference of a time format information from the table L<time_formats|/"Table time_formats"> for a given C<region> ID.

The meaning of the fields are as follows:

=over 4

=item * C<time_format_id>

A unique incremental value automatically generated by SQLite.

=item * C<region>

A string representing a C<region>, which can be a C<territory> code, such as C<US> or C<419>, or a C<language> ID with a C<territory> ID, such as C<it-CH> or C<en-001>.

=item * C<territory>

A string representing the C<territory> part of the C<region> as can be found in L<table territories|/"Tabke territories">

=item * C<locale>

A string representing the C<locale> part of the C<region> value.

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<time_format>

A short string representing a time format.

Known values are: C<H> and C<h>

=item * C<time_allowed>

An array of format allowed.

For example:

    ["H","h","hB","hb"]

=back

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Time_Data> for more information.

=head2 time_formats

    my $all = $cldr->time_formats;
    my $all = $cldr->time_formats( region => 'US' );
    my $all = $cldr->time_formats( territory => 'JP' );
    my $all = $cldr->time_formats( locale => undef );
    my $all = $cldr->time_formats( locale => 'en' );

Returns all time formats information from L<table time_formats|/"Table time_formats"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale> such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<region>

A C<territory> code as can be found in table L<territories|/"Table territories">

=item * C<territory>

A C<territory> code as can be found in table L<territories|/"Table territories">

=back

=head2 time_relative_l10n

    my $ref = $cldr->time_relative_l10n(
        locale          => 'en',
        field_type      => 'day',
        field_length    => 'short',
        relative        => -1,
        # optionally a 'count' value; defaults to 'one'
        # count         => 'one'
    );
    # Returns an hash reference like this:
    {
        time_relative_id    => 2087,
        locale              => 'en',
        field_type          => 'day',
        field_length        => 'short',
        relative            => -1,
        format_pattern      => '{0} day ago',
        count               => 'one',
    }

Returns an hash reference of a field localised information from the table L<time_relative_l10n|/"Table time_relative_l10n"> for a given C<locale> ID, C<field_type>, C<field_length> and C<relative> value.

The meaning of the fields are as follows:

=over 4

=item * C<time_relative_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<field_type>

A string representing a field type.

Known values are: C<day>, C<fri>, C<hour>, C<minute>, C<mon>, C<month>, C<quarter>, C<sat>, C<second>, C<sun>, C<thu>, C<tue>, C<wed>, C<week>, C<year>

=item * C<field_length>

A string representing a field length.

Known values are: C<narrow>, C<short>, C<standard>

=item * C<relative>

An integer representing the relative value of the field. For example, C<-1> being the past, and C<1> being the future.

Posible values are: C<-1>, C<1>

=item * C<format_pattern>

A string containing the localised pattern based on the C<locale>

=item * C<count>

A string representing the count for the pattern. If none is provided, it defaults to C<one>

Possible values may be: C<zero>, C<one>, C<two>, C<few>, C<many>, C<other>

=back

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Calendar_Fields> for more information.

=head2 time_relatives_l10n

    my $all = $cldr->time_relatives_l10n;
    my $all = $cldr->time_relatives_l10n( locale => 'en' );
    my $all = $cldr->time_relatives_l10n(
        locale          => 'en',
        field_type      => 'day',
        field_length    => 'short',
    );

Returns all time relative localised information from L<table time_relative_l10n|/"Table time_relative_l10n"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<field_type>

A string representing a field type.

Known values are: C<day>, C<fri>, C<hour>, C<minute>, C<mon>, C<month>, C<quarter>, C<sat>, C<second>, C<sun>, C<thu>, C<tue>, C<wed>, C<week>, C<year>

=item * C<field_length>

A string representing a field length.

Known values are: C<narrow>, C<short>, C<standard>

=item * C<count>

A string representing the count for the pattern.

Possible values may be: C<zero>, C<one>, C<two>, C<few>, C<many>, C<other>

=back

=head2 timezone

    my $ref = $cldr->timezone( timezone => 'Asia/Tokyo' );
    # Returns an hash reference like this:
    {
        timezone_id => 281,
        timezone    => 'Asia/Tokyo',
        territory   => 'JP',
        region      => 'Asia',
        tzid        => 'japa',
        metazone    => 'Japan',
        tz_bcpid    => 'jptyo',
        is_golden   => 1,
        is_primary  => 0,
        is_preferred => 0,
        is_canonical => 0,
    }

Returns an hash reference of a time zone information from the table L<timezones|/"Table timezones"> based on the C<timezone> ID provided.

The meaning of the fields are as follows:

=over 4

=item * C<timezone_id>

A unique incremental value automatically generated by SQLite.

=item * C<timezone>

A C<timezone> ID

=item * C<territory>

A string representing a C<territory> code as can be found in L<table territories|/"Table territories">

=item * C<region>

A string representing a world region.

Known regions are; C<Africa>, C<America>, C<Antarctica>, C<Arctic>, C<Asia>, C<Atlantic>, C<Australia>, C<CST6CDT>, C<EST5EDT>, C<Etc>, C<Europe>, C<Indian>, C<MST7MDT>, C<PST8PDT>, C<Pacific>

=item * C<tzid>

A string representing a timezone ID

=item * C<metazone>

A string representing a metazone ID

=item * C<tz_bcpid>

A boolean specifying whether this timezone ID is also a BCP47 C<timezone>.

=item * C<is_golden>

A boolean specifying whether this timezone is a golden timezone.

A C<timezone> is deemed C<golden> if it is specified in the C<CLDR> as part of the L<primaryZones|https://unicode.org/reports/tr35/tr35-dates.html#Primary_Zones> or if the C<timezone> territory is C<001> (World).

As explained in the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Using_Time_Zone_Names>, "[t]he golden zones are those in mapZone supplemental data under the territory C<001>."

=item * C<is_primary>

A boolean specifying whether this timezone is a primary timezone.

As explained in the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Primary_Zones>, this "specifies the dominant zone for a region; this zone should use the region name for its generic location name even though there are other canonical zones available in the same region. For example, C<Asia/Shanghai> is displayed as C<China Time>, instead of C<Shanghai Time>"

=item * C<is_preferred>

A boolean specifying whether this timezone is the preferred timezone for this C<metazone>

=item * C<is_canonical>

A boolean specifying whether this timezone is the canonical timezone, since it can have multiple aliases.

=back

=head2 timezones

    my $array_ref = $cldr->timezones;
    # Or, providing with some filtering arguments
    # Returns all the timezones for the country code 'JP'
    my $array_ref = $cldr->timezones( territory => 'JP' );
    # Returns all the timezones for the region code 'Asia'
    my $array_ref = $cldr->timezones( region => 'Asia' );
     # Returns all the timezones that match the CLDR timezone ID 'japa'
    my $array_ref = $cldr->timezones( tzid => 'japa' );
     # Returns all the timezones that match the BCP47 timezone ID 'jptyo'
    my $array_ref = $cldr->timezones( tz_bcpid => 'jptyo' );
     # Returns all the timezones that have the CLDR metazone 'Japan'
    my $array_ref = $cldr->timezones( metazone => 'Japan' );
    # Returns all the timezones that are 'golden' timezones
    my $array_ref = $cldr->timezones( is_golden => 1 );
    my $array_ref = $cldr->timezones( is_primary => 1 );
    my $array_ref = $cldr->timezones( is_canonical => 1 );

Returns all the C<timezone> information as an array reference of hash reference from the L<table timezones|/"Table timezones">

You can adjust the data return by using a combination of the following filtering arguments:

=over 4

=item * C<territory>

A C<territory> code as can be found in table L<territories|/"Table territories">

=item * C<region>

A world region. Known values are: C<Africa>, C<America>, C<Antarctica>, C<Arctic>, C<Asia>, C<Atlantic>, C<Australia>, C<CST6CDT>, C<EST5EDT>, C<Etc>, C<Europe>, C<Indian>, C<MST7MDT>, C<PST8PDT>, C<Pacific>

=item * C<tzid>

A Unicode timezone ID

=item * C<tz_bcpid>

A Unicode BCP47 timezone ID.

=item * C<metazone>

A Unicode metazone ID.

=item * C<is_golden>

A boolean expressing whether this time zone is C<golden> (in Unicode parlance), or not. C<1> for true, and C<0> for false.

=item * C<is_primary>

A boolean specifying whether this timezone is a primary timezone.

=item * C<is_canonical>

A boolean specifying whether this timezone is the canonical timezone, since it can have multiple aliases.

=back

=head2 timezone_canonical

    my $str = $cldr->timezone_canonical( 'Europe/Paris' );
    # Europe/Paris
    my $str = $cldr->timezone_canonical( 'America/Atka' );
    # America/Adak
    my $str = $cldr->timezone_canonical( 'US/Aleutian' );
    # America/Adak

Provided with a C<timezone>, and this returns the canonical timezone corresponding.

If no matching C<timezone> could be found, an empty string is returned.

If an error occurred, this sets an L<exception object|Locale::Unicode::Data::Exception>, and returns C<undef> in scalar context, and an empty list in list context.

=head2 timezone_city

    my $ref = $cldr->timezone_city(
        locale   => 'de',
        timezone => 'Asia/Tokyo',
    );
    # Returns an hash reference like this:
    {
        tz_city_id  => 7486,
        locale      => 'de',
        timezone    => 'Asia/Tokyo',
        city        => 'Tokio',
        alt         => undef,
    }

Returns an hash reference of a C<timezone> localised exemplar city from the table L<timezones_cities|/"Table timezones_cities"> for a given C<locale> ID, C<timezone> and C<alt> value. If no C<alt> value is provided, it will default to C<undef>

The behaviour of this method is altered depending on whether L<extend_timezones_cities|/extend_timezones_cities> is set to a true boolean value or not. If set to true, this will retrieve the data from the table C<timezones_cities_extended> instead of the C<timezones_cities>

By default, L<extend_timezones_cities|/extend_timezones_cities> is set to true, and the L<Locale::Unicode::Data> distribution comes with an extended set of time zones cities. The default Unicode CLDR data comes only with a minimal set.

This method is especially used to format the pattern characters C<v> and C<V>. See the section on L<Format Patterns|/"Format Patterns"> for more about this.

The meaning of the fields are as follows:

=over 4

=item * C<tz_city_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<timezone>

A C<timezone> ID as can be found in the L<table timezones|/"Table timezones">

=item * C<city>

A localised version of a representative city for this given C<timezone>.

Note that not all locales have a localised city for all timezones.

=item * C<alt>

A string specified to provide for an alternative city value for the same city name.

Known values are: C<undef> and C<secondary>

=back

=head2 timezones_cities

    my $all = $cldr->timezones_cities;
    my $all = $cldr->timezones_cities( locale => 'ja' );
    my $all = $cldr->timezones_cities(
        locale  => 'ja',
        alt     => undef,
    );

Returns all timezone localised representative city name from L<table timezones_cities|/"Table timezones_cities"> as an array reference of hash reference.

The behaviour of this method is altered depending on whether L<extend_timezones_cities|/extend_timezones_cities> is set to a true boolean value or not. If set to true, this will retrieve the data from the table C<timezones_cities_extended> instead of the C<timezones_cities>

By default, L<extend_timezones_cities|/extend_timezones_cities> is set to true, and the L<Locale::Unicode::Data> distribution comes with an extended set of time zones cities. The default Unicode CLDR data comes only with a minimal set.

This method is especially used to format the pattern characters C<v> and C<V>. See the section on L<Format Patterns|/"Format Patterns"> for more about this.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<alt>

A string used to differentiate two version of a localised city name.

Known values are: C<undef> and C<secondary>

=back

=head2 timezone_formats

    my $ref = $cldr->timezone_formats(
        locale  => 'en',
        type    => 'region',
        subtype => 'standard',
    );
    # Returns an hash reference like this:
    {
        tz_fmt_id       => 145,
        locale          => 'en',
        type            => 'region',
        subtype         => 'standard',
        format_pattern  => '{0} Standard Time',
    }

Returns an hash reference of a C<timezone> formats localised information from the table L<timezones_formats|/"Table timezones_formats"> for a given C<locale> ID, C<type> and optional C<subtype> value. If no C<subtype> value is provided, it will default to C<undef>

The meaning of the fields are as follows:

=over 4

=item * C<tz_fmt_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<type>

A format type. This can be either: C<fallback>, C<gmt>, C<gmt_zero>, C<hour> and C<region>

=over 4

=item * C<fallback>

Quoting the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#fallbackFormat>: "a formatting string such as C<{1} ({0})>, where C<{1}> is the metazone, and C<{0}> is the country or city."

For example: C<{1} ({0})>, which would yield in English: C<Pacific Time (Canada)>

=item * C<gmt>

A formatting string, such as C<GMT{0}>, where C<{0}> is the GMT offset in hour, minute, and possibly seconds, using the C<hour> formatting.

For example: C<GMT{0}>, which would yield in English: C<GMT-0800>

=item * C<hour>

2 formatting strings separated by a semicolon; one for the positive offset formatting and the other for the negative offset formatting.

See the section on L<formatting patterns|/"Format Patterns"> for the significance of the letters used in formatting.

For example: C<+HHmm;-HHmm>, which would yield in English: C<+1200>

=item * C<gmt_zero>

For example: C<GMT>

This specifies how GMT/UTC with no explicit offset (implied 0 offset) should be represented.

=item * C<region>

Quoting the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Time_Zone_Format_Terminology>: "a formatting string such as C<{0} Time>, where C<{0}> is the country or city."

For example: C<{0} Daylight Time>, which would yield in English: C<France Daylight Time>, or in Spanish, the pattern C<horario de verano de {0}>, which would yield C<horario de verano de Francia>

=back

=item * C<subtype>

A C<timezone> format subtype, such as C<daylight>, C<standard>

Note that not all timezones and locales have a localised C<daylight> or C<standard> format

=item * C<format_pattern>

A string representing the format pattern.

=back

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Using_Time_Zone_Names> and L<specifications about fallback formats|https://unicode.org/reports/tr35/tr35-dates.html#timeZoneNames_Elements_Used_for_Fallback> for more information.

=head2 timezones_formats

    my $all = $cldr->timezones_formats;
    my $all = $cldr->timezones_formats( locale => 'ja' );
    my $all = $cldr->timezones_formats(
        locale  => 'ja',
        type    => 'region',
    );
    my $all = $cldr->timezones_formats(
        locale  => 'ja',
        subtype => 'standard',
    );
    my $all = $cldr->timezones_formats(
        format_pattern  => '{0} Daylight Time',
    );

Returns all C<timezone> localised formats from L<table timezones_formats|/"Table timezones_formats"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<type>

A format type. This can be either: C<fallback>, C<gmt>, C<gmt_zero>, C<hour> and C<region>

=item * C<subtype>

A C<timezone> format subtype, such as C<daylight>, C<standard>

Note that not all timezones and locales have a localised C<daylight> or C<standard> format

=back

=head2 timezone_info

    my $ref = $cldr->timezone_info(
        timezone    => 'Europe/Simferopol',
        start       => '1994-04-30T21:00:00',
    );
    # Returns an hash reference like this:
    {
        tzinfo_id   => 594,
        timezone    => 'Europe/Simferopol',
        metazone    => 'Moscow',
        start       => '1994-04-30T21:00:00',
        until       => '1997-03-30T01:00:00',
    }

or, maybe, simpler, using the L<advanced search|/"Advanced Search">:

    my $ref = $cldr->timezone_info(
        timezone    => 'Europe/Simferopol',
        start       => ['>1992-01-01', '<1995-01-01'],
    );

That way, you do not need to know the exact date.

Returns an hash reference of a C<timezone> historical information from the table L<timezones_info|/"Table timezones_info"> for a given C<timezone> ID and a C<start> datetime. If no C<start> value is provided, it will default to C<undef>

The meaning of the fields are as follows:

=over 4

=item * C<tzinfo_id>

A unique incremental value automatically generated by SQLite.

=item * C<timezone>

A C<timezone>, such as C<Asia/Tokyo> table L<timezones|/"Table timezones">

=item * C<metazone>

A C<metazone> ID

There are 190 known C<metazone> IDs

=item * C<start>

An ISO8601 start datetime value for this timezone.

This may be C<undef>

=item * C<until>

An ISO8601 datetime value representing the date and time until which this timezone was valid.

It may be C<undef>

=back

=head2 timezones_info

    my $all = $cldr->timezones_info;
    my $all = $cldr->timezones_info( timezone => 'Europe/Simferopol' );
    my $all = $cldr->timezones_info( metazone => 'Singapore' );
    my $all = $cldr->timezones_info( start => undef );
    my $all = $cldr->timezones_info( until => undef );

Returns all the C<timezone> information as an array reference of hash reference from the L<table timezones_info|/"Table timezones_info">

You can adjust the data return by using a combination of the following filtering arguments:

=over 4

=item * C<metazone>

A Unicode C<metazone> ID

=item * C<start>

An ISO8601 date and time from which to find data. For example: C<2014-10-25T14:00:00>

=item * C<timezone>

A C<timezone> value.

=item * C<until>

An ISO8601 date and time until which to find data. For example: C<2016-03-26T18:00:00>

=back

=head2 timezone_names

    my $ref = $cldr->timezone_names(
        locale      => 'ja',
        timezone    => 'Europe/London',
        width       => 'long',
    );
    # Returns an hash reference like this:
    {
        tz_name_id      => 85,
        locale          => 'ja',
        timezone        => 'Europe/London',
        width           => 'long',
        generic         => undef,
        standard        => undef,
        daylight        => '英国夏時間',
    }

Returns an hash reference of a C<timezone> names localised information from the table L<timezones_names|/"Table timezones_names"> for a given C<locale> ID, C<timezone> and C<width> value.

The meaning of the fields are as follows:

=over 4

=item * C<tz_name_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<timezone>

A C<timezone> such as can be found in table L<timezones|/"Table timezones">

=item * C<width>

A C<timezone> localised name C<width>, which can be either C<long> or C<short>

Note that not all timezones names have both C<width> defined.

=item * C<generic>

The C<timezone> C<generic> name.

=item * C<standard>

The C<timezone> C<standard> name.

=item * C<standard>

The C<timezone> C<daylight> name defined if the C<timezone> use daylight saving time system.

=back

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Time_Zone_Names> for more information.

=head2 timezones_names

    my $all = $cldr->timezones_names;
    my $all = $cldr->timezones_names( locale => 'ja' );
    my $all = $cldr->timezones_names( width => 'long' );
    my $all = $cldr->timezones_names(
        locale  => 'ja',
        width   => 'long',
    );

Returns all C<timezone> localised formats from L<table timezones_names|/"Table timezones_names"> as an array reference of hash reference.

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<timezone>

A C<timezone> such as can be found in table L<timezones|/"Table timezones">

=item * C<width>

A C<timezone> localised name C<width>, which can be either C<long> or C<short>

Note that not all timezones names have both C<width> defined.

=back

=head2 unit_alias

    my $ref = $cldr->unit_alias( alias => 'meter-per-second-squared' );
    # Returns an hash reference like this:
    {
        unit_alias_id   => 3,
        alias           => 'meter-per-second-squared',
        target          => 'meter-per-square-second',
        reason          => 'deprecated',
    }

Or, maybe simpler, using the L<advanced search|/"Advanced Search">:

    my $ref = $cldr->unit_alias( alias => '~^meter.*' );

or

    my $ref = $cldr->unit_alias( alias => qr/^meter.*/ );

Returns an hash reference of a unit alias information from the table L<unit_aliases|/"Table unit_aliases"> based on the C<alias> ID provided.

=head2 unit_aliases

    my $all = $cldr->unit_aliases;

Returns all the unit alias information as an array reference of hash reference from the L<table unit_aliases|/"Table unit_aliases">

No additional parameter is needed.

=head2 unit_constant

    my $ref = $cldr->unit_constant( constant => 'lb_to_kg' );
    # Returns an hash reference like this:
    {
        unit_constant_id    => 1,
        constant            => 'lb_to_kg',
        expression          => 0.45359237,
        value               => 0.45359237,
        description         => undef,
        status              => undef,
    }

Returns an hash reference of a unit constant information from the table L<unit_constants|/"Table unit_constants"> based on the C<constant> ID provided.

The meaning of the fields are as follows:

=over 4

=item * C<unit_constant_id>

A unique incremental value automatically generated by SQLite.

=item * C<constant>

The unit constant ID.

=item * C<expression>

The constant expression as defined in C<CLDR>

=item * C<value>

The constant resolved value, computed from the C<expression> specified.

=item * C<description>

A string describing the constant.

=item * C<status>

A string representing the C<status> for this C<constant>

=back

=head2 unit_constants

    my $all = $cldr->unit_constants;

Returns all the unit constants information as an array reference of hash reference from the L<table unit_constants|/"Table unit_constants">

No additional parameter is needed.

=head2 unit_conversion

    my $ref = $cldr->unit_conversion( source => 'kilogram' );
    # Returns an hash reference like this:
    {
        unit_conversion_id  => 9,
        source              => 'kilogram',
        base_unit           => 'kilogram',
        expression          => undef,
        factor              => undef,
        systems             => ["si", "metric"],
        category            => 'mass',
    }

Returns an hash reference of a unit conversion information from the table L<unit_conversions|/"Table unit_conversions"> based on the C<source> ID provided.

The meaning of the fields are as follows:

=over 4

=item * C<unit_conversion_id>

A unique incremental value automatically generated by SQLite.

=item * C<source>

A string representing the unit source.

=item * C<base_unit>

A string representing the base unit for this unit conversion

=item * C<expression>

A string representing the unit expression, if any.

=item * C<factor>

A string representing the unit factor value, if any.

=item * C<systems>

An array of string representing the unit conversion systems.

=item * C<category>

A string representing the unit conversion category.

Known category values are: C<acceleration>, C<angle>, C<area>, C<catalytic-activity>, C<concentration-mass>, C<digital>, C<electric-capacitance>, C<electric-charge>, C<electric-conductance>, C<electric-current>, C<electric-inductance>, C<electric-resistance>, C<energy>, C<force>, C<frequency>, C<graphics>, C<ionizing-radiation>, C<length>, C<luminance>, C<luminous-flux>, C<luminous-intensity>, C<magnetic-flux>, C<magnetic-induction>, C<mass>, C<portion>, C<power>, C<pressure>, C<pressure-per-length>, C<radioactivity>, C<solid-angle>, C<speed>, C<substance-amount>, C<temperature>, C<th>, C<time>, C<typewidth>, C<voltage>, C<volume>, C<year-duration>

=back

=head2 unit_conversions

    my $all = $cldr->unit_conversions;
    my $all = $cldr->unit_conversions( base_unit => 'kilogram' );;
    my $all = $cldr->unit_conversions( category => 'mass' );

Returns all the unit conversion information as an array reference of hash reference from the L<table unit_conversions|/"Table unit_conversions">

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<base_unit>

A base unit ID.

=item * C<category>

A category ID. Known categories are: C<acceleration>, C<angle>, C<area>, C<catalytic-activity>, C<concentration-mass>, C<digital>, C<electric-capacitance>, C<electric-charge>, C<electric-conductance>, C<electric-current>, C<electric-inductance>, C<electric-resistance>, C<energy>, C<force>, C<frequency>, C<graphics>, C<ionizing-radiation>, C<length>, C<luminance>, C<luminous-flux>, C<luminous-intensity>, C<magnetic-flux>, C<magnetic-induction>, C<mass>, C<portion>, C<power>, C<pressure>, C<pressure-per-length>, C<radioactivity>, C<solid-angle>, C<speed>, C<substance-amount>, C<temperature>, C<th>, C<time>, C<typewidth>, C<voltage>, C<volume>, C<year-duration>

=back

=head2 unit_l10n

    my $ref = $cldr->unit_l10n(
        unit_id         => 'length-kilometer',
        locale          => 'en',
        # long, narrow, short
        format_length   => 'long',
        # compound, regular
        unit_type       => 'regular',
        count           => 'one',
        gender          => undef,
        gram_case       => undef,
    );
    # Returns an hash reference like this:
    {
        units_l10n_id   => 25599,
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
    }

Returns an hash reference of a C<unit> localised information from the table L<units_l10n|/"Table units_l10n"> for a given C<locale> ID, C<format_length>, C<unit_type>, C<unit_id>, C<count>, C<gender>, C<gram_case>.

If no C<count>, C<gender>, or C<gram_case> value is provided, it will default to C<undef>

The meaning of the fields are as follows:

=over 4

=item * C<units_l10n_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<format_length>

A string representing the unit format length

Known values are: C<long>, C<narrow>, C<short>

=item * C<unit_type>

A string representing a C<unit> type.

Known values are: C<compound> and C<regular>

=item * C<unit_id>

A string representing a C<unit> ID.

=item * C<unit_pattern>

A string representing a localised C<unit> pattern.

=item * C<pattern_type>

A string representing a pattern type.

Known values are: C<per-unit>, C<prefix>, C<regular>

=item * C<locale_name>

A string containing the localised representation of this C<unit>

Note that there is no C<locale_name> value for C<unit> of type C<compound> in the C<CLDR> data.

=item * C<count>

A string used to differentiate identical values.

Known values are: C<undef>, C<one>, C<other>, C<zero>, C<two>, C<few>, C<many>

=item * C<gender>

A string representing the C<gender> associated with the C<unit>

The locales that are known to use C<gender> information for units are:

=over 8

=item * C<ar>

Arabic

=item * C<ca>

Catalan

=item * C<cs>

Czech

=item * C<da>

Danish

=item * C<de>

German

=item * C<el>

Greek

=item * C<es>

Spanish

=item * C<fr>

French

=item * C<fr-CA>

Canadian French

=item * C<gu>

Gujarati

=item * C<he>

Hebrew

=item * C<hi>

Hindi

=item * C<hr>

Croatian

=item * C<is>

Icelandic

=item * C<it>

Italian

=item * C<kn>

Kannada

=item * C<lt>

Lithuanian

=item * C<lv>

Latvian

=item * C<ml>

Malayalam

=item * C<mr>

Marathi

=item * C<nl>

Dutch

=item * C<nn>

Norwegian Nynorsk

=item * C<no>

Norwegian

=item * C<pa>

Punjabi

=item * C<pl>

Polish

=item * C<pt>

Portuguese

=item * C<ro>

Romanian

=item * C<ru>

Russian

=item * C<sk>

Slovak

=item * C<sl>

Slovenian

=item * C<sr>

Serbian

=item * C<sv>

Swedish

=item * C<uk>

Ukrainian

=item * C<ur>

Urdu

=back

=item * C<gram_case>

A string representing a grammatical case.

Known values are: C<ablative>, C<accusative>, C<dative>, C<elative>, C<ergative>, C<genitive>, C<illative>, C<instrumental>, C<locative>, C<oblique>, C<partitive>, C<prepositional>, C<sociative>, C<terminative>, C<translative>, C<vocative>

=back

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-general.html#Unit_Elements> for more information.

=head2 units_l10n

    my $all = $cldr->units_l10n;
    my $all = $cldr->units_l10n( locale => 'en' );
    my $all = $cldr->units_l10n(
        locale          => 'en',
        format_length   => 'long',
        unit_type       => 'regular',
        unit_id         => 'length-kilometer',
        pattern_type    => 'regular',
    );

Returns all the unit prefixes information as an array reference of hash reference from the L<table units_l10n|/"Table units_l10n">

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<format_length>

A string representing the unit format length

Known values are: C<long>, C<narrow>, C<short>

=item * C<unit_type>

A string representing a C<unit> type.

Known values are: C<compound> and C<regular>

=item * C<unit_id>

A string representing a C<unit> ID.

=item * C<pattern_type>

A string representing a pattern type.

Known values are: C<per-unit>, C<prefix>, C<regular>

=back

=head2 unit_prefix

    my $ref = $cldr->unit_prefix( unit_id => 'micro' );
    # Returns an hash reference like this:
    {
        unit_prefix_id  => 9,
        unit_id         => 'micro',
        symbol          => 'μ',
        power           => 10,
        factor          => -6,
    }

Returns an hash reference of a unit prefix information from the table L<unit_prefixes|/"Table unit_prefixes"> based on the C<unit_id> ID provided.

The meaning of the fields are as follows:

=over 4

=item * C<unit_prefix_id>

A unique incremental value automatically generated by SQLite.

=item * C<unit_id>

A C<unit> ID

=item * C<symbol>

A string representing the unit symbol.

=item * C<power>

A value representing the unit power

=item * C<factor>

A value representing the unit factor.

=back

=head2 unit_prefixes

    my $all = $cldr->unit_prefixes;

Returns all the unit prefixes information as an array reference of hash reference from the L<table unit_prefixes|/"Table unit_prefixes">

No additional parameter is needed.

=head2 unit_pref

    my $ref = $cldr->unit_pref( unit_id => 'square-meter' );
    # Returns an hash reference like this:
    {
        unit_pref_id    => 3,
        unit_id         => 'square-meter',
        territory       => '001',
        category        => 'area',
        usage           => 'default',
        geq             => undef,
        skeleton        => undef,
    }

Returns an hash reference of a unit preference information from the table L<unit_prefs|/"Table unit_prefs"> based on the C<unit_id> ID provided.

=head2 unit_prefs

    my $all = $cldr->unit_prefs;
    my $all = $cldr->unit_prefs( territory => 'US' );
    my $all = $cldr->unit_prefs( category => 'area' );

Returns all the unit preferences information as an array reference of hash reference from the L<table unit_prefs|/"Table unit_prefs">

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<territory>

A C<territory> code as can be found in table L<territories|/"Table territories">

=item * C<category>

A category ID. Known categories are: C<area>, C<concentration>, C<consumption>, C<duration>, C<energy>, C<length>, C<mass>, C<mass-density>, C<power>, C<pressure>, C<speed>, C<temperature>, C<volume>, C<year-duration>

=back

=head2 unit_quantity

    my $ref = $cldr->unit_quantity( base_unit => 'kilogram' );
    # Returns an hash reference like this:
    {
        unit_quantity_id    => 4,
        base_unit           => 'kilogram',
        quantity            => 'mass',
        status              => 'simple',
        comment             => undef,
    }

Returns an hash reference of a unit quantities information from the table L<unit_quantities|/"Table unit_quantities"> based on the C<unit_id> ID provided.

The meaning of the fields are as follows:

=over 4

=item * C<unit_quantity_id>

A unique incremental value automatically generated by SQLite.

=item * C<base_unit>

A string representing the base unit.

=item * C<quantity>

A string representing the unit quantity.

Known values are: C<acceleration>, C<angle>, C<area>, C<catalytic-activity>, C<concentration>, C<concentration-mass>, C<consumption>, C<current-density>, C<digital>, C<duration>, C<electric-capacitance>, C<electric-charge>, C<electric-conductance>, C<electric-current>, C<electric-inductance>, C<electric-resistance>, C<energy>, C<force>, C<frequency>, C<graphics>, C<illuminance>, C<ionizing-radiation>, C<length>, C<luminous-flux>, C<luminous-intensity>, C<magnetic-field-strength>, C<magnetic-flux>, C<magnetic-induction>, C<mass>, C<mass-density>, C<mass-fraction>, C<portion>, C<power>, C<pressure>, C<pressure-per-length>, C<radioactivity>, C<resolution>, C<solid-angle>, C<specific-volume>, C<speed>, C<substance-amount>, C<temperature>, C<typewidth>, C<voltage>, C<volume>, C<wave-number>, C<year-duration>

=item * C<status>

A string representing the unit status.

Known values are: C<undef> and C<simple>

=item * C<comment>

A text providing some comments about this unit quantity.

=back

=head2 unit_quantities

    my $all = $cldr->unit_quantities;
    my $all = $cldr->unit_quantities( quantity => 'mass' );

Returns all the unit quantities information as an array reference of hash reference from the L<table unit_quantities|/"Table unit_quantities">

A combination of the following fields may be provided to filter the information returned:

=over 4

=item * C<quantity>

A C<quantity> ID. Known C<quantity> ID are: C<acceleration>, C<angle>, C<area>, C<catalytic-activity>, C<concentration>, C<concentration-mass>, C<consumption>, C<current-density>, C<digital>, C<duration>, C<electric-capacitance>, C<electric-charge>, C<electric-conductance>, C<electric-current>, C<electric-inductance>, C<electric-resistance>, C<energy>, C<force>, C<frequency>, C<graphics>, C<illuminance>, C<ionizing-radiation>, C<length>, C<luminous-flux>, C<luminous-intensity>, C<magnetic-field-strength>, C<magnetic-flux>, C<magnetic-induction>, C<mass>, C<mass-density>, C<mass-fraction>, C<portion>, C<power>, C<pressure>, C<pressure-per-length>, C<radioactivity>, C<resolution>, C<solid-angle>, C<specific-volume>, C<speed>, C<substance-amount>, C<temperature>, C<typewidth>, C<voltage>, C<volume>, C<wave-number>, C<year-duration>

=back

=head2 variant

    my $ref = $cldr->variant( variant => 'valencia' );
    # Returns an hash reference like this:
    {
        variant_id  => 111,
        variant     => 'valencia',
        status      => 'regular',
    }

Returns an hash reference of a variant information from the table L<variants|/"Table variants"> based on the C<variant> ID provided.

The meaning of the fields are as follows:

=over 4

=item * C<variant_id>

A unique incremental value automatically generated by SQLite.

=item * C<variant>

A C<variant> ID

=item * C<status>

A string representing a status for this variant.

Known values are: C<undef>, C<deprecated>, C<regular>

=back

=head2 variants

    my $all = $cldr->variants;

Returns all the variants information as an array reference of hash reference from the L<table variants|/"Table variants">

No additional parameter is needed.

=head2 variant_l10n

    my $ref = $cldr->variant_l10n(
        variant => 'valencia',
        locale  => 'en',
        alt     => undef,
    );
    # Returns an hash reference like this:
    {
        var_l10n_id => 771,
        locale      => 'en',
        variant     => 'valencia',
        locale_name => 'Valencian',
        alt         => undef,
    }

Returns an hash reference of a C<variant> localised information from the table L<variants_l10n|/"Table variants_l10n"> for a given C<variant> ID and a C<locale> ID and an C<alt> value. If no C<alt> value is provided, it will default to C<undef>

The meaning of the fields are as follows:

=over 4

=item * C<var_l10n_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<variant>

A C<variant> ID as can be found in the L<table variants|/"Table variants">

=item * C<locale_name>

A string representing the localised C<variant> name based on the C<locale>

=item * C<alt>

An alternative value identifier to distinguish a variant with the same name.

Known values are: C<undef> and C<secondary>

=back

=head2 variants_l10n

    my $all = $cldr->variants_l10n;
    my $all = $cldr->variants_l10n( locale => 'en' );
    my $all = $cldr->variants_l10n(
        locale  => 'en',
        alt     => undef,
    );

Returns all the variants localised information as an array reference of hash reference from the L<table variants_l10n|/"Table variants_l10n">

=head2 week_preference

    my $ref = $cldr->week_preference( locale => 'ja' );
    # Returns an hash reference like this:
    {
        week_pref_id    => 32,
        locale          => 'ja',
        ordering        => ["weekOfDate", "weekOfMonth"],
    }

Returns an hash reference of a week preference information from the table L<week_preferences|/"Table week_preferences"> for a given C<locale> ID.

The meaning of the fields are as follows:

=over 4

=item * C<week_pref_id>

A unique incremental value automatically generated by SQLite.

=item * C<locale>

A C<locale>, such as C<en> or C<ja-JP> as can be found in table L<locales|/"Table locales">

=item * C<ordering>

This is "an ordered list of the preferred types of week designations for that"[L<1|https://unicode.org/reports/tr35/tr35-dates.html#Week_Data>]

It is provided as an array of tokens.

Known values in the array are:

=over 8

=item * C<weekOfYear>

=item * C<weekOfMonth>

=item * C<weekOfDate>

=item * C<weekOfInterval>

=back

=back

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Week_Data> for more information.

=head2 week_preferences

    my $all = $cldr->week_preferences;

Returns all the week preferences information as an array reference of hash reference from the L<table week_preferences|/"Table week_preferences">

=head1 Format Patterns

The following is taken directly from the L<Unicode LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#table-date-field-symbol-table> and placed here for your convenience.

See also the L<ICU format patterns table|https://unicode-org.github.io/icu/userguide/format_parse/datetime/#date-field-symbol-table>.

Examples:

=over 4

=item * C<yyyy.MM.dd G 'at' HH:mm:ss zzz>

1996.07.10 AD at 15:08:56 PDT

=item * C<EEE, MMM d, ''yy>

Wed, July 10, '96

=item * C<h:mm a>

12:08 PM

=item * C<hh 'o''clock' a, zzzz>

12 o'clock PM, Pacific Daylight Time

=item * C<K:mm a, z>

0:00 PM, PST

=item * C<yyyyy.MMMM.dd GGG hh:mm aaa>

01996.July.10 AD 12:08 PM

=back

See the L<date field symbols table|https://unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table> for more details.

=over 4

=item * C<a> period

B<AM, PM>

May be upper or lowercase depending on the locale and other options. The wide form may be the same as the short form if the “real” long form (eg ante meridiem) is not customarily used. The narrow form must be unique, unlike some other fields. See also Parsing Dates and Times.

Examples:

=over 8

=item * C<a..aaa> (Abbreviated)

am. [e.g. 12 am.]

=item * C<aaaa> (Wide)

am. [e.g. 12 am.]

=item * C<aaaaa> (Narrow)

a [e.g. 12a]

=back

=item * C<A> second

Milliseconds in day (numeric). This field behaves exactly like a composite of all time-related fields, not including the zone fields. As such, it also reflects discontinuities of those fields on DST transition days. On a day of DST onset, it will jump forward. On a day of DST cessation, it will jump backward. This reflects the fact that it must be combined with the offset field to obtain a unique local time value. The field length specifies the minimum number of digits, with zero-padding as necessary.

Examples:

=over 8

=item * C<A+>

69540000

=back

=item * C<b> period

B<am, pm, noon, midnight>

May be upper or lowercase depending on the locale and other options. If the locale doesn't have the notion of a unique "noon" = 12:00, then the PM form may be substituted. Similarly for "midnight" = 00:00 and the AM form. The narrow form must be unique, unlike some other fields.

Examples:

=over 8

=item * C<b..bbb> (Abbreviated)

mid. [e.g. 12 mid.]

=item * C<bbbb> (Wide)

midnight

[e.g. 12 midnight]

=item * C<bbbbb> (Narrow)

md [e.g. 12 md]

=back

=item * C<B> period

B<flexible day periods>

May be upper or lowercase depending on the locale and other options. Often there is only one width that is customarily used.

Examples:

=over 8

=item * C<B..BBB> (Abbreviated)

at night

[e.g. 3:00 at night]

=item * C<BBBB> (Wide)

at night

[e.g. 3:00 at night]

=item * C<BBBBB> (Narrow)

at night

[e.g. 3:00 at night]

=back

=item * C<c> week day

Stand-Alone local day of week number/name.

Examples:

=over 8

=item * C<c..cc>

2

Numeric: 1 digit

=item * C<ccc> (Abbreviated)

Tue

=item * C<cccc> (Wide)

Tuesday

=item * C<ccccc> (Narrow)

T

=item * C<cccccc> (Short)

Tu

=back

=item * C<C>

B<Input skeleton symbol>

It must not occur in pattern or skeleton data. Instead, it is reserved for use in skeletons passed to APIs doing flexible date pattern generation. In such a context, like 'j', it requests the preferred hour format for the locale. However, unlike 'j', it can also select formats such as hb or hB, since it is based not on the preferred attribute of the hours element in supplemental data, but instead on the first element of the allowed attribute (which is an ordered preferrence list). For example, with "Cmm", 18:00 could appear as “6:00 in the afternoon”.

Example:

=over 8

=item * C<C>

C<8>

C<8> (morning)

Numeric hour (minimum digits), abbreviated dayPeriod if used

=item * C<CC>

C<08>

C<08> (morning)

Numeric hour (2 digits, zero pad if needed), abbreviated dayPeriod if used

=item * C<CCC>

C<8>

C<8> in the morning

Numeric hour (minimum digits), wide dayPeriod if used

=item * C<CCCC>

C<08>

C<08> in the morning

Numeric hour (2 digits, zero pad if needed), wide dayPeriod if used

=item * C<CCCCC>

C<8>

C<8> (morn.)

Numeric hour (minimum digits), narrow dayPeriod if used

=item * C<CCCCCC>

C<08>

C<08> (morn.)

Numeric hour (2 digits, zero pad if needed), narrow dayPeriod if used

=back

=item * C<d> day of month

Day of month (numeric).

Example:

=over 8

=item * C<d>

1

Numeric: minimum digits

=item * C<dd>

01

Numeric: 2 digits, zero pad if needed

=back

=item * C<D> day of year

The field length specifies the minimum number of digits, with zero-padding as necessary.

Example:

=over 8

=item * C<D...DDD> day

345	Day of year (numeric).

=back

=item * C<e> week day

Local day of week number/name, format style. Same as E except adds a numeric value that will depend on the local starting day of the week. For this example, Monday is the first day of the week.

Example:

=over 8

=item * C<e>

2

Numeric: 1 digit

=item * C<ee>

02

Numeric: 2 digits + zero pad

=item * C<eee> (Abbreviated)

Tue

=item * C<eeee> (Wide)

Tuesday

=item * C<eeeee> (Narrow)

T

=item * C<eeeeee> (Short)

Tu

=back

=item * C<E> week day

Day of week name, format style.

Example:

=over 8

=item * C<E..EEE> (Abbreviated)

Tue

=item * C<EEEE> (Wide)

Tuesday

=item * C<EEEEE> (Narrow)

T

=item * C<EEEEEE> (Short)

Tu

=back

=item * C<F> day

Day of Week in Month (numeric). The example is for the 2nd Wed in July

Example:

=over 8

=item * C<F>

2

=back

=item * C<g>

Modified Julian day (numeric). This is different from the conventional Julian day number in two regards. First, it demarcates days at local zone midnight, rather than noon GMT. Second, it is a local number; that is, it depends on the local time zone. It can be thought of as a single number that encompasses all the date-related fields. The field length specifies the minimum number of digits, with zero-padding as necessary.

Example:

=over 8

=item * C<g+>

2451334

=back

=item * C<G> era

Era name.

Example:

=over 8

=item * C<G..GGG> (Abbreviated)

AD

[variant: CE]

=item * C<GGGG> (Wide)

Anno Domini

[variant: Common Era]

=item * C<GGGGG> (Narrow)

A

=back

=item * C<h> hour

Hour [1-12]. When used in skeleton data or in a skeleton passed in an API for flexible date pattern generation, it should match the 12-hour-cycle format preferred by the locale (h or K); it should not match a 24-hour-cycle format (H or k).

Example:

=over 8

=item * C<h>

1, 12

Numeric: minimum digits

=item * C<hh>

01, 12

Numeric: 2 digits, zero pad if needed

=back

=item * C<H> hour

Hour [0-23]. When used in skeleton data or in a skeleton passed in an API for flexible date pattern generation, it should match the 24-hour-cycle format preferred by the locale (H or k); it should not match a 12-hour-cycle format (h or K).

Example:

=over 8

=item * C<H>

C<0>, C<23>

Numeric: minimum digits

=item * C<HH>

C<00>, C<23>

Numeric: 2 digits, zero pad if needed

=back

=item * C<j>

B<Input skeleton symbol>

It must not occur in pattern or skeleton data. Instead, it is reserved for use in skeletons passed to APIs doing flexible date pattern generation. In such a context, it requests the preferred hour format for the locale (h, H, K, or k), as determined by the preferred attribute of the hours element in supplemental data. In the implementation of such an API, 'j' must be replaced by h, H, K, or k before beginning a match against availableFormats data.

Note that use of 'j' in a skeleton passed to an API is the only way to have a skeleton request a locale's preferred time cycle type (12-hour or 24-hour).

Example:

=over 8

=item * C<j>

C<8>

C<8 AM>

C<13>

C<1 PM>

Numeric hour (minimum digits), abbreviated dayPeriod if used

=item * C<jj>

C<08>

C<08 AM>

C<13>

C<01 PM>

Numeric hour (2 digits, zero pad if needed), abbreviated dayPeriod if used

=item * C<jjj>

C<8>

C<8 A.M.>

C<13>

C<1 P.M.>

Numeric hour (minimum digits), wide dayPeriod if used

=item * C<jjjj>

C<08>

C<08 A.M.>

C<13>

C<01 P.M.>

Numeric hour (2 digits, zero pad if needed), wide dayPeriod if used

=item * C<jjjjj>

C<8>

C<8a>

C<13>

C<1p>

Numeric hour (minimum digits), narrow dayPeriod if used

=item * C<jjjjjj>

C<08>

C<08a>

C<13>

C<01p>

Numeric hour (2 digits, zero pad if needed), narrow dayPeriod if used

=back

=item * C<J>

B<Input skeleton symbol>

It must not occur in pattern or skeleton data. Instead, it is reserved for use in skeletons passed to APIs doing flexible date pattern generation. In such a context, like 'j', it requests the preferred hour format for the locale (h, H, K, or k), as determined by the B<preferred> attribute of the hours element in supplemental data. However, unlike 'j', it requests no dayPeriod marker such as “am/pm” (it is typically used where there is enough context that that is not necessary). For example, with "jmm", 18:00 could appear as “6:00 PM”, while with "Jmm", it would appear as “6:00” (no PM).

Example:

=over 8

=item * C<J>

C<8>

C<8>

Numeric hour (minimum digits)

=item * C<JJ>

C<08>

C<08>

Numeric hour (2 digits, zero pad if needed)

=back

=item * C<k> hour

Hour [1-24]. When used in a skeleton, only matches k or H, see above.

Example:

=over 8

=item * C<k>

C<1>, C<24>

Numeric: minimum digits

=item * C<kk>

C<01>, C<24>

Numeric: 2 digits, zero pad if needed

=back

=item * C<K> hour

Hour [0-11]. When used in a skeleton, only matches K or h, see above.

Example:

=over 8

=item * C<K>

0, 11

Numeric: minimum digits

=item * C<KK>

00, 11

Numeric: 2 digits, zero pad if needed

=back

=item * C<L> month

Stand-Alone month number/name: For use when the month is displayed by itself, and in any other date pattern (e.g. just month and year, e.g. "LLLL y") that shares the same form of the month name. For month names, this is typically the nominative form. See discussion of month element.

See also the symbol C<M> for month.

Example:

=over 8

=item * C<L>

9, 12

Numeric: minimum digits

=item * C<LL>

09, 12	Numeric: 2 digits, zero pad if needed

=item * C<LLL> (Abbreviated)

Sep

=item * C<LLLL> (Wide)

September

=item * C<LLLLL> (Narrow)

S

=back

=item * C<M> month

Numeric: minimum digits	Format style month number/name: The format style name is an additional form of the month name (besides the stand-alone style) that can be used in contexts where it is different than the stand-alone form. For example, depending on the language, patterns that combine month with day-of month (e.g. "d MMMM") may require the month to be in genitive form. See discussion of month element. If a separate form is not needed, the format and stand-alone forms can be the same.

See also C<L>

Example:

=over 8

=item * C<M>

9, 12

=item * C<MM>

09, 12	Numeric: 2 digits, zero pad if needed

=item * C<MMM> (Abbreviated)

Sep

=item * C<MMMM> (Wide)

September

=item * C<MMMMM> (Narrow)

S

=back

=item * C<m> minute

Minute (numeric). Truncated, not rounded.

Examples:

=over 8

=item * C<m>

C<8>, C<59>

Numeric: minimum digits

=item * C<mm>

C<08>, C<59>

Numeric: 2 digits, zero pad if needed

=back

=item * C<O> zone

Examples:

=over 8

=item * C<O>

C<GMT-8>

The short localized GMT format.

=item * C<OOOO>

C<GMT-08:00>

The long localized GMT format.

=back

=item * C<q> quarter

Stand-Alone Quarter number/name.

Examples:

=over 8

=item * C<q>

C<2>

Numeric: 1 digit

=item * C<qq>

C<02>

Numeric: 2 digits + zero pad

=item * C<qqq> (Abbreviated)

C<Q2>

=item * C<qqqq> (Wide)

C<2nd quarter>

=item * C<qqqqq> (Narrow)

C<2>

=back

=item * C<Q> quarter

Quarter number/name.

Examples:

=over 8

=item * C<Q>

C<2>

Numeric: 1 digit

=item * C<QQ>

C<02>

Numeric: 2 digits + zero pad

=item * C<QQQ> (Abbreviated)

C<Q2>

=item * C<QQQQ> (Wide)

C<2nd quarter>

=item * C<QQQQQ> (Narrow)

C<2>

=back

=item * C<r>

Related Gregorian year (numeric). For non-Gregorian calendars, this corresponds to the extended Gregorian year in which the calendar’s year begins. Related Gregorian years are often displayed, for example, when formatting dates in the Japanese calendar — e.g. “2012(平成24)年1月15日” — or in the Chinese calendar — e.g. “2012壬辰年腊月初四”. The related Gregorian year is usually displayed using the "latn" numbering system, regardless of what numbering systems may be used for other parts of the formatted date. If the calendar’s year is linked to the solar year (perhaps using leap months), then for that calendar the ‘r’ year will always be at a fixed offset from the ‘u’ year. For the Gregorian calendar, the ‘r’ year is the same as the ‘u’ year. For ‘r’, all field lengths specify a minimum number of digits; there is no special interpretation for “rr”.

Example:

=over 8

=item * C<r+>

C<2017>

=back

=item * C<s> second

Second (numeric). Truncated, not rounded.

Example:

=over 8

=item * C<s>

C<8>, C<12>

Numeric: minimum digits

=item * C<ss>

C<08>, C<12>

Numeric: 2 digits, zero pad if needed

=back

=item * C<S> second

Fractional Second (numeric). Truncates, like other numeric time fields, but in this case to the number of digits specified by the field length. (Example shows display using pattern SSSS for seconds value 12.34567)

Example:

=over 8

=item * C<S+>

3456

=back

=item * C<u>

Extended year (numeric). This is a single number designating the year of this calendar system, encompassing all supra-year fields. For example, for the Julian calendar system, year numbers are positive, with an era of BCE or CE. An extended year value for the Julian calendar system assigns positive values to CE years and negative values to BCE years, with 1 BCE being year 0. For ‘u’, all field lengths specify a minimum number of digits; there is no special interpretation for “uu”.

Example:

=over 8

=item * C<u+>

C<4601>

=back

=item * C<U>

Cyclic year name. Calendars such as the Chinese lunar calendar (and related calendars) and the Hindu calendars use 60-year cycles of year names. If the calendar does not provide cyclic year name data, or if the year value to be formatted is out of the range of years for which cyclic name data is provided, then numeric formatting is used (behaves like 'y').

Currently the data only provides abbreviated names, which will be used for all requested name widths.

Example:

=over 8

=item * C<U..UUU> (Abbreviated)

C<甲子>

=item * C<UUUU> (Wide)

C<甲子> [for now]

=item * C<UUUUU> (Narrow)

C<甲子> [for now]

=back

=item * C<v> zone

Example:

=over 8

=item * C<v>

C<PT>

The short generic non-location format Where that is unavailable, falls back to the generic location format ("VVVV"), then the short localized GMT format as the final fallback.

=item * C<vvvv>

C<Pacific Time>

The long generic non-location format. Where that is unavailable, falls back to generic location format ("VVVV").

=back

=item * C<V> zone

Example:

=over 8

=item * C<V>

C<uslax>

The short time zone ID. Where that is unavailable, the special short time zone ID unk (Unknown Zone) is used.
Note: This specifier was originally used for a variant of the short specific non-location format, but it was deprecated in the later version of this specification. In CLDR 23, the definition of the specifier was changed to designate a short time zone ID.

=item * C<VV>

C<America/Los_Angeles>

The long time zone ID.

=item * C<VVV>

C<Los Angeles>

The exemplar city (location) for the time zone. Where that is unavailable, the localized exemplar city name for the special zone Etc/Unknown is used as the fallback (for example, "Unknown City").

=item * C<VVVV>

C<Los Angeles Time>

The generic location format. Where that is unavailable, falls back to the long localized GMT format ("OOOO"; Note: Fallback is only necessary with a GMT-style Time Zone ID, like Etc/GMT-830.)

This is especially useful when presenting possible timezone choices for user selection, since the naming is more uniform than the "v" format.

=back

=item * C<w>

Week of Year (numeric). When used in a pattern with year, use ‘Y’ for the year field instead of ‘y’.

Example:

=over 8

=item * C<w>

C<8>, C<27>

Numeric: minimum digits

=item * C<ww>

C<08>, C<27>

Numeric: 2 digits, zero pad if needed

=back

=item * C<W>

Week of Month (numeric)

Example:

=over 8

=item * C<W>

C<3>

Numeric: 1 digit

=back

=item * C<x> zone

Example:

=over 8

=item * C<x>

C<-08>

C<+0530>

C<+00>

The ISO8601 basic format with hours field and optional minutes field. (The same as X, minus "Z".)

=item * C<xx>

C<-0800>

C<+0000>

The ISO8601 basic format with hours and minutes fields. (The same as XX, minus "Z".)

=item * C<xxx>

C<-08:00>

C<+00:00>

The ISO8601 extended format with hours and minutes fields. (The same as XXX, minus "Z".)

=item * C<xxxx>

C<-0800>

C<-075258>

C<+0000>

The ISO8601 basic format with hours, minutes and optional seconds fields. (The same as XXXX, minus "Z".)

Note: The seconds field is not supported by the ISO8601 specification.

=item * C<xxxxx>

C<-08:00>

C<-07:52:58>

C<+00:00>

The ISO8601 extended format with hours, minutes and optional seconds fields. (The same as XXXXX, minus "Z".)

Note: The seconds field is not supported by the ISO8601 specification.

=back

=item * C<X> zone

Example:

=over 8

=item * C<X>

C<-08>

C<+0530>

C<Z>

The ISO8601 basic format with hours field and optional minutes field. The ISO8601 UTC indicator "Z" is used when local time offset is 0. (The same as x, plus "Z".)

=item * C<XX>

C<-0800>

C<Z>

The ISO8601 basic format with hours and minutes fields. The ISO8601 UTC indicator "Z" is used when local time offset is 0. (The same as xx, plus "Z".)

=item * C<XXX>

C<-08:00>

C<Z>

The ISO8601 extended format with hours and minutes fields. The ISO8601 UTC indicator "Z" is used when local time offset is 0. (The same as xxx, plus "Z".)

=item * C<XXXX>

C<-0800>

C<-075258>

C<Z>

The ISO8601 basic format with hours, minutes and optional seconds fields. The ISO8601 UTC indicator "Z" is used when local time offset is 0. (The same as xxxx, plus "Z".)

Note: The seconds field is not supported by the ISO8601 specification.

=item * C<XXXXX>

C<-08:00>

C<-07:52:58>

C<Z>

The ISO8601 extended format with hours, minutes and optional seconds fields. The ISO8601 UTC indicator "Z" is used when local time offset is 0. (The same as xxxxx, plus "Z".)

Note: The seconds field is not supported by the ISO8601 specification.

=back

=item * C<y>

Calendar year (numeric). In most cases the length of the y field specifies the minimum number of digits to display, zero-padded as necessary; more digits will be displayed if needed to show the full year. However, “yy” requests just the two low-order digits of the year, zero-padded as necessary. For most use cases, “y” or “yy” should be adequate.

Example:

=over 8

=item * C<y>

C<2>, C<20>, C<201>, C<2017>, C<20173>

=item * C<yy>

C<02>, C<20>, C<01>, C<17>, C<73>

=item * C<yyy>

C<002>, C<020>, C<201>, C<2017>, C<20173>

=item * C<yyyy>

C<0002>, C<0020>, C<0201>, C<2017>, C<20173>

=item * C<yyyyy+>

...

=back

=item * C<Y>

Year in “Week of Year” based calendars in which the year transition occurs on a week boundary; may differ from calendar year ‘y’ near a year transition. This numeric year designation is used in conjunction with pattern character ‘w’ in the ISO year-week calendar as defined by ISO 8601, but can be used in non-Gregorian based calendar systems where week date processing is desired. The field length is interpreted in the same was as for ‘y’; that is, “yy” specifies use of the two low-order year digits, while any other field length specifies a minimum number of digits to display.

Example:

=over 8

=item * C<Y>

C<2>, C<20>, C<201>, C<2017>, C<20173>

=item * C<YY>

C<02>, C<20>, C<01>, C<17>, C<73>

=item * C<YYY>

C<002>, C<020>, C<201>, C<2017>, C<20173>

=item * C<YYYY>

C<0002>, C<0020>, C<0201>, C<2017>, C<20173>

=item * C<YYYYY+>

...

=back

=item * C<z> zone

Examples:

=over 8

=item * C<z..zzz>

C<PDT>

The short specific non-location format. Where that is unavailable, falls back to the short localized GMT format ("O").

=item * C<zzzz>

C<Pacific Daylight Time>

The long specific non-location format. Where that is unavailable, falls back to the long localized GMT format ("OOOO").

=back

=item * C<Z>

Examples:

=over 8

=item * C<Z..ZZZ>

C<-0800>

The ISO8601 basic format with hours, minutes and optional seconds fields. The format is equivalent to RFC 822 zone format (when optional seconds field is absent). This is equivalent to the "xxxx" specifier.

=item * C<ZZZZ>

C<GMT-8:00>

The long localized GMT format. This is equivalent to the "OOOO" specifier.

=item * C<ZZZZZ>

C<-08:00>

C<-07:52:58>

The ISO8601 extended format with hours, minutes and optional seconds fields. The ISO8601 UTC indicator "Z" is used when local time offset is 0. This is equivalent to the "XXXXX" specifier.

=back

=back

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35-dates.html#Date_Format_Patterns> for more information on the date and time formatting.

=head1 Locale Inheritance

When performing data look-ups, some data, such as width, may be missing and the default C<wide> should be used, and sometime, the data is aliased. For example, C<narrow> would be aliased to C<abbreviated>.

Then, there is also a vertical inheritance, whereby a locale C<fr-CA> would lookup up data in its parent C<fr>. When the inheritance is not natural, the C<LDML> specifies a C<parent>. This information can be found in table L<locales|/"Table locales">. Ultimately, the root C<locale> with value C<und> is to be used.

See the L<LDML specifications|https://unicode.org/reports/tr35/tr35.html#Parent_Locales> for more information.

=head1 Errors

This module does not die upon errors, unless you have set L<fatal|/fatal> to a true value. Instead it sets an L<error object|Locale::Unicode::Data::Exception> that can be retrieved.

When an error occurred, an L<error object|Locale::Unicode::Data::Exception> will be set and the method will return C<undef> in scalar context and an empty list in list context.

Otherwise, the only occasions when this module will die is when there is an internal design error, which would be my fault.

=head1 Advanced Search

You can specify an operator other than the default C<=> when providing arguments values, by placing it just before the argument value.

Possible explicit operators are:

=over 4

=item * C<=>

=item * C<!=>

=item * C<< < >>

=item * C<< <= >>

=item * C<< > >>

=item * C<< >= >>

=item * C<~>

Will enable the use of regular expression.

Alternatively, you can use a perl regular expression using the perl operator L<qr|perlop/"Regexp Quote-Like Operators">

=back

For example:

    my $all = $cldr->timezone_info(
        timezone => 'Europe/Simferopol',
        start => ['>1991-01-01','<1995-01-01'],
    );

This would result in:

    {
        tzinfo_id   => 594,
        timezone    => 'Europe/Simferopol',
        metazone    => 'Moscow',
        start       => '1994-04-30T21:00:00',
        until       => '1997-03-30T01:00:00',
    }

or, using the C<~> operator:

    my $all = $cldr->time_formats(
        region => '~^U.*',
    );
    my $all = $cldr->time_formats(
        region => qr/^U.*/,
    );

would result in:

    [
        {
            time_format_id => 141,
            region => "UA",
            territory => "UA",
            locale => undef,
            time_format => "H",
            time_allowed => [qw( H hB h )],
        },
        {
            time_format_id => 142,
            region => "UZ",
            territory => "UZ",
            locale => undef,
            time_format => "H",
            time_allowed => [qw( H hB h )],
        },
        {
            time_format_id => 155,
            region => "UG",
            territory => "UG",
            locale => undef,
            time_format => "H",
            time_allowed => [qw( hB hb H h )],
        },
        {
            time_format_id => 194,
            region => "UY",
            territory => "UY",
            locale => undef,
            time_format => "h",
            time_allowed => [qw( h H hB hb )],
        },
        {
            time_format_id => 226,
            region => "UM",
            territory => "UM",
            locale => undef,
            time_format => "h",
            time_allowed => [qw( h hb H hB )],
        },
        {
            time_format_id => 227,
            region => "US",
            territory => "US",
            locale => undef,
            time_format => "h",
            time_allowed => [qw( h hb H hB )],
        },
    ]

For single result methods, i.e. the methods that only return an hash reference, you can provide an array reference instead of a regular string for the primary field you are trying to query. So, for example, using the example above with the C<timezone> info:

    my $all = $cldr->timezone_info(
        timezone => 'Europe/Simferopol',
        start => ['>1991-01-01','<1995-01-01'],
    );

or, querying the L<calendar terms|/calendar_term>:

    my $all = $cldr->calendar_term(
        locale          => 'und',
        calendar        => 'gregorian',
        # format, stand-alone
        term_context    => 'format',
        # abbreviated, narrow, wide
        term_width      => 'abbreviated',
        term_name       => [qw( am pm )],
    );
    # Returns an array reference like:
    [
        {
            cal_term_id     => 23478,
            locale          => 'und',
            calendar        => 'gregorian',
            term_type       => 'day_period',
            term_context    => 'format',
            term_width      => 'abbreviated',
            alt             => undef,
            term_name       => 'am',
            term_value      => 'AM',
        },
        {
            cal_term_id     => 23479,
            locale          => 'und',
            calendar        => 'gregorian',
            term_type       => 'day_period',
            term_context    => 'format',
            term_width      => 'abbreviated',
            alt             => undef,
            term_name       => 'pm',
            term_value      => 'PM',
        },
    ]

Of course, instead of returning an hash reference, as it normally would, it will return an array reference of hash reference.

You can check if a table field containing an array has a certain value. For example:

    my $all = $cldr->metazones(
        has => [territories => 'CA'],
    );

This will return all metazone entries that have the array value C<CA> in the field C<territories>.

You can specify more than one field:

    my $all = $cldr->metazones(
        has => [territories => 'CA', timezones => 'America/Chicago'],
    );

You can also use an hash reference instead of an array reference:

    my $all = $cldr->metazones(
        has => {
            territories => 'CA',
            timezones => 'America/Chicago',
        },
    );

And if the table contains only one array field, then you do not have tp specify the field name:

    my $all = $cldr->aliases(
        has => 'America/Toronto',
    );

This will implicitly use the field C<replacement>. However, if there are more than one array field, and you do not specify which one, then an error will be triggered. For example:

    my $all = $cldr->metazones(
        has => 'CA',
    );
    say $cldr->error->message;
    # "There are 2 fields with array. You need to specify which one you want to check for value 'CA'"

You can also ensure a certain order based on a field value. For example, you want to retrieve the C<day> terms using L<calendar_term|/calendar_term>, but the C<term_name> are string, and we want to ensure the results are sorted in this order: C<mon>, C<tue>, C<wed>, C<thu>, C<fri>, C<sat> and C<sun>

    my $terms = $cldr->calendar_terms(
        locale => 'en',
        calendar => 'gregorian',
        term_type => 'day',
        term_context => 'format',
        term_width => 'wide',
        order_by_value => [term_name => [qw( mon tue wed thu fri sat sun )]],
    );
    my @weekdays = map( $_->{term_name}, @$terms );
    # Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday

If we had wanted to put Sunday first, we would have done:

    my $terms = $cldr->calendar_terms(
        locale => 'en',
        calendar => 'gregorian',
        term_type => 'day',
        term_context => 'format',
        term_width => 'wide',
        order_by_value => [term_name => [qw( sun mon tue wed thu fri sat )]],
    );

The parameter C<order_by_value> supersedes the parameter C<order> that may be provided.

You can specify a particular data type to sort the values returned by SQLite, by providing the argument C<order>, such as:

    my $months = $cldr->calendar_terms(
        locale => 'en',
        calendar => 'gregorian',
        term_type => 'month',
        term_context => 'format',
        term_width => 'wide',
        order => [term_name => 'integer'],
    );

or, alternatively, using an hash reference with a single key:

    my $months = $cldr->calendar_terms(
        locale => 'en',
        calendar => 'gregorian',
        term_type => 'month',
        term_context => 'format',
        term_width => 'wide',
        order => { term_name => 'integer' },
    );
    my @month_names = map( $_->{term_name}, @$months );
    # January, February, March, April, May, June, July, August, September, October, November, December

=head1 SQL Schema

The SQLite SQL schema is available in the file C<scripts/cldr-schema.sql>

The data are populated into the SQLite database using the script located in C<scripts/create_database.pl> and the data accessible from L<https://github.com/unicode-org/cldr> or from L<https://cldr.unicode.org/index/downloads/>

=head1 Tables

The SQL schema used to create the SQLite database is available in the C<scripts> directory of this distribution in the file C<cldr-schema.sql>

The tables used are as follows, in alphabetical order:

=head2 Table aliases

=over 4

=item * C<alias_id>

An integer field.

=item * C<alias>

A string field.

=item * C<replacement>

A string array field.

=item * C<reason>

A string field.

=item * C<type>

A string field.

=item * C<comment>

A string field.

=back

=head2 Table annotations

=over 4

=item * C<annotation_id>

An integer field.

=item * C<locale>

A string field.

=item * C<annotation>

A string field.

=item * C<defaults>

A string array field.

=item * C<tts>

A string field.

=back

=head2 Table bcp47_currencies

=over 4

=item * C<bcp47_curr_id>

An integer field.

=item * C<currid>

A string field.

=item * C<code>

A string field.

=item * C<description>

A string field.

=item * C<is_obsolete>

A boolean field.

=back

=head2 Table bcp47_extensions

=over 4

=item * C<bcp47_ext_id>

An integer field.

=item * C<category>

A string field.

=item * C<extension>

A string field.

=item * C<alias>

A string field.

=item * C<value_type>

A string field.

=item * C<description>

A string field.

=item * C<deprecated>

A boolean field.

=back

=head2 Table bcp47_timezones

=over 4

=item * C<bcp47_tz_id>

An integer field.

=item * C<tzid>

A string field.

=item * C<alias>

A string array field.

=item * C<preferred>

A string field.

=item * C<description>

A string field.

=item * C<deprecated>

A boolean field.

=back

=head2 Table bcp47_values

=over 4

=item * C<bcp47_value_id>

An integer field.

=item * C<category>

A string field.

=item * C<extension>

A string field.

=item * C<value>

A string field.

=item * C<description>

A string field.

=back

=head2 Table calendar_append_formats

=over 4

=item * C<cal_append_fmt_id>

An integer field.

=item * C<locale>

A string field.

=item * C<calendar>

A string field.

=item * C<format_id>

A string field.

=item * C<format_pattern>

A string field.

=back

=head2 Table calendar_available_formats

=over 4

=item * C<cal_avail_fmt_id>

An integer field.

=item * C<locale>

A string field.

=item * C<calendar>

A string field.

=item * C<format_id>

A string field.

=item * C<format_pattern>

A string field.

=item * C<count>

A string field.

=item * C<alt>

A string field.

=back

=head2 Table calendar_cyclics_l10n

=over 4

=item * C<cal_int_fmt_id>

An integer field.

=item * C<locale>

A string field.

=item * C<calendar>

A string field.

=item * C<format_set>

A string field.

=item * C<format_type>

A string field.

=item * C<format_length>

A string field.

=item * C<format_id>

An integer field.

=item * C<format_pattern>

A string field.

=back

=head2 Table calendar_datetime_formats

=over 4

=item * C<cal_dt_fmt_id>

An integer field.

=item * C<locale>

A string field.

=item * C<calendar>

A string field.

=item * C<format_length>

A string field.

=item * C<format_type>

A string field.

=item * C<format_pattern>

A string field.

=back

=head2 Table calendar_eras

=over 4

=item * C<calendar_era_id>

An integer field.

=item * C<calendar>

A string field.

=item * C<sequence>

An integer field.

=item * C<code>

A string field.

=item * C<aliases>

A string array field.

=item * C<start>

A date field.

=item * C<until>

A date field.

=back

=head2 Table calendar_eras_l10n

=over 4

=item * C<cal_era_l10n_id>

An integer field.

=item * C<locale>

A string field.

=item * C<calendar>

A string field.

=item * C<era_width>

A string field.

=item * C<era_id>

A string field.

=item * C<alt>

A string field.

=item * C<locale_name>

A string field.

=back

=head2 Table calendar_formats_l10n

=over 4

=item * C<cal_fmt_l10n_id>

An integer field.

=item * C<locale>

A string field.

=item * C<calendar>

A string field.

=item * C<format_type>

A string field.

=item * C<format_length>

A string field.

=item * C<alt>

A string field.

=item * C<format_id>

A string field.

=item * C<format_pattern>

A string field.

=back

=head2 Table calendar_interval_formats

=over 4

=item * C<cal_int_fmt_id>

An integer field.

=item * C<locale>

A string field.

=item * C<calendar>

A string field.

=item * C<format_id>

A string field.

=item * C<greatest_diff_id>

A string field.

=item * C<format_pattern>

A string field.

=item * C<alt>

A string field.

=item * C<part1>

A string field.

=item * C<separator>

A string field.

=item * C<part2>

A string field.

=item * C<repeating_field>

A string field.

=back

=head2 Table calendar_terms

=over 4

=item * C<cal_term_id>

An integer field.

=item * C<locale>

A string field.

=item * C<calendar>

A string field.

=item * C<term_type>

A string field.

=item * C<term_context>

A string field.

=item * C<term_width>

A string field.

=item * C<alt>

A string field.

=item * C<yeartype>

A string field.

=item * C<term_name>

A string field.

=item * C<term_value>

A string field.

=back

=head2 Table calendars

=over 4

=item * C<calendar_id>

An integer field.

=item * C<calendar>

A string field.

=item * C<system>

A string field.

=item * C<inherits>

A string field.

=item * C<description>

A string field.

=back

=head2 Table calendars_l10n

=over 4

=item * C<calendar_l10n_id>

An integer field.

=item * C<locale>

A string field.

=item * C<calendar>

A string field.

=item * C<locale_name>

A string field.

=back

=head2 Table casings

=over 4

=item * C<casing_id>

An integer field.

=item * C<locale>

A string field.

=item * C<token>

A string field.

=item * C<value>

A string field.

=back

=head2 Table code_mappings

=over 4

=item * C<code_mapping_id>

An integer field.

=item * C<code>

A string field.

=item * C<alpha3>

A string field.

=item * C<numeric>

An integer field.

=item * C<fips10>

A string field.

=item * C<type>

A string field.

=back

=head2 Table collations_l10n

=over 4

=item * C<collation_l10n_id>

An integer field.

=item * C<locale>

A string field.

=item * C<collation>

A string field.

=item * C<locale_name>

A string field.

=back

=head2 Table currencies

=over 4

=item * C<currency_id>

An integer field.

=item * C<currency>

A string field.

=item * C<digits>

An integer field.

=item * C<rounding>

An integer field.

=item * C<cash_digits>

An integer field.

=item * C<cash_rounding>

An integer field.

=item * C<is_obsolete>

A boolean field.

=item * C<status>

A string field.

=back

=head2 Table currencies_info

=over 4

=item * C<currency_info_id>

An integer field.

=item * C<territory>

A string field.

=item * C<currency>

A string field.

=item * C<start>

A date field.

=item * C<until>

A date field.

=item * C<is_tender>

A boolean field.

=item * C<hist_sequence>

An integer field.

=item * C<is_obsolete>

A boolean field.

=back

=head2 Table currencies_l10n

=over 4

=item * C<curr_l10n_id>

An integer field.

=item * C<locale>

A string field.

=item * C<currency>

A string field.

=item * C<count>

A string field.

=item * C<locale_name>

A string field.

=item * C<symbol>

A string field.

=back

=head2 Table date_fields_l10n

=over 4

=item * C<date_field_id>

An integer field.

=item * C<locale>

A string field.

=item * C<field_type>

A string field.

=item * C<field_length>

A string field.

=item * C<relative>

An integer field.

=item * C<locale_name>

A string field.

=back

=head2 Table date_terms

=over 4

=item * C<date_term_id>

An integer field.

=item * C<locale>

A string field.

=item * C<term_type>

A string field.

=item * C<term_length>

A string field.

=item * C<display_name>

A string field.

=back

=head2 Table day_periods

=over 4

=item * C<day_period_id>

An integer field.

=item * C<locale>

A string field.

=item * C<day_period>

A string field.

=item * C<start>

A string field.

=item * C<until>

A string field.

=back

=head2 Table language_population

=over 4

=item * C<language_pop_id>

An integer field.

=item * C<territory>

A string field.

=item * C<locale>

A string field.

=item * C<population_percent>

A decimal field.

=item * C<literacy_percent>

A decimal field.

=item * C<writing_percent>

A decimal field.

=item * C<official_status>

A string field.

=back

=head2 Table languages

=over 4

=item * C<language_id>

An integer field.

=item * C<language>

A string field.

=item * C<scripts>

A string array field.

=item * C<territories>

A string array field.

=item * C<parent>

A string field.

=item * C<alt>

A string field.

=item * C<status>

A string field.

=back

=head2 Table languages_match

=over 4

=item * C<lang_match_id>

An integer field.

=item * C<desired>

A string field.

=item * C<supported>

A string field.

=item * C<distance>

An integer field.

=item * C<is_symetric>

A boolean field.

=item * C<is_regexp>

A boolean field.

=item * C<sequence>

An integer field.

=back

=head2 Table likely_subtags

=over 4

=item * C<likely_subtag_id>

An integer field.

=item * C<locale>

A string field.

=item * C<target>

A string field.

=back

=head2 Table locale_number_systems

=over 4

=item * C<locale_num_sys_id>

An integer field.

=item * C<locale>

A string field.

=item * C<number_system>

A string field.

=item * C<native>

A string field.

=item * C<traditional>

A string field.

=item * C<finance>

A string field.

=back

=head2 Table locales

=over 4

=item * C<locale_id>

An integer field.

=item * C<locale>

A string field.

=item * C<parent>

A string field.

=item * C<collations>

A string array field.

=item * C<status>

A string field.

=back

=head2 Table locales_info

=over 4

=item * C<locales_info_id>

An integer field.

=item * C<locale>

A string field.

=item * C<property>

A string field.

=item * C<value>

A string field.

=back

=head2 Table locales_l10n

=over 4

=item * C<locales_l10n_id>

An integer field.

=item * C<locale>

A string field.

=item * C<locale_id>

A string field.

=item * C<locale_name>

A string field.

=item * C<alt>

A string field.

=back

=head2 Table metainfos

=over 4

=item * C<meta_id>

An integer field.

=item * C<property>

A string field.

=item * C<value>

A string field.

=back

=head2 Table metazones

=over 4

=item * C<metazone_id>

An integer field.

=item * C<metazone>

A string field.

=item * C<territories>

A string array field.

=item * C<timezones>

A string array field.

=back

=head2 Table metazones_names

=over 4

=item * C<metatz_name_id>

An integer field.

=item * C<locale>

A string field.

=item * C<metazone>

A string field.

=item * C<width>

A string field.

=item * C<generic>

A string field.

=item * C<standard>

A string field.

=item * C<daylight>

A string field.

=back

=head2 Table number_formats_l10n

=over 4

=item * C<number_format_id>

An integer field.

=item * C<locale>

A string field.

=item * C<number_system>

A string field.

=item * C<number_type>

A string field.

=item * C<format_length>

A string field.

=item * C<format_type>

A string field.

=item * C<format_id>

A string field.

=item * C<format_pattern>

A string field.

=item * C<alt>

A string field.

=item * C<count>

A string field.

=back

=head2 Table number_symbols_l10n

=over 4

=item * C<number_symbol_id>

An integer field.

=item * C<locale>

A string field.

=item * C<number_system>

A string field.

=item * C<property>

A string field.

=item * C<value>

A string field.

=item * C<alt>

A string field.

=back

=head2 Table number_systems

=over 4

=item * C<numsys_id>

An integer field.

=item * C<number_system>

A string field.

=item * C<digits>

A string array field.

=item * C<type>

A string field.

=back

=head2 Table number_systems_l10n

=over 4

=item * C<num_sys_l10n_id>

An integer field.

=item * C<locale>

A string field.

=item * C<number_system>

A string field.

=item * C<locale_name>

A string field.

=item * C<alt>

A string field.

=back

=head2 Table person_name_defaults

=over 4

=item * C<pers_name_def_id>

An integer field.

=item * C<locale>

A string field.

=item * C<value>

A string field.

=back

=head2 Table rbnf

=over 4

=item * C<rbnf_id>

An integer field.

=item * C<locale>

A string field.

=item * C<grouping>

A string field.

=item * C<ruleset>

A string field.

=item * C<rule_id>

A string field.

=item * C<rule_value>

A string field.

=back

=head2 Table refs

=over 4

=item * C<ref_id>

An integer field.

=item * C<code>

A string field.

=item * C<uri>

A string field.

=item * C<description>

A string field.

=back

=head2 Table scripts

=over 4

=item * C<script_id>

An integer field.

=item * C<script>

A string field.

=item * C<rank>

An integer field.

=item * C<sample_char>

A string field.

=item * C<id_usage>

A string field.

=item * C<rtl>

A boolean field.

=item * C<lb_letters>

A boolean field.

=item * C<has_case>

A boolean field.

=item * C<shaping_req>

A boolean field.

=item * C<ime>

A boolean field.

=item * C<density>

An integer field.

=item * C<origin_country>

A string field.

=item * C<likely_language>

A string field.

=item * C<status>

A string field.

=back

=head2 Table scripts_l10n

=over 4

=item * C<scripts_l10n_id>

An integer field.

=item * C<locale>

A string field.

=item * C<script>

A string field.

=item * C<locale_name>

A string field.

=item * C<alt>

A string field.

=back

=head2 Table subdivisions

=over 4

=item * C<subdivision_id>

An integer field.

=item * C<territory>

A string field.

=item * C<subdivision>

A string field.

=item * C<parent>

A string field.

=item * C<is_top_level>

A boolean field.

=item * C<status>

A string field.

=back

=head2 Table subdivisions_l10n

=over 4

=item * C<subdiv_l10n_id>

An integer field.

=item * C<locale>

A string field.

=item * C<subdivision>

A string field.

=item * C<locale_name>

A string field.

=back

=head2 Table territories

=over 4

=item * C<territory_id>

An integer field.

=item * C<territory>

A string field.

=item * C<parent>

A string field.

=item * C<gdp>

An integer field.

=item * C<literacy_percent>

A decimal field.

=item * C<population>

An integer field.

=item * C<languages>

A string array field.

=item * C<contains>

A string array field.

=item * C<currency>

A string field.

=item * C<calendars>

A string array field.

=item * C<min_days>

An integer field.

=item * C<first_day>

An integer field.

=item * C<weekend>

An integer array field.

=item * C<status>

A string field.

=back

=head2 Table territories_l10n

=over 4

=item * C<terr_l10n_id>

An integer field.

=item * C<locale>

A string field.

=item * C<territory>

A string field.

=item * C<locale_name>

A string field.

=item * C<alt>

A string field.

=back

=head2 Table time_formats

=over 4

=item * C<time_format_id>

An integer field.

=item * C<region>

A string field.

=item * C<territory>

A string field.

=item * C<locale>

A string field.

=item * C<time_format>

A string field.

=item * C<time_allowed>

A string array field.

=back

=head2 Table time_relative_l10n

=over 4

=item * C<time_relative_id>

An integer field.

=item * C<locale>

A string field.

=item * C<field_type>

A string field.

=item * C<field_length>

A string field.

=item * C<relative>

An integer field.

=item * C<format_pattern>

A string field.

=item * C<count>

A string field.

=back

=head2 Table timezones

=over 4

=item * C<timezone_id>

An integer field.

=item * C<timezone>

A string field.

=item * C<territory>

A string field.

=item * C<region>

A string field.

=item * C<tzid>

A string field.

=item * C<metazone>

A string field.

=item * C<tz_bcpid>

A string field.

=item * C<is_golden>

A boolean field.

=item * C<is_primary>

A boolean field.

=item * C<is_preferred>

A boolean field.

=item * C<is_canonical>

A boolean field.

=item * C<alias>

A string array field.

=back

=head2 Table timezones_cities

=over 4

=item * C<tz_city_id>

An integer field.

=item * C<locale>

A string field.

=item * C<timezone>

A string field.

=item * C<city>

A string field.

=item * C<alt>

A string field.

=back

=head2 Table timezones_cities_supplemental

=over 4

=item * C<tz_city_id>

An integer field.

=item * C<locale>

A string field.

=item * C<timezone>

A string field.

=item * C<city>

A string field.

=item * C<alt>

A string field.

=back

=head2 Table timezones_formats

=over 4

=item * C<tz_fmt_id>

An integer field.

=item * C<locale>

A string field.

=item * C<type>

A string field.

=item * C<subtype>

A string field.

=item * C<format_pattern>

A string field.

=back

=head2 Table timezones_info

=over 4

=item * C<tzinfo_id>

An integer field.

=item * C<timezone>

A string field.

=item * C<metazone>

A string field.

=item * C<start>

A datetime field.

=item * C<until>

A datetime field.

=back

=head2 Table timezones_names

=over 4

=item * C<tz_name_id>

An integer field.

=item * C<locale>

A string field.

=item * C<timezone>

A string field.

=item * C<width>

A string field.

=item * C<generic>

A string field.

=item * C<standard>

A string field.

=item * C<daylight>

A string field.

=back

=head2 Table unit_aliases

=over 4

=item * C<unit_alias_id>

An integer field.

=item * C<alias>

A string field.

=item * C<target>

A string field.

=item * C<reason>

A string field.

=back

=head2 Table unit_constants

=over 4

=item * C<unit_constant_id>

An integer field.

=item * C<constant>

A string field.

=item * C<expression>

A string field.

=item * C<value>

A decimal field.

=item * C<description>

A string field.

=item * C<status>

A string field.

=back

=head2 Table unit_conversions

=over 4

=item * C<unit_conversion_id>

An integer field.

=item * C<source>

A string field.

=item * C<base_unit>

A string field.

=item * C<expression>

A string field.

=item * C<factor>

A decimal field.

=item * C<systems>

A string array field.

=item * C<category>

A string field.

=back

=head2 Table unit_prefixes

=over 4

=item * C<unit_prefix_id>

An integer field.

=item * C<unit_id>

A string field.

=item * C<symbol>

A string field.

=item * C<power>

An integer field.

=item * C<factor>

An integer field.

=back

=head2 Table unit_prefs

=over 4

=item * C<unit_pref_id>

An integer field.

=item * C<unit_id>

A string field.

=item * C<territory>

A string field.

=item * C<category>

A string field.

=item * C<usage>

A string field.

=item * C<geq>

A decimal field.

=item * C<skeleton>

A string field.

=back

=head2 Table unit_quantities

=over 4

=item * C<unit_quantity_id>

An integer field.

=item * C<base_unit>

A string field.

=item * C<quantity>

A string field.

=item * C<status>

A string field.

=item * C<comment>

A string field.

=back

=head2 Table units_l10n

=over 4

=item * C<units_l10n_id>

An integer field.

=item * C<locale>

A string field.

=item * C<format_length>

A string field.

=item * C<unit_type>

A string field.

=item * C<unit_id>

A string field.

=item * C<unit_pattern>

A string field.

=item * C<pattern_type>

A string field.

=item * C<locale_name>

A string field.

=item * C<count>

A string field.

=item * C<gender>

A string field.

=item * C<gram_case>

A string field.

=back

=head2 Table variants

=over 4

=item * C<variant_id>

An integer field.

=item * C<variant>

A string field.

=item * C<status>

A string field.

=back

=head2 Table variants_l10n

=over 4

=item * C<var_l10n_id>

An integer field.

=item * C<locale>

A string field.

=item * C<variant>

A string field.

=item * C<locale_name>

A string field.

=item * C<alt>

A string field.

=back

=head2 Table week_preferences

=over 4

=item * C<week_pref_id>

An integer field.

=item * C<locale>

A string field.

=item * C<ordering>

A string array field.

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Locale::Unicode>, L<DateTime::Locale::FromCLDR>, L<DateTime::Formatter::Unicode>, L<DateTime::Locale::FromData>, L<DateTime::Format::CLDR>

=head1 CREDITS

Credits to GeoNames (L<http://www.geonames.org|http://www.geonames.org>) and its data that helped build the time zones extended exemplar cities data in many localised versions.

GeoNames is a project of Unxos GmbH, Tutilostrasse 17d, 9011 St. Gallen, Switzerland, and managed by Marc Wick.

GeoNames data is licensed under a Creative Commons Attribution 4.0 License.

=head1 COPYRIGHT & LICENSE

Copyright(c) 2024 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
