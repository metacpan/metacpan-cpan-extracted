package Developer::Dashboard::InternalCLI;

use strict;
use warnings;

our $VERSION = '2.34';

use File::Basename qw(dirname);
use File::Spec;
use File::ShareDir qw(dist_dir);
use Developer::Dashboard::SeedSync ();

# helper_names()
# Returns the built-in private helper command names that dashboard manages.
# Input: none.
# Output: ordered list of helper command name strings.
sub helper_names {
    return qw(
      jq yq tomq propq iniq csvq xmlq
      of open-file ticket path paths ps1
      encode decode indicator collector config auth init cpan page action docker serve stop restart shell doctor skills
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
        open my $existing_fh, '<:raw', $target or die "Unable to read $target: $!";
        my $existing = do { local $/; <$existing_fh> };
        close $existing_fh or die "Unable to close $target: $!";
        return 0 if !_is_dashboard_managed_helper( $existing, $name );
        return 0 if Developer::Dashboard::SeedSync::same_content_md5( $existing, $content );
    }

    open my $fh, '>:raw', $target or die "Unable to write $target: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $target: $!";
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

# _managed_helper_content($name)
# Returns the staged helper body with a dashboard ownership marker injected
# after any shebang line.
# Input: canonical helper command name.
# Output: helper source text string.
sub _managed_helper_content {
    my ($name) = @_;
    my $content = helper_content($name);
    my $marker  = _managed_helper_marker($name) . "\n";
    return $content if $content =~ /\Q$marker\E/;
    if ( $content =~ /\A(#![^\n]*\n)/ ) {
        substr( $content, length($1), 0, $marker );
        return $content;
    }
    return $marker . $content;
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

# _helper_asset_path($name)
# Resolves one private helper asset path from the repo share tree during
# development or from the installed distribution share dir after install.
# Input: canonical helper command name.
# Output: absolute helper asset file path string.
sub _helper_asset_path {
    my ($name) = @_;
    my $repo_path = File::Spec->catfile( _repo_private_cli_root(), $name );
    return $repo_path if -f $repo_path;
    return File::Spec->catfile( _shared_private_cli_root(), $name );
}

# _repo_private_cli_root()
# Resolves the repo-tree private CLI helper asset directory.
# Input: none.
# Output: absolute private helper asset directory path string.
sub _repo_private_cli_root {
    return File::Spec->catdir(
        dirname(__FILE__),
        File::Spec->updir,
        File::Spec->updir,
        File::Spec->updir,
        'share',
        'private-cli',
    );
}

# _shared_private_cli_root()
# Resolves the installed distribution share directory for private helper assets.
# Input: none.
# Output: absolute helper asset directory path inside the installed dist share.
sub _shared_private_cli_root {
    return File::Spec->catdir( dist_dir('Developer-Dashboard'), 'private-cli' );
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
