use v5.38;
use lib ( 'lib', '../lib' );
use Logic::Probabilistic::Syntax;

# Network Reliability model
prob_logic NetworkModel {

    # Network topology with independent failure/survival probabilities
    pfact 0.85 => link( 'a', 'b' );
    pfact 0.70 => link( 'a', 'c' );
    pfact 0.90 => link( 'b', 'd' );
    pfact 0.80 => link( 'c', 'd' );
    pfact 0.95 => link( 'd', 'e' );
    pfact 0.40 => link( 'c', 'e' );    # direct backup link from C to E

    # Bidirectional communication over active links
    rule connected( $u, $v ) {
        link( $u, $v );
    }

    # Recursive reachability: base case
    rule path( $x, $y ) {
        connected( $x, $y );
    }

    # Recursive reachability: transitive step
    rule path( $x, $y ) {
        fresh my $z;
        connected( $x, $z );
        path( $z, $y );
    }
}

say "=== Network Reliability and Graph Reachability ===";
say "Topology: Server 'a' transmits packets to destination 'e'";
say "Paths available: a->b->d->e, a->c->d->e, and direct backup a->c->e";

# 1. Exact overall network reliability P(path(a, e))
query_prob NetworkModel::path( 'a', 'e' )->my $res_exact;
say "\n1. Exact Network Reliability P(path('a', 'e')): " . $res_exact->probability;
say "   Evaluated over " . $res_exact->total_samples . " possible network failure states.";

# 2. Monte Carlo Rejection Sampling approximation
query_prob NetworkModel::path( 'a', 'e' ),
  method  => 'rejection',
  samples => 10_000,
  seed    => 42->my $res_mc;
say "2. Monte Carlo Estimate (10,000 trials): " . $res_mc->to_string;

# 3. MCMC Metropolis-Hastings approximation
query_prob NetworkModel::path( 'a', 'e' ),
  method  => 'mcmc',
  samples => 10_000,
  burn_in => 1000,
  lag     => 5,
  seed    => 42->my $res_mcmc;
say "3. MCMC Estimate (10,000 samples): " . $res_mcmc->to_string;

# 4. Partial route queries: reliability between intermediate hops
query_prob NetworkModel::path( 'a', 'd' )->my $res_ad;
say "\n4. Reliability to intermediate gateway 'd': " . $res_ad->probability;


