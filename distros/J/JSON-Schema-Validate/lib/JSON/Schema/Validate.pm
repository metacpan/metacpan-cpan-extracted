##----------------------------------------------------------------------------
## JSON Schema Validator - ~/lib/JSON/Schema/Validate.pm
## Version v0.7.0
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2025/11/07
## Modified 2025/12/17
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package JSON::Schema::Validate;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use vars qw( $VERSION $DEBUG );
    use B ();
    use JSON ();
    use Scalar::Util qw( blessed looks_like_number reftype refaddr );
    use List::Util qw( first any all );
    use Encode ();
    our $VERSION = 'v0.7.0';
};

use v5.16.0;
use strict;
use warnings;

sub new
{
    my $class  = shift( @_ );
    my $schema = shift( @_ );
    if( defined( $schema ) && ( !ref( $schema ) || ref( $schema ) ne 'HASH' ) )
    {
        die( "You provided a value (", overload::StrVal( $schema ), "), but it is not an hash reference. You must create a new $class object like this: $class->new( \$schema, \%opts );" );
    }

    my $self =
    {
        comment_handler     => undef,
        # boolean
        compile_on          => 0,
        # { schema, anchors, id_index, base }
        compiled            => undef,
        # boolean; when 0, failures don’t invalidate; when 1, they do
        content_assert      => 0,
        content_decoders    => {},
        errors              => [],
        # boolean; when true, then non-standard extensions are enabled.
        extensions          => 0,
        formats             => {},
        # boolean
        ignore_req_vocab    => 0,
        last_error          => '',
        last_trace          => [],
        max_errors          => 200,
        media_validators    => {},
        # boolean
        normalize_instance  => 1,
        # boolean: when true, prune unknown properties before validate()
        prune_unknown       => 0,
        # ($abs_uri) -> $schema_hashref
        resolver            => undef,
        schema              => _clone( $schema ),
        # 0 = unlimited
        trace_limit         => 0,
        # boolean
        trace_on            => 0,
        # 0 = record all
        trace_sample        => 0,
        # boolean; when true, 'uniqueKeys' extension is enabled.
        unique_keys         => 0,
        # internal boolean; not an option
        vocab_checked       => 0,
        vocab_support       => {},
    };

    bless( $self, $class );
    my $opts = $self->_get_args_as_hash( @_ );
    my @bool_options = qw(
        content_assert
        extensions
        ignore_req_vocab
        normalize_instance
        prune_unknown
        unique_keys
    );
    foreach my $opt ( @bool_options )
    {
        next unless( exists( $opts->{ $opt } ) );
        $self->{ $opt } = $opts->{ $opt } ? 1 : 0
    }
    # Make sure the boolean value for 'extensions' is propagated to 'unique_keys' unless the option 'unique_keys' has been explicitly specified, and then we do not want to overwrite it.
    $self->{unique_keys} = $self->{extensions} unless( exists( $opts->{unique_keys} ) );
    if( exists( $opts->{ignore_unknown_required_vocab} ) )
    {
        $self->{ignore_req_vocab} = $opts->{ignore_unknown_required_vocab} ? 1 : 0;
    }
    if( exists( $opts->{compile} ) )
    {
        $self->{compile_on} = $opts->{compile} ? 1 : 0;
    }
    if( exists( $opts->{trace} ) )
    {
        $self->{trace_on} = $opts->{trace} ? 1 : 0;
    }

    my @other_options = qw( max_errors trace_limit );
    foreach my $opt ( @other_options )
    {
        next unless( exists( $opts->{ $opt } ) );
        $self->{ $opt } = $opts->{ $opt };
    }

    if( exists( $opts->{trace_sample} ) )
    {
        # Check for percentage integer (0 to 100)
        if( $opts->{trace_sample} =~ /^([0-9]{1,2}|100)$/ )
        {
            $self->{trace_sample} = $opts->{trace_sample};
        }
        else
        {
            warn( "Warning only: invalid value for option 'trace_sample'." ) if( warnings::enabled() );
        }
    }

    # User-supplied format callbacks (override precedence left to caller order)
    if( $opts->{format} && ref( $opts->{format} ) eq 'HASH' )
    {
        $self->{formats}->{ $_ } = $opts->{format}->{ $_ } for( keys( %{$opts->{format}} ) );
    }
    $self->{vocab_support} = $opts->{vocab_support} ? { %{$opts->{vocab_support}} } : {};

    $self->_check_vocabulary_required unless( $self->{ignore_req_vocab} );
    $self->_register_builtin_media_validators() if( $self->{content_assert} );
    $self->{compiled} = _compile_root( $self->{schema} ) if( $self->{compile_on} );
    return( $self );
}

# $js->compile -> enables it
# $js->compile(1) -> enables it
# $js->compile(0) -> disables it
sub compile
{
    my( $self, $bool ) = @_;
    my $on = defined( $bool ) ? $bool : 1;
    $self->{compile_on} = $on;

    if( $self->{compile_on} && !$self->{compiled} )
    {
        $self->{compiled} = _compile_root( $self->{schema} );
    }
    return( $self );
}

sub compile_js
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );

    my $schema = $self->{schema}
        or die( "No schema loaded; cannot compile to JavaScript" );

    # Public JS API name, e.g. "validateIncorporation"
    my $name = exists( $opts->{name} ) && defined( $opts->{name} ) && length( $opts->{name} )
        ? $opts->{name}
        : 'validate';

    # Max errors to collect on the client side
    my $max_errors = exists( $opts->{max_errors} ) ? int( $opts->{max_errors} ) : 200;
    $max_errors = 0 if( $max_errors < 0 );

    my %seen;          # schema_pointer -> function name
    my $counter = 0;   # for generating unique function names
    my @funcs;         # accumulated JS validator functions

    my $root_ptr = '#';

    # Pass $opts down so we can see ecma => ... inside the compiler.
    my $root_fn  = $self->_compile_js_node( $schema, $root_ptr, \%seen, \@funcs, \$counter, $schema, $opts );

    my $js = '';

    $js .= <<'JS_RUNTIME';
(function(global)
{
    "use strict";

    function _jsv_err(ctx, path, keyword, message, schemaPtr)
    {
        if(ctx.maxErrors && ctx.errors.length >= ctx.maxErrors)
        {
            return;
        }
        ctx.errors.push({
            path: path,
            keyword: keyword,
            message: message,
            schema_pointer: schemaPtr
        });
    }

    function _jsv_typeOf(x)
    {
        if(x === null)
        {
            return "null";
        }
        if(Array.isArray ? Array.isArray(x) : Object.prototype.toString.call(x) === "[object Array]")
        {
            return "array";
        }
        var t = typeof x;
        if(t === "number" && isFinite(x) && Math.floor(x) === x)
        {
            // distinguish "integer" for convenience
            return "integer";
        }
        return t;
    }

    function _jsv_hasOwn(obj, prop)
    {
        return Object.prototype.hasOwnProperty.call(obj, prop);
    }

JS_RUNTIME

    # Public entry point
    $js .= <<"JS_RUNTIME";
    function $name(instance)
    {
        var ctx = { errors: [], maxErrors: $max_errors };
        $root_fn(instance, "#", ctx);
        return ctx.errors;
    }

JS_RUNTIME

    # Attach to global (browser: window) in a conservative way
    $js .= <<"JS_RUNTIME";
    if(typeof global === 'object' && global)
    {
        global.$name = $name;
    }

JS_RUNTIME

    # Emit all compiled validator functions, indented one level
    $js .= join( "\n\n", map{ '    ' . join( "\n    ", split( /\n/, $_ ) ) } @funcs );

    $js .= <<'JS_RUNTIME';

})(this);
JS_RUNTIME

    return( $js );
}

# $js->content_checks -> enables it
# $js->content_checks(1) -> enables it
# $js->content_checks(0) -> disables it
sub content_checks
{
    my( $self, $bool ) = @_;
    my $on = defined( $bool ) ? $bool : 1;
    $self->{content_assert} = $on ? 1 : 0;
    $self->_register_builtin_media_validators() if( $self->{content_assert} );
    return( $self );
}

# TODO: Backward compatibility, but need to remove it
{
    no warnings 'once';
    *enable_content_checks = \&content_checks;
}

sub error { $_[0]->{last_error} }

# We return a copy of the array reference containing the error objects
sub errors { return( [@{$_[0]->{errors}}] ); }

sub extensions
{
    my( $self, $bool ) = @_;
    my $on = defined( $bool ) ? $bool : 1;
    $self->{extensions} = $on;
    $self->unique_keys( $on );
    return( $self );
}

sub get_trace
{
    my( $self ) = @_;
    return( [@{ $self->{last_trace} || [] }] );
}

