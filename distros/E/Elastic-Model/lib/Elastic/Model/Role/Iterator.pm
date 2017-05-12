package Elastic::Model::Role::Iterator;
$Elastic::Model::Role::Iterator::VERSION = '0.52';
use Carp;
use Moose::Role;
use MooseX::Types::Moose qw(ArrayRef Int CodeRef);
use namespace::autoclean;

#===================================
has 'elements' => (
#===================================
    isa     => ArrayRef,
    traits  => ['Array'],
    is      => 'ro',
    writer  => '_set_elements',
    handles => { 'get_element' => 'get', },
    default => sub { [] },
);

#has 'page_size' => (
#    isa     => Int,
#    is      => 'rw',
#    default => 10
#);

#===================================
has '_i' => (
#===================================
    isa     => Int,
    is      => 'rw',
    default => -1,
);

#===================================
has 'wrapper' => (
#===================================
    isa     => CodeRef,
    is      => 'rw',
    lazy    => 1,
    default => sub {
        sub { shift() }
    },
);

#===================================
has 'multi_wrapper' => (
#===================================
    isa     => CodeRef,
    is      => 'rw',
    lazy    => 1,
    default => sub {
        sub {@_}
    },
);

#===================================
after 'all_elements'
#===================================
    => sub { shift->reset };

#===================================
around [ 'wrapper', 'multi_wrapper' ]
#===================================
    => sub {
    my $orig = shift;
    my $self = shift;
    if (@_) { $self->$orig(@_); return $self }
    $self->$orig(@_);
    };

no Moose;

#===================================
sub _incr_i {
#===================================
    my $self = shift;
    my $i    = $self->_i + 1;
    $self->_i( $i >= $self->size ? -1 : $i );
}

#===================================
sub _decr_i {
#===================================
    my $self = shift;
    my $i    = $self->_i - 1;
    $self->_i( $i < -1 ? $self->size - 1 : $i );
}

#===================================
sub size { 0 + @{ shift->elements } }
#===================================

#===================================
sub index {
#===================================
    my $self = shift;
    if (@_) {
        my $index = my $original = shift;
        if ( defined $index ) {
            my $size = $self->size
                or croak("Index ($original) out of bounds. No values.");
            $index += $size
                if $index < 0;
            croak(    "Index ($original) out of bounds. "
                    . "Values can be 0.."
                    . ( $size - 1 ) )
                if $index >= $size || $index < 0;
        }
        else { $index = -1 }
        $self->_i($index);
    }
    return $self->_i < 0 ? undef : $self->_i;
}

#===================================
sub reset { shift->_i(-1) }
#===================================

#===================================
sub first     { $_[0]->wrapper->( $_[0]->first_element ) }
sub last      { $_[0]->wrapper->( $_[0]->last_element ) }
sub next      { $_[0]->wrapper->( $_[0]->next_element ) }
sub prev      { $_[0]->wrapper->( $_[0]->prev_element ) }
sub current   { $_[0]->wrapper->( $_[0]->current_element ) }
sub peek_next { $_[0]->wrapper->( $_[0]->peek_next_element ) }
sub peek_prev { $_[0]->wrapper->( $_[0]->peek_prev_element ) }

#===================================
sub shift : method {
#===================================
    my $self = shift;
    $self->wrapper->( $self->shift_element );
}

#===================================
sub all {
#===================================
    my $self = shift;
    $self->multi_wrapper->( $self->all_elements(@_) );
}
#===================================
sub slice {
#===================================
    my $self = shift;
    $self->multi_wrapper->( $self->slice_elements(@_) );
}

#===================================
sub first_element {
#===================================
    my $self = shift;
    $self->_i(0);
    $self->get_element(0);
}

#===================================
sub last_element {
#===================================
    my $self = shift;
    my $i    = $self->_i( $self->size - 1 );
    $self->get_element($i);
}

#===================================
sub current_element {
#===================================
    my $self = shift;
    my $i    = $self->_i;
    return undef if $i == -1;
    return $self->get_element($i);
}

#===================================
sub next_element {
#===================================
    my $self = shift;
    my $i    = $self->_incr_i;
    return undef if $i < 0;
    return $self->get_element($i);
}

#===================================
sub prev_element {
#===================================
    my $self = shift;
    my $i    = $self->_decr_i;
    return undef if $i < 0;
    return $self->get_element($i);
}

#===================================
sub peek_next_element {
#===================================
    my $self = shift;
    my $i    = $self->_i;
    my $raw  = $self->next_element;
    $self->_i($i);
    return $raw;
}

#===================================
sub peek_prev_element {
#===================================
    my $self = shift;
    my $i    = $self->_i;
    my $raw  = $self->prev_element;
    $self->_i($i);
    return $raw;
}

