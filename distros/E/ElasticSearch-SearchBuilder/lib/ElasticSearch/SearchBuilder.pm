package ElasticSearch::SearchBuilder;

use Carp;
use strict;
use warnings;
use Scalar::Util ();

our $VERSION = '0.19';

my %SPECIAL_OPS = (
    query => {
        '='   => [ 'match',               0 ],
        '=='  => [ 'match_phrase',        0 ],
        '!='  => [ 'match',               1 ],
        '<>'  => [ 'match',               1 ],
        '>'   => [ 'range',               0 ],
        '>='  => [ 'range',               0 ],
        '<'   => [ 'range',               0 ],
        '<='  => [ 'range',               0 ],
        'gt'  => [ 'range',               0 ],
        'lt'  => [ 'range',               0 ],
        'gte' => [ 'range',               0 ],
        'lte' => [ 'range',               0 ],
        '^'   => [ 'match_phrase_prefix', 0 ],
        '*'   => [ 'wildcard',            0 ],
    },
    filter => {
        '='           => [ 'terms',   0 ],
        '!='          => [ 'terms',   1 ],
        '<>'          => [ 'terms',   1 ],
        '>'           => [ 'range',   0 ],
        '>='          => [ 'range',   0 ],
        '<'           => [ 'range',   0 ],
        '<='          => [ 'range',   0 ],
        'gt'          => [ 'range',   0 ],
        'lt'          => [ 'range',   0 ],
        'gte'         => [ 'range',   0 ],
        'lte'         => [ 'range',   0 ],
        '^'           => [ 'prefix',  0 ],
        'exists'      => [ 'exists',  0 ],
        'not_exists'  => [ 'exists',  0 ],
        'missing'     => [ 'missing', 0 ],
        'not_missing' => [ 'missing', 1 ],
    }
);

my %RANGE_MAP = (
    '>'  => 'gt',
    '<'  => 'lt',
    '>=' => 'gte',
    '<=' => 'lte'
);

#===================================
sub new {
#===================================
    my $proto = shift;
    my $class = ref($proto) || $proto;
    return bless {}, $class;
}

#===================================
sub query  { shift->_top_recurse( 'query',  @_ ) }
sub filter { shift->_top_recurse( 'filter', @_ ) }
#===================================

#======================================================================
# top-level
#======================================================================

#===================================
sub _top_ARRAYREF {
#===================================
    my ( $self, $type, $params, $logic ) = @_;
    $logic ||= 'or';

    my @args = @$params;
    my @clauses;

    while (@args) {
        my $el     = shift @args;
        my $clause = $self->_SWITCH_refkind(
            'ARRAYREFs',
            $el,
            {   ARRAYREF => sub {
                    $self->_recurse( $type, $el ) if @$el;
                },
                HASHREF => sub {
                    $self->_recurse( $type, $el, 'and' ) if %$el;
                },
                HASHREFREF => sub {$$el},
                SCALAR     => sub {
                    $self->_recurse( $type, { $el => shift(@args) } );
                },
                UNDEF => sub { croak "UNDEF in arrayref not supported" },
            }
        );
        push @clauses, $clause if $clause;
    }
    return $self->_join_clauses( $type, $logic, \@clauses );
}

#===================================
sub _top_HASHREF {
#===================================
    my ( $self, $type, $params ) = @_;

    my ( @clauses, $filter );
    $params = {%$params};
    for my $k ( sort keys %$params ) {
        my $v = $params->{$k};

        my $clause;

        # ($k => $v) is either a special unary op or a regular hashpair
        if ( $k =~ /^-./ ) {
            my $op = substr $k, 1;
            my $not = $op =~ s/^not_//;
            croak "Invalid op 'not_$op'"
                if $not and $op eq 'cache' || $op eq 'nocache';

            if ( $op eq 'filter' and $type eq 'query' ) {
                $filter = $self->_recurse( 'filter', $v );
                $filter = $self->_negate_clause( 'filter', $filter )
                    if $not;
                next;
            }

            my $handler = $self->can("_${type}_unary_$op")
                or croak "Unknown $type op '$op'";

            $clause = $handler->( $self, $v );
            $clause = $self->_negate_clause( $type, $clause )
                if $not;
        }
        else {
            my $method = $self->_METHOD_FOR_refkind( "_hashpair", $v );
            $clause = $self->$method( $type, $k, $v );
        }
        push @clauses, $clause if $clause;
    }

    my $clause = $self->_join_clauses( $type, 'and', \@clauses );

    return $clause unless $filter;
    return $clause
        ? { filtered => { query => $clause, filter => $filter } }
        : { constant_score => { filter => $filter } };
}

#===================================
sub _top_SCALAR {
#===================================
    my ( $self, $type, $params ) = @_;
    return $type eq 'query'
        ? { match => { _all => $params } }
        : { term => { _all => $params } };
}

#===================================
sub _top_HASHREFREF { return ${ $_[2] } }
sub _top_SCALARREF  { return ${ $_[2] } }
sub _top_UNDEF      {return}
#===================================

#======================================================================
# HASH PAIRS
#======================================================================

#===================================
sub _hashpair_ARRAYREF {
#===================================
    my ( $self, $type, $k, $v ) = @_;

    my @v = @$v ? @$v : [undef];

    # put apart first element if it is an operator (-and, -or)
    my $op
        = $v[0] && ( $v[0] eq '-and' || $v[0] eq '-or' )
        ? shift @v
        : '';
    my $logic = $op ? substr( $op, 1 ) : '';
    my @distributed = map { +{ $k => $_ } } @v;

    # if all values are defined scalars then try to use
    # a terms query/filter

    if ( $logic ne 'and' and $type eq 'filter' ) {
        my $scalars = 0;
        for (@v) {
            $scalars++ if defined and !ref;
        }
        return $self->_filter_field_terms( $k, 'terms', \@v )
            if $scalars == @v;

    }
    unshift @distributed, $op
        if $op;

    return $self->_recurse( $type, \@distributed, $logic );
}

#===================================
sub _hashpair_HASHREF {
#===================================
    my ( $self, $type, $k, $v, $logic ) = @_;
    $logic ||= 'and';

    my @clauses;

    for my $orig_op ( sort keys %$v ) {
        my $clause;

        my $val = $v->{$orig_op};
        my $op  = $orig_op;
        $op =~ s/^-//;

        if ( my $hash_op = $SPECIAL_OPS{$type}{$op} ) {
            my ( $handler, $not ) = @$hash_op;
            $handler = "_${type}_field_$handler";
            $clause  = $self->$handler( $k, $op, $val );
            $clause  = $self->_negate_clause( $type, $clause )
                if $not;
        }
        else {
            my $not = ( $op =~ s/^not_// );
            my $handler = "_${type}_field_$op";
            croak "Unknown $type operator '$op'"
                unless $self->can($handler);

            $clause = $self->$handler( $k, $op, $val );
            $clause = $self->_negate_clause( $type, $clause )
                if $not;
        }
        push @clauses, $clause;
    }

    return $self->_join_clauses( $type, $logic, \@clauses );
}

#===================================
sub _hashpair_SCALARREF {
#===================================
    my ( $self, $type, $k, $v ) = @_;
    return { $k => $$v };
}

#===================================
sub _hashpair_SCALAR {
#===================================
    my ( $self, $type, $k, $v ) = @_;
    return $type eq 'query'
        ? { match => { $k => $v } }
        : { term => { $k => $v } };
}

#===================================
sub _hashpair_UNDEF {
#===================================
    my ( $self, $type, $k, $v ) = @_;
    return { missing => { field => $k } }
        if $type eq 'filter';
    croak "$k => UNDEF not a supported query op";
}

#======================================================================
# CLAUSE UTILS
#======================================================================

#===================================
sub _negate_clause {
#===================================
    my ( $self, $type, $clause ) = @_;
    return $type eq 'filter'
        ? { not => { filter => $clause } }
        : $self->_merge_bool_queries( 'must_not', [$clause] );
}

#===================================
sub _join_clauses {
#===================================
    my ( $self, $type, $logic, $clauses ) = @_;

    return if @$clauses == 0;
    return $clauses->[0] if @$clauses == 1;

    if ( $logic eq 'and' ) {
        $clauses = $self->_merge_range_clauses($clauses);
        return $clauses->[0] if @$clauses == 1;
    }
    if ( $type eq 'query' ) {
        my $op = $logic eq 'and' ? 'must' : 'should';
        return $self->_merge_bool_queries( $op, $clauses );

    }
    return { $logic => $clauses };
}

#===================================
sub _merge_bool_queries {
#===================================
    my $self    = shift;
    my $op      = shift;
    my $queries = shift;
    my %bool;

    for my $query (@$queries) {
        my ( $type, $clauses ) = %$query;
        if ( $type eq 'bool' ) {
            $clauses = {%$clauses};
            my ( $must, $should, $not )
                = map { ref $_ eq 'HASH' ? [$_] : $_ }
                delete @{$clauses}{qw(must should must_not)};
            if ( !keys %$clauses ) {
                if ( $op eq 'must' ) {
                    push @{ $bool{must} },     @$must if $must;
                    push @{ $bool{must_not} }, @$not  if $not;
                    next unless $should;
                    if ( @$should == 1 ) {
                        push @{ $bool{must} }, $should->[0];
                        next;
                    }
                    elsif ( @$queries == 1 ) {
                        push @{ $bool{should} }, @$should;
                        next;
                    }
                    delete @{ $query->{bool} }{ 'must', 'must_not' };
                }
                elsif ( $op eq 'should' ) {
                    unless ($not) {
                        if ($should) {
                            if ( !$must ) {
                                push @{ $bool{should} }, @$should;
                                next;
                            }
                        }
                        elsif ( $must and @$must == 1 ) {
                            push @{ $bool{should} }, $must->[0];
                            next;
                        }
                    }
                }
                else {
                    if ($must) {
                        if ( @$must == 1 and !$should and !$not ) {
                            push @{ $bool{must_not} }, @$must;
                            next;
                        }
                    }
                    else {
                        if ($should) {
                            if ( !$not ) {
                                push @{ $bool{must_not} }, @$should;
                                next;
                            }
                        }
                        elsif ($not) {
                            push @{ $bool{must} }, @$not;
                            next;
                        }
                    }
                }
            }
        }
        push @{ $bool{$op} }, $query;
    }
    if ( keys %bool == 1 ) {
        my ( $k, $v ) = %bool;
        return $v->[0]
            if $k ne 'must_not' and @$v == 1;
    }

    return { bool => \%bool };
}

my %Range_Clauses = (
    range         => 1,
    numeric_range => 1,
);

#===================================
sub _merge_range_clauses {
#===================================
    my $self    = shift;
    my $clauses = shift;
    my ( @new, %merge );

    for (@$clauses) {
        my ($type) = keys %$_;

        if ( $Range_Clauses{$type} and not exists $_->{$type}{_cache} ) {
            my ( $field, $constraint ) = %{ $_->{$type} };

            for my $op ( keys %$constraint ) {
                if ( defined $merge{$type}{$field}{$op} ) {
                    croak "Duplicate '$type:$op' exists "
                        . "for field '$field', with values: "
                        . $merge{$type}{$field}{$op} . ' and '
                        . $constraint->{$op};
                }

                $merge{$type}{$field}{$op} = $constraint->{$op};
            }
        }
        else { push @new, $_ }
    }

    for my $type ( keys %merge ) {
        for my $field ( keys %{ $merge{$type} } ) {
            push @new, { $type => { $field => $merge{$type}{$field} } };
        }
    }
    return \@new;
}

#======================================================================
# UNARY OPS
#======================================================================
# Shared query/filter unary ops
#======================================================================

#===================================
sub _query_unary_all { shift->_unary_all( 'query', shift ) }
sub _query_unary_or  { shift->_unary_and( 'query', shift, 'or' ) }
sub _query_unary_and { shift->_unary_and( 'query', shift, 'and' ) }
sub _query_unary_not { shift->_unary_not( 'query', shift, ) }
sub _query_unary_ids { shift->_unary_ids( 'query', shift ) }
sub _query_unary_has_child { shift->_unary_child( 'query', shift ) }
sub _query_unary_has_parent { shift->_unary_parent( 'query', shift ) }
#===================================

#===================================
sub _filter_unary_all { shift->_unary_all( 'filter', shift ) }
sub _filter_unary_or  { shift->_unary_and( 'filter', shift, 'or' ) }
sub _filter_unary_and { shift->_unary_and( 'filter', shift, 'and' ) }
sub _filter_unary_not { shift->_unary_not( 'filter', shift, ) }
sub _filter_unary_ids { shift->_unary_ids( 'filter', shift ) }
sub _filter_unary_has_child { shift->_unary_child( 'filter', shift ) }
sub _filter_unary_has_parent { shift->_unary_parent( 'filter', shift ) }
#===================================

#===================================
sub _unary_all {
#===================================
    my ( $self, $type, $v ) = @_;
    $v = {} unless $v and ref $v eq 'HASH';
    $self->_SWITCH_refkind(
        "Unary -all",
        $v,
        {   HASHREF => sub {
                my $p = $self->_hash_params( 'all', $v, [],
                    $type eq 'query' ? [ 'boost', 'norms_field' ] : [] );
                return { match_all => $p };
            },
        }
    );
}

#===================================
sub _unary_and {
#===================================
    my ( $self, $type, $v, $op ) = @_;
    $self->_SWITCH_refkind(
        "Unary -$op",
        $v,
        {   ARRAYREF => sub { return $self->_top_ARRAYREF( $type, $v, $op ) },
            HASHREF => sub {
                return $op eq 'or'
                    ? $self->_top_ARRAYREF( $type,
                    [ map { $_ => $v->{$_} } ( sort keys %$v ) ], $op )
                    : $self->_top_HASHREF( $type, $v );
            },

            SCALAR => sub {
                croak "$type -$op => '$v' makes little sense, "
                    . "use filter -exists => '$v' instead";
            },
            UNDEF => sub { croak "$type -$op => undef not supported" },
        }
    );
}

#===================================
sub _unary_not {
#===================================
    my ( $self, $type, $v ) = @_;
    my $clause = $self->_SWITCH_refkind(
        "Unary -not",
        $v,
        {   ARRAYREF => sub { $self->_top_ARRAYREF( $type, $v ) },
            HASHREF  => sub { $self->_top_HASHREF( $type,  $v ) },
            SCALAR   => sub {
                croak "$type -not => '$v' makes little sense, "
                    . "use filter -missing => '$v' instead";
            },
            UNDEF => sub { croak "$type -not => undef not supported" },
        }
    ) or return;

    return $self->_negate_clause( $type, $clause );
}

#===================================
sub _unary_ids {
#===================================
    my ( $self, $type, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary -ids",
        $v,
        {   SCALAR   => sub { return { ids => { values => [$v] } } },
            ARRAYREF => sub {
                return unless @$v;
                return { ids => { values => $v } };
            },
            HASHREF => sub {
                my $p = $self->_hash_params( 'ids', $v, ['values'],
                    $type eq 'query' ? [ 'type', 'boost' ] : ['type'] );
                $p->{values} = [ $p->{values} ] unless ref $p->{values};
                return { ids => $p };
            },
        }
    );
}

#===================================
sub _query_unary_top_children {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary query -top_children",
        $v,
        {   HASHREF => sub {
                my $p = $self->_hash_params(
                    'top_children', $v,
                    [ 'query', 'type' ],
                    [qw(_scope score factor incremental_factor)]
                );
                $p->{query} = $self->_recurse( 'query', $p->{query} );
                return { top_children => $p };
            },
        }
    );
}

