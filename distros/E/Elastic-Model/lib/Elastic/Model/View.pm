package Elastic::Model::View;
$Elastic::Model::View::VERSION = '0.52';
use Moose;

use Carp;
use Elastic::Model::Types qw(
    IndexNames ArrayRefOfStr SortArgs
    HighlightArgs Consistency Replication);
use MooseX::Types::Moose qw(Str Int HashRef ArrayRef Bool Num Object);
use Elastic::Model::SearchBuilder();
use namespace::autoclean;

#===================================
has 'domain' => (
#===================================
    isa     => IndexNames,
    is      => 'rw',
    lazy    => 1,
    builder => '_build_domains',
    coerce  => 1,
);

#===================================
has 'type' => (
#===================================
    is      => 'rw',
    isa     => ArrayRefOfStr,
    default => sub { [] },
    coerce  => 1,
);

#===================================
has 'query' => (
#===================================
    isa => HashRef,
    is  => 'rw',
);

#===================================
has 'filter' => (
#===================================
    isa => HashRef,
    is  => 'rw',
);

#===================================
has 'post_filter' => (
#===================================
    isa => HashRef,
    is  => 'rw',
);

#===================================
has 'aggs' => (
#===================================
    traits  => ['Hash'],
    isa     => HashRef [HashRef],
    is      => 'rw',
    handles => {
        add_agg    => 'set',
        remove_agg => 'delete',
        get_agg    => 'get'
    }
);

#===================================
has 'facets' => (
#===================================
    traits  => ['Hash'],
    isa     => HashRef [HashRef],
    is      => 'rw',
    handles => {
        add_facet    => 'set',
        remove_facet => 'delete',
        get_facet    => 'get'
    }
);

#===================================
has 'fields' => (
#===================================
    isa     => ArrayRefOfStr,
    coerce  => 1,
    is      => 'rw',
    default => sub { [] },
);

#===================================
has 'from' => (
#===================================
    isa     => Int,
    is      => 'rw',
    default => 0,
);

#===================================
has 'size' => (
#===================================
    isa       => Int,
    is        => 'rw',
    lazy      => 1,
    default   => 10,
    predicate => '_has_size',
);

#===================================
has 'sort' => (
#===================================
    isa    => SortArgs,
    is     => 'rw',
    coerce => 1,
);

#===================================
has 'highlighting' => (
#===================================
    isa     => HashRef,
    is      => 'rw',
    trigger => \&_check_no_fields,
);

#===================================
has 'highlight' => (
#===================================
    is     => 'rw',
    isa    => HighlightArgs,
    coerce => 1,
);

#===================================
has 'index_boosts' => (
#===================================
    isa => HashRef [Num],
    is => 'rw',
    traits  => ['Hash'],
    handles => {
        add_index_boost    => 'set',
        remove_index_boost => 'delete',
        get_index_boost    => 'get'
    }
);

#===================================
has 'min_score' => (
#===================================
    isa => Num,
    is  => 'rw',
);

#===================================
has 'preference' => (
#===================================
    isa => Str,
    is  => 'rw',
);

#===================================
has 'routing' => (
#===================================
    isa    => ArrayRefOfStr,
    coerce => 1,
    is     => 'rw',
);

#===================================
has 'include_paths' => (
#===================================
    is        => 'rw',
    isa       => ArrayRef [Str],
    predicate => '_has_include_paths'
);

#===================================
has 'exclude_paths' => (
#===================================
    is        => 'rw',
    isa       => ArrayRef [Str],
    predicate => '_has_exclude_paths'
);

#===================================
has 'script_fields' => (
#===================================
    isa     => HashRef,
    is      => 'rw',
    traits  => ['Hash'],
    handles => {
        add_script_field    => 'set',
        remove_script_field => 'delete',
        get_script_field    => 'get'
    }
);

#===================================
has 'timeout' => (
#===================================
    isa => Str,
    is  => 'rw',
);

#===================================
has 'explain' => (
#===================================
    is  => 'rw',
    isa => Bool,
);

