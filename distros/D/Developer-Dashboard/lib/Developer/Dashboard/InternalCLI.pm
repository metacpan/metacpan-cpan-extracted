package Developer::Dashboard::InternalCLI;

use strict;
use warnings;

our $VERSION = '4.03';

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;

our $MODULE_SOURCE_PATH = File::Spec->rel2abs(__FILE__);

# helper_names()
# Returns the built-in private helper command names that dashboard manages.
# Input: none.
# Output: ordered list of helper command name strings.
sub helper_names {
    return qw(
      jq yq tomq propq iniq csvq xmlq
      of open-file workspace file files path paths ps1
      encode decode indicator collector config auth api init cpan page action docker serve stop restart log shell doctor housekeeper skills which
      complete
    );
}

# helper_aliases()
# Returns the compatibility alias map for renamed helper commands.
# Input: none.
# Output: hash reference mapping older names to current helper names.
sub helper_aliases {
    return {
        pjq   => 'jq',
        pyq   => 'yq',
        ptomq => 'tomq',
        pjp   => 'propq',
        ticket => 'workspace',
        skill => 'skills',
        logs  => 'log',
    };
}

# canonical_helper_name($name)
# Normalizes one helper command name to the current built-in helper name.
# Input: helper command string.
# Output: canonical helper name string or empty string when unsupported.
sub canonical_helper_name {
    my ($name) = @_;
    return '' if !defined $name || $name eq '';
    my %allowed = map { $_ => 1 } helper_names();
    return $name if $allowed{$name};
    my $aliases = helper_aliases();
    return $aliases->{$name} || '';
}

# helper_path(%args)
# Resolves one private helper executable path under the home runtime DD helper
# namespace root.
# Input: path registry object plus helper command name.
# Output: helper file path string.
sub helper_path {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing paths registry';
    my $name  = canonical_helper_name( $args{name} );
    die "Unsupported helper command '$args{name}'" if $name eq '';
    return File::Spec->catfile( _helper_install_root($paths), $name );
}

# helper_content($name)
# Loads one shipped private helper executable source body from the helper asset
# directory.
# Input: canonical helper command name.
# Output: full executable source text string.
sub helper_content {
    my ($name) = @_;
    $name = $name eq '_dashboard-core' ? $name : canonical_helper_name($name);
    die "Unsupported helper command '$name'" if !defined $name || $name eq '';
    my $path = _helper_asset_path($name);
    open my $fh, '<:raw', $path or die "Unable to read $path: $!";
    my $content = do { local $/; <$fh> };
    close $fh or die "Unable to close $path: $!";
    return $content;
}

# ensure_helpers(%args)
# Seeds the built-in private helper executables into the home runtime DD helper
# namespace root.
# Input: path registry object.
# Output: array reference of written helper file paths.
sub ensure_helpers {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing paths registry';

    my @written;
    $paths->ensure_dir( _helper_parent_root($paths) );
    $paths->ensure_dir( _helper_install_root($paths) );
    my $core_target = File::Spec->catfile( _helper_install_root($paths), '_dashboard-core' );
    if ( _stage_managed_helper( paths => $paths, name => '_dashboard-core', target => $core_target ) ) {
        $paths->secure_file_permissions( $core_target, executable => 1 );
    }

    for my $name ( helper_names() ) {
        my $target = helper_path( paths => $paths, name => $name );
        next if !_stage_managed_helper( paths => $paths, name => $name, target => $target );
        $paths->secure_file_permissions( $target, executable => 1 );
        push @written, $target;
    }

    _remove_retired_managed_helper(
        paths => $paths,
        name  => 'skill',
    );
    _remove_legacy_managed_flat_helpers( paths => $paths );

    return \@written;
}

