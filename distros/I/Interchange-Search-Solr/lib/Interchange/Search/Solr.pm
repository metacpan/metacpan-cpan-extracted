package Interchange::Search::Solr;

use strict;
use warnings;

use Moo;
use WebService::Solr;
use WebService::Solr::Query;
use Data::Dumper;
use POSIX qw//;
use Encode qw//;
use XML::LibXML;
use Interchange::Search::Solr::Response;
use Interchange::Search::Solr::Builder;
use Lingua::StopWords;
use Types::Standard qw/ArrayRef HashRef Int Bool/;
use namespace::clean;
use HTTP::Response;
use Scalar::Util;
use constant { DEBUG => 0 };

=head1 NAME

Interchange::Search::Solr -- Solr query encapsulation

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';

=head1 DESCRIPTION

Exposes Solr search API in a programmer-friendly way.

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Interchange::Search::Solr;
    my $solr = Interchange::Search::Solr->new(solr_url => $url);
    $solr->rows(10);
    $solr->start(0);
    $solr->search('shirts');
    $results = $solr->results;

=head1 ACCESSORS

=head2 solr_url

Url of the solr instance. Read-only.

=head2 input_encoding [DEPRECATED]

Assume the urls to be in this encoding, so decode it before parsing
it. This is basically a (probably bugged) workaround when you have all
the shop in latin1. If the search keep crashing on non-ascii
characters, try to set this to iso-8859-1.

=head2 rows

Number of results to return. Read-write (so you can reuse the object).

=head2 page_scope

The number of paging items for the paginator

=head2 search_fields

An arrayref with the indexed fields to search. Defaults to:

  [qw/sku name description/]

You can add boost to fields appending a float with a caret.

  [qw/ sku^5.0 name^1.0 description^0.4 /]


=head2 return_fields

An arrayref of indexed fields to return. All by default.

=head2 facets

A string or an arrayref with the fields which will generate a facet.
Defaults to

 [qw/suchbegriffe manufacturer/]

=head2 start

Start of pagination. Read-write.

=head2 page

Current page. Read-write.

=head2 filters

An hashref with the filters. E.g.

 {
  suchbegriffe => [qw/xxxxx yyyy/],
  manufacturer => [qw/pikeur/],
 }

The keys of the hashref, to have any effect, must be one of the facets.

=head2 response

Read-only accessor to the response object of the current search.

=head2 facets_found

After a search, the structure with the facets can be retrieved with
this accessor, with this structure:

 {
   field => [ { name => "name", count => 11 }, { name => "name", count => 9 }, ...  ],
   field2 => [ { name => "name", count => 7 }, { name => "name", count => 6 }, ...  ],
   ...
 }

Each hashref in each field's arrayref has the following keys:

=over 4

=item name

The name to display

=item count

The count of item

=item query_url

The url fragment to toggle this filter.

=item active

True if currently in use (to be used for, e.g., checkboxes)

=back

=head2 search_string

Debug only. The search string produced by the query.

=head2 search_terms

The terms used for the current search.

=head2 search_structure

The perl data structure used for the current search. It's passed to
L<Webservice::Solr::Query> for stringification.

=head2 sorting

The field used to sort the result (optional and defaults to score, as
per Solr doc).

You can set it to a scalar with a field name or instead you can use
the L<SQL::Abstract> syntax (all the cases documented there are
supported). E.g.

 $solr->sorting([{ -asc => 'created_date' }, {-desc => [qw/updated_date sku/] }]);

If you pass a reference, the C<sorting_direction> setting is ignored.

=head2 sorting_direction

The direction used by the sorting, when C<sorting> is specified and is a plain scalar.
Default to 'desc'.

=cut

has solr_url => (is => 'ro',
                 required => 1);

has input_encoding => (is => 'ro');


=head2 wild_matching

By default, a search term produce a query with a wildcard appended. So
searching for 1234 will query 1234*. With this option set to true, a
wildcard is prepended as well, querying for *1234* instead).

=cut


has wild_matching => (is => 'ro',
                      default => sub { 0 });

=head2 stop_words_langs

The languages for which we should build the stop word list. It
defaults to:

 [ 'en' ]

New in 0.10. To revert to the old behaviour (no filtering of
stopwords), pass an empty arrayref.

=cut

has stop_words => (is => 'lazy', isa => HashRef);

