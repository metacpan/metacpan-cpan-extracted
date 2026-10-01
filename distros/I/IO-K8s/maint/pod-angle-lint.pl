#!/usr/bin/env perl
# POD "C<> angle trap" linter for IO::K8s.
#
# Guards the house rule settled in karr k186: inside a code span that
# contains an angle bracket, ALWAYS use the double-bracket form with a
# literal angle -- C<< ... >> (or C<<< ... >>>) -- and NEVER the single
# form C<...> with a '<' or '>' in it, whether raw or written as an
# E<lt>/E<gt> escape.
#
# Why it matters (the trap k168/k176 fixed case-by-case and k186 part 1
# normalised across lib/): in a single-bracket code span a raw '>'
# terminates the sequence early, so C<a =E<gt> b> or C<Net::IP-E<gt>new>
# render wrong, and the escape form E<gt>/E<lt> -- while it renders --
# is the exact thing the unified C<< literal >> form replaces. Hand-
# wrapping upstream-derived API descriptions (types like <domain>, the
# =>/-> arrows, <=/>= comparisons) re-introduces it easily, and neither
# podchecker nor Pod::Simple flags it. This lint is that missing gate.
#
# Run it whenever lib/ gains hand-written POD -- in particular on an
# upstream spec sync, alongside maint/spec-drift-check.pl -- and as a CI
# gate: exit is 0 when clean, non-zero when anything is found.
#
# Detection (mechanical, biased to zero false negatives against the trap):
#   * a single-bracket C< (NOT C<< / C<<< , which are the sanctioned
#     forms and are skipped) whose content contains a '<' -- this catches
#     a raw '<' (e.g. <domain>, <=) AND every E<lt>/E<gt> escape, since
#     both escapes literally contain a '<';
#   * a single-bracket C< whose closing '>' is itself part of a raw
#     '=>' / '>=' / '>>' operator (a raw '>' inside otherwise terminates
#     the span, so it is caught here at the boundary).
# Content is scanned across line breaks within a POD paragraph, so a span
# wrapped over two lines is not missed. Verbatim (indented) paragraphs are
# left alone -- C<> is literal text there, not a formatting code.
#
# This is a report generator. It never edits lib/, never touches the karr
# board, never talks to the network.
#
# Usage:
#   maint/pod-angle-lint.pl [PATH]...
#     PATH is a .pm file or a directory scanned recursively for .pm files.
#     With no PATH it scans DIST/lib.
#
# Examples:
#   maint/pod-angle-lint.pl
#     Lint every .pm under lib/ (the default).
#
#   maint/pod-angle-lint.pl lib/IO/K8s/Role/CertManaged.pm
#     Lint a single file.
use strict;
use warnings;
use v5.10;
use FindBin;
use File::Spec;
use File::Find;
use Getopt::Long qw(GetOptions);

my $DIST_ROOT = File::Spec->rel2abs(File::Spec->catdir($FindBin::Bin, '..'));

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

