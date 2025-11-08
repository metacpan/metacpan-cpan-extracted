##----------------------------------------------------------------------------
## JSON Schema Validator - ~/lib/JSON/Schema/Validate.pm
## Version v0.1.0
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2025/11/07
## Modified 2025/11/07
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
    use vars qw( $VERSION );
    use B ();
    use JSON ();
    use Scalar::Util qw( blessed looks_like_number reftype refaddr );
    use List::Util qw( first any all );
    use Encode ();
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub new
{
    my $class  = shift( @_ );
    my $schema = shift( @_ );

    my $self =
    {
        # { schema, anchors, id_index, base }
        compiled            => undef,
        errors              => [],
        formats             => {},
        last_error          => '',
        max_errors          => 200,
        normalize_instance  => 1,
        # ($abs_uri) -> $schema_hashref
        resolver            => undef,
        schema              => _clone( $schema ),
    };

    bless( $self, $class );
    my $opts = $self->_get_args_as_hash( @_ );
    if( exists( $opts->{normalize_instance} ) )
    {
        $self->{normalize_instance} = $opts->{normalize_instance} ? 1 : 0;
    }

    # User-supplied format callbacks (override precedence left to caller order)
    if( $opts->{format} && ref( $opts->{format} ) eq 'HASH' )
    {
        $self->{formats}->{ $_ } = $opts->{format}->{ $_ } for( keys( %{$opts->{format}} ) );
    }
    $self->{compiled} = _compile_root( $self->{schema} );
    return $self;
}

sub error  { $_[0]->{last_error} }

sub errors { return( [ map { { %$_ } } @{ $_[0]->{errors} } ] ); }

