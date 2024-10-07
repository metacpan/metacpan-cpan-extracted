##----------------------------------------------------------------------------
## Locale Intl - ~/lib/Locale/Intl.pm
## Version v0.1.0
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2024/09/16
## Modified 2024/09/16
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Locale::Intl;
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Locale::Unicode );
    use vars qw( $VERSION $ERROR $DEBUG );
    use curry;
    use Locale::Unicode::Data;
    use Want;
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub new
{
    my $this = shift( @_ );
    my $locale = shift( @_ );
    my $opts = $this->_get_args_as_hash( @_ );
    my $self = $this->Locale::Unicode::new( $locale, %$opts ) ||
        return( $this->pass_error( $this->error ) );
    # We have to handle 'language' and 'region' specially
    if( exists( $opts->{language} ) )
    {
        my $lang = delete( $opts->{language} );
        if( defined( $lang ) &&
            length( $lang ) )
        {
            my $loc = Locale::Unicode->new( $lang ) ||
                return( $this->pass_error( Locale::Unicode->error ) );
            if( my $locale2 = $loc->locale )
            {
                $self->locale( $locale2 );
                $self->locale3( undef );
            }
            elsif( my $locale3 = $loc->locale3 )
            {
                $self->locale( undef );
                $self->locale3( $locale3 );
            }
        }
        # This is not good, but if this is what the user wants...
        else
        {
            $self->locale( undef );
            $self->locale3( undef );
        }
    }

    if( exists( $opts->{region} ) )
    {
        my $region = delete( $opts->{region} );
        if( defined( $region ) &&
            length( $region ) )
        {
            # A country code
            if( $region =~ /^[a-zA-Z]{2}$/ )
            {
                $self->country_code( $region );
                $self->SUPER::region( undef );
            }
            # A world region
            elsif( $region =~ /^\d{3}$/ )
            {
                $self->country_code( undef );
                $self->SUPER::region( $region );
            }
            else
            {
                return( $self->error( "Unknown region value '", ( $region // 'undef' ), "' provided." ) );
            }
        }
        else
        {
            $self->country_code( undef );
            $self->SUPER::region( undef );
        }
    }
    my $map =
    {
        calendar    => sub{ $self->SUPER::calendar( @_ ); },
        caseFirst   => $self->curry::colCaseFirst,
        collation   => sub{ $self->SUPER::collation( @_ ); },
        hourCycle   => $self->curry::hour_cycle,
        numberingSystem => $self->curry::number,
        numeric     => $self->curry::colNumeric,
        script      => sub{ $self->SUPER::script( @_ ) },
    };
    foreach my $prop ( keys( %$opts ) )
    {
        if( exists( $map->{ $prop } ) )
        {
            my $rv = $map->{ $prop }->( $opts->{ $prop } );
            delete( $opts->{ $prop } );
            if( !defined( $rv ) && $self->error )
            {
                return( $this->pass_error( $self->error ) );
            }
        }
    }

    if( scalar( keys( %$opts ) ) )
    {
        warn( "Unknow option parameters provided: '", join( "', '", map( overload::StrVal( $_ ), sort( keys( %$opts ) ) ) ), "'" ) if( warnings::enabled() );
    }
    $self->{_cldr} = Locale::Unicode::Data->new;
    return( $self );
}

sub baseName
{
    my $self = shift( @_ );
    if( my $core = $self->core )
    {
        return( $core );
    }
    # Otherwise, as per the specs, we return undef
    if( Want::want( 'OBJECT' ) )
    {
        return( Locale::Intl::NullObject->new );
    }
    return;
}

sub calendar
{
    my $self = shift( @_ );
    # This is a property, so it is read-only, but we need to ensure our parent package method keeps working
    if( @_ )
    {
        return( $self->SUPER::calendar( @_ ) );
    }

    if( my $col = $self->SUPER::calendar )
    {
        return( $col );
    }
    # Otherwise, as per the specs, we return undef
    if( Want::want( 'OBJECT' ) )
    {
        return( Locale::Intl::NullObject->new );
    }
    return;
}

sub caseFirst
{
    my $self = shift( @_ );
    if( my $cf = $self->colCaseFirst )
    {
        return( $cf );
    }
    # Otherwise, as per the specs, we return undef
    if( Want::want( 'OBJECT' ) )
    {
        return( Locale::Intl::NullObject->new );
    }
    return;
}

sub collation
{
    my $self = shift( @_ );
    # This is a property, so it is read-only, but we need to ensure our parent package method keeps working
    if( @_ )
    {
        return( $self->SUPER::collation( @_ ) );
    }

    if( my $col = $self->SUPER::collation )
    {
        return( $col );
    }
    # Otherwise, as per the specs, we return undef
    if( Want::want( 'OBJECT' ) )
    {
        return( Locale::Intl::NullObject->new );
    }
    return;
}

sub error
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $msg = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : $_, @_ ) );
        $self->{error} = $ERROR = Locale::Intl::Exception->new({
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
            if( Want::want( 'ARRAY' ) )
            {
                rreturn( [] );
            }
            elsif( Want::want( 'OBJECT' ) )
            {
                rreturn( Locale::Intl::NullObject->new );
            }
            return;
        }
    }
    return( ref( $self ) ? $self->{error} : $ERROR );
}

sub getAllCalendars
{
    my $self = shift( @_ );
    my $cldr = $self->_cldr || return( $self->pass_error );
    my $all = $cldr->calendars;
    my @cals = map( $_->{calendar}, @$all );
    return( \@cals );
}

sub getAllNumberingSystems
{
    my $self = shift( @_ );
    my $cldr = $self->_cldr || return( $self->pass_error );
    my $all = $cldr->number_systems;
    my @ids = map( $_->{number_system}, @$all );
    return( \@ids );
}

sub getAllTimeZones
{
    my $self = shift( @_ );
    my $cldr = $self->_cldr || return( $self->pass_error );
    my $all = $cldr->timezones;
    my @tzs = map( $_->{timezone}, @$all );
    return( \@tzs );
}