# ensure_helper(%args)
# Stages one dashboard-managed helper, plus the shared _dashboard-core runtime
# when the helper delegates through it, without refreshing every helper on the
# hot command path.
# Input: path registry object plus helper command name.
# Output: array reference of helper file paths written during this focused sync.
sub ensure_helper {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing paths registry';
    my $name  = canonical_helper_name( $args{name} );
    die "Unsupported helper command '$args{name}'" if $name eq '';

    my @written;
    $paths->ensure_dir( _helper_parent_root($paths) );
    $paths->ensure_dir( _helper_install_root($paths) );

    if ( _helper_uses_dashboard_core($name) ) {
        my $core_target = File::Spec->catfile( _helper_install_root($paths), '_dashboard-core' );
        if ( !_managed_helper_file_current( $core_target, '_dashboard-core' ) ) {
            if ( _stage_managed_helper( paths => $paths, name => '_dashboard-core', target => $core_target ) ) {
                $paths->secure_file_permissions( $core_target, executable => 1 );
                push @written, $core_target;
            }
        }
    }

    my $target = helper_path( paths => $paths, name => $name );
    if ( !_managed_helper_file_current( $target, $name ) ) {
        if ( _stage_managed_helper( paths => $paths, name => $name, target => $target ) ) {
            $paths->secure_file_permissions( $target, executable => 1 );
            push @written, $target;
        }
    }

    _remove_retired_managed_helper(
        paths => $paths,
        name  => 'skill',
    );
    _remove_legacy_managed_flat_helpers( paths => $paths );

    return \@written;
}

# _stage_managed_helper(%args)
# Writes one dashboard-managed helper file only when the existing target is
# absent or already owned by the dashboard runtime.
# Input: path registry, helper name, and target path.
# Output: boolean true when the helper was written or updated, false when a
# user-owned existing target was preserved or when the file already matched.
sub _stage_managed_helper {
    my (%args) = @_;
    my $target = $args{target} || die 'Missing helper target';
    my $name   = $args{name}   || die 'Missing helper name';
    my $content = _managed_helper_content($name);

    if ( -e $target ) {
        return 0 if !-f $target;
        if ( ( -s $target ) == 0 && _is_managed_helper_target( $args{paths}, $target ) ) {
            _write_helper_atomically( $target, $content );
            return 1;
        }
        open my $existing_fh, '<:raw', $target or die "Unable to read $target: $!";
        my $existing = do { local $/; <$existing_fh> };
        close $existing_fh or die "Unable to close $target: $!";
        return 0 if !_is_dashboard_managed_helper( $existing, $name );
        require Developer::Dashboard::SeedSync;
        return 0 if Developer::Dashboard::SeedSync::same_content_md5( $existing, $content );
    }

    _write_helper_atomically( $target, $content );
    return 1;
}

# _write_helper_atomically($target, $content)
# Writes one managed helper body through a temporary file and atomic rename so
# concurrent dashboard processes do not expose partial private helper files.
# Input: final helper target path and full helper source text string.
# Output: true after the new helper body is fully in place.
sub _write_helper_atomically {
    my ( $target, $content ) = @_;
    my $temp = $target . '.tmp.' . $$ . '.' . int( rand(1_000_000) );
    open my $fh, '>:raw', $temp or die "Unable to write $temp: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $temp: $!";
    rename $temp, $target or do {
        my $error = $!;
        unlink $temp;
        die "Unable to rename $temp to $target: $error";
    };
    return 1;
}

# _remove_retired_managed_helper(%args)
# Removes one no-longer-supported dashboard-managed helper from the staged home
# runtime when the target is still owned by dashboard.
# Input: path registry object plus retired helper name.
# Output: boolean true when a managed legacy helper was removed, false
# otherwise.
sub _remove_retired_managed_helper {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing paths registry';
    my $name  = $args{name}  || die 'Missing retired helper name';
    my $target = File::Spec->catfile( _helper_install_root($paths), $name );
    return 0 if !-e $target;
    return 0 if !-f $target;
    open my $fh, '<:raw', $target or die "Unable to read $target: $!";
    my $content = do { local $/; <$fh> };
    close $fh or die "Unable to close $target: $!";
    return 0 if !_is_dashboard_managed_helper( $content, $name );
    unlink $target or die "Unable to remove retired helper $target: $!";
    return 1;
}

# _remove_legacy_managed_flat_helpers(%args)
# Removes dashboard-managed legacy helper files that used to live directly under
# the home runtime cli root before helpers moved under cli/dd/.
# Input: path registry object.
# Output: array reference of removed legacy helper path strings.
sub _remove_legacy_managed_flat_helpers {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing paths registry';
    my $parent = _helper_parent_root($paths);
    my @removed;
    for my $name ( '_dashboard-core', helper_names() ) {
        my $target = File::Spec->catfile( $parent, $name );
        next if !-e $target || !-f $target;
        open my $fh, '<:raw', $target or die "Unable to read $target: $!";
        my $content = do { local $/; <$fh> };
        close $fh or die "Unable to close $target: $!";
        next if !_is_dashboard_managed_helper( $content, $name );
        unlink $target or die "Unable to remove legacy managed helper $target: $!";
        push @removed, $target;
    }
    return \@removed;
}

