#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;

use lib 'lib';
use Developer::Dashboard::IndicatorStore;

# _indicator_sort_cmp is a private method, but it takes no state from $self
# beyond the invocant itself, so a bare bless is enough to call it directly
# without constructing a full IndicatorStore (matching this project's own
# convention of testing small private comparators in isolation elsewhere).
my $store = bless {}, 'Developer::Dashboard::IndicatorStore';

# DD-885: priority => 0 must sort FIRST (lower priority sorts first, per
# the built-in indicators' own convention: docker=20, git=30, project=50),
# not last. The bug was `$left->{priority} || 999`, which treats 0 as
# falsy and silently substitutes the "unset" default.
ok(
    $store->_indicator_sort_cmp( { name => 'zero-prio', priority => 0 }, { name => 'normal', priority => 50 } ) < 0,
    'AC-1: priority=>0 sorts before priority=>50 (comparator returns negative)'
);

ok(
    $store->_indicator_sort_cmp( { name => 'zero-prio', priority => 0 }, { name => 'unset' } ) < 0,
    'AC-2: priority=>0 sorts before an indicator with no priority set at all (0 beats the 999 default)'
);

# AC-3: unaffected behavior - unset-vs-unset ties on priority (both fall
# back to 999) and falls through to the comparator's own name tie-break,
# rather than being decided by priority at all.
is(
    $store->_indicator_sort_cmp( { name => 'same' }, { name => 'same' } ),
    0,
    'AC-3: two unset-priority indicators with the same name are a full tie (priority AND name tie-break both agree)'
);
ok(
    $store->_indicator_sort_cmp( { name => 'a' }, { name => 'b' } ) < 0,
    'AC-3: two unset-priority indicators fall through to the name tie-break (not decided by priority, which ties at 999 for both)'
);

ok(
    $store->_indicator_sort_cmp( { name => 'low', priority => 20 }, { name => 'high', priority => 50 } ) < 0,
    'AC-3: ordering among two positive priorities is unaffected (20 still sorts before 50)'
);

done_testing;

__END__

=head1 NAME

t/186-indicator-sort-cmp-zero-priority.t - _indicator_sort_cmp treats
priority => 0 as a real, sort-first value

=head1 PURPOSE

Proves the fix for DD-885: C<Developer::Dashboard::IndicatorStore>'s
C<_indicator_sort_cmp> used C<$left-E<gt>{priority} || 999>, which treats
Perl's falsy C<0> the same as an unset priority - silently sorting an
indicator explicitly configured with the lowest, sort-first priority value
dead last instead.

=head1 WHY IT EXISTS

Found by this session's hourly bug-hunt automation, reproduced live
against the running comparator (returned C<1> - sorts after - for a
C<priority =E<gt> 0> indicator compared against C<priority =E<gt> 50>,
when a correct comparator returns a negative number). This test is the
permanent regression guard for the fix (C<defined($priority) ? $priority :
999>, matching the already-correct C<collector_order> handling two lines
below in the same function).

=head1 WHEN TO USE

Run this file whenever C<_indicator_sort_cmp> or the indicator-priority
contract it implements changes. See also C<t/02-indicator-collector.t> for
the broader indicator-ordering contract this file does not duplicate.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/186-indicator-sort-cmp-zero-priority.t

=head1 WHAT USES IT

The suite, through C<prove -lr t>. Its subject is
L<Developer::Dashboard::IndicatorStore>'s sort comparator, as consumed by
the web status strip and C<dashboard ps1> prompt rendering wherever the
full indicator set is displayed in order.

=head1 EXAMPLES

Watching this fail on a reintroduced regression: revert
C<_indicator_sort_cmp>'s priority read back to
C<$left-E<gt>{priority} || 999>, then rerun - AC-1 and AC-2 both fail,
since a C<priority =E<gt> 0> indicator is again silently treated as
unset and sorted last (returns C<1> instead of a negative number).

=cut
