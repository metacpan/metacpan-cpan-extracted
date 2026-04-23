package Developer::Dashboard::Housekeeper;

use strict;
use warnings;

our $VERSION = '3.04';

use File::Path qw(remove_tree);
use File::Spec;
use POSIX qw(strftime);
use Time::HiRes qw(time);

use Developer::Dashboard::Collector;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::JSON qw(json_decode);

# new(%args)
# Constructs the temp-state cleanup service.
# Input: path registry object.
# Output: Developer::Dashboard::Housekeeper object.
sub new {
    my ( $class, %args ) = @_;
    my $paths = $args{paths} || die 'Missing paths registry';
    return bless {
        paths => $paths,
    }, $class;
}

# run(%args)
# Removes stale dashboard temp state and dashboard-owned temp files.
# Input: optional min_age_seconds integer and optional now_epoch integer for deterministic testing.
# Output: hash reference summary with scan counts and removed item details.
sub run {
    my ( $self, %args ) = @_;
    my $min_age_seconds = defined $args{min_age_seconds} ? $args{min_age_seconds} : 3600;
    die "min_age_seconds must be a non-negative integer\n"
      if $min_age_seconds !~ /\A\d+\z/;

    my $removed = [];
    my $scanned = {
        state_roots       => 0,
        ajax_temp_files   => 0,
        result_temp_files => 0,
        collector_logs    => 0,
    };

    push @{$removed}, $self->_cleanup_state_roots( min_age_seconds => $min_age_seconds, scanned => $scanned );
    push @{$removed}, $self->_cleanup_temp_files( min_age_seconds => $min_age_seconds, scanned => $scanned );
    push @{$removed}, $self->_rotate_collector_logs( scanned => $scanned, now_epoch => $args{now_epoch} );

    return {
        ok               => 1,
        happened_at      => _now_iso8601(),
        min_age_seconds  => $min_age_seconds + 0,
        scanned          => $scanned,
        removed          => $removed,
        removed_count    => scalar @{$removed},
    };
}

# _rotate_collector_logs(%args)
# Applies configured collector log retention rules through the collector storage layer.
# Input: scanned hash reference and optional now_epoch integer.
# Output: list of collector-log rotation summary hash references.
sub _rotate_collector_logs {
    my ( $self, %args ) = @_;
    my @rotated;
    for my $job ( @{ $self->_config->collectors || [] } ) {
        next if ref($job) ne 'HASH';
        my $name = $job->{name} || next;
        my $rotation = $self->_collector_rotation($job);
        next if !keys %{$rotation};
        $args{scanned}{collector_logs}++;
        my $result = $self->_collector_store->rotate_log(
            $name,
            $rotation,
            now_epoch => $args{now_epoch},
        );
        push @rotated, $result if $result;
    }
    return @rotated;
}

# _cleanup_state_roots(%args)
# Removes stale hashed runtime state roots from the shared temp state tree.
# Input: min_age_seconds integer and scanned hash reference.
# Output: list of removed item hash references.
sub _cleanup_state_roots {
    my ( $self, %args ) = @_;
    my $base = $self->{paths}->state_base_root;
    return () if !-d $base;

    my %active_roots = map {
        $self->{paths}->_state_root_for_layer($_) => 1
    } $self->{paths}->runtime_layers;

    opendir my $dh, $base or die "Unable to read $base: $!";
    my @removed;
    while ( my $entry = readdir $dh ) {
        next if $entry eq '.' || $entry eq '..';
        my $dir = File::Spec->catdir( $base, $entry );
        next if !-d $dir;
        $args{scanned}{state_roots}++;
        next if $active_roots{$dir};
        next if !$self->_state_root_is_stale( $dir, $args{min_age_seconds} );
        push @removed, $self->_remove_tree( $dir, 'state-root' );
    }
    closedir $dh;
    return @removed;
}

# _cleanup_temp_files(%args)
# Removes stale dashboard-owned temp files left under the system temp directory.
# Input: min_age_seconds integer and scanned hash reference.
# Output: list of removed item hash references.
sub _cleanup_temp_files {
    my ( $self, %args ) = @_;
    my $tmpdir = File::Spec->tmpdir;
    opendir my $dh, $tmpdir or die "Unable to read $tmpdir: $!";
    my @removed;
    while ( my $entry = readdir $dh ) {
        next if $entry eq '.' || $entry eq '..';
        my $path = File::Spec->catfile( $tmpdir, $entry );
        next if !-f $path;
        my ( $kind, $scan_key ) = $self->_temp_file_kind($entry);
        next if !$kind;
        $args{scanned}{$scan_key}++;
        next if !$self->_path_is_old_enough( $path, $args{min_age_seconds} );
        if ( !unlink $path ) {
            next if !-e $path;
            my $label = $kind eq 'ajax-temp-file' ? 'Ajax temp file' : 'runtime result temp file';
            die "Unable to remove stale $label $path: $!";
        }
        push @removed, {
            kind => $kind,
            path => $path,
        };
    }
    closedir $dh;
    return @removed;
}

