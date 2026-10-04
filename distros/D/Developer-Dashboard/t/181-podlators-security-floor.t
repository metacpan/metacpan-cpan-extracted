#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

my $ROOT = File::Spec->rel2abs( File::Spec->catdir( $FindBin::Bin, File::Spec->updir ) );
my $cpanfile = _slurp('cpanfile');
my $makefile = _slurp('Makefile.PL');
my $dist     = _slurp('dist.ini');
my $cli      = _slurp('bin/dashboard');
my $audit    = _slurp('script/cpan-audit-project');
my $exclude  = _slurp('cpan-audit-exclusions.txt');

like( $cli, qr/use\s+Pod::Usage\b/, 'the CLI has a Pod::Usage help-rendering surface' );
like( $cpanfile, qr/requires\s+'Pod::Text'\s*,\s*'6\.1\.1'\s*;/,
    'cpanfile requires the fixed Pod::Text release' );
like( $makefile, qr/'Pod::Text'\s*=>\s*'6\.1\.1'/,
    'Makefile.PL requires the fixed Pod::Text release' );
like( $dist, qr/^Pod::Text\s*=\s*6\.1\.1$/m,
    'dist.ini requires the fixed Pod::Text release' );
like( $audit, qr/Pod::Text.*6\.1\.1/s,
    'the audit gate verifies the actual Pod::Text version loaded from its scanned root' );
like( $audit, qr/CPANSA-podlators-2026-82560/,
    'the gate documents the specific podlators audit mapping disposition' );
like( $exclude, qr/^CPANSA-podlators-2026-82560$/m,
    'only the reviewed podlators advisory is excluded after the direct module guard' );

done_testing;

# Purpose: read one repository file as text for dependency-floor assertions.
# Input:   a repository-relative path.
# Output:  the complete file contents, or an empty string if it is absent.
sub _slurp {
    my ($relative) = @_;
    my $path = File::Spec->catfile( $ROOT, split m{/}, $relative );
    return '' if !-f $path;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "Unable to close $path: $!";
    return defined $content ? $content : '';
}

__END__

=head1 NAME

t/181-podlators-security-floor.t - require a fixed Pod::Text release

=head1 PURPOSE

Verify that the CLI's C<Pod::Usage> help path has an explicit distribution
dependency on C<Pod::Text> 6.1.1 or later in C<cpanfile>, C<Makefile.PL>, and
C<dist.ini>.

=head1 WHY IT EXISTS

The CI isolated dependency audit found C<podlators> 6.0.2, whose C<Pod::Text>
implementation is vulnerable to CPU and memory exhaustion when formatting
attacker-controlled deeply nested POD. The dashboard CLI invokes C<Pod::Usage>,
which uses C<Pod::Text> to render usage text. Without an explicit minimum, a
fresh install can resolve an affected release even when the runtime dependency
chain audit looks clean. CPAN::Audit's installed scanner can identify the
podlators distribution through C<Pod::Man>'s independent module version rather
than the affected C<Pod::Text> version. The gate therefore verifies the loaded
module path and minimum itself before applying its exact advisory disposition.

=head1 WHEN TO USE

Run this test after changing CLI help rendering or dependency metadata, and
before building a release that contains the C<Pod::Usage> invocation.

=head1 HOW TO USE

    prove -lv t/181-podlators-security-floor.t

The test is self-contained and needs only core Perl modules and C<Test::More>.
It checks the application surface and each supported dependency declaration so
the build metadata cannot drift independently.

=head1 WHAT USES IT

The repository test suite runs this guard through C<prove -lr t>. The dependency
audit and package build rely on the same metadata floors to install a patched
C<podlators> distribution.

=head1 EXAMPLES

To inspect the guarded declarations, search C<cpanfile>, C<Makefile.PL>, and
C<dist.ini> for C<Pod::Text>. Removing or lowering any one declaration makes
this test fail with the specific metadata source identified in its assertion.

=cut