has stop_words_langs => (is => 'ro', default => sub { [qw/en/ ] }, isa => ArrayRef);

sub _build_stop_words {
    my $self = shift;
    my @stopwords;
    foreach my $lang (@{ $self->stop_words_langs }) {
        if (my $stops = Lingua::StopWords::getStopWords($lang, 'UTF-8')) {
            push @stopwords, keys %$stops;
        }
    }
    my %out = map { $_ => 1 } @stopwords;
    return \%out;
}

=head2 min_chars

Minimum characters for filtering the search terms. Default to 3.

New in 0.10. To revert to the old behaviour, set it to 0.

=head2 permit_empty_search

By default, empty searches are not executed. You can permit them
setting this accessor to 1. The module will reset it to 0 when the
search is executed.

=cut

has min_chars => (is => 'ro', isa => Int, default => sub { 3 });

has permit_empty_search => (is => 'rw', isa => Bool, default => sub { 0 });

has search_fields => (is => 'ro',
                      default => sub {
                          return [
                              qw/sku
                                 name
                                 description/
                             ]
                      },
                      isa => sub { die unless ref($_[0]) eq 'ARRAY' });

has facets => (is => 'rw',
               isa => sub { die "not an arrayref" unless ref($_[0]) eq 'ARRAY' },
               default => sub {
                   return [qw/suchbegriffe manufacturer/];
               });

has rows => (is => 'rw',
             default => sub { 10 });

has page_scope => (is => 'rw',
                   default => sub { 5 });

has start => (is => 'rw',
              default => sub { 0 });

has page => (is => 'rw',
             default => sub { 1 });

has filters => (is => 'rw',
                isa => HashRef,
                default => sub { return {} },
               );

has response => (is => 'rwp');

has search_string => (is => 'rwp');

has search_terms  => (is => 'rw',
                      isa => sub { die unless ref($_[0]) eq 'ARRAY' },
                      default => sub { return [] },
                     );

has search_structure => (is => 'rw');

has sorting => (is => 'rw');
has sorting_direction => (is => 'rw',
                          isa => sub { die unless $_[0] =~ m/\A(asc|desc)\z/ },
                          default => sub { 'desc' },
                         );

has return_fields => (is => 'rw',
                      isa => sub { die unless ref($_[0]) eq 'ARRAY' },
                     );

has global_conditions => (is => 'rw',
                          isa => sub { die unless ref($_[0]) eq 'HASH' }
                         );

sub results {
    my $self = shift;
    my @matches;
    if ($self->response->ok) {
        for my $doc ( $self->response->docs ) {
            my (%record, $name);

            for my $fld ($doc->fields) {
                $name = $fld->name;
                next if $name =~ /^_/;

                $record{$name} = $fld->value;
            }

            push  @matches, \%record;
        }
    }
    return \@matches;
}

=head1 INTERNAL ACCESSORS

=head2 solr_object

The L<WebService::Solr> instance.

=cut

has solr_object => (is => 'lazy');

sub _build_solr_object {
    my $self = shift;
    my @args = $self->solr_url;
#     if (my $enc = $self->solr_encoding) {
#         my %options = (
#                        default_params => {
#                                           ie => $enc,
#                                          },
#                       );
#         push @args, \%options;
#     }
    return WebService::Solr->new(@args);
}

=head2 builder_object(\@terms, \%filters, $page)

Creates Interchange::Search::Solr::Builder instance.

=cut

sub builder_object {
    my ($self, $terms, $filters, $page) = @_;
    return Interchange::Search::Solr::Builder->new(
        terms   => $terms,
        filters => $filters,
        facets  => $self->facets,
        page    => $page
    );
}

=head1 METHODS

=head2 search( [ $string_or$structure ] ])

Run a search and return a L<WebService::Solr::Response> object.

The method accept zero or one argument.

With no arguments, run a full wildcard search.

With one argument, if it's a string, run the search against all the
indexed fields. If it's a structure, build a query for it. The syntax
of the structure is described at L<WebService::Solr::Query>.

After calling this method you can inspect the response using the
following methods:

=head2 results

Returns reference to list of results, each result is a hash
reference.

=head2 skus_found

Returns just a plain list of skus.

=head2 num_found

Return the number of items found

=head2 has_more

Return true if there are more pages

=cut

