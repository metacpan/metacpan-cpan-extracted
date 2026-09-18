package Developer::Dashboard::Pax::Benchmark;

our $VERSION = '4.45';

use strict;
use warnings;
use JSON::XS ();
use Time::HiRes qw(time);
use Developer::Dashboard::Pax::Capture;
use Developer::Dashboard::Pax::Manifest;
use Developer::Dashboard::Pax::RegionSelector;
use Developer::Dashboard::Pax::HIR;
use Developer::Dashboard::Pax::GuardedSSA;
use Developer::Dashboard::Pax::Tier1;
use Developer::Dashboard::Pax::NativeRunner;

sub new {
    my ($class, %args) = @_;
    return bless {
        iterations => $args{iterations} // 3,
        pax_bin => $args{pax_bin},
    }, $class;
}

sub run_capture_benchmark {
    my ($self, $entrypoint) = @_;
    my @samples;
    my $rss_before = _current_rss_kb();
    for (1 .. $self->{iterations}) {
        my $start = time();
        my $capture = eval { Developer::Dashboard::Pax::Capture->new(mode => 'live')->capture($entrypoint) };
        my $exit = ($@ || !$capture || ($capture->{status} // '') ne 'ok') ? 1 : 0;
        my $elapsed = time() - $start;
        push @samples, {
            iteration => $_,
            exit => $exit,
            elapsed_seconds => $elapsed,
            rss_kb => _current_rss_kb(),
        };
    }
    my $rss_after = _current_rss_kb();

    my $total = 0;
    $total += $_->{elapsed_seconds} for @samples;
    return {
        entrypoint => $entrypoint,
        benchmark_class => 'capture_overhead',
        iterations => $self->{iterations},
        samples => \@samples,
        mean_seconds => @samples ? $total / @samples : 0,
        warm_up_seconds => @samples ? $samples[0]{elapsed_seconds} : 0,
        fallback_share => 1,
        memory_impact => _memory_impact($rss_before, $rss_after),
    };
}

sub run_runtime_benchmark {
    my ($self, $entrypoint) = @_;
    my $rss_before = _current_rss_kb();
    my $reference = $self->_time_command([$^X, $entrypoint]);
    my $capture = $self->run_capture_benchmark($entrypoint);
    my $native = $self->_time_native($entrypoint);
    my $rss_after = _current_rss_kb();

    return {
        entrypoint => $entrypoint,
        benchmark_class => 'runtime',
        iterations => $self->{iterations},
        reference_mean_seconds => $reference->{mean_seconds},
        capture_mean_seconds => $capture->{mean_seconds},
        native_mean_seconds => $native->{mean_seconds},
        native_available => $native->{available},
        native_result => $native->{result},
        warm_up_seconds => $capture->{warm_up_seconds},
        fallback_share => $native->{available} ? 0 : 1,
        memory_impact => _memory_impact($rss_before, $rss_after),
    };
}

sub _time_command {
    local $?;    # DD-882 (vendored-in from PAX): guard $? so this sub's own subprocess call never leaks a mutated exit status to whatever runs in the caller after it returns.
    my ($self, $cmd) = @_;
    my @samples;
    for (1 .. $self->{iterations}) {
        my $start = time();
        system(@$cmd);
        push @samples, {
            iteration => $_,
            exit => $? >> 8,
            elapsed_seconds => time() - $start,
            rss_kb => _current_rss_kb(),
        };
    }
    return _summarise(\@samples);
}

sub _time_native {
    my ($self, $entrypoint) = @_;
    my $capture = Developer::Dashboard::Pax::Capture->new(mode => 'live')->capture($entrypoint);
    my $manifest = Developer::Dashboard::Pax::Manifest->new(capture => $capture)->to_hash;
    my $regions = Developer::Dashboard::Pax::RegionSelector->new(manifest => $manifest)->select;
    my $hir = Developer::Dashboard::Pax::HIR->new(manifest => $manifest, regions => $regions->{selected})->lower_all;
    my $ssa = Developer::Dashboard::Pax::GuardedSSA->new(hir_units => $hir)->build_all;
    my @artifacts = map { Developer::Dashboard::Pax::Tier1->new->compile($_) } @$ssa;
    my ($native) = grep { ($_->{entry_kind} // '') eq 'native_i64_leaf' && $_->{executable_path} } @artifacts;
    if (!$native) {
        return {
            available => JSON::XS::false(),
            mean_seconds => undef,
            result => undef,
        };
    }

    my @samples;
    my $result;
    for (1 .. $self->{iterations}) {
        my $start = time();
        $result = Developer::Dashboard::Pax::NativeRunner->new->run_i64_binary(
            path => $native->{executable_path},
            left => 10,
            right => 32,
        );
        push @samples, {
            iteration => $_,
            exit => $result->{exit},
            elapsed_seconds => time() - $start,
            rss_kb => _current_rss_kb(),
        };
    }
    my $summary = _summarise(\@samples);
    $summary->{available} = JSON::XS::true();
    $summary->{result} = $result;
    return $summary;
}

sub _summarise {
    my ($samples) = @_;
    my $total = 0;
    $total += $_->{elapsed_seconds} for @$samples;
    return {
        samples => $samples,
        mean_seconds => @$samples ? $total / @$samples : 0,
        warm_up_seconds => @$samples ? $samples->[0]{elapsed_seconds} : 0,
    };
}

sub _current_rss_kb {
    open my $fh, '<', '/proc/self/status' or return undef;
    while (my $line = <$fh>) {
        return 0 + $1 if $line =~ /^VmRSS:\s+(\d+)\s+kB/;
    }
    return undef;
}

sub _memory_impact {
    my ($before, $after) = @_;
    return {
        measured => defined($before) && defined($after) ? JSON::XS::true() : JSON::XS::false(),
        unit => 'KiB',
        before_rss_kb => $before,
        after_rss_kb => $after,
        delta_rss_kb => defined($before) && defined($after) ? $after - $before : undef,
        source => '/proc/self/status VmRSS',
    };
}

1;

__END__

=head1 NAME

Developer::Dashboard::Pax::Benchmark - internal benchmark helpers for PAX validation

=head1 SYNOPSIS

  my $bench = Developer::Dashboard::Pax::Benchmark->new(iterations => 5);
  my $result = $bench->run_runtime_benchmark(entrypoint => 'bin/app.pl');

=head1 DESCRIPTION

This module measures capture, reference runtime, and native-runtime behavior for
validation gates. Under SOW-03 it calls compiler/runtime modules directly
instead of shelling out to removed public diagnostic CLI commands.

=head1 METHODS

=head2 new

Creates a benchmark runner. C<iterations> controls the number of samples.

=head2 run_capture_benchmark

Runs C<Developer::Dashboard::Pax::Capture> directly and records timing plus process memory fields.

=head2 run_runtime_benchmark

Compares stock Perl timing, capture timing, and native execution timing where a
native region can be emitted.

=head1 PURPOSE

This module exists to keep performance comparisons scripted and reproducible so
PAX can measure where a build is faster, slower, or functionally different from
stock Perl.

=head1 WHY IT EXISTS

PAX's whole value proposition is "capture/native-compile this entrypoint and
it still behaves the same, only faster (or at least no slower)" - a claim
that is only checkable by actually timing runs, not by inspecting code. This
module runs the SAME entrypoint under three conditions (stock C<perl>,
PAX's capture/interpret path, and a natively-compiled artifact when one
exists) with matched sample counts and RSS-before/after memory accounting,
so a benchmark result is directly comparable across the three rather than
each caller timing its own ad-hoc subset.

=head1 WHEN TO USE

Edit this file when adding a new dimension to compare (a new timing metric,
a different memory measurement), when the native-artifact selection logic
in C<_time_native> needs to recognize a new C<entry_kind>, or when the
benchmark result shape callers depend on changes.

=head1 HOW TO USE

Construct a C<Benchmark> with an C<iterations> count, then call
C<run_capture_benchmark> to measure just the capture/interpret overhead for
one entrypoint, or C<run_runtime_benchmark> for the full three-way
comparison (stock Perl, capture, native). Read C<native_available> before
trusting C<native_mean_seconds> - a region with no natively-compilable
shape legitimately reports C<native_available =E<gt> false> and
C<fallback_share =E<gt> 1> rather than a fabricated timing.

=head1 WHAT USES IT

PAX's own differential/validation test paths (see
L<Developer::Dashboard::Pax::Differential>) and its benchmark-matrix
tooling (see L<Developer::Dashboard::Pax::BenchmarkMatrix>) call this to
produce the timing evidence behind a "this build is not slower" claim.

=head1 EXAMPLES

Example 1:

  my $bench = Developer::Dashboard::Pax::Benchmark->new(iterations => 5);
  my $result = $bench->run_capture_benchmark('bin/app.pl');
  # $result->{mean_seconds} is the mean capture/interpret time over 5 runs

Example 2:

  my $bench = Developer::Dashboard::Pax::Benchmark->new(iterations => 3);
  my $result = $bench->run_runtime_benchmark('bin/app.pl');
  # compares $result->{reference_mean_seconds} (stock perl) against
  # $result->{native_mean_seconds} when $result->{native_available} is true

=cut
