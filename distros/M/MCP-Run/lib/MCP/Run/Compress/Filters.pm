package MCP::Run::Compress::Filters;
# ABSTRACT: Command Output Compression Reference
our $VERSION = '0.107';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MCP::Run::Compress::Filters - Command Output Compression Reference

=head1 VERSION

version 0.107

=head1 DESCRIPTION

This document lists all commands that L<MCP::Run::Compress> filters and how
they are compressed. Each filter removes noise, truncates verbose output,
and limits lines to reduce token count while preserving essential information.

The file holds no code. It is a promise about another file's behaviour, and
kept honest by F<t/60-filters-doc.t>, which compares every command named in
an C<=item> below against the filters L<MCP::Run::Compress> actually
registers, and fails on drift in either direction. Two rules follow from that,
and both matter when adding an entry:

=over 4

=item *

The command named in an C<=item> is the filter's B<identity> -- the shortest
command line that makes it match -- and nothing else. A filter registered for
the program C<iptables> is documented as C<iptables>, not as C<iptables -L>,
even though C<-L> is what one usually types; the C<-L> belongs in the prose.
Flags appear in the name only when the filter genuinely requires them, as
C<git diff --stat> does.

=item *

An entry documents a filter that exists. A command listed here is a command
the compressor really compresses. Anything else makes this reference worse
than silence: someone checking whether their tool is supported reads exactly
this file.

=back

=head1 COMMANDS

=head2 File System Commands

=over 4

=item C<ls>

Long listing format (C<-l>, C<-la>, etc.) is detected automatically from the
output. When detected, the filter strips permissions, owner, group, size,
date, inode, and device information. Only the file type letter and the
filename are preserved.

Every type C<ls -l> prints is recognised (C<-> C<b> C<c> C<d> C<D> C<l> C<p>
C<s>), as is the character some systems append to the mode column for the
file's alternate access method: C<.> for an SELinux context, C<+> for a POSIX
ACL, C<@> for macOS extended attributes. For a symlink the preserved name is
the whole C<< link -> target >>, because the target is the only thing the
entry actually states.

The date column is recognised in every shape C<ls --time-style=> produces:
the locale default (C<Aug 14 08:44>, and C<Mar 12 2024> for an older file),
C<iso> (C<08-23 10:00>), C<long-iso> (C<2026-08-23 10:00>), C<full-iso>
(C<2026-08-23 10:00:00.123456789 +0200>) and the date alone, as in
C<+%Y-%m-%d> (C<2026-08-23>). A strftime format that prints neither an ISO
date nor an ISO time is not recognised, and such a line stays uncollapsed.

For non-long listings, common noise directories are filtered:
F<node_modules>, F<.git>, F<.target>, F<.next>, F<.nuxt>, F<.cache>,
F<__pycache__>, F<.DS_Store>, F<vendor/bundle>.

    # Before: drwxr-xr-x. 14 getty getty 4096 Apr 24 02:32 .build
    # After:  d .build
    # Before: lrwxrwxrwx   1 getty getty    9 Apr 24 02:32 link -> target
    # After:  l link -> target

=item C<stat>

Strips Device, Inode, and Birth lines.

    # Before:
    #   Device: 801h/2049d      Inode: 1234567     Links: 1
    #   Birth: 2026-03-09 10:00:00.000000000 +0100
    # After: (lines removed)

=item C<find>

Strips C<permission denied> errors and limits results.

=item C<df>

Truncates columns at 80 characters, limits to 20 lines.

=item C<du>

Strips F<.git> and F<node_modules> directories, truncates at 150 characters,
max 50 lines.

=back

=head2 Git Commands

=over 4

=item C<git status>

Strips branch information, keeps changed/untracked files.

=item C<git diff>

Strips diff headers (C<diff --git>, C<index>, C<--->, C<+++>).
Keeps actual C<-> and C<+> lines with content.

=item C<git diff --stat>

Transforms to compact "N+M- filename" format (additions+deletions-filename).
Strips summary lines (X files changed, insertions(+), deletions(-)).

    # Before:
    #  file1.txt | 5 +++ --- 2 deletions(-)
    #  file2.rb  | 3 +++ --- 1 deletion(-)
    #  2 files changed, 8 insertions(+), 3 deletions(-)
    # After:
    #  5+2-file1.txt
    #  3+1-file2.rb

