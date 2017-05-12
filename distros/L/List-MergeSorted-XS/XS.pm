package List::MergeSorted::XS;

use 5.008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(merge);
our @EXPORT = qw();

our $VERSION = '1.06';

require XSLoader;
XSLoader::load('List::MergeSorted::XS', $VERSION);

use constant {
    PRIO_LINEAR => 0,
    PRIO_FIB    => 1,
    SORT        => 2,
};

sub merge {
    my $lists = shift;
    my %opts = @_;

    # validate inputs
    unless ($lists && ref $lists && ref $lists eq 'ARRAY') {
        die "merge requires an array reference";
    }
    for my $list (@$lists) {
        unless ($list && ref $list && ref $list eq 'ARRAY') {
            die "lists to merge must be arrayrefs";
        }
    }

    my $limit = $opts{limit} || 0;
    die "limit must be positive" if defined $limit && $limit < 0;

    die "key_cb option must be a coderef"
        if defined $opts{key_cb} && ref $opts{key_cb} ne 'CODE';

    die "uniq_cb option must be a coderef"
        if defined $opts{uniq_cb} && ref $opts{uniq_cb} ne 'CODE';

    return [] unless @$lists;

    # pick an algorithm
    my @params = ($lists, $limit, $opts{key_cb}, $opts{uniq_cb});

    if (defined $opts{method}) {
        return _merge($opts{method}, @params);
    }

    if (defined $opts{key_cb}) {
        # linear priority queue is faster until ~100 lists, relatively
        # independent of limit %. sort never wins in keyed mode because of
        # Schwartzian tx overhead

        return scalar @$lists < 100
            ? _merge(PRIO_LINEAR, @params)
            : _merge(PRIO_FIB, @params);
    }
    else {
        # linear always wins with a small number of lists (<100). with more
        # lists, fib wins with low limit, giving way to sort around 25%
        # limit.

        # compute what fraction of the merged set will be returned
        my $total = _count_elements($lists);
        $limit ||= $total;

        if ($limit < 0.05 * $total) {
            return scalar @$lists < 1000
                ? _merge(PRIO_LINEAR, @params)
                : _merge(PRIO_FIB, @params);
        }
        elsif ($limit < 0.25 * $total) {
            return scalar @$lists < 500
                ? _merge(PRIO_LINEAR, @params)
                : _merge(PRIO_FIB, @params)
        }
        elsif ($limit < 0.75 * $total) {
            return scalar @$lists < 100
                ? _merge(PRIO_LINEAR, @params)
                : _merge(SORT, @params)
        }
        else {
            return scalar @$lists < 100
                ? _merge(PRIO_LINEAR, @params)
                : _merge(SORT, @params)
        }
    }
}

# dispatch to appopriate implementation based on algorithm and options
sub _merge {
    my ($method, $lists, $limit, $key_cb, $uniq_cb) = @_;

    if ($method == PRIO_LINEAR) {
        return $key_cb ? $uniq_cb ? _merge_linear_keyed_dedupe($lists, $limit, $key_cb, $uniq_cb)
                                  : _merge_linear_keyed_dupeok($lists, $limit, $key_cb)
                       : $uniq_cb ? _merge_linear_flat_dedupe($lists, $limit, $uniq_cb)
                                  : _merge_linear_flat_dupeok($lists, $limit);
    }
    elsif ($method == PRIO_FIB) {
        return $key_cb ? $uniq_cb ? _merge_fib_keyed_dedupe($lists, $limit, $key_cb, $uniq_cb)
                                  : _merge_fib_keyed_dupeok($lists, $limit, $key_cb)
                       : $uniq_cb ? _merge_fib_flat_dedupe($lists, $limit, $uniq_cb)
                                  : _merge_fib_flat_dupeok($lists, $limit);
    }
    elsif ($method == SORT) {
        return $key_cb ? $uniq_cb ? _merge_sort_keyed_dedupe($lists, $limit, $key_cb, $uniq_cb)
                                  : _merge_sort_keyed_dupeok($lists, $limit, $key_cb)
                       : $uniq_cb ? _merge_sort_flat_dedupe($lists, $limit, $uniq_cb)
                                  : _merge_sort_flat_dupeok($lists, $limit);
    }
    else {
        die "unknown sort method $method requested\n";
    }
}

# concatenate all lists and sort the whole thing. works well when no limit is
# given.

sub _merge_sort_flat_dupeok {
    my ($lists, $limit) = @_;

    my @output = sort {$a <=> $b} map {@$_} @$lists;
    splice @output, $limit if $limit && @output > $limit;
    return \@output;
}

sub _merge_sort_keyed_dupeok {
    my ($lists, $limit, $keyer) = @_;

    # Schwartzian transform is faster than sorting on
    # {$keyer->($a) <=> # $keyer->($b)}, even for degenerately simple case
    # of $keyer = sub { $_[0] }

    my @output =
        map  { $_->[1] }
        sort { $a->[0] <=> $b->[0] }
        map  { [$keyer->($_), $_] }
        map  { @$_ }
        @$lists;

    splice @output, $limit if $limit && @output > $limit;
    return \@output;
}

