package Developer::Dashboard::Doctor;

use strict;
use warnings;

our $VERSION = '4.03';

use File::Find ();
use File::Spec;

use Developer::Dashboard::InternalCLI ();
use Developer::Dashboard::JSON qw(json_decode);

# new(%args)
# Constructs the dashboard doctor runtime service.
# Input: paths object.
# Output: Developer::Dashboard::Doctor object.
sub new {
    my ( $class, %args ) = @_;
    my $paths = $args{paths} || die 'Missing paths registry';
    return bless { paths => $paths }, $class;
}

# run(%args)
# Audits dashboard runtime trees for owner-only file-system permissions,
# checks staged helper drift, and merges any pre-run doctor hook results
# exported through RESULT.
# Input: optional fix boolean.
# Output: hash reference with ok flag, root reports, issues, and hook results.
sub run {
    my ( $self, %args ) = @_;
    my $fix = $args{fix} ? 1 : 0;
    my @roots = $self->_audit_roots( fix => $fix );
    my @helper_issues = $self->_helper_issues( fix => $fix );
    my @shell_issues = $self->_shell_bootstrap_issues( fix => $fix );
    my @issues = map { @{ $_->{issues} || [] } } @roots;
    push @issues, @helper_issues;
    push @issues, @shell_issues;
    my $hooks = $self->_doctor_hook_results;
    my @hook_failures = grep { ( $_->{exit_code} || 0 ) != 0 } values %{$hooks};

    return {
        ok            => @issues || @hook_failures ? 0 : 1,
        fix_applied   => $fix,
        roots         => \@roots,
        issues        => \@issues,
        issue_count   => scalar @issues,
        helper_issues => \@helper_issues,
        shell_issues  => \@shell_issues,
        hooks         => $hooks,
        hook_failures => scalar @hook_failures,
    };
}

# _audit_roots(%args)
# Audits the known new and older dashboard roots when they exist.
# Input: optional fix boolean.
# Output: list of root audit hash references.
sub _audit_roots {
    my ( $self, %args ) = @_;
    my %seen;
    my @reports;
    for my $root ( $self->_known_roots ) {
        next if !$root->{path} || $seen{ $root->{path} }++;
        push @reports, $self->_audit_root( %{$root}, fix => $args{fix} );
    }
    return @reports;
}

# _known_roots()
# Returns the current and older dashboard roots that should be audited.
# Input: none.
# Output: list of hash references with label and path keys.
sub _known_roots {
    my ($self) = @_;
    my $home = $self->{paths}->home;
    return (
        {
            label => 'home_runtime',
            path  => $self->{paths}->home_runtime_path,
        },
        map {
            +{
                label => $_->{label},
                path  => File::Spec->catdir( $home, $_->{name} ),
            }
        } (
            { label => 'legacy_bookmarks', name => 'bookmarks' },
            { label => 'legacy_config',    name => 'config' },
            { label => 'legacy_cli',       name => 'cli' },
            { label => 'legacy_checkers',  name => 'checkers' },
        ),
    );
}

# _audit_root(%args)
# Audits one runtime root recursively for owner-only directory and file modes.
# Input: root path, label, and optional fix boolean.
# Output: hash reference with root metadata and any discovered permission issues.
sub _audit_root {
    my ( $self, %args ) = @_;
    my $path = $args{path} || die 'Missing audit root path';
    my $label = $args{label} || die 'Missing audit root label';
    my $fix = $args{fix} ? 1 : 0;

    return {
        label       => $label,
        path        => $path,
        exists      => 0,
        issue_count => 0,
        issues      => [],
    } if !-e $path;

    my @issues;
    File::Find::find(
        {
            no_chdir => 1,
            wanted   => sub {
                my $entry = $File::Find::name;
                my $issue = $self->_permission_issue_for_path($entry);
                return if !$issue;
                if ($fix) {
                    chmod oct( $issue->{expected_mode} ), $entry
                      or die sprintf 'Unable to chmod %s to %s: %s', $entry, $issue->{expected_mode}, $!;
                    $issue->{fixed} = 1;
                    $issue->{current_mode} = $issue->{expected_mode};
                }
                push @issues, $issue;
            },
        },
        $path,
    );

    return {
        label       => $label,
        path        => $path,
        exists      => 1,
        issue_count => scalar @issues,
        issues      => \@issues,
    };
}