#===================================
has 'stats' => (
#===================================
    is     => 'rw',
    isa    => ArrayRefOfStr,
    coerce => 1,
);

#===================================
has 'track_scores' => (
#===================================
    isa => Bool,
    is  => 'rw',
);

#===================================
has 'consistency' => (
#===================================
    is  => 'rw',
    isa => Consistency,
);

#===================================
has 'replication' => (
#===================================
    is  => 'rw',
    isa => Replication
);

#===================================
has 'search_builder' => (
#===================================
    isa     => Object,
    is      => 'rw',
    lazy    => 1,
    builder => '_build_search_builder',
);

#===================================
has 'cache' => (
#===================================
    is  => 'rw',
    isa => Object,
);

#===================================
has 'cache_opts' => (
#===================================
    is  => 'rw',
    isa => HashRef,
);

#===================================
sub _build_search_builder { Elastic::Model::SearchBuilder->new }
#===================================

#===================================
sub queryb {
#===================================
    my $self  = shift;
    my @args  = @_ > 1 ? {@_} : shift();
    my $query = $self->search_builder->query(@args)
        or return $self->_clone_self;
    $self->query( $query->{query} );
}

#===================================
sub filterb {
#===================================
    my $self   = shift;
    my @args   = @_ > 1 ? {@_} : shift();
    my $filter = $self->search_builder->filter(@args)
        or return $self->_clone_self;
    $self->filter( $filter->{filter} );
}

#===================================
sub post_filterb {
#===================================
    my $self   = shift;
    my @args   = @_ > 1 ? {@_} : shift();
    my $filter = $self->search_builder->filter(@args)
        or return $self->_clone_self;
    $self->post_filter( $filter->{filter} );
}

#===================================
# clone views when setting attributes
#===================================

around [
#===================================
    'from',           'size',        'timeout',   'track_scores',
    'search_builder', 'preference',  'min_score', 'explain',
    'consistency',    'replication', 'cache'
#===================================
] => sub { _clone_args( \&_scalar_args, @_ ) };

around [
#===================================
    'domain',        'type', 'fields', 'sort', 'routing', 'stats',
    'include_paths', 'exclude_paths'
#===================================
] => sub { _clone_args( \&_array_args, @_ ) };

around [
#===================================
    'aggs',  'facets', 'index_boosts', 'script_fields', 'highlighting',
    'query', 'filter', 'post_filter',  'cache_opts'
#===================================
] => sub { _clone_args( \&_hash_args, @_ ) };

#===================================
around 'highlight'
#===================================
    => sub { _clone_args( \&_highlight_args, @_ ) };

for my $name ( 'agg', 'facet', 'index_boost', 'script_field' ) {
    my $attr = $name . 's';
    for my $method ( "add_$name", "remove_$name" ) {
        around $method => sub {
            my $orig = shift;
            my $self = shift;
            my %hash = %{ $self->$attr || {} };
            $self = $self->$attr( \%hash );
            $self->$orig(@_);
            return $self;
        };
    }
}

#===================================
sub _scalar_args    {@_}
sub _hash_args      { @_ > 1 ? {@_} : @_ }
sub _highlight_args { ref $_[0] ? shift : \@_ }
sub _array_args     { ref $_[0] eq 'ARRAY' ? shift() : \@_ }
#===================================

#===================================
sub _clone_args {
#===================================
    my $args = shift;
    my $orig = shift;
    my $self = shift;
    if (@_) {
        $self = bless {%$self}, ref $self;
        $self->$orig( $args->(@_) );
        return $self;
    }
    $self->$orig();
}

#===================================
sub _clone_self {
#===================================
    my $self = shift;
    return bless {%$self}, ref $self;
}

#===================================
sub _check_no_fields {
#===================================
    my ( $self, $val ) = @_;
    croak "Use the (highlight) attribute to set the fields to highlight"
        if $val->{fields};
}

no Moose;