sub search {
    my ($self, $string) = (shift, shift);
    die "Extra parameter found" if (@_);
    my $structure;
    # here we just split the terms, set C<search_terms>, and call
    # _do_search.
    if ($string && ref($string)) {
        $structure = $string;
        $string = undef;
    }
    my @terms;
    if ($string) {
        @terms = grep { $self->_term_is_good($_) } split(/\s+/, $string);
    }
    $self->search_terms(\@terms);
    $self->search_structure($structure);
    return $self->_do_search;
}

sub _do_search {
    my $self = shift;

    my @terms = grep { $self->_term_is_good($_) } @{ $self->search_terms };

    my $query = '';
    my $wild_match = '';
    if ($self->wild_matching) {
        $wild_match = '*';
    }

    if (@terms) {
        my @escaped = map { $wild_match . WebService::Solr::Query->escape($_) . '*' } @terms;
        $query = '(' . join(' AND ', @escaped) . ')';
        # even if the structure looks correct, the query isn't build properly
        # print Dumper($query);
    }
    else {
        # catch all
        if (my $structure = $self->search_structure) {
            $query = WebService::Solr::Query->new($structure);
        }

    }
    return $self->execute_query($query);
}

=head2 execute_query($query)

Accept either a raw string with the query or a WebService::Solr::Query
object and run the query against the Solr service.

If no query is provided, a wildcard search is performed.

=cut

sub _search_is_empty {
    my $self = shift;
    my @terms = @{ $self->search_terms };
    my %filters = %{ $self->filters };
    my $structure = $self->search_structure;
    if (@terms || %filters || $structure) {
        return 0;
    }
    else {
        return 1;
    }
}

sub execute_query {
    my ($self, $query) = @_;
    my $querystring = '*';
    if (ref($query)) {
        $querystring = $query->stringify;
    }
    elsif ($query) {
        $querystring = $query;
    }

    if (my $global = $self->global_conditions) {
        my @conditions = ($querystring);
        foreach my $condition (keys %$global) {
            my $string;
            if (ref($global->{$condition}) eq 'SCALAR') {
                $string = ${$global->{$condition}};
            }
            else {
                $string = '"' .
                  WebService::Solr::Query->escape($global->{$condition}) . '"';
            }
            push @conditions, qq{($condition:$string)};
        }
        $querystring = '(' . join(' AND ', @conditions) . ')';
    }
    # save the debug info
    $self->_set_search_string($querystring);

    my $our_res;
    unless ($self->permit_empty_search) {
        if ($self->_search_is_empty) {
            $our_res = Interchange::Search::Solr::Response->new(HTTP::Response->new(404));
            $our_res->error('empty_search');
        }
    }
    unless ($our_res) {
        my %params = $self->construct_params;
        # print Dumper(\%params) if DEBUG;
        my $res = $self->solr_object->search($querystring, \%params);
        $our_res = Interchange::Search::Solr::Response->new($res->raw_response);

	if ($our_res->solr_status != 0) {
	    die "Solr failure: ".$our_res->raw_response->message;
	}
    }
    $self->_set_response($our_res);
    $self->permit_empty_search(0);
    return $our_res;
}

=head2 construct_params

Constructs parameters for the search.

=cut

sub construct_params {
    # set start and rows
    my $self = shift;
    my %params = (
                  start => $self->_start_row,
                  rows => $self->_rows
                 );


    if (my $facet_field = $self->facets) {
        $params{facet} = 'true';
        $params{'facet.field'} = $facet_field;
        $params{'facet.mincount'} = 1;

        # see if we have filters set
        if (my $filters = $self->filters) {
            my @fq;
            foreach my $facet (@{ $self->facets }) {
                if (my $condition = $filters->{$facet}) {
                    push @fq,
                      WebService::Solr::Query->new({
                                                    $facet => $condition,
                                                   });
                }
            }
            if (@fq) {
                $params{fq} = \@fq;
            }
        }
    }
    if (my $sort_by = $self->sorting) {
        my $sort_by_struct;
        if (ref($sort_by)) {
            $sort_by_struct = $sort_by;
        }
        else {
            $sort_by_struct = { '-' . $self->sorting_direction => $sort_by };
        }
        $params{sort} = join(', ', $self->_build_sort_field($sort_by_struct));
    }
    if (my $fl = $self->return_fields) {
        $params{fl} = join(',', @$fl);
    }
    # if using edifmax
    $params{qf} = join(' ', @{ $self->search_fields });
    $params{defType} = 'edismax';
    return %params;
}