#===================================
sub shift_element {
#===================================
    my $self = shift;
    $self->_i(-1);
    CORE::shift @{ $self->elements };
}

#===================================
sub all_elements {
#===================================
    my $self = shift;
    $self->_fetch_until( $self->size - 1 );
    @{ $self->elements };
}

#===================================
sub even     { my $i = shift->_i; $i < 0 ? undef : !!( $i % 2 ) }
sub odd      { my $i = shift->_i; $i < 0 ? undef : !( $i % 2 ) }
sub parity   { my $i = shift->_i; $i < 0 ? undef : $i % 2 ? 'even' : 'odd' }
sub is_first { my $i = shift->_i; $i < 0 ? undef : $i == 0 }
sub is_last  { my $i = $_[0]->_i; $i < 0 ? undef : $i == $_[0]->size - 1 }
sub has_next { $_[0]->_i < $_[0]->size - 1 }
sub has_prev { !!( $_[0]->_i == 0 ? 0 : $_[0]->size ) }
#===================================

#===================================
sub slice_elements {
#===================================
    my $self   = shift;
    my $first  = shift || 0;
    my $length = shift || 0;
    my $size   = $self->size;
    $first = $first + $size if $first < 0;
    my $last = $length ? $first + $length - 1 : $size - 1;
    if ( $last > $size - 1 ) {
        $last = $size - 1;
    }
    my @slice;
    if ( $first < $size ) {
        $self->_fetch_until($last);
        my $elements = $self->elements;
        @slice = @{$elements}[ $first .. $last ];
    }
    return @slice;
}

#===================================
sub as_elements {
#===================================
    my $self = shift;
    $self->wrapper( sub       { shift() } );
    $self->multi_wrapper( sub {@_} );
    $self;
}

#===================================
sub _fetch_until { }
#===================================

# TODO: extra methods for iterator
#=element C<page()>
#
#    %results = $browse->page($page_no)
#    %results = $browse->page(page => $page_no, page_size => $rows_per_page)
#
#Returns a HASH ref with the following keys:
#
# - total:       total number of elements in the list
# - page:        current page (will be the last available page if $page_no
#                greated than last_page
# - last_page:   the last available page
# - start_row:   the number of the first element (1..$total)
# - last_row:    the number of the last element
# - results:     an iterator containing the requested elements
#
#=cut
#
##===================================
#sub page {
##===================================
#    my $self = shift;
#    my %params
#        = @_ != 1 ? @_
#        : ref $_[0] eq ' HASH ' ? %{ $_[0] }
#        :                       ( page => $_[0] || 1 );
#
#    my $total = $self->size
#        or return;
#
#    my $page_size = $params{page_size} || 10;
#    my $last_page = int( ( $total - 1 ) / $page_size ) + 1;
#    my $page = make_int( $params{page} );
#
#    $page = 1          if $page < 1;
#    $page = $last_page if $page > $last_page;
#
#    my $start_index = ( $page - 1 ) * $page_size;
#    my %search      = (
#        page      => $page,
#        last_page => $last_page,
#        total     => $total,
#        start_row => $start_index + 1,
#        end_row   => $start_index + $page_size,
#        page_size => $page_size
#    );
#
#    $search{end_row} = $total if $total < $search{end_row};
#    $self->_index($start_index);
#
#    # so next_id gives us the first in the list
#    $self->prev_id;
#
#    my @ids;
#    for ( 1 .. $page_size ) {
#        my $id = $self->next_id || last;
#        push @ids, $id;
#    }
#
#    $search{results} = $self->_iterator_class->new(
#        class => $self->object_class,
#        ids   => \@ids
#    );
#
#    $search{results}->preload;
#    return \%search;
#}
#

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Role::Iterator - A generic iterator role

=head1 VERSION

version 0.52

=head1 SYNOPSIS

    print "Total: ".$iter->size;

    while (my $el = $iter->next) {
        print "Row: ".$iter->index + 1;
        print "Data: $el";
        print "More to come..."
            unless $iter->is_last;
    }

=head1 DESCRIPTION

L<Elastic::Model::Role::Iterator> is a generic iterator role which is
applied to L<Elastic::Model::Results> and L<Elastic::Model::Results::Scrolled>
via L<Elastic::Model::Role::Results>.

=head1 ATTRIBUTES

=head2 elements

    \@elements = $iter->elements

An array ref containing all of the data structures that we can iterate over.

=head2 size

    $size = $iter->size

The number of elements in L</elements>.

=head2 wrapper

    $iter     = $iter->wrapper($code_ref);
    $code_ref = $iter->wrapper();

A coderef that wraps all single-element wrapped accessors. Defaults to
L</as_elements()>.

=head2 multi_wrapper

    $iter     = $iter->multi_wrapper($code_ref);
    $code_ref = $iter->multi_wrapper();

