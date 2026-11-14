package LibTmux::Selection;
use v5.44;
use Scalar::Util qw(blessed);
use LibTmux::X;
use LibTmux::Selection::Iterator;

sub new ($class, @items) {
    my $self = bless \@items, $class;
    $self->_validate;
    return $self;
}

sub _validate ($self) {
    my $identity;
    for my $i (0 .. $#$self) {
        my $item = $self->[$i];
        LibTmux::X::InvalidSelection->throw(
            message => "member $i is not a " . $self->_kind . " entity")
            unless exists($self->[$i])
            && blessed($item)
            && $item->isa('LibTmux::Entity')
            && $item->kind eq $self->_kind;
        my $owner = $item->server_id . "\0" . $item->generation;
        $identity //= $owner;
        LibTmux::X::InvalidSelection->throw(
            message => 'selection mixes server identities or generations')
            unless $owner eq $identity;
    }
    return $self;
}

sub _filter ($self, $criteria) {
    require LibTmux::Filter;
    my $filter;
    if (blessed($criteria) && $criteria->isa('LibTmux::Filter')) {
        $filter = $criteria;
        LibTmux::X::InvalidFilter->throw(
            message => 'compiled filter has a different entity kind')
            unless $filter->entity eq $self->_kind;
    }
    else {
        $filter =
            LibTmux::Filter->new(entity => $self->_kind, where => $criteria);
    }
    return $filter;
}

sub where ($self, $criteria) {
    my $filter = $self->_filter($criteria);
    $self->_validate;
    return ref($self)->new(CORE::grep { $filter->matches($_) } @$self);
}

sub grep ($self, $callback) {
    LibTmux::X::InvalidArgument->throw(message => 'grep requires one coderef')
        unless ref($callback) eq 'CODE';
    $self->_validate;
    my @out;
    for my $item (@$self) {
        my $argument = $item;
        local $_ = $item;
        push @out, $item if scalar $callback->($argument);
    }
    return ref($self)->new(@out);
}
sub to_array ($self) { $self->_validate; return [@$self] }

sub _matches ($self, @criteria) {
    LibTmux::X::InvalidArgument->throw(
        message => 'expected at most one criterion')
        if @criteria > 1;
    my $filter = @criteria ? $self->_filter($criteria[0]) : undef;
    $self->_validate;
    return $filter;
}

sub count ($self, @criteria) {
    my $filter = $self->_matches(@criteria);
    return scalar @$self unless $filter;
    my $n = 0;
    for my $item (@$self) { $n++ if $filter->matches($item) }
    return $n;
}

sub exists ($self, @criteria) {
    defined($self->first(@criteria)) ? true : false;
}

sub first ($self, @criteria) {
    my $filter = $self->_matches(@criteria);
    for my $item (@$self) {
        return $item if !$filter || $filter->matches($item);
    }
    return undef;
}

sub _one ($self, $optional, @criteria) {
    my $filter = $self->_matches(@criteria);
    my @found;
    for my $item (@$self) {
        next if $filter && !$filter->matches($item);
        push @found, $item;
        LibTmux::X::MultipleMatches->throw(
            entity      => $self->_kind,
            matched_ids => [map { $_->id } @found],
            count       => 'at least two',
            message => 'expected at most one occurrence; matched at least two'
        ) if @found == 2;
    }
    return $found[0] if @found;
    return undef     if $optional;
    LibTmux::X::NoMatch->throw(
        entity      => $self->_kind,
        matched_ids => [],
        count       => 0,
        message     => 'expected exactly one occurrence; matched none'
    );
}
sub one          ($self, @criteria) { $self->_one(false, @criteria) }
sub one_or_undef ($self, @criteria) { $self->_one(true,  @criteria) }

sub iterator ($self) {
    $self->_validate;
    bless {items => [@$self], next => 0}, 'LibTmux::Selection::Iterator';
}

=head1 NAME

LibTmux::Selection - Native array selections with fixed query returns

=head1 METHODS

=head2 new

C<new(@entities)> creates a concrete blessed array reference and validates every member. Construct an entity-specific selection such as L<LibTmux::PaneSelection>; an empty instance retains that schema.

Members may come from separate captures of the same server generation; each
retains its own observation. Mixing servers or daemon generations throws
L<LibTmux::X/InvalidSelection>. Combining captures does not reconcile their times.

=head2 where

C<where($criteria_or_filter)> eagerly returns a new selection of the same concrete class in scalar, list, or void context. Complete validation precedes evaluation, including on empty input. See L<LibTmux::Filter/new>. Order and duplicate occurrences are preserved.

=head2 grep

C<grep($callback)> returns a new same-class selection. Invoke the callback in scalar context with exactly one entity argument and a localized C<$_>. Both bindings hold copies of the reference: assignment cannot replace a source slot. Restore C<$_> and propagate the original thrown value even on failure. Predicates must not edit the traversed sequence.

=head2 count

C<count($criteria?)> returns an integer. Empty input returns zero. Validate all members before evaluating the optional criterion; count every matching occurrence, including duplicates.

=head2 exists

C<exists($criteria?)> returns a native Boolean. Empty input returns false. After validating the entire membership, stop at the first matching entity. A reference itself remains true even when empty.

=head2 first

C<first($criteria?)> returns the first matching entity or undef. Input order determines first; after membership validation, later field reads may be skipped.

=head2 one

C<one($criteria?)> returns one entity. Zero throws L<NoMatch|LibTmux::X/NoMatch>; a second occurrence throws L<MultipleMatches|LibTmux::X/MultipleMatches>, reporting at least two and their IDs. Two occurrences of one identity are still ambiguous.

=head2 one_or_undef

C<one_or_undef($criteria?)> returns an entity or undef for absence. A second matching occurrence still throws L<MultipleMatches|LibTmux::X/MultipleMatches>.

=head2 iterator

Return a fresh local cursor with a copy of current membership. Its C<next> returns an entity or undef only at exhaustion. Later native array edits do not alter this traversal; the selection remains replayable.

=head2 to_array

Return a fresh, unblessed array reference containing the same entity references. Editing its membership cannot corrupt graph adjacency or this selection. Captured entity values remain read-only through public readers.

=head1 EXECUTION

All methods in this module operate on local captured data and perform no tmux
I/O. Ordering is deterministic; public query methods do not mutate membership.
Typed validation/evaluation errors propagate. See L<LibTmux::Server/snapshot>
for explicit acquisition and L<LibTmux::X> for machine-readable failures.

=cut