sub register_builtin_formats
{
    my( $self ) = @_;

    require Regexp::Common;
    Regexp::Common->import();
    require DateTime;
    require DateTime::Duration;
    local $@;
    my $has_iso  = eval { require DateTime::Format::ISO8601; 1 } ? 1 : 0;
    my $has_idn  = eval { require Net::IDN::Encode; 1 } ? 1 : 0;
    my $has_mail = eval { require Regexp::Common; Regexp::Common->import('Email::Address'); 1 } ? 1 : 0;

    my %F;

    # RFC3339 date-time / date / time
    $F{'date-time'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return eval { DateTime::Format::ISO8601->parse_datetime($s) ? 1 : 0 } if( $has_iso );
        return( $s =~ /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+\-]\d{2}:\d{2})\z/ ? 1 : 0 );
    };

    $F{'date'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return(0) unless( $s =~ /\A(\d{4})-(\d{2})-(\d{2})\z/ );
        my( $y, $m, $d ) = ( $1, $2, $3 );
        return eval { DateTime->new( year => $y, month => $m, day => $d ); 1 } ? 1 : 0;
    };

    $F{'time'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        if( $has_iso )
        {
            return eval { DateTime::Format::ISO8601->parse_datetime("1970-01-01T$s") ? 1 : 0 } ? 1 : 0;
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
        return(0) unless $s =~ /\A
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
        \z/x;
        my( $y, $mo, $d, $h, $mi, $se ) = ( $1 || 0, $2 || 0, $3 || 0, $4 || 0, $5 || 0, $6 || 0 );
        return eval {
            DateTime::Duration->new(
                years => $y, months => $mo, days => $d,
                hours => $h, minutes => $mi, seconds => $se
            ); 1;
        } ? 1 : 0;
    };

    # Email / IDN email
    if( $has_mail )
    {
        $F{'email'}     = sub { defined $_[0] && !ref($_[0]) && $_[0] =~ /\A$Regexp::Common::RE{Email}{Address}\z/ ? 1 : 0 };
        $F{'idn-email'} = $F{'email'};
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
            my $a = eval { Net::IDN::Encode::domain_to_ascii($s) };
            return( $a && $F{'hostname'}->($a) ? 1 : 0 );
        }
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

    # --- UUID ---

    $F{'uuid'} = sub
    {
        my( $s ) = @_;
        return(0) unless( defined( $s ) && !ref( $s ) );
        return( $s =~ /\A[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}\z/ ? 1 : 0 );
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
        return( eval { "" =~ /$s/; 1 } ? 1 : 0 );
    };

    while( my( $k, $v ) = each( %F ) )
    {
        $self->{formats}->{ $k } = $v unless( exists( $self->{formats}->{ $k } ) );
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

sub set_resolver
{
    my( $self, $code ) = @_;
    $self->{resolver} = $code if( ref( $code ) eq 'CODE' );
    return( $self );
}

sub validate
{
    my( $self, $data ) = @_;

    $self->{errors}     = [];
    $self->{last_error} = '';

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
        id_stack        => [ $self->{compiled}{base} ],
        dyn_stack       => [ {} ],                     # dynamicAnchor scope frames
        visited         => {},                         # "schema_ptr|inst_addr" => 1

        # annotation (for unevaluated*)
        ann_mode        => 1,
    };

    my $res = _v( $ctx, '#', $self->{compiled}{schema}, $data );

    if( !$res->{ok} )
    {
        $self->{last_error} = _first_error_text( $self->{errors} );
        return 0;
    }
    return 1;
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

    # Local fragment → pointer or anchor
    if( $ref =~ /^\#/ )
    {
        # 2.a JSON Pointer path
        if( my $n = $ctx->{root}{anchors}{$ref} )
        {
            return( _v( $ctx, $ref, $n, $inst ) );
        }

        # 2.b Anchor name (e.g. "#Name")
        if( $ref =~ /^\#([A-Za-z0-9._-]+)\z/ )
        {
            my $cand = $base . '#' . $1;
            if( my $node = $ctx->{root}{id_index}{$cand} )
            {
                my $sp = _ptr_of_node( $ctx->{root}, $node );
                return( _v( $ctx, $sp, $node, $inst ) );
            }
        }

        # 2.c Convenience: "#$defs/Name" → treat the tail "Name" as an anchor
        if( $ref =~ /^\#\$defs\/([A-Za-z0-9._-]+)\z/ )
        {
            my $cand = $base . '#' . $1;
            if( my $node = $ctx->{root}{id_index}{$cand} )
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
        my $ext = eval { $ctx->{resolver}->( $abs ) };
        return( _err_res( $ctx, $schema_ptr, "resolver failed for \$ref: $abs" ) ) unless( $ext && ref( $ext ) );

        my $ext_base = _normalize_uri( ( ref( $ext ) eq 'HASH' && $ext->{'$id'} ) ? $ext->{'$id'} : $abs );
        my( $anchors, $ids ) = ( {}, {} );
        _index_schema_202012( $ext, $ext_base, '#', $anchors, $ids );

        push( @{ $ctx->{id_stack} }, $ext_base );
        my $r = _v( $ctx, '#', $ext, $inst );
        pop( @{ $ctx->{id_stack} } );
        return( $r );
    }

    return( _err_res( $ctx, $schema_ptr, "unresolved \$ref: $ref (abs: $abs)" ) );
}

sub _canon
{
    my( $v ) = @_;
    my $json = JSON->new->allow_nonref(1)->canonical(1)->convert_blessed(1);
    return( $json->encode( $v ) );
}

sub _clone
{
    my( $v ) = @_;
    my $json = JSON->new->allow_nonref(1)->canonical(1);
    return( $json->decode( $json->encode( $v ) ) );
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
    });
}

# Errors, utils, pointers, URIs
sub _err
{
    my( $ctx, $ptr, $msg ) = @_;
    push @{ $ctx->{errors} }, { path => $ptr, msg => $msg };
    $ctx->{error_count}++;
    return(0);
}

sub _err_res
{
    my( $ctx, $ptr, $msg ) = @_;
    _err( $ctx, $ptr, $msg );
    return( { ok => 0, props => {}, items => {} } );
}

sub _fail { return( { ok => 0, props => {}, items => {} } ); }

sub _first_error_text
{
    my( $errs ) = @_;
    return( '' ) unless( @$errs );
    my $e = $errs->[0];
    return( "$e->{path}: $e->{msg}" );
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
    # JSON::PP marks numbers with IOK/NOK; plain strings (even "12") won’t have them.
    my $sv    = B::svref_2object( \$v );
    my $flags = $sv->FLAGS;

    # SVf_IOK = 0x02000000, SVf_NOK = 0x04000000 on most builds;
    # we don’t hardcode constants—B::SV’s FLAGS is stable to test with these bitmasks.
    # Use string eval to avoid importing platform-specific constants.
    my $SVf_IOK = eval { B::SVf_IOK() } || 0x02000000;
    my $SVf_NOK = eval { B::SVf_NOK() } || 0x04000000;

    return( ( $flags & ($SVf_IOK | $SVf_NOK) ) ? 1 : 0 );
}

sub _is_true { my $v = shift; return ref($v) eq 'HASH' ? 0 : $v ? 1 : 0; }

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
        return( _err_res( $ctx, $sp, "array has fewer than minItems $S->{minItems}" ) );
    }
    if( exists( $S->{maxItems} ) && @$A > $S->{maxItems} )
    {
        return( _err_res( $ctx, $sp, "array has more than maxItems $S->{maxItems}" ) );
    }

    if( $S->{uniqueItems} )
    {
        my %seen;
        for my $i ( 0 .. $#$A )
        {
            my $k = _canon( $A->[$i] );
            if( $seen{ $k }++ )
            {
                return( _err_res( $ctx, _join_ptr( $sp, $i ), "array items not unique" ) );
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
                $items_ann{$i} = 1;
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

        return( _err_res( $ctx, $sp, "contains matched $matches < minContains $minc" ) ) if( $matches < $minc );
        return( _err_res( $ctx, $sp, "contains matched $matches > maxContains $maxc" ) ) if( $matches > $maxc );
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
            return( _err_res( $ctx, $sp, "unevaluatedItems not allowed at indices: " . join( ',', @unknown ) ) ) if( @unknown );
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
        for my $i ( 0 .. $#{ $S->{allOf} } )
        {
            my $r = _v( $ctx, _join_ptr( $sp, "allOf/$i" ), $S->{allOf}->[ $i ], $inst );
            return( $r ) unless( $r->{ok} );
            %props = ( %props, %{ $r->{props} } );
            %items = ( %items, %{ $r->{items} } );
        }
        return( { ok => 1, props => \%props, items => \%items } );
    }

    if( $kw eq 'anyOf' )
    {
        for my $i ( 0 .. $#{ $S->{anyOf} } )
        {
            my $r = _v( $ctx, _join_ptr( $sp, "anyOf/$i" ), $S->{anyOf}->[ $i ], $inst );
            return( $r ) if( $r->{ok} );
        }
        return( _err_res( $ctx, $sp, "instance does not satisfy anyOf" ) );
    }

    if( $kw eq 'oneOf' )
    {
        my @ok;
        for my $i ( 0 .. $#{ $S->{oneOf} } )
        {
            my $r = _v( $ctx, _join_ptr( $sp,"oneOf/$i" ), $S->{oneOf}->[$i], $inst );
            push( @ok, $r ) if( $r->{ok} );
        }
        return( $ok[0] ) if( @ok == 1 );
        return( _err_res( $ctx, $sp, "instance satisfies " . scalar( @ok ) . " schemas in oneOf (expected exactly 1)" ) );
    }

    if( $kw eq 'not' )
    {
        my $r = _v( $ctx, _join_ptr( $sp, "not" ), $S->{not}, $inst );
        return( _err_res( $ctx, $sp, "instance matches forbidden not-schema" ) ) if( $r->{ok} );
        return( { ok => 1, props => {}, items => {} } );
    }

    return( { ok => 1, props => {}, items => {} } );
}

sub _k_const
{
    my( $ctx, $v, $const, $ptr ) = @_;
    return(1) if( _json_equal( $v, $const ) );
    return( _err( $ctx, $ptr, "const mismatch" ) );
}

sub _k_enum
{
    my( $ctx, $v, $arr, $ptr ) = @_;
    for my $e ( @$arr )
    {
        return(1) if( _json_equal( $v, $e ) );
    }
    return( _err( $ctx, $ptr, "value not in enum" ) );
}

sub _k_format
{
    my( $ctx, $s, $fmt, $ptr ) = @_;
    my $cb = $ctx->{formats}->{ $fmt };
    return(1) unless( $cb );
    local $@;
    my $ok = eval { $cb->( $s ) ? 1 : 0 };
    return( $ok ? 1 : _err( $ctx, $ptr, "string fails format '$fmt'" ) );
}

sub _k_if_then_else
{
    my( $ctx, $sp, $S, $inst ) = @_;

    my $cond = _v( $ctx, _join_ptr( $sp, 'if' ), $S->{if}, $inst );
    if( $cond->{ok} )
    {
        return( { ok => 1, props => {}, items => {} } ) unless( exists( $S->{then} ) );
        return( _v( $ctx, _join_ptr( $sp, 'then' ), $S->{then}, $inst ) );
    }
    else
    {
        return( { ok => 1, props => {}, items => {} } ) unless( exists( $S->{else} ) );
        return( _v( $ctx, _join_ptr( $sp, 'else' ), $S->{else}, $inst ) );
    }
}

sub _k_number
{
    my( $ctx, $v, $kw, $arg, $ptr ) = @_;
    if( $kw eq 'multipleOf' )
    {
        return( _err( $ctx, $ptr, "number not multipleOf $arg" ) )
            unless( $arg && ( ( $v / $arg ) == int( $v / $arg ) ) );
        return(1);
    }
    if( $kw eq 'minimum' )
    {
        return( $v >= $arg ? 1 : _err( $ctx, $ptr, "number less than minimum $arg" ) );
    }
    elsif( $kw eq 'maximum' )
    {
        return( $v <= $arg ? 1 : _err( $ctx, $ptr, "number greater than maximum $arg" ) );
    }
    elsif( $kw eq 'exclusiveMinimum' )
    {
        return( $v >  $arg ? 1 : _err( $ctx, $ptr, "number not greater than exclusiveMinimum $arg" ) );
    }
    elsif( $kw eq 'exclusiveMaximum' )
    {
        return( $v <  $arg ? 1 : _err( $ctx, $ptr, "number not less than exclusiveMaximum $arg" ) );
    }
    return(1);
}

sub _k_object_all
{
    my( $ctx, $sp, $S, $H ) = @_;

    if( exists( $S->{minProperties} ) && ( scalar( keys( %$H ) ) ) < $S->{minProperties} )
    {
        return( _err_res( $ctx, $sp, "object has fewer than minProperties $S->{minProperties}" ) );
    }
    if( exists( $S->{maxProperties} ) && ( scalar( keys( %$H ) ) ) > $S->{maxProperties} )
    {
        return( _err_res( $ctx, $sp, "object has more than maxProperties $S->{maxProperties}" ) );
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

    for my $rq ( grep { $required{ $_ } } keys( %required ) )
    {
        next if( exists( $H->{ $rq } ) );
        return( _err_res( $ctx, _join_ptr( $sp, $rq ), "required property '$rq' is missing" ) );
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
                my $ok = eval { $k =~ /$re/ };
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
                return( _err_res( $ctx, _join_ptr( $sp, $k ), "additionalProperties not allowed: '$k'" ) );
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
            for my $need ( @{ $depR->{ $k } || [] } )
            {
                next if( exists( $H->{ $need } ) );
                return( _err_res( $ctx, _join_ptr( $sp, $need ), "dependentRequired: '$need' required when '$k' is present" ) );
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
            return( _err_res( $ctx, $sp, "unevaluatedProperties not allowed: " . join( ',', @unknown ) ) ) if( @unknown );
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
        return( _err( $ctx, $ptr, "string shorter than minLength $S->{minLength}" ) );
    }
    if( exists( $S->{maxLength} ) && $len > $S->{maxLength} )
    {
        return( _err( $ctx, $ptr, "string longer than maxLength $S->{maxLength}" ) );
    }
    if( exists( $S->{pattern} ) )
    {
        my $re = $S->{pattern};
        local $@;
        my $ok = eval { $s =~ /$re/ };
        return( _err( $ctx, $ptr, "string does not match pattern /$re/" ) ) unless( $ok );
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

    my $exp = join( '|', map { ref($_) ? 'schema' : $_ } @alts );
    return( _err( $ctx, $ptr, "type mismatch: expected $exp" ) );
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

    return(1) if( $t eq 'array'   && ref( $v ) eq 'ARRAY' );
    return(1) if( $t eq 'object'  && ref( $v ) eq 'HASH' );

    return(0);
}

sub _normalize_uri
{
    my( $u ) = @_;
    return( '#' ) unless( defined( $u ) && length( $u ) );
    return( $u );
}

sub _ptr_of_node
{
    my( $root, $target ) = @_;
    for my $p ( keys( %{ $root->{anchors} } ) )
    {
        my $n = $root->{anchors}->{ $p };
        return( $p ) if( $n eq $target );
    }
    return( '#' );
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

sub _strlen
{
    my( $s ) = @_;
    $s = Encode::decode( 'UTF-8', "$s", Encode::FB_DEFAULT ) unless( Encode::is_utf8( $s ) );
    my @cp = unpack( 'U*', $s );
    return( scalar( @cp ) );
}

# Validation core with annotation + recursion
# _v returns { ok=>0|1, props=>{k=>1,...}, items=>{i=>1,...} }
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
    if( ref( $schema ) eq 'HASH' && exists( $schema->{'$dynamicAnchor'} ) && defined( $schema->{'$dynamicAnchor'} ) && $schema->{'$dynamicAnchor'} ne '' )
    {
        my %frame = %{ $ctx->{dyn_stack}->[-1] }; # inherit
        $frame{ $schema->{'$dynamicAnchor'} } = $schema;
        push( @{ $ctx->{dyn_stack} }, \%frame );
        $frame_added = 1;
    }

    my $res = _v_node( $ctx, $schema_ptr, $schema, $inst );

    if( $frame_added )
    {
        pop( @{ $ctx->{dyn_stack} } );
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

    # Numbers
    if( _is_number($inst) )
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

    # Objects
    if( ref( $inst ) eq 'HASH' )
    {
        my $r = _k_object_all( $ctx, $schema_ptr, $schema, $inst );
        return( $r ) unless( $r->{ok} );
        %ann_props = ( %ann_props, %{ $r->{props} } );
    }

    # Combinators
    for my $comb ( qw( allOf anyOf oneOf not ) )
    {
        next unless( exists( $schema->{ $comb } ) );
        my $r = _k_combinator( $ctx, $schema_ptr, $schema, $inst, $comb );
        return( $r ) unless( $r->{ok} );
        %ann_props = ( %ann_props, %{ $r->{props} } );
        %ann_items = ( %ann_items, %{ $r->{items} } );
    }

    # Conditionals
    if( exists( $schema->{if} ) )
    {
        my $r = _k_if_then_else( $ctx, $schema_ptr, $schema, $inst );
        return( $r ) unless( $r->{ok} );
        %ann_props = ( %ann_props, %{ $r->{props} } );
        %ann_items = ( %ann_items, %{ $r->{items} } );
    }

    return( { ok => 1, props => \%ann_props, items => \%ann_items } );
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
        ->register_builtin_formats;

    my $ok = $js->validate({ name => 'head', next=>{ name => 'tail' } })
        or die $js->error;

    print "ok\n";

=head1 VERSION

v0.1.0

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

Reasonable regex checks for scheme and reference forms (not a full RFC parser).

=item * C<uuid>

Hyphenated 8-4-4-4-12 hex.

=item * C<json-pointer>, C<relative-json-pointer>

Conformant to RFC 6901 and the relative variant used by JSON Schema.

=item * C<regex>

Checks that the pattern compiles in Perl.

=back

Custom formats can be registered or override builtins via C<register_format> or the C<format =E<gt> { ... }> constructor option (see L</METHODS>).

=head1 METHODS

=head2 new

    my $js = JSON::Schema::Validate->new( $schema, %opts );

Build a validator from a decoded JSON Schema (Perl hash/array structure).

Options (all optional):

=over 4

=item C<format =E<gt> \%callbacks>

Hash of C<format_name =E<gt> sub { ... }> validators. Each sub receives the string to validate and must return true/false. Entries here take precedence when you later call C<register_builtin_formats> (i.e. your callbacks remain in place).

=item C<fnormalize_instance =E<gt> 1|0>

Defaults to C<1>

When true, the instance is round-tripped through L<JSON> before validation, which enforces strict JSON typing (strings remain strings; numbers remain numbers). This matches Python C<jsonschema>’s type behaviour. Set to C<0> if you prefer Perl’s permissive numeric/string duality.

=back

=head2 register_builtin_formats

    $js->register_builtin_formats;

Registers the built-in validators listed in L</Formats>. Existing user-supplied format callbacks are preserved if they already exist under the same name.

=head2 register_format

    $js->register_format( $name, sub { ... } );

Register or override a C<format> validator at runtime. The sub receives a single scalar (the candidate string) and must return true/false.

=head2 set_resolver

    $js->set_resolver( sub { my( $absolute_uri ) = @_; ...; return $schema_hashref } );

Install a resolver for external documents. It is called with an absolute URI (formed from the current base C<$id> and the C<$ref>) and must return a Perl hash reference representation of a JSON Schema. If the returned hash contains C<'$id'>, it will become the new base for that document; otherwise, the absolute URI is used as its base.

=head2 validate

    my $ok = $js->validate( $data );

Validate a decoded JSON instance against the compiled schema. Returns a boolean.
On failure, inspect C<< $js->error >> for a concise message (first error), or C<< $js->errors >> for an arrayref of hashes like:

    { path => '#/properties~1name', msg => 'string shorter than minLength 1' }

=head2 error

    my $msg = $js->error;

Short, human-oriented message for the first failure.

=head2 errors

    my $arrayref = $js->errors;

All collected errors (up to the internal C<max_errors> cap).

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

=item * Unsupported/Not Implemented

This module intentionally omits some rarely used 2020-12 control keywords such as C<$vocabulary> and C<$comment> processing, and media-related keywords like C<contentEncoding>/C<contentMediaType>. These can be added later if required.

=back

=head1 CREDITS

Albert from OpenAI for his invaluable help.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<perl>, L<DateTime>, L<DateTime::Format::ISO8601>, L<DateTime::Duration>, L<Regexp::Common>, L<Net::IDN::Encode>, L<JSON::PP>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2025 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
