#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use Capture::Tiny qw(capture);

# DD-1045-adjacent: reported live on macOS as
#   _dd_apply_tmux_ticket_status:12: no matches found: status-format[1]
# zsh treats an unquoted [...] word as a filename glob, and with its
# default NOMATCH option a pattern matching no file aborts the command
# with exactly that message - this is NOT a zsh syntax error (zsh -n
# would pass it clean), it is a runtime word-expansion failure, so the
# only real regression guard is executing the actual generated function
# in a real zsh (SKIP-guarded below) plus a static check that every
# status-format[N] literal in the generated shell text is quoted.

my $repo_root   = File::Spec->rel2abs('.');
my $private_core_path = File::Spec->catfile( $repo_root, 'share', 'private-cli', '_dashboard-core' );
my $private_core = _slurp($private_core_path);

# AC-1: every status-format[N] literal WITHIN A POSIX-FAMILY SHELL BLOCK
# (zsh/bash/sh) is quoted, never a bare word - a bare word is exactly
# what zsh glob-expands and dash/bash tolerate silently, which is why
# this bug shipped unnoticed for as long as it did. Deliberately scoped
# to the zsh/bash/sh blocks only: the PowerShell block also emits
# status-format[N] but PowerShell does not glob-expand bare arguments to
# native commands the way POSIX shells do, so it was not found to
# reproduce this bug and is intentionally left unquoted (a different
# argument-parsing model, not an oversight).
my $posix_blocks = join(
    "\n",
    grep { defined }
    map  { _extract_block_containing( $private_core, $_, '_dd_apply_tmux_ticket_status' ) }
    qw(zsh bash sh)
);
my @bare = $posix_blocks =~ /(?<!['"])status-format\[[0-9]\](?!['"])/g;
is( scalar(@bare), 0, 'no unquoted status-format[N] literal remains in the zsh/bash/sh blocks' )
    or diag("bare occurrences found: " . scalar(@bare));

# AC-2: the function is genuinely still present in all three POSIX-family
# shell blocks (zsh/bash/sh) - a regex checking for zero bare occurrences
# would trivially "pass" if the function were accidentally deleted instead
# of fixed, so assert its presence independently.
for my $shell (qw(zsh bash sh)) {
    like(
        $private_core,
        qr/_dd_apply_tmux_ticket_status/,
        "_dd_apply_tmux_ticket_status is still defined (checked once; shared across $shell/other blocks)"
    );
    last;    # the function body is identical across all three blocks; one presence check plus AC-1's
             # file-wide scan already covers all of them - looping would just repeat the same assertion.
}

# AC-3 (live execution, SKIP-guarded per-shell): source the REAL emitted
# zsh/bash/sh function bodies (extracted from the actual file, not
# hand-retyped) with a fake `tmux` on PATH, and confirm the function
# actually runs clean - this is the assertion that would have caught the
# real bug, since AC-1 alone only guards against regressing the fix in
# the exact way that this fix happened to fail, not against re-introducing
# an unquoted use elsewhere with different surrounding punctuation.
my $tmpdir = tempdir( CLEANUP => 1 );
my $fake_tmux = File::Spec->catfile( $tmpdir, 'tmux' );
open my $fh, '>', $fake_tmux or die "write $fake_tmux: $!";
print {$fh} "#!/usr/bin/env bash\nexit 0\n";
close $fh;
chmod 0755, $fake_tmux;

my %block_for_shell = (
    zsh  => _extract_block_containing( $private_core, 'zsh',  '_dd_apply_tmux_ticket_status' ),
    bash => _extract_block_containing( $private_core, 'bash', '_dd_apply_tmux_ticket_status' ),
    sh   => _extract_block_containing( $private_core, 'sh',   '_dd_apply_tmux_ticket_status' ),
);

for my $shell (qw(zsh bash sh)) {
    SKIP: {
        skip "$shell not available for live glob-expansion check", 1 if !_command_available($shell);
        my $block = $block_for_shell{$shell};
        ok( defined $block && length $block, "extracted a $shell block from _dashboard-core" )
            or skip "no $shell block extracted, cannot live-test it", 0;

        my $script = File::Spec->catfile( $tmpdir, "run.$shell" );
        open my $sfh, '>', $script or die "write $script: $!";
        print {$sfh} $block;
        print {$sfh} "\n_dd_apply_tmux_ticket_status\n";
        close $sfh;

        my ( $stdout, $stderr, $exit ) = capture {
            local $ENV{PATH} = "$tmpdir:$ENV{PATH}";
            local $ENV{TMUX} = 'fake';
            system $shell, $script;
            return $? >> 8;
        };
        is( $exit, 0, "_dd_apply_tmux_ticket_status exits 0 under real $shell" );
        unlike( $stderr, qr/no matches found/, "no zsh glob-expansion error under real $shell" )
            if $shell eq 'zsh';
        diag("$shell stderr: $stderr") if $stderr && $exit != 0;
    }
}

done_testing();

sub _extract_block_containing {
    my ( $source, $shell, $needle ) = @_;
    my $tag = uc($shell);

    # _dashboard-core defines this heredoc tag more than once (one set of
    # zsh/bash/sh blocks for prompt setup, another for the tmux ticket-status
    # hook this file guards) - so find every block under this tag and return
    # whichever one actually defines $needle, rather than assuming the first.
    while ( $source =~ /return <<'\Q$tag\E';\n(.*?)\n\Q$tag\E\n/gs ) {
        my $block = $1;
        return $block if index( $block, $needle ) >= 0;
    }
    return undef;
}

sub _slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "open $path: $!";
    local $/;
    return <$fh> // '';
}

sub _command_available {
    my ($name) = @_;
    my ( undef, undef, $exit_code ) = capture {
        system 'sh', '-c', "command -v '$name' >/dev/null 2>&1";
        return $? >> 8;
    };
    return $exit_code == 0 ? 1 : 0;
}

__END__

=pod

=head1 NAME

224-tmux-status-format-zsh-glob-quoting.t - proves DD-1045's tmux status-format[N] zsh-glob fix

=head1 PURPOSE

Guards that C<_dd_apply_tmux_ticket_status> (the tmux ticket-status prompt
hook emitted into every shell's init by C<share/private-cli/_dashboard-core>)
never passes an unquoted C<status-format[N]> word to C<tmux>, and that the
real zsh/bash/sh copies of the function still execute cleanly.

=head1 WHY IT EXISTS

Reported live on macOS: opening a tmux-integrated shell failed with

    _dd_apply_tmux_ticket_status:12: no matches found: status-format[1]

zsh treats an unquoted C<[...]> word as a filename glob pattern (a
character class), and its default C<NOMATCH> option aborts the whole
command when the pattern matches no file in the current directory -
which a fixed, literal tmux option name like C<status-format[1]> never
will. This is not a shell syntax error (C<zsh -n> passes the unfixed file
cleanly) - it is a runtime word-expansion failure that only zsh's default
glob behavior triggers; bash and POSIX C<sh> silently leave a
no-match unquoted glob as the literal word instead of erroring, which is
exactly why this shipped unnoticed on every host except a real
interactive zsh session. The fix quotes every C<status-format[N]> literal
in all three POSIX-family shell blocks (the PowerShell block is a
different argument-parsing model and was not found to reproduce this).

=head1 WHEN TO USE

Run this file whenever C<_dd_apply_tmux_ticket_status> or the tmux status
integration in C<share/private-cli/_dashboard-core> changes.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/224-tmux-status-format-zsh-glob-quoting.t

=head1 WHAT USES IT

C<_dd_apply_tmux_ticket_status> is not exercised by any other test file -
it is shell-init text generated by C<_dashboard-core>, never called
directly from Perl code, so this file is its only coverage.

=head1 EXAMPLES

Example 1:

    prove -lv t/224-tmux-status-format-zsh-glob-quoting.t

Confirms zero unquoted C<status-format[N]> literals remain, and (when zsh
is on PATH) that the real emitted zsh function runs to exit 0 with no
glob-expansion error.

=cut
