# t/0007-usascii.t
# Verify that every file listed in MANIFEST contains only US-ASCII
# characters (code points 0x00-0x7F).
# Non-ASCII bytes in source files, POD, or metadata cause problems on
# some CPAN toolchains and violate the project's encoding policy.
# Files under doc/ are exempt: cheat sheets are intentionally written
# in the local language and may contain UTF-8 encoded characters.
# No network or fork required; runs on all platforms.
use strict;

# ---- Minimal test harness (no Test::More required) --------------------
my ($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);
sub plan_tests { $T_PLAN = $_[0]; print "1..$T_PLAN\n" }
sub plan_skip  { print "1..0 # SKIP $_[0]\n"; exit 0 }
sub ok   { my($ok,$n)=@_; $T_RUN++; $ok||$T_FAIL++;
           print +($ok?'':'not ')."ok $T_RUN".($n?" - $n":"")."\n"; $ok }
END { exit 1 if $T_PLAN && $T_FAIL }
# -----------------------------------------------------------------------

# Read the file list from MANIFEST.
# MANIFEST must exist; if it is missing the distribution is broken.
open FH_MANIFEST, '<MANIFEST' or plan_skip('MANIFEST not found');
chomp(my @manifest = <FH_MANIFEST>);
close FH_MANIFEST;

# Keep only files that exist on disk (skip blank lines and comments).
my @files = grep { defined $_ && $_ ne '' && -f $_ } @manifest;

plan_skip('no files found in MANIFEST') unless @files;
plan_tests(scalar @files);

for my $file (@files) {
    # doc/ files are intentionally written in local languages (UTF-8).
    if ($file =~ m{^doc/}) {
        ok(1, "$file (documents may contain UTF-8 encoding)");
        next;
    }

    # ok N: <filename> is US-ASCII only
    local *FH;
    unless (open FH, "<$file") {
        ok(0, "$file - cannot open: $!");
        next;
    }
    binmode FH;

    my $bad_line = 0;
    my $line_no  = 0;
    while (<FH>) {
        $line_no++;
        if (/[^\x00-\x7F]/) {
            $bad_line = $line_no;
            last;
        }
    }
    close FH;

    if ($bad_line) {
        ok(0, "$file - non-ASCII byte at line $bad_line");
    }
    else {
        ok(1, "$file is US-ASCII");
    }
}