sub _start_row {
    my $self = shift;
    return $self->_convert_to_int($self->start) || 0;
}

sub _rows {
    my $self = shift;
    return $self->_convert_to_int($self->rows) || 10;
}

sub _convert_to_int {
    my ($self, $maybe_num) = @_;
    return 0 unless $maybe_num;
    if ($maybe_num =~ m/([1-9][0-9]*)/) {
        return $1;
    }
    else {
        return 0;
    }
}

sub num_found {
    my $self = shift;
    if (my $res = $self->response) {
        return $res->content->{response}->{numFound} || 0;
    }
    else {
        return 0;
    }
}

sub skus_found {
    my $self = shift;
    my @skus;
    if ($self->response->ok) {
        foreach my $item ($self->response->docs) {
            push @skus, $item->value_for('sku');
        }
    }
    return @skus;
}

sub facets_found {
    my $self = shift;
    my $res = $self->response;
    my $facets = $res->content->{facet_counts}->{facet_fields};
    my %out;
    foreach my $field (keys %$facets) {
        my @list = @{$facets->{$field}};
        my @items;
        while (@list > 1) {
            my $name = shift @list;
            my $count = shift @list;
            push @items, {
                          name => $name,
                          count => $count,
                          query_url => $self->_build_facet_url($field, $name),
                          active => $self->_filter_is_active($field, $name),
                         };
        }
        $out{$field} = \@items;
    }
    return \%out;
}


sub has_more {
    my $self = shift;
    if ($self->num_found > ($self->_start_row + $self->_rows)) {
        return 1;
    }
    else {
        return 0;
    }
}


=head2 maintainer_update($mode)

Perform a maintainer update and return a L<WebService::Solr::Response>
object.

=cut

sub maintainer_update {
    my ($self, $mode, $data) = @_;
    die "Missing argument" unless $mode;
    my (@query, %params);

    if ($mode eq 'add') {
        my $xml = $self->_build_xml_add_op($data);

        %params = (
            'stream.body' => $xml,
            commit => 'true',
        );

        @query = ('update', \%params);
    }
    elsif ($mode eq 'clear') {
        %params = (
                      'stream.body' => '<delete><query>*:*</query></delete>',
                      commit        => 'true',
                     );
        @query = ('update', \%params);
    }
    elsif ($mode eq 'full') {
        @query = ('dataimport', { command => 'full-import' });
    }
    elsif ($mode eq 'delta') {
        @query = ('dataimport', { command => 'delta-import' });
    }
    else {
        die "Unrecognized mode $mode!";
    }
    return $self->solr_object->generic_solr_request(@query);
}

# builds XML for add maintainer option

sub _build_xml_add_op {
    my ($self, $input) = @_;
    my $doc = XML::LibXML::Document->new;
    my $el_add = $doc->createElement('add');
    my $list;
    $doc->addChild($el_add);

    if (ref($input) eq 'ARRAY') {
        $list = $input;
    }
    elsif (ref($input) eq 'HASH') {
        $list = [ $input ];
    }
    else {
        die "Bad usage: input should be an arrayref or an hashref";
    }

    foreach my $data (@$list) {
        my $el_doc = $doc->createElement('doc');
        $el_add->addChild($el_doc);
        while (my ($name, $value) = each %$data) {
            if (defined $value) {
                my @values;
                if (ref($value) eq 'ARRAY') {
                    @values = @$value;
                } else {
                    @values = ($value);
                }
                foreach my $v (@values) {
                    my $el_field = $doc->createElement('field');
                    $el_field->setAttribute(name => $name);
                    $el_field->appendText($v);
                    $el_doc->addChild($el_field);
                }
            }
        }
    }
    return $doc->toString;
}

=head2 reset_object

Reset the leftovers of a possible previous search.

=head2 search_from_url($url)

Parse the url provided and do the search.

=cut

sub reset_object {
    my $self = shift;
    $self->start(0);
    $self->page(1);
    $self->_set_response(undef);
    $self->_set_search_string(undef);
    $self->filters({});
    $self->search_terms([]);
    $self->search_structure(undef);
}

