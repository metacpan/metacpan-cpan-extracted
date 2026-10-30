package Developer::Dashboard::IndicatorStore;

use strict;
use warnings;
use utf8;

our $VERSION = '6.06';

use Developer::Dashboard::PathIdentity qw(current_working_directory);
use Fcntl qw(:flock);
use File::Spec;
use Time::HiRes qw(time);
use Errno qw(ENOENT ENOTDIR);

use Developer::Dashboard::JSON qw(json_encode json_decode);
use Developer::Dashboard::IndicatorStore::Watch;
use Developer::Dashboard::PathsRegistryArg qw(require_paths_arg);

my $STATUS_ICONS = {
    ok => {
        yes     => '&#x2705;',
        running => '&#x2705;',
        secure  => '&#x2705;',
        ok      => '&#x2705;',
        clean   => '&#x2705;',
    },
    error => {
        wrong     => '&#x1F6A8;',
        stopped   => '&#x1F6A8;',
        paused    => '&#x1F6A8;',
        insecure  => '&#x1F6A8;',
        reloading => '&#x1F6A8;',
        missing   => '&#x1F6A8;',
        error     => '&#x1F6A8;',
        dirty     => '&#x1F6A8;',
        down      => '&#x1F6A8;',
    },
};

my $PROMPT_STATUS_ICONS = {
    ok => {
        yes     => '✅',
        running => '✅',
        secure  => '✅',
        ok      => '✅',
        clean   => '✅',
    },
    error => {
        wrong     => '🚨',
        stopped   => '🚨',
        paused    => '🚨',
        insecure  => '🚨',
        reloading => '🚨',
        missing   => '🚨',
        error     => '🚨',
        dirty     => '🚨',
        down      => '🚨',
    },
};

# new(%args)
# Constructs the file-backed indicator store.
# Input: paths object.
# Output: Developer::Dashboard::IndicatorStore object.
sub new {
    my ( $class, %args ) = @_;
    my $paths = require_paths_arg(%args);
    return bless { paths => $paths }, $class;
}

# set_indicator($name, %data)
# Writes indicator state to the file-backed indicator store.
# Input: indicator name plus state fields such as label, icon, and status, and
# optional internal preserve fields used when config sync must not clobber a
# newer live status update. During collector sync, a write invalidates the
# matching request-local decoded-file entry.
# Output: saved indicator hash reference.
sub set_indicator {
    my ( $self, $name, %data ) = @_;
    my $dir  = $self->{paths}->indicator_dir($name);
    my $file = File::Spec->catfile( $dir, 'status.json' );
    my $lock = File::Spec->catfile( $dir, '.lock' );
    my $preserve_fields = delete $data{_preserve_existing_fields};
    my @preserve_existing = ref($preserve_fields) eq 'ARRAY' ? @{$preserve_fields} : ();

    open my $lock_fh, '>>', $lock or die "Unable to open $lock: $!";
    $self->_lock_indicator_file($lock_fh) or die "Unable to lock $lock: $!";
    my $existing = $self->_read_indicator_file($file) || {};

    for my $field (@preserve_existing) {
        next if !exists $existing->{$field};
        $data{$field} = $existing->{$field};
    }

    $data{name}       = $name;
    $data{updated_at} = time if !exists $data{updated_at};

    # DD-989: the staging path used to be the bare literal "$file.pending"
    # (no uniquifier at all) and permissions were secured only AFTER the
    # write, so a symlink pre-planted at that exact, fully predictable path
    # let a local actor clobber an arbitrary victim file - open('>:raw', ...)
    # follows the symlink and overwrites its target, and the subsequent
    # rename then moved the symlink itself on top of the real status.json.
    # atomic_write_secure (DD-610) closes both halves at once: it requires
    # an unpredictable per-writer $tmp (built here the same way DD-850
    # established for every other pending-file writer in this codebase -
    # pid + wall-clock time + a per-process monotonic counter) and it
    # secures that staging file's permissions BEFORE the rename, not after.
    my $tmp = $self->_pending_indicator_file($file);
    $self->{paths}->atomic_write_secure( $tmp, $file, json_encode( \%data ) );
    delete $self->{_indicator_sync_read_cache}{$file}
      if ref( $self->{_indicator_sync_read_cache} ) eq 'HASH';
    delete $self->{_indicator_file_bytes_cache}{$file}
      if ref( $self->{_indicator_file_bytes_cache} ) eq 'HASH';

    return \%data;
}

# _pending_indicator_file($file)
# Builds the per-writer staging path set_indicator() writes to before the
# atomic rename into $file. Its own sub (rather than an inline sprintf)
# exists so a coverage test can override it to a fixed, predictable path
# when it needs to pre-stage that exact location to force a write failure.
# DD-989/DD-850: pid+wall-clock-second alone is NOT collision-safe - the
# per-process monotonic counter below guarantees no two calls from one
# process ever collide, whatever the timing; cross-process collision
# remains prevented by pid uniqueness among live processes.
# Input: final destination file path string.
# Output: staging file path string.
my $_pending_indicator_file_seq = 0;

sub _pending_indicator_file {
    my ( $self, $file ) = @_;
    return sprintf '%s.%s.%s.%s.pending', $file, $$, time, ++$_pending_indicator_file_seq;
}

# get_indicator($name)
# Loads a single indicator state record.
# Input: indicator name string.
# Output: indicator hash reference or undef when missing.
sub get_indicator {
    my ( $self, $name ) = @_;
    my @roots = $self->{paths}->indicators_roots;
    return $self->_get_indicator_from_roots( $name, \@roots );
}

# _get_indicator_from_roots($name, $roots)
# Loads one indicator from a caller's already-discovered ordered state roots.
# Input: indicator name string and array reference of roots ordered deepest to home.
# Output: decoded indicator hash reference or undef when no candidate exists.
sub _get_indicator_from_roots {
    my ( $self, $name, $roots ) = @_;
    die "Indicator roots must be an array reference\n" if ref($roots) ne 'ARRAY';
    for my $root ( @{$roots} ) {
        my $file = File::Spec->catfile( $root, $name, 'status.json' );
        my $item = $self->_read_indicator_file($file);
        return $item if $item;
    }
    return;
}

# list_indicators()
# Lists all valid stored indicators ordered by prompt priority.
# Input: optional internal ordered roots array reference; when omitted, roots
# are discovered from the live PathRegistry.
# Output: sorted list of indicator hash references.
sub list_indicators {
    my ( $self, $roots ) = @_;
    my %items;
    my @roots = ref($roots) eq 'ARRAY' ? @{$roots} : $self->{paths}->indicators_roots;
    my @directory_inventory;
    for my $root (@roots) {
        next if !-d $root;
        opendir my $dh, $root or next;
        my @entries;
        while ( my $entry = readdir $dh ) {
            next if $entry eq '.' || $entry eq '..';
            push @entries, $entry;
            next if $items{$entry};
            my $item = eval { $self->_get_indicator_from_roots( $entry, \@roots ) };
            $items{$entry} = $item if $item;
        }
        closedir $dh;
        push @directory_inventory, [ $root, [ sort @entries ] ];
    }
    $self->{_indicator_sync_directory_inventory_current} = json_encode( \@directory_inventory )
      if exists $self->{_indicator_sync_directory_inventory_current};

    return $self->_sort_indicators( values %items );
}

