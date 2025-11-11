##----------------------------------------------------------------------------
## JSON Schema Validator - ~/lib/JSON/Schema/Validate.pm
## Version v0.3.0
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2025/11/07
## Modified 2025/11/10
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
    use vars qw( $VERSION );
    use B ();
    use JSON ();
    use Scalar::Util qw( blessed looks_like_number reftype refaddr );
    use List::Util qw( first any all );
    use Encode ();
    our $VERSION = 'v0.3.0';
};

use strict;
use warnings;

sub new
{
    my $class  = shift( @_ );
    my $schema = shift( @_ );

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
        formats             => {},
        # boolean
        ignore_req_vocab    => 0,
        last_error          => '',
        last_trace          => [],
        max_errors          => 200,
        media_validators    => {},
        # boolean
        normalize_instance  => 1,
        # ($abs_uri) -> $schema_hashref
        resolver            => undef,
        schema              => _clone( $schema ),
        # 0 = unlimited
        trace_limit         => 0,
        # boolean
        trace_on            => 0,
        # 0 = record all
        trace_sample        => 0,
        # internal boolean; not an option
        vocab_checked       => 0,
        vocab_support       => {},
    };

    bless( $self, $class );
    my $opts = $self->_get_args_as_hash( @_ );
    my @bool_options = qw( content_assert ignore_req_vocab normalize_instance );
    foreach my $opt ( @bool_options )
    {
        next unless( exists( $opts->{ $opt } ) );
        $self->{ $opt } = $opts->{ $opt } ? 1 : 0
    }
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
    $self->{vocab_support} = $opts->{vocab_support} ? { %{ $opts->{vocab_support} } } : {};

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

sub get_trace
{
    my( $self ) = @_;
    return( [ @{ $self->{last_trace} || [] } ] );
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

sub is_unknown_required_vocab_ignored { $_[0]->{ignore_req_vocab} ? 1 : 0 }

sub register_builtin_formats
{
    my( $self ) = @_;

    require Regexp::Common;
    Regexp::Common->import();
    require DateTime;
    require DateTime::Duration;
    local $@;
    my $email_re;
    my $has_iso  = eval{ require DateTime::Format::ISO8601; 1 } ? 1 : 0;
    my $has_idn  = eval{ require Net::IDN::Encode; 1 } ? 1 : 0;
    my $has_mail = eval{ require Regexp::Common; Regexp::Common->import('Email::Address'); no warnings 'once'; $email_re = qr/\A$Regexp::Common::RE{Email}{Address}\z/; 1 } ? 1 : 0;

    my %F;

    # RFC3339 date-time / date / time
    $F{'date-time'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return eval{ DateTime::Format::ISO8601->parse_datetime( $s ) ? 1 : 0 } if( $has_iso );
        return( $s =~ /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+\-]\d{2}:\d{2})\z/ ? 1 : 0 );
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
    if( $has_mail )
    {
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

            # Without IDN module, fall back to permissive Unicode domain check + ASCII regex
            # If you prefer to hard-fail instead, return 0 here.
            return(0);
        };
    }

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