# Accessor-only method. See trace_limit for its mutator alter ego.
sub get_trace_limit { 0 + ( $_[0]->{trace_limit} // 0 ) }

# $js->ignore_unknown_required_vocab -> enables it
# $js->ignore_unknown_required_vocab(1) -> enables it
# $js->ignore_unknown_required_vocab(0) -> disables it
sub ignore_unknown_required_vocab
{
    my( $self, $bool ) = @_;
    my $on = defined( $bool ) ? $bool : 1;
    $self->{ignore_req_vocab} = $on;
    return( $self );
}

sub is_compile_enabled { $_[0]->{compile_on} ? 1 : 0 }

sub is_content_checks_enabled { $_[0]->{content_assert} ? 1 : 0 }

# Accessor only method. See trace or the mutator vession.
sub is_trace_on { $_[0]->{trace_on} ? 1 : 0 }

sub is_unique_keys_enabled { $_[0]->{unique_keys} ? 1 : 0 }

sub is_unknown_required_vocab_ignored { $_[0]->{ignore_req_vocab} ? 1 : 0 }

sub is_valid
{
    my $self = shift( @_ );
    my $data = shift( @_ );

    my $opts = $self->_get_args_as_hash( @_ );
    # Optional: allow overriding max_errors for this call only
    # (e.g. $v->is_valid( $data, max_errors => 1 );)
    $opts->{max_errors} //= 1;

    # validate already populates $self->{errors}; is_valid just returns boolean
    return( $self->validate( $data, $opts ) ? 1 : 0 );
}

# Example:
# my $pruned = $js->prune_instance( $incoming_data );
sub prune_instance
{
    my( $self, $data ) = @_;

    # Work on a cloned copy if normalize_instance is on,
    # to remain consistent with validate().
    if( $self->{normalize_instance} )
    {
        my $json = JSON->new->allow_nonref(1)->canonical(1);
        $data = $json->decode( $json->encode( $data ) );
    }

    return( $self->_prune_with_schema( $self->{schema}, $data ) );
}

sub prune_unknown
{
    my( $self, $bool ) = @_;
    my $on = defined( $bool ) ? $bool : 1;
    $self->{prune_unknown} = $on ? 1 : 0;
    return( $self );
}

sub register_builtin_formats
{
    my( $self ) = @_;

    require DateTime;
    require DateTime::Duration;
    local $@;
    my $has_iso  = eval{ require DateTime::Format::ISO8601; 1 } ? 1 : 0;
    my $has_idn  = eval{ require Net::IDN::Encode; 1 } ? 1 : 0;
    # perl -MRegexp::Common=Email::Address -lE 'say $Regexp::Common::RE{Email}{Address}'
    state $email_re = qr/\A(?:(?^u:(?:(?^u:(?>(?^u:(?^u:(?>(?^u:(?>(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|\.|\s*"(?^u:(?^u:[^\\"])|(?^u:\\(?^u:[^\x0A\x0D])))+"\s*))+))|(?>(?^u:(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*"(?^u:(?^u:[^\\"])|(?^u:\\(?^u:[^\x0A\x0D])))*"(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*)))+))?)(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*<(?^u:(?^u:(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*(?^u:(?>[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?:\.[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+)*))(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*"(?^u:(?^u:[^\\"])|(?^u:\\(?^u:[^\x0A\x0D])))*"(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*)))\@(?^u:(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*(?^u:(?>[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?:\.[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+)*))(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*\[(?:\s*(?^u:(?^u:[^\[\]\\])|(?^u:\\(?^u:[^\x0A\x0D]))))*\s*\](?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))))>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*)))|(?^u:(?^u:(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*(?^u:(?>[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?:\.[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+)*))(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*"(?^u:(?^u:[^\\"])|(?^u:\\(?^u:[^\x0A\x0D])))*"(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*)))\@(?^u:(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*(?^u:(?>[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+(?:\.[^\x00-\x1F\x7F()<>\[\]:;@\\,."\s]+)*))(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*))|(?^u:(?>(?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*\[(?:\s*(?^u:(?^u:[^\[\]\\])|(?^u:\\(?^u:[^\x0A\x0D]))))*\s*\](?^u:(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))|(?>\s+))*)))))(?>(?^u:(?>\s*\((?:\s*(?^u:(?^u:(?>[^()\\]+))|(?^u:\\(?^u:[^\x0A\x0D]))|))*\s*\)\s*))*)))\z/;

    my %F;

    # RFC3339 date-time / date / time
    $F{'date-time'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );

        # Preferred path when DateTime::Format::ISO8601 is available
        if( $has_iso )
        {
            return( eval{ DateTime::Format::ISO8601->parse_datetime( $s ) ? 1 : 0 } ? 1 : 0 );
        }

        # Fallback: parse and validate with DateTime itself
        # YYYY-MM-DDThh:mm:ss[.fraction](Z|±hh:mm)
        return(0) unless( $s =~ /\A
            (\d{4})-(\d{2})-(\d{2})      # date
            T
            (\d{2}):(\d{2}):(\d{2})      # time
            (?:\.\d+)?                   # optional fraction
            (?:Z|[+\-]\d{2}:\d{2})       # offset
        \z/x );

        my( $y, $m, $d, $H, $M, $S ) = ( $1, $2, $3, $4, $5, $6 );

        my $ok = eval
        {
            DateTime->new(
                year   => $y,
                month  => $m,
                day    => $d,
                hour   => $H,
                minute => $M,
                second => $S,
            );
            1;
        };

        return( $ok ? 1 : 0 );
    };

    $F{'date'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return(0) unless( $s =~ /\A(\d{4})-(\d{2})-(\d{2})\z/ );
        my( $y, $m, $d ) = ( $1, $2, $3 );
        return eval{ DateTime->new( year => $y, month => $m, day => $d ); 1 } ? 1 : 0;
    };

    $F{'time'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        if( $has_iso )
        {
            return eval{ DateTime::Format::ISO8601->parse_datetime( "1970-01-01T$s" ) ? 1 : 0 } ? 1 : 0;
        }
        return $s =~ /\A
            (?:[01]\d|2[0-3])              # HH
            :
            (?:[0-5]\d)                     # MM
            :
            (?:[0-5]\d)                     # SS
            (?:\.\d+)?                      # .fraction
            (?:Z|[+\-](?:[01]\d|2[0-3]):[0-5]\d)?  # offset
        \z/x ? 1 : 0;
    };

    # Duration
    $F{'duration'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return(0) unless( $s =~ /\A
            P(?:
                (?:(\d+)Y)?
                (?:(\d+)M)?
                (?:(\d+)D)?
            )?
            (?:T
                (?:(\d+)H)?
                (?:(\d+)M)?
                (?:(\d+(?:\.\d+)?)S)?
            )?
        \z/x );
        my( $y, $mo, $d, $h, $mi, $se ) = ( $1 || 0, $2 || 0, $3 || 0, $4 || 0, $5 || 0, $6 || 0 );
        return eval{
            DateTime::Duration->new(
                years => $y, months => $mo, days => $d,
                hours => $h, minutes => $mi, seconds => $se
            ); 1;
        } ? 1 : 0;
    };

    # Email / IDN email
    # Plain email (ASCII) — unchanged
    $F{'email'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return( $s =~ $email_re ? 1 : 0 );
    };

    # IDN email: punycode the domain, validate with same regex
    $F{'idn-email'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return(0) unless( $s =~ /\A(.+)\@(.+)\z/s );  # keep local-part as-is (EAI allows UTF-8)
        my( $local, $domain ) = ( $1, $2 );

        if( $has_idn )
        {
            local $@;
            my $ascii = eval{ Net::IDN::Encode::domain_to_ascii( $domain ) };
            return(0) unless( defined( $ascii ) && length( $ascii ) );

            my $candidate = "$local\@$ascii";
            return( $candidate =~ $email_re ? 1 : 0 );
        }

        # Fallback: if the domain already *looks* ASCII, validate directly
        if( $domain =~ /\A[[:ascii:]]+\z/ )
        {
            my $candidate = "$local\@$domain";
            return( $candidate =~ $email_re ? 1 : 0 );
        }

        # Without IDN module, fall back to permissive Unicode domain check + ASCII regex
        return(0);
    };

    # Hostnames
    $F{'hostname'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return(0) if( length( $s ) > 253 );
        for my $label ( split( /\./, $s ) )
        {
            return(0) unless( length( $label ) >= 1 && length( $label ) <= 63 );
            return(0) unless( $label =~ /\A[a-zA-Z0-9](?:[a-zA-Z0-9\-]*[a-zA-Z0-9])?\z/ );
        }
        return(1);
    };

    $F{'idn-hostname'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        if( $has_idn )
        {
            local $@;
            my $ascii = eval{ Net::IDN::Encode::domain_to_ascii( $s ) };
            return(0) unless( defined( $ascii ) && length( $ascii ) );
            return( $F{'hostname'}->( $ascii ) ? 1 : 0 );
        }

        # Fallback: permissive Unicode label check (as you had), then ASCII hostname rule
        return(0) if( length( $s ) > 253 );
        for my $label ( split( /\./, $s ) )
        {
            return(0) unless( length( $label ) >= 1 && length( $label ) <= 63 );
            return(0) unless( $label =~ /\A[[:alnum:]\pL\pN](?:[[:alnum:]\pL\pN\-]*[[:alnum:]\pL\pN])?\z/u );
        }
        return(1);
    };

    # IP addresses
    $F{'ipv4'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return $s =~ /\A
            (25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.
            (25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.
            (25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.
            (25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)
        \z/x ? 1 : 0;
    };

    $F{'ipv6'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return $s =~ /\A
            (?: (?:[0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4}
            |  (?:[0-9A-Fa-f]{1,4}:){1,7}:
            |  (?:[0-9A-Fa-f]{1,4}:){1,6}:[0-9A-Fa-f]{1,4}
            |  (?:[0-9A-Fa-f]{1,4}:){1,5}(?::[0-9A-Fa-f]{1,4}){1,2}
            |  (?:[0-9A-Fa-f]{1,4}:){1,4}(?::[0-9A-Fa-f]{1,4}){1,3}
            |  (?:[0-9A-Fa-f]{1,4}:){1,3}(?::[0-9A-Fa-f]{1,4}){1,4}
            |  (?:[0-9A-Fa-f]{1,4}:){1,2}(?::[0-9A-Fa-f]{1,4}){1,5}
            |  [0-9A-Fa-f]{1,4}:(?:(?::[0-9A-Fa-f]{1,4}){1,6})
            |  :(?:(?::[0-9A-Fa-f]{1,4}){1,7}|:)
            |  (?:[0-9A-Fa-f]{1,4}:){6}
               (?:\d{1,3}\.){3}\d{1,3}
            |  ::(?:[0-9A-Fa-f]{1,4}:){0,5}
               (?:\d{1,3}\.){3}\d{1,3}
            |  (?:[0-9A-Fa-f]{1,4}:){1,5}:
               (?:\d{1,3}\.){3}\d{1,3}
            )
        \z/x ? 1 : 0;
    };

    # URI/IRI
    $F{'uri'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return( $s =~ /\A[A-Za-z][A-Za-z0-9+\-.]*:[^\s]+\z/ ? 1 : 0 );
    };

    $F{'uri-reference'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return( $s =~ /\A(?:[A-Za-z][A-Za-z0-9+\-.]*:)?[^\s]+\z/ ? 1 : 0 );
    };

    $F{'iri'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return( $s =~ /\A[\p{L}\p{N}\.\-]+:[^\s]+|\A\/\/[^\s]+|\A[^\s]+\z/u ? 1 : 0 );
    };

    # UUID
    $F{'uuid'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return( $s =~ /\A[a-fA-F0-9]{8}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{4}\-[a-fA-F0-9]{12}\z/ ? 1 : 0 );
    };

    # JSON Pointer / Relative JSON Pointer
    $F{'json-pointer'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return(1) if( $s eq '' );
        return( $s =~ m{\A/(?:[^~/]|~[01])*(?:/(?:[^~/]|~[01])*)*\z} ? 1 : 0 );
    };

    $F{'relative-json-pointer'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return(1) if( $s =~ /\A0\z/ );
        return( $s =~ m,\A[1-9]\d*(?:#|(?:/(?:[^~/]|~[01])*)*)\z, ? 1 : 0 );
    };

    # Regex
    $F{'regex'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        local $@;
        return( eval{ "" =~ /$s/; 1 } ? 1 : 0 );
    };

    while( my( $k, $v ) = each( %F ) )
    {
        $self->{formats}->{ $k } = $v unless( exists( $self->{formats}->{ $k } ) );
    }

    return( $self );
}

sub register_content_decoder
{
    my( $self, $name, $cb ) = @_;
    if( ref( $cb ) eq 'CODE' )
    {
        $self->{content_decoders}->{ lc( "$name" ) } = $cb;
    }
    else
    {
        die( "content decoder must be a code reference" );
    }
    return( $self );
}

sub register_format
{
    my( $self, $name, $code ) = @_;
    die( "format name required" ) unless( defined( $name ) && length( $name ) );
    die( "format validator must be a coderef" ) unless( ref( $code ) eq 'CODE' );
    $self->{formats}->{ $name } = $code;
    return( $self );
}

sub register_media_validator
{
    my( $self, $type, $cb ) = @_;
    if( ref( $cb ) eq 'CODE' )
    {
        $self->{media_validators}->{ lc( "$type" ) } = $cb;
    }
    else
    {
        die( "media validator must be a code reference" );
    }
    return( $self );
}

sub set_comment_handler
{
    my( $self, $code ) = @_;
    if( @_ > 1 )
    {
        if( defined( $code ) && ref( $code ) ne 'CODE' )
        {
            warn( "Warning only: the handler provided is not a code reference." ) if( warnings::enabled() );
            return( $self );
        }
        $self->{comment_handler} = $code;
    }
    return( $self );
}

sub set_resolver
{
    my( $self, $code ) = @_;
    if( @_ > 1 )
    {
        if( defined( $code ) && ref( $code ) ne 'CODE' )
        {
            warn( "Warning only: the handler provided is not a code reference." ) if( warnings::enabled() );
            return( $self );
        }
        $self->{resolver} = $code;
    }
    return( $self );
}

sub set_vocabulary_support
{
    my( $self, $h ) = @_;
    $self->{vocab_support} = { %{ $h || {} } };
    $self->{vocab_checked} = 0;
    return( $self );
}

# This is a mutator only method
# $js->trace -> enables it
# $js->trace(1) -> enables it
# $js->trace(0) -> disables it
# Always returns the object
# See is_trace_on for the accessor method
sub trace
{
    my( $self, $bool ) = @_;
    my $on = defined( $bool ) ? $bool : 1;
    $self->{trace_on} = $on;
    return( $self );
}

sub trace_limit
{
    my( $self, $n ) = @_;
    $self->{trace_limit} = 0 + ( $n || 0 );
    return( $self );
}

sub trace_sample
{
    my( $self, $pct ) = @_;
    $self->{trace_sample} = 0 + ( $pct || 0 );
    return( $self );
}

sub unique_keys
{
    my( $self, $bool ) = @_;
    my $on = defined( $bool ) ? $bool : 1;
    $self->{unique_keys} = $on;
    return( $self );
}

sub validate
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );

    $self->{errors}     = [];
    $self->{last_error} = '';

    # Ensure we have the compiled root (indexing/anchors) even in lazy mode
    $self->{compiled} = _compile_root( $self->{schema} ) unless( $self->{compiled} );

    # One-time $vocabulary check (Draft 2020-12)
    if( !$self->{vocab_checked} )
    {
        my $root = $self->{schema};
        if( ref( $root ) eq 'HASH' &&
            ref( $root->{'$vocabulary'} ) eq 'HASH' )
        {
            my $decl    = $root->{'$vocabulary'};   # { uri => JSON::true|false, ... }
            my $support = $self->{vocab_support} || {};
            for my $uri ( keys( %$decl ) )
            {
                next unless( $decl->{ $uri } );     # only enforce for required=true
                next if( $support->{ $uri } );      # caller says it's supported
                unless( $self->{ignore_req_vocab} )
                {
                    die( "Required vocabulary not supported: $uri" );
                }
            }
        }
        $self->{vocab_checked} = 1;
    }

    # Because Perl scalar are not JSON scalar, we force the Perl structure into strict JSON types, eliminating all Perl duality and guaranteeing predictable validation semantics.
    if( $self->{normalize_instance} )
    {
        my $json = JSON->new->allow_nonref(1)->canonical(1);
        $data = $json->decode( $json->encode( $data ) );
    }

    # Optional pre-validation pruning of unknown properties / nested objects.
    # This only happens if explicitly enabled via prune_unknown => 1.
    if( $self->{prune_unknown} )
    {
        $data = $self->_prune_with_schema( $self->{schema}, $data );
    }

    my $ctx =
    {
        root            => $self->{compiled},
        instance_root   => $data,
        resolver        => $self->{resolver},
        formats         => $self->{formats},
        errors          => $self->{errors},
        max_errors      => ( ( defined( $opts->{max_errors} ) && $opts->{max_errors} =~ /^\d+$/ ) ? $opts->{max_errors} : $self->{max_errors} ),
        error_count     => 0,

        # paths / recursion
        ptr_stack       => ['#'],
        id_stack        => [ $self->{compiled}->{base} ],
        dyn_stack       => [ {} ],                     # dynamicAnchor scope frames
        visited         => {},                         # "schema_ptr|inst_addr" => 1

        # annotation (for unevaluated*)
        ann_mode        => 1,
        compile_on      => ( defined( $opts->{compile_on} ) ? ( $opts->{compile_on} ? 1 : 0 ) : ( $self->{compile_on} ? 1 : 0 ) ),

        # trace
        trace_on        => ( defined( $opts->{trace_on} ) ? ( $opts->{trace_on} ? 1 : 0 ) : ( $self->{trace_on} ? 1 : 0 ) ),
        trace_sample    => $self->{trace_sample} || 0,
        trace_limit     => ( defined( $opts->{trace_limit} ) && $opts->{trace_limit} =~ /^\d+$/ ) ? $opts->{trace_limit} : ( $self->{trace_limit} || 0 ),
        trace           => [],

        # content assertion & helpers
        content_assert   => ( defined( $opts->{content_assert} ) ? ( $opts->{content_assert} ? 1 : 0 ) : ( $self->{content_assert} ? 1 : 0 ) ),
        media_validators => $self->{media_validators},
        content_decoders => $self->{content_decoders},

        comment_handler  => $self->{comment_handler},

        # extensions
        unique_keys      => $self->{unique_keys},
        extensions       => $self->{extensions},
    };

    # Guarantee at least one trace entry when trace is enabled
    if( $ctx->{trace_on} )
    {
        push( @{$ctx->{trace}},
        {
            schema_ptr => '#',
            keyword    => 'validate',
            inst_path  => '#',
            outcome    => 'start',
            note       => 'start',
        });
    }

    my $res = _v( $ctx, '#', $self->{compiled}->{schema}, $data );

    $self->{last_trace} = $ctx->{trace};

    if( !$res->{ok} )
    {
        # $self->{last_error} = _first_error_text( $self->{errors} );
        $self->{last_error} = scalar( @{$self->{errors}} ) ? $self->{errors}->[0] : '';
        return(0);
    }
    return(1);
}

sub _apply_dynamic_ref
{
    my( $ctx, $schema_ptr, $ref, $inst ) = @_;

    if( $ref =~ /\#(.+)\z/ )
    {
        my $name = $1;
        for( my $i = $#{ $ctx->{dyn_stack} }; $i >= 0; $i-- )
        {
            my $frame = $ctx->{dyn_stack}->[$i];
            if( my $node = $frame->{ $name } )
            {
                my $sp = _ptr_of_node( $ctx->{root}, $node );
                return( _v( $ctx, $sp, $node, $inst ) );
            }
        }
    }

    return( _apply_ref( $ctx, $schema_ptr, $ref, $inst ) );
}

# $ref and $dynamicRef
sub _apply_ref
{
    my( $ctx, $schema_ptr, $ref, $inst ) = @_;

    my $base = $ctx->{id_stack}->[-1];
    my $abs  = _resolve_uri( $base, $ref );

    # Direct absolute ID/anchor hit
    if( my $node = $ctx->{root}->{id_index}->{ $abs } )
    {
        my $sp = _ptr_of_node( $ctx->{root}, $node );
        return( _v( $ctx, $sp, $node, $inst ) );
    }

    # Local fragment
    if( $ref =~ /^\#/ )
    {
        # 1) Try anchors (e.g. "#foo" / "#MyAnchor")
        if( my $n = $ctx->{root}->{anchors}->{ $ref } )
        {
            return( _v( $ctx, $ref, $n, $inst ) );
        }
        if( $ref =~ /^\#([A-Za-z0-9._-]+)\z/ )
        {
            my $cand = $base . '#' . $1;
            if( my $node = $ctx->{root}->{id_index}->{ $cand } )
            {
                my $sp = _ptr_of_node( $ctx->{root}, $node );
                return( _v( $ctx, $sp, $node, $inst ) );
            }
        }
        # 2) If it’s a JSON Pointer ( "#/..." ), use _jsv_resolve_internal_ref
        if( $ref =~ m{\A\#/(?:[^~/]|~[01])} )
        {
            # or pulled from id_index; same one used in compile_js
            my $root_schema = $ctx->{root}->{schema} or return( _err_res( $ctx, $schema_ptr, "missing schema", '$ref' ) );

            my $node = _jsv_resolve_internal_ref( $root_schema, $ref );
            if( $node )
            {
                return( _v( $ctx, $ref, $node, $inst ) );
            }

            return _err_res(
                $ctx,
                $schema_ptr,
                "unresolved JSON Pointer fragment in \$ref: $abs",
                '$ref'
            );
        }
        # 3) If not a JSON Pointer and not an anchor, fall through to external resolver / error
    }

    # External resolver hook
    if( $ctx->{resolver} )
    {
        local $@;
        my $ext = eval{ $ctx->{resolver}->( $abs ) };
        return( _err_res( $ctx, $schema_ptr, "resolver failed for \$ref: $abs", '$ref' ) ) unless( $ext && ref( $ext ) );

        my $ext_base = _normalize_uri( ( ref( $ext ) eq 'HASH' && $ext->{'$id'} ) ? $ext->{'$id'} : $abs );

        my( $frag ) = ( $abs =~ /(\#.*)\z/ );
        my ( $anchors, $ids ) = ( {}, {} );
        _index_schema_202012( $ext, $ext_base, '#', $anchors, $ids );

        push( @{$ctx->{id_stack}}, $ext_base );

        # If the abs URI included a JSON Pointer fragment, honor it here
        my $target_ptr = '#';
        if( defined( $frag ) && length( $frag ) )
        {
            if( $frag =~ m{\A\#/(?:[^~/]|~[01])} )
            {
                # JSON Pointer fragment
                if( my $node = $anchors->{ $frag } )
                {
                    my $r = _v( $ctx, $frag, $node, $inst );
                    pop( @{$ctx->{id_stack}} );
                    return( $r );
                }
                else
                {
                    pop( @{$ctx->{id_stack}} );
                    return( _err_res( $ctx, $schema_ptr, "unresolved JSON Pointer fragment in \$ref: $abs", '$ref' ) );
                }
            }
            elsif( $frag =~ /\A\#([A-Za-z0-9._-]+)\z/ )
            {
                my $cand = $ext_base . '#' . $1;
                if( my $node = $ids->{ $cand } )
                {
                    my $sp = _ptr_of_node( { anchors => $anchors }, $node ) || '#';
                    my $r  = _v( $ctx, $sp, $node, $inst );
                    pop( @{$ctx->{id_stack}} );
                    return( $r );
                }
            }
        }

        my $r = _v( $ctx, '#', $ext, $inst );
        pop( @{$ctx->{id_stack}} );
        return( $r );
    }

    return( _err_res( $ctx, $schema_ptr, "unresolved \$ref: $ref (abs: $abs)", '$ref' ) );
}

sub _canon
{
    my( $v ) = @_;
    my $json = JSON->new->allow_nonref(1)->canonical(1)->convert_blessed(1);
    return( $json->encode( $v ) );
}

sub _check_vocabulary_required
{
    my( $self ) = @_;
    return(1) if( $self->{vocab_checked} );

    my $root = $self->{schema};
    if( ref( $root ) eq 'HASH' && ref( $root->{'$vocabulary'} ) eq 'HASH' )
    {
        my $decl    = $root->{'$vocabulary'};
        my $support = $self->{vocab_support} || {};
        for my $uri ( keys( %$decl ) )
        {
            # required only
            next unless( $decl->{ $uri } );
            next if( $support->{ $uri } );
            # TODO: Maybe we should return an exception rather than dying; it would be more user-friendly
            die( "Required vocabulary not supported: $uri" );
        }
    }
    return( $self->{vocab_checked} = 1 );
}

sub _clone
{
    my( $v ) = @_;
    my $json = JSON->new->allow_nonref(1)->canonical(1);
    return( $json->decode( $json->encode( $v ) ) );
}

sub _compile_js_node
{
    my $self = shift( @_ );
    my( $S, $sp, $seen, $funcs, $counter_ref, $root, $opts ) = @_;

    $opts ||= {};
    my $ecma  = exists( $opts->{ecma} ) ? $opts->{ecma} : 'auto';
    my $force_unicode =
        defined( $ecma ) &&
        $ecma =~ /^\d+$/ &&
        $ecma >= 2018;

    # Re-use same JS function for the same schema pointer
    if( exists( $seen->{ $sp } ) )
    {
        return( $seen->{ $sp } );
    }

    # Support pointer-alias schemas such as:
    # definitions => { address => "#/definitions/jp_address" }
    if( defined( $S ) && !ref( $S ) && $S =~ /^#\// )
    {
        my $target_ptr = $S;

        # If we already compiled that pointer, just alias it
        if( exists( $seen->{ $target_ptr } ) )
        {
            $seen->{ $sp } = $seen->{ $target_ptr };
            return( $seen->{ $target_ptr } );
        }

        my $target_schema = _jsv_resolve_internal_ref( $root, $target_ptr );

        # Follow chains of pointer-aliases
        if( defined( $target_schema ) && !ref( $target_schema ) )
        {
            my %followed;
            while(
                defined( $target_schema ) &&
                !ref( $target_schema ) &&
                $target_schema =~ /^#\//
            )
            {
                last if( $followed{ $target_schema }++ );
                $target_ptr    = $target_schema;
                $target_schema = _jsv_resolve_internal_ref( $root, $target_ptr );
            }
        }

        unless( defined( $target_schema ) )
        {
            # Could not resolve: emit a no-op validator (server still enforces)
            my $id = $$counter_ref++;
            my $fn = "jsv_node_${id}";
            $seen->{ $sp } = $fn;
            push( @$funcs, <<JS_RUNTIME );
// $sp (unresolved pointer-alias $S)
function $fn(inst, path, ctx)
{
}
JS_RUNTIME
            return( $fn );
        }

        unless( ref( $target_schema ) eq 'HASH' )
        {
            die(
                "Internal error: pointer-alias '$S' at '$sp' did not resolve to an object schema " .
                "(got " . ( ref( $target_schema ) || 'scalar' ) . ")."
            );
        }

        my $base_fn = $self->_compile_js_node( $target_schema, $target_ptr, $seen, $funcs, $counter_ref, $root, $opts );

        # Alias this pointer to the target validator
        $seen->{ $sp } = $base_fn;
        return( $base_fn );
    }

    # NOTE: $ref
    # 0) $ref handling (internal refs only)
    if( ref( $S ) eq 'HASH' &&
        exists( $S->{'$ref'} ) )
    {
        my $ref = $S->{'$ref'};

        # Only support internal refs ("#/...") in JS
        if( defined( $ref ) && $ref =~ /^#/ )
        {
            my $target_ptr = $ref;

            # If we already compiled that pointer, just alias and return it
            if( exists( $seen->{ $target_ptr } ) )
            {
                $seen->{ $sp } = $seen->{ $target_ptr };
                return( $seen->{ $target_ptr } );
            }

            # Otherwise, resolve pointer against the root schema
            my $target_schema = _jsv_resolve_internal_ref( $root, $target_ptr );


            # Support "pointer alias" schemas such as:
            # definitions => { address => "#/definitions/jp_address" }
            # Keep resolving until we reach a real schema hash.
            if( defined( $target_schema ) && !ref( $target_schema ) )
            {
                my %followed;
                while(
                    defined( $target_schema ) &&
                    !ref( $target_schema ) &&
                    $target_schema =~ /^#\//
                )
                {
                    last if( $followed{ $target_schema }++ );
                    $target_ptr    = $target_schema;
                    $target_schema = _jsv_resolve_internal_ref( $root, $target_ptr );
                }
            }

            unless( defined( $target_schema ) )
            {
                # Pointer could not be resolved. As a safety fallback,
                # make this node a no-op on the client (server will still enforce).
                my $id = $$counter_ref++;
                my $fn = "jsv_node_${id}";
                $seen->{ $sp } = $fn;
                push( @$funcs, <<JS_RUNTIME );
// $sp
function $fn(inst, path, ctx)
{
}

JS_RUNTIME
                return( $fn );
            }

            unless( ref( $target_schema ) eq 'HASH' )
            {
                die( "Internal error: \$ref target '$target_ptr' did not resolve to a schema object (got " .
                     ( defined( $target_schema ) ? ref( $target_schema ) || 'scalar' : 'undef' ) .
                     "). If you are using pointer-alias definitions, they must ultimately resolve to an object schema." );
            }

            # Compile the target, then merge sibling keywords
            my $base_fn = $self->_compile_js_node( $target_schema, $target_ptr, $seen, $funcs, $counter_ref, $root, $opts );

            # Create a wrapper that runs both the referenced schema AND local keywords
            my $id = $$counter_ref++;
            my $wrapper_fn = "jsv_node_$id";
            $seen->{ $sp } = $wrapper_fn;

            my @wrapper_body;
            push( @wrapper_body, <<JS_RUNTIME );
// $sp (\$ref + siblings)
function $wrapper_fn(inst, path, ctx)
{
    $base_fn(inst, path, ctx);
    if(ctx.errors.length >= ctx.maxErrors) return;
JS_RUNTIME

            # Now compile the current node again, but skip the $ref
            my $local_S = { %$S };  # shallow copy
            delete( $local_S->{'$ref'} );
            my $local_sp = _join_ptr( $sp, '__local__' );
            my $local_fn = $self->_compile_js_node( $local_S, $local_sp, $seen, $funcs, $counter_ref, $root, $opts );

            if( $local_fn ne $wrapper_fn )
            {
                push( @wrapper_body, <<JS_RUNTIME );
    $local_fn(inst, path, ctx);
JS_RUNTIME
            }

            push( @wrapper_body, <<JS_RUNTIME );
}
JS_RUNTIME
            push( @$funcs, join( '', @wrapper_body ) );
            return( $wrapper_fn );
        }

        # External refs (URLs, etc.) are not resolved on the client.
        # Full resolution is done server-side.
    }

    my $id = $$counter_ref++;
    my $fn = "jsv_node_$id";
    $seen->{ $sp } = $fn;

    my @body;

    push( @body, <<JS_RUNTIME );
// $sp
function $fn(inst, path, ctx)
{
JS_RUNTIME

    # NOTE: combinator (allOf / anyOf / oneOf / not / if-then-else)
    if( ref( $S ) eq 'HASH' )
    {
        # allOf – AND of subschemas
        if( exists( $S->{allOf} ) &&
            ref( $S->{allOf} ) eq 'ARRAY' &&
            @{$S->{allOf}} )
        {
            for my $i ( 0 .. $#{$S->{allOf}} )
            {
                my $sub_sp = _join_ptr( $sp, 'allOf', $i );
                my $sub_fn = $self->_compile_js_node( $S->{allOf}->[ $i ], $sub_sp, $seen, $funcs, $counter_ref, $root, $opts );

                push( @body, <<JS_RUNTIME );
    // $sub_sp
    $sub_fn(inst, path + '/allOf/$i', ctx);
    if(ctx.maxErrors && ctx.errors.length >= ctx.maxErrors) return;
JS_RUNTIME
            }

            # IMPORTANT: we do *not* return here.
            # Other local keywords (type, properties, contains, ...) must still run.
        }

        # anyOf – at least one must validate (we only emit a single anyOf error)
        if( exists( $S->{anyOf} ) &&
            ref( $S->{anyOf} ) eq 'ARRAY' &&
            @{$S->{anyOf}} )
        {
            push( @body, <<JS_RUNTIME );
    (function()
    {
        var baseErrors = ctx.errors;
        var matched = false;

JS_RUNTIME

            for my $i ( 0 .. $#{$S->{anyOf}} )
            {
                my $sub_sp = _join_ptr( $sp, 'anyOf', $i );
                my $sub_fn = $self->_compile_js_node( $S->{anyOf}->[ $i ], $sub_sp, $seen, $funcs, $counter_ref, $root, $opts );

                push( @body, <<JS_RUNTIME );
        if(matched) return;
        ctx.errors = [];
        // $sub_sp
        $sub_fn(inst, path + '/anyOf/$i', ctx);
        if(ctx.errors.length === 0)
        {
            matched = true;
            ctx.errors = baseErrors;
            return;
        }
JS_RUNTIME
            }

            my $sp_qp = _js_quote( $sp );
            push( @body, <<JS_RUNTIME );
        ctx.errors = baseErrors;
        if(!matched)
        {
            _jsv_err(ctx, path, 'anyOf', 'no subschema matched', $sp_qp);
        }
    })();
    // return;
JS_RUNTIME
        }

        # oneOf – exactly one must validate
        if( exists( $S->{oneOf} ) &&
            ref( $S->{oneOf} ) eq 'ARRAY' &&
            @{$S->{oneOf}} )
        {
            push( @body, <<JS_RUNTIME );
    (function()
    {
        var baseErrors = ctx.errors;
        var hits = 0;

JS_RUNTIME

            for my $i ( 0 .. $#{$S->{oneOf}} )
            {
                my $sub_sp = _join_ptr( $sp, 'oneOf', $i );
                my $sub_fn = $self->_compile_js_node( $S->{oneOf}->[ $i ], $sub_sp, $seen, $funcs, $counter_ref, $root, $opts );

                push( @body, <<JS_RUNTIME );
        ctx.errors = [];
        // $sub_sp
        $sub_fn(inst, path + '/oneOf/$i', ctx);
        if(ctx.errors.length === 0)
        {
            hits++;
        }
JS_RUNTIME
            }

            my $sp_qp = _js_quote( $sp );
            push( @body, <<JS_RUNTIME );
        ctx.errors = baseErrors;
        if(hits !== 1)
        {
            _jsv_err(ctx, path, 'oneOf', 'exactly one subschema must match, but ' + hits + ' did', $sp_qp);
        }
    })();
    // return;
JS_RUNTIME
        }

        # not – but we SKIP "negative required" patterns on the client
        if( exists( $S->{not} ) )
        {
            my $skip_not = 0;

            if( ref( $S->{not} ) eq 'HASH' )
            {
                my $N = $S->{not};

                # Direct: { "not": { "required": [...] } }
                if( exists( $N->{required} ) &&
                    ref( $N->{required} ) eq 'ARRAY' )
                {
                    $skip_not = 1;
                }
                # Or: { "not": { "anyOf": [ {required:...}, ... ] } }
                elsif( exists( $N->{anyOf} ) &&
                       ref( $N->{anyOf} ) eq 'ARRAY' )
                {
                    my $all_req = 1;
                    for my $elt ( @{$N->{anyOf}} )
                    {
                        if( !( ref( $elt ) eq 'HASH' &&
                               exists( $elt->{required} ) &&
                               ref( $elt->{required} ) eq 'ARRAY' ) )
                        {
                            $all_req = 0;
                            last;
                        }
                    }
                    $skip_not = 1 if( $all_req );
                }
            }

            if( !$skip_not )
            {
                my $sub_sp = _join_ptr( $sp, 'not' );
                my $sub_fn = $self->_compile_js_node( $S->{not}, $sub_sp, $seen, $funcs, $counter_ref, $root, $opts );
                my $sp_qp  = _js_quote( $sp );
                push( @body, <<JS_RUNTIME );
    (function()
    {
        var baseErrors = ctx.errors;
        ctx.errors = [];
        // $sub_sp
        $sub_fn(inst, path + '/not', ctx);
        var failed = (ctx.errors.length > 0);
        ctx.errors = baseErrors;
        if(!failed)
        {
            _jsv_err(ctx, path, 'not', 'instance matched forbidden schema', $sp_qp);
        }
    })();
    // return;
JS_RUNTIME
            }
            else
            {
                # Skip "not + required" style rules on the client;
                # they are enforced server-side only.
                push( @body, <<JS_RUNTIME );
    // NOTE: 'not' at $sp is a negative-required pattern; skipped client-side.
JS_RUNTIME
            }
        }

        # if / then / else  (branch errors are enforced, "if" errors are not)
        if( exists( $S->{if} ) )
        {
            my $if_sp = _join_ptr( $sp, 'if' );
            my $if_fn = $self->_compile_js_node( $S->{if}, $if_sp, $seen, $funcs, $counter_ref, $root, $opts );

            push( @body, <<JS_RUNTIME );
    (function()
    {
        var baseErrors = ctx.errors;
        var tmp = [];
        ctx.errors = tmp;
        // $if_sp
        $if_fn(inst, path + '/if', ctx);
        var failed = (tmp.length > 0);
        ctx.errors = baseErrors;
JS_RUNTIME

            if( $S->{then} )
            {
                my $then_sp = _join_ptr( $sp, 'then' );
                my $then_fn = $self->_compile_js_node( $S->{then}, $then_sp, $seen, $funcs, $counter_ref, $root, $opts );
                push( @body, <<JS_RUNTIME );
        if(!failed)
        {
            $then_fn(inst, path + '/then', ctx);
        }
JS_RUNTIME
            }
            if( $S->{else} )
            {
                my $else_sp = _join_ptr( $sp, 'else' );
                my $else_fn = $self->_compile_js_node( $S->{else}, $else_sp, $seen, $funcs, $counter_ref, $root, $opts );
                push( @body, <<JS_RUNTIME );
        else
        {
            $else_fn(inst, path + '/else', ctx);
        }
JS_RUNTIME
            }

            push( @body, <<JS_RUNTIME );
    })();
JS_RUNTIME
            # Do NOT return here; this node can also have local constraints
        }

        # uniqueKeys extension when enabled
        if( $self->{unique_keys} &&
            exists( $S->{uniqueKeys} ) &&
            ref( $S->{uniqueKeys} ) eq 'ARRAY' )
        {
            for my $keyset_ref ( @{$S->{uniqueKeys}} )
            {
                next unless( ref( $keyset_ref ) eq 'ARRAY' && @$keyset_ref );

                my @keys = map{ _js_quote( $_ ) } @$keyset_ref;
                my $qsp  = _js_quote( $sp );

                push( @body, <<JS_RUNTIME );
    if(Array.isArray(inst))
    {
        var seen = {};
        for(var i = 0; i < inst.length; i++)
        {
            var item = inst[i];
            var key = '';
            try
            {
                key = [ @keys ].map(function(k){ return item[k]; }).join('\x1E'); // RS separator
            }
            catch(e) {}
            if(seen.hasOwnProperty(key))
            {
                _jsv_err(ctx, path, 'uniqueKeys', 'duplicate items with keys [@$keyset_ref]', $qsp);
                break;
            }
            seen[key] = true;
        }
    }
JS_RUNTIME
            }
        }
    }

    my $has_type_keyword = ( ref( $S ) eq 'HASH' && exists( $S->{type} ) ) ? 1 : 0;

    # NOTE: type
    # 1) type
    if( exists( $S->{type} ) )
    {
        my @types = ref( $S->{type} ) eq 'ARRAY' ? @{$S->{type}} : ( $S->{type} );

        # Special-case "number" vs "integer": _jsv_typeOf returns "integer" for ints
        my @checks;
        for my $t ( @types )
        {
            if( $t eq 'number' )
            {
                # accept "number" or "integer" from _jsv_typeOf
                push( @checks, q{tt === 'number' || tt === 'integer'} );
            }
            else
            {
                my $qt = _js_quote( $t );
                push( @checks, "tt === $qt" );
            }
        }

        my $cond = join( ' || ', @checks );
        my $msg  = 'expected type ' .
                   ( @types == 1 ? $types[0] : '[' . join( ',', @types ) . ']' ) .
                   ' but found ';
        my $qmsg = _js_quote( $msg );
        my $qsp  = _js_quote( $sp );

        push( @body, <<JS_RUNTIME );
    var tt = _jsv_typeOf(inst);
    if(!( $cond ))
    {
        _jsv_err(ctx, path, 'type', $qmsg + tt, $qsp);
        return;
    }
JS_RUNTIME
    }

    # NOTE: enum
    # 2) enum
    if( exists( $S->{enum} ) &&
        ref( $S->{enum} ) eq 'ARRAY' &&
        @{$S->{enum}} )
    {
        my @vals  = @{$S->{enum}};
        my @vs_js = map{ _js_quote( $_ ) } @vals;
        my $qsp   = _js_quote( $sp );

        local $" = ', ';
        push( @body, <<JS_RUNTIME );
    (function()
    {
        var ok = false;
        var v = inst;
        var list = [ @vs_js ];
        for(var i = 0; i < list.length; i++)
        {
            if(v === list[i])
            {
                ok = true;
                break;
            }
        }
        if(!ok)
        {
            _jsv_err(ctx, path, 'enum', 'value is not in enum list', $qsp);
        }
    })();
JS_RUNTIME
    }

    # NOTE: const
    # 3) const (primitive only)
    if( exists( $S->{const} ) )
    {
        # For simplicity on the JS side, only support primitive const reliably.
        # (Object/array equality is non-trivial; we keep it minimal for now.)
        my $c   = $S->{const};
        my $qsp = _js_quote( $sp );

        if( !ref( $c ) )
        {
            my $cv = _js_quote( $c );
            push( @body, <<JS_RUNTIME );
    if(inst !== $cv)
    {
        _jsv_err(ctx, path, 'const', 'value does not match const', $qsp);
    }
JS_RUNTIME
        }
        else
        {
            # Complex const -> skip in JS (server will still enforce)
            push( @body, <<JS_RUNTIME );
    // NOTE: const at $sp is non-primitive; not enforced client-side.

JS_RUNTIME
        }
    }

    # NOTE: required
    # 4) required (objects)
    if( exists( $S->{required} ) &&
        ref( $S->{required} ) eq 'ARRAY' &&
        @{$S->{required}} )
    {
        push( @body, <<JS_RUNTIME );
    if(_jsv_typeOf(inst) === 'object')
    {
JS_RUNTIME

        for my $p ( @{$S->{required}} )
        {
            my $qp   = _js_quote( $p );
            my $sp2  = _join_ptr( $sp, 'properties', $p );
            my $qsp2 = _js_quote( $sp2 );

            my $msg  = "required property '$p' is missing";
            my $qmsg = _js_quote( $msg );

            push( @body, <<JS_RUNTIME );
        if(!_jsv_hasOwn(inst, $qp))
        {
            _jsv_err(ctx, path, 'required', $qmsg, $qsp2);
        }
JS_RUNTIME
        }

        push( @body, <<JS_RUNTIME );
    }
JS_RUNTIME
    }

    # NOTE: string && pattern
    # 5) string length & pattern
    my $has_string_constraints =
        exists( $S->{minLength} ) ||
        exists( $S->{maxLength} ) ||
        exists( $S->{pattern} );

    if( $has_string_constraints )
    {
        my $qsp = _js_quote( $sp );

        push( @body, <<JS_RUNTIME );
    if(_jsv_typeOf(inst) === 'string')
    {
JS_RUNTIME

        if( exists( $S->{minLength} ) )
        {
            my $min = int( $S->{minLength} );
            push( @body, <<JS_RUNTIME );
        if(inst.length < $min)
        {
            _jsv_err(ctx, path, 'minLength', 'string shorter than minLength $min', $qsp);
        }
JS_RUNTIME
        }

        if( exists( $S->{maxLength} ) )
        {
            my $max = int( $S->{maxLength} );
            push( @body, <<JS_RUNTIME );
        if(inst.length > $max)
        {
            _jsv_err(ctx, path, 'maxLength', 'string longer than maxLength $max', $qsp);
        }
JS_RUNTIME
        }

        if( exists( $S->{pattern} ) &&
            defined( $S->{pattern} ) &&
            length( $S->{pattern} ) )
        {
            my $pat  = $S->{pattern};
            # my $qpat = _js_quote( $pat );
            # from \x{FF70} to \uFF70
            # from \p{Katakana} to \p{sc=Katakana}
            my $qpat = _re_to_js( $pat );

            if( $force_unicode )
            {
                # ecma >= 2018: always try with "u" flag (Unicode mode)
                push( @body, <<JS_RUNTIME );
        try
        {
            var re = new RegExp("$qpat", "u");
            if(!re.test(inst))
            {
                _jsv_err(ctx, path, 'pattern', 'string does not match pattern', $qsp);
            }
        }
        catch(e)
        {
            // Browser does not support Unicode property escapes or this pattern.
        }
JS_RUNTIME
            }
            else
            {
                # auto / ES5 mode: detect "advanced" patterns
                if( $pat =~ /\\p\{|\\P\{|\\X|\\R|\(\?[A-Za-z]/ )
                {
                    # Attempt Unicode mode with "u" flag, but gracefully fall back
                    push( @body, <<JS_RUNTIME );
        (function()
        {
            var re = null;
            try
            {
                re = new RegExp("$qpat", "u");
            }
            catch(e)
            {
                // Older browser; skip Unicode-property-based pattern on client.
            }
            if(re && !re.test(inst))
            {
                _jsv_err(ctx, path, 'pattern', 'string does not match pattern', $qsp);
            }
        })();
JS_RUNTIME
                }
                else
                {
                    # Simple ECMA 5-compatible pattern
                    push( @body, <<JS_RUNTIME );
        try
        {
            var re = new RegExp("$qpat");
            if(!re.test(inst))
            {
                _jsv_err(ctx, path, 'pattern', 'string does not match pattern', $qsp);
            }
        }
        catch(e)
        {
            // If pattern is not JS-compatible, we silently skip on the client.
        }
JS_RUNTIME
                }
            }
        }

        push( @body, <<JS_RUNTIME );
    }
JS_RUNTIME
    }

    # NOTE: minimum, maximum, etc
    # 6) numeric bounds (minimum/maximum/exclusive*)
    my $has_num_constraints =
        exists( $S->{minimum} ) ||
        exists( $S->{maximum} ) ||
        exists( $S->{exclusiveMinimum} ) ||
        exists( $S->{exclusiveMaximum} );

    if( $has_num_constraints )
    {
        # For consistency with string/pattern/etc, we report the
        # schema pointer of the *owning schema* ($sp), not the
        # child keyword location (.../minimum).
        my $qsp_num = _js_quote( $sp );
        my $qmsg_expected_num = _js_quote( 'expected number but found ' );

        push( @body, <<'JS_RUNTIME' );
    var t = _jsv_typeOf(inst);

    // Coerce numeric-looking strings to numbers, for friendlier UX
    if(t === 'string' && /^[+-]?(?:\d+|\d*\.\d+)$/.test(inst))
    {
        inst = +inst;
        t = _jsv_typeOf(inst);
    }

    if(t === 'number' || t === 'integer')
    {
JS_RUNTIME

        if( exists( $S->{minimum} ) )
        {
            my $min = 0 + $S->{minimum};
            push( @body, <<JS_RUNTIME );
        if(inst < $min)
        {
            _jsv_err(ctx, path, 'minimum', 'number is less than minimum $min', $qsp_num);
        }
JS_RUNTIME
        }

        if( exists( $S->{maximum} ) )
        {
            my $max = 0 + $S->{maximum};
            push( @body, <<JS_RUNTIME );
        if(inst > $max)
        {
            _jsv_err(ctx, path, 'maximum', 'number is greater than maximum $max', $qsp_num);
        }
JS_RUNTIME
        }

        if( exists( $S->{exclusiveMinimum} ) )
        {
            my $emin = 0 + $S->{exclusiveMinimum};
            push( @body, <<JS_RUNTIME );
        if(inst <= $emin)
        {
            _jsv_err(ctx, path, 'exclusiveMinimum',
                     'number is <= exclusiveMinimum $emin', $qsp_num);
        }
JS_RUNTIME
        }

        if( exists( $S->{exclusiveMaximum} ) )
        {
            my $emax = 0 + $S->{exclusiveMaximum};
            push( @body, <<JS_RUNTIME );
        if(inst >= $emax)
        {
            _jsv_err(ctx, path, 'exclusiveMaximum',
                     'number is >= exclusiveMaximum $emax', $qsp_num);
        }
JS_RUNTIME
        }

        # Close the "if(t === 'number' || t === 'integer')" and, if needed,
        # add a fallback type error when no explicit "type" keyword exists.
        if( $has_type_keyword )
        {
            push( @body, <<'JS_RUNTIME' );
    }
JS_RUNTIME
        }
        else
        {
            push( @body, <<JS_RUNTIME );
    }
    else
    {
        _jsv_err(ctx, path, 'type', $qmsg_expected_num + t, $qsp_num);
    }
JS_RUNTIME
        }
    }

    # NOTE: items / minItems / maxItems
    # 7) array items & minItems/maxItems
    my $has_array_len =
        exists( $S->{minItems} ) ||
        exists( $S->{maxItems} );

    if( exists( $S->{items} ) || $has_array_len )
    {
        my $qsp = _js_quote( $sp );

        # Precompile single-schema "items"
        my $items_fn;
        if( exists( $S->{items} ) && ref( $S->{items} ) eq 'HASH' )
        {
            my $items_ptr = _join_ptr( $sp, 'items' );
            $items_fn     = $self->_compile_js_node( $S->{items}, $items_ptr, $seen, $funcs, $counter_ref, $root, $opts );
        }

        my $min_items = exists( $S->{minItems} ) ? int( $S->{minItems} ) : undef;
        my $max_items = exists( $S->{maxItems} ) ? int( $S->{maxItems} ) : undef;

        my( $qmsg_min, $qmsg_max );
        if( defined( $min_items ) )
        {
            my $msg_min = "array has fewer than $min_items items";
            $qmsg_min   = _js_quote( $msg_min );
        }
        if( defined( $max_items ) )
        {
            my $msg_max = "array has more than $max_items items";
            $qmsg_max   = _js_quote( $msg_max );
        }

        push( @body, <<JS_RUNTIME );
    if(_jsv_typeOf(inst) === 'array')
    {
JS_RUNTIME

        if( defined( $min_items ) )
        {
            push( @body, <<JS_RUNTIME );
        if(inst.length < $min_items)
        {
            _jsv_err(ctx, path, 'minItems', $qmsg_min, $qsp);
        }
JS_RUNTIME
        }

        if( defined( $max_items ) )
        {
            push( @body, <<JS_RUNTIME );
        if(inst.length > $max_items)
        {
            _jsv_err(ctx, path, 'maxItems', $qmsg_max, $qsp);
        }
JS_RUNTIME
        }

        if( $items_fn )
        {
            push( @body, <<JS_RUNTIME );
        for(var i = 0; i < inst.length; i++)
        {
            $items_fn(inst[i], path + '/' + i, ctx);
            if(ctx.maxErrors && ctx.errors && ctx.errors.length >= ctx.maxErrors)
            {
                return;
            }
        }
JS_RUNTIME
        }

        push( @body, <<JS_RUNTIME );
    }
JS_RUNTIME
    }

    # NOTE: properties
    # 8) properties (objects) – recurse into children
    if( exists( $S->{properties} ) &&
        ref( $S->{properties} ) eq 'HASH' )
    {
        push( @body, <<JS_RUNTIME );
    if(_jsv_typeOf(inst) === 'object')
    {
JS_RUNTIME

        for my $p ( sort( keys( %{$S->{properties}} ) ) )
        {
            my $child     = $S->{properties}->{ $p };
            my $child_ptr = _join_ptr( $sp, 'properties', $p );
            my $child_fn  = $self->_compile_js_node( $child, $child_ptr, $seen, $funcs, $counter_ref, $root, $opts );

            my $qp            = _js_quote( $p );
            my $path_suffix   = '/' . $p;
            my $path_suffix_q = _js_quote( $path_suffix );

            push( @body, <<JS_RUNTIME );
        if(_jsv_hasOwn(inst, $qp))
        {
            // $child_ptr
            $child_fn(inst[$qp], path + $path_suffix_q, ctx);
        }
JS_RUNTIME
        }

        push( @body, <<JS_RUNTIME );
    }
JS_RUNTIME
    }

    # NOTE: definitions – recurse into named schemas
    if( exists( $S->{definitions} ) &&
        ref( $S->{definitions} ) eq 'HASH' )
    {
        for my $name ( sort keys %{ $S->{definitions} } )
        {
            my $child     = $S->{definitions}->{ $name };
            my $child_ptr = _join_ptr( $sp, 'definitions', $name );
            my $child_fn  = $self->_compile_js_node( $child, $child_ptr, $seen, $funcs, $counter_ref, $root, $opts );

            # No runtime call needed here — definitions don't validate by themselves.
            # We just need them compiled so pointer-based lookup can see them.
        }
    }

    # NOTE: contains
    # 9) contains / minContains / maxContains (arrays)
    if( exists( $S->{contains} ) )
    {
        my $contains_schema = $S->{contains};
        my $contains_ptr    = _join_ptr( $sp, 'contains' );
        my $contains_fn     = $self->_compile_js_node( $contains_schema, $contains_ptr, $seen, $funcs, $counter_ref, $root, $opts );
        my $qsp_contains    = _js_quote( $contains_ptr );

        my $have_min = exists( $S->{minContains} );
        my $have_max = exists( $S->{maxContains} );
        my $min      = $have_min ? int( $S->{minContains} ) : 0;
        my $max      = $have_max ? int( $S->{maxContains} ) : 0;

        my $msg_min  = "array has fewer than $min items matching contains subschema";
        my $qmsg_min = _js_quote( $msg_min );
        my $msg_max  = "array has more than $max items matching contains subschema";
        my $qmsg_max = _js_quote( $msg_max );
        my $msg_cont = "array does not contain any item matching contains subschema";
        my $qmsg_cont= _js_quote( $msg_cont );

        push( @body, <<JS_RUNTIME );
    if(_jsv_typeOf(inst) === 'array')
    {
        var matchCount = 0;
        for(var i = 0; i < inst.length; i++)
        {
            var tmpCtx = { errors: [], maxErrors: ctx.maxErrors };
            // $contains_ptr
            $contains_fn(inst[i], path + '/' + i, tmpCtx);
            if(tmpCtx.errors.length === 0)
            {
                matchCount++;
            }
        }
JS_RUNTIME

        if( $have_min )
        {
            push( @body, <<JS_RUNTIME );
        if(matchCount < $min)
        {
            _jsv_err(ctx, path, 'minContains', $qmsg_min, $qsp_contains);
        }
JS_RUNTIME
        }

        if( $have_max )
        {
            push( @body, <<JS_RUNTIME );
        if(matchCount > $max)
        {
            _jsv_err(ctx, path, 'maxContains', $qmsg_max, $qsp_contains);
        }
JS_RUNTIME
        }

        # Plain "contains" only if no min/max are present
        if( !$have_min && !$have_max )
        {
            push( @body, <<JS_RUNTIME );
        if(matchCount === 0)
        {
            _jsv_err(ctx, path, 'contains', $qmsg_cont, $qsp_contains);
        }
JS_RUNTIME
        }

        push( @body, <<JS_RUNTIME );
    }
JS_RUNTIME
    }

    push( @body, <<JS_RUNTIME );
}
JS_RUNTIME

    push( @$funcs, join( '', @body ) );

    return( $fn );
}

sub _compile_node
{
    my( $root, $ptr, $S ) = @_;

    # Non-hash schemas (incl. booleans) => trivial pass
    return sub
    {
        my( $ctx, $inst ) = @_;
        return( { ok => 1, props => {}, items => {} } );
    } unless( ref( $S ) eq 'HASH' );

    # Capture presence and values so runtime avoids hash lookups
    my $has_type    = exists( $S->{type} );
    my $type_spec   = $S->{type};

    my $has_const   = exists( $S->{const} );
    my $const_val   = $S->{const};

    my $has_enum    = exists( $S->{enum} );
    my $enum_vals   = $S->{enum};

    my %numk = map{ $_ => $S->{ $_ } } grep{ exists( $S->{ $_ } ) }
               qw( multipleOf minimum maximum exclusiveMinimum exclusiveMaximum );

    my $has_strlen = ( exists( $S->{minLength} ) || exists( $S->{maxLength} ) || exists( $S->{pattern} ) ) ? 1 : 0;
    my $has_format  = exists( $S->{format} );
    my $format_name = $S->{format};

    my $has_unique_keys =
        exists( $S->{uniqueKeys} ) &&
        ref( $S->{uniqueKeys} ) eq 'ARRAY';

    # Precompile child closures (same structure our interpreter walks)
    my %child;

    # Arrays
    if( ref( $S->{prefixItems} ) eq 'ARRAY' )
    {
        for my $i ( 0 .. $#{ $S->{prefixItems} } )
        {
            my $cp = _join_ptr( $ptr, "prefixItems/$i" );
            $child{ "prefix:$i" } = _compile_node( $root, $cp, $S->{prefixItems}->[$i] );
        }
    }
    if( ref( $S->{items} ) eq 'HASH' )
    {
        $child{ "items" } = _compile_node( $root, _join_ptr( $ptr, "items" ), $S->{items} );
    }
    if( exists( $S->{contains} ) && ref( $S->{contains} ) )
    {
        $child{ "contains" } = _compile_node( $root, _join_ptr( $ptr, "contains" ), $S->{contains} );
    }
    if( exists( $S->{unevaluatedItems} ) && ref( $S->{unevaluatedItems} ) eq 'HASH' )
    {
        $child{ "unevaluatedItems" } = _compile_node( $root, _join_ptr( $ptr, "unevaluatedItems" ), $S->{unevaluatedItems} );
    }

    # Objects
    if( ref( $S->{properties} ) eq 'HASH' )
    {
        for my $k ( keys( %{$S->{properties}} ) )
        {
            my $cp = _join_ptr( $ptr, "properties/$k" );
            $child{ "prop:$k" } = _compile_node( $root, $cp, $S->{properties}->{ $k } );
        }
    }
    if( ref( $S->{patternProperties} ) eq 'HASH' )
    {
        for my $re ( keys( %{ $S->{patternProperties} } ) )
        {
            my $cp = _join_ptr( $ptr, "patternProperties/$re" );
            $child{ "pat:$re" } = _compile_node( $root, $cp, $S->{patternProperties}->{ $re } );
        }
    }
    if( exists( $S->{additionalProperties} ) && ref( $S->{additionalProperties} ) eq 'HASH' )
    {
        $child{ "additional" } = _compile_node( $root, _join_ptr( $ptr, "additionalProperties" ), $S->{additionalProperties} );
    }
    if( exists( $S->{propertyNames} ) && ref( $S->{propertyNames} ) eq 'HASH' )
    {
        $child{ "propnames" } = _compile_node( $root, _join_ptr( $ptr, "propertyNames" ), $S->{propertyNames} );
    }
    if( exists( $S->{dependentSchemas} ) && ref( $S->{dependentSchemas} ) eq 'HASH' )
    {
        for my $k ( keys( %{$S->{dependentSchemas}} ) )
        {
            my $cp = _join_ptr( $ptr, "dependentSchemas/$k" );
            $child{ "deps:$k" } = _compile_node( $root, $cp, $S->{dependentSchemas}->{ $k } );
        }
    }
    if( exists( $S->{unevaluatedProperties} ) && ref( $S->{unevaluatedProperties} ) eq 'HASH' )
    {
        $child{ "ueprops" } = _compile_node( $root, _join_ptr( $ptr, "unevaluatedProperties" ), $S->{unevaluatedProperties} );
    }

    # Combinators
    for my $kw ( qw( allOf anyOf oneOf not ) )
    {
        next unless( exists( $S->{ $kw } ) );
        if( $kw eq 'not' )
        {
            $child{ "not" } = _compile_node( $root, _join_ptr( $ptr, "not" ), $S->{not} ) if( ref( $S->{not} ) );
            next;
        }
        if( ref( $S->{ $kw } ) eq 'ARRAY' )
        {
            for my $i ( 0 .. $#{$S->{ $kw }} )
            {
                my $cp = _join_ptr( $ptr, "$kw/$i" );
                $child{ "$kw:$i" } = _compile_node( $root, $cp, $S->{ $kw }->[$i] );
            }
        }
    }

    # Conditionals
    if( exists( $S->{if} ) && ref( $S->{if} ) eq 'HASH' )
    {
        $child{ "if" }   = _compile_node( $root, _join_ptr( $ptr, 'if' ),   $S->{if} );
        $child{ "then" } = _compile_node( $root, _join_ptr( $ptr, 'then' ), $S->{then} ) if( exists( $S->{then} ) && ref( $S->{then} ) );
        $child{ "else" } = _compile_node( $root, _join_ptr( $ptr, 'else' ), $S->{else} ) if( exists( $S->{else} ) && ref( $S->{else} ) );
    }

    # Return specialized validator
    return sub
    {
        my( $ctx, $inst ) = @_;

        # Parity with interpreter: trace node visit
        _t( $ctx, $ptr, 'node', undef, 'visit' ) if( $ctx->{trace_on} );

        # Type / const / enum
        if( $has_type  ) { _k_type(  $ctx, $inst, $type_spec, $ptr ) or return( _fail() ); }
        if( $has_const ) { _k_const( $ctx, $inst, $const_val, $ptr ) or return( _fail() ); }
        if( $has_enum  ) { _k_enum(  $ctx, $inst, $enum_vals, $ptr ) or return( _fail() ); }

        # uniqueKeys extension (compiled path)
        if( $ctx->{unique_keys} && $has_unique_keys && ref( $inst ) eq 'ARRAY' )
        {
            my $r = _k_unique_keys( $ctx, $ptr, $S->{uniqueKeys}, $inst );
            return( $r ) unless( $r->{ok} );
        }

        # Numbers
        if( _is_number( $inst ) )
        {
            for my $k ( qw( multipleOf minimum maximum exclusiveMinimum exclusiveMaximum ) )
            {
                next unless( exists( $numk{ $k } ) );
                _k_number( $ctx, $inst, $k, $numk{$k}, $ptr ) or return( _fail() );
            }
        }

        # Strings
        if( !ref( $inst ) && defined( $inst ) )
        {
            if( $has_strlen ) { _k_string( $ctx, $inst, $S,           $ptr ) or return( _fail() ); }
            if( $has_format ) { _k_format( $ctx, $inst, $format_name, $ptr ) or return( _fail() ); }

            # contentEncoding / contentMediaType / contentSchema (compiled path)
            if( exists( $S->{contentEncoding} ) ||
                exists( $S->{contentMediaType} ) ||
                exists( $S->{contentSchema} ) )
            {
                my $assert = $ctx->{content_assert} ? 1 : 0;
                my $bytes  = "$inst";
                my $decoded_ref;

                if( exists( $S->{contentEncoding} ) )
                {
                    my $dec = _content_decode( $ctx, $S->{contentEncoding}, $bytes );
                    if( !defined( $dec ) )
                    {
                        return( _err_res( $ctx, $ptr, "contentEncoding '$S->{contentEncoding}' decode failed", 'contentEncoding' ) ) if( $assert );
                    }
                    else
                    {
                        $bytes = $dec;
                    }
                }

                if( exists( $S->{contentMediaType} ) )
                {
                    my( $mt, $params ) = _parse_media_type( $S->{contentMediaType} );
                    if( my $cb = $ctx->{media_validators}->{ $mt } )
                    {
                        my( $ok, $msg, $maybe_decoded ) = _safe_invoke( $cb, $bytes, $params );
                        if( !$ok )
                        {
                            return( _err_res( $ctx, $ptr, ( $msg || "contentMediaType '$mt' validation failed" ), 'contentMediaType' ) ) if( $assert );
                        }
                        # If the media validator decoded into a Perl structure, keep it
                        $decoded_ref = $maybe_decoded if( ref( $maybe_decoded ) );
                        # If it produced new octets/text, keep that too
                        $bytes = $maybe_decoded if( defined( $maybe_decoded ) && !ref( $maybe_decoded ) );
                    }
                    else
                    {
                        if( $mt =~ m{\Atext/} && ( ( $params->{charset} || '' ) =~ /\Autf-?8\z/i ) )
                        {
                            local $@;
                            my $ok = eval
                            {
                                require Encode;
                                Encode::decode( 'UTF-8', $bytes, Encode::FB_CROAK );
                                1;
                            } ? 1 : 0;
                            if( !$ok && $assert )
                            {
                                return( _err_res( $ctx, $ptr, "contentMediaType '$mt' invalid UTF-8", 'contentMediaType' ) );
                            }
                        }
                    }
                }

                if( exists( $S->{contentSchema} ) )
                {
                    my $val;

                    if( ref( $decoded_ref ) )
                    {
                        # already decoded by media validator (e.g. application/json)
                        $val = $decoded_ref;
                    }
                    else
                    {
                        local $@;
                        # still a string of bytes; try JSON decode now
                        $val = eval{ JSON->new->allow_nonref(1)->utf8(1)->decode( $bytes ) };
                    }

                    if( !defined( $val ) )
                    {
                        return( _err_res( $ctx, $ptr, "contentSchema present but payload not JSON-decodable", 'contentSchema' ) ) if( $assert );
                    }
                    else
                    {
                        my $r = _v( $ctx, _join_ptr( $ptr, 'contentSchema' ), $S->{contentSchema}, $val );
                        return( $r ) unless( $r->{ok} );
                    }
                }
            }
        }

        my %ann_props;
        my %ann_items;

        # Arrays
        if( ref( $inst ) eq 'ARRAY' )
        {
            my $r = _k_array_all( $ctx, $ptr, $S, $inst );
            return( $r ) unless( $r->{ok} );
            %ann_items = ( %ann_items, %{$r->{items}} );
        }

        # Objects
        if( ref( $inst ) eq 'HASH' )
        {
            my $r = _k_object_all( $ctx, $ptr, $S, $inst );
            return( $r ) unless( $r->{ok} );
            %ann_props = ( %ann_props, %{$r->{props}} );
        }

        # Combinators
        # allOf: all subschemas must pass, and we merge their annotations.
        if( exists( $S->{allOf} ) && ref( $S->{allOf} ) eq 'ARRAY' )
        {
            my( %p, %it );
            for my $i ( 0 .. $#{ $S->{allOf} } )
            {
                my $r = $child{ "allOf:$i" }->( $ctx, $inst );
                return $r unless $r->{ok};
                %p  = ( %p,  %{$r->{props}} );
                %it = ( %it, %{$r->{items}} );
            }
            %ann_props = ( %ann_props, %p );
            %ann_items = ( %ann_items, %it );
        }

        # anyOf: at least one subschema must pass; do NOT leak errors from
        # non-selected branches into the main context.
        if( exists( $S->{anyOf} ) && ref( $S->{anyOf} ) eq 'ARRAY' )
        {
            my $ok = 0;
            my( %p, %it );
            my @branch_errs;

            for my $i ( 0 .. $#{ $S->{anyOf} } )
            {
                # Shadow context for this branch
                my %shadow = %$ctx;
                my @errs;
                $shadow{errors}      = \@errs;
                $shadow{error_count} = 0;

                my $r = $child{ "anyOf:$i" }->( \%shadow, $inst );

                if( $r->{ok} )
                {
                    $ok = 1;
                    %p  = ( %p,  %{$r->{props}} );
                    %it = ( %it, %{$r->{items}} );
                    last;
                }

                push( @branch_errs, \@errs );
            }

            unless( $ok )
            {
                # No branch matched: merge collected branch errors into main context
                for my $aref ( @branch_errs )
                {
                    next unless( @$aref );
                    push( @{$ctx->{errors}}, @$aref );
                    $ctx->{error_count} += scalar( @$aref );
                }

                return( _err_res( $ctx, $ptr, "instance does not satisfy anyOf", 'anyOf' ) );
            }

            %ann_props = ( %ann_props, %p );
            %ann_items = ( %ann_items, %it );
        }

        # oneOf: exactly one subschema must pass; again, isolate branch errors.
        if( exists( $S->{oneOf} ) && ref( $S->{oneOf} ) eq 'ARRAY' )
        {
            my $hits = 0;

            for my $i ( 0 .. $#{ $S->{oneOf} } )
            {
                my %shadow = %$ctx;
                my @errs;
                $shadow{errors}      = \@errs;
                $shadow{error_count} = 0;

                my $r = $child{ "oneOf:$i" }->( \%shadow, $inst );
                $hits++ if( $r->{ok} );
            }

            return( _err_res( $ctx, $ptr, "instance satisfies $hits subschemas in oneOf (expected exactly 1)", 'oneOf' ) )
                unless( $hits == 1 );
        }

        # not: the inner schema must **fail**; its own errors are irrelevant
        # on success, so we run it entirely in a shadow context.
        if( exists( $S->{not} ) && ref( $S->{not} ) )
        {
            my %shadow = %$ctx;
            my @errs;
            $shadow{errors}      = \@errs;
            $shadow{error_count} = 0;

            my $r = $child{ "not" }->( \%shadow, $inst );

            # If inner schema passes, then "not" fails
            return( _err_res( $ctx, $ptr, "instance matches forbidden not-schema", 'not' ) )
                if( $r->{ok} );

            # Otherwise, "not" is satisfied; ignore inner errors entirely
        }

        # Conditionals
        if( exists( $S->{if} ) && ref( $S->{if} ) )
        {
            my $cond = $child{ "if" }->( $ctx, $inst );
            if( $cond->{ok} )
            {
                if( exists( $child{ "then" } ) )
                {
                    my $r = $child{ "then" }->( $ctx, $inst );
                    return( $r ) unless( $r->{ok} );
                }
            }
            else
            {
                if( exists( $child{ "else" } ) )
                {
                    my $r = $child{ "else" }->( $ctx, $inst );
                    return( $r ) unless( $r->{ok} );
                }
            }
        }

        _t( $ctx, $ptr, 'node', undef, 'pass' ) if( $ctx->{trace_on} );
        return( { ok => 1, props => \%ann_props, items => \%ann_items } );
    };
}

# Compilation / Indexing
sub _compile_root
{
    my( $schema ) = @_;

    if( ref( $schema ) eq 'HASH' )
    {
        $schema->{'$defs'} ||= delete( $schema->{definitions} ) if( exists( $schema->{definitions} ) );
    }

    my $base = _normalize_uri( ( ref( $schema ) eq 'HASH' && $schema->{'$id'} ) ? $schema->{'$id'} : '#' );

    my $anchors  = {};
    my $id_index = {};

    _index_schema_202012( $schema, $base, '#', $anchors, $id_index );

    return({
        schema   => $schema,
        anchors  => $anchors,     # "#/a/b/0"
        id_index => $id_index,    # absolute IDs and #anchors
        base     => $base,
        fn_index => {},           # cache of ptr => compiled closure
    });
}

sub _content_decode
{
    my( $ctx, $enc, $s ) = @_;
    $enc = lc( $enc // '' );

    if( my $cb = $ctx->{content_decoders}->{ $enc } )
    {
        my( $ok, $msg, $out ) = _safe_invoke( $cb, $s );
        return( $ok ? $out : undef );
    }

    if( $enc eq 'base64' )
    {
        my $out = _strict_base64_decode( $s );
        # undef on failure is exactly what we want
        return( $out );
    }

    # Unknown encoding (annotation only unless assert)
    return;
}

# Errors, utils, pointers, URIs
sub _err
{
    my( $ctx, $schema_ptr, $msg, $keyword ) = @_;
    return(0) if( $ctx->{error_count} >= $ctx->{max_errors} );

    # Instance path: use current ptr_stack top if available, else '#'
    my $inst_path = $ctx->{ptr_stack} && @{$ctx->{ptr_stack}}
                  ? ( $ctx->{ptr_stack}->[-1] // '#' )
                  : '#';

    push( @{$ctx->{errors}}, JSON::Schema::Validate::Error->new(
            path            => $inst_path,
            message         => $msg,
            keyword         => $keyword,        # may be undef (back-compat)
            schema_pointer  => $schema_ptr,     # where in the schema this came from
    ));
    $ctx->{error_count}++;
    return(0);
}

sub _err_res
{
    my( $ctx, $schema_ptr, $msg, $keyword ) = @_;
    _err( $ctx, $schema_ptr, $msg, $keyword );
    return( { ok => 0, props => {}, items => {} } );
}

# Used by _prune* methods
sub _extract_array_shape
{
    my( $self, $schema, $out ) = @_;

    return unless( ref( $schema ) eq 'HASH' );

    if( ref( $schema->{prefixItems} ) eq 'ARRAY' )
    {
        my $src = $schema->{prefixItems};
        for my $i ( 0 .. $#$src )
        {
            # First win: do not override an existing prefix schema at this index
            $out->{prefix_items}->[ $i ] = $src->[ $i ]
                unless( defined( $out->{prefix_items}->[ $i ] ) );
        }
    }

    if( exists( $schema->{items} ) && ref( $schema->{items} ) eq 'HASH' )
    {
        # Again, first win: if we already have items from another branch, keep it.
        $out->{items} = $schema->{items} unless( $out->{items} );
    }

    # allOf mixins for arrays as well
    if( ref( $schema->{allOf} ) eq 'ARRAY' )
    {
        foreach my $sub ( @{$schema->{allOf}} )
        {
            $self->_extract_array_shape( $sub, $out );
        }
    }

    # anyOf / oneOf / not ignored for same reason as objects.
}

# Used by _prune* methods
sub _extract_object_shape
{
    my( $self, $schema, $out ) = @_;

    return unless( ref( $schema ) eq 'HASH' );

    # Direct properties
    if( ref( $schema->{properties} ) eq 'HASH' )
    {
        foreach my $k ( keys( %{$schema->{properties}} ) )
        {
            # First win: do not override an already-collected subschema
            $out->{props}->{ $k } = $schema->{properties}->{ $k }
                unless( exists( $out->{props}->{ $k } ) );
        }
    }

    # patternProperties
    if( ref( $schema->{patternProperties} ) eq 'HASH' )
    {
        foreach my $re ( keys( %{$schema->{patternProperties}} ) )
        {
            push( @{$out->{patterns}}, [ $re, $schema->{patternProperties}->{ $re } ] );
        }
    }

    # additionalProperties
    if( exists( $schema->{additionalProperties} ) )
    {
        my $ap = $schema->{additionalProperties};

        # JSON booleans or plain scalars
        if( !ref( $ap ) || ( blessed( $ap ) && $ap->isa( 'JSON::PP::Boolean' ) ) )
        {
            if( $ap )
            {
                # true: additionalProperties allowed; keep any stricter setting we might already have
                $out->{allow_ap} = 1 unless( defined( $out->{allow_ap} ) && !$out->{allow_ap} );
                # do not touch ap_schema here
            }
            else
            {
                # false: forbidden regardless of earlier "true"
                $out->{allow_ap}  = 0;
                $out->{ap_schema} = undef;
            }
        }
        elsif( ref( $ap ) eq 'HASH' )
        {
            # Schema for additionals
            $out->{allow_ap}  = 1;
            $out->{ap_schema} = $ap;
        }
    }

    # allOf mixins: merge their object keywords as well.
    if( ref( $schema->{allOf} ) eq 'ARRAY' )
    {
        foreach my $sub ( @{$schema->{allOf}} )
        {
            $self->_extract_object_shape( $sub, $out );
        }
    }

    # NOTE:
    # We intentionally ignore anyOf / oneOf / not for pruning.
    # Without performing full validation against each branch, we cannot
    # safely decide which properties are truly forbidden, so we err on
    # the side of *keeping* more rather than over-pruning.
}

sub _fail { return( { ok => 0, props => {}, items => {} } ); }

sub _first_error_text
{
    my( $errs ) = @_;
    return( '' ) unless( @$errs );
    my $e = $errs->[0];
    return( "$e" );
}

sub _get_args_as_hash
{
    my $self = shift( @_ );
    return( {} ) if( !scalar( @_ ) );
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
        die( "Uneven number of parameters provided: '", join( "', '", map( overload::StrVal( $_ ), @_ ) ), "'" );
    }
    return( $ref );
}

sub _index_schema_202012
{
    my( $node, $base_uri, $ptr, $anchors, $id_index ) = @_;

    $anchors->{ $ptr } = $node;

    my $here_base = $base_uri;

    if( ref( $node ) eq 'HASH' )
    {
        if( exists( $node->{'$id'} ) && defined( $node->{'$id'} ) && $node->{'$id'} ne '' )
        {
            $here_base = _resolve_uri( $base_uri, $node->{'$id'} );
            $id_index->{ $here_base } = $node;
        }

        if( exists( $node->{'$anchor'} ) && defined( $node->{'$anchor'} ) && $node->{'$anchor'} ne '' )
        {
            my $abs = $here_base . '#' . $node->{'$anchor'};
            $id_index->{ $abs } = $node;
        }

        if( exists( $node->{'$dynamicAnchor'} ) && defined( $node->{'$dynamicAnchor'} ) && $node->{'$dynamicAnchor'} ne '' )
        {
            my $abs = $here_base . '#dyn:' . $node->{'$dynamicAnchor'};
            $id_index->{ $abs } = $node;
        }

        for my $k ( sort( keys( %$node ) ) )
        {
            my $child = $node->{ $k };
            my $child_ptr = _join_ptr( $ptr, $k );
            _index_schema_202012( $child, $here_base, $child_ptr, $anchors, $id_index );
        }
    }
    elsif( ref( $node ) eq 'ARRAY' )
    {
        for my $i ( 0 .. $#$node )
        {
            my $child = $node->[$i];
            my $child_ptr = _join_ptr( $ptr, $i );
            _index_schema_202012( $child, $here_base, $child_ptr, $anchors, $id_index );
        }
    }
}

sub _inst_addr
{
    my( $inst, $ptr ) = @_;
    return( "SCALAR:$ptr" ) unless( ref( $inst ) );
    return( ref( $inst ) . ':' . refaddr( $inst ) );
}

# truthy helpers
sub _is_hash { my $v = shift; return ref($v) eq 'HASH' ? 1 : 0; }

sub _is_number
{
    my( $v ) = @_;

    return(0) if( ref( $v ) );
    return(0) unless( defined( $v ) );

    # Strict JSON typing: accept only scalars that actually carry numeric flags.
    # JSON marks numbers with IOK/NOK; plain strings (even "12") will not have them.
    my $sv    = B::svref_2object( \$v );
    my $flags = $sv->FLAGS;

    local $@;
    # SVf_IOK = 0x02000000, SVf_NOK = 0x04000000 on most builds;
    # we do not hardcode constants—B::SV’s FLAGS is stable to test with these bitmasks.
    # Use string eval to avoid importing platform-specific constants.
    my $SVf_IOK = eval{ B::SVf_IOK() } || 0x02000000;
    my $SVf_NOK = eval{ B::SVf_NOK() } || 0x04000000;

    return( ( $flags & ( $SVf_IOK | $SVf_NOK ) ) ? 1 : 0 );
}

sub _is_true { my $v = shift( @_ ); return( ref( $v ) eq 'HASH' ? 0 : $v ? 1 : 0 ); }

sub _join_ptr
{
    my( $base, @tokens ) = @_;

    # Default base to '#' if not provided
    $base = '#' unless( defined( $base ) && length( $base ) );

    my $ptr = $base;

    for my $token ( @tokens )
    {
        next unless( defined( $token ) );

        # Proper rfc6901 JSON Pointer escaping
        $token =~ s/~/~0/g;
        $token =~ s/\//~1/g;

        if( $ptr eq '#' )
        {
            $ptr = "#/$token";
        }
        else
        {
            $ptr .= "/$token";
        }
    }

    return( $ptr );
}

sub _js_quote
{
    my $s = shift( @_ );
    $s = '' unless( defined( $s ) );
    $s =~ s/\\/\\\\/g;
    $s =~ s/'/\\'/g;
    $s =~ s/\r\n/\n/g;
    $s =~ s/\r/\n/g;
    $s =~ s/\n/\\n/g;
    return( "'$s'" );
}

sub _json_equal
{
    my( $a, $b ) = @_;
    return( _canon( $a ) eq _canon( $b ) );
}

# Very small JSON Pointer resolver for internal refs ("#/...") for JS compile
sub _jsv_resolve_internal_ref
{
    my( $root, $ptr ) = @_;

    return( $root ) if( !defined( $ptr ) || $ptr eq '' || $ptr eq '#' );

    # Expect something like "#/definitions/address"
    $ptr =~ s/^#//;

    my @tokens = split( /\//, $ptr );
    shift( @tokens ) if( @tokens && $tokens[0] eq '' );

    my $node = $root;

    TOKEN:
    for my $tok ( @tokens )
    {
        # rfc6901 JSON Pointer unescaping
        $tok =~ s/~1/\//g;
        $tok =~ s/~0/~/g;

        if( ref( $node ) eq 'HASH' )
        {
            # Draft 2020-12 alias: allow "definitions" to hit "$defs" if needed
            if( $tok eq 'definitions' &&
                !exists( $node->{definitions} ) &&
                exists( $node->{'$defs'} ) )
            {
                $tok = '$defs';
            }

            unless( exists( $node->{ $tok } ) )
            {
                # Optional: help debug resolution problems
                warn( "_jsv_resolve_internal_ref: token '$tok' not found in current hash for pointer '$ptr'\n" )
                    if( $JSON::Schema::Validate::DEBUG );
                return;
            }
            $node = $node->{ $tok };
        }
        elsif( ref( $node ) eq 'ARRAY' )
        {
            unless( $tok =~ /^\d+$/ && $tok < @$node )
            {
                warn( "_jsv_resolve_internal_ref: array index '$tok' out of range for pointer '$ptr'\n" )
                    if( $JSON::Schema::Validate::DEBUG );
                return;
            }
            $node = $node->[ $tok ];
        }
        else
        {
            warn( "_jsv_resolve_internal_ref: reached non-container node while resolving '$ptr'\n" )
                if( $JSON::Schema::Validate::DEBUG );
            return;
        }
    }

    return( $node );
}

# Keyword groups
sub _k_array_all
{
    my( $ctx, $sp, $S, $A ) = @_;

    if( exists( $S->{minItems} ) && @$A < $S->{minItems} )
    {
        return( _err_res( $ctx, $sp, "array has fewer than minItems $S->{minItems}", 'minItems' ) );
    }
    if( exists( $S->{maxItems} ) && @$A > $S->{maxItems} )
    {
        return( _err_res( $ctx, $sp, "array has more than maxItems $S->{maxItems}", 'maxItems' ) );
    }

    if( $S->{uniqueItems} )
    {
        my %seen;
        for my $i ( 0 .. $#$A )
        {
            my $k = _canon( $A->[$i] );
            if( $seen{ $k }++ )
            {
                return( _err_res( $ctx, _join_ptr( $sp, $i ), "array items not unique", 'uniqueItems' ) );
            }
        }
    }

    my %items_ann;

    if( ref( $S->{prefixItems} ) eq 'ARRAY' )
    {
        my $tuple = $S->{prefixItems};
        for my $i ( 0 .. $#$A )
        {
            push( @{$ctx->{ptr_stack}}, _join_ptr( $sp, $i ) );

            if( $i <= $#$tuple )
            {
                my $r = _v( $ctx, _join_ptr( $sp, "prefixItems/$i" ), $tuple->[$i], $A->[$i] );
                return( $r ) unless( $r->{ok} );
                $items_ann{ $i } = 1;
            }
            elsif( exists( $S->{items} ) && ref( $S->{items} ) eq 'HASH' )
            {
                my $r = _v( $ctx, _join_ptr( $sp, "items" ), $S->{items}, $A->[$i] );
                return( $r ) unless( $r->{ok} );
                $items_ann{ $i } = 1;
            }

            pop( @{$ctx->{ptr_stack}} );
        }
    }
    elsif( ref( $S->{items} ) eq 'HASH' )
    {
        for my $i ( 0 .. $#$A )
        {
            push( @{$ctx->{ptr_stack}}, _join_ptr( $sp, $i ) );
            my $r = _v( $ctx, _join_ptr( $sp, "items" ), $S->{items}, $A->[$i] );
            return( $r ) unless( $r->{ok} );
            $items_ann{ $i } = 1;
            pop( @{$ctx->{ptr_stack}} );
        }
    }

    if( exists( $S->{contains} ) )
    {
        my $matches = 0;

        # Quiet sub-context to avoid emitting errors for non-matching items
        for my $i ( 0 .. $#$A )
        {
            my %shadow = %$ctx;
            my @errs;
            $shadow{errors}      = \@errs;
            $shadow{error_count} = 0;

            my $tmp = _v( \%shadow, _join_ptr( $sp, "contains" ), $S->{contains}, $A->[$i] );
            $matches++ if( $tmp->{ok} );
        }

        my $minc = defined( $S->{minContains} ) ? $S->{minContains} : 1;
        my $maxc = defined( $S->{maxContains} ) ? $S->{maxContains} : ( 2**31 - 1 );

        return( _err_res( $ctx, $sp, "contains matched $matches < minContains $minc", 'minContains' ) ) if( $matches < $minc );
        return( _err_res( $ctx, $sp, "contains matched $matches > maxContains $maxc", 'maxContains' ) ) if( $matches > $maxc );
    }

    if( exists( $S->{unevaluatedItems} ) )
    {
        my @unknown = ();
        for my $i ( 0 .. $#$A )
        {
            next if( $items_ann{ $i } );
            push( @unknown, $i );
        }
        my $UE = $S->{unevaluatedItems};
        if( !_is_true( $UE ) && !_is_hash( $UE ) )
        {
            return( _err_res( $ctx, $sp, "unevaluatedItems not allowed at indices: " . join( ',', @unknown ), 'unevaluatedItems' ) ) if( @unknown );
        }
        elsif( ref( $UE ) eq 'HASH' )
        {
            for my $i ( @unknown )
            {
                my $r = _v( $ctx, _join_ptr( $sp, "unevaluatedItems" ), $UE, $A->[$i] );
                return( $r ) unless( $r->{ok} );
                $items_ann{ $i } = 1;
            }
        }
    }

    return( { ok => 1, props => {}, items => \%items_ann } );
}

sub _k_combinator
{
    my( $ctx, $sp, $S, $inst, $kw ) = @_;


    # allOf: all subschemas must pass, we merge their annotations
    if( $kw eq 'allOf' )
    {
        my %props;
        my %items;

        for my $i ( 0 .. $#{$S->{allOf}} )
        {
            my $r = _v( $ctx, _join_ptr( $sp, "allOf/$i" ), $S->{allOf}->[ $i ], $inst );
            return( $r ) unless( $r->{ok} );

            %props = ( %props, %{$r->{props}} );
            %items = ( %items, %{$r->{items}} );
        }

        return( { ok => 1, props => \%props, items => \%items } );
    }

    # anyOf: at least one subschema must pass.
    # Errors from failing branches must NOT leak into the main context.
    if( $kw eq 'anyOf' )
    {
        my @branch_errs;

        for my $i ( 0 .. $#{$S->{anyOf}} )
        {
            # Shadow context: isolate errors for this branch
            my %shadow = %$ctx;
            my @errs;
            $shadow{errors}      = \@errs;
            $shadow{error_count} = 0;

            my $r = _v( \%shadow, _join_ptr( $sp, "anyOf/$i" ), $S->{anyOf}->[ $i ], $inst );

            if( $r->{ok} )
            {
                # One branch passed: combinator satisfied.
                # Ignore all other branch errors.
                return( { ok => 1, props => {}, items => {} } );
            }

            push( @branch_errs, \@errs );
        }

        # No branch matched: merge collected branch errors into main context
        for my $aref ( @branch_errs )
        {
            next unless( @$aref );
            push( @{$ctx->{errors}}, @$aref );
            $ctx->{error_count} += scalar( @$aref );
        }

        return( _err_res( $ctx, $sp, "instance does not satisfy anyOf", 'anyOf' ) );
    }

    # oneOf: exactly one subschema must pass.
    # Again, do not leak errors from non-selected branches.
    if( $kw eq 'oneOf' )
    {
        my @ok_results;
        my @branch_errs;

        for my $i ( 0 .. $#{$S->{oneOf}} )
        {
            my %shadow = %$ctx;
            my @errs;
            $shadow{errors}      = \@errs;
            $shadow{error_count} = 0;

            my $r = _v( \%shadow, _join_ptr( $sp, "oneOf/$i" ), $S->{oneOf}->[$i], $inst );

            if( $r->{ok} )
            {
                push( @ok_results, $r );
            }
            else
            {
                push( @branch_errs, \@errs );
            }
        }

        if( @ok_results == 1 )
        {
            # Exactly one branch matched: combinator satisfied.
            # Do NOT bubble up branch props/items through oneOf.
            return( { ok => 1, props => {}, items => {} } );
        }

        # Zero or >1 matched -> failure; merge branch errors
        for my $aref ( @branch_errs )
        {
            next unless( @$aref );
            push( @{$ctx->{errors}}, @$aref );
            $ctx->{error_count} += scalar( @$aref );
        }

        return(
            _err_res(
                $ctx,
                $sp,
                "instance satisfies " . scalar( @ok_results ) . " schemas in oneOf (expected exactly 1)",
                'oneOf'
            )
        );
    }

    # not: subschema must NOT validate.
    # Any errors from validating the inner schema are irrelevant on success.
    if( $kw eq 'not' )
    {
        my %shadow = %$ctx;
        my @errs;
        $shadow{errors}      = \@errs;
        $shadow{error_count} = 0;

        my $r = _v( \%shadow, _join_ptr( $sp, "not" ), $S->{not}, $inst );

        # If inner schema passes, then "not" fails
        return( _err_res( $ctx, $sp, "instance matches forbidden not-schema", 'not' ) )
            if( $r->{ok} );

        # Otherwise, "not" is satisfied; ignore inner errors entirely
        return( { ok => 1, props => {}, items => {} } );
    }

    # Unknown / unsupported combinator (defensive default)
    return( { ok => 1, props => {}, items => {} } );
}

sub _k_const
{
    my( $ctx, $v, $const, $ptr ) = @_;
    return(1) if( _json_equal( $v, $const ) );
    return( _err( $ctx, $ptr, "const mismatch", 'const' ) );
}

sub _k_enum
{
    my( $ctx, $v, $arr, $ptr ) = @_;
    for my $e ( @$arr )
    {
        return(1) if( _json_equal( $v, $e ) );
    }
    return( _err( $ctx, $ptr, "value not in enum", 'enum' ) );
}

sub _k_format
{
    my( $ctx, $s, $fmt, $ptr ) = @_;
    my $cb = $ctx->{formats}->{ $fmt };
    return(1) unless( $cb );
    local $@;
    my $ok = eval{ $cb->( $s ) ? 1 : 0 };
    return( $ok ? 1 : _err( $ctx, $ptr, "string fails format '$fmt'", 'format' ) );
}

sub _k_if_then_else
{
    my( $ctx, $sp, $S, $inst ) = @_;

    # Evaluate "if" in a shadow context so its errors do NOT leak
    my %shadow = %$ctx;
    my @errs;
    $shadow{errors}      = \@errs;
    $shadow{error_count} = 0;

    my $cond = _v( \%shadow, _join_ptr( $sp, 'if' ), $S->{if}, $inst );

    if( $cond->{ok} )
    {
        _t( $ctx, $sp, 'if', undef, 'pass', 'then' ) if( $ctx->{trace_on} );
        return( { ok => 1, props => {}, items => {} } )
            unless( exists( $S->{then} ) );

        # Apply "then" against the REAL context
        return( _v( $ctx, _join_ptr( $sp, 'then' ), $S->{then}, $inst ) );
    }
    else
    {
        _t( $ctx, $sp, 'if', undef, 'pass', 'else' ) if( $ctx->{trace_on} );
        return( { ok => 1, props => {}, items => {} } )
            unless( exists( $S->{else} ) );

        # Apply "else" against the REAL context
        return( _v( $ctx, _join_ptr( $sp, 'else' ), $S->{else}, $inst ) );
    }
}

sub _k_number
{
    my( $ctx, $v, $kw, $arg, $ptr ) = @_;
    if( $kw eq 'multipleOf' )
    {
        # Guard per spec: multipleOf must be > 0
        if( !defined( $arg ) || $arg <= 0 )
        {
            _t( $ctx, $ptr, 'multipleOf', undef, 'fail', 'arg<=0' ) if( $ctx->{trace_on} );
            return( _err( $ctx, $ptr, "multipleOf must be > 0", 'multipleOf' ) );
        }
        # Float-tolerant multiple check
        # my $ok = abs( ( $v / $arg ) - int( $v / $arg + 1e-10 ) ) < 1e-9;
        my $ok = abs( ( $v / $arg ) - int( $v / $arg + 0.0000000001 ) ) < 1e-9;
        _t( $ctx, $ptr, 'multipleOf', undef, $ok ? 'pass' : 'fail', "$v mod $arg" ) if( $ctx->{trace_on} );
        return( $ok ? 1 : _err( $ctx, $ptr, "number not multipleOf $arg" ) );
    }
    elsif( $kw eq 'minimum' )
    {
        _t( $ctx, $ptr, 'minimum', undef, $v >= $arg ? 'pass' : 'fail', "$v >= $arg" ) if( $ctx->{trace_on} );
        return( $v >= $arg ? 1 : _err( $ctx, $ptr, "number less than minimum $arg", 'minimum' ) );
    }
    elsif( $kw eq 'maximum' )
    {
        _t( $ctx, $ptr, 'maximum', undef, $v <= $arg ? 'pass' : 'fail', "$v <= $arg" ) if( $ctx->{trace_on} );
        return( $v <= $arg ? 1 : _err( $ctx, $ptr, "number greater than maximum $arg", 'maximum' ) );
    }
    elsif( $kw eq 'exclusiveMinimum' )
    {
        _t( $ctx, $ptr, 'exclusiveMinimum', undef, $v > $arg ? 'pass' : 'fail', "$v > $arg" ) if( $ctx->{trace_on} );
        return( $v > $arg ? 1 : _err( $ctx, $ptr, "number not greater than exclusiveMinimum $arg", 'exclusiveMinimum' ) );
    }
    elsif( $kw eq 'exclusiveMaximum' )
    {
        _t( $ctx, $ptr, 'exclusiveMaximum', undef, $v < $arg ? 'pass' : 'fail', "$v < $arg" ) if( $ctx->{trace_on} );
        return( $v < $arg ? 1 : _err( $ctx, $ptr, "number not less than exclusiveMaximum $arg", 'exclusiveMaximum' ) );
    }
    return(1);
}

sub _k_object_all
{
    my( $ctx, $sp, $S, $H ) = @_;

    my $ok = 1;

    my $bail_if_max = sub
    {
        return( $ctx->{max_errors} && $ctx->{error_count} >= $ctx->{max_errors} ) ? 1 : 0;
    };

    if( exists( $S->{minProperties} ) && ( scalar( keys( %$H ) ) ) < $S->{minProperties} )
    {
        _err_res( $ctx, $sp, "object has fewer than minProperties $S->{minProperties}", 'minProperties' );
        $ok = 0;
        return( { ok => 0, props => {}, items => {} } ) if( $bail_if_max->() );
    }
    if( exists( $S->{maxProperties} ) && ( scalar( keys( %$H ) ) ) > $S->{maxProperties} )
    {
        _err_res( $ctx, $sp, "object has more than maxProperties $S->{maxProperties}", 'maxProperties' );
        $ok = 0;
        return( { ok => 0, props => {}, items => {} } ) if( $bail_if_max->() );
    }

    # Merge required from:
    #   - top-level "required" (array only)
    #   - property-level { required => 1 } or { optional => 0 }
    my %required;

    if( exists( $S->{required} ) && ref( $S->{required} ) eq 'ARRAY' )
    {
        $required{ $_ } = 1 for( @{ $S->{required} } );
    }

    if( my $P = $S->{properties} )
    {
        for my $k ( keys( %$P ) )
        {
            my $pd = $P->{ $k };
            next unless( ref( $pd ) eq 'HASH' );

            if( exists( $pd->{required} ) )
            {
                $required{ $k } = $pd->{required} ? 1 : 0;
            }
            if( exists( $pd->{optional} ) )
            {
                $required{ $k } = $pd->{optional} ? 0 : 1; # optional => 0 means required
            }
        }
    }

    for my $rq ( grep{ $required{ $_ } } keys( %required ) )
    {
        next if( exists( $H->{ $rq } ) );
        _t( $ctx,$sp, 'required', undef, 'fail', $rq ) if( $ctx->{trace_on} );

        my @need = sort grep { $required{ $_ } } keys %required;
        my @have = sort keys %$H;

        my $need_str = @need ? join( ', ', @need ) : '(none)';
        my $have_str = @have ? join( ', ', @have ) : '(none)';

        my $msg = "required property '$rq' is missing "
                . "(required: $need_str; present: $have_str)";

        _err_res(
            $ctx,
            _join_ptr( $sp, $rq ),
            $msg,
            'required'
        );

        $ok = 0;
        return( { ok => 0, props => {}, items => {} } ) if( $bail_if_max->() );
    }

    if( exists( $S->{propertyNames} ) && ref( $S->{propertyNames} ) eq 'HASH' )
    {
        for my $k ( keys( %$H ) )
        {
            my $r = _v( $ctx, _join_ptr( $sp, "propertyNames" ), $S->{propertyNames}, $k );
            if( !$r->{ok} )
            {
                $ok = 0;
                return( { ok => 0, props => {}, items => {} } ) if( $bail_if_max->() );
            }
        }
    }

    my $props     = $S->{properties}        || {};
    my $patprops  = $S->{patternProperties} || {};
    my $addl_set  = exists( $S->{additionalProperties} );
    my $addl      = $addl_set ? $S->{additionalProperties} : JSON::true;

    my %ann;

    for my $k ( sort( keys( %$H ) ) )
    {
        my $v = $H->{ $k };
        my $matched = 0;

        my $child_path = _join_ptr( $sp, $k );
        push( @{$ctx->{ptr_stack}}, $child_path );

        if( exists( $props->{ $k } ) )
        {
            my $r = _v( $ctx, _join_ptr( $sp, "properties/$k" ), $props->{ $k }, $v );
            if( !$r->{ok} )
            {
                $ok = 0;
                pop( @{$ctx->{ptr_stack}} );
                return( { ok => 0, props => \%ann, items => {} } ) if( $bail_if_max->() );
                next;
            }
            $ann{ $k } = 1;
            $matched   = 1;
        }

        unless( $matched )
        {
            local $@;
            for my $re ( keys( %$patprops ) )
            {
                my $re_ok = eval{ $k =~ /$re/ };
                next unless( $re_ok );

                my $r = _v( $ctx, _join_ptr( $sp, "patternProperties/$re" ), $patprops->{ $re }, $v );
                if( !$r->{ok} )
                {
                    $ok = 0;
                    pop( @{$ctx->{ptr_stack}} );
                    return( { ok => 0, props => \%ann, items => {} } ) if( $bail_if_max->() );
                    next;
                }
                $ann{ $k } = 1;
                $matched   = 1;
            }
        }

        unless( $matched )
        {
            if( $addl_set && !_is_true( $addl ) && !_is_hash( $addl ) )
            {
                _err_res( $ctx, _join_ptr( $sp, $k ), "additionalProperties not allowed: '$k'", 'additionalProperties' );
                $ok = 0;
                pop( @{$ctx->{ptr_stack}} );
                return( { ok => 0, props => \%ann, items => {} } ) if( $bail_if_max->() );
                next;
            }
            elsif( ref( $addl ) eq 'HASH' )
            {
                my $r = _v( $ctx, _join_ptr( $sp, "additionalProperties" ), $addl, $v );
                if( !$r->{ok} )
                {
                    $ok = 0;
                    pop( @{$ctx->{ptr_stack}} );
                    return( { ok => 0, props => \%ann, items => {} } ) if( $bail_if_max->() );
                    next;
                }
                $ann{ $k } = 1;
            }
        }

        pop( @{$ctx->{ptr_stack}} );
    }

    if( my $depR = $S->{dependentRequired} )
    {
        for my $k ( keys( %$depR ) )
        {
            next unless( exists( $H->{ $k } ) );
            for my $need ( @{$depR->{ $k } || []} )
            {
                next if( exists( $H->{ $need } ) );
                _err_res( $ctx, _join_ptr( $sp, $need ), "dependentRequired: '$need' required when '$k' is present", 'dependentRequired' );
                $ok = 0;
                return( { ok => 0, props => \%ann, items => {} } ) if( $bail_if_max->() );
            }
        }
    }

    if( my $depS = $S->{dependentSchemas} )
    {
        for my $k ( keys( %$depS ) )
        {
            next unless( exists( $H->{ $k } ) );
            my $r = _v( $ctx, _join_ptr( $sp, "dependentSchemas/$k" ), $depS->{ $k }, $H );
            if( !$r->{ok} )
            {
                $ok = 0;
                return( { ok => 0, props => \%ann, items => {} } ) if( $bail_if_max->() );
            }
        }
    }

    if( exists( $S->{unevaluatedProperties} ) )
    {
        my @unknown = grep { !$ann{ $_ } } keys( %$H );
        my $UE = $S->{unevaluatedProperties};

        if( !_is_true( $UE ) && !_is_hash( $UE ) )
        {
            if( @unknown )
            {
                _err_res( $ctx, $sp, "unevaluatedProperties not allowed: " . join( ',', @unknown ), 'unevaluatedProperties' );
                $ok = 0;
                return( { ok => 0, props => \%ann, items => {} } ) if( $bail_if_max->() );
            }
        }
        elsif( ref( $UE ) eq 'HASH' )
        {
            for my $k ( @unknown )
            {
                my $r = _v( $ctx, _join_ptr( $sp, "unevaluatedProperties" ), $UE, $H->{ $k } );
                if( !$r->{ok} )
                {
                    $ok = 0;
                    return( { ok => 0, props => \%ann, items => {} } ) if( $bail_if_max->() );
                    next;
                }
                $ann{ $k } = 1;
            }
        }
    }

    return( { ok => ( $ok ? 1 : 0 ), props => \%ann, items => {} } );
}

sub _k_string
{
    my( $ctx, $s, $S, $ptr ) = @_;
    my $len = _strlen( $s );

    if( exists( $S->{minLength} ) && $len < $S->{minLength} )
    {
        _t( $ctx, $ptr, 'minLength', undef, 'fail', "len=$len < $S->{minLength}" ) if( $ctx->{trace_on} );
        return( _err( $ctx, $ptr, "string shorter than minLength $S->{minLength}", 'minLength' ) );
    }
    _t( $ctx, $ptr, 'minLength', undef, 'pass', "len=$len >= $S->{minLength}" ) if( exists( $S->{minLength} ) && $ctx->{trace_on} );

    if( exists( $S->{maxLength} ) && $len > $S->{maxLength} )
    {
        _t( $ctx, $ptr, 'maxLength', undef, 'fail', "len=$len > $S->{maxLength}" ) if( $ctx->{trace_on} );
        return( _err( $ctx, $ptr, "string longer than maxLength $S->{maxLength}", 'maxLength' ) );
    }
    _t( $ctx, $ptr, 'maxLength', undef, 'pass', "len=$len <= $S->{maxLength}" ) if( exists( $S->{maxLength} ) && $ctx->{trace_on} );

    if( exists( $S->{pattern} ) )
    {
        my $re = $S->{pattern};
        local $@;
        my $ok = eval{ $s =~ /$re/ };
        _t( $ctx, $ptr, 'pattern', undef, $ok ? 'pass' : 'fail', "/$re/" ) if( $ctx->{trace_on} );
        return( _err( $ctx, $ptr, "string does not match pattern /$re/", 'pattern' ) ) unless( $ok );
    }
    return(1);
}

# Primitive keyword helpers
sub _k_type
{
    my( $ctx, $v, $type_kw, $ptr ) = @_;

    my @alts = ref( $type_kw ) eq 'ARRAY' ? @$type_kw : ( $type_kw );

    # First, allow inline schemas in the union
    my $i = 0;
    for my $alt ( @alts )
    {
        if( ref( $alt ) eq 'HASH' )
        {
            my $r = _v( $ctx, _join_ptr( $ptr, "type/$i" ), $alt, $v );
            return(1) if( $r->{ok} );
        }
        $i++;
    }

    # Then, try string type names
    for my $t ( @alts )
    {
        next if( ref( $t ) );
        return(1) if( _match_type( $v, $t ) );
    }

    my $exp = join( '|', map{ ref( $_ ) ? 'schema' : $_ } @alts );
    return( _err( $ctx, $ptr, "type mismatch: expected $exp", 'type' ) );
}

sub _k_unique_keys
{
    my( $ctx, $sp, $uk_def, $array ) = @_;
    unless( ref( $uk_def ) eq 'ARRAY' && @$uk_def )
    {
        return( { ok => 1, props => {}, items => {} } );
    }

    for my $key_set ( @$uk_def )
    {
        next unless( ref( $key_set ) eq 'ARRAY' && @$key_set );

        my %seen;
        for my $i ( 0 .. $#$array )
        {
            my $item = $array->[$i];
            next unless( ref( $item ) eq 'HASH' );

            my @key_vals;
            my $all_present = 1;
            for my $key ( @$key_set )
            {
                if( exists( $item->{ $key } ) )
                {
                    push( @key_vals, _canon( $item->{ $key } ) );
                }
                else
                {
                    $all_present = 0;
                    last;
                }
            }

            # Skip items that do not have *all* keys in this key set
            next unless( $all_present );

            my $composite = join( "\0", @key_vals );
            if( exists( $seen{ $composite } ) )
            {
                my $prev_i = $seen{ $composite };
                my $keys   = join( ', ', map { "'$_'" } @$key_set );
                push( @{$ctx->{ptr_stack}}, _join_ptr( $sp, $i ) );
                my $res = _err_res(
                    $ctx,
                    $sp,
                    "uniqueKeys violation: items[$prev_i] and items[$i] have identical values for key(s) [$keys]",
                    'uniqueKeys',
                );
                pop( @{$ctx->{ptr_stack}} );

                return( $res );
            }
            $seen{ $composite } = $i;
        }
    }

    return( { ok => 1, props => {}, items => {} } );
}

sub _match_type
{
    my( $v, $t ) = @_;

    return(1) if( $t eq 'null' && !defined( $v ) );

    if( $t eq 'boolean' )
    {
        return(0) if( !defined( $v ) );
        if( blessed( $v ) && ( ref( $v ) =~ /Boolean/ ) )
        {
            my $s = "$v";
            return( ( $s eq '0' || $s eq '1' ) ? 1 : 0 );
        }
        return( ( $v =~ /\A(?:0|1|true|false)\z/i ) ? 1 : 0 );
    }

    if( $t eq 'integer' )
    {
        return(0) unless( _is_number( $v ) );
        return( ( $v =~ /\A-?(?:0|[1-9][0-9]*)\z/ ) ? 1 : 0 );
    }

    if( $t eq 'number' )
    {
        return( _is_number( $v ) );
    }

    if( $t eq 'string' )
    {
        # Must be a scalar, defined, and NOT a numeric SV under strict typing.
        return( (!ref( $v ) && defined( $v ) && !_is_number( $v )) ? 1 : 0 );
    }

    return(1) if( $t eq 'array'  && ref( $v ) eq 'ARRAY' );
    return(1) if( $t eq 'object' && ref( $v ) eq 'HASH' );

    return(0);
}

sub _normalize_uri
{
    my( $u ) = @_;
    return( '#' ) unless( defined( $u ) && length( $u ) );
    return( $u );
}

sub _parse_media_type
{
    my( $s ) = @_;
    my( $type, @rest ) = split( /;/, "$s" );
    $type ||= '';
    $type =~ s/\s+//g;
    my %p;
    for my $kv ( @rest )
    {
        my( $k, $v ) = split( /=/, $kv, 2 );
        next unless( defined( $k ) );
        $k =~ s/\s+//g;
        $v = '' unless( defined( $v ) );
        $v =~ s/^\s+|\s+$//g;
        # Allow single or double quote, but be consistent
        $v =~ s/^(?<quote>["'])(.*)\g{quote}$/$2/;
        $p{ lc( $k ) } = $v;
    }
    return( lc( $type ), \%p );
}

sub _prune_array_with_schema
{
    my( $self, $schema, $data ) = @_;

    my @out;

    my $shape =
    {
        prefix_items => [],   # index => subschema
        items        => undef # subschema for additional items
    };

    $self->_extract_array_shape( $schema, $shape );

    for my $i ( 0 .. $#$data )
    {
        my $item = $data->[ $i ];
        my $item_schema;

        if( defined( $shape->{prefix_items}->[ $i ] ) )
        {
            $item_schema = $shape->{prefix_items}->[ $i ];
        }
        elsif( $shape->{items} )
        {
            $item_schema = $shape->{items};
        }

        if( $item_schema && ref( $item ) )
        {
            $out[ $i ] = $self->_prune_with_schema( $item_schema, $item );
        }
        else
        {
            # No structural knowledge or scalar item: keep as-is
            $out[ $i ] = $item;
        }
    }

    return( \@out );
}

sub _prune_object_with_schema
{
    my( $self, $schema, $data ) = @_;

    # Collect effective object shape from this schema and any allOf mixins.
    my $shape =
    {
        props     => {},   # property name => subschema
        patterns  => [],   # [ regex, subschema ] ...
        allow_ap  => 1,    # additionalProperties allowed?
        ap_schema => undef # subschema for additionalProperties, if any
    };

    $self->_extract_object_shape( $schema, $shape );

    my %clean;

    KEY:
    foreach my $key ( keys( %$data ) )
    {
        my $val = $data->{ $key };

        # 1) Direct properties
        if( exists( $shape->{props}->{ $key } ) )
        {
            my $sub = $shape->{props}->{ $key };
            $clean{ $key } = $self->_prune_with_schema( $sub, $val );
            next KEY;
        }

        # 2) patternProperties
        foreach my $pair ( @{$shape->{patterns}} )
        {
            my( $re, $pschema ) = @$pair;
            my $ok;

            {
                local $@;
                $ok = eval{ $key =~ /$re/ ? 1 : 0; };
            }

            next unless( $ok );

            $clean{ $key } = $self->_prune_with_schema( $pschema, $val );
            next KEY;
        }

        # 3) additionalProperties
        if( $shape->{allow_ap} )
        {
            if( $shape->{ap_schema} && ref( $val ) )
            {
                $clean{ $key } = $self->_prune_with_schema( $shape->{ap_schema}, $val );
            }
            else
            {
                # allowed, but no further structure known
                $clean{ $key } = $val;
            }
        }
        else
        {
            # additionalProperties is false (or equivalent) => drop unknown key
            next KEY;
        }
    }

    return( \%clean );
}

sub _prune_with_schema
{
    my( $self, $schema, $data ) = @_;

    # Boolean schemas and non-hash schemas: do not attempt pruning.
    return( $data ) unless( ref( $schema ) eq 'HASH' );

    # Only prune structured values; scalars we leave untouched.
    if( ref( $data ) eq 'HASH' )
    {
        return( $self->_prune_object_with_schema( $schema, $data ) );
    }
    elsif( ref( $data ) eq 'ARRAY' )
    {
        return( $self->_prune_array_with_schema( $schema, $data ) );
    }

    return( $data );
}

sub _ptr_of_node
{
    my( $root, $target ) = @_;
    for my $p ( keys( %{$root->{anchors}} ) )
    {
        my $n = $root->{anchors}->{ $p };
        return( $p ) if( $n eq $target );
    }
    return( '#' );
}

my %SCRIPT_LIKE = map{ $_ => 1 } qw(
    Hiragana Katakana Han Hangul Latin Cyrillic Greek
    Hebrew Thai Armenian Georgian
    Arabic Devanagari Bengali Gurmukhi Gujarati Oriya
    Tamil Telugu Kannada Malayalam Sinhala
    Lao Tibetan Myanmar Khmer
);
sub _re_to_js
{
    my $re = shift( @_ );
    my %opt = @_;

    # style: 'literal'  => for use in /.../u
    #        'string'   => for use in new RegExp("...", "u")
    my $style = $opt{style} || 'string';

    return if( !defined( $re ) || !length( $re ) );

    #
    # 1) Convert \x{...} (Perl) to \u.... or \u{....} (JS)
    #    - 1–4 hex digits  -> \uHHHH
    #    - 5–6 hex digits  -> \u{HHHHH}  (requires /u in JS)
    #
    $re =~ s{
        \\x\{([0-9A-Fa-f]{1,6})\}
    }{
        my $hex = uc( $1 );
        if( length( $hex ) <= 4 )
        {
            "\\u$hex";
        }
        else
        {
            "\\u\{$hex\}";
        }
    }egx;

    # Script eXtended
    # 
    # 2) Convert \p{Katakana} / \P{Katakana}
    #    to \p{scx=Katakana} / \P{scx=Katakana}
    #    (Script_Extensions so it covers half-width too)
    #
    $re =~ s[
        \\([pP])\{([^}]+)\}
    ][
        my( $p, $name ) = ( $1, $2 );

        my $norm = $name;
        $norm =~ s/^\s+|\s+$//g;
        $norm = ucfirst( lc( $norm ) );

        if( exists( $SCRIPT_LIKE{ $norm } ) )
        {
            "\\$p\{scx=$norm\}";
        }
        else
        {
            # Pass other properties through unchanged:
            # \p{L}, \p{Letter}, \p{Nd}, etc.
            "\\$p\{$name\}";
        }
    ]egx;

    #
    # 3) Optionally escape backslashes for JS string literal
    #
    if( $style eq 'string' )
    {
        $re =~ s{\\}{\\\\}g;   # existing
        $re =~ s{"}{\\"}g;     # escape "
        $re =~ s{\n}{\\n}g;
        $re =~ s{\r}{\\r}g;
        $re =~ s{/}{\/}g;
    }

    # For 'literal', we leave backslashes as-is, for use in /.../u

    return( $re );
}

sub _register_builtin_media_validators
{
    my( $self ) = @_;

    # Example: application/json
    $self->register_media_validator( 'application/json' => sub
    {
        my( $bytes, $params ) = @_;
        local $@;
        my $v = eval{ JSON->new->allow_nonref(1)->decode( $bytes ) };
        return( 0, 'invalid JSON', undef ) if( $@ );
        # JSON value is valid even if it’s 0, "", or false
        return( 1, undef, $v );
    } );

    return( $self );
}

sub _resolve_uri
{
    my( $base, $ref ) = @_;
    return( $ref ) if( !defined( $base ) || $base eq '' || $ref =~ /^[A-Za-z][A-Za-z0-9+\-.]*:/ );
    if( $ref =~ /^\#/ )
    {
        ( my $no_frag = $base ) =~ s/\#.*$//;
        return( $no_frag . $ref );
    }
    return( $base . $ref ) if( $base =~ /\/$/ );
    ( my $dir = $base ) =~ s{[^/]*$}{};
    return( $dir . $ref );
}

sub _safe_invoke
{
    my( $cb, @args ) = @_;
    local $@;
    # Force list context to preserve (ok, msg, out) style returns
    my @ret = eval{ $cb->( @args ) };
    return( 0, ( $@ || 'callback failed' ), undef ) if( $@ );

    # If callback returns (ok, msg, out) or (ok, msg)
    if( @ret >= 2 )
    {
        my( $ok, $msg, $out ) = ( $ret[0] ? 1 : 0, $ret[1], $ret[2] );
        return( $ok, $msg, $out );
    }

    # If callback returns a single value
    if( @ret == 1 )
    {
        my $v = $ret[0];
        # Reference => treat as decoded structure (success)
        return( 1, undef, $v ) if( ref( $v ) );
        # Defined scalar => truthiness decides; scalar can be treated as decoded bytes
        return( $v ? 1 : 0, undef, ( defined( $v ) ? $v : undef ) );
    }

    # Empty list => treat as failure (safer default)
    return( 0, 'callback returned no value', undef );
}

sub _strlen
{
    my( $s ) = @_;
    $s = Encode::decode( 'UTF-8', "$s", Encode::FB_DEFAULT ) unless( Encode::is_utf8( $s ) );
    my @cp = unpack( 'U*', $s );
    return( scalar( @cp ) );
}

# Strict base64: validates alphabet, padding, length, and round-trips
sub _strict_base64_decode
{
    my( $s ) = @_;
    return unless( defined( $s ) );

    # strip ASCII whitespace per RFC 4648 §3.3 (tests commonly include raw)
    ( my $norm = "$s" ) =~ s/\s+//g;

    # valid alphabet + padding only
    return unless( $norm =~ /\A[A-Za-z0-9+\/]*={0,2}\z/ );

    # length must be a multiple of 4
    return unless( ( length( $norm ) % 4 ) == 0 );

    local $@;
    return unless( eval{ require MIME::Base64; 1 } );

    my $out = MIME::Base64::decode_base64( $norm );

    # re-encode and compare to ensure no silent salvage
    my $re = MIME::Base64::encode_base64( $out, '' );
    # RFC allows omitting trailing '=' if not needed; normalize both
    $re   =~ s/\s+//g;
    $norm =~ s/\s+//g;
    return unless( $re eq $norm );
    return( $out );
}

sub _t
{
    my( $ctx, $schema_ptr, $keyword, $inst_path, $outcome, $note ) = @_;
    return unless( $ctx->{trace_on} );

    if( $ctx->{trace_limit} && @{$ctx->{trace}} >= $ctx->{trace_limit} )
    {
        return;
    }
    if( $ctx->{trace_sample} )
    {
        return if( int( rand(100) ) >= $ctx->{trace_sample} );
    }

    push( @{$ctx->{trace}}, 
    {
        schema_ptr => $schema_ptr,
        keyword    => $keyword,
        inst_path  => ( $ctx->{ptr_stack}->[-1] // '#' ),
        outcome    => $outcome,   # 'pass' | 'fail'
        note       => $note,      # short string
    });
}

# Validation core with annotation + recursion
# _v returns { ok => 0|1, props => {k=>1,...}, items => {i=>1,...} }
sub _v
{
    my( $ctx, $schema_ptr, $schema, $inst ) = @_;

    # Recursion guard only for reference types
    if( ref( $inst ) )
    {
        my $inst_addr = _inst_addr( $inst, $ctx->{ptr_stack}->[-1] );
        my $vkey      = "$schema_ptr|$inst_addr";
        return( { ok => 1, props => {}, items => {} } ) if( $ctx->{visited}->{ $vkey }++ );
    }

    # Enter dynamicAnchor scope if present
    my $frame_added = 0;
    if( ref( $schema ) eq 'HASH' &&
        exists( $schema->{'$dynamicAnchor'} ) &&
        defined( $schema->{'$dynamicAnchor'} ) &&
        $schema->{'$dynamicAnchor'} ne '' )
    {
        my %frame = %{$ctx->{dyn_stack}->[-1]}; # inherit
        $frame{ $schema->{'$dynamicAnchor'} } = $schema;
        push( @{$ctx->{dyn_stack}}, \%frame );
        $frame_added = 1;
    }

    my $res = _v_node( $ctx, $schema_ptr, $schema, $inst );

    if( $frame_added )
    {
        pop( @{$ctx->{dyn_stack}} );
    }

    return( $res );
}

sub _v_node
{
    my( $ctx, $schema_ptr, $schema, $inst ) = @_;

    # $ref / $dynamicRef first
    if( ref( $schema ) eq 'HASH' &&
        exists( $schema->{'$ref'} ) )
    {
        return( _apply_ref( $ctx, $schema_ptr, $schema->{'$ref'}, $inst ) );
    }
    if( ref( $schema ) eq 'HASH' &&
        exists( $schema->{'$dynamicRef'} ) )
    {
        return( _apply_dynamic_ref( $ctx, $schema_ptr, $schema->{'$dynamicRef'}, $inst ) );
    }
    if( ref( $schema ) eq 'HASH' &&
        exists( $schema->{'$comment'} ) &&
        defined( $schema->{'$comment'} ) )
    {
        my $c = $schema->{'$comment'};
        if( my $cb = $ctx->{comment_handler} )
        {
            local $@;
            eval{ $cb->( $schema_ptr, "$c" ) };
            # ignore callback errors to keep validation resilient
        }
        _t( $ctx, $schema_ptr, '$comment', undef, 'visit', "$c" ) if( $ctx->{trace_on} );
    }

    _t( $ctx, $schema_ptr, 'node', undef, 'visit' ) if( $ctx->{trace_on} );

    # Use compiled validator if enabled
    if( $ctx->{compile_on} )
    {
        my $fn = $ctx->{root}->{fn_index}->{ $schema_ptr };
        unless( $fn )
        {
            $fn = _compile_node( $ctx->{root}, $schema_ptr, $schema );
            $ctx->{root}->{fn_index}->{ $schema_ptr } = $fn;
        }
        return( $fn->( $ctx, $inst ) );
    }

    return( { ok => 1, props => {}, items => {} } ) unless( ref( $schema ) eq 'HASH' );

    my $ptr = $schema_ptr;

    # Types / const / enum
    if( exists( $schema->{type} ) )
    {
        _k_type( $ctx, $inst, $schema->{type}, $ptr ) or return( _fail() );
    }
    if( exists( $schema->{const} ) )
    {
        _k_const( $ctx, $inst, $schema->{const}, $ptr ) or return( _fail() );
    }
    if( exists( $schema->{enum} ) )
    {
        _k_enum( $ctx, $inst, $schema->{enum}, $ptr ) or return( _fail() );
    }
    _t( $ctx, $schema_ptr, 'type/const/enum', undef, 'pass', '' ) if( $ctx->{trace_on} );

    if( $ctx->{unique_keys} &&
        exists( $schema->{uniqueKeys} ) &&
        ref( $schema->{uniqueKeys} ) eq 'ARRAY' &&
        ref( $inst ) eq 'ARRAY' )
    {
        my $r = _k_unique_keys( $ctx, $ptr, $schema->{uniqueKeys}, $inst );
        return( $r ) unless( $r->{ok} );
    }

    # Numbers
    if( _is_number( $inst ) )
    {
        for my $k ( qw( multipleOf minimum maximum exclusiveMinimum exclusiveMaximum ) )
        {
            next unless( exists( $schema->{ $k } ) );
            _k_number( $ctx, $inst, $k, $schema->{ $k }, $ptr ) or return( _fail() );
        }
    }

    # Strings
    if( !ref( $inst ) && defined( $inst ) )
    {
        if( exists( $schema->{minLength} ) || exists( $schema->{maxLength} ) || exists( $schema->{pattern} ) )
        {
            _k_string( $ctx, $inst, $schema, $ptr ) or return( _fail() );
        }
        if( exists( $schema->{format} ) )
        {
            _k_format( $ctx, $inst, $schema->{format}, $ptr ) or return( _fail() );
        }

        # contentEncoding / contentMediaType / contentSchema
        if( exists( $schema->{contentEncoding} ) ||
            exists( $schema->{contentMediaType} ) ||
            exists( $schema->{contentSchema} ) )
        {
            my $assert = $ctx->{content_assert} ? 1 : 0;
            my $bytes  = "$inst";
            my $decoded_ref;

            if( exists( $schema->{contentEncoding} ) )
            {
                my $dec = _content_decode( $ctx, $schema->{contentEncoding}, $bytes );
                if( !defined( $dec ) )
                {
                    return( _err_res( $ctx, $ptr, "contentEncoding '$schema->{contentEncoding}' decode failed", 'contentEncoding' ) ) if( $assert );
                }
                else
                {
                    $bytes = $dec;
                }
            }

            if( exists( $schema->{contentMediaType} ) )
            {
                my( $mt, $params ) = _parse_media_type( $schema->{contentMediaType} );
                if( my $cb = $ctx->{media_validators}->{ $mt } )
                {
                    my( $ok, $msg, $maybe_decoded ) = _safe_invoke( $cb, $bytes, $params );
                    if( !$ok )
                    {
                        return( _err_res( $ctx, $ptr, ( $msg || "contentMediaType '$mt' validation failed", 'contentMediaType' ) ) ) if( $assert );
                    }
                    $decoded_ref = $maybe_decoded if( ref( $maybe_decoded ) );
                    $bytes = $maybe_decoded if( defined( $maybe_decoded ) && !ref( $maybe_decoded ) );
                }
                else
                {
                    if( $mt =~ m{\Atext/} && ( ( $params->{charset} || '' ) =~ /\Autf-?8\z/i ) )
                    {
                        local $@;
                        my $ok = eval
                        {
                            require Encode;
                            Encode::decode( 'UTF-8', $bytes, Encode::FB_CROAK );
                            1;
                        } ? 1 : 0;
                        if( !$ok && $assert )
                        {
                            return( _err_res( $ctx, $ptr, "contentMediaType '$mt' invalid UTF-8", 'contentMediaType' ) );
                        }
                    }
                }
            }

            if( exists( $schema->{contentSchema} ) )
            {
                my $val;
                if( ref( $decoded_ref ) )
                {
                    $val = $decoded_ref; # already decoded by media validator
                }
                else
                {
                    local $@;
                    $val = eval{ JSON->new->allow_nonref(1)->utf8(1)->decode( $bytes ) };
                }

                if( !defined( $val ) )
                {
                    return( _err_res( $ctx, $ptr, "contentSchema present but payload not JSON-decodable", 'contentSchema' ) ) if( $assert );
                }
                else
                {
                    my $r = _v( $ctx, _join_ptr( $ptr, 'contentSchema' ), $schema->{contentSchema}, $val );
                    return( $r ) unless( $r->{ok} );
                }
            }
        }
    }

    my %ann_props;
    my %ann_items;

    # Arrays
    if( ref( $inst ) eq 'ARRAY' )
    {
        my $r = _k_array_all( $ctx, $schema_ptr, $schema, $inst );
        return( $r ) unless( $r->{ok} );
        %ann_items = ( %ann_items, %{ $r->{items} } );
    }
    _t( $ctx, $schema_ptr, 'array', undef, 'pass', '' ) if( ref( $inst ) eq 'ARRAY' && $ctx->{trace_on} );

    # Objects
    if( ref( $inst ) eq 'HASH' )
    {
        my $r = _k_object_all( $ctx, $schema_ptr, $schema, $inst );
        return( $r ) unless( $r->{ok} );
        %ann_props = ( %ann_props, %{ $r->{props} } );
    }
    _t( $ctx, $schema_ptr, 'object', undef, 'pass', '' ) if( ref( $inst ) eq 'HASH' && $ctx->{trace_on} );

    # Combinators
    for my $comb ( qw( allOf anyOf oneOf not ) )
    {
        next unless( exists( $schema->{ $comb } ) );
        my $r = _k_combinator( $ctx, $schema_ptr, $schema, $inst, $comb );
        return( $r ) unless( $r->{ok} );
        %ann_props = ( %ann_props, %{ $r->{props} } );
        %ann_items = ( %ann_items, %{ $r->{items} } );
        _t( $ctx, $schema_ptr, $comb, undef, 'pass', '' ) if( $ctx->{trace_on} );
    }

    # Conditionals
    if( exists( $schema->{if} ) )
    {
        my $r = _k_if_then_else( $ctx, $schema_ptr, $schema, $inst );
        return( $r ) unless( $r->{ok} );
        %ann_props = ( %ann_props, %{ $r->{props} } );
        %ann_items = ( %ann_items, %{ $r->{items} } );
    }

    _t( $ctx, $schema_ptr, 'node', undef, 'pass' ) if( $ctx->{trace_on} );
    return( { ok => 1, props => \%ann_props, items => \%ann_items } );
}

# NOTE: JSON::Schema::Validate::Error
package JSON::Schema::Validate::Error;
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $VERSION );
    use overload (
        '""'    => 'as_string',
        'eq'    => sub{ _obj_eq(@_) },
        'ne'    => sub{ !_obj_eq(@_) },
        '=='    => sub{ _obj_eq(@_) },
        '!='    => sub{ !_obj_eq(@_) },
        bool    => sub{1},
        fallback => 1,
    );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;
use utf8;

sub new
{
    my $that = shift( @_ );
    my $ref = {};
    # Legacy instantiation
    # We make sure this is not one single option that was provided to us.
    if( @_ == 2 && $_[0] !~ /^(?:path|message|keyword|schema_pointer)$/ )
    {
        @$ref{qw( path message )} = @_;
    }
    else
    {
        my $args = { @_ };
        for( qw( path message keyword schema_pointer ) )
        {
            $ref->{ $_ } = $args->{ $_ } if( exists( $args->{ $_ } ) );
        }
    }
    return( bless( $ref => ( ref( $that ) || $that ) ) );
}

sub as_hash
{
    my $self = shift( @_ );
    my $ref = {};
    my @keys = qw( keyword message path schema_pointer );
    @$ref{ @keys } = @$self{ @keys };
    return( $ref );
}

sub as_string
{
    my $self = shift( @_ );
    my $sp   = $self->schema_pointer // '';
    my $path = $self->path // '';
    my $msg  = $self->message // '';
    # Dual-path if avail
    return( $sp ? "${sp} → ${path}: ${msg}" : "${path}: ${msg}" );
}

sub keyword
{
    my $self = shift( @_ );
    $self->{keyword} = shift( @_ ) if( @_ );
    return( $self->{keyword} );
}

sub message
{
    my $self = shift( @_ );
    $self->{message} = shift( @_ ) if( @_ );
    return( $self->{message} );
}

sub path
{
    my $self = shift( @_ );
    $self->{path} = shift( @_ ) if( @_ );
    return( $self->{path} );
}

sub schema_pointer
{
    my $self = shift( @_ );
    $self->{schema_pointer} = shift( @_ ) if( @_ );
    return( $self->{schema_pointer} );
}

sub _obj_eq
{
    no overloading;
    my $self  = shift( @_ );
    my $other = shift( @_ );
    my $me;
    if( defined( $other ) &&
        Scalar::Util::blessed( $other ) &&
        $other->isa( 'JSON::Schema::Validate::Error' ) )
    {
        if( ( $self->message // '' ) eq ( $other->message // '' ) &&
            ( $self->path // '' ) eq ( $other->path // '' ) )
        {
            return(1);
        }
        else
        {
            return(0);
        }
    }
    # Compare error message
    elsif( !ref( $other ) )
    {
        my $me = $self->message // '';
        return( $me eq $other );
    }
    # Otherwise some reference data to which we cannot compare
    return(0) ;
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

JSON::Schema::Validate - Lean, recursion-safe JSON Schema validator (Draft 2020-12)

=head1 SYNOPSIS

    use JSON::Schema::Validate;
    use JSON ();

    my $schema = {
        '$schema' => 'https://json-schema.org/draft/2020-12/schema',
        '$id'     => 'https://example.org/s/root.json',
        type      => 'object',
        required  => [ 'name' ],
        properties => {
            name => { type => 'string', minLength => 1 },
            next => { '$dynamicRef' => '#Node' },
        },
        '$dynamicAnchor' => 'Node',
        additionalProperties => JSON::false,
    };

    my $js = JSON::Schema::Validate->new( $schema )
        ->compile
        ->content_checks
        ->ignore_unknown_required_vocab
        ->prune_unknown
        ->register_builtin_formats
        ->trace
        ->trace_limit(200) # 0 means unlimited
        ->unique_keys; # enable uniqueKeys

You could also do:

    my $js = JSON::Schema::Validate->new( $schema,
        compile          => 1,
        content_checks   => 1,
        ignore_req_vocab => 1,
        prune_unknown    => 1,
        trace_on         => 1,
        trace_limit      => 200,
        unique_keys      => 1,
    )->register_builtin_formats;

    my $ok = $js->validate({ name => 'head', next => { name => 'tail' } })
        or die( $js->error );

    print "ok\n";

    # Override instance options for one call only (backward compatible)
    $js->validate( $data, max_errors => 1 )
        or die( $js->error );

    # Quick boolean check (records at most one error by default)
    $js->is_valid({ name => 'head', next => { name => 'tail' } })
        or die( $js->error );

Generating a browser-side validator with L</compile_js>:

    use JSON::Schema::Validate;
    use JSON ();

    my $schema = JSON->new->decode( do {
        local $/;
        <DATA>;
    } );

    my $js = JSON::Schema::Validate->new( $schema )
        ->compile;
    my $ok = $js->validate({ name => 'head', next => { name => 'tail' } })
        or die( $js->error );

    # Generate a standalone JavaScript validator for use in a web page.
    # ecma => 2018 enables Unicode regex features when available.
    my $js_code = $validator->compile_js( ecma => 2018 );

    open my $fh, '>:encoding(UTF-8)', 'htdocs/js/schema-validator.js'
        or die( "Unable to write schema-validator.js: $!" );
    print {$fh} $js_code;
    close $fh;

In your HTML:

    <script src="/js/schema-validator.js"></script>
    <script>
    function validateForm()
    {
        var src = document.getElementById('payload').value;
        var out = document.getElementById('errors');
        var inst;

        try
        {
            inst = JSON.parse( src );
        }
        catch( e )
        {
            out.textContent = "Invalid JSON: " + e;
            return;
        }

        // The generated file defines a global function `validate(inst)`
        // that returns an array of error objects.
        var errors = validate( inst );

        if( !errors || !errors.length )
        {
            out.textContent = "OK – no client-side schema errors.";
            return;
        }

        var lines = [];
        for( var i = 0; i < errors.length; i++ )
        {
            var e = errors[i];
            lines.push(
                e.path + " [" + e.keyword + "]: " + e.message
            );
        }
        out.textContent = lines.join("\n");
    }
    </script>

=head1 VERSION

v0.7.0

=head1 DESCRIPTION

C<JSON::Schema::Validate> is a compact, dependency-light validator for L<JSON Schema|https://json-schema.org/> draft 2020-12. It focuses on:

=over 4

=item *

Correctness and recursion safety (supports C<$ref>, C<$dynamicRef>, C<$anchor>, C<$dynamicAnchor>).

=item *

Draft 2020-12 evaluation semantics, including C<unevaluatedItems> and C<unevaluatedProperties> with annotation tracking.

=item *

A practical Perl API (constructor takes the schema; call C<validate> with your data; inspect C<error> / C<errors> on failure).

=item *

Builtin validators for common C<format>s (date, time, email, hostname, ip, uri, uuid, JSON Pointer, etc.), with the option to register or override custom format handlers.

=item *

Optional code generation via L</compile_js> to run a subset of the schema client-side in JavaScript, using the same error structure as the Perl validator.

=back

This module is intentionally minimal compared to large reference implementations, but it implements the parts most people rely on in production.

=head2 Supported Keywords (2020-12)

=over 4

=item * Types

C<type> (string or array of strings), including union types. Unions may also include inline schemas (e.g. C<< type => [ 'integer', { minimum => 0 } ] >>).

=item * Constant / Enumerations

C<const>, C<enum>.

=item * Numbers

C<multipleOf>, C<minimum>, C<maximum>, C<exclusiveMinimum>, C<exclusiveMaximum>.

=item * Strings

C<minLength>, C<maxLength>, C<pattern>, C<format>.

=item * Arrays

C<prefixItems>, C<items>, C<contains>, C<minContains>, C<maxContains>, C<uniqueItems>, C<unevaluatedItems>.

=item * Objects

C<properties>, C<patternProperties>, C<additionalProperties>, C<propertyNames>, C<required>, C<dependentRequired>, C<dependentSchemas>, C<unevaluatedProperties>.

=item * Combinators

C<allOf>, C<anyOf>, C<oneOf>, C<not>.

=item * Conditionals

C<if>, C<then>, C<else>.

=item * Referencing

C<$id>, C<$anchor>, C<$ref>, C<$dynamicAnchor>, C<$dynamicRef>.

=back

The Perl engine supports the full list above. The generated JavaScript currently implements a pragmatic subset; see L</compile_js> for details.

=head2 Formats

Call C<register_builtin_formats> to install default validators for the following C<format> names:

=over 4

=item * C<date-time>, C<date>, C<time>, C<duration>

Leverages L<DateTime> and L<DateTime::Format::ISO8601> when available (falls back to strict regex checks). Duration uses L<DateTime::Duration>.

=item * C<email>, C<idn-email>

Imported and use the very complex and complete regular expression from L<Regexp::Common::Email::Address>, but without requiring this module.

=item * C<hostname>, C<idn-hostname>

C<idn-hostname> uses L<Net::IDN::Encode> if available; otherwise, applies a permissive Unicode label check and then C<hostname> rules.

=item * C<ipv4>, C<ipv6>

Strict regex-based validation.

=item * C<uri>, C<uri-reference>, C<iri>

Reasonable regex checks for scheme and reference forms (heuristic, not a full RFC parser).

=item * C<uuid>

Hyphenated 8-4-4-4-12 hex.

=item * C<json-pointer>, C<relative-json-pointer>

Conformant to RFC 6901 and the relative variant used by JSON Schema.

=item * C<regex>

Checks that the pattern compiles in Perl.

=back

Custom formats can be registered or override builtins via C<register_format> or the C<format =E<gt> { ... }> constructor option (see L</METHODS>).

=head1 CONSTRUCTOR

=head2 new

    my $js = JSON::Schema::Validate->new( $schema, %opts );

Build a validator from a decoded JSON Schema (Perl hash/array structure), and returns the newly instantiated object.

Options (all optional):

=over 4

=item C<compile =E<gt> 1|0>

Defaults to C<0>

Enable or disable the compiled-validator fast path.

When enabled and the root has not been compiled yet, this triggers an initial compilation.

=item C<content_assert =E<gt> 1|0>

Defaults to C<0>

Enable or disable the content assertions for the C<contentEncoding>, C<contentMediaType> and C<contentSchema> trio.

When enabling, built-in media validators are registered (e.g. C<application/json>).

=item C<extensions =E<gt> 1|0>

Defaults to C<0>

This enables or disables all non-core extensions currently implemented by the validator.

When set to a true value, this enables the C<uniqueKeys> applicator. Future extensions (e.g. custom keywords, additional vocabularies) will also be controlled by this flag.

When set to a true value, all known extensions are activated; setting it to false disables them all.

If you set separately an extension boolean value, it will not be overriden by this. So for example:

    my $js = JSON::Schema::Validate->new( $schema, extension => 0, unique_keys => 1 );

Will globally disable extension, but will enable C<uniqueKeys>

Enabling extensions does not affect core Draft 2020-12 compliance — unknown keywords are still ignored unless explicitly supported.

=item C<format =E<gt> \%callbacks>

Hash of C<format_name =E<gt> sub{ ... }> validators. Each sub receives the string to validate and must return true/false. Entries here take precedence when you later call C<register_builtin_formats> (i.e. your callbacks remain in place).

=item C<ignore_unknown_required_vocab =E<gt> 1|0>

Defaults to C<0>

If enabled, required vocabularies declared in C<$vocabulary> that are not advertised as supported by the caller will be I<ignored> instead of causing the validator to C<die>.

You can also use C<ignore_req_vocab> for short.

=item C<max_errors>

Defaults to C<200>

Sets the maximum number of errors to be recorded.

=item C<normalize_instance =E<gt> 1|0>

Defaults to C<1>

When true, the instance is round-tripped through L<JSON> before validation, which enforces strict JSON typing (strings remain strings; numbers remain numbers). This matches Python C<jsonschema>’s type behaviour. Set to C<0> if you prefer Perl’s permissive numeric/string duality.

=item C<prune_unknown =E<gt> 1|0>

Defaults to C<0>

When set to a true value, unknown object properties in the instance are pruned (removed) prior to validation, based on the schema’s structural keywords.

Pruning currently takes into account:

=over 4

=item * C<properties>

=item * C<patternProperties>

=item * C<additionalProperties>

(item value or subschema, including within C<allOf>)

=item * C<allOf> (for merging additional object or array constraints)

=back

For objects:

=over 4

=item *

Any property explicitly declared under C<properties> is kept, and its value is recursively pruned according to its subschema (if it is itself an object or array).

=item *

Any property whose name matches one of the C<patternProperties> regular expressions is kept, and pruned recursively according to the associated subschema.

=item *

If C<additionalProperties> is C<false>, any object property not covered by C<properties> or C<patternProperties> is removed.

=item *

If C<additionalProperties> is a subschema, any such additional property is kept, and its value is pruned recursively following that subschema.

=back

For arrays:

=over 4

=item *

Items covered by C<prefixItems> (by index) or C<items> (for remaining elements) are kept, and if they are objects or arrays, they are pruned recursively. Existing positions are never removed; pruning only affects the nested contents.

=back

The pruner intentionally does B<not> interpret C<anyOf>, C<oneOf> or C<not> when deciding which properties to keep or drop, because doing so would require running full validation logic and could remove legitimate data incorrectly. In those cases, pruning errs on the side of keeping more data rather than over-pruning.

When C<prune_unknown> is disabled (the default), the instance is not modified for validation purposes, and no pruning is performed.

=item C<trace>

Defaults to C<0>

Enable or disable tracing. When enabled, the validator records lightweight, bounded trace events according to L</trace_limit> and L</trace_sample>.

=item C<trace_limit>

Defaults to C<0>

Set a hard cap on the number of trace entries recorded during a single C<validate> call (C<0> = unlimited).

=item C<trace_sample =E<gt> $percent>

Enable probabilistic sampling of trace events. C<$percent> is an integer percentage in C<[0,100]>. C<0> disables sampling. Sampling occurs per-event, and still respects L</trace_limit>.

=item C<unique_keys =E<gt> 1|0>

Defaults to C<0>

Explicitly enable or disable the C<uniqueKeys> applicator.

C<uniqueKeys> is a non-standard extension (proposed for future drafts) that enforces uniqueness of one or more properties across all objects in an array.

    "uniqueKeys": [ ["id"] ]                   # 'id' must be unique
    "uniqueKeys": [ ["id"], ["email"] ]        # id AND email must each be unique
    "uniqueKeys": [ ["category", "code"] ]     # the pair (category,code) must be unique

The applicator supports both single-property constraints and true composite keys.

This option is useful when you need stronger guarantees than C<uniqueItems> provides, without resorting to complex C<contains>/C<not> patterns.

When C<extensions> is enabled, C<unique_keys> is automatically turned on; the specific method allows finer-grained control.

This works in B<both interpreted and compiled modes> and is fully integrated into the annotation system (plays nicely with C<unevaluatedProperties>, etc.).

Disabled by default for maximum spec purity.

=item C<vocab_support =E<gt> {}>

A hash reference of support vocabularies.

=back

=head1 METHODS

=head2 compile

    $js->compile;       # enable compilation
    $js->compile(1);    # enable
    $js->compile(0);    # disable

Enable or disable the compiled-validator fast path.

When enabled and the root hasn’t been compiled yet, this triggers an initial compilation.

Returns the current object to enable chaining.

=head2 compile_js

    my $js_source = $js->compile_js;
    my $js_source = $js->compile_js( ecma => 2018 );

Generate a standalone JavaScript validator for the current schema and return it as a UTF-8 string.

You are responsible for writing this string to a C<.js> file and serving it to the browser (or embedding it in a page).

The generated code:

=over 4

=item *

Wraps everything in a simple IIFE (Immediately Invoked Function Expression) C<(function(global){ ... })(this)>.

=item *

Defines a single public function:

    function validate(inst) { ... }

exported on the global object (C<window.validate> in a browser).

=item *

Implements the same error reporting format as the Perl engine, but using plain JavaScript objects:

    {
        path:           "#/path/in/instance",
        keyword:        "minimum",
        message:        "number is less than minimum 2",
        schema_pointer: "#/definitions/.../minimum"
    }

=item *

Returns an C<Array> of such error objects. If validation succeeds, the array is empty.

=back

Supported JavaScript options:

=over 4

=item * C<ecma =E<gt> "auto" | YEAR>

Controls which JavaScript regexp features the generated code will try to use.

    ecma => "auto"      # default
    ecma => 2018        # assume ES2018+ (Unicode property escapes, etc.)

When C<ecma> is a number C<E<gt>= 2018>, patterns that use Unicode property escapes (e.g. C<\p{scx=Katakana}>) are compiled with the C</u> flag and will take advantage of Script / Script_Extensions support when the browser has it.

In C<"auto"> mode the generator emits cautious compatibility shims: “advanced” patterns are wrapped in C<try/catch>; if the browser cannot compile them, those checks are silently skipped on the client (and are still enforced server-side by Perl).

=item * C<max_errors =E<gt> 200>

Defaults to 200.

Set the maximum number of errors to be recorded.

=item * C<name =E<gt> "myValidator">

Defaults to C<validate>

Sets a custom name for the JavaScript validation function.

=back

=head3 JavaScript keyword coverage

The generated JS implements a pragmatic subset of the Perl engine:

=over 4

=item * Types

C<type> (including unions).

=item * Constants / enumerations

C<const> (primitive values only) and C<enum>.

Complex object/array C<const> values are currently ignored client-side and enforced server-side only.

=item * Numbers

C<minimum>, C<maximum>, C<exclusiveMinimum>, C<exclusiveMaximum>.

For better UX, numeric-looking strings such as C<"10"> or C<"3.14"> are coerced to numbers before applying bounds. Non-numeric values:

=over 4

=item *

trigger a C<type> error (C<"expected number but found string">) when numeric keywords are present and no explicit C<type> is declared;

=item *

or are handled by the normal C<type> keyword if you explicitly declared C<< type => 'number' >> in the schema.

=back

=item * Strings

C<minLength>, C<maxLength>, C<pattern>.

Patterns are converted from Perl syntax to JavaScript using a conservative converter (e.g. C<\x{FF70}> to C<\uFF70>, C<\p{Katakana}> to C<\p{scx=Katakana}>). When the browser does not support the necessary Unicode features, such patterns are skipped client-side.

=item * Arrays

C<items> (single-schema form), C<minItems>, C<maxItems>, C<contains>, C<minContains>, C<maxContains>.

=item * Objects

C<properties>, C<required>.

=item * Combinators

C<allOf>, C<anyOf>, C<oneOf>, C<not>.

“Negative required” patterns of the form C<< { "not": { "required": [...] } } >> are intentionally skipped on the client and enforced server-side only.

=item * Conditionals

C<if>, C<then>, C<else>, with the same semantics as the Perl engine: C<if> is evaluated in a “shadow” context and never produces errors directly; only C<then>/C<else> do.

=item * Non-core extension

C<uniqueKeys> when you enabled it via C<< unique_keys => 1 >> or C<< ->unique_keys >>.

=back

The following are intentionally B<not> implemented in JavaScript (but are fully supported in Perl):

=over 4

=item *

C<format> (client-side format checks are skipped).

=item *

C<prefixItems>, C<patternProperties>, C<unevaluatedItems>, C<unevaluatedProperties>, C<contentEncoding>, C<contentMediaType>, C<contentSchema>, external C<$ref> and C<$dynamicRef> targets.

=back

In other words: the JS validator is a fast, user-friendly I<pre-flight> check for web forms; the Perl validator remains the source of truth.

=head3 Example: integrating the generated JS in a form

Perl side:

    my $schema = ...; # your decoded schema

    my $validajstor = JSON::Schema::Validate->new( $schema )
        ->compile;

    my $js_source = $validator->compile_js( ecma => 2018 );

    open my $fh, '>:encoding(UTF-8)', 'htdocs/js/validator.js'
        or die( "Cannot write JS: $!" );
    print {$fh} $js_source;
    close $fh;

HTML / JavaScript:

    <textarea id="company-data" rows="8" cols="80">
    { "name_ja": "株式会社テスト", "capital": 1 }
    </textarea>

    <button type="button" onclick="runValidation()">Validate</button>

    <pre id="validation-errors"></pre>

    <script src="/js/validator.js"></script>
    <script>
    function runValidation()
    {
        var src = document.getElementById('company-data').value;
        var out = document.getElementById('validation-errors');
        var inst;

        try
        {
            inst = JSON.parse( src );
        }
        catch( e )
        {
            out.textContent = "Invalid JSON: " + e;
            return;
        }

        var errors = validate( inst ); // defined by validator.js

        if( !errors || !errors.length )
        {
            out.textContent = "OK – no client-side schema errors.";
            return;
        }

        var lines = [];
        for( var i = 0; i < errors.length; i++ )
        {
            var e = errors[i];
            lines.push(
                "- " + e.path +
                " [" + e.keyword + "]: " +
                e.message
            );
        }
        out.textContent = lines.join("\n");
    }
    </script>

You can then map each error back to specific fields, translate C<message> via your own localisation layer, or forward the C<errors> array to your logging pipeline.

=head2 content_checks

    $js->content_checks;     # enable
    $js->content_checks(1);  # enable
    $js->content_checks(0);  # disable

Turn on/off content assertions for the C<contentEncoding>, C<contentMediaType> and C<contentSchema> trio.

When enabling, built-in media validators are registered (e.g. C<application/json>).

Returns the current object to enable chaining.

=for Pod::Coverage enable_content_checks

=head2 error

    my $msg = $js->error;

Returns the first error L<JSON::Schema::Validate::Error> object out of all the possible errors found (see L</errors>), if any.

When stringified, the object provides a short, human-oriented message for the first failure.

=head2 errors

    my $array_ref = $js->errors;

All collected L<error objects|JSON::Schema::Validate::Error> (up to the internal C<max_errors> cap).

=head2 extensions

    $js->extensions;       # enable all extensions
    $js->extensions(1);    # enable
    $js->extensions(0);    # disable

Turn the extension framework on or off.

Enabling extensions currently activates the C<uniqueKeys> applicator (and any future non-core features). Disabling it turns all extensions off, regardless of individual settings.

Returns the object for method chaining.

=head2 get_trace

    my $trace = $js->get_trace; # arrayref of trace entries (copy)

Return a B<copy> of the last validation trace (array reference of hash references) so callers cannot mutate internal state. Each entry contains:

    {
        inst_path  => '#/path/in/instance',
        keyword    => 'node' | 'minimum' | ...,
        note       => 'short string',
        outcome    => 'pass' | 'fail' | 'visit' | 'start',
        schema_ptr => '#/path/in/schema',
    }

=head2 get_trace_limit

    my $n = $js->get_trace_limit;

Accessor that returns the numeric trace limit currently in effect. See L</trace_limit> to set it.

=head2 ignore_unknown_required_vocab

    $js->ignore_unknown_required_vocab;     # enable
    $js->ignore_unknown_required_vocab(1);  # enable
    $js->ignore_unknown_required_vocab(0);  # disable

If enabled, required vocabularies declared in C<$vocabulary> that are not advertised as supported by the caller will be I<ignored> instead of causing the validator to C<die>.

Returns the current object to enable chaining.

=head2 is_compile_enabled

    my $bool = $js->is_compile_enabled;

Read-only accessor.

Returns true if compilation mode is enabled, false otherwise.

=head2 is_content_checks_enabled

    my $bool = $js->is_content_checks_enabled;

Read-only accessor.

Returns true if content assertions are enabled, false otherwise.

=head2 is_trace_on

    my $bool = $js->is_trace_on;

Read-only accessor.

Returns true if tracing is enabled, false otherwise.

=head2 is_unique_keys_enabled

    my $bool = $js->is_unique_keys_enabled;

Read-only accessor.

Returns true if the C<uniqueKeys> applicator is currently active, false otherwise.

=head2 is_unknown_required_vocab_ignored

    my $bool = $js->is_unknown_required_vocab_ignored;

Read-only accessor.

Returns true if unknown required vocabularies are being ignored, false otherwise.

=head2 is_valid

    my $ok = $js->is_valid( $data );

    my $ok = $js->is_valid(
        $data,
        max_errors     => 1,     # default for is_valid
        trace_on       => 0,
        trace_limit    => 0,
        compile_on     => 0,
        content_assert => 0,
    );

Validate C<$data> against the compiled schema and return a boolean.

This is a convenience method intended for “yes/no” checks. It behaves like L</validate> but defaults to C<< max_errors => 1 >> so that, on failure, only one error is recorded.

On failure, the single recorded error can be retrieved with L</error>:

    $js->is_valid( $data )
        or die( $js->error );

Per-call options are passed through to L</validate> and may override the instance configuration for this call only (e.g. C<max_errors>, C<trace_on>, C<trace_limit>, C<compile_on>, C<content_assert>).

Returns 1 on success, 0 on failure.

=head2 prune_instance

    my $pruned = $jsv->prune_instance( $instance );

Returns a pruned copy of C<$instance> according to the schema that was passed to C<new>. The original data structure is B<not> modified.

The pruning rules are the same as those used when the constructor option C<prune_unknown> is enabled (see L</prune_unknown>), namely:

=over 4

=item *

For objects, only properties allowed by C<properties>, C<patternProperties> and C<additionalProperties> (including those brought in via C<allOf>) are kept. Their values are recursively pruned when they are objects or arrays.

=item *

If C<additionalProperties> is C<false>, properties not matched by C<properties> or C<patternProperties> are removed.

=item *

If C<additionalProperties> is a subschema, additional properties are kept and pruned recursively according to that subschema.

=item *

For arrays, items are never removed by index. However, for elements covered by C<prefixItems> or C<items>, their nested content is pruned recursively when it is an object or array.

=item *

C<anyOf>, C<oneOf> and C<not> are B<not> used to decide which properties to drop, to avoid over-pruning valid data without performing full validation.

=back

This method is useful when you want to clean incoming data structures before further processing, without necessarily performing a full schema validation at the same time.

=head2 register_builtin_formats

    $js->register_builtin_formats;

Registers the built-in validators listed in L</Formats>. Existing user-supplied format callbacks are preserved if they already exist under the same name.

User-supplied callbacks passed via C<< format => { ... } >> are preserved and take precedence.

=head2 register_content_decoder

    $js->register_content_decoder( $name => sub{ ... } );

or

    $js->register_content_decoder(rot13 => sub
    {
        $bytes =~ tr/A-Za-z/N-ZA-Mn-za-m/;
        return( $bytes ); # now treated as (1, undef, $decoded)
    });

Register a content B<decoder> for C<contentEncoding>. The callback receives a single argument: the raw data, and should return one of:

=over 4

=item * a decoded scalar (success);

=item * C<undef> (failure);

=item * or the triplet C<( $ok, $msg, $out )> where C<$ok> is truthy on success, C<$msg> is an optional error string, and C<$out> is the decoded value.

=back

The C<$name> is lower-cased internally. Returns the current object.

Throws an exception if the second argument is not a code reference.

=head2 register_format

    $js->register_format( $name, sub { ... } );

Register or override a C<format> validator at runtime. The sub receives a single scalar (the candidate string) and must return true/false.

=head2 register_media_validator

    $js->register_media_validator( 'application/json' => sub{ ... } );

Register a media B<validator/decoder> for C<contentMediaType>. The callback receives 2 arguments:

=over 4

=item * C<$bytes>

The data to validate

=item * C<\%params>

A hash reference of media-type parameters (e.g. C<charset>).

=back

It may return one of:

=over 4

=item * C<( $ok, $msg, $decoded )> — canonical form. On success C<$ok> is true, C<$msg> is optional, and C<$decoded> can be either a Perl structure or a new octet/string value.

=item * a reference — treated as success with that reference as C<$decoded>.

=item * a defined scalar — treated as success with that scalar as C<$decoded>.

=item * C<undef> or empty list — treated as failure.

=back

The media type key is lower-cased internally.

It returns the current object.

It throws an exception if the second argument is not a code reference.

=head2 set_comment_handler

    $js->set_comment_handler(sub
    {
        my( $schema_ptr, $text ) = @_;
        warn "Comment at $schema_ptr: $text\n";
    });

Install an optional callback for the Draft 2020-12 C<$comment> keyword.

C<$comment> is annotation-only (never affects validation). When provided, the callback is invoked once per encountered C<$comment> string with the schema pointer and the comment text. Callback errors are ignored.

If a value is provided, and is not a code reference, a warning will be emitted.

This returns the current object.

=head2 set_resolver

    $js->set_resolver( sub{ my( $absolute_uri ) = @_; ...; return $schema_hashref } );

Install a resolver for external documents. It is called with an absolute URI (formed from the current base C<$id> and the C<$ref>) and must return a Perl hash reference representation of a JSON Schema. If the returned hash contains C<'$id'>, it will become the new base for that document; otherwise, the absolute URI is used as its base.

=head2 set_vocabulary_support

    $js->set_vocabulary_support( \%support );

Declare which vocabularies the host supports, as a hash reference:

    {
        'https://example/vocab/core' => 1,
        ...
    }

Resets internal vocabulary-checked state so the declaration is enforced on next C<validate>.

By default, this module supports all vocabularies required by 2020-12.

However, you can restrict support:

    $js->set_vocabulary_support({
        'https://json-schema.org/draft/2020-12/vocab/core'         => 1,
        'https://json-schema.org/draft/2020-12/vocab/applicator'   => 1,
        'https://json-schema.org/draft/2020-12/vocab/format'       => 0,
        'https://mycorp/vocab/internal'                            => 1,
    });

It returns the current object.

=head2 trace

    $js->trace;    # enable
    $js->trace(1); # enable
    $js->trace(0); # disable

Enable or disable tracing. When enabled, the validator records lightweight, bounded trace events according to L</trace_limit> and L</trace_sample>.

It returns the current object for chaining.

=head2 trace_limit

    $js->trace_limit( $n );

Set a hard cap on the number of trace entries recorded during a single C<validate> call (C<0> = unlimited).

It returns the current object for chaining.

=head2 trace_sample

    $js->trace_sample( $percent );

Enable probabilistic sampling of trace events. C<$percent> is an integer percentage in C<[0,100]>. C<0> disables sampling. Sampling occurs per-event, and still respects L</trace_limit>.

It returns the current object for chaining.

=head2 unique_keys

    $js->unique_keys;       # enable uniqueKeys
    $js->unique_keys(1);    # enable
    $js->unique_keys(0);    # disable

Enable or disable the C<uniqueKeys> applicator independently of the C<extensions> option.

When disabled (the default), schemas containing the C<uniqueKeys> keyword are ignored.

Returns the object for method chaining.

=head2 validate

    my $ok = $js->validate( $data );

    my $ok = $js->validate(
        $data,
        max_errors      => 5,
        trace_on        => 1,
        trace_limit     => 200,
        compile_on      => 0,
        content_assert  => 1,
    );

Validate a decoded JSON instance against the compiled schema and return a boolean.

On failure, inspect C<< $js->error >> to retrieve the L<error object|JSON::Schema::Validate::Error> that stringifies for a concise message (first error), or C<< $js->errors >> for an array reference of L<error objects|JSON::Schema::Validate::Error>.

Example:

    my $ok = $js->validate( $data ) or die( $js->error );

Each error is a L<JSON::Schema::Validate::Error> object:

    my $err = $js->error;
    say $err->path;           # #/properties~1name
    say $err->schema_pointer; # #/properties/name
    say $err->keyword;        # minLength
    say $err->message;        # string shorter than minLength 1
    say "$err";               # stringifies to a concise message

=head3 Per-call option overrides

C<validate> accepts optional named parameters (hash or hash reference) that override the validator’s instance configuration for this call only.

Currently supported overrides:

=over 4

=item * C<max_errors>

Maximum number of errors to collect before stopping validation.

=item * C<trace_on>, C<trace_limit>

Enable tracing and limit the number of trace entries.

=item * C<compile_on>

Enable on-the-fly compilation during validation.

=item * C<content_assert>

Enable media-type / content assertions.

=back

All options are optional and backward compatible. If omitted, the instance configuration is used.

=head3 Relationship to C<is_valid>

L</is_valid> is a convenience wrapper around C<validate> that defaults C<< max_errors => 1 >> and is intended for fast boolean checks:

    $js->is_valid( $data ) or die( $js->error );

=head1 BEHAVIOUR NOTES

=over 4

=item * Recursion & Cycles

The validator guards on the pair C<(schema_pointer, instance_address)>, so self-referential schemas and cyclic instance graphs will not infinite-loop.

=item * Union Types with Inline Schemas

C<type> may be an array mixing string type names and inline schemas. Any inline schema that validates the instance makes the C<type> check succeed.

=item * Booleans

For practicality in Perl, C<< type => 'boolean' >> accepts JSON-like booleans (e.g. true/false, 1/0 as strings) as well as Perl boolean objects (if you use a boolean class). If you need stricter behaviour, you can adapt C<_match_type> or introduce a constructor flag and branch there.

=item * Combinators C<allOf>, C<anyOf>, C<oneOf>, C<not>

C<allOf> validates all subschemas and merges their annotations (e.g. evaluated properties/items) into the parent schema’s annotation. If any subschema fails, C<allOf> fails.

C<anyOf> and C<oneOf> always validate their branches in a “shadow” context.
Errors produced by non-selected branches do not leak into the main context when the combinator as a whole succeeds. When C<anyOf> fails (no branch matched) or C<oneOf> fails (zero or more than one branch matched), the validator merges the collected branch errors into the main context to make debugging easier.

C<not> is also evaluated in a shadow context. If the inner subschema validates, C<not> fails with a single “forbidden not-schema” error; otherwise C<not> succeeds and any inner errors are discarded.

=item * Conditionals C<if> / C<then> / C<else>

The subschema under C<if> is treated purely as a condition:

=over 4

=item *

C<if> is always evaluated in an isolated “shadow” context. Any errors it produces (for example from C<required>) are never reported directly.

=item *

If C<if> succeeds and C<then> is present, C<then> is evaluated against the real context and may produce errors.

=item *

If C<if> fails and C<else> is present, C<else> is evaluated against the real context and may produce errors.

=back

This matches the JSON Schema 2020-12 intent: only C<then>/C<else> affect validity, C<if> itself never does.

=item * C<unevaluatedItems> / C<unevaluatedProperties>

Both C<unevaluatedItems> and C<unevaluatedProperties> are enforced using annotation produced by earlier keyword evaluations within the same schema object, matching draft 2020-12 semantics.

=item * Error reporting and pointers

Each error object contains both:

=over 4

=item *

C<path> – a JSON Pointer-like path to the failing location in the instance (e.g. C<#/properties~1s/oneOf~11/properties~1classes/0>).

=item *

C<schema_pointer> – a JSON Pointer into the root schema that identifies the keyword which emitted the error (e.g.
C<#/properties~1s/oneOf~11/properties~1classes/items/allOf~10/then/voting_right>).

=back

Messages for C<required> errors also list the full required set and the keys actually present at that location to help debug combinators such as C<anyOf>/C<oneOf>/C<if>/C<then>/C<else>.

=item * RFC rigor and media types

L<URI>/C<IRI> and media‐type parsing is intentionally pragmatic rather than fully RFC-complete. For example, C<uri>, C<iri>, and C<uri-reference> use strict but heuristic regexes; C<contentMediaType> validates UTF-8 for C<text/*; charset=utf-8> and supports pluggable validators/decoders, but is not a general MIME toolkit.

=item * Compilation vs. Interpretation

Both code paths are correct by design. The interpreter is simpler and great while developing a schema; toggle C<< ->compile >> when moving to production or after the schema stabilises. You may enable compilation lazily (call C<compile> any time) or eagerly via the constructor (C<< compile => 1 >>).

=back

=head1 WHY ENABLE C<COMPILE>?

When C<compile> is ON, the validator precompiles a tiny Perl closure for each schema node. At runtime, those closures:

=over 4

=item * avoid repeated hash lookups for keyword presence/values;

=item * skip dispatch on absent keywords (branchless fast paths);

=item * reuse precompiled child validators (arrays/objects/combinators);

=item * reduce allocator churn by returning small, fixed-shape result hashes.

=back

In practice this improves steady-state throughput (especially for large/branchy schemas, or hot validation loops) and lowers tail latency by minimising per-instance work. The trade-offs are:

=over 4

=item * a one-time compile cost per node (usually amortised quickly);

=item * a small memory footprint for closures (one per visited node).

=back

If you only validate once or twice against a tiny schema, compilation will not matter; for services, batch jobs, or streaming pipelines it typically yields a noticeable speedup. Always benchmark with your own schema+data.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>, L<DateTime>, L<DateTime::Format::ISO8601>, L<DateTime::Duration>, L<Regexp::Common>, L<Net::IDN::Encode>, L<JSON::PP>

L<JSON::Schema>, L<JSON::Validator>

L<python-jsonschema|https://github.com/python-jsonschema/jsonschema>,
L<fastjsonschema|https://github.com/horejsek/python-fastjsonschema>,
L<Pydantic|https://docs.pydantic.dev>,
L<RapidJSON Schema|https://rapidjson.org/md_doc_schema.html>

L<https://json-schema.org/specification>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2025 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
