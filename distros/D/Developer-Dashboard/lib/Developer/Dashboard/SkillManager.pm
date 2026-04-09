package Developer::Dashboard::SkillManager;

use strict;
use warnings;

our $VERSION = '2.02';

use Cwd qw(realpath);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Basename qw(basename);
use Capture::Tiny qw(capture);
use JSON::XS qw(decode_json encode_json);
use Developer::Dashboard::PathRegistry;

# new()
# Creates a SkillManager instance to handle skill installation, updates, uninstalls.
# Input: none.
# Output: SkillManager object.
sub new {
    my ( $class, %args ) = @_;
    my $paths = $args{paths}
      || Developer::Dashboard::PathRegistry->new(
        home            => ( $ENV{HOME} || (getpwuid($>))[7] || $ENV{USERPROFILE} || die 'Missing home directory' ),
        workspace_roots => [],
        project_roots   => [],
      );

    return bless {
        paths       => $paths,
        skills_root => $paths->skills_root,
    }, $class;
}

# install($git_url)
# Clones a Git repository as a skill into ~/.developer-dashboard/skills/<repo-name>/
# Input: Git URL (can be git@, https://, file:///, etc.)
# Output: hash ref with success status and repo name.
sub install {
    my ( $self, $git_url ) = @_;
    return { error => 'Missing Git URL' } if !$git_url;

    my $repo_name = _extract_repo_name($git_url);
    return { error => "Unable to extract repo name from $git_url" } if !$repo_name;

    my $skill_path = File::Spec->catdir( $self->{skills_root}, $repo_name );
    return { error => "Skill '$repo_name' already installed at $skill_path" } if -d $skill_path;

    $self->{paths}->ensure_dir( $self->{skills_root} );

    my ( $stdout, $stderr, $exit ) = capture {
        system( 'git', 'clone', $git_url, $skill_path );
    };
    if ( $exit != 0 ) {
        remove_tree($skill_path) if -d $skill_path;
        return { error => "Failed to clone $git_url: $stderr" };
    }

    $self->_prepare_skill_layout($skill_path);
    my $dependency = $self->_install_skill_dependencies($skill_path);
    return $dependency if $dependency->{error};

    return {
        success   => 1,
        repo_name => $repo_name,
        path      => $skill_path,
        message   => "Skill '$repo_name' installed successfully",
        metadata  => $self->_skill_metadata( $repo_name, $skill_path ),
    };
}

# uninstall($repo_name)
# Removes a skill completely from ~/.developer-dashboard/skills/<repo-name>/
# Input: skill repo name.
# Output: hash ref with success status.
sub uninstall {
    my ( $self, $repo_name ) = @_;
    
    return { error => 'Missing repo name' } if !$repo_name;
    
    my $skill_path = File::Spec->catdir( $self->{skills_root}, $repo_name );
    return { error => "Skill '$repo_name' not found" } if !-d $skill_path;
    my $real_root = realpath( $self->{skills_root} ) || $self->{skills_root};
    my $real_path = realpath($skill_path) || $skill_path;
    return { error => "Refusing to uninstall path outside skills root: $skill_path" }
      if index( $real_path, $real_root . '/' ) != 0;

    my $error;
    remove_tree( $skill_path, { error => \$error } );
    if ( @$error ) {
        return { error => "Failed to uninstall skill: " . join( ', ', @$error ) };
    }

    return {
        success   => 1,
        repo_name => $repo_name,
        message   => "Skill '$repo_name' uninstalled successfully",
    };
}

# update($repo_name)
# Pulls latest changes from the skill's Git repository.
# Input: skill repo name.
# Output: hash ref with success status.
sub update {
    my ( $self, $repo_name ) = @_;
    
    return { error => 'Missing repo name' } if !$repo_name;
    
    my $skill_path = File::Spec->catdir( $self->{skills_root}, $repo_name );
    return { error => "Skill '$repo_name' not found" } if !-d $skill_path;

    my ( $stdout, $stderr, $exit ) = capture {
        system( 'git', '-C', $skill_path, 'pull', '--ff-only' );
    };
    if ( $exit != 0 ) {
        return { error => "Failed to update skill: $stderr" };
    }

    $self->_prepare_skill_layout($skill_path);
    my $dependency = $self->_install_skill_dependencies($skill_path);
    return $dependency if $dependency->{error};

    return {
        success   => 1,
        repo_name => $repo_name,
        message   => "Skill '$repo_name' updated successfully",
        metadata  => $self->_skill_metadata( $repo_name, $skill_path ),
    };
}

# list()
# Lists all installed skills with metadata.
# Input: none.
# Output: array ref of skill metadata hashes.
sub list {
    my ($self) = @_;
    
    return [] if !-d $self->{skills_root};
    
    opendir( my $dh, $self->{skills_root} ) or return [];
    my @skills;
    
    for my $entry ( sort grep { $_ ne '.' && $_ ne '..' } readdir($dh) ) {
        my $skill_path = File::Spec->catdir( $self->{skills_root}, $entry );
        next unless -d $skill_path;
        
        push @skills, $self->_skill_metadata( $entry, $skill_path );
    }
    
    closedir($dh);
    return \@skills;
}

# get_skill_path($repo_name)
# Returns the full path to an installed skill.
# Input: skill repo name.
# Output: skill path string or undef.
sub get_skill_path {
    my ( $self, $repo_name ) = @_;
    
    return if !$repo_name;
    
    my $skill_path = File::Spec->catdir( $self->{skills_root}, $repo_name );
    return -d $skill_path ? $skill_path : undef;
}

