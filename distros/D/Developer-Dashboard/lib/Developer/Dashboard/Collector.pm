package Developer::Dashboard::Collector;

use strict;
use warnings;

our $VERSION = '3.04';

use File::Spec;
use POSIX qw(strftime);
use Time::HiRes qw(time);
use Time::Local qw(timegm);

use Developer::Dashboard::JSON qw(json_encode json_decode);

# new(%args)
# Constructs the collector storage manager.
# Input: paths object.
# Output: Developer::Dashboard::Collector object.
sub new {
    my ( $class, %args ) = @_;
    my $paths = $args{paths} || die 'Missing paths registry';
    return bless { paths => $paths }, $class;
}

# new_from_all_folders()
# Constructs a collector store from the public Folder-derived path inventory.
# Input: none.
# Output: Developer::Dashboard::Collector object.
sub new_from_all_folders {
    my ($class) = @_;
    require Developer::Dashboard::PathRegistry;
    return $class->new(
        paths => Developer::Dashboard::PathRegistry->new_from_all_folders,
    );
}

# collector_paths($name)
# Returns the runtime file layout for a named collector.
# Input: collector name string.
# Output: hash reference of file paths for that collector.
sub collector_paths {
    my ( $self, $name ) = @_;
    my $dir = $self->{paths}->collector_dir($name);
    return {
        dir       => $dir,
        log       => File::Spec->catfile( $dir, 'log' ),
        stdout    => File::Spec->catfile( $dir, 'stdout' ),
        stderr    => File::Spec->catfile( $dir, 'stderr' ),
        combined  => File::Spec->catfile( $dir, 'combined' ),
        last_run  => File::Spec->catfile( $dir, 'last_run' ),
        status    => File::Spec->catfile( $dir, 'status.json' ),
        job       => File::Spec->catfile( $dir, 'job.json' ),
    };
}

# write_job($name, $job)
# Persists the declarative job definition for a collector.
# Input: collector name string and job hash reference.
# Output: written job file path.
sub write_job {
    my ( $self, $name, $job ) = @_;
    my $paths = $self->collector_paths($name);
    return $self->_atomic_write_json( $paths->{job}, $job );
}

# read_job($name)
# Loads a stored collector job definition.
# Input: collector name string.
# Output: job hash reference or undef when missing.
sub read_job {
    my ( $self, $name ) = @_;
    for my $file ( $self->_collector_file_candidates( $name, 'job.json' ) ) {
        next if !-f $file;
        open my $fh, '<:raw', $file or die "Unable to read $file: $!";
        local $/;
        return json_decode(<$fh>);
    }
    return;
}

# write_result($name, %result)
# Persists collector stdout, stderr, combined output, and status metadata.
# Input: collector name and result fields such as exit_code/stdout/stderr.
# Output: written status file path.
sub write_result {
    my ( $self, $name, %result ) = @_;
    my $paths = $self->collector_paths($name);

    $self->_atomic_write_text( $paths->{stdout}, defined $result{stdout} ? $result{stdout} : '' );
    $self->_atomic_write_text( $paths->{stderr}, defined $result{stderr} ? $result{stderr} : '' );
    $self->_atomic_write_text( $paths->{combined}, ( defined $result{stdout} ? $result{stdout} : '' ) . ( defined $result{stderr} ? $result{stderr} : '' ) );

    my $timestamp = _now_iso8601();
    $self->_atomic_write_text( $paths->{last_run}, $timestamp . "\n" );

    my $previous = $self->read_status($name) || {};
    my $status = {
        %$previous,
        name             => $name,
        enabled          => exists $result{enabled} ? $result{enabled} : 1,
        running          => exists $result{running} ? $result{running} : 0,
        last_run         => $timestamp,
        last_completed_at=> $timestamp,
        last_exit_code   => $result{exit_code},
        last_success     => $result{exit_code} ? 0 : 1,
        last_success_at  => $result{exit_code} ? ( $previous->{last_success_at} || undef ) : $timestamp,
        last_failure_at  => $result{exit_code} ? $timestamp : ( $previous->{last_failure_at} || undef ),
        last_started_at  => $result{started_at} || $previous->{last_started_at},
        output_format    => $result{output_format},
        timed_out        => $result{timed_out} ? 1 : 0,
        updated_at_epoch => time,
    };

    my $written = $self->_atomic_write_json( $paths->{status}, $status );
    $self->append_log_entry(
        $name,
        happened_at => $timestamp,
        exit_code   => $result{exit_code},
        timed_out   => $result{timed_out},
        stdout      => $result{stdout},
        stderr      => $result{stderr},
    );
    return $written;
}

