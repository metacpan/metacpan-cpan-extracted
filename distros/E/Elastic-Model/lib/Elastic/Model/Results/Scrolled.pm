package Elastic::Model::Results::Scrolled;
$Elastic::Model::Results::Scrolled::VERSION = '0.52';
use Carp;
use Moose;
with 'Elastic::Model::Role::Results';
use MooseX::Types::Moose qw(Int);

use namespace::autoclean;

#===================================
has '_scroll' => (
#===================================
    isa    => 'Search::Elasticsearch::Scroll',
    is     => 'ro',
    writer => '_set_scroll',
);

#===================================
has '_virtual_size' => (
#===================================
    isa    => Int,
    is     => 'ro',
    writer => '_set_virtual_size',
);

#===================================
sub BUILD {
#===================================
    my $self   = shift;
    my $scroll = $self->model->store->scrolled_search( $self->search );
    $self->_set_scroll($scroll);

    # TODO: handle partial results if some shards failed?
    # TODO: croak "Search timed out" if $result->{timed_out};

    $self->_set_total( $scroll->total );
    $self->_set_virtual_size( $scroll->total );
    $self->_set_facets( $scroll->facets       || {} );
    $self->_set_aggs( $scroll->aggregations   || {} );
    $self->_set_max_score( $scroll->max_score || 0 );
}

#===================================
sub size { shift->_virtual_size }
#===================================

#===================================
before '_i' => sub {
#===================================
    my $self = shift;
    if (@_) {
        my $i = shift;
        $self->_fetch_until($i) if $i > -1;
    }
};

#===================================
before 'shift_element' => sub {
#===================================
    my $self = shift;
    $self->_fetch_until(0);
    my $size = $self->size;
    $self->_set_virtual_size( $size > 0 ? $size - 1 : 0 );
};