#===================================
sub BUILD {
#===================================
    my ( $orig_self, $args ) = @_;
    my $self = $orig_self;
    for (qw(queryb filterb post_filterb)) {
        $self = $self->$_( $args->{$_} )
            if defined $args->{$_};
    }

    %{$orig_self} = %{$self};
}

#===================================
sub _build_domains {
#===================================
    my $self       = shift;
    my $namespaces = $self->model->namespaces;
    [   map { $_, @{ $namespaces->{$_}->fixed_domains } }
        sort keys %$namespaces
    ];
}

#===================================
sub search {
#===================================
    my $self = shift;
    $self->model->results_class->new( search => $self->_build_search )
        ->as_results;
}

#===================================
sub cached_search {
#===================================
    my $self  = shift;
    my $cache = $self->cache
        or return $self->search;

    my %cache_opts
        = ( %{ $self->cache_opts || {} }, @_ == 1 ? %{ $_[0] } : @_ );

    $self->model->cached_results_class->new(
        search     => $self->_build_search,
        cache      => $cache,
        cache_opts => \%cache_opts
    )->as_results;
}

#===================================
sub scroll { shift->_scroll(@_)->as_results }
#===================================

#===================================
sub scan {
#===================================
    my $self = shift;
    croak "A scan cannot be combined with sorting"
        if @{ $self->sort || [] };
    return $self->_scroll( shift, search_type => 'scan', @_ )->as_objects;
}

#===================================
sub _scroll {
#===================================
    my $self = shift;
    my $search = $self->_build_search( scroll => shift() || '1m', @_ );
    return $self->model->scrolled_results_class->new( search => $search );
}

#===================================
sub delete {
#===================================
    my $self = shift;
    $self->model->store->delete_by_query( $self->_build_delete(@_) );
}

#===================================
sub first { shift->size(1)->search(@_)->first }
sub total { shift->size(0)->search(@_)->total }
#===================================

#===================================
sub _build_search {
#===================================
    my $self = shift;

    my ( $highlight, $hfields );
    if ( $hfields = $self->highlight and keys %$hfields ) {
        $highlight = { %{ $self->highlighting || {} }, fields => $hfields };
    }

    my $fields = $self->fields;

    my $source;
    $source->{include} = $self->include_paths
        if $self->_has_include_paths;
    $source->{exclude} = $self->exclude_paths
        if $self->_has_exclude_paths;

    $fields = ['_source'] unless $source || @$fields;

    my %args = _strip_undef(
        (   map { $_ => $self->$_ }
                qw(
                type sort from size aggs
                min_score post_filter preference routing stats
                script_fields timeout track_scores explain
                )
        ),
        facets        => $self->_build_facets,
        index         => $self->domain,
        query         => $self->_build_query,
        highlight     => $highlight,
        indices_boost => $self->index_boosts,
        @_,
        version => 1,
        fields  => [ '_parent', '_routing', @$fields ]
    );
    $args{_source} = $source
        if defined $source;
    return \%args;
}

#===================================
sub _build_facets {
#===================================
    my $self = shift;
    return undef unless $self->facets;

    my $facets = { %{ $self->facets } };

    for ( values %$facets ) {
        die "All (facets) must be HASH refs" unless ref $_ eq 'HASH';
        $_ = my $facet = {%$_};
        $self->_to_dsl(
            {   queryb        => 'query',
                filterb       => 'filter',
                facet_filterb => 'facet_filter'
            },
            $facet
        );
    }

    $facets;
}

#===================================
sub _to_dsl {
#===================================
    my ( $self, $ops ) = ( shift, shift );

    my $builder;
    for my $clause (@_) {
        while ( my ( $old, $new ) = each %$ops ) {
            my $src = delete $clause->{$old} or next;
            die "Cannot specify $old and $new parameters.\n" if $clause->{$new};

            $builder ||= $self->search_builder;
            my $method = $new eq 'query' ? 'query' : 'filter';
            my $sub_clause = $builder->$method($src) or next;
            $clause->{$new} = $sub_clause->{$method};
        }
    }
}