#===================================
sub _unary_child {
#===================================
    my ( $self, $type, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary $type -has_child",
        $v,
        {   HASHREF => sub {
                my $p = $self->_hash_params(
                    'has_child', $v,
                    [ 'query', 'type' ],
                    $type eq 'query' ? [ 'boost', '_scope', 'score_type' ] : ['_scope']
                );
                $p->{query} = $self->_recurse( 'query', $p->{query} );
                return { has_child => $p };
            },
        }
    );
}

#===================================
sub _unary_parent {
#===================================
    my ( $self, $type, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary $type -has_parent",
        $v,
        {   HASHREF => sub {
                my $p = $self->_hash_params(
                    'has_parent', $v,
                    [ 'query', 'type' ],
                    $type eq 'query' ? [ 'boost', '_scope', 'score_type' ] : ['_scope']
                );
                $p->{query} = $self->_recurse( 'query', $p->{query} );
                return { has_parent => $p };
            },
        }
    );
}

#======================================================================
# Query only unary ops
#======================================================================

#===================================
sub _query_unary_match {
#===================================
    my ( $self, $v, $op ) = @_;
    $op ||= 'match';
    return $self->_SWITCH_refkind(
        "Unary query -$op",
        $v,
        {   HASHREF => sub {
                my $p = $self->_hash_params(
                    $op, $v,
                    [ 'query', 'fields' ],
                    [ qw(
                            use_dis_max tie_breaker
                            boost operator analyzer fuzziness fuzzy_rewrite
                            rewrite max_expansions minimum_should_match
                            prefix_length lenient slop type)
                    ]
                );
                return { "multi_match" => $p };
            },
        }
    );
}

#===================================
sub _query_unary_qs { shift->_query_unary_query_string( @_, 'qs' ) }
#===================================

#===================================
sub _query_unary_query_string {
#===================================
    my ( $self, $v, $op ) = @_;
    $op ||= 'query_string';
    return $self->_SWITCH_refkind(
        "Unary query -$op",
        $v,
        {   SCALAR  => sub { return { query_string => { query => $v } } },
            HASHREF => sub {
                my $p = $self->_hash_params(
                    'query_string',
                    $v,
                    ['query'],
                    [   qw(allow_leading_wildcard analyzer analyze_wildcard
                            auto_generate_phrase_queries boost
                            default_operator enable_position_increments
                            fields fuzzy_min_sim fuzzy_prefix_length
                            fuzzy_rewrite fuzzy_max_expansions
                            lowercase_expanded_terms phrase_slop
                            tie_breaker use_dis_max lenient
                            quote_analyzer quote_field_suffix
                            minimum_should_match )
                    ]
                );
                return { query_string => $p };
            },
        }
    );
}

#===================================
sub _query_unary_flt {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary query -flt",
        $v,
        {   SCALAR  => sub { return { flt => { like_text => $v } } },
            HASHREF => sub {
                my $p = $self->_hash_params(
                    'flt', $v,
                    ['like_text'],
                    [   qw(analyzer boost fields ignore_tf max_query_terms
                            min_similarity prefix_length )
                    ]
                );
                return { flt => $p };
            },
        }
    );
}

#===================================
sub _query_unary_mlt {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary query -mlt",
        $v,
        {   SCALAR  => sub { return { mlt => { like_text => $v } } },
            HASHREF => sub {
                my $p = $self->_hash_params(
                    'mlt', $v,
                    ['like_text'],
                    [   qw(analyzer boost boost_terms fields
                            max_doc_freq max_query_terms max_word_len
                            min_doc_freq min_term_freq min_word_len
                            percent_terms_to_match stop_words )
                    ]
                );
                return { mlt => $p };
            },
        }
    );
}

#===================================
sub _query_unary_custom_score {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary query -custom_score",
        $v,
        {   HASHREF => sub {
                my $p = $self->_hash_params(
                    'custom_score', $v,
                    [ 'query',  'script' ],
                    [ 'params', 'lang' ]
                );
                $p->{query} = $self->_recurse( 'query', $p->{query} );
                return { custom_score => $p };
            },
        }
    );
}

#===================================
sub _query_unary_constant_score {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary query -constant_score",
        $v,
        {   HASHREF => sub {
                my $p = $self->_hash_params(
                    'constant_score', $v,
                    [ 'query' ],
                    [ 'boost' ]
                );
                $p->{query} = $self->_recurse( 'query', $p->{query} );
                return { constant_score => $p };
            },
        }
    );
}



#===================================
sub _query_unary_custom_filters_score {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary query -custom_filters_score",
        $v,
        {   HASHREF => sub {
                my $p = $self->_hash_params(
                    'custom_filters_score', $v,
                    [ 'query',      'filters' ],
                    [ 'score_mode', 'max_boost' ]
                );
                $p->{query} = $self->_recurse( 'query', $p->{query} );
                my @raw
                    = ref $p->{filters} eq 'ARRAY'
                    ? @{ $p->{filters} }
                    : $p->{filters};
                my @filters;

                for my $pf (@raw) {
                    $pf = $self->_hash_params( 'custom_filters_score.filters',
                        $pf, ['filter'],
                        [ 'boost', 'script', 'params', 'lang' ] );
                    $pf->{filter}
                        = $self->_recurse( 'filter', $pf->{filter} );
                    push @filters, $pf;
                }
                $p->{filters} = \@filters;
                my $filters = $p->{filters};

                return { custom_filters_score => $p };
            },
        }
    );
}

#===================================
sub _query_unary_dismax { shift->_query_unary_dis_max(@_) }
#===================================
#===================================
sub _query_unary_dis_max {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary query -dis_max",
        $v,
        {   ARRAYREF => sub {
                return $self->_query_unary_dis_max( { queries => $v } );
            },
            HASHREF => sub {
                my $p = $self->_hash_params( 'dis_max', $v, ['queries'],
                    [ 'boost', 'tie_breaker' ] );
                $p = $self->_multi_queries( $p, 'queries' );
                return { dis_max => $p };
            },
        }
    );
}

#===================================
sub _query_unary_bool {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary query -bool",
        $v,
        {   HASHREF => sub {
                my $p = $self->_hash_params(
                    'bool', $v,
                    [],
                    [   qw(must should must_not boost
                            minimum_number_should_match disable_coord)
                    ]
                );
                $p = $self->_multi_queries( $p, 'must', 'should',
                    'must_not' );
                return { bool => $p };
            },
        }
    );
}

#===================================
sub _query_unary_boosting {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary query -boosting",
        $v,
        {   HASHREF => sub {
                my $p = $self->_hash_params( 'boosting', $v,
                    [ 'positive', 'negative', 'negative_boost' ] );
                $p->{$_} = $self->_recurse( 'query', $p->{$_} )
                    for 'positive', 'negative';
                return { boosting => $p };
            },
        }
    );
}

#===================================
sub _query_unary_custom_boost {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary query -custom_boost",
        $v,
        {   HASHREF => sub {
                my $p = $self->_hash_params( 'custom_boost', $v,
                    [ 'query', 'boost_factor' ] );
                $p->{query} = $self->_recurse( 'query', $p->{query} );
                return { custom_boost_factor => $p };
            },
        }
    );
}

#===================================
sub _query_unary_indices {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary query -indices",
        $v,
        {   HASHREF => sub {
                my $p
                    = $self->_hash_params( 'indices', $v,
                    [ 'indices', 'query' ],
                    ['no_match_query'] );
                $p->{indices} = [ $p->{indices} ]
                    unless ref $p->{indices} eq 'ARRAY';
                $p->{query} = $self->_recurse( 'query', $p->{query} );
                my $no = delete $p->{no_match_query};
                if ($no) {
                    $p->{no_match_query}
                        = $no =~ /^(?:all|none)$/
                        ? $no
                        : $self->_recurse( 'query', $no );
                }
                return { indices => $p };
            },
        }
    );
}

