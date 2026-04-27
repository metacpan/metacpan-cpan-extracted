package MCP::Run::Compress::Filters;
# ABSTRACT: Command Output Compression Reference
our $VERSION = '0.100';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MCP::Run::Compress::Filters - Command Output Compression Reference

=head1 VERSION

version 0.100

=head1 DESCRIPTION

This document lists all commands that L<MCP::Run::Compress> filters and how
they are compressed. Each filter removes noise, truncates verbose output,
and limits lines to reduce token count while preserving essential information.

=head1 COMMANDS

=head2 File System Commands

=over 4

=item C<ls>

Long listing format (C<-l>, C<-la>, etc.) is detected automatically from the
output. When detected, the filter strips permissions, owner, group, size,
date, inode, and device information. Only the file type (C<d> or C<->) and
the filename are preserved.

For non-long listings, common noise directories are filtered:
F<node_modules>, F<.git>, F<.target>, F<.next>, F<.nuxt>, F<.cache>,
F<__pycache__>, F<.DS_Store>, F<vendor/bundle>.

    # Before: drwxr-xr-x 14 getty getty 4096 Apr 24 02:32 .build
    # After:  d .build

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

Filters out F<.git> and F<node_modules> directories.

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

=back

=head2 Build & Compile Commands

=over 4

=item C<make>

Strips C<make[N]: Entering directory>, C<Leaving directory>,
and C<Nothing to be done> messages.

    # On empty output: "make: ok"

=item C<gcc>, C<g++>

Strips include chain, compiler notes. Keeps errors and warnings.

    # Before:
    #   In file included from /usr/include/stdio.h:42:
    #   main.c:10:5: error: use of undeclared identifier 'foo'
    # After:
    #   main.c:10:5: error: use of undeclared identifier 'foo'

=item C<cargo build>

Strips C<Compiling> and C<Fresh> lines. Keeps errors.

=item C<cargo test>

Strips compilation and running noise. Max 100 lines.

=item C<swift build>

Short-circuits successful builds to C<ok (build complete)>,
unless warnings or errors are present.

=item C<mix compile>

Elixir Mix compiler. Strips C<Compiling N files>, C<Generated> lines.

=item C<pio run>

PlatformIO build. Strips verbose mode, configuration, LDF, library
manager, compiling, linking, building, and size checking messages.

=item C<mvn build>, C<gradle>

Build system noise stripped, errors preserved.

=item C<webpack>, C<esbuild>, C<vite>

Bundler/Build tool output condensed.

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

=back

=head2 Cloud & Infrastructure Commands

=over 4

=item C<terraform plan>, C<terraform apply>

Strips C<Refreshing state...> and progress messages.

=item C<tofu plan>, C<tofu validate>, C<tofu init>, C<tofu fmt>

OpenTofu variants. Strips tofu-specific noise.

=item C<helm install>, C<helm upgrade>

Strips NAME, NAMESPACE, STATUS, REVISION, NOTES noise.

=item C<ansible-playbook>

Strips PLAY/TASK banners, running handlers, and recap headers.
Max 100 lines.

=item C<docker-compose>

Compose service output filtered.

=item C<kubectl>

K8s CLI output compacted.

=item C<gcloud>

GCP CLI output filtered.

=back

=head2 Package Managers

=over 4

=item C<cpanm>

Strips C<--> Working on, C<OK>, C<FAIL> noise.
Shows only essential progress.

=item C<cpan>

CPAN shell output filtered.

=item C<cpm>

Perl C<cpm> package manager output filtered.

=item C<npm install>

Strips added/found packages confirmation and warnings.

=item C<yarn>, C<pnpm>

Strips C<Done in...>, C<Resolving completed>, C<Linking completed>.

=item C<composer install>

Strips repository loading, dependency updating, lock file operations.

=item C<pip install>

Strips C<Collecting>, C<Downloading>, C<Installing collected packages>.

=item C<brew install>

Package manager output filtered.

=item C<poetry install>

Python Poetry dependency installer output.

=item C<uv sync>

Python UV package manager.

=back

=head2 System Commands

=over 4

=item C<ps>

Truncates columns at 120 characters, max 30 lines.

=item C<systemctl status>

Strips status bullets (C<●>), Loaded, Main PID lines.

=item C<journalctl>

Strips C<-- Reboot -->, C<-- Logs begin at...>, C<-- No entries -->.
Max 100 lines.

=item C<iptables -L>

Truncates columns at 150 characters, max 50 lines.

=item C<ping>

Strips PING header, resolves, and statistics.

=item C<rsync>

Strips sent/received bytes and total size summary.

=item C<netstat>

Truncates columns at 150 characters, max 50 lines.

=item C<ip addr>, C<ip route>, C<ip link>

Truncates at 150 characters, max 30-50 lines.

=item C<mount>

Truncates columns at 200 characters, max 50 lines.

=item C<lsblk>

Lists block devices in tree format. Truncates at 150 characters, max 50 lines.

=item C<blkid>

Lists block device attributes. Truncates at 200 characters, max 50 lines.

=item C<fail2ban-client>

Strips blank lines, max 30 lines.

=item C<jira>

Strips verbose metadata and CLI option noise.

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

Strips ANSI spinner characters (⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏).

=item C<quarto render>

Short-circuits on C<Output created:> success to C<ok (output created)>.
Strips processing, validating, resolving messages.

=back

=head2 Version Control Systems

=over 4

=item C<jj>

Jujutsu VCS. Strips Hint lines and C<Working copy now at:> messages.
Max 30 lines.

=item C<shopify theme push>, C<shopify theme pull>

Keeps only the last 5 lines (typically the success/failure result).

=back

=head2 Other Commands

=over 4

=item C<sops>

Secrets management output filtered.

=item C<ty>

TigerBeetle CLI. Strips F<zig> noise.

=item C<yamllint>, C<hadolint>, C<shellcheck>

Linter output filtered for essential findings.

=item C<jq>

JSON processor output handled.

=item C<just>

Justfile runner output filtered.

=item C<mise>

DEV tools version manager.

=back

=head1 FILTER STAGES

Each filter applies output through this pipeline:

=over 4

=item 1.

B<strip_ansi> - Removes ANSI escape codes (colors, cursor control)

=item 2.

B<filter_stderr> - Merges stderr into stdout if configured

=item 3.

B<match_output> - Short-circuits on pattern match (e.g., success messages)

=item 4.

B<transform> - Line-by-line transformation (e.g., strip ls permissions)

=item 5.

B<strip_lines_matching> - Removes lines matching regex patterns

=item 6.

B<keep_lines_matching> - Keeps only lines matching patterns

=item 7.

B<truncate_lines_at> - Truncates each line to N characters

=item 8.

B<head_lines> / B<tail_lines> - Keeps first/last N lines

=item 9.

B<max_lines> - Absolute line limit

=item 10.

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

=head1 SEE ALSO

L<MCP::Run::Compress>, L<MCP::Run>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-mcp-run/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
