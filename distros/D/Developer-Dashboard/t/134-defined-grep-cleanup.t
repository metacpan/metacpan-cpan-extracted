#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Cwd qw(abs_path);
use File::Find qw(find);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use Test::More;

my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );

# Hermetic runtime: this is a read-only source scan, but HOME and the working
# directory are still isolated so no .developer-dashboard layer under the real
# home can be discovered, written to, or influence the run. $ROOT is resolved
# to an absolute path before the chdir so the scan still finds the checkout.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

# A redundant definedness filter over the direct output of split. Perl's split
# only ever returns defined strings for a pattern with no capture groups, so a
# `defined` term in a grep block applied straight to a split expression can
# never take its false side: it is dead code that forces an unreachable
# branch/condition onto the coverage report. Every accepted spelling of the
# dead term is matched here - a bare `defined`, `defined $_`, and
# `defined($_)` - with or without further `&&`-joined predicates after it.
my $DEFINED_TERM = qr/ defined (?: \s* \( \s* \$_ \s* \) | \s+ \$_ )? /x;
my $REDUNDANT_RE = qr/
    \b grep \s* \{ \s*
    $DEFINED_TERM
    \s* (?: && [^}]* )?
    \} \s*
    split \b
/x;

# Sanity-check the detector itself before trusting an empty offender list: a
# green result is only meaningful if the pattern still recognises the shapes it
# is meant to reject, and still ignores the shapes that are legitimately needed.
my @must_match = (
    q{my @p = grep { defined } split /:/, $spec;},
    q{my @p = grep { defined && $_ ne '' } split m{/+}, $route;},
    q{my @p = grep { defined $_ && $_ ne '' } split /\./, $command;},
    q{my @p = grep { defined($_) && $_ ne '' } split /\n/, $text;},
    q{my $n = scalar grep { defined } split /\n/, $board;},
);
like( $_, $REDUNDANT_RE, "detector rejects the redundant split-derived filter: $_" ) for @must_match;

my @must_not_match = (
    q{my @p = grep { $_ ne '' } split /:/, $spec;},
    q{my @terms = grep { defined && $_ ne '' } @terms;},
    q{my @roots = grep { defined && -d } map { "$home/$_" } qw(projects src work);},
    'for my $line ( split /\n/, defined($text) ? $text : q{} ) {',
    q{my @p = grep { $_ ne '' } split /:/, ( defined $keys ? $keys : '' );},
);
unlike( $_, $REDUNDANT_RE, "detector leaves the legitimate filter alone: $_" ) for @must_not_match;

# The scan is line-oriented on purpose: every such expression in this codebase
# is written on a single line, and a line number is what a failure needs to
# report so the offending expression can be fixed directly.
my @offenders;
find(
    {
        no_chdir => 1,
        wanted   => sub {
            return if !-f $_ || $_ !~ /\.pm\z/;

            open my $fh, '<', $_ or die "Unable to read $_: $!";
            while ( my $line = <$fh> ) {
                push @offenders, File::Spec->abs2rel( $_, $ROOT ) . ":$."
                  if $line =~ $REDUNDANT_RE;
            }
            close $fh or die "Unable to close $_: $!";
        },
    },
    File::Spec->catdir( $ROOT, 'lib' ),
);

is_deeply(
    [ sort @offenders ],
    [],
    'split-derived grep filters do not retain a redundant defined check',
);

# Acceptance: the surviving non-empty filter is the whole of the behaviour the
# removed defined term was bundled with, so a split-derived list still loses its
# empty fields and keeps everything else in order.
is_deeply(
    [ grep { $_ ne '' } split m{/+}, '/alpha//beta/' ],
    [ 'alpha', 'beta' ],
    'a simplified split-derived filter still excludes empty fields and preserves order',
);

done_testing;

__END__

=pod

=head1 NAME

t/134-defined-grep-cleanup.t - enforce concise filters for split-derived fields

=head1 PURPOSE

This source-policy test finds Perl module lines that filter the direct output of
C<split> through a grep block containing a definedness term. Perl C<split>
returns defined strings for a pattern with no capture groups, so such a term can
never take its false side: it adds an unreachable branch or condition to the
coverage report without changing the resulting list. The test also verifies its
own detector against both offending and legitimate spellings, then asserts that
a simplified filter still drops empty fields.

=head1 WHY IT EXISTS

A broader cleanup previously removed C<defined> from filters whose inputs could
legitimately contain undefined values, which produced uninitialized-value
warnings in routines that are deliberately called with undef. This narrower
contract distinguishes the safe, split-derived cases from argument, environment,
and hash-derived lists where preserving C<defined> remains necessary for
warning-free behaviour, and it keeps the safe cases from creeping back in.

=head1 WHEN TO USE

Run this test when editing list normalization, route parsing, path parsing,
colon-separated environment variables, terminal line counting, or coverage
annotations around Perl C<split> expressions. Use it before applying mechanical
grep-filter cleanup so only expressions with guaranteed-defined inputs are
changed, and after adding a new module that parses split output.

=head1 HOW TO USE

Run C<prove -lv t/134-defined-grep-cleanup.t> for the focused source-policy
check. A failure reports every module and line that still applies a definedness
term to direct C<split> output. Review each reported expression to confirm that
C<split> is the actual list producer, then remove only the redundant term and
its obsolete coverage annotation, leaving any non-empty comparison in place.
Follow with the affected module tests and C<prove -lr t>.

=head1 WHAT USES IT

Developers performing safe condition cleanup, the repository test suite, and the
coverage gate use this file. It protects the distinction between split-derived
values, which are always defined, and caller-provided values that may
legitimately be undefined.

=head1 EXAMPLES

Example 1:

  prove -lv t/134-defined-grep-cleanup.t

Run the focused policy test and inspect any reported module-line pairs.

Example 2:

  prove -lv t/134-defined-grep-cleanup.t t/64-cli-progress-coverage.t

Run the policy test together with the renderer coverage test that pins the
rendered line count derived from a split expression, confirming the cleanup is
behaviour-preserving.

=cut
