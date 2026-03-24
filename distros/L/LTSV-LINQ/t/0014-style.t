# t/0014-style.t
# Check ina@CPAN coding style:
#   "if"/"while"/"for" blocks open on the same line as the keyword.
#   "else"/"elsif" must appear on a NEW line after the closing "}" of
#   the previous block -- never on the same line as that "}".
#
# Rule checked: a line whose non-whitespace content matches
#
#       }  [optional spaces]  else   [optional: if(...) ] {
#   or  }  [optional spaces]  elsif  ...                 {
#
# is a violation.
#
# Exclusions (lines are silently skipped):
#   - Lines inside a POD block  (=head1 ... =cut)
#   - Lines inside a heredoc    (<<'...' / <<"...")
#   - Lines that are pure comments (#...)
#   - The file itself is not required to exist; it is simply skipped.
#
# Usage: prove -l t/014-style.t
#        TEST_AUTHOR=1 prove -l t/014-style.t   (same, author flag not needed)
#
# Files checked: every file listed in MANIFEST that ends in .pm or .t
# If MANIFEST is not present, only lib/**/*.pm and t/*.t are scanned.

use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use File::Spec;

# ---- Minimal test harness (no Test::More required) --------------------
my ($T_PLAN, $T_RUN, $T_FAIL) = (0, 0, 0);
sub plan_tests { $T_PLAN = $_[0]; print "1..$T_PLAN\n" }
sub plan_skip  { print "1..0 # SKIP $_[0]\n"; exit 0 }
sub ok   { my($ok,$n)=@_; $T_RUN++; $ok||$T_FAIL++;
           print +($ok?'':'not ')."ok $T_RUN".($n?" - $n":"")."\n"; $ok }
END { exit 1 if $T_PLAN && $T_FAIL }
# -----------------------------------------------------------------------

# Collect files to check
my @files = _collect_files();

plan_tests(scalar @files);

for my $file (sort @files) {
    my @violations = _check_file($file);
    if (@violations) {
        ok(0, "$file - ina\@CPAN style violation");
        for my $v (@violations) {
            print "# line $v->{line}: $v->{text}";
        }
    }
    else {
        ok(1, "$file - ina\@CPAN style OK");
    }
}

# -----------------------------------------------------------------------
# _collect_files() - return list of .pm / .t files to check
# -----------------------------------------------------------------------
sub _collect_files {
    my @result;

    if (-f 'MANIFEST') {
        local *FH;
        if (open FH, '<MANIFEST') {
            while (<FH>) {
                chomp;
                s/\s.*$//;    # strip optional comment after filename
                next unless /\.(pm|t)$/;
                push @result, $_ if -f $_;
            }
            close FH;
        }
    }

    # Fallback: scan lib/ and t/ directly
    unless (@result) {
        for my $dir ('lib', 't') {
            next unless -d $dir;
            local *DH;
            _find_pm_t($dir, \@result);
        }
    }

    return @result;
}

# Recursive file finder for .pm and .t files
sub _find_pm_t {
    my($dir, $out) = @_;
    local *DH;
    opendir DH, $dir or return;
    my @entries = readdir DH;
    closedir DH;
    for my $e (sort @entries) {
        next if $e eq '.' || $e eq '..';
        my $path = "$dir/$e";
        if (-d $path) {
            _find_pm_t($path, $out);
        }
        elsif ($e =~ /\.(pm|t)$/ && -f $path) {
            push @$out, $path;
        }
    }
}

# -----------------------------------------------------------------------
# _check_file($path) - return list of violation hashrefs {line, text}
# -----------------------------------------------------------------------
sub _check_file {
    my($path) = @_;
    my @violations;

    local *FH;
    unless (open FH, "<$path") {
        return ();    # unreadable file: skip silently
    }

    my $in_pod      = 0;
    my $in_heredoc  = 0;    # heredoc end-marker (string) or 0
    my $lineno      = 0;

    while (my $line = <FH>) {
        $lineno++;

        # ------ heredoc tracking ------
        if ($in_heredoc) {
            # End of heredoc: line equals the marker (possibly with trailing \n)
            my $marker = $in_heredoc;
            if ($line =~ /^\Q$marker\E\s*$/) {
                $in_heredoc = 0;
            }
            next;
        }

        # Detect start of heredoc (<<'END' / <<"END" / <<END)
        # We only track single-token heredocs; complex cases are ignored.
        if ($line =~ /<<['"]?(\w+)['"]?/) {
            $in_heredoc = $1;
            # The rest of this line is normal code; fall through to style check
        }

        # ------ POD tracking ------
        if ($line =~ /^=[a-zA-Z]/) {
            $in_pod = 1;
        }
        if ($line =~ /^=cut/) {
            $in_pod = 0;
            next;
        }
        next if $in_pod;

        # ------ Skip pure comment lines ------
        next if $line =~ /^\s*#/;

        # ------ ina@CPAN style check ------
        # Violation: "}" and "else"/"elsif" on the same line
        # Pattern:  optional-whitespace  }  optional-whitespace  else/elsif  anything  {
        if ($line =~ /^\s*\}\s*els(?:e|if)\b/) {
            push @violations, { line => $lineno, text => $line };
        }
    }

    close FH;
    return @violations;
}
