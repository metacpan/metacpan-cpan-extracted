package Developer::Dashboard::SkillManager;

use strict;
use warnings;

our $VERSION = '3.14';

use Cwd qw(realpath);
use File::Copy qw(copy);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Basename qw(basename);
use File::Find qw(find);
use File::Temp qw(tempdir);
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
        paths    => $paths,
        progress => $args{progress},
    }, $class;
}

# install_progress_tasks()
# Returns the ordered task list shown for one dashboard skills install run.
# Input: none.
# Output: array reference of progress task hashes.
sub install_progress_tasks {
    return [
        { id => 'fetch_source',         label => 'Fetch skill source' },
        { id => 'prepare_layout',       label => 'Prepare skill layout' },
        { id => 'install_aptfile',      label => 'Install aptfile dependencies' },
        { id => 'install_apkfile',      label => 'Install apkfile dependencies' },
        { id => 'install_dnfile',       label => 'Install dnfile dependencies' },
        { id => 'install_brewfile',     label => 'Install brewfile dependencies' },
        { id => 'install_package_json', label => 'Install package.json dependencies' },
        { id => 'install_cpanfile',     label => 'Install cpanfile dependencies' },
        { id => 'install_cpanfile_local', label => 'Install cpanfile.local dependencies' },
        { id => 'install_ddfile',       label => 'Install ddfile dependencies' },
        { id => 'install_ddfile_local', label => 'Install ddfile.local dependencies' },
    ];
}

# install_progress_tasks_for_sources(@sources)
# Returns the ordered source-level task list shown for multi-skill install and
# bare update-all runs.
# Input: skill source strings in the order they will be installed.
# Output: array reference of progress task hashes.
sub install_progress_tasks_for_sources {
    my ( $class, @sources ) = @_;
    my @tasks;
    my $idx = 0;
    for my $source (@sources) {
        next if !defined $source || $source eq '';
        push @tasks, {
            id    => 'install_source_' . $idx,
            label => 'Install/update ' . $source,
        };
        $idx++;
    }
    return \@tasks;
}

# install($source)
# Installs or reinstalls a skill into the deepest participating DD-OOP-LAYERS
# skills root.
# Input: Git URL, shorthand GitHub skill name, owner/repo shorthand, or direct
# local checked-out repository path.
# Output: hash ref with success status and repo name.
sub install {
    my ( $self, $source ) = @_;
    return { error => 'Missing skill source' } if !$source;
    my $result = $self->_install_to_skills_root( $source, $self->{paths}->skills_root );
    return $result if $result->{error};
    my $gitignore_registration = $self->_register_home_gitignore_skill( $result->{repo_name} );
    return $gitignore_registration if $gitignore_registration->{error};
    $result->{registered_gitignore} = $gitignore_registration->{gitignore} if defined $gitignore_registration->{gitignore};
    $result->{registered_gitignore_entry} = $gitignore_registration->{registered}
      if exists $gitignore_registration->{registered};
    return $result if $ENV{DEVELOPER_DASHBOARD_SKIP_SKILL_REGISTRY};
    my $registration = $self->_register_root_ddfile_source($source);
    return $registration if $registration->{error};
    $result->{registered_ddfile} = $registration->{ddfile};
    $result->{registered_ddfile_entry} = $registration->{registered};
    return $result;
}

# install_many(@sources)
# Installs or reinstalls multiple explicit skill sources in the order supplied
# by the operator.
# Input: one or more Git URLs, shorthand GitHub names, owner/repo shorthands,
# or direct local checked-out repository paths.
# Output: hash ref with batch success status, original sources, and individual
# install results, or an error hash that includes completed results.
sub install_many {
    my ( $self, @sources ) = @_;
    @sources = grep { defined && $_ ne '' } @sources;
    return { error => 'Missing skill source' } if !@sources;

    my @results;
    my $idx = 0;
    for my $source (@sources) {
        my $task_id = 'install_source_' . $idx;
        $self->_progress_emit( { task_id => $task_id, status => 'running', label => "Install/update $source" } );
        my $result = $self->install($source);
        push @results, $result;
        if ( $result->{error} ) {
            $self->_progress_emit( { task_id => $task_id, status => 'failed', label => "Install/update $source" } );
            return {
                error   => "Failed to install skill source $source: $result->{error}",
                source  => $source,
                sources => \@sources,
                results => \@results,
            };
        }
        $self->_progress_emit( { task_id => $task_id, status => 'done', label => $self->_install_result_progress_label($source, $result) } );
        $idx++;
    }

    return {
        success => 1,
        sources => \@sources,
        results => \@results,
        message => @sources == 1 ? 'Installed skill successfully' : 'Installed skills successfully',
    };
}

# install_from_ddfiles($base_dir)
# Installs or reinstalls every skill source listed in ddfile and ddfile.local
# under one directory, processing ddfile first and ddfile.local second.
# Input: absolute or relative directory path that may contain ddfile manifests.
# Output: hash ref describing the completed manifest-driven install operations.
sub install_from_ddfiles {
    my ( $self, $base_dir ) = @_;
    $base_dir ||= '.';
    my $root = realpath($base_dir) || $base_dir;
    my $ddfile = File::Spec->catfile( $root, 'ddfile' );
    my $ddfile_local = File::Spec->catfile( $root, 'ddfile.local' );
    return { error => "No ddfile or ddfile.local found under $root" }
      if !-f $ddfile && !-f $ddfile_local;

    my @operations;

    my $global_result = $self->_install_manifest_file(
        $ddfile,
        manifest_name => 'ddfile',
        skills_root   => File::Spec->catdir( $self->{paths}->home_runtime_root, 'skills' ),
        operations    => \@operations,
    );
    return $global_result if $global_result->{error};

    my $local_result = $self->_install_manifest_file(
        $ddfile_local,
        manifest_name => 'ddfile.local',
        skills_root   => File::Spec->catdir( $root, 'skills' ),
        operations    => \@operations,
    );
    return $local_result if $local_result->{error};

    return {
        success    => 1,
        base_dir   => $root,
        operations => \@operations,
        message    => 'Installed skills from ddfile manifests successfully',
    };
}

# install_registered_skills()
# Reinstalls or updates every skill source listed in the home runtime ddfile.
# Input: none.
# Output: hash ref describing completed root-ddfile update operations or an
# error hash when the root registry is missing or empty.
sub install_registered_skills {
    my ($self) = @_;
    my $home_root = $self->{paths}->home_runtime_root;
    my $ddfile = File::Spec->catfile( $home_root, 'ddfile' );
    return { error => "No root ddfile found under $home_root; install a skill first or pass a skill source" }
      if !-f $ddfile;
    return { error => "Root ddfile $ddfile does not list any skills to install" }
      if !$self->_root_ddfile_has_sources($ddfile);

    my @operations;
    my $result = $self->_install_manifest_file(
        $ddfile,
        manifest_name => 'ddfile',
        skills_root   => File::Spec->catdir( $home_root, 'skills' ),
        operations    => \@operations,
        progress      => 1,
    );
    return $result if $result->{error};

    return {
        success    => 1,
        base_dir   => $home_root,
        ddfile     => $ddfile,
        operations => \@operations,
        message    => 'Installed registered skills from the home root ddfile successfully',
    };
}

# registered_skill_sources()
# Reads the home root ddfile and returns the installable skill sources it lists.
# Input: none.
# Output: list of non-comment source strings, or an empty list when absent.
sub registered_skill_sources {
    my ($self) = @_;
    my $ddfile = File::Spec->catfile( $self->{paths}->home_runtime_root, 'ddfile' );
    return () if !-f $ddfile;
    return $self->_dependency_file_lines($ddfile);
}