#===================================
sub _build_query {
#===================================
    my $self = shift;
    my $q    = $self->query;
    my $f    = $self->filter;
    return { match_all => {} } unless $q || $f;

    return
         !$q ? { constant_score => { filter => $f } }
        : $f ? { filtered => { query => $q, filter => $f } }
        :      $q;
}

#===================================
sub _build_delete {
#===================================
    my $self = shift;
    my %args = _strip_undef(
        index => $self->domain,
        ( map { $_ => $self->$_ } qw(type routing consistency replication) ),
        @_,
        query => $self->_build_query,
    );
    return \%args;
}

#===================================
sub _strip_undef {
#===================================
    my %args = @_;
    return map { $_ => $args{$_} } grep { defined $args{$_} } keys %args;
}
1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::View - Views to query your docs in Elasticsearch

=head1 VERSION

version 0.52

=head1 SYNOPSIS

    $view    = $model->view();         # all domains and types known to the model
    $view    = $domain->view();        # just $domain->name, and its types
    $posts   = $view->type( 'post' );  # just type post

10 most relevant posts containing C<'perl'> or C<'moose'>

    $results = $posts->queryb( content => 'perl moose' )->search;

10 most relevant posts containing C<'perl'> or C<'moose'> published since
1 Jan 2012, sorted by C<timestamp>, with highlighted snippets from the
C<content> field:

    $results = $posts
                ->queryb    ( 'content' => 'perl moose'            )
                ->filterb   ( 'created' => { gte => '2012-01-01' } )
                ->sort      ( 'timestamp'                          )
                ->highlight ( 'content'                            )
                ->search;

The same as the above, but in one step:

    $results = $domain->view(
        type             => 'post',
        sort             => 'timestamp',
        queryb           => { content => 'perl moose' },
        filterb          => { created => { gte => '2012-01-01' } },
        highlight        => 'content',
    )->search;

Efficiently retrieve all posts, unsorted:

    $results = $posts->size(100)->scan;

    while (my $result = $results->shift_result) {
        do_something_with($result);
    );

Cached results:

    $cache   = CHI->new(....);
    $view    = $view->cache( $cache )->cache_opts( expires_in => '2 min');

    $results = $view->queryb( 'perl' )->cached_search();
    $results = $view->queryb( 'perl' )->cached_search( expires => '30 sec');

=head1 DESCRIPTION

L<Elastic::Model::View> is used to query your docs in Elasticsearch.

Views are "chainable". In other words, you get a clone of the
current view every time you set an attribute. For instance, you could do:

    $all_types      = $domain->view;
    $users          = $all_types->type('user');
    $posts          = $all_types->('post');
    $recent_posts   = $posts->filterb({ published => { gt => '2012-05-01' }});

Alternatively, you can set all or some of the attributes when you create
a view:

    $recent_posts   = $domain->view(
        type    => 'post',
        filterb => { published => { gt => '2012-05-01 '}}
    );

Views are also reusable.  They only hit the database when you call one
of the L<methods|/METHODS>, eg:

    $results        = $recent_posts->search;    # retrieve $size results
    $scroll         = $recent_posts->scroll;    # keep pulling results

=head1 METHODS

Calling one of the methods listed below executes your query and returns
the results.  Your C<view> is unchanged and can be reused later.

See L<Elastic::Manual::Searching> for a discussion about when
and how to use L</search()>, L</scroll()> or L</scan()>.

=head2 search()

    $results = $view->search();

Executes a search and returns an L<Elastic::Model::Results> object
with at most L</size> results.

This is useful for returning finite results, ie where you know how many
results you want.  For instance: I<"give me the 10 best results">.

=head2 cached_search()

B<NOTE: Think carefully before you cache data outside of Elasticsearch.
Elasticsearch already has smart filter caches, which are updated as your data
changes. Most of the time, you will be better off using those directly,
instead of an external cache.>

    $results = $view->cache( $cache )->cached_search( %opts );