# _sort_indicators($items)
# Sorts indicator records using the public prompt/page ordering contract. Small
# lists use the shared comparator; larger lists precompute compare fields to
# avoid repeated method dispatch and hash lookups inside Perl's sort loop.
# Input: indicator hash references as a list.
# Output: indicator hash references ordered by priority, collector order, name.
sub _sort_indicators {
    my ( $self, @items ) = @_;
    return sort { $self->_indicator_sort_cmp( $a, $b ) } @items if @items < 32;

    my @decorated = map {
        my $item = $_;
        [
            $item,
            ( defined $item->{priority} ? $item->{priority} : 999 ),
            ( $item->{managed_by_collector} || 0 ) ? 1 : 0,
            ( defined $item->{collector_order} ? $item->{collector_order} : 999 ),
            ( $item->{name} || '' ),
        ];
    } @items;

    return map { $_->[0] }
      sort { _indicator_sort_order_cmp( $a, $b ) } @decorated;
}

# _indicator_sort_order_cmp($left, $right)
# Compares decorated indicator tuples without object dispatch or hash access.
# Input: two arrays [record, priority, collector flag, collector order, name].
# Output: negative, zero, or positive integer suitable for Perl sort.
sub _indicator_sort_order_cmp {
    my ( $left, $right ) = @_;
    my $priority_order = $left->[1] <=> $right->[1];
    return $priority_order if $priority_order;

    if ( $left->[2] && $right->[2] ) {
        my $collector_order = $left->[3] <=> $right->[3];
        return $collector_order if $collector_order;
    }

    return $left->[4] cmp $right->[4];
}

# sync_collectors($jobs, %opts)
# Seeds or refreshes indicator records declared by collector config without
# clobbering live status from previous collector runs.
# Callers may request the final inventory so it can be rendered without a
# second read of the same status files.
# Input: array reference of collector job hash references and optional
# return_indicators, return_unchanged, and
# skip_indicators_if_unchanged booleans, and an optional canonical
# collector_jobs_signature from a config snapshot already validated by its
# watcher.
# Output: written indicator array reference, or a hash reference containing
# written and indicators array references when return_indicators is true. Each
# call shares one roots snapshot and decoded-file cache, discarded on return so
# later calls observe filesystem changes. With return_unchanged, the inventory
# result also reports whether it came from the validated stable-sync fast path.
sub sync_collectors {
    my ( $self, $jobs, %opts ) = @_;
    my $return_indicators = $opts{return_indicators} ? 1 : 0;
    my $return_unchanged = $opts{return_unchanged} ? 1 : 0;
    my $skip_indicators_if_unchanged = $opts{skip_indicators_if_unchanged} ? 1 : 0;
    if ( ref($jobs) ne 'ARRAY' || scalar(@$jobs) == 0 ) {
        return [] if !$return_indicators;
        return { written => [], indicators => [ $self->list_indicators ] };
    }

    # Decoded records live for one sync only. Raw JSON bytes may be reused across
    # syncs only while high-resolution file metadata and the directory inventory agree.
    local $self->{_indicator_sync_read_cache} = {};
    local $self->{_indicator_sync_persistent_read} = 1;
    local $self->{_indicator_sync_file_changed} = 0;
    local $self->{_indicator_sync_directory_inventory_current};
    my @indicator_roots = $self->{paths}->indicators_roots;
    my $jobs_signature;
    if ( exists $opts{collector_jobs_signature} ) {
        die "collector_jobs_signature must be a non-empty scalar\n"
          if !defined $opts{collector_jobs_signature}
          || ref( $opts{collector_jobs_signature} )
          || $opts{collector_jobs_signature} eq '';
        $jobs_signature = $opts{collector_jobs_signature};
    }
    else {
        $jobs_signature = json_encode($jobs);
    }
    my $config_signature = json_encode( { jobs_signature => $jobs_signature, roots => \@indicator_roots } );

    if ( defined $self->{_collector_sync_config_signature}
        && $self->{_collector_sync_config_signature} eq $config_signature )
    {
        if ( $return_indicators && $return_unchanged && $skip_indicators_if_unchanged ) {
            if ( $self->_collector_sync_files_unchanged( \@indicator_roots, $jobs ) ) {
                return { written => [], unchanged => 1 };
            }
        }
        else {
            my @cached_indicators = $self->list_indicators( \@indicator_roots );
            my $inventory_matches = defined $self->{_indicator_sync_directory_inventory_current}
              && defined $self->{_indicator_sync_directory_inventory_signature}
              && $self->{_indicator_sync_directory_inventory_current}
              eq $self->{_indicator_sync_directory_inventory_signature};
            my %present = map { ( $_->{name} || '' ) => 1 } grep { ref($_) eq 'HASH' } @cached_indicators;
            my $all_active_indicators_present = 1;
            for my $job ( @{$jobs} ) {
                next if ref($job) ne 'HASH';
                next if ref( $job->{indicator} ) ne 'HASH';
                next if !defined $job->{name} || $job->{name} eq '' || $job->{disable};
                my $name = $job->{indicator}{name};
                $name = $job->{name} if !$name;
                if ( !$present{$name} ) {
                    $all_active_indicators_present = 0;
                    last;
                }
            }

            if (
                _collector_inventory_is_unchanged(
                    $inventory_matches,
                    $self->{_indicator_sync_file_changed},
                    $all_active_indicators_present,
                )
              )
            {
                return [] if !$return_indicators;
                my $result = { written => [], indicators => \@cached_indicators };
                $result->{unchanged} = 1 if $return_unchanged;
                return $result;
            }
        }
    }

    my @written;
    my %active_collectors;
    my $collector_order = 0;
    for my $job ( @{$jobs} ) {
        next if ref($job) ne 'HASH';
        next if ref( $job->{indicator} ) ne 'HASH';
        next if !defined $job->{name} || $job->{name} eq '';
        next if $job->{disable};

        $active_collectors{ $job->{name} } = 1;
        my $plan = $self->_collector_sync_plan(
            $job,
            collector_order => $collector_order,
            indicator_roots => \@indicator_roots,
        );
        if ( $plan->{needs_write} ) {
            my $candidate = $plan->{candidate};
            push @written, $self->set_indicator(
                $candidate->{name},
                %{$candidate},
                _preserve_existing_fields => $plan->{preserve_existing},
            );
        }
        $collector_order++;
    }

    my @current_indicators = $self->list_indicators( \@indicator_roots );
    my $deleted_indicator  = 0;
    for my $indicator (@current_indicators) {
        next if ref($indicator) ne 'HASH';
        next if !$indicator->{managed_by_collector};
        my $collector_name = $indicator->{collector_name} || '';
        next if $collector_name eq '';
        next if $active_collectors{$collector_name};
        $self->delete_indicator( $indicator->{name}, \@indicator_roots );
        $deleted_indicator = 1;
        push @written, { %{$indicator}, deleted => 1 };
    }

    if ($return_indicators) {
        @current_indicators = $self->list_indicators( \@indicator_roots ) if $deleted_indicator;
        $self->{_collector_sync_config_signature} = $config_signature;
        $self->{_indicator_sync_directory_inventory_signature}
          = $self->{_indicator_sync_directory_inventory_current};
        $self->_configure_indicator_sync_watcher( \@indicator_roots, $jobs );
        my $result = { written => \@written, indicators => \@current_indicators };
        $result->{unchanged} = 0 if $return_unchanged;
        return $result;
    }
    $self->{_collector_sync_config_signature} = $config_signature;
    $self->{_indicator_sync_directory_inventory_signature}
      = $self->{_indicator_sync_directory_inventory_current};
    $self->_configure_indicator_sync_watcher( \@indicator_roots, $jobs );
    return \@written;
}

