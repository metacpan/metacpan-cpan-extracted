package Developer::Dashboard::Pax::Gatekeeper;

our $VERSION = '4.45';

use strict;
use warnings;
use JSON::XS ();
use Developer::Dashboard::Pax::Backend::Tier1CraneliftEquivalent;
use Developer::Dashboard::Pax::Backend::Tier2LLVM;
use Developer::Dashboard::Pax::Benchmark;
use Developer::Dashboard::Pax::BenchmarkMatrix;
use Developer::Dashboard::Pax::CPANMatrix;
use Developer::Dashboard::Pax::Capture;
use Developer::Dashboard::Pax::CoreSuite;
use Developer::Dashboard::Pax::Corpus;
use Developer::Dashboard::Pax::GuardedSSA;
use Developer::Dashboard::Pax::HIR;
use Developer::Dashboard::Pax::Manifest;
use Developer::Dashboard::Pax::ProfileStore;
use Developer::Dashboard::Pax::RegionSelector;
use Developer::Dashboard::Pax::AppImage;

sub new {
    my ($class, %args) = @_;
    return bless {
        root => $args{root} // '.',
    }, $class;
}

sub sow01_report {
    my ($self) = @_;
    my @checks = (
        $self->_check_file('source_sow', 'project/SOW-01.pdf', 'Approved SOW-01 PDF exists'),
        $self->_check_file('source_sow_02', 'project/SOW-02.pdf', 'Approved SOW-02 PDF exists when SOW-02 is indexed'),
        $self->_check_backlog_approved_sows,
        $self->_check_docker_pin,
        $self->_check_cli_surface,
        $self->_check_test_file('host_cli_tests', 't/cli.t', 'Host CLI test suite is present'),
        $self->_check_core_suite,
        $self->_check_cpan_matrix,
        $self->_check_file('nasty_perl_corpus', 't/corpus.json', 'Nasty Perl corpus manifest is present for local dynamic-feature fixtures'),
        $self->_check_file('benchmark_matrix_manifest', 't/benchmark_matrix.json', 'Benchmark matrix manifest is present'),
        $self->_check_validation_matrix,
        $self->_check_semantic_snapshot_capture,
        $self->_check_optree_derived_hir_lowering,
        $self->_check_tiered_backend_architecture,
        $self->_check_deopt_frame_fields,
        $self->_check_broad_cpan_xs_matrix,
        $self->_check_performance_observability_fields,
        $self->_check_current_docs_no_gap_language,
        $self->_check_real_backend_integration,
        $self->_check_real_hot_region_jit_aot,
        $self->_check_real_cpan_xs_coverage,
        $self->_check_whole_program_app_image,
    );
    my $passed = 0;
    $passed++ for grep { $_->{status} eq 'passed' } @checks;
    my $blocked = 0;
    $blocked++ for grep { $_->{status} ne 'passed' } @checks;
    return {
        sow => 'SOW-01',
        status => $blocked ? 'not_passed' : 'passed',
        passed => $passed,
        blocked => $blocked,
        checks => \@checks,
    };
}

sub _check_real_backend_integration {
    my ($self) = @_;
    my $tier1 = _slurp("$self->{root}/lib/Developer/Dashboard/Pax/Tier1.pm");
    my $tier2 = _slurp("$self->{root}/lib/Developer/Dashboard/Pax/Backend/Tier2LLVM.pm");
    my @missing;
    push @missing, 'real_cranelift_backend' if $tier1 =~ /\brustc\b/ || $tier1 !~ /Cranelift/i;
    push @missing, 'real_llvm_codegen' if $tier2 !~ /LLVM/ || $tier2 !~ /emit|compile|module|object/i;
    return {
        id => 'real_backend_integration',
        description => 'Real Cranelift-equivalent Tier 1 and LLVM Tier 2 code generation are implemented, not just metadata or rustc fixture emission',
        status => @missing ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : 'real backend integration',
    };
}