sub search_from_url {
    my ($self, $url) = @_;
    if (my $enc = $self->input_encoding) {
        $url = Encode::decode($enc, $url);
    }
    $self->_parse_url($url);
    # at this point, all the parameters are set after the url parsing
    return $self->_do_search;
}

=head2 add_terms_to_url($url, $string)

Parse the url, and return a new one with the additional words added.
The page is discarded, while the filters are retained.

=cut

sub add_terms_to_url {
    my ($self, $url, @other_terms) = @_;
    die "Bad usage" unless defined $url;
    $self->_parse_url($url);
    return $url unless @other_terms;
    my @additional_terms = grep { $self->_term_is_good($_) } @other_terms;
    my @terms = @{ $self->search_terms };
    push @terms, @additional_terms;
    $self->search_terms(\@terms);
    my $builder =  $self->builder_object(
        $self->search_terms,
        $self->filters
    );
    return $builder->url_builder;
    
}


sub _parse_url {
    my ($self, $url) = @_;
    $self->reset_object;
    return unless $url;
    my @fragments = grep { $_ } split('/', $url);

    # nothing to do if there are no fragments
    return unless @fragments;

    my (@terms, %filters);
    # the first keyword we need is the optional "words"
    if ($fragments[0] eq 'words') {
        # just discards and check if we have something. This could
        # also mean that the next word is not a keyword.
        shift @fragments;
        if (@fragments) {
            push @terms, shift @fragments;
        }
    }

    # the page is the last fragment, so check that
    if (@fragments > 1) {
        my $page = $#fragments;
        if ($fragments[$page - 1] eq 'page') {
            $page = pop @fragments;
            # and remove the page
            pop @fragments;
            # but assert it is a number, 1 otherwise
            if ($page =~ s/^([1-9][0-9]*)$/)/) {
                $self->page($1);
            }
            else {
                $self->page(1);
            }
            $self->_set_start_from_page;
        }
    }
    my $current_filter;
    while (@fragments) {

        my $chunk = shift @fragments;

        # we lookup until the first keyword, but only if there is
        # non-keywords after that.
        if ($self->_fragment_is_keyword($chunk) and
            @fragments and
            !$self->_fragment_is_keyword($fragments[0])) {
            # chunk is actually a keyword. Set the flag, prepare the
            # array and move on.
            $current_filter = $chunk;
            $filters{$current_filter} = [];
            next;
        }

        # are we inside a filter?
        if ($current_filter) {
            push @{ $filters{$current_filter} }, $chunk;
        }
        # if not, it's a term
        else {
            push @terms, $chunk;
        }
    }
    # filter the terms
    $self->search_terms([ grep { $self->_term_is_good($_) } @terms ]);
    $self->filters(\%filters);
}

sub _fragment_is_keyword {
    my ($self, $fragment) = @_;
    return unless defined $fragment;
    return grep { $_ eq $fragment } @{ $self->facets };
}


sub _set_start_from_page {
    my $self = shift;
    $self->start($self->rows * ($self->page - 1));
}


=head2 current_search_to_url

Return the url for the current search.

=cut

sub current_search_to_url {
    my ($self, %args) = @_;
    my $page;

    if (! $args{hide_page}) {
        $page = $self->page;
    }

    my $builder = $self->builder_object($self->search_terms,
                              $self->filters,
                              $page);

    return $builder->url_builder;
}

sub _build_facet_url {
    my ($self, $field, $name) = @_;
    # get the current filters
    # print "Building $field $name\n";
    my @terms = @{ $self->search_terms };
    # page is not needed

    # the hash for the url builder
    my %toggled_filters;

    # the current filters
    my $filters = $self->filters;

    # loop over the facets we defined
    foreach my $facet (@{ $self->facets }) {

        # copy of the active filters
        my @active = @{ $filters->{$facet} || [] };

        # filter is active: remove
        if ($self->_filter_is_active($facet, $name)) {
            @active = grep { $_ ne $name } @active;
        }
        # it's not active, but we're building an url for this facet
        elsif ($facet eq $field)  {
            push @active, $name;
        }
        # and store
        $toggled_filters{$facet} = \@active if @active;
    }
    #    print Dumper(\@terms, \%toggled_filters);
    my $builder = $self->builder_object(\@terms, \%toggled_filters);
    return $builder->url_builder;
}