sub validate
{
    my( $self, $data ) = @_;

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

    if( $self->{normalize_instance} )
    {
        my $json = JSON->new->allow_nonref(1)->canonical(1);
        $data = $json->decode( $json->encode( $data ) );
    }

    my $ctx =
    {
        root            => $self->{compiled},
        instance_root   => $data,
        resolver        => $self->{resolver},
        formats         => $self->{formats},
        errors          => $self->{errors},
        max_errors      => $self->{max_errors},
        error_count     => 0,

        # paths / recursion
        ptr_stack       => ['#'],
        id_stack        => [ $self->{compiled}->{base} ],
        dyn_stack       => [ {} ],                     # dynamicAnchor scope frames
        visited         => {},                         # "schema_ptr|inst_addr" => 1

        # annotation (for unevaluated*)
        ann_mode        => 1,
        compile_on      => $self->{compile_on} ? 1 : 0,

        # trace
        trace_on        => $self->{trace_on} ? 1 : 0,
        trace_sample    => $self->{trace_sample} || 0,
        trace_limit     => $self->{trace_limit}  || 0,
        trace           => [],

        # content assertion & helpers
        content_assert   => $self->{content_assert} ? 1 : 0,
        media_validators => $self->{media_validators},
        content_decoders => $self->{content_decoders},

        comment_handler => $self->{comment_handler},
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
        if( $ref =~ /^\#\$defs\/([A-Za-z0-9._-]+)\z/ )
        {
            my $cand = $base . '#' . $1;
            if( my $node = $ctx->{root}->{id_index}->{ $cand } )
            {
                my $sp = _ptr_of_node( $ctx->{root}, $node );
                return( _v( $ctx, $sp, $node, $inst ) );
            }
        }
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

    my %numk = map{ $_ => $S->{$_} } grep{ exists( $S->{ $_ } ) }
               qw( multipleOf minimum maximum exclusiveMinimum exclusiveMaximum );

    my $has_strlen = ( exists( $S->{minLength} ) || exists( $S->{maxLength} ) || exists( $S->{pattern} ) ) ? 1 : 0;
    my $has_format  = exists( $S->{format} );
    my $format_name = $S->{format};

    # Precompile child closures (same structure your interpreter walks)
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
            %ann_props = ( %ann_props, %{ $r->{props} } );
        }

        # Combinators
        if( exists( $S->{allOf} ) && ref( $S->{allOf} ) eq 'ARRAY' )
        {
            my( %p, %it );
            for my $i ( 0 .. $#{ $S->{allOf} } )
            {
                my $r = $child{"allOf:$i"}->( $ctx, $inst );
                return $r unless $r->{ok};
                %p  = ( %p,  %{ $r->{props} } );
                %it = ( %it, %{ $r->{items} } );
            }
            %ann_props = ( %ann_props, %p );
            %ann_items = ( %ann_items, %it );
        }
        if( exists( $S->{anyOf} ) && ref( $S->{anyOf} ) eq 'ARRAY' )
        {
            my $ok = 0;
            for my $i ( 0 .. $#{ $S->{anyOf} } )
            {
                my $r = $child{"anyOf:$i"}->( $ctx, $inst );
                if( $r->{ok} )
                {
                    $ok = 1;
                    last;
                }
            }
            return( _err_res( $ctx, $ptr, "instance does not satisfy anyOf", 'anyOf' ) ) unless( $ok );
        }
        if( exists( $S->{oneOf} ) && ref( $S->{oneOf} ) eq 'ARRAY' )
        {
            my $hits = 0;
            for my $i ( 0 .. $#{$S->{oneOf}} )
            {
                my $r = $child{"oneOf:$i"}->( $ctx, $inst );
                $hits++ if( $r->{ok} );
            }
            return( _err_res( $ctx, $ptr, "instance satisfies $hits schemas in oneOf (expected exactly 1)", 'oneOf' ) ) unless( $hits == 1 );
        }
        if( exists( $S->{not} ) && ref( $S->{not} ) )
        {
            my $r = $child{"not"}->( $ctx, $inst );
            return( _err_res( $ctx, $ptr, "instance matches forbidden not-schema", 'oneOf' ) ) if( $r->{ok} );
        }

        # Conditionals
        if( exists( $S->{if} ) && ref( $S->{if} ) )
        {
            my $cond = $child{"if"}->( $ctx, $inst );
            if( $cond->{ok} )
            {
                if( exists( $child{"then"} ) )
                {
                    my $r = $child{"then"}->( $ctx, $inst );
                    return( $r ) unless( $r->{ok} );
                }
            }
            else
            {
                if( exists( $child{"else"} ) )
                {
                    my $r = $child{"else"}->( $ctx, $inst );
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
    my( $base, $token ) = @_;
    # Proper JSON Pointer escaping
    $token =~ s/~/~0/g;
    $token =~ s/\//~1/g;
    return( $base eq '#' ? "#/$token" : "$base/$token" );
}

sub _json_equal
{
    my( $a, $b ) = @_;
    return( _canon( $a ) eq _canon( $b ) );
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
        }
    }
    elsif( ref( $S->{items} ) eq 'HASH' )
    {
        for my $i ( 0 .. $#$A )
        {
            my $r = _v( $ctx, _join_ptr( $sp, "items" ), $S->{items}, $A->[$i] );
            return( $r ) unless( $r->{ok} );
            $items_ann{ $i } = 1;
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

    if( $kw eq 'allOf' )
    {
        my %props; my %items;
        for my $i ( 0 .. $#{$S->{allOf}} )
        {
            my $r = _v( $ctx, _join_ptr( $sp, "allOf/$i" ), $S->{allOf}->[ $i ], $inst );
            return( $r ) unless( $r->{ok} );
            %props = ( %props, %{$r->{props}} );
            %items = ( %items, %{$r->{items}} );
        }
        return( { ok => 1, props => \%props, items => \%items } );
    }

    if( $kw eq 'anyOf' )
    {
        for my $i ( 0 .. $#{$S->{anyOf}} )
        {
            my $r = _v( $ctx, _join_ptr( $sp, "anyOf/$i" ), $S->{anyOf}->[ $i ], $inst );
            return( $r ) if( $r->{ok} );
        }
        return( _err_res( $ctx, $sp, "instance does not satisfy anyOf", 'anyOf' ) );
    }

    if( $kw eq 'oneOf' )
    {
        my @ok;
        for my $i ( 0 .. $#{$S->{oneOf}} )
        {
            my $r = _v( $ctx, _join_ptr( $sp,"oneOf/$i" ), $S->{oneOf}->[$i], $inst );
            push( @ok, $r ) if( $r->{ok} );
        }
        return( $ok[0] ) if( @ok == 1 );
        return( _err_res( $ctx, $sp, "instance satisfies " . scalar( @ok ) . " schemas in oneOf (expected exactly 1)", 'oneOf' ) );
    }

    if( $kw eq 'not' )
    {
        my $r = _v( $ctx, _join_ptr( $sp, "not" ), $S->{not}, $inst );
        return( _err_res( $ctx, $sp, "instance matches forbidden not-schema", 'not' ) ) if( $r->{ok} );
        return( { ok => 1, props => {}, items => {} } );
    }

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

    my $cond = _v( $ctx, _join_ptr( $sp, 'if' ), $S->{if}, $inst );
    if( $cond->{ok} )
    {
        _t( $ctx, $sp, 'if', undef, 'pass', 'then' ) if( $ctx->{trace_on} );
        return( { ok => 1, props => {}, items => {} } ) unless( exists( $S->{then} ) );
        return( _v( $ctx, _join_ptr( $sp, 'then' ), $S->{then}, $inst ) );
    }
    else
    {
        _t( $ctx, $sp, 'if', undef, 'pass', 'else' ) if( $ctx->{trace_on} );
        return( { ok => 1, props => {}, items => {} } ) unless( exists( $S->{else} ) );
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

    if( exists( $S->{minProperties} ) && ( scalar( keys( %$H ) ) ) < $S->{minProperties} )
    {
        return( _err_res( $ctx, $sp, "object has fewer than minProperties $S->{minProperties}", 'minProperties' ) );
    }
    if( exists( $S->{maxProperties} ) && ( scalar( keys( %$H ) ) ) > $S->{maxProperties} )
    {
        return( _err_res( $ctx, $sp, "object has more than maxProperties $S->{maxProperties}", 'maxProperties' ) );
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
        return( _err_res( $ctx, _join_ptr( $sp, $rq ), "required property '$rq' is missing", 'required' ) );
    }

    if( exists( $S->{propertyNames} ) && ref( $S->{propertyNames} ) eq 'HASH' )
    {
        for my $k ( keys( %$H ) )
        {
            my $r = _v( $ctx, _join_ptr( $sp, "propertyNames" ), $S->{propertyNames}, $k );
            return( $r ) unless( $r->{ok} );
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

        if( exists( $props->{ $k } ) )
        {
            my $r = _v( $ctx, _join_ptr( $sp, "properties/$k" ), $props->{ $k }, $v );
            return( $r ) unless( $r->{ok} );
            $ann{ $k } = 1;
            $matched   = 1;
        }

        unless( $matched )
        {
            local $@;
            for my $re ( keys( %$patprops ) )
            {
                my $ok = eval{ $k =~ /$re/ };
                next unless( $ok );
                my $r = _v( $ctx, _join_ptr( $sp, "patternProperties/$re" ), $patprops->{ $re }, $v );
                return( $r ) unless( $r->{ok} );
                $ann{ $k } = 1;
                $matched   = 1;
            }
        }

        unless( $matched )
        {
            if( $addl_set && !_is_true( $addl ) && !_is_hash( $addl ) )
            {
                return( _err_res( $ctx, _join_ptr( $sp, $k ), "additionalProperties not allowed: '$k'", 'additionalProperties' ) );
            }
            elsif( ref( $addl ) eq 'HASH' )
            {
                my $r = _v( $ctx, _join_ptr( $sp, "additionalProperties" ), $addl, $v );
                return( $r ) unless( $r->{ok} );
                $ann{ $k } = 1;
            }
        }
    }

    if( my $depR = $S->{dependentRequired} )
    {
        for my $k ( keys( %$depR ) )
        {
            next unless( exists( $H->{ $k } ) );
            for my $need ( @{$depR->{ $k } || []} )
            {
                next if( exists( $H->{ $need } ) );
                return( _err_res( $ctx, _join_ptr( $sp, $need ), "dependentRequired: '$need' required when '$k' is present", 'dependentRequired' ) );
            }
        }
    }

    if( my $depS = $S->{dependentSchemas} )
    {
        for my $k ( keys( %$depS ) )
        {
            next unless( exists( $H->{ $k } ) );
            my $r = _v( $ctx, _join_ptr( $sp, "dependentSchemas/$k" ), $depS->{ $k }, $H );
            return( $r ) unless( $r->{ok} );
        }
    }

    if( exists( $S->{unevaluatedProperties} ) )
    {
        my @unknown = grep { !$ann{ $_ } } keys( %$H );
        my $UE = $S->{unevaluatedProperties};
        if( !_is_true( $UE ) && !_is_hash( $UE ) )
        {
            return( _err_res( $ctx, $sp, "unevaluatedProperties not allowed: " . join( ',', @unknown ), 'unevaluatedProperties' ) ) if( @unknown );
        }
        elsif( ref( $UE ) eq 'HASH' )
        {
            for my $k ( @unknown )
            {
                my $r = _v( $ctx, _join_ptr( $sp, "unevaluatedProperties" ), $UE, $H->{ $k } );
                return( $r ) unless( $r->{ok} );
                $ann{ $k } = 1;
            }
        }
    }

    return( { ok => 1, props => \%ann, items => {} } );
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

sub _match_type
{
    my( $v, $t ) = @_;

    return(1) if( $t eq 'null' && !defined( $v ) );

    if( $t eq 'boolean' )
    {
        return(0) if( ref( $v ) || !defined( $v ) );
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

sub _register_builtin_media_validators
{
    my( $self ) = @_;

    # Example: application/json
    $self->register_media_validator( 'application/json' => sub
    {
        my( $bytes, $params ) = @_;
        local $@;
        my $v = eval{ JSON->new->allow_nonref(1)->decode( $bytes ) };
        return( $v ? ( 1, undef, $v ) : ( 0, 'invalid JSON' ) );
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

    if( $ctx->{trace_limit} && @{ $ctx->{trace} } >= $ctx->{trace_limit} )
    {
        return;
    }
    if( $ctx->{trace_sample} )
    {
        return if( int( rand(100) ) >= $ctx->{trace_sample} );
    }

    push( @{ $ctx->{trace} }, 
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
    if( ref( $schema ) eq 'HASH' && exists( $schema->{'$ref'} ) )
    {
        return( _apply_ref( $ctx, $schema_ptr, $schema->{'$ref'}, $inst ) );
    }
    if( ref( $schema ) eq 'HASH' && exists( $schema->{'$dynamicRef'} ) )
    {
        return( _apply_dynamic_ref( $ctx, $schema_ptr, $schema->{'$dynamicRef'}, $inst ) );
    }
    if( exists( $schema->{'$comment'} ) && defined( $schema->{'$comment'} ) )
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
        ->register_builtin_formats
        ->trace
        ->trace_limit(200); # 0 means unlimited

    my $ok = $js->validate({ name => 'head', next=>{ name => 'tail' } })
        or die( $js->error );

    print "ok\n";

=head1 VERSION

v0.3.0

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

C<prefixItems>, C<items>, C<contains>, C<minContains>, C<maxContains>,
C<uniqueItems>, C<unevaluatedItems>.

=item * Objects

C<properties>, C<patternProperties>, C<additionalProperties>, C<propertyNames>, C<required>, C<dependentRequired>, C<dependentSchemas>, C<unevaluatedProperties>.

=item * Combinators

C<allOf>, C<anyOf>, C<oneOf>, C<not>.

=item * Conditionals

C<if>, C<then>, C<else>.

=item * Referencing

C<$id>, C<$anchor>, C<$ref>, C<$dynamicAnchor>, C<$dynamicRef>.

=back

=head2 Formats

Call C<register_builtin_formats> to install default validators for the following C<format> names:

=over 4

=item * C<date-time>, C<date>, C<time>, C<duration>

Leverages L<DateTime> and L<DateTime::Format::ISO8601> when available (falls back to strict regex checks). Duration uses L<DateTime::Duration>.

=item * C<email>, C<idn-email>

Uses L<Regexp::Common> with C<Email::Address> if available.

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

=item C<trace>

Defaults to C<0>

Enable or disable tracing. When enabled, the validator records lightweight, bounded trace events according to L</trace_limit> and L</trace_sample>.

=item C<trace_limit>

Defaults to C<0>

Set a hard cap on the number of trace entries recorded during a single C<validate> call (C<0> = unlimited).

=item C<trace_sample =E<gt> $percent>

Enable probabilistic sampling of trace events. C<$percent> is an integer percentage in C<[0,100]>. C<0> disables sampling. Sampling occurs per-event, and still respects L</trace_limit>.

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

=head2 content_checks

    $js->content_checks;     # enable
    $js->content_checks(1);  # enable
    $js->content_checks(0);  # disable

Turn on/off content assertions for the C<contentEncoding>, C<contentMediaType> and C<contentSchema> trio.

When enabling, built-in media validators are registered (e.g. C<application/json>).

Returns the current object to enable chaining.

=head2 POD::Coverage enable_content_checks

=head2 error

    my $msg = $js->error;

Returns the first error L<JSON::Schema::Validate::Error> object out of all the possible errors found (see L</errors>), if any.

When stringified, the object provides a short, human-oriented message for the first failure.

=head2 errors

    my $array_ref = $js->errors;

All collected L<error objects|JSON::Schema::Validate::Error> (up to the internal C<max_errors> cap).

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

=head2 is_unknown_required_vocab_ignored

    my $bool = $js->is_unknown_required_vocab_ignored;

Read-only accessor.

Returns true if unknown required vocabularies are being ignored, false otherwise.

=head2 register_builtin_formats

    $js->register_builtin_formats;

Registers the built-in validators listed in L</Formats>. Existing user-supplied format callbacks are preserved if they already exist under the same name.

User-supplied callbacks passed via C<< format => { ... } >> are preserved and take precedence.

=head2 register_content_decoder

    $js->register_content_decoder( $name => sub{ ... } );

Register a content B<decoder> for C<contentEncoding>. The callback receives a single argument: the raw data, and should return one of:

=over 4

=item * a decoded scalar (success);

=item * C<undef> (failure);

=item * or the triplet C<( $ok, $msg, $out )> where C<$ok> is truthy on success,
C<$msg> is an optional error string, and C<$out> is the decoded value.

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

    $js->set_resolver( sub { my( $absolute_uri ) = @_; ...; return $schema_hashref } );

Install a resolver for external documents. It is called with an absolute URI (formed from the current base C<$id> and the C<$ref>) and must return a Perl hash reference representation of a JSON Schema. If the returned hash contains C<'$id'>, it will become the new base for that document; otherwise, the absolute URI is used as its base.

=head2 set_vocabulary_support

    $js->set_vocabulary_support( \%support );

Declare which vocabularies the host supports, as a hash reference:

    {
        'https://example/vocab/core' => 1,
        ...
    }

Resets internal vocabulary-checked state so the declaration is enforced on next C<validate>.

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

=head2 validate

    my $ok = $js->validate( $data );

Validate a decoded JSON instance against the compiled schema. Returns a boolean.
On failure, inspect C<< $js->error >> to retrieve the L<error object|JSON::Schema::Validate::Error> that stringifies for a concise message (first error), or C<< $js->errors >> for an array reference of L<error objects|JSON::Schema::Validate::Error> like:

    my $err = $js->error;
    say $err->path; # #/properties~1name
    say $err->message; # string shorter than minLength 1
    say "$err"; # error object will stringify

=head1 BEHAVIOUR NOTES

=over 4

=item * Recursion & Cycles

The validator guards on the pair C<(schema_pointer, instance_address)>, so self-referential schemas and cyclic instance graphs won’t infinite-loop.

=item * Union Types with Inline Schemas

C<type> may be an array mixing string type names and inline schemas. Any inline schema that validates the instance makes the C<type> check succeed.

=item * Booleans

For practicality in Perl, C<< type => 'boolean' >> accepts JSON-like booleans (e.g. true/false, 1/0 as strings) as well as Perl boolean objects (if you use a boolean class). If you need stricter behaviour, you can adapt C<_match_type> or introduce a constructor flag and branch there.

=item * Unevaluated*

Both C<unevaluatedItems> and C<unevaluatedProperties> are enforced using annotation produced by earlier keyword evaluations within the same schema object, matching draft 2020-12 semantics.

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

=head1 CREDITS

Albert from OpenAI for his invaluable help.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>, L<DateTime>, L<DateTime::Format::ISO8601>, L<DateTime::Duration>, L<Regexp::Common>, L<Net::IDN::Encode>, L<JSON::PP>

L<JSON::Schema>, L<JSON::Validator>

L<python-jsonschema|https://github.com/python-jsonschema/jsonschema>,
L<fastjsonschema|https://github.com/horejsek/python-fastjsonschema>,
L<Pydantic|https://docs.pydantic.dev>,
L<RapidJSON Schema|https://rapidjson.org/md_doc_schema.html>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2025 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
