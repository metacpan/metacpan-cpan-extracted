use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';

use lib ( 'lib', '../lib' );
use Time::HiRes qw(time);

# Use Parallel::ForkManager to parallelize rejection sampling

# Check for Parallel::ForkManager
my $has_fork_manager = 0;
try {
    require Parallel::ForkManager;
    $has_fork_manager = 1;
}
catch ($e) {
    warn "This example requires 'Parallel::ForkManager'.\n"
      . "Install it via CPAN: cpanm Parallel::ForkManager\n";
    exit 0;
}

use Logic::Probabilistic::Syntax;
use Logic::Probabilistic::Result;

# Pearl's classic Alarm Bayesian Network
prob_logic AlarmNet {

    # Prior probabilities of events
    pfact 0.01 => burglary;
    pfact 0.02 => earthquake;

    # Noisy causal triggers
    pfact 0.95 => alarm_cause_burglary;
    pfact 0.20 => alarm_cause_earthquake;
    pfact 0.01 => alarm_spontaneous;

    rule alarm {
        burglary;
        alarm_cause_burglary;
    } rule alarm {
        earthquake;
        alarm_cause_earthquake;
    } rule alarm {
        alarm_spontaneous;
    }
}

say "============================================================";
say "   Parallel Forward Rejection Sampling Demonstration";
say "============================================================";
say "Domain: Pearl's Alarm Network";
say "Query:  P(burglary | alarm)";
say "";

# 1. Exact Analytical Truth
my $p_exact;
query_prob AlarmNet::burglary, given => [AlarmNet::alarm]->$p_exact;
say sprintf( "1. Exact Analytical Baseline:  P = %.4f", $p_exact->probability );
say "";

# 2. Single-threaded Baseline
my $samples_single = 25_000;
say "2. Single-Threaded Rejection Sampling ($samples_single samples):";
my $t0_single = time();
my $res_single;
query_prob AlarmNet::burglary,
  given   => [AlarmNet::alarm],
  method  => 'rejection',
  samples => $samples_single,
  seed    => 42->$res_single;
my $elapsed_single = time() - $t0_single;

say "   Result:   " . $res_single->to_string;
say sprintf( "   Elapsed:  %.3f s (%.0f samples/sec)",
    $elapsed_single, $samples_single / ( $elapsed_single || 1 ) );
say sprintf(
    "   Accepted: %d / %d (%.2f%%)",
    $res_single->accepted_samples,
    $res_single->total_samples,
    ( $res_single->accepted_samples / $res_single->total_samples ) * 100
);
say "";

# 3. Parallel Multi-Core Rejection Sampling
my $num_workers        = 4;
my $samples_per_worker = 25_000;
my $total_target       = $num_workers * $samples_per_worker;

say
"3. Parallel Rejection Sampling ($num_workers workers x $samples_per_worker = $total_target samples):";

my $pm = Parallel::ForkManager->new($num_workers);

my $parallel_total    = 0;
my $parallel_accepted = 0;
my $parallel_success  = 0;

# Collect returned scalar metrics from worker processes
$pm->run_on_finish(
    sub (
        $pid, $exit_code, $ident,
        $exit_signal, $core_dump, $data_ref = undef
      )
    {
        if ( defined $data_ref ) {
            $parallel_total    += $data_ref->{total};
            $parallel_accepted += $data_ref->{accepted};
            $parallel_success  += $data_ref->{success};
        }
        return;
    }
);

my $t0_parallel = time();

for my $worker_id ( 1 .. $num_workers ) {
    $pm->start and next;

    # PRNG Seed Hygiene:
    # Each forked child must reseed to generate independent random worlds.
    srand( ( 1000 * $worker_id ) + 42 );

    my $res = $AlarmNet::PROGRAM->query(
        'burglary',
        evidence => ['alarm'],
        method   => 'rejection',
        samples  => $samples_per_worker,
    );

    # Send scalar counts back to the parent process
    $pm->finish(
        0,
        {
            total    => $res->total_samples,
            accepted => $res->accepted_samples,
            success  => $res->query_success_count,
        }
    );
}

$pm->wait_all_children;
my $elapsed_parallel = time() - $t0_parallel;

# Combine worker results into a unified Result object
my $res_parallel = Logic::Probabilistic::Result->new(
    probability => $parallel_accepted > 0
    ? ( $parallel_success / $parallel_accepted )
    : 0.0,
    evidence_probability => 1.0,
    method               => 'rejection',
    total_samples        => $parallel_total,
    accepted_samples     => $parallel_accepted,
    query_success_count  => $parallel_success,
);

say "   Result:   " . $res_parallel->to_string;
say sprintf( "   Elapsed:  %.3f s (%.0f samples/sec)",
    $elapsed_parallel, $parallel_total / ( $elapsed_parallel || 1 ) );
say sprintf(
    "   Accepted: %d / %d (%.2f%%)",
    $res_parallel->accepted_samples,
    $res_parallel->total_samples,
    ( $res_parallel->accepted_samples / $res_parallel->total_samples ) * 100
);
say "";

# 4. Performance & Precision Analysis
say "============================================================";
say "   Comparison Summary";
say "============================================================";
my ( $low_s, $high_s ) = $res_single->ci(0.95);
my ( $low_p, $high_p ) = $res_parallel->ci(0.95);
my $width_single   = $high_s - $low_s;
my $width_parallel = $high_p - $low_p;
my $speedup =
  ( $parallel_total / ( $elapsed_parallel || 1 ) ) /
  ( $samples_single / ( $elapsed_single   || 1 ) );

say sprintf( "Throughput Speedup:      %.2fx faster sample throughput",
    $speedup );
say sprintf( "Single-thread 95%% CI:    [%.4f .. %.4f] (span: %.4f)",
    $low_s, $high_s, $width_single );
say sprintf( "Parallel (%d cores) CI:   [%.4f .. %.4f] (span: %.4f)",
    $num_workers, $low_p, $high_p, $width_parallel );
say sprintf( "Uncertainty Reduction:   %.1f%% tighter error bound (1/sqrt(%d))",
    ( 1.0 - ( $width_parallel / $width_single ) ) * 100, $num_workers );
say "============================================================";

