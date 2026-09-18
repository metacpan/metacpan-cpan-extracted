#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

# DD-923: a PAX-compiled binary garbled literal UTF-8 characters that live
# in a REQUIRED LIBRARY MODULE's top-level `our $VAR = '...';` initializer
# (Developer::Dashboard::IndicatorStore's status icons, used by
# `dashboard ps1`) - correct when interpreted, mojibake when compiled.
# This test reproduces the defect against a REAL `pax build` output (never
# a seeded fake binary - see DD-924's card for why a seeded fixture cannot
# exercise this class of bug), using a minimal standalone fixture module so
# the test stays fast rather than compiling the whole dashboard binary.

my $repo = abs_path("$FindBin::Bin/..");
my $pax  = File::Spec->catfile( $repo, 'share', 'private-cli', 'pax' );

local $ENV{PAX_PROGRESS} = 0;
local $ENV{PERL5LIB} = defined $ENV{PERL5LIB} && $ENV{PERL5LIB} ne ''
    ? "$repo/lib:$ENV{PERL5LIB}"
    : "$repo/lib";

my $work = tempdir( CLEANUP => 1 );
my $lib_dir = File::Spec->catdir( $work, 'lib' );
make_path($lib_dir);

my $module_path = File::Spec->catfile( $lib_dir, 'DD923UtfFixture.pm' );
open my $mfh, '>:encoding(UTF-8)', $module_path or die "cannot write $module_path: $!";
print {$mfh} <<'PERLMOD';
package DD923UtfFixture;
use strict;
use warnings;
use utf8;
our $VERSION = '1.0';
our $ICON = '🚨';
1;
PERLMOD
close $mfh;

my $entry_path = File::Spec->catfile( $work, 'dd923-utf-entry.pl' );
open my $efh, '>:encoding(UTF-8)', $entry_path or die "cannot write $entry_path: $!";
print {$efh} <<'PERLENTRY';
#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
no warnings 'once';
use FindBin qw($Bin);
use lib "$Bin/lib";
binmode STDOUT, ':encoding(UTF-8)';
require DD923UtfFixture;
print "$DD923UtfFixture::ICON\n";
PERLENTRY
close $efh;
chmod 0755, $entry_path;

# Expected bytes: the correct 4-byte UTF-8 encoding of U+1F6A8 (🚨) plus a
# trailing newline - the same bytes an interpreted run produces.
my $expected = "\xf0\x9f\x9a\xa8\n";

{
    my $out = `"$^X" -I "$repo/lib" "$entry_path" 2>/dev/null`;
    is( $out, $expected, 'DD-923: interpreted run of the fixture prints the correct UTF-8 bytes (control)' );
}

my $bin_file = File::Spec->catfile( $work, 'dd923-utf-compiled' );

# pax build creates its own '.pax' scratch directory relative to the
# CALLER's current working directory (not relative to the pax tool or the
# entrypoint script) - chdir into the writable tempdir first so this test
# does not depend on the caller's own cwd being writable.
my $original_cwd = Cwd::getcwd();
chdir $work or die "cannot chdir to $work: $!";
my $build_out = `"$^X" "$pax" build --compact -o "$bin_file" "$entry_path" 2>&1`;
my $build_exit = $? >> 8;
chdir $original_cwd or die "cannot chdir back to $original_cwd: $!";

SKIP: {
    skip 'a real pax build did not succeed in this environment', 1
        if $build_exit != 0 || !-x $bin_file;

    my $out = `"$bin_file" 2>/dev/null`;
    is( $out, $expected,
        'DD-923: a REAL pax-compiled binary prints the correct UTF-8 bytes for a literal character in a required module (regression for CodeUnitCompiler embedding raw bytes as JSON without a UTF-8 decode step)'
    );
}

done_testing();

__END__

=pod

=head1 NAME

t/196-codeunitcompiler-utf8-round-trip.t - DD-923 regression: PAX-compiled
binaries must preserve literal non-ASCII characters from required modules

=head1 PURPOSE

Proves that C<Developer::Dashboard::Pax::CodeUnitCompiler> correctly
round-trips a literal UTF-8 character (such as the status icons in
C<Developer::Dashboard::IndicatorStore>, used by C<dashboard ps1>) through a
real C<pax build>, rather than corrupting it via a missing UTF-8 decode step
before the source text is embedded as a JSON string value.

=head1 WHY IT EXISTS

C<dashboard ps1>'s emoji indicators rendered correctly when interpreted but
as mojibake (raw UTF-8 bytes reinterpreted as Latin-1 and re-encoded) when
run from the PAX-compiled C<dashboard> binary. Root cause: C<CodeUnitCompiler::compile>
read C<.pm> source files with C<_slurp> (a raw C<:raw> byte read, correct
for content-addressing/hashing) and then used those same raw bytes,
undecoded, as the value embedded in a C<JSON::XS-E<gt>new-E<gt>ascii(1)>-encoded
record - each original UTF-8 byte was individually escaped as its own
C<\u00XX>, rather than the actual multi-byte character being escaped as one
(possibly surrogate-paired) codepoint. Fixed by explicitly UTF-8-decoding
the slurped source (C<Encode::decode('UTF-8', ...)>) before it is used for
extraction/embedding, in the two C<compile()> code paths (entrypoint and
library-module) that feed literal source text into these JSON records.

A prior test for this general mechanism (t/184-d2-self-compile.t) exists
but seeds a FAKE sentinel "compiled binary", which cannot exercise this
class of defect at all - see DD-924. This test therefore performs a REAL
C<pax build>, matching t/183-pax-cli-build-run-contract.t's precedent, and
is skipped (not failed) if a real PAX build cannot succeed in the current
environment.

=head1 WHEN TO USE

Run this whenever C<CodeUnitCompiler.pm>'s source-reading, initializer
extraction, or JSON-record embedding logic changes, or when adding new
literal non-ASCII content anywhere reachable from a compiled entrypoint or
required library module.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/196-codeunitcompiler-utf8-round-trip.t

=head1 WHAT USES IT

Guards C<lib/Developer/Dashboard/Pax/CodeUnitCompiler.pm>'s C<compile>
method, exercised indirectly by every C<dashboard>/C<d2> self-compile and
by C<dashboard ps1>'s emoji indicator rendering when run from a compiled
binary.

=head1 EXAMPLES

A green run proves a real compiled binary's output for a module containing
a literal C<🚨> character byte-for-byte matches the interpreted run's
output. A red run (before the fix) shows the compiled binary emitting
C<c3 b0 c2 9f c2 9a c2 a8> (double-encoded mojibake) instead of the correct
C<f0 9f 9a a8>.

=cut
