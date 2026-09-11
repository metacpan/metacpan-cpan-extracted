#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
# File::Temp, not a pid-based name in a shared tmpdir. A predictable filename in
# a world-writable directory is CWE-377: another local user can pre-create the
# path and the test then reads content it did not write. DD-798 is the same
# class in a shipped refusal's advice, found by the peer session the same
# evening; this file acquired it by writing three fixtures the convenient way,
# and the perlsec review of its own card is what caught it.
use File::Temp qw(tempfile);

# DD-800. A spec must not hardcode an absolute home directory. Two files did -
# t/05-cli-smoke.t and t/31-powershell-bootstrap-cache.t each prepended a
# literal /home/<user>/perl5/lib/perl5 to PERL5LIB - and the vault page says
# "do not put a machine-specific path back". Nothing enforced that, so this
# file does.
#
# THE GUARD MUST STRIP COMMENTS AND POD BEFORE MATCHING, and that is not
# tidiness. The fix for those two files left a COMMENT at each call site
# explaining why the literal was there and why it must not return - and those
# comments necessarily quote the path. A raw-source grep cannot tell code from
# the commentary about code, so it would flag the very explanation that stops
# the next person reintroducing the defect, and the natural way to make the
# guard pass would be to delete the explanation.

# _executable_lines($path)
# Reads a Perl source file and returns only the lines that can execute:
# comments, POD blocks and HEREDOC BODIES removed. Line numbers are preserved
# so a failure can name where it is.
#
# HEREDOC AWARENESS IS NOT OPTIONAL, and this file proved it against itself.
# A heredoc body is source text held as a STRING - commonly a fixture, or a
# script written out for another interpreter - and a line-oriented scanner
# cannot tell it from real code in the enclosing file. The first version of
# this guard flagged its OWN control fixture at line 79 and failed on a clean
# tree. docs/source-scanning-checkers-and-heredocs.md records this as a
# recurring shape here and prescribes the remedy taken: narrow the checker with
# a real discriminator rather than discarding the same finding by hand.
#
# Input: path to a Perl file.
# Output: list of [line_number, text] pairs for executable lines only.
sub _executable_lines {
    my ($path) = @_;
    open my $fh, '<:encoding(UTF-8)', $path or die "cannot read $path: $!";
    my @out;
    my $in_pod     = 0;
    my $heredoc_to = undef;    # terminator we are skipping towards, when inside one
    my $line_no    = 0;
    while ( my $line = <$fh> ) {
        $line_no++;
        chomp $line;

        if ( defined $heredoc_to ) {
            # Perl allows an indented terminator with <<~; accept either form.
            $heredoc_to = undef if $line =~ /^\s*\Q$heredoc_to\E\s*$/;
            next;
        }

        if ( $line =~ /^=cut\b/ )    { $in_pod = 0; next }
        if ( $line =~ /^=[a-zA-Z]/ ) { $in_pod = 1; next }
        next if $in_pod;
        last if $line =~ /^__END__\s*$/;

        my $code = $line;
        $code =~ s/^\s*#.*\z//;         # whole-line comment
        $code =~ s/\s+#(?![{]).*\z//;   # trailing comment, leaving $#{...} alone

        # A heredoc OPENER is itself executable and is kept; its body is not.
        if ( $code =~ /<<~?\s*(?:'([A-Za-z_]\w*)'|"([A-Za-z_]\w*)"|([A-Z_]\w*))/ ) {
            $heredoc_to = defined $1 ? $1 : defined $2 ? $2 : $3;
        }

        next if $code !~ /\S/;
        push @out, [ $line_no, $code ];
    }
    close $fh;
    return @out;
}

my @specs = sort glob 't/*.t';
cmp_ok( scalar @specs, '>=', 100,
    'the spec list is populated, so a clean result discriminates rather than reflecting an empty search' );

# The pattern deliberately matches any user's home, not just this machine's -
# a guard keyed to one developer would pass on everybody else's mistake.
my $home_literal = qr{(?:/home/[a-z0-9_.-]+|/Users/[A-Za-z0-9_.-]+)/};

# AND IT MUST BE NARROWER THAN "AN ABSOLUTE HOME APPEARS", which is the second
# discriminator this file needed and the second one it learned by going red.
# Run without this clause the guard flagged five innocent specs: a mock
# returning a fake path it never opens (t/07), a string fixture reproducing an
# error message (t/107), and THREE files passing '/home/dev/x'-style paths as
# TEST DATA to functions whose whole job is to sanitize or display a path
# (t/113, t/78, t/97). Those files are testing path handling; forbidding a
# home-shaped literal there would forbid the test.
#
# The defect is not a home path appearing - it is a home path being used to
# CONFIGURE THIS PROCESS'S ENVIRONMENT, which is what makes the spec's @INC
# depend on the machine. Both members assigned into %ENV, and that is the
# discriminator: a literal reaching $ENV{...} changes where the interpreter
# looks; the same literal in an argument or an expected value does not.
# AND IT MUST MATCH PER STATEMENT, NOT PER LINE - the third discriminator this
# file learned by going red, and the one that matters most, because without it
# the guard misses HALF ITS OWN SUBJECT. t/31's original assignment spanned
# four lines:
#
#     local $ENV{PERL5LIB} = join ':',        # line 16 - has $ENV{, no literal
#         grep { defined && $_ ne '' }
#         '/home/mv/perl5/lib/perl5',         # line 18 - has literal, no $ENV{
#         ( $ENV{PERL5LIB} || () );
#
# A per-line test requires both halves on one line and finds neither. Measured:
# run per-line against the pre-fix files it flagged t/05 and NOT t/31 - a false
# negative on one of the two members the guard exists for.
#
# _statements($path)
# Joins executable lines into ;-terminated statements, keeping the line number
# the statement STARTED on so a failure still points at something findable.
# A trailing fragment with no ';' is emitted rather than dropped - silently
# discarding the last statement of a file is how a scanner acquires a blind
# spot at exactly the place people put closing code.
# Input: path to a Perl file.
# Output: list of [starting_line_number, joined_statement_text] pairs.
sub _statements {
    my ($path) = @_;
    my ( @statements, $buffer, $start );
    for my $pair ( _executable_lines($path) ) {
        my ( $line_no, $code ) = @{$pair};
        $start = $line_no if !defined $buffer;
        $buffer = defined $buffer ? "$buffer $code" : $code;
        next if $code !~ /;\s*$/;
        push @statements, [ $start, $buffer ];
        ( $buffer, $start ) = ( undef, undef );
    }
    push @statements, [ $start, $buffer ] if defined $buffer;
    return @statements;
}

my @offenders;
for my $spec (@specs) {
    for my $pair ( _statements($spec) ) {
        my ( $line_no, $code ) = @{$pair};
        next if $code !~ $home_literal;
        next if $code !~ /\$ENV\{/;
        push @offenders, sprintf '%s line %d: %s', $spec, $line_no, substr( $code, 0, 120 );
    }
}

is( scalar @offenders, 0,
    'no spec under t/ hardcodes an absolute home directory in executable code (DD-800)' )
    or diag( "offending lines:\n" . join( "\n", @offenders ) );

# The guard is only worth trusting if it can go red. Feed it a line that IS an
# offence and one that is only a comment about an offence, and require it to
# tell them apart - the distinction the whole file rests on.
{
    my ( $fh, $tmp ) = tempfile( "dd800-guard-control-XXXXXXXX", SUFFIX => '.pl', TMPDIR => 1 );
    binmode $fh, ':encoding(UTF-8)';
    print {$fh} <<'ENDOFFIXTURE';
# this comment mentions /home/someone/perl5/lib/perl5 and must NOT be flagged
my $bad = '/home/someone/perl5/lib/perl5';
ENDOFFIXTURE
    close $fh;

    my @hits = grep { $_->[1] =~ $home_literal } _executable_lines($tmp);
    is( scalar @hits, 1,
        'CONTROL: the guard flags the executable line and not the comment quoting the same path' );
    is( $hits[0][0], 2, 'CONTROL: it is line 2 - the assignment - that is flagged, not line 1' );
    unlink $tmp;
}

# Second control, and this one exists because the guard failed it. A heredoc
# body is a STRING holding source text; flagging it would make any file that
# carries a fixture unfixable except by deleting the fixture.
{
    my ( $fh, $tmp ) = tempfile( "dd800-guard-heredoc-XXXXXXXX", SUFFIX => '.pl', TMPDIR => 1 );
    binmode $fh, ':encoding(UTF-8)';
    print {$fh} <<'ENDOFHEREDOCFIXTURE';
my $fixture = <<'INNER';
my $bad = '/home/someone/perl5/lib/perl5';
INNER
my $real = '/home/someone/perl5/lib/perl5';
ENDOFHEREDOCFIXTURE
    close $fh;

    my @hits = grep { $_->[1] =~ $home_literal } _executable_lines($tmp);
    is( scalar @hits, 1,
        'CONTROL: a path inside a heredoc BODY is not flagged, while the same path in real code is' );
    is( $hits[0][0], 4,
        'CONTROL: line 4 is flagged - the assignment after the heredoc closes, not line 2 inside it' );
    unlink $tmp;
}

# Third control, also written because the guard went red without it. A spec
# that passes a home-shaped path as TEST DATA - to a sanitizer, a display
# helper, a line matcher - is testing path handling, and forbidding the literal
# there would forbid the test. Five real specs do exactly this.
{
    my ( $fh, $tmp ) = tempfile( "dd800-guard-env-XXXXXXXX", SUFFIX => '.pl', TMPDIR => 1 );
    binmode $fh, ':encoding(UTF-8)';
    print {$fh} <<'ENDOFENVFIXTURE';
is( $obj->_display_path('/home/dev/x'), '/home/dev/x', 'test data, not configuration' );
return '/home/dev/bin/cmd' if $name eq 'cmd';
local $ENV{PERL5LIB} = '/home/dev/perl5/lib/perl5';
ENDOFENVFIXTURE
    close $fh;

    my @env_hits = grep { $_->[1] =~ $home_literal && $_->[1] =~ /\$ENV\{/ } _executable_lines($tmp);
    is( scalar @env_hits, 1,
        'CONTROL: only the line assigning into %ENV is an offence; test data and a mock return are not' );
    is( $env_hits[0][0], 3, 'CONTROL: line 3 is the $ENV assignment, and lines 1-2 are left alone' );
    unlink $tmp;
}

done_testing;

__END__

=head1 NAME

t/173-no-machine-specific-paths-in-specs.t - no spec hardcodes an absolute home directory

=head1 PURPOSE

Fails when any test file under C<t/> assigns an absolute home directory into
C<%ENV> - the thing that makes a spec's C<@INC> depend on the machine it runs
on.

Three narrowings make that checkable, and every one of them was added because
the guard went red without it:

=over 4

=item * Comments and POD are stripped, so a file may EXPLAIN the hazard without
tripping the guard that enforces it. Both fixed call sites carry such a comment.

=item * Heredoc bodies are skipped. A heredoc holds source text as a string;
this file's own control fixtures are heredocs, and the first version flagged
them.

=item * Matching is per STATEMENT, not per line, and the C<%ENV> assignment must
be in the same statement as the literal. Per line the guard missed one of the
two specs it was written for, whose assignment spanned four lines; and without
the C<%ENV> clause it flagged five innocent specs that pass home-shaped paths as
TEST DATA to path-sanitizing helpers.

=back

=head1 WHY IT EXISTS

DD-800 found two specs that prepended a literal C</home/E<lt>userE<gt>/perl5/lib/perl5>
to C<PERL5LIB>, committed since the first commit in the repository. The entry
was inert wherever that path did not exist, so it broke nothing - it MASKED.
The spec could not fail for a caller who had not set C<PERL5LIB>, because it
supplied the dependencies itself, and a spec that cannot fail for a missing
dependency cannot report one.

The fix removed both. The vault page records the rule, and a rule that nothing
checks is a rule that returns the first time somebody localises C<HOME> to a
temporary directory and needs to compensate. This file is the check.

It matches any user's home rather than this machine's, because a guard keyed to
one developer's path would pass silently on everybody else's mistake.

=head1 WHEN TO USE

Runs as part of the full suite. Consult it directly when adding a spec that
needs modules resolved from outside the checkout - the answer is to let the
caller supply C<PERL5LIB>, or to derive the path from the real C<HOME> captured
before any temporary-directory localisation, never to write a literal.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/173-no-machine-specific-paths-in-specs.t

A failure names every offending file, line number and line, so the fix does not
require re-running a search to locate it.

=head1 WHAT USES IT

The full C<prove -lr t> suite, and therefore every gate that depends on it.
Nothing else consumes its output.

=head1 EXAMPLES

Rejected, because it can execute:

    local $ENV{PERL5LIB} = join ':', '/home/someone/perl5/lib/perl5', ( $ENV{PERL5LIB} || () );

Accepted, because the caller supplies the path:

    local $ENV{PERL5LIB} = join ':', grep { defined && $_ ne '' } ( $ENV{PERL5LIB} || () );

Also accepted - a comment may quote the very path the guard forbids, which is
what lets the explanation live beside the code it explains:

    # DD-800: this used to prepend a literal '/home/someone/perl5/lib/perl5'.

=cut
