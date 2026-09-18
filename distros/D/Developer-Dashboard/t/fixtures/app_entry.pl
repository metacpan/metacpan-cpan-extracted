#!/usr/bin/env perl

use strict;
use warnings;
use HybridLoad ();
use ResidualOnly ();
use SlowLoad ();

my $cmd = shift @ARGV // 'status';
if ($cmd eq 'status') {
    print SlowLoad::message(), "\n";
    exit 0;
}

if ($cmd eq 'asset') {
    my $root = $ENV{PAX_EMBEDDED_ASSET_ROOT} // '';
    my $path = $root ? "$root/banner.txt" : '';
    if (!$path || !-f $path) {
        print STDERR "missing asset\n";
        exit 3;
    }
    open my $fh, '<', $path or die $!;
    my $content = <$fh>;
    close $fh;
    print $content;
    exit 0;
}

if ($cmd eq 'hybrid-fast') {
    print HybridLoad::fast_message(), "\n";
    exit 0;
}

if ($cmd eq 'hybrid-slow') {
    print HybridLoad::slow_message('alpha:beta'), "\n";
    exit 0;
}

if ($cmd eq 'residual-only') {
    print ResidualOnly::reverse_words('one two three'), "\n";
    exit 0;
}

print STDERR "unknown command: $cmd\n";
exit 2;

__END__

=head1 NAME

t/fixtures/app_entry.pl - fixture: a realistic multi-command application with embedded-asset access and mixed eager/lazy module loading

=head1 PURPOSE

A small multi-command application entrypoint (status/asset/hybrid-fast/hybrid-slow/residual-only) used by the standalone app-image tests to exercise a compiled binary that still needs to read an embedded asset file (via PAX_EMBEDDED_ASSET_ROOT) and dispatch across several companion modules (HybridLoad, ResidualOnly, SlowLoad) loaded at different times.

=head1 WHY IT EXISTS

Ported from PAX's own upstream fixture corpus as part of DD-882's vendoring
of the whole PAX compiler into C<Developer::Dashboard::Pax::*>, so the same
narrow edge case PAX's own maintainers already tested against - a realistic multi-command application with embedded-asset access and mixed eager/lazy module loading -
keeps being exercised against the vendored copy exactly as it was against
the original.

=head1 WHEN TO USE

Change this file only when the specific behavior it captures needs to
change. Add a new, separate fixture for a different edge case rather than
widening this one's scope - each fixture in this directory is deliberately
narrow.

=head1 HOW TO USE

Built and run via C<pax build>/C<pax run> against this file as an
entrypoint, driven from t/183-pax-cli-build-run-contract.t. Each subcommand exercises a different code path: C<status> calls SlowLoad, C<asset> reads a file under C<$ENV{PAX_EMBEDDED_ASSET_ROOT}>, C<hybrid-fast>/C<hybrid-slow> call HybridLoad, and C<residual-only> calls ResidualOnly.

=head1 WHAT USES IT

t/183-pax-cli-build-run-contract.t, exercising the vendored PAX compiler's
handling of this specific case during build and run.

=head1 EXAMPLES

Running it interpreted, the baseline behavior a compiled version must match:

    perl t/fixtures/app_entry.pl

Building and running it through the vendored PAX compiler:

    pax build t/fixtures/app_entry.pl -o /tmp/out && /tmp/out

=cut
