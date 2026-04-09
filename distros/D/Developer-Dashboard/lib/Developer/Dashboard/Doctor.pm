package Developer::Dashboard::Doctor;

use strict;
use warnings;

our $VERSION = '2.02';

use File::Find ();
use File::Spec;

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
# Audits dashboard runtime trees for owner-only file-system permissions and
# merges any pre-run doctor hook results exported through RESULT.
# Input: optional fix boolean.
# Output: hash reference with ok flag, root reports, issues, and hook results.
sub run {
    my ( $self, %args ) = @_;
    my $fix = $args{fix} ? 1 : 0;
    my @roots = $self->_audit_roots( fix => $fix );
    my @issues = map { @{ $_->{issues} || [] } } @roots;
    my $hooks = $self->_doctor_hook_results;
    my @hook_failures = grep { ( $_->{exit_code} || 0 ) != 0 } values %{$hooks};

    return {
        ok            => @issues || @hook_failures ? 0 : 1,
        fix_applied   => $fix,
        roots         => \@roots,
        issues        => \@issues,
        issue_count   => scalar @issues,
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
owner-only and that files are readable only by the owner unless they are meant
to stay owner-executable.

=head1 METHODS

=head2 new, run

Construct the doctor service and audit the known dashboard roots.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Perl module in the Developer Dashboard codebase. This file audits and repairs dashboard runtime permissions and health checks.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::Doctor> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::Doctor -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