#===================================
sub _query_unary_nested {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary query -nested",
        $v,
        {   HASHREF => sub {
                my $p = $self->_hash_params(
                    'nested', $v,
                    [ 'path',       'query' ],
                    [ 'score_mode', '_scope' ]
                );
                $p->{query} = $self->_recurse( 'query', $p->{query} );
                return { nested => $p };
            },
        }
    );
}

#======================================================================
# Filter only unary ops
#======================================================================

#===================================
sub _filter_unary_missing {
#===================================
    my ( $self, $v ) = @_;

    return $self->_SWITCH_refkind(
        "Unary filter -missing",
        $v,
        {   SCALAR  => sub { return { missing => { field => $v } } },
            HASHREF => sub {
                my $p = $self->_hash_params( 'missing', $v, ['field'],
                    [ 'existence', 'null_value' ] );
                return { missing => $p };
            },
        },
    );
}

#===================================
sub _filter_unary_exists {
#===================================
    my ( $self, $v, $op ) = @_;
    $op ||= 'exists';

    return $self->_SWITCH_refkind(
        "Unary filter -$op",
        $v,
        {   SCALAR => sub { return { $op => { field => $v } } }
        }
    );
}

#===================================
sub _filter_unary_indices {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary filter -indices",
        $v,
        {   HASHREF => sub {
                my $p
                    = $self->_hash_params( 'indices', $v,
                    [ 'indices', 'filter' ],
                    ['no_match_filter'] );
                $p->{indices} = [ $p->{indices} ]
                    unless ref $p->{indices} eq 'ARRAY';
                $p->{filter} = $self->_recurse( 'filter', $p->{filter} );
                my $no = delete $p->{no_match_filter};
                if ($no) {
                    $p->{no_match_filter}
                        = $no =~ /^(?:all|none)$/
                        ? $no
                        : $self->_recurse( 'filter', $no );
                }
                return { indices => $p };
            },
        }
    );
}

#===================================
sub _filter_unary_type {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary filter -type",
        $v,
        {   SCALAR   => sub { return { type => { value => $v } } },
            ARRAYREF => sub {
                my @clauses = map { +{ type => { value => $_ } } } @$v;
                return $self->_join_clauses( 'filter', 'or', \@clauses );
            },
        }
    );
}

#===================================
sub _filter_unary_limit {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary filter -limit",
        $v,
        {   SCALAR => sub { return { limit => { value => $v } } }
        }
    );
}

#===================================
sub _filter_unary_script {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary filter -script",
        $v,
        {   SCALAR  => sub { return { script => { script => $v } } },
            HASHREF => sub {
                my $p = $self->_hash_params( 'script', $v, ['script'],
                    [ 'params', 'lang' ] );
                return { script => $p };
            },
        }
    );
}

#===================================
sub _filter_unary_nested {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Filter query -nested",
        $v,
        {   HASHREF => sub {
                my $p = $self->_hash_params(
                    'nested', $v,
                    [ 'path', 'filter' ],
                    [ '_cache', '_name', '_cache_key' ],
                );
                $p->{filter} = $self->_recurse( 'filter', $p->{filter} );
                return { nested => $p };
            },
        }
    );
}

#===================================
sub _filter_unary_query { shift->query(@_) }
#===================================

#===================================
sub _filter_unary_nocache { shift->_filter_unary_cache( @_, 'nocache' ) }
#===================================
#===================================
sub _filter_unary_cache {
#===================================
    my ( $self, $v, $op ) = @_;
    $op ||= 'cache';
    my $filter = $self->_SWITCH_refkind(
        "Unary filter -$op",
        $v,
        {   ARRAYREF => sub { $self->_recurse( 'filter', $v ) },
            HASHREF  => sub { $self->_recurse( 'filter', $v ) },
        }
    );

    return unless $filter;

    my ($type) = grep { !/^_/ } keys %$filter;
    if ( $type eq 'query' ) {
        $filter = { fquery => $filter };
        $type = 'fquery';
    }
    elsif ( $type eq 'or' or $type eq 'and' ) {
        my $filters = $filter->{$type};
        $filter->{$type} = { filters => $filters } if ref $filters eq 'ARRAY';
    }
    $filter->{$type}{_cache} = $op eq 'cache' ? 1 : 0;
    return $filter;
}

#===================================
sub _filter_unary_name {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary filter -name",
        $v,
        {   HASHREF => sub {
                my @filters;
                for my $name ( sort keys %$v ) {
                    my $filter = $self->_recurse( 'filter', $v->{$name} )
                        or next;
                    my ($type) = grep { !/^_/ } keys %$filter;
                    if ( $type eq 'query' ) {
                        $filter = { fquery => $filter };
                        $type = 'fquery';
                    }
                    $filter->{$type}{_name} = $name;
                    push @filters, $filter;
                }
                return $self->_join_clauses( 'filter', 'or', \@filters );
            },
        }
    );

}

#===================================
sub _filter_unary_cache_key {
#===================================
    my ( $self, $v ) = @_;
    return $self->_SWITCH_refkind(
        "Unary filter -cache_key",
        $v,
        {   HASHREF  => sub { $self->_join_cache_keys( 'and', %$v ) },
            ARRAYREF => sub { $self->_join_cache_keys( 'or',  @$v ) }
        }
    );

}

#===================================
sub _join_cache_keys {
#===================================
    my ( $self, $op, @v ) = @_;
    my @filters;
    while (@v) {
        my $key = shift @v;
        my $filter = $self->_recurse( 'filter', shift @v ) or next;
        my ($type) = grep { !/^_/ } keys %$filter;
        if ( $type eq 'query' ) {
            $filter = { fquery => $filter };
            $type = 'fquery';
        }
        $filter->{$type}{_cache_key} = $key;
        push @filters, $filter;
    }
    return $self->_join_clauses( 'filter', $op, \@filters );
}

#======================================================================
# FIELD OPS
#======================================================================
# Query field ops
#======================================================================

#===================================
sub _query_field_prefix {
#===================================
    shift->_query_field_generic( @_, 'prefix', ['value'],
        [ 'boost', 'rewrite' ] );
}

#===================================
sub _query_field_wildcard {
#===================================
    shift->_query_field_generic( @_, 'wildcard', ['value'],
        [ 'boost', 'rewrite' ] );
}

#===================================
sub _query_field_fuzzy {
#===================================
    shift->_query_field_generic( @_, 'fuzzy', ['value'],
        [qw(boost min_similarity max_expansions prefix_length rewrite)] );
}

#===================================
sub _query_field_match {
#===================================
    shift->_query_field_generic(
        @_, 'match',
        ['query'],
        [   qw(boost operator analyzer
                fuzziness fuzzy_rewrite rewrite max_expansions
                minimum_should_match prefix_length lenient)
        ]
    );
}

#===================================
sub _query_field_phrase        { shift->_query_field_match_phrase(@_) }
sub _query_field_phrase_prefix { shift->_query_field_match_phrase_prefix(@_) }
#===================================

#===================================
sub _query_field_match_phrase {
#===================================
    shift->_query_field_generic( @_, 'match_phrase', ['query'],
        [qw(boost analyzer slop lenient)] );
}

#===================================
sub _query_field_match_phrase_prefix {
#===================================
    shift->_query_field_generic( @_, 'match_phrase_prefix', ['query'],
        [qw(boost analyzer slop lenient max_expansions)] );
}

#===================================
sub _query_field_qs { shift->_query_field_query_string(@_) }
#===================================

#===================================
sub _query_field_query_string {
#===================================
    shift->_query_field_generic(
        @_, 'field',
        ['query'],
        [   qw(default_operator analyzer allow_leading_wildcard
                lowercase_expanded_terms enable_position_increments
                fuzzy_prefix_length lenient fuzzy_min_sim
                fuzzy_rewrite fuzzy_max_expansions
                phrase_slop boost
                analyze_wildcard auto_generate_phrase_queries rewrite
                quote_analyzer quote_field_suffix
                minimum_should_match)
        ]
    );
}

#===================================
sub _query_field_generic {
#===================================
    my ( $self, $k, $orig_op, $val, $op, $req, $opt ) = @_;

    return $self->_SWITCH_refkind(
        "Query field operator -$orig_op",
        $val,
        {   SCALAR   => sub { return { $op => { $k => $val } } },
            ARRAYREF => sub {
                my $method
                    = $self->can("_query_field_${op}")
                    || $self->can("_query_field_${orig_op}")
                    || croak
                    "Couldn't find method _query_field_${op} or _query_field_${orig_op}";
                my @queries
                    = map { $self->$method( $k, $orig_op, $_ ) } @$val;
                return $self->_join_clauses( 'query', 'or', \@queries ),;
            },
            HASHREF => sub {
                my $p = $self->_hash_params( $orig_op, $val, $req, $opt );
                return { $op => { $k => $p } };
            },
        }
    );
}

#===================================
sub _query_field_term { shift->_query_field_terms(@_) }
#===================================

#===================================
sub _query_field_terms {
#===================================
    my ( $self, $k, $op, $val ) = @_;

    return $self->_SWITCH_refkind(
        "Query field operator -$op",
        $val,
        {   SCALAR  => sub { return { term => { $k => $val } } },
            HASHREF => sub {
                $val = {%$val};
                my $v = delete $val->{value};
                $v = $v->[0] if ref $v eq 'ARRAY' and @$v < 2;
                croak "Missing 'value' param in 'terms' query"
                    unless defined $v;

                if ( ref $v eq 'ARRAY' ) {
                    my $p = $self->_hash_params( $op, $val, [],
                        [ 'boost', 'minimum_match' ] );
                    $p->{$k} = $v;
                    return { terms => $p };
                }
                delete $val->{minimum_match};
                my $p = $self->_hash_params( $op, $val, [], ['boost'] );
                $p->{value} = $v;
                return { term => { $k => $p } };
            },
            ARRAYREF => sub {
                my @scalars = grep { defined && !ref } @$val;
                if ( @scalars == @$val && @scalars > 1 ) {
                    return { terms => { $k => $val } };
                }
                my @queries;
                for (@$val) {
                    my $query = $self->_query_field_terms( $k, $op, $_ )
                        or next;
                    push @queries, $query;
                }
                return $self->_join_clauses( 'query', 'or', \@queries );
            },

        },
    );
}

#===================================
sub _query_field_mlt {
#===================================
    my ( $self, $k, $op, $val ) = @_;

    return $self->_SWITCH_refkind(
        "Query field operator -$op",
        $val,
        {   SCALAR => sub {
                return { mlt_field => { $k => { like_text => $val } } };
            },
            ARRAYREF => sub {
                my @queries
                    = map { $self->_query_field_mlt( $k, $op, $_ ) } @$val;
                return $self->_join_clauses( 'query', 'or', \@queries ),;
            },
            HASHREF => sub {
                my $p = $self->_hash_params(
                    $op, $val,
                    ['like_text'],
                    [   qw( analyzer boost boost_terms max_doc_freq
                            max_query_terms max_word_len min_doc_freq
                            min_term_freq min_word_len
                            percent_terms_to_match stop_words )
                    ]
                );
                return { mlt_field => { $k => $p } };
            },
        }
    );
}

#===================================
sub _query_field_flt {
#===================================
    my ( $self, $k, $op, $val ) = @_;

    return $self->_SWITCH_refkind(
        "Query field operator -$op",
        $val,
        {   SCALAR => sub {
                return { flt_field => { $k => { like_text => $val } } };
            },
            ARRAYREF => sub {
                my @queries
                    = map { $self->_query_field_flt( $k, $op, $_ ) } @$val;
                return $self->_join_clauses( 'query', 'or', \@queries ),;
            },
            HASHREF => sub {
                my $p = $self->_hash_params(
                    $op, $val,
                    ['like_text'],
                    [   qw( analyzer boost ignore_tf max_query_terms
                            min_similarity prefix_length)
                    ]
                );
                return { flt_field => { $k => $p } };
            },
        }
    );
}