# _managed_helper_content($name)
# Returns the staged helper body with a dashboard ownership marker injected
# after any shebang line.
# Input: canonical helper command name.
# Output: helper source text string.
sub _managed_helper_content {
    my ($name) = @_;
    my $content = helper_content($name);
    if ( _helper_uses_dashboard_core($name) ) {
        my $legacy_block = <<'BLOCK';
my $command = basename($0);
my $core = File::Spec->catfile( $Bin, '_dashboard-core' );
exec { $^X } $^X, $core, $command, @ARGV;
die "Unable to exec $core for $command: $!";
BLOCK
        my $managed_block = <<"BLOCK";
my \$command = '$name';
my \$core = File::Spec->catfile( \$Bin, '_dashboard-core' );
if ( !defined \$ENV{DEVELOPER_DASHBOARD_REPO_LIB} || \$ENV{DEVELOPER_DASHBOARD_REPO_LIB} eq q{} ) {
    for my \$inc (\@INC) {
        next if !defined \$inc || \$inc eq q{};
        my \$candidate = File::Spec->catfile( \$inc, 'Developer', 'Dashboard.pm' );
        if ( -f \$candidate ) {
            \$ENV{DEVELOPER_DASHBOARD_REPO_LIB} = \$inc;
            last;
        }
    }
}
my \@command = ( \$^X, \$core, \$command, \@ARGV );
if (is_windows()) {
    system \@command;
    my \$status = \$?;
    my \$exit_code = \$status > 255 ? \$status >> 8 : \$status;
    exit \$exit_code;
}
exec { \$^X } \@command;
die "Unable to exec \$core for \$command: \$!";
BLOCK
        $content =~ s/use File::Basename qw\(basename\);\n//;
        $content =~ s/use Developer::Dashboard::Platform qw\(is_windows\);\n//g;
        $content =~ s/use File::Spec;\nuse FindBin qw\(\$Bin\);\n/use File::Spec;\nuse FindBin qw(\$Bin);\nuse Developer::Dashboard::Platform qw(is_windows);\n/;
        $content =~ s/\Q$legacy_block\E/$managed_block/;
        $content =~ s/my \$command = '[^']+';\nmy \$core = File::Spec->catfile\( \$Bin, '_dashboard-core' \);\nmy \@command = \( \$\^X, \$core, \$command, \@ARGV \);\nif \(is_windows\(\)\) \{\n    system \@command;\n    my \$status = \$\?;\n    my \$exit_code = \$status > 255 \? \$status >> 8 : \$status;\n    exit \$exit_code;\n\}\nexec \{ \$\^X \} \@command;\ndie "Unable to exec \$core for \$command: \$!";/$managed_block/s;
    }
    my $marker  = _managed_helper_marker($name) . "\n";
    my $version_marker = _managed_helper_version_marker() . "\n";
    if ( $content =~ /\Q$marker\E/ ) {
        return $content if $content =~ /\Q$version_marker\E/;
        $content =~ s/\Q$marker\E/$marker$version_marker/;
        return $content;
    }
    if ( $content =~ /\A(#![^\n]*\n)/ ) {
        substr( $content, length($1), 0, $marker . $version_marker );
        return $content;
    }
    return $marker . $version_marker . $content;
}

# _managed_helper_marker($name)
# Returns the stable marker string used to identify dashboard-managed staged
# helper files.
# Input: helper name string.
# Output: marker comment string.
sub _managed_helper_marker {
    my ($name) = @_;
    return "# developer-dashboard-managed-helper: $name";
}

# _managed_helper_version_marker()
# Returns the stable marker string used to stamp managed helper bodies with the
# dashboard build version that generated them.
# Input: none.
# Output: marker comment string.
sub _managed_helper_version_marker {
    return "# developer-dashboard-managed-helper-version: $VERSION";
}