# _permission_issue_for_path($path)
# Checks whether one path deviates from the owner-only runtime policy.
# Input: file or directory path string.
# Output: hash reference describing the mismatch, or undef when compliant.
sub _permission_issue_for_path {
    my ( $self, $path ) = @_;
    return if !defined $path || $path eq '';
    my $mode = _mode_octal($path);
    return if !defined $mode;

    my $expected = -d $path ? '0700' : ( -x $path ? '0700' : '0600' );
    return if $mode eq $expected;

    return {
        path          => $path,
        kind          => -d $path ? 'directory' : 'file',
        current_mode  => $mode,
        expected_mode => $expected,
        fixed         => 0,
    };
}

# _doctor_hook_results()
# Decodes any doctor hook results exported through RESULT.
# Input: none.
# Output: hash reference of hook result hashes.
sub _doctor_hook_results {
    my ($self) = @_;
    return {} if !defined $ENV{RESULT} || $ENV{RESULT} eq '';
    my $results = json_decode( $ENV{RESULT} );
    die 'Doctor hook RESULT must decode to a hash'
      if ref($results) ne 'HASH';
    return $results;
}

# _helper_issues(%args)
# Audits the staged managed helper namespace for missing or stale dashboard
# helper assets and optionally restages them through the managed helper path.
# Input: optional fix boolean.
# Output: list of helper issue hash references.
sub _helper_issues {
    my ( $self, %args ) = @_;
    my $fix = $args{fix} ? 1 : 0;
    my $helper_root = File::Spec->catdir( $self->{paths}->cli_root, 'dd' );
    my @issues;

    for my $name ( '_dashboard-core', Developer::Dashboard::InternalCLI::helper_names() ) {
        my $path = File::Spec->catfile( $helper_root, $name );
        my $issue = $self->_helper_issue_for_path( name => $name, path => $path );
        push @issues, $issue if $issue;
    }

    if ( $fix && @issues ) {
        Developer::Dashboard::InternalCLI::ensure_helpers( paths => $self->{paths} );
        for my $issue (@issues) {
            my $post_issue = $self->_helper_issue_for_path(
                name => $issue->{helper_name},
                path => $issue->{path},
            );
            $issue->{fixed} = $post_issue ? 0 : 1;
        }
    }

    return @issues;
}

# _helper_issue_for_path(%args)
# Compares one staged managed helper file against the currently shipped helper
# body and reports missing or stale content drift.
# Input: helper name plus expected staged path.
# Output: hash reference describing the helper drift, or undef when current.
sub _helper_issue_for_path {
    my ( $self, %args ) = @_;
    my $name = $args{name} || die 'Missing helper audit name';
    my $path = $args{path} || die 'Missing helper audit path';
    my $expected = Developer::Dashboard::InternalCLI::_managed_helper_content($name);

    if ( !-f $path ) {
        return {
            path          => $path,
            kind          => 'helper',
            helper_name   => $name,
            current_mode  => 'missing',
            expected_mode => 'managed-helper-current',
            problem       => 'missing managed helper',
            fixed         => 0,
        };
    }

    open my $fh, '<:raw', $path or die "Unable to read $path: $!";
    local $/;
    my $current = <$fh>;
    close $fh;

    return undef if defined $current && $current eq $expected;

    return {
        path          => $path,
        kind          => 'helper',
        helper_name   => $name,
        current_mode  => 'stale',
        expected_mode => 'managed-helper-current',
        problem       => 'stale managed helper content',
        fixed         => 0,
    };
}

# _shell_bootstrap_issues(%args)
# Audits shell bootstrap files for dashboard-managed lines that are unreachable
# in non-interactive shells such as tmux status commands on Debian-family bash
# setups, and optionally rewrites those lines above the early-return guard.
# Input: optional fix boolean.
# Output: list of shell bootstrap issue hash references.
sub _shell_bootstrap_issues {
    my ( $self, %args ) = @_;
    my $fix = $args{fix} ? 1 : 0;
    my $bashrc = File::Spec->catfile( $self->{paths}->home, '.bashrc' );
    my @issues;

    my $issue = $self->_bashrc_bootstrap_issue( path => $bashrc );
    if ($issue) {
        if ($fix) {
            $self->_rewrite_bashrc_dashboard_lines($bashrc);
            my $post_issue = $self->_bashrc_bootstrap_issue( path => $bashrc );
            $issue->{fixed} = $post_issue ? 0 : 1;
        }
        push @issues, $issue;
    }

    return @issues;
}