sub usage {
    my ($exit_code) = @_;
    print <<"USAGE";
Usage:
  $0 [PATH]...

Lints hand-written POD for the "C<> angle trap" (karr k186): a single-
bracket C<...> code span containing a '<' or '>' (raw, or as an E<lt>/
E<gt> escape). The sanctioned forms C<< ... >> / C<<< ... >>> are skipped.

  PATH   A .pm file, or a directory scanned recursively for .pm files.
         Defaults to DIST/lib when no PATH is given.
  --help This message.

Exit status is 0 when clean and non-zero when any offending span is found,
so it doubles as a CI / spec-sync gate.
USAGE
    exit($exit_code // 0);
}

sub parse_args {
    my %opt;
    GetOptions(\%opt, 'help|h') or usage(1);
    usage(0) if $opt{help};
    my @paths = @ARGV;
    @paths = (File::Spec->catdir($DIST_ROOT, 'lib')) unless @paths;
    return \@paths;
}

# ---------------------------------------------------------------------------
# File discovery
# ---------------------------------------------------------------------------

sub collect_pm_files {
    my ($paths) = @_;
    my @files;
    for my $p (@$paths) {
        if (-d $p) {
            find(
                { wanted => sub { push @files, $File::Find::name if /\.pm$/ && -f $_ },
                  no_chdir => 1 },
                $p,
            );
        }
        elsif (-f $p) {
            push @files, $p;
        }
        else {
            die "pod-angle-lint: no such file or directory: $p\n";
        }
    }
    return sort @files;
}

# ---------------------------------------------------------------------------
# POD paragraph extraction
#
# A line is scannable POD text when we are inside a POD region (opened by a
# =command, closed by =cut) and the line is neither a =command line's own
# body nor a verbatim (indented) paragraph. Consecutive scannable text
# lines are grouped into one paragraph so a code span wrapped over a line
# break is scanned as a whole. =command lines (=item, =head..) are scanned
# on their own, since they carry code spans too but never continue a
# paragraph.
# ---------------------------------------------------------------------------

sub scannable_paragraphs {
    my ($file) = @_;
    open my $fh, '<:encoding(UTF-8)', $file
        or die "pod-angle-lint: cannot read $file: $!\n";
    my @paragraphs;    # each: [ [lineno,text], [lineno,text], ... ]
    my @chunk;
    my $in_pod = 0;
    my $lineno = 0;

    my $flush = sub { push @paragraphs, [@chunk] if @chunk; @chunk = () };

    while (my $line = <$fh>) {
        $lineno++;
        chomp $line;
        if ($line =~ /^=cut\b/) {
            $flush->();
            $in_pod = 0;
            next;
        }
        if ($line =~ /^=[a-zA-Z]/) {
            $flush->();
            $in_pod = 1;
            push @paragraphs, [[$lineno, $line]];    # command line, scanned alone
            next;
        }
        if (!$in_pod || $line eq '' || $line =~ /^\s/) {
            # outside POD, blank (paragraph break), or verbatim (indented)
            $flush->();
            next;
        }
        push @chunk, [$lineno, $line];
    }
    $flush->();
    close $fh;
    return \@paragraphs;
}

# ---------------------------------------------------------------------------
# The scanner
# ---------------------------------------------------------------------------

# Join a paragraph's lines into one string plus a per-character line map, so
# a finding's offset resolves back to its source line.
sub join_with_line_map {
    my ($chunk) = @_;
    my $joined = '';
    my @line_at;
    for my $idx (0 .. $#$chunk) {
        my ($ln, $txt) = @{ $chunk->[$idx] };
        push @line_at, ($ln) x length($txt);
        if ($idx < $#$chunk) {
            $joined .= $txt . "\n";
            push @line_at, $ln;    # the joining newline belongs to this line
        }
        else {
            $joined .= $txt;
        }
    }
    return ($joined, \@line_at);
}

sub snippet_of {
    my ($joined, $from, $close) = @_;
    my $text;
    if ($close >= 0) {
        $text = substr($joined, $from, $close - $from + 1);
    }
    else {
        # Unterminated on this paragraph: show the opener's line, capped.
        my $nl = index($joined, "\n", $from);
        my $end = $nl >= 0 ? $nl : length $joined;
        $end = $from + 80 if $end - $from > 80;
        $text = substr($joined, $from, $end - $from);
    }
    $text =~ s/\s+/ /g;    # collapse a wrapped span for one-line reporting
    return $text;
}

# Scan one paragraph, pushing [file, lineno, snippet, reason] onto $findings.
sub scan_paragraph {
    my ($chunk, $file, $findings) = @_;
    my ($s, $line_at) = join_with_line_map($chunk);
    my $len = length $s;
    my $i   = 0;

    while ($i < $len) {
        # A code span starts only at a literal 'C' immediately followed by '<'.
        unless (substr($s, $i, 1) eq 'C' && $i + 1 < $len && substr($s, $i + 1, 1) eq '<') {
            $i++;
            next;
        }

        # Count the run of '<' after C.
        my $j = $i + 1;
        $j++ while $j < $len && substr($s, $j, 1) eq '<';
        my $run   = $j - ($i + 1);
        my $after = $j < $len ? substr($s, $j, 1) : '';

        # C<< ... >> / C<<< ... >>> -- sanctioned. Requires whitespace right
        # after the opening run. Skip past the matching run of '>'.
        if ($run >= 2 && $after =~ /\s/) {
            my $close_seq = '>' x $run;
            my $pos = index($s, $close_seq, $j);
            $i = $pos >= 0 ? $pos + $run : $len;
            next;
        }

        # Single-bracket form. The first '<' opens; content starts after it.
        # (A run of 2+ '<' not followed by whitespace -- e.g. C<<domain>> --
        # is a broken single span whose content begins with '<', and is
        # correctly caught below.)
        my $content_start = $i + 2;
        my $k        = $content_start;
        my $found_lt = 0;
        my $close    = -1;
        while ($k < $len) {
            my $ch = substr($s, $k, 1);
            if ($ch eq '>') { $close = $k; last }
            if ($ch eq '<') {
                $found_lt = 1;
                # Consume an E<...> escape so the outer close (and the
                # reported snippet) is not cut at the escape's own '>'.
                if ($k > $content_start && substr($s, $k - 1, 1) eq 'E') {
                    my $ec = index($s, '>', $k + 1);
                    if ($ec >= 0) { $k = $ec + 1; next }
                }
                $k++;
                next;
            }
            $k++;
        }

        my ($flag, $reason) = (0, '');
        if ($found_lt) {
            $flag   = 1;
            $reason = q{single-bracket C<> whose content has a '<' (raw, or an E<lt>/E<gt> escape) -- use C<< ... >>};
        }
        elsif ($close >= 0) {
            # No '<' anywhere, but a raw '>' operator can hide at the close.
            my $before = $close > $content_start ? substr($s, $close - 1, 1) : '';
            my $afterc = $close + 1 < $len       ? substr($s, $close + 1, 1) : '';
            if ($before eq '=') {
                $flag   = 1;
                $reason = q{single-bracket C<> closed by a raw '=>' operator -- use C<< ... >>};
            }
            elsif ($afterc eq '=' || $afterc eq '>') {
                $flag   = 1;
                $reason = q{single-bracket C<> followed by a raw '>='/'>>' operator -- use C<< ... >>};
            }
        }

        if ($flag) {
            push @$findings, [
                $file,
                $line_at->[$i],
                snippet_of($s, $i, $close),
                $reason,
            ];
        }

        $i = $close >= 0 ? $close + 1 : $len;
    }
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

my $paths = parse_args();
my @files = collect_pm_files($paths);

my @findings;
for my $file (@files) {
    my $paragraphs = scannable_paragraphs($file);
    scan_paragraph($_, $file, \@findings) for @$paragraphs;
}

if (@findings) {
    my %by_file;
    for my $f (@findings) {
        push @{ $by_file{ $f->[0] } }, $f;
    }
    for my $file (sort keys %by_file) {
        for my $f (@{ $by_file{$file} }) {
            printf "%s:%d: %s\n    -- %s\n", $f->[0], $f->[1], $f->[2], $f->[3];
        }
    }
    printf "\npod-angle-lint: %d offending C<> span%s in %d file%s (of %d scanned)\n",
        scalar(@findings), (@findings == 1 ? '' : 's'),
        scalar(keys %by_file), (keys %by_file == 1 ? '' : 's'),
        scalar(@files);
    exit 1;
}

printf "pod-angle-lint: clean -- no single-bracket C<> spans with angle content (%d files scanned)\n",
    scalar(@files);
exit 0;