# _helper_uses_dashboard_core($name)
# Returns whether one staged helper is a thin wrapper that must hand a fixed
# built-in command name to the shared _dashboard-core runtime.
# Input: helper name string.
# Output: boolean true when the helper delegates into _dashboard-core.
sub _helper_uses_dashboard_core {
    my ($name) = @_;
    return 0 if !defined $name || $name eq '';
    return $name =~ /\A(?:encode|decode|indicator|collector|config|auth|api|init|cpan|page|action|docker|serve|stop|restart|log|shell|doctor|housekeeper|skills|which)\z/ ? 1 : 0;
}

# _is_dashboard_managed_helper($content, $name)
# Detects whether an existing helper file was previously staged by dashboard,
# including older pre-marker releases that carried the built-in helper POD.
# Input: existing file content plus helper name.
# Output: boolean true when dashboard owns the target and may update it.
sub _is_dashboard_managed_helper {
    my ( $content, $name ) = @_;
    return 0 if !defined $content;
    return 1 if $content =~ /^\Q@{[ _managed_helper_marker($name) ]}\E$/m;
    if ( $name eq '_dashboard-core' ) {
        return 1
          if $content =~ /Missing built-in dashboard command/
          && $content =~ /Developer::Dashboard::CLI::SeededPages/;
    }
    return 1
      if $content =~ /LAZY-THIN-CMD/
      && $content =~ /Developer Dashboard/;
    return 0;
}

# _helper_parent_root($paths)
# Returns the home runtime user CLI root that contains the dashboard-managed dd
# namespace.
# Input: path registry object.
# Output: directory path string.
sub _helper_parent_root {
    my ($paths) = @_;
    return File::Spec->catdir( $paths->home_runtime_root, 'cli' );
}

# _helper_install_root($paths)
# Returns the home runtime DD helper namespace root used for built-in helper
# staging.
# Input: path registry object.
# Output: directory path string.
sub _helper_install_root {
    my ($paths) = @_;
    return File::Spec->catdir( _helper_parent_root($paths), 'dd' );
}

# _is_managed_helper_target($paths, $target)
# Detects whether a helper target path lives under the dashboard-managed dd
# helper namespace root.
# Input: path registry object plus target path string.
# Output: boolean true when the target belongs to the managed helper root.
sub _is_managed_helper_target {
    my ( $paths, $target ) = @_;
    return 0 if !$paths || !defined $target || $target eq '';
    my $root = File::Spec->rel2abs( _helper_install_root($paths) );
    my $path = File::Spec->rel2abs($target);
    return 1 if $path eq $root;
    return index( $path, $root . '/' ) == 0;
}

# _managed_helper_file_current($path, $name)
# Detects whether one staged helper file already belongs to dashboard and
# carries the current helper-version marker so the hot command path can skip a
# full helper refresh.
# Input: helper file path string and helper name string.
# Output: boolean true when the target already matches the current dashboard
# helper version marker.
sub _managed_helper_file_current {
    my ( $path, $name ) = @_;
    return 0 if !defined $path || $path eq '' || !-f $path;
    open my $fh, '<:raw', $path or die "Unable to read $path: $!";
    my $content = do { local $/; <$fh> };
    close $fh or die "Unable to close $path: $!";
    return 0 if !_is_dashboard_managed_helper( $content, $name );
    return $content =~ /^\Q@{[ _managed_helper_version_marker() ]}\E$/m ? 1 : 0;
}

# _helper_asset_path($name)
# Resolves one private helper asset path from the repo share tree during
# development or from the installed distribution share dir after install.
# Input: canonical helper command name.
# Output: absolute helper asset file path string.
sub _helper_asset_path {
    my ($name) = @_;
    my $repo_path = File::Spec->catfile( _repo_private_cli_root(), $name );
    return $repo_path if -f $repo_path;
    for my $root ( _repo_private_cli_root_candidates() ) {
        next if !defined $root || $root eq '';
        my $candidate = File::Spec->catfile( $root, $name );
        return $candidate if -f $candidate;
    }
    if ( _module_source_looks_like_blib_build() ) {
        for my $root ( _shared_private_cli_root_candidates() ) {
            next if !defined $root || $root eq '';
            my $candidate = File::Spec->catfile( $root, $name );
            return $candidate if -f $candidate;
        }
    }
    my @roots = _shared_private_cli_root_candidates();
    for my $root (@roots) {
        next if !defined $root || $root eq '';
        my $candidate = File::Spec->catfile( $root, $name );
        return $candidate if -f $candidate;
    }
    return File::Spec->catfile( _shared_private_cli_root(), $name );
}