# _collector_inventory_is_unchanged($inventory_matches, $file_changed, $all_active_present)
# Decides whether the cached collector inventory is safe to return without a
# reconciliation pass. Kept as a named predicate so each safety input can be
# independently tested, including combinations that the filesystem makes rare.
# Input: booleans describing directory inventory equality, status-file changes,
#        and presence of every active collector indicator.
# Output: true only when inventory matches, no file changed, and all active
#         indicator records are present.
sub _collector_inventory_is_unchanged {
    my ( $inventory_matches, $file_changed, $all_active_present ) = @_;
    return $inventory_matches && !$file_changed && $all_active_present ? 1 : 0;
}

# _collector_sync_files_unchanged($roots, $jobs)
# Validates the previously listed indicator directories and chosen status files
# using names and file signatures only, avoiding JSON decoding when an internal
# caller already has a validated serialized response to reuse. It reuses path
# strings only for an exact ordered-root and directory-inventory match. A
# matching, event-free watcher can skip this portable revalidation.
# Input: indicator roots in lookup order and the normalized collector jobs.
# Optional named skip_watcher boolean forces portable validation while a new
# watcher snapshot is being established.
# Output: true only when directory inventory, cached file signatures, and every
#        active collector's effective indicator file are unchanged.
sub _collector_sync_files_unchanged {
    my ( $self, $roots, $jobs, %opts ) = @_;
    return 0 if ref($roots) ne 'ARRAY' || ref($jobs) ne 'ARRAY';
    return 0 if !defined $self->{_indicator_sync_directory_inventory_signature};

    if ( !$opts{skip_watcher} ) {
        my $watcher = $self->_indicator_sync_watcher;
        if ($watcher) {
            my $root_signature = join "\0", @{$roots};
            return 0
              if !defined $self->{_indicator_sync_watcher_roots_signature}
              || $self->{_indicator_sync_watcher_roots_signature} ne $root_signature;
            return 1
              if defined $self->{_indicator_sync_watcher_signature}
              && $watcher->unchanged( $self->{_indicator_sync_watcher_signature} );
            if ( defined $watcher->last_error ) {
                $self->_disable_indicator_sync_watcher($watcher);
            }
        }
    }

    my @directory_inventory;
    my %inventory_names;
    for my $root ( @{$roots} ) {
        next if !-d $root;
        opendir my $dh, $root or return 0;
        my @entries;
        $! = 0;
        while ( my $entry = readdir $dh ) {
            next if $entry eq '.' || $entry eq '..';
            push @entries, $entry;
            $inventory_names{$entry} = 1;
        }
        if ($!) {
            closedir $dh or die "Unable to close indicator directory '$root': $!";
            return 0;
        }
        closedir $dh or die "Unable to close indicator directory '$root': $!";
        push @directory_inventory, [ $root, [ sort @entries ] ];
    }

    my $current_inventory_signature = json_encode( \@directory_inventory );
    $self->{_indicator_sync_directory_inventory_current} = $current_inventory_signature
      if exists $self->{_indicator_sync_directory_inventory_current};
    return 0 if $current_inventory_signature ne $self->{_indicator_sync_directory_inventory_signature};

    my $status_paths_signature = json_encode( { roots => $roots, inventory => $current_inventory_signature } );
    my $status_paths_cache = $self->{_indicator_status_paths_cache};
    if ( ref($status_paths_cache) ne 'HASH'
        || !defined $status_paths_cache->{cache_signature}
        || $status_paths_cache->{cache_signature} ne $status_paths_signature
        || ref( $status_paths_cache->{paths_by_name} ) ne 'HASH' )
    {
        my %paths_by_name;
        for my $name ( keys %inventory_names ) {
            $paths_by_name{$name} = [ map { File::Spec->catfile( $_, $name, 'status.json' ) } @{$roots} ];
        }
        $status_paths_cache = {
            cache_signature => $status_paths_signature,
            paths_by_name   => \%paths_by_name,
        };
        $self->{_indicator_status_paths_cache} = $status_paths_cache;
    }

    my $persistent = $self->{_indicator_file_bytes_cache};
    return 0 if ref($persistent) ne 'HASH';
    for my $file ( keys %{$persistent} ) {
        my $cached = $persistent->{$file};
        return 0 if ref($cached) ne 'HASH' || !defined $cached->{signature};
        my $current_signature = $self->_indicator_file_signature($file);
        if ( $current_signature ne $cached->{signature} ) {
            $self->{_indicator_sync_file_changed} = 1
              if exists $self->{_indicator_sync_file_changed};
            return 0;
        }
    }

    my %status_file_exists_by_name;
    for my $name ( keys %inventory_names ) {
        my $files = $status_paths_cache->{paths_by_name}{$name};
        return 0 if ref($files) ne 'ARRAY';
        for my $file ( @{$files} ) {
            return 0 if !exists $persistent->{$file};
            if ( $persistent->{$file}{signature} ne 'missing' ) {
                $status_file_exists_by_name{$name} = 1;
                last;
            }
        }
    }

    for my $job ( @{$jobs} ) {
        next if ref($job) ne 'HASH';
        next if ref( $job->{indicator} ) ne 'HASH';
        next if !defined $job->{name} || $job->{name} eq '' || $job->{disable};
        my $name = $job->{indicator}{name};
        $name = $job->{name} if !$name;
        return 0 if !$status_file_exists_by_name{$name};
    }

    return 1;
}

# _indicator_sync_watcher()
# Returns the store's optional native watcher, constructing it at most once.
# Missing FFI or an unsupported platform is memoized as an unavailable backend.
# Input: none.
# Output: watcher object or undef when native filesystem events are unavailable.
sub _indicator_sync_watcher {
    my ($self) = @_;
    return $self->{_indicator_sync_watcher}
      if ref( $self->{_indicator_sync_watcher} );
    return if $self->{_indicator_sync_watcher_unavailable};
    my $watcher = Developer::Dashboard::IndicatorStore::Watch->new;
    if ( !$watcher ) {
        $self->{_indicator_sync_watcher_unavailable} = 1;
        return;
    }
    $self->{_indicator_sync_watcher} = $watcher;
    return $watcher;
}