If a L</cache> attribute has been specified for the current view, then
L</cached_search()> tries to retrieve the search results from the L</cache>.
If it fails, then a L</search()> is executed, and the results are stored in
the L</cache>. An L<Elastic::Model::Results::Cached> object is returned.

Any C<%opts> that are passed in override any default L</cache_opts>, and are
passed to L<CHI's get() or set()|'https://metacpan.org/module/CHI#Getting-and-setting>
methods.

    $view    = $view->cache_opts( expires_in => '30 sec' );

    $results = $view->cached_search;                            # 30 seconds
    $results = $view->cached_search( expires_in => '2 min' );   #  2 minutes

Given the near-real-time nature of Elasticsearch, you sometimes want to
invalidate a cached result in the near future.  For instance, if you have
cached a list of comments on a blog post, but then you add a new comment,
you want to invalidate the cached comments list.  However, the new
comment will only become visible to search sometime within the next second, so
invalidating the cache immediately may or may not be useful.

Use the special argument C<force_set> to bypass the cache C<get()> and to force
the cached version to be updated, along with a new expiry time:

    $results = $view->cached_search( force_set => 1, expires_in => '2 sec');

=head2 scroll()

    $scroll_timeout = '1m';
    $scrolled_results = $view->scroll( $scroll_timeout );

Executes a search and returns an L<Elastic::Model::Results::Scrolled>
object which will pull L</size> results from Elasticsearch as required until
either (1) no more results are available or (2) more than C<$scroll_timeout>
(default 1 minute) elapses between requests to Elasticsearch.

Scrolling allows you to return an unbound result set.  Useful if you're not
sure whether to expect 2 results or 2000.

=head2 scan()

    $timeout = '1m';
    $scrolled_results = $view->scan($timeout);

L</scan()> is a special type of L</scroll()> request, intended for efficient
handling of large numbers of unsorted docs (eg when you want to reindex
all of your data).

=head2 first()

    $result = $view->first();
    $object = $view->first->object;

Executes the search and returns just the first result.  All other
metadata is thrown away.

=head2 total()

    $total = $view->total();

Executes the search and returns the total number of matching docs.
All other metadta is thrown away.

=head2 delete()

    $results = $view->delete();

Deletes all docs matching the query and returns a hashref indicating
success. Any docs that are stored in a live L<scope|Elastic::Model::Scope>
or are cached somewhere are not removed. Any
L<unique keys|Elastic::Manual::Attributes::Unique> are not removed.

This should really only be used once you are sure that the matching docs
are out of circulation.  Also, it is more efficient to just delete a whole index
(if possible), rather than deleting large numbers of docs.

B<Note:> The only attributes relevant to L</delete()> are L</domain>,
L</type>, L</query>, L</routing>, L</consistency> and L</replication>.

=head1 CORE ATTRIBUTES

=head2 domain

    $new_view = $view->domain('my_index');
    $new_view = $view->domain('index_one','alias_two');

    \@domains = $view->domain;

Specify one or more domains (indices or aliases) to query. By default, a C<view>
created from a L<domain|Elastic::Model::Domain> will query just that domain's
L<name|Elastic::Model::Domain/name>.
A C<view> created from the L<model|Elastic::Model::Role::Model> will query all
the main domains (ie the L<Elastic::Model::Namespace/name>) and
L<fixed domains|Elastic::Model::Namesapace/fixed domains> known to the model.

=head2 type

    $new_view = $view->type('user');
    $new_view = $view->type('user','post');

    \@types   = $view->type;

By default, a C<view> will query all L<types|Elastic::Manual::Terminology/Type>
known to all the L<domains|"domain"> specified in the view.  You can specify
one or more types.

=head2 query

=head2 queryb

    # native query DSL
    $new_view = $view->query( text => { title => 'interesting words' } );

    # SearchBuilder DSL
    $new_view = $view->queryb( title => 'interesting words' );

    \%query   = $view->query