sub _filter_is_active {
    my ($self, $field, $name) = @_;
    my $filters = $self->filters;
    if (my $list = $self->filters->{$field}) {
        if (my @active = @$list) {
            if (grep { $_ eq $name } @active) {
                return 1;
            }
        }
    }
    return 0 ;
}

=head2 paginator

Return an hashref suitable to be turned into a paginator, undef if
there is no need for a paginator.

Be careful that a defined empty string in the first/last/next/previous
keys is perfectly legit and points to an unfiltered search which will
return all the items, so concatenating it to the prefix is perfectly
fine (e.g. "products/" . ''). When rendering this structure to HTML,
just check if the value is defined, not if it's true.

The structure looks like this:

 {
   first => 'words/bla' || undef,
   first_page => 1 || undef,
   last  => 'words/bla/page/5' || undef,
   last_page => 5 || undef,
   next => 'words/bla/page/5' || undef,
   next_page => 5 || undef
   previous => 'words/bla/page/3' || undef,
   previous_page => 3 || undef,
   pages => [
             {
              name => 1,
              url => 'words/bla/page/1',
             },
             {
              name => 2,
              url => 'words/bla/page/2',
             },
             {
              name => 3,
              url => 'words/bla/page/3',
             },
             {
              name => 4,
              url => 'words/bla/page/4',
              current => 1,
             },
             {
              name => 5,
              url => 'words/bla/page/5',
             },
            ]
   total_pages => 5
 }

=cut

sub paginator {
    my $self = shift;
    my $page = $self->page || 1;
    my $page_size = $self->rows;
    my $page_scope = $self->page_scope;
    my $total = $self->num_found;
    return undef unless $total;
    my $total_pages = POSIX::ceil($total / $page_size);
    return undef if $total_pages < 2;

    # compute the scope
    my $start = ($page - $page_scope > 0) ? ($page - $page_scope) : 1;
    my $end   = ($page + $page_scope < $total_pages) ? ($page + $page_scope) : $total_pages;

    my %pager = (items => []);
    my $builder = $self->builder_object($self->search_terms, $self->filters);

    for (my $count = $start; $count <= $end ; $count++) {
        # create the link
        $builder->page($count);
        my $url = $builder->url_builder;
        my $item = {
                    url => $url,
                    name => $count,
                   };
        my $position = $count - $page;
        if ($position == 0) {
            $item->{current} = 1;
        }
        elsif ($position == 1) {
            $pager{next} = $url;
            $pager{next_page} = $count;
        }
        elsif ($position == -1) {
            $pager{previous} = $url;
            $pager{previous_page} = $count;
        }
        push @{$pager{items}}, $item;
    }
    if ($page != $total_pages) {
        $builder->page($total_pages);
        $pager{last} = $builder->url_builder;
        $pager{last_page} = $total_pages;
    }
    if ($page != 1) {
        $builder->page(1);
        $pager{first} = $builder->url_builder;
        $pager{first_page} = 1;
    }
    $pager{total_pages} = $total_pages;
    return \%pager;
}

=head2 terms_found

Returns an hashref suitable to build a widget with the terms used and
the links to toggle them. Return undef if no terms were used in the search.

The structure looks like this:

 {
  reset => '',
  terms => [
            { term => 'first', url => 'words/second' },
            { term => 'second', url => 'words/first' },
           ],
 }

See also:

=over 4

=item clear_words_link

Which return the reset link

=item remove_word_links

Which returns a list of hashrefs with C<uri> and C<label> for each
word to remove.

=back

=cut

sub terms_found {
    my $self = shift;
    my @terms = @{ $self->search_terms };
    return unless @terms;
    my %out = (
               reset => $self->builder_object([], $self->filters)->url_builder,
               terms => [],
              );
    my @toggled;
    my $builder = $self->builder_object(\@toggled, $self->filters);
    foreach my $term (@terms) {
        @toggled = grep { $_ ne $term } @terms;
        $builder->terms(\@toggled);
        push @{ $out{terms} }, {
                                term => $term,
                                url  => $builder->url_builder,
                               };
    }
    return \%out;
    
}

=head2 version

Return the version of this module.

=cut

sub version {
    return $VERSION;
}


=head2 breadcrumbs

Return a list of hashrefs with C<uri> and C<label> suitable to compose
a breadcrumb for the current search.

If the breadcrumb points to a facet, the facet name is stored in the
C<facet> key.

=cut