# _configure_indicator_sync_watcher($roots, $jobs)
# Establishes directory watches after a full reconciliation, then runs the
# portable validator once to protect the scan-to-watch boundary from mutations.
# Input: ordered indicator roots and normalized collector job array reference.
# Output: true when a stable watch snapshot is ready, false when watching is
#         unavailable or a new full scan is required.
sub _configure_indicator_sync_watcher {
    my ( $self, $roots, $jobs ) = @_;
    return 0 if ref($roots) ne 'ARRAY' || ref($jobs) ne 'ARRAY';
    return 0 if !defined $self->{_indicator_sync_directory_inventory_signature};
    my $watcher = $self->_indicator_sync_watcher or return 0;
    my $inventory = json_decode( $self->{_indicator_sync_directory_inventory_signature} );
    die "Indicator directory inventory is not an array reference\n" if ref($inventory) ne 'ARRAY';

    my @watch_paths;
    for my $entry (@{$inventory}) {
        next if ref($entry) ne 'ARRAY' || !defined $entry->[0] || ref( $entry->[1] ) ne 'ARRAY';
        my ( $root, $names ) = @{$entry};
        push @watch_paths, $root;
        for my $name ( @{$names} ) {
            next if !defined $name || ref($name) || $name eq '';
            my $directory = File::Spec->catdir( $root, $name );
            push @watch_paths, $directory if -d $directory;
        }
    }

    my $watch_signature = json_encode(
        {
            roots     => $roots,
            inventory => $self->{_indicator_sync_directory_inventory_signature},
        }
    );
    if ( !$watcher->configure( $watch_signature, \@watch_paths ) ) {
        my $reason = $watcher->last_error || 'watch backend rejected the inventory';
        $self->_disable_indicator_sync_watcher( $watcher, $reason );
        return 0;
    }
    $self->{_indicator_sync_watcher_signature} = $watch_signature;
    $self->{_indicator_sync_watcher_roots_signature} = join "\0", @{$roots};

    return 1 if $self->_collector_sync_files_unchanged( $roots, $jobs, skip_watcher => 1 );
    $watcher->close;
    delete $self->{_indicator_sync_watcher_signature};
    delete $self->{_indicator_sync_watcher_roots_signature};
    return 0;
}

# _disable_indicator_sync_watcher($watcher, $reason)
# Emits a watcher failure before clearing the optional backend and returning all
# future syncs to the already-tested portable metadata validator.
# Input: watcher object and optional explicit failure reason.
# Output: undef; the store memoizes that this optional backend was disabled.
sub _disable_indicator_sync_watcher {
    my ( $self, $watcher, $reason ) = @_;
    if ( !$reason ) {
        my $watch_error = $watcher->last_error;
        $reason = defined $watch_error && $watch_error ne ''
          ? $watch_error
          : 'unknown filesystem watch error';
    }
    warn "IndicatorStore optional filesystem watcher disabled: $reason\n";
    $watcher->close;
    delete $self->{_indicator_sync_watcher};
    delete $self->{_indicator_sync_watcher_signature};
    delete $self->{_indicator_sync_watcher_roots_signature};
    $self->{_indicator_sync_watcher_unavailable} = 1;
    return;
}

# collectors_need_sync($jobs)
# Checks whether collector-declared indicators differ from persisted state so
# prompt helpers can skip the full sync path when nothing changed.
# Input: array reference of collector job hash references.
# Output: boolean true when sync_collectors would write or delete anything.
sub collectors_need_sync {
    my ( $self, $jobs ) = @_;
    $jobs = [] if ref($jobs) ne 'ARRAY';

    my %active_collectors;
    my $collector_order = 0;
    for my $job ( @{$jobs} ) {
        next if ref($job) ne 'HASH';
        next if ref( $job->{indicator} ) ne 'HASH';
        next if !defined $job->{name} || $job->{name} eq '';
        next if $job->{disable};

        $active_collectors{ $job->{name} } = 1;
        my $plan = $self->_collector_sync_plan( $job, collector_order => $collector_order );
        return 1 if $plan->{needs_write};
        $collector_order++;
    }

    for my $indicator ( $self->list_indicators ) {
        next if ref($indicator) ne 'HASH';
        next if !$indicator->{managed_by_collector};
        my $collector_name = $indicator->{collector_name} || '';
        next if $collector_name eq '';
        return 1 if !$active_collectors{$collector_name};
    }

    return 0;
}

# collector_indicator_candidate($job, %opts)
# Normalizes one collector-managed indicator payload from config plus optional
# existing live state.
# Input: collector job hash reference plus optional existing indicator hash and
# explicit status override.
# Output: normalized indicator hash reference ready for persistence.
sub collector_indicator_candidate {
    my ( $self, $job, %opts ) = @_;
    die 'Collector indicator candidate requires a collector job hash'
      if ref($job) ne 'HASH';
    die 'Collector indicator candidate requires a collector name'
      if !defined $job->{name} || $job->{name} eq '';

    my $indicator = ref( $job->{indicator} ) eq 'HASH' ? $job->{indicator} : {};
    my $name = $indicator->{name} ? $indicator->{name} : $job->{name};
    my $existing = ref( $opts{existing} ) eq 'HASH'
      ? $opts{existing}
      : eval { $self->get_indicator($name) } || {};
    my $label = defined $indicator->{label} && $indicator->{label} ne ''
      ? $indicator->{label}
      : $name;

    my %candidate = (
        %{$existing},
        %{$indicator},
        name                 => $name,
        label                => $label,
        configured_label     => $label,
        configured_alias     => exists $indicator->{alias} ? ( defined $indicator->{alias} ? $indicator->{alias} : '' ) : '',
        configured_page_status_icon => exists $indicator->{page_status_icon}
          ? ( defined $indicator->{page_status_icon} ? $indicator->{page_status_icon} : '' )
          : '',
        status               => exists $opts{status}
          ? $opts{status}
          : defined $existing->{status} && $existing->{status} ne ''
          ? $existing->{status}
          : 'missing',
        collector_order      => defined $opts{collector_order}
          ? $opts{collector_order}
          : exists $existing->{collector_order}
          ? $existing->{collector_order}
          : undef,
        collector_name       => $job->{name},
        managed_by_collector => 1,
        prompt_visible       => exists $indicator->{prompt_visible}
          ? $indicator->{prompt_visible}
          : exists $existing->{prompt_visible}
          ? $existing->{prompt_visible}
          : 1,
    );

    if ( $self->_is_template_toolkit_text( $indicator->{icon} ) ) {
        my $preserved_icon = '';
        if (
            defined $existing->{icon_template}
            && $existing->{icon_template} eq $indicator->{icon}
            && defined $existing->{icon}
        ) {
            $preserved_icon = $existing->{icon};
        }
        $candidate{icon_template} = $indicator->{icon};
        $candidate{configured_icon} = $indicator->{icon};
        $candidate{icon}          = $preserved_icon;
    }
    else {
        delete $candidate{icon_template};
        $candidate{configured_icon} = exists $indicator->{icon}
          ? ( defined $indicator->{icon} ? $indicator->{icon} : '' )
          : '';
        if ( exists $indicator->{icon} ) {
            $candidate{icon} = defined $indicator->{icon} ? $indicator->{icon} : '';
        }
        else {
            delete $candidate{icon};
        }
    }

    return \%candidate;
}