# _bashrc_bootstrap_issue(%args)
# Detects whether dashboard-managed bash bootstrap lines appear after the
# standard bash non-interactive return guard in ~/.bashrc.
# Input: bashrc path.
# Output: hash reference describing the misplaced bootstrap issue, or undef.
sub _bashrc_bootstrap_issue {
    my ( $self, %args ) = @_;
    my $path = $args{path} || die 'Missing bashrc audit path';
    return undef if !-f $path;

    my $text = $self->_slurp_text_file($path);
    my ( $guard_start, $guard_end ) = $self->_bash_noninteractive_guard_offsets($text);
    return undef if !defined $guard_end;

    my @dashboard_lines = $self->_dashboard_bashrc_lines($text);
    return undef if !@dashboard_lines;

    my $after_guard = 0;
    for my $line (@dashboard_lines) {
        my $position = index( $text, $line );
        next if $position < 0;
        if ( $position >= $guard_end ) {
            $after_guard = 1;
            last;
        }
    }
    return undef if !$after_guard;

    return {
        path          => $path,
        kind          => 'shell-bootstrap',
        current_mode  => 'after-noninteractive-return',
        expected_mode => 'before-noninteractive-return',
        problem       => 'dashboard-managed bash bootstrap is hidden behind the non-interactive return guard',
        fixed         => 0,
    };
}

# _rewrite_bashrc_dashboard_lines($path)
# Moves dashboard-managed bash bootstrap lines ahead of the standard bash
# non-interactive return guard so tmux status commands can resolve dashboard in
# non-interactive shells.
# Input: bashrc path string.
# Output: none. Dies on read or write failures.
sub _rewrite_bashrc_dashboard_lines {
    my ( $self, $path ) = @_;
    my $text = $self->_slurp_text_file($path);
    my ( $guard_start, $guard_end ) = $self->_bash_noninteractive_guard_offsets($text);
    return if !defined $guard_start || !defined $guard_end;

    my @dashboard_lines = $self->_dashboard_bashrc_lines($text);
    return if !@dashboard_lines;

    for my $line (@dashboard_lines) {
        $text =~ s/^\Q$line\E\n?//mg;
    }

    my $before = substr( $text, 0, $guard_start );
    my $guard  = substr( $text, $guard_start, $guard_end - $guard_start );
    my $after  = substr( $text, $guard_end );

    $before =~ s/\s+\z//;
    my $replacement = join( "\n", @dashboard_lines ) . "\n";
    my $rewritten = q{};
    $rewritten .= $before . "\n" if length $before;
    $rewritten .= $replacement;
    $rewritten .= $guard;
    $rewritten .= $after;

    open my $write_fh, '>', $path or die "Unable to write $path: $!";
    print {$write_fh} $rewritten;
    close $write_fh or die "Unable to close $path after writing: $!";
}

# _dashboard_bashrc_lines($text)
# Extracts dashboard-managed bash bootstrap lines from one bashrc body while
# preserving their original order.
# Input: bashrc text string.
# Output: list of dashboard-managed line strings.
sub _dashboard_bashrc_lines {
    my ( $self, $text ) = @_;
    my @matches;
    for my $line ( split /\n/, defined($text) ? $text : q{} ) {
        next if !$self->_is_dashboard_bashrc_line($line);
        push @matches, $line;
    }
    return @matches;
}

# _is_dashboard_bashrc_line($line)
# Recognizes one dashboard-managed bash bootstrap line that must remain
# reachable in non-interactive shells.
# Input: one bashrc line string.
# Output: true when the line belongs to the dashboard-managed bootstrap set.
sub _is_dashboard_bashrc_line {
    my ( $self, $line ) = @_;
    return 0 if !defined $line || $line eq q{};
    return 1 if $line =~ /\Aexport PERLBREW_HOME=.*perlbrew.*\z/;
    return 1 if $line =~ /\Aexport PATH=.*perlbrew\/perls\/.*:\$PATH"?\z/;
    return 1 if $line =~ /\Aeval "\$\(".*-Mlocal::lib\)"\z/;
    return 1 if $line =~ /\Aeval "\$\(".*dashboard" shell bash\)"\z/;
    return 0;
}