=item C<git log>

Shows first 20 and last 10 lines (with total count),
strips commit hashes, author, and date noise.

=item C<git branch>

Strips blank lines, max 30 lines.

=item C<git stash>

Strips blank lines, max 30 lines.

=item C<git commit>

The one filter that rewrites the B<command> instead of its output. When
C<CO_AUTHORED_BY> or C<ANTHROPIC_MODEL> is set, the Co-Authored-By trailer in
the commit message is replaced, or added to the last C<-m>/C<--message>
argument when none is present. Set C<MCP_RUN_COMPRESS_NO_CO_AUTHORED> to
disable it entirely.

Unlike every other git entry here this one matches inside compound commands,
so C<cd project && git add . && git commit -m "..."> is rewritten too. The
output of C<git commit> itself is left untouched.

=back

=head2 Build & Compile Commands

=over 4

=item C<make>

Strips C<make[N]: Entering directory>, C<Leaving directory>,
and C<Nothing to be done> messages.

    # On empty output: "make: ok"

=item C<cargo build>

Strips C<Compiling>, C<Fresh> and C<Finished> lines. Keeps errors.

=item C<cargo test>

Strips compilation and running noise. Max 100 lines.

=item C<gcc>, C<g++>

Merges stderr into stdout -- a compiler says everything there -- then strips
the include chain, the C<note:> lines and the echoed source with its caret
markers. The diagnostics themselves are kept: file, line, column, message.

    # Before:
    #   In file included from /usr/include/stdio.h:42:
    #   main.c:10:5: error: use of undeclared identifier 'foo'
    #      10 |     foo();
    #         |     ^
    # After:
    #   main.c:10:5: error: use of undeclared identifier 'foo'

=item C<swift build>

Strips the build chatter (C<[N/M]>, C<Compiling>, C<Fetching>, resolution and
C<Build complete!>), so that what remains is exactly the warnings and errors.
On a clean build nothing remains and the output becomes
C<swift build: ok (build complete)>.

=item C<mix compile>

Elixir Mix compiler. Strips C<Compiling N files>, C<Generated ... app> and Hex
dependency resolution lines. On empty output: C<mix compile: ok>.

=item C<pio run>

PlatformIO build. Strips the environment report (CONFIGURATION, PLATFORM,
HARDWARE, DEBUG, PACKAGES), the library dependency finder, and the compiling,
archiving, linking and size checking lines. The C<RAM:>/C<Flash:> usage lines
are kept. On empty output: C<pio run: ok>.

=item C<mvn>

Strips the C<[INFO]> bookkeeping -- separators, plugin banners, downloads,
C<Total time>, C<Finished at> -- but not every C<[INFO]> line: surefire
reports its test results there. C<[WARNING]> and C<[ERROR]> are untouched.

=item C<gradle>

Strips C<< > Task : >> lines for tasks that succeeded, were up to date,
skipped or came from the cache, plus daemon and download noise. A task line
carrying C<FAILED> is kept.

=back

=head2 Container Commands

=over 4

=item C<docker ps>, C<docker images>

Truncates columns at 120 characters, max 30 lines.

=item C<docker build>