A coderef that wraps all multi-element wrapped accessors. Defaults to
L</as_elements()>.

=head1 ITERATOR CONTROL

=head2 index

    $index = $iter->index;      # index of the current element, or undef
    $iter->index(0);            # set the current element to the first element
    $iter->index(-1);           # set the current element to the last element
    $iter->index(undef);        # resets the iterator, no current element

L</index> contains the current index of the iterator.  Before you start
iterating, it will return undef.

=head2 reset

    $iter->reset;

Resets the iterator so that the next call to L</next> will return
the first element. B<Note:> any calls to L</shift> means that those
elements have been discarded.  L</reset> will not reload these.

=head1 INFORMATIONAL ACCESSORS

=head2 size

    $size = $iter->size;

Returns the number of L</elements>.

=head2 even

    $bool = $iter->even

Is the current L</index> even?

=head2 odd

    $bool = $iter->odd

Is the current L</index> odd?

=head2 parity

    $parity = $iter->parity

Returns C<'odd'> or C<'even'>. Useful for alternating the colour of rows:

    while ( my $el = $iter->next ) {
        my $css_class = $el->parity;
        # display row
    }

=head2 is_first

    $bool = $iter->is_first

Is the L</current> element the first element?

=head2 is_last

    $bool = $iter->is_last

Is the L</current> element the last element?

=head2 has_next

    $bool = $iter->has_next

Is there a L</next> element?

=head2 has_prev

    $bool = $iter->has_prev

Is there a L</prev> element?

=head1 WRAPPERS

All of the accessors ending in C<_element> or C<_elements> returns the
raw data structure stored in L</elements>.

The "short" accessors (eg L</first>, L</next>) pass the result of the
"long" accessors (eg C<first_element>, C<next_element>) through
the L</wrapper> (or L</multi_wrapper> for accessors with multiple return values),
allowing the wrapper to transform the raw data in some way.

The default for the "short" accessors is just to return the value
unchanged.

=head2 as_elements()

    $iter->as_elements()

Sets the L</wrapper> and L</multi_wrapper> to return the raw data structures
stored in L</elements>.

=head1 ELEMENT ACCESSORS

All of the accessors below have 2 forms:

=over

=item *

Element, eg C<next_element> which returns the raw element.

=item *

Short, which passes the raw element through the L</wrapper> or
L</multi_wrapper> currently in effect.

=back

=head2 first

    $el = $iter->first

Returns the first element, and resets the iterator so that a call
to L</next> will return the second element. If there is
no first element, it returns undef.

Also C<first_element>

=head2 next

    $el = $iter->next;

Returns the next element, and advances the iterator by one.  If there is
no next element, it returns undef.  If the next element is the last
element, then it will work like this:

    $iter->next;        # returns last element
    $iter->next;        # returns undef, and resets iterator
    $iter->next;        # returns first element

Also C<next_element>

=head2 prev

    $el = $iter->prev

Returns the previous element, and moves the iterator one step in reverse.  If
there is no previous element, it returns undef.  If the previous element is the
first element, then it will work like this:

    $iter->prev;        # returns prev element
    $iter->prev;        # returns undef, and resets iterator to end
    $iter->prev;        # returns last element

Also C<prev_element>

=head2 current

    $el = $iter->current

Returns the current element, or undef

Also C<current_element>

=head2 last

    $el = $iter->last

Returns the last element, and resets the iterator so that a call
to L</next> will return undef, and a second call to
L</next> will return the first element If there is
no last element, it returns undef.

Also C<last_element>

=head2 peek_next

    $el = $iter->peek_next

Returns the next element (or undef), but doesn't move the iterator.

Also C<peek_next_element>

=head2 peek_prev

    $el = $iter->peek_prev

Returns the previous element (or undef), but doesn't move the iterator.

Also C<peek_prev_element>

=head2 shift

    $el = $iter->shift

Returns the L</first> element and removes it from from the list. L</size>
will decrease by 1. Returns undef if there are no more elements.

Also C<shift_element>

=head2 slice

    @els = $iter->slice($offset,$length);

Returns a list of (max) C<$length> elements, starting at C<$offset> (which
is zero-based):

    $iter->slice();             # all elements;
    $iter->slice(5);            # elements 5..size
    $iter->slice(-5);           # elements size-5..size
    $iter->slice(0,10);         # elements 0..9
    $iter->slice(5,10);         # elements 5..14

If your iterator only contains 5 elements:

    $iter->slice(3,10);         # elements 3..4
    $iter->slice(10,10);        # an empty list

Also C<slice_elements>

=head2 all

    @els = $iter->all

Returns all L</elements> as a list.

Also C<all_elements>

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: A generic iterator role