# _repo_private_cli_root()
# Resolves the repo-tree private CLI helper asset directory.
# Input: none.
# Output: absolute private helper asset directory path string.
sub _repo_private_cli_root {
    my @candidates = _repo_private_cli_root_candidates();
    for my $candidate (@candidates) {
        return $candidate if _private_cli_root_has_dashboard_core($candidate);
    }
    return $candidates[0];
}

# _repo_private_cli_root_candidates()
# Builds the ordered candidate list for repo-tree private helper asset roots
# derived from the loaded module source path.
# Input: none.
# Output: list of absolute candidate directory paths.
sub _repo_private_cli_root_candidates {
    my @candidates;
    my $module_source = _module_source_path();
    my $module_dir = dirname( File::Spec->rel2abs($module_source) );
    for my $levels_up ( 3 .. 6 ) {
        push @candidates, _abs_existing_path(
            File::Spec->rel2abs(
                File::Spec->catdir(
                    $module_dir,
                    ( File::Spec->updir ) x $levels_up,
                    'share',
                    'private-cli',
                )
            )
        );
    }
    my %seen;
    return grep { defined $_ && $_ ne '' && !$seen{$_}++ } @candidates;
}

# _module_source_path()
# Resolves the source path for the loaded InternalCLI module from %INC when
# available, otherwise falls back to __FILE__.
# Input: none.
# Output: absolute or relative module source file path string.
sub _module_source_path {
    $MODULE_SOURCE_PATH ||= File::Spec->rel2abs(__FILE__);
    return $MODULE_SOURCE_PATH;
}

# _module_source_looks_like_blib_build()
# Detects whether the loaded InternalCLI module currently comes from a blib/lib
# build tree where helper assets still live under the unpacked dist share tree.
# Input: none.
# Output: boolean true when the module source path contains a blib/lib segment.
sub _module_source_looks_like_blib_build {
    my $module_source = _module_source_path();
    return 0 if !defined $module_source || $module_source eq '';
    return $module_source =~ m{(?:^|[\\/])blib[\\/]lib(?:[\\/]|$)} ? 1 : 0;
}

# _abs_existing_path($path)
# Canonicalizes one existing filesystem path when possible without warning on
# missing candidates.
# Input: absolute or relative path string.
# Output: canonical absolute path string when the path exists, otherwise the
# original path string.
sub _abs_existing_path {
    my ($path) = @_;
    return '' if !defined $path || $path eq '';
    return $path if !-e $path;
    return abs_path($path) || $path;
}

# _shared_private_cli_root()
# Resolves the installed distribution share directory for private helper assets.
# Input: none.
# Output: absolute helper asset directory path inside the installed dist share.
sub _shared_private_cli_root {
    my @candidates = _shared_private_cli_root_candidates();
    for my $candidate (@candidates) {
        next if !defined $candidate || $candidate eq '';
        return $candidate if _private_cli_root_has_dashboard_core($candidate);
    }
    return $candidates[0];
}

# _shared_private_cli_root_candidates()
# Builds the ordered candidate list for installed private helper asset roots.
# Input: none.
# Output: list of absolute candidate directory paths.
sub _shared_private_cli_root_candidates {
    my @candidates;
    my $dist_root = eval { dist_dir('Developer-Dashboard') };
    if ( defined $dist_root && $dist_root ne '' ) {
        push @candidates, File::Spec->catdir( $dist_root, 'private-cli' );
        push @candidates, $dist_root if _looks_like_private_cli_root($dist_root);
    }

    my $module_root = _module_install_lib_root();
    if ( defined $module_root && $module_root ne '' ) {
        push @candidates, File::Spec->catdir(
            $module_root,
            'auto',
            'Developer',
            'Dashboard',
            'private-cli',
        );
        push @candidates, File::Spec->catdir(
            $module_root,
            'auto',
            'share',
            'dist',
            'Developer-Dashboard',
            'private-cli',
        );
    }

    push @candidates, _home_private_cli_root_candidates();

    my %seen;
    return grep { defined $_ && $_ ne '' && !$seen{$_}++ } @candidates;
}

