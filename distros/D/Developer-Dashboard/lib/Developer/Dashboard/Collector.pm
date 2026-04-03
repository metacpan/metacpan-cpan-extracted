package Developer::Dashboard::Collector;

use strict;
use warnings;

our $VERSION = '1.33';

use File::Spec;
use POSIX qw(strftime);
use Time::HiRes qw(time);

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

# collector_paths($name)
# Returns the runtime file layout for a named collector.
# Input: collector name string.
# Output: hash reference of file paths for that collector.
sub collector_paths {
    my ( $self, $name ) = @_;
    my $dir = $self->{paths}->collector_dir($name);
    return {
        dir       => $dir,
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
    my $file = $self->collector_paths($name)->{job};
    return if !-f $file;
    open my $fh, '<', $file or die "Unable to read $file: $!";
    local $/;
    return json_decode(<$fh>);
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
        updated_at_epoch => time,
    };

    return $self->_atomic_write_json( $paths->{status}, $status );
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
    my $file = $self->collector_paths($name)->{status};
    return if !-f $file;
    open my $fh, '<', $file or die "Unable to read $file: $!";
    local $/;
    my $raw = <$fh>;
    my $data = eval { json_decode($raw) };
    return $data if !$@;
    return;
}

# read_output($name)
# Loads the latest output artifacts for a collector.
# Input: collector name string.
# Output: hash reference with stdout, stderr, combined, and last_run.
sub read_output {
    my ( $self, $name ) = @_;
    my $paths = $self->collector_paths($name);
    return {
        'stdout'   => _slurp( $paths->{stdout} ),
        'stderr'   => _slurp( $paths->{stderr} ),
        'combined' => _slurp( $paths->{combined} ),
        'last_run' => _slurp( $paths->{last_run} ),
    };
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
    my $root = $self->{paths}->collectors_root;
    opendir my $dh, $root or return;

    my @items;
    while ( my $entry = readdir $dh ) {
        next if $entry eq '.' || $entry eq '..';
        my $status = eval { $self->read_status($entry) };
        push @items, $status if $status;
    }
    closedir $dh;

    return sort { $a->{name} cmp $b->{name} } @items;
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
    open my $fh, '>', $tmp or die "Unable to write $tmp: $!";
    print {$fh} $text;
    close $fh;
    unlink $file if -f $file;
    rename $tmp, $file or die "Unable to rename $tmp to $file: $!";
    return $file;
}

# _slurp($file)
# Reads an entire file or returns an empty string when missing.
# Input: file path string.
# Output: file content string.
sub _slurp {
    my ($file) = @_;
    return '' if !-f $file;
    open my $fh, '<', $file or die "Unable to read $file: $!";
    local $/;
    return scalar <$fh>;
}

# _now_iso8601()
# Returns the current UTC timestamp in ISO-8601 form.
# Input: none.
# Output: timestamp string.
sub _now_iso8601 {
    my @t = gmtime();
    return strftime( '%Y-%m-%dT%H:%M:%SZ', @t );
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
status records, and latest outputs.

=head1 METHODS

=head2 new, collector_paths, write_job, read_job, write_result, write_status, read_status, read_output, inspect_collector, list_collectors

Construct and manage collector storage.

=cut