sub _merge_sort_flat_dedupe {
    my ($lists, $limit, $uniquer) = @_;

    my @merged = sort {$a <=> $b} map {@$_} @$lists;

    my @output;
    my $last_unique = undef;
    for my $element (@merged) {
        my $unique = $uniquer->($element);
        next if defined $last_unique && $unique == $last_unique;
        push @output, $element;
        $last_unique = $unique;
    }
    splice @output, $limit if $limit && @output > $limit;
    return \@output;
}

sub _merge_sort_keyed_dedupe {
    my ($lists, $limit, $keyer, $uniquer) = @_;

    my @merged =
        map  { $_->[1] }
        sort { $a->[0] <=> $b->[0] }
        map  { [$keyer->($_), $_] }
        map  { @$_ }
        @$lists;

    my @output;
    my %seen;
    for my $element (@merged) {
        my $unique = $uniquer->($element);
        next if $seen{$unique}++;
        push @output, $element;
    }

    splice @output, $limit if $limit && @output > $limit;
    return \@output;
}

1;
__END__

=head1 NAME

List::MergeSorted::XS - Fast merger of presorted lists

=head1 SYNOPSIS

  use List::MergeSorted::XS 'merge';

  # merge plain integer lists
  @lists = ([1, 3, 5], [2, 6, 8], [4, 7, 9]);
  merge(\@lists); # [1..9]

  # return only beginning of union
  merge(\@lists, limit => 4); # [1..4]

  # remove duplicates
  @lists = ([1, 2], [0, 2, 3], [3, 4]);
  merge(\@lists, uniq_cb => sub { $_[0] }); # [0..4]

  # merge complicated objects based on accompanying integer keys
  @lists = ([
              [1 => 'x'], [3 => {t => 1}]
            ],
            [
              [2 => bless {}, 'C'], [4 => 5]
            ]);
  $sorted = merge(\@lists, key_cb => sub { $_[0][0] });

=head1 DESCRIPTION

This module takes a set of presorted lists and returns the sorted union of
those lists.

To maximize speed, an appropriate algorithm is chosen heuristically based on
the size of the input data; additionally, efficient C implementations of the
algorithms are used.

=head1 FUNCTIONS

=over 4

=item $merged = merge(\@list_of_lists, %opts)

Computes the sorted union of a set of lists of integers. The first parameter
must be an array reference which itself contains a number of array references.
The result set is returned in an array reference.

The constituent lists must meet these preconditions for correct behavior:

=over 4

=item * either each element of each list is an integer or an integer may be
        computed from the element using the C<key_cb> parameter below

=item * each list is pre-sorted in ascending order

=back

C<merge>'s behavior may be modified by additional options passed after the list:

=over 4

=item * limit

Specifies a maximum number of elements to return. By default all elements are
returned.

=item * key_cb

Specifies a callback routine which will be passed an element of an inner list
through @_. The routine must return the integer value by which the element will be
sorted. In effect, the default callback is C<sub {$_[0]}>. This allows more
complicated structures to be merged.

=item * uniq_cb

Specifies a callback routine which will be passed an element of an inner list
through @_. The routine must return the integer value which identifies the
element in some sense. Elements with the same identity value will not be
duplicated in the output. Elements with the same identity must also have the
same key.

If no uniq_cb is passed, duplicates are allowed in the output.

=item * method

Specifies the algorithm to use to merge the lists. If provided, the value must
be one of the constants listed below under L<ALGORITHM>.

If no B<method> is given, one is chosen automatically based upon the input
data. This is generally recommended.

=back

=back

=head1 NOTES

Only ascending order is supported. To merge lists which are sorted in
descending order, use C<< key_cb => sub { -$_[0] } >>.

=head1 EXPORTS

None by default, C<merge> at request.

=head1 ALGORITHM

The algorithm used to merge the lists is heuristically chosen based on the
number of lists (N), the total number of elements in the lists (M), and the
requested limit (L). (The heuristic constants were determined by analysis of
benchmarks on a 2.5GHz Intel Xeon where all data fit in memory.)

When there are many lists and the element limit is a significant fraction of
the total element count (L/M > 1/4), perl's built-in C<sort> is used to order
the concatenated lists. The time complexity is C<O(M log M)>. Since this method
always processes the full list, it cannot short-circuit in the highly-limited
case (as the priority queue methods do).

When L is a smaller fraction of M, a priority queue is used to track the list
heads. For small N, this is implemented as a linked list kept in sorted order
(using linear-time insertion), yielding time complexity of C<O(L N)>. For large
N, a Fibonacci heap is used, for a time complexity of C<O(L log N)>. The linked
list has less bookkeeping overhead than the heap, so it is more efficient for
fewer lists.

To force a particular implementation, pass the C<method> parameter to C<merge>
with one of these constants:

=over 4

=item * List::MergeSorted::XS::SORT

=item * List::MergeSorted::XS::PRIO_LINEAR

=item * List::MergeSorted::XS::PRIO_FIB

=back

=head1 TODO

* Support comparative orderings, where no mapping from elements to integers
exists but a well-defined ordering exists for which a two-element comparison
callback can be provided.

* Allow modification of the heuristics (perhaps based on local benchmarks).

=head1 SEE ALSO

John-Mark Gurney's Fibonacci heap library L<fib|http://resnet.uoregon.edu/~gurney_j/jmpc/fib.html>

=head1 AUTHOR

Adam Thomason, E<lt>athomason@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Say Media Inc <cpan@saymedia.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut
