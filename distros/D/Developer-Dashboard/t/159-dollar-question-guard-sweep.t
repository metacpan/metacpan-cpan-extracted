#!/usr/bin/env perl

use strict;
use warnings;

use File::Find qw(find);
use File::Spec;
use FindBin qw($RealBin);
use Test::More;

# _repo_path(@parts)
# Builds an absolute path rooted at the repository checkout, independent of
# the caller's own working directory.
# Input: path segment strings.
# Output: absolute path string.
sub _repo_path {
    return File::Spec->rel2abs( File::Spec->catfile( $RealBin, File::Spec->updir, @_ ) );
}

# DD-611: this baseline was DD-597's own still-open findings (25 hits at the
# time this gate was written). DD-597 has now guarded every one of them with
# "local $?;", so the sweep finds zero hits and the baseline is empty - any
# future hit is a genuinely new, unguarded sub and fails the suite on its
# own.
my %BASELINE = map { $_ => 1 } ();

# DD-670: this baseline is the SETTING side's still-open findings - subs that
# call waitpid/system/backticks (so they SET $?) with no "local $?;" guard,
# triaged rather than blanket-guarded. Only one instance (ActionRunner's own
# _reap_child_process, matching the shape ProcessSupervision.pm already fixed)
# was confirmed as a real caller-visible leak and is fixed by this same
# change, so it is NOT in this baseline. The rest are recorded here rather
# than silently unguarded - each is a real subprocess call, but its callers
# were not individually verified to read $? afterward, which is exactly the
# per-sub judgement DD-670 warns against skipping ("guarding everywhere makes
# the next real instance unfindable"). Shrink this baseline, do not leave a
# fixed entry stale in it, same discipline as %BASELINE above.
#
# DD-1019: 'Developer/Dashboard/CollectorRunner.pm::_terminate_command_process'
# was removed from here - a refactor moved its real body into shared
# Developer::Dashboard::CommandRunner::terminate_command_process, leaving the
# CollectorRunner sub a thin delegating wrapper with no subprocess call of
# its own, so the old entry stopped reproducing (a stale baseline entry, not
# a fixed one). The new location was a genuine new unguarded instance and is
# now guarded directly in lib/ rather than re-added here - see
# CommandRunner.pm::terminate_command_process, fixed by this ticket.
my %SETTER_BASELINE = map { $_ => 1 } (
    'Developer/Dashboard/ActionRunner.pm::run_command_action',
    'Developer/Dashboard/CLI/Ask.pm::_ask_claude',
    'Developer/Dashboard/CLI/Ask.pm::_missing_backend_message',
    'Developer/Dashboard/CLI/Ask.pm::_run_cli',
    'Developer/Dashboard/CollectorRunner.pm::_waitpid_nonblocking',
    'Developer/Dashboard/RuntimeManager.pm::_wait_for_any_child_process',
    'Developer/Dashboard/SkillDispatcher.pm::dispatch',
    'Developer/Dashboard/SkillDispatcher.pm::execute_hooks',
    'Developer/Dashboard/SkillManager.pm::update',
    'Developer/Dashboard/SkillManager.pm::_sync_local_skill_source',
    'Developer/Dashboard/SkillManager.pm::_terminate_streaming_command',
    'Developer/Dashboard/SkillManager.pm::_install_skill_dependency_manifest',
    'Developer/Dashboard/Web/Server.pm::_waitpid',
    'Developer/Dashboard/Web/Server.pm::generate_self_signed_cert',
    'Developer/Dashboard/Web/Server.pm::_ssl_cert_has_expected_profile',
);

# _subs_in_file($path)
# Extracts every top-level named sub's source text from one Perl module,
# using this codebase's own consistent formatting convention (an opening
# "sub name {" line, and either a same-line close for a one-liner or a lone
# "}" line at column 0 for a multi-line body) rather than a full parser -
# deliberately dependency-free so this gate needs nothing beyond core Perl.
# Input: file path string.
# Output: list of { name => ..., body => ... } hash references.
sub _subs_in_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my @lines = <$fh>;
    close $fh or die "Unable to close $path: $!";

    my @subs;
    my $i = 0;
    while ( $i <= $#lines ) {
        if ( $lines[$i] =~ /\A sub \s+ (\w+) /x ) {
            my $name  = $1;
            my $body  = $lines[$i];
            if ( $body !~ /\{ .* \}/x ) {
                $i++;
                while ( $i <= $#lines && $lines[$i] !~ /\A \} \s* \z/x ) {
                    $body .= $lines[$i];
                    $i++;
                }
                $body .= $lines[$i] if $i <= $#lines;
            }
            push @subs, { name => $name, body => $body };
        }
        $i++;
    }
    return @subs;
}

# _strip_comments($text)
# Removes every Perl "#" comment from a block of source text, tracking single-
# and double-quote state (with backslash escaping) so a "#" or backtick INSIDE
# a string literal is never mistaken for the start of a comment. DD-693: both
# sweeps below used to grep raw source, so a comment quoting `backticks` or
# naming "$?" in prose read exactly like the code it was explaining - an
# explanation of the defect became indistinguishable from the defect itself.
# Deliberately dependency-free (no PPI), matching the rest of this file's
# style; a full comment can still leave a trailing newline, which is fine
# because every regex this feeds is a substring search, not an anchor.
# Input: multi-line source text string.
# Output: the same text with every "#"-to-end-of-line comment removed.
sub _strip_comments {
    my ($text) = @_;
    my $out = '';
    my $quote = '';    # '' | "'" | '"'
    my @pending_heredocs;    # DD-1019: tags to strip once the current line ends
    my $i = 0;
    my $len = length $text;
    while ( $i < $len ) {
        my $ch = substr( $text, $i, 1 );
        if ($quote) {
            $out .= $ch;
            if ( $ch eq '\\' && $i + 1 < $len ) {
                $out .= substr( $text, $i + 1, 1 );
                $i += 2;
                next;
            }
            $quote = '' if $ch eq $quote;
            $i++;
            next;
        }
        if ( $ch eq q{'} || $ch eq q{"} ) {
            $quote = $ch;
            $out .= $ch;
            $i++;
            next;
        }
        if ( $ch eq '#' ) {
            $i++;
            $i++ while $i < $len && substr( $text, $i, 1 ) ne "\n";
            next;
        }
        # DD-1019: a heredoc body is not "inside a string" the way the
        # quote-tracking above understands strings, so <<'TAG'/<<"TAG" must
        # be handled on its own - otherwise a documentation heredoc's own
        # markdown backticks or "#" read straight through as real code (the
        # exact shape that made CLI/Ask.pm::_docs_context a false positive).
        if ( substr( $text, $i, 2 ) eq '<<'
            && substr( $text, $i ) =~ m{\A<<(['"]?)([A-Za-z_]\w*)\1} ) {
            my $matched = '<<' . $1 . $2 . $1;
            $out .= $matched;
            $i += length $matched;
            push @pending_heredocs, $2;
            next;
        }
        if ( $ch eq "\n" ) {
            $out .= $ch;
            $i++;
            while (@pending_heredocs) {
                my $tag = shift @pending_heredocs;
                while ( $i < $len ) {
                    my $nl = index( $text, "\n", $i );
                    $nl = $len if $nl == -1;
                    my $line = substr( $text, $i, $nl - $i );
                    $i = ( $nl < $len ) ? $nl + 1 : $nl;
                    last if $line eq $tag;
                }
            }
            next;
        }
        $out .= $ch;
        $i++;
    }
    return $out;
}

# _unguarded_dollar_question_hits($lib_dir)
# Sweeps every .pm file under a lib/ root for a sub that reads the global $?
# without a preceding "local $?;" guard anywhere in its own body - the shape
# DD-585/589-593/597 exist to fix, where a query helper's own subprocess call
# leaves $? mutated for whatever the CALLER reads next.
# Input: lib/ directory path string.
# Output: hash reference keyed "relative/File.pm::sub_name" for every hit.
sub _unguarded_dollar_question_hits {
    my ($lib_dir) = @_;
    my @files;
    find( { wanted => sub { push @files, $File::Find::name if /\.pm\z/ }, no_chdir => 1 }, $lib_dir );

    my %hits;
    for my $file ( sort @files ) {
        my ($rel) = $file =~ /\Q$lib_dir\E\/?(.*)/;
        for my $sub ( _subs_in_file($file) ) {
            my $code = _strip_comments( $sub->{body} );
            next if $code !~ /\$\?/;
            next if $code =~ /local\s+\$\?/;
            $hits{"$rel\::$sub->{name}"} = 1;
        }
    }
    return \%hits;
}

# _unguarded_dollar_question_setters($lib_dir)
# Sweeps every .pm file under a lib/ root for a sub that SETS the global $? -
# by calling waitpid, system, or backticks - without a preceding "local $?;"
# guard anywhere in its own body. This is the setting half of the same bug
# class the read-side sweep above catches: a sub that reads $? unguarded is a
# sub that might be MISLED by a stale value; a sub that sets $? unguarded is
# the sub that does the misleading, and it is invisible to the read-side
# sweep by construction (DD-670).
# Input: lib/ directory path string.
# Output: hash reference keyed "relative/File.pm::sub_name" for every hit.
sub _unguarded_dollar_question_setters {
    my ($lib_dir) = @_;
    my @files;
    find( { wanted => sub { push @files, $File::Find::name if /\.pm\z/ }, no_chdir => 1 }, $lib_dir );

    my %hits;
    for my $file ( sort @files ) {
        my ($rel) = $file =~ /\Q$lib_dir\E\/?(.*)/;
        for my $sub ( _subs_in_file($file) ) {
            my $code = _strip_comments( $sub->{body} );
            my $sets = $code =~ /\bwaitpid\s*\(/
                || $code =~ /\bsystem\s*\(/
                || $code =~ /`[^`]*`/;
            next if !$sets;
            next if $code =~ /local\s+\$\?/;
            $hits{"$rel\::$sub->{name}"} = 1;
        }
    }
    return \%hits;
}

# DD-693: _strip_comments unit coverage, run before the real sweep so a
# regression in the stripper itself is caught with a precise diagnostic
# rather than surfacing as a confusing sweep false-positive/negative.
is( _strip_comments("my \$x = 1; # a comment mentioning \$? and `backticks`\n"),
    "my \$x = 1; \n",
    'a trailing comment naming $? and backticks is stripped, code before it survives' );
is( _strip_comments("    # whole-line comment with `backticks` and \$?\n    return 1;\n"),
    "    \n    return 1;\n",
    'a whole-line comment is stripped entirely, the following code line survives' );
is( _strip_comments(q{my $s = "a # not a comment";} . "\n"),
    q{my $s = "a # not a comment";} . "\n",
    'a "#" inside a double-quoted string is not treated as a comment start' );
is( _strip_comments(q{my $s = 'another # not a comment';} . "\n"),
    q{my $s = 'another # not a comment';} . "\n",
    'a "#" inside a single-quoted string is not treated as a comment start' );
is( _strip_comments(q{my $s = "escaped \" quote # still inside the string"; # real comment} . "\n"),
    q{my $s = "escaped \" quote # still inside the string"; } . "\n",
    'a backslash-escaped quote inside a string does not end the string early, so a "#" before the real closing quote stays part of the string' );

# DD-1019: a heredoc body is not "inside a string" the way the quote-tracker
# above understands strings, so a documentation heredoc containing markdown
# backticks (`dashboard`) or a literal "#" previously fell straight through
# as ordinary code - the exact shape that made CLI/Ask.pm::_docs_context a
# false positive for the setter sweep. _strip_comments must recognize a
# <<'TAG' / <<"TAG" opener and discard every line up to and including the
# line that is exactly TAG, leaving code that follows the heredoc intact.
is( _strip_comments(qq{return <<'DOCS';\nSee \`dashboard\` and \# not a comment.\nDOCS\nmy \$after = 1;\n}),
    qq{return <<'DOCS';\nmy \$after = 1;\n},
    'a single-quoted heredoc body (markdown backticks and a literal "#") is stripped entirely, code after the terminator survives' );
is( _strip_comments(qq{return <<"DOCS";\nSee \`dashboard\` and \# not a comment.\nDOCS\nmy \$after = 1;\n}),
    qq{return <<"DOCS";\nmy \$after = 1;\n},
    'a double-quoted heredoc body is stripped the same way' );

my $lib_dir = _repo_path('lib');
my $hits    = _unguarded_dollar_question_hits($lib_dir);

my @new_hits   = sort grep { !$BASELINE{$_} } keys %$hits;
my @stale_base = sort grep { !$hits->{$_} } keys %BASELINE;

is( scalar(@new_hits), 0,
    'no sub outside the DD-597 baseline reads $? without a preceding local $?; guard' )
  or diag( "New unguarded \$? use(s) not in the DD-611 baseline:\n" . join( "\n", map {"  $_"} @new_hits ) );

is( scalar(@stale_base), 0,
    'every DD-597 baseline entry still reproduces (a fix must shrink this test\'s baseline, not leave it stale)' )
  or diag( "Baseline entries the sweep no longer finds (fixed - remove from t/159's \%BASELINE):\n"
      . join( "\n", map {"  $_"} @stale_base ) );

my $setter_hits      = _unguarded_dollar_question_setters($lib_dir);
my @new_setter_hits   = sort grep { !$SETTER_BASELINE{$_} } keys %$setter_hits;
my @stale_setter_base = sort grep { !$setter_hits->{$_} } keys %SETTER_BASELINE;

is( scalar(@new_setter_hits), 0,
    'no sub outside the DD-670 setter baseline sets $? (via waitpid/system/backticks) without a preceding local $?; guard' )
  or diag( "New unguarded \$?-setting use(s) not in the DD-670 setter baseline:\n"
      . join( "\n", map {"  $_"} @new_setter_hits ) );

is( scalar(@stale_setter_base), 0,
    'every DD-670 setter baseline entry still reproduces (a fix must shrink this test\'s setter baseline, not leave it stale)' )
  or diag( "Setter baseline entries the sweep no longer finds (fixed - remove from t/159's \%SETTER_BASELINE):\n"
      . join( "\n", map {"  $_"} @stale_setter_base ) );

done_testing;

__END__

=head1 NAME

t/159-dollar-question-guard-sweep.t - catch a new sub reading OR setting $?
without a local $?; guard

=head1 PURPOSE

Sweeps every sub under C<lib/> for a read of the global C<$?> with no
preceding C<local $?;> guard in its own body, and compares the result against
an explicit baseline of DD-597's still-open findings, so this specific bug
class (DD-585/589-593/597: a query helper's own subprocess call leaves C<$?>
mutated for whatever the caller reads next) cannot regress silently, and
cannot be "fixed" by simply deleting the guard without also touching this
baseline.

DD-670 widened this to the OTHER half of the same defect: a sub can leave
C<$?> mutated for its caller without ever reading C<$?> itself, simply by
calling C<waitpid>, C<system>, or backticks and never guarding the value.
That is invisible to the read-side sweep by construction, so a second sweep
and a second, separately-triaged baseline (C<%SETTER_BASELINE>) cover it.

DD-693 fixed both sweeps matching raw source instead of code: a comment
quoting backticks (e.g. explaining an unrelated helper's own backtick usage
in prose) read as a command substitution, and a comment merely naming the
variable C<$?> read as an unguarded read - so an explanation of this exact
bug class was itself flagged as an instance of it. C<_strip_comments> now
removes every C<#>-to-end-of-line comment (tracking quote state so a C<#> or
backtick inside a string literal is left alone) before either sweep runs.
Re-deriving C<%SETTER_BASELINE> against the stripped source found six
entries that were never real offenders - each verified by hand to contain no
actual C<waitpid>/C<system>/backtick call, only a comment quoting one in
prose - and removed them.

=head1 WHY IT EXISTS

DD-597 found 25 more instances of the same bug DD-585/589-593 already fixed
six times, using a one-off sweep script that existed only in C</tmp> and ran
exactly once. Nothing stopped a twenty-sixth instance from shipping the next
day. This test makes the sweep a standing part of C<prove -lr t> instead of a
manual step someone has to remember to repeat. It intentionally does not
demand either baseline be empty: DD-597 (and now DD-670's setter baseline)
are separate, already-open tickets, and gating this check on their landing
first would mean the regression-prevention half of the fix (a NEW unguarded
sub failing the suite) ships only once someone else's unrelated ticket
closes. Each baseline is that ticket's own findings by name, so fixing one
requires shrinking the matching baseline here - a fix that leaves a stale
entry behind fails this test exactly as loudly as a genuinely new, unguarded
sub would.

DD-670 also found that a $?-setting sub is NOT automatically a bug: a
top-level entry point whose own caller never reads C<$?> afterward needs no
guard, and guarding every setter regardless makes the next genuinely risky
instance unfindable among the noise. C<%SETTER_BASELINE> therefore records
every currently-unguarded setter this sweep finds, whether or not it was
individually confirmed as a real caller-visible leak - the ones that were
confirmed (matching the shape DD-585/589-593/597/670 already fixed
elsewhere, e.g. a C<_pid_is_running>-style query calling an unguarded
C<_reap_child_process>) are guarded and removed from the baseline; the rest
stay listed as tracked-but-untriaged rather than silently unguarded.

=head1 WHEN TO USE

Every suite run. Also read this file's C<%BASELINE> and C<%SETTER_BASELINE>
whenever DD-597, DD-670, or any future sub in either shape is fixed - the fix
is incomplete until the fixed entry is removed from the matching baseline,
and this test fails loudly on a stale entry to make that unmissable.

=head1 HOW TO USE

  PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/159-dollar-question-guard-sweep.t

=head1 WHAT USES IT

The suite, through C<prove -lr t>, and therefore CI. Its subject is every
C<.pm> file under C<lib/>.

=head1 EXAMPLES

To watch it fail on a read-side regression, add a new sub anywhere under
C<lib/> that calls C<system()> and later reads C<$?> with no C<local $?;>
guard, then rerun - the new sub is named in the diagnostic. To watch it fail
on a setting-side regression, add a new sub that calls C<waitpid>, C<system>,
or backticks with no C<local $?;> guard - it is reported against
C<%SETTER_BASELINE> the same way. To watch either fail on a stale baseline,
fix any listed sub without removing its entry from the matching hash here.

=cut