# write_status($name, $status)
# Merges and persists collector status metadata without rewriting outputs.
# Input: collector name string and partial status hash reference.
# Output: written status file path.
sub write_status {
    my ( $self, $name, $status ) = @_;
    my $paths = $self->collector_paths($name);
    my $existing = $self->read_status($name) || {};
    my %merged = (
        %$existing,
        %{ $status || {} },
        name             => $name,
        updated_at_epoch => time,
    );
    return $self->_atomic_write_json( $paths->{status}, \%merged );
}

# read_status($name)
# Loads stored status metadata for a collector.
# Input: collector name string.
# Output: status hash reference or undef when missing.
sub read_status {
    my ( $self, $name ) = @_;
    for my $file ( $self->_collector_file_candidates( $name, 'status.json' ) ) {
        next if !-f $file;
        open my $fh, '<:raw', $file or die "Unable to read $file: $!";
        local $/;
        my $raw = <$fh>;
        my $data = eval { json_decode($raw) };
        return $data if !$@;
    }
    return;
}

# read_output($name)
# Loads the latest output artifacts for a collector.
# Input: collector name string.
# Output: hash reference with stdout, stderr, combined, and last_run.
sub read_output {
    my ( $self, $name ) = @_;
    my $last_run = $self->_first_existing_text_file( $name, 'last_run' );
    $last_run =~ s/\r?\n\z// if defined $last_run;
    return {
        'stdout'   => $self->_first_existing_text_file( $name, 'stdout' ),
        'stderr'   => $self->_first_existing_text_file( $name, 'stderr' ),
        'combined' => $self->_first_existing_text_file( $name, 'combined' ),
        'last_run' => $last_run,
    };
}

# collector_exists($name)
# Returns whether a collector exists in persisted state across any runtime layer.
# Input: collector name string.
# Output: boolean true when collector files or directories exist.
sub collector_exists {
    my ( $self, $name ) = @_;
    die 'Missing collector name' if !defined $name || $name eq '';
    for my $root ( $self->{paths}->collectors_roots ) {
        return 1 if -d File::Spec->catdir( $root, $name );
    }
    return 0;
}

# append_log_entry($name, %entry)
# Appends one human-readable collector log entry to the collector log file.
# Input: collector name string plus happened_at, exit_code, timed_out, stdout, stderr, and error fields.
# Output: collector log file path string.
sub append_log_entry {
    my ( $self, $name, %entry ) = @_;
    die 'Missing collector name' if !defined $name || $name eq '';
    my $paths = $self->collector_paths($name);
    my $text = $self->_format_log_entry(
        name        => $name,
        happened_at => $entry{happened_at},
        exit_code   => $entry{exit_code},
        timed_out   => $entry{timed_out},
        stdout      => $entry{stdout},
        stderr      => $entry{stderr},
        error       => $entry{error},
        source      => $entry{source},
    );
    open my $fh, '>>', $paths->{log} or die "Unable to append $paths->{log}: $!";
    print {$fh} $text;
    close $fh;
    $self->{paths}->secure_file_permissions( $paths->{log} );
    return $paths->{log};
}

