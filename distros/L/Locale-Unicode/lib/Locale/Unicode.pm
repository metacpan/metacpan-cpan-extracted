##----------------------------------------------------------------------------
## Unicode Locale Identifier - ~/lib/Locale/Unicode.pm
## Version v0.1.8
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2024/05/11
## Modified 2024/06/12
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Locale::Unicode;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use vars qw(
        $ERROR $VERSION $DEBUG
        $LOCALE_BCP47_RE $LOCALE_BCP47_NAMELESS_RE $LOCALE_RE $LOCALE_UNICODE_SUBTAG_RE
        $LOCALE_EXTENSIONS_RE $LOCALE_TRANSFORM_PARAMETERS_RE
        $TZ_DICT $TZ_NAME2ID
        $PROP_TO_SUB
        $EXPLICIT_BOOLEAN
    );
    use overload (
        '""'    => 'as_string',
        bool    => sub{ $_[0] },
        fallback => 1,
    );
    use Scalar::Util ();
    use Want;
    our $LOCALE_BCP47_RE = qr/
    (?:
        (?:
            (?<locale>[a-z]{2})
            |
            (?<locale3>[a-z]{3})
        )
        # "Up to three optional extended language subtags composed of three letters each, separated by hyphens"
        # "There is currently no extended language subtag registered in the Language Subtag Registry without an equivalent and preferred primary language subtag"
        (?<extended>[a-z]{3}){0,3}
    )
    # ISO 15924 for scripts
    (?:
        -
        (?:
            (?<script>[A-Z][a-z]{3})
            |
            (?<script>[a-z]{4})
        )
    )?
    (?:
        (?:
            -
            (?:
                (?<country_code>[A-Z]{2})
                |
                # BCP47, section 2.2.4.4: the UN Standard Country or Area Codes for Statistical Use
                (?<region>\d{3})
            )
        )?
        # "Optional variant subtags, separated by hyphens, each composed of five to eight letters, or of four characters starting with a digit"
        # ca-ES-valencia
        # country code can be skipped if the variant is limited to a country
        # be-tarask
        (?:
            -
            (?<variant>
                (?:[[:alpha:]]{5,8})
                |
                (?:\d[[:alpha:]]{3})
            )
        )?
    )?
    /xi;
    # We need the same regular express as $LOCALE_BCP47_RE, but without named capturing group
    # so it does not interfere with matches from $LOCALE_BCP47_RE
    our $LOCALE_BCP47_NAMELESS_RE = qr/
    (?:
        (?:
            (?:[a-z]{2})
            |
            (?:[a-z]{3})
        )
        # "Up to three optional extended language subtags composed of three letters each, separated by hyphens"
        # "There is currently no extended language subtag registered in the Language Subtag Registry without an equivalent and preferred primary language subtag"
        (?:[a-z]{3}){0,3}
    )
    # ISO 15924 for scripts
    (?:
        -
        (?:
            (?:[A-Z][a-z]{3})
            |
            (?:[a-z]{4})
        )
    )?
    (?:
        (?:
            -
            (?:
                (?:[A-Z]{2})
                |
                # BCP47, section 2.2.4.4: the UN Standard Country or Area Codes for Statistical Use
                (?:\d{3})
            )
        )?
        # "Optional variant subtags, separated by hyphens, each composed of five to eight letters, or of four characters starting with a digit"
        # ca-ES-valencia
        # country code can be skipped if the variant is limited to a country
        # be-tarask
        (?:
            -
            (?:
                (?:[[:alpha:]]{5,8})
                |
                (?:\d[[:alpha:]]{3})
            )
        )?
    )?
    /xi;
    our $LOCALE_UNICODE_SUBTAG_RE = qr/
    (?<ext_unicode_subtag>
        (?:
            (?<ext_calendar>ca)
            |
            (?<ext_currency_format>cf)
            |
            (?<ext_collation>co)
            |
            (?<ext_currency>cu)
            |
            (?<ext_dict_break_exclusion>dx)
            |
            (?<ext_emoji>em)
            |
            (?<ext_first_day>fw)
            |
            (?<ext_hour_cycle>hc)
            |
            (?<ext_line_break>lb)
            |
            (?<ext_line_break_word>lw)
            |
            (?<ext_measurement>ms)
            |
            (?<ext_unit>mu)
            |
            (?<ext_number>nu)
            |
            (?<ext_region_override>rg)
            |
            (?<ext_subdivision>sd)
            |
            (?<ext_sentence_break_suppression>ss)
            |
            (?<ext_time_zone>tz)
            |
            (?<ext_variant>va)
            |
            (?<ext_unicode_unknown>
                [a-zA-Z0-9]{2,8}
            )
        )
        (?<ext_unicode_values>
            (?:\-
                # Collation or Transformation subtags, eventhough the latter should not be here
                (?!(?:ka|kb|kc|kf|kh|kk|kn|kr|ks|kv|vt|d0|h0|i0|k0|m0|s0|t0|x0|[a]0)[^[:alnum:]])
                [a-zA-Z0-9]{2,8}
            )*
        )
    )
    (?:
        \-
        (?:
            # Should not be here, but could be malformed
            (?<transform_options>
                (?:d0|h0|i0|k0|m0|s0|t0|x0|[a]0)
                (?:\-[a-zA-Z0-9]{2,8})*
            )
            |
            (?<collation_options>
                (?:ka|kb|kc|kf|kh|kk|kn|kr|ks|kv|vt)
                (?:\-[a-zA-Z0-9]{2,8})*
            )
        )
    )?
    /xi;
    our $LOCALE_TRANSFORM_PARAMETERS_RE = qr/(?:d0|h0|i0|k0|m0|s0|t0|x0|[a]0)/i;
    our $LOCALE_TRANSFORM_SUBTAG_RE = qr/
    (?<ext_transform_locale>
        $LOCALE_BCP47_NAMELESS_RE
    )
    (?:
        \-
        (?<ext_transform_subtag>
            (?:
                (?<ext_destination>d0)
                |
                (?<ext_hybrid>h0)
                |
                (?<ext_input>i0)
                |
                (?<ext_keyboard>k0)
                |
                (?<ext_mechanism>m0)
                |
                (?<ext_source>s0)
                |
                (?<ext_translation>t0)
                |
                (?<ext_private_transform>x0)
                |
                (?<ext_transform_unknown>
                    [a-zA-Z0-9]{2,8}
                )
            )
            (?<ext_transform_values>
                (?:\-
                    # Transformation or Unicode collation subtags, eventhough the latter should not be here
                    (?!(?:ka|kb|kc|kf|kh|kk|kn|kr|ks|kv|vt|d0|h0|i0|k0|m0|s0|t0|x0|[a]0)[^[:alnum:]])
                    [a-zA-Z0-9]{2,8}
                )*
            )
        )
    )?
    (?:
        \-
        (?:
            (?<transform_options>
                (?:d0|h0|i0|k0|m0|s0|t0|x0|[a]0)
                (?:\-[a-zA-Z0-9]{2,8})*
            )
            |
            # Should not be here, but could be malformed
            (?<collation_options>
                (?:ka|kb|kc|kf|kh|kk|kn|kr|ks|kv|vt)
                (?:\-[a-zA-Z0-9]{2,8})*
            )
        )
    )?
    /xi;
    our $LOCALE_EXTENSIONS_RE = qr/
    (?:
        (?<ext_transform>
            t
            \-
            $LOCALE_TRANSFORM_SUBTAG_RE
        )
        |
        (?<ext_unicode>
            u
            \-
            $LOCALE_UNICODE_SUBTAG_RE
        )
        |
        (?<extension>
            (?<singleton>[a-wy-z])
            \-
            (?<subtag>
                [a-zA-Z0-9]{2,8}
                (?:\-[a-zA-Z0-9]{2,8})*
            )
        )
    )
    /xi;
    # Possible IETF BCP 47 language tags:
    # fr
    # fre
    # fr-Bret
    # fr-FR
    # fr-Bret-FR
    # See: <https://en.wikipedia.org/wiki/IETF_language_tag#Syntax_of_language_tags>
    #      <https://en.wikipedia.org/wiki/ISO_15924>
    our $LOCALE_RE = qr/
    (?<locale_bcp47>
        $LOCALE_BCP47_RE
    )
    # BCP47, section 2.2.6:
    # "Optional extension subtags, separated by hyphens, each composed of a single character, with the exception of the letter x, and a hyphen followed by one or more subtags of two to eight characters each, separated by hyphens"
    (?:
        \-
        (?<locale_extensions>
            $LOCALE_EXTENSIONS_RE
            (?:
                \-
                $LOCALE_EXTENSIONS_RE
            )*
        )?
        # "An optional private-use subtag, composed of the letter x and a hyphen followed by subtags of one to eight characters each, separated by hyphens"
        (?:
            \-
            (?<private_extension>
                x
                \-
                (?<private_subtag>
                    [a-zA-Z0-9]{1,8}
                    (?:\-[a-zA-Z0-9]{1,8})*
                )
            )
        )*
    )?
    /xi;
    our $PROP_TO_SUB = {};
    # False, by default
    our $EXPLICIT_BOOLEAN = 0;
    our $VERSION = 'v0.1.8';
};

use strict;
use warnings;

sub new
{
    my $this = shift( @_ );
    my $self = bless( {} => ( ref( $this ) || $this ) );
    my $locale = shift( @_ ) ||
        return( $self->error( "No locale was provided." ) );
    # u-dx
    $self->{break_exclusion}    = undef;
    # u-ca
    $self->{calendar}           = undef;
    # u-co
    $self->{collation}          = undef;
    # ISO3166 2-letters country code
    $self->{country_code}       = undef;
    # u-cf
    $self->{cu_format}          = undef;
    # u-cu
    $self->{currency}           = undef;
    # t-d0
    $self->{destination}        = undef;
    # u-em
    $self->{emoji}              = undef;
    # u-fw
    $self->{first_day}          = undef;
    # u-hc
    $self->{hour_cycle}         = undef;
    # t-h0
    $self->{hybrid}             = undef;
    # t-i0
    $self->{input}              = undef;
    # u-lb
    $self->{line_break}         = undef;
    # u-lw
    $self->{line_break_word}    = undef;
    # u-ms
    $self->{measurement}        = undef;
    # u-nu
    $self->{number}             = undef;
    # u-mu
    $self->{unit}               = undef;
    $self->{locale}             = undef;
    $self->{locale3}            = undef;
    # t-m0
    $self->{mechanism}          = undef;
    # x-something
    $self->{private}            = undef;
    $self->{region}             = undef;
    # u-rg
    $self->{region_override}    = undef;
    # t-s0
    $self->{source}             = undef;
    $self->{script}             = undef;
    # t-t0
    $self->{translation}        = undef;
    # u-sd
    $self->{subdivision}        = undef;
    # t-x
    $self->{t_private}          = undef;
    # u-tz
    $self->{time_zone}          = undef;
    # u-va
    $self->{variant}            = undef;
    # A simple dictionary that stores the preferred boolean representation for each attribute
    # i.e. yes or true, no or false
    # literal or logic
    $self->{_bool_types} = {};
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

    # If the locale provided contains any subtags, parse it
    if( index( $locale, '-' ) != -1 ||
        index( $locale, '_' ) != -1 )
    {
        $locale =~ tr/_/-/;
        my $ref = $self->parse( $locale ) ||
            return( $self->pass_error );
        $self->apply( $ref ) || return( $self->pass_error );
    }
    else
    {
        $self->{locale} = $locale;
    }

    # Then, if the user provided with an hash or hash reference of options, we apply them
    for( my $i = 0; $i < scalar( @args ); $i++ )
    {
        my $name = $args[ $i ];
        my $val  = $args[ ++$i ];
        my $meth = $self->can( $name );
        if( !defined( $meth ) )
        {
            return( $self->error( "Unknown method \"${meth}\" provided for locale \"${locale}\"." ) );
        }
        elsif( !defined( $meth->( $self, $val ) ) )
        {
            if( defined( $val ) && $self->error )
            {
                return( $self->pass_error );
            }
        }
    }
    return( $self );
}

sub apply
{
    my $self = shift( @_ );
    my $hash = $self->_get_args_as_hash( @_ );
    return( $self ) if( !scalar( keys( %$hash ) ) );
    foreach my $prop ( keys( %$hash ) )
    {
        next if( $prop eq 'transform_ext' || $prop eq 'unicode_ext' );
        my $code;
        unless( $code = $PROP_TO_SUB->{ $prop } )
        {
            $code = $self->can( $prop );
            if( !$code )
            {
                warn( "No method \"${prop}\" supported in ", ( ref( $self ) || $self ) ) if( warnings::enabled() );
                next;
            }
            $PROP_TO_SUB->{ $prop } = $code;
        }
        $code->( $self, $hash->{ $prop } );
    }
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    return( $self->{_cache_value} ) if( $self->{_cache_value} && !CORE::length( $self->{_reset} ) );
    my $unicodes =
    {
    ca  => 'calendar',
    cf  => 'cu_format',
    co  => 'collation',
    cu  => 'currency',
    dx  => 'break_exclusion',
    em  => 'emoji',
    fw  => 'first_day',
    hc  => 'hour_cycle',
    lb  => 'line_break',
    lw  => 'line_break_word',
    ms  => 'measurement',
    mu  => 'unit',
    nu  => 'number',
    rg  => 'region_override',
    sd  => 'subdivision',
    ss  => 'sentence_break',
    tz  => 'time_zone',
    va  => 'variant',
    };
    my $collation =
    {
    ka  => 'colAlternate',
    kb  => { type => 'boolean', method => 'colBackwards' },
    kc  => { type => 'boolean', method => 'colCaseLevel' },
    kf  => 'colCaseFirst',
    kh  => { type => 'boolean', method => 'colHiraganaQuaternary' },
    kk  => { type => 'boolean', method => 'colNormalization' },
    kn  => { type => 'boolean', method => 'colNumeric' },
    kr  => 'colReorder',
    ks  => 'colStrength',
    kv  => 'colValue',
    vt  => 'colVariableTop',
    };
    my $transform =
    {
    d0  => 'destination',
    h0  => 'hybrid',
    i0  => 'input',
    k0  => 'keyboard',
    m0  => 'mechanism',
    s0  => 'source',
    t0  => 'translation',
    x0  => 't_private',
    };
    my $others =
    {
    x_  => 'private',
    };
    my $map =
    [
        unicode => { prefix => 'u', data => $unicodes },
        # und-u-ka-noignore
        collation => { prefix => 'u', data => $collation },
        transform => { prefix => 't', data => $transform },
    ];
    my $result = {};
    for( my $i = 0; $i < scalar( @$map ); $i += 2 )
    {
        my $type = $map->[$i];
        my $dict = $map->[$i + 1];
        my $prefix = $dict->{prefix};
        my $ref  = $dict->{data};
        foreach my $tag ( sort( keys( %$ref ) ) )
        {
            my $meth;
            my $def = {};
            if( ref( $ref->{ $tag } ) eq 'HASH' )
            {
                $def = $ref->{ $tag };
                $meth = $def->{method};
            }
            else
            {
                $meth = $ref->{ $tag };
            }
            my $code;
            unless( $code = $PROP_TO_SUB->{ $tag } )
            {
                $code = $self->can( $meth ) || die( "Unknown method '${meth}' for ${type} subtag '${tag}'" );
                $PROP_TO_SUB->{ $tag } = $code;
            }

            my $val = $code->( $self );
            next if( !defined( $val ) );
            $result->{ $prefix } = [] if( !exists( $result->{ $prefix } ) );
            if( exists( $def->{type} ) && $def->{type} eq 'boolean' )
            {
                # We are explicit about the true value, but it could be ignored and be implicit.
                # push( @{$result->{ $prefix }}, join( '-', $tag, ( $val ? 'true' : 'false' ) ) );
                push( @{$result->{ $prefix }}, ( $EXPLICIT_BOOLEAN ? join( '-', $tag, ( $val ? 'true' : 'false' ) ) : ( $val ? $tag : join( '-', $tag, 'false' ) ) ) );
            }
            else
            {
                push( @{$result->{ $prefix }}, join( '-', $tag, $val ) );
            }
        }
    }
    my @parts = ();

    push( @parts, $self->core );

    if( my $transform_locale = $self->transform_locale )
    {
        unshift( @{$result->{t}}, $transform_locale );
    }
    # There is no transformation locale and yet the user has set some transformation subtags.
    # We warn the user about it.
    elsif( exists( $result->{t} ) &&
           ref( $result->{t} ) eq 'ARRAY' &&
           scalar( @{$result->{t}} ) )
    {
        warn( "You are attempting at setting ", scalar( @{$result->{t}} ), " transform subtags without declaring a transformation locale." ) if( warnings::enabled() );
    }

    foreach my $pref ( qw( u t ) )
    {
        if( exists( $result->{ $pref } ) )
        {
            push( @parts, join( '-', $pref, join( '-', @{$result->{ $pref }} ) ) );
        }
    }
    if( my $private = $self->private )
    {
        push( @parts, "x-${private}" );
    }
    my $rv = join( '-', @parts );
    $self->{_cache_value} = $rv;
    CORE::delete( $self->{_reset} );
    return( $rv );
}

# u-dx
sub break_exclusion { return( shift->reset(@_)->_set_get_prop( 'break_exclusion', @_ ) ); }

# u-ca
sub ca { return( shift->calendar( @_ ) ); }

sub calendar { return( shift->reset(@_)->_set_get_prop( 'calendar', @_ ) ); }

# u-cf
sub cf { return( shift->cu_format( @_ ) ); }

sub clone
{
    my $self = shift( @_ );
    my $new = $self->new( "$self" ) || return( $self->pass_error );
    return( $new );
}

# u-co
sub co { return( shift->collation( @_ ) ); }

# u-ka
sub colAlternate { return( shift->reset(@_)->_set_get_prop({
    field => 'col_alternate',
    regexp => qr/[[:alnum:]][[:alnum:]\-]+/,
}, @_ ) ); }

# u-kb
sub colBackwards { return( shift->reset(@_)->_set_get_prop({
    field => 'col_backwards',
    type => 'boolean',
}, @_ ) ); }

# u-kc
sub colCaseLevel { return( shift->reset(@_)->_set_get_prop({
    field => 'col_case_level',
    type => 'boolean',
}, @_ ) ); }

# u-kf
sub colCaseFirst { return( shift->reset(@_)->_set_get_prop({
    field => 'col_case_first',
    # lower, upper, undef
    regexp => qr/[[:alnum:]]+/,
}, @_ ) ); }

# u-co
sub collation { return( shift->reset(@_)->_set_get_prop({
    field => 'collation',
    regexp => qr/[[:alnum:]]+/,
}, @_ ) ); }

# u-kh
sub colHiraganaQuaternary { return( shift->reset(@_)->_set_get_prop({
    field => 'col_hiragana_quaternary',
    type => 'boolean',
}, @_ ) ); }

sub colNormalisation { return( shift->colNormalization( @_ ) ); }

# u-kk
sub colNormalization { return( shift->reset(@_)->_set_get_prop({
    field => 'col_normalisation',
    type => 'boolean',
}, @_ ) ); }

# u-kn
sub colNumeric { return( shift->reset(@_)->_set_get_prop({
    field => 'col_numeric',
    type => 'boolean',
}, @_ ) ); }

# u-kr
sub colReorder { return( shift->reset(@_)->_set_get_prop({
    field => 'col_reorder',
    regexp => qr/[[:alnum:]][[:alnum:]\-]+/,
}, @_ ) ); }

# u-ks
sub colStrength { return( shift->reset(@_)->_set_get_prop({
    field => 'col_strength',
    regexp => qr/[[:alnum:]][[:alnum:]\-]+/,
}, @_ ) ); }

# u-kv
sub colValue { return( shift->reset(@_)->_set_get_prop({
    field => 'col_value',
    regexp => qr/[[:alnum:]]+/,
}, @_ ) ); }

# u-vt
sub colVariableTop { return( shift->reset(@_)->_set_get_prop({
    field => 'col_variable_top',
    regexp => qr/[[:alnum:]]+/,
}, @_ ) ); }

sub core
{
    my $self = shift( @_ );
    my @locale_parts = ();
    if( my $locale = $self->locale )
    {
        push( @locale_parts, $locale );
    }
    elsif( my $locale3 = $self->locale3 )
    {
        push( @locale_parts, $locale3 );
    }
    # 'und' for 'undefined'
    else
    {
        push( @locale_parts, 'und' );
    }
    if( my $script = $self->script )
    {
        push( @locale_parts, $script );
    }
    if( my $cc = $self->country_code )
    {
        push( @locale_parts, $cc );
    }
    elsif( my $region = $self->region )
    {
        push( @locale_parts, $region );
    }
    if( my $variant = $self->variant )
    {
        push( @locale_parts, $variant );
    }
    return( join( '-', @locale_parts ) );
}

sub country_code { return( shift->reset(@_)->_set_get_prop( 'country_code', @_ ) ); }

# u-cf
sub cu_format { return( shift->reset(@_)->_set_get_prop( 'cu_format', @_ ) ); }

# u-cu
sub cu { return( shift->reset(@_)->_set_get_prop( 'currency', @_ ) ); }

# u-cu
sub currency { return( shift->reset(@_)->_set_get_prop( 'currency', @_ ) ); }

# t-d0
sub d0 { return( shift->reset(@_)->_set_get_prop( 'destination', @_ ) ); }

# t-d0
sub dest { return( shift->reset(@_)->_set_get_prop( 'destination', @_ ) ); }

# t-d0
sub destination { return( shift->reset(@_)->_set_get_prop( 'destination', @_ ) ); }

# u-dx
sub dx { return( shift->reset(@_)->_set_get_prop( 'break_exclusion', @_ ) ); }

# u-em
sub em { return( shift->reset(@_)->_set_get_prop( 'emoji', @_ ) ); }

# u-em
sub emoji { return( shift->reset(@_)->_set_get_prop( 'emoji', @_ ) ); }

sub error
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $msg = join( '', map( ( ref( $_ ) eq 'CODE' ) ? $_->() : $_, @_ ) );
        $self->{error} = $ERROR = Locale::Unicode::Exception->new({
            skip_frames => 1,
            message => $msg,
        });
        warn( $msg ) if( warnings::enabled() );
        rreturn( Locale::Unicode::NullObject->new ) if( Want::want( 'OBJECT' ) );
        return;
    }
    return( ref( $self ) ? $self->{error} : $ERROR );
}

sub false { return( $Locale::Unicode::Boolean::false ); }

# u-fw
sub first_day { return( shift->reset(@_)->_set_get_prop( 'first_day', @_ ) ); }

# u-fw
sub fw { return( shift->reset(@_)->_set_get_prop( 'first_day', @_ ) ); }

# t-h0
sub h0 { return( shift->reset(@_)->_set_get_prop( 'hybrid', @_ ) ); }

# u-hc
sub hc { return( shift->reset(@_)->_set_get_prop( 'hour_cycle', @_ ) ); }

# u-hc
sub hour_cycle { return( shift->reset(@_)->_set_get_prop( 'hour_cycle', @_ ) ); }

# t-h0
sub hybrid { return( shift->reset(@_)->_set_get_prop( 'hybrid', @_ ) ); }

# t-i0
sub i0 { return( shift->reset(@_)->_set_get_prop( 'input', @_ ) ); }

# t-i0
sub input { return( shift->reset(@_)->_set_get_prop( 'input', @_ ) ); }

# t-k0
sub k0 { return( shift->reset(@_)->_set_get_prop( 'keyboard', @_ ) ); }

# u-ka
sub ka { return( shift->colAlternate( @_ ) ); }

# u-kb
sub kb { return( shift->colBackwards( @_ ) ); }

# u-kc
sub kc { return( shift->colCaseLevel( @_ ) ); }

# t-k0
sub keyboard { return( shift->reset(@_)->_set_get_prop( 'keyboard', @_ ) ); }

# u-kf
sub kf { return( shift->colCaseFirst( @_ ) ); }

# u-kh
sub kh { return( shift->colHiraganaQuaternary( @_ ) ); }

# u-kk
sub kk { return( shift->colNormalization( @_ ) ); }

# u-kn
sub kn { return( shift->colNumeric( @_ ) ); }

# u-kr
sub kr { return( shift->colReorder( @_ ) ); }

# u-ks
sub ks { return( shift->colStrength( @_ ) ); }

# u-kv
sub kv { return( shift->colValue( @_ ) ); }

sub lang { return( shift->reset(@_)->_set_get_prop( 'locale', @_ ) ); }

sub language { return( shift->lang( @_ ) ); }

# u-lb
sub lb { return( shift->reset(@_)->_set_get_prop( 'line_break', @_ ) ); }

# u-lb
sub line_break { return( shift->reset(@_)->_set_get_prop( 'line_break', @_ ) ); }

# u-lw
sub line_break_word { return( shift->reset(@_)->_set_get_prop( 'line_break_word', @_ ) ); }

sub locale { return( shift->reset(@_)->_set_get_prop( 'locale', @_ ) ); }

sub locale3 { return( shift->reset(@_)->_set_get_prop( 'locale3', @_ ) ); }

# u-lw
sub lw { return( shift->reset(@_)->_set_get_prop( 'line_break_word', @_ ) ); }

# t-m0
sub m0 { return( shift->mechanism( @_ ) ); }

sub matches
{
    my $self = shift( @_ );
    my $lang = shift( @_ ) || return( $self->error( "No language was provided." ) );
    # Required by RFC for parsing
    $lang =~ tr/_/-/;
    # Special language 'root' becomes 'und' for 'undefined'
    if( substr( lc( $lang ), 0, 5 ) eq 'root-' )
    {
        substr( $lang, 0, 4, 'und' );
    }
    if( $lang =~ /^$LOCALE_RE$/ )
    {
        my $re = {%+};
        return( $re );
    }
    # Returns false with empty string, but not undef. Undef is reserved for errors
    return( wantarray() ? () : '' );
}

# u-ms
sub measurement { return( shift->reset(@_)->_set_get_prop( 'measurement', @_ ) ); }

# t-m0
sub mechanism { return( shift->reset(@_)->_set_get_prop( 'mechanism', @_ ) ); }

# u-ms
sub ms { return( shift->measurement( @_ ) ); }

# u-mu
sub mu { return( shift->unit( @_ ) ); }

# u-nu
sub nu { return( shift->number( @_ ) ); }

# u-nu
sub number { return( shift->reset(@_)->_set_get_prop( 'number', @_ ) ); }