# uninstall($repo_name)
# Removes the effective layered skill instance completely from its active skills
# root.
# Input: skill repo name.
# Output: hash ref with success status.
sub uninstall {
    my ( $self, $repo_name ) = @_;
    
    return { error => 'Missing repo name' } if !$repo_name;
    
    my $skill_path = $self->get_skill_path( $repo_name, include_disabled => 1 );
    return { error => "Skill '$repo_name' not found" } if !defined $skill_path || !-d $skill_path;
    my $real_path = realpath($skill_path) || $skill_path;
    my $inside_layer = 0;
    for my $skills_root ( $self->{paths}->skills_roots ) {
        my $real_root = realpath($skills_root) || $skills_root;
        if ( index( $real_path, $real_root . '/' ) == 0 ) {
            $inside_layer = 1;
            last;
        }
    }
    return { error => "Refusing to uninstall path outside skills root: $skill_path" } if !$inside_layer;

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
    
    my $skill_path = $self->get_skill_path( $repo_name, include_disabled => 1 );
    return { error => "Skill '$repo_name' not found" } if !defined $skill_path || !-d $skill_path;

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

# enable($repo_name)
# Re-enables an installed skill by removing its disabled marker.
# Input: skill repo name.
# Output: hash ref with success status, enabled flag, and metadata.
sub enable {
    my ( $self, $repo_name ) = @_;
    return { error => 'Missing repo name' } if !$repo_name;

    my $skill_path = $self->get_skill_path( $repo_name, include_disabled => 1 );
    return { error => "Skill '$repo_name' not found" } if !$skill_path;

    my $marker = $self->_disabled_marker_path($skill_path);
    if ( -f $marker ) {
        unlink $marker or return { error => "Unable to remove disabled marker for skill '$repo_name': $!" };
    }

    return {
        success   => 1,
        repo_name => $repo_name,
        enabled   => JSON::XS::true(),
        message   => "Skill '$repo_name' enabled successfully",
        metadata  => $self->_skill_metadata( $repo_name, $skill_path ),
    };
}

# disable($repo_name)
# Disables an installed skill without uninstalling it.
# Input: skill repo name.
# Output: hash ref with success status, enabled flag, and metadata.
sub disable {
    my ( $self, $repo_name ) = @_;
    return { error => 'Missing repo name' } if !$repo_name;

    my $skill_path = $self->get_skill_path( $repo_name, include_disabled => 1 );
    return { error => "Skill '$repo_name' not found" } if !$skill_path;

    my $marker = $self->_disabled_marker_path($skill_path);
    open my $fh, '>', $marker or return { error => "Unable to write disabled marker for skill '$repo_name': $!" };
    print {$fh} "disabled\n";
    close $fh;
    $self->{paths}->secure_file_permissions($marker);

    return {
        success   => 1,
        repo_name => $repo_name,
        enabled   => JSON::XS::false(),
        message   => "Skill '$repo_name' disabled successfully",
        metadata  => $self->_skill_metadata( $repo_name, $skill_path ),
    };
}

# list()
# Lists all installed skills with metadata.
# Input: none.
# Output: array ref of skill metadata hashes.
sub list {
    my ($self) = @_;
    my @skills;

    for my $skill_path ( $self->{paths}->installed_skill_roots( include_disabled => 1 ) ) {
        my $entry = basename($skill_path);
        push @skills, $self->_skill_metadata( $entry, $skill_path );
    }

    return \@skills;
}

# get_skill_path($repo_name)
# Returns the full path to an installed skill.
# Input: skill repo name.
# Output: skill path string or undef.
sub get_skill_path {
    my ( $self, $repo_name, %args ) = @_;
    return if !$repo_name;

    for my $skill_path ( $self->{paths}->installed_skill_roots(%args) ) {
        next if basename($skill_path) ne $repo_name;
        return $skill_path;
    }
    return;
}

# is_enabled($repo_name)
# Reports whether an installed skill is enabled for runtime lookup.
# Input: skill repo name.
# Output: boolean true for enabled installed skills, false otherwise.
sub is_enabled {
    my ( $self, $repo_name ) = @_;
    return 0 if !$repo_name;
    my $skill_path = $self->get_skill_path( $repo_name, include_disabled => 1 ) or return 0;
    return $self->_skill_disabled($skill_path) ? 0 : 1;
}

# usage($repo_name)
# Returns detailed usage metadata for one installed skill even when disabled.
# Input: skill repo name.
# Output: hash ref with detailed skill metadata or an error hash.
sub usage {
    my ( $self, $repo_name ) = @_;
    return { error => 'Missing repo name' } if !$repo_name;
    my $skill_path = $self->get_skill_path( $repo_name, include_disabled => 1 );
    return { error => "Skill '$repo_name' not found" } if !$skill_path;
    return $self->_skill_usage( $repo_name, $skill_path );
}

# _extract_repo_name($source)
# Extracts repository name from various Git URL formats.
# Input: Git URL string or local directory path.
# Output: repo name or undef.
sub _extract_repo_name {
    my ($url) = @_;
    
    return if !$url;
    return basename($url) if -d $url;
    
    # Extract from: git@github.com:user/repo-name.git
    if ( $url =~ m{/([^/]+?)(\.git)?$} ) {
        my $name = $1;
        return $name;
    }
    
    return;
}

# _normalize_install_source($source)
# Expands shorthand remote skill names into full GitHub clone URLs while
# leaving local paths and explicit remote URLs unchanged.
# Input: install source string.
# Output: normalized install source string.
sub _normalize_install_source {
    my ( $self, $source ) = @_;
    return $source if !defined $source || $source eq '';
    return $source if -d $source;
    return $source if $source =~ m{\A[A-Za-z][A-Za-z0-9+.-]*://};
    return $source if $source =~ /\Agit@/;
    return "https://github.com/$source"
      if $source =~ /\A[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+(?:\.git)?\z/;
    return "https://github.com/manif3station/$source"
      if $source =~ /\A[A-Za-z0-9_.-]+\z/;
    return $source;
}

# _root_ddfile_has_sources($ddfile)
# Reports whether one root ddfile has at least one non-comment skill source.
# Input: root ddfile path.
# Output: boolean true when an installable source exists.
sub _root_ddfile_has_sources {
    my ( $self, $ddfile ) = @_;
    return scalar $self->_dependency_file_lines($ddfile) ? 1 : 0;
}

# _register_root_ddfile_source($source)
# Appends one explicit skill install source to the home root ddfile unless the
# same non-comment source is already present.
# Input: source string exactly as supplied to dashboard skills install.
# Output: hash ref with ddfile path and boolean registered status, or an error hash.
sub _register_root_ddfile_source {
    my ( $self, $source ) = @_;
    return { error => 'Missing skill source' } if !$source;

    my $home_root = $self->{paths}->home_runtime_root;
    $self->{paths}->ensure_dir($home_root);
    my $ddfile = File::Spec->catfile( $home_root, 'ddfile' );
    my $existing = '';
    if ( -f $ddfile ) {
        open my $read_fh, '<', $ddfile or return { error => "Unable to read root ddfile $ddfile: $!" };
        local $/;
        $existing = <$read_fh> // '';
        close $read_fh;
        for my $line ( split /\n/, $existing ) {
            $line =~ s/^\s+|\s+$//g;
            next if $line eq '' || $line =~ /\A#/;
            return {
                success    => 1,
                ddfile     => $ddfile,
                registered => 0,
            } if $line eq $source;
        }
    }

    open my $append_fh, '>>', $ddfile or return { error => "Unable to update root ddfile $ddfile: $!" };
    print {$append_fh} "\n" if length($existing) && $existing !~ /\n\z/;
    print {$append_fh} "$source\n";
    close $append_fh;
    $self->{paths}->secure_file_permissions($ddfile);

    return {
        success    => 1,
        ddfile     => $ddfile,
        registered => 1,
    };
}

# _register_home_gitignore_skill($repo_name)
# Adds one installed skill directory to the home runtime .gitignore when that
# ignore file already exists.
# Input: installed skill repository name.
# Output: hash ref describing the .gitignore path and whether a new entry was
# appended, or a success skip hash when no home .gitignore exists.
sub _register_home_gitignore_skill {
    my ( $self, $repo_name ) = @_;
    return { error => 'Missing repo name' } if !$repo_name;

    my $home_root = $self->{paths}->home_runtime_root;
    my @gitignore_candidates = (
        File::Spec->catfile( $home_root, '.gitignore' ),
        File::Spec->catfile( $home_root, '.gitiignore' ),
    );
    my ($gitignore) = grep { -f $_ } @gitignore_candidates;
    return { success => 1, skipped => 1 } if !$gitignore;

    my $entry = "skills/$repo_name/";
    my $existing = '';
    open my $read_fh, '<', $gitignore or return { error => "Unable to read home gitignore $gitignore: $!" };
    {
        local $/;
        $existing = <$read_fh> // '';
    }
    close $read_fh or return { error => "Unable to close home gitignore $gitignore: $!" };
    for my $line ( split /\n/, $existing ) {
        $line =~ s/^\s+|\s+$//g;
        next if $line eq '' || $line =~ /\A#/;
        return {
            success    => 1,
            gitignore  => $gitignore,
            registered => 0,
        } if $line eq $entry;
    }

    open my $append_fh, '>>', $gitignore or return { error => "Unable to update home gitignore $gitignore: $!" };
    print {$append_fh} "\n" if length($existing) && $existing !~ /\n\z/;
    print {$append_fh} "$entry\n";
    close $append_fh or return { error => "Unable to close home gitignore $gitignore: $!" };
    $self->{paths}->secure_file_permissions($gitignore);

    return {
        success    => 1,
        gitignore  => $gitignore,
        registered => 1,
    };
}

# _sync_local_skill_source($source_path, $target_path)
# Copies one validated local skill checkout into the isolated installed skill
# root, using rsync when available and a Perl tree copy otherwise.
# Input: absolute source path and absolute target path.
# Output: success hash ref or error hash ref.
sub _sync_local_skill_source {
    my ( $self, $source_path, $target_path ) = @_;
    return { error => 'Missing local skill source path' } if !$source_path;
    return { error => 'Missing local skill target path' } if !$target_path;

    if ( $self->_rsync_available ) {
        my ( $stdout, $stderr, $exit ) = capture {
            system( 'rsync', '-a', '--delete', $source_path . '/', $target_path );
        };
        return { success => 1 } if $exit == 0;
        return { error => "Failed to sync local skill source $source_path: $stderr" };
    }

    return $self->_copy_tree( $source_path, $target_path );
}

# _rsync_available()
# Reports whether the external rsync binary is available for local skill sync.
# Input: none.
# Output: boolean true when rsync can be executed from PATH, false otherwise.
sub _rsync_available {
    my ($self) = @_;
    return system( 'sh', '-c', 'command -v rsync >/dev/null 2>&1' ) == 0 ? 1 : 0;
}

# _copy_tree($source_path, $target_path)
# Recursively copies one source directory tree into a fresh target directory
# while preserving executable modes needed by installed skill commands.
# Input: absolute source path and absolute target path.
# Output: success hash ref or error hash ref.
sub _copy_tree {
    my ( $self, $source_path, $target_path ) = @_;
    eval {
        make_path($target_path);
        find(
            {
                no_chdir => 1,
                wanted   => sub {
                    my $path = $File::Find::name;
                    return if $path eq $source_path;
                    my $relative = File::Spec->abs2rel( $path, $source_path );
                    my $target = File::Spec->catfile( $target_path, $relative );
                    if ( -d $path ) {
                        make_path($target);
                        chmod( ( stat($path) )[2] & 07777, $target );
                        return;
                    }
                    copy( $path, $target ) or die "Unable to copy $path to $target: $!";
                    chmod( ( stat($path) )[2] & 07777, $target );
                },
            },
            $source_path,
        );
        1;
    } or do {
        my $error = $@ || 'Unknown local skill copy failure';
        return { error => "Failed to sync local skill source $source_path without rsync: $error" };
    };

    return { success => 1 };
}

# _clone_skill_source($clone_source, $target_path)
# Clones one remote skill checkout into the isolated installed skill root
# using git clone and explicit captured stdout and stderr for error reporting.
# Input: normalized remote clone source string and absolute target path.
# Output: success hash ref or error hash ref.
sub _clone_skill_source {
    my ( $self, $clone_source, $target_path ) = @_;
    return { error => 'Missing remote skill source' } if !$clone_source;
    return { error => 'Missing remote skill target path' } if !$target_path;

    my ( $stdout, $stderr, $exit ) = capture {
        system( 'git', 'clone', $clone_source, $target_path );
    };
    return { success => 1 } if $exit == 0;

    my $message = $stderr || $stdout || 'git clone failed without output';
    chomp $message;
    return { error => "Failed to clone $clone_source: $message" };
}

# _local_checked_out_source($source)
# Detects and validates one direct local checked-out skill repository path.
# Input: install source string.
# Output: normalized absolute source path string or undef when the source is
# not a direct local repository path.
sub _local_checked_out_source {
    my ( $self, $source ) = @_;
    return if !$source;
    return if $source =~ m{\A[A-Za-z][A-Za-z0-9+.-]*://};
    return if !-d $source;

    my $local_source = realpath($source) || $source;
    return { error => "Local skill source '$source' is missing a .git directory" }
      if !-d File::Spec->catdir( $local_source, '.git' );
    return { error => "Local skill source '$source' is missing a .env file with VERSION" }
      if !$self->_local_skill_has_version($local_source);
    return $local_source;
}

# _local_skill_has_version($skill_path)
# Checks whether one direct local checked-out skill source carries a
# qualification .env file with a VERSION assignment.
# Input: local skill source directory path.
# Output: boolean true when .env exists and contains VERSION=..., false
# otherwise.
sub _local_skill_has_version {
    my ( $self, $skill_path ) = @_;
    my $env_file = File::Spec->catfile( $skill_path, '.env' );
    return 0 if !-f $env_file;
    open my $fh, '<', $env_file or die "Unable to read $env_file: $!";
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content =~ /^VERSION\s*=\s*\S+/m ? 1 : 0;
}

# _remove_existing_skill_path($skill_path)
# Removes one previously installed skill path so install can act as reinstall.
# Input: absolute installed skill root path.
# Output: success hash reference.
sub _remove_existing_skill_path {
    my ( $self, $skill_path ) = @_;
    return { success => 1 } if !-e $skill_path;
    my $error;
    remove_tree( $skill_path, { error => \$error } );
    if ( @{$error} ) {
        return { error => "Failed to replace existing skill at $skill_path: " . join( ', ', @{$error} ) };
    }
    return { success => 1 };
}

# _install_to_skills_root($source, $skills_root)
# Installs one skill source into a specific skills root so manifest-driven
# installs can target either the active DD-OOP-LAYER or a nested local skills tree.
# Input: install source string and absolute target skills root directory path.
# Output: success hash ref including repo name, install path, and metadata, or an error hash.
sub _install_to_skills_root {
    my ( $self, $source, $skills_root ) = @_;
    return { error => 'Missing skill source' } if !$source;
    return { error => 'Missing skills root' } if !$skills_root;

    my $local_source = $self->_local_checked_out_source($source);
    return $local_source if ref($local_source) eq 'HASH';
    my $clone_source = $local_source ? $source : $self->_normalize_install_source($source);
    my $repo_name = $local_source ? basename($local_source) : _extract_repo_name($clone_source);
    return { error => "Unable to extract repo name from $source" } if !$repo_name;

    $self->{paths}->ensure_dir($skills_root);
    my $skill_path = File::Spec->catdir( $skills_root, $repo_name );
    my $version_before = $self->_skill_env_version($skill_path);
    my $remove = $self->_remove_existing_skill_path($skill_path);
    return $remove if $remove->{error};

    if ($local_source) {
        $self->_progress_emit(
            {
                task_id => 'fetch_source',
                status  => 'running',
                label   => "Fetch skill source from $local_source",
            }
        );
        my $sync = $self->_sync_local_skill_source( $local_source, $skill_path );
        if ( $sync->{error} ) {
            remove_tree($skill_path) if -d $skill_path;
            $self->_progress_emit( { task_id => 'fetch_source', status => 'failed' } );
            return $sync;
        }
        $self->_progress_emit(
            {
                task_id => 'fetch_source',
                status  => 'done',
                label   => "Fetch skill source from $local_source",
            }
        );
    }
    else {
        $self->_progress_emit(
            {
                task_id => 'fetch_source',
                status  => 'running',
                label   => "Fetch skill source from $clone_source",
            }
        );
        my $clone = $self->_clone_skill_source( $clone_source, $skill_path );
        if ( $clone->{error} ) {
            remove_tree($skill_path) if -d $skill_path;
            $self->_progress_emit( { task_id => 'fetch_source', status => 'failed' } );
            return $clone;
        }
        $self->_progress_emit(
            {
                task_id => 'fetch_source',
                status  => 'done',
                label   => "Fetch skill source from $clone_source",
            }
        );
    }

    $self->_progress_emit( { task_id => 'prepare_layout', status => 'running' } );
    $self->_prepare_skill_layout($skill_path);
    $self->_progress_emit( { task_id => 'prepare_layout', status => 'done' } );
    my $dependency = $self->_install_skill_dependencies($skill_path);
    return $dependency if $dependency->{error};
    my $version_after = $self->_skill_env_version($skill_path);
    my $install_status = $self->_install_version_status( $version_before, $version_after );

    return {
        success        => 1,
        source         => $source,
        repo_name      => $repo_name,
        path           => $skill_path,
        version_before => $version_before,
        version_after  => $version_after,
        status         => $install_status,
        changed        => $install_status eq 'updated' || $install_status eq 'installed' ? 1 : 0,
        message        => "Skill '$repo_name' installed successfully",
        metadata       => $self->_skill_metadata( $repo_name, $skill_path ),
    };
}

# _skill_env_version($skill_path)
# Reads VERSION from a skill .env file when it exists.
# Input: absolute skill root directory path.
# Output: version string or undef when no VERSION entry exists.
sub _skill_env_version {
    my ( $self, $skill_path ) = @_;
    my $env_file = File::Spec->catfile( $skill_path, '.env' );
    return undef if !-f $env_file;
    open my $fh, '<', $env_file or die "Unable to read $env_file: $!";
    while ( my $line = <$fh> ) {
        chomp $line;
        next if $line =~ /\A\s*(?:#|\z)/;
        if ( $line =~ /\A\s*VERSION\s*=\s*(.*?)\s*\z/ ) {
            my $version = $1;
            $version =~ s/\A['"]//;
            $version =~ s/['"]\z//;
            close $fh;
            return $version;
        }
    }
    close $fh;
    return undef;
}

# _install_version_status($before, $after)
# Classifies one install result from the before and after .env VERSION values.
# Input: optional version strings.
# Output: installed, updated, no update, or unknown.
sub _install_version_status {
    my ( $self, $before, $after ) = @_;
    return 'installed' if !defined $before && defined $after;
    return 'updated'   if defined $before && defined $after && $before ne $after;
    return 'no update' if defined $before && defined $after && $before eq $after;
    return 'unknown';
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
# Installs one skill's system and language dependencies in install order, with
# ddfile manifests deferred until last.
# Input: absolute skill root directory path.
# Output: result hash reference with success or error state.
sub _install_skill_dependencies {
    my ( $self, $skill_path ) = @_;
    my @steps = (
        [ install_aptfile      => sub { $self->_install_skill_aptfile($skill_path) } ],
        [ install_apkfile      => sub { $self->_install_skill_apkfile($skill_path) } ],
        [ install_dnfile       => sub { $self->_install_skill_dnfile($skill_path) } ],
        [ install_brewfile     => sub { $self->_install_skill_brewfile($skill_path) } ],
        [ install_package_json => sub { $self->_install_skill_package_json($skill_path) } ],
        [ install_cpanfile     => sub { $self->_install_skill_cpanfile($skill_path) } ],
        [ install_cpanfile_local => sub { $self->_install_skill_cpanfile_local($skill_path) } ],
        [ install_ddfile       => sub { $self->_install_skill_ddfile($skill_path) } ],
        [ install_ddfile_local => sub { $self->_install_skill_ddfile_local($skill_path) } ],
    );
    my @stdout;
    my @stderr;
    my $ran = 0;
    for my $step (@steps) {
        my ( $task_id, $runner ) = @{$step};
        my $running_label = $self->_dependency_progress_label( $task_id, $skill_path );
        $self->_progress_emit( { task_id => $task_id, status => 'running', label => $running_label } );
        my $result = $runner->();
        if ( $result->{error} ) {
            $self->_progress_emit(
                {
                    task_id => $task_id,
                    status  => 'failed',
                    label   => $self->_dependency_progress_label( $task_id, $skill_path, result => $result ),
                }
            );
            return $result;
        }
        $self->_progress_emit(
            {
                task_id => $task_id,
                status  => 'done',
                label   => $self->_dependency_progress_label( $task_id, $skill_path, result => $result ),
            }
        );
        $ran ||= !$result->{skipped};
        push @stdout, $result->{stdout} if defined $result->{stdout} && $result->{stdout} ne '';
        push @stderr, $result->{stderr} if defined $result->{stderr} && $result->{stderr} ne '';
    }

    return { success => 1, skipped => 1 } if !$ran;
    return {
        success => 1,
        stdout  => join( '', @stdout ),
        stderr  => join( '', @stderr ),
    };
}

# _dependency_progress_label($task_id, $skill_path, %args)
# Returns one operator-facing progress label for a dependency install task so
# large skill installs show which manifest was detected or skipped.
# Input: task id string, absolute skill root path, and optional result hash
# reference.
# Output: human-readable progress label string.
sub _dependency_progress_label {
    my ( $self, $task_id, $skill_path, %args ) = @_;
    my %files = (
        install_ddfile         => 'ddfile',
        install_ddfile_local   => 'ddfile.local',
        install_aptfile        => 'aptfile',
        install_apkfile        => 'apkfile',
        install_dnfile         => 'dnfile',
        install_brewfile       => 'brewfile',
        install_package_json   => 'package.json',
        install_cpanfile       => 'cpanfile',
        install_cpanfile_local => 'cpanfile.local',
    );
    my %labels = (
        install_ddfile         => 'Install ddfile dependencies',
        install_ddfile_local   => 'Install ddfile.local dependencies',
        install_aptfile        => 'Install aptfile dependencies',
        install_apkfile        => 'Install apkfile dependencies',
        install_dnfile         => 'Install dnfile dependencies',
        install_brewfile       => 'Install brewfile dependencies',
        install_package_json   => 'Install package.json dependencies',
        install_cpanfile       => 'Install cpanfile dependencies',
        install_cpanfile_local => 'Install cpanfile.local dependencies',
    );
    my $label = $labels{$task_id} || $task_id;
    my $file  = $files{$task_id} || return $label;
    my $path  = File::Spec->catfile( $skill_path, $file );
    my $result = $args{result};

    if ( ref($result) eq 'HASH' && $result->{skipped} ) {
        return "$label (skipped: $result->{skip_reason})"
          if defined $result->{skip_reason} && $result->{skip_reason} ne '';
        return "$label (skipped: $file not present)";
    }
    if ( ref($result) eq 'HASH' && defined $result->{error} && $result->{error} ne '' ) {
        my $error = $self->_progress_error_text( $result->{error} );
        return "$label from $path (error: $error)" if -f $path;
        return "$label (error: $error)";
    }
    return "$label from $path" if -f $path;
    return $label;
}

# _progress_error_text($error)
# Compacts one install error into a single visible task-board line.
# Input: raw error string from one dependency or source install step.
# Output: single-line error summary string.
sub _progress_error_text {
    my ( $self, $error ) = @_;
    return 'unknown failure' if !defined $error || $error eq '';
    $error =~ s/\s+/ /g;
    $error =~ s/\A\s+//;
    $error =~ s/\s+\z//;
    return $error;
}

# _progress_emit($event)
# Sends one skill-install progress event to the optional progress callback.
# Input: event hash reference.
# Output: true value.
sub _progress_emit {
    my ( $self, $event ) = @_;
    my $progress = $self->{progress};
    return 1 if !$progress || ref($progress) ne 'CODE';
    $progress->($event);
    return 1;
}

# _skill_install_root($skill_path)
# Returns the owning skills root directory for one installed skill.
# Input: absolute installed skill root directory path.
# Output: absolute parent skills root directory path.
sub _skill_install_root {
    my ( $self, $skill_path ) = @_;
    my ( undef, $dir ) = File::Spec->splitpath($skill_path);
    $dir =~ s{[\\/]\z}{};
    return $dir;
}

# _skill_apt_packages($skill_path)
# Reads one skill aptfile into a trimmed package list, ignoring blank lines and comments.
# Input: absolute skill root directory path.
# Output: ordered list of apt package name strings.
sub _skill_apt_packages {
    my ( $self, $skill_path ) = @_;
    my $aptfile = File::Spec->catfile( $skill_path, 'aptfile' );
    return () if !-f $aptfile;
    open my $fh, '<', $aptfile or die "Unable to read $aptfile: $!";
    my @packages;
    while ( my $line = <$fh> ) {
        chomp $line;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        next if $line eq '';
        next if $line =~ /^#/;
        push @packages, $line;
    }
    close $fh;
    return @packages;
}

# _packages_missing($is_installed, @packages)
# Filters one ordered package list down to packages that are not installed yet.
# Input: code reference that receives one package name and returns an installed
# boolean, followed by ordered package names.
# Output: ordered list of package names that still need installation.
sub _packages_missing {
    my ( $self, $is_installed, @packages ) = @_;
    my @missing;
    for my $package (@packages) {
        push @missing, $package if !$is_installed->($package);
    }
    return @missing;
}

# _dependency_file_lines($file)
# Reads one dependency manifest into a trimmed ordered entry list.
# Input: absolute dependency file path.
# Output: ordered list of non-empty non-comment entry strings.
sub _dependency_file_lines {
    my ( $self, $file ) = @_;
    return () if !defined $file || !-f $file;
    open my $fh, '<', $file or die "Unable to read $file: $!";
    my @entries;
    while ( my $line = <$fh> ) {
        chomp $line;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        next if $line eq '';
        next if $line =~ /^#/;
        push @entries, $line;
    }
    close $fh;
    return @entries;
}

# _current_os()
# Resolves the active operating system for dependency policy checks.
# Input: none.
# Output: short operating system string such as linux or darwin.
sub _current_os {
    return $ENV{DD_TEST_OS} || $^O;
}

# _is_debian_like()
# Detects whether aptfile processing should run on the current host.
# Input: none.
# Output: boolean true when the host is Debian-like.
sub _is_debian_like {
    my ($self) = @_;
    return 1 if $ENV{DD_TEST_DEBIAN_LIKE};
    return 0 if $self->_is_alpine;
    return 0 if $self->_current_os ne 'linux';
    return -f '/etc/debian_version' ? 1 : 0;
}

# _is_alpine()
# Detects whether apkfile processing should run on the current host.
# Input: none.
# Output: boolean true when the host is Alpine Linux.
sub _is_alpine {
    my ($self) = @_;
    return 1 if $ENV{DD_TEST_ALPINE};
    return 0 if $self->_current_os ne 'linux';
    return -f '/etc/alpine-release' ? 1 : 0;
}

# _is_fedora()
# Detects whether dnfile processing should run on the current host.
# Input: none.
# Output: boolean true when the host is Fedora Linux.
sub _is_fedora {
    my ($self) = @_;
    return 1 if $ENV{DD_TEST_FEDORA};
    return 0 if $self->_current_os ne 'linux';
    return -f '/etc/fedora-release' ? 1 : 0;
}

# _apt_package_is_installed($package)
# Checks whether one Debian-family package is already installed.
# Input: package name string from one skill aptfile.
# Output: boolean true when the package is already installed.
sub _apt_package_is_installed {
    my ( $self, $package ) = @_;
    my ( $stdout, undef, $exit ) = capture {
        system( 'dpkg-query', '-W', '--showformat=${Status}', '--', $package );
    };
    return 0 if $exit != 0;
    return $stdout =~ /install ok installed/ ? 1 : 0;
}

# _apk_package_is_installed($package)
# Checks whether one Alpine package is already installed.
# Input: package name string from one skill apkfile.
# Output: boolean true when the package is already installed.
sub _apk_package_is_installed {
    my ( $self, $package ) = @_;
    my ( undef, undef, $exit ) = capture {
        system( 'apk', 'info', '-e', $package );
    };
    return $exit == 0 ? 1 : 0;
}

# _dnf_package_is_installed($package)
# Checks whether one Fedora package is already installed.
# Input: package name string from one skill dnfile.
# Output: boolean true when the package is already installed.
sub _dnf_package_is_installed {
    my ( $self, $package ) = @_;
    my ( undef, undef, $exit ) = capture {
        system( 'rpm', '-q', '--quiet', $package );
    };
    return $exit == 0 ? 1 : 0;
}

# _shared_perl_root()
# Returns the shared Perl dependency install root used by skills.
# Input: none.
# Output: absolute directory path string.
sub _shared_perl_root {
    my ($self) = @_;
    return File::Spec->catdir( $self->{paths}->home, 'perl5' );
}

# _skill_local_perl_root($skill_path)
# Returns the skill-local Perl dependency install root for cpanfile.local.
# Input: absolute skill root directory path.
# Output: absolute directory path string.
sub _skill_local_perl_root {
    my ( $self, $skill_path ) = @_;
    return File::Spec->catdir( $skill_path, 'perl5' );
}

# _ensure_perl_root($root)
# Creates and secures one Perl dependency install root.
# Input: absolute target directory path.
# Output: same absolute target directory path.
sub _ensure_perl_root {
    my ( $self, $root ) = @_;
    make_path($root) if !-d $root;
    $self->{paths}->secure_dir_permissions($root);
    return $root;
}

# _install_skill_ddfile($skill_path)
# Installs dependent skills listed in ddfile while skipping already-installed
# or in-flight dependencies to avoid recursion loops.
# Input: absolute skill root directory path.
# Output: result hash reference with success or error state.
sub _install_skill_ddfile {
    my ( $self, $skill_path ) = @_;
    return $self->_install_skill_dependency_manifest( $skill_path, 'ddfile' );
}

# _install_skill_ddfile_local($skill_path)
# Installs dependent skills listed in ddfile.local into the same skills root as
# the current installed skill.
# Input: absolute skill root directory path.
# Output: result hash reference with success or error state.
sub _install_skill_ddfile_local {
    my ( $self, $skill_path ) = @_;
    return $self->_install_skill_dependency_manifest( $skill_path, 'ddfile.local' );
}

# _install_skill_dependency_manifest($skill_path, $manifest_name)
# Installs dependent skills listed in one manifest while keeping every
# dependency at the current installed skill level.
# Input: absolute skill root directory path and manifest filename.
# Output: result hash reference with success or error state.
sub _install_skill_dependency_manifest {
    my ( $self, $skill_path, $manifest_name ) = @_;
    my $manifest = File::Spec->catfile( $skill_path, $manifest_name );
    my @skills = $self->_dependency_file_lines($manifest);
    return { success => 1, skipped => 1 } if !@skills;

    my $skills_root = $self->_skill_install_root($skill_path);
    my %seen = map { $_ => 1 } grep { defined && $_ ne '' } split /:/, ( $ENV{DEVELOPER_DASHBOARD_INSTALL_STACK} || '' );
    my $repo_name = basename($skill_path);
    $seen{$repo_name} = 1 if defined $repo_name && $repo_name ne '';

    my @stdout;
    my @stderr;
    for my $dependency (@skills) {
        next if $seen{$dependency};
        next if $self->get_skill_path( $dependency, include_disabled => 1 );
        my $install_stack = join ':', grep { defined && $_ ne '' } sort keys %{{ %seen, $dependency => 1 }};
        my ( $step_stdout, $step_stderr, $exit ) = do {
            local $ENV{DEVELOPER_DASHBOARD_INSTALL_STACK} = $install_stack;
            local $ENV{DEVELOPER_DASHBOARD_DEPENDENCY_MANIFEST} = $manifest_name;
            local $ENV{DEVELOPER_DASHBOARD_SKIP_SKILL_REGISTRY} = 1;
            my $cwd = Cwd::getcwd();
            my ( $stdout, $stderr, $status );
            eval {
                chdir $skills_root or die "Unable to chdir to $skills_root for $manifest_name dependency install: $!";
                ( $stdout, $stderr, $status ) = capture {
                    system( 'dashboard', 'skills', 'install', $dependency );
                };
                chdir $cwd or die "Unable to chdir back to $cwd after $manifest_name dependency install: $!";
                1;
            };
            my $eval_error = $@;
            if ($eval_error) {
                chdir $cwd if Cwd::getcwd() ne $cwd;
                die $eval_error;
            }
            ( $stdout, $stderr, $status );
        };
        return {
            error => "Failed to install dependent skills for $skill_path via $manifest_name: $step_stderr",
        } if $exit != 0;
        push @stdout, $step_stdout if defined $step_stdout && $step_stdout ne '';
        push @stderr, $step_stderr if defined $step_stderr && $step_stderr ne '';
    }

    return { success => 1, skipped => 1 } if !@stdout && !@stderr;
    return {
        success => 1,
        stdout  => join( '', @stdout ),
        stderr  => join( '', @stderr ),
    };
}

# _install_skill_package_json($skill_path)
# Installs Node dependencies declared by package.json into the dashboard home
# node_modules directory by running npx-wrapped npm inside a private staging
# workspace and then merging the resulting dependency tree into HOME/node_modules.
# Input: absolute skill root directory path.
# Output: result hash reference with success or error state.
sub _install_skill_package_json {
    my ( $self, $skill_path ) = @_;
    my $package_json = File::Spec->catfile( $skill_path, 'package.json' );
    return { success => 1, skipped => 1 } if !-f $package_json;
    my @specs = $self->_package_json_dependency_specs($package_json);
    return { success => 1, skipped => 1 } if !@specs;

    die "Unable to chdir to " . $self->{paths}->home . " for package.json dependency install: No such file or directory\n"
      if !-d $self->{paths}->home;
    my $workspace_parent = File::Spec->catdir( $self->{paths}->home_runtime_root, 'cache', 'node-package-installs' );
    my $target_root = File::Spec->catdir( $self->{paths}->home, 'node_modules' );
    make_path($workspace_parent) if !-d $workspace_parent;
    make_path($target_root) if !-d $target_root;
    my $workspace = tempdir( 'npm-install-XXXXXX', DIR => $workspace_parent, CLEANUP => 1 );
    my $workspace_package_json = File::Spec->catfile( $workspace, 'package.json' );
    open my $workspace_fh, '>', $workspace_package_json or die "Unable to write $workspace_package_json: $!";
    print {$workspace_fh} encode_json(
        {
            name    => 'developer-dashboard-skill-runtime',
            version => '1.0.0',
            private => JSON::XS::true(),
        }
    );
    close $workspace_fh;

    my $cwd = Cwd::getcwd();
    my ( $npm_stdout, $npm_stderr, $npm_exit );
    eval {
        chdir $workspace or die "Unable to chdir to $workspace for package.json dependency install: $!";
        ( $npm_stdout, $npm_stderr, $npm_exit ) = capture {
            system( 'npx', '--yes', 'npm', 'install', @specs );
        };
        chdir $cwd or die "Unable to chdir back to $cwd after package.json dependency install: $!";
        1;
    } or do {
        my $error = $@;
        chdir $cwd if Cwd::getcwd() ne $cwd;
        die $error;
    };
    return {
        error => "Failed to install skill Node dependencies for $skill_path: $npm_stderr",
    } if $npm_exit != 0;

    my $workspace_modules = File::Spec->catdir( $workspace, 'node_modules' );
    my ( $copy_stdout, $copy_stderr, $copy_exit ) = ( '', '', 0 );
    if ( -d $workspace_modules ) {
        ( $copy_stdout, $copy_stderr, $copy_exit ) = capture {
            system( 'cp', '-R', "$workspace_modules/.", $target_root );
        };
        return {
            error => "Failed to merge skill Node dependencies into $target_root for $skill_path: $copy_stderr",
        } if $copy_exit != 0;
    }

    return {
        success => 1,
        stdout  => $npm_stdout . $copy_stdout,
        stderr  => $npm_stderr . $copy_stderr,
    };
}

# _package_json_dependency_specs($package_json)
# Extracts one deterministic dependency install list from package.json without
# asking npm to treat the skill checkout itself as an installable package.
# Input: absolute package.json path.
# Output: ordered list of npm install spec strings.
sub _package_json_dependency_specs {
    my ( $self, $package_json ) = @_;
    return () if !defined $package_json || !-f $package_json;

    open my $fh, '<', $package_json or die "Unable to read $package_json: $!";
    local $/;
    my $content = <$fh>;
    close $fh;

    my $decoded = eval { decode_json($content) };
    die "Unable to parse $package_json: $@" if !$decoded || $@;

    my @specs;
    for my $section ( qw(dependencies devDependencies optionalDependencies peerDependencies) ) {
        my $entries = $decoded->{$section};
        next if ref($entries) ne 'HASH';
        for my $name ( sort keys %{$entries} ) {
            my $version = $entries->{$name};
            push @specs, defined $version && $version ne '' ? "$name\@$version" : $name;
        }
    }

    return @specs;
}

# _install_manifest_file($manifest_path, %args)
# Installs every source listed in one explicit ddfile-style manifest into the
# requested skills root without skipping already-installed targets.
# Input: manifest file path plus manifest_name, skills_root, and operations array reference.
# Output: success hash ref when the manifest is absent or completes, or an error hash.
sub _install_manifest_file {
    my ( $self, $manifest_path, %args ) = @_;
    return { success => 1, skipped => 1 } if !defined $manifest_path || !-f $manifest_path;
    my $manifest_name = $args{manifest_name} || basename($manifest_path);
    my $skills_root = $args{skills_root} || return { error => "Missing skills root for $manifest_name" };
    my $operations = $args{operations};
    my @sources = $self->_dependency_file_lines($manifest_path);
    return { success => 1, skipped => 1 } if !@sources;

    my $idx = 0;
    for my $source (@sources) {
        my $task_id = 'install_source_' . $idx;
        $self->_progress_emit( { task_id => $task_id, status => 'running', label => "Install/update $source" } )
          if $args{progress};
        my $result = $self->_install_to_skills_root( $source, $skills_root );
        if ( $result->{error} ) {
            $self->_progress_emit( { task_id => $task_id, status => 'failed', label => "Install/update $source" } )
              if $args{progress};
            return $result;
        }
        push @{$operations}, {
            manifest       => $manifest_name,
            source         => $source,
            repo_name      => $result->{repo_name},
            path           => $result->{path},
            version_before => $result->{version_before},
            version_after  => $result->{version_after},
            status         => $result->{status},
            changed        => $result->{changed},
        } if ref($operations) eq 'ARRAY';
        $self->_progress_emit( { task_id => $task_id, status => 'done', label => $self->_install_result_progress_label($source, $result) } )
          if $args{progress};
        $idx++;
    }

    return { success => 1 };
}

# _install_result_progress_label($source, $result)
# Builds a concise source-level completion label for an install result.
# Input: source string and install result hash reference.
# Output: operator-facing progress label with status and version transition.
sub _install_result_progress_label {
    my ( $self, $source, $result ) = @_;
    my $repo = ref($result) eq 'HASH' && $result->{repo_name} ? $result->{repo_name} : $source;
    my $status = ref($result) eq 'HASH' && $result->{status} ? $result->{status} : 'done';
    my $before = ref($result) eq 'HASH' && defined $result->{version_before} ? $result->{version_before} : '-';
    my $after  = ref($result) eq 'HASH' && defined $result->{version_after}  ? $result->{version_after}  : '-';
    return "$repo $status ($before -> $after)";
}

# _install_skill_aptfile($skill_path)
# Installs aptfile packages on Debian-like hosts after printing the requested
# package list.
# Input: absolute skill root directory path.
# Output: result hash reference with success or error state.
sub _install_skill_aptfile {
    my ( $self, $skill_path ) = @_;
    my @apt_packages = $self->_skill_apt_packages($skill_path);
    return { success => 1, skipped => 1 } if !@apt_packages || !$self->_is_debian_like;
    my @missing_packages = $self->_packages_missing(
        sub { $self->_apt_package_is_installed( $_[0] ) },
        @apt_packages
    );
    return {
        success     => 1,
        skipped     => 1,
        skip_reason => 'all aptfile packages already installed',
    } if !@missing_packages;

    my $aptfile = File::Spec->catfile( $skill_path, 'aptfile' );
    my @runner_prefix = $self->_skill_package_runner_prefix;
    my ( $stdout, $stderr, $exit ) = capture {
        print "Installing apt packages for ", basename($skill_path), " from $aptfile: ", join( ' ', @missing_packages ), "\n";
        system( @runner_prefix, 'apt-get', 'install', '-y', @missing_packages );
    };
    return {
        error => "Failed to install skill apt dependencies for $skill_path: $stderr",
    } if $exit != 0;

    return {
        success => 1,
        stdout  => $stdout,
        stderr  => $stderr,
    };
}

# _install_skill_apkfile($skill_path)
# Installs apkfile packages on Alpine hosts after printing the requested
# package list.
# Input: absolute skill root directory path.
# Output: result hash reference with success or error state.
sub _install_skill_apkfile {
    my ( $self, $skill_path ) = @_;
    my $apkfile = File::Spec->catfile( $skill_path, 'apkfile' );
    my @packages = $self->_dependency_file_lines($apkfile);
    return { success => 1, skipped => 1 } if !@packages || !$self->_is_alpine;
    my @missing_packages = $self->_packages_missing(
        sub { $self->_apk_package_is_installed( $_[0] ) },
        @packages
    );
    return {
        success     => 1,
        skipped     => 1,
        skip_reason => 'all apkfile packages already installed',
    } if !@missing_packages;

    my @runner_prefix = $self->_skill_package_runner_prefix;
    my ( $stdout, $stderr, $exit ) = capture {
        print "Installing apk packages for ", basename($skill_path), " from $apkfile: ", join( ' ', @missing_packages ), "\n";
        system( @runner_prefix, 'apk', 'add', '--no-cache', @missing_packages );
    };
    return {
        error => "Failed to install skill apk dependencies for $skill_path: $stderr",
    } if $exit != 0;

    return {
        success => 1,
        stdout  => $stdout,
        stderr  => $stderr,
    };
}

# _install_skill_dnfile($skill_path)
# Installs dnfile packages on Fedora hosts after printing the requested
# package list.
# Input: absolute skill root directory path.
# Output: result hash reference with success or error state.
sub _install_skill_dnfile {
    my ( $self, $skill_path ) = @_;
    my $dnfile = File::Spec->catfile( $skill_path, 'dnfile' );
    my @packages = $self->_dependency_file_lines($dnfile);
    return { success => 1, skipped => 1 } if !@packages || !$self->_is_fedora;
    my @missing_packages = $self->_packages_missing(
        sub { $self->_dnf_package_is_installed( $_[0] ) },
        @packages
    );
    return {
        success     => 1,
        skipped     => 1,
        skip_reason => 'all dnfile packages already installed',
    } if !@missing_packages;

    my @runner_prefix = $self->_skill_package_runner_prefix;
    my ( $stdout, $stderr, $exit ) = capture {
        print "Installing dnf packages for ", basename($skill_path), " from $dnfile: ", join( ' ', @missing_packages ), "\n";
        system( @runner_prefix, 'dnf', 'install', '-y', @missing_packages );
    };
    return {
        error => "Failed to install skill dnf dependencies for $skill_path: $stderr",
    } if $exit != 0;

    return {
        success => 1,
        stdout  => $stdout,
        stderr  => $stderr,
    };
}

# _skill_package_runner_prefix()
# Returns the command prefix used for privileged package-manager installs.
# Input: none.
# Output: list containing 'sudo' for non-root users, or an empty list for root.
sub _skill_package_runner_prefix {
    my ($self) = @_;
    return () if ( $> || 0 ) == 0;
    return ('sudo');
}

# _install_skill_brewfile($skill_path)
# Installs brewfile packages on macOS after printing the requested package list.
# Input: absolute skill root directory path.
# Output: result hash reference with success or error state.
sub _install_skill_brewfile {
    my ( $self, $skill_path ) = @_;
    my $brewfile = File::Spec->catfile( $skill_path, 'brewfile' );
    my @packages = $self->_dependency_file_lines($brewfile);
    return { success => 1, skipped => 1 } if !@packages || $self->_current_os ne 'darwin';

    my ( $stdout, $stderr, $exit ) = capture {
        print "Installing brew packages for ", basename($skill_path), " from $brewfile: ", join( ' ', @packages ), "\n";
        system( 'brew', 'install', @packages );
    };
    return {
        error => "Failed to install skill brew dependencies for $skill_path: $stderr",
    } if $exit != 0;

    return {
        success => 1,
        stdout  => $stdout,
        stderr  => $stderr,
    };
}

# _install_skill_cpanfile($skill_path)
# Installs shared Perl dependencies from cpanfile into HOME perl5.
# Input: absolute skill root directory path.
# Output: result hash reference with success or error state.
sub _install_skill_cpanfile {
    my ( $self, $skill_path ) = @_;
    my $cpanfile = File::Spec->catfile( $skill_path, 'cpanfile' );
    return { success => 1, skipped => 1 } if !-f $cpanfile;
    my $shared_root = $self->_ensure_perl_root( $self->_shared_perl_root );
    my ( $stdout, $stderr, $exit ) = capture {
        system( 'cpanm', '--notest', '-L', $shared_root, '--cpanfile', $cpanfile, '--installdeps', $skill_path );
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

# _install_skill_cpanfile_local($skill_path)
# Installs skill-local Perl dependencies from cpanfile.local into ./perl5.
# Input: absolute skill root directory path.
# Output: result hash reference with success or error state.
sub _install_skill_cpanfile_local {
    my ( $self, $skill_path ) = @_;
    my $cpanfile_local = File::Spec->catfile( $skill_path, 'cpanfile.local' );
    return { success => 1, skipped => 1 } if !-f $cpanfile_local;
    my $local_root = $self->_ensure_perl_root( $self->_skill_local_perl_root($skill_path) );
    my ( $stdout, $stderr, $exit ) = capture {
        system( 'cpanm', '--notest', '-L', $local_root, '--cpanfile', $cpanfile_local, '--installdeps', $skill_path );
    };
    return {
        error => "Failed to install skill local dependencies for $skill_path: $stderr",
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
    my @commands = map { $_->{name} } @{ $self->_cli_command_details($skill_path) };

    my $docker_root = File::Spec->catdir( $skill_path, 'config', 'docker' );
    my @docker_services = map { $_->{name} } @{ $self->_docker_service_details($skill_path) };
    my $pages = $self->_page_details($skill_path);
    my $collectors = $self->_collector_details( $repo_name, $skill_path );
    my $indicators_count = 0;
    for my $collector ( @{$collectors} ) {
        $indicators_count++ if $collector->{has_indicator};
    }
    my $enabled = $self->_skill_disabled($skill_path) ? JSON::XS::false() : JSON::XS::true();
    my $has_ddfile = -f File::Spec->catfile( $skill_path, 'ddfile' ) ? JSON::XS::true() : JSON::XS::false();
    my $has_aptfile = -f File::Spec->catfile( $skill_path, 'aptfile' ) ? JSON::XS::true() : JSON::XS::false();
    my $has_apkfile = -f File::Spec->catfile( $skill_path, 'apkfile' ) ? JSON::XS::true() : JSON::XS::false();
    my $has_dnfile = -f File::Spec->catfile( $skill_path, 'dnfile' ) ? JSON::XS::true() : JSON::XS::false();
    my $has_brewfile = -f File::Spec->catfile( $skill_path, 'brewfile' ) ? JSON::XS::true() : JSON::XS::false();
    my $has_config = -f File::Spec->catfile( $skill_path, 'config', 'config.json' ) ? JSON::XS::true() : JSON::XS::false();
    my $has_cpanfile = -f File::Spec->catfile( $skill_path, 'cpanfile' ) ? JSON::XS::true() : JSON::XS::false();
    my $has_cpanfile_local = -f File::Spec->catfile( $skill_path, 'cpanfile.local' ) ? JSON::XS::true() : JSON::XS::false();
    my $pages_count = scalar @{ $pages->{entries} };
    my $docker_services_count = scalar @docker_services;
    my $collectors_count = scalar @{$collectors};

    my $metadata = {};
    $metadata->{name} = $repo_name;
    $metadata->{path} = $skill_path;
    $metadata->{cli_commands} = \@commands;
    $metadata->{enabled} = $enabled;
    $metadata->{cli_commands_count} = scalar(@commands);
    $metadata->{pages_count} = $pages_count;
    $metadata->{docker_services_count} = $docker_services_count;
    $metadata->{collectors_count} = $collectors_count;
    $metadata->{indicators_count} = $indicators_count;
    $metadata->{has_ddfile} = $has_ddfile;
    $metadata->{has_aptfile} = $has_aptfile;
    $metadata->{has_apkfile} = $has_apkfile;
    $metadata->{has_dnfile} = $has_dnfile;
    $metadata->{has_brewfile} = $has_brewfile;
    $metadata->{has_config} = $has_config;
    $metadata->{has_cpanfile} = $has_cpanfile;
    $metadata->{has_cpanfile_local} = $has_cpanfile_local;
    $metadata->{config_root} = File::Spec->catdir( $skill_path, 'config' );
    $metadata->{docker_root} = $docker_root;
    $metadata->{docker_services} = \@docker_services;
    $metadata->{state_root} = File::Spec->catdir( $skill_path, 'state' );
    $metadata->{logs_root} = File::Spec->catdir( $skill_path, 'logs' );
    $metadata->{cli_root} = $cli_root;
    $metadata->{local_root} = $self->_skill_local_perl_root($skill_path);
    $metadata->{shared_perl_root} = $self->_shared_perl_root;
    return $metadata;
}

# _skill_usage($repo_name, $skill_path)
# Builds a detailed description of one installed skill for the usage command.
# Input: skill repo name and absolute skill root directory path.
# Output: metadata hash reference with command, page, docker, and collector details.
sub _skill_usage {
    my ( $self, $repo_name, $skill_path ) = @_;
    my $pages = $self->_page_details($skill_path);
    my $docker = $self->_docker_service_details($skill_path);
    my $collectors = $self->_collector_details( $repo_name, $skill_path );
    my $has_ddfile = -f File::Spec->catfile( $skill_path, 'ddfile' ) ? JSON::XS::true() : JSON::XS::false();
    my $has_config = -f File::Spec->catfile( $skill_path, 'config', 'config.json' ) ? JSON::XS::true() : JSON::XS::false();
    my $has_aptfile = -f File::Spec->catfile( $skill_path, 'aptfile' ) ? JSON::XS::true() : JSON::XS::false();
    my $has_apkfile = -f File::Spec->catfile( $skill_path, 'apkfile' ) ? JSON::XS::true() : JSON::XS::false();
    my $has_dnfile = -f File::Spec->catfile( $skill_path, 'dnfile' ) ? JSON::XS::true() : JSON::XS::false();
    my $has_brewfile = -f File::Spec->catfile( $skill_path, 'brewfile' ) ? JSON::XS::true() : JSON::XS::false();
    my $has_cpanfile = -f File::Spec->catfile( $skill_path, 'cpanfile' ) ? JSON::XS::true() : JSON::XS::false();
    my $has_cpanfile_local = -f File::Spec->catfile( $skill_path, 'cpanfile.local' ) ? JSON::XS::true() : JSON::XS::false();
    my $usage = { %{ $self->_skill_metadata( $repo_name, $skill_path ) } };
    $usage->{cli} = $self->_cli_command_details($skill_path);
    $usage->{pages} = $pages;
    $usage->{docker} = {};
    $usage->{docker}{root} = File::Spec->catdir( $skill_path, 'config', 'docker' );
    $usage->{docker}{services} = $docker;
    $usage->{config} = {};
    $usage->{config}{root} = File::Spec->catdir( $skill_path, 'config' );
    $usage->{config}{file} = File::Spec->catfile( $skill_path, 'config', 'config.json' );
    $usage->{config}{merged_key} = '_' . $repo_name;
    $usage->{config}{has_ddfile} = $has_ddfile;
    $usage->{config}{has_config} = $has_config;
    $usage->{config}{has_aptfile} = $has_aptfile;
    $usage->{config}{has_apkfile} = $has_apkfile;
    $usage->{config}{has_dnfile} = $has_dnfile;
    $usage->{config}{has_brewfile} = $has_brewfile;
    $usage->{config}{has_cpanfile} = $has_cpanfile;
    $usage->{config}{has_cpanfile_local} = $has_cpanfile_local;
    $usage->{collectors} = $collectors;
    return $usage;
}

# _cli_command_details($skill_path)
# Enumerates executable skill commands and their hook metadata.
# Input: absolute skill root directory path.
# Output: array reference of command metadata hashes.
sub _cli_command_details {
    my ( $self, $skill_path ) = @_;
    my $cli_root = File::Spec->catdir( $skill_path, 'cli' );
    my @commands;
    if ( -d $cli_root ) {
        opendir( my $dh, $cli_root ) or die "Unable to read $cli_root: $!";
        for my $entry (
            sort grep {
                $_ ne '.' && $_ ne '..'
                  && -f File::Spec->catfile( $cli_root, $_ )
                  && $_ !~ /\.d\z/
            } readdir($dh)
          )
        {
            my $hooks_root = File::Spec->catdir( $cli_root, $entry . '.d' );
            my @hooks = $self->_sorted_files($hooks_root);
            my @hook_paths;
            for my $hook (@hooks) {
                push @hook_paths, File::Spec->catfile( $hooks_root, $hook );
            }
            push @commands, {
                name       => $entry,
                path       => File::Spec->catfile( $cli_root, $entry ),
                hooks_root => $hooks_root,
                has_hooks  => @hooks ? JSON::XS::true() : JSON::XS::false(),
                hook_count => scalar(@hooks),
                hooks      => \@hook_paths,
            };
        }
        closedir($dh);
    }
    return \@commands;
}

# _page_details($skill_path)
# Enumerates bookmark and nav pages shipped by one skill.
# Input: absolute skill root directory path.
# Output: hash reference with page and nav entry arrays.
sub _page_details {
    my ( $self, $skill_path ) = @_;
    my $dashboards_root = File::Spec->catdir( $skill_path, 'dashboards' );
    my @entries;
    if ( -d $dashboards_root ) {
        opendir( my $dh, $dashboards_root ) or die "Unable to read $dashboards_root: $!";
        @entries = sort grep {
               $_ ne '.'
            && $_ ne '..'
            && $_ ne 'nav'
            && -f File::Spec->catfile( $dashboards_root, $_ )
        } readdir($dh);
        closedir($dh);
    }

    my $nav_root = File::Spec->catdir( $dashboards_root, 'nav' );
    my @nav_entries;
    for my $entry ( $self->_sorted_files($nav_root) ) {
        push @nav_entries, 'nav/' . $entry;
    }
    return {
        root        => $dashboards_root,
        entries     => \@entries,
        nav_root    => $nav_root,
        nav_entries => \@nav_entries,
    };
}

# _docker_service_details($skill_path)
# Enumerates docker service folders and their files for one skill.
# Input: absolute skill root directory path.
# Output: array reference of docker service metadata hashes.
sub _docker_service_details {
    my ( $self, $skill_path ) = @_;
    my $docker_root = File::Spec->catdir( $skill_path, 'config', 'docker' );
    my @services;
    if ( -d $docker_root ) {
        opendir( my $dh, $docker_root ) or die "Unable to read $docker_root: $!";
        for my $entry (
            sort grep {
                $_ ne '.' && $_ ne '..' && -d File::Spec->catdir( $docker_root, $_ )
            } readdir($dh)
          )
        {
            my $service_root = File::Spec->catdir( $docker_root, $entry );
            my @service_files;
            for my $file ( $self->_sorted_files($service_root) ) {
                push @service_files, File::Spec->catfile( $service_root, $file );
            }
            push @services, {
                name  => $entry,
                root  => $service_root,
                files => \@service_files,
            };
        }
        closedir($dh);
    }
    return \@services;
}

# _collector_details($repo_name, $skill_path)
# Enumerates collectors declared in one skill config and derives indicator metadata.
# Input: skill repo name and absolute skill root directory path.
# Output: array reference of collector metadata hashes.
sub _collector_details {
    my ( $self, $repo_name, $skill_path ) = @_;
    my $config = $self->_read_skill_config_file($skill_path);
    my $collectors = $config->{collectors};
    return [] if ref($collectors) ne 'ARRAY';
    my @items;
    for my $job ( @{$collectors} ) {
        next if ref($job) ne 'HASH';
        next if !defined $job->{name} || $job->{name} eq '';
        my $qualified_name = $job->{name} =~ /^\Q$repo_name\E\./ ? $job->{name} : $repo_name . '.' . $job->{name};
        my $indicator = ref( $job->{indicator} ) eq 'HASH' ? $job->{indicator} : {};
        my $has_indicator = %{$indicator} ? JSON::XS::true() : JSON::XS::false();
        my %item = (
            name           => $job->{name},
            qualified_name => $qualified_name,
            command        => $job->{command},
            cwd            => $job->{cwd},
            schedule       => $job->{schedule},
            interval       => $job->{interval},
            has_indicator  => $has_indicator,
            indicator      => $indicator,
        );
        push @items, \%item;
    }
    return \@items;
}

# _read_skill_config_file($skill_path)
# Reads one skill config/config.json file directly.
# Input: absolute skill root directory path.
# Output: decoded hash reference or empty hash reference on invalid/missing JSON.
sub _read_skill_config_file {
    my ( $self, $skill_path ) = @_;
    my $config_file = File::Spec->catfile( $skill_path, 'config', 'config.json' );
    return {} if !-f $config_file;
    open my $fh, '<', $config_file or return {};
    local $/;
    my $json_text = <$fh>;
    close $fh;
    my $config = eval { decode_json($json_text) };
    return ref($config) eq 'HASH' ? $config : {};
}

# _sorted_files($root)
# Lists plain files under one directory in deterministic sorted order.
# Input: directory path string.
# Output: sorted list of child file names.
sub _sorted_files {
    my ( $self, $root ) = @_;
    return () if !$root || !-d $root;
    opendir( my $dh, $root ) or die "Unable to read $root: $!";
    my @files = sort grep {
           $_ ne '.'
        && $_ ne '..'
        && -f File::Spec->catfile( $root, $_ )
    } readdir($dh);
    closedir($dh);
    return @files;
}

# _skill_disabled($skill_path)
# Checks whether one installed skill has been disabled locally.
# Input: absolute skill root directory path.
# Output: boolean true when the disabled marker exists.
sub _skill_disabled {
    my ( $self, $skill_path ) = @_;
    return -f $self->_disabled_marker_path($skill_path) ? 1 : 0;
}

# _disabled_marker_path($skill_path)
# Returns the filesystem path of the skill-disabled marker file.
# Input: absolute skill root directory path.
# Output: marker file path string.
sub _disabled_marker_path {
    my ( $self, $skill_path ) = @_;
    return File::Spec->catfile( $skill_path, '.disabled' );
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

Skills are isolated under the active DD-OOP-LAYERS skills root such as
~/.developer-dashboard/skills/<repo-name>/ or
<project>/.developer-dashboard/skills/<repo-name>/

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module installs, updates, removes, and lists dashboard skills. It manages the on-disk skill roots under the active C<DD-OOP-LAYERS> chain, clones or updates Git-backed skill repos, prepares the expected directory layout, and helps the rest of the runtime locate the effective skill for one repo name from deepest layer back to home.

=head1 WHY IT EXISTS

It exists because skill lifecycle management is not the same as skill execution. The dashboard needs one module that owns where skills live, how they are installed or refreshed, how layered skill roots shadow one another, and how command and bookmark dispatchers find the effective skill later.

=head1 WHEN TO USE

Use this file when changing skill install/update/uninstall behavior, the expected skill directory layout, dependency bootstrap rules for skills, or skill listing and lookup semantics.

=head1 HOW TO USE

Construct it with the active paths, then call the install/update/uninstall/list methods from the C<dashboard skills> helper or from tests. Leave command execution and hook handling to C<Developer::Dashboard::SkillDispatcher>.

=head1 WHAT USES IT

It is used by the C<dashboard skills> command family, by the skill dispatcher, by release metadata that documents the isolated skill layout, and by skill lifecycle tests.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::SkillManager -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/19-skill-system.t t/20-skill-web-routes.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.

Example 5:

  dashboard skills install --ddfile

Drive an explicit manifest install from the current directory, where F<ddfile>
targets the base home-layer F<~/.developer-dashboard/skills/> root and
F<ddfile.local> targets the current directory's nested C<skills/> tree.


=for comment FULL-POD-DOC END

=cut