Specify the query to run in the native
L<Elasticsearch query DSL|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl.html>
or use C<queryb()> to specify your query  with the more Perlish
L<Elastic::Model::SearchBuilder> query syntax.

By default, the query will
L<match all docs|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-match-all-query.html>.

=head2 filter

=head2 filterb

    # native query DSL
    $new_view = $view->filter( term => { tag => 'perl' } );

    # SearchBuilder DSL
    $new_view = $view->filterb( tag => 'perl' );

    \%filter  = $view->filter;

You can specify a filter to apply to the query results using either
the native Elasticsearch query DSL or, use C<filterb()> to specify your
filter with the more Perlish L<Elastic::Model::SearchBuilder> DSL.
If a filter is specified, it will be combined with the L</query>
as a L<filtered query|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-filtered-query.html>,
or (if no query is specified) as a
L<constant score|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-constant-score-query.html>
query.

=head2 post_filter

=head2 post_filterb

    # native query DSL
    $new_view = $view->post_filter( term => { tag => 'perl' } );

    # SearchBuilder DSL
    $new_view = $view->post_filterb( tag => 'perl' );

    \%filter  = $view->post_filter;

L<Post-filters|http://www.elasticsearch.org/guide/en/elasticsearch/reference/0.90/search-request-post-filter.html>
filter the results AFTER any L</aggs> have been calculated.  In the above
example, the aggregations would be calculated on all values of C<tag>, but the
results would then be limited to just those docs where C<tag == perl>.

You can specify a post_filter using either the native Elasticsearch query DSL or,
use C<post_filterb()> to specify it with the more Perlish
L<Elastic::Model::SearchBuilder> DSL.

=head2 sort

    $new_view = $view->sort( '_score'                ); # _score desc
    $new_view = $view->sort( 'timestamp'             ); # timestamp asc
    $new_view = $view->sort( { timestamp => 'asc' }  ); # timestamp asc
    $new_view = $view->sort( { timestamp => 'desc' } ); # timestamp desc

    $new_view = $view->sort(
        '_score',                                       # _score desc
        { timestamp => 'desc' }                         # then timestamp desc
    );

    \@sort    = $view->sort

By default, results are sorted by "relevance" (C<< _score => 'desc' >>).
You can specify multiple sort arguments, which are applied in order, and
can include scripts or geo-distance.
See L<http://www.elasticsearch.org/guide/en/elasticsearch/reference/0.90/search-request-sort.html> for
more information.

B<Note:> Sorting cannot be combined with L</scan()>.

=head2 from

    $new_view = $view->from( 10 );

    $from     = $view->from;

By default, results are returned from the first result. Think of it as
I<"the number of docs to skip">, so setting C<from> to C<0> would start from
the first result. Setting C<from> to C<10> would skip the first 10 results
and return docs from result number 11 onwards.

=head2 size

    $new_view = $view->size( 100 );

    $size     = $view->size;

The number of results returned in a single L</search()>, which defaults to 10.

B<Note:> See L</scan()> for a slightly different application of the L</size>
value.

=head2 aggs

    $new_view = $view->aggs(
        active_docs => {
            filter => {
                term => { status => 'active' }
            },
            aggs => {
                popular_tags => {
                    terms => {
                        field => 'path.to.tags',
                        size  => 10
                    }
                }
            }
        },
        agg_two => {....}
    );

    $new_view = $view->add_agg( agg_three => {...} )
    $new_view = $view->remove_agg('agg_three');

    \%aggs  = $view->aggs;
    \%agg   = $view->get_agg('active_docs');

Aggregations allow you to aggregate data from a query, for instance: most popular
terms, number of blog posts per day, average price etc. Aggs are calculated
from the query generated from L</query> and L</filter>.  If you want to filter
your query results down further after calculating your aggs, you can
use L</post_filter>.

B<NOTE:> There is no support in aggs for L<Elastic::Model::SearchBuilder>.

See L<http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-aggregations.html> for
an explanation of what aggregations are available.

=head2 facets

