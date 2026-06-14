package Developer::Dashboard::Prompt;

use strict;
use warnings;
use utf8;

our $VERSION = '4.16';

use Cwd qw(abs_path cwd);
use File::Basename qw(basename);
use File::Spec;
use POSIX qw(strftime);

# new(%args)
# Constructs the prompt renderer.
# Input: indicators and paths objects.
# Output: Developer::Dashboard::Prompt object.
sub new {
    my ( $class, %args ) = @_;
    my $indicators = $args{indicators} || die 'Missing indicator store';
    my $paths      = $args{paths}      || die 'Missing paths registry';

    return bless {
        indicators => $indicators,
        paths      => $paths,
    }, $class;
}

# render(%args)
# Renders the shell prompt string from cached indicator and path state.
# Input: jobs count, cwd, display mode, color flag, and max-age options.
# Output: full prompt string suitable for command substitution in PS1.
sub render {
    my ( $self, %args ) = @_;

    my $jobs = defined $args{jobs} ? $args{jobs} : 0;
    my $cwd  = $args{cwd} || cwd();
    my $mode = $args{mode} || 'compact';
    my $color = exists $args{color} ? $args{color} : 0;
    my $max_age = defined $args{max_age} ? $args{max_age} : 300;
    my $no_indicators = $args{no_indicators} ? 1 : 0;
    $no_indicators = 1 if !$no_indicators && $self->_tmux_status_active;
    my $project = $self->{paths}->project_root_for($cwd);
    my $home = $self->{paths}->home;
    $cwd =~ s/^\Q$home\E/~/;
    $cwd = "Home: $home" if $cwd eq '~';

    my @indicator_parts = $no_indicators
      ? ()
      : $self->_indicator_parts(
          color   => $color,
          max_age => $max_age,
          mode    => $mode,
      );

    my $ticket = defined $ENV{WORKSPACE_REF} && $ENV{WORKSPACE_REF} ne ''
      ? $ENV{WORKSPACE_REF}
      : ( defined $ENV{TICKET_REF} ? $ENV{TICKET_REF} : '' );
    my @info_parts = @indicator_parts;
    push @info_parts, "🎫:$ticket" if defined $ticket && $ticket ne '';
    my $info = @info_parts ? join( ' ', @info_parts ) : '';
    my $branch = $self->_git_branch($project);
    my $jobs_suffix = $jobs ? " ($jobs jobs)" : '';
    my $branch_suffix = $branch ? " 🌿$branch" : '';

    return sprintf "(%s)%s [%s]%s%s\n> ",
      $self->_timestamp,
      ( $info ne '' ? " $info" : '' ),
      $cwd,
      $jobs_suffix,
      $branch_suffix;
}

# render_tmux_status(%args)
# Renders the tmux status-line indicator fragment without prompt-only details.
# Input: optional color flag, max-age threshold, requested line, and width.
# Output: one or two indicator-status lines joined by newlines when no explicit line is requested.
sub render_tmux_status {
    my ( $self, %args ) = @_;
    my $line = $args{line} || '';
    my ( $top, $bottom ) = $self->_tmux_status_lines(%args);
    return $top    if $line eq 'top';
    return $bottom if $line eq 'bottom';
    return join "\n", grep { defined $_ && $_ ne q{} } ( $top, $bottom );
}

# _timestamp()
# Renders the prompt timestamp in the older shell-helper format.
# Input: none.
# Output: local timestamp string as YYYY-MM-DD HH:MM:SS.
sub _timestamp {
    return strftime( '%Y-%m-%d %H:%M:%S', localtime );
}

# _indicator_parts(%args)
# Builds formatted indicator fragments for prompt and page-header rendering.
# Input: display mode, color flag, and max-age threshold.
# Output: list of formatted indicator strings.
sub _indicator_parts {
    my ( $self, %args ) = @_;
    my $mode = $args{mode} || 'compact';
    my $color = exists $args{color} ? $args{color} : 0;
    my $max_age = defined $args{max_age} ? $args{max_age} : 300;

    my @indicator_parts;
    for my $indicator ( $self->{indicators}->list_indicators ) {
        next if exists $indicator->{prompt_visible} && !$indicator->{prompt_visible};
        my $status_icon = $self->{indicators}->prompt_status_icon($indicator);
        my $icon = defined $indicator->{icon} ? $indicator->{icon} : '';
        my $label = defined $indicator->{label} ? $indicator->{label} : $indicator->{name};
        my $stale = $self->{indicators}->is_stale( $indicator, max_age => $max_age ) ? 1 : 0;
        my $part = $mode eq 'extended'
          ? join( '', grep { defined && $_ ne '' } $status_icon, $icon, $label )
          : join( '', grep { defined && $_ ne '' } $status_icon, ( $icon || substr( $label, 0, 1 ) ) );
        if ($color) {
            my $status = $indicator->{status} || '';
            my $ansi = $stale ? "\e[33m" : $status =~ /^(ok|clean)$/ ? "\e[32m" : $status =~ /^(missing|error|dirty|down)$/ ? "\e[31m" : "\e[36m";
            $part = $ansi . $part . "\e[0m";
        }
        push @indicator_parts, $part;
    }

    return @indicator_parts;
}

# _tmux_status_active()
# Determines whether the current shell should suppress inline prompt indicators
# because a dashboard-managed tmux ticket session owns the status area.
# Input: none.
# Output: boolean true when tmux status owns the indicator strip.
sub _tmux_status_active {
    return 0 if !defined $ENV{TMUX} || $ENV{TMUX} eq '';
    return 1
      if defined $ENV{DEVELOPER_DASHBOARD_TMUX_STATUS}
      && $ENV{DEVELOPER_DASHBOARD_TMUX_STATUS} ne ''
      && $ENV{DEVELOPER_DASHBOARD_TMUX_STATUS} ne '0';
    return 1 if defined $ENV{WORKSPACE_REF} && $ENV{WORKSPACE_REF} ne '';
    return 1 if defined $ENV{TICKET_REF} && $ENV{TICKET_REF} ne '';
    return 0;
}