# delete_indicator($name)
# Removes one persisted indicator record and its directory when present.
# Input: indicator name string and optional ordered roots array reference.
# Output: true when cleanup completes; invalidates matching request-local cache
# entries when called during collector synchronization.
sub delete_indicator {
    my ( $self, $name, $roots ) = @_;
    return 1 if !defined $name || $name eq '';
    my @roots = ref($roots) eq 'ARRAY' ? @{$roots} : $self->{paths}->indicators_roots;
    for my $dir ( map { File::Spec->catdir( $_, $name ) } @roots ) {
        my $file = File::Spec->catfile( $dir, 'status.json' );
        unlink $file if -f $file;
        rmdir $dir if -d $dir;
        delete $self->{_indicator_sync_read_cache}{$file}
          if ref( $self->{_indicator_sync_read_cache} ) eq 'HASH';
        delete $self->{_indicator_file_bytes_cache}{$file}
          if ref( $self->{_indicator_file_bytes_cache} ) eq 'HASH';
    }
    return 1;
}

# _indicator_file_candidates($name)
# Returns candidate indicator status files across every runtime layer in lookup
# order from deepest to home.
# Input: indicator name string and optional ordered roots array reference.
# Output: ordered list of file path strings.
sub _indicator_file_candidates {
    my ( $self, $name, $roots ) = @_;
    my @roots = ref($roots) eq 'ARRAY' ? @{$roots} : $self->{paths}->indicators_roots;
    return map { File::Spec->catfile( $_, $name, 'status.json' ) } @roots;
}

# mark_stale($name, %opts)
# Marks a stored indicator as stale for prompt/dashboard display.
# Input: indicator name and optional replacement status.
# Output: updated indicator hash reference or undef when missing.
sub mark_stale {
    my ( $self, $name, %opts ) = @_;
    my $item = $self->get_indicator($name) || return;
    $item->{stale} = 1;
    $item->{status} = $opts{status} if defined $opts{status};
    return $self->set_indicator( $name, %$item );
}

# is_stale($item, %opts)
# Checks whether an indicator should be treated as stale.
# Input: indicator hash reference and optional max_age threshold.
# Output: boolean stale flag.
sub is_stale {
    my ( $self, $item, %opts ) = @_;
    return if ref($item) ne 'HASH';
    return 1 if $item->{stale};
    my $max_age = defined $opts{max_age} ? $opts{max_age} : 300;
    return if !$item->{updated_at};
    return ( time - $item->{updated_at} ) > $max_age ? 1 : 0;
}

# refresh_core_indicators(%args)
# Refreshes project/Git core status and retires obsolete built-in Docker state.
# Input: optional cwd to resolve project-related state.
# Output: array reference of updated project/Git indicator records; never a
#        Docker indicator.
sub refresh_core_indicators {
    my ( $self, %args ) = @_;
    # A QUERY MUST NOT DECIDE ITS CALLER'S EXIT STATUS (DD-589, same shape as
    # DD-585's fix in CollectorRunner.pm). The git rev-parse/diff calls below
    # read $? into their own return values, but without this guard the raw,
    # unshifted $? from whichever ran last stays set in the caller's process
    # after this sub returns - and this sub is called from share/private-cli/ps1
    # and _dashboard-core, so that pollution is live in the 'dashboard ps1'
    # process, not merely theoretical. `local` restores the caller's $? on
    # return regardless of how many system() calls run inside.
    local $?;
    my $prompt_only = $args{prompt_only} ? 1 : 0;
    my $cwd   = $args{cwd} || $self->{paths}->current_project_root;
    $cwd = $self->{paths}->home if !$cwd;
    my $items = [];
    $self->_remove_legacy_core_docker_indicator;
    return $items if $prompt_only;
    require Capture::Tiny;

    my $project = $self->{paths}->project_root_for($cwd);
    push @$items, $self->_set_indicator_if_changed(
        'project',
        label          => $project || '(no-project)',
        icon           => 'P',
        status         => $project ? 'ok' : 'none',
        priority       => 50,
        prompt_visible => 0,
    );

    my $git_status = 'none';
    if ($project) {
        my $old = current_working_directory();
        chdir $project or die "Unable to chdir to $project: $!";
        # DD-607: the git status probe runs inside an eval so a die anywhere
        # in it (including one raised by capture() itself) still restores cwd
        # before propagating, instead of leaving the process stuck in
        # $project. Mirrors the eval-wrapped risky-work pattern already used
        # around chdir/restore pairs in CollectorRunner.pm's _run_command and
        # _run_code.
        my $status_result = eval {
            my ( $stdout, $stderr, $inside_exit ) = Capture::Tiny::capture( sub {
                system( 'git', 'rev-parse', '--is-inside-work-tree' );
                return $? >> 8;
            } );
            my $inside_work_tree = $inside_exit == 0 && $stdout =~ /^\s*true\s*$/m ? 1 : 0;
            my $status = 'none';
            if ($inside_work_tree) {
                my ( undef, undef, $dirty_exit ) = Capture::Tiny::capture( sub {
                    system( 'git', 'diff', '--quiet', '--ignore-submodules', 'HEAD', '--' );
                    return $? >> 8;
                } );
                # git diff --quiet exits 0 for a clean tree and 1 for a modified
                # one; any other exit (for example 128) is a real git failure, not a
                # dirty work tree, so surface it as an explicit error status.
                $status =
                    $dirty_exit == 0 ? 'clean'
                  : $dirty_exit == 1 ? 'dirty'
                  :                    'error';
            }
            return $status;
        };
        my $status_error = $@;
        chdir $old or die "Unable to restore cwd to $old: $!";
        die $status_error if $status_error;
        $git_status = $status_result;
    }
    push @$items, $self->_set_indicator_if_changed(
        'git',
        label          => $git_status eq 'dirty' ? 'Git*' : 'Git',
        icon           => 'G',
        status         => $git_status,
        priority       => 30,
        prompt_visible => 0,
    );

    return $items;
}

# _remove_legacy_core_docker_indicator()
# Removes only persisted records matching the retired built-in Docker indicator,
# leaving collector-owned or user-customized indicators named docker intact.
# Input: none.
# Output: true after all matching records across the active runtime layers are removed.
sub _remove_legacy_core_docker_indicator {
    my ($self) = @_;
    for my $file ( $self->_indicator_file_candidates('docker') ) {
        next if !-f $file;
        my ( $volume, $directory ) = File::Spec->splitpath($file);
        my $lock = File::Spec->catpath( $volume, $directory, '.lock' );
        open my $lock_fh, '>>', $lock or die "Unable to open $lock: $!";
        $self->_lock_indicator_file($lock_fh) or die "Unable to lock $lock: $!";
        my $indicator = $self->_read_indicator_file($file);
        next if !$self->_is_legacy_core_docker_indicator($indicator);
        unlink $file or die "Unable to remove retired built-in Docker indicator $file: $!";
    }
    return 1;
}