# rotate_log($name, $rotation, %args)
# Applies configured retention rules to one collector log file.
# Input: collector name string, rotation hash reference, and optional now_epoch.
# Output: hash reference describing the applied rotation, or undef when nothing changed.
sub rotate_log {
    my ( $self, $name, $rotation, %args ) = @_;
    die 'Missing collector name' if !defined $name || $name eq '';
    my $normalized = $self->_normalize_rotation( $name, $rotation );
    return if !keys %{$normalized};

    my $paths = $self->collector_paths($name);
    return if !-f $paths->{log};

    my $original = _slurp( $paths->{log} );
    my $rotated = $self->_apply_log_rotation(
        $name,
        $original,
        $normalized,
        now_epoch => $args{now_epoch},
    );
    return if $rotated eq $original;

    $self->_atomic_write_text( $paths->{log}, $rotated );
    return {
        kind         => 'collector-log-rotation',
        name         => $name,
        path         => $paths->{log},
        strategy     => join( ',', map { $_ . '=' . $normalized->{$_} } sort keys %{$normalized} ),
        before_bytes => length $original,
        after_bytes  => length $rotated,
    };
}

# read_log($name)
# Reads the collector log stream, falling back to the latest persisted output snapshot.
# Input: collector name string.
# Output: log text string or empty string when no log data exists yet.
sub read_log {
    my ( $self, $name ) = @_;
    die 'Missing collector name' if !defined $name || $name eq '';
    for my $file ( $self->_collector_file_candidates( $name, 'log' ) ) {
        return _slurp($file) if -f $file;
    }
    return $self->_render_latest_log_entry($name);
}

# inspect_collector($name)
# Returns the combined view of job definition, output, and status.
# Input: collector name string.
# Output: inspection hash reference.
sub inspect_collector {
    my ( $self, $name ) = @_;
    return {
        job    => $self->read_job($name),
        output => $self->read_output($name),
        status => $self->read_status($name),
    };
}

# list_collectors()
# Lists all collectors with valid persisted status metadata.
# Input: none.
# Output: sorted list of status hash references.
sub list_collectors {
    my ($self) = @_;
    my %items;
    for my $root ( $self->{paths}->collectors_roots ) {
        next if !-d $root;
        opendir my $dh, $root or next;
        while ( my $entry = readdir $dh ) {
            next if $entry eq '.' || $entry eq '..';
            next if $items{$entry};
            my $status = eval { $self->read_status($entry) };
            $items{$entry} = $status if $status;
        }
        closedir $dh;
    }

    return sort { $a->{name} cmp $b->{name} } values %items;
}

# _collector_file_candidates($name, $filename)
# Returns candidate collector file paths across every runtime layer in lookup
# order from deepest to home.
# Input: collector name string and collector-relative filename string.
# Output: ordered list of file path strings.
sub _collector_file_candidates {
    my ( $self, $name, $filename ) = @_;
    return map { File::Spec->catfile( $_, $name, $filename ) } $self->{paths}->collectors_roots;
}

# _first_existing_text_file($name, $filename)
# Reads the first existing collector text artifact across every runtime layer.
# Input: collector name string and collector-relative filename string.
# Output: file content string or an empty string when missing.
sub _first_existing_text_file {
    my ( $self, $name, $filename ) = @_;
    for my $file ( $self->_collector_file_candidates( $name, $filename ) ) {
        return _slurp($file) if -f $file;
    }
    return '';
}

# _render_latest_log_entry($name)
# Synthesizes one collector log entry from the latest persisted output/state.
# Input: collector name string.
# Output: formatted log text string or an empty string when no persisted log data exists.
sub _render_latest_log_entry {
    my ( $self, $name ) = @_;
    return '' if !$self->collector_exists($name);
    my $status = $self->read_status($name) || {};
    my $output = $self->read_output($name) || {};
    return '' if !$self->_log_payload_present( $status, $output );
    return $self->_format_log_entry(
        name        => $name,
        happened_at => $output->{last_run} || $status->{last_run} || $status->{last_completed_at} || $status->{last_started_at},
        exit_code   => $status->{last_exit_code},
        timed_out   => $status->{timed_out},
        stdout      => $output->{stdout},
        stderr      => $output->{stderr},
        source      => 'latest state snapshot',
    );
}

