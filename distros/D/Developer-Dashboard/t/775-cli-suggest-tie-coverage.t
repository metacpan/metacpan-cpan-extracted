#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Developer::Dashboard::CLI::Suggest;

my $self = bless {}, 'Developer::Dashboard::CLI::Suggest';

# Two distinct candidates with the same score and the same length fall through
# to the final alphabetical tiebreak.
my @ranked = $self->_rank_candidates( 'aa', [ 'aac', 'aab' ] );
is_deeply( [ map { $_->{value} } @ranked ], [ 'aab', 'aac' ], 'equal score and length candidates sort alphabetically' );

done_testing;

__END__

=pod

=head1 NAME

t/775-cli-suggest-tie-coverage.t - covers the alphabetical tiebreak of the Suggest ranking

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It ranks two candidates of equal score and length so the final tiebreak runs.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate allows no uncoverable annotations, so every branch in the covered modules must be reached by a real test that also works when the suite runs as root.

=head1 WHEN TO USE

Use this file when you change the code it covers, or when a coverage run reports one of its lines, branches or conditions as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/775-cli-suggest-tie-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/775-cli-suggest-tie-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/775-cli-suggest-tie-coverage.t

Confirm the targeted lines are reported as covered.

=cut