sub _check_real_hot_region_jit_aot {
    my ($self) = @_;
    my @missing;
    push @missing, 'hot_region_jit_runtime' if !-f "$self->{root}/lib/Developer/Dashboard/Pax/HotRegionJIT.pm";
    push @missing, 'profile_guided_aot_runtime' if !-f "$self->{root}/lib/Developer/Dashboard/Pax/ProfileGuidedAOT.pm";
    push @missing, 'osr_runtime' if !-f "$self->{root}/lib/Developer/Dashboard/Pax/OSR.pm";
    push @missing, 'inline_cache_runtime' if !-f "$self->{root}/lib/Developer/Dashboard/Pax/InlineCache.pm";
    return {
        id => 'real_hot_region_jit_aot',
        description => 'Hot-region JIT, profile-guided AOT, OSR, and inline caches are implemented',
        status => @missing ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : 'JIT/AOT/OSR runtime',
    };
}

sub _check_real_cpan_xs_coverage {
    my ($self) = @_;
    my $matrix = _slurp("$self->{root}/t/cpan_matrix.json");
    my $dist_count = () = $matrix =~ /"distribution"\s*:/g;
    my @missing;
    push @missing, 'broad_distribution_count' if $dist_count < 25;
    push @missing, 'declared_xs_metadata' if $matrix !~ /declared-xs|declared_xs|XS declaration/i;
    push @missing, 'level_a_to_d_coverage' if $matrix !~ /Level A|Level B|Level C|Level D|fully acceleratable|fallback-heavy|unsupported/i;
    return {
        id => 'real_cpan_xs_coverage',
        description => 'Broad real CPAN and XS compatibility matrix covers common distributions and A-D compatibility levels',
        status => @missing ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : 'broad CPAN/XS matrix',
    };
}

sub _check_file {
    my ($self, $id, $path, $description) = @_;
    return {
        id => $id,
        description => $description,
        status => -f "$self->{root}/$path" ? 'passed' : 'blocked',
        evidence => $path,
    };
}

sub _check_test_file {
    my ($self, $id, $path, $description) = @_;
    return $self->_check_file($id, $path, $description);
}

sub _check_no_path {
    my ($self, $id, $path, $description) = @_;
    return {
        id => $id,
        description => $description,
        status => !-e "$self->{root}/$path" ? 'passed' : 'blocked',
        evidence => $path,
    };
}

sub _check_backlog_approved_sows {
    my ($self) = @_;
    my $path = "$self->{root}/project/BACKLOG.md";
    my $content = _slurp($path);
    my $ok = $content =~ /\| SOW-01 \|/ && $content =~ /\| SOW-02 \|/ && $content !~ /\| SOW-03 \|/;
    return {
        id => 'approved_sows_indexed',
        description => 'Backlog indexes approved SOW-01 and SOW-02 only',
        status => $ok ? 'passed' : 'blocked',
        evidence => 'project/BACKLOG.md',
    };
}

sub _check_docker_pin {
    my ($self) = @_;
    my $content = _slurp("$self->{root}/Dockerfile");
    return {
        id => 'pinned_perl_baseline',
        description => 'Dockerfile pins the Perl 5.42.0 baseline image',
        status => $content =~ /^FROM\s+perl:5\.42\.0\b/m ? 'passed' : 'blocked',
        evidence => 'Dockerfile',
    };
}

sub _check_cli_surface {
    my ($self) = @_;
    my $content = _slurp("$self->{root}/lib/Developer/Dashboard/Pax/CLI.pm");
    my @missing = grep { $content !~ /if \(\$command eq '\Q$_\E'\)/ } ('build', 'run');
    my @extra = grep { $content =~ /if \(\$command eq '\Q$_\E'\)/ } qw(
        capture inspect hir compile diff bench bench-matrix run-native corpus core-suite
        cpan-matrix dispatch profile why-not trace-guards gatekeeper app-build app-start
        app-run app-stop standalone-build standalone-run standalone-inspect standalone-extract
        standalone-why-not standalone-native-run
    );
    return {
        id => 'cli_sow03_surface',
        description => 'Public CLI includes only build and run; diagnostics remain internal implementation APIs',
        status => (@missing || @extra) ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : (@extra ? 'extra: ' . join(', ', @extra) : 'lib/Developer/Dashboard/Pax/CLI.pm'),
    };
}