# dist_dir($dist_name)
# Lazily resolves one installed distribution share root through File::ShareDir.
# Input: distribution name string.
# Output: distribution share directory path string.
sub dist_dir {
    require File::ShareDir;
    return File::ShareDir::dist_dir(@_);
}

# _module_install_lib_root()
# Resolves the installed lib/perl5 root that contains the loaded InternalCLI
# module.
# Input: none.
# Output: absolute module lib root path string.
sub _module_install_lib_root {
    my $module_path = $INC{'Developer/Dashboard/InternalCLI.pm'} || __FILE__;
    return File::Spec->rel2abs(
        File::Spec->catdir(
            dirname($module_path),
            File::Spec->updir,
            File::Spec->updir,
        )
    );
}

# _looks_like_private_cli_root($path)
# Detects whether a path already points at the private helper root instead of a
# dist share parent directory.
# Input: candidate directory path string.
# Output: boolean true when the path already looks like the private-cli root.
sub _looks_like_private_cli_root {
    my ($path) = @_;
    return 0 if !defined $path || $path eq '';
    my @parts = File::Spec->splitdir($path);
    return 0 if !@parts || $parts[-1] ne 'private-cli';
    return _private_cli_root_has_dashboard_core($path);
}

# _private_cli_root_has_dashboard_core($path)
# Detects whether a candidate private-cli root contains the built-in helper
# payloads that dashboard must stage into the user runtime.
# Input: candidate directory path string.
# Output: boolean true when the candidate contains _dashboard-core.
sub _private_cli_root_has_dashboard_core {
    my ($path) = @_;
    return 0 if !defined $path || $path eq '';
    return 0 if !-d $path;
    return -f File::Spec->catfile( $path, '_dashboard-core' ) ? 1 : 0;
}

# _home_private_cli_root_candidates()
# Returns the staged home helper roots that can bootstrap checkout installs
# before the managed dd namespace has been seeded.
# Input: none.
# Output: ordered list of absolute home helper root candidate paths.
sub _home_private_cli_root_candidates {
    my $home = $ENV{HOME};
    return if !defined $home || $home eq '';
    return (
        File::Spec->catdir( $home, '.developer-dashboard', 'cli', 'dd' ),
        File::Spec->catdir( $home, '.developer-dashboard', 'cli' ),
    );
}

1;

__END__

=head1 NAME

Developer::Dashboard::InternalCLI - private runtime helper executable management

=head1 SYNOPSIS

  use Developer::Dashboard::InternalCLI;

  my $paths = Developer::Dashboard::PathRegistry->new(home => $ENV{HOME});
  Developer::Dashboard::InternalCLI::ensure_helpers(paths => $paths);

=head1 DESCRIPTION

This module manages the built-in private helper executables that Developer
Dashboard stages under F<~/.developer-dashboard/cli/dd/> instead of exposing as
global system commands.

=head1 FUNCTIONS

=head2 helper_names, helper_aliases, canonical_helper_name, helper_content, helper_path, ensure_helpers

Build and seed the built-in private helper command files.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module owns the dashboard-managed private helper assets. It decides which built-in command names exist, stages the corresponding helper files under F<~/.developer-dashboard/cli/dd/>, and resolves the helper paths that the public C<dashboard> entrypoint should C<exec> into.

=head1 WHY IT EXISTS

It exists because built-in helper staging is a product contract of its own. The switchboard must know which helpers are dashboard-managed and how to refresh them without mixing that policy into every command or shell bootstrap path.

=head1 WHEN TO USE

Use this file when adding, renaming, or removing built-in helper commands, when changing the private helper namespace, or when fixing helper staging drift between shipped assets and the home runtime copy.

=head1 HOW TO USE

Call C<ensure_helpers> with the active paths object to stage or refresh managed helpers, use C<canonical_helper_name> to normalize helper aliases, and use C<helper_path> when the switchboard needs the final staged executable path.

=head1 WHAT USES IT

It is used by C<bin/dashboard>, by init/update flows that stage built-ins, by shell bootstrap generation, and by tests that verify helper extraction and private-helper packaging.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::InternalCLI -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/07-core-units.t t/21-refactor-coverage.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