B<IMPORTANT:> Facets are deprecated in favour of L<aggregations|/aggs>.
They will be removed in a future version of Elasticsearch.

    $new_view = $view->facets(
        facet_one => {
            terms   => {
                field => 'field.to.facet',
                size  => 10
            },
            facet_filterb => { status => 'active' },
        },
        facet_two => {....}
    );

    $new_view = $view->add_facet( facet_three => {...} )
    $new_view = $view->remove_facet('facet_three');

    \%facets  = $view->facets;
    \%facet   = $view->get_facet('facet_one');

Facets allow you to aggregate data from a query, for instance: most popular
terms, number of blog posts per day, average price etc. Facets are calculated
from the query generated from L</query> and L</filter>.  If you want to filter
your query results down further after calculating your facets, you can
use L</post_filter>.

See L<http://www.elasticsearch.org/guide/en/elasticsearch/reference/0.90/search-facets.html> for
an explanation of what facets are available.

=head2 highlight

    $new_view = $view->highlight(
        'field_1',
        'field_2' => \%field_2_settings,
        'field_3'
    );

Specify which fields should be used for
L<highlighted snippets|http://www.elasticsearch.org/guide/en/elasticsearch/reference/0.90/search-request-highlighting.html>.
to your search results. You can pass just a list of fields, or fields with
their field-specific settings. These values are used to set the C<fields>
parameter in L</highlighting>.

=head2 highlighting

    $new_view = $view->highlighting(
        pre_tags    =>  [ '<em>',  '<b>'  ],
        post_tags   =>  [ '</em>', '</b>' ],
        encoder     => 'html'
        ...
    );

The L</highlighting> attribute is used to pass any highlighting parameters
which should be applied to all of the fields set in L</highlight> (although
you can override these settings for individual fields by passing field settings
to L</highlight>).

See L<http://www.elasticsearch.org/guide/en/elasticsearch/reference/0.90/search-request-highlighting.html>.
for more about how highlighting works, and L<Elastic::Model::Result/highlight>
for how to retrieve the highlighted snippets.

=head1 OTHER ATTRIBUTES

=head2 fields

    $new_view = $view->fields('title','content');

By default, searches will return the L<_source|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/mapping-source-field.html>
field which contains the whole document, allowing Elastic::Model to inflate
the original object without having to retrieve the document separately. If you
would like to just retrieve a subset of fields, you can specify them in
L</fields>. See L<http://www.elasticsearch.org/guide/en/elasticsearch/reference/0.90/search-request-fields.html>.

B<Note:> If you do specify any fields, and you DON'T include C<'_source'> then the
C<_source> field won't be returned, and you won't be able to retrieve the original
object without requesting it from Elasticsearch in a separate (but automatic) step.

=head2 script_fields

    $new_view = $view->script_fields(
        distance => {
            script  => q{doc['location'].distance(lat,lon)},
            params  => { lat => $lat, lon => $lon }
        },
        $name    => \%defn,
        ...
    );

    $new_view = $view->add_script_field( $name => \%defn );
    $new_view = $view->remove_script_field($name);

    \%fields  = $view->script_fields;
    \%defn    = $view->get_script_field($name);

L<Script fields|http://www.elasticsearch.org/guide/en/elasticsearch/reference/0.90/search-request-script-fields.html>
can be generated using the L<mvel|http://mvel.codehaus.org/Language+Guide+for+2.0>
scripting language. (You can also use L<Groovy, Javascript, Python and Java|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/modules-scripting.html>.)

=head2 include_paths / exclude_paths

    $new_view    = $view->include_paths('foo.*')
                        ->exclude_paths('foo.bar.*','baz.*');

    $results     = $new_view->search->as_partials;
    $partial_obj = $results->next;

If your objects are large, but you only need access to a few attributes to
eg display search results, you may want to retrieve only the relevant parts of
each object.  You can specify which parts of the object to include or exclude
using C<include_paths> and C<exclude_paths>. If either of these is set
then the full C<_source> field will not be loaded (unless you specify it
explicitly using L</fields>).

