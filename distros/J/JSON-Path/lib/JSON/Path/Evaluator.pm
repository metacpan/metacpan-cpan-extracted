package JSON::Path::Evaluator;
$JSON::Path::Evaluator::VERSION = '0.431';
use strict;
use warnings;
use 5.008;

# ABSTRACT: A module that recursively evaluates JSONPath expressions with native support for Javascript-style filters

use Carp;
use Carp::Assert qw(assert);
use Exporter::Tiny ();
use JSON::MaybeXS;
use JSON::Path::Constants qw(:operators :symbols);
use JSON::Path::Tokenizer qw(tokenize);
use List::Util qw/pairs/;
use Readonly;
use Safe;
use Scalar::Util qw/looks_like_number blessed refaddr/;
use Storable qw/dclone/;
use Sys::Hostname qw/hostname/;
use Try::Tiny;

# VERSION
use base q(Exporter);
our $AUTHORITY = 'cpan:POPEFELIX';
our @EXPORT_OK = qw/ evaluate_jsonpath /;

Readonly my $OPERATOR_IS_TRUE         => 'IS_TRUE';
Readonly my $OPERATOR_TYPE_PATH       => 1;
Readonly my $OPERATOR_TYPE_COMPARISON => 2;
Readonly my %OPERATORS                => (
    $TOKEN_ROOT                => $OPERATOR_TYPE_PATH,          # $
    $TOKEN_CURRENT             => $OPERATOR_TYPE_PATH,          # @
    $TOKEN_CHILD               => $OPERATOR_TYPE_PATH,          # . OR []
    $TOKEN_RECURSIVE           => $OPERATOR_TYPE_PATH,          # ..
    $TOKEN_ALL                 => $OPERATOR_TYPE_PATH,          # *
    $TOKEN_FILTER_OPEN         => $OPERATOR_TYPE_PATH,          # ?(
    $TOKEN_SCRIPT_OPEN         => $OPERATOR_TYPE_PATH,          # (
    $TOKEN_FILTER_SCRIPT_CLOSE => $OPERATOR_TYPE_PATH,          # )
    $TOKEN_SUBSCRIPT_OPEN      => $OPERATOR_TYPE_PATH,          # [
    $TOKEN_SUBSCRIPT_CLOSE     => $OPERATOR_TYPE_PATH,          # ]
    $TOKEN_UNION               => $OPERATOR_TYPE_PATH,          # ,
    $TOKEN_ARRAY_SLICE         => $OPERATOR_TYPE_PATH,          # [ start:end:step ]
    $TOKEN_SINGLE_EQUAL        => $OPERATOR_TYPE_COMPARISON,    # =
    $TOKEN_DOUBLE_EQUAL        => $OPERATOR_TYPE_COMPARISON,    # ==
    $TOKEN_TRIPLE_EQUAL        => $OPERATOR_TYPE_COMPARISON,    # ===
    $TOKEN_GREATER_THAN        => $OPERATOR_TYPE_COMPARISON,    # >
    $TOKEN_LESS_THAN           => $OPERATOR_TYPE_COMPARISON,    # <
    $TOKEN_NOT_EQUAL           => $OPERATOR_TYPE_COMPARISON,    # !=
    $TOKEN_GREATER_EQUAL       => $OPERATOR_TYPE_COMPARISON,    # >=
    $TOKEN_LESS_EQUAL          => $OPERATOR_TYPE_COMPARISON,    # <=
);

Readonly my $ASSERT_ENABLE => $ENV{ASSERT_ENABLE};


sub new {
    my $class = shift;
    my %args  = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;
    my $self  = {};
    for my $key (qw/root expression/) {
        croak qq{Missing required argument '$key' in constructor} unless $args{$key};
        $self->{$key} = $args{$key};
    }
    $self->{want_ref}         = $args{want_ref}         || 0;
    $self->{_calling_context} = $args{_calling_context} || 0;

    my $script_engine =
        $args{script_engine} ? $args{script_engine} : $self->{expression} =~ /\$_/ ? 'perl' : undef;
    $self->{script_engine} = $script_engine || 'PseudoJS';
    bless $self, $class;
    return $self;
}


