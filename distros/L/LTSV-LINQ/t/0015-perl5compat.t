######################################################################
#
# 0015-perl5compat.t
#
# Verifies that all .pm files in lib/ use only Perl 5.005_03-compatible
# syntax.  Checks for:
#
#   P1  - No 'our' keyword
#   P2  - No say/given/state keywords
#   P3  - No my(undef) in list assignments
#   P4  - No \d+ in string repetition (not applicable; placeholder)
#   P5  - No defined-or operator (//)
#   P6  - No yada-yada operator (...)
#   P7  - No smart-match operator (~~)
#   P8  - No postfix-if in variable declarations
#   P9  - No non-ASCII source characters
#   P10 - $VERSION self-assignment present
#   P11 - warnings compatibility stub present
#   P12 - CVE-2016-1238 mitigation (pop @INC) present
#
######################################################################

use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

# ---- Minimal test harness (no Test::More required) --------------------
my ($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);
sub plan_tests { $T_PLAN = $_[0]; print "1..$T_PLAN\n" }
sub plan_skip  { print "1..0 # SKIP $_[0]\n"; exit 0 }
sub ok   { my($ok,$n)=@_; $T_RUN++; $ok||$T_FAIL++;
           print +($ok?'':'not ')."ok $T_RUN".($n?" - $n":"")."\n"; $ok }
END { exit 1 if $T_PLAN && $T_FAIL }
# -----------------------------------------------------------------------

# Collect .pm files from lib/
my @pm_files;
{
    local *DH;
    _find_pm('lib', \@pm_files);
}

plan_skip('no .pm files found in lib/') unless @pm_files;
plan_tests(12 * scalar @pm_files);

for my $file (sort @pm_files) {
    local *FH;
    open FH, "<$file" or do { ok(0, "P - cannot open $file") for 1..12; next };
    my $src = do { local $/; <FH> };
    close FH;

    # Strip POD
    (my $code = $src) =~ s/^=\w.*?^=cut[ \t]*$//msg;
    # Strip __END__ / __DATA__
    $code =~ s/\n__(?:END|DATA__)__\b.*\z//s;

    # P1: no 'our' (skip comment lines)
    {
        my $no_comments = $code;
        $no_comments =~ s/^\s*#[^\n]*\n//mg;
        ok($no_comments !~ /\bour\b/,
            "P1 - no 'our' keyword: $file");
    }

    # P2: no say/given/state
    ok($code !~ /\b(?:say|given|state)\s*[\(\{;]/,
        "P2 - no say/given/state: $file");

    # P3: no my(undef)
    ok($code !~ /\bmy\s*\(\s*undef/,
        "P3 - no my(undef): $file");

    # P4: (placeholder - always pass)
    ok(1, "P4 - (n/a): $file");

    # P5: no defined-or (//)  -- skip s/// delimiters and URLs
    {
        my $stripped = $code;
        $stripped =~ s{s/[^/]*/[^/]*/\w*}{}g;   # remove s///
        $stripped =~ s{https?://\S+}{}g;          # remove URLs
        $stripped =~ s{'[^']*'}{}g;               # remove single-quoted strings
        ok($stripped !~ m{(?<![=!<>])//(?!=)},
            "P5 - no defined-or (//): $file");
    }

    # P6: no yada-yada (...) - skip comments and quoted strings
    {
        my $p6_ok = 1;
        for my $line (split /\n/, $code) {
            next if $line =~ /^\s*#/;
            (my $s = $line) =~ s/'[^']*'//g;
            $s =~ s/"[^"]*"//g;
            if ($s =~ /(?<![.])\.\.\.(?![.])/) {
                $p6_ok = 0; last;
            }
        }
        ok($p6_ok, "P6 - no yada-yada (...): $file");
    }

    # P7: no smart-match (~~)
    ok($code !~ /~~/,
        "P7 - no smart-match (~~): $file");

    # P8: no postfix-if in variable declarations (single-line check)
    {
        my $p8_ok = 1;
        for my $line (split /\n/, $code) {
            next if $line =~ /^\s*#/;
            if ($line =~ /\bmy\s+\$\w+\s*=[^;\n]+\bif\b/) {
                $p8_ok = 0; last;
            }
        }
        ok($p8_ok, "P8 - no postfix-if in declaration: $file");
    }

    # P9: no non-ASCII bytes
    ok($src !~ /[^\x00-\x7F]/,
        "P9 - US-ASCII source only: $file");

    # P10: $VERSION self-assignment
    ok($src =~ /\$VERSION\s*=\s*\$VERSION/,
        "P10 - \$VERSION self-assignment present: $file");

    # P11: warnings compatibility stub
    ok($src =~ /INC\{'warnings\.pm'\}/,
        "P11 - warnings compat stub present: $file");

    # P12: CVE-2016-1238 mitigation
    ok($src =~ /pop\s+\@INC/,
        "P12 - CVE-2016-1238 pop \@INC present: $file");
}

sub _find_pm {
    my($dir, $out) = @_;
    local *DH;
    opendir DH, $dir or return;
    my @entries = sort readdir DH;
    closedir DH;
    for my $e (@entries) {
        next if $e eq '.' || $e eq '..';
        my $path = "$dir/$e";
        if (-d $path)                      { _find_pm($path, $out) }
        elsif ($e =~ /\.pm$/ && -f $path)  { push @$out, $path }
    }
}