sub breadcrumbs {
    my $self = shift;
    my $words = $self->search_terms;
    my $filters = $self->filters;
    # always add the root
    my @pieces;
    my $current_uri = 'words';
    foreach my $word (@$words) {
        $current_uri .= "/$word";
        push @pieces, {
                       uri => $current_uri,
                       label => $word,
                      };
    }
    if (%$filters) {
        foreach my $facet (@{ $self->facets }) {
            if (my $terms = $filters->{$facet}) {
                $current_uri .= "/$facet";
                foreach my $term (@$terms) {
                    $current_uri .= "/$term";
                    push @pieces, {
                                   uri => $current_uri,
                                   label => $term,
                                   facet => $facet,
                                  };
                }
            }
        }
    }
    return @pieces;
}

sub clear_words_link {
    my $self = shift;
    if (my $struct = $self->terms_found) {
        return $struct->{reset};
    }
    else {
        return;
    }
}

sub remove_word_links {
    my $self = shift;
    my @out;
    if (my $struct = $self->terms_found) {
        if (my $terms = $struct->{terms}) {
            foreach my $term (@$terms) {
                push @out, {
                            uri => $term->{url},
                            label => $term->{term},
                           };
            }
        }
    }
    return @out;
}

sub _term_is_good {
    my ($self, $term) = @_;
    if ($term && $term =~ /\w/) {
        if ($self->stop_words->{lc($term)}) {
            return 0;
        }
        if ($self->min_chars > 1) {
            my $re = "\\w.*" x $self->min_chars;
            if ($term =~ m/$re/) {
                return 1;
            }
            else {
                return 0;
            }
        }
        return 1;
    }
    return 0;
}

# stolen from SQL::Abstract

sub _build_sort_field {
    my ($self, $arg) = @_;
    return $self->_SWITCH_refkind($arg,
                                  {
                                   ARRAYREF => sub {
                                       map { $self->_build_sort_field($_) } @$arg;
                                   },
                                   SCALAR => sub {
                                       return "$arg";
                                   },
                                   UNDEF => sub {
                                       return;
                                   },
                                   SCALARREF => sub {
                                       $$arg;
                                   },
                                   HASHREF => sub {
                                       my ($key, $val, @rest) = %$arg;
                                       return () unless $key;
                                       if ( @rest or not $key =~ /^-(desc|asc)/i ) {
                                           die "hash passed to sorting  must have exactly ".
                                             "one key (-desc or -asc)";
                                       }
                                       my $direction = $1;
                                       my @ret;
                                       for my $c ($self->_build_sort_field($val)) {
                                           my $query;
                                           $self->_SWITCH_refkind ($c,
                                                                   {
                                                                    SCALAR => sub {
                                                                        $query = $c;
                                                                    },
                                                                   });
                                           $query = $query . ' ' . lc($direction);
                                           push @ret, $query;
                                       }
                                       return @ret;
                                   },
                                  });
}


sub _refkind {
    my ($self, $data) = @_;
    return 'UNDEF' unless defined $data;
    # blessed objects are treated like scalars
    my $ref = (Scalar::Util::blessed $data) ? '' : ref $data;
    return 'SCALAR' unless $ref;
    my $n_steps = 1;
    while ($ref eq 'REF') {
        $data = $$data;
        $ref = (Scalar::Util::blessed $data) ? '' : ref $data;
        $n_steps++ if $ref;
    }
    return ($ref||'SCALAR') . ('REF' x $n_steps);
}

sub _SWITCH_refkind {
    my ($self, $data, $dispatch_table) = @_;
    my $type = $self->_refkind($data);
    my $coderef = $dispatch_table->{$self->_refkind($data)};
    die "Unsupported structure $type" unless $coderef;
    $coderef->();
}


=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/interchange/Interchange-Search-Solr/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Interchange::Search::Solr


You can also look for information at:

=over 4

=item * Github

L<https://github.com/interchange/Interchange-Search-Solr>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Interchange-Search-Solr>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Interchange-Search-Solr>

=item * META CPAN

L<https://metacpan.org/pod/Interchange::Search::Solr>

=back


=head1 ACKNOWLEDGEMENTS

Mohammad S Anwar (GH #14).

=head1 LICENSE AND COPYRIGHT

Copyright 2014-2016 Marco Pessotto.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Interchange::Search::Solr