sub parse
{
    my $self = shift( @_ );
    my $this = shift( @_ ) || return( $self->error( "No language string was provided." ) );
    my $opts = $self->_get_args_as_hash( @_ );

    my $re = $self->matches( $this );
    return( $self->pass_error ) if( !defined( $opts ) );

    my $info = {};
    foreach my $prop ( qw( locale locale3 extended script country_code region variant ) )
    {
        # the property provided as an option can be undef by design to remove the value
        if( exists( $opts->{ $prop } ) )
        {
            $info->{ $prop } = $opts->{ $prop };
        }
        elsif( exists( $re->{ $prop } ) &&
            defined( $re->{ $prop } ) &&
            length( $re->{ $prop } ) )
        {
            $info->{ $prop } = $re->{ $prop };
        }
    }

    if( exists( $re->{locale_bcp47} ) &&
        defined( $re->{locale_bcp47} ) &&
        length( $re->{locale_bcp47} ) )
    {
        my $offset = length( $re->{locale_bcp47} );
        $offset++ if( substr( $this, $offset, 1 ) eq '-' );
        substr( $this, 0, $offset, '' );
    }

    if( ( exists( $re->{ext_transform} ) &&
          defined( $re->{ext_transform} ) &&
          length( $re->{ext_transform} ) ) ||
        ( exists( $re->{transform_options} ) &&
          defined( $re->{transform_options} ) &&
          length( $re->{transform_options} ) ) )
    {
        my $t;
        if( exists( $re->{ext_transform} ) &&
            defined( $re->{ext_transform} ) )
        {
            my $t_locale = $self->new( $re->{ext_transform_locale} ) ||
                return( $self->pass_error );
            $info->{transform_locale} = $t_locale;
            $t = $re->{ext_transform};
            my $offset = length( "t-${t_locale}" );
            if( length( $re->{ext_transform} ) > $offset &&
                substr( $re->{ext_transform}, $offset, 1 ) eq '-' )
            {
                $offset++;
            }
            substr( $t, 0, $offset, '' );
        }
        elsif( exists( $re->{transform_options} ) &&
               defined( $re->{transform_options} ) )
        {
            $t = $re->{transform_options};
        }
        $info->{transform_ext} = [];
        my @parts = split( /\-?($LOCALE_TRANSFORM_PARAMETERS_RE)\-/, $t );
        # First array element is undef, because it is the beginning of the string.
        shift( @parts );
        for( my $i = 0; $i < scalar( @parts ); $i += 2 )
        {
            my $n = $parts[$i];
            my $v = $parts[$i + 1];
            if( exists( $info->{ $n } ) )
            {
                warn( "The Transform extension \"${n}\" was previously defined with \"", ( $info->{ $n } // 'undef' ), "\", overwriting it with \"", ( $v // 'undef' ), "\"" ) if( warnings::enabled() );
            }
            elsif( !$self->can( $n ) )
            {
                warn( "The Transform extension specified \"${n}\" is unsupported." ) if( warnings::enabled() );
            }
            $info->{ $n } = $v;
            push( @{$info->{transform_ext}}, $n );
        }
    }

    if( ( exists( $re->{ext_unicode} ) &&
          defined( $re->{ext_unicode} ) &&
          length( $re->{ext_unicode} ) ) ||
        ( exists( $re->{collation_options} ) &&
          defined( $re->{collation_options} ) &&
          length( $re->{collation_options} ) ) )
    {
        $info->{unicode_ext} = [];
        # ca, co, cf, cu, etc... or collation options such as: ka, kb, kc, etc.
        # my @parts = split( /\-([a-z]{2})\-/, '-' . ( $re->{ext_unicode_subtag} // $re->{collation_options} ) );
        substr( $re->{ext_unicode}, 0, 1, '' ) if( substr( $re->{ext_unicode}, 0, 2 ) eq 'u-' );
        my @parts = split( /\-([a-z]{2})\-/, ( $re->{ext_unicode} // ( '-' . $re->{collation_options} ) ) );
        shift( @parts );
        for( my $i = 0; $i < scalar( @parts ); $i += 2 )
        {
            my $n = $parts[$i];
            my $v = $parts[$i + 1];
            if( exists( $info->{ $n } ) )
            {
                warn( "The Unicode extension \"${n}\" was previously defined with \"", ( $info->{ $n } // 'undef' ), "\", overwriting it with \"", ( $v // 'undef' ), "\"" ) if( warnings::enabled() );
            }
            elsif( !$self->can( $n ) )
            {
                warn( "The Unicode extension specified \"${n}\" is unsupported." ) if( warnings::enabled() );
            }
            $info->{ $n } = $v;
            push( @{$info->{unicode_ext}}, $n );
        }
    }

    if( exists( $re->{extension} ) &&
        defined( $re->{extension} ) &&
        length( $re->{extension} ) )
    {
        my $tag = $re->{singleton};
        $info->{singleton} = 
        {
            $tag => {},
        };
        $info->{singleton}->{ $tag }->{subtags} = [];
        my @parts = split( /\-([a-zA-Z0-9]{2,8})\-/, $re->{subtag} );
        for( my $i = 0; $i < scalar( @parts ); $i += 2 )
        {
            my $n = $parts[$i];
            my $v = $parts[$i + 1];
            $info->{singleton}->{ $tag }->{ $n } = $v;
            push( @{$info->{singleton}->{ $tag }->{subtags}}, $n );
        }
    }

    if( exists( $re->{private_extension} ) &&
        defined( $re->{private_extension} ) &&
        length( $re->{private_extension} ) )
    {
        $info->{private} = $re->{private_subtag};
    }
    return( $info );
}

sub pass_error
{
    my $self = shift( @_ );
    if( Want::want( 'OBJECT' ) )
    {
        rreturn( Locale::Unicode::NullObject->new );
    }
    return;
}

# x-something
sub private { return( shift->reset(@_)->_set_get_prop( 'private', @_ ) ); }

sub region { return( shift->reset(@_)->_set_get_prop( 'region', @_ ) ); }

# u-rg
sub region_override { return( shift->reset(@_)->_set_get_prop( 'region_override', @_ ) ); }

# u-rg
sub rg { return( shift->region_override( @_ ) ); }

sub reset
{
    my $self = shift( @_ );
    if( !CORE::length( $self->{_reset} ) && scalar( @_ ) )
    {
        $self->{_reset} = scalar( @_ );
    }
    return( $self );
}

# t-s0
sub s0 { return( shift->source( @_ ) ); }

sub script { return( shift->reset(@_)->_set_get_prop( 'script', @_ ) ); }

# u-ss
sub sentence_break { return( shift->reset(@_)->_set_get_prop( 'sentence_break', @_ ) ); }

# u-kv
sub shiftedGroup { return( shift->colValue( @_ ) ); }

# t-s0
sub source { return( shift->reset(@_)->_set_get_prop( 'source', @_ ) ); }

# u-sd
sub sd { return( shift->subdivision( @_ ) ); }

# u-ss
sub ss { return( shift->sentence_break( @_ ) ); }

# u-sd
sub subdivision { return( shift->reset(@_)->_set_get_prop( 'subdivision', @_ ) ); }

# t-t0
sub t0 { return( shift->translation( @_ ) ); }

# t-x0
sub t_private { return( shift->reset(@_)->_set_get_prop( 't_private', @_ ) ); }

# u-tz
sub time_zone { return( shift->reset(@_)->_set_get_prop( 'time_zone', @_ ) ); }

# u-tz
sub timezone { return( shift->reset(@_)->_set_get_prop( 'time_zone', @_ ) ); }

sub transform
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        if( defined( $val ) )
        {
            unless( Scalar::Util::blessed( $val ) && 
                    $val->isa( ref( $self ) || $self ) )
            {
                my $locale = $self->new( $val ) || return( $self->pass_error );
                my $core = $locale->core;
                $locale = $self->new( $core ) unless( $core eq $locale );
                $val = $locale;
            }
        }
        $self->transform_locale( $val );
    }
    return( $self );
}

# t-und-Latn
sub transform_locale { return( shift->reset(@_)->_set_get_prop({
    field => 'transform_locale',
    isa => 'Locale::Unicode',
}, @_ ) ); }

# t-t0
sub translation { return( shift->reset(@_)->_set_get_prop( 'translation', @_ ) ); }

sub true { return( $Locale::Unicode::Boolean::true ); }

# u-tz
sub tz { return( shift->time_zone( @_ ) ); }

# Returns an Olson IANA time zone name as a string for a given CLDR timezone ID
sub tz_id2name
{
    my $self = shift( @_ );
    my $id = shift( @_ ) || return( $self->error( "No CLDR timezone ID was provided." ) );
    my $def = $self->tz_info( $id ) || return( '' );
    if( !defined( $def->{tz} ) ||
        !length( $def->{tz} // '' ) )
    {
        return( $self->error( "No property 'tz' could be found in our database for CLDR timezone ID '$id'. It seems our database is corrupted." ) );
    }
    return( $def->{tz} );
}

# Returns an array object of Olson IANA time zones for a given CLDR timezone ID
sub tz_id2names
{
    my $self = shift( @_ );
    my $id = shift( @_ ) || return( $self->error( "No CLDR timezone ID was provided." ) );
    my $a = [];
    my $def = $self->tz_info( $id );
    if( !defined( $def ) )
    {
        return( $self->pass_error );
    }
    elsif( !$def )
    {
        return( $a );
    }
    push( @$a, @{$def->{alias}} ) if( exists( $def->{alias} ) && ( ref( $def->{alias} ) || '' ) eq 'ARRAY' );
    return( $a );
}

sub tz_info
{
    my $self = shift( @_ );
    my $id = shift( @_ ) || return( $self->error( "No CLDR timezone ID was provided." ) );
    $id = lc( $id );
    return( '' ) if( !exists( $TZ_DICT->{ $id } ) );
    my %ref = %{$TZ_DICT->{ $id }};
    return( \%ref );
}

# Returns a CLDR timezone ID for a given IANA Olson timezone name
sub tz_name2id
{
    my $self = shift( @_ );
    my $name = shift( @_ ) || return( $self->error( "No CLDR timezone ID was provided." ) );
    if( !exists( $TZ_NAME2ID->{ $name } ) ||
        !defined( $TZ_NAME2ID->{ $name } ) ||
        !length( $TZ_NAME2ID->{ $name } ) )
    {
        return( '' );
    }
    return( $TZ_NAME2ID->{ $name } );
}

# u-mu
sub unit { return( shift->reset(@_)->_set_get_prop( 'unit', @_ ) ); }

# u-va
sub va { return( shift->variant( @_ ) ); }

# u-va
sub variant { return( shift->reset(@_)->_set_get_prop( 'variant', @_ ) ); }

# u-vt
sub vt { return( shift->colVariableTop( @_ ) ); }

# t-x0
sub x0 { return( shift->t_private( @_ ) ); }

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

sub INIT
{
    # NOTE: $TZ_DICT
    $TZ_DICT =
    {
        adalv => { desc => "Andorra", tz => "Europe/Andorra" },
        aedxb => { desc => "Dubai, United Arab Emirates", tz => "Asia/Dubai" },
        afkbl => { desc => "Kabul, Afghanistan", tz => "Asia/Kabul" },
        aganu => { desc => "Antigua", tz => "America/Antigua" },
        aiaxa => { desc => "Anguilla", tz => "America/Anguilla" },
        altia => { desc => "Tirane, Albania", tz => "Europe/Tirane" },
        amevn => { desc => "Yerevan, Armenia", tz => "Asia/Yerevan" },
        ancur => { desc => "Cura\xE7ao", tz => "America/Curacao" },
        aolad => { desc => "Luanda, Angola", tz => "Africa/Luanda" },
        aqams => {
            deprecated => 1,
            desc => "Amundsen-Scott Station, South Pole",
            preferred => "nzakl",
        },
        aqcas => { desc => "Casey Station, Bailey Peninsula", tz => "Antarctica/Casey" },
        aqdav => { desc => "Davis Station, Vestfold Hills", tz => "Antarctica/Davis" },
        aqddu => {
            desc => "Dumont d'Urville Station, Terre Ad\xE9lie",
            tz => "Antarctica/DumontDUrville",
        },
        aqmaw => { desc => "Mawson Station, Holme Bay", tz => "Antarctica/Mawson" },
        aqmcm => { desc => "McMurdo Station, Ross Island", tz => "Antarctica/McMurdo" },
        aqplm => { desc => "Palmer Station, Anvers Island", tz => "Antarctica/Palmer" },
        aqrot => {
            desc => "Rothera Station, Adelaide Island",
            tz => "Antarctica/Rothera",
        },
        aqsyw => {
            desc => "Syowa Station, East Ongul Island",
            tz => "Antarctica/Syowa",
        },
        aqtrl => { desc => "Troll Station, Queen Maud Land", tz => "Antarctica/Troll" },
        aqvos => { desc => "Vostok Station, Lake Vostok", tz => "Antarctica/Vostok" },
        arbue => {
            alias => [qw( America/Buenos_Aires America/Argentina/Buenos_Aires )],
            desc => "Buenos Aires, Argentina",
            tz => "America/Argentina/Buenos_Aires",
        },
        arcor => {
            alias => [qw( America/Cordoba America/Argentina/Cordoba America/Rosario )],
            desc => "C\xF3rdoba, Argentina",
            tz => "America/Argentina/Cordoba",
        },
        arctc => {
            alias => [qw(
                America/Catamarca America/Argentina/Catamarca
                America/Argentina/ComodRivadavia
            )],
            desc => "Catamarca, Argentina",
            tz => "America/Argentina/Catamarca",
        },
        arirj => { desc => "La Rioja, Argentina", tz => "America/Argentina/La_Rioja" },
        arjuj => {
            alias => [qw( America/Jujuy America/Argentina/Jujuy )],
            desc => "Jujuy, Argentina",
            tz => "America/Argentina/Jujuy",
        },
        arluq => { desc => "San Luis, Argentina", tz => "America/Argentina/San_Luis" },
        armdz => {
            alias => [qw( America/Mendoza America/Argentina/Mendoza )],
            desc => "Mendoza, Argentina",
            tz => "America/Argentina/Mendoza",
        },
        arrgl => {
            desc => "R\xEDo Gallegos, Argentina",
            tz => "America/Argentina/Rio_Gallegos",
        },
        arsla => { desc => "Salta, Argentina", tz => "America/Argentina/Salta" },
        artuc => { desc => "Tucum\xE1n, Argentina", tz => "America/Argentina/Tucuman" },
        aruaq => { desc => "San Juan, Argentina", tz => "America/Argentina/San_Juan" },
        arush => { desc => "Ushuaia, Argentina", tz => "America/Argentina/Ushuaia" },
        asppg => {
            alias => [qw( Pacific/Pago_Pago Pacific/Samoa US/Samoa )],
            desc => "Pago Pago, American Samoa",
            tz => "Pacific/Pago_Pago",
        },
        atvie => { desc => "Vienna, Austria", tz => "Europe/Vienna" },
        auadl => {
            alias => [qw( Australia/Adelaide Australia/South )],
            desc => "Adelaide, Australia",
            tz => "Australia/Adelaide",
        },
        aubhq => {
            alias => [qw( Australia/Broken_Hill Australia/Yancowinna )],
            desc => "Broken Hill, Australia",
            tz => "Australia/Broken_Hill",
        },
        aubne => {
            alias => [qw( Australia/Brisbane Australia/Queensland )],
            desc => "Brisbane, Australia",
            tz => "Australia/Brisbane",
        },
        audrw => {
            alias => [qw( Australia/Darwin Australia/North )],
            desc => "Darwin, Australia",
            tz => "Australia/Darwin",
        },
        aueuc => { desc => "Eucla, Australia", tz => "Australia/Eucla" },
        auhba => {
            alias => [qw( Australia/Hobart Australia/Tasmania Australia/Currie )],
            desc => "Hobart, Australia",
            tz => "Australia/Hobart",
        },
        aukns => { deprecated => 1, desc => "Currie, Australia", preferred => "auhba" },
        auldc => { desc => "Lindeman Island, Australia", tz => "Australia/Lindeman" },
        auldh => {
            alias => [qw( Australia/Lord_Howe Australia/LHI )],
            desc => "Lord Howe Island, Australia",
            tz => "Australia/Lord_Howe",
        },
        aumel => {
            alias => [qw( Australia/Melbourne Australia/Victoria )],
            desc => "Melbourne, Australia",
            tz => "Australia/Melbourne",
        },
        aumqi => {
            desc => "Macquarie Island Station, Macquarie Island",
            tz => "Antarctica/Macquarie",
        },
        auper => {
            alias => [qw( Australia/Perth Australia/West )],
            desc => "Perth, Australia",
            tz => "Australia/Perth",
        },
        ausyd => {
            alias => [qw(
                Australia/Sydney Australia/ACT Australia/Canberra
                Australia/NSW
            )],
            desc => "Sydney, Australia",
            tz => "Australia/Sydney",
        },
        awaua => { desc => "Aruba", tz => "America/Aruba" },
        azbak => { desc => "Baku, Azerbaijan", tz => "Asia/Baku" },
        basjj => { desc => "Sarajevo, Bosnia and Herzegovina", tz => "Europe/Sarajevo" },
        bbbgi => { desc => "Barbados", tz => "America/Barbados" },
        bddac => {
            alias => [qw( Asia/Dhaka Asia/Dacca )],
            desc => "Dhaka, Bangladesh",
            tz => "Asia/Dhaka",
        },
        bebru => { desc => "Brussels, Belgium", tz => "Europe/Brussels" },
        bfoua => { desc => "Ouagadougou, Burkina Faso", tz => "Africa/Ouagadougou" },
        bgsof => { desc => "Sofia, Bulgaria", tz => "Europe/Sofia" },
        bhbah => { desc => "Bahrain", tz => "Asia/Bahrain" },
        bibjm => { desc => "Bujumbura, Burundi", tz => "Africa/Bujumbura" },
        bjptn => { desc => "Porto-Novo, Benin", tz => "Africa/Porto-Novo" },
        bmbda => { desc => "Bermuda", tz => "Atlantic/Bermuda" },
        bnbwn => { desc => "Brunei", tz => "Asia/Brunei" },
        bolpb => { desc => "La Paz, Bolivia", tz => "America/La_Paz" },
        bqkra => {
            desc => "Bonaire, Sint Estatius and Saba",
            tz => "America/Kralendijk",
        },
        braux => { desc => "Aragua\xEDna, Brazil", tz => "America/Araguaina" },
        brbel => { desc => "Bel\xE9m, Brazil", tz => "America/Belem" },
        brbvb => { desc => "Boa Vista, Brazil", tz => "America/Boa_Vista" },
        brcgb => { desc => "Cuiab\xE1, Brazil", tz => "America/Cuiaba" },
        brcgr => { desc => "Campo Grande, Brazil", tz => "America/Campo_Grande" },
        brern => { desc => "Eirunep\xE9, Brazil", tz => "America/Eirunepe" },
        brfen => {
            alias => [qw( America/Noronha Brazil/DeNoronha )],
            desc => "Fernando de Noronha, Brazil",
            tz => "America/Noronha",
        },
        brfor => { desc => "Fortaleza, Brazil", tz => "America/Fortaleza" },
        brmao => {
            alias => [qw( America/Manaus Brazil/West )],
            desc => "Manaus, Brazil",
            tz => "America/Manaus",
        },
        brmcz => { desc => "Macei\xF3, Brazil", tz => "America/Maceio" },
        brpvh => { desc => "Porto Velho, Brazil", tz => "America/Porto_Velho" },
        brrbr => {
            alias => [qw( America/Rio_Branco America/Porto_Acre Brazil/Acre )],
            desc => "Rio Branco, Brazil",
            tz => "America/Rio_Branco",
        },
        brrec => { desc => "Recife, Brazil", tz => "America/Recife" },
        brsao => {
            alias => [qw( America/Sao_Paulo Brazil/East )],
            desc => "S\xE3o Paulo, Brazil",
            tz => "America/Sao_Paulo",
        },
        brssa => { desc => "Bahia, Brazil", tz => "America/Bahia" },
        brstm => { desc => "Santar\xE9m, Brazil", tz => "America/Santarem" },
        bsnas => { desc => "Nassau, Bahamas", tz => "America/Nassau" },
        btthi => {
            alias => [qw( Asia/Thimphu Asia/Thimbu )],
            desc => "Thimphu, Bhutan",
            tz => "Asia/Thimphu",
        },
        bwgbe => { desc => "Gaborone, Botswana", tz => "Africa/Gaborone" },
        bymsq => { desc => "Minsk, Belarus", tz => "Europe/Minsk" },
        bzbze => { desc => "Belize", tz => "America/Belize" },
        cacfq => { desc => "Creston, Canada", tz => "America/Creston" },
        caedm => {
            alias => [qw( America/Edmonton Canada/Mountain America/Yellowknife )],
            desc => "Edmonton, Canada",
            tz => "America/Edmonton",
        },
        caffs => { deprecated => 1, desc => "Rainy River, Canada", preferred => "cawnp" },
        cafne => { desc => "Fort Nelson, Canada", tz => "America/Fort_Nelson" },
        caglb => { desc => "Glace Bay, Canada", tz => "America/Glace_Bay" },
        cagoo => { desc => "Goose Bay, Canada", tz => "America/Goose_Bay" },
        cahal => {
            alias => [qw( America/Halifax Canada/Atlantic )],
            desc => "Halifax, Canada",
            tz => "America/Halifax",
        },
        caiql => {
            alias => [qw( America/Iqaluit America/Pangnirtung )],
            desc => "Iqaluit, Canada",
            tz => "America/Iqaluit",
        },
        camon => { desc => "Moncton, Canada", tz => "America/Moncton" },
        camtr => { deprecated => 1, desc => "Montreal, Canada", preferred => "cator" },
        canpg => { deprecated => 1, desc => "Nipigon, Canada", preferred => "cator" },
        capnt => { deprecated => 1, desc => "Pangnirtung, Canada", preferred => "caiql" },
        careb => { desc => "Resolute, Canada", tz => "America/Resolute" },
        careg => {
            alias => [qw( America/Regina Canada/East-Saskatchewan Canada/Saskatchewan )],
            desc => "Regina, Canada",
            tz => "America/Regina",
        },
        casjf => {
            alias => [qw( America/St_Johns Canada/Newfoundland )],
            desc => "St. John's, Canada",
            tz => "America/St_Johns",
        },
        cathu => { deprecated => 1, desc => "Thunder Bay, Canada", preferred => "cator" },
        cator => {
            alias => [qw(
                America/Toronto America/Montreal Canada/Eastern
                America/Nipigon America/Thunder_Bay
            )],
            desc => "Toronto, Canada",
            tz => "America/Toronto",
        },
        cavan => {
            alias => [qw( America/Vancouver Canada/Pacific )],
            desc => "Vancouver, Canada",
            tz => "America/Vancouver",
        },
        cawnp => {
            alias => [qw( America/Winnipeg Canada/Central America/Rainy_River )],
            desc => "Winnipeg, Canada",
            tz => "America/Winnipeg",
        },
        caybx => { desc => "Blanc-Sablon, Canada", tz => "America/Blanc-Sablon" },
        caycb => { desc => "Cambridge Bay, Canada", tz => "America/Cambridge_Bay" },
        cayda => { desc => "Dawson, Canada", tz => "America/Dawson" },
        caydq => { desc => "Dawson Creek, Canada", tz => "America/Dawson_Creek" },
        cayek => { desc => "Rankin Inlet, Canada", tz => "America/Rankin_Inlet" },
        cayev => { desc => "Inuvik, Canada", tz => "America/Inuvik" },
        cayxy => {
            alias => [qw( America/Whitehorse Canada/Yukon )],
            desc => "Whitehorse, Canada",
            tz => "America/Whitehorse",
        },
        cayyn => { desc => "Swift Current, Canada", tz => "America/Swift_Current" },
        cayzf => { deprecated => 1, desc => "Yellowknife, Canada", preferred => "caedm" },
        cayzs => {
            alias => [qw( America/Coral_Harbour America/Atikokan )],
            desc => "Atikokan, Canada",
            tz => "America/Atikokan",
        },
        cccck => { desc => "Cocos (Keeling) Islands", tz => "Indian/Cocos" },
        cdfbm => {
            desc => "Lubumbashi, Democratic Republic of the Congo",
            tz => "Africa/Lubumbashi",
        },
        cdfih => {
            desc => "Kinshasa, Democratic Republic of the Congo",
            tz => "Africa/Kinshasa",
        },
        cfbgf => { desc => "Bangui, Central African Republic", tz => "Africa/Bangui" },
        cgbzv => {
            desc => "Brazzaville, Republic of the Congo",
            tz => "Africa/Brazzaville",
        },
        chzrh => { desc => "Zurich, Switzerland", tz => "Europe/Zurich" },
        ciabj => { desc => "Abidjan, C\xF4te d'Ivoire", tz => "Africa/Abidjan" },
        ckrar => { desc => "Rarotonga, Cook Islands", tz => "Pacific/Rarotonga" },
        clipc => {
            alias => [qw( Pacific/Easter Chile/EasterIsland )],
            desc => "Easter Island, Chile",
            tz => "Pacific/Easter",
        },
        clpuq => { desc => "Punta Arenas, Chile", tz => "America/Punta_Arenas" },
        clscl => {
            alias => [qw( America/Santiago Chile/Continental )],
            desc => "Santiago, Chile",
            tz => "America/Santiago",
        },
        cmdla => { desc => "Douala, Cameroon", tz => "Africa/Douala" },
        cnckg => { deprecated => 1, desc => "Chongqing, China", preferred => "cnsha" },
        cnhrb => { deprecated => 1, desc => "Harbin, China", preferred => "cnsha" },
        cnkhg => { deprecated => 1, desc => "Kashgar, China", preferred => "cnurc" },
        cnsha => {
            alias => [qw( Asia/Shanghai Asia/Chongqing Asia/Chungking Asia/Harbin PRC )],
            desc => "Shanghai, China",
            tz => "Asia/Shanghai",
        },
        cnurc => {
            alias => [qw( Asia/Urumqi Asia/Kashgar )],
            desc => "\xDCr\xFCmqi, China",
            tz => "Asia/Urumqi",
        },
        cobog => { desc => "Bogot\xE1, Colombia", tz => "America/Bogota" },
        crsjo => { desc => "Costa Rica", tz => "America/Costa_Rica" },
        cst6cdt => {
            desc => "POSIX style time zone for US Central Time",
            tz => "CST6CDT",
        },
        cuhav => {
            alias => [qw( America/Havana Cuba )],
            desc => "Havana, Cuba",
            tz => "America/Havana",
        },
        cvrai => { desc => "Cape Verde", tz => "Atlantic/Cape_Verde" },
        cxxch => { desc => "Christmas Island", tz => "Indian/Christmas" },
        cyfmg => { desc => "Famagusta, Cyprus", tz => "Asia/Famagusta" },
        cynic => {
            alias => [qw( Asia/Nicosia Europe/Nicosia )],
            desc => "Nicosia, Cyprus",
            tz => "Asia/Nicosia",
        },
        czprg => { desc => "Prague, Czech Republic", tz => "Europe/Prague" },
        deber => { desc => "Berlin, Germany", tz => "Europe/Berlin" },
        debsngn => { desc => "Busingen, Germany", tz => "Europe/Busingen" },
        deprecated => 1,
        djjib => { desc => "Djibouti", tz => "Africa/Djibouti" },
        dkcph => { desc => "Copenhagen, Denmark", tz => "Europe/Copenhagen" },
        dmdom => { desc => "Dominica", tz => "America/Dominica" },
        dosdq => {
            desc => "Santo Domingo, Dominican Republic",
            tz => "America/Santo_Domingo",
        },
        dzalg => { desc => "Algiers, Algeria", tz => "Africa/Algiers" },
        ecgps => { desc => "Gal\xE1pagos Islands, Ecuador", tz => "Pacific/Galapagos" },
        ecgye => { desc => "Guayaquil, Ecuador", tz => "America/Guayaquil" },
        eetll => { desc => "Tallinn, Estonia", tz => "Europe/Tallinn" },
        egcai => {
            alias => [qw( Africa/Cairo Egypt )],
            desc => "Cairo, Egypt",
            tz => "Africa/Cairo",
        },
        eheai => { desc => "El Aai\xFAn, Western Sahara", tz => "Africa/El_Aaiun" },
        erasm => {
            alias => [qw( Africa/Asmera Africa/Asmara )],
            desc => "Asmara, Eritrea",
            tz => "Africa/Asmara",
        },
        esceu => { desc => "Ceuta, Spain", tz => "Africa/Ceuta" },
        eslpa => { desc => "Canary Islands, Spain", tz => "Atlantic/Canary" },
        esmad => { desc => "Madrid, Spain", tz => "Europe/Madrid" },
        est5edt => {
            desc => "POSIX style time zone for US Eastern Time",
            tz => "EST5EDT",
        },
        etadd => { desc => "Addis Ababa, Ethiopia", tz => "Africa/Addis_Ababa" },
        fihel => { desc => "Helsinki, Finland", tz => "Europe/Helsinki" },
        fimhq => { desc => "Mariehamn, \xC5land, Finland", tz => "Europe/Mariehamn" },
        fjsuv => { desc => "Fiji", tz => "Pacific/Fiji" },
        fkpsy => { desc => "Stanley, Falkland Islands", tz => "Atlantic/Stanley" },
        fmksa => { desc => "Kosrae, Micronesia", tz => "Pacific/Kosrae" },
        fmpni => {
            alias => [qw( Pacific/Ponape Pacific/Pohnpei )],
            desc => "Pohnpei, Micronesia",
            tz => "Pacific/Pohnpei",
        },
        fmtkk => {
            alias => [qw( Pacific/Truk Pacific/Chuuk Pacific/Yap )],
            desc => "Chuuk, Micronesia",
            tz => "Pacific/Chuuk",
        },
        fotho => {
            alias => [qw( Atlantic/Faeroe Atlantic/Faroe )],
            desc => "Faroe Islands",
            tz => "Atlantic/Faroe",
        },
        frpar => { desc => "Paris, France", tz => "Europe/Paris" },
        galbv => { desc => "Libreville, Gabon", tz => "Africa/Libreville" },
        gaza => {
            deprecated => 1,
            desc => "Gaza Strip, Palestinian Territories",
            preferred => "gazastrp",
        },
        gazastrp => { desc => "Gaza Strip, Palestinian Territories", tz => "Asia/Gaza" },
        gblon => {
            alias => [qw( Europe/London Europe/Belfast GB GB-Eire )],
            desc => "London, United Kingdom",
            tz => "Europe/London",
        },
        gdgnd => { desc => "Grenada", tz => "America/Grenada" },
        getbs => { desc => "Tbilisi, Georgia", tz => "Asia/Tbilisi" },
        gfcay => { desc => "Cayenne, French Guiana", tz => "America/Cayenne" },
        gggci => { desc => "Guernsey", tz => "Europe/Guernsey" },
        ghacc => { desc => "Accra, Ghana", tz => "Africa/Accra" },
        gigib => { desc => "Gibraltar", tz => "Europe/Gibraltar" },
        gldkshvn => { desc => "Danmarkshavn, Greenland", tz => "America/Danmarkshavn" },
        glgoh => {
            alias => [qw( America/Godthab America/Nuuk )],
            desc => "Nuuk (Godth\xE5b), Greenland",
            tz => "America/Nuuk",
        },
        globy => {
            desc => "Ittoqqortoormiit (Scoresbysund), Greenland",
            tz => "America/Scoresbysund",
        },
        glthu => { desc => "Qaanaaq (Thule), Greenland", tz => "America/Thule" },
        gmbjl => { desc => "Banjul, Gambia", tz => "Africa/Banjul" },
        gmt => {
            alias => [qw(
                Etc/GMT Etc/GMT+0 Etc/GMT-0 Etc/GMT0 Etc/Greenwich GMT
                GMT+0 GMT-0 GMT0 Greenwich
            )],
            desc => "Greenwich Mean Time",
            tz => "Etc/GMT",
        },
        gncky => { desc => "Conakry, Guinea", tz => "Africa/Conakry" },
        gpbbr => { desc => "Guadeloupe", tz => "America/Guadeloupe" },
        gpmsb => { desc => "Marigot, Saint Martin", tz => "America/Marigot" },
        gpsbh => { desc => "Saint Barth\xE9lemy", tz => "America/St_Barthelemy" },
        gqssg => { desc => "Malabo, Equatorial Guinea", tz => "Africa/Malabo" },
        grath => { desc => "Athens, Greece", tz => "Europe/Athens" },
        gsgrv => {
            desc => "South Georgia and the South Sandwich Islands",
            tz => "Atlantic/South_Georgia",
        },
        gtgua => { desc => "Guatemala", tz => "America/Guatemala" },
        gugum => { desc => "Guam", tz => "Pacific/Guam" },
        gwoxb => { desc => "Bissau, Guinea-Bissau", tz => "Africa/Bissau" },
        gygeo => { desc => "Guyana", tz => "America/Guyana" },
        hebron => { desc => "West Bank, Palestinian Territories", tz => "Asia/Hebron" },
        hkhkg => {
            alias => [qw( Asia/Hong_Kong Hongkong )],
            desc => "Hong Kong SAR China",
            tz => "Asia/Hong_Kong",
        },
        hntgu => { desc => "Tegucigalpa, Honduras", tz => "America/Tegucigalpa" },
        hrzag => { desc => "Zagreb, Croatia", tz => "Europe/Zagreb" },
        htpap => { desc => "Port-au-Prince, Haiti", tz => "America/Port-au-Prince" },
        hubud => { desc => "Budapest, Hungary", tz => "Europe/Budapest" },
        iddjj => { desc => "Jayapura, Indonesia", tz => "Asia/Jayapura" },
        idjkt => { desc => "Jakarta, Indonesia", tz => "Asia/Jakarta" },
        idmak => {
            alias => [qw( Asia/Makassar Asia/Ujung_Pandang )],
            desc => "Makassar, Indonesia",
            tz => "Asia/Makassar",
        },
        idpnk => { desc => "Pontianak, Indonesia", tz => "Asia/Pontianak" },
        iedub => {
            alias => [qw( Europe/Dublin Eire )],
            desc => "Dublin, Ireland",
            tz => "Europe/Dublin",
        },
        imdgs => { desc => "Isle of Man", tz => "Europe/Isle_of_Man" },
        inccu => {
            alias => [qw( Asia/Calcutta Asia/Kolkata )],
            desc => "Kolkata, India",
            tz => "Asia/Kolkata",
        },
        iodga => { desc => "Chagos Archipelago", tz => "Indian/Chagos" },
        iqbgw => { desc => "Baghdad, Iraq", tz => "Asia/Baghdad" },
        irthr => {
            alias => [qw( Asia/Tehran Iran )],
            desc => "Tehran, Iran",
            tz => "Asia/Tehran",
        },
        isrey => {
            alias => [qw( Atlantic/Reykjavik Iceland )],
            desc => "Reykjavik, Iceland",
            tz => "Atlantic/Reykjavik",
        },
        itrom => { desc => "Rome, Italy", tz => "Europe/Rome" },
        jeruslm => {
            alias => [qw( Asia/Jerusalem Asia/Tel_Aviv Israel )],
            desc => "Jerusalem",
            tz => "Asia/Jerusalem",
        },
        jesth => { desc => "Jersey", tz => "Europe/Jersey" },
        jmkin => {
            alias => [qw( America/Jamaica Jamaica )],
            desc => "Jamaica",
            tz => "America/Jamaica",
        },
        joamm => { desc => "Amman, Jordan", tz => "Asia/Amman" },
        jptyo => {
            alias => [qw( Asia/Tokyo Japan )],
            desc => "Tokyo, Japan",
            tz => "Asia/Tokyo",
        },
        kenbo => { desc => "Nairobi, Kenya", tz => "Africa/Nairobi" },
        kgfru => { desc => "Bishkek, Kyrgyzstan", tz => "Asia/Bishkek" },
        khpnh => { desc => "Phnom Penh, Cambodia", tz => "Asia/Phnom_Penh" },
        kicxi => { desc => "Kiritimati, Kiribati", tz => "Pacific/Kiritimati" },
        kipho => {
            alias => [qw( Pacific/Enderbury Pacific/Kanton )],
            desc => "Enderbury Island, Kiribati",
            tz => "Pacific/Kanton",
        },
        kitrw => { desc => "Tarawa, Kiribati", tz => "Pacific/Tarawa" },
        kmyva => { desc => "Comoros", tz => "Indian/Comoro" },
        knbas => { desc => "Saint Kitts", tz => "America/St_Kitts" },
        kpfnj => { desc => "Pyongyang, North Korea", tz => "Asia/Pyongyang" },
        krsel => {
            alias => [qw( Asia/Seoul ROK )],
            desc => "Seoul, South Korea",
            tz => "Asia/Seoul",
        },
        kwkwi => { desc => "Kuwait", tz => "Asia/Kuwait" },
        kygec => { desc => "Cayman Islands", tz => "America/Cayman" },
        kzaau => { desc => "Aqtau, Kazakhstan", tz => "Asia/Aqtau" },
        kzakx => { desc => "Aqtobe, Kazakhstan", tz => "Asia/Aqtobe" },
        kzala => { desc => "Almaty, Kazakhstan", tz => "Asia/Almaty" },
        kzguw => { desc => "Atyrau (Guryev), Kazakhstan", tz => "Asia/Atyrau" },
        kzksn => { desc => "Qostanay (Kostanay), Kazakhstan", tz => "Asia/Qostanay" },
        kzkzo => { desc => "Kyzylorda, Kazakhstan", tz => "Asia/Qyzylorda" },
        kzura => { desc => "Oral, Kazakhstan", tz => "Asia/Oral" },
        lavte => { desc => "Vientiane, Laos", tz => "Asia/Vientiane" },
        lbbey => { desc => "Beirut, Lebanon", tz => "Asia/Beirut" },
        lccas => { desc => "Saint Lucia", tz => "America/St_Lucia" },
        livdz => { desc => "Vaduz, Liechtenstein", tz => "Europe/Vaduz" },
        lkcmb => { desc => "Colombo, Sri Lanka", tz => "Asia/Colombo" },
        lrmlw => { desc => "Monrovia, Liberia", tz => "Africa/Monrovia" },
        lsmsu => { desc => "Maseru, Lesotho", tz => "Africa/Maseru" },
        ltvno => { desc => "Vilnius, Lithuania", tz => "Europe/Vilnius" },
        lulux => { desc => "Luxembourg", tz => "Europe/Luxembourg" },
        lvrix => { desc => "Riga, Latvia", tz => "Europe/Riga" },
        lytip => {
            alias => [qw( Africa/Tripoli Libya )],
            desc => "Tripoli, Libya",
            tz => "Africa/Tripoli",
        },
        macas => { desc => "Casablanca, Morocco", tz => "Africa/Casablanca" },
        mcmon => { desc => "Monaco", tz => "Europe/Monaco" },
        mdkiv => {
            alias => [qw( Europe/Chisinau Europe/Tiraspol )],
            desc => "Chi\x{15F}in\x{103}u, Moldova",
            tz => "Europe/Chisinau",
        },
        metgd => { desc => "Podgorica, Montenegro", tz => "Europe/Podgorica" },
        mgtnr => { desc => "Antananarivo, Madagascar", tz => "Indian/Antananarivo" },
        mhkwa => {
            alias => [qw( Pacific/Kwajalein Kwajalein )],
            desc => "Kwajalein, Marshall Islands",
            tz => "Pacific/Kwajalein",
        },
        mhmaj => { desc => "Majuro, Marshall Islands", tz => "Pacific/Majuro" },
        mkskp => { desc => "Skopje, Macedonia", tz => "Europe/Skopje" },
        mlbko => {
            alias => [qw( Africa/Bamako Africa/Timbuktu )],
            desc => "Bamako, Mali",
            tz => "Africa/Bamako",
        },
        mmrgn => {
            alias => [qw( Asia/Rangoon Asia/Yangon )],
            desc => "Yangon (Rangoon), Burma",
            tz => "Asia/Yangon",
        },
        mncoq => { desc => "Choibalsan, Mongolia", tz => "Asia/Choibalsan" },
        mnhvd => { desc => "Khovd (Hovd), Mongolia", tz => "Asia/Hovd" },
        mnuln => {
            alias => [qw( Asia/Ulaanbaatar Asia/Ulan_Bator )],
            desc => "Ulaanbaatar (Ulan Bator), Mongolia",
            tz => "Asia/Ulaanbaatar",
        },
        momfm => {
            alias => [qw( Asia/Macau Asia/Macao )],
            desc => "Macau SAR China",
            tz => "Asia/Macau",
        },
        mpspn => { desc => "Saipan, Northern Mariana Islands", tz => "Pacific/Saipan" },
        mqfdf => { desc => "Martinique", tz => "America/Martinique" },
        mrnkc => { desc => "Nouakchott, Mauritania", tz => "Africa/Nouakchott" },
        msmni => { desc => "Montserrat", tz => "America/Montserrat" },
        mst7mdt => {
            desc => "POSIX style time zone for US Mountain Time",
            tz => "MST7MDT",
        },
        mtmla => { desc => "Malta", tz => "Europe/Malta" },
        muplu => { desc => "Mauritius", tz => "Indian/Mauritius" },
        mvmle => { desc => "Maldives", tz => "Indian/Maldives" },
        mwblz => { desc => "Blantyre, Malawi", tz => "Africa/Blantyre" },
        mxchi => { desc => "Chihuahua, Mexico", tz => "America/Chihuahua" },
        mxcjs => { desc => "Ciudad Ju\xE1rez, Mexico", tz => "America/Ciudad_Juarez" },
        mxcun => { desc => "Canc\xFAn, Mexico", tz => "America/Cancun" },
        mxhmo => { desc => "Hermosillo, Mexico", tz => "America/Hermosillo" },
        mxmam => { desc => "Matamoros, Mexico", tz => "America/Matamoros" },
        mxmex => {
            alias => [qw( America/Mexico_City Mexico/General )],
            desc => "Mexico City, Mexico",
            tz => "America/Mexico_City",
        },
        mxmid => { desc => "M\xE9rida, Mexico", tz => "America/Merida" },
        mxmty => { desc => "Monterrey, Mexico", tz => "America/Monterrey" },
        mxmzt => {
            alias => [qw( America/Mazatlan Mexico/BajaSur )],
            desc => "Mazatl\xE1n, Mexico",
            tz => "America/Mazatlan",
        },
        mxoji => { desc => "Ojinaga, Mexico", tz => "America/Ojinaga" },
        mxpvr => {
            desc => "Bah\xEDa de Banderas, Mexico",
            tz => "America/Bahia_Banderas",
        },
        mxstis => {
            deprecated => 1,
            desc => "Santa Isabel (Baja California), Mexico",
            preferred => "mxtij",
        },
        mxtij => {
            alias => [qw(
                America/Tijuana America/Ensenada Mexico/BajaNorte
                America/Santa_Isabel
            )],
            desc => "Tijuana, Mexico",
            tz => "America/Tijuana",
        },
        mykch => { desc => "Kuching, Malaysia", tz => "Asia/Kuching" },
        mykul => { desc => "Kuala Lumpur, Malaysia", tz => "Asia/Kuala_Lumpur" },
        mzmpm => { desc => "Maputo, Mozambique", tz => "Africa/Maputo" },
        nawdh => { desc => "Windhoek, Namibia", tz => "Africa/Windhoek" },
        ncnou => { desc => "Noumea, New Caledonia", tz => "Pacific/Noumea" },
        nenim => { desc => "Niamey, Niger", tz => "Africa/Niamey" },
        nfnlk => { desc => "Norfolk Island", tz => "Pacific/Norfolk" },
        nglos => { desc => "Lagos, Nigeria", tz => "Africa/Lagos" },
        nimga => { desc => "Managua, Nicaragua", tz => "America/Managua" },
        nlams => { desc => "Amsterdam, Netherlands", tz => "Europe/Amsterdam" },
        noosl => { desc => "Oslo, Norway", tz => "Europe/Oslo" },
        npktm => {
            alias => [qw( Asia/Katmandu Asia/Kathmandu )],
            desc => "Kathmandu, Nepal",
            tz => "Asia/Kathmandu",
        },
        nrinu => { desc => "Nauru", tz => "Pacific/Nauru" },
        nuiue => { desc => "Niue", tz => "Pacific/Niue" },
        nzakl => {
            alias => [qw( Pacific/Auckland Antarctica/South_Pole NZ )],
            desc => "Auckland, New Zealand",
            tz => "Pacific/Auckland",
        },
        nzcht => {
            alias => [qw( Pacific/Chatham NZ-CHAT )],
            desc => "Chatham Islands, New Zealand",
            tz => "Pacific/Chatham",
        },
        ommct => { desc => "Muscat, Oman", tz => "Asia/Muscat" },
        papty => { desc => "Panama", tz => "America/Panama" },
        pelim => { desc => "Lima, Peru", tz => "America/Lima" },
        pfgmr => {
            desc => "Gambiera Islands, French Polynesia",
            tz => "Pacific/Gambier",
        },
        pfnhv => {
            desc => "Marquesas Islands, French Polynesia",
            tz => "Pacific/Marquesas",
        },
        pfppt => { desc => "Tahiti, French Polynesia", tz => "Pacific/Tahiti" },
        pgpom => {
            desc => "Port Moresby, Papua New Guinea",
            tz => "Pacific/Port_Moresby",
        },
        pgraw => {
            desc => "Bougainville, Papua New Guinea",
            tz => "Pacific/Bougainville",
        },
        phmnl => { desc => "Manila, Philippines", tz => "Asia/Manila" },
        pkkhi => { desc => "Karachi, Pakistan", tz => "Asia/Karachi" },
        plwaw => {
            alias => [qw( Europe/Warsaw Poland )],
            desc => "Warsaw, Poland",
            tz => "Europe/Warsaw",
        },
        pmmqc => { desc => "Saint Pierre and Miquelon", tz => "America/Miquelon" },
        pnpcn => { desc => "Pitcairn Islands", tz => "Pacific/Pitcairn" },
        prsju => { desc => "Puerto Rico", tz => "America/Puerto_Rico" },
        pst8pdt => {
            desc => "POSIX style time zone for US Pacific Time",
            tz => "PST8PDT",
        },
        ptfnc => { desc => "Madeira, Portugal", tz => "Atlantic/Madeira" },
        ptlis => {
            alias => [qw( Europe/Lisbon Portugal )],
            desc => "Lisbon, Portugal",
            tz => "Europe/Lisbon",
        },
        ptpdl => { desc => "Azores, Portugal", tz => "Atlantic/Azores" },
        pwror => { desc => "Palau", tz => "Pacific/Palau" },
        pyasu => { desc => "Asunci\xF3n, Paraguay", tz => "America/Asuncion" },
        qadoh => { desc => "Qatar", tz => "Asia/Qatar" },
        rereu => { desc => "R\xE9union", tz => "Indian/Reunion" },
        robuh => { desc => "Bucharest, Romania", tz => "Europe/Bucharest" },
        rsbeg => { desc => "Belgrade, Serbia", tz => "Europe/Belgrade" },
        ruasf => { desc => "Astrakhan, Russia", tz => "Europe/Astrakhan" },
        rubax => { desc => "Barnaul, Russia", tz => "Asia/Barnaul" },
        ruchita => { desc => "Chita Zabaykalsky, Russia", tz => "Asia/Chita" },
        rudyr => { desc => "Anadyr, Russia", tz => "Asia/Anadyr" },
        rugdx => { desc => "Magadan, Russia", tz => "Asia/Magadan" },
        ruikt => { desc => "Irkutsk, Russia", tz => "Asia/Irkutsk" },
        rukgd => { desc => "Kaliningrad, Russia", tz => "Europe/Kaliningrad" },
        rukhndg => { desc => "Khandyga Tomponsky, Russia", tz => "Asia/Khandyga" },
        rukra => { desc => "Krasnoyarsk, Russia", tz => "Asia/Krasnoyarsk" },
        rukuf => { desc => "Samara, Russia", tz => "Europe/Samara" },
        rukvx => { desc => "Kirov, Russia", tz => "Europe/Kirov" },
        rumow => {
            alias => [qw( Europe/Moscow W-SU )],
            desc => "Moscow, Russia",
            tz => "Europe/Moscow",
        },
        runoz => { desc => "Novokuznetsk, Russia", tz => "Asia/Novokuznetsk" },
        ruoms => { desc => "Omsk, Russia", tz => "Asia/Omsk" },
        ruovb => { desc => "Novosibirsk, Russia", tz => "Asia/Novosibirsk" },
        rupkc => { desc => "Kamchatka Peninsula, Russia", tz => "Asia/Kamchatka" },
        rurtw => { desc => "Saratov, Russia", tz => "Europe/Saratov" },
        rusred => { desc => "Srednekolymsk, Russia", tz => "Asia/Srednekolymsk" },
        rutof => { desc => "Tomsk, Russia", tz => "Asia/Tomsk" },
        ruuly => { desc => "Ulyanovsk, Russia", tz => "Europe/Ulyanovsk" },
        ruunera => { desc => "Ust-Nera Oymyakonsky, Russia", tz => "Asia/Ust-Nera" },
        ruuus => { desc => "Sakhalin, Russia", tz => "Asia/Sakhalin" },
        ruvog => { desc => "Volgograd, Russia", tz => "Europe/Volgograd" },
        ruvvo => { desc => "Vladivostok, Russia", tz => "Asia/Vladivostok" },
        ruyek => { desc => "Yekaterinburg, Russia", tz => "Asia/Yekaterinburg" },
        ruyks => { desc => "Yakutsk, Russia", tz => "Asia/Yakutsk" },
        rwkgl => { desc => "Kigali, Rwanda", tz => "Africa/Kigali" },
        saruh => { desc => "Riyadh, Saudi Arabia", tz => "Asia/Riyadh" },
        sbhir => { desc => "Guadalcanal, Solomon Islands", tz => "Pacific/Guadalcanal" },
        scmaw => { desc => "Mah\xE9, Seychelles", tz => "Indian/Mahe" },
        sdkrt => { desc => "Khartoum, Sudan", tz => "Africa/Khartoum" },
        sesto => { desc => "Stockholm, Sweden", tz => "Europe/Stockholm" },
        sgsin => {
            alias => [qw( Asia/Singapore Singapore )],
            desc => "Singapore",
            tz => "Asia/Singapore",
        },
        shshn => { desc => "Saint Helena", tz => "Atlantic/St_Helena" },
        silju => { desc => "Ljubljana, Slovenia", tz => "Europe/Ljubljana" },
        sjlyr => {
            alias => [qw( Arctic/Longyearbyen Atlantic/Jan_Mayen )],
            desc => "Longyearbyen, Svalbard",
            tz => "Arctic/Longyearbyen",
        },
        skbts => { desc => "Bratislava, Slovakia", tz => "Europe/Bratislava" },
        slfna => { desc => "Freetown, Sierra Leone", tz => "Africa/Freetown" },
        smsai => { desc => "San Marino", tz => "Europe/San_Marino" },
        sndkr => { desc => "Dakar, Senegal", tz => "Africa/Dakar" },
        somgq => { desc => "Mogadishu, Somalia", tz => "Africa/Mogadishu" },
        srpbm => { desc => "Paramaribo, Suriname", tz => "America/Paramaribo" },
        ssjub => { desc => "Juba, South Sudan", tz => "Africa/Juba" },
        sttms => {
            desc => "S\xE3o Tom\xE9, S\xE3o Tom\xE9 and Pr\xEDncipe",
            tz => "Africa/Sao_Tome",
        },
        svsal => { desc => "El Salvador", tz => "America/El_Salvador" },
        sxphi => { desc => "Sint Maarten", tz => "America/Lower_Princes" },
        sydam => { desc => "Damascus, Syria", tz => "Asia/Damascus" },
        szqmn => { desc => "Mbabane, Swaziland", tz => "Africa/Mbabane" },
        tcgdt => {
            desc => "Grand Turk, Turks and Caicos Islands",
            tz => "America/Grand_Turk",
        },
        tdndj => { desc => "N'Djamena, Chad", tz => "Africa/Ndjamena" },
        tfpfr => {
            desc => "Kerguelen Islands, French Southern Territories",
            tz => "Indian/Kerguelen",
        },
        tglfw => { desc => "Lom\xE9, Togo", tz => "Africa/Lome" },
        thbkk => { desc => "Bangkok, Thailand", tz => "Asia/Bangkok" },
        tjdyu => { desc => "Dushanbe, Tajikistan", tz => "Asia/Dushanbe" },
        tkfko => { desc => "Fakaofo, Tokelau", tz => "Pacific/Fakaofo" },
        tldil => { desc => "Dili, East Timor", tz => "Asia/Dili" },
        tmasb => {
            alias => [qw( Asia/Ashgabat Asia/Ashkhabad )],
            desc => "Ashgabat, Turkmenistan",
            tz => "Asia/Ashgabat",
        },
        tntun => { desc => "Tunis, Tunisia", tz => "Africa/Tunis" },
        totbu => { desc => "Tongatapu, Tonga", tz => "Pacific/Tongatapu" },
        trist => {
            alias => [qw( Europe/Istanbul Asia/Istanbul Turkey )],
            desc => "Istanbul, T\xFCrkiye",
            tz => "Europe/Istanbul",
        },
        ttpos => {
            desc => "Port of Spain, Trinidad and Tobago",
            tz => "America/Port_of_Spain",
        },
        tvfun => { desc => "Funafuti, Tuvalu", tz => "Pacific/Funafuti" },
        twtpe => {
            alias => [qw( Asia/Taipei ROC )],
            desc => "Taipei, Taiwan",
            tz => "Asia/Taipei",
        },
        tzdar => { desc => "Dar es Salaam, Tanzania", tz => "Africa/Dar_es_Salaam" },
        uaiev => {
            alias => [qw( Europe/Kiev Europe/Kyiv Europe/Zaporozhye Europe/Uzhgorod )],
            desc => "Kyiv, Ukraine",
            tz => "Europe/Kyiv",
        },
        uaozh => {
            deprecated => 1,
            desc => "Zaporizhia (Zaporozhye), Ukraine",
            preferred => "uaiev",
        },
        uasip => { desc => "Simferopol, Ukraine", tz => "Europe/Simferopol" },
        uauzh => {
            deprecated => 1,
            desc => "Uzhhorod (Uzhgorod), Ukraine",
            preferred => "uaiev",
        },
        ugkla => { desc => "Kampala, Uganda", tz => "Africa/Kampala" },
        umawk => {
            desc => "Wake Island, U.S. Minor Outlying Islands",
            tz => "Pacific/Wake",
        },
        umjon => {
            deprecated => 1,
            desc => "Johnston Atoll, U.S. Minor Outlying Islands",
            preferred => "ushnl",
        },
        ummdy => {
            desc => "Midway Islands, U.S. Minor Outlying Islands",
            tz => "Pacific/Midway",
        },
        unk => { desc => "Unknown time zone", tz => "Etc/Unknown" },
        usadk => {
            alias => [qw( America/Adak America/Atka US/Aleutian )],
            desc => "Adak (Alaska), United States",
            tz => "America/Adak",
        },
        usaeg => {
            desc => "Marengo (Indiana), United States",
            tz => "America/Indiana/Marengo",
        },
        usanc => {
            alias => [qw( America/Anchorage US/Alaska )],
            desc => "Anchorage, United States",
            tz => "America/Anchorage",
        },
        usboi => { desc => "Boise (Idaho), United States", tz => "America/Boise" },
        uschi => {
            alias => [qw( America/Chicago US/Central )],
            desc => "Chicago, United States",
            tz => "America/Chicago",
        },
        usden => {
            alias => [qw( America/Denver America/Shiprock Navajo US/Mountain )],
            desc => "Denver, United States",
            tz => "America/Denver",
        },
        usdet => {
            alias => [qw( America/Detroit US/Michigan )],
            desc => "Detroit, United States",
            tz => "America/Detroit",
        },
        ushnl => {
            alias => [qw( Pacific/Honolulu US/Hawaii Pacific/Johnston )],
            desc => "Honolulu, United States",
            tz => "Pacific/Honolulu",
        },
        usind => {
            alias => [qw(
                America/Indianapolis America/Fort_Wayne
                America/Indiana/Indianapolis US/East-Indiana
            )],
            desc => "Indianapolis, United States",
            tz => "America/Indiana/Indianapolis",
        },
        usinvev => {
            desc => "Vevay (Indiana), United States",
            tz => "America/Indiana/Vevay",
        },
        usjnu => { desc => "Juneau (Alaska), United States", tz => "America/Juneau" },
        usknx => {
            alias => [qw( America/Indiana/Knox America/Knox_IN US/Indiana-Starke )],
            desc => "Knox (Indiana), United States",
            tz => "America/Indiana/Knox",
        },
        uslax => {
            alias => [qw( America/Los_Angeles US/Pacific US/Pacific-New )],
            desc => "Los Angeles, United States",
            tz => "America/Los_Angeles",
        },
        uslui => {
            alias => [qw( America/Louisville America/Kentucky/Louisville )],
            desc => "Louisville (Kentucky), United States",
            tz => "America/Kentucky/Louisville",
        },
        usmnm => {
            desc => "Menominee (Michigan), United States",
            tz => "America/Menominee",
        },
        usmoc => {
            desc => "Monticello (Kentucky), United States",
            tz => "America/Kentucky/Monticello",
        },
        usmtm => {
            desc => "Metlakatla (Alaska), United States",
            tz => "America/Metlakatla",
        },
        usnavajo => {
            deprecated => 1,
            desc => "Shiprock (Navajo), United States",
            preferred => "usden",
        },
        usndcnt => {
            desc => "Center (North Dakota), United States",
            tz => "America/North_Dakota/Center",
        },
        usndnsl => {
            desc => "New Salem (North Dakota), United States",
            tz => "America/North_Dakota/New_Salem",
        },
        usnyc => {
            alias => [qw( America/New_York US/Eastern )],
            desc => "New York, United States",
            tz => "America/New_York",
        },
        usoea => {
            desc => "Vincennes (Indiana), United States",
            tz => "America/Indiana/Vincennes",
        },
        usome => { desc => "Nome (Alaska), United States", tz => "America/Nome" },
        usphx => {
            alias => [qw( America/Phoenix US/Arizona )],
            desc => "Phoenix, United States",
            tz => "America/Phoenix",
        },
        ussit => { desc => "Sitka (Alaska), United States", tz => "America/Sitka" },
        ustel => {
            desc => "Tell City (Indiana), United States",
            tz => "America/Indiana/Tell_City",
        },
        uswlz => {
            desc => "Winamac (Indiana), United States",
            tz => "America/Indiana/Winamac",
        },
        uswsq => {
            desc => "Petersburg (Indiana), United States",
            tz => "America/Indiana/Petersburg",
        },
        usxul => {
            desc => "Beulah (North Dakota), United States",
            tz => "America/North_Dakota/Beulah",
        },
        usyak => { desc => "Yakutat (Alaska), United States", tz => "America/Yakutat" },
        utc => {
            alias => [qw(
                Etc/UTC Etc/UCT Etc/Universal Etc/Zulu UCT UTC Universal
                Zulu
            )],
            desc => "UTC (Coordinated Universal Time)",
            tz => "Etc/UTC",
        },
        utce01 => { desc => "1 hour ahead of UTC", tz => "Etc/GMT-1" },
        utce02 => { desc => "2 hours ahead of UTC", tz => "Etc/GMT-2" },
        utce03 => { desc => "3 hours ahead of UTC", tz => "Etc/GMT-3" },
        utce04 => { desc => "4 hours ahead of UTC", tz => "Etc/GMT-4" },
        utce05 => { desc => "5 hours ahead of UTC", tz => "Etc/GMT-5" },
        utce06 => { desc => "6 hours ahead of UTC", tz => "Etc/GMT-6" },
        utce07 => { desc => "7 hours ahead of UTC", tz => "Etc/GMT-7" },
        utce08 => { desc => "8 hours ahead of UTC", tz => "Etc/GMT-8" },
        utce09 => { desc => "9 hours ahead of UTC", tz => "Etc/GMT-9" },
        utce10 => { desc => "10 hours ahead of UTC", tz => "Etc/GMT-10" },
        utce11 => { desc => "11 hours ahead of UTC", tz => "Etc/GMT-11" },
        utce12 => { desc => "12 hours ahead of UTC", tz => "Etc/GMT-12" },
        utce13 => { desc => "13 hours ahead of UTC", tz => "Etc/GMT-13" },
        utce14 => { desc => "14 hours ahead of UTC", tz => "Etc/GMT-14" },
        utcw01 => { desc => "1 hour behind UTC", tz => "Etc/GMT+1" },
        utcw02 => { desc => "2 hours behind UTC", tz => "Etc/GMT+2" },
        utcw03 => { desc => "3 hours behind UTC", tz => "Etc/GMT+3" },
        utcw04 => { desc => "4 hours behind UTC", tz => "Etc/GMT+4" },
        utcw05 => {
            alias => [qw( Etc/GMT+5 EST )],
            desc => "5 hours behind UTC",
            tz => "Etc/GMT+5",
        },
        utcw06 => { desc => "6 hours behind UTC", tz => "Etc/GMT+6" },
        utcw07 => {
            alias => [qw( Etc/GMT+7 MST )],
            desc => "7 hours behind UTC",
            tz => "Etc/GMT+7",
        },
        utcw08 => { desc => "8 hours behind UTC", tz => "Etc/GMT+8" },
        utcw09 => { desc => "9 hours behind UTC", tz => "Etc/GMT+9" },
        utcw10 => {
            alias => [qw( Etc/GMT+10 HST )],
            desc => "10 hours behind UTC",
            tz => "Etc/GMT+10",
        },
        utcw11 => { desc => "11 hours behind UTC", tz => "Etc/GMT+11" },
        utcw12 => { desc => "12 hours behind UTC", tz => "Etc/GMT+12" },
        uymvd => { desc => "Montevideo, Uruguay", tz => "America/Montevideo" },
        uzskd => { desc => "Samarkand, Uzbekistan", tz => "Asia/Samarkand" },
        uztas => { desc => "Tashkent, Uzbekistan", tz => "Asia/Tashkent" },
        vavat => { desc => "Vatican City", tz => "Europe/Vatican" },
        vcsvd => {
            desc => "Saint Vincent, Saint Vincent and the Grenadines",
            tz => "America/St_Vincent",
        },
        veccs => { desc => "Caracas, Venezuela", tz => "America/Caracas" },
        vgtov => { desc => "Tortola, British Virgin Islands", tz => "America/Tortola" },
        vistt => {
            alias => [qw( America/St_Thomas America/Virgin )],
            desc => "Saint Thomas, U.S. Virgin Islands",
            tz => "America/St_Thomas",
        },
        vnsgn => {
            alias => [qw( Asia/Saigon Asia/Ho_Chi_Minh )],
            desc => "Ho Chi Minh City, Vietnam",
            tz => "Asia/Ho_Chi_Minh",
        },
        vuvli => { desc => "Efate, Vanuatu", tz => "Pacific/Efate" },
        wfmau => { desc => "Wallis Islands, Wallis and Futuna", tz => "Pacific/Wallis" },
        wsapw => { desc => "Apia, Samoa", tz => "Pacific/Apia" },
        yeade => { desc => "Aden, Yemen", tz => "Asia/Aden" },
        ytmam => { desc => "Mayotte", tz => "Indian/Mayotte" },
        zajnb => { desc => "Johannesburg, South Africa", tz => "Africa/Johannesburg" },
        zmlun => { desc => "Lusaka, Zambia", tz => "Africa/Lusaka" },
        zwhre => { desc => "Harare, Zimbabwe", tz => "Africa/Harare" },
    };

    # NOTE: $TZ_NAME2ID
    # This BCP47 timezone database is different from the Olson IANA database in that it keeps old record for reliability and consistency.
    # See <https://github.com/unicode-org/cldr/blob/main/common/bcp47/timezone.xml>
    # <https://www.iana.org/time-zones>
    # <ftp://ftp.iana.org/tz/releases/>
    $TZ_NAME2ID =
    {
        "Africa/Abidjan" => "ciabj",
        "Africa/Accra" => "ghacc",
        "Africa/Addis_Ababa" => "etadd",
        "Africa/Algiers" => "dzalg",
        "Africa/Asmara" => "erasm",
        "Africa/Asmera" => "erasm",
        "Africa/Bamako" => "mlbko",
        "Africa/Bangui" => "cfbgf",
        "Africa/Banjul" => "gmbjl",
        "Africa/Bissau" => "gwoxb",
        "Africa/Blantyre" => "mwblz",
        "Africa/Brazzaville" => "cgbzv",
        "Africa/Bujumbura" => "bibjm",
        "Africa/Cairo" => "egcai",
        "Africa/Casablanca" => "macas",
        "Africa/Ceuta" => "esceu",
        "Africa/Conakry" => "gncky",
        "Africa/Dakar" => "sndkr",
        "Africa/Dar_es_Salaam" => "tzdar",
        "Africa/Djibouti" => "djjib",
        "Africa/Douala" => "cmdla",
        "Africa/El_Aaiun" => "eheai",
        "Africa/Freetown" => "slfna",
        "Africa/Gaborone" => "bwgbe",
        "Africa/Harare" => "zwhre",
        "Africa/Johannesburg" => "zajnb",
        "Africa/Juba" => "ssjub",
        "Africa/Kampala" => "ugkla",
        "Africa/Khartoum" => "sdkrt",
        "Africa/Kigali" => "rwkgl",
        "Africa/Kinshasa" => "cdfih",
        "Africa/Lagos" => "nglos",
        "Africa/Libreville" => "galbv",
        "Africa/Lome" => "tglfw",
        "Africa/Luanda" => "aolad",
        "Africa/Lubumbashi" => "cdfbm",
        "Africa/Lusaka" => "zmlun",
        "Africa/Malabo" => "gqssg",
        "Africa/Maputo" => "mzmpm",
        "Africa/Maseru" => "lsmsu",
        "Africa/Mbabane" => "szqmn",
        "Africa/Mogadishu" => "somgq",
        "Africa/Monrovia" => "lrmlw",
        "Africa/Nairobi" => "kenbo",
        "Africa/Ndjamena" => "tdndj",
        "Africa/Niamey" => "nenim",
        "Africa/Nouakchott" => "mrnkc",
        "Africa/Ouagadougou" => "bfoua",
        "Africa/Porto-Novo" => "bjptn",
        "Africa/Sao_Tome" => "sttms",
        "Africa/Timbuktu" => "mlbko",
        "Africa/Tripoli" => "lytip",
        "Africa/Tunis" => "tntun",
        "Africa/Windhoek" => "nawdh",
        "America/Adak" => "usadk",
        "America/Anchorage" => "usanc",
        "America/Anguilla" => "aiaxa",
        "America/Antigua" => "aganu",
        "America/Araguaina" => "braux",
        "America/Argentina/Buenos_Aires" => "arbue",
        "America/Argentina/Catamarca" => "arctc",
        "America/Argentina/ComodRivadavia" => "arctc",
        "America/Argentina/Cordoba" => "arcor",
        "America/Argentina/Jujuy" => "arjuj",
        "America/Argentina/La_Rioja" => "arirj",
        "America/Argentina/Mendoza" => "armdz",
        "America/Argentina/Rio_Gallegos" => "arrgl",
        "America/Argentina/Salta" => "arsla",
        "America/Argentina/San_Juan" => "aruaq",
        "America/Argentina/San_Luis" => "arluq",
        "America/Argentina/Tucuman" => "artuc",
        "America/Argentina/Ushuaia" => "arush",
        "America/Aruba" => "awaua",
        "America/Asuncion" => "pyasu",
        "America/Atikokan" => "cayzs",
        "America/Atka" => "usadk",
        "America/Bahia" => "brssa",
        "America/Bahia_Banderas" => "mxpvr",
        "America/Barbados" => "bbbgi",
        "America/Belem" => "brbel",
        "America/Belize" => "bzbze",
        "America/Blanc-Sablon" => "caybx",
        "America/Boa_Vista" => "brbvb",
        "America/Bogota" => "cobog",
        "America/Boise" => "usboi",
        "America/Buenos_Aires" => "arbue",
        "America/Cambridge_Bay" => "caycb",
        "America/Campo_Grande" => "brcgr",
        "America/Cancun" => "mxcun",
        "America/Caracas" => "veccs",
        "America/Catamarca" => "arctc",
        "America/Cayenne" => "gfcay",
        "America/Cayman" => "kygec",
        "America/Chicago" => "uschi",
        "America/Chihuahua" => "mxchi",
        "America/Ciudad_Juarez" => "mxcjs",
        "America/Coral_Harbour" => "cayzs",
        "America/Cordoba" => "arcor",
        "America/Costa_Rica" => "crsjo",
        "America/Creston" => "cacfq",
        "America/Cuiaba" => "brcgb",
        "America/Curacao" => "ancur",
        "America/Danmarkshavn" => "gldkshvn",
        "America/Dawson" => "cayda",
        "America/Dawson_Creek" => "caydq",
        "America/Denver" => "usden",
        "America/Detroit" => "usdet",
        "America/Dominica" => "dmdom",
        "America/Edmonton" => "caedm",
        "America/Eirunepe" => "brern",
        "America/El_Salvador" => "svsal",
        "America/Ensenada" => "mxtij",
        "America/Fort_Nelson" => "cafne",
        "America/Fort_Wayne" => "usind",
        "America/Fortaleza" => "brfor",
        "America/Glace_Bay" => "caglb",
        "America/Godthab" => "glgoh",
        "America/Goose_Bay" => "cagoo",
        "America/Grand_Turk" => "tcgdt",
        "America/Grenada" => "gdgnd",
        "America/Guadeloupe" => "gpbbr",
        "America/Guatemala" => "gtgua",
        "America/Guayaquil" => "ecgye",
        "America/Guyana" => "gygeo",
        "America/Halifax" => "cahal",
        "America/Havana" => "cuhav",
        "America/Hermosillo" => "mxhmo",
        "America/Indiana/Indianapolis" => "usind",
        "America/Indiana/Knox" => "usknx",
        "America/Indiana/Marengo" => "usaeg",
        "America/Indiana/Petersburg" => "uswsq",
        "America/Indiana/Tell_City" => "ustel",
        "America/Indiana/Vevay" => "usinvev",
        "America/Indiana/Vincennes" => "usoea",
        "America/Indiana/Winamac" => "uswlz",
        "America/Indianapolis" => "usind",
        "America/Inuvik" => "cayev",
        "America/Iqaluit" => "caiql",
        "America/Jamaica" => "jmkin",
        "America/Jujuy" => "arjuj",
        "America/Juneau" => "usjnu",
        "America/Kentucky/Louisville" => "uslui",
        "America/Kentucky/Monticello" => "usmoc",
        "America/Knox_IN" => "usknx",
        "America/Kralendijk" => "bqkra",
        "America/La_Paz" => "bolpb",
        "America/Lima" => "pelim",
        "America/Los_Angeles" => "uslax",
        "America/Louisville" => "uslui",
        "America/Lower_Princes" => "sxphi",
        "America/Maceio" => "brmcz",
        "America/Managua" => "nimga",
        "America/Manaus" => "brmao",
        "America/Marigot" => "gpmsb",
        "America/Martinique" => "mqfdf",
        "America/Matamoros" => "mxmam",
        "America/Mazatlan" => "mxmzt",
        "America/Mendoza" => "armdz",
        "America/Menominee" => "usmnm",
        "America/Merida" => "mxmid",
        "America/Metlakatla" => "usmtm",
        "America/Mexico_City" => "mxmex",
        "America/Miquelon" => "pmmqc",
        "America/Moncton" => "camon",
        "America/Monterrey" => "mxmty",
        "America/Montevideo" => "uymvd",
        "America/Montreal" => "cator",
        "America/Montserrat" => "msmni",
        "America/Nassau" => "bsnas",
        "America/New_York" => "usnyc",
        "America/Nipigon" => "cator",
        "America/Nome" => "usome",
        "America/Noronha" => "brfen",
        "America/North_Dakota/Beulah" => "usxul",
        "America/North_Dakota/Center" => "usndcnt",
        "America/North_Dakota/New_Salem" => "usndnsl",
        "America/Nuuk" => "glgoh",
        "America/Ojinaga" => "mxoji",
        "America/Panama" => "papty",
        "America/Pangnirtung" => "caiql",
        "America/Paramaribo" => "srpbm",
        "America/Phoenix" => "usphx",
        "America/Port-au-Prince" => "htpap",
        "America/Port_of_Spain" => "ttpos",
        "America/Porto_Acre" => "brrbr",
        "America/Porto_Velho" => "brpvh",
        "America/Puerto_Rico" => "prsju",
        "America/Punta_Arenas" => "clpuq",
        "America/Rainy_River" => "cawnp",
        "America/Rankin_Inlet" => "cayek",
        "America/Recife" => "brrec",
        "America/Regina" => "careg",
        "America/Resolute" => "careb",
        "America/Rio_Branco" => "brrbr",
        "America/Rosario" => "arcor",
        "America/Santa_Isabel" => "mxtij",
        "America/Santarem" => "brstm",
        "America/Santiago" => "clscl",
        "America/Santo_Domingo" => "dosdq",
        "America/Sao_Paulo" => "brsao",
        "America/Scoresbysund" => "globy",
        "America/Shiprock" => "usden",
        "America/Sitka" => "ussit",
        "America/St_Barthelemy" => "gpsbh",
        "America/St_Johns" => "casjf",
        "America/St_Kitts" => "knbas",
        "America/St_Lucia" => "lccas",
        "America/St_Thomas" => "vistt",
        "America/St_Vincent" => "vcsvd",
        "America/Swift_Current" => "cayyn",
        "America/Tegucigalpa" => "hntgu",
        "America/Thule" => "glthu",
        "America/Thunder_Bay" => "cator",
        "America/Tijuana" => "mxtij",
        "America/Toronto" => "cator",
        "America/Tortola" => "vgtov",
        "America/Vancouver" => "cavan",
        "America/Virgin" => "vistt",
        "America/Whitehorse" => "cayxy",
        "America/Winnipeg" => "cawnp",
        "America/Yakutat" => "usyak",
        "America/Yellowknife" => "caedm",
        "Antarctica/Casey" => "aqcas",
        "Antarctica/Davis" => "aqdav",
        "Antarctica/DumontDUrville" => "aqddu",
        "Antarctica/Macquarie" => "aumqi",
        "Antarctica/Mawson" => "aqmaw",
        "Antarctica/McMurdo" => "aqmcm",
        "Antarctica/Palmer" => "aqplm",
        "Antarctica/Rothera" => "aqrot",
        "Antarctica/South_Pole" => "nzakl",
        "Antarctica/Syowa" => "aqsyw",
        "Antarctica/Troll" => "aqtrl",
        "Antarctica/Vostok" => "aqvos",
        "Arctic/Longyearbyen" => "sjlyr",
        "Asia/Aden" => "yeade",
        "Asia/Almaty" => "kzala",
        "Asia/Amman" => "joamm",
        "Asia/Anadyr" => "rudyr",
        "Asia/Aqtau" => "kzaau",
        "Asia/Aqtobe" => "kzakx",
        "Asia/Ashgabat" => "tmasb",
        "Asia/Ashkhabad" => "tmasb",
        "Asia/Atyrau" => "kzguw",
        "Asia/Baghdad" => "iqbgw",
        "Asia/Bahrain" => "bhbah",
        "Asia/Baku" => "azbak",
        "Asia/Bangkok" => "thbkk",
        "Asia/Barnaul" => "rubax",
        "Asia/Beirut" => "lbbey",
        "Asia/Bishkek" => "kgfru",
        "Asia/Brunei" => "bnbwn",
        "Asia/Calcutta" => "inccu",
        "Asia/Chita" => "ruchita",
        "Asia/Choibalsan" => "mncoq",
        "Asia/Chongqing" => "cnsha",
        "Asia/Chungking" => "cnsha",
        "Asia/Colombo" => "lkcmb",
        "Asia/Dacca" => "bddac",
        "Asia/Damascus" => "sydam",
        "Asia/Dhaka" => "bddac",
        "Asia/Dili" => "tldil",
        "Asia/Dubai" => "aedxb",
        "Asia/Dushanbe" => "tjdyu",
        "Asia/Famagusta" => "cyfmg",
        "Asia/Gaza" => "gazastrp",
        "Asia/Harbin" => "cnsha",
        "Asia/Hebron" => "hebron",
        "Asia/Ho_Chi_Minh" => "vnsgn",
        "Asia/Hong_Kong" => "hkhkg",
        "Asia/Hovd" => "mnhvd",
        "Asia/Irkutsk" => "ruikt",
        "Asia/Istanbul" => "trist",
        "Asia/Jakarta" => "idjkt",
        "Asia/Jayapura" => "iddjj",
        "Asia/Jerusalem" => "jeruslm",
        "Asia/Kabul" => "afkbl",
        "Asia/Kamchatka" => "rupkc",
        "Asia/Karachi" => "pkkhi",
        "Asia/Kashgar" => "cnurc",
        "Asia/Kathmandu" => "npktm",
        "Asia/Katmandu" => "npktm",
        "Asia/Khandyga" => "rukhndg",
        "Asia/Kolkata" => "inccu",
        "Asia/Krasnoyarsk" => "rukra",
        "Asia/Kuala_Lumpur" => "mykul",
        "Asia/Kuching" => "mykch",
        "Asia/Kuwait" => "kwkwi",
        "Asia/Macao" => "momfm",
        "Asia/Macau" => "momfm",
        "Asia/Magadan" => "rugdx",
        "Asia/Makassar" => "idmak",
        "Asia/Manila" => "phmnl",
        "Asia/Muscat" => "ommct",
        "Asia/Nicosia" => "cynic",
        "Asia/Novokuznetsk" => "runoz",
        "Asia/Novosibirsk" => "ruovb",
        "Asia/Omsk" => "ruoms",
        "Asia/Oral" => "kzura",
        "Asia/Phnom_Penh" => "khpnh",
        "Asia/Pontianak" => "idpnk",
        "Asia/Pyongyang" => "kpfnj",
        "Asia/Qatar" => "qadoh",
        "Asia/Qostanay" => "kzksn",
        "Asia/Qyzylorda" => "kzkzo",
        "Asia/Rangoon" => "mmrgn",
        "Asia/Riyadh" => "saruh",
        "Asia/Saigon" => "vnsgn",
        "Asia/Sakhalin" => "ruuus",
        "Asia/Samarkand" => "uzskd",
        "Asia/Seoul" => "krsel",
        "Asia/Shanghai" => "cnsha",
        "Asia/Singapore" => "sgsin",
        "Asia/Srednekolymsk" => "rusred",
        "Asia/Taipei" => "twtpe",
        "Asia/Tashkent" => "uztas",
        "Asia/Tbilisi" => "getbs",
        "Asia/Tehran" => "irthr",
        "Asia/Tel_Aviv" => "jeruslm",
        "Asia/Thimbu" => "btthi",
        "Asia/Thimphu" => "btthi",
        "Asia/Tokyo" => "jptyo",
        "Asia/Tomsk" => "rutof",
        "Asia/Ujung_Pandang" => "idmak",
        "Asia/Ulaanbaatar" => "mnuln",
        "Asia/Ulan_Bator" => "mnuln",
        "Asia/Urumqi" => "cnurc",
        "Asia/Ust-Nera" => "ruunera",
        "Asia/Vientiane" => "lavte",
        "Asia/Vladivostok" => "ruvvo",
        "Asia/Yakutsk" => "ruyks",
        "Asia/Yangon" => "mmrgn",
        "Asia/Yekaterinburg" => "ruyek",
        "Asia/Yerevan" => "amevn",
        "Atlantic/Azores" => "ptpdl",
        "Atlantic/Bermuda" => "bmbda",
        "Atlantic/Canary" => "eslpa",
        "Atlantic/Cape_Verde" => "cvrai",
        "Atlantic/Faeroe" => "fotho",
        "Atlantic/Faroe" => "fotho",
        "Atlantic/Jan_Mayen" => "sjlyr",
        "Atlantic/Madeira" => "ptfnc",
        "Atlantic/Reykjavik" => "isrey",
        "Atlantic/South_Georgia" => "gsgrv",
        "Atlantic/St_Helena" => "shshn",
        "Atlantic/Stanley" => "fkpsy",
        "Australia/ACT" => "ausyd",
        "Australia/Adelaide" => "auadl",
        "Australia/Brisbane" => "aubne",
        "Australia/Broken_Hill" => "aubhq",
        "Australia/Canberra" => "ausyd",
        "Australia/Currie" => "auhba",
        "Australia/Darwin" => "audrw",
        "Australia/Eucla" => "aueuc",
        "Australia/Hobart" => "auhba",
        "Australia/LHI" => "auldh",
        "Australia/Lindeman" => "auldc",
        "Australia/Lord_Howe" => "auldh",
        "Australia/Melbourne" => "aumel",
        "Australia/North" => "audrw",
        "Australia/NSW" => "ausyd",
        "Australia/Perth" => "auper",
        "Australia/Queensland" => "aubne",
        "Australia/South" => "auadl",
        "Australia/Sydney" => "ausyd",
        "Australia/Tasmania" => "auhba",
        "Australia/Victoria" => "aumel",
        "Australia/West" => "auper",
        "Australia/Yancowinna" => "aubhq",
        "Brazil/Acre" => "brrbr",
        "Brazil/DeNoronha" => "brfen",
        "Brazil/East" => "brsao",
        "Brazil/West" => "brmao",
        "Canada/Atlantic" => "cahal",
        "Canada/Central" => "cawnp",
        "Canada/East-Saskatchewan" => "careg",
        "Canada/Eastern" => "cator",
        "Canada/Mountain" => "caedm",
        "Canada/Newfoundland" => "casjf",
        "Canada/Pacific" => "cavan",
        "Canada/Saskatchewan" => "careg",
        "Canada/Yukon" => "cayxy",
        "Chile/Continental" => "clscl",
        "Chile/EasterIsland" => "clipc",
        CST6CDT => "cst6cdt",
        Cuba => "cuhav",
        Egypt => "egcai",
        Eire => "iedub",
        EST => "utcw05",
        EST5EDT => "est5edt",
        "Etc/GMT" => "gmt",
        "Etc/GMT+0" => "gmt",
        "Etc/GMT+1" => "utcw01",
        "Etc/GMT+10" => "utcw10",
        "Etc/GMT+11" => "utcw11",
        "Etc/GMT+12" => "utcw12",
        "Etc/GMT+2" => "utcw02",
        "Etc/GMT+3" => "utcw03",
        "Etc/GMT+4" => "utcw04",
        "Etc/GMT+5" => "utcw05",
        "Etc/GMT+6" => "utcw06",
        "Etc/GMT+7" => "utcw07",
        "Etc/GMT+8" => "utcw08",
        "Etc/GMT+9" => "utcw09",
        "Etc/GMT-0" => "gmt",
        "Etc/GMT-1" => "utce01",
        "Etc/GMT-10" => "utce10",
        "Etc/GMT-11" => "utce11",
        "Etc/GMT-12" => "utce12",
        "Etc/GMT-13" => "utce13",
        "Etc/GMT-14" => "utce14",
        "Etc/GMT-2" => "utce02",
        "Etc/GMT-3" => "utce03",
        "Etc/GMT-4" => "utce04",
        "Etc/GMT-5" => "utce05",
        "Etc/GMT-6" => "utce06",
        "Etc/GMT-7" => "utce07",
        "Etc/GMT-8" => "utce08",
        "Etc/GMT-9" => "utce09",
        "Etc/GMT0" => "gmt",
        "Etc/Greenwich" => "gmt",
        "Etc/UCT" => "utc",
        "Etc/Universal" => "utc",
        "Etc/Unknown" => "unk",
        "Etc/UTC" => "utc",
        "Etc/Zulu" => "utc",
        "Europe/Amsterdam" => "nlams",
        "Europe/Andorra" => "adalv",
        "Europe/Astrakhan" => "ruasf",
        "Europe/Athens" => "grath",
        "Europe/Belfast" => "gblon",
        "Europe/Belgrade" => "rsbeg",
        "Europe/Berlin" => "deber",
        "Europe/Bratislava" => "skbts",
        "Europe/Brussels" => "bebru",
        "Europe/Bucharest" => "robuh",
        "Europe/Budapest" => "hubud",
        "Europe/Busingen" => "debsngn",
        "Europe/Chisinau" => "mdkiv",
        "Europe/Copenhagen" => "dkcph",
        "Europe/Dublin" => "iedub",
        "Europe/Gibraltar" => "gigib",
        "Europe/Guernsey" => "gggci",
        "Europe/Helsinki" => "fihel",
        "Europe/Isle_of_Man" => "imdgs",
        "Europe/Istanbul" => "trist",
        "Europe/Jersey" => "jesth",
        "Europe/Kaliningrad" => "rukgd",
        "Europe/Kiev" => "uaiev",
        "Europe/Kirov" => "rukvx",
        "Europe/Kyiv" => "uaiev",
        "Europe/Lisbon" => "ptlis",
        "Europe/Ljubljana" => "silju",
        "Europe/London" => "gblon",
        "Europe/Luxembourg" => "lulux",
        "Europe/Madrid" => "esmad",
        "Europe/Malta" => "mtmla",
        "Europe/Mariehamn" => "fimhq",
        "Europe/Minsk" => "bymsq",
        "Europe/Monaco" => "mcmon",
        "Europe/Moscow" => "rumow",
        "Europe/Nicosia" => "cynic",
        "Europe/Oslo" => "noosl",
        "Europe/Paris" => "frpar",
        "Europe/Podgorica" => "metgd",
        "Europe/Prague" => "czprg",
        "Europe/Riga" => "lvrix",
        "Europe/Rome" => "itrom",
        "Europe/Samara" => "rukuf",
        "Europe/San_Marino" => "smsai",
        "Europe/Sarajevo" => "basjj",
        "Europe/Saratov" => "rurtw",
        "Europe/Simferopol" => "uasip",
        "Europe/Skopje" => "mkskp",
        "Europe/Sofia" => "bgsof",
        "Europe/Stockholm" => "sesto",
        "Europe/Tallinn" => "eetll",
        "Europe/Tirane" => "altia",
        "Europe/Tiraspol" => "mdkiv",
        "Europe/Ulyanovsk" => "ruuly",
        "Europe/Uzhgorod" => "uaiev",
        "Europe/Vaduz" => "livdz",
        "Europe/Vatican" => "vavat",
        "Europe/Vienna" => "atvie",
        "Europe/Vilnius" => "ltvno",
        "Europe/Volgograd" => "ruvog",
        "Europe/Warsaw" => "plwaw",
        "Europe/Zagreb" => "hrzag",
        "Europe/Zaporozhye" => "uaiev",
        "Europe/Zurich" => "chzrh",
        GB => "gblon",
        "GB-Eire" => "gblon",
        GMT => "gmt",
        "GMT+0" => "gmt",
        "GMT-0" => "gmt",
        GMT0 => "gmt",
        Greenwich => "gmt",
        Hongkong => "hkhkg",
        HST => "utcw10",
        Iceland => "isrey",
        "Indian/Antananarivo" => "mgtnr",
        "Indian/Chagos" => "iodga",
        "Indian/Christmas" => "cxxch",
        "Indian/Cocos" => "cccck",
        "Indian/Comoro" => "kmyva",
        "Indian/Kerguelen" => "tfpfr",
        "Indian/Mahe" => "scmaw",
        "Indian/Maldives" => "mvmle",
        "Indian/Mauritius" => "muplu",
        "Indian/Mayotte" => "ytmam",
        "Indian/Reunion" => "rereu",
        Iran => "irthr",
        Israel => "jeruslm",
        Jamaica => "jmkin",
        Japan => "jptyo",
        Kwajalein => "mhkwa",
        Libya => "lytip",
        "Mexico/BajaNorte" => "mxtij",
        "Mexico/BajaSur" => "mxmzt",
        "Mexico/General" => "mxmex",
        MST => "utcw07",
        MST7MDT => "mst7mdt",
        Navajo => "usden",
        NZ => "nzakl",
        "NZ-CHAT" => "nzcht",
        "Pacific/Apia" => "wsapw",
        "Pacific/Auckland" => "nzakl",
        "Pacific/Bougainville" => "pgraw",
        "Pacific/Chatham" => "nzcht",
        "Pacific/Chuuk" => "fmtkk",
        "Pacific/Easter" => "clipc",
        "Pacific/Efate" => "vuvli",
        "Pacific/Enderbury" => "kipho",
        "Pacific/Fakaofo" => "tkfko",
        "Pacific/Fiji" => "fjsuv",
        "Pacific/Funafuti" => "tvfun",
        "Pacific/Galapagos" => "ecgps",
        "Pacific/Gambier" => "pfgmr",
        "Pacific/Guadalcanal" => "sbhir",
        "Pacific/Guam" => "gugum",
        "Pacific/Honolulu" => "ushnl",
        "Pacific/Johnston" => "ushnl",
        "Pacific/Kanton" => "kipho",
        "Pacific/Kiritimati" => "kicxi",
        "Pacific/Kosrae" => "fmksa",
        "Pacific/Kwajalein" => "mhkwa",
        "Pacific/Majuro" => "mhmaj",
        "Pacific/Marquesas" => "pfnhv",
        "Pacific/Midway" => "ummdy",
        "Pacific/Nauru" => "nrinu",
        "Pacific/Niue" => "nuiue",
        "Pacific/Norfolk" => "nfnlk",
        "Pacific/Noumea" => "ncnou",
        "Pacific/Pago_Pago" => "asppg",
        "Pacific/Palau" => "pwror",
        "Pacific/Pitcairn" => "pnpcn",
        "Pacific/Pohnpei" => "fmpni",
        "Pacific/Ponape" => "fmpni",
        "Pacific/Port_Moresby" => "pgpom",
        "Pacific/Rarotonga" => "ckrar",
        "Pacific/Saipan" => "mpspn",
        "Pacific/Samoa" => "asppg",
        "Pacific/Tahiti" => "pfppt",
        "Pacific/Tarawa" => "kitrw",
        "Pacific/Tongatapu" => "totbu",
        "Pacific/Truk" => "fmtkk",
        "Pacific/Wake" => "umawk",
        "Pacific/Wallis" => "wfmau",
        "Pacific/Yap" => "fmtkk",
        Poland => "plwaw",
        Portugal => "ptlis",
        PRC => "cnsha",
        PST8PDT => "pst8pdt",
        ROC => "twtpe",
        ROK => "krsel",
        Singapore => "sgsin",
        Turkey => "trist",
        UCT => "utc",
        Universal => "utc",
        "US/Alaska" => "usanc",
        "US/Aleutian" => "usadk",
        "US/Arizona" => "usphx",
        "US/Central" => "uschi",
        "US/East-Indiana" => "usind",
        "US/Eastern" => "usnyc",
        "US/Hawaii" => "ushnl",
        "US/Indiana-Starke" => "usknx",
        "US/Michigan" => "usdet",
        "US/Mountain" => "usden",
        "US/Pacific" => "uslax",
        "US/Pacific-New" => "uslax",
        "US/Samoa" => "asppg",
        UTC => "utc",
        "W-SU" => "rumow",
        Zulu => "utc",
    };
};

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

# NOTE: Locale::Unicode::Boolean class
package Locale::Unicode::Boolean;
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
    $true  = do{ bless( \( my $dummy = 1 ) => 'Locale::Unicode::Boolean' ) };
    $false = do{ bless( \( my $dummy = 0 ) => 'Locale::Unicode::Boolean' ) };
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

sub is_bool($) { UNIVERSAL::isa( $_[0], 'Locale::Unicode::Boolean' ) }

sub is_true($) { $_[0] && UNIVERSAL::isa( $_[0], 'Locale::Unicode::Boolean' ) }

sub is_false($) { !$_[0] && UNIVERSAL::isa( $_[0], 'Locale::Unicode::Boolean' ) }

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

# NOTE: Locale::Unicode::Exception class
package Locale::Unicode::Exception;
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
        elsif( ref( $_[0] ) && $_[0]->isa( 'Locale::Unicode::Exception' ) )
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
    # NOTE: Locale::Unicode::NullObject class
    package
        Locale::Unicode::NullObject;
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

Locale::Unicode - Unicode Locale Identifier compliant with BCP47 and CLDR

=head1 SYNOPSIS

    use Locale::Unicode;
    my $locale = Locale::Unicode->new( 'ja-Kana-t-it' ) ||
        die( Locale::Unicode->error );
    say $locale; # ja-Kana-t-it

    # Some undefined locale in Cyrillic script
    my $locale = Locale::Unicode->new( 'und-Cyrl' );
    $locale->transform( 'und-latn' );
    $locale->mechanism( 'ungegn-2007' );
    say $locale; # und-Cyrl-t-und-latn-m0-ungegn-2007
    # A locale in Cyrillic, transformed from Latin, according to a UNGEGN specification dated 2007.

This API detects when methods are called in object context and return the current object:

    $locale->translation( 'my-software' )->tz( 'jptyo' )->ca( 'japanese' )

In Scalar or in list context, the value returned is the last value set.

    $locale->translation( 'my-software' ); # my-software
    $locale->translation( 'other-software' ); # other-software

=head1 VERSION

    v0.1.8

=head1 DESCRIPTION

This module implements the L<Unicode LDML (Locale Data Markup Language) extensions|https://unicode.org/reports/tr35/#u_Extension>

It does not enforce the standard, and is merely an API to construct, access and modify locales. It is your responsibility to set the right values.

For your convenience, summary of key elements of the standard can be found in this documentation.

It is lightweight and fast with no dependency outside of L<Scalar::Util> and L<Want>. It requires perl C<v5.10> minimum to operate.

The object stringifies, and once its string value is computed, it is cached and re-used until it is changed. Thus repetitive call to L<as_string|/as_string> or to stringification does not incur any speed penalty by recomputing what has not changed.

=head1 CONSTRUCTOR

=head2 new

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

This takes a C<locale> as compliant with the BCP47 standard, and an optional hash or hash reference of options and this returns a new object.

The C<locale> provided is parsed and its components can be accessed and modified using all the methods of this class API.

If an hash or hash reference of options are provided, it will be used to set or modify the components from the C<locale> provided.

If an error occurs, an L<exception object|Locale::Unicode::Exception> is set and C<undef> is returned in scalar context, or an empty list in list context. The L<exception object|Locale::Unicode::Exception> can then be retrieved using L<error|/error>, such as:

    my $locale = Locale::Unicode->new( $somthing_bad ) ||
        die( Locale::Unicode->error );

=head1 METHODS

All the methods below are context sensitive.

If they are called in an object context, they will return the current C<Locale::Unicode> object for chaining, otherwise, they will return the current value. And if that value is C<undef>, it will return C<undef> in scalar context, but an empty list in list context.

Also, if an error occurs, it will set an L<exception object|Locale::Unicode::Exception> and returns C<undef> in scalar context, or an empty list in list context.

=head2 apply

    my $hash_reference = Locale::Unicode->parse( 'ja-Kana-t-it' );
    $locale->apply( $hash_reference );

Provided with an hash reference of key-value pairs, and this will set each corresponding method with the associated value.

If a property provided has no corresponding method, it emits a warning if L<warnings are enabled|warnings/"warnings::enabled()">

It returns the current object upon success, or sets an L<error object|Module::Generic::Exception> upon error and returns C<undef> in scalar context, or an empty list in list context.

=head2 as_string

Returns the Locale object as a string, based on its latest attributes set.

The string value returned is computed only once and further call to C<as_string> returns a cached value unless changes were made to the Locale attributes.

Boolean values are expressed as C<true> for tue values and C<false> for false values. However, if a value is true for a given C<locale> component, it is not explicitly stated by default, since the LDML specifications indicate, it is true implicitly. If, however, you want the true boolean value to be displayed nevertheless, make sure to set the global variable C<$EXPLICIT_BOOLEAN> to a true value.

For example:

    my $locale = Locale::Unicode->new( 'ko-Kore-KR', {
        # You can also use 1 or 'yes' as per the specifications
        colNumeric => 'true',
        colCaseFirst => 'upper'
    });
    say $locale; # ko-Kore-KR-u-kf-upper-kn

    local $EXPLICIT_BOOLEAN = 1;
    my $locale = Locale::Unicode->new( 'ko-Kore-KR', {
        # You can also use 1 or 'yes' as per the specifications
        colNumeric => 'true',
        colCaseFirst => 'upper'
    });
    say $locale; # ko-Kore-KR-u-kf-upper-kn-true

=head2 break_exclusion

    my $locale = Locale::Unicode->new( 'ja' );
    $locale->break_exclusion( 'hani-hira-kata' );
    # Now: ja-dx-hani-hira-kata

This is a Unicode Dictionary Break Exclusion Identifier that specifies scripts to be excluded from dictionary-based text break (for words and lines).

Sets or gets the Unicode extension C<dx>

See also L<dx|/dx>

=head2 ca

This is an alias for L</calendar>

=head2 calendar

    my $locale = Locale::Unicode->new( 'th' );
    $locale->calendar( 'buddhist' );
    # or:
    # $locale->ca( 'buddhist' );
    # Now: th-u-ca-buddhist
    # which is the Thai with Buddist calendar

Sets or gets the Unicode extension C<ca>, which is a L<calendar identifier|https://unicode.org/reports/tr35/#UnicodeCalendarIdentifier>.

See the section on L</"BCP47 EXTENSIONS"> for the proper values.

=head2 cf

This is an alias for L</cu_format>

=head2 clone

Clones the current object and returns the newly instantiated copy.

If an error occurs, this sets an L<exception object|Locale::Unicode::Exception> and returns C<undef> in scalar context, and an empty list in list context.

=head2 co

    my $locale = Locale::Unicode->new( 'de' );
    $locale->collation( 'phonebk' );
    $locale->ka( 'shifted' );
    # Now: de-u-co-phonebk-ka-shifted

This is a Unicode collation identifier that specifies a type of collation (sort order).

This is an alias for L</collation>

=head2 colAlternate

    my $locale = Locale::Unicode->new( 'de' );
    $locale->collation( 'phonebk' );
    $locale->ka( 'shifted' );
    # Now: de-u-co-phonebk-ka-shifted

    $locale->collation( 'noignore' );
    # or similarly:
    $locale->collation( 'non-ignorable' );

Sets alternate handling for variable weights.

Sets or gets the Unicode extension C<ka>

See L</"Collation Options"> for more information.

=head2 colBackwards

    $locale->colBackwards(1); # true
    # Now: kb-true
    $locale->colBackwards(0); # false
    # Now: kb-false

Sets collation boolean value for backward collation weight.

Sets or gets the Unicode extension C<kb>

See L</"Collation Options"> for more information.

=head2 colCaseFirst

    $locale->colCaseFirst( undef ); # false (default)
    $locale->colCaseFirst( 'upper' );
    $locale->colCaseFirst( 'lower' );

Sets or gets the Unicode extension C<kf>

See L</"Collation Options"> for more information.

=head2 colCaseLevel

    $locale->colCaseLevel(1); # true
    # Now: kc-true
    $locale->colCaseLevel(0); # false
    # Now: kc-false

Sets collation boolean value for case level.

Sets or gets the Unicode extension C<kc>

See L</"Collation Options"> for more information.

=head2 colHiraganaQuaternary

    $locale->colHiraganaQuaternary(1); # true
    # Now: kh-true
    $locale->colHiraganaQuaternary(0); # false
    # Now: kh-false

Sets collation parameter key for special Hiragana handling.

Sets or gets the Unicode extension C<kh>

See L</"Collation Options"> for more information.

=head2 collation

    my $locale = Locale::Unicode->new( 'fr' );
    $locale->collation( 'emoji' );
    # Now: fr-u-co-emoji

    my $locale = Locale::Unicode->new( 'de' );
    $locale->collation( 'phonebk' );
    # Now: de-u-co-phonebk
    # which is: German using Phonebook sorting

Sets or gets the Unicode extension C<co>

This specifies a type of collation (sort order).

See L</"Unicode extensions"> for possible values and more information on standard.

See also L</"Collation Options"> for more on collation options.

=head2 colNormalisation

This is an alias for L<colNormalization|/colNormalization>

=head2 colNormalization

    $locale->colNormalization(1); # true
    # Now: kk-true
    $locale->colNormalization(0); # false
    # Now: kk-false

Sets collation parameter key for normalisation.

Sets or gets the Unicode extension C<kk>

See L</"Collation Options"> for more information.

=head2 colNumeric

    $locale->colNumeric(1); # true
    # Now: kn-true
    $locale->colNumeric(0); # false
    # Now: kn-false

Sets collation parameter key for numeric handling.

Sets or gets the Unicode extension C<kn>

See L</"Collation Options"> for more information.

=head2 colReorder

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

Sets or gets the Unicode extension C<kr>

See L</"Collation Options"> for more information.

=head2 shiftedGroup

This is an alias for L</colValue>

=head2 colStrength

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

Sets or gets the Unicode extension C<ks>

See L</"Collation Options"> for more information.

=head2 colValue

    $locale->colValue( 'currency' );
    $locale->colValue( 'punct' );
    $locale->colValue( 'space' );
    $locale->colValue( 'symbol' );

Sets the collation value for the last reordering group to be affected by L<ka-shifted|/colAlternate>.

Sets or gets the Unicode extension C<kv>

See L</"Collation Options"> for more information.

=head2 colVariableTop

Sets the string value for the variable top.

Sets or gets the Unicode extension C<vt>

See L</"Collation Options"> for more information.

=head2 core

    my $locale = Locale::Unicode->new( 'ja-Kana-JP-t-de-AT-t0-und-u-ca-japanese-tz-jptyo' );
    say $locale->core; # ja-Kana-JP

This is a read-only method.

It returns the core part of the C<locale>, which is composed of a 2 to 3-characters code, some optional C<script> and C<country> or C<region> code.

=head2 country_code

    my $locale = Locale::Unicode->new( 'en' );
    $locale->country_code( 'US' );
    # Now: en-US
    $locale->country_code( 'GB' );
    # Now: en-GB

Sets or gets the country code part of the C<locale>.

A country code should be an ISO 3166 2-letters code, but keep in mind that the LDML (Locale Data Markup Language) accepts old data to ensure stability.

=head2 cu

    my $locale = Locale::Unicode->new( 'ja' );
    $locale->cu( 'jpy' );
    # Now: ja-u-cu-jpy
    # which is the Japanese Yens

This is a Unicode currency identifier that specifies a type of currency (ISO 4217 code.

This is an alias for L</currency>

=head2 cu_format

    # Using minus sign symbol for negative numbers
    $locale->cf( 'standard' );
    # Using parentheses for negative numbers
    $locale->cf( 'account' );

This is a currency format identifier such as C<standard> or C<account>

Sets or gets the Unicode extension C<cf>

See the section on L</"BCP47 EXTENSIONS"> for the proper values.

=head2 currency

    my $locale = Locale::Unicode->new( 'ja' );
    $locale->currency( 'jpy' );
    # or
    # $locale->cu( 'jpy' );
    # Now: ja-u-cu-jpy
    # which is the Japanese yens

Sets or gets the Unicode extension C<cu>

This specifies a type of ISO4217 currency code.

=head2 d0

This is an alias for L</destination>

=head2 dest

This is an alias for L</destination>

=head2 destination

Sets or gets the Transformation extension C<d0> for destination.

See the section on L</"Transform extensions"> for more information.

=head2 dx

This is an alias for L</break_exclusion>

=head2 em

This is an alias for L</emoji>

=head2 emoji

This is a Unicode Emoji Presentation Style Identifier that specifies a request for the preferred emoji presentation style.

Sets or gets the Unicode extension C<em>.

=head2 error

Used as a mutator, this sets and L<exception object|Locale::Unicode::Exception> and returns an C<Locale::Unicode::NullObject> in object context (such as when chaining), or C<undef> in scalar context, or an empty list in list context.

The C<Locale::Unicode::NullObject> class prevents the perl error of C<Can't call method "%s" on an undefined value> (see L<perldiag>). Upon the last method chained, C<undef> is returned in scalar context or an empty list in list context.

For example:

    my $locale =Locale::Unicode->new( 'ja' );
    $locale->translation( 'my-software' )->transform_locale( $bad_value )->tz( 'jptyo' ) ||
        die( $locale->error );

In this example, C<jptyo> will never be set, because C<transform_locale> triggered an exception that returned an C<Locale::Unicode::NullObject> object catching all further method calls, but eventually we get the error and die.

=head2 false

This is read-only and returns a L<Locale::Unicode::Boolean> object representing a false value.

=head2 fw

This is an alias for L</first_day>

=head2 first_day

This is a Unicode First Day Identifier that specifies the preferred first day of the week for calendar display.

Sets or gets the Unicode extension C<fw>.

Its values are C<sun>, C<mon>, etc... C<sat>

=head2 h0

This is an alias for L</hybrid>

=head2 hc

This is an alias for L</hour_cycle>

=head2 hour_cycle

This is a Unicode Hour Cycle Identifier that specifies the preferred time cycle.

Sets or gets the Unicode extension C<hc>.

=head2 hybrid

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

Those are Hybrid Locale Identifiers indicating that the C<t> value is a language that is mixed into the main language tag to form a hybrid.

Sets or gets the Transformation extension C<h0>.

See the section on L</"Transform extensions"> for more information.

=head2 i0

This is an alias for L</input>

=head2 k0

This is an alias for L</keyboard>

=head2 input

    my $locale = Locale::Unicode->new( 'zh' );
    $locale->input( 'pinyin' );
    # Now: zh-t-i0-pinyin

This is an Input Method Engine transformation.

Sets or gets the Transformation extension C<i0>.

See the section on L</"Transform extensions"> for more information.

=head2 ka

This is an alias for L</colAlternate>

=head2 kb

This is an alias for L</colBackwards>

=head2 kc

This is an alias for L</colCaseLevel>

=head2 keyboard

    my $locale = Locale::Unicode->new( 'en' );
    $locale->keyboard( 'dvorak' );
    # Now: en-t-k0-dvorak

This is a keyboard transformation, such as used by client-side virtual keyboards.

Sets or gets the Transformation extension C<k0>.

See the section on L</"Transform extensions"> for more information.

=head2 kf

This is an alias for L</colCaseFirst>

=head2 kh

This is an alias for L</colHiraganaQuaternary>

=head2 kk

This is an alias for L</colNormalization>

=head2 kn

This is an alias for L</colNumeric>

=head2 kr

This is an alias for L</colReorder>

=head2 ks

This is an alias for L</colStrength>

=head2 kv

This is an alias for L</colValue>

=head2 lang

    # current value: fr-FR
    $obj->lang( 'de' );
    # Now: de-FR

Sets or gets the C<locale> part of this Local object.

See also L</locale>

=head2 language

This is an alias for L<lang|/lang>

=head2 lb

This is an alias for L</line_break>

=head2 line_break

This is a Unicode Line Break Style Identifier that specifies a preferred line break style corresponding to the CSS level 3 line-break option.

Sets or gets the Unicode extension C<lb>.

=head2 line_break_word

This is a Unicode Line Break Word Identifier that specifies a preferred line break word handling behavior corresponding to the CSS level 3 word-break option

Sets or gets the Unicode extension C<lw>.

=head2 locale

This is an alias for L</lang>

=head2 locale3

    my $locale = Locale::Unicode->new( 'jpn' );
    $locale->script( 'Kana' );
    # Now: jpn-Kana

Sets or gets the L<3-letter ISO 639-2 code|https://www.loc.gov/standards/iso639-2/php/code_list.php/>. Keep in mind, however, that to ensure stability, the LDML (Locale Data Markup Language) also uses old data.

=head2 lw

This is an alias for L</line_break_word>

=head2 m0

This is an alias for L</mechanism>

=head2 measurement

This is a Unicode Measurement System Identifier that specifies a preferred measurement system.

Sets or gets the Unicode extension C<ms>.

=head2 mechanism

    my $locale = Locale::Unicode->new( 'und-Latn' );
    $locale->transform( 'ru' );
    $locale->mechanism( 'ungegn-2007' );
    # Now: und-Latn-t-ru-m0-ungegn-2007
    # representing a transformation from United Nations Group of Experts on 
    # Geographical Names in 2007

This is a transformation mechanism referencing an authority or rules for a type of transformation.

Sets or gets the Transformation extension C<m0>.

See the section on L</"Transform extensions"> for more information.

=head2 ms

This is an alias for L</measurement>

=head2 mu

This is an alias for L</unit>

=head2 nu

This is an alias for L</number>

=head2 number

This is a Unicode Number System Identifier that specifies a type of number system.

Sets or gets the Unicode extension C<nu>.

=head2 private

    my $locale = Locale::Unicode->new( 'ja-JP' );
    $locale->private( 'something-else' );
    # Now: ja-JP-x-something-else

This serves to set or get the value for a private subtag.

=head2 region

    # current value: fr-FR
    $locale->region( '150' );
    # Now: fr-150

Sets or gets the C<region> part of a Unicode locale.

This is a world region represented by a 3-digits code.

Below are the known regions:

=over 4

=item * 001

World

=item * 002

Africa

=item * 003

North America

=item * 005

South America

=item * 009

Oceania

=item * 011

Western Africa

=item * 013

Central America

=item * 014

Eastern Africa

=item * 015

Northern Africa

=item * 017

Middle Africa

=item * 018

Southern Africa

=item * 019

Americas

=item * 021

Northern America

=item * 029

Caribbean

=item * 030

Eastern Asia

=item * 034

Southern Asia

=item * 035

Southeast Asia

=item * 039

Southern Europe

=item * 053

Australasia

=item * 054

Melanesia

=item * 057

Micronesian Region

=item * 061

Polynesia

=item * 142

Asia

=item * 143

Central Asia

=item * 145

Western Asia

=item * 150

Europe

=item * 151

Eastern Europe

=item * 154

Northern Europe

=item * 155

Western Europe

=item * 202

Sub-Saharan Africa

=item * 419

Latin America

=back

=head2 region_override

    my $locale = Locale::Unicode->new( 'en-GB' );
    $locale->region_override( 'uszzzz' );
    # Now: en-GB-u-rg-uszzzz
    # which is a locale for British English but with region-specific defaults set to US.

This is a Unicode Region Override that specifies an alternate C<country code> or C<region> to use for obtaining certain region-specific default values.

Sets or gets the Unicode extension C<rg>.

=head2 reset

When provided with any argument, this will reset the cached value computed by L</as_string>

=head2 rg

This is an alias for L</region_override>

=head2 s0

This is an alias for L</source>

=head2 script

    # current value: zh-Hans
    $locale->script( 'Hant' );
    # Now: zh-Hant

Sets or gets the C<script> part of the Locale identifier.

=head2 sd

This is an alias for L</subdivision>

=head2 sentence_break

This is a Unicode Sentence Break Suppressions Identifier that specifies a set of data to be used for suppressing certain sentence breaks.

Sets or gets the Unicode extension C<ss>.

=head2 source

This is a transformation source for non-languages or scripts, such as fullwidth-halfwidth conversion.

Sets or gets the Transformation extension C<s0>.

See the section on L</"Transform extensions"> for more information.

=head2 ss

This is an alias for L</sentence_break>

=head2 subdivision

    my $locale = Locale::Unicode->new( 'gsw' );
    $locale->subdivision( 'chzh' );
    # or
    # $locale->sd( 'chzh' );
    # Now: gsw-u-sd-chzh

    my $locale = Locale::Unicode->new( 'en-US' );
    $locale->sd( 'usca' );
    # Now: en-US-u-sd-usca

This is a Unicode Subdivision Identifier that specifies a regional subdivision used for locale. This is typically the States in the U.S., or prefectures in France or Japan, or provinces in Canada.

Sets or gets the Unicode extension C<sd>.

Be careful of the rule in the standard. For example, C<en-CA-u-sd-gbsct> would be invalid because C<gb> in C<gbsct> does not match the region subtag C<CA>

=head2 t0

This is an alias for L</translation>

=head2 t_private

    my $locale = Locale::Unicode->new( 'ja' );
    $locale->transform( 'und' );
    $locale->t_private( 'medical' );
    # Now: ja-t-de-t0-und-x0-medical

This is a private transformation subtag.

Sets or gets the Transformation private subtag C<x0>.

=head2 time_zone

This is a Unicode Timezone Identifier that specifies a time zone.

Sets or gets the Unicode extension C<tz>.

=head2 timezone

This is an alias for L</time_zone>

=head2 transform

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

Sets or gets the Transformation extension C<t>.

This takes either a string representing a C<locale> or an L<Locale::Unicode> object.

If a string is provided, it will be converted to an L<Locale::Unicode> object.

The resulting value is passed to L<transform_locale|/transform_locale>

This method is convenient since you do not have to concern yourself whether the value you provide is an object, or not.

It returns the current object for chaining.

=head2 transform_locale

    my $locale = Locale::Unicode->new( 'ja' );
    my $locale2 = Locale::Unicode->new( 'it' );
    $locale->transform_locale( $locale2 );
    # Now: ja-t-it
    my $object = $locale->transform_locale;

Sets or gets a L<Locale::Unicode> object used to indicate the original locale subject to transformation.

This will trigger an L<exception|Locale::Unicode::Exception> if a value, other than C<Locale::Unicode> or an inheriting class object, is set.

See the section on L</"Transform extensions"> for more information.

=head2 translation

    my $locale = Locale::Unicode->new( 'ja' );
    $locale->transform( 'de' );
    $locale->translation( 'und' );
    # Now: ja-t-de-t0-und
    # Japanese translated from Germany by an undefined vendor

This is used to indicate content that has been machine translated, or a request for a particular type of machine translation of content.

Sets or gets the Transformation extension C<t0>.

See the section on L</"Transform extensions"> for more information.

=head2 true

This is read-only and returns a L<Locale::Unicode::Boolean> object representing a true value.

=head2 tz

This is an alias for L</time_zone>

=head2 unit

This is a Measurement Unit Preference Override that specifies an override for measurement unit preference.

Sets or gets the Unicode extension C<mu>.

=head2 va

This is an alias for L</variant>

=head2 variant

This is a Unicode Variant Identifier that specifies a special variant used for locales.

Sets or gets the Unicode extension C<va>.

=head2 vt

This is an alias for L</colVariableTop>

=head2 x0

This is an alias for L</t_private>

=head1 CLASS FUNCTIONS

=head2 matches

Provided with a BCP47 locale, and this returns an hash reference of its components if it matches the BCP47 regular expression, which can be accessed as global class variable C<$LOCALE_RE>.

If nothing matches, it returns an empty string in scalar context, or an empty list in list context.

If an error occurs, its sets an L<error object|Module::Generic::Exception> and returns C<undef> in scalar context, or an empty list in list context.

=head2 parse

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

Provided with a BCP47 locale, and an optional hash reference like the one returned by L<matches|/matches>, and this will return an hash reference with detailed broken down of the locale embedded information, as per the Unicode BCP47 standard.

=head2 tz_id2name

Provided with a CLDR timezone ID, such as C<jptyo> for C<Asia/Tokyo>, and this returns the IANA Olson name equivalent, which, in this case, would be C<Asia/Tokyo>

If an error occurs, its sets an L<error object|Module::Generic::Exception> and returns C<undef> in scalar context, or an empty list in list context.

=head2 tz_id2names

    my $ref = Locale::Unicode->tz_id2names( 'unknown' );
    # yields an empty array object
    my $ref = Locale::Unicode->tz_id2names( 'jptyo' );
    # Asia/Tokyo

Provided with a CLDR timezone ID, such as C<ausyd>, which stands primarily for C<Australia/Sydney>, and this returns an L<array object|Module::Generic::Array> of IANA Olson timezone names, which, in this case, would yield: C<['Australia/Sydney', 'Australia/ACT', 'Australia/Canberra', 'Australia/NSW']>

The order is set by L<BCP47 timezone data|https://github.com/unicode-org/cldr/blob/main/common/bcp47/timezone.xml>

If an error occurs, its sets an L<error object|Module::Generic::Exception> and returns C<undef> in scalar context, or an empty list in list context.

=head2 tz_info

    my $def = Locale::Unicode->tz_id2names( 'jptyo' );
    # yields the following hash reference:
    # {
    #     alias => [qw( Asia/Tokyo Japan )],
    #     desc => "Tokyo, Japan",
    #     tz => "Asia/Tokyo",
    # }
    my $def = Locale::Unicode->tz_id2names( 'unknown' );
    # yields an empty string (not undef)

Provided with a CLDR timezone ID, such as C<jptyo> and this returns an hash reference representing the dictionary entry for that ID.

If no information exists for the given timezone ID, an empty string is returned. C<undef> is returned only for errors.

If an error occurs, its sets an L<error object|Module::Generic::Exception> and returns C<undef> in scalar context, or an empty list in list context.

=head2 tz_name2id

    my $id = Locale::Unicode->tz_name2id( 'Asia/Tokyo' );
    # jptyo
    my $id = Locale::Unicode->tz_name2id( 'Australia/Canberra' );
    # ausyd

Provided with an IANA Olson timezone name, such as C<Asia/Tokyo> and this returns its CLDR equivalent, which, in this case, would be C<jptyo>

If none exists, an empty string is returned.

If an error occurs, its sets an L<error object|Module::Generic::Exception> and returns C<undef> in scalar context, or an empty list in list context.

=head1 OVERLOADING

Any object from this class is overloaded and stringifies to its locale representation.

For example:

    my $locale = Locale::Unicode->new('ja-Kana-t-it' );
    say $locale; # ja-Kana-t-it
    $locale->transform( 'de' );
    say $locale; # ja-Kana-t-de

In boolean context, it always returns true by merely returning the current object instead of falling back on stringifying the object.

Any other overloading is performed using L<fallback methods|overload/"fallback">.

=head1 BCP47 EXTENSIONS

=head2 Unicode extensions

Example:

=over 4

=item * C<gsw-u-sd-chzh>

=back

Known L<BCP47 language extensions|https://unicode.org/reports/tr35/#u_Extension> as defined in L<RFC6067|https://datatracker.ietf.org/doc/html/rfc6067> are as follows:

=over 4

=item * C<ca>

A L<Unicode calendar identifier|https://unicode.org/reports/tr35/#UnicodeCalendarIdentifier> that specifies a type of calendar used for formatting and parsing, such as date/time symbols and patterns; it also selects supplemental calendarData used for calendrical calculations. The value can affect the computation of the first day of the week.

For example:

=over 8

=item * C<ja-u-ca-japanese>

Japanese Imperial calendar

=item * C<th-u-ca-buddhist>

Thai with Buddist calendar

=back

Possible L<values|https://github.com/unicode-org/cldr/blob/main/common/bcp47/calendar.xml> are:

=over 8

=item * C<buddhist>

Thai Buddhist calendar

=item * C<chinese>

Traditional Chinese calendar

=item * C<coptic>

Coptic calendar

=item * C<dangi>

Traditional Korean calendar

=item * C<ethioaa>

Ethiopic calendar, Amete Alem (epoch approx. 5493 B.C.E)

=item * C<ethiopic>

Ethiopic calendar, Amete Mihret (epoch approx, 8 C.E.)

=item * C<gregory>

Gregorian calendar

=item * C<hebrew>

Traditional Hebrew calendar

=item * C<indian>

Indian calendar

=item * C<islamic>

Hijri calendar

=item * C<islamic-civil>

Hijri calendar, tabular (intercalary years [2,5,7,10,13,16,18,21,24,26,29] - civil epoch)

=item * C<islamic-rgsa>

Hijri calendar, Saudi Arabia sighting

=item * C<islamic-tbla>

Hijri calendar, tabular (intercalary years [2,5,7,10,13,16,18,21,24,26,29] - astronomical epoch)

=item * C<islamic-umalqura>

Hijri calendar, Umm al-Qura

=item * C<islamicc>

Civil (algorithmic) Arabic calendar

=item * C<iso8601>

ISO calendar (Gregorian calendar using the ISO 8601 calendar week rules)

=item * C<japanese>

Japanese Imperial calendar

=item * C<persian>

Persian calendar

=item * C<roc>

Republic of China calendar

=back

=item * C<cf>

A L<Unicode currency format identifier|https://unicode.org/reports/tr35/#UnicodeCurrencyFormatIdentifier>

Typical values are:

=over 8

=item * C<standard>

Default value. Negative numbers use the minusSign symbol.

=item * C<account>

Negative numbers use parentheses or equivalent.

=back

=item * C<co>

A L<Unicode collation identifier|https://unicode.org/reports/tr35/#UnicodeCollationIdentifier> that specifies a type of collation (sort order).

Possible L<values|https://github.com/unicode-org/cldr/blob/main/common/bcp47/collation.xml> are:

=over 8

=item * C<big5han>

Pinyin ordering for Latin, big5 charset ordering for CJK characters (used in Chinese)

=item * C<compat>

A previous version of the ordering, for compatibility

=item * C<dict>

Dictionary style ordering (such as in Sinhala)

=item * C<direct>

Binary code point order (used in Hindi)

=item * C<ducet>

The default Unicode collation element table order

=item * C<emoji>

Recommended ordering for emoji characters

=item * C<eor>

European ordering rules

=item * C<gb2312>

Pinyin ordering for Latin, gb2312han charset ordering for CJK characters (used in Chinese)

=item * C<phonebk>

Phonebook style ordering (such as in German)

=item * C<phonetic>

Phonetic ordering (sorting based on pronunciation)

=item * C<pinyin>

Pinyin ordering for Latin and for CJK characters (used in Chinese)

=item * C<reformed>

Reformed ordering (such as in Swedish)

=item * C<search>

Special collation type for string search

=item * C<searchjl>

Special collation type for Korean initial consonant search

=item * C<standard>

Default ordering for each language

=item * C<stroke>

Pinyin ordering for Latin, stroke order for CJK characters (used in Chinese)

=item * C<trad>

Traditional style ordering (such as in Spanish)

=item * C<unihan>

Pinyin ordering for Latin, Unihan radical-stroke ordering for CJK characters (used in Chinese)

=item * C<zhuyin>

Pinyin ordering for Latin, zhuyin order for Bopomofo and CJK characters (used in Chinese)

=back

For example: C<de-u-co-phonebk-ka-shifted> (German using Phonebook sorting, ignore punct.)

=item * C<cu>

A L<Unicode Currency Identifier|https://unicode.org/reports/tr35/#UnicodeCurrencyIdentifier> that specifies a type of currency (L<ISO 4217 code|https://github.com/unicode-org/cldr/blob/main/common/bcp47/currency.xml>) consisting of 3 ASCII letters that are or have been valid in ISO 4217, plus certain additional codes that are or have been in common use.

For example: C<ja-u-cu-jpy> (Japanese yens)

=item * C<dx>

A L<Unicode Dictionary Break Exclusion Identifier|https://unicode.org/reports/tr35/#UnicodeDictionaryBreakExclusionIdentifier> specifies scripts to be excluded from dictionary-based text break (for words and lines).

A proper value is one or more Unicode script subtags separated by hyphen. Their order is not important, but canonical order is alphabetical, such as C<dx-hani-thai>

For example:

=over 8

=item * C<dx-hani-hira-kata>

=item * C<dx-thai-hani>

=back

=item * C<em>

A L<Unicode Emoji Presentation Style Identifier|https://unicode.org/reports/tr35/#UnicodeEmojiPresentationStyleIdentifier> specifies a request for the preferred emoji presentation style.

Possible L<values|https://github.com/unicode-org/cldr/blob/main/common/bcp47/variant.xml> are:

=over 8

=item * C<emoji>

Use an emoji presentation for emoji characters if possible.

=item * C<text>

Use a text presentation for emoji characters if possible.

=item * C<default>

Use the default presentation for emoji characters as specified in L<UTR #51|https://www.unicode.org/reports/tr51/#Presentation_Style>

=back

=item * C<fw>

A L<Unicode First Day Identifier|https://unicode.org/reports/tr35/#UnicodeFirstDayIdentifier> defines the preferred first day of the week for calendar display.

Possible L<values|https://github.com/unicode-org/cldr/blob/main/common/bcp47/calendar.xml> are:

=over 8

=item * C<sun>

Sunday

=item * C<mon>

Monday

=item * C<tue>

Tuesday

=item * C<wed>

Wednesday

=item * C<thu>

Thursday

=item * C<fri>

Friday

=item * C<sat>

Saturday

=back

=item * C<hc>

A L<Unicode Hour Cycle Identifier|https://unicode.org/reports/tr35/#UnicodeHourCycleIdentifier> defines the preferred time cycle.

Possible L<values|https://github.com/unicode-org/cldr/blob/main/common/bcp47/calendar.xml> are:

=over 8

=item * C<h12>

Hour system using 1–12; corresponds to C<h> in patterns

=item * C<h23>

Hour system using 0–23; corresponds to C<H> in patterns

=item * C<h11>

Hour system using 0–11; corresponds to C<K> in patterns

=item * C<h24>

Hour system using 1–24; corresponds to C<k> in pattern

=back

=item * C<lb>

A L<Unicode Line Break Style Identifier|https://unicode.org/reports/tr35/#UnicodeLineBreakStyleIdentifier> defines a preferred line break style corresponding to the L<CSS level 3 line-break option|https://drafts.csswg.org/css-text/#line-break-property>.

Possible L<values|https://github.com/unicode-org/cldr/blob/10ed3348d56be1c9fdadeb0a793a9b909eac3151/common/bcp47/segmentation.xml#L16> are:

=over 8

=item * C<strict>

CSS level 3 line-break=strict, e.g. treat CJ as NS

=item * C<normal>

CSS level 3 line-break=normal, e.g. treat CJ as ID, break before hyphens for ja,zh

=item * C<loose>

CSS lev 3 line-break=loose

=back

=item * C<lw>

A L<Unicode Line Break Word Identifier|https://unicode.org/reports/tr35/#UnicodeLineBreakWordIdentifier> defines preferred line break word handling behavior corresponding to the L<CSS level 3 word-break option|https://drafts.csswg.org/css-text/#word-break-property>.

Possible L<values|https://github.com/unicode-org/cldr/blob/main/common/bcp47/segmentation.xml> are:

=over 8

=item * C<normal>

CSS level 3 word-break=normal, normal script/language behavior for midword breaks

=item * C<breakall>

CSS level 3 word-break=break-all, allow midword breaks unless forbidden by lb setting

=item * C<keepall>

CSS level 3 word-break=keep-all, prohibit midword breaks except for dictionary breaks

=item * C<phrase>

Prioritise keeping natural phrases (of multiple words) together when breaking, used in short text like title and headline

=back

=item * C<ms>

A L<Unicode Measurement System Identifier|https://unicode.org/reports/tr35/#UnicodeMeasurementSystemIdentifier> defines a preferred measurement system. Specifying "ms" in a locale identifier overrides the default value specified by supplemental measurement system data for the region

Possible L<values|https://github.com/unicode-org/cldr/blob/main/common/bcp47/measure.xml> are:

=over 8

=item * C<metric>

Metric System

=item * C<ussystem>

US System of measurement: feet, pints, etc.; pints are 16oz

=item * C<uksystem>

UK System of measurement: feet, pints, etc.; pints are 20oz

=back

=item * C<mu>

A L<Measurement Unit Preference Override|https://unicode.org/reports/tr35/#MeasurementUnitPreferenceOverride> defines an override for measurement unit preference.

Possible L<values|https://github.com/unicode-org/cldr/blob/main/common/bcp47/measure.xml> are:

=over 8

=item * C<celsius>

Celsius as temperature unit

=item * C<kelvin>

Kelvin as temperature unit

=item * C<fahrenhe>

Fahrenheit as temperature unit

=back

=item * C<nu>

A L<Unicode Number System Identifier|https://unicode.org/reports/tr35/#UnicodeNumberSystemIdentifier> defines a type of number system.

For example: C<ar-u-nu-native> (Arabic with native digits such as "٠١٢٣٤"), or C<ar-u-nu-latn> (Arabic with Western digits such as "01234")

Possible L<values|https://github.com/unicode-org/cldr/blob/main/common/bcp47/number.xml> are:

=over 8

=item * C<4-letters Unicode script subtag>

=item * C<arabext>

Extended Arabic-Indic digits ("arab" means the base Arabic-Indic digits)

=item * C<armnlow>

Armenian lowercase numerals

=item * C<finance>

Financial numerals

=item * C<fullwide>

Full width digits

=item * C<greklow>

Greek lower case numerals

=item * C<hanidays>

Han-character day-of-month numbering for lunar/other traditional calendars

=item * C<hanidec>

Positional decimal system using Chinese number ideographs as digits

=item * C<hansfin>

Simplified Chinese financial numerals

=item * C<hantfin>

Traditional Chinese financial numerals

=item * C<jpanfin>

Japanese financial numerals

=item * C<jpanyear>

Japanese first-year Gannen numbering for Japanese calendar

=item * C<lanatham>

Tai Tham Tham (ecclesiastical) digits

=item * C<mathbold>

Mathematical bold digits

=item * C<mathdbl>

Mathematical double-struck digits

=item * C<mathmono>

Mathematical monospace digits

=item * C<mathsanb>

Mathematical sans-serif bold digits

=item * C<mathsans>

Mathematical sans-serif digits

=item * C<mymrepka>

Myanmar Eastern Pwo Karen digits

=item * C<mymrpao>

Myanmar Pao digits

=item * C<mymrshan>

Myanmar Shan digits

=item * C<mymrtlng>

Myanmar Tai Laing digits

=item * C<native>

Native digits

=item * C<outlined>

Legacy computing outlined digits

=item * C<roman>

Roman numerals

=item * C<romanlow>

Roman lowercase numerals

=item * C<segment>

Legacy computing segmented digits

=item * C<tamldec>

Modern Tamil decimal digits

=item * C<traditio>

Traditional numerals

=back

=item * C<rg>

A L<Region Override|https://unicode.org/reports/tr35/#RegionOverride> specifies an alternate region to use for obtaining certain region-specific default values

For example: C<en-GB-u-rg-uszzzz> representing a locale for British English but with region-specific defaults set to US.

=item * C<sd>

A L<Unicode Subdivision Identifier|https://unicode.org/reports/tr35/#UnicodeSubdivisionIdentifier> defines a L<regional subdivision|https://unicode.org/reports/tr35/#Unicode_Subdivision_Codes> used for locales.

They are called various names, such as a state in the United States, or a prefecture in Japan or France, or a province in Canada.

For example:

=over 8

=item * C<en-u-sd-uszzzz>

Subdivision codes for unknown values are the region code plus C<zzzz>, such as here with C<uszzzz> for an unknown subdivision of the US.

=item * C<en-US-u-sd-usca>

English as used in California, USA

=back

C<en-CA-u-sd-gbsct> would be invalid because C<gb> in C<gbsct> does not match the region subtag C<CA>

=item * C<ss>

A L<Unicode Sentence Break Suppressions Identifier|https://unicode.org/reports/tr35/#UnicodeSentenceBreakSuppressionsIdentifier> defines a set of data to be used for suppressing certain sentence breaks

Possible L<values|https://github.com/unicode-org/cldr/blob/10ed3348d56be1c9fdadeb0a793a9b909eac3151/common/bcp47/segmentation.xml#L29> are:

=over 8

=item * C<none> (default)

Do not use sentence break suppressions data

=item * C<standard>

Use sentence break suppressions data of type C<standard>

=back

=item * C<tz>

A L<Unicode Timezone Identifier|https://unicode.org/reports/tr35/#UnicodeTimezoneIdentifier> defines a timezone.

To access those values, check the class functions L</tz_id2name>, L<tz_id2names>, L</tz_info> and L</tz_name2id>

Possible L<values|https://github.com/unicode-org/cldr/blob/main/common/bcp47/timezone.xml> are:

=over 8

=item * C<adalv>

Name: Andorra

Time zone: C<Europe/Andorra>

=item * C<aedxb>

Name: Dubai, United Arab Emirates

Time zone: C<Asia/Dubai>

=item * C<afkbl>

Name: Kabul, Afghanistan

Time zone: C<Asia/Kabul>

=item * C<aganu>

Name: Antigua

Time zone: C<America/Antigua>

=item * C<aiaxa>

Name: Anguilla

Time zone: C<America/Anguilla>

=item * C<altia>

Name: Tirane, Albania

Time zone: C<Europe/Tirane>

=item * C<amevn>

Name: Yerevan, Armenia

Time zone: C<Asia/Yerevan>

=item * C<ancur>

Name: Curaçao

Time zone: C<America/Curacao>

=item * C<aolad>

Name: Luanda, Angola

Time zone: C<Africa/Luanda>

=item * C<aqams>

Amundsen-Scott Station, South Pole

Deprecated. See instead C<nzakl>

=item * C<aqcas>

Name: Casey Station, Bailey Peninsula

Time zone: C<Antarctica/Casey>

=item * C<aqdav>

Name: Davis Station, Vestfold Hills

Time zone: C<Antarctica/Davis>

=item * C<aqddu>

Name: Dumont d'Urville Station, Terre Adélie

Time zone: C<Antarctica/DumontDUrville>

=item * C<aqmaw>

Name: Mawson Station, Holme Bay

Time zone: C<Antarctica/Mawson>

=item * C<aqmcm>

Name: McMurdo Station, Ross Island

Time zone: C<Antarctica/McMurdo>

=item * C<aqplm>

Name: Palmer Station, Anvers Island

Time zone: C<Antarctica/Palmer>

=item * C<aqrot>

Name: Rothera Station, Adelaide Island

Time zone: C<Antarctica/Rothera>

=item * C<aqsyw>

Name: Syowa Station, East Ongul Island

Time zone: C<Antarctica/Syowa>

=item * C<aqtrl>

Name: Troll Station, Queen Maud Land

Time zone: C<Antarctica/Troll>

=item * C<aqvos>

Name: Vostok Station, Lake Vostok

Time zone: C<Antarctica/Vostok>

=item * C<arbue>

Name: Buenos Aires, Argentina

Time zone: C<America/Buenos_Aires>, C<America/Argentina/Buenos_Aires>

=item * C<arcor>

Name: Córdoba, Argentina

Time zone: C<America/Cordoba>, C<America/Argentina/Cordoba>, C<America/Rosario>

=item * C<arctc>

Name: Catamarca, Argentina

Time zone: C<America/Catamarca>, C<America/Argentina/Catamarca>, C<America/Argentina/ComodRivadavia>

=item * C<arirj>

Name: La Rioja, Argentina

Time zone: C<America/Argentina/La_Rioja>

=item * C<arjuj>

Name: Jujuy, Argentina

Time zone: C<America/Jujuy>, C<America/Argentina/Jujuy>

=item * C<arluq>

Name: San Luis, Argentina

Time zone: C<America/Argentina/San_Luis>

=item * C<armdz>

Name: Mendoza, Argentina

Time zone: C<America/Mendoza>, C<America/Argentina/Mendoza>

=item * C<arrgl>

Name: Río Gallegos, Argentina

Time zone: C<America/Argentina/Rio_Gallegos>

=item * C<arsla>

Name: Salta, Argentina

Time zone: C<America/Argentina/Salta>

=item * C<artuc>

Name: Tucumán, Argentina

Time zone: C<America/Argentina/Tucuman>

=item * C<aruaq>

Name: San Juan, Argentina

Time zone: C<America/Argentina/San_Juan>

=item * C<arush>

Name: Ushuaia, Argentina

Time zone: C<America/Argentina/Ushuaia>

=item * C<asppg>

Name: Pago Pago, American Samoa

Time zone: C<Pacific/Pago_Pago>, C<Pacific/Samoa>, C<US/Samoa>

=item * C<atvie>

Name: Vienna, Austria

Time zone: C<Europe/Vienna>

=item * C<auadl>

Name: Adelaide, Australia

Time zone: C<Australia/Adelaide>, C<Australia/South>

=item * C<aubhq>

Name: Broken Hill, Australia

Time zone: C<Australia/Broken_Hill>, C<Australia/Yancowinna>

=item * C<aubne>

Name: Brisbane, Australia

Time zone: C<Australia/Brisbane>, C<Australia/Queensland>

=item * C<audrw>

Name: Darwin, Australia

Time zone: C<Australia/Darwin>, C<Australia/North>

=item * C<aueuc>

Name: Eucla, Australia

Time zone: C<Australia/Eucla>

=item * C<auhba>

Name: Hobart, Australia

Time zone: C<Australia/Hobart>, C<Australia/Tasmania>, C<Australia/Currie>

=item * C<aukns>

Currie, Australia

Deprecated. See instead C<auhba>

=item * C<auldc>

Name: Lindeman Island, Australia

Time zone: C<Australia/Lindeman>

=item * C<auldh>

Name: Lord Howe Island, Australia

Time zone: C<Australia/Lord_Howe>, C<Australia/LHI>

=item * C<aumel>

Name: Melbourne, Australia

Time zone: C<Australia/Melbourne>, C<Australia/Victoria>

=item * C<aumqi>

Name: Macquarie Island Station, Macquarie Island

Time zone: C<Antarctica/Macquarie>

=item * C<auper>

Name: Perth, Australia

Time zone: C<Australia/Perth>, C<Australia/West>

=item * C<ausyd>

Name: Sydney, Australia

Time zone: C<Australia/Sydney>, C<Australia/ACT>, C<Australia/Canberra>, C<Australia/NSW>

=item * C<awaua>

Name: Aruba

Time zone: C<America/Aruba>

=item * C<azbak>

Name: Baku, Azerbaijan

Time zone: C<Asia/Baku>

=item * C<basjj>

Name: Sarajevo, Bosnia and Herzegovina

Time zone: C<Europe/Sarajevo>

=item * C<bbbgi>

Name: Barbados

Time zone: C<America/Barbados>

=item * C<bddac>

Name: Dhaka, Bangladesh

Time zone: C<Asia/Dhaka>, C<Asia/Dacca>

=item * C<bebru>

Name: Brussels, Belgium

Time zone: C<Europe/Brussels>

=item * C<bfoua>

Name: Ouagadougou, Burkina Faso

Time zone: C<Africa/Ouagadougou>

=item * C<bgsof>

Name: Sofia, Bulgaria

Time zone: C<Europe/Sofia>

=item * C<bhbah>

Name: Bahrain

Time zone: C<Asia/Bahrain>

=item * C<bibjm>

Name: Bujumbura, Burundi

Time zone: C<Africa/Bujumbura>

=item * C<bjptn>

Name: Porto-Novo, Benin

Time zone: C<Africa/Porto-Novo>

=item * C<bmbda>

Name: Bermuda

Time zone: C<Atlantic/Bermuda>

=item * C<bnbwn>

Name: Brunei

Time zone: C<Asia/Brunei>

=item * C<bolpb>

Name: La Paz, Bolivia

Time zone: C<America/La_Paz>

=item * C<bqkra>

Name: Bonaire, Sint Estatius and Saba

Time zone: C<America/Kralendijk>

=item * C<braux>

Name: Araguaína, Brazil

Time zone: C<America/Araguaina>

=item * C<brbel>

Name: Belém, Brazil

Time zone: C<America/Belem>

=item * C<brbvb>

Name: Boa Vista, Brazil

Time zone: C<America/Boa_Vista>

=item * C<brcgb>

Name: Cuiabá, Brazil

Time zone: C<America/Cuiaba>

=item * C<brcgr>

Name: Campo Grande, Brazil

Time zone: C<America/Campo_Grande>

=item * C<brern>

Name: Eirunepé, Brazil

Time zone: C<America/Eirunepe>

=item * C<brfen>

Name: Fernando de Noronha, Brazil

Time zone: C<America/Noronha>, C<Brazil/DeNoronha>

=item * C<brfor>

Name: Fortaleza, Brazil

Time zone: C<America/Fortaleza>

=item * C<brmao>

Name: Manaus, Brazil

Time zone: C<America/Manaus>, C<Brazil/West>

=item * C<brmcz>

Name: Maceió, Brazil

Time zone: C<America/Maceio>

=item * C<brpvh>

Name: Porto Velho, Brazil

Time zone: C<America/Porto_Velho>

=item * C<brrbr>

Name: Rio Branco, Brazil

Time zone: C<America/Rio_Branco>, C<America/Porto_Acre>, C<Brazil/Acre>

=item * C<brrec>

Name: Recife, Brazil

Time zone: C<America/Recife>

=item * C<brsao>

Name: São Paulo, Brazil

Time zone: C<America/Sao_Paulo>, C<Brazil/East>

=item * C<brssa>

Name: Bahia, Brazil

Time zone: C<America/Bahia>

=item * C<brstm>

Name: Santarém, Brazil

Time zone: C<America/Santarem>

=item * C<bsnas>

Name: Nassau, Bahamas

Time zone: C<America/Nassau>

=item * C<btthi>

Name: Thimphu, Bhutan

Time zone: C<Asia/Thimphu>, C<Asia/Thimbu>

=item * C<bwgbe>

Name: Gaborone, Botswana

Time zone: C<Africa/Gaborone>

=item * C<bymsq>

Name: Minsk, Belarus

Time zone: C<Europe/Minsk>

=item * C<bzbze>

Name: Belize

Time zone: C<America/Belize>

=item * C<cacfq>

Name: Creston, Canada

Time zone: C<America/Creston>

=item * C<caedm>

Name: Edmonton, Canada

Time zone: C<America/Edmonton>, C<Canada/Mountain>, C<America/Yellowknife>

=item * C<caffs>

Rainy River, Canada

Deprecated. See instead C<cawnp>

=item * C<cafne>

Name: Fort Nelson, Canada

Time zone: C<America/Fort_Nelson>

=item * C<caglb>

Name: Glace Bay, Canada

Time zone: C<America/Glace_Bay>

=item * C<cagoo>

Name: Goose Bay, Canada

Time zone: C<America/Goose_Bay>

=item * C<cahal>

Name: Halifax, Canada

Time zone: C<America/Halifax>, C<Canada/Atlantic>

=item * C<caiql>

Name: Iqaluit, Canada

Time zone: C<America/Iqaluit>, C<America/Pangnirtung>

=item * C<camon>

Name: Moncton, Canada

Time zone: C<America/Moncton>

=item * C<camtr>

Montreal, Canada

Deprecated. See instead C<cator>

=item * C<capnt>

Pangnirtung, Canada

Deprecated. See instead C<caiql>

=item * C<careb>

Name: Resolute, Canada

Time zone: C<America/Resolute>

=item * C<careg>

Name: Regina, Canada

Time zone: C<America/Regina>, C<Canada/East-Saskatchewan>, C<Canada/Saskatchewan>

=item * C<casjf>

Name: St. John's, Canada

Time zone: C<America/St_Johns>, C<Canada/Newfoundland>

=item * C<canpg>

Nipigon, Canada

Deprecated. See instead C<cator>

=item * C<cathu>

Thunder Bay, Canada

Deprecated. See instead C<cator>

=item * C<cator>

Name: Toronto, Canada

Time zone: C<America/Toronto>, C<America/Montreal>, C<Canada/Eastern>, C<America/Nipigon>, C<America/Thunder_Bay>

=item * C<cavan>

Name: Vancouver, Canada

Time zone: C<America/Vancouver>, C<Canada/Pacific>

=item * C<cawnp>

Name: Winnipeg, Canada

Time zone: C<America/Winnipeg>, C<Canada/Central>, C<America/Rainy_River>

=item * C<caybx>

Name: Blanc-Sablon, Canada

Time zone: C<America/Blanc-Sablon>

=item * C<caycb>

Name: Cambridge Bay, Canada

Time zone: C<America/Cambridge_Bay>

=item * C<cayda>

Name: Dawson, Canada

Time zone: C<America/Dawson>

=item * C<caydq>

Name: Dawson Creek, Canada

Time zone: C<America/Dawson_Creek>

=item * C<cayek>

Name: Rankin Inlet, Canada

Time zone: C<America/Rankin_Inlet>

=item * C<cayev>

Name: Inuvik, Canada

Time zone: C<America/Inuvik>

=item * C<cayxy>

Name: Whitehorse, Canada

Time zone: C<America/Whitehorse>, C<Canada/Yukon>

=item * C<cayyn>

Name: Swift Current, Canada

Time zone: C<America/Swift_Current>

=item * C<cayzf>

Yellowknife, Canada

Deprecated. See instead C<caedm>

=item * C<cayzs>

Name: Atikokan, Canada

Time zone: C<America/Coral_Harbour>, C<America/Atikokan>

=item * C<cccck>

Name: Cocos (Keeling) Islands

Time zone: C<Indian/Cocos>

=item * C<cdfbm>

Name: Lubumbashi, Democratic Republic of the Congo

Time zone: C<Africa/Lubumbashi>

=item * C<cdfih>

Name: Kinshasa, Democratic Republic of the Congo

Time zone: C<Africa/Kinshasa>

=item * C<cfbgf>

Name: Bangui, Central African Republic

Time zone: C<Africa/Bangui>

=item * C<cgbzv>

Name: Brazzaville, Republic of the Congo

Time zone: C<Africa/Brazzaville>

=item * C<chzrh>

Name: Zurich, Switzerland

Time zone: C<Europe/Zurich>

=item * C<ciabj>

Name: Abidjan, Côte d'Ivoire

Time zone: C<Africa/Abidjan>

=item * C<ckrar>

Name: Rarotonga, Cook Islands

Time zone: C<Pacific/Rarotonga>

=item * C<clipc>

Name: Easter Island, Chile

Time zone: C<Pacific/Easter>, C<Chile/EasterIsland>

=item * C<clpuq>

Name: Punta Arenas, Chile

Time zone: C<America/Punta_Arenas>

=item * C<clscl>

Name: Santiago, Chile

Time zone: C<America/Santiago>, C<Chile/Continental>

=item * C<cmdla>

Name: Douala, Cameroon

Time zone: C<Africa/Douala>

=item * C<cnckg>

Chongqing, China

Deprecated. See instead C<cnsha>

=item * C<cnhrb>

Harbin, China

Deprecated. See instead C<cnsha>

=item * C<cnkhg>

Kashgar, China

Deprecated. See instead C<cnurc>

=item * C<cnsha>

Name: Shanghai, China

Time zone: C<Asia/Shanghai>, C<Asia/Chongqing>, C<Asia/Chungking>, C<Asia/Harbin>, C<PRC>

=item * C<cnurc>

Name: Ürümqi, China

Time zone: C<Asia/Urumqi>, C<Asia/Kashgar>

=item * C<cobog>

Name: Bogotá, Colombia

Time zone: C<America/Bogota>

=item * C<crsjo>

Name: Costa Rica

Time zone: C<America/Costa_Rica>

=item * C<cst6cdt>

Name: POSIX style time zone for US Central Time

Time zone: C<CST6CDT>

=item * C<cuhav>

Name: Havana, Cuba

Time zone: C<America/Havana>, C<Cuba>

=item * C<cvrai>

Name: Cape Verde

Time zone: C<Atlantic/Cape_Verde>

=item * C<cxxch>

Name: Christmas Island

Time zone: C<Indian/Christmas>

=item * C<cyfmg>

Name: Famagusta, Cyprus

Time zone: C<Asia/Famagusta>

=item * C<cynic>

Name: Nicosia, Cyprus

Time zone: C<Asia/Nicosia>, C<Europe/Nicosia>

=item * C<czprg>

Name: Prague, Czech Republic

Time zone: C<Europe/Prague>

=item * C<deber>

Name: Berlin, Germany

Time zone: C<Europe/Berlin>

=item * C<debsngn>

Name: Busingen, Germany

Time zone: C<Europe/Busingen>

=item * C<djjib>

Name: Djibouti

Time zone: C<Africa/Djibouti>

=item * C<dkcph>

Name: Copenhagen, Denmark

Time zone: C<Europe/Copenhagen>

=item * C<dmdom>

Name: Dominica

Time zone: C<America/Dominica>

=item * C<dosdq>

Name: Santo Domingo, Dominican Republic

Time zone: C<America/Santo_Domingo>

=item * C<dzalg>

Name: Algiers, Algeria

Time zone: C<Africa/Algiers>

=item * C<ecgps>

Name: Galápagos Islands, Ecuador

Time zone: C<Pacific/Galapagos>

=item * C<ecgye>

Name: Guayaquil, Ecuador

Time zone: C<America/Guayaquil>

=item * C<eetll>

Name: Tallinn, Estonia

Time zone: C<Europe/Tallinn>

=item * C<egcai>

Name: Cairo, Egypt

Time zone: C<Africa/Cairo>, C<Egypt>

=item * C<eheai>

Name: El Aaiún, Western Sahara

Time zone: C<Africa/El_Aaiun>

=item * C<erasm>

Name: Asmara, Eritrea

Time zone: C<Africa/Asmera>, C<Africa/Asmara>

=item * C<esceu>

Name: Ceuta, Spain

Time zone: C<Africa/Ceuta>

=item * C<eslpa>

Name: Canary Islands, Spain

Time zone: C<Atlantic/Canary>

=item * C<esmad>

Name: Madrid, Spain

Time zone: C<Europe/Madrid>

=item * C<est5edt>

Name: POSIX style time zone for US Eastern Time

Time zone: C<EST5EDT>

=item * C<etadd>

Name: Addis Ababa, Ethiopia

Time zone: C<Africa/Addis_Ababa>

=item * C<fihel>

Name: Helsinki, Finland

Time zone: C<Europe/Helsinki>

=item * C<fimhq>

Name: Mariehamn, Åland, Finland

Time zone: C<Europe/Mariehamn>

=item * C<fjsuv>

Name: Fiji

Time zone: C<Pacific/Fiji>

=item * C<fkpsy>

Name: Stanley, Falkland Islands

Time zone: C<Atlantic/Stanley>

=item * C<fmksa>

Name: Kosrae, Micronesia

Time zone: C<Pacific/Kosrae>

=item * C<fmpni>

Name: Pohnpei, Micronesia

Time zone: C<Pacific/Ponape>, C<Pacific/Pohnpei>

=item * C<fmtkk>

Name: Chuuk, Micronesia

Time zone: C<Pacific/Truk>, C<Pacific/Chuuk>, C<Pacific/Yap>

=item * C<fotho>

Name: Faroe Islands

Time zone: C<Atlantic/Faeroe>, C<Atlantic/Faroe>

=item * C<frpar>

Name: Paris, France

Time zone: C<Europe/Paris>

=item * C<galbv>

Name: Libreville, Gabon

Time zone: C<Africa/Libreville>

=item * C<gaza>

Gaza Strip, Palestinian Territories

Deprecated. See instead C<gazastrp>

=item * C<gazastrp>

Name: Gaza Strip, Palestinian Territories

Time zone: C<Asia/Gaza>

=item * C<gblon>

Name: London, United Kingdom

Time zone: C<Europe/London>, C<Europe/Belfast>, C<GB>, C<GB-Eire>

=item * C<gdgnd>

Name: Grenada

Time zone: C<America/Grenada>

=item * C<getbs>

Name: Tbilisi, Georgia

Time zone: C<Asia/Tbilisi>

=item * C<gfcay>

Name: Cayenne, French Guiana

Time zone: C<America/Cayenne>

=item * C<gggci>

Name: Guernsey

Time zone: C<Europe/Guernsey>

=item * C<ghacc>

Name: Accra, Ghana

Time zone: C<Africa/Accra>

=item * C<gigib>

Name: Gibraltar

Time zone: C<Europe/Gibraltar>

=item * C<gldkshvn>

Name: Danmarkshavn, Greenland

Time zone: C<America/Danmarkshavn>

=item * C<glgoh>

Name: Nuuk (Godthåb), Greenland

Time zone: C<America/Godthab>, C<America/Nuuk>

=item * C<globy>

Name: Ittoqqortoormiit (Scoresbysund), Greenland

Time zone: C<America/Scoresbysund>

=item * C<glthu>

Name: Qaanaaq (Thule), Greenland

Time zone: C<America/Thule>

=item * C<gmbjl>

Name: Banjul, Gambia

Time zone: C<Africa/Banjul>

=item * C<gmt>

Name: Greenwich Mean Time

Time zone: C<Etc/GMT>, C<Etc/GMT+0>, C<Etc/GMT-0>, C<Etc/GMT0>, C<Etc/Greenwich>, C<GMT>, C<GMT+0>, C<GMT-0>, C<GMT0>, C<Greenwich>

=item * C<gncky>

Name: Conakry, Guinea

Time zone: C<Africa/Conakry>

=item * C<gpbbr>

Name: Guadeloupe

Time zone: C<America/Guadeloupe>

=item * C<gpmsb>

Name: Marigot, Saint Martin

Time zone: C<America/Marigot>

=item * C<gpsbh>

Name: Saint Barthélemy

Time zone: C<America/St_Barthelemy>

=item * C<gqssg>

Name: Malabo, Equatorial Guinea

Time zone: C<Africa/Malabo>

=item * C<grath>

Name: Athens, Greece

Time zone: C<Europe/Athens>

=item * C<gsgrv>

Name: South Georgia and the South Sandwich Islands

Time zone: C<Atlantic/South_Georgia>

=item * C<gtgua>

Name: Guatemala

Time zone: C<America/Guatemala>

=item * C<gugum>

Name: Guam

Time zone: C<Pacific/Guam>

=item * C<gwoxb>

Name: Bissau, Guinea-Bissau

Time zone: C<Africa/Bissau>

=item * C<gygeo>

Name: Guyana

Time zone: C<America/Guyana>

=item * C<hebron>

Name: West Bank, Palestinian Territories

Time zone: C<Asia/Hebron>

=item * C<hkhkg>

Name: Hong Kong SAR China

Time zone: C<Asia/Hong_Kong>, C<Hongkong>

=item * C<hntgu>

Name: Tegucigalpa, Honduras

Time zone: C<America/Tegucigalpa>

=item * C<hrzag>

Name: Zagreb, Croatia

Time zone: C<Europe/Zagreb>

=item * C<htpap>

Name: Port-au-Prince, Haiti

Time zone: C<America/Port-au-Prince>

=item * C<hubud>

Name: Budapest, Hungary

Time zone: C<Europe/Budapest>

=item * C<iddjj>

Name: Jayapura, Indonesia

Time zone: C<Asia/Jayapura>

=item * C<idjkt>

Name: Jakarta, Indonesia

Time zone: C<Asia/Jakarta>

=item * C<idmak>

Name: Makassar, Indonesia

Time zone: C<Asia/Makassar>, C<Asia/Ujung_Pandang>

=item * C<idpnk>

Name: Pontianak, Indonesia

Time zone: C<Asia/Pontianak>

=item * C<iedub>

Name: Dublin, Ireland

Time zone: C<Europe/Dublin>, C<Eire>

=item * C<imdgs>

Name: Isle of Man

Time zone: C<Europe/Isle_of_Man>

=item * C<inccu>

Name: Kolkata, India

Time zone: C<Asia/Calcutta>, C<Asia/Kolkata>

=item * C<iodga>

Name: Chagos Archipelago

Time zone: C<Indian/Chagos>

=item * C<iqbgw>

Name: Baghdad, Iraq

Time zone: C<Asia/Baghdad>

=item * C<irthr>

Name: Tehran, Iran

Time zone: C<Asia/Tehran>, C<Iran>

=item * C<isrey>

Name: Reykjavik, Iceland

Time zone: C<Atlantic/Reykjavik>, C<Iceland>

=item * C<itrom>

Name: Rome, Italy

Time zone: C<Europe/Rome>

=item * C<jeruslm>

Name: Jerusalem

Time zone: C<Asia/Jerusalem>, C<Asia/Tel_Aviv>, C<Israel>

=item * C<jesth>

Name: Jersey

Time zone: C<Europe/Jersey>

=item * C<jmkin>

Name: Jamaica

Time zone: C<America/Jamaica>, C<Jamaica>

=item * C<joamm>

Name: Amman, Jordan

Time zone: C<Asia/Amman>

=item * C<jptyo>

Name: Tokyo, Japan

Time zone: C<Asia/Tokyo>, C<Japan>

=item * C<kenbo>

Name: Nairobi, Kenya

Time zone: C<Africa/Nairobi>

=item * C<kgfru>

Name: Bishkek, Kyrgyzstan

Time zone: C<Asia/Bishkek>

=item * C<khpnh>

Name: Phnom Penh, Cambodia

Time zone: C<Asia/Phnom_Penh>

=item * C<kicxi>

Name: Kiritimati, Kiribati

Time zone: C<Pacific/Kiritimati>

=item * C<kipho>

Name: Enderbury Island, Kiribati

Time zone: C<Pacific/Enderbury>, C<Pacific/Kanton>

=item * C<kitrw>

Name: Tarawa, Kiribati

Time zone: C<Pacific/Tarawa>

=item * C<kmyva>

Name: Comoros

Time zone: C<Indian/Comoro>

=item * C<knbas>

Name: Saint Kitts

Time zone: C<America/St_Kitts>

=item * C<kpfnj>

Name: Pyongyang, North Korea

Time zone: C<Asia/Pyongyang>

=item * C<krsel>

Name: Seoul, South Korea

Time zone: C<Asia/Seoul>, C<ROK>

=item * C<kwkwi>

Name: Kuwait

Time zone: C<Asia/Kuwait>

=item * C<kygec>

Name: Cayman Islands

Time zone: C<America/Cayman>

=item * C<kzaau>

Name: Aqtau, Kazakhstan

Time zone: C<Asia/Aqtau>

=item * C<kzakx>

Name: Aqtobe, Kazakhstan

Time zone: C<Asia/Aqtobe>

=item * C<kzala>

Name: Almaty, Kazakhstan

Time zone: C<Asia/Almaty>

=item * C<kzguw>

Name: Atyrau (Guryev), Kazakhstan

Time zone: C<Asia/Atyrau>

=item * C<kzksn>

Name: Qostanay (Kostanay), Kazakhstan

Time zone: C<Asia/Qostanay>

=item * C<kzkzo>

Name: Kyzylorda, Kazakhstan

Time zone: C<Asia/Qyzylorda>

=item * C<kzura>

Name: Oral, Kazakhstan

Time zone: C<Asia/Oral>

=item * C<lavte>

Name: Vientiane, Laos

Time zone: C<Asia/Vientiane>

=item * C<lbbey>

Name: Beirut, Lebanon

Time zone: C<Asia/Beirut>

=item * C<lccas>

Name: Saint Lucia

Time zone: C<America/St_Lucia>

=item * C<livdz>

Name: Vaduz, Liechtenstein

Time zone: C<Europe/Vaduz>

=item * C<lkcmb>

Name: Colombo, Sri Lanka

Time zone: C<Asia/Colombo>

=item * C<lrmlw>

Name: Monrovia, Liberia

Time zone: C<Africa/Monrovia>

=item * C<lsmsu>

Name: Maseru, Lesotho

Time zone: C<Africa/Maseru>

=item * C<ltvno>

Name: Vilnius, Lithuania

Time zone: C<Europe/Vilnius>

=item * C<lulux>

Name: Luxembourg

Time zone: C<Europe/Luxembourg>

=item * C<lvrix>

Name: Riga, Latvia

Time zone: C<Europe/Riga>

=item * C<lytip>

Name: Tripoli, Libya

Time zone: C<Africa/Tripoli>, C<Libya>

=item * C<macas>

Name: Casablanca, Morocco

Time zone: C<Africa/Casablanca>

=item * C<mcmon>

Name: Monaco

Time zone: C<Europe/Monaco>

=item * C<mdkiv>

Name: Chişinău, Moldova

Time zone: C<Europe/Chisinau>, C<Europe/Tiraspol>

=item * C<metgd>

Name: Podgorica, Montenegro

Time zone: C<Europe/Podgorica>

=item * C<mgtnr>

Name: Antananarivo, Madagascar

Time zone: C<Indian/Antananarivo>

=item * C<mhkwa>

Name: Kwajalein, Marshall Islands

Time zone: C<Pacific/Kwajalein>, C<Kwajalein>

=item * C<mhmaj>

Name: Majuro, Marshall Islands

Time zone: C<Pacific/Majuro>

=item * C<mkskp>

Name: Skopje, Macedonia

Time zone: C<Europe/Skopje>

=item * C<mlbko>

Name: Bamako, Mali

Time zone: C<Africa/Bamako>, C<Africa/Timbuktu>

=item * C<mmrgn>

Name: Yangon (Rangoon), Burma

Time zone: C<Asia/Rangoon>, C<Asia/Yangon>

=item * C<mncoq>

Name: Choibalsan, Mongolia

Time zone: C<Asia/Choibalsan>

=item * C<mnhvd>

Name: Khovd (Hovd), Mongolia

Time zone: C<Asia/Hovd>

=item * C<mnuln>

Name: Ulaanbaatar (Ulan Bator), Mongolia

Time zone: C<Asia/Ulaanbaatar>, C<Asia/Ulan_Bator>

=item * C<momfm>

Name: Macau SAR China

Time zone: C<Asia/Macau>, C<Asia/Macao>

=item * C<mpspn>

Name: Saipan, Northern Mariana Islands

Time zone: C<Pacific/Saipan>

=item * C<mqfdf>

Name: Martinique

Time zone: C<America/Martinique>

=item * C<mrnkc>

Name: Nouakchott, Mauritania

Time zone: C<Africa/Nouakchott>

=item * C<msmni>

Name: Montserrat

Time zone: C<America/Montserrat>

=item * C<mst7mdt>

Name: POSIX style time zone for US Mountain Time

Time zone: C<MST7MDT>

=item * C<mtmla>

Name: Malta

Time zone: C<Europe/Malta>

=item * C<muplu>

Name: Mauritius

Time zone: C<Indian/Mauritius>

=item * C<mvmle>

Name: Maldives

Time zone: C<Indian/Maldives>

=item * C<mwblz>

Name: Blantyre, Malawi

Time zone: C<Africa/Blantyre>

=item * C<mxchi>

Name: Chihuahua, Mexico

Time zone: C<America/Chihuahua>

=item * C<mxcun>

Name: Cancún, Mexico

Time zone: C<America/Cancun>

=item * C<mxcjs>

Name: Ciudad Juárez, Mexico

Time zone: C<America/Ciudad_Juarez>

=item * C<mxhmo>

Name: Hermosillo, Mexico

Time zone: C<America/Hermosillo>

=item * C<mxmam>

Name: Matamoros, Mexico

Time zone: C<America/Matamoros>

=item * C<mxmex>

Name: Mexico City, Mexico

Time zone: C<America/Mexico_City>, C<Mexico/General>

=item * C<mxmid>

Name: Mérida, Mexico

Time zone: C<America/Merida>

=item * C<mxmty>

Name: Monterrey, Mexico

Time zone: C<America/Monterrey>

=item * C<mxmzt>

Name: Mazatlán, Mexico

Time zone: C<America/Mazatlan>, C<Mexico/BajaSur>

=item * C<mxoji>

Name: Ojinaga, Mexico

Time zone: C<America/Ojinaga>

=item * C<mxpvr>

Name: Bahía de Banderas, Mexico

Time zone: C<America/Bahia_Banderas>

=item * C<mxstis>

Santa Isabel (Baja California), Mexico

Deprecated. See instead C<mxtij>

=item * C<mxtij>

Name: Tijuana, Mexico

Time zone: C<America/Tijuana>, C<America/Ensenada>, C<Mexico/BajaNorte>, C<America/Santa_Isabel>

=item * C<mykch>

Name: Kuching, Malaysia

Time zone: C<Asia/Kuching>

=item * C<mykul>

Name: Kuala Lumpur, Malaysia

Time zone: C<Asia/Kuala_Lumpur>

=item * C<mzmpm>

Name: Maputo, Mozambique

Time zone: C<Africa/Maputo>

=item * C<nawdh>

Name: Windhoek, Namibia

Time zone: C<Africa/Windhoek>

=item * C<ncnou>

Name: Noumea, New Caledonia

Time zone: C<Pacific/Noumea>

=item * C<nenim>

Name: Niamey, Niger

Time zone: C<Africa/Niamey>

=item * C<nfnlk>

Name: Norfolk Island

Time zone: C<Pacific/Norfolk>

=item * C<nglos>

Name: Lagos, Nigeria

Time zone: C<Africa/Lagos>

=item * C<nimga>

Name: Managua, Nicaragua

Time zone: C<America/Managua>

=item * C<nlams>

Name: Amsterdam, Netherlands

Time zone: C<Europe/Amsterdam>

=item * C<noosl>

Name: Oslo, Norway

Time zone: C<Europe/Oslo>

=item * C<npktm>

Name: Kathmandu, Nepal

Time zone: C<Asia/Katmandu>, C<Asia/Kathmandu>

=item * C<nrinu>

Name: Nauru

Time zone: C<Pacific/Nauru>

=item * C<nuiue>

Name: Niue

Time zone: C<Pacific/Niue>

=item * C<nzakl>

Name: Auckland, New Zealand

Time zone: C<Pacific/Auckland>, C<Antarctica/South_Pole>, C<NZ>

=item * C<nzcht>

Name: Chatham Islands, New Zealand

Time zone: C<Pacific/Chatham>, C<NZ-CHAT>

=item * C<ommct>

Name: Muscat, Oman

Time zone: C<Asia/Muscat>

=item * C<papty>

Name: Panama

Time zone: C<America/Panama>

=item * C<pelim>

Name: Lima, Peru

Time zone: C<America/Lima>

=item * C<pfgmr>

Name: Gambiera Islands, French Polynesia

Time zone: C<Pacific/Gambier>

=item * C<pfnhv>

Name: Marquesas Islands, French Polynesia

Time zone: C<Pacific/Marquesas>

=item * C<pfppt>

Name: Tahiti, French Polynesia

Time zone: C<Pacific/Tahiti>

=item * C<pgpom>

Name: Port Moresby, Papua New Guinea

Time zone: C<Pacific/Port_Moresby>

=item * C<pgraw>

Name: Bougainville, Papua New Guinea

Time zone: C<Pacific/Bougainville>

=item * C<phmnl>

Name: Manila, Philippines

Time zone: C<Asia/Manila>

=item * C<pkkhi>

Name: Karachi, Pakistan

Time zone: C<Asia/Karachi>

=item * C<plwaw>

Name: Warsaw, Poland

Time zone: C<Europe/Warsaw>, C<Poland>

=item * C<pmmqc>

Name: Saint Pierre and Miquelon

Time zone: C<America/Miquelon>

=item * C<pnpcn>

Name: Pitcairn Islands

Time zone: C<Pacific/Pitcairn>

=item * C<prsju>

Name: Puerto Rico

Time zone: C<America/Puerto_Rico>

=item * C<pst8pdt>

Name: POSIX style time zone for US Pacific Time

Time zone: C<PST8PDT>

=item * C<ptfnc>

Name: Madeira, Portugal

Time zone: C<Atlantic/Madeira>

=item * C<ptlis>

Name: Lisbon, Portugal

Time zone: C<Europe/Lisbon>, C<Portugal>

=item * C<ptpdl>

Name: Azores, Portugal

Time zone: C<Atlantic/Azores>

=item * C<pwror>

Name: Palau

Time zone: C<Pacific/Palau>

=item * C<pyasu>

Name: Asunción, Paraguay

Time zone: C<America/Asuncion>

=item * C<qadoh>

Name: Qatar

Time zone: C<Asia/Qatar>

=item * C<rereu>

Name: Réunion

Time zone: C<Indian/Reunion>

=item * C<robuh>

Name: Bucharest, Romania

Time zone: C<Europe/Bucharest>

=item * C<rsbeg>

Name: Belgrade, Serbia

Time zone: C<Europe/Belgrade>

=item * C<ruasf>

Name: Astrakhan, Russia

Time zone: C<Europe/Astrakhan>

=item * C<rubax>

Name: Barnaul, Russia

Time zone: C<Asia/Barnaul>

=item * C<ruchita>

Name: Chita Zabaykalsky, Russia

Time zone: C<Asia/Chita>

=item * C<rudyr>

Name: Anadyr, Russia

Time zone: C<Asia/Anadyr>

=item * C<rugdx>

Name: Magadan, Russia

Time zone: C<Asia/Magadan>

=item * C<ruikt>

Name: Irkutsk, Russia

Time zone: C<Asia/Irkutsk>

=item * C<rukgd>

Name: Kaliningrad, Russia

Time zone: C<Europe/Kaliningrad>

=item * C<rukhndg>

Name: Khandyga Tomponsky, Russia

Time zone: C<Asia/Khandyga>

=item * C<rukra>

Name: Krasnoyarsk, Russia

Time zone: C<Asia/Krasnoyarsk>

=item * C<rukuf>

Name: Samara, Russia

Time zone: C<Europe/Samara>

=item * C<rukvx>

Name: Kirov, Russia

Time zone: C<Europe/Kirov>

=item * C<rumow>

Name: Moscow, Russia

Time zone: C<Europe/Moscow>, C<W-SU>

=item * C<runoz>

Name: Novokuznetsk, Russia

Time zone: C<Asia/Novokuznetsk>

=item * C<ruoms>

Name: Omsk, Russia

Time zone: C<Asia/Omsk>

=item * C<ruovb>

Name: Novosibirsk, Russia

Time zone: C<Asia/Novosibirsk>

=item * C<rupkc>

Name: Kamchatka Peninsula, Russia

Time zone: C<Asia/Kamchatka>

=item * C<rurtw>

Name: Saratov, Russia

Time zone: C<Europe/Saratov>

=item * C<rusred>

Name: Srednekolymsk, Russia

Time zone: C<Asia/Srednekolymsk>

=item * C<rutof>

Name: Tomsk, Russia

Time zone: C<Asia/Tomsk>

=item * C<ruuly>

Name: Ulyanovsk, Russia

Time zone: C<Europe/Ulyanovsk>

=item * C<ruunera>

Name: Ust-Nera Oymyakonsky, Russia

Time zone: C<Asia/Ust-Nera>

=item * C<ruuus>

Name: Sakhalin, Russia

Time zone: C<Asia/Sakhalin>

=item * C<ruvog>

Name: Volgograd, Russia

Time zone: C<Europe/Volgograd>

=item * C<ruvvo>

Name: Vladivostok, Russia

Time zone: C<Asia/Vladivostok>

=item * C<ruyek>

Name: Yekaterinburg, Russia

Time zone: C<Asia/Yekaterinburg>

=item * C<ruyks>

Name: Yakutsk, Russia

Time zone: C<Asia/Yakutsk>

=item * C<rwkgl>

Name: Kigali, Rwanda

Time zone: C<Africa/Kigali>

=item * C<saruh>

Name: Riyadh, Saudi Arabia

Time zone: C<Asia/Riyadh>

=item * C<sbhir>

Name: Guadalcanal, Solomon Islands

Time zone: C<Pacific/Guadalcanal>

=item * C<scmaw>

Name: Mahé, Seychelles

Time zone: C<Indian/Mahe>

=item * C<sdkrt>

Name: Khartoum, Sudan

Time zone: C<Africa/Khartoum>

=item * C<sesto>

Name: Stockholm, Sweden

Time zone: C<Europe/Stockholm>

=item * C<sgsin>

Name: Singapore

Time zone: C<Asia/Singapore>, C<Singapore>

=item * C<shshn>

Name: Saint Helena

Time zone: C<Atlantic/St_Helena>

=item * C<silju>

Name: Ljubljana, Slovenia

Time zone: C<Europe/Ljubljana>

=item * C<sjlyr>

Name: Longyearbyen, Svalbard

Time zone: C<Arctic/Longyearbyen>, C<Atlantic/Jan_Mayen>

=item * C<skbts>

Name: Bratislava, Slovakia

Time zone: C<Europe/Bratislava>

=item * C<slfna>

Name: Freetown, Sierra Leone

Time zone: C<Africa/Freetown>

=item * C<smsai>

Name: San Marino

Time zone: C<Europe/San_Marino>

=item * C<sndkr>

Name: Dakar, Senegal

Time zone: C<Africa/Dakar>

=item * C<somgq>

Name: Mogadishu, Somalia

Time zone: C<Africa/Mogadishu>

=item * C<srpbm>

Name: Paramaribo, Suriname

Time zone: C<America/Paramaribo>

=item * C<ssjub>

Name: Juba, South Sudan

Time zone: C<Africa/Juba>

=item * C<sttms>

Name: São Tomé, São Tomé and Príncipe

Time zone: C<Africa/Sao_Tome>

=item * C<svsal>

Name: El Salvador

Time zone: C<America/El_Salvador>

=item * C<sxphi>

Name: Sint Maarten

Time zone: C<America/Lower_Princes>

=item * C<sydam>

Name: Damascus, Syria

Time zone: C<Asia/Damascus>

=item * C<szqmn>

Name: Mbabane, Swaziland

Time zone: C<Africa/Mbabane>

=item * C<tcgdt>

Name: Grand Turk, Turks and Caicos Islands

Time zone: C<America/Grand_Turk>

=item * C<tdndj>

Name: N'Djamena, Chad

Time zone: C<Africa/Ndjamena>

=item * C<tfpfr>

Name: Kerguelen Islands, French Southern Territories

Time zone: C<Indian/Kerguelen>

=item * C<tglfw>

Name: Lomé, Togo

Time zone: C<Africa/Lome>

=item * C<thbkk>

Name: Bangkok, Thailand

Time zone: C<Asia/Bangkok>

=item * C<tjdyu>

Name: Dushanbe, Tajikistan

Time zone: C<Asia/Dushanbe>

=item * C<tkfko>

Name: Fakaofo, Tokelau

Time zone: C<Pacific/Fakaofo>

=item * C<tldil>

Name: Dili, East Timor

Time zone: C<Asia/Dili>

=item * C<tmasb>

Name: Ashgabat, Turkmenistan

Time zone: C<Asia/Ashgabat>, C<Asia/Ashkhabad>

=item * C<tntun>

Name: Tunis, Tunisia

Time zone: C<Africa/Tunis>

=item * C<totbu>

Name: Tongatapu, Tonga

Time zone: C<Pacific/Tongatapu>

=item * C<trist>

Name: Istanbul, Türkiye

Time zone: C<Europe/Istanbul>, C<Asia/Istanbul>, C<Turkey>

=item * C<ttpos>

Name: Port of Spain, Trinidad and Tobago

Time zone: C<America/Port_of_Spain>

=item * C<tvfun>

Name: Funafuti, Tuvalu

Time zone: C<Pacific/Funafuti>

=item * C<twtpe>

Name: Taipei, Taiwan

Time zone: C<Asia/Taipei>, C<ROC>

=item * C<tzdar>

Name: Dar es Salaam, Tanzania

Time zone: C<Africa/Dar_es_Salaam>

=item * C<uaiev>

Name: Kyiv, Ukraine

Time zone: C<Europe/Kiev>, C<Europe/Kyiv>, C<Europe/Zaporozhye>, C<Europe/Uzhgorod>

=item * C<uaozh>

Zaporizhia (Zaporozhye), Ukraine

Deprecated. See instead C<uaiev>

=item * C<uasip>

Name: Simferopol, Ukraine

Time zone: C<Europe/Simferopol>

=item * C<uauzh>

Uzhhorod (Uzhgorod), Ukraine

Deprecated. See instead C<uaiev>

=item * C<ugkla>

Name: Kampala, Uganda

Time zone: C<Africa/Kampala>

=item * C<umawk>

Name: Wake Island, U.S. Minor Outlying Islands

Time zone: C<Pacific/Wake>

=item * C<umjon>

Johnston Atoll, U.S. Minor Outlying Islands

Deprecated. See instead C<ushnl>

=item * C<ummdy>

Name: Midway Islands, U.S. Minor Outlying Islands

Time zone: C<Pacific/Midway>

=item * C<unk>

Name: Unknown time zone

Time zone: C<Etc/Unknown>

=item * C<usadk>

Name: Adak (Alaska), United States

Time zone: C<America/Adak>, C<America/Atka>, C<US/Aleutian>

=item * C<usaeg>

Name: Marengo (Indiana), United States

Time zone: C<America/Indiana/Marengo>

=item * C<usanc>

Name: Anchorage, United States

Time zone: C<America/Anchorage>, C<US/Alaska>

=item * C<usboi>

Name: Boise (Idaho), United States

Time zone: C<America/Boise>

=item * C<uschi>

Name: Chicago, United States

Time zone: C<America/Chicago>, C<US/Central>

=item * C<usden>

Name: Denver, United States

Time zone: C<America/Denver>, C<America/Shiprock>, C<Navajo>, C<US/Mountain>

=item * C<usdet>

Name: Detroit, United States

Time zone: C<America/Detroit>, C<US/Michigan>

=item * C<ushnl>

Name: Honolulu, United States

Time zone: C<Pacific/Honolulu>, C<US/Hawaii>, C<Pacific/Johnston>

=item * C<usind>

Name: Indianapolis, United States

Time zone: C<America/Indianapolis>, C<America/Fort_Wayne>, C<America/Indiana/Indianapolis>, C<US/East-Indiana>

=item * C<usinvev>

Name: Vevay (Indiana), United States

Time zone: C<America/Indiana/Vevay>

=item * C<usjnu>

Name: Juneau (Alaska), United States

Time zone: C<America/Juneau>

=item * C<usknx>

Name: Knox (Indiana), United States

Time zone: C<America/Indiana/Knox>, C<America/Knox_IN>, C<US/Indiana-Starke>

=item * C<uslax>

Name: Los Angeles, United States

Time zone: C<America/Los_Angeles>, C<US/Pacific>, C<US/Pacific-New>

=item * C<uslui>

Name: Louisville (Kentucky), United States

Time zone: C<America/Louisville>, C<America/Kentucky/Louisville>

=item * C<usmnm>

Name: Menominee (Michigan), United States

Time zone: C<America/Menominee>

=item * C<usmtm>

Name: Metlakatla (Alaska), United States

Time zone: C<America/Metlakatla>

=item * C<usmoc>

Name: Monticello (Kentucky), United States

Time zone: C<America/Kentucky/Monticello>

=item * C<usnavajo>

Shiprock (Navajo), United States

Deprecated. See instead C<usden>

=item * C<usndcnt>

Name: Center (North Dakota), United States

Time zone: C<America/North_Dakota/Center>

=item * C<usndnsl>

Name: New Salem (North Dakota), United States

Time zone: C<America/North_Dakota/New_Salem>

=item * C<usnyc>

Name: New York, United States

Time zone: C<America/New_York>, C<US/Eastern>

=item * C<usoea>

Name: Vincennes (Indiana), United States

Time zone: C<America/Indiana/Vincennes>

=item * C<usome>

Name: Nome (Alaska), United States

Time zone: C<America/Nome>

=item * C<usphx>

Name: Phoenix, United States

Time zone: C<America/Phoenix>, C<US/Arizona>

=item * C<ussit>

Name: Sitka (Alaska), United States

Time zone: C<America/Sitka>

=item * C<ustel>

Name: Tell City (Indiana), United States

Time zone: C<America/Indiana/Tell_City>

=item * C<uswlz>

Name: Winamac (Indiana), United States

Time zone: C<America/Indiana/Winamac>

=item * C<uswsq>

Name: Petersburg (Indiana), United States

Time zone: C<America/Indiana/Petersburg>

=item * C<usxul>

Name: Beulah (North Dakota), United States

Time zone: C<America/North_Dakota/Beulah>

=item * C<usyak>

Name: Yakutat (Alaska), United States

Time zone: C<America/Yakutat>

=item * C<utc>

Name: UTC (Coordinated Universal Time)

Time zone: C<Etc/UTC>, C<Etc/UCT>, C<Etc/Universal>, C<Etc/Zulu>, C<UCT>, C<UTC>, C<Universal>, C<Zulu>

=item * C<utce01>

Name: 1 hour ahead of UTC

Time zone: C<Etc/GMT-1>

=item * C<utce02>

Name: 2 hours ahead of UTC

Time zone: C<Etc/GMT-2>

=item * C<utce03>

Name: 3 hours ahead of UTC

Time zone: C<Etc/GMT-3>

=item * C<utce04>

Name: 4 hours ahead of UTC

Time zone: C<Etc/GMT-4>

=item * C<utce05>

Name: 5 hours ahead of UTC

Time zone: C<Etc/GMT-5>

=item * C<utce06>

Name: 6 hours ahead of UTC

Time zone: C<Etc/GMT-6>

=item * C<utce07>

Name: 7 hours ahead of UTC

Time zone: C<Etc/GMT-7>

=item * C<utce08>

Name: 8 hours ahead of UTC

Time zone: C<Etc/GMT-8>

=item * C<utce09>

Name: 9 hours ahead of UTC

Time zone: C<Etc/GMT-9>

=item * C<utce10>

Name: 10 hours ahead of UTC

Time zone: C<Etc/GMT-10>

=item * C<utce11>

Name: 11 hours ahead of UTC

Time zone: C<Etc/GMT-11>

=item * C<utce12>

Name: 12 hours ahead of UTC

Time zone: C<Etc/GMT-12>

=item * C<utce13>

Name: 13 hours ahead of UTC

Time zone: C<Etc/GMT-13>

=item * C<utce14>

Name: 14 hours ahead of UTC

Time zone: C<Etc/GMT-14>

=item * C<utcw01>

Name: 1 hour behind UTC

Time zone: C<Etc/GMT+1>

=item * C<utcw02>

Name: 2 hours behind UTC

Time zone: C<Etc/GMT+2>

=item * C<utcw03>

Name: 3 hours behind UTC

Time zone: C<Etc/GMT+3>

=item * C<utcw04>

Name: 4 hours behind UTC

Time zone: C<Etc/GMT+4>

=item * C<utcw05>

Name: 5 hours behind UTC

Time zone: C<Etc/GMT+5>, C<EST>

=item * C<utcw06>

Name: 6 hours behind UTC

Time zone: C<Etc/GMT+6>

=item * C<utcw07>

Name: 7 hours behind UTC

Time zone: C<Etc/GMT+7>, C<MST>

=item * C<utcw08>

Name: 8 hours behind UTC

Time zone: C<Etc/GMT+8>

=item * C<utcw09>

Name: 9 hours behind UTC

Time zone: C<Etc/GMT+9>

=item * C<utcw10>

Name: 10 hours behind UTC

Time zone: C<Etc/GMT+10>, C<HST>

=item * C<utcw11>

Name: 11 hours behind UTC

Time zone: C<Etc/GMT+11>

=item * C<utcw12>

Name: 12 hours behind UTC

Time zone: C<Etc/GMT+12>

=item * C<uymvd>

Name: Montevideo, Uruguay

Time zone: C<America/Montevideo>

=item * C<uzskd>

Name: Samarkand, Uzbekistan

Time zone: C<Asia/Samarkand>

=item * C<uztas>

Name: Tashkent, Uzbekistan

Time zone: C<Asia/Tashkent>

=item * C<vavat>

Name: Vatican City

Time zone: C<Europe/Vatican>

=item * C<vcsvd>

Name: Saint Vincent, Saint Vincent and the Grenadines

Time zone: C<America/St_Vincent>

=item * C<veccs>

Name: Caracas, Venezuela

Time zone: C<America/Caracas>

=item * C<vgtov>

Name: Tortola, British Virgin Islands

Time zone: C<America/Tortola>

=item * C<vistt>

Name: Saint Thomas, U.S. Virgin Islands

Time zone: C<America/St_Thomas>, C<America/Virgin>

=item * C<vnsgn>

Name: Ho Chi Minh City, Vietnam

Time zone: C<Asia/Saigon>, C<Asia/Ho_Chi_Minh>

=item * C<vuvli>

Name: Efate, Vanuatu

Time zone: C<Pacific/Efate>

=item * C<wfmau>

Name: Wallis Islands, Wallis and Futuna

Time zone: C<Pacific/Wallis>

=item * C<wsapw>

Name: Apia, Samoa

Time zone: C<Pacific/Apia>

=item * C<yeade>

Name: Aden, Yemen

Time zone: C<Asia/Aden>

=item * C<ytmam>

Name: Mayotte

Time zone: C<Indian/Mayotte>

=item * C<zajnb>

Name: Johannesburg, South Africa

Time zone: C<Africa/Johannesburg>

=item * C<zmlun>

Name: Lusaka, Zambia

Time zone: C<Africa/Lusaka>

=item * C<zwhre>

Name: Harare, Zimbabwe

Time zone: C<Africa/Harare>

=back

See the L<standard documentation|https://unicode.org/reports/tr35/#Time_Zone_Identifiers> for more information.

=item * C<va>

A L<Unicode Variant Identifier|https://unicode.org/reports/tr35/#UnicodeVariantIdentifier> defines a special variant used for locales.

=back

=head2 Transform extensions

This is used for transliterations, transcriptions, translations, etc, as per L<RFC6497|https://datatracker.ietf.org/doc/html/rfc6497>

For example:

=over 4

=item * C<ja-t-it>

The content is Japanese, transformed from Italian.

=item * C<ja-Kana-t-it>

The content is Japanese Katakana, transformed from Italian.

=item * C<und-Latn-t-und-cyrl>

The content is in the Latin script, transformed from the Cyrillic script.

=item * C<und-Cyrl-t-und-latn-m0-ungegn-2007>

The content is in Cyrillic, transformed from Latin, according to a UNGEGN specification dated 2007.

The date is of format C<YYYYMMDD> all without space, and the month and day information should be provided only when necessary for clarification, as per the L<RFC6497, section 2.5(c)|https://datatracker.ietf.org/doc/html/rfc6497#section-2.5>

=item * C<und-Cyrl-t-und-latn-m0-ungegn>

Same, but without year.

=back

The complete list of valid subtags is as follows. They are all two to eight alphanumeric characters.

=over 4

=item * C<d0>

Transform destination: for non-languages/scripts, such as fullwidth-halfwidth conversion

See also C<s0>

Possible L<values|https://github.com/unicode-org/cldr/blob/maint/maint-41/common/bcp47/transform-destination.xml> are:

=over 8

=item * C<accents>

Map base + punctuation, etc to accented characters

=item * C<ascii>

Map as many characters to the closest ASCII character as possible

=item * C<casefold>

Apply Unicode case folding

=item * C<charname>

Map each character to its Unicode name

=item * C<digit>

Convert to digit form of accent

=item * C<fcc>

Map string to the FCC format; L<http://unicode.org/notes/tn5>

=item * C<fcd>

Map string to the FCD format; L<http://unicode.org/notes/tn5>

=item * C<fwidth>

Map characters to their fullwidth equivalents

=item * C<hex>

Map characters to a hex equivalents, eg C<a> to C<\u0061>; for hex variants see L<transform.xml|https://github.com/unicode-org/cldr/blob/maint/maint-41/common/bcp47/transform.xml>

=item * C<hwidth>

Map characters to their halfwidth equivalents

=item * C<lower>

Apply Unicode full lowercase mapping

=item * C<morse>

Map Unicode to Morse Code encoding

=item * C<nfc>

Map string to the Unicode NFC format

=item * C<nfd>

Map string to the Unicode NFD format

=item * C<nfkc>

Map string to the Unicode NFKC format

=item * C<nfkd>

Map string to the Unicode NFKD format

=item * C<npinyin>

Map pinyin written with tones to the numeric form

=item * C<null>

Make no change in the string

=item * C<publish>

Map to preferred forms for publishing, such as C<, >, C<—>

=item * C<remove>

Remove every character in the string

=item * C<title>

Apply Unicode full titlecase mapping

=item * C<upper>

Apply Unicode full uppercase mapping

=item * C<zawgyi>

Map Unicode to Zawgyi Myanmar encoding

=back

=item * C<h0>

Hybrid Locale Identifiers: C<h0> with the value C<hybrid> indicates that the C<-t-> value is a language that is mixed into the main language tag to form a hybrid.

For L<example|https://unicode.org/reports/tr35/#Hybrid_Locale>:

=over 8

=item * C<hi-t-en-h0-hybrid>

Hybrid Deva - Hinglish

Hindi-English hybrid where the script is Devanagari*

=item * C<hi-Latn-t-en-h0-hybrid>

Hybrid Latin - Hinglish

Hindi-English hybrid where the script is Latin*

=item * C<ru-t-en-h0-hybrid>

Hybrid Cyrillic - Runglish

Russian with an admixture of American English

=item * C<ru-t-en-gb-h0-hybrid>

Hybrid Cyrillic - Runglish

Russian with an admixture of British English

=item * C<en-t-zh-h0-hybrid>

Hybrid Latin - Chinglish

American English with an admixture of Chinese (Simplified Mandarin Chinese)

=item * C<en-t-zh-hant-h0-hybrid>

Hybrid Latin - Chinglish

American English with an admixture of Chinese (Traditional Mandarin Chinese)

=back

=item * C<i0>

Input Method Engine transform: used to indicate an input method transformation, such as one used by a client-side input method. The first subfield in a sequence would typically be a C<platform> or vendor designation.

For example: C<zh-t-i0-pinyin>

Possible L<values|https://github.com/unicode-org/cldr/blob/maint/maint-41/common/bcp47/transform_ime.xml> are:

=over 8

=item * C<handwrit>

Handwriting input: used when the only information known (or requested) is that the text was (or is to be) converted using an handwriting input.

=item * C<pinyin>

Pinyin input: for simplified Chinese characters. See also L<http://en.wikipedia.org/wiki/Pinyin_method>.

=item * C<und>

The choice of input method is not specified. Used when the only information known (or requested) is that the text was (or is to be) converted using an input method engine

=item * C<wubi>

Wubi input: for simplified Chinese characters. For background information, see L<http://en.wikipedia.org/wiki/Wubi_method>

=back

=item * C<k0>

Keyboard transform: used to indicate a keyboard transformation, such as one used by a client-side virtual keyboard. The first subfield in a sequence would typically be a C<platform> designation, representing the platform that the keyboard is intended for.

For example: C<en-t-k0-dvorak>

Possible L<values|https://github.com/unicode-org/cldr/blob/maint/maint-41/common/bcp47/transform_keyboard.xml> are:

=over 8

=item * C<101key>

101 key layout.

=item * C<102key>

102 key layout.

=item * C<600dpi>

Keyboard for a 600 dpi device.

=item * C<768dpi>

Keyboard for a 768 dpi device.

=item * C<android>

Android keyboard.

=item * C<azerty>

A AZERTY-based keyboard or one that approximates AZERTY in a different script.

=item * C<chromeos>

ChromeOS keyboard.

=item * C<colemak>

Colemak keyboard layout. The Colemak keyboard is an alternative to the QWERTY and dvorak keyboards. http://colemak.com/.

=item * C<dvorak>

Dvorak keyboard layout. See also L<http://en.wikipedia.org/wiki/Dvorak_Simplified_Keyboard>.

=item * C<dvorakl>

Dvorak left-handed keyboard layout. See also L<http://en.wikipedia.org/wiki/File:KB_Dvorak_Left.svg>.

=item * C<dvorakr>

Dvorak right-handed keyboard layout. See also L<http://en.wikipedia.org/wiki/File:KB_Dvorak_Right.svg>.

=item * C<el220>

Greek 220 keyboard. See also L<http://www.microsoft.com/resources/msdn/goglobal/keyboards/kbdhela2.html>.

=item * C<el319>

Greek 319 keyboard. See also L<ftp://ftp.software.ibm.com/software/globalization/keyboards/KBD319.pdf>.

=item * C<extended>

A keyboard that has been enhanced with a large number of extra characters.

=item * C<googlevk>

Google virtual keyboard.

=item * C<isiri>

Persian ISIRI keyboard. Based on ISIRI 2901:1994 standard. See also L<http://behdad.org/download/Publications/persiancomputing/a007.pdf>.

=item * C<legacy>

A keyboard that has been replaced with a newer standard but is kept for legacy purposes.

=item * C<lt1205>

Lithuanian standard keyboard, based on the LST 1205:1992 standard. See also L<http://www.kada.lt/litwin/>.

=item * C<lt1582>

Lithuanian standard keyboard, based on the LST 1582:2000 standard. See also L<http://www.kada.lt/litwin/>.

=item * C<nutaaq>

Inuktitut Nutaaq keyboard. See also L<http://www.pirurvik.ca/en/webfm_send/15>.

=item * C<osx>

Mac OSX keyboard.

=item * C<patta>

Thai Pattachote keyboard. This is a less frequently used layout in Thai (Kedmanee layout is more popular). See also L<http://www.nectec.or.th/it-standards/keyboard_layout/thai-key.htm>.

=item * C<qwerty>

QWERTY-based keyboard or one that approximates QWERTY in a different script.

=item * C<qwertz>

QWERTZ-based keyboard or one that approximates QWERTZ in a different script.

=item * C<ta99>

Tamil 99 keyboard. See also L<http://www.tamilvu.org/Tamilnet99/annex1.htm>.

=item * C<und>

The vender for the keyboard is not specified. Used when the only information known (or requested) is that the text was (or is to be) converted using an keyboard.

=item * C<var>

A keyboard layout with small variations from the default.

=item * C<viqr>

Vietnamese VIQR layout, based on L<http://tools.ietf.org/html/rfc1456>.

=item * C<windows>

Windows keyboard.

=back

=item * C<m0>

Transform extension mechanism: to reference an authority or rules for a type of transformation.

For example: C<und-Latn-t-ru-m0-ungegn-2007>

Possible L<values|https://github.com/unicode-org/cldr/blob/maint/maint-41/common/bcp47/transform.xml> are:

=over 8

=item * C<aethiopi>

Encylopedia Aethiopica Transliteration

=item * C<alaloc>

American Library Association-Library of Congress

=item * C<betamets>

Beta Maṣāḥǝft Transliteration

=item * C<bgn>

US Board on Geographic Names

=item * C<buckwalt>

Buckwalter Arabic transliteration system

=item * C<c11>

for hex transforms, using the C11 syntax: \u0061\U0001F4D6

=item * C<css>

for hex transforms, using the CSS syntax: \61 \01F4D6, spacing where necessary

=item * C<din>

Deutsches Institut für Normung

=item * C<es3842>

Ethiopian Standards Agency ES 3842:2014 Ethiopic-Latin Transliteration

=item * C<ewts>

Extended Wylie Transliteration Scheme

=item * C<gost>

Euro-Asian Council for Standardization, Metrology and Certification

=item * C<gurage>

Gurage Legacy to Modern Transliteration

=item * C<gutgarts>

Yaros Gutgarts Ethiopic-Cyrillic Transliteration

=item * C<iast>

International Alphabet of Sanskrit Transliteration

=item * C<iesjes>

IES/JES Amharic Transliteration

=item * C<iso>

International Organization for Standardization

=item * C<java>

for hex transforms, using the Java syntax: \u0061\uD83D\uDCD6

=item * C<lambdin>

Thomas Oden Lambdin Ethiopic-Latin Transliteration

=item * C<mcst>

Korean Ministry of Culture, Sports and Tourism

=item * C<mns>

Mongolian National Standard

=item * C<percent>

for hex transforms, using the percent syntax: %61%F0%9F%93%96

=item * C<perl>

for hex transforms, using the perl syntax: \x{61}\x{1F4D6}

=item * C<plain>

for hex transforms, with no surrounding syntax, spacing where necessary: 0061 1F4D6

=item * C<prprname>

transform variant for proper names

=item * C<satts>

Standard Arabic Technical Transliteration System (SATTS)

=item * C<sera>

System for Ethiopic Representation in ASCII

=item * C<tekieali>

Tekie Alibekit Blin-Latin Transliteration

=item * C<ungegn>

United Nations Group of Experts on Geographical Names

=item * C<unicode>

to hex with the Unicode syntax: U+0061 U+1F4D6, spacing where necessary

=item * C<xaleget>

Eritrean Ministry of Education Blin-Latin Transliteration

=item * C<xml>

for hex transforms, using the xml syntax: &#x61;&#x1F4D6;

=item * C<xml10>

for hex transforms, using the xml decimal syntax: &#97;&#128214;

=back

=item * C<s0>

Transform source: for non-languages/scripts, such as fullwidth-halfwidth conversion

See also C<d0>

Possible L<values|https://github.com/unicode-org/cldr/blob/maint/maint-41/common/bcp47/transform-destination.xml> are:

=over 8

=item * C<accents>

Accented characters to map base + punctuation, etc

=item * C<ascii>

Map from ASCII to the target, perhaps using different conventions

=item * C<hex>

Map characters from hex equivalents, trying all variants, eg C<U+0061> to C<a>; for hex variants see L<transform.xml|https://github.com/unicode-org/cldr/blob/maint/maint-41/common/bcp47/transform.xml>

=item * C<morse>

Map Morse Code to Unicode encoding

=item * C<npinyin>

Map the numeric form of pinyin to the tone format

=item * C<publish>

Map publishing characters, such as C<, >, C<—>, to from vanilla characters

=item * C<zawgyi>

Map Zawgyi Myanmar encoding to Unicode

=back

=item * C<t0>

Machine Translation: used to indicate content that has been machine translated, or a request for a particular type of machine translation of content. The first subfield in a sequence would typically be a C<platform> or vendor designation.

For example: C<ja-t-de-t0-und>

=item * C<x0>

Private Use.

For example: C<ja-t-de-t0-und-x0-medical>

=back

=head2 Collation Options

L<Parametric settings|https://unicode.org/reports/tr35/tr35-collation.html#Setting_Options> can be specified in language tags or in rule syntax (in the form [keyword value] ). For example, C<-ks-level2> or [strength 2] will only compare strings based on their primary and secondary weights.

The options description below is taken from the LDML standard, and reflect how the algorithm works when implemented by web browser, or other runtime environment. This module does not do any of those algorithms. The documentation is only here for your benefit and convenience.

See the L<standard documentation|https://unicode.org/reports/tr35/tr35-collation.html> and the L<DUCET (Default Unicode Collation Element Table)|https://www.unicode.org/reports/tr10/#Default_Unicode_Collation_Element_Table> for more information.

=over 4

=item * C<ka> or C<colAlternate>

Sets alternate handling for variable weights.

Possible L<values|https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L34> are optional and can be:

=over 8

=item * C<noignore> or C<non-ignorable>

Default value.

=item * C<shifted>

=back

=item * C<kb> or C<colBackwards>

Sets collation parameter key for backward collation weight.

Sets alternate handling for variable weights.

Possible L<values|https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L39> are optional and can be: C<true> or C<yes>, C<false> (default) or C<no>

=item * C<kc> or C<colCaseLevel>

Sets collation parameter key for case level.

Specifies a boolean. If C<on>, a level consisting only of case characteristics will be inserted in front of tertiary level, as a "Level 2.5". To ignore accents but take case into account, set strength to C<primary> and case level to C<on>.

Possible L<values|https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L44> are optional and can be: C<true> or C<yes>, C<false> (default) or C<no>

=item * C<kf> or C<colCaseFirst>

Sets collation parameter key for ordering by case.

If set to C<upper>, causes upper case to sort before lower case. If set to C<lower>, causes lower case to sort before upper case.

Possible L<values|https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L49> are: C<upper>, C<lower>, C<false> (default) or C<no>

=item * C<kh> or C<colHiraganaQuaternary>

Sets collation parameter key for special Hiragana handling.

This is deprecated by the LDML standard.

Specifies a boolean. Controls special treatment of Hiragana code points on quaternary level. If turned on, Hiragana codepoints will get lower values than all the other non-variable code points in shifted.

Possible L<values|https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L55> are optional and can be: C<true> (default) or C<yes>, C<false> or C<no>

=item * C<kk> or C<colNormalization>

Sets collation parameter key for normalisation.

Specifies a boolean. If on, then the normal L<UCA|https://www.unicode.org/reports/tr41/#UTS10> algorithm is used.

Possible L<values|https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L60> are optional and can be: C<true> (default) or C<yes>, C<false> or C<no>

=item * C<kn> or C<colNumeric>

Sets collation parameter key for numeric handling.

Specifies a boolean. If set to on, any sequence of Decimal Digits is sorted at a primary level with its numeric value.

Possible L<values|https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L65> are optional and can be: C<true> or C<yes>, C<false> (default) or C<no>

=item * C<kr> or C<colReorder>

Sets collation reorder codes.

Specifies a reordering of scripts or other significant blocks of characters such as symbols, punctuation, and digits.

Possible L<values|https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L70> are: C<currency>, C<digit>, C<punct>, C<space>, C<symbol>, or any BCP47 script ID.

Also possible: C<others> where all codes not explicitly mentioned should be ordered. The script code Zzzz (Unknown Script) is a synonym for others.

For example:

=over 8

=item * C<en-u-kr-latn-digit>

Reorder digits after Latin characters.

=item * C<en-u-kr-arab-cyrl-others-symbol>

Reorder Arabic characters first, then Cyrillic, and put symbols at the end—after all other characters.

=item * C<en-u-kr-others>

Remove any locale-specific reordering, and use DUCET order for reordering blocks.

=back

=item * C<ks> or C<colStrength>

Sets the collation parameter key for collation strength used for comparison.

Possible L<values|https://github.com/unicode-org/cldr/blob/5ae2965c8afed18f89f54195db72205aa5b6fc3a/common/bcp47/collation.xml#L79> are:

=over 8

=item * C<level1> or C<primary>

=item * C<level2> or C<secondary>

=item * C<level3> (default) or C<tertiary>

=item * C<level4> or C<quaternary> or C<quarternary>

=item * C<identic> or C<identical>

=back

=item * C<kv>

Sets the collation parameter key for C<maxVariable>, the last reordering group to be affected by C<ka-shifted>.

Possible values are:

=over 8

=item * C<currency>

Spaces, punctuation and all symbols are affected by ka-shifted.

=item * C<punct>

Spaces and punctuation are affected by ka-shifted (CLDR default).

=item * C<space>

Only spaces are affected by ka-shifted.

=item * C<symbol>

Spaces, punctuation and symbols except for currency symbols are affected by ka-shifted (UCA default).

=back

=item * C<vt>

Sets the parameter key for the variable top.

B<This is deprecated by the LDML standard.>

=back

=head1 SERIALISATION

C<Locale::Unicode> supports L<Storable::Improved>, L<Storable>, L<Sereal> and L<CBOR|CBOR::XS> serialisation, by implementing the methods C<FREEZE>, C<THAW>, C<STORABLE_freeze>, C<STORABLE_thaw>

For serialisation with L<Sereal>, make sure to instantiate the L<Sereal encoder|Sereal::Encoder> with the C<freeze_callbacks> option set to true, otherwise, C<Sereal> will not use the C<FREEZE> and C<THAW> methods.

See L<Sereal::Encoder/"FREEZE/THAW CALLBACK MECHANISM"> for more information.

For L<CBOR|CBOR::XS>, it is recommended to use the option C<allow_sharing> to enable the reuse of references, such as:

    my $cbor = CBOR::XS->new->allow_sharing;

Also, if you use the option C<allow_tags> with L<JSON>, then all of those modules will work too, since this option enables support for the C<FREEZE> and C<THAW> methods.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<https://github.com/unicode-org/cldr/tree/main/common/bcp47>, L<https://en.wikipedia.org/wiki/IETF_language_tag>

L<https://www.rfc-editor.org/info/bcp47>

L<Unicode Locale Data Markup Language|https://unicode.org/reports/tr35/>

L<BCP47|https://www.rfc-editor.org/rfc/bcp/bcp47.txt>

L<RFC6067 on the Unicode extensions|https://datatracker.ietf.org/doc/html/rfc6067>

L<RFC6497 on the transformation extension|https://datatracker.ietf.org/doc/html/rfc6497>

See L<HTML::Object::Locale> for an implementation of Web API class L<Intl.Locale|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Locale>

L<Unicode::Collate>, L<Unicode::Collate::Locale>, L<Unicode::Unihan>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2024 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