sub evaluate_jsonpath {
    my ( $json_object, $expression, %args ) = @_;

    if ( !ref $json_object ) {
        try {
            $json_object = decode_json($json_object);
        }
        catch {
            croak qq{Unable to decode $json_object as JSON: $_};
        }
    }

    my $want_ref  = delete $args{want_ref}  || 0;
    my $want_path = delete $args{want_path} || 0;

    my $self = __PACKAGE__->new(
        root             => $json_object,
        expression       => $expression,
        _calling_context => wantarray ? 'ARRAY' : 'SCALAR',
        %args
    );
    return $self->evaluate( $expression, want_ref => $want_ref, want_path => $want_path );
}


sub evaluate {
    my ( $self, $expression, %args ) = @_;

    my $json_object = $self->{root};

    my $token_stream = [ tokenize($expression) ];
    shift @{$token_stream} if $token_stream->[0] eq $TOKEN_ROOT;
    shift @{$token_stream} if $token_stream->[0] eq $TOKEN_CHILD;

    if ( $args{want_path} ) {
        my %reftable = $self->_reftable_walker($json_object);
        my @refs = $self->_evaluate( $json_object, dclone $token_stream, 1 );

        my @paths;
        for my $ref (@refs) {
            my $refaddr = ref ${$ref} ? refaddr ${$ref} : refaddr $ref;
            push @paths, $reftable{$refaddr};
        }
        return @paths;
    }

    my @ret = $self->_evaluate( $json_object, $token_stream, $args{want_ref} );
    return @ret;
}

sub _reftable_walker {
    my ( $self, $json_object, $base_path ) = @_;

    $base_path   = defined $base_path   ? $base_path   : '$';
    $json_object = defined $json_object ? $json_object : $self->root;

    my @entries = ( refaddr $json_object => $base_path );

    if ( _arraylike($json_object) ) {
        for ( 0 .. $#{$json_object} ) {
            my $path = sprintf q{%s['%d']}, $base_path, $_;
            if ( ref $json_object->[$_] ) {
                push @entries, $self->_reftable_walker( $json_object->[$_], $path );
            }
            else {
                push @entries, refaddr \( $json_object->[$_] ) => $path;
            }
        }
    }
    elsif ( _hashlike($json_object) ) {
        for my $index ( keys %{$json_object} ) {
            my $path = sprintf q{%s['%s']}, $base_path, $index;
            if ( ref $json_object->{$index} ) {
                push @entries, $self->_reftable_walker( $json_object->{$index}, $path );
            }
            else {
                push @entries, refaddr \( $json_object->{$index} ) => $path;
            }
        }
    }
    return @entries;
}

sub _evaluate {    # This assumes that the token stream is syntactically valid
    my ( $self, $obj, $token_stream, $want_ref ) = @_;

    return unless ref $obj;

    $token_stream = defined $token_stream ? $token_stream : [];

    while ( defined( my $token = shift @{$token_stream} ) ) {
        next if $token eq $TOKEN_CURRENT;
        next if $token eq $TOKEN_CHILD;

        if ( $token eq $TOKEN_FILTER_OPEN ) {
            my $filter_expression = shift @{$token_stream};

            my $closing_token = shift @{$token_stream};
            assert( $closing_token eq $TOKEN_FILTER_SCRIPT_CLOSE, q{Closing token seen} ) if $ASSERT_ENABLE;

            # Find all indices matching the filter expression. This modifies $token_stream
            my @matching_indices = $self->_process_filter( $obj, $filter_expression );

            if ( !@{$token_stream} ) {
                my @got = map { _get( $obj, $_ ) } @matching_indices;
                return $want_ref ? @got : map { ${$_} } @got;
            }
            else {
                return map { $self->_evaluate( _get( $obj, $_ ), dclone($token_stream), $want_ref ) } @matching_indices;
            }
        }
        elsif ( $token eq $TOKEN_RECURSIVE )
        {    # Sweet Jesus, Pooh, that's not honey! You're eating Sweet Jesus, Pooh, that's not honey! You're eating...
            my $index = shift @{$token_stream};
            my @matched;
            if ( $index eq $TOKEN_FILTER_OPEN ) {
                my $filter_expression = shift @{$token_stream};

                my $closing_token = shift @{$token_stream};
                assert( $closing_token eq $TOKEN_FILTER_SCRIPT_CLOSE, q{Closing token seen} ) if $ASSERT_ENABLE;

                return $self->_filter_recursive( $obj, $filter_expression, $want_ref );
            }

            @matched = _match_recursive( $obj, $index, $want_ref );
            if ( !@{$token_stream} ) {
                return @matched;
            }
            return map { $self->_evaluate( $_, dclone($token_stream), $want_ref ) } @matched;
        }
        else {
            my $index;
            if ( $token eq $TOKEN_SUBSCRIPT_OPEN ) {
                $index = shift @{$token_stream};
                my $closing_token = shift @{$token_stream};
                assert $closing_token eq $TOKEN_SUBSCRIPT_CLOSE if $ASSERT_ENABLE;
            }
            else {
                $index = $token;
            }

            assert( !$OPERATORS{$index}, qq{"$index" is not an operator} ) if $index ne $TOKEN_ALL;
            assert( !ref $index,         q{Index is a scalar} )            if $ASSERT_ENABLE;

            my (@got) = _get( $obj, $index, create_key => $want_ref );    # This always returns a ref
            if ( !@{$token_stream} ) {
                return $want_ref ? @got : map { ${$_} } @got;
            }
            else {
                return map { $self->_evaluate( ${$_}, dclone($token_stream), $want_ref ) } @got;
            }
        }
    }
}