Strips build progress (C<# N [M/N]>, C<Step N/M:>).

=item C<docker run>

Strips image pulling and status messages.

=item C<kubectl get>

Truncates columns at 150 characters, max 50 lines.

=item C<kubectl describe>

Strips name, namespace, labels, annotations noise.
Max 100 lines.

=item C<docker-compose>, C<docker compose>

Both the v1 binary and the v2 subcommand. Strips network, volume and
container lifecycle lines (C<Creating>, C<Started>, C<Healthy>, ...),
C<Pulling> and C<Attaching to>. Service log output is kept.

=back

=head2 Cloud & Infrastructure Commands

=over 4

=item C<terraform plan>, C<terraform apply>

Strips C<Refreshing state...> and progress messages.

=item C<helm install>, C<helm upgrade>

Strips NAME, NAMESPACE, STATUS, REVISION, NOTES noise.

=item C<ansible-playbook>

Strips PLAY/TASK banners, running handlers, and recap headers.
Max 100 lines.

=item C<tofu plan>, C<tofu apply>

OpenTofu is a Terraform fork and prints the same lines; these filters mirror
the C<terraform> ones above.

=item C<tofu init>

Short-circuits a successful init to C<tofu init: ok> -- there is nothing else
in it. A failing init keeps its output, minus provider discovery
(C<- Finding>, C<- Installing>, C<- Installed>).

=back

=head2 Package Managers

=over 4

=item C<cpanm>

Strips C<--> Working on, C<OK>, C<FAIL> noise.
Shows only essential progress.

=item C<npm install>

Strips added/found packages confirmation and warnings.

=item C<yarn install>, C<yarn add>, C<pnpm install>, C<pnpm add>

Strips C<Done in...>, C<Resolving completed>, C<Linking completed>.

=item C<pip install>

Strips C<Collecting>, C<Downloading>, C<Installing collected packages>.

=item C<cpan>

Strips the CPAN shell's narration: C<Reading '...'>, C<Database was generated
on>, C<Fetching with>, C<Checksum for>, C<Running make/test/install for>.

=item C<cpm>

Strips the per-distribution C<DONE ...> lines and keeps the summary. On empty
output: C<cpm: ok>.

=item C<composer install>

Strips repository loading, dependency updating, the per-package operation
lines, lock file writing and autoload generation. On empty output:
C<composer install: ok>.

=item C<brew install>

Strips C<< ==> Downloading >>, C<< ==> Pouring >>, C<< ==> Fetching >>,
auto-update noise and C<Already downloaded:>.
C<< ==> Installing dependencies for ... >> goes,
C<< ==> Installing ... >> stays.

=item C<poetry install>

Strips C<Installing dependencies from lock file>, C<Package operations:> and
the per-package bullet lines. On empty output: C<poetry install: ok>.

=item C<uv sync>

Strips the C<Resolved/Prepared/Audited N packages in ...> timings and the
C<+>/C<-> package list; C<Installed N packages> is kept. On empty output:
C<uv sync: ok>.

=back

=head2 System Commands

=over 4

=item C<ps>

Truncates columns at 120 characters, max 30 lines.

=item C<iptables>

Any invocation, C<iptables -L> in particular: truncates columns at 150
characters, max 50 lines.

=item C<ping>

Strips PING header, replies, and statistics.

=item C<rsync>

Strips sent/received bytes and total size summary.

=item C<netstat>

Truncates columns at 150 characters, max 50 lines.

=item C<ip addr>, C<ip route>, C<ip link>

C<ip addr> truncates at 150 characters, max 50 lines; C<ip route> and
C<ip link> strip blank lines, max 30 lines.

=item C<mount>

Truncates columns at 200 characters, max 50 lines.

=item C<lsblk>

Lists block devices in tree format. Truncates at 150 characters, max 50 lines.

=item C<blkid>

Lists block device attributes. Truncates at 200 characters, max 50 lines.

=item C<systemctl status>

Removes the state glyph from the unit line and strips the accounting block:
Loaded, Docs, Main PID, Tasks, Memory, CPU, CGroup and the process tree under
it. C<Active:> and the recent log lines are kept -- C<Active:> also carries
the state the glyph stood for.

=item C<journalctl>

Strips C<-- Reboot -->, C<-- Logs begin at ...>, C<-- Journal begins at ...>,
C<-- No entries --> and boot markers. Max 100 lines.

=item C<fail2ban-client>

Strips blank lines, max 30 lines.

=back

=head2 Development Tools

=over 4

=item C<grep>

Truncates lines at 150 characters, max 100 lines.

=item C<cat>

Strips blank lines, truncates at 500 characters, max 100 lines.

=item C<curl>

Merges stderr into stdout, strips progress (% Total, Resolving,
Connected to, HTTP/... responses).

=item C<wget>

Strips timestamp, resolving, connecting, length, saving, and
progress bar lines.

=item C<pytest>

Strips coverage and HTML report generation lines.

=item C<ollama run>

Strips ANSI escapes and the braille spinner frames. Nothing else: the output
is the model's answer, so no line of it is dropped, truncated or counted.

=item C<quarto render>

Short-circuits on C<Output created:> to C<quarto render: ok (output created)>.
Otherwise strips processing, validating and resolving messages and the
percentage progress lines.

=back

=head2 Version Control Systems

=over 4

=item C<jj>

Jujutsu VCS. Strips C<Hint:> lines, C<Working copy now at:>, C<Parent commit:>
and rebase counts, all of which arrive on stderr. Max 30 lines.

=item C<shopify theme push>, C<shopify theme pull>

Keeps only the last 5 lines -- the result and the preview URL. Deliberately
not registered for C<shopify theme> as a whole: C<shopify theme list> is
nothing but its answer, and a tail of 5 would cut it.

=back

=head1 FILTER STAGES

Each filter applies output through this pipeline, in this order:

=over 4

=item 1.

B<filter_stderr> - Merges stderr into stdout if configured

=item 2.

B<strip_ansi> - Removes ANSI escape codes (colors, cursor control)

=item 3.

B<collapse_cr> - Reduces carriage-return overwrites to the last state on each
line, which is what a terminal would have shown. Unconditional, with no filter
attribute: a progress bar carries no newlines at all, so to every stage below it
is a single line that C<max_lines> cannot shorten. Runs for commands no filter
matches, too: normalising C<\r> is display semantics rather than filtering.

=item 4.

B<match_output> - Short-circuits on pattern match, replacing the B<entire>
output with a fixed message. Only ever honest for success, when there is
nothing left to say: a diagnostic short-circuit deletes precisely what the
output was being read for. Patterns want C</m>, since they are matched against
the whole text rather than line by line.

=item 5.

B<transform> - Line-by-line transformation (e.g., strip ls permissions)

=item 6.

B<strip_lines_matching> - Removes lines matching regex patterns

=item 7.

B<keep_lines_matching> - Keeps only lines matching patterns

=item 8.

B<truncate_lines_at> - Truncates each line to N characters, appending C<...>

=item 9.

B<head_lines> / B<tail_lines> - Keeps first/last N lines, and says so:
C<... N lines omitted ...> goes after the kept lines when only the head is
kept, and before them when only the tail is kept. Truncating without a marker
would leave the model holding a fragment it has no reason to doubt.

=item 10.

B<max_lines> - Absolute line limit, appending C<... N more lines ...>. This
counts separately from the marker above: two markers in one output are normal
and their numbers do not add up to a single total.

=item 11.

B<on_empty> - Fallback message when output is empty after filtering

=back

=head1 ADDING CUSTOM FILTERS

    use MCP::Run::Compress;

    my $compressor = MCP::Run::Compress->new;

    # Legacy regex-based matching
    $compressor->register_filter(
        command => '^my-command\b',
        strip_lines_matching => [
            qr(^\s*$),
            qr(^Verbose:),
        ],
        truncate_lines_at => 100,
        max_lines => 30,
        on_empty => 'my-command: ok',
    );

    # New parsed_command matching (order-independent flags)
    $compressor->register_filter(
        parsed_command => {
            program    => 'my-tool',
            subcommand => 'process',
            flags      => { verbose => 1, output => 1 },
        },
        strip_lines_matching => [qr(^\s*$)],
        max_lines => 50,
    );

A filter added to the default table in L<MCP::Run::Compress> belongs in the
COMMANDS section above; F<t/60-filters-doc.t> fails until it is there.

=head1 PARSED COMMAND APPROACH

Filters can use either regex-based C<command> matching (legacy) or the new
C<parsed_command> approach. The parsed approach extracts program, subcommand,
and flags using L<Getopt::Long>, enabling order-independent flag matching.

    # Matches: git diff --stat, git diff --stat -w 5, git -C /path diff --stat
    $compressor->register_filter(
        parsed_command => {
            program    => 'git',
            subcommand => 'diff',
            flags      => { stat => 1 },
        },
        transform => sub { ... },
    );

The C<flags> hash specifies which flags must be present. Flag values are
ignored - only presence matters for matching.

Matching a program without a subcommand matches B<every> invocation of that
program, so such a filter shadows any program+subcommand filter for the same
program: the compressor stops at the first matching parsed filter, and which
one that is depends on hash order. C<kubectl get> and a bare C<kubectl> cannot
both exist as long as that is true.

=head1 SEE ALSO

L<MCP::Run::Compress>, L<MCP::Run>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-mcp-run/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