sub _check_whole_program_app_image {
    my ($self) = @_;
    my @missing;
    push @missing, 'app_image_builder' if !-f "$self->{root}/lib/Developer/Dashboard/Pax/AppImage.pm";
    push @missing, 'app_server_runtime' if !-f "$self->{root}/lib/Developer/Dashboard/Pax/AppServer.pm";
    push @missing, 'paxfile_loader' if !-f "$self->{root}/lib/Developer/Dashboard/Pax/Paxfile.pm";
    push @missing, 'project_paxfile' if !-f "$self->{root}/paxfile.yml";
    push @missing, 'app_image_test' if !-f "$self->{root}/t/app_image.t";
    push @missing, 'embedded_asset_fixture' if !-f "$self->{root}/t/fixtures/app_assets/banner.txt";
    my $cli = _slurp("$self->{root}/lib/Developer/Dashboard/Pax/CLI.pm");
    my $app_image = _slurp("$self->{root}/lib/Developer/Dashboard/Pax/AppImage.pm");
    push @missing, 'public_build_command' if $cli !~ /if \(\$command eq 'build'\)/;
    push @missing, 'public_run_command' if $cli !~ /if \(\$command eq 'run'\)/;
    push @missing, 'asset_build_flags' if $cli !~ /--asset/ || $cli !~ /--asset-dir/;
    push @missing, 'paxfile_cli_flags' if $cli !~ /--paxfile/ || $cli !~ /--no-paxfile/;
    push @missing, 'asset_embedding_runtime' if $app_image !~ /pax_assets/ || $app_image !~ /PAX_EMBEDDED_ASSET_ROOT/;
    return {
        id => 'whole_program_app_image_runtime',
        description => 'Whole-program Perl entrypoints can be built from paxfile.yml into PAX app images with embedded assets and run through a preloaded subsystem',
        status => @missing ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : 'Developer::Dashboard::Pax::AppImage/Developer::Dashboard::Pax::AppServer',
    };
}

sub _check_benchmark_matrix_command {
    my ($self) = @_;
    my $content = _slurp("$self->{root}/lib/Developer/Dashboard/Pax/CLI.pm");
    return {
        id => 'full_benchmark_execution',
        description => 'Benchmark matrix has an executable CLI path',
        status => $content =~ /bench-matrix/ ? 'passed' : 'blocked',
        evidence => 'Developer::Dashboard::Pax::BenchmarkMatrix t/benchmark_matrix.json',
    };
}

sub _check_validation_matrix {
    my ($self) = @_;
    my @runs = (
        ['core-suite', sub { Developer::Dashboard::Pax::CoreSuite->new(manifest_path => "$self->{root}/t/perl_core_suite.json")->run }],
        ['corpus', sub { Developer::Dashboard::Pax::Corpus->new(manifest_path => "$self->{root}/t/corpus.json")->run }],
        ['cpan-matrix', sub { Developer::Dashboard::Pax::CPANMatrix->new(manifest_path => "$self->{root}/t/cpan_matrix.json")->run }],
        ['bench-matrix', sub { Developer::Dashboard::Pax::BenchmarkMatrix->new(manifest_path => "$self->{root}/t/benchmark_matrix.json", iterations => 1, pax_bin => "$self->{root}/bin/pax")->run }],
    );
    my @failed;
    for my $run (@runs) {
        my ($name, $code) = @$run;
        my $result = eval { $code->() };
        if ($@ || !$result || !$result->{passed}) {
            push @failed, $@ ? "$name: $@" : $name;
        }
    }
    return {
        id => 'sow_validation_matrix',
        description => 'Core, nasty Perl, CPAN/XS, and performance validation suites execute successfully',
        status => @failed ? 'blocked' : 'passed',
        evidence => @failed ? join('; ', @failed) : 'core-suite, corpus, cpan-matrix, bench-matrix',
    };
}