sub _process_filter {
    my ( $self, $obj, $filter_expression ) = @_;

    my @matching_indices;
    if ( $self->{script_engine} eq 'PseudoJS' ) {
        @matching_indices = $self->_process_pseudo_js( $obj, $filter_expression );
    }
    elsif ( $self->{script_engine} eq 'perl' ) {
        @matching_indices = $self->_process_perl( $obj, $filter_expression );
    }
    else {
        croak qq{Unsupported script engine "$self->{script_engine}"};
    }
    return @matching_indices;
}

# This _always_ has to return a ref so that when it's called from evaluate( ... , want_ref => 1)
# So that we can return a ref into the object (e.g. for use as an lvalue), even when the path points
# to a scalar (which will of course be copied).
#
# I.E.: for { foo => 'bar' }, we always want \( foo->{bar} ) so that
# JSON::Path->new('$.foo')->value($obj) = 'baz' works  like it oughtta.
sub _get {
    my ( $object, $index, %args ) = @_;

    assert( _hashlike($object) || _arraylike($object), 'Object is a hashref or an arrayref' ) if $ASSERT_ENABLE;

    my $create_key = $args{create_key};

    # When want_ref is passed to _evaluate(), it will return a reference to whatever was matched.
    # If what was matched is itself a ref (e.g. an arrayref), _evaluate() will return a ref of
    # type 'REF'.
    if ( ref $object eq 'REF' ) {
        $object = ${$object};
    }

    if ( $index eq $TOKEN_ALL ) {
        if ( _hashlike($object) ) {
            return map { \($_) } values %{$object};
        }
        else {
            return map { \($_) } @{$object};
        }
    }
    else {
        my @indices;
        if ( $index =~ /$TOKEN_ARRAY_SLICE/ ) {
            my $length = _hashlike($object) ? scalar values %{$object} : scalar @{$object};
            @indices = _slice( $index, $length );
        }
        elsif ( $index =~ /$TOKEN_UNION/ ) {
            @indices = split /$TOKEN_UNION/, $index;
        }
        else {
            @indices = ($index);
        }

        if ( _hashlike($object) ) {
            if ($create_key) {
                return map { \( $object->{$_} ) } @indices;
            }
            else {
                my @ret;
                for my $index (@indices) {
                    push @ret, \( $object->{$index} ) if exists $object->{$index};
                }
                return @ret;
            }
        }
        else {
            my @numeric_indices = grep { looks_like_number($_) } @indices;
            if ($create_key) {
                return map { \( $object->[$_] ) } @numeric_indices;
            }
            else {
                my @ret;
                for my $index (@numeric_indices) {
                    push @ret, \( $object->[$index] ) if exists $object->[$index];
                }
                return @ret;
            }
        }
    }
}

