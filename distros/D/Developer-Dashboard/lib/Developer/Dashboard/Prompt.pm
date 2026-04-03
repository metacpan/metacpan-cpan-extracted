package Developer::Dashboard::Prompt;

use strict;
use warnings;

our $VERSION = '1.33';

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use File::Basename qw(basename);

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

    my @indicator_parts = $self->_indicator_parts(
        color   => $color,
        max_age => $max_age,
        mode    => $mode,
    );

    my $status = @indicator_parts ? join( ' ', @indicator_parts ) : '';
    my $project_label = $project ? basename($project) : '';
    my $branch = $self->_git_branch($project);
    my $jobs_suffix = $jobs ? " ($jobs jobs)" : '';
    my $context = '';
    if ( $project_label && $branch ) {
        $context = "$project_label:$branch";
    }
    elsif ($project_label) {
        $context = $project_label;
    }
    elsif ($branch) {
        $context = $branch;
    }
    my $project_suffix = $context ? " {$context}" : '';

    return sprintf "[%s]%s %s%s\n> ",
      scalar localtime,
      ( $status ne '' ? " $status" : '' ),
      $cwd,
      $jobs_suffix . $project_suffix;
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
# Reads the current git branch for a project root if available.
# Input: project root directory path.
# Output: branch name string or undef when unavailable.
sub _git_branch {
    my ( $self, $project_root ) = @_;
    return if !$project_root || !-d $project_root;

    my $old = cwd();
    chdir $project_root or return;
    my ( $stdout, undef, $exit_code ) = capture {
        system 'git', 'rev-parse', '--abbrev-ref', 'HEAD';
        return $? >> 8;
    };
    chdir $old or die "Unable to restore cwd to $old: $!";
    return if $exit_code != 0;
    $stdout =~ s/\s+$// if defined $stdout;
    return $stdout;
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

=cut