sub _check_core_suite {
    my ($self) = @_;
    my $content = _slurp("$self->{root}/lib/Developer/Dashboard/Pax/CLI.pm");
    my $report = "$self->{root}/projects/sow-01-project-pax/epic-06-validation-benchmarking-delivery/perl-core-suite-report.md";
    return {
        id => 'perl_core_suite',
        description => 'Perl core regression suite is wired and recorded',
        status => ($content =~ /core-suite/ && -f $report) ? 'passed' : 'blocked',
        evidence => 'Developer::Dashboard::Pax::CoreSuite t/perl_core_suite.json',
    };
}

sub _check_cpan_matrix {
    my ($self) = @_;
    my $content = _slurp("$self->{root}/lib/Developer/Dashboard/Pax/CLI.pm");
    my $report = "$self->{root}/projects/sow-01-project-pax/epic-06-validation-benchmarking-delivery/cpan-matrix-report.md";
    return {
        id => 'real_cpan_matrix',
        description => 'CPAN distribution matrix is wired and recorded',
        status => ($content =~ /cpan-matrix/ && -f $report) ? 'passed' : 'blocked',
        evidence => 'Developer::Dashboard::Pax::CPANMatrix t/cpan_matrix.json',
    };
}

sub _check_semantic_snapshot_capture {
    my ($self) = @_;
    my $manifest = _slurp("$self->{root}/lib/Developer/Dashboard/Pax/Manifest.pm");
    my $capture = _slurp("$self->{root}/lib/Developer/Dashboard/Pax/Capture.pm");
    my @required = qw(lexical_pads closure_descriptors method_resolution regex_metadata compile_phase_events pad_layout closure_descriptor);
    my @missing = grep { ($manifest . $capture) !~ /\b\Q$_\E\b/ } @required;
    my $snapshot = eval {
        my $raw = Developer::Dashboard::Pax::Capture->new(mode => 'live')->capture("$self->{root}/t/fixtures/compile_phase.pl");
        Developer::Dashboard::Pax::Manifest->new(capture => $raw)->to_hash;
    };
    push @missing, 'executable_capture' if $@ || !$snapshot || ($snapshot->{capture}{status} // '') ne 'ok';
    push @missing, 'compile_phase_events' if !$snapshot || !@{ $snapshot->{compile_phase_events} // [] };
    push @missing, 'lexical_pads' if !$snapshot || !%{ $snapshot->{lexical_pads}{subs} // {} };
    push @missing, 'closure_descriptors' if !$snapshot || !%{ $snapshot->{closure_descriptors}{subs} // {} };
    push @missing, 'method_resolution' if !$snapshot || !%{ $snapshot->{method_resolution} // {} };
    return {
        id => 'full_semantic_snapshot_capture',
        description => 'Pads, closures, method metadata, regex metadata, and compile-time side effects are captured',
        status => @missing ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : 'Developer::Dashboard::Pax::Capture/Developer::Dashboard::Pax::Manifest',
    };
}

sub _check_optree_derived_hir_lowering {
    my ($self) = @_;
    my $hir = _slurp("$self->{root}/lib/Developer/Dashboard/Pax/HIR.pm");
    my $selector = _slurp("$self->{root}/lib/Developer/Dashboard/Pax/RegionSelector.pm");
    my $uses_manifest_shape = $hir =~ /source\}\{native_shape\}/ && $selector =~ /native_shape/;
    my $reads_source = $hir =~ /open\s+my\s+\$fh/ || $hir =~ /_slurp/;
    my $pipeline_ok = eval {
        my $capture = Developer::Dashboard::Pax::Capture->new(mode => 'live')->capture("$self->{root}/t/fixtures/native_leafs.pl");
        my $manifest = Developer::Dashboard::Pax::Manifest->new(capture => $capture)->to_hash;
        my $regions = Developer::Dashboard::Pax::RegionSelector->new(manifest => $manifest)->select;
        my $units = Developer::Dashboard::Pax::HIR->new(manifest => $manifest, regions => $regions->{selected})->lower_all;
        my ($unit) = grep { $_->{source}{native_shape} && @{ $_->{source}{optree_ops} // [] } } @$units;
        $unit ? 1 : 0;
    };
    return {
        id => 'optree_derived_hir_lowering',
        description => 'HIR lowering consumes captured optree/native metadata rather than reading source',
        status => ($uses_manifest_shape && !$reads_source && $pipeline_ok) ? 'passed' : 'blocked',
        evidence => 'lib/Developer/Dashboard/Pax/HIR.pm',
    };
}

sub _check_tiered_backend_architecture {
    my ($self) = @_;
    my $tier1 = eval { Developer::Dashboard::Pax::Backend::Tier1CraneliftEquivalent->new->metadata };
    my $tier2 = eval { Developer::Dashboard::Pax::Backend::Tier2LLVM->new->metadata };
    my @missing;
    push @missing, 'tier1' if !$tier1 || ($tier1->{tier} // 0) != 1;
    push @missing, 'tier2' if !$tier2 || ($tier2->{tier} // 0) != 2;
    push @missing, 'tier1_name' if !$tier1 || ($tier1->{name} // '') =~ /prototype/;
    push @missing, 'tier2_enabled' if !$tier2 || ($tier2->{status} // '') ne 'enabled';
    return {
        id => 'tiered_backend_architecture',
        description => 'Cranelift-equivalent Tier 1 and LLVM Tier 2 backend paths are present',
        status => @missing ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : 'Developer::Dashboard::Pax::Backend::Tier1CraneliftEquivalent/Developer::Dashboard::Pax::Backend::Tier2LLVM',
    };
}

sub _check_performance_observability_fields {
    my ($self) = @_;
    my @missing;
    my $bench = eval {
        Developer::Dashboard::Pax::Benchmark->new(pax_bin => "$self->{root}/bin/pax", iterations => 1)
            ->run_runtime_benchmark("$self->{root}/t/fixtures/simple.pl");
    };
    push @missing, 'benchmark_memory_impact' if $@ || !$bench || ref($bench->{memory_impact}) ne 'HASH';
    push @missing, 'benchmark_memory_delta' if !$bench || !exists $bench->{memory_impact}{delta_rss_kb};

    my $store = Developer::Dashboard::Pax::ProfileStore->new(threshold => 1);
    $store->record_dispatch({ region_name => 'gate', status => 'native', osr_event => 'promote' });
    $store->record_dispatch({ region_name => 'gate', status => 'fallback', osr_event => 'retire' });
    my ($region) = @{ $store->report->{regions} };
    push @missing, 'osr_promotion_events' if !$region || ($region->{osr_promotions} // 0) < 1;
    push @missing, 'osr_retirement_events' if !$region || ($region->{osr_retirements} // 0) < 1;

    return {
        id => 'performance_observability_fields',
        description => 'Benchmarking and profiling expose memory impact plus OSR promotion and retirement events',
        status => @missing ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : 'Developer::Dashboard::Pax::Benchmark/Developer::Dashboard::Pax::ProfileStore',
    };
}

sub _check_current_docs_no_gap_language {
    my ($self) = @_;
    my @paths = qw(
        project/BACKLOG.md
        DOCKER.md
        projects/sow-01-project-pax/SOW.md
        projects/sow-01-project-pax/implementation-status.md
        projects/sow-01-project-pax/sow-alignment-report.md
        projects/sow-01-project-pax/sow-gatekeeper-report.md
    );
    my @bad;
    for my $path (@paths) {
        my $content = _slurp("$self->{root}/$path");
        push @bad, $path if $content =~ /\b(?:placeholder|not_measured|interface_defined_pending|current prototype|prototype checkpoint|future hardening|remains future|not implemented)\b/i;
    }
    return {
        id => 'current_docs_no_gap_language',
        description => 'Current SOW status documents do not describe completed SOW-01 work as prototype, pending, placeholder, or future work',
        status => @bad ? 'blocked' : 'passed',
        evidence => @bad ? 'gap language in: ' . join(', ', @bad) : 'current SOW status documents',
    };
}

sub _check_broad_cpan_xs_matrix {
    my ($self) = @_;
    my $matrix = _slurp("$self->{root}/t/cpan_matrix.json");
    my $dist_count = () = $matrix =~ /"distribution"\s*:/g;
    my $has_xs = $matrix =~ /installed-xs-backed-cpan/;
    return {
        id => 'broad_cpan_xs_matrix',
        description => 'CPAN and XS matrix covers dual-life and XS-backed distributions',
        status => ($dist_count >= 7 && $has_xs) ? 'passed' : 'blocked',
        evidence => 't/cpan_matrix.json',
    };
}

sub _check_deopt_frame_fields {
    my ($self) = @_;
    my $content = _slurp("$self->{root}/lib/Developer/Dashboard/Pax/DeoptEngine.pm");
    my @required = qw(argv wantarray lexicals closure_environment exception_handlers exception_state caller debugger_stack);
    my @missing = grep { $content !~ /\b\Q$_\E\b/ } @required;
    return {
        id => 'arbitrary_frame_deopt',
        description => 'Deopt reconstruction includes arbitrary Perl frame fields',
        status => @missing ? 'blocked' : 'passed',
        evidence => @missing ? 'missing: ' . join(', ', @missing) : 'lib/Developer/Dashboard/Pax/DeoptEngine.pm',
    };
}

sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or return '';
    local $/;
    return <$fh> // '';
}

1;

__END__

=head1 NAME

Developer::Dashboard::Pax::Gatekeeper - release and SOW validation checks for PAX

=head1 SYNOPSIS

  my $gatekeeper = Developer::Dashboard::Pax::Gatekeeper->new(root => '.');
  my $report = $gatekeeper->sow01_report;

=head1 DESCRIPTION

C<Developer::Dashboard::Pax::Gatekeeper> provides internal validation checks used by development and
release gates. SOW-03 keeps these checks as module APIs while the public
C<bin/pax> command surface is limited to C<build> and C<run>.

=head1 METHODS

=head2 new

Creates a gatekeeper rooted at a repository path.

=head2 sow01_report

Returns the historical SOW validation report. The CLI-surface check now verifies
that the public command runner exposes only C<build> and C<run>, with lower-level
diagnostics retained as internal Perl APIs.

=head1 PURPOSE

This module keeps historical SOW and release-policy checks callable from Perl
so validation can be reused by gates and tests without reopening the public CLI
surface.

=head1 WHY IT EXISTS

PAX's own release history accumulated a set of statements of work (SOW-01,
etc.) each with concrete, checkable acceptance conditions - things like "the
CPAN/XS test matrix covers at least 7 dual-life distributions" or "deopt
frame reconstruction includes every required Perl frame field". Those
conditions used to be exercised through diagnostic subcommands that SOW-03
deliberately removed from the public CLI surface (C<bin/pax> now exposes
only C<build> and C<run>). Rather than lose the ability to verify them at
all, this module keeps every check as a plain Perl method, so a gate or
test can call C<sow01_report> (and friends) directly without needing a
public CLI command that would reopen the surface SOW-03 closed.

=head1 WHEN TO USE

Edit this file when adding a new named check to an existing SOW report
(follow the C<_check_*> naming and C<{id, description, status, evidence}>
result shape already used throughout), or when a check's pass/fail
condition needs to change because the code it inspects moved or was
renamed.

=head1 HOW TO USE

Construct with C<root> pointing at the repository checkout the checks
should inspect, then call the report method for the SOW you need (e.g.
C<sow01_report>). Each report aggregates its individual C<_check_*> calls
into a list of C<{id, description, status, evidence}> hashes - read
C<status> (C<passed> vs C<blocked>) per check, and C<evidence> for what to
look at when a check is blocked.

=head1 WHAT USES IT

PAX's own internal release/gate tooling calls this to verify SOW acceptance
conditions still hold before a release is considered valid, without
depending on any public CLI diagnostic surface.

=head1 EXAMPLES

Example 1:

  my $gatekeeper = Developer::Dashboard::Pax::Gatekeeper->new(root => '.');
  my $report = $gatekeeper->sow01_report;
  my @blocked = grep { $_->{status} eq 'blocked' } @$report;
  # @blocked lists every SOW-01 condition not currently satisfied

Example 2:

  for my $check (@$report) {
      print "$check->{id}: $check->{status} ($check->{evidence})\n";
  }

=cut