sub getCalendars
{
    my $self = shift( @_ );
    my $cldr = $self->_cldr || return( $self->pass_error );
    my $cc;
    # This is how the algorithm works.
    # If the locale set has no country code associated, we find out with the maximize() method
    # Then, we get the preferred calendars, or by default, 'gregory'
    unless( $cc = $self->country_code )
    {
        my $lang = $self->maximize;
        my $new = $self->new( $lang ) || return( $self->pass_error );
        $cc = $new->country_code || return( $self->error( "Unable to find out a country code for this locale '", $self->core, "', or '${lang}'" ) );
    }
    my $ref = $cldr->territory( territory => $cc ) ||
        return( $self->error( "Unknown territory code '${cc}'" ) );
    my $cals = $ref->{calendars};
    # If there are no calendars identified for this territory, by standard, we must look it up in the 'World' territory, i.e. '001'
    unless( $cals && ref( $cals ) eq 'ARRAY' && scalar( @$cals ) )
    {
        $ref = $cldr->territory( territory => '001' ) ||
            return( $self->error( "Unknown territory code '001' used for World ! This should not be happening." ) );
        if( $ref && 
            $ref->{calendars} &&
            ref( $ref->{calendars} // '' ) eq 'ARRAY' &&
            scalar( @{$ref->{calendars}} ) )
        {
            $cals = $ref->{calendars};
        }
        else
        {
            return( $self->error( "Unable to find the calendars data for the territory '001' (World). This should not be happening." ) );
        }
    }
    return( $cals );
}

sub getCollations
{
    my $self = shift( @_ );
    my $cldr = $self->_cldr || return( $self->pass_error );
    my $core = $self->core;
    my $tree = $cldr->make_inheritance_tree( $core ) ||
        return( $self->pass_error( $cldr->error ) );
    my $collations;
    foreach my $loc ( @$tree )
    {
        my $ref = $cldr->locale(
            locale => $loc,
        );
        return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
        if( $ref && 
            defined( $ref->{collations} ) &&
            ref( $ref->{collations} ) eq 'ARRAY' &&
            scalar( @{$ref->{collations}} ) )
        {
            $collations = $ref->{collations};
            last;
        }
    }
    return( $collations );
}

sub getHourCycles
{
    my $self = shift( @_ );
    my $cldr = $self->_cldr || return( $self->pass_error );
    # If an hour cycle has been set, return it, as per the specs.
    if( my $hc = $self->hour_cycle )
    {
        return( [$hc] );
    }
    my $core = $self->core;
    # Maybe something like fr-CA ?
    my $ref = $cldr->time_format( region => $core );
    if( !$ref )
    {
        my $cc = ( $self->country_code || $self->SUPER::region );
        unless( $cc )
        {
            my $full = $self->maximize || return( $self->pass_error );
            my $loc = $self->new( $full ) || return( $self->pass_error );
            $cc = ( $self->country_code || $self->SUPER::region );
        }
        return( [] ) if( !$cc );
        my $all = $cldr->time_formats( territory => $cc );
        return( $self->pass_error( $cldr->error ) ) if( !defined( $all ) && $cldr->error );
        $ref = $all->[0] if( $all && ref( $all ) eq 'ARRAY' );
    }
    if( $ref &&
        exists( $ref->{time_format} ) &&
        $ref->{time_format} )
    {
        my $map =
        {
            h => 'h12',
            H => 'h23',
            k => 'h24',
            K => 'h11',
        };
        my @rv = map{ $map->{ $_ } || $_ } split( //, $ref->{time_format} );
        return( \@rv );
    }
    return( [] );
}

sub getNumberingSystems
{
    my $self = shift( @_ );
    # "If the Locale already has a numberingSystem, then the returned array contains that single value."
    if( my $nu = $self->number )
    {
        return( [$nu] );
    }
    my $cldr = $self->_cldr || return( $self->pass_error );
    my $core = $self->core;
    my $tree = $cldr->make_inheritance_tree( $core ) ||
        return( $self->pass_error( $cldr->error ) );
    my $num_sys;
    foreach my $loc ( @$tree )
    {
        my $ref = $cldr->locale_number_system(
            locale => $loc,
        );
        return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
        if( $ref &&
            length( $ref->{number_system} // '' ) )
        {
            $num_sys = $ref->{number_system};
            last;
        }
    }
    # Although we return an array, in reality, there is only one element in the array.
    return( [$num_sys] ) if( defined( $num_sys ) );
    return( [] );
}

sub getTextInfo
{
    my $self = shift( @_ );
    my $cldr = $self->_cldr || return( $self->pass_error );
    my $core = $self->core;
    my $tree = $cldr->make_inheritance_tree( $core ) ||
        return( $self->pass_error( $cldr->error ) );
    my $orientation;
    foreach my $loc ( @$tree )
    {
        my $ref = $cldr->locales_info(
            locale => $loc,
            property => 'char_orientation',
        );
        return( $self->pass_error( $cldr->error ) ) if( !defined( $ref ) && $cldr->error );
        if( $ref &&
            length( $ref->{value} // '' ) )
        {
            $orientation = $ref->{value};
            last;
        }
    }
    my $map =
    {
        'right-to-left' => 'rtl',
        'left-to-right' => 'ltr',
    };
    if( defined( $orientation ) )
    {
        return( $self->error( "Unsupported value '${orientation}' found for locale '${core}'" ) ) if( !exists( $map->{ $orientation } ) );
        return( $map->{ $orientation } );
    }
    return( 'ltr' );
}

sub getTimeZones
{
    my $self = shift( @_ );
    my $cldr = $self->_cldr || return( $self->pass_error );
    my $cc = $self->country_code;
    unless( $cc )
    {
        my $full = $self->maximize;
        my $loc = $self->new( $full ) || return( $self->error );
        $cc = $loc->country_code;
    }
    if( $cc )
    {
        my $all = $cldr->timezones( territory => $cc, is_canonical => 1 ) ||
            return( $self->pass_error( $cldr->error ) );
        my @timezones = map( $_->{timezone}, @$all );
        return( \@timezones );
    }
    else
    {
        return( [] );
    }
}

sub getWeekInfo
{
    my $self = shift( @_ );
    my $cldr = $self->_cldr || return( $self->pass_error );
    my $core = $self->core;
    my $cc;
    unless( $cc = $self->country_code )
    {
        my $full = $self->maximize || return( $self->pass_error );
        my $locale = $self->new( $full ) || return( $self->pass_error );
        $cc = $locale->country_code || return( $self->error( "No country code could be derived for this locale ${core}" ) );
    }
    my $info = $cldr->territory( territory => $cc );
    my $fallback;
    my $def = {};
    # Firt day of the week
    if( length( $info->{first_day} // '' ) )
    {
        $def->{firstDay} = $info->{first_day};
    }
    else
    {
        # 001 is the code for World, acting as the default fallback value
        $fallback = $cldr->territory( territory => '001' ) if( !defined( $fallback ) );
        $def->{firstDay} = $fallback->{first_day} if( $fallback );
    }
    # Minimum number of days for calendar display
    if( length( $info->{min_days} // '' ) )
    {
        $def->{minimalDays} = $info->{min_days};
    }
    else
    {
        # 001 is the code for World, acting as the default fallback value
        $fallback = $cldr->territory( territory => '001' ) if( !defined( $fallback ) );
        $def->{minimalDays} = $fallback->{min_days} if( $fallback );
    }
    # Week-end start, end
    # The value is already an array reference in the database
    if( length( $info->{weekend} // '' ) )
    {
        $def->{weekend} = $info->{weekend};
    }
    else
    {
        # 001 is the code for World, acting as the default fallback value
        $fallback = $cldr->territory( territory => '001' ) if( !defined( $fallback ) );
        $def->{weekend} = $fallback->{weekend} if( $fallback );
    }
    return( $def );
}

sub hourCycle
{
    my $self = shift( @_ );
    # If hour cycle has been set as component of the locale, or as an object option
    # we return it
    if( my $hc = $self->hour_cycle )
    {
        return( $hc );
    }
    # Otherwise, as per the specs, we return undef
    if( Want::want( 'OBJECT' ) )
    {
        return( Locale::Intl::NullObject->new );
    }
    return;
}

sub language
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        if( !defined( $val ) )
        {
            $self->SUPER::language( undef );
            $self->SUPER::language3( undef );
        }
        elsif( length( $val ) == 2 )
        {
            $self->SUPER::language( $val );
        }
        else
        {
            $self->SUPER::language3( $val );
        }
    }
    if( my $loc = ( $self->SUPER::language || $self->SUPER::language3 ) )
    {
        return( $loc );
    }
    if( Want::want( 'OBJECT' ) )
    {
        return( Locale::Intl::NullObject->new );
    }
    return;
}

sub maximise { return( shift->maximize( @_ ) ); }

sub maximize
{
    my $self = shift( @_ );
    my $cldr = $self->_cldr || return( $self->pass_error );
    my $core = $self->core;
    my $tree = $cldr->make_inheritance_tree( $core ) ||
        return( $self->pass_error( $cldr->error ) );
    my $full;
    foreach my $loc ( @$tree )
    {
        my $ref = $cldr->likely_subtag( locale => $loc );
        if( $ref && $ref->{target} )
        {
            $full = $ref->{target};
            last;
        }
    }

    if( defined( $full ) )
    {
        my $new = $self->new( $full );
        my $clone = $self->clone;
        if( my $locale = $new->locale )
        {
            $clone->locale( $locale );
        }
        elsif( my $locale3 = $new->locale3 )
        {
            $clone->locale3( $locale3 );
        }

        if( my $script = $new->script )
        {
            $clone->script( $script );
        }

        if( my $cc = $new->country_code )
        {
            $clone->country_code( $cc );
        }
        elsif( my $code = $new->region )
        {
            $clone->region( $code );
        }

        if( my $variant = $new->variant )
        {
            $clone->variant( $variant );
        }
        return( $clone );
    }
    else
    {
        return( $self );
    }
}

sub minimise { return( shift->minimize( @_ ) ); }

sub minimize
{
    my $self = shift( @_ );
    my $cldr = $self->_cldr || return( $self->pass_error );
    my $core = $self->core;
    my $locale = $self->locale;
    my $locale3 = $self->locale3;
    my $script = $self->script;
    my $cc = $self->country_code;
    my $clone = $self->clone;
    $clone->locale( undef );
    $clone->locale3( undef );
    $clone->script( undef );
    $clone->country_code( undef );
    $clone->SUPER::region( undef );
    if( !defined( $locale ) || !length( $locale ) )
    {
        # If und, this should become, with maximize(), en-Latn-US
        $locale3 //= 'und';
        my $test = $self->new( "${locale3}" )->maximize;
        $core = $test->core;
        # Maybe the locale3 provided is an invalid locale3, such as xyz. If so we would return it.
        if( $core eq $locale3 )
        {
            return( $self );
        }
        $locale = $test->locale;
        $locale3 = $test->locale3;
        $script = $test->script;
        $cc = $test->country_code;
        $clone->locale( $locale );
    }

    # First check if there is nothing to do
    # Even if it is an unknown language, such as xy, we still return it.
    if( defined( $locale ) && 
        length( $locale ) &&
        $core eq $locale )
    {
        return( $self );
    }

    my $test = $self->new( "$locale" )->maximize;
    my $test_locale = $test->locale;
    # Maybe the same as our initial locale
    # For example: fr-FR -> fr-Latn-FR
    # but
    # und-Latn -> en-Latn-US
    if( $test_locale )
    {
        $clone->locale( $test_locale );
    }
    # Should not happen
    else
    {
        return( $self->error( "Unable to get a locale language by maximising \"${core}\"" ) );
    }
    # First check if we have a country code, and maybe if this country code is the authority for this language
    # such as fr -> fr-FR
    # We get the maximised version derived from the 2-characters language and if it bears the same country code,
    # this means, this is the authoritative country for this language, and there is no need to add the country code.
    # Next, we check if the script, if any, can be removed. For that we use $CLDR_LANGUAGE_SCRIPTS and if found, we check
    # if it is the sole entry for this language. If not found, this means the script is the default 'Latn'
    my $test_cc = $test->country_code;
    my $test_script = $test->script;
    # Our country code is different than the default one for this locale, so we keep it
    if( $cc )
    {
        if( $cc ne $test_cc )
        {
            $clone->country_code( $cc );
        }
    }
    elsif( $test_cc )
    {
        $clone->country_code( $test_cc );
    }
    if( $script )
    {
        my $info = $cldr->language( language => $test_locale );
        my $lang_scripts;
        if( $info &&
            exists( $info->{scripts} ) &&
            ref( $info->{scripts} // '' ) eq 'ARRAY' &&
            scalar( @{$info->{scripts}} ) )
        {
            $lang_scripts = $info->{scripts};
        }
        else
        {
            $lang_scripts = ['Latn'];
        }
        # There could be more than 1 script, but if our script is the first, i.e. 
        # preferred one, it becomes superflous.
        if( $script ne $lang_scripts->[0] )
        {
            $clone->script( $script );
        }
    }
    return( $clone );
}

sub numberingSystem
{
    my $self = shift( @_ );
    if( my $num = $self->number )
    {
        return( $num );
    }

    if( Want::want( 'OBJECT' ) )
    {
        return( Locale::Intl::NullObject->new );
    }
    return;
}

sub numeric
{
    my $self = shift( @_ );
    if( defined( my $bool = $self->colNumeric ) )
    {
        return( $bool ? Locale::Intl::Boolean->true : Locale::Intl::Boolean->false );
    }

    if( Want::want( 'OBJECT' ) )
    {
        return( Locale::Intl::NullObject->new );
    }
    return;
}

sub pass_error
{
    my $self = shift( @_ );
    if( Want::want( 'OBJECT' ) )
    {
        rreturn( Locale::Intl::NullObject->new );
    }
    return;
}

# NOTE: Locale::Unicode makes a distinction between a country code (a 2-letters code) and a region (a 3-digits numeric code)
sub region
{
    my $self = shift( @_ );
    if( @_ )
    {
        return( $self->SUPER::region( @_ ) );
    }
    if( my $rg = ( $self->country_code || $self->SUPER::region ) )
    {
        return( $rg );
    }

    if( Want::want( 'OBJECT' ) )
    {
        return( Locale::Intl::NullObject->new );
    }
    return;
}

sub script
{
    my $self = shift( @_ );
    # This is a property, so it is read-only, but we need to ensure our parent package method keeps working
    if( @_ )
    {
        return( $self->SUPER::script( @_ ) );
    }

    if( my $script = $self->SUPER::script )
    {
        return( $script );
    }

    if( Want::want( 'OBJECT' ) )
    {
        return( Locale::Intl::NullObject->new );
    }
    return;
}

sub toString { return( shift->as_string ); }

sub _cldr
{
    my $self = shift( @_ );
    my $cldr;
    if( ref( $self ) )
    {
        $cldr = $self->{_cldr} ||
            return( $self->error( "The Locale::Unicode::Data object is gone!" ) );
    }
    else
    {
        $cldr = Locale::Unicode::Data->new ||
            return( $self->pass_error( Locale::Unicode::Data->error ) );
    }
    return( $cldr );
}

# NOTE: Locale::Intl::Exception class
package Locale::Intl::Exception;
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
        elsif( ref( $_[0] ) && $_[0]->isa( 'Locale::Intl::Exception' ) )
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

# NOTE: Locale::Intl::Boolean class
package Locale::Intl::Boolean;
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $true $false );
    use overload
      "0+"     => sub{ ${$_[0]} },
      "++"     => sub{ $_[0] = ${$_[0]} + 1 },
      "--"     => sub{ $_[0] = ${$_[0]} - 1 },
      fallback => 1;
    $true  = do{ bless( \( my $dummy = 1 ) => 'Locale::Intl::Boolean' ) };
    $false = do{ bless( \( my $dummy = 0 ) => 'Locale::Intl::Boolean' ) };
    our( $VERSION ) = 'v0.1.0';
};

use strict;
use warnings;

sub new { return( $_[1] ? $true : $false ); }

sub false () { $false }

sub true  () { $true  }

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

{
    # NOTE: Locale::Intl::NullObject class
    package
        Locale::Intl::NullObject;
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

Locale::Intl - A Web Intl.Locale Class Implementation

=head1 SYNOPSIS

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

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class inherits from L<Unicode::Locale>.

Make sure to check the API of L<Unicode::Locale> for its constructor and its methods.

It also accesses the Unicode CLDR (Common Locale Data Repository) data using L<Locale::Unicode::Data>

It requires perl v5.10.1 minimum to run.

=head1 CONSTRUCTOR

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

=head2 new

This takes a L<Unicode locale identifier|Locale::Unicode> and an optional hash or hash reference of options, and returns a new instance of L<Locale::Intl>. For the syntax of L<locale identifier|Locale::Unicode> strings, see the L<Unicode documentation|https://www.unicode.org/reports/tr35/>.

A C<locale> is composed of a C<language>, such as C<fr> (French) or C<ja> (Japanese) or C<gsw> (Swiss German), an optional C<script>, such as C<Latn> (Latin) or C<Kana> (Katanaka), a C<region>, which can be a L<country code|Locale::Unicode/country_code>, such as C<US> (United States) or a world region, such as C<150> (Europe) and a C<variant>, such as C<valencia> as in C<ca-ES-valencia>. Only the C<language> part is required.

The supported options are:

=over 4

=item * C<calendar>

Any syntactically valid string following the L<Unicode type grammar|https://unicode.org/reports/tr35/#Unicode_locale_identifier> (one or more segments of 3–8 alphanumerals, joined by hyphens) is accepted. See L<getAllCalendars()|/getAllCalendars> for all the supported calendars.

See also L<Locale::Unicode/calendar>

=item * C<caseFirst>

This is the case-first sort option. Possible values are C<upper>, C<lower>, or a false value, such as C<undef> or C<0>.

See also L<Locale::Unicode/colCaseFirst>

=item * C<collation>

Any syntactically valid string following the L<Unicode type grammar|https://unicode.org/reports/tr35/#Unicode_locale_identifier> is accepted. See L<getCollations|/getCollations> for a list of supported collations.

See also L<Locale::Unicode/collation>

=item * C<hourCycle>

Possible values are C<h23>, C<h12>, C<h11>, or the practically unused C<h24>, which are explained in L<getHourCycles|/getHourCycles>

See also L<Locale::Unicode/hour_cycle>

=item * C<language>

Not to be confused, this is a part of a broader C<locale>. Any syntactically valid string following the L<Unicode language subtag grammar|https://unicode.org/reports/tr35/#unicode_language_subtag> (2–3 or 5–8 letters) is accepted.

=item * C<numberingSystem>

Any syntactically valid string following the L<Unicode type grammar|https://unicode.org/reports/tr35/#Unicode_locale_identifier> is accepted. See L<getNumberingSystems|/getNumberingSystems> for the numbering systems supported for the C<locale> set in the object, or L<getAllNumberingSystems|/getAllNumberingSystems> for the list of all supported numbering systems.

See also L<Locale::Unicode/number>

=item * C<numeric>

The numeric sort option. This takes a boolean value.

See also L<Locale::Unicode/colNumeric>

=item * C<region>

Any syntactically valid string following the L<Unicode region subtag grammar|https://unicode.org/reports/tr35/#unicode_region_subtag> (either 2 letters or 3 digits) is accepted.

=item * C<script>

Any syntactically valid string following the L<Unicode script subtag|https://unicode.org/reports/tr35/#unicode_script_subtag> grammar (4 letters) is accepted, but the implementation only recognizes certain kinds.

See also L<Locale::Unicode/script>

=back

=head1 METHODS

=head2 getAllCalendars

This is a read-only method that returns an array of all possible calendar values supported by the current version of L<LDML (Locale Data Markup Language)|https://unicode.org/reports/tr35/>.

=head2 getAllNumberingSystems

This is a read-only method that returns an array of all possible numbering system values supported by the current version of L<LDML (Locale Data Markup Language)|https://unicode.org/reports/tr35/>.

=head2 getAllTimeZones

This is a read-only method that returns an array of all possible time zone values supported by the current version of L<LDML (Locale Data Markup Language)|https://unicode.org/reports/tr35/>. Please note that to ensure consistency, the LDML supports some values that are either outdated or removed from IANA's time zone database.

=head2 getCalendars

    my $jaJP = new Locale::Intl( 'ja-JP' );
    say $jaJP->getCalendars(); # ["gregory", "japanese"]

This method returns an array of one or more unique L<calendar|Locale::Unicode/calendar> identifiers for this C<locale>.

See the L<Unicode Locale BCP47 extensions|Locale::Unicode/"BCP47 EXTENSIONS"> for the list of valid calendar values.

=head2 getCollations

    my $locale = Locale::Intl->new( 'zh' );
    say $locale->getCollations(); # ["pinyin", "stroke", "zhuyin", "emoji", "eor"]

The C<getCollations()> method returns an array of one or more collation types commonly used for this L<locale|Locale::Unicode>. If the L<Locale|Locale::Unicode> already has a C<collation>, then the returned array contains that single value.

If the L<locale identifier|Locale::Unicode> object does not have a C<collation> already, C<getCollations()> lists all commonly-used collation types for the given L<locale identifier|Locale::Unicode>.

See the L<Unicode Locale BCP47 extensions|Locale::Unicode/"BCP47 EXTENSIONS"> for the list of valid collation values.

=head2 getHourCycles

    my $jaJP = Locale::Intl->new( 'ja-JP' );
    say $jaJP->getHourCycles(); # ["h23"]

    my $arEG = Locale::Intl->new( 'ar-EG' );
    say $arEG->getHourCycles(); # ["h12"]

This method returns an array of one or more unique hour cycle identifiers commonly used for this L<locale|Locale::Unicode>, sorted in descending preference. If the Locale already has an hourCycle, then the returned array contains that single value.

If the L<locale identifier|Locale::Unicode> object does not have a C<hourCycle> already, this method lists all commonly-used hour cycle identifiers for the given L<locale|Locale::Unicode>.

Below are the valid values:

=over 4

=item * C<h12>

Hour system using C<1–12>; corresponds to C<h> in patterns. The 12 hour clock, with midnight starting at C<12:00> am. As used, for example, in the United States.

=item * C<h23>

Hour system using C<0–23>; corresponds to C<H> in patterns. The 24 hour clock, with midnight starting at C<0:00>.

=item * C<h11>

Hour system using C<0–11>; corresponds to C<K> in patterns. The 12 hour clock, with midnight starting at C<0:00> am. Mostly used in Japan.

=item * C<h24>

Hour system using C<1–24>; corresponds to C<k> in pattern. The 24 hour clock, with midnight starting at C<24:00>. Not used anywhere.

=back

Hour cycles usage in the world are:

=over 4

=item * C<h12 h23>

115 locales

=item * C<h23 h12>

95 locales

=item * C<h23>

60 locales

=item * C<h23 h11 h12>

1 locale

=back

See also the property L<hourCycle|/hourCycle>

=head2 getNumberingSystems

    my $ja = Locale::Intl->new( 'ja' );
    say $ja->getNumberingSystems(); # ["latn"]

    my $arEG = Locale::Intl->new( 'ar-EG' );
    say $arEG->getNumberingSystems(); # ["arab"]

This method returns an array of one or more unique numbering system identifiers commonly used for this L<locale|Locale::Unicode>, sorted in descending preference. If the Locale already has a numberingSystem, then the returned array contains that single value.

See the L<Unicode Locale BCP47 extensions|Locale::Unicode/"BCP47 EXTENSIONS"> for the list of valid numbering system values.

=head2 getTextInfo

    my $ar = Locale::Intl->new( 'ar' );
    say $ar->getTextInfo(); # rtl

    my $es = Locale::Intl->new( 'es' );
    say $es->getTextInfo(); # ltr

This method returns a string representing the ordering of characters indicated by either C<ltr> (left-to-right) or by C<rtl> (right-to-left) for this L<locale|Locale::Unicode> as specified in L<UTS 35 Layouts Elements|https://www.unicode.org/reports/tr35/tr35-general.html#Layout_Elements>.

=head2 getTimeZones

    my $jaJP = Locale::Intl->new( 'ja-JP' );
    say $jaJP->getTimeZones(); # ["Asia/Tokyo"]

    my $ar = Locale::Intl->new( 'ar' );
    # This will resolve to Africa/Cairo, because the locale 'ar' 
    3 will maximize to ar-Arab-EG and from there to Egypt
    say $ar->getTimeZones(); # ["Africa/Cairo"]

This method returns an array of supported time zones for this L<locale|Locale::Unicode>.

ach value is an L<IANA time zone canonical name|https://en.wikipedia.org/wiki/Daylight_saving_time#IANA_time_zone_database>, sorted in alphabetical order. If the L<locale identifier|Locale::Unicode> does not contain a C<region> subtag, the returned value is C<undef>.

Keep in mind that the values do not necessarily match the IANA database that changes from time to time. The Unicode LDML L<keeps old time zones for stability purpose|https://unicode.org/reports/tr35/#Time_Zone_Identifiers>.

Also note that this method behaves slightly differently from its JavaScript counter part, as the L<JavaScript getTimeZones() method|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Locale/getTimeZones> will return C<undef> if only a C<language> subtag is provided and not a C<locale> tha would include a C<country code>. This method, instead, will L<maximize|/maximize> the 2-letters C<locale> provided and from there will returns the time zone for the default country for that language.

See also L<getAllTimeZones|/getAllTimeZones> to get a list of all available time zones.

=head2 getWeekInfo

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

This method returns an hash reference with the properties C<firstDay>, C<weekend> and C<minimalDays> for this L<locale|Locale::Unicode>, as specified in L<UTS 35 Week Elements|https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Patterns_Week_Elements>.

=over 4

=item * C<firstDay>

An integer indicating the first day of the week for the locale. Can be either C<1> (Monday) or C<7> (Sunday).

=item * C<weekend>

An array of integers indicating the weekend days for the locale, where C<1> is Monday and C<7> is Sunday.

=item * C<minimalDays>

An integer between C<1> and C<7> indicating the minimal days required in the first week of a month or year, for calendar purposes.

=back

See also the L<Unicode LDML specifications|https://unicode-org.github.io/cldr/ldml/tr35-dates.html#Date_Patterns_Week_Elements>

=head2 maximise

This is an alias for L<maximise|/maximise>

=head2 maximize

    my $english = Locale::Intl->new( 'en' );
    my $korean = Locale::Intl->new( 'ko' );
    my $arabic = Locale::Intl->new( 'ar' );
    
    say $english->maximize()->baseName;
    # en-Latn-US
    
    say $korean->maximize()->baseName;
    # ko-Kore-KR
    
    say $arabic->maximize()->baseName;
    # ar-Arab-EG

This method gets L<the most likely values|https://github.com/unicode-org/cldr-json/blob/main/cldr-json/cldr-core/supplemental/likelySubtags.json> for the C<language>, C<script>, and C<region> of this L<locale|Locale::Unicode> based on existing values and returns a new L<Locale::Intl> object.

Sometimes, it is convenient to be able to identify the most likely L<locale language identifier|Locale::Unicode> subtags based on an incomplete C<language> ID. The L<Add Likely Subtags algorithm|https://www.unicode.org/reports/tr35/#Likely_Subtags> gives us this functionality. For instance, given the C<language> ID C<en>, the algorithm would return C<en-Latn-US>, since English can only be written in the Latin script, and is most likely to be used in the United States, as it is the largest English-speaking country in the world. This functionality is provided via this C<maximize()> method. C<maximize()> only affects the main subtags that comprise the C<language> identifier: C<language>, C<script>, and C<region> subtags. Other subtags after the C<-u> in the C<locale> identifier are L<called extension subtags|Locale::Unicode/"BCP47 EXTENSIONS"> and are not affected by the C<maximize()> method. Examples of these subtags include L<hourCycle|/hourCycle>, L<calendar|/calendar>, and L<numeric|/numeric>.

Upon error, it sets an L<exception object|Locale::Intl::Exception> and returns C<undef> in scalar context, or an empty list in list context.

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

=head2 minimise

This is an alias for L<minimise|/minimise>

=head2 minimize

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

This method attempts to remove information about this C<locale> that would be added by calling L<maximize()|/maximize>, which means removing any language, script, or region subtags from the locale language identifier (essentially the contents of baseName).

This is useful when there are superfluous subtags in the language identifier; for instance, C<en-Latn> can be simplified to C<en>, since C<Latn> is the only script used to write English. C<minimize()> only affects the main subtags that comprise the L<language identifier|Locale::Unicode>: C<language>, C<script>, and C<region> subtags. Other subtags after the C<-u> in the L<locale identifier|Locale::Unicode> are called L<extension subtags|Locale::Unicode/"BCP47 EXTENSIONS"> and are not affected by the C<minimize()> method. Examples of these subtags include L<hourCycle|/hourCycle>, L<calendar|/calendar>, and L<numeric|/numeric>. 

This returns a new L<Locale::Intl> instance whose L<baseName|/baseName> property returns the result of the L<Remove Likely Subtags|https://www.unicode.org/reports/tr35/#Likely_Subtags> algorithm executed against C<< $locale->baseName >>. 

=for Pod::Coverage pass_error

=head2 toString

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

This method returns this L<Locale::Intl>'s full locale identifier string.

The string value is computed once and is cached until any of the C<locale>'s attributes are changed.

=head1 PROPERTIES

=head2 baseName

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

The C<baseName> accessor property of L<Locale::Intl> instances returns a substring of this C<locale>'s string representation, containing core information about this locale.

Specifically, this returns the substring containing the C<language>, the C<script> and C<region> if available.

See L<Unicode grammar ID|https://www.unicode.org/reports/tr35/#Identifiers> for more information.

=head2 calendar

This returns the calendar type for this locale.

The C<calendar> property's value is set at object instantiation time, either through the C<ca> attribute of the C<locale> identifier or through the C<calendar> option of the L<Locale::Unicode> constructor. The latter takes priority if they are both present; and if neither is present, the property has value C<undef>.

For a list of supported calendar types, see L<Locale::Intl/getCalendars>.

For example:

Adding a C<calendar> through the C<locale> attribute.

In the L<Unicode locale string specifications|https://www.unicode.org/reports/tr35/>, C<calendar> era types are C<locale> attribute "extension subtags". These subtags add additional data about the C<locale>, and are added to C<locale> identifiers by using the C<-u> extension. Thus, the C<calendar> era type can be added to the initial C<locale> identifier string that is passed into the L<Locale::Intl> constructor. To add the calendar type, first add the C<-u> extension to the string. Next, add the L<-ca|Locale::Unicode/ca> extension to indicate that you are adding a calendar type. Finally, add the calendar era type to the string.

    my $locale = Locale::Intl->new( 'he-IL-u-ca-hebrew-tz-jeruslm' );
    say $locale->calendar; # hebrew

Alternatively, you could also achieve the same results, using the methods inherited from L<Locale::Unicode>:

    my $locale = Locale::Intl->new( 'he-IL' );
    $locale->ca( 'hebrew' )->tz( 'jeruslm' );
    say $locale->calendar; # hebrew

Adding a C<calendar> type via the optional hash or hash reference of options.

The L<Locale::Intl> constructor takes an optional hash or hash reference of options, which can contain any of several extension types, including calendars. Set the C<calendar> property of the optional hash or hash reference to your desired C<calendar> era, and then pass it into the constructor.

    my $locale = Locale::Intl->new( 'he-IL', { calendar => 'hebrew' } );
    say $locale->calendar; # hebrew

=head2 caseFirst

The C<caseFirst> accessor property of L<Locale::Intl> instances returns whether case is taken into account for this C<locale>'s collation rules.

There are 3 values that the C<caseFirst> property can have, outlined in the table below.

=over 4

=item * C<upper>

Upper case to be sorted before lower case.

=item * C<lower>

Lower case to be sorted before upper case.

=item * C<false>

No special case ordering.

=back

Setting the caseFirst value via the locale string

In the L<Unicode locale string specifications|https://www.unicode.org/reports/tr35/>, the values that C<aseFirst> represents correspond to the attribute L<kf|Locale::Unicode/kf>. C<kf> is treated as a C<locale> string "extension subtag". These subtags add additional data about the C<locale>, and are added to C<locale> identifiers by using the C<-u> extension attribute. Thus, the C<caseFirst> value can be added to the initial C<locale> identifier string that is passed into the L<Locale|Locale::Unicode> constructor. To add the C<caseFirst> value, first add the C<-u> extension key to the string. Next, add the L<-kf|Locale::Unicode/kf> extension key to indicate that you are adding a value for C<caseFirst>. Finally, add the C<caseFirst> value to the string.

    my $locale = Locale::Intl->new( "fr-Latn-FR-u-kf-upper" );
    say $locale->caseFirst; # upper

Setting the C<caseFirst> value via the optional hash or hash reference of options.

The L<Locale::Intl> constructor takes an optional hash or hash reference of options, which can be used to pass extension types. Set the C<caseFirst> property of the configuration object to your desired C<caseFirst> value, and then pass it into the constructor.

    my $locale = Locale::Intl->new( "en-Latn-US", { caseFirst => "lower" });
    say $locale->caseFirst; # lower

=head2 collation

The C<collation> accessor property of L<Locale::Intl> instances returns the C<collation> type for this C<locale>, which is used to order strings according to the C<locale>'s rules.

The C<collation> property's value is set at object instantiation time, either through the L<co|Locale::Unicode/co> attribute of the L<locale identifier|Locale::Unicode> or through the C<collation> option of the L<Locale::Intl> constructor. The latter takes priority if they are both present; and if neither is present, the property has value C<undef>.

For a list of supported collation types, see L<getCollations()|Locale::Intl/getCollations>.

For example:

Adding a collation type via the locale string.

In the L<Unicode locale string specifications|https://www.unicode.org/reports/tr35/>, C<collation> types are C<locale> attribute "extension subtags". These subtags add additional data about the C<locale>, and are added to L<locale identifiers|Locale::Unicode> by using the C<-u> extension. Thus, the L<collation|Locale::Unicode/collation> type can be added to the initial L<locale identifier|Locale::Unicode> string that is passed into the L<Locale::Intl> constructor. To add the C<collation> type, first add the C<-u> extension to the string. Next, add the C<-co> extension to indicate that you are adding a collation type. Finally, add the collation type to the string.

    my $locale = Locale::Intl->new( "zh-Hant-u-co-zhuyin" );
    say $locale->collation; # zhuyin

Adding a collation type via the configuration object argument.

The L<Locale::Intl> constructor has an optional hash or hash reference of options, which can contain any of several extension types, including C<collation> types. Set the C<collation> property of the configuration object to your desired C<collation> type, and then pass it into the constructor.

    my $locale = Locale::Intl->new( "zh-Hant", { collation => "zhuyin" });
    say $locale->collation; # zhuyin

=head2 hourCycle

The C<hourCycle> accessor property of L<Locale::Intl> instances returns the L<hour cycle|Locale::Unicode/hour_cycle> type for this L<locale identifier|Locale::Unicode>.

There are 2 main types of time keeping conventions (clocks) used around the world: the 12 hour clock and the 24 hour clock. The C<hourCycle> property's value is set upon object instantiation, either through the L<hc|Locale::Unicode/hc> attribute of the L<locale identifier|Locale::Unicode> or through the C<hourCycle> option of the L<Locale::Intl> constructor. The latter takes priority if they are both present; and if neither is present, the property has value C<undef>.

For a list of supported hour cycle types, see L<getHourCycles()|Locale::Intl/getHourCycles>.

For example:

Like other C<locale> subtags, the hour cycle type can be added to the L<Locale::Intl> object via the locale string, or an option upon object instantiation.

Adding an hour cycle via the locale string

In the L<Unicode locale string specifications|https://www.unicode.org/reports/tr35/>, L<hour cycle|Locale::Unicode/hour_cycle> types are locale attribute "extension subtags". These subtags add additional data about the C<locale>, and are added to L<locale identifiers|Locale::Unicode> by using the C<-u> extension. Thus, the hour cycle type can be added to the initial L<locale identifier|Locale::Unicode> string that is passed into the L<Locale::Intl> constructor. To add the L<hour cycle|Locale::Unicode/hour_cycle> type, first add the C<-u> extension key to the string. Next, add the C<-hc> extension to indicate that you are adding an hour cycle. Finally, add the hour cycle type to the string.

    my $locale = Locale::Intl->new( "fr-FR-u-hc-h23" );
    say $locale->hourCycle; # h23

Adding an hour cycle via the configuration object argument

The L<Locale::Intl> constructor has an optional hash or hash reference of options, which can contain any of several extension types, including L<hour cycle|Locale::Unicode/hour_cycle> types. Set the C<hourCycle> property of the configuration object to your desired hour cycle type, and then pass it into the constructor.

    my $locale = Locale::Intl->new( "en-US", { hourCycle => "h12" });
    say $locale->hourCycle; # h12

=head2 language

The C<language> accessor property of L<Locale::Intl> instances returns the C<language> associated with this C<locale>.

Language is one of the core features of a C<locale>. The Unicode specification treats the C<language> identifier of a C<locale> as the C<language> and the C<region> together (to make a distinction between dialects and variations, e.g. British English vs. American English). However, the C<language> property of an L<Locale::Intl> object returns strictly the C<locale>'s C<language> subtag. This subtag can be a 2 or 3-characters code.

For example:

Setting the C<language> in the locale identifier string argument.

In order to be a valid L<Unicode locale identifier|Locale::Unicode>, a string must start with the C<language> subtag. The main argument to the L<Locale::Intl> constructor must be a valid L<Unicode locale identifier|Locale::Unicode>, so whenever the constructor is used, it must be passed an identifier with a C<language> subtag.

    my $locale = Locale::Intl->new( "en-Latn-US" );
    say $locale->language; # en

Overriding language via the configuration object.

While the C<language> subtag must be specified, the L<Locale::Intl> constructor takes an hash or hash reference of options, which can override the C<language> subtag.

    my $locale = Locale::Intl->new( "en-Latn-US", { language => "es" });
    say $locale->language; # es

=head2 numberingSystem

The C<numberingSystem> accessor property of L<Locale::Intl> instances returns the numeral system for this C<locale>.

A numeral system is a system for expressing numbers. The C<numberingSystem> property's value is set upon object instantiation, either through the L<nu|Locale::Unicode/nu> attribute of the L<locale identifier|Locale::Unicode> or through the C<numberingSystem> option of the L<Locale::Intl> constructor. The latter takes priority if they are both present; and if neither is present, the property has value C<undef>.

For a list of supported numbering system types, see L<getNumberingSystems()|Locale::Intl/getNumberingSystems>.

Adding a numbering system via the locale string.

In the L<Unicode locale string specifications|https://www.unicode.org/reports/tr35/>, numbering system types are C<locale> attribute "extension subtags". These subtags add additional data about the C<locale>, and are added to C<locale> identifiers by using the C<-u> extension. Thus, the numbering system type can be added to the initial C<locale> identifier string that is passed into the L<Locale::Intl> constructor. To add the numbering system type, first add the C<-u> extension attribute to the string. Next, add the L<-nu|Locale::Unicode/nu> extension to indicate that you are adding a numbering system. Finally, add the numbering system type to the string.

    my $locale = Locale::Intl->new( "fr-Latn-FR-u-nu-mong" );
    say $locale->numberingSystem; # mong

Adding a numbering system via the configuration object argument.

The L<Locale::Intl> constructor has an optional hash or hash reference of options, which can contain any of several extension types, including numbering system types. Set the C<numberingSystem> property of the hash or hash reference of options to your desired numbering system type, and then pass it into the constructor.

    my $locale = Locale::Intl->new( "en-Latn-US", { numberingSystem => "latn" });
    say $locale->numberingSystem; # latn

=head2 numeric

The C<numeric> accessor property of L<Locale::Intl> instances returns a L<boolean object|Locale::Intl::Boolean> representing whether this C<locale> has special collation handling for C<numeric> characters.

Like C<caseFirst>, C<numeric> represents a modification to the collation rules utilized by the locale. C<numeric> is a boolean value, which means that it can be either L<true|Locale::Intl::Boolean/true> or L<false|Locale::Intl::Boolean/false>. If C<numeric> is set to C<false>, there will be no special handling of C<numeric> values in strings. If C<numeric> is set to C<true>, then the C<locale> will take C<numeric> characters into account when collating strings. This special C<numeric> handling means that sequences of decimal digits will be compared as numbers. For example, the string C<A-21> will be considered less than C<A-123>.

Example:

Setting the numeric value via the locale string.

In the L<Unicode locale string specifications|https://www.unicode.org/reports/tr35/>, the values that C<numeric> represents correspond to the attribute L<kn|Locale::Unicode/kn>. L<kn|Locale::Unicode/kn> is considered a L<locale|Locale::Unicode> string extension subtag". These subtags add additional data about the L<locale|Locale::Unicode>, and are added to L<locale identifiers|Locale::Unicode> by using the -u extension key. Thus, the C<numeric> value can be added to the initial L<locale identifier|Locale::Unicode> string that is passed into the L<Locale::Intl> constructor. To set the C<numeric> value, first add the C<-u> extension attribute to the string. Next, add the C<-kn> extension attribute to indicate that you are adding a value for C<numeric>. Finally, add the C<numeric> value to the string. If you want to set C<numeric> to true, adding the L<kn|Locale::Unicode/kn> attribute will suffice. To set the value to false, you must specify in by adding "false" after the L<kn|Locale::Unicode/kn> attribute.

    my $locale = Locale::Intl->new("fr-Latn-FR-u-kn-false");
    say $locale->numeric); # false

Setting the numeric value via the configuration object argument.

The L<Locale::Unicode> constructor has an optional hash or hash reference of options, which can be used to pass extension types. Set the C<numeric> property of the hash or hash reference of options to your desired C<numeric> value and pass it into the constructor.

    my $locale = Locale::Intl->new("en-Latn-US", { numeric => $true_value });
    say $locale->numeric; # true

=head2 region

The C<region> accessor property of L<Locale::Intl> instances returns the C<region> of the world (usually a country) associated with this C<locale>. This could be a L<country code|Locale::Unicode/country_code>, or a world region represented with a L<3-digits code|Locale::Unicode/region>

The C<region> is an essential part of the L<locale identifier|Locale::Unicode>, as it places the C<locale> in a specific area of the world. Knowing the C<locale>'s region is vital to identifying differences between locales. For example, English is spoken in the United Kingdom and the United States of America, but there are differences in spelling and other C<language> conventions between those two countries.

For example:

Setting the region in the locale identifier string argument.

The C<region> is the third part of a valid L<Unicode language identifier|Locale::Unicode> string, and can be set by adding it to the L<locale identifier|Locale::Unicode> string that is passed into the L<Locale::Intl> constructor.

    my $locale = Locale::Intl->new( "en-Latn-US" );
    say $locale->region; # US

    my $locale = Locale::Intl->new( "fr-Latn-150" );
    say $locale->region; # 150
    # 150 is the region code for Europe

See the file C<territories.json> in the L<CLDR repository|https://github.com/unicode-org/cldr-json/tree/main/cldr-json/cldr-localenames-full> for the localised names of those territories.

=head2 script

The C<script> accessor property of L<Locale::Intl> instances returns the C<script> used for writing the particular C<language> used in this C<locale>.

A C<script>, sometimes called writing system, is one of the core attributes of a L<locale|Locale::Unicode>. It indicates the set of symbols, or glyphs, that are used to write a particular C<language>. For instance, the C<script> associated with English is Latin (C<latn>), whereas the C<script> used to represent Japanese Katanaka is C<Kana> and the one typically associated with Korean is Hangul (C<Hang>). In many cases, denoting a C<script> is not strictly necessary, since the language (which is necessary) is only written in a single C<script>. There are exceptions to this rule, however, and it is important to indicate the C<script> whenever possible, in order to have a complete L<Unicode language identifier|Locale::Unicode>.

For example:

Setting the script in the locale identifier string argument.

The C<script> is the second part of a valid L<Unicode language identifier|Locale::Unicode> string, and can be set by adding it to the L<locale identifier|Locale::Unicode> string that is passed into the L<Locale::Intl> constructor. Note that the C<script> is not a required part of a L<locale identifier|Locale::Unicode>.

    my $locale = Locale::Intl->new( "en-Latn-US" );
    say $locale->script); # Latn

Setting the C<script> via the hash or hash reference of options.

The L<Locale::Intl> constructor takes an hash or hash reference of options, which can be used to set the C<script> subtag and property.

    my $locale = Locale::Intl->new("fr-FR", { script => "Latn" });
    say $locale; # fr-Latn-FR
    say $locale->script; # Latn

=head1 OVERLOADING

Instances of L<Locale::Intl> have the stringification overloaded as inherited from L<Locale::Unicode>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<DateTime::Format::Intl>

=head1 CREDITS

Credits to Mozilla for L<parts of their documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Locale> I copied here.

=head1 COPYRIGHT & LICENSE

Copyright(c) 2024 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