# _temp_file_kind($entry)
# Maps one temp-directory entry name to the dashboard-owned cleanup category.
# Input: basename string from the system temp directory.
# Output: kind string and scanned hash key, or empty list when the file is unrelated.
sub _temp_file_kind {
    my ( $self, $entry ) = @_;
    return ( 'ajax-temp-file', 'ajax_temp_files' ) if $entry =~ /\Adeveloper-dashboard-ajax-/;
    return ( 'result-temp-file', 'result_temp_files' ) if $entry =~ /\Adashboard-result-/;
    return;
}

# _collector_rotation($job)
# Merges the supported collector rotation configuration keys from one collector definition.
# Input: collector job hash reference.
# Output: merged rotation hash reference.
sub _collector_rotation {
    my ( $self, $job ) = @_;
    my %rotation;
    if ( ref( $job->{rotation} ) eq 'HASH' ) {
        %rotation = ( %rotation, %{ $job->{rotation} } );
    }
    if ( ref( $job->{rotations} ) eq 'HASH' ) {
        %rotation = ( %rotation, %{ $job->{rotations} } );
    }
    return \%rotation;
}

# _state_root_is_stale($dir, $min_age_seconds)
# Checks whether one hashed runtime state root is old enough and no longer needed.
# Input: state root directory path and minimum-age integer.
# Output: boolean true when the state root should be removed.
sub _state_root_is_stale {
    my ( $self, $dir, $min_age_seconds ) = @_;
    return 0 if !$self->_path_is_old_enough( $dir, $min_age_seconds );
    return 0 if $self->_state_root_has_live_collectors($dir);

    my $metadata = $self->_read_state_metadata($dir);
    if ($metadata) {
        my $runtime_root = $metadata->{runtime_root} || '';
        return 1 if $runtime_root eq '' || !-d $runtime_root;
        return 0;
    }

    return 1;
}

# _state_root_has_live_collectors($dir)
# Checks whether one state root still tracks any live managed collector process.
# Input: state root directory path.
# Output: boolean true when a collector pidfile still points at a live process.
sub _state_root_has_live_collectors {
    my ( $self, $dir ) = @_;
    my $collectors_root = File::Spec->catdir( $dir, 'collectors' );
    return 0 if !-d $collectors_root;
    opendir my $dh, $collectors_root or die "Unable to read $collectors_root: $!";
    while ( my $entry = readdir $dh ) {
        next if $entry eq '.' || $entry eq '..';
        next if $entry !~ /\.pid\z/;
        my $pidfile = File::Spec->catfile( $collectors_root, $entry );
        next if !-f $pidfile;
        open my $fh, '<', $pidfile or die "Unable to read $pidfile: $!";
        my $pid = <$fh>;
        close $fh or die "Unable to close $pidfile: $!";
        chomp $pid if defined $pid;
        next if !defined $pid || $pid !~ /\A\d+\z/;
        if ( kill 0, $pid ) {
            closedir $dh;
            return 1;
        }
    }
    closedir $dh;
    return 0;
}

# _read_state_metadata($dir)
# Loads the runtime metadata recorded for one hashed state root.
# Input: state root directory path.
# Output: hash reference or undef when metadata is missing or unreadable.
sub _read_state_metadata {
    my ( $self, $dir ) = @_;
    my $file = File::Spec->catfile( $dir, 'runtime.json' );
    return if !-f $file;
    open my $fh, '<', $file or die "Unable to read $file: $!";
    local $/;
    my $raw = <$fh>;
    close $fh or die "Unable to close $file: $!";
    my $data = eval { json_decode($raw) };
    return if !$data || ref($data) ne 'HASH';
    return $data;
}

# _path_is_old_enough($path, $min_age_seconds)
# Checks whether one file-system path is older than the requested minimum age.
# Input: file or directory path plus minimum-age integer.
# Output: boolean true when the path age is at least the threshold.
sub _path_is_old_enough {
    my ( $self, $path, $min_age_seconds ) = @_;
    my @stat = stat($path);
    return 0 if !@stat;
    return ( time - $stat[9] ) >= $min_age_seconds ? 1 : 0;
}

