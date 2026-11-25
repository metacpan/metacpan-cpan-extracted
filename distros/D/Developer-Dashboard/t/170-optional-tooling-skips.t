#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Capture::Tiny qw(capture);
use Test::More;

my $repo = abs_path('.');

# The specs under test. Each exercises the coverage gate, whose subject cannot be
# measured at all without a Devel::Cover to write or read a database - so each must
# SKIP when the module is unavailable rather than report its assertions as failures.
my @SPECS = qw(
  t/148-coverage-gate-entrypoint.t
  t/149-coverage-gate-moving-target.t
  t/150-coverage-gate-lock-rename.t
  t/151-coverage-gate-launch-boundary.t
  t/138-coverage-exec-truncation.t
);

# _blocker_lib()
# Builds a temporary library directory holding a module that masks Devel::Cover
# from any process that loads it.
# Input: none.
# Output: the directory path, and the module name to load from it.
sub _blocker_lib {
    my $dir = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $dir, 'DDNoCover' ) );
    my $pm = File::Spec->catfile( $dir, 'DDNoCover.pm' );
    open my $fh, '>', $pm or die "cannot write blocker: $!";
    # An @INC hook that refuses Devel/Cover*.pm. `eval { require ...; 1 }` is false
    # whether the module is genuinely absent or refused here, and that eval is
    # exactly what a skip guard tests - so this reproduces the condition the guard
    # must react to, on a host that has the module installed.
    print {$fh} <<'PERL';
package DDNoCover;
use strict;
use warnings;
BEGIN {
    unshift @INC, sub {
        my ( undef, $file ) = @_;
        die "DDNoCover: $file is masked for this test\n" if $file =~ m{^Devel/Cover};
        return;
    };
}
1;
PERL
    close $fh;
    return $dir;
}

# _run_without_cover($spec)
# Runs one spec in its own process with Devel::Cover masked.
# Input: the spec path relative to the repository root.
# Output: hashref of exit status and combined output.
sub _run_without_cover {
    my ($spec) = @_;
    my $lib = _blocker_lib();
    my ( $out, $err, $status ) = capture {
        local $ENV{PERL5OPT}            = "-I$lib -MDDNoCover";
        local $ENV{HARNESS_PERL_SWITCHES} = '';
        system $^X, '-Ilib', $spec;
    };
    return { exit => $status, text => ( $out // '' ) . ( $err // '' ) };
}

for my $spec (@SPECS) {
    my $result = _run_without_cover($spec);
    like(
        $result->{text},
        qr/^1\.\.0#\s*SKIP|# SKIP|1\.\.0/m,
        "$spec skips when Devel::Cover cannot be loaded, instead of reporting failures",
    );
    like(
        $result->{text},
        qr/Devel::Cover/,
        "$spec names Devel::Cover in its skip reason, so a reader knows what to install",
    );
    is( $result->{exit}, 0, "$spec exits 0 when it skips, so the suite does not report an environmental gap as a defect" );
    unlike(
        $result->{text},
        qr/Bad plan/,
        "$spec does not declare a plan it then abandons - the guard runs before the plan",
    );
}

done_testing;

__END__

=head1 NAME

t/170-optional-tooling-skips.t - the coverage-gate specs skip when Devel::Cover is absent

=head1 PURPOSE

Prove that every spec whose subject is the coverage tooling SKIPS, with a reason
naming Devel::Cover, when that module cannot be loaded - rather than reporting its
assertions as failures.

=head1 WHY IT EXISTS

Measured in C<developer-dashboard:latest>, which carries every declared runtime
dependency and not Devel::Cover: C<t/148> failed 29 of 50 and C<t/151> died after 3
of a planned 9. The gate itself behaves correctly there and says so - "Devel::Cover::DB::IO
could not be loaded ... install Devel::Cover" - but the specs assert a different
message and so report an environmental gap as a defect, which is indistinguishable
from a real one to anyone reading the output.

The regression is invisible to CI, which has Devel::Cover installed. Without this
file the guards could be removed and nothing would notice until someone ran the
suite in a container - which is the same failure this card was filed for.

=head1 WHEN TO USE

Runs with the suite. Consult it when changing a skip guard in any coverage-tooling
spec, or when adding a spec that needs an optional tool.

=head1 HOW TO USE

  PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/170-optional-tooling-skips.t

It masks Devel::Cover with an C<@INC> hook in a child process, so it exercises the
absent case on a host that has the module installed.

=head1 WHAT USES IT

The full suite, and the coverage gate indirectly - these specs are what stands
between a missing optional tool and a suite that reports it as a product defect.

=head1 EXAMPLES

A passing run reports, for each spec, that it skipped, that the reason names
Devel::Cover, that the exit status was 0, and that no "Bad plan" line appeared.

=cut