# _tmux_status_lines(%args)
# Splits the tmux indicator strip into one or two lines based on the available
# tmux width so ticket sessions can keep the normal tmux session/window line
# below the dashboard-owned indicator area.
# Input: optional color flag, max-age threshold, and width in terminal cells.
# Output: two-element list containing the primary indicator line and optional
# overflow line.
sub _tmux_status_lines {
    my ( $self, %args ) = @_;
    my $color = exists $args{color} ? $args{color} : 0;
    my $max_age = defined $args{max_age} ? $args{max_age} : 300;
    my $width = defined $args{width} && $args{width} =~ /\A\d+\z/ ? $args{width} + 0 : 0;
    my @parts = $self->_indicator_parts(
        color   => $color,
        max_age => $max_age,
        mode    => 'compact',
    );
    my $timestamp = "🕒" . $self->_timestamp;
    @parts = ( @parts, $timestamp );
    return ( $timestamp, q{} ) if @parts == 1;

    my $top = q{};
    my @bottom_parts;
    for my $part (@parts) {
        my $candidate = $top eq q{} ? $part : "$top $part";
        if ( $width > 0 && $top ne q{} && length( _strip_ansi($candidate) ) > $width ) {
            push @bottom_parts, $part;
            next;
        }
        $top = $candidate;
    }

    my $bottom = join ' ', @bottom_parts;
    return ( $top, $bottom );
}

# _strip_ansi($text)
# Removes ANSI colour escapes before width calculations.
# Input: text string that may contain ANSI SGR codes.
# Output: plain text string with ANSI SGR sequences removed.
sub _strip_ansi {
    my ($text) = @_;
    $text = '' if !defined $text;
    $text =~ s/\e\[[0-9;]*m//g;
    return $text;
}

# _git_branch($project_root)
# Reads the current git branch for a project root directly from git metadata
# without shelling out, so prompt rendering stays cheap on slower systems.
# Input: project root directory path.
# Output: branch name string, detached HEAD short SHA, or undef when unavailable.
sub _git_branch {
    my ( $self, $project_root ) = @_;
    return if !$project_root || !-d $project_root;

    my $git_dir = $self->_git_metadata_dir($project_root) || return;
    my $head_file = File::Spec->catfile( $git_dir, 'HEAD' );
    return if !-f $head_file;

    open my $head_fh, '<', $head_file or return;
    my $head = <$head_fh>;
    close $head_fh;
    return if !defined $head;
    $head =~ s/\s+\z//;

    if ( $head =~ /^ref:\s+(.+)$/ ) {
        return basename($1);
    }

    return substr( $head, 0, 7 ) if $head =~ /\A[0-9a-f]{7,40}\z/i;
    return;
}

# _git_metadata_dir($project_root)
# Resolves the concrete git metadata directory for normal repos and worktrees.
# Input: project root directory path.
# Output: absolute git metadata directory path or undef when unavailable.
sub _git_metadata_dir {
    my ( $self, $project_root ) = @_;
    return if !defined $project_root || $project_root eq '';

    my $git_path = File::Spec->catfile( $project_root, '.git' );
    return $git_path if -d $git_path;
    return if !-f $git_path;

    open my $git_fh, '<', $git_path or return;
    my $line = <$git_fh>;
    close $git_fh;
    return if !defined $line;
    $line =~ s/\s+\z//;
    return if $line !~ /^gitdir:\s*(.+)$/;

    my $git_dir = $1;
    $git_dir = File::Spec->catdir( $project_root, $git_dir )
      if !File::Spec->file_name_is_absolute($git_dir);
    my $resolved = abs_path($git_dir);
    return $resolved if defined $resolved && -d $resolved;
    return if !-d $git_dir;
    return $git_dir;
}

1;

__END__

=head1 NAME

Developer::Dashboard::Prompt - prompt rendering for Developer Dashboard

=head1 SYNOPSIS

  my $prompt = Developer::Dashboard::Prompt->new(
      paths      => $paths,
      indicators => $indicators,
  );
  print $prompt->render(jobs => 1);

=head1 DESCRIPTION

This module renders the shell prompt from cached indicator state, current
directory context, and git metadata. It is designed to stay fast enough for
per-prompt execution.

=head1 METHODS

=head2 new

Construct a prompt renderer.

=head2 render

Return the full prompt string.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module renders the dashboard prompt fragment. It reads indicators, collector status, current cwd, job counts, and ticket context, then turns that state into the compact or extended prompt text used by shell bootstraps and prompt refresh commands.

=head1 WHY IT EXISTS

It exists because prompt rendering is a product feature with its own ordering and icon rules. Putting that logic in one module keeps bash, zsh, POSIX sh, and PowerShell prompt behavior aligned.

=head1 WHEN TO USE

Use this file when changing prompt shape, indicator ordering, icon/status rendering, compact versus extended prompt output, or the prompt command arguments exposed through C<dashboard ps1>.

=head1 HOW TO USE

Construct it with the active paths and state stores, then call the prompt-rendering method that matches the requested mode. Shell helper scripts should consume the rendered string rather than rebuilding prompt logic in shell code.

=head1 WHAT USES IT

It is used by the C<dashboard ps1> helper, by generated shell bootstrap functions, by integration smoke runs that verify prompt text, and by prompt-focused regression tests.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::Prompt -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/02-indicator-collector.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