# _extract_repo_name($git_url)
# Extracts repository name from various Git URL formats.
# Input: Git URL string.
# Output: repo name or undef.
sub _extract_repo_name {
    my ($url) = @_;
    
    return if !$url;
    
    # Extract from: git@github.com:user/repo-name.git
    if ( $url =~ m{/([^/]+?)(\.git)?$} ) {
        my $name = $1;
        return $name;
    }
    
    return;
}

# _prepare_skill_layout($skill_path)
# Ensures the isolated skill directory tree exists under one skill root.
# Input: absolute skill root directory path.
# Output: true value.
sub _prepare_skill_layout {
    my ( $self, $skill_path ) = @_;
    for my $dir (
        File::Spec->catdir( $skill_path, 'cli' ),
        File::Spec->catdir( $skill_path, 'config' ),
        File::Spec->catdir( $skill_path, 'config', 'docker' ),
        File::Spec->catdir( $skill_path, 'state' ),
        File::Spec->catdir( $skill_path, 'logs' ),
        File::Spec->catdir( $skill_path, 'local' ),
    ) {
        make_path($dir) if !-d $dir;
        $self->{paths}->secure_dir_permissions($dir);
    }

    my $config_file = File::Spec->catfile( $skill_path, 'config', 'config.json' );
    if ( !-f $config_file ) {
        open my $fh, '>', $config_file or die "Unable to write $config_file: $!";
        print {$fh} "{}\n";
        close $fh;
        $self->{paths}->secure_file_permissions($config_file);
    }
    return 1;
}

# _install_skill_dependencies($skill_path)
# Installs one skill's Perl dependencies into its isolated local library when a cpanfile exists.
# Input: absolute skill root directory path.
# Output: result hash reference with success or error state.
sub _install_skill_dependencies {
    my ( $self, $skill_path ) = @_;
    my $cpanfile = File::Spec->catfile( $skill_path, 'cpanfile' );
    return { success => 1, skipped => 1 } if !-f $cpanfile;

    my $local_root = File::Spec->catdir( $skill_path, 'local' );
    make_path($local_root) if !-d $local_root;
    $self->{paths}->secure_dir_permissions($local_root);

    my ( $stdout, $stderr, $exit ) = capture {
        system( 'cpanm', '-L', $local_root, '--installdeps', $skill_path );
    };
    return {
        error => "Failed to install skill dependencies for $skill_path: $stderr",
    } if $exit != 0;

    return {
        success => 1,
        stdout  => $stdout,
        stderr  => $stderr,
    };
}

# _skill_metadata($repo_name, $skill_path)
# Summarizes the isolated filesystem and command surface for one installed skill.
# Input: repo name string and absolute skill root directory path.
# Output: metadata hash reference.
sub _skill_metadata {
    my ( $self, $repo_name, $skill_path ) = @_;
    my $cli_root = File::Spec->catdir( $skill_path, 'cli' );
    my @commands;
    if ( -d $cli_root ) {
        opendir( my $dh, $cli_root ) or die "Unable to read $cli_root: $!";
        @commands = sort grep {
            $_ ne '.' && $_ ne '..'
              && -f File::Spec->catfile( $cli_root, $_ )
              && $_ !~ /\.d\z/
        } readdir($dh);
        closedir($dh);
    }

    my @docker_services;
    my $docker_root = File::Spec->catdir( $skill_path, 'config', 'docker' );
    if ( -d $docker_root ) {
        opendir( my $dh, $docker_root ) or die "Unable to read $docker_root: $!";
        @docker_services = sort grep {
            $_ ne '.' && $_ ne '..' && -d File::Spec->catdir( $docker_root, $_ )
        } readdir($dh);
        closedir($dh);
    }

    return {
        name            => $repo_name,
        path            => $skill_path,
        cli_commands    => \@commands,
        has_config      => -f File::Spec->catfile( $skill_path, 'config', 'config.json' ) ? 1 : 0,
        has_cpanfile    => -f File::Spec->catfile( $skill_path, 'cpanfile' ) ? 1 : 0,
        config_root     => File::Spec->catdir( $skill_path, 'config' ),
        docker_root     => $docker_root,
        docker_services => \@docker_services,
        state_root      => File::Spec->catdir( $skill_path, 'state' ),
        logs_root       => File::Spec->catdir( $skill_path, 'logs' ),
        cli_root        => $cli_root,
        local_root      => File::Spec->catdir( $skill_path, 'local' ),
    };
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::SkillManager - manage installed dashboard skills

=head1 SYNOPSIS

  use Developer::Dashboard::SkillManager;
  my $manager = Developer::Dashboard::SkillManager->new();
  
  my $result = $manager->install('git@github.com:user/skill-name.git');
  my $list = $manager->list();
  my $path = $manager->get_skill_path('skill-name');
  my $update_result = $manager->update('skill-name');
  my $uninstall_result = $manager->uninstall('skill-name');

=head1 DESCRIPTION

Manages the lifecycle of installed dashboard skills:
- Install: Clone Git repositories as skills
- Uninstall: Remove skills completely
- Update: Pull latest changes from skill repositories
- List: Show all installed skills
- Resolve: Find skill paths and metadata

Skills are isolated under ~/.developer-dashboard/skills/<repo-name>/

=for comment FULL-POD-DOC START

=head1 PURPOSE

Perl module in the Developer Dashboard codebase. This file installs, updates, and removes isolated skill runtimes.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::SkillManager> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::SkillManager -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