# _log_payload_present($status, $output)
# Checks whether persisted collector state contains anything worth rendering as a log entry.
# Input: status hash reference and output hash reference.
# Output: boolean true when exit code, timestamps, or output content exist.
sub _log_payload_present {
    my ( $self, $status, $output ) = @_;
    return 1 if grep { defined && $_ ne '' } map { $output->{$_} } qw(stdout stderr combined last_run);
    return 1 if grep { defined } map { $status->{$_} } qw(last_exit_code last_run last_completed_at last_started_at timed_out);
    return 0;
}

# _format_log_entry(%args)
# Formats one collector log event into the human-readable CLI log stream.
# Input: name, happened_at, exit_code, timed_out, stdout, stderr, error, and source fields.
# Output: formatted log text string with trailing newline.
sub _format_log_entry {
    my ( $self, %args ) = @_;
    my $name = $args{name} || die 'Missing collector name';
    my $time = $args{happened_at} || 'unknown-time';
    my @header = ( "=== collector $name", "\@ $time" );
    push @header, 'exit=' . $args{exit_code} if defined $args{exit_code};
    push @header, 'timed_out=1' if $args{timed_out};
    push @header, 'source=' . $args{source} if defined $args{source} && $args{source} ne '';

    my @chunks = ( join( ' | ', @header ) . " ===\n" );
    if ( defined $args{stdout} && $args{stdout} ne '' ) {
        push @chunks, "[stdout]\n", _with_trailing_newline( $args{stdout} );
    }
    if ( defined $args{stderr} && $args{stderr} ne '' ) {
        push @chunks, "[stderr]\n", _with_trailing_newline( $args{stderr} );
    }
    if ( defined $args{error} && $args{error} ne '' ) {
        push @chunks, "[error]\n", _with_trailing_newline( $args{error} );
    }
    push @chunks, "\n";
    return join '', @chunks;
}

# _normalize_rotation($name, $rotation)
# Validates and normalizes one collector log-rotation configuration hash.
# Input: collector name string and raw rotation hash reference.
# Output: normalized rotation hash reference keyed by canonical retention names.
sub _normalize_rotation {
    my ( $self, $name, $rotation ) = @_;
    return {} if !defined $rotation;
    die "collector rotation for $name must be a hash reference\n"
      if ref($rotation) ne 'HASH';

    my %normalized;
    my %aliases = (
        lines   => 'lines',
        minute  => 'minutes',
        minutes => 'minutes',
        hour    => 'hours',
        hours   => 'hours',
        day     => 'days',
        days    => 'days',
        week    => 'weeks',
        weeks   => 'weeks',
        month   => 'months',
        months  => 'months',
    );

    for my $key ( sort keys %{$rotation} ) {
        my $canonical = $aliases{$key}
          or die "collector rotation key $key for $name is not supported\n";
        my $value = $rotation->{$key};
        die "collector rotation $canonical for $name must be a non-negative integer\n"
          if !defined $value || $value !~ /\A\d+\z/;
        $normalized{$canonical} = $value + 0;
    }

    return \%normalized;
}

# _apply_log_rotation($name, $text, $rotation, %args)
# Applies time-based and line-based retention rules to one collector log blob.
# Input: collector name string, log text, normalized rotation hash reference, and optional now_epoch.
# Output: rotated log text string.
sub _apply_log_rotation {
    my ( $self, $name, $text, $rotation, %args ) = @_;
    my $rotated = $text;

    my $retention_seconds = $self->_rotation_retention_seconds($rotation);
    if ( defined $retention_seconds ) {
        $rotated = $self->_trim_log_by_age(
            $name,
            $rotated,
            $retention_seconds,
            now_epoch => $args{now_epoch},
        );
    }

    if ( exists $rotation->{lines} ) {
        $rotated = $self->_trim_log_by_lines( $rotated, $rotation->{lines} );
    }

    return $rotated;
}

