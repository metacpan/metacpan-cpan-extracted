##----------------------------------------------------------------------------
## JSON Schema Validator - ~/lib/JSON/Schema/Validate.pm
## Version v0.9.2
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2025/11/07
## Modified 2026/11/28
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.##
##----------------------------------------------------------------------------##
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
    our $VERSION = 'v0.9.2';
};

use v5.16.0;
use strict;
use warnings;

sub new
{
    my $class  = shift( @_ );
    my $schema = shift( @_ );
    if( defined( $schema ) && ref( $schema ) ne 'HASH' && !JSON::is_bool( $schema ) )
    {
        die( "You provided a value (", overload::StrVal( $schema ), "), but it is not a hash reference or a JSON boolean. You must create a new $class object like this: $class->new( \$schema, \%opts );" );
    }

    my $self =
    {
        comment_handler     => undef,
        # boolean
        compile_on          => 0,
        # { schema, resource_index, base, fn_index }
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
    $opts    = {%$opts};

    my $schema = $self->{schema};
    die( "No schema loaded; cannot compile to JavaScript" ) unless( defined( $schema ) );

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
    my $index = { resources => {}, nodes => {} };
    $opts->{_resource_base} = _index_schema_202012( $schema, '', '#', $index, 1 );
    $opts->{_resource_index} = $index;

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

    function _jsv_equal(a, b)
    {
        if(a === b) return true;
        if(a === null || b === null || typeof a !== 'object' || typeof b !== 'object') return false;
        if(Array.isArray(a) !== Array.isArray(b)) return false;
        var keys = Object.keys(a);
        if(keys.length !== Object.keys(b).length) return false;
        for(var i = 0; i < keys.length; i++)
        {
            var key = keys[i];
            if(!_jsv_hasOwn(b, key) || !_jsv_equal(a[key], b[key])) return false;
        }
        return true;
    }

    function _jsv_strlen(s)
    {
        return s.replace(/[\uD800-\uDBFF][\uDC00-\uDFFF]/g, 'x').length;
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
        $data = _clone( $data );
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

    local $@;
    my $has_iso  = eval{ require DateTime::Format::ISO8601; 1 } ? 1 : 0;
    my $has_tp   = eval{ require Time::Piece; 1 } ? 1 : 0;
    my $has_dt   = eval{ require DateTime; 1 } ? 1 : 0;
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

        # YYYY-MM-DDThh:mm:ss[.fraction](Z|±hh:mm)
        return(0) unless( $s =~ /\A
            (\d{4})-(\d{2})-(\d{2})      # date
            T
            (\d{2}):(\d{2}):(\d{2})      # time
            (?:\.\d+)?                   # optional fraction
            (?:Z|[+\-]\d{2}:\d{2})       # offset
        \z/x );

        my( $y, $m, $d, $H, $M, $S ) = ( $1, $2, $3, $4, $5, $6 );

        # Time::Piece is a core module (available since perl 5.10): use it first
        if( $has_tp )
        {
            # strptime validates calendar correctness (e.g. rejects Feb 30)
            # We feed it the bare datetime without offset/fraction (already captured above)
            my $bare = sprintf( '%04d-%02d-%02dT%02d:%02d:%02d', $y, $m, $d, $H, $M, $S );
            return( eval{ Time::Piece->strptime( $bare, '%Y-%m-%dT%H:%M:%S' ); 1 } ? 1 : 0 );
        }

        # Fall back to DateTime if available
        if( $has_dt )
        {
            return( eval
            {
                DateTime->new(
                    year   => $y,
                    month  => $m,
                    day    => $d,
                    hour   => $H,
                    minute => $M,
                    second => $S
                );
                1
            } ? 1 : 0 );
        }

        # Last resort: the regex above was already sufficient for structural checks
        return(1);
    };

    $F{'date'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return(0) unless( $s =~ /\A(\d{4})-(\d{2})-(\d{2})\z/ );
        my( $y, $m, $d ) = ( $1, $2, $3 );

        # Time::Piece is core - prefer it
        if( $has_tp )
        {
            return( eval{ Time::Piece->strptime( $s, '%Y-%m-%d' ); 1 } ? 1 : 0 );
        }

        # Fall back to DateTime if available
        if( $has_dt )
        {
            return( eval{ DateTime->new( year => $y, month => $m, day => $d ); 1 } ? 1 : 0 );
        }

        # Last resort: structural regex already passed above
        return(1);
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

    # Duration (RFC 3339 §5.6 / ISO 8601)
    # Valid:   P1Y, P3M, P1Y2M3DT4H5M6S, PT10S, P1W
    # Invalid: P, PT, P1Y2M3DT  (T with nothing after it, or no designator at all)
    $F{'duration'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );

        # Week form: PnW (stands alone; no mixing with other designators per ISO 8601)
        return(1) if( $s =~ /\AP\d+W\z/ );

        # Full form: at least one date *or* time component must be present
        # The T separator must be followed by at least one time designator
        return( $s =~ /\A
            P
            (?:(\d+)Y)?
            (?:(\d+)M)?
            (?:(\d+)D)?
            (?:T
                (?=\d)          # T must be followed by at least one digit
                (?:(\d+)H)?
                (?:(\d+)M)?
                (?:(\d+(?:\.\d+)?)S)?
            )?
        \z/x && ( defined($1) || defined($2) || defined($3) || defined($4) || defined($5) || defined($6) )
            ? 1 : 0 );
    };

    # Email / IDN email
    # Plain email (ASCII) - unchanged
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
        # Must have a scheme (letters followed by colon) per RFC 3987 §2.2
        # Scheme: ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
        # After scheme: at least one non-whitespace character
        return( $s =~ /\A[A-Za-z][A-Za-z0-9+\-.]*:[^\s]+\z/u ? 1 : 0 );
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
        $data = _clone( $data );
    }

    # Optional pre-validation pruning of unknown properties / nested objects.
    # This only happens if explicitly enabled via prune_unknown => 1.
    if( $self->{prune_unknown} )
    {
        $data = $self->_prune_with_schema( $self->{schema}, $data );
    }

    my $ctx =
    {
        root                => $self->{compiled},
        resource_index      => _copy_resource_index( $self->{compiled}->{resource_index} ),
        external_fn_index   => {},
        instance_root       => $data,
        resolver            => $self->{resolver},
        formats             => $self->{formats},
        errors              => $self->{errors},
        max_errors          => ( ( defined( $opts->{max_errors} ) && $opts->{max_errors} =~ /^\d+$/ ) ? $opts->{max_errors} : $self->{max_errors} ),
        error_count         => 0,

        # paths / recursion
        ptr_stack           => ['#'],
        id_stack            => [ $self->{compiled}->{base} ],
        dyn_stack           => [ {} ],  # dynamicAnchor scope frames
        visited             => {},      # "resource|schema_ptr|inst_addr" => 1

        # annotation (for unevaluated*)
        ann_mode            => 1,
        compile_on          => ( defined( $opts->{compile_on} ) ? ( $opts->{compile_on} ? 1 : 0 ) : ( $self->{compile_on} ? 1 : 0 ) ),

        # trace
        trace_on            => ( defined( $opts->{trace_on} ) ? ( $opts->{trace_on} ? 1 : 0 ) : ( $self->{trace_on} ? 1 : 0 ) ),
        trace_sample        => $self->{trace_sample} || 0,
        trace_limit         => ( defined( $opts->{trace_limit} ) && $opts->{trace_limit} =~ /^\d+$/ ) ? $opts->{trace_limit} : ( $self->{trace_limit} || 0 ),
        trace               => [],

        # content assertion & helpers
        content_assert      => ( defined( $opts->{content_assert} ) ? ( $opts->{content_assert} ? 1 : 0 ) : ( $self->{content_assert} ? 1 : 0 ) ),
        media_validators    => $self->{media_validators},
        content_decoders    => $self->{content_decoders},

        comment_handler     => $self->{comment_handler},

        # extensions
        unique_keys         => $self->{unique_keys},
        extensions          => $self->{extensions},
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
    return( _apply_ref( $ctx, $schema_ptr, $ref, $inst, '$dynamicRef' ) );
}

# $ref and $dynamicRef
sub _apply_ref
{
    my( $ctx, $schema_ptr, $ref, $inst, $keyword ) = @_;
    $keyword ||= '$ref';
    my $abs = _resolve_uri( $ctx->{id_stack}->[-1], $ref );
    my( $uri, $fragment ) = split( /#/, $abs, 2 );
    $uri = '' unless( defined( $uri ) );
    my $index = $ctx->{resource_index};

    # Resolve external resources once per validation, without retaining resolver answers across calls.
    if( !exists( $index->{resources}->{ $uri } ) && $ctx->{resolver} )
    {
        local $@;
        my $ext = eval{ $ctx->{resolver}->( $abs ) };
        return( _err_res( $ctx, $schema_ptr, "resolver failed for $keyword: $abs", $keyword ) )
            unless( ref( $ext ) eq 'HASH' || JSON::is_bool( $ext ) );
        $ext = eval{ _clone( $ext ) };
        return( _err_res( $ctx, $schema_ptr, "invalid schema resource for $keyword: $abs", $keyword ) ) if( $@ );
        # A retrieval URI may identify an already indexed canonical resource. Reuse it only if the schema is identical.
        my $canonical = $uri;
        if( ref( $ext ) eq 'HASH' && defined( $ext->{'$id'} ) && !ref( $ext->{'$id'} ) && length( $ext->{'$id'} ) )
        {
            $canonical = _resolve_uri( $uri, $ext->{'$id'} );
            $canonical =~ s/#$//;
        }
        if( my $existing = $index->{resources}->{ $canonical } )
        {
            return( _err_res( $ctx, $schema_ptr, "conflicting schema resource for $keyword: $abs", $keyword ) )
                unless( _canon( $existing->{schema} ) eq _canon( $ext ) );
            $index->{resources}->{ $uri } = $existing;
        }
        else
        {
            my $staged = _copy_resource_index( $index );
            my $base = eval{ _index_schema_202012( $ext, $uri, '#', $staged, 1 ) };
            return( _err_res( $ctx, $schema_ptr, "invalid schema resource for $keyword: $abs", $keyword ) ) if( $@ );
            # The retrieval URI cannot also identify a different embedded resource in the returned document.
            return( _err_res( $ctx, $schema_ptr, "conflicting schema resource for $keyword: $abs", $keyword ) )
                if( $uri ne $base && exists( $staged->{resources}->{ $uri } ) );
            $staged->{resources}->{ $uri } = $staged->{resources}->{ $base };
            %$index = %$staged;
        }
    }
    my $resource = $index->{resources}->{ $uri };
    return( _err_res( $ctx, $schema_ptr, "unresolved $keyword: $ref (abs: $abs)", $keyword ) ) unless( $resource );
    my( $node, $ptr );
    $fragment = '' unless( defined( $fragment ) );
    # URI fragments are UTF-8 percent-encoded JSON Pointers or plain-name anchors.
    my $decoded = eval{ _decode_fragment( $fragment ) };
    return( _err_res( $ctx, $schema_ptr, "invalid fragment in $keyword: $abs", $keyword ) ) unless( defined( $decoded ) );
    $fragment = $decoded;
    if( $fragment eq '' )
    {
        ( $node, $ptr ) = @$resource{qw( schema pointer )};
    }
    elsif( $fragment =~ m{^/} )
    {
        $node = _jsv_resolve_internal_ref( $resource->{schema}, '#' . $fragment );
        $ptr = $resource->{pointer} . $fragment;
    }
    else
    {
        my $entry = $resource->{anchors}->{ $fragment };
        if( $entry )
        {
            # Only a dynamic anchor at the statically resolved target enables dynamic scope lookup.
            if( $keyword eq '$dynamicRef' && $entry->{dynamic} )
            {
                for my $scope ( @{$ctx->{id_stack}} )
                {
                    my $candidate = $index->{resources}->{ $scope }->{anchors}->{ $fragment };
                    next unless( $candidate && $candidate->{dynamic} );
                    $entry = $candidate;
                    last;
                }
            }
            ( $node, $ptr ) = @$entry{qw( schema pointer )};
        }
    }
    unless( ref( $node ) eq 'HASH' || JSON::is_bool( $node ) )
    {
        my $msg = $fragment =~ m{^/} ? "unresolved JSON Pointer fragment in $keyword: $abs" : "unresolved $keyword: $ref (abs: $abs)";
        return( _err_res( $ctx, $schema_ptr, $msg, $keyword ) );
    }
    # Explicit pointers may address legacy schema containers outside standard vocabulary locations.
    my $base = $resource->{base};
    if( ref( $node ) eq 'HASH' && !exists( $index->{nodes}->{ refaddr( $node ) } ) )
    {
        my $staged = _copy_resource_index( $index );
        eval{ _index_schema_202012( $node, $base, $ptr, $staged, 0 ) };
        return( _err_res( $ctx, $schema_ptr, "invalid schema resource for $keyword: $abs", $keyword ) ) if( $@ );
        %$index = %$staged;
    }
    # Hash schemas carry their own indexed scope; boolean schemas cannot contain references.
    return( _v( $ctx, $ptr, $node, $inst ) );
}

sub _builtin_json_media
{
    my( $text, $params ) = @_;
    local $@;
    eval{ _decode_json_content( $text ) };
    return( 0, 'invalid JSON', undef ) if( $@ );
    # Leave the original payload available for contentSchema, including JSON scalars and null.
    return( 1, undef );
}

sub _canon
{
    my( $v ) = @_;
    state $json = JSON->new->allow_nonref(1)->canonical(1)->convert_blessed(1);
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
    state $json = JSON->new->allow_nonref(1)->canonical(1);
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
                if( $followed{ $target_schema }++ )
                {
                    $target_schema = undef;
                    last;
                }
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
// Schema node (unresolved pointer alias)
function $fn(inst, path, ctx)
{
}
JS_RUNTIME
            return( $fn );
        }

        unless( ref( $target_schema ) eq 'HASH' || JSON::is_bool( $target_schema ) )
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

    my $id = $$counter_ref++;
    my $fn = "jsv_node_$id";
    $seen->{ $sp } = $fn;

    my @body;
    my $qsp = _js_quote( $sp );
    my $comment = _js_comment( $sp );
    push( @body, <<JS_RUNTIME );
// $comment
function $fn(inst, path, ctx)
{
JS_RUNTIME
    if( JSON::is_bool( $S ) )
    {
        push( @body, "    _jsv_err(ctx, path, 'false', 'instance does not satisfy false schema', $qsp);\n" ) unless( $S );
        push( @$funcs, join( '', @body ) . "}\n" );
        return( $fn );
    }
    unless( ref( $S ) eq 'HASH' )
    {
        push( @$funcs, join( '', @body ) . "}\n" );
        return( $fn );
    }

    # Guard reference recursion at the same instance path. Register the function before compiling its targets.
    my $has_ref = exists( $S->{'$ref'} );
    if( $has_ref )
    {
        my $guard = _js_quote( $fn );
        push( @body, <<JS_RUNTIME );
    var active = ctx.active || (ctx.active = Object.create(null));
    var guard = $guard + ':' + path;
    if(active[guard]) return;
    active[guard] = true;
    try
    {
JS_RUNTIME
        my( $target_schema, $target_ptr ) = _js_reference_target( $S, $opts );
        if( defined( $target_schema ) )
        {
            my $base_fn = $self->_compile_js_node( $target_schema, $target_ptr, $seen, $funcs, $counter_ref, $root, $opts );
            push( @body, <<JS_RUNTIME );
    $base_fn(inst, path, ctx);
    if(ctx.maxErrors && ctx.errors.length >= ctx.maxErrors) return;
JS_RUNTIME
        }
        # External or unsupported references remain server-side checks, but local keywords still apply.
    }

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
    // Schema node
    $sub_fn(inst, path, ctx);
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
        // Schema node
        $sub_fn(inst, path, ctx);
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
        // Schema node
        $sub_fn(inst, path, ctx);
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
        // Schema node
        $sub_fn(inst, path, ctx);
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
    // NOTE: 'not' is a negative-required pattern; skipped client-side.
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
        // Schema node
        $if_fn(inst, path, ctx);
        var failed = (tmp.length > 0);
        ctx.errors = baseErrors;
JS_RUNTIME

            if( exists( $S->{then} ) )
            {
                my $then_sp = _join_ptr( $sp, 'then' );
                my $then_fn = $self->_compile_js_node( $S->{then}, $then_sp, $seen, $funcs, $counter_ref, $root, $opts );
                push( @body, <<JS_RUNTIME );
        if(!failed)
        {
            $then_fn(inst, path, ctx);
        }
JS_RUNTIME
            }
            if( exists( $S->{else} ) )
            {
                my $else_sp = _join_ptr( $sp, 'else' );
                my $else_fn = $self->_compile_js_node( $S->{else}, $else_sp, $seen, $funcs, $counter_ref, $root, $opts );
                push( @body, <<JS_RUNTIME );
        if(failed)
        {
            $else_fn(inst, path, ctx);
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
        my @vs_js = map{ "JSON.parse(" . _js_quote( _js_literal( $_ ) ) . ")" } @vals;
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
            if(_jsv_equal(v, list[i]))
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
    # 3) const compares JSON values without coercion.
    if( exists( $S->{const} ) )
    {
        my $cv = _js_quote( _js_literal( $S->{const} ) );
        my $qsp = _js_quote( $sp );
        push( @body, <<JS_RUNTIME );
    if(!_jsv_equal(inst, JSON.parse($cv)))
    {
        _jsv_err(ctx, path, 'const', 'value does not match const', $qsp);
    }
JS_RUNTIME
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
        if(_jsv_strlen(inst) < $min)
        {
            _jsv_err(ctx, path, 'minLength', 'string shorter than minLength $min', $qsp);
        }
JS_RUNTIME
        }

        if( exists( $S->{maxLength} ) )
        {
            my $max = int( $S->{maxLength} );
            push( @body, <<JS_RUNTIME );
        if(_jsv_strlen(inst) > $max)
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

    # NOTE: prefixItems / items / minItems / maxItems
    # 7) array items & minItems/maxItems
    my $prefix = ref( $S->{prefixItems} ) eq 'ARRAY' ? $S->{prefixItems} : [];
    my $has_array_len =
        exists( $S->{minItems} ) ||
        exists( $S->{maxItems} );

    if( @$prefix || exists( $S->{items} ) || $has_array_len )
    {
        my $qsp = _js_quote( $sp );

        # Precompile single-schema "items"
        my $items_fn;
        if( exists( $S->{items} ) && ( ref( $S->{items} ) eq 'HASH' || JSON::is_bool( $S->{items} ) ) )
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

        # Validate each existing tuple position before applying items to the remainder.
        for my $i ( 0 .. $#$prefix )
        {
            my $prefix_ptr = _join_ptr( $sp, 'prefixItems', $i );
            my $prefix_fn = $self->_compile_js_node( $prefix->[$i], $prefix_ptr, $seen, $funcs, $counter_ref, $root, $opts );
            push( @body, <<JS_RUNTIME );
        if(inst.length > $i)
        {
            $prefix_fn(inst[$i], path + '/' + $i, ctx);
            if(ctx.maxErrors && ctx.errors.length >= ctx.maxErrors) return;
        }
JS_RUNTIME
        }

        if( $items_fn )
        {
            my $start = scalar( @$prefix );
            push( @body, <<JS_RUNTIME );
        for(var i = $start; i < inst.length; i++)
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
            my $path_suffix   = substr( _join_ptr( '#', $p ), 1 );
            my $path_suffix_q = _js_quote( $path_suffix );

            push( @body, <<JS_RUNTIME );
        if(_jsv_hasOwn(inst, $qp))
        {
            // Schema node
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

            # No runtime call needed here - definitions don't validate by themselves.
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
            // Schema node
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
        if( !$have_min )
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

    if( $has_ref )
    {
        push( @body, <<JS_RUNTIME );
    }
    finally
    {
        delete active[guard];
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

    # Boolean subschemas use the same semantics as the interpreter.
    if( JSON::is_bool( $S ) )
    {
        return sub
        {
            my( $ctx, $inst ) = @_;
            return( _v_node( $ctx, $ptr, $S, $inst ) );
        };
    }

    # Non-hash, non-boolean schemas retain the existing fallback behaviour.
    return sub
    {
        my( $ctx, $inst ) = @_;
        return( { ok => 1, props => {}, items => {} } );
    } unless( ref( $S ) eq 'HASH' );

    # NOTE: $ref / $dynamicRef must not be compiled inline.
    # Delegate reference-bearing nodes to _v_node(), which evaluates the references
    # and their sibling keywords together. It bypasses the compiled closure for
    # these nodes to prevent recursive delegation.
    if( exists( $S->{'$ref'} ) ||
        exists( $S->{'$dynamicRef'} ) )
    {
        return sub
        {
            my( $ctx, $inst ) = @_;
            return( _v_node( $ctx, $ptr, $S, $inst ) );
        };
    }

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
        if( _match_type( $inst, 'string' ) )
        {
            if( $has_strlen ) { _k_string( $ctx, $inst, $S,           $ptr ) or return( _fail() ); }
            if( $has_format ) { _k_format( $ctx, $inst, $format_name, $ptr ) or return( _fail() ); }

            # contentEncoding / contentMediaType / contentSchema (compiled path)
            if( $ctx->{content_assert} && ( exists( $S->{contentEncoding} ) || exists( $S->{contentMediaType} ) || exists( $S->{contentSchema} ) ) )
            {
                my $r = _validate_content( $ctx, $ptr, $S, $inst );
                return( $r ) unless( $r->{ok} );
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

        # Combinators and conditionals share the interpreter's annotation semantics.
        for my $comb ( qw( allOf anyOf oneOf not ) )
        {
            next unless( exists( $S->{ $comb } ) );
            my $r = _k_combinator( $ctx, $ptr, $S, $inst, $comb );
            return( $r ) unless( $r->{ok} );
            %ann_props = ( %ann_props, %{$r->{props}} );
            %ann_items = ( %ann_items, %{$r->{items}} );
        }
        if( exists( $S->{if} ) )
        {
            my $r = _k_if_then_else( $ctx, $ptr, $S, $inst );
            return( $r ) unless( $r->{ok} );
            %ann_props = ( %ann_props, %{$r->{props}} );
            %ann_items = ( %ann_items, %{$r->{items}} );
        }

        my $r = _k_unevaluated( $ctx, $ptr, $S, $inst, \%ann_props, \%ann_items );
        return( $r ) unless( $r->{ok} );

        _t( $ctx, $ptr, 'node', undef, 'pass' ) if( $ctx->{trace_on} );
        return( { ok => 1, props => \%ann_props, items => \%ann_items } );
    };
}

# Compilation / Indexing
sub _compile_root
{
    my( $schema ) = @_;
    # Retain the original schema and index each resource relative to its containing resource.
    my $index = { resources => {}, nodes => {} };
    my $base = _index_schema_202012( $schema, '', '#', $index, 1 );
    return({
        schema => $schema,
        base => $base,
        resource_index => $index,
        fn_index => {},
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
sub _copy_resource_index
{
    my( $index ) = @_;
    my %resources;
    for my $uri ( keys( %{$index->{resources}} ) )
    {
        my $entry = $index->{resources}->{ $uri };
        $resources{ $uri } = { %$entry, anchors => { %{$entry->{anchors}} } };
    }
    return( { resources => \%resources, nodes => { %{$index->{nodes}} } } );
}

sub _decode_fragment
{
    my( $fragment ) = @_;
    my $bytes = Encode::encode( 'UTF-8', $fragment );
    die( 'Invalid URI percent escape' ) if( $bytes =~ /%(?![0-9A-Fa-f]{2})/ );
    $bytes =~ s/%([0-9A-Fa-f]{2})/chr( hex( $1 ) )/eg;
    return( Encode::decode( 'UTF-8', $bytes, Encode::FB_CROAK ) );
}

sub _decimal_multiple
{
    my( $value, $divisor ) = @_;
    my( $vs, $v, $ve ) = _decimal_parts( $value );
    my( $ds, $d, $de ) = _decimal_parts( $divisor );
    return(0) unless( defined( $v ) && defined( $d ) && $ds eq '' && $d ne '0' );
    return(1) if( $v eq '0' );

    # Neither coefficient has trailing zeroes, so a negative exponent difference cannot yield an integer quotient.
    my $shift = $ve - $de;
    return(0) if( $shift < 0 );
    return(1) if( $d eq '1' );
    my $digits = $v . ( '0' x $shift );

    # Keep the intermediate remainder within the signed 32-bit integer range for the common case.
    if( length( $d ) <= 8 )
    {
        my $rem = 0;
        $rem = ( $rem * 10 + $_ ) % $d for( split( //, $digits ) );
        return( $rem == 0 ? 1 : 0 );
    }

    # Decimal long division avoids native integer overflow for larger coefficients.
    my $rem = '0';
    for my $digit ( split( //, $digits ) )
    {
        $rem = $rem eq '0' ? $digit : $rem . $digit;
        while( length( $rem ) > length( $d ) || ( length( $rem ) == length( $d ) && $rem ge $d ) )
        {
            my $borrow = 0;
            my $j = length( $d ) - 1;
            for( my $i = length( $rem ) - 1; $i >= 0; $i-- )
            {
                my $n = substr( $rem, $i, 1 ) - $borrow - ( $j >= 0 ? substr( $d, $j--, 1 ) : 0 );
                $borrow = $n < 0 ? 1 : 0;
                substr( $rem, $i, 1 ) = $n + 10 * $borrow;
            }
            $rem =~ s/\A0+(?=[0-9])//;
        }
    }
    return( $rem eq '0' ? 1 : 0 );
}

sub _decimal_parts
{
    my( $value ) = @_;
    my $json = _canon( $value );
    return unless( $json =~ /\A(-?)(0|[1-9][0-9]*)(?:\.([0-9]+))?(?:[eE]([+-]?[0-9]+))?\z/ );
    my( $sign, $whole, $fraction, $exponent ) = ( $1, $2, $3 // '', $4 // 0 );
    my $digits = $whole . $fraction;
    $digits =~ s/\A0+//;
    return( '', '0', 0 ) unless( length( $digits ) );
    $exponent -= length( $fraction );
    if( $digits =~ s/(0+)\z// )
    {
        $exponent += length( $1 );
    }
    return( $sign, $digits, $exponent );
}

sub _decode_json_content
{
    my( $text ) = @_;
    return( JSON->new->allow_nonref(1)->decode( $text ) );
}

# Errors, utils, pointers, URIs
sub _err
{
    my( $ctx, $schema_ptr, $msg, $keyword ) = @_;
    return(0) if( $ctx->{max_errors} && $ctx->{error_count} >= $ctx->{max_errors} );

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
    my( $node, $base, $ptr, $index, $resource_root ) = @_;
    if( ref( $node ) eq 'HASH' && defined( $node->{'$id'} ) && !ref( $node->{'$id'} ) && length( $node->{'$id'} ) )
    {
        $base = _resolve_uri( $base, $node->{'$id'} );
        $base =~ s/#$//;
        $resource_root = 1;
    }
    if( $resource_root )
    {
        die( "Duplicate schema resource identifier: $base" ) if( exists( $index->{resources}->{ $base } ) );
        $index->{resources}->{ $base } = { schema => $node, pointer => $ptr, base => $base, anchors => {} };
    }
    return( $base ) unless( ref( $node ) eq 'HASH' );
    $index->{nodes}->{ refaddr( $node ) } = { base => $base, pointer => $ptr };
    my $resource = $index->{resources}->{ $base };
    for my $kw ( '$anchor', '$dynamicAnchor' )
    {
        next unless( defined( $node->{ $kw } ) && !ref( $node->{ $kw } ) && length( $node->{ $kw } ) );
        my $name = $node->{ $kw };
        my $existing = $resource->{anchors}->{ $name };
        die( "Duplicate schema anchor: $base#$name" ) if( $existing && refaddr( $existing->{schema} ) != refaddr( $node ) );
        $resource->{anchors}->{ $name } = { schema => $node, pointer => $ptr, dynamic => ( $kw eq '$dynamicAnchor' ? 1 : 0 ) };
    }

    # Only schema-bearing keywords may declare resources or anchors. Literal values and property names cannot do so.
    for my $kw ( qw( properties patternProperties dependentSchemas definitions $defs ) )
    {
        next unless( ref( $node->{ $kw } ) eq 'HASH' );
        for my $key ( sort( keys( %{$node->{ $kw }} ) ) )
        {
            _index_schema_202012( $node->{ $kw }->{ $key }, $base, _join_ptr( $ptr, $kw, $key ), $index, 0 );
        }
    }
    for my $kw ( qw( allOf anyOf oneOf prefixItems type ) )
    {
        next unless( ref( $node->{ $kw } ) eq 'ARRAY' );
        for my $i ( 0 .. $#{$node->{ $kw }} )
        {
            _index_schema_202012( $node->{ $kw }->[$i], $base, _join_ptr( $ptr, $kw, $i ), $index, 0 );
        }
    }
    for my $kw ( qw( not if then else items contains propertyNames additionalProperties unevaluatedProperties unevaluatedItems contentSchema ) )
    {
        next unless( exists( $node->{ $kw } ) );
        _index_schema_202012( $node->{ $kw }, $base, _join_ptr( $ptr, $kw ), $index, 0 );
    }
    return( $base );
}

sub _inst_addr
{
    my( $inst, $ptr ) = @_;
    # Decoded content can contain a different scalar at the same instance path.
    # Preserve both its JSON type and value when identifying an active evaluation.
    return( 'SCALAR:' . _canon( [$ptr, $inst] ) ) unless( ref( $inst ) );
    return( ref( $inst ) . ':' . refaddr( $inst ) );
}

# Keyword groups
# NOTE: instance pointer base
# The pointer stack tracks the location of the failing value inside the *instance*,
# which is what a user interface needs in order to highlight the offending field.
# It must therefore be built from the current instance pointer, never from the
# schema pointer, otherwise the reported path drifts into the schema as soon as
# validation descends through a $ref or a combinator.
sub _inst_ptr
{
    my( $ctx, $token ) = @_;
    my $base = ( $ctx->{ptr_stack} && @{$ctx->{ptr_stack}} )
             ? ( $ctx->{ptr_stack}->[-1] // '#' )
             : '#';
    return( _join_ptr( $base, $token ) );
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
    # we do not hardcode constants-B::SV’s FLAGS is stable to test with these bitmasks.
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

sub _js_comment
{
    my( $value ) = @_;
    $value =~ s/([\r\n\x{2028}\x{2029}])/sprintf( '\\u%04X', ord( $1 ) )/eg;
    return( $value );
}

sub _js_literal
{
    my( $value ) = @_;
    return( JSON->new->allow_nonref(1)->ascii(1)->canonical(1)->encode( $value ) );
}

sub _js_quote
{
    my( $value ) = @_;
    $value = '' unless( defined( $value ) );
    return( JSON->new->allow_nonref(1)->ascii(1)->encode( "$value" ) );
}

sub _js_reference_target
{
    my( $schema, $opts ) = @_;
    my $index = $opts->{_resource_index};
    my $meta = $index->{nodes}->{ refaddr( $schema ) };
    my $base = $meta ? $meta->{base} : $opts->{_resource_base};
    my( $uri, $fragment ) = split( /#/, _resolve_uri( $base, $schema->{'$ref'} ), 2 );
    $uri //= '';
    my $resource = $index->{resources}->{ $uri } or return;
    $fragment = eval{ _decode_fragment( $fragment // '' ) };
    return unless( defined( $fragment ) );
    my( $target, $ptr );
    if( $fragment eq '' )
    {
        ( $target, $ptr ) = @$resource{qw( schema pointer )};
    }
    elsif( $fragment =~ m{^/} )
    {
        $target = _jsv_resolve_internal_ref( $resource->{schema}, '#' . $fragment );
        $ptr = $resource->{pointer} . $fragment;
    }
    else
    {
        my $entry = $resource->{anchors}->{ $fragment } or return;
        ( $target, $ptr ) = @$entry{qw( schema pointer )};
    }
    # Use the indexed canonical pointer for schemas reached through an alias.
    if( ref( $target ) eq 'HASH' && ( my $entry = $index->{nodes}->{ refaddr( $target ) } ) )
    {
        $ptr = $entry->{pointer};
    }
    return( $target, $ptr );
}

sub _json_equal
{
    my( $a, $b ) = @_;
    if( _is_number( $a ) && _is_number( $b ) )
    {
        my( $as, $ad, $ae ) = _decimal_parts( $a );
        my( $bs, $bd, $be ) = _decimal_parts( $b );
        return( $as eq $bs && $ad eq $bd && $ae == $be ? 1 : 0 ) if( defined( $ad ) && defined( $bd ) );
    }
    return( _canon( $a ) eq _canon( $b ) );
}

# Very small JSON Pointer resolver for internal refs ("#/...") for JS compile
sub _jsv_resolve_internal_ref
{
    my( $root, $ptr ) = @_;

    return( $root ) if( !defined( $ptr ) || $ptr eq '' || $ptr eq '#' );

    # Expect something like "#/definitions/address"
    $ptr =~ s/^#//;
    return unless( $ptr =~ m{^/} );

    my @tokens = split( /\//, $ptr, -1 );
    shift( @tokens ) if( @tokens && $tokens[0] eq '' );

    my $node = $root;

    TOKEN:
    for my $tok ( @tokens )
    {
        # rfc6901 JSON Pointer unescaping
        return if( $tok =~ /~(?![01])/ );
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
            unless( $tok =~ /\A(?:0|[1-9][0-9]*)\z/ && $tok < @$node )
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
            push( @{$ctx->{ptr_stack}}, _inst_ptr( $ctx, $i ) );

            if( $i <= $#$tuple )
            {
                my $r = _v( $ctx, _join_ptr( $sp, "prefixItems/$i" ), $tuple->[$i], $A->[$i] );
                unless( $r->{ok} )
                {
                    pop( @{$ctx->{ptr_stack}} );
                    return( $r );
                }
                $items_ann{ $i } = 1;
            }
            elsif( exists( $S->{items} ) && ( ref( $S->{items} ) eq 'HASH' || JSON::is_bool( $S->{items} ) ) )
            {
                my $r = _v( $ctx, _join_ptr( $sp, "items" ), $S->{items}, $A->[$i] );
                unless( $r->{ok} )
                {
                    pop( @{$ctx->{ptr_stack}} );
                    return( $r );
                }
                $items_ann{ $i } = 1;
            }

            pop( @{$ctx->{ptr_stack}} );
        }
    }
    elsif( ref( $S->{items} ) eq 'HASH' || JSON::is_bool( $S->{items} ) )
    {
        for my $i ( 0 .. $#$A )
        {
            push( @{$ctx->{ptr_stack}}, _inst_ptr( $ctx, $i ) );
            my $r = _v( $ctx, _join_ptr( $sp, "items" ), $S->{items}, $A->[$i] );
            # NOTE: the instance pointer must be popped on every exit path
            # Returning early without popping leaves the failing item's pointer on the
            # stack, and every later error in the same document inherits it as a prefix.
            unless( $r->{ok} )
            {
                pop( @{$ctx->{ptr_stack}} );
                return( $r );
            }
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

            push( @{$ctx->{ptr_stack}}, _inst_ptr( $ctx, $i ) );
            my $tmp = _v( \%shadow, _join_ptr( $sp, "contains" ), $S->{contains}, $A->[$i] );
            pop( @{$ctx->{ptr_stack}} );
            if( $tmp->{ok} )
            {
                $matches++;
                $items_ann{ $i } = 1;
            }
        }

        my $minc = defined( $S->{minContains} ) ? $S->{minContains} : 1;
        my $maxc = defined( $S->{maxContains} ) ? $S->{maxContains} : ( 2**31 - 1 );

        return( _err_res( $ctx, $sp, "contains matched $matches < minContains $minc", 'minContains' ) ) if( $matches < $minc );
        return( _err_res( $ctx, $sp, "contains matched $matches > maxContains $maxc", 'maxContains' ) ) if( $matches > $maxc );
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
        my( %props, %items );
        my $matched = 0;

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
                # All successful branches contribute annotations.
                # Ignore errors from unsuccessful branches if any branch matches.
                $matched = 1;
                %props = ( %props, %{$r->{props}} );
                %items = ( %items, %{$r->{items}} );
                next;
            }

            push( @branch_errs, \@errs );
        }

        return( { ok => 1, props => \%props, items => \%items } ) if( $matched );

        # No branch matched: merge collected branch errors into main context
        for my $aref ( @branch_errs )
        {
            next unless( @$aref );
            for my $error ( @$aref )
            {
                last if( $ctx->{max_errors} && $ctx->{error_count} >= $ctx->{max_errors} );
                push( @{$ctx->{errors}}, $error );
                $ctx->{error_count}++;
            }
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
            # Exactly one branch matched: its annotations contribute to the parent.
            return( $ok_results[0] );
        }

        # Zero or >1 matched -> failure; merge branch errors
        for my $aref ( @branch_errs )
        {
            next unless( @$aref );
            for my $error ( @$aref )
            {
                last if( $ctx->{max_errors} && $ctx->{error_count} >= $ctx->{max_errors} );
                push( @{$ctx->{errors}}, $error );
                $ctx->{error_count}++;
            }
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
        return( $cond ) unless( exists( $S->{then} ) );

        # Apply "then" against the real context and retain annotations from the successful condition.
        my $r = _v( $ctx, _join_ptr( $sp, 'then' ), $S->{then}, $inst );
        return( $r ) unless( $r->{ok} );
        return( { ok => 1, props => { %{$cond->{props}}, %{$r->{props}} }, items => { %{$cond->{items}}, %{$r->{items}} } } );
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
        # Test divisibility of the decimal JSON representations without rounding the quotient.
        my $ok = _decimal_multiple( $v, $arg );
        _t( $ctx, $ptr, 'multipleOf', undef, $ok ? 'pass' : 'fail', "$v mod $arg" ) if( $ctx->{trace_on} );
        return( $ok ? 1 : _err( $ctx, $ptr, "number not multipleOf $arg", 'multipleOf' ) );
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
        for my $k ( sort( keys( %$P ) ) )
        {
            my $pd = $P->{ $k };
            next unless( ref( $pd ) eq 'HASH' );

            if( exists( $pd->{required} ) && ( !ref( $pd->{required} ) || JSON::is_bool( $pd->{required} ) ) )
            {
                $required{ $k } = $pd->{required} ? 1 : 0;
            }
            if( exists( $pd->{optional} ) )
            {
                $required{ $k } = $pd->{optional} ? 0 : 1; # optional => 0 means required
            }
        }
    }

    for my $rq ( grep{ $required{ $_ } } sort( keys( %required ) ) )
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

    if( exists( $S->{propertyNames} ) && ( ref( $S->{propertyNames} ) eq 'HASH' || JSON::is_bool( $S->{propertyNames} ) ) )
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

        my $child_path = _inst_ptr( $ctx, $k );
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

        # Every matching pattern applies, even when the property has an explicit schema.
        # Keep the instance path on the stack until all matching patterns have been checked.
        {
            local $@;
            for my $re ( sort( keys( %$patprops ) ) )
            {
                my $re_ok = eval{ $k =~ /$re/ };
                next unless( $re_ok );
                $matched = 1;

                my $r = _v( $ctx, _join_ptr( $sp, "patternProperties/$re" ), $patprops->{ $re }, $v );
                if( !$r->{ok} )
                {
                    $ok = 0;
                    if( $bail_if_max->() )
                    {
                        pop( @{$ctx->{ptr_stack}} );
                        return( { ok => 0, props => \%ann, items => {} } );
                    }
                    next;
                }
                $ann{ $k } = 1;
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
            elsif( $addl_set )
            {
                $ann{ $k } = 1;
            }
        }

        pop( @{$ctx->{ptr_stack}} );
    }

    if( my $depR = $S->{dependentRequired} )
    {
        for my $k ( sort( keys( %$depR ) ) )
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
        for my $k ( sort( keys( %$depS ) ) )
        {
            next unless( exists( $H->{ $k } ) );
            my $r = _v( $ctx, _join_ptr( $sp, "dependentSchemas/$k" ), $depS->{ $k }, $H );
            if( !$r->{ok} )
            {
                $ok = 0;
                return( { ok => 0, props => \%ann, items => {} } ) if( $bail_if_max->() );
            }
            else
            {
                %ann = ( %ann, %{$r->{props}} );
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
            my %shadow = %$ctx;
            $shadow{errors} = [];
            $shadow{error_count} = 0;
            my $r = _v( \%shadow, _join_ptr( $ptr, "type/$i" ), $alt, $v );
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

# Evaluate remaining properties or items only after all adjacent applicators have contributed annotations.
sub _k_unevaluated
{
    my( $ctx, $sp, $S, $inst, $props, $items ) = @_;

    my( $kw, $ann, @unknown );
    if( ref( $inst ) eq 'HASH' && exists( $S->{unevaluatedProperties} ) )
    {
        $kw = 'unevaluatedProperties';
        $ann = $props;
        @unknown = grep { !$ann->{ $_ } } sort( keys( %$inst ) );
    }
    elsif( ref( $inst ) eq 'ARRAY' && exists( $S->{unevaluatedItems} ) )
    {
        $kw = 'unevaluatedItems';
        $ann = $items;
        @unknown = grep { !$ann->{ $_ } } ( 0 .. $#$inst );
    }
    else
    {
        return( { ok => 1, props => $props, items => $items } );
    }

    my $UE = $S->{ $kw };
    if( @unknown && !_is_true( $UE ) && !_is_hash( $UE ) )
    {
        my $msg = $kw eq 'unevaluatedItems' ? 'unevaluatedItems not allowed at indices: ' : 'unevaluatedProperties not allowed: ';
        return( _err_res( $ctx, $sp, $msg . join( ',', @unknown ), $kw ) );
    }
    my $ok = 1;
    for my $k ( @unknown )
    {
        if( ref( $UE ) eq 'HASH' )
        {
            my $value = ref( $inst ) eq 'HASH' ? $inst->{ $k } : $inst->[$k];
            push( @{$ctx->{ptr_stack}}, _inst_ptr( $ctx, $k ) );
            my $r = _v( $ctx, _join_ptr( $sp, $kw ), $UE, $value );
            pop( @{$ctx->{ptr_stack}} );
            if( !$r->{ok} )
            {
                $ok = 0;
                last if( $ctx->{max_errors} && $ctx->{error_count} >= $ctx->{max_errors} );
                next;
            }
        }
        $ann->{ $k } = 1;
    }
    return( { ok => $ok, props => $props, items => $items } );
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
                push( @{$ctx->{ptr_stack}}, _inst_ptr( $ctx, $i ) );
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
        return( $v == int( $v ) ? 1 : 0 );
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
        $re =~ s{\x{2028}}{\\u2028}g;
        $re =~ s{\x{2029}}{\\u2029}g;
        $re =~ s{/}{\/}g;
    }

    # For 'literal', we leave backslashes as-is, for use in /.../u

    return( $re );
}

sub _register_builtin_media_validators
{
    my( $self ) = @_;
    $self->register_media_validator( 'application/json' => \&_builtin_json_media ) unless( exists( $self->{media_validators}->{'application/json'} ) );
    return( $self );
}

sub _resolve_uri
{
    my( $base, $ref ) = @_;
    $base //= '';
    my( $bs, $ba, $bp, $bq ) = $base =~ m{\A(?:([A-Za-z][A-Za-z0-9+.-]*):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?};
    my( $rs, $ra, $rp, $rq, $rf ) = $ref =~ m{\A(?:([A-Za-z][A-Za-z0-9+.-]*):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?\z}s;
    return( $ref ) unless( defined( $rp ) );
    my( $scheme, $authority, $path, $query ) = ( $rs, $ra, $rp, $rq );
    if( !defined( $rs ) )
    {
        $scheme = $bs;
        if( !defined( $ra ) )
        {
            $authority = $ba;
            if( $rp eq '' )
            {
                $path = $bp // '';
                $query = $bq unless( defined( $rq ) );
            }
            elsif( $rp !~ m{^/} )
            {
                my $dir = $bp // '';
                $dir =~ s{[^/]*$}{};
                $dir = '/' if( $dir eq '' && defined( $ba ) );
                $path = $dir . $rp;
            }
        }
    }
    # Remove dot segments while retaining leading relative parent segments when there is no absolute base.
    if( $path =~ m{(?:^|/)\.\.?(?:/|$)} )
    {
        my @parts;
        my $absolute = $path =~ m{^/};
        for my $part ( split( m{/}, $path, -1 ) )
        {
            next if( $part eq '.' );
            if( $part eq '..' )
            {
                if( @parts && $parts[-1] ne '..' && !( $absolute && @parts == 1 ) ) { pop( @parts ); }
                elsif( !$absolute ) { push( @parts, $part ); }
            }
            else { push( @parts, $part ); }
        }
        push( @parts, '' ) if( $path =~ m{/(?:\.|\.\.)$} );
        $path = join( '/', @parts );
        $path = '/' if( $absolute && $path eq '' );
    }
    return( ( defined( $scheme ) ? "$scheme:" : '' ) . ( defined( $authority ) ? "//$authority" : '' ) . $path . ( defined( $query ) ? "?$query" : '' ) . ( defined( $rf ) ? "#$rf" : '' ) );
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

sub _strlen
{
    my( $s ) = @_;
    # The input is a decoded Perl string, not an encoded UTF-8 byte sequence.
    return( length( $s ) );
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

    # The indexed resource, rather than the calling reference, determines the base URI.
    my $meta = ref( $schema ) eq 'HASH' ? $ctx->{resource_index}->{nodes}->{ refaddr( $schema ) } : undef;
    my $resource = $meta ? $meta->{base} : $ctx->{id_stack}->[-1];
    local $ctx->{id_stack} = [ @{$ctx->{id_stack}}, $resource ] if( $resource ne $ctx->{id_stack}->[-1] );

    # Guard active recursion by schema identity and instance identity, including scalar values.
    my $inst_addr = _inst_addr( $inst, $ctx->{ptr_stack}->[-1] );
    my $identity = ref( $schema ) eq 'HASH' ? refaddr( $schema ) : $schema_ptr;
    my $vkey = _canon( [$resource, $identity, $inst_addr] );
    return( { ok => 1, props => {}, items => {} } ) if( $ctx->{visited}->{ $vkey } );
    local $ctx->{visited}->{ $vkey } = 1;
    return( _v_node( $ctx, $schema_ptr, $schema, $inst ) );
}

sub _v_node
{
    my( $ctx, $schema_ptr, $schema, $inst ) = @_;

    # Boolean subschemas must be resolved before the compiled or interpreted path.
    if( JSON::is_bool( $schema ) )
    {
        return( $schema ? { ok => 1, props => {}, items => {} } :
            _err_res( $ctx, $schema_ptr, "instance does not satisfy false schema", 'false' ) );
    }

    # References are applicators. Evaluate each reference before its sibling keywords.
    my @ref_results;
    if( ref( $schema ) eq 'HASH' && exists( $schema->{'$ref'} ) )
    {
        my $r = _apply_ref( $ctx, $schema_ptr, $schema->{'$ref'}, $inst );
        return( $r ) unless( $r->{ok} );
        push( @ref_results, $r );
    }
    if( ref( $schema ) eq 'HASH' && exists( $schema->{'$dynamicRef'} ) )
    {
        my $r = _apply_dynamic_ref( $ctx, $schema_ptr, $schema->{'$dynamicRef'}, $inst );
        return( $r ) unless( $r->{ok} );
        push( @ref_results, $r );
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

    # Reference-bearing nodes use the interpreter to avoid re-entering the delegate closure.
    if( $ctx->{compile_on} && !@ref_results )
    {
        my $resource = $ctx->{id_stack}->[-1];
        my $identity = ref( $schema ) eq 'HASH' ? refaddr( $schema ) : $schema_ptr;
        my $key = _canon( [$resource, $identity, $schema_ptr] );
        my $cache = ref( $schema ) eq 'HASH' && exists( $ctx->{root}->{resource_index}->{nodes}->{ $identity } ) ? $ctx->{root}->{fn_index} : $ctx->{external_fn_index};
        my $fn = $cache->{ $key };
        unless( $fn )
        {
            $fn = _compile_node( $ctx->{root}, $schema_ptr, $schema );
            $cache->{ $key } = $fn;
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
    if( _match_type( $inst, 'string' ) )
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
        if( $ctx->{content_assert} && ( exists( $schema->{contentEncoding} ) || exists( $schema->{contentMediaType} ) || exists( $schema->{contentSchema} ) ) )
        {
            my $r = _validate_content( $ctx, $ptr, $schema, $inst );
            return( $r ) unless( $r->{ok} );
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

    # Include annotations from every successful reference before evaluating unevaluated keywords.
    for my $r ( @ref_results )
    {
        %ann_props = ( %ann_props, %{$r->{props}} );
        %ann_items = ( %ann_items, %{$r->{items}} );
    }

    my $r = _k_unevaluated( $ctx, $schema_ptr, $schema, $inst, \%ann_props, \%ann_items );
    return( $r ) unless( $r->{ok} );

    _t( $ctx, $schema_ptr, 'node', undef, 'pass' ) if( $ctx->{trace_on} );
    return( { ok => 1, props => \%ann_props, items => \%ann_items } );
}

sub _validate_content
{
    my( $ctx, $ptr, $schema, $inst ) = @_;
    my $text = "$inst";
    my $octets = 0;
    if( exists( $schema->{contentEncoding} ) )
    {
        $text = _content_decode( $ctx, $schema->{contentEncoding}, $text );
        return( _err_res( $ctx, $ptr, "contentEncoding '$schema->{contentEncoding}' decode failed", 'contentEncoding' ) ) unless( defined( $text ) );
        $octets = !utf8::is_utf8( $text );
    }
    my $decoded;
    if( exists( $schema->{contentMediaType} ) )
    {
        my( $mt, $params ) = _parse_media_type( $schema->{contentMediaType} );
        my $cb = $ctx->{media_validators}->{ $mt };
        $cb ||= \&_builtin_json_media if( $mt eq 'application/json' );
        # Only the built-in JSON validator needs character text. Custom callbacks retain their original input contract.
        my $builtin_json = $cb && refaddr( $cb ) == refaddr( \&_builtin_json_media );
        if( $octets && ( $builtin_json || ( !$cb && $mt =~ m{^text/} && ( $params->{charset} // '' ) =~ /\Autf-?8\z/i ) ) )
        {
            local $@;
            my $chars = eval{ Encode::decode( 'UTF-8', $text, Encode::FB_CROAK | Encode::LEAVE_SRC ) };
            return( _err_res( $ctx, $ptr, "contentMediaType '$mt' invalid UTF-8", 'contentMediaType' ) ) if( $@ );
            $text = $chars;
            $octets = 0;
        }
        if( $cb )
        {
            my( $ok, $msg, $out ) = _safe_invoke( $cb, $text, $params );
            return( _err_res( $ctx, $ptr, ( $msg || "contentMediaType '$mt' validation failed" ), 'contentMediaType' ) ) unless( $ok );
            $decoded = $out if( ref( $out ) );
            $text = $out if( defined( $out ) && !ref( $out ) );
            $octets = 0 if( utf8::is_utf8( $text ) );
        }
    }
    if( exists( $schema->{contentSchema} ) )
    {
        my $val = $decoded;
        unless( ref( $decoded ) )
        {
            local $@;
            $val = eval{ $octets ? JSON->new->allow_nonref(1)->utf8(1)->decode( $text ) : _decode_json_content( $text ) };
            return( _err_res( $ctx, $ptr, 'contentSchema present but payload not JSON-decodable', 'contentSchema' ) ) if( $@ );
        }
        return( _v( $ctx, _join_ptr( $ptr, 'contentSchema' ), $schema->{contentSchema}, $val ) );
    }
    return( { ok => 1, props => {}, items => {} } );
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

See also the live demonstration on CodePen: L<https://codepen.io/jdeguest/pen/vEGjNYX>

and the original announcement on Reddit: L<https://www.reddit.com/r/perl/comments/1p80dne/showcase_localised_json_schema_validation_in_perl/>

=head1 VERSION

v0.9.2

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

In the Perl validator, C<multipleOf> and numeric scalar comparisons for C<const> and C<enum> use the decimal representations produced by the JSON backend. This avoids rounding the quotient to a nearby integer, but cannot recover precision already lost when a number was decoded or normalised.

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

For C<date-time> and C<date>, leverages L<DateTime::Format::ISO8601> when available, then falls back to L<Time::Piece> (core since perl 5.10), then to L<DateTime> if installed, and finally to strict regex checks. C<duration> is validated entirely by a strict ISO 8601 regex; no external module is required or used.

=item * C<email>, C<idn-email>

Imported and use the very complex and complete regular expression from L<Regexp::Common::Email::Address>, but without requiring this module.

=item * C<hostname>, C<idn-hostname>

C<idn-hostname> uses L<Net::IDN::Encode> if available; otherwise, applies a permissive Unicode label check and then C<hostname> rules.

=item * C<ipv4>, C<ipv6>

Strict regex-based validation.

=item * C<uri>, C<uri-reference>, C<iri>

Reasonable regex checks: C<uri> and C<iri> require a proper RFC-compliant scheme (C<ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )> followed by C<:>); C<iri> additionally permits Unicode characters in the path and query components. C<uri-reference> allows an optional scheme. None of these is a full RFC 2396/3987 parser.

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

Enabling extensions does not affect core Draft 2020-12 compliance - unknown keywords are still ignored unless explicitly supported.

=item C<format =E<gt> \%callbacks>

Hash of C<format_name =E<gt> sub{ ... }> validators. Each sub receives the string to validate and must return true/false. Entries here take precedence when you later call C<register_builtin_formats> (i.e. your callbacks remain in place).

=item C<ignore_unknown_required_vocab =E<gt> 1|0>

Defaults to C<0>

If enabled, required vocabularies declared in C<$vocabulary> that are not advertised as supported by the caller will be I<ignored> instead of causing the validator to C<die>.

You can also use C<ignore_req_vocab> for short.

=item C<max_errors>

Defaults to C<200>

Sets the maximum number of errors to be recorded. A value of C<0> disables this limit.

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

C<const> and C<enum>, including objects and arrays. JSON value types are preserved.

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

The Perl validator uses Perl regular expression semantics, not the ECMA-262 dialect. For strict end-of-input matching in Perl, use C<\z>; the C<$> anchor can also match before a final newline. Use C<[0-9]> when ASCII digits are required.

Patterns are converted from Perl syntax to JavaScript using a conservative converter (e.g. C<\x{FF70}> to C<\uFF70>, C<\p{Katakana}> to C<\p{scx=Katakana}>). When the browser does not support the necessary Unicode features, such patterns are skipped client-side.

=item * Arrays

C<prefixItems>, C<items> (single-schema form), C<minItems>, C<maxItems>, C<contains>, C<minContains>, C<maxContains>.

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

C<patternProperties>, C<unevaluatedItems>, C<unevaluatedProperties>, C<contentEncoding>, C<contentMediaType>, C<contentSchema>, external C<$ref> and C<$dynamicRef> targets.

=back

In other words: the JS validator is a fast, user-friendly I<pre-flight> check for web forms; the Perl validator remains the source of truth. Unsupported constraints can also affect branch selection in combinators and conditionals, so a client-side failure is not in itself proof that the instance is invalid under the complete schema.

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

=item * C<( $ok, $msg, $decoded )> - canonical form. On success C<$ok> is true, C<$msg> is optional, and C<$decoded> can be either a Perl structure or a new octet/string value.

=item * a reference - treated as success with that reference as C<$decoded>.

=item * a defined scalar - treated as success with that scalar as C<$decoded>.

=item * C<undef> or empty list - treated as failure.

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

Install a resolver for external documents. It receives the resolved reference URI, including any fragment. It must return a Perl hash reference or a JSON boolean representing the complete external schema, not merely the referenced fragment. A relative C<$id> in the returned schema is resolved against the retrieval URI. References within that resource are resolved locally. Resolver answers are cached only for the duration of a validation call. Identical schemas with the same canonical identifier may be retrieved through different URIs; conflicting resource definitions are rejected.

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

Maximum number of errors to collect before stopping validation. A value of C<0> disables this limit.

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

The validator guards active evaluations by resource URI, schema pointer and instance address (or instance path, JSON type and value for scalars). Independent evaluations of the same reference are not skipped.

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

Both Perl code paths are intended to enforce the same constraints. The interpreter is useful while developing a schema; toggle C<< ->compile >> when moving to production or after the schema stabilises. You may enable compilation lazily (call C<compile> any time) or eagerly via the constructor (C<< compile => 1 >>).

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

L<perl>, L<Time::Piece>, L<DateTime>, L<DateTime::Format::ISO8601>, L<Regexp::Common>, L<Net::IDN::Encode>, L<JSON::PP>

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