# _lock_indicator_file($handle)
# Serializes status writers and legacy cleanup using their shared lock file.
# Input: open indicator lock handle.
# Output: flock success boolean; callers expose any failure with the lock path.
sub _lock_indicator_file {
    my ( $self, $handle ) = @_;
    return flock( $handle, LOCK_EX );
}

# _is_legacy_core_docker_indicator($indicator)
# Identifies the exact persisted shape written by older core refreshes, without
# treating collector-owned or customized Docker-named indicators as built-ins.
# Input: decoded indicator value.
# Output: boolean true only for a legacy core Docker record.
sub _is_legacy_core_docker_indicator {
    my ( $self, $indicator ) = @_;
    return 0 if ref($indicator) ne 'HASH';
    return 0 if $indicator->{managed_by_collector};
    my %expected = (
        name          => 'docker',
        label         => 'Docker',
        alias         => '🐳',
        icon          => '🐳',
        priority      => 20,
        prompt_visible => 1,
    );
    for my $field ( keys %expected ) {
        return 0 if !defined $indicator->{$field};
        return 0 if $indicator->{$field} ne $expected{$field};
    }
    return 0 if ( $indicator->{page_status_icon} || '' ) !~ /\A(?:&#x1F7E2;|&#x1F534;)\z/;
    return 0 if grep { exists $indicator->{$_} } qw(collector_name configured_label configured_alias configured_icon);
    return 1;
}

# _set_indicator_if_changed($name, %data)
# Writes one indicator only when the persisted state differs from the incoming
# payload so prompt refreshes do not rewrite stable status files.
# Input: indicator name plus indicator data fields.
# Output: saved indicator hash reference or the unchanged existing indicator.
sub _set_indicator_if_changed {
    my ( $self, $name, %data ) = @_;
    my $existing = $self->get_indicator($name);
    return $existing if ref($existing) eq 'HASH' && $self->_indicator_matches( $existing, { %data, name => $name } );
    return $self->set_indicator( $name, %data );
}

# page_header_items($indicators)
# Builds the older top-of-page status payload from stored indicators.
# Input: optional array reference of already-loaded indicator records.
# Output: list of hashes with prog, alias, and status fields.
sub page_header_items {
    my ( $self, $indicators ) = @_;
    my @items;
    my @indicators = ref($indicators) eq 'ARRAY' ? @{$indicators} : $self->list_indicators;
    for my $indicator (@indicators) {
        next if exists $indicator->{prompt_visible} && !$indicator->{prompt_visible};
        my $alias = defined $indicator->{alias} && $indicator->{alias} ne ''
          ? $indicator->{alias}
          : defined $indicator->{icon} && $indicator->{icon} ne ''
          ? $indicator->{icon}
          : defined $indicator->{label} && $indicator->{label} ne ''
          ? $indicator->{label}
          : $indicator->{name};
        push @items, {
            prog   => $indicator->{name},
            alias  => $alias,
            status => $self->_page_status_icon($indicator),
        };
    }
    return @items;
}

# page_header_payload(%args)
# Builds the older `/system/status` response payload shape.
# Input: optional indicators array reference returned by sync_collectors.
# Output: hash reference with array, hash, and status maps.
sub page_header_payload {
    my ( $self, %args ) = @_;
    my @array = $self->page_header_items( $args{indicators} );
    my %hash  = map { $_->{prog} => { %$_ } } @array;
    return {
        array  => \@array,
        hash   => \%hash,
        status => $STATUS_ICONS,
    };
}

# prompt_status_icon($indicator)
# Resolves the prompt status glyph for one indicator record.
# Input: indicator hash reference.
# Output: plain-text status glyph or empty string.
sub prompt_status_icon {
    my ( $self, $indicator ) = @_;
    return $self->_status_icon_for( $indicator, $PROMPT_STATUS_ICONS );
}

# _page_status_icon($indicator)
# Resolves the page-header status icon for one indicator record.
# Input: indicator hash reference.
# Output: HTML entity or plain icon string.
sub _page_status_icon {
    my ( $self, $indicator ) = @_;
    return '' if ref($indicator) ne 'HASH';
    return $indicator->{page_status_icon} if defined $indicator->{page_status_icon} && $indicator->{page_status_icon} ne '';
    return $self->_status_icon_for( $indicator, $STATUS_ICONS );
}

# _indicator_matches($existing, $candidate)
# Compares persisted and candidate indicator fields to avoid rewriting files on
# every dashboard prompt render.
# Input: existing and candidate indicator hash references.
# Output: boolean true when the stored record already matches.
sub _indicator_matches {
    my ( $self, $existing, $candidate ) = @_;
    return 0 if ref($existing) ne 'HASH' || ref($candidate) ne 'HASH';
    for my $key ( qw(name label alias icon icon_template configured_label configured_alias configured_icon configured_page_status_icon status priority prompt_visible page_status_icon collector_name collector_order managed_by_collector) ) {
        next if $key eq 'collector_order' && ( !exists $existing->{$key} || !defined $existing->{$key} || $existing->{$key} eq '' );
        my $left  = exists $existing->{$key}  ? $existing->{$key}  : undef;
        my $right = exists $candidate->{$key} ? $candidate->{$key} : undef;
        $left  = '' if !defined $left;
        $right = '' if !defined $right;
        return 0 if $left ne $right;
    }
    return 1;
}

# _collector_sync_plan($job, %opts)
# Builds the normalized collector indicator comparison payload used by sync and
# prompt fast-path checks.
# Input: collector job hash reference plus collector_order.
# Output: hash reference with needs_write, candidate, and comparison fields.
sub _collector_sync_plan {
    my ( $self, $job, %opts ) = @_;
    my $indicator_name = $job->{indicator}{name} || $job->{name};
    my $roots = ref( $opts{indicator_roots} ) eq 'ARRAY' ? $opts{indicator_roots} : undef;
    my $existing = $roots
      ? eval { $self->_get_indicator_from_roots( $indicator_name, $roots ) } || {}
      : eval { $self->get_indicator($indicator_name) } || {};
    my $local_existing = $roots && @{$roots} == 1
      ? $existing
      : $self->_local_indicator( $indicator_name, $roots ) || {};
    my $effective_existing = $existing;
    my $healed_from_inherited = 0;
    if (
        %{ $local_existing }
        && $self->_is_placeholder_missing_indicator($local_existing)
    ) {
        my $inherited = $roots && @{$roots} < 2
          ? undef
          : $self->_nearest_inherited_indicator( $indicator_name, $roots );
        if (
            ref($inherited) eq 'HASH'
            && %{ $inherited }
            && ( $inherited->{managed_by_collector} || 0 )
            && ( $inherited->{collector_name} || '' ) eq $job->{name}
            && !$self->_is_placeholder_missing_indicator($inherited)
        ) {
            $effective_existing = $inherited;
            $healed_from_inherited = 1;
        }
    }
    my $candidate = $self->collector_indicator_candidate(
        $job,
        collector_order => $opts{collector_order},
        existing => $effective_existing,
        status   => defined $effective_existing->{status} && $effective_existing->{status} ne '' ? $effective_existing->{status} : 'missing',
    );
    my $comparison_existing = %{ $local_existing }
      ? $local_existing
      : $existing;
    my @preserve_existing = $healed_from_inherited ? () : qw(status updated_at stale);
    if (
        ( $effective_existing->{managed_by_collector} || 0 )
        && ( $effective_existing->{collector_name} || '' ) eq $job->{name}
        && !$self->_is_placeholder_missing_indicator($effective_existing)
    ) {
        if (
            exists $effective_existing->{configured_label}
            && ( defined $effective_existing->{configured_label} ? $effective_existing->{configured_label} : '' )
                eq $candidate->{configured_label}
            && ( defined $effective_existing->{label} ? $effective_existing->{label} : '' ) ne $candidate->{configured_label}
        ) {
            push @preserve_existing, 'label';
        }
        if (
            exists $effective_existing->{configured_alias}
            && ( defined $effective_existing->{configured_alias} ? $effective_existing->{configured_alias} : '' )
                eq $candidate->{configured_alias}
            && ( defined $effective_existing->{alias} ? $effective_existing->{alias} : '' ) ne $candidate->{configured_alias}
        ) {
            push @preserve_existing, 'alias';
        }
        if (
            exists $effective_existing->{configured_page_status_icon}
            && ( defined $effective_existing->{configured_page_status_icon} ? $effective_existing->{configured_page_status_icon} : '' )
                eq $candidate->{configured_page_status_icon}
            && ( defined $effective_existing->{page_status_icon} ? $effective_existing->{page_status_icon} : '' ) ne $candidate->{configured_page_status_icon}
        ) {
            push @preserve_existing, 'page_status_icon';
        }
        if (
            exists $effective_existing->{configured_icon}
            && ( defined $effective_existing->{configured_icon} ? $effective_existing->{configured_icon} : '' )
                eq $candidate->{configured_icon}
            && ( defined $effective_existing->{icon} ? $effective_existing->{icon} : '' ) ne $candidate->{configured_icon}
        ) {
            push @preserve_existing, 'icon';
        }
    }
    if (
        defined $candidate->{icon_template}
        # redundant "ne ''" removed: icon_template is non-empty whenever defined.
        && defined $effective_existing->{icon_template}
        && $effective_existing->{icon_template} eq $candidate->{icon_template}
    ) {
        push @preserve_existing, qw(icon icon_template);
    }
    my %comparison_candidate = %{$candidate};
    for my $field (@preserve_existing) {
        next if !exists $comparison_existing->{$field};
        $comparison_candidate{$field} = $comparison_existing->{$field};
    }

    return {
        candidate           => $candidate,
        comparison_existing => $comparison_existing,
        comparison_candidate => \%comparison_candidate,
        preserve_existing   => \@preserve_existing,
        needs_write         => $self->_indicator_matches( $comparison_existing, \%comparison_candidate ) ? 0 : 1,
    };
}

# _indicator_sort_cmp($left, $right)
# Compares two indicator records for prompt and page-header ordering while
# keeping managed collector indicators in configured collector-array order.
# Input: two indicator hash references.
# Output: negative, zero, or positive integer suitable for Perl sort.
sub _indicator_sort_cmp {
    my ( $self, $left, $right ) = @_;
    my $left_priority = defined $left->{priority} ? $left->{priority} : 999;
    my $right_priority = defined $right->{priority} ? $right->{priority} : 999;
    my $priority_cmp = $left_priority <=> $right_priority;
    return $priority_cmp if $priority_cmp;

    my $left_collector = ( $left->{managed_by_collector} || 0 ) ? 1 : 0;
    my $right_collector = ( $right->{managed_by_collector} || 0 ) ? 1 : 0;
    if ( $left_collector && $right_collector ) {
        my $left_order = defined $left->{collector_order} ? $left->{collector_order} : 999;
        my $right_order = defined $right->{collector_order} ? $right->{collector_order} : 999;
        my $collector_cmp = $left_order <=> $right_order;
        return $collector_cmp if $collector_cmp;
    }

    return ( $left->{name} || '' ) cmp ( $right->{name} || '' );
}

# _local_indicator($name)
# Loads the indicator state stored in the deepest participating runtime layer
# only, without falling back to inherited layers.
# Input: indicator name string and optional ordered roots array reference.
# Output: indicator hash reference or undef when the deepest layer has no file.
sub _local_indicator {
    my ( $self, $name, $roots ) = @_;
    my ($file) = $self->_indicator_file_candidates( $name, $roots );
    return if !defined $file;
    return $self->_read_indicator_file($file);
}

# _nearest_inherited_indicator($name)
# Loads the nearest inherited indicator state beneath the deepest local layer.
# Input: indicator name string and optional ordered roots array reference.
# Output: indicator hash reference or undef when no inherited layer stores it.
sub _nearest_inherited_indicator {
    my ( $self, $name, $roots ) = @_;
    my @files = $self->_indicator_file_candidates( $name, $roots );
    shift @files;
    for my $file (@files) {
        my $item = $self->_read_indicator_file($file);
        return $item if $item;
    }
    return;
}

# _is_placeholder_missing_indicator($indicator)
# Detects whether one collector-managed indicator is only carrying the default
# placeholder missing state rather than a real live result.
# Input: indicator hash reference.
# Output: boolean true when the indicator status is the default missing state.
sub _is_placeholder_missing_indicator {
    my ( $self, $indicator ) = @_;
    return 0 if ref($indicator) ne 'HASH';
    return 0 if !( $indicator->{managed_by_collector} || 0 );
    my $status = defined $indicator->{status} ? lc $indicator->{status} : '';
    return $status eq 'missing' ? 1 : 0;
}

# _is_template_toolkit_text($text)
# Detects whether a configured indicator field contains Template Toolkit syntax.
# Input: optional text string.
# Output: boolean true when the text contains a TT directive marker.
sub _is_template_toolkit_text {
    my ( $self, $text ) = @_;
    return 0 if !defined $text || $text eq '';
    return index( $text, '[%' ) >= 0 ? 1 : 0;
}

# _read_indicator_file($file)
# Reads and decodes one indicator status file when it exists.
# Input: absolute indicator status file path.
# Output: indicator hash reference or undef when the file is missing.
sub _read_indicator_file {
    my ( $self, $file ) = @_;
    my $cache = $self->{_indicator_sync_read_cache};
    return $cache->{$file} if ref($cache) eq 'HASH' && exists $cache->{$file};

    my $item;
    if ( $self->{_indicator_sync_persistent_read} ) {
        my $signature = $self->_indicator_file_signature($file);
        my $persistent = $self->{_indicator_file_bytes_cache} ||= {};
        if ( exists $persistent->{$file} && $persistent->{$file}{signature} eq $signature ) {
            $item = defined $persistent->{$file}{raw} ? json_decode( $persistent->{$file}{raw} ) : undef;
        }
        else {
            $self->{_indicator_sync_file_changed} = 1
              if exists $self->{_indicator_sync_file_changed};
            my $raw = $self->_read_indicator_file_bytes_uncached($file);
            my $after_signature = $self->_indicator_file_signature($file);
            if ( $after_signature eq $signature ) {
                $persistent->{$file} = { signature => $signature, raw => $raw };
            }
            else {
                delete $persistent->{$file};
            }
            $item = defined $raw ? json_decode($raw) : undef;
        }
    }
    else {
        $item = $self->_read_indicator_file_uncached($file);
    }

    $cache->{$file} = $item if ref($cache) eq 'HASH';
    return $item;
}

# _indicator_file_signature($file)
# Returns a high-resolution identity for one status file so a collector sync can
# reuse cached raw bytes only while the same file state remains on disk.
# Input: absolute indicator status file path.
# Output: stable stat-signature string, or the literal missing marker for ENOENT.
sub _indicator_file_signature {
    my ( $self, $file ) = @_;
    $! = 0;
    my @stat = Time::HiRes::stat($file);
    if ( !@stat ) {
        return 'missing' if $! == ENOENT || $! == ENOTDIR;
        die "Unable to inspect indicator file $file: $!";
    }
    return join "\0", @stat[ 0, 1, 2, 3, 4, 5, 7, 9, 10 ];
}

# _read_indicator_file_uncached($file)
# Reads and decodes one indicator status file without consulting the temporary
# collector-sync cache.
# Input: absolute indicator status file path.
# Output: decoded indicator hash reference or undef when the file is missing.
sub _read_indicator_file_uncached {
    my ( $self, $file ) = @_;
    my $raw = $self->_read_indicator_file_bytes_uncached($file);
    return defined $raw ? json_decode($raw) : undef;
}

# _read_indicator_file_bytes_uncached($file)
# Reads one indicator JSON file as raw bytes without consulting any decoded or
# persistent sync cache.
# Input: absolute indicator status file path.
# Output: raw file contents, or undef when the file is missing.
sub _read_indicator_file_bytes_uncached {
    my ( $self, $file ) = @_;
    return if !-f $file;
    open my $fh, '<:raw', $file or die "Unable to read $file: $!";
    local $/;
    my $raw = <$fh>;
    $self->_close_indicator_read_handle($fh) or die "Unable to close $file: $!";
    return $raw;
}

# _close_indicator_read_handle($fh)
# Closes a status-file read handle and returns the close result so I/O failure
# remains visible to callers and can be tested without filesystem-specific tricks.
# Input: open filehandle reference.
# Output: true when the handle closes successfully, false on close failure.
sub _close_indicator_read_handle {
    my ( $self, $fh ) = @_;
    return close $fh;
}

# _status_icon_for($indicator, $map)
# Maps indicator status strings to either page-header or prompt glyphs.
# Input: indicator hash reference and icon lookup map.
# Output: resolved glyph string or the indicator icon as a fallback.
sub _status_icon_for {
    my ( $self, $indicator, $map ) = @_;
    return '' if ref($indicator) ne 'HASH';
    my $status = defined $indicator->{status} ? lc $indicator->{status} : '';
    return $map->{ok}{$status}    if exists $map->{ok}{$status};
    return $map->{error}{$status} if exists $map->{error}{$status};
    return defined $indicator->{icon} ? $indicator->{icon} : '';
}

1;

__END__

=head1 NAME

Developer::Dashboard::IndicatorStore - file-backed indicator state for Developer Dashboard

=head1 SYNOPSIS

  my $store = Developer::Dashboard::IndicatorStore->new(paths => $paths);
  $store->set_indicator('docker', status => 'ok');

=head1 DESCRIPTION

This module stores small status indicators that are consumed by prompt
rendering and dashboard views. It also provides a small built-in refresh path
for core generic indicators.

=head1 METHODS

=head2 new, set_indicator, get_indicator, list_indicators, _sort_indicators, _indicator_sort_order_cmp, collector_indicator_candidate

Construct and manage the indicator store.

C<list_indicators> reads current records from the ordered runtime roots and
returns them in priority/collector/name order. When at least 32 records are
present, its private sorter decorates each item with those comparison fields
once, then sorts the compact tuples to avoid repeated method calls and hash
lookups in the comparator. The small-list path continues to use the shared
comparison method. Both paths use the same field defaults and tie rules.
C<_indicator_sort_order_cmp> compares decorated tuples without object method
dispatch; direct tests pin each priority, collector-order, and name-fallback
case.

C<sync_collectors> discovers its ordered indicator roots once and shares them
with all collector comparisons and the final inventory. It also decodes each
status file at most once during that synchronization. The cache is local to the
call; writes and deletions invalidate the affected file, and a later sync
rereads disk so external edits remain visible. Docker regression coverage checks
root discovery, physical file reads, next-sync freshness, and collector
retirement. With 50 configured collectors, a byte-identical Docker comparison
measured 9.203 ms/request before and 2.689 ms/request after (3.42x). NYTProf
showed status-file reads dropping from 15,000 to 5,000 and root resolutions
from 15,100 to 100 over 100 requests. This workload-specific gain does not
establish Problem 48's 50x target for every routine.

=head2 mark_stale, is_stale, refresh_core_indicators, page_header_items, page_header_payload

Handle stale state and refresh the local project and Git indicators. Docker is
not a built-in indicator; its status is shown only when a collector is
configured for Docker. Core refresh also removes persisted records matching
the retired built-in Docker signature while preserving customized and
collector-managed records named C<docker>.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module persists prompt and browser status indicators. It stores indicator definitions and live status updates, merges collector-managed indicators with user-managed ones, keeps TT-backed collector icon templates separate from their live rendered icon values, refreshes project/Git core state without probing Docker, retires old built-in Docker records without deleting configured collector indicators, and provides the ordered indicator data used by the prompt renderer and the browser status strip.

=head1 WHY IT EXISTS

It exists because indicators are shared state that multiple features read and write. Prompt rendering, collector status, and browser chrome all need one source of truth for icon, label, priority, prompt visibility, and current status. C<set_indicator> persists that state through C<Developer::Dashboard::PathRegistry::atomic_write_secure> via an unpredictable per-writer staging path (DD-989), so a local actor cannot pre-plant a symlink at a known staging location and clobber an unrelated file.

=head1 WHEN TO USE

Use this file when changing indicator JSON layout, sorting rules, collector-managed indicator behavior, TT-backed collector icon persistence, core project/Git status refresh, or the persistence semantics of prompt-visible versus hidden indicators. Core refresh must not check for Docker or create a Docker indicator; explicitly configured Docker collectors remain supported.

=head1 HOW TO USE

Construct it with the active runtime paths, then call the store and list methods rather than editing indicator state files directly. Collector code should report into this store instead of inventing its own indicator persistence.

=head1 WHAT USES IT

It is used by the indicator command helper, by collector refresh paths, by the prompt renderer, by the browser status page, and by regression tests that verify indicator ownership and ordering.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::IndicatorStore -e 1

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
