package Developer::Dashboard::SkillManager;

use strict;
use warnings;

our $VERSION = '2.72';

use Cwd qw(realpath);
use File::Copy qw(copy);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Basename qw(basename);
use File::Find qw(find);
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
        paths => $paths,
    }, $class;
}

# install($source)
# Installs or reinstalls a skill into the deepest participating DD-OOP-LAYERS
# skills root.
# Input: Git URL or direct local checked-out repository path.
# Output: hash ref with success status and repo name.
sub install {
    my ( $self, $source ) = @_;
    return { error => 'Missing skill source' } if !$source;

    my $local_source = $self->_local_checked_out_source($source);
    return $local_source if ref($local_source) eq 'HASH';
    my $repo_name = $local_source ? basename($local_source) : _extract_repo_name($source);
    return { error => "Unable to extract repo name from $source" } if !$repo_name;

    my $skills_root = $self->{paths}->skills_root;
    my $skill_path = File::Spec->catdir( $skills_root, $repo_name );

    $self->{paths}->ensure_dir($skills_root);
    my $remove = $self->_remove_existing_skill_path($skill_path);
    return $remove if $remove->{error};

    if ($local_source) {
        my $sync = $self->_sync_local_skill_source( $local_source, $skill_path );
        if ( $sync->{error} ) {
            remove_tree($skill_path) if -d $skill_path;
            return $sync;
        }
    }
    else {
        my ( $stdout, $stderr, $exit ) = capture {
            system( 'git', 'clone', $source, $skill_path );
        };
        if ( $exit != 0 ) {
            remove_tree($skill_path) if -d $skill_path;
            return { error => "Failed to clone $source: $stderr" };
        }
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
# Installs one skill's system and Perl dependencies in install order.
# Input: absolute skill root directory path.
# Output: result hash reference with success or error state.
sub _install_skill_dependencies {
    my ( $self, $skill_path ) = @_;
    my $aptfile = File::Spec->catfile( $skill_path, 'aptfile' );
    my $cpanfile = File::Spec->catfile( $skill_path, 'cpanfile' );
    return { success => 1, skipped => 1 } if !-f $aptfile && !-f $cpanfile;

    my @apt_packages = $self->_skill_apt_packages($skill_path);
    if (@apt_packages) {
        my ( $stdout, $stderr, $exit ) = capture {
            system( 'apt-get', 'install', '-y', @apt_packages );
        };
        return {
            error => "Failed to install skill apt dependencies for $skill_path: $stderr",
        } if $exit != 0;
    }

    return {
        success => 1,
        skipped => 1,
    } if !-f $cpanfile;

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
    my $indicators_count = scalar grep { $_->{has_indicator} } @{$collectors};

    return {
        name            => $repo_name,
        path            => $skill_path,
        cli_commands    => \@commands,
        enabled         => $self->_skill_disabled($skill_path) ? JSON::XS::false() : JSON::XS::true(),
        cli_commands_count => scalar(@commands),
        pages_count        => scalar( @{ $pages->{entries} } ),
        docker_services_count => scalar(@docker_services),
        collectors_count   => scalar( @{$collectors} ),
        indicators_count   => $indicators_count,
        has_aptfile     => -f File::Spec->catfile( $skill_path, 'aptfile' ) ? JSON::XS::true() : JSON::XS::false(),
        has_config      => -f File::Spec->catfile( $skill_path, 'config', 'config.json' ) ? JSON::XS::true() : JSON::XS::false(),
        has_cpanfile    => -f File::Spec->catfile( $skill_path, 'cpanfile' ) ? JSON::XS::true() : JSON::XS::false(),
        config_root     => File::Spec->catdir( $skill_path, 'config' ),
        docker_root     => $docker_root,
        docker_services => \@docker_services,
        state_root      => File::Spec->catdir( $skill_path, 'state' ),
        logs_root       => File::Spec->catdir( $skill_path, 'logs' ),
        cli_root        => $cli_root,
        local_root      => File::Spec->catdir( $skill_path, 'local' ),
    };
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
    return {
        %{ $self->_skill_metadata( $repo_name, $skill_path ) },
        cli => $self->_cli_command_details($skill_path),
        pages => $pages,
        docker => {
            root     => File::Spec->catdir( $skill_path, 'config', 'docker' ),
            services => $docker,
        },
        config => {
            root        => File::Spec->catdir( $skill_path, 'config' ),
            file        => File::Spec->catfile( $skill_path, 'config', 'config.json' ),
            merged_key  => '_' . $repo_name,
            has_config  => -f File::Spec->catfile( $skill_path, 'config', 'config.json' ) ? JSON::XS::true() : JSON::XS::false(),
            has_aptfile => -f File::Spec->catfile( $skill_path, 'aptfile' ) ? JSON::XS::true() : JSON::XS::false(),
            has_cpanfile => -f File::Spec->catfile( $skill_path, 'cpanfile' ) ? JSON::XS::true() : JSON::XS::false(),
        },
        collectors => $collectors,
    };
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
            push @commands, {
                name       => $entry,
                path       => File::Spec->catfile( $cli_root, $entry ),
                hooks_root => $hooks_root,
                has_hooks  => @hooks ? JSON::XS::true() : JSON::XS::false(),
                hook_count => scalar(@hooks),
                hooks      => [ map { File::Spec->catfile( $hooks_root, $_ ) } @hooks ],
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
    my @nav_entries = map { 'nav/' . $_ } $self->_sorted_files($nav_root);
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
            push @services, {
                name  => $entry,
                root  => $service_root,
                files => [ map { File::Spec->catfile( $service_root, $_ ) } $self->_sorted_files($service_root) ],
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
        push @items, {
            name           => $job->{name},
            qualified_name => $qualified_name,
            command        => $job->{command},
            cwd            => $job->{cwd},
            schedule       => $job->{schedule},
            interval       => $job->{interval},
            has_indicator  => %{$indicator} ? JSON::XS::true() : JSON::XS::false(),
            indicator      => $indicator,
        };
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


=for comment FULL-POD-DOC END

=cut