The partial objects returned when L<Elastic::Model::Results/as_partials()>
is in effect function exactly as real objects, except that they cannot
be saved.

See L<http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-request-source-filtering.html>.

=head2 routing

    $new_view = $view->routing( 'routing_val' );
    $new_view = $view->routing( 'routing_1', 'routing_2' );

Search queries are usually directed at all shards. If you are using routing
(eg to store related docs on the same shard) then you can limit the search
to just the relevant shard(s). B<Note:> if you are searching on aliases that
have routing configured, then specifying a L</routing> manually will override
those values.

See L<Elastic::Manual::Scaling> for more.

=head2 index_boosts

    $new_view = $view->index_boosts(
        index_1 => 4,
        index_2 => 2
    );

    $new_view = $view->add_index_boost( $index => $boost );
    $new_view = $view->remove_index_boost( $index );

    \%boosts  = $view->index_boosts;
    $boost    = $view->get_index_boost( $index );

Make results from one index more relevant than those from another index.

=head2 min_score

    $new_view  = $view->min_score( 2 );
    $min_score = $view->min_score;

Exclude results whose score (relevance) is less than the specified number.

=head2 preference

    $new_view = $view->preference( '_local' );

Control which node should return search results. See
L<http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-request-preference.html> for more.

=head2 timeout

    $new_view = $view->timeout( 10 );         # 10 ms
    $new_view = $view->timeout( '10s' );      # 10 sec

    $timeout  = $view->timeout;

Sets an upper limit on the the time to wait for search results, returning
with whatever results it has managed to receive up until that point.

=head2 track_scores

    $new_view = $view->track_scores( 1 );
    $track    = $view->track_scores;

By default, If you sort on a field other than C<_score>, Elasticsearch
does not return the calculated relevance score for each doc.  If
L</track_scores> is true, these scores will be returned regardless.

=head1 CACHING ATTRIBUTES

Bounded searches (those returned by calling L</search()>) can be stored
in a L<CHI>-compatible cache.

=head2 cache

    $cache    = CHI->new(...);
    $new_view = $view->cache( $cache );

Stores an instance of a L<CHI>-compatible cache, to be used with
L</cached_search()>.

=head2 cache_opts

    $new_view = $view->cache_opts( expires_in => '20 sec', ...);

Stores the default options that should be passed to
L<CHI's get() or set()|'https://metacpan.org/module/CHI#Getting-and-setting>.
These can be overridden by passing options to L</cached_search()>.

=head1 DEBUGGING ATTRIBUTES

=head2 explain

    $new_view = $view->explain( 1 );
    $explain  = $view->explain;

Set L</explain> to true to return debugging information explaining how
each document's score was calculated. See
L<Elastic::Model::Result/explain> to view the output.

=head2 stats

    $new_view = $view->stats( 'group_1', 'group_2' );
    \@groups  = $view->stats;

The statistics for each search can be aggregated by C<group>. These stats
can later be retrieved using L<Search::Elasticsearch::Client::Direct::Indices/stats()>.

=head2 search_builder

    $new_view = $view->search_builder( $search_builder );
    $builder  = $view->search_builder;

If you would like to use a different search builder than the default
L<Elastic::Model::SearchBuilder> for L</"queryb">, L</"filterb"> or
L</post_filterb>, then you can set a value for L</search_builder>.

=head1 DELETE ATTRIBUTES

These parameters are only used with L</delete()>.

=head2 consistency

    $new_view    = $view->consistency( 'quorum' | 'all' | 'one' );
    $consistency = $view->consistency;

At least C<one>, C<all> or a C<quorum> (default) of nodes must be present for
the delete to take place.

=head2 replication

    $new_view    = $view->replication( 'sync' | 'async' );
    $replication = $view->replication;

Should a delete be done synchronously (ie waits until all nodes within
the replcation group have run the delete) or asynchronously (returns
immediately, and performs the delete in the background).

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Views to query your docs in Elasticsearch