# _rotation_retention_seconds($rotation)
# Converts normalized time-based rotation rules into one retention window.
# Input: normalized rotation hash reference.
# Output: total retention seconds integer, or undef when no age rule was configured.
sub _rotation_retention_seconds {
    my ( $self, $rotation ) = @_;
    my %seconds_per_unit = (
        minutes => 60,
        hours   => 60 * 60,
        days    => 60 * 60 * 24,
        weeks   => 60 * 60 * 24 * 7,
        months  => 60 * 60 * 24 * 30,
    );

    my $seconds;
    for my $unit ( keys %seconds_per_unit ) {
        next if !exists $rotation->{$unit};
        $seconds ||= 0;
        $seconds += $rotation->{$unit} * $seconds_per_unit{$unit};
    }

    return $seconds;
}

# _trim_log_by_age($name, $text, $retention_seconds, %args)
# Keeps only collector log entries whose timestamps fall inside the retention window.
# Input: collector name string, log text, retention window in seconds, and optional now_epoch.
# Output: rotated log text string containing only retained entries.
sub _trim_log_by_age {
    my ( $self, $name, $text, $retention_seconds, %args ) = @_;
    return $text if !defined $retention_seconds;
    return $text if $text eq '';

    my $now_epoch = defined $args{now_epoch} ? $args{now_epoch} : time;
    my $cutoff = $now_epoch - $retention_seconds;
    my @kept;
    for my $entry ( $self->_split_log_entries($text) ) {
        my $entry_epoch = $self->_entry_timestamp_epoch( $name, $entry );
        push @kept, $entry if $entry_epoch >= $cutoff;
    }
    return join '', @kept;
}