#===================================
sub _query_field_range {
#===================================
    my ( $self, $k, $op, $val ) = @_;

    my $es_op = $RANGE_MAP{$op} || $op;
    if ( $op eq 'range' ) {
        return $self->_SWITCH_refkind(
            "Query field operator -range",
            $val,
            {   HASHREF => sub {
                    my $p = $self->_hash_params(
                        'range', $val,
                        [],
                        [   qw(from to include_lower include_upper
                                gt gte lt lte boost)
                        ]
                    );
                    return { range => { $k => $p } };
                },
                SCALAR => sub {
                    croak "range op does not accept a scalar. Instead, use "
                        . "a comparison operator, eg: gt, lt";
                },
            }
        );
    }

    return $self->_SWITCH_refkind(
        "Query field operator -$op",
        $val,
        {   SCALAR => sub {
                return { 'range' => { $k => { $es_op => $val } } };
            },
        }
    );
}

#======================================================================
# Filter field ops
#======================================================================

#===================================
sub _filter_field_term { shift->_filter_field_terms(@_) }
#===================================

#===================================
sub _filter_field_terms {
#===================================
    my ( $self, $k, $op, $val ) = @_;

    return $self->_SWITCH_refkind(
        "Filter field operator -$op",
        $val,
        {   UNDEF  => sub { $self->_hashpair_UNDEF( 'filter',  $k, $val ) },
            SCALAR => sub { $self->_hashpair_SCALAR( 'filter', $k, $val ) },
            ARRAYREF => sub {
                my @scalars = grep { defined && !ref } @$val;
                if ( @scalars == @$val && @scalars > 1 ) {
                    return { terms => { $k => $val } };
                }
                my @filters;
                for (@$val) {
                    my $filter = $self->_filter_field_terms( $k, $op, $_ )
                        or next;
                    push @filters, $filter;
                }
                return $self->_join_clauses( 'filter', 'or', \@filters );
            },
            HASHREF => sub {
                $val = {%$val};
                my $v = delete $val->{value};

                $v = $v->[0] if ref $v eq 'ARRAY' and @$v < 2;
                croak "Missing 'value' param in 'terms' filter"
                    unless defined $v;

                if ( ref $v eq 'ARRAY' ) {
                    my $p
                        = $self->_hash_params( $op, $val, [], ['execution'] );
                    $p->{$k} = $v;
                    return { terms => $p };
                }
                return { term => { $k => $v } };
            },
        }
    );
}

#===================================
sub _filter_field_range {
#===================================
    my ( $self, $k, $op, $val ) = @_;

    my ( $type, $es_op );
    if ( $es_op = $RANGE_MAP{$op} ) {
        $type = 'numeric_range';
    }
    else {
        $es_op = $op;
        $type  = 'range';
    }

    if ( $op eq 'range' ) {
        return $self->_SWITCH_refkind(
            "Filter field operator -$op",
            $val,
            {   HASH => sub {
                    my $p = $self->_hash_params(
                        'range', $val,
                        [],
                        [   qw(from to include_lower include_upper
                                gt gte lt lte boost)
                        ]
                    );
                    return { range => { $k => $p } };
                },
            }
        );
    }
    return $self->_SWITCH_refkind(
        "Filter field operator -$op",
        $val,
        {   SCALAR => sub {
                return { $type => { $k => { $es_op => $val } } };
            },
        }
    );
}

#===================================
sub _filter_field_prefix {
#===================================
    my ( $self, $k, $op, $val ) = @_;

    return $self->_SWITCH_refkind(
        "Filter field operator -$op",
        $val,
        {   SCALAR   => sub { return { prefix => { $k => $val } } },
            ARRAYREF => sub {
                my @filters
                    = map { $self->_filter_field_prefix( $k, $op, $_ ) }
                    @$val;
                return $self->_join_clauses( 'filter', 'or', \@filters ),;
            },
        }
    );
}

#===================================
sub _filter_field_exists {
#===================================
    my ( $self, $k, $op, $val ) = @_;
    $val ||= 0;
    $val = !$val if $op =~ s/^not_//;

    return $self->_SWITCH_refkind(
        "Filter field operator -$op",
        $val,
        {   SCALAR => sub {
                if ( $op eq 'missing' ) { $val = !$val }
                return { ( $val ? 'exists' : 'missing' ) => { field => $k } };
            },
        }
    );
}

#===================================
sub _filter_field_missing {
#===================================
    my ( $self, $k, $op, $val ) = @_;
    $val ||= 0;

    return $self->_SWITCH_refkind(
        "Filter field operator -$op",
        $val,
        {   SCALAR => sub {
                return { ( $val ? 'missing' : 'exists' ) => { field => $k } };
            },
            HASHREF => sub {
                my $p = $self->_hash_params( 'missing', $val, [],
                    [ 'null_value', 'existence' ] );
                $p->{field} = $k;
                return { missing => $p };
            },

        }
    );
}

#===================================
sub _filter_field_geo_bbox {
#===================================
    shift->_filter_field_geo_bounding_box( $_[0], 'geo_bbox', $_[2] );
}

#===================================
sub _filter_field_geo_bounding_box {
#===================================
    my $self = shift;
    my $k    = shift;
    my $p    = $self->_hash_params(
        @_,
        [qw(top_left bottom_right)],
        [ 'normalize', 'type' ]
    );
    return { geo_bounding_box => { $k => $p } };
}

#===================================
sub _filter_field_geo_distance {
#===================================
    my $self = shift;
    my $k    = shift;
    my $p    = $self->_hash_params( @_, [qw(distance location )],
        [ 'normalize', 'optimize_bbox' ] );
    $p->{$k} = delete $p->{location};
    return { geo_distance => $p };
}

#===================================
sub _filter_field_geo_distance_range {
#===================================
    my $self = shift;
    my $k    = shift;
    my $p    = $self->_hash_params(
        @_,
        ['location'],
        [   qw(from to gt lt gte lte
                include_upper include_lower normalize optimize_bbox)
        ]
    );
    $p->{$k} = delete $p->{location};
    return { geo_distance_range => $p };
}

#===================================
sub _filter_field_geo_polygon {
#===================================
    my $self = shift;
    my $k    = shift;
    my ( $op, $val ) = @_;

    return $self->_SWITCH_refkind(
        "Filter field operator -$op",
        $val,
        {   ARRAYREF => sub {
                return { geo_polygon => { $k => { points => $val } } };
            },
            HASHREF => sub {
                my $p = $self->_hash_params( $op, $val, ['points'],
                    ['normalize'] );
                return { geo_polygon => { $k => $p } };
            },
        }
    );
}

#======================================================================
# UTILITIES
#======================================================================

#===================================
sub _top_recurse {
#===================================
    my $self   = shift;
    my $type   = shift;
    my $params = shift;
    croak "Too many params passed to ${type}()"
        if @_;
    my $clause = $self->_recurse( $type, $params );
    return $clause ? { $type => $clause } : undef;
}

#===================================
sub _recurse {
#===================================
    my ( $self, $type, $params, $logic ) = @_;

    my $method = $self->_METHOD_FOR_refkind( "_top", $params );
    return $self->$method( $type, $params, $logic );
}

#===================================
sub _refkind {
#===================================
    my ( $self, $data ) = @_;

    return 'UNDEF' unless defined $data;

    # blessed objects are treated like scalars
    my $ref = ( Scalar::Util::blessed $data) ? '' : ref $data;

    return 'SCALAR' unless $ref;

    my $n_steps = 1;
    while ( $ref eq 'REF' ) {
        $data = $$data;
        $ref = ( Scalar::Util::blessed $data) ? '' : ref $data;
        $n_steps++ if $ref;
    }

    return ( $ref || 'SCALAR' ) . ( 'REF' x $n_steps );
}

#===================================
sub _try_refkind {
#===================================
    my ( $self, $data ) = @_;
    my @try = ( $self->_refkind($data) );
    push @try, 'SCALAR_or_UNDEF'
        if $try[0] eq 'SCALAR' || $try[0] eq 'UNDEF';
    push @try, 'FALLBACK';
    return \@try;
}

#===================================
sub _METHOD_FOR_refkind {
#===================================
    my ( $self, $meth_prefix, $data ) = @_;

    my $method;
    for ( @{ $self->_try_refkind($data) } ) {
        $method = $self->can( $meth_prefix . "_" . $_ )
            and last;
    }

    return $method
        || croak "cannot dispatch on '$meth_prefix' for "
        . $self->_refkind($data);
}

#===================================
sub _SWITCH_refkind {
#===================================
    my ( $self, $op, $data, $dispatch_table ) = @_;

    my $coderef;
    for ( @{ $self->_try_refkind($data) } ) {
        $coderef = $dispatch_table->{$_}
            and last;
    }

    unless ($coderef) {
        croak "$op only accepts parameters of type: "
            . join( ', ', sort keys %$dispatch_table ) . "\n";
    }

    return $coderef->();
}

#===================================
sub _hash_params {
#===================================
    my ( $self, $op, $val, $req, $opt ) = @_;

    croak "Op '$op' only accepts a hashref"
        unless ref $val eq 'HASH';
    $val = {%$val};
    my %params;
    for (@$req) {
        my $v = $params{$_} = delete $val->{$_};
        croak "'$op' missing required param '$_'"
            unless defined $v and length $v;
    }
    if ($opt) {
        for (@$opt) {
            next unless exists $val->{$_};
            my $val = delete $val->{$_};
            $params{$_} = defined($val) && length($val) ? $val : '';
        }
    }

    croak "Unknown param(s) for '$op': " . join( ', ', keys %$val )
        if %$val;

    return \%params;
}

#===================================
sub _multi_queries {
#===================================
    my $self   = shift;
    my $params = shift;
    for my $key (@_) {
        my $v = delete $params->{$key} or next;
        my @q = ref $v eq 'ARRAY' ? @$v : $v;
        my @queries = map { $self->_recurse( 'query', $_ ) } @q;
        next unless @queries;
        $params->{$key} = \@queries;
    }
    return $params;
}

1;

=head1 NAME

ElasticSearch::SearchBuilder - A Perlish compact query language for ElasticSearch

=head1 VERSION

Version 0.16

Compatible with ElasticSearch version 0.19.11

=cut

=head1 BREAKING CHANGE

The 'text' queries have been renamed 'match' queries in
elasticsearch 0.19.9. If you need support for an older version of elasticsearch,
please use L<https://metacpan.org/release/DRTECH/ElasticSearch-SearchBuilder-0.15/>.

=head1 DESCRIPTION