# _bash_noninteractive_guard_offsets($text)
# Locates the standard bash non-interactive early-return guard inside one
# bashrc body.
# Input: bashrc text string.
# Output: two-element list containing the guard start and end offsets, or
#         undef values when the guard is absent.
sub _bash_noninteractive_guard_offsets {
    my ( $self, $text ) = @_;
    return ( undef, undef ) if !defined $text;
    my $guard_re = qr{
        (?:
            ^case \s+ \$- \s+ in \s* \n
            (?:
                (?! ^[ \t]* esac \s* $ )
                .*\n
            )*?
            ^[ \t]* \*i\* \) \s* ;; \s* \n
            ^[ \t]* \* \) \s* return \s* ;; \s* \n
            ^[ \t]* esac \s* \n?
        )
        |
        (?:
            ^[ \t]* \[ \s* -z \s+ "\$PS1" \s* \] \s* && \s* return \s* \n?
        )
    }xms;
    return ( undef, undef ) if $text !~ /$guard_re/;
    my $start = $-[0];
    my $end   = $+[0];
    return ( $start, $end );
}

# _slurp_text_file($path)
# Reads one UTF-8-safe text file body for doctor audits and repairs.
# Input: file path string.
# Output: complete file contents as a string.
sub _slurp_text_file {
    my ( $self, $path ) = @_;
    open my $read_fh, '<', $path or die "Unable to read $path: $!";
    local $/;
    my $text = <$read_fh>;
    close $read_fh or die "Unable to close $path after reading: $!";
    return defined($text) ? $text : q{};
}

# _mode_octal($path)
# Returns the permission bits for one file-system entry in four-digit octal form.
# Input: file or directory path string.
# Output: four-digit octal mode string or undef when stat fails.
sub _mode_octal {
    my ($path) = @_;
    my @stat = stat($path);
    return undef if !@stat;
    return sprintf '%04o', $stat[2] & 07777;
}

1;

__END__

=head1 NAME

Developer::Dashboard::Doctor - runtime permission doctor for Developer Dashboard

=head1 SYNOPSIS

  my $doctor = Developer::Dashboard::Doctor->new(paths => $paths);
  my $report = $doctor->run(fix => 1);

=head1 DESCRIPTION

This module audits the current home runtime and any older dashboard roots that
still exist in the user's home directory, checking that directories are
owner-only, that files are readable only by the owner unless they are meant
to stay owner-executable, and that staged dashboard-managed helpers under
F<~/.developer-dashboard/cli/dd/> still match the currently shipped helper
assets.

=head1 METHODS

=head2 new, run

Construct the doctor service and audit the known dashboard roots.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module audits and optionally repairs runtime permissions. It checks the home runtime and older dashboard roots for owner-only directory and file modes, inspects staged dashboard-managed helpers for missing or stale helper drift, applies the expected C<0700>/C<0600> policy where needed, restages helpers through the managed helper path when possible, and returns a structured report that the CLI can print or act on.

=head1 WHY IT EXISTS

It exists because runtime security should be inspectable and fixable from inside the product instead of depending on a manual shell checklist. That gives users and tests one trusted place to check whether the dashboard runtime is private enough.

=head1 WHEN TO USE

Use this file when changing the runtime permission policy, the report format for C<dashboard doctor>, or the set of files and directories that should be audited and repaired.

=head1 HOW TO USE

Construct it with the active path registry, call C<run(fix =E<gt> 0)> to audit or C<run(fix =E<gt> 1)> to repair, and let the CLI wrapper render the resulting report. Site-specific doctor hooks should remain in the command hook layer, not inside this module.

=head1 WHAT USES IT

It is used by the C<dashboard doctor> helper, by security and integration tests, and by contributors verifying that init/update paths do not leave insecure runtime permissions behind.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::Doctor -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/00-load.t t/21-refactor-coverage.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