#===================================
sub _fetch_until {
#===================================
    my $self     = shift;
    my $i        = shift || 0;
    my $scroll   = $self->_scroll;
    my $elements = $self->elements;
    while ( $i >= @$elements and not $scroll->is_finished ) {
        push @$elements, $scroll->drain_buffer;
        $scroll->refill_buffer;
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Results::Scrolled - An iterator over unbounded search results

=head1 VERSION

version 0.52

=head1 SYNOPSIS

All active users:

    $all_users = $model->view
                   ->index  ( 'my_domain' )
                   ->type   ( 'user' )
                   ->filterb( 'status'    => 'active' )
                   ->size   ( 100 )
                   ->scan

    while ( my $user = $users->next ) {
        say $user->name;
    }

=head1 DESCRIPTION

An L<Elastic::Model::Results::Scrolled> object is returned when you call
L<Elastic::Model::View/scroll()> or L<Elastic::Model::View/scan()>,
and is intended for searches that could potentially retrieve many results.
Results are retrieved from Elasticsearch in chunks.

A C<$results> object can iterate through L<Elastic::Model::Result> objects
(with all the result metadata), or just the DocClass object itself
(eg C<MyApp::User>). For instance, you can do:

    $result = $results->next_result;
    $object = $results->next_object;

Or you can set the default type to return:

    $results->as_objects;
    $object = $results->next;

    $results->as_results;
    $result = $results->next;

By default, L<scroll()|Elastic::Model::View/scroll()> will set the short accessors
to return L<Elastic::Model::Result> objects, and
L<scan()|Elastic::Model::View/scan()> will set them to default to the
original objects.

Most attributes and accessors in this class come from
L<Elastic::Model::Role::Results> and L<Elastic::Model::Role::Iterator>.

Also, see L<Elastic::Manual::Searching>.

=head1 ATTRIBUTES

=head2 size

    $size = $results->size;

Initially the same as the L</total> attribute, as you can
potentially retrieve all matching results. (This is different from the
L<Elastic::Model::Results/size>.)  If you use L</shift>, the L</size>
will decrease, while the L</total> will remain the same.

=head2 total

    $total_matching = $results->total

The total number of matching docs found by Elasticsearch.

=head2 max_score

    $max_score = $results->max_score

The highest score (relevance) found by Elasticsearch. B<Note:> if you
are sorting by a field other than C<_score> then you will need
to set L<Elastic::Model::View/track_scores> to true to retrieve the
L</max_score>.

=head2 facets

=head2 facet

    $facets = $results->facets
    $facet  = $results->facet($facet_name)

Facet results, if any were requested with L<Elastic::Model::View/facets>.

=head2 elements

    \@elements = $results->elements;

An array ref containing all of the data structures that we can iterate over.

=head2 search

    \%search_args = $results->search

Contains the hash ref of the search request passed to
L<Elastic::Model::Role::Store/scrolled_search()>

=head1 ITERATOR CONTROL

=head2 index

    $index = $results->index;      # index of the current element, or undef
    $results->index(0);            # set the current element to the first element
    $results->index(-1);           # set the current element to the last element
    $results->index(undef);        # resets the iterator, no current element

L</index> contains the current index of the iterator.  Before you start
iterating, it will return undef.

=head2 reset

    $results->reset;

Resets the iterator so that the next call to L</next> will return
the first element. B<Note:> any calls to L</shift> means that those
elements have been discarded.  L</reset> will not reload these.

=head1 INFORMATIONAL ACCESSORS

=head2 size

    $size = $results->size;

Returns the number of L</elements>.

=head2 even

    $bool = $results->even

Is the current L</index> even?

=head2 odd

    $bool = $results->odd

Is the current L</index> odd?

=head2 parity

    $parity = $results->parity

Returns C<'odd'> or C<'even'>. Useful for alternating the colour of rows:

    while ( my $el = $results->next ) {
        my $css_class = $el->parity;
        # display row
    }

=head2 is_first

    $bool = $results->is_first

Is the L</current> element the first element?

=head2 is_last

    $bool = $results->is_last

Is the L</current> element the last element?

=head2 has_next

    $bool = $results->has_next

Is there a L</next> element?

=head2 has_prev

    $bool = $results->has_prev

Is there a L</prev> element?

=head1 WRAPPERS

=head2 as_results()

    $results = $results->as_results;

Sets the "short" accessors (eg L</next>, L</prev>) to return
L<Elastic::Model::Result> objects.

=head2 as_objects()

    $objects = $objects->as_objects;

Sets the "short" accessors (eg L</next>, L</prev>) to return the object itself,
eg C<MyApp::User>

=head2 as_elements()

    $results->as_elements()

Sets the "short" accessors (eg L</next>, L</prev>) to return the raw result
returned by Elasticsearch.

=head1 ELEMENT ACCESSORS

All of the accessors below have 4 forms:

=over

=item *

Result, eg C<next_result> which returns the full result metadata as an
L<Elastic::Model::Result> object.

=item *

Object, eg C<next_object> which returns the original matching object, eg
an instance of C<MyApp::User>

=item *

Element, eg C<next_element> which returns the raw hashref from Elasticsearch

=item *

Short, which can return any one of the above, depending on which
L<Wrapper|/WRAPPERS> is currently in effect.

=back

Typically you would select the type that you need, then use the short
accessors, eg:

    $results->as_objects;

    while (my $object = $result->next ) {...}

=head2 first

    $el = $results->first

Returns the first element, and resets the iterator so that a call
to L</next> will return the second element. If there is
no first element, it returns undef.

Also C<first_result>, C<first_object>, C<first_element>

=head2 next

    $el = $results->next;

Returns the next element, and advances the iterator by one.  If there is
no next element, it returns undef.  If the next element is the last
element, then it will work like this:

    $results->next;        # returns last element
    $results->next;        # returns undef, and resets iterator
    $results->next;        # returns first element

Also C<next_result>, C<next_object>, C<next_element>

=head2 prev

    $el = $results->prev

Returns the previous element, and moves the iterator one step in reverse.  If
there is no previous element, it returns undef.  If the previous element is the
first element, then it will work like this:

    $results->prev;        # returns prev element
    $results->prev;        # returns undef, and resets iterator to end
    $results->prev;        # returns last element

Also C<prev_result>, C<prev_object>, C<prev_element>

=head2 current

    $el = $results->current

Returns the current element, or undef

Also C<current_result>, C<current_object>, C<current_element>

=head2 last

    $el = $results->last

Returns the last element, and resets the iterator so that a call
to L</next> will return undef, and a second call to
L</next> will return the first element If there is
no last element, it returns undef.

Also C<last_result>, C<last_object>, C<last_element>

=head2 peek_next

    $el = $results->peek_next

Returns the next element (or undef), but doesn't move the iterator.

Also C<peek_next_result>, C<peek_next_object>, C<peek_next_element>

=head2 peek_prev

    $el = $results->peek_prev

Returns the previous element (or undef), but doesn't move the iterator.

Also C<peek_prev_result>, C<peek_prev_object>, C<peek_prev_element>

=head2 shift

    $el = $results->shift

Returns the L</first> element and removes it from from the list. L</size>
will decrease by 1. Returns undef if there are no more elements.

Also C<shift_result>, C<shift_object>, C<shift_element>

=head2 slice

    @els = $results->slice($offset,$length);

Returns a list of (max) C<$length> elements, starting at C<$offset> (which
is zero-based):

    $results->slice();             # all elements;
    $results->slice(5);            # elements 5..size
    $results->slice(-5);           # elements size-5..size
    $results->slice(0,10);         # elements 0..9
    $results->slice(5,10);         # elements 5..14

If your iterator only contains 5 elements:

    $results->slice(3,10);         # elements 3..4
    $results->slice(10,10);        # an empty list

Also C<slice_results>, C<slice_objects>, C<slice_elements>

=head2 all

    @els = $results->all

Returns all L</elements> as a list.

Also C<all_results>, C<all_objects>, C<all_elements>

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: An iterator over unbounded search results