sub _indices {
    my $object = shift;
    return
          _hashlike($object)  ? keys %{$object}
        : _arraylike($object) ? ( 0 .. $#{$object} )
        : ();
}

sub _hashlike {
    my $object = shift;
    return ( ref $object eq 'HASH' || ( blessed $object && $object->can('typeof') && $object->typeof eq 'HASH' ) );
}

sub _arraylike {
    my $object = shift;
    return ( ref $object eq 'ARRAY' || ( blessed $object && $object->can('typeof') && $object->typeof eq 'ARRAY' ) );
}

sub _get_token {
    my $token_stream = shift;
    my $token        = shift @{$token_stream};
    return unless defined $token;

    if ( $token eq $TOKEN_SUBSCRIPT_OPEN ) {
        my @substream;
        my $close_seen;
        while ( defined( my $token = shift @{$token_stream} ) ) {
            if ( $token eq $TOKEN_SUBSCRIPT_CLOSE ) {
                $close_seen = 1;
                last;
            }
            push @substream, $token;
        }

        assert($close_seen) if $ASSERT_ENABLE;

        if ( grep { $_ eq $TOKEN_ARRAY_SLICE } @substream ) {

            # There are five valid cases:
            #
            # n:m   -> n:m:1
            # n:m:s -> n:m:s
            # :m    -> 0:m:1
            # ::s   -> 0:-1:s
            # n:    -> n:-1:1
            if ( $substream[0] eq $TOKEN_ARRAY_SLICE ) {
                unshift @substream, undef;
            }

            no warnings qw/uninitialized/;
            if ( $substream[2] eq $TOKEN_ARRAY_SLICE ) {
                @substream = ( @substream[ ( 0, 1 ) ], undef, @substream[ ( 2 .. $#substream ) ] );
            }
            use warnings qw/uninitialized/;

            my ( $start, $end, $step );
            $start = $substream[0] // 0;
            $end   = $substream[2] // -1;
            $step  = $substream[4] // 1;
            return { slice => [ $start, $end, $step ] };
        }
        elsif ( grep { $_ eq $TOKEN_UNION } @substream ) {
            my @union = grep { $_ ne $TOKEN_UNION } @substream;
            return { union => \@union };
        }

        return $substream[0];
    }
    return $token;
}

# See http://wiki.ecmascript.org/doku.php?id=proposals:slice_syntax
#
# in particular, for the slice [n:m], m is *one greater* than the last index to slice.
# This means that the slice [3:5] will return indices 3 and 4, but *not* 5.
sub _slice {
    my ( $index, $length ) = @_;

    my ( $start, $end, $step ) = split /$TOKEN_ARRAY_SLICE/, $index, 3;

    if ( !defined($start) || $start eq '' ) {
        $start = 0;
    }
    if ( !defined($end) || $end eq '' ) {
        $end = -1;
    }
    if ( !defined($step) || $step eq '' ) {
        $step = 1;
    }

    $start = ( $length - 1 ) if $start == -1;
    $end   = $length         if $end == -1;

    my @indices;
    if ( $step < 0 ) {
        @indices = grep { %_ % -$step == 0 } reverse( $start .. ( $end - 1 ) );
    }
    else {
        @indices = grep { $_ % $step == 0 } ( $start .. ( $end - 1 ) );
    }
    return @indices;
}

sub _match_recursive {
    my ( $obj, $index, $want_ref ) = @_;

    my @match;

    # Fix for RT #122529.
    #
    # Consider the expression "$..foo..bar", evaluated with respect to the JSON "{"foo":{"bar":"baz"}}".
    #
    # The first term to be evaluated in the expression is "$..foo". If want_ref is passed to evaluate(),
    # this will return a REF reference. In that case we must first dereference it to get the object that
    # we will evaluate "..bar" with respect to.
    if ( ref $obj eq 'REF' ) {
        $obj = ${$obj};
    }

    if ( _arraylike($obj) ) {
        if ( looks_like_number($index) && exists $obj->[$index] ) {
            push @match, $want_ref ? \( $obj->[$index] ) : $obj->[$index];
        }
        for ( 0 .. $#{$obj} ) {
            next unless ref $obj->[$_];
            push @match, _match_recursive( $obj->[$_], $index, $want_ref );
        }
    }
    elsif ( _hashlike($obj) ) {
        if ( exists $obj->{$index} ) {
            push @match, $want_ref ? \( $obj->{$index} ) : $obj->{$index};
        }
        for my $val ( values %{$obj} ) {
            next unless ref $val;
            push @match, _match_recursive( $val, $index, $want_ref );
        }
    }
    return @match;
}

sub _filter_recursive {
    my ( $self, $obj, $expression, $want_ref ) = @_;

    my @ret;

    # Evaluate the filter expression for the current object
    my @matching_indices = $self->_process_filter( $obj, $expression );
    for my $index (@matching_indices) {
        my ($got) = _get( $obj, $index );
        push @ret, $want_ref ? $got : ${$got};
    }

    # Evaluate the filter expression for any subordinate objects
    for my $index ( _indices($obj) ) {
        my ($got) = _get( $obj, $index );
        $got = ${$got};    # _get will always return a reference. We want the value, so dereference it
        next unless ref $got;
        push @ret, $self->_filter_recursive( $got, $expression, $want_ref );
    }

    return @ret;
}

sub _process_pseudo_js {
    my ( $self, $object, $expression ) = @_;

    my ( $lhs, $operator, $rhs ) = _parse_psuedojs_expression($expression);

    my (@token_stream) = tokenize($lhs);

    my $index;

    my @lhs;
    if ( _hashlike($object) ) {
        @lhs = map { $self->_evaluate( $_, [@token_stream] ) } values %{$object};
    }
    elsif ( _arraylike($object) ) {
        for my $value ( @{$object} ) {
            my ($got) = $self->_evaluate( $value, [@token_stream] );
            push @lhs, $got;
        }
    }

    # get indexes that pass compare()
    my @matching;
    for ( 0 .. $#lhs ) {
        my $val = $lhs[$_];
        push @matching, $_ if _compare( $operator, $val, $rhs );
    }

    return @matching;
}

sub _parse_psuedojs_expression {
    my $expression = shift;
    my @parts;

    my ( $lhs, $operator, $rhs );

    # The operator could be '=', '!=', '==', '===', '<=', or '>='
    if ( $expression =~ /$EQUAL_SIGN/ ) {
        my $position = index( $expression, '=' );
        if ( substr( $expression, $position + 1, 1 ) eq $EQUAL_SIGN ) {    # could be '==' or '==='
            if ( substr( $expression, $position + 2, 1 ) eq $EQUAL_SIGN ) {    # ===
                $operator = $TOKEN_TRIPLE_EQUAL;
            }
            else {
                $operator = $TOKEN_DOUBLE_EQUAL;
            }
        }
        else {
            my $preceding_char = substr( $expression, $position - 1, 1 );
            if ( $preceding_char eq $GREATER_THAN_SIGN ) {
                $operator = $TOKEN_GREATER_EQUAL;
            }
            elsif ( $preceding_char eq $LESS_THAN_SIGN ) {
                $operator = $TOKEN_LESS_EQUAL;
            }
            elsif ( $preceding_char eq $EXCLAMATION_MARK ) {
                $operator = $TOKEN_NOT_EQUAL;
            }
            else {
                $operator = $TOKEN_SINGLE_EQUAL;
            }
        }
        ( $lhs, $rhs ) = split /$operator/, $expression, 2;
    }
    else {
        for ( grep { $OPERATORS{$_} eq $OPERATOR_TYPE_COMPARISON } keys %OPERATORS ) {
            next if /$EQUAL_SIGN/;
            if ( $expression =~ /$_/ ) {
                ( $lhs, $rhs ) = split /$_/, $expression, 2;
                $operator = $_;
                last;
            }
        }
    }

    # FIXME: RHS is assumed to be a single value. This isn't necessarily a safe assumption.
    if ($operator) {
        $rhs = _normalize( $rhs || '' );
        $lhs = _normalize($lhs);
    }
    else {
        $operator = $OPERATOR_IS_TRUE;
        $lhs      = $expression;
    }
    return ( $lhs, $operator, $rhs );
}

sub _normalize {
    my $string = shift;

    # NB: Stripping spaces *before* stripping quotes allows the caller to quote spaces in an index.
    # So an index of 'foo ' will be correctly normalized as 'foo', but '"foo "' will normalize to 'foo '.
    $string =~ s/\s+$//;                # trim trailing spaces
    $string =~ s/^\s+//;                # trim leading spaces
    $string =~ s/^['"](.+)['"]$/$1/;    # Strip quotes from index
    return $string;
}

sub _process_perl {
    my ( $self, $object, $code ) = @_;

    my $cpt = Safe->new;
    $cpt->permit_only( ':base_core', qw/padsv padav padhv padany rv2gv/ );
    ${ $cpt->varglob('root') } = dclone( $self->{root} );

    my @matching;
    if ( _hashlike($object) ) {
        for my $index ( keys %{$object} ) {
            local $_ = $object->{$index};
            my $ret = $cpt->reval($code);
            croak qq{Error in filter: $@} if $@;
            push @matching, $index if $ret;
        }
    }
    else {
        for my $index ( 0 .. $#{$object} ) {
            local $_ = $object->[$index];
            my $ret = $cpt->reval($code);
            croak qq{Error in filter: $@} if $@;
            push @matching, $index if $ret;
        }
    }
    return @matching;
}

sub _compare {
    my ( $operator, $lhs, $rhs ) = @_;

    no warnings qw/uninitialized/;
    if ( $operator eq $OPERATOR_IS_TRUE ) {
        return $lhs ? 1 : 0;
    }

    my $use_numeric = looks_like_number($lhs) && looks_like_number($rhs);

    if ( $operator eq '=' || $operator eq '==' || $operator eq '===' ) {
        return $use_numeric ? ( $lhs == $rhs ) : $lhs eq $rhs;
    }
    if ( $operator eq '<' ) {
        return $use_numeric ? ( $lhs < $rhs ) : $lhs lt $rhs;
    }
    if ( $operator eq '>' ) {
        return $use_numeric ? ( $lhs > $rhs ) : $lhs gt $rhs;
    }
    if ( $operator eq '<=' ) {
        return $use_numeric ? ( $lhs <= $rhs ) : $lhs le $rhs;
    }
    if ( $operator eq '>=' ) {
        return $use_numeric ? ( $lhs >= $rhs ) : $lhs ge $rhs;
    }
    if ( $operator eq '!=' || $operator eq '!==' ) {
        return $use_numeric ? ( $lhs != $rhs ) : $lhs ne $rhs;
    }
    use warnings qw/uninitialized/;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Path::Evaluator - A module that recursively evaluates JSONPath expressions with native support for Javascript-style filters

=head1 VERSION

version 0.431

=head1 SYNOPSIS

    use JSON::MaybeXS qw/decode_json/; # Or whatever JSON thing you like. I won't judge.
    use JSON::Path::Evaluator qw/evaluate_jsonpath/;

    my $obj = decode_json(q(
        { "store": {
            "book": [
              { "category": "reference",
                "author": "Nigel Rees",
                "title": "Sayings of the Century",
                "price": 8.95
              },
              { "category": "fiction",
                "author": "Evelyn Waugh",
                "title": "Sword of Honour",
                "price": 12.99
              },
              { "category": "fiction",
                "author": "Herman Melville",
                "title": "Moby Dick",
                "isbn": "0-553-21311-3",
                "price": 8.99
              },
              { "category": "fiction",
                "author": "J. R. R. Tolkien",
                "title": "The Lord of the Rings",
                "isbn": "0-395-19395-8",
                "price": 22.99
              }
            ],
            "bicycle": {
              "color": "red",
              "price": 19.95
            }
          }
        }
    ));

    my @fiction = evaluate_jsonpath( $obj, q{$..book[?(@.category == "fiction")]});
    # @fiction = (
    #     {   category => "fiction",
    #         author   => "Evelyn Waugh",
    #         title    => "Sword of Honour",
    #         price    => 12.99
    #     },
    #     {   category => "fiction",
    #         author   => "Herman Melville",
    #         title    => "Moby Dick",
    #         isbn     => "0-553-21311-3",
    #         price    => 8.99
    #     },
    #     {   category => "fiction",
    #         author   => "J. R. R. Tolkien",
    #         title    => "The Lord of the Rings",
    #         isbn     => "0-395-19395-8",
    #         price    => 22.99
    #     }
    # );

=head1 METHODS

=head2 new

Constructor for the object-oriented interface to this module. Arguments may be specified in a hash or a hashref.

Args:

=over 4

=item root

Required. JSONPath expressions will be evaluated with respect to this. Must be a hashref or an arrayref.

=item expression

JSONPath expression to evaluate

=item want_ref

Set this to true if you want a reference to the thing the JSONPath expression matches, rather than the value
of said thing. Useful if you want to use this to modify hashrefs / arrayrefs in place.

=item script_engine

Defaults to "PseudoJS", which is my clever name for a subset of Javascript-B<like> operators for Boolean expressions.
See L</"Filtering with PseudoJS">. You may also specify "perl" here, in which case the filter will be treated as Perl code.
See L</"Filtering with Perl">.

=back

=head2 evaluate_jsonpath

Evaluate a JSONPath expression on the given object. CLASS METHOD.

Args:

=over 4

=item $json_object

JSON object for which the expression will be evaluated. If this is a scalar, it will be treated
as a JSON string and parsed into the appropriate Perl data structure first.

=item $expression

JSONPath expression to evaluate on the object.

=item %args

Misc. arguments to this method. Currently the only supported argument is 'want_ref' - set this to
true in order to return a reference to the matched portion of the object, rather than the value
of that matched portion.

=back

=head2 evaluate

Evaluate a JSONPath expression on the object passed to the constructor.  OBJECT METHOD.

Args:

=over 4

=item $expression

JSONPath expression to evaluate on the object.

=item %args

Misc. arguments to this method.

Supported keys:

=over 4

=item want_ref

Set this to true in order to return a reference to the matched portion of the object, rather than
the value of the matched portion.

=item want_path

Set this to true in order to return the canonical path(s) to the elements matching the expression.

=back

=back

=head1 JSONPath

This code implements the JSONPath specification at L<JSONPath specification|http://goessner.net/articles/JsonPath/>.

JSONPath is a tool, similar to XPath for XML, that allows one to construct queries to pick out parts of a JSON structure.

=head2 JSONPath Expressions

From the spec: "JSONPath expressions always refer to a JSON structure in the same way as XPath
expression are used in combination with an XML document. Since a JSON structure is usually anonymous
and doesn't necessarily have a "root member object" JSONPath assumes the abstract name $ assigned
to the outer level object."

Note that in JSONPath square brackets operate on the object or array addressed by the previous path fragment. Indices always start by 0.

=head2 Operators

=over 4

=item $

the root object/element

=item @

the current object/element

=item . or []

child operator

=item ..

recursive descent. JSONPath borrows this syntax from E4X.

=item '*' (literal asterisk)

wildcard. All objects/elements regardless their names.

=item []

subscript operator. XPath uses it to iterate over element collections and for predicates. In Javascript and JSON it is the native array operator.

=item [,]

Union operator in XPath results in a combination of node sets. JSONPath allows alternate names or array indices as a set.

=item [start:end:step]

array slice operator borrowed from ES4.

=item ?()

applies a filter (script) expression. See L<Filtering>.

=item ()

script expression, using the underlying script engine. Handled the same as "?()".

=back

=head2 Filtering

Filters are the most powerful feature of JSONPath. They allow the caller to retrieve data
conditionally, similar to Perl's C<grep> operator.

Filters are specified using the '?(' token, terminated by ')'. Anything in between these
two tokens is treated as a filter expression. Filter expressions must return a boolean value.

=head3 Filtering with PseudoJS

By default, this module uses a limited subset of Javascript expressions to evaluate filters. Using
this script engine, specify the filter in the form "<LHS> <operator> <RHS>", or "<LHS>". This latter
case will be evaluated as "<LHS> is true".

<LHS> must be a valid JSONPath expression. <RHS> must be a scalar value; comparison of two JSONPath
expressions is not supported at this time.

Example:

Using the JSON in L<SYNOPSIS> above and the JSONPath expression C<$..book[?(@.category == "fiction")]>,
the filter expression C<@.category == "fiction"> will match all values having a value of "fiction" for
the key "category".

=head2 Filtering with Perl

When the script engine is set to "perl", filter
Using the JSON in L<SYNOPSIS> above and the JSONPath expression C<$..book[?(@.category == "fiction")]>,

This is understandably dangerous. Although steps have been taken (Perl expressions are evaluated using
L<Safe> and a limited set of permitted opcodes) to reduce the risk, callers should be aware of the risk
when using filters.

When filtering in Perl, there are some differences between the JSONPath spec and this implementation.

=over 4

=item *

JSONPath uses the token '$' to refer to the root node. As this is not valid Perl, this should be

replaced with '$root' in a filter expression.

=item *

JSONPath uses the token '@' to refer to the current node. This is also not valid Perl. Use '$_'

instead.

=back

=head1 AUTHOR

Kit Peters <popefelix@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Kit Peters.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