# _trim_log_by_lines($text, $lines)
# Keeps only the configured trailing number of lines from a collector log blob.
# Input: log text string and non-negative line count.
# Output: rotated log text string containing at most the requested number of lines.
sub _trim_log_by_lines {
    my ( $self, $text, $lines ) = @_;
    return $text if $text eq '';

    my $has_trailing_newline = $text =~ /\n\z/ ? 1 : 0;
    my @parts = split /\n/, $text, -1;
    pop @parts if $has_trailing_newline && @parts && $parts[-1] eq '';
    return $text if @parts <= $lines;
    @parts = @parts[ @parts - $lines .. $#parts ];
    return join( "\n", @parts ) . ( $has_trailing_newline ? "\n" : '' );
}

# _split_log_entries($text)
# Splits one collector log blob into individual formatted log entries.
# Input: log text string.
# Output: ordered list of log entry text chunks.
sub _split_log_entries {
    my ( $self, $text ) = @_;
    return () if !defined $text || $text eq '';
    return grep { defined && $_ ne '' } split /(?=^=== collector )/m, $text;
}

# _entry_timestamp_epoch($name, $entry)
# Extracts and parses the timestamp from one formatted collector log entry.
# Input: collector name string and one log entry text chunk.
# Output: UTC epoch integer for the entry timestamp.
sub _entry_timestamp_epoch {
    my ( $self, $name, $entry ) = @_;
    my ($timestamp) = $entry =~ /\A=== collector [^\n]* \| \@ ([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:Z|[+-][0-9]{4}|[+-][0-9]{2}:[0-9]{2}))(?: \| [^\n]*)* ===\n/;
    die "Unable to parse collector log timestamp for $name\n"
      if !defined $timestamp;
    return $self->_iso8601_to_epoch($timestamp);
}

# _iso8601_to_epoch($timestamp)
# Converts one dashboard ISO-8601 timestamp string into epoch seconds.
# Input: timestamp string in YYYY-MM-DDTHH:MM:SSZ or YYYY-MM-DDTHH:MM:SS+HHMM form.
# Output: UTC epoch integer.
sub _iso8601_to_epoch {
    my ( $self, $timestamp ) = @_;
    my ( $year, $month, $day, $hour, $minute, $second, $zone ) =
      $timestamp =~ /\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(Z|[+-]\d{4}|[+-]\d{2}:\d{2})\z/;
    die "Unsupported collector log timestamp $timestamp\n" if !defined $zone;

    my $offset_seconds = 0;
    if ( $zone ne 'Z' ) {
        my ( $sign, $offset_hour, $offset_minute ) = $zone =~ /\A([+-])(\d{2}):?(\d{2})\z/;
        $offset_seconds = ( $offset_hour * 3600 ) + ( $offset_minute * 60 );
        $offset_seconds *= -1 if $sign eq '-';
    }

    return timegm( $second, $minute, $hour, $day, $month - 1, $year ) - $offset_seconds;
}

# _with_trailing_newline($text)
# Ensures a text block ends with one newline for deterministic log formatting.
# Input: text string.
# Output: text string with a trailing newline.
sub _with_trailing_newline {
    my ($text) = @_;
    $text = '' if !defined $text;
    return $text =~ /\n\z/ ? $text : $text . "\n";
}

# _atomic_write_json($file, $data)
# Atomically writes JSON to a file using a pending temporary file.
# Input: target file path and Perl data structure.
# Output: written file path string.
sub _atomic_write_json {
    my ( $self, $file, $data ) = @_;
    return $self->_atomic_write_text( $file, json_encode($data) );
}

# _atomic_write_text($file, $text)
# Atomically writes raw text to a file using a pending temporary file.
# Input: target file path and text string.
# Output: written file path string.
sub _atomic_write_text {
    my ( $self, $file, $text ) = @_;
    my $tmp = "$file.pending";
    open my $fh, '>:raw', $tmp or die "Unable to write $tmp: $!";
    print {$fh} $text;
    close $fh;
    $self->{paths}->secure_file_permissions($tmp);
    unlink $file if -f $file;
    rename $tmp, $file or die "Unable to rename $tmp to $file: $!";
    $self->{paths}->secure_file_permissions($file);
    return $file;
}

# _slurp($file)
# Reads an entire file or returns an empty string when missing.
# Input: file path string.
# Output: file content string.
sub _slurp {
    my ($file) = @_;
    return '' if !-f $file;
    open my $fh, '<:raw', $file or die "Unable to read $file: $!";
    local $/;
    return scalar <$fh>;
}

# _now_iso8601()
# Returns the current local timestamp in ISO-8601 form with timezone offset.
# Input: none.
# Output: timestamp string.
sub _now_iso8601 {
    my @t = localtime();
    return strftime( '%Y-%m-%dT%H:%M:%S%z', @t );
}

1;

__END__

=head1 NAME

Developer::Dashboard::Collector - file-backed collector storage

=head1 SYNOPSIS

  my $collector = Developer::Dashboard::Collector->new(paths => $paths);
  $collector->write_job('sample', { name => 'sample', command => 'true' });

=head1 DESCRIPTION

This module owns the on-disk storage model for collector job definitions,
status records, latest outputs, and persisted collector log transcripts. It
also applies collector log retention rules when housekeeping asks it to rotate
those transcripts.

=head1 METHODS

=head2 new, collector_paths, write_job, read_job, write_result, write_status, read_status, read_output, collector_exists, append_log_entry, rotate_log, read_log, inspect_collector, list_collectors

Construct and manage collector storage.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module is the file-backed persistence layer for collectors. It knows
where each collector stores its job definition, stdout, stderr, combined
output, last-run marker, status JSON, and transcript log across the layered
runtime roots, and it updates those files atomically.

=head1 WHY IT EXISTS

It exists because collectors are stateful background work. Their output,
status files, and transcript retention rules need one owner that handles
layered lookup, atomic writes, stable file layout, and explicit log rotation
instead of scattering those rules across the runner, prompt renderer,
inspection commands, and housekeeping code.

=head1 WHEN TO USE

Use this file when changing collector on-disk layout, status JSON fields, output artifact names, or the read/merge/write behavior for collector state.

=head1 HOW TO USE

Construct it with the active path registry, then use C<write_job>,
C<write_result>, C<write_status>, C<read_status>, C<read_output>,
C<rotate_log>, and C<list_collectors>. Keep collector storage rules here and
let the runner focus on process execution.

=head1 WHAT USES IT

It is used by C<Developer::Dashboard::CollectorRunner>, by the housekeeper
cleanup pass, by collector inspection/list commands, by prompt and status
views that read collector state, and by collector persistence tests.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::Collector -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/05-cli-smoke.t t/07-core-units.t

Run the focused regression tests that most directly exercise collector
persistence and log rotation behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