The Query DSL for ElasticSearch (see L<Query DSL|http://www.elasticsearch.org/guide/reference/query-dsl>),
which is used to write queries and filters,
is simple but verbose, which can make it difficult to write and understand
large queries.

L<ElasticSearch::SearchBuilder> is an L<SQL::Abstract>-like query language
which exposes the full power of the query DSL, but in a more compact,
Perlish way.

B<This module is considered stable.> If you have
suggestions for improvements to the API or the documenation, please
contact me.

=cut

=head1 SYNOPSIS

    my $sb = ElasticSearch::SearchBuilder->new();
    my $query = $sb->query({
        body    => 'interesting keywords',
        -filter => {
            status  => 'active',
            tags    => ['perl','python','ruby'],
            created => {
                '>=' => '2010-01-01',
                '<'  => '2011-01-01'
            },
        }
    })


B<NOTE>: C<ElasticSearch::SearchBuilder> is fully integrated with the
L<ElasticSearch> API.  Wherever you can specify C<query>, C<filter> or
C<facet_filter> in L<ElasticSearch>, you can automatically use SearchBuilder
by specifying C<queryb>, C<filterb>, C<facet_filterb> instead.

    $es->search( queryb  => { body => 'interesting keywords' } )

=cut

=head1 METHODS

=head2 new()

    my $sb = ElasticSearch::SearchBuilder->new()

Creates a new instance of the SearchBuilder - takes no parameters.

=head2 query()

    my $es_query = $sb->query($compact_query)

Returns a query in the ElasticSearch query DSL.

C<$compact_query> can be a scalar, a hash ref or an array ref.

    $sb->query('foo')
    # { "query" : { "match" : { "_all" : "foo" }}}

    $sb->query({ ... }) or $sb->query([ ... ])
    # { "query" : { ... }}

=head2 filter()

    my $es_filter = $sb->filter($compact_filter)

Returns a filter in the ElasticSearch query DSL.

C<$compact_filter> can be a scalar, a hash ref or an array ref.

    $sb->filter('foo')
    # { "filter" : { "term" : { "_all" : "foo" }}}

    $sb->filter({ ... }) or $sb->filter([ ... ])
    # { "filter" : { ... }}

=cut

=head1 INTRODUCTION

B<IMPORTANT>: If you are not familiar with ElasticSearch then you should
read L</"ELASTICSEARCH CONCEPTS"> before continuing.

This module was inspired by L<SQL::Abstract> but they are not compatible with
each other.

The easiest way to explain how the syntax works is to give examples:

=head2 QUERY / FILTER CONTEXT

There are two contexts:

=over

=item *

C<filter> context

Filter are fast and cacheable. They should be used to include/exclude docs,
based on simple term values.  For instance, exclude all docs that have
neither tag C<perl> nor C<python>.

Typically, most of your clauses should be filters, which reduce the number
of docs that need to be passed to the query.

=item *

C<query> context

Queries are smarter than filters, but more expensive, as they have
to calculate search relevance (ie C<_score>).

They should be used where:

=over

=item *

relevance is important, eg: in a search for tags C<perl> or C<python>,
a doc that has BOTH tags is more relevant than a doc that has only one

=item *

where search terms need to be analyzed as full text, eg: find me all
docs where the C<content> field includes the words "Perl is GREAT", no matter
how those words are capitalized.

=back

=back

The available operators (and the query/filter clauses that are generated)
differ according to which context you are in.

The initial context depends upon which method you use: L</"query()"> puts
you into C<query> context, and L</"filter()"> into C<filter> context.

However, you can switch from one context to another as follows:

    $sb->query({

        # query context
        foo     => 1,
        bar     => 2,

        -filter => {
            # filter context
            foo     => 1,
            bar     => 2,

            -query  => {
                # query context
                foo => 1
            }
        }
    })


=head3 -filter | -not_filter

Switch from query context to filter context:

    # query field content for 'brown cow', and filter documents
    # where status is 'active' and tags contains the term 'perl'
    {
        content => 'brown cow',
        -filter => {
            status => 'active',
            tags   => 'perl'
        }
    }


    # no query, just a filter:
    { -filter => { status => 'active' }}

See L<Filtered Query|http://www.elasticsearch.org/guide/reference/query-dsl/filtered-query.html>
and L<Constant Score Query|http://www.elasticsearch.org/guide/reference/query-dsl/constant-score-query.html>

=head3 -query | -not_query

Use a query as a filter:

    # query field content for 'brown cow', and filter documents
    # where status is 'active', tags contains the term 'perl'
    # and a match query on field title contains 'important'
    {
        content => 'brown cow',
        -filter => {
            status => 'active',
            tags   => 'perl',
            -query => {
                title => 'important'
            }
        }
    }

See L<Query Filter|http://www.elasticsearch.org/guide/reference/query-dsl/query-filter.html>

=head2 KEY-VALUE PAIRS

Key-value pairs are equivalent to the C<=> operator, discussed below. They are
converted to C<match> queries or C<term> filters:

    # Field 'foo' contains term 'bar'
    # equiv: { foo => { '=' => 'bar' }}
    { foo => 'bar' }



    # Field 'foo' contains 'bar' or 'baz'
    # equiv: { foo => { '=' => ['bar','baz'] }}
    { foo => ['bar','baz']}


    # Field 'foo' contains terms 'bar' AND 'baz'
    # equiv: { foo => { '-and' => [ {'=' => 'bar'}, {'=' => 'baz'}] }}
    { foo => ['-and','bar','baz']}


    ### FILTER ONLY ###

    # Field 'foo' is missing ie has no value
    # equiv: { -missing => 'foo' }
    { foo => undef }

=cut

=head2 AND|OR LOGIC

Arrays are OR'ed, hashes are AND'ed:

    # tags = 'perl' AND status = 'active:
    {
        tags   => 'perl',
        status => 'active'
    }

    # tags = 'perl' OR status = 'active:
    [
        tags   => 'perl',
        status => 'active'
    ]

    # tags = 'perl' or tags = 'python':
    { tags => [ 'perl','python' ]}
    { tags => { '=' => [ 'perl','python' ] }}

    # tags begins with prefix 'p' or 'r'
    { tags => { '^' => [ 'p','r' ] }}

The logic in an array can changed from C<OR> to C<AND> by making the first
element of the array ref C<-and>:

    # tags has term 'perl' AND 'python'

    { tags => ['-and','perl','python']}

    {
        tags => [
            -and => { '=' => 'perl'},
                    { '=' => 'python'}
        ]
    }

However, the first element in an array ref which is used as the value for
a field operator (see L</"FIELD OPERATORS">) is not special:

    # WRONG
    { tags => { '=' => [ '-and','perl','python' ] }}

    # RIGHT
    { tags => ['-and' => [ {'=' => 'perl'}, {'=' => 'python'} ] ]}

...otherwise you would never be able to search for the term C<-and>. So if
you might possibly have the terms C<-and> or C<-or> in your data, use:

    { foo => {'=' => [....] }}

instead of:

    { foo => [....]}

=head3 -and | -or | -not

These unary operators allow you apply C<and>, C<or> and C<not> logic to
nested queries or filters.

    # Field foo has both terms 'bar' and 'baz'
    { -and => [
            foo => 'bar',
            foo => 'baz'
    ]}

    # Field 'name' contains 'john smith', or the name field is missing
    # and the 'desc' field contains 'john smith'

    { -or => [
        { name => 'John Smith' },
        {
            desc     => 'John Smith'
            -filter  => { -missing => 'name' },
        }
    ]}

The C<-and>, C<-or> and C<-not> constructs emit C<bool> queries when
in query context, and C<and>, C<or> and C<not> clauses when in filter
context.

See also:
L</"NAMED FILTERS">,
L<Bool Query|http://www.elasticsearch.org/guide/reference/query-dsl/bool-query.html>,
L<And Filter|http://www.elasticsearch.org/guide/reference/query-dsl/and-filter.html>,
L<Or Filter|http://www.elasticsearch.org/guide/reference/query-dsl/or-filter.html>
and
L<Not Filter|http://www.elasticsearch.org/guide/reference/query-dsl/not-filter.html>


=head2 FIELD OPERATORS

Most operators (eg C<=>, C<gt>, C<geo_distance> etc) are applied to a
particular field. These are known as C<Field Operators>. For example:

    # Field foo contains the term 'bar'
    { foo => 'bar' }
    { foo => {'=' => 'bar' }}

    # Field created is between Jan 1 and Dec 31 2010
    { created => {
        '>='  => '2010-01-01',
        '<'   => '2011-01-01'
    }}

    # Field foo contains terms which begin with prefix 'a' or 'b' or 'c'
    { foo => { '^' => ['a','b','c' ]}}

Some field operators are available as symbols (eg C<=>, C<*>, C<^>, C<gt>) and
others as words (eg C<geo_distance> or C<-geo_distance> - the dash is optional).

Multiple field operators can be applied to a single field.
Use C<{}> to imply C<this AND that>:

    # Field foo has any value from 100 to 200
    { foo => { gte => 100, lte => 200 }}

    # Field foo begins with 'p' but is not python
    { foo => {
        '^'  => 'p',
        '!=' => 'python'
    }}

Or C<[]> to imply C<this OR that>

    # foo is 5 or foo greater than 10
    { foo => [
        { '='  => 5  },
        { 'gt' => 10 }
    ]}

All word operators may be negated by adding C<not_> to the beginning, eg:

    # Field foo does NOT contain a term beginning with 'bar' or 'baz'
    { foo => { not_prefix => ['bar','baz'] }}


=head2 UNARY OPERATORS

There are other operators which don't fit this
C<< { field => { op => value }} >> model.

For instance:

=over

=item *

An operator might apply to multiple fields:

    # Search fields 'title' and 'content' for text 'brown cow'
    {
        -match => {
            query   => 'brown cow',
            fields  => ['title','content']
        }
    }

=item *

The field might BE the value:

    # Find documents where the field 'foo' is blank or undefined
    { -missing => 'foo' }

    # Find documents where the field 'foo' exists and has a value
    { -exists => 'foo' }

=item *

For combining other queries or filters:

    # Field foo has terms 'bar' and 'baz' but not 'balloo'
    {
        -and => [
            foo => 'bar',
            foo => 'baz',
            -not => { foo => 'balloo' }
        ]
    }

=item *

Other:

    # Script query
    { -script => "doc['num1'].value > 1" }

=back

These operators are called C<unary operators> and ALWAYS begin with a dash C<->
to distinguish them from field names.

Unary operators may also be prefixed with C<not_> to negate their meaning.

=cut

=head1 MATCH ALL

=head2 -all

The C<-all> operator matches all documents:

    # match all
    { -all => 1  }
    { -all => 0  }
    { -all => {} }

In query context, the C<match_all> query usually scores all docs as
1 (ie having the same relevance). By specifying a C<norms_field>, the
relevance can be read from that field (at the cost of a slower execution time):

    # Query context only
    { -all =>{
        boost       => 1,
        norms_field => 'doc_boost'
    }}

=head1 EQUALITY

These operators answer the question: "Does this field contain this term?"

Filter equality operators work only with exact terms, while query equality
operators (the C<match> family of queries) will "do the right thing", ie
work with terms for C<not_analyzed> fields and with analyzed text for
C<analyzed> fields.

=head2 EQUALITY (QUERIES)

=head3 = | -match | != | <> | -not_match

These operators all generate C<match> queries:

    # Analyzed field 'title' contains the terms 'Perl is GREAT'
    # (which is analyzed to the terms 'perl','great')
    { title => 'Perl is GREAT' }
    { title => { '='  => 'Perl is GREAT' }}
    { title => { match => 'Perl is GREAT' }}

    # Not_analyzed field 'status' contains the EXACT term 'ACTIVE'
    { status => 'ACTIVE' }
    { status => { '='  => 'ACTIVE' }}
    { status => { match => 'ACTIVE' }}

    # Same as above but with extra parameters:
    { title => {
        match => {
            query                => 'Perl is GREAT',
            boost                => 2.0,
            operator             => 'and',
            analyzer             => 'default',
            fuzziness            => 0.5,
            fuzzy_rewrite        => 'constant_score_default',
            lenient              => 1,
            max_expansions       => 100,
            minimum_should_match => 2,
            prefix_length        => 2,
        }
    }}

Operators C<< <> >>, C<!=> and C<not_match> are synonyms for each other and
just wrap the operator in a C<not> clause.

See L<Match Query|http://www.elasticsearch.org/guide/reference/query-dsl/match-query.html>

=head3 == | -phrase | -not_phrase

These operators look for a complete phrase.

For instance, given the text

    The quick brown fox jumped over the lazy dog.

    # matches
    { content => { '==' => 'Quick Brown' }}

    # doesn't match
    { content => { '==' => 'Brown Quick' }}
    { content => { '==' => 'Quick Fox'   }}

The C<slop> parameter can be used to allow the phrase to match words in the
same order, but further apart:

    # with other parameters
    { content => {
        phrase => {
            query    => 'Quick Fox',
            slop     => 3,
            analyzer => 'default'
            boost    => 1,
            lenient  => 1,
    }}

See L<Match Query|http://www.elasticsearch.org/guide/reference/query-dsl/match-query.html>

=head3 Multi-field -match | -not_match

To run a C<match> | C<=>, C<phrase> or C<phrase_prefix> query against
multiple fields, you can use the C<-match> unary operator:

    {
        -match => {
            query                => "Quick Fox",
            type                 => 'boolean',
            fields               => ['content','title'],

            use_dis_max          => 1,
            tie_breaker          => 0.7,

            boost                => 2.0,
            operator             => 'and',
            analyzer             => 'default',
            fuzziness            => 0.5,
            fuzzy_rewrite        => 'constant_score_default',
            lenient              => 1,
            max_expansions       => 100,
            minimum_should_match => 2,
            prefix_length        => 2,
        }
    }

The C<type> parameter can be C<boolean> (equivalent of C<match> | C<=>)
which is the default, C<phrase> or C<phrase_prefix>.

See L<Multi-match Query|http://www.elasticsearch.org/guide/reference/query-dsl/multi-match-query.html>.

=head3 -term | -terms | -not_term | -not_terms

The C<term>/C<terms> operators are provided for completeness.  You
should almost always use the C<match>/C<=> operator instead.

There are only two use cases:

=over

=item *

To find the exact (ie not analyzed) term 'foo' in an analyzed field:

    { title => { term => 'foo' }}

=item *

To match a list of possible terms, where more than 1 value must match:

    # match 2 or more of these tags
    { tags => {
        terms => {
            value         => ['perl','python','php'],
            minimum_match => 2,
            boost         => 1,
        }
    }}

The above can also be achieved with the L</"-bool"> operator.

=back

C<term> and C<terms> are synonyms, as are C<not_term> and C<not_terms>.

=head2 EQUALITY (FILTERS)

=head3 = | -term | -terms | <> | != | -not_term | -not_terms

These operators result in C<term> or C<terms> filters, which look for
fields which contain exactly the terms specified:

    # Field foo has the term 'bar':
    { foo => 'bar' }
    { foo => { '='    => 'bar' }}
    { foo => { 'term' => 'bar' }}

    # Field foo has the term 'bar' or 'baz'
    { foo => ['bar','baz'] }
    { foo => { '='     => ['bar','baz'] }}
    { foo => { 'term'  => ['bar','baz'] }}

C<< <> >> and C<!=> are synonyms:

    # Field foo does not contain the term 'bar':
    { foo => { '!=' => 'bar' }}
    { foo => { '<>' => 'bar' }}

    # Field foo contains neither 'bar' nor 'baz'
    { foo => { '!=' => ['bar','baz'] }}
    { foo => { '<>' => ['bar','baz'] }}

The C<terms> filter can take an C<execution> parameter which affects how the
filter of multiple terms is executed and cached.

For instance:

    { foo => {
        -terms => {
            value       => ['foo','bar'],
            execution   => 'bool'
        }
    }}

See L<Term Filter|http://www.elasticsearch.org/guide/reference/query-dsl/term-filter.html>
and L<Terms Filter|http://www.elasticsearch.org/guide/reference/query-dsl/terms-filter.html>

=head1 RANGES

=head2 lt | gt | lte | gte | < | <= | >= | > | -range | -not_range

These operators imply a range query or filter, which can be numeric or
alphabetical.

    # Field foo contains terms between 'alpha' and 'beta'
    { foo => {
        'gte'   => 'alpha',
        'lte'   => 'beta'
    }}

    # Field foo contains numbers between 10 and 20
    { foo => {
        'gte'   => '10',
        'lte'   => '20'
    }}

    # boost a range  *** query only ***
    { foo => {
        range => {
            gt      => 5,
            gte     => 5,
            lt      => 10,
            lte     => 10,
            boost   => 2.0
        }
    }}

For queries, C<< < >> is a synonym for C<lt>, C<< > >> for C<gt> etc.

See L<Range Query|http://www.elasticsearch.org/guide/reference/query-dsl/range-query.html>

B<Note>: for filter clauses, the C<gt>,C<gte>,C<lt> and C<lte> operators
imply a C<range> filter, while the C<< < >>, C<< <= >>, C<< > >> and C<< >= >>
operators imply a C<numeric_range> filter.

B<< This does not mean that you should use the C<numeric_range> version
for any field which contains numbers! >>

The C<numeric_range> filter should be used for numbers/datetimes which
have many distinct values, eg C<ID> or C<last_modified>.  If you have a numeric
field with few distinct values, eg C<number_of_fingers> then it is better
to use a C<range> filter.

See L<Range Filter|http://www.elasticsearch.org/guide/reference/query-dsl/range-filter.html>
and L<Numeric Range Filter|http://www.elasticsearch.org/guide/reference/query-dsl/numeric-range-filter.html>.

=head1 MISSING OR NULL VALUES

*** Filter context only ***

=head2 -missing | -exists

You can use a C<missing> or C<exists> filter to select only docs where a
particular field exists and has a value, or is undefined or has no value:

    # Field 'foo' has a value:
    { foo     => { exists  => 1 }}
    { foo     => { missing => 0 }}
    { -exists => 'foo'           }

    # Field 'foo' is undefined or has no value:
    { foo      => { missing => 1 }}
    { foo      => { exists  => 0 }}
    { -missing => 'foo'           }
    { foo      => undef           }

The C<missing> filter also supports the C<null_value> and C<existence>
parameters:

    {
        foo     => {
            missing => {
                null_value => 1,
                existence  => 1,
            }
        }
    }

OR

    { -missing => {
        field      => 'foo',
        null_value => 1,
        existence  => 1,
    }}

See L<Missing Filter|http://www.elasticsearch.org/guide/reference/query-dsl/missing-filter.html>
and L<Exists Filter|http://www.elasticsearch.org/guide/reference/query-dsl/exists-filter.html>

=head1 FULL TEXT SEARCH

*** Query context only ***

For most full text search queries, the C<match> queries are what you
want.  These analyze the search terms, and look for documents that
contain one or more of those terms. (See L</"EQUALITY (QUERIES)">).

=head2 -qs | -query_string | -not_qs | -not_query_string

However, there is a more advanced query string syntax
(see L<Lucene Query Parser Syntax|http://lucene.apache.org/core/old_versioned_docs/versions/3_5_0/queryparsersyntax.html>)
which understands search terms like:

   perl AND python tag:recent "this exact phrase" -apple

It is useful for "power" users, but has the disadvantage that, if
the syntax is incorrect, ES throws an error.  You can use
L<ElasticSearch::QueryParser> to fix any syntax errors.

    # find docs whose 'title' field matches 'this AND that'
    { title => { qs           => 'this AND that' }}
    { title => { query_string => 'this AND that' }}

    # With other parameters
    { title => {
        field => {
            query                        => 'this that ',
            default_operator             => 'AND',
            analyzer                     => 'default',
            allow_leading_wildcard       => 0,
            lowercase_expanded_terms     => 1,
            enable_position_increments   => 1,
            fuzzy_min_sim                => 0.5,
            fuzzy_prefix_length          => 2,
            fuzzy_rewrite                => 'constant_score_default',
            fuzzy_max_expansions         => 1024,
            lenient                      => 1,
            phrase_slop                  => 10,
            boost                        => 2,
            analyze_wildcard             => 1,
            auto_generate_phrase_queries => 0,
            rewrite                      => 'constant_score_default',
            minimum_should_match         => 3,
            quote_analyzer               => 'standard',
            quote_field_suffix           => '.unstemmed'
        }
    }}

The unary form C<-qs> or C<-query_string> can be used when matching
against multiple fields:

    { -qs => {
            query                        => 'this AND that ',
            fields                       => ['title','content'],
            default_operator             => 'AND',
            analyzer                     => 'default',
            allow_leading_wildcard       => 0,
            lowercase_expanded_terms     => 1,
            enable_position_increments   => 1,
            fuzzy_min_sim                => 0.5,
            fuzzy_prefix_length          => 2,
            fuzzy_rewrite                => 'constant_score_default',
            fuzzy_max_expansions         => 1024,
            lenient                      => 1,
            phrase_slop                  => 10,
            boost                        => 2,
            analyze_wildcard             => 1,
            auto_generate_phrase_queries => 0,
            use_dis_max                  => 1,
            tie_breaker                  => 0.7,
            minimum_should_match         => 3,
            quote_analyzer               => 'standard',
            quote_field_suffix           => '.unstemmed'
    }}

See L<Query-string Query|http://www.elasticsearch.org/guide/reference/query-dsl/query-string-query.html>


=head2 -mlt | -not_mlt

An C<mlt> or C<more_like_this> query finds documents that are "like" the
specified text, where "like" means that it contains some or all of the
specified terms.

    # Field foo is like "brown cow"
    { foo => { mlt => "brown cow" }}

    # With other paramters:
    { foo => {
        mlt => {
            like_text               => 'brown cow',
            percent_terms_to_match  => 0.3,
            min_term_freq           => 2,
            max_query_terms         => 25,
            stop_words              => ['the','and'],
            min_doc_freq            => 5,
            max_doc_freq            => 1000,
            min_word_len            => 0,
            max_word_len            => 20,
            boost_terms             => 2,
            boost                   => 2.0,
            analyzer                => 'default'
        }
    }}

    # multi fields
    { -mlt => {
        like_text               => 'brown cow',
        fields                  => ['title','content']
        percent_terms_to_match  => 0.3,
        min_term_freq           => 2,
        max_query_terms         => 25,
        stop_words              => ['the','and'],
        min_doc_freq            => 5,
        max_doc_freq            => 1000,
        min_word_len            => 0,
        max_word_len            => 20,
        boost_terms             => 2,
        boost                   => 2.0,
        analyzer                => 'default'
    }}

See L<MLT Field Query|http://www.elasticsearch.org/guide/reference/query-dsl/mlt-field-query.html>
and L<MLT Query|http://www.elasticsearch.org/guide/reference/query-dsl/mlt-query.html>


=head2 -flt | -not_flt

An C<flt> or C<fuzzy_like_this> query fuzzifies all specified terms, then
picks the best C<max_query_terms> differentiating terms. It is a combination
of C<fuzzy> with C<more_like_this>.

    # Field foo is fuzzily similar to "brown cow"
    { foo => { flt => 'brown cow }}

    # With other parameters:
    { foo => {
        flt => {
            like_text       => 'brown cow',
            ignore_tf       => 0,
            max_query_terms => 10,
            min_similarity  => 0.5,
            prefix_length   => 3,
            boost           => 2.0,
            analyzer        => 'default'
        }
    }}

    # Multi-field
    flt => {
        like_text       => 'brown cow',
        fields          => ['title','content'],
        ignore_tf       => 0,
        max_query_terms => 10,
        min_similarity  => 0.5,
        prefix_length   => 3,
        boost           => 2.0,
        analyzer        => 'default'
    }}

See L<FLT Field Query|http://www.elasticsearch.org/guide/reference/query-dsl/flt-field-query.html>
and L<FLT Query|http://www.elasticsearch.org/guide/reference/query-dsl/flt-query.html>

=head1 PREFIX

=head2 PREFIX (QUERIES)

=head3 ^ | -phrase_prefix | -not_phrase_prefix

These operators use the C<match_phrase_prefix> query.

For C<analyzed> fields, it analyzes the search terms, and does a
C<match_phrase> query, with a C<prefix> query on the last term.
Think "auto-complete".

For C<not_analyzed> fields, this behaves the same as the term-based
C<prefix> query.

For instance, given the phrase
C<The quick brown fox jumped over the lazy dog>:

    # matches
    { content => { '^'             => 'qui'}}
    { content => { '^'             => 'quick br'}}
    { content => { 'phrase_prefix' => 'quick brown f'}}

    # doesn't match
    { content => { '^'             => 'quick fo' }}
    { content => { 'phrase_prefix' => 'fox brow'}}

With extra options

    { content => {
        phrase_prefix => {
            query          => "Brown Fo",
            slop           => 3,
            analyzer       => 'default',
            boost          => 3.0,
            max_expansions => 100,
        }
    }}

See http://www.elasticsearch.org/guide/reference/query-dsl/match-query.html

=head3 -prefix | -not_prefix

The C<prefix> query is a term-based query - no analysis takes place,
even on analyzed fields.  Generally you should use C<^> instead.

    # Field 'lang' contains terms beginning with 'p'
    { lang => { prefix => 'p' }}

    # With extra options
    { lang => {
        'prefix' => {
            value   => 'p',
            boost   => 2,
            rewrite => 'constant_score_default',

        }
    }}

See L<Prefix Query|http://www.elasticsearch.org/guide/reference/query-dsl/prefix-query.html>.

=head2 PREFIX (FILTERS)


=head3 ^ | -prefix | -not_prefix

    # Field foo contains a term which begins with 'bar'
    { foo => { '^'      => 'bar' }}
    { foo => { 'prefix' => 'bar' }}

    # Field foo contains a term which begins with 'bar' or 'baz'
    { foo => { '^'      => ['bar','baz'] }}
    { foo => { 'prefix' => ['bar','baz'] }}

    # Field foo contains a term which begins with neither 'bar' nor 'baz'
    { foo => { 'not_prefix' => ['bar','baz'] }}

See L<Prefix Filter|http://www.elasticsearch.org/guide/reference/query-dsl/prefix-filter.html>


=head1 WILDCARD AND FUZZY QUERIES

*** Query context only ***

=head2 * | -wildcard | -not_wildcard

A C<wildcard> is a term-based query (no analysis is applied), which
does shell globbing to find matching terms. In other words C<?>
represents any single character, while C<*> represents zero or more
characters.

    # Field foo matches 'f?ob*'
    { foo => { '*'        => 'f?ob*' }}
    { foo => { 'wildcard' => 'f?ob*' }}

    # with a boost:
    { foo => {
        '*' => { value => 'f?ob*', boost => 2.0 }
    }}
    { foo => {
        'wildcard' => {
            value   => 'f?ob*',
            boost   => 2.0,
            rewrite => 'constant_score_default',
        }
    }}

See L<Wildcard Query|http://www.elasticsearch.org/guide/reference/query-dsl/wildcard-query.html>

=head2 -fuzzy | -not_fuzzy

A C<fuzzy> query is a term-based query (ie no analysis is done)
which looks for terms that are similar to the the provided terms,
where similarity is based on the Levenshtein (edit distance) algorithm:

    # Field foo is similar to 'fonbaz'
    { foo => { fuzzy => 'fonbaz' }}

    # With other parameters:
    { foo => {
        fuzzy => {
            value           => 'fonbaz',
            boost           => 2.0,
            min_similarity  => 0.2,
            max_expansions  => 10,
            rewrite         => 'constant_score_default',
        }
    }}

Normally, you should rather use either the L</"EQUALITY"> queries with
the C<fuzziness> parameter, or the L<-flt|/"-flt E<verbar> -not_flt"> queries.

See L<Fuzzy Query|http://www.elasticsearch.org/guide/reference/query-dsl/fuzzy-query.html>.

=head1 COMBINING QUERIES

*** Query context only ***

These constructs allow you to combine multiple queries.

=head2 -dis_max | -dismax

While a C<bool> query adds together the scores of the nested queries, a
C<dis_max> query uses the highest score of any matching queries.

    # Run the two queries and use the best score
    { -dismax => [
        { foo => 'bar' },
        { foo => 'baz' }
    ] }

    # With other parameters
    { -dismax => {
        queries => [
            { foo => 'bar' },
            { foo => 'baz' }
        ],
        tie_breaker => 0.5,
        boost => 2.0
    ] }

See L<DisMax Query|http://www.elasticsearch.org/guide/reference/query-dsl/dis-max-query.html>

=head2 -bool

Normally, there should be no need to use a C<bool> query directly, as these
are autogenerated from eg C<-and>, C<-or> and C<-not> constructs. However,
if you need to pass any of the other parameters to a C<bool> query, then
you can do the following:

    {
       -bool => {
           must          => [{ foo => 'bar' }],
           must_not      => { status => 'inactive' },
           should        => [
                { tag    => 'perl'   },
                { tag    => 'python' },
                { tag    => 'ruby' },
           ],
           minimum_number_should_match => 2,
           disable_coord => 1,
           boost         => 2
       }
    }

See L<Bool Query|http://www.elasticsearch.org/guide/reference/query-dsl/bool-query.html>

=head2 -boosting

The C<boosting> query can be used to "demote" results that match a given query.
Unlike the C<must_not> clause of a C<bool> query, the query still matches,
but the results are "less relevant".

    { -boosting => {
        positive       => { title => 'apple pear'     },
        negative       => { title => 'apple computer' },
        negative_boost => 0.2
    }}

See L<Boosting Query|http://www.elasticsearch.org/guide/reference/query-dsl/boosting-query.html>

=head2 -custom_boost

The C<custom_boost> query allows you to multiply the scores of another query
by the specified boost factor. This is a bit different from a standard C<boost>,
which is normalized.

    {
        -custom_boost => {
            query           => { title => 'foo' },
            boost_factor    => 3
        }
    }

See L<Custom Boost Factor Query|http://www.elasticsearch.org/guide/reference/query-dsl/custom-boost-factor-query.html>.

=head1 NESTED QUERIES/FILTERS

Nested queries/filters allow you to run queries/filters on nested docs.

Normally, a doc like this would not allow you to associate the name C<perl>
with the number C<5>

   {
       title:  "my title",
       tags: [
        { name: "perl",   num: 5},
        { name: "python", num: 2}
       ]
   }

However, if C<tags> is mapped as a C<nested> field, then you can run queries
or filters on each sub-doc individually.

See L<Nested Type|http://www.elasticsearch.org/guide/reference/mapping/nested-type.html>,
L<Nested Query|http://www.elasticsearch.org/guide/reference/query-dsl/nested-query.html>
and L<Nested Filter|http://www.elasticsearch.org/guide/reference/query-dsl/nested-filter.html>

=head2 -nested (QUERY)

    {
        -nested => {
            path        => 'tags',
            score_mode  => 'avg',
            _scope      => 'my_tags',
            query       => {
                "tags.name"  => 'perl',
                "tags.num"   => { gt => 2 },
            }
        }
    }

See L<Nested Query|http://www.elasticsearch.org/guide/reference/query-dsl/nested-query.html>

=head2 -nested (FILTER)

    {
        -nested => {
            path        => 'tags',
            score_mode  => 'avg',
            _cache      => 1,
            _name       => 'my_filter',
            filter      => {
                tags.name    => 'perl',
                tags.num     => { gt => 2},
            }
        }
    }

See L<Nested Filter|http://www.elasticsearch.org/guide/reference/query-dsl/nested-filter.html>

=head1 SCRIPTING

ElasticSearch supports the use of scripts to customise query or filter
behaviour.  By default the query language is C<mvel> but javascript, groovy,
python and native java scripts are also supported.

See L<Scripting|http://www.elasticsearch.org/guide/reference/modules/scripting.html> for
more on scripting.

=head2 -custom_score

*** Query context only ***

The C<-custom_score> query allows you to customise the C<_score> or relevance
(and thus the order) of docs returned from a query.

    {
        -custom_score => {
            query  => { foo => 'bar' },
            lang    => 'mvel',
            script => "_score * doc['my_numeric_field'].value / pow(param1, param2)"
            params => {
                param1 => 2,
                param2 => 3.1
            },
        }
    }

See L<Custom Score Query|http://www.elasticsearch.org/guide/reference/query-dsl/custom-score-query.html>

=head2 -custom_filters_score

*** Query context only ***

The C<-custom_filters_score> query allows you to boost documents that match
a filter, either with a C<boost> parameter, or with a custom C<script>.

This is a very powerful and efficient way to boost results which depend on
matching unanalyzed fields, eg a C<tag> or a C<date>.  Also, these filters
can be cached.

    {
        -custom_filters_score => {
            query       => { foo => 'bar' },
            score_mode  => 'first|max|total|avg|min|multiply', # default 'first'
            max_boost   => 10,
            filters     => [
                {
                    filter => { tag => 'perl' },
                    boost  => 2,
                },
                {
                    filter => { tag => 'python' },
                    script => '_score * my_boost',
                    params => { my_boost => 2},
                    lang   => 'mvel'
                },
            ]
        }
    }

See L<Custom Filters Score Query|http://www.elasticsearch.org/guide/reference/query-dsl/custom-filters-score-query.html>

=head2 -script

*** Filter context only ***

The C<-script> filter allows you to use a script as a filter. Return a true
value to indicate that the filter matches.

    # Filter docs whose field 'foo' is greater than 5
    { -script => "doc['foo'].value > 5 " }

    # With other params
    {
        -script => {
            script => "doc['foo'].value > minimum ",
            params => { minimum => 5 },
            lang   => 'mvel'
        }
    }

See L<Script Filter|http://www.elasticsearch.org/guide/reference/query-dsl/script-filter.html>

=head1 PARENT/CHILD

Documents stored in ElasticSearch can be configured to have parent/child
relationships.

See L<Parent Field|http://www.elasticsearch.org/guide/reference/mapping/parent-field.html>
for more.

=head2 -has_parent | -not_has_parent

Find child documents that have a parent document which matches a query.

    # Find parent docs whose children of type 'comment' have the tag 'perl'
    {
        -has_parent => {
            type   => 'comment',
            query  => { tag => 'perl' },
            _scope => 'my_scope',
            boost  => 1,                    # Query context only
            score_type => 'max'             # Query context only
        }
    }

See L<Has Parent Query|http://www.elasticsearch.org/guide/reference/query-dsl/has-parent-query.html>
and See L<Has Parent Filter|http://www.elasticsearch.org/guide/reference/query-dsl/has-parent-filter.html>.

=head2 -has_child | -not_has_child

Find parent documents that have child documents which match a query.

    # Find parent docs whose children of type 'comment' have the tag 'perl'
    {
        -has_child => {
            type   => 'comment',
            query  => { tag => 'perl' },
            _scope => 'my_scope',
            boost  => 1,                    # Query context only
            score_type => 'max'             # Query context only
         }
    }

See L<Has Child Query|http://www.elasticsearch.org/guide/reference/query-dsl/has-child-query.html>
and See L<Has Child Filter|http://www.elasticsearch.org/guide/reference/query-dsl/has-child-filter.html>.

=head2 -top_children

*** Query context only ***

The C<top_children> query runs a query against the child docs, and aggregates
the scores to find the parent docs whose children best match.

    {
        -top_children => {
            type                => 'blog_tag',
            query               => { tag => 'perl' },
            score               => 'max',
            factor              => 5,
            incremental_factor  => 2,
            _scope              => 'my_scope'
        }
    }

See L<Top Children Query|http://www.elasticsearch.org/guide/reference/query-dsl/top-children-query.html>

=head1 GEO FILTERS

For all the geo filters, the C<normalize> parameter defaults to C<true>, meaning
that the longitude value will be normalized to C<-180> to C<180> and the
latitude value to C<-90> to C<90>.

=head2 -geo_distance | -not_geo_distance

*** Filter context only ***

The C<geo_distance> filter will find locations within a certain distance of
a given point:

    {
        my_location => {
            -geo_distance     => {
                location      => { lat => 10, lon => 5 },
                distance      => '5km',
                normalize     => 1 | 0,
                optimize_bbox => memory | indexed | none,
            }
        }
    }

See L<Geo Distance Filter|http://www.elasticsearch.org/guide/reference/query-dsl/geo-distance-filter.html>

=head2 -geo_distance_range | -not_geo_distance_range

*** Filter context only ***

The C<geo_distance_range> filter is similar to the L<-geo_distance|/"-geo_distance | -not_geo_distance">
filter, but expressed as a range:

    {
        my_location => {
            -geo_distance       => {
                location        => { lat => 10, lon => 5 },
                from            => '5km',
                to              => '10km',
                include_lower   => 1 | 0,
                include_upper   => 0 | 1
                normalize       => 1 | 0,
                optimize_bbox   => memory | indexed | none,
            }
        }
    }

or instead of C<from>, C<to>, C<include_lower> and C<include_upper> you can
use C<gt>, C<gte>, C<lt>, C<lte>.

See L<Geo Distance Range Filter|http://www.elasticsearch.org/guide/reference/query-dsl/geo-distance-range-filter.html>

=head2 -geo_bounding_box | -geo_bbox | -not_geo_bounding_box | -not_geo_bbox

*** Filter context only ***

The C<geo_bounding_box> filter finds points which lie within the given
rectangle:

    {
        my_location => {
            -geo_bbox => {
                top_left     => { lat => 9, lon => 4  },
                bottom_right => { lat => 10, lon => 5 },
                normalize    => 1 | 0,
                type         => memory | indexed
            }
        }
    }

See L<Geo Bounding Box Filter|http://www.elasticsearch.org/guide/reference/query-dsl/geo-bounding-box-filter.html>

=head2 -geo_polygon | -not_geo_polygon

*** Filter context only ***

The C<geo_polygon> filter is similar to the L<-geo_bounding_box|/"-geo_bounding_box | -geo_bbox | -not_geo_bounding_box | -not_geo_bbox">
filter, except that it allows you to specify a polygon instead of a rectangle:

    {
        my_location => {
            -geo_polygon => [
                { lat => 40, lon => -70 },
                { lat => 30, lon => -80 },
                { lat => 20, lon => -90 },
            ]
        }
    }

or:

    {
        my_location => {
            -geo_polygon => {
                points  => [
                    { lat => 40, lon => -70 },
                    { lat => 30, lon => -80 },
                    { lat => 20, lon => -90 },
                ],
                normalize => 1 | 0,
            }
        }
    }

See L<Geo Polygon Filter|http://www.elasticsearch.org/guide/reference/query-dsl/geo-polygon-filter.html>

=head1 INDEX/TYPE/ID

=head2 -indices

*** Query context only ***

To run a different query depending on the index name, you can use the
C<-indices> query:

    {
        -indices => {
            indices         => 'one' | ['one','two],
            query           => { status => 'active' },
            no_match_query  => 'all' | 'none' | { another => query }
        }
    }

The `no_match_query` will be run on any indices which don't appear in the
specified list.  It defaults to C<all>, but can be set to C<none> or to
a full query.

See L<Indices Query|http://www.elasticsearch.org/guide/reference/query-dsl/indices-query.html>.

*** Filter context only ***

To run a different filter depending on the index name, you can use the
C<-indices> filter:

    {
        -indices => {
            indices         => 'one' | ['one','two],
            filter          => { status => 'active' },
            no_match_filter => 'all' | 'none' | { another => filter }
        }
    }

The `no_match_filter` will be run on any indices which don't appear in the
specified list.  It defaults to C<all>, but can be set to C<none> or to
a full filter.

See L<Indices Filter|https://github.com/elasticsearch/elasticsearch/issues/1787>.

=head2 -ids

The C<_id> field is not indexed by default, and thus isn't
available for normal queries or filters

Returns docs with the matching C<_id> or C<_type>/C<_id> combination:

    # doc with ID 123
    { -ids => 123 }

    # docs with IDs 123 or 124
    { -ids => [123,124] }

    # docs of types 'blog' or 'comment' with IDs 123 or 124
    {
        -ids => {
            type    => ['blog','comment'],
            values  => [123,124]

        }
    }

See L<IDs Query|http://www.elasticsearch.org/guide/reference/query-dsl/ids-query.html>
abd L<IDs Filter|http://www.elasticsearch.org/guide/reference/query-dsl/ids-filter.html>

=head2 -type

*** Filter context only ***

Filters docs with matching C<_type> fields.

While the C<_type> field is indexed by default, ElasticSearch provides the
C<type> filter which will work even if indexing of the C<_type> field is
disabled.

    # Filter docs of type 'comment'
    { -type => 'comment' }

    # Filter docs of type 'comment' or 'blog'
    { -type => ['blog','comment' ]}

See L<Type Filter|http://www.elasticsearch.org/guide/reference/query-dsl/type-filter.html>


=head1 LIMIT

*** Filter context only ***

The C<limit> filter limits the number of documents (per shard) to execute on:

    {
        name    => "Joe Bloggs",
        -filter => { -limit => 100       }
    }

See L<Limit Filter|http://www.elasticsearch.org/guide/reference/query-dsl/limit-filter.html>

=head1 NAMED FILTERS

ElasticSearch allows you to name filters, in which each search result will
include a C<matched_filters> array containing the names of all filters that
matched.

=head2 -name | -not_name

*** Filter context only ***

    { -name => {
        popular   => { user_rank => { 'gte' => 10 }},
        unpopular => { user_rank => { 'lt'  => 10 }},
    }}

Multiple filters are joined with an C<or> filter (as it doesn't make sense
to join them with C<and>).

See L<Named Filters|http://www.elasticsearch.org/guide/reference/api/search/named-filters.html>
and L</"-and E<verbar> -or E<verbar> -not">.

=head1 CACHING FILTERS

Part of the performance boost that you get when using filters comes from the
ability to cache the results of those filters.  However, it doesn't make
sense to cache all filters by default.

=head2 -cache | -nocache

*** Filter context only ***

If you would like to override the default caching, then you can use
C<-cache> or C<-nocache>:

    # Don't cache the term filter for 'status'
    {
        content => 'interesting post',
        -filter => {
            -nocache => { status => 'active' }
        }
    }

    # Do cache the numeric range filter:
    {
        content => 'interesting post',
        -filter => {
            -cache => { created => {'>' => '2010-01-01' } }
        }
    }

See L<Query DSL|http://www.elasticsearch.org/guide/reference/query-dsl/> for more
details about what is cached by default and what is not.

=head2 -cache_key

It is also possible to use a name to identify a cached filter. For instance:

    {
        -cache_key => {
            friends => { person_id => [1,2,3] },
            enemies => { person_id => [4,5,6] },
        }
    }

In the above example, the two filters will be joined by an C<and> filter. The
following example will have the two filters joined by an C<or> filter:

    {
        -cache_key => [
            friends => { person_id => [1,2,3] },
            enemies => { person_id => [4,5,6] },
        ]
    }

See L<_cache_key|http://www.elasticsearch.org/guide/reference/query-dsl/index.html> for
more details.

=head1 RAW ELASTICSEARCH QUERY DSL

Sometimes, instead of using the SearchBuilder syntax, you may want to revert
to the raw Query DSL that ElasticSearch uses.

You can do this by passing a reference to a HASH ref, for instance:

    $sb->query({
        foo => 1,
        -filter => \{ term => { bar => 2 }}
    })

Would result in:

    {
        query => {
            filtered => {
                query => {
                    match => { foo => 1 }
                },
                filter => {
                    term => { bar => 2 }
                }
            }
        }
    }

An example with OR'ed filters:

    $sb->filter([
        foo => 1,
        \{ term => { bar => 2 }}
    ])

Would result in:

    {
        filter => {
            or => [
                { term => { foo => 1 }},
                { term => { bar => 2 }}
            ]
        }
    }

An example with AND'ed filters:

    $sb->filter({
        -and => [
            foo => 1 ,
            \{ term => { bar => 2 }}
        ]
    })

Would result in:

    {
        filter => {
            and => [
                { term => { foo => 1 }},
                { term => { bar => 2 }}
            ]
        }
    }

Wherever a filter or query is expected, passing a reference to a HASH-ref is
accepted.

=cut

=head1 ELASTICSEARCH CONCEPTS

=head2 FILTERS VS QUERIES

ElasticSearch supports filters and queries:

=over

=item *

A filter just answers the question: "Does this field match? Yes/No", eg:

=over

=item *

Does this document have the tag C<"beta">?

=item *

Was this document published in 2011?

=back

=item *

A query is used to calculate relevance (
known in ElasticSearch as C<_score>):

=over

=item *

Give me all documents that include the keywords C<"Foo"> and C<"Bar"> and
rank them in order of relevance.

=item *

Give me all documents whose C<tag> field contains C<"perl"> or C<"ruby">
and rank documents that contain BOTH tags more highly.

=back

=back

Filters are lighter and faster, and the results can often be cached, but they
don't contribute to the C<_score> in any way.

Typically, most of your clauses will be filters, and just a few will be queries.

=head2 TERMS VS TEXT

All data is stored in ElasticSearch as a C<term>, which is an exact value.
The term C<"Foo"> is not the same as C<"foo">.

While this is useful for fields that have discreet values (eg C<"active">,
C<"inactive">), it is not sufficient to support full text search.

ElasticSearch has to I<analyze> text to convert it into terms. This applies
both to the text that the stored document contains, and to the text that the
user tries to search on.

The default analyzer will:

=over

=item *

split the text on (most) punctuation and remove that punctuation

=item *

lowercase each word

=item *

remove English stopwords

=back

For instance, C<"The 2 GREATEST widgets are foo-bar and fizz_buzz"> would result
in the terms C< [2,'greatest','widgets','foo','bar','fizz_buzz']>.

It is important that the same analyzer is used both for the stored text
and for the search terms, otherwise the resulting terms may be different,
and the query won't succeed.

For instance, a C<term> query for C<GREATEST> wouldn't work, but C<greatest>
would work.  However, a C<match> query for C<GREATEST> would work, because
the search text would be analyzed to produce the same terms that are stored
in the index.

See L<Analysis|http://www.elasticsearch.org/guide/reference/index-modules/analysis/>
for the list of supported analyzers.

=head2 C<match> QUERIES

ElasticSearch has a family of DWIM queries called C<match> queries.

Their action depends upon how the field has been defined. If a field is
C<analyzed> (the default for string fields) then the C<match> queries analyze
the search terms before doing the search:

    # Convert "Perl is GREAT" to the terms 'perl','great' and search
    # the 'content' field for those terms

    { match: { content: "Perl is GREAT" }}

If a field is C<not_analyzed>, then it treats the search terms as a single
term:

    # Find all docs where the 'status' field contains EXACTLY the term 'ACTIVE'
    { match: { status: "ACTIVE" }}

Filters, on the other hand, don't have full text queries - filters operate on
simple terms instead.

See L<Match Query|http://www.elasticsearch.org/guide/reference/query-dsl/match-query.html>
for more about match queries.

=cut

=head1 AUTHOR

Clinton Gormley, C<< <drtech at cpan.org> >>

=head1 BUGS

If you have any suggestions for improvements, or find any bugs, please report
them to L<https://github.com/clintongormley/ElasticSearch-SearchBuilder/issues>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 TODO

Add support for C<span> queries.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ElasticSearch::SearchBuilder


You can also look for information at: L<http://www.elasticsearch.org>


=head1 ACKNOWLEDGEMENTS

Thanks to SQL::Abstract for providing the inspiration and some of the internals.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Clinton Gormley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

