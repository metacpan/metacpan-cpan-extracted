package Developer::Dashboard::Prompt;

use strict;
use warnings;
use utf8;

our $VERSION = '2.02';

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use File::Basename qw(basename);
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
    my $project = $self->{paths}->project_root_for($cwd);
    my $home = $self->{paths}->home;
    $cwd =~ s/^\Q$home\E/~/;
    $cwd = "Home: $home" if $cwd eq '~';

    my @indicator_parts = $self->_indicator_parts(
        color   => $color,
        max_age => $max_age,
        mode    => $mode,
    );

    my $ticket = defined $ENV{TICKET_REF} ? $ENV{TICKET_REF} : '';
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

# _git_branch($project_root)
# Reads the current git branch for a project root if available using the older
# `git branch` parsing style so the prompt matches the classic shell helper.
# Input: project root directory path.
# Output: branch name string or undef when unavailable.
sub _git_branch {
    my ( $self, $project_root ) = @_;
    return if !$project_root || !-d $project_root;

    my $old = cwd();
    chdir $project_root or return;
    my ( $stdout, undef, $exit_code ) = capture {
        system 'git', 'branch';
        return $? >> 8;
    };
    chdir $old or die "Unable to restore cwd to $old: $!";
    return if $exit_code != 0;
    return if !defined $stdout || $stdout eq '';
    for my $line ( split /\n/, $stdout ) {
        next if !defined $line;
        return $1 if $line =~ /^\*\s+(.+)$/;
    }
    return;
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

Perl module in the Developer Dashboard codebase. This file renders prompt output such as the shell prompt branch display.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::Prompt> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::Prompt -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