# _remove_tree($path, $kind)
# Removes one stale directory tree and returns the summary payload.
# Input: directory path and removal kind string.
# Output: hash reference describing the removed path.
sub _remove_tree {
    my ( $self, $path, $kind ) = @_;
    my $errors = [];
    remove_tree( $path, { error => \$errors } );
    if ( @{$errors} && !$self->_only_missing_tree_errors($errors) ) {
        die "Unable to remove stale $kind $path\n";
    }
    return {
        kind => $kind,
        path => $path,
    };
}

# _only_missing_tree_errors($errors)
# Checks whether File::Path removal failures are only benign missing-path races.
# Input: File::Path error array reference.
# Output: boolean true when every reported error is an ENOENT-style missing-path race.
sub _only_missing_tree_errors {
    my ( $self, $errors ) = @_;
    return 1 if ref($errors) ne 'ARRAY' || !@{$errors};
    for my $entry ( @{$errors} ) {
        my ($message) = values %{ $entry || {} };
        return 0 if !defined $message || $message !~ /No such file or directory/;
    }
    return 1;
}

# _collector_store()
# Lazily constructs the collector storage helper for runtime housekeeping work.
# Input: none.
# Output: Developer::Dashboard::Collector object.
sub _collector_store {
    my ($self) = @_;
    return $self->{collector_store} ||= Developer::Dashboard::Collector->new( paths => $self->{paths} );
}

# _config()
# Lazily constructs the merged runtime config loader for housekeeping work.
# Input: none.
# Output: Developer::Dashboard::Config object.
sub _config {
    my ($self) = @_;
    return $self->{config} ||= Developer::Dashboard::Config->new(
        paths => $self->{paths},
        files => Developer::Dashboard::FileRegistry->new( paths => $self->{paths} ),
    );
}

# _now_iso8601()
# Returns the current UTC time in dashboard timestamp format.
# Input: none.
# Output: timestamp string.
sub _now_iso8601 {
    return strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime(time) );
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::Housekeeper - cleanup stale dashboard temp state

=head1 SYNOPSIS

  use Developer::Dashboard::Housekeeper;

  my $housekeeper = Developer::Dashboard::Housekeeper->new( paths => $paths );
  my $summary = $housekeeper->run;

=head1 DESCRIPTION

This module removes stale dashboard-owned temp artefacts from the shared temp
area. It currently targets hashed runtime state roots under
F</tmp/E<lt>userE<gt>/developer-dashboard/state/>, oversized Ajax payload temp
files created under F</tmp/>, file-backed runtime result payloads created
under F</tmp/dashboard-result-*>, and configured collector log transcripts
that exceed their declared retention windows.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module is the cleanup service for dashboard-owned temp artefacts. It keeps
the shared temp state area from filling up with dead runtime roots and removes
leftover oversized Ajax payload files plus stale runtime result temp files once
they are old enough to be considered abandoned. It also enforces configured
collector log retention through the same built-in housekeeper path.

=head1 WHY IT EXISTS

It exists because state was intentionally moved out of the persistent runtime
tree and into F</tmp/> so reboot cleanup could discard stale state safely.
Without a runtime-owned cleanup pass, repeated project-layer work and test runs
can still accumulate dead hashed state directories and orphaned temp payload
files between reboots, while collector transcript logs can also grow without a
separate retention pass.

=head1 WHEN TO USE

Use this file when changing temp-state layout, stale-state retention rules, or
the built-in cleanup command and collector that keep the shared temp area tidy,
including collector log rotation policy.

=head1 HOW TO USE

Construct it with the active path registry, then call C<run>. The result is a
hash reference that reports what was scanned and what was removed. Collector
definitions can add C<rotation> or C<rotations> with C<lines>,
C<minutes>/C<minute>, C<hours>/C<hour>, C<days>/C<day>, C<weeks>/C<week>, and
C<months>/C<month> retention values for housekeeper-managed transcript
rotation.

=head1 WHAT USES IT

It is used by the built-in C<dashboard housekeeper> command and by the built-in
C<housekeeper> collector job that runs through the normal collector runtime.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::Housekeeper -e 1

Compile-load the module directly from a source checkout.

Example 2:

  dashboard housekeeper

Run the built-in command path and print the JSON cleanup summary.

Example 3:

  dashboard collector run housekeeper

Run the built-in housekeeper collector through the collector runtime and store
its output like any other managed collector.

Example 4:

  prove -lv t/05-cli-smoke.t t/07-core-units.t

Recheck the focused CLI and unit regressions that cover this cleanup module and
its built-in command surface.


=for comment FULL-POD-DOC END

=cut
