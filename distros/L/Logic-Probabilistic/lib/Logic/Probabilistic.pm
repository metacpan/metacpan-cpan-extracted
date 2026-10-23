package Logic::Probabilistic;

use v5.38;
use experimental 'signatures';

our $VERSION = '0.01';

use Logic::Probabilistic::Program;
use Logic::Probabilistic::PFact;
use Logic::Probabilistic::PChoice;
use Logic::Probabilistic::Result;
use Logic::Probabilistic::Distribution;
use Logic::Probabilistic::Inference::Base;
use Logic::Probabilistic::Inference::Exact;
use Logic::Probabilistic::Inference::Rejection;
use Logic::Probabilistic::Inference::MCMC;
use Logic::Probabilistic::Serializer;

sub new ( $class, %args ) {
    return Logic::Probabilistic::Program->new(%args);
}

1;

__END__

=head1 NAME

Logic::Probabilistic - Probabilistic Logic Programming in Perl.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use v5.38;
    use Logic::Probabilistic::Syntax;

    prob_logic AlarmNet {
        pfacts {
            0.7 => burglary;
            0.2 => earthquake;
        }

        prule 0.9 => alarm { burglary; earthquake; }
        prule 0.8 => alarm { burglary; not { earthquake; } }
        prule 0.1 => alarm { not { burglary; } earthquake; }
    }

    # Condition on observing alarm
    query_prob AlarmNet::burglary, evidence => { alarm => 1 } -> my $b_given_alarm;
    say "P(burglary | alarm):   " . $b_given_alarm->probability;   # ~0.9897

    query_prob AlarmNet::earthquake, evidence => { alarm => 1 } -> my $e_given_alarm;
    say "P(earthquake | alarm): " . $e_given_alarm->probability; # ~0.2276

=head1 DESCRIPTION

C<Logic::Probabilistic> builds on L<Logic::Relational> to allow the association of probabilities with facts and rules, and queries that return probabilities and probability distributions. To do this, it uses Sato's Distribution Semantics to define and query over possible worlds.

C<Logic::Probabilistic> is most straightforwardly used with its syntax layer,  L<Logic::Probabilistic::Syntax>, which adds extra syntax to that of L<Logic::Relational> for declaring probabilistic logic programs, probabilistic facts and rules.

=head1 USAGE

=head2 Declaring a Probabilistic Model

use C<prob_logic modelName { ... }> to create a probabilistic model package.

    prob_logic CoinGame {
        # Independent Bernoulli probabilistic fact: 70% chance of heads
        pfact 0.70 => heads;

        # Deterministic rule: winning requires heads
        rule win {
            heads;
        }
    }

=head2 Declaring Probabilistic Facts (C<pfact>)

use C<pfact> and give the probability (between 0 and 1 inclusive).

    pfact 0.7 => burglary;
    pfact 0.2 => earthquake;
    
Probabilistic facts can take arguments. Each ground instance represents an independent random variable.

    pfact 0.9 => reliable_link('server_a', 'router_1');
    pfact 0.1 => unreliable_link('router_1', 'server_b');

When declaring multiple probabilistic facts, you can group them into a single C<pfacts { ... }> block without repeating the C<pfact> keyword on every line.

    pfacts {
        # Propositional events
        0.01 => burglary;
        0.02 => earthquake;

        # Parameterized relations and fractions
        0.90 => link('server_a', 'router_1');
        0.85 => link('router_1', 'server_b');
        1/6  => die_face(1);
    }
    
=head3 C<fact> and C<pfact>

Use C<fact> rather than C<pfact 1.0> when you want to declare definitive background knowledge.

    fact throws('John');
    fact taxes;
    fact edge('a', 'b');
    
It is important to know when to use C<fact> rather than C<pfact>. Although it is supeficially equivalent to C<pfact 1.0 >, a C<fact> is stored directly in the underlying relational logic engine and is not treated as a probabilistic variable, therefore it does not introduce any extra computational demand or create additional possible worlds. However, its associated probability cannot be changed from 1 using C<update_pfact> at a later time, making it unsuitable for learning or adaptive models.

=head2 Categorical Choices and Annotated Disjunctions (C<pchoice>)

Sometimes a variable has multiple mutually exclusive outcomes rather than a simple true/false state (e.g. rolling a 6-sided die). These variables can be declared using C<pchoice>.

    pchoice prize => [
        1/3 => 'door1',
        1/3 => 'door2',
        1/3 => 'door3',
    ];

In any possible world, exactly one outcome is active. You can also specify an optional null probability (where no outcome is chosen) if the probabilities do not sum to C<1.0>.

=head2 Rules and Probabilistic Rules

Rules (C<rule>) are Horn clauses as per L<Logic::Relational>.

    # Head with no arguments:
    rule alarm {
        burglary;
        alarm_cause_burglary;
    }

    # Head with arguments and logical variables:
    rule path($x, $y) {
        edge($x, $y);
    }

    rule path($x, $z) {
        edge($x, $y);
        path($y, $z);
    }
    
Use C<prule> to associate a probability with a rule.

    prule 0.5 => heads($c) {
        coin($c);
    }

    prule 0.1 => calls($x) {
        not { alarm; }
        person($x);
    }

    prule 0.2 => influences($x, $y) {
        person($x);
        person($y);
        $x \= $y;
    }

    # Propositional (0-arity) probabilistic rule
    prule 0.9 => alarm {
        burglary;
        earthquake;
    }

A C<prule> is formally de-sugared into two components: An independent auxiliary C<pfact> with the given probability (the 'cause'), and a deterministic Horn clause (C<rule>) which combines the body with the auxiliary cause. To have explicit control over the underlying variables, use this pattern directly, e.g.

    prob_logic BrokenWindow {
        # 1. Background facts
        fact throws('john');            # John throws with certainty (P = 1.0)
        pfact 0.50 => throws('mary');   # Mary throws with 50% probability

        # 2. Auxiliary causal mechanisms (probability that a throw breaks the glass)
        pfact 0.80 => break_cause('mary');
        pfact 0.60 => break_cause('john');

        # 3. Deterministic relational rule combining preconditions with causes
        rule break {
            fresh my $person;
            throws($person);
            break_cause($person);
        }
    }
    
=head2 Logical Inversion and Negation

You can query or condition on the negation of predicates using C<not { ... }>.

    rule not_cloudy {
        not {
            rain;
        };
    }

For query-level negative evidence, you can also use C<not_goal(...)> or boolean hash values (see below sections on querying).

=head2 Querying Point Probabilities with C<query_prob>

C<query_prob> evaluates a query against a model, optionally conditioning on observed evidence.

    query_prob MyModel::alarm -> my $result;
    say "P(alarm) = " . $result->probability;
    
C<query_prob> returns a L<Logic::Probabilistic::Result> with the following methods and overloading:

=head3 Overloading

B<Numeric context> causes the result to evaluate directly to the float probability.

    if ( $result > 0.50 ) { ... }

B<String context> formats the result into a summary including the probability and containing statistics relating to the inference engine (see below).

=head3 Methods

=over 4

=item * C<< $result->probability >>: Point probability estimate (float in C<[0.0, 1.0]>).

=item * C<< $result->ci($level) >>: Lower and upper bounds of the Wilson score interval (default level 0.95).

=item * C<< $result->ci_low($level) >> / C<< $result->ci_high($level) >>: Individual interval endpoints.

=item * C<< $result->method >>: The inference method used (C<exact>, C<rejection>, or C<mcmc>).

=item * C<< $result->total_samples >>: Number of worlds or samples evaluated.

=item * C<< $result->accepted_samples >>: Number of samples satisfying the evidence.

=item * C<< $result->r_hat >>: Gelman-Rubin convergence metric (MCMC only).

=item * C<< $result->ess >>: Effective Sample Size accounting for autocorrelation (MCMC only).

=item * C<< $result->chains >>: Number of Markov chains executed (MCMC only).

=item * C<< $result->is_converged($threshold) >>: Boolean checking whether C<< r_hat <= 1.05 >>.

=item * C<< $result->warnings >>: Array of diagnostic warning messages.

=item * C<< $result->has_gradients >>: Boolean checking whether analytical gradients are available.

=item * C<< $result->gradients >>: Hashref of exact parameter partial derivatives (C<< { $param => $derivative } >>).

=item * C<< $result->gradient($target) >>: Partial derivative with respect to a specific parameter name or C<pfact> object.

=back

=head2 Providing Evidence

Evidence can be specified using either C<evidence> or C<given>, supporting both positive observations and negative observations. If the observed evidence has zero probability, the engine raises the error: "Zero probability evidence: evidence cannot be satisfied in any possible world".

=head3 Boolean Hash Syntax

    # Condition on alarm being true and earthquake being false
    query_prob MyModel::burglary,
        evidence => { alarm => 1, earthquake => 0 } -> my $result;   

=head3 List of Goals

    # Condition on both John and Mary calling
    query_prob MyModel::burglary,
        evidence => [ MyModel::calls('John'), MyModel::calls('Mary') ] -> 
        my $result;

=head3 Pair List Syntax

    # Flat list of pairs
    query_prob MyModel::burglary,
        evidence => [ MyModel::calls('John') => 1, MyModel::calls('Mary') => 1 ] -> 
        my $result;

    # Nested list of pairs
    query_prob MyModel::burglary,
        evidence => [ [ MyModel::calls('John') => 1, MyModel::calls('Mary') => 1 ] ] -> 
        my $result;

    # Array of separate pairs
    query_prob MyModel::burglary,
        evidence => [   [ MyModel::calls('John') => 1 ], 
                        [ MyModel::calls('Mary') => 0 ] ] -> 
        my $result;

=head3 Direct Negation (C<not_goal>)

    query_prob MyModel::win,
        evidence => [ not_goal(MyModel::twoHeads()) ] -> my $result;

=head2 Querying Probability Distributions with C<query_dist>

When a query contains an unbound logical variable, you can query the complete probability distribution over all possible unified values using C<query_dist>.

    fresh my $who;
    query_dist BrokenWindow::throws($who) -> my $dist;

    say "Probability distribution over throwers:";
    say $dist;

Here, C<$dist> is a L<Logic::Probabilistic::Distribution> object providing moments (mean, variance, standard deviation), quantiles, CDFs, entropy, sampling, and formatted ASCII histogram tables. 

=head3 Overloading

Printing C<$dist> directly outputs a formatted statistical summary and ASCII bar chart.

=head3 Methods

=over 4

=item * C<< $dist->prob($val) >>: Probability of a specific value (C<< 0.0 >> if not observed).

=item * C<< $dist->mean >>, C<< $dist->variance >>, C<< $dist->std_dev >>: Statistical moments for numeric distributions.

=item * C<< $dist->mode >>: Most probable value.

=item * C<< $dist->min >>, C<< $dist->max >>: Extrema of numeric values.

=item * C<< $dist->entropy($base) >>: Shannon entropy (default base 2, in bits).

=item * C<< $dist->cdf($val) >>: Cumulative distribution function  C<< P(X <= x)  >>.

=item * C<< $dist->quantile($p) >>: Inverse CDF value for probability.

=item * C<< $dist->sample() >>: Draw a random value from the distribution according to its weights.

=item * C<< $dist->histogram_table($width) >>: Generate a custom-width ASCII chart string.

=item * C<< $dist->outcomes >>: Returns list of L<Logic::Probabilistic::Distribution::Outcome> objects representing individual values and their weights.

=back 

=head2 Inference Engines

C<Logic::Probabilistic> currently provides three inference engines which are appropriate for different problem scales and models: B<Exact Enumeration>, B<Forward Rejection Sampling>, and B<Markov Chain Monte Carlo>. The default is B<Exact Enumeration>.

=head3 Exact Enumeration

Exact enumeration generates all combinations of truth values for the probabilistic atoms (C<2^k> worlds for C<k> probabilistic facts). For each world, it checks whether the evidence and query succeed via L<Logic::Relational>.

    query_prob MyModel::burglary,
        evidence => ['alarm'],
        method   => 'exact'
        -> my $result;
        
    say $result; # P = 0.4075 (Exact, 32 worlds)

The benefit here is that the result is 100% exact. The downside is the exponential complexity which quickly slows the whole query down for even relatively small C<k>.

=head3 Forward Monte Carlo Rejection Sampling

Rejection sampling draws complete independent sample worlds directly from prior distributions. A sample is 'accepted' if it satisfies the evidence. Among accepted samples, the proportion where query succeeds estimates the probability. 

    query_prob MyModel::burglary,
        evidence => [ MyModel::calls('John'), MyModel::calls('Mary') ],
        method   => 'rejection',
        samples  => 10_000,
        seed     => 42
        -> my $result;
        
    say $result; 
    # Output: P = 0.4244 [95% CI: 0.3633 .. 0.4879] (10000 samples, rejection)

Every sampling result includes a Wilson score confidence interval computed at a 95% confidence level (or a given custom level).

    my ($low, $high) = $result->ci(0.95);
    say "95% confidence interval: $low .. $high";

The benefit of rejection sampling is that it can be much faster than exact enumeration, of course trading off between sample size/speed and the final accuracy of the probability estimation. However, the approach is 'embarrassingly parallel', so with the correct setup, high sample sizes can be obtained on many modern CPUs (see below). 

An occasional but major con with this approach is that if evidence is rare (e.g. C<P(Evidence) = 0.001>) almost all samples end up being rejected; thereby motivating the next approach.

=head3 Markov Chain Monte Carlo

The Metropolis-Hastings Markov Chain Monte Carlo ('MCMC') aims to solve the issue of very low evidence probabilities by taking a random walk only through the subspace of worlds that satisfy the evidence.

    query_prob MyModel::burglary,
        evidence => ['alarm'],
        method   => 'mcmc',
        chains   => 4, # 4 independent parallel Markov chains (default)
        samples  => 10_000, # 2500 samples per chain
        burn_in  => 1000,   # warmup transitions discarded before recording
        lag      => 10,     # subsample every 10 transitions to reduce autocorrelation
        seed     => 42
        -> my $result;
        
    say $result;
    # Output: P = 0.4150 [95% CI: 0.3720 .. 0.4580] (4 chains x 2500 samples, R-hat = 1.01, ESS = 1840, mcmc)
    
When using the MCMC method, it is important to verify convergence in case of mode-trapping. The following methods are provided for this:

    say "Chains:    " . $result->chains;
    say "R-hat:     " . $result->r_hat;
    say "ESS:       " . $result->ess;
    say "Converged: " . ($result->is_converged ? "yes" : "no");

=head2 Resource Management

The C<2^k> worlds that result from C<k> independent probabilistic facts can result in queries that are unsparing to CPU and RAM. Some methods are available for applying constraint.

=head3 World Enumeration Cap (C<max_worlds>)

When using the C<exact> inference method, the default limit is 4,096 worlds. (C<k = 12>). Exceeding this threshold causes the engine to display an error message rather than proceeding. If you have the available compute (or time to spare) then change C<max_worlds> as required.

    query_prob Model::goal, max_worlds => 65_536 -> my $result;
    query_prob Model::goal, max_worlds => 0 -> my $result; # 0 = unlimited
    
C<max_worlds> can also be configured at the model/program level.

    $Model::PROGRAM->max_worlds(16_384);

=head3 Timeout Guard (C<timeout>)

Set a maximum execution time in seconds. This is supported across all the inference engines. If execution exceeds the specified duration, it will abort with a timeout message.

    query_prob Model::goal, timeout => 5.0 -> my $result;
    
=head3 Parallel Rejection Sampling

Forward Monte Carlo rejection sampling is an embarrassingly parallel algorithm that scales across multiple CPU cores with near-linear speedup. Currently C<Logic::Probabilistic> does not itself provide a parallelization mechanism (for now preferring to leave the specific implementation to the user), but the basic approach is documented below and an example is provided (see C<examples/parallel_rejection.pl>).

=over 4

=item 1. 

Divide the total sample budget across worker processes (C<$samples / $num_workers>).

=item 2. 

Ensure each worker is initialized with a different PRNG seed to ensure they each explore independent random worlds.

=item 3. 

Collect the counts C<total_samples>, C<accepted_samples>, C<query_success_count> from each worker on finish.

=item 4. 

Construct a unified C<Logic::Probabilistic::Result> combining all worker counts.

=back

=head2 Managing Probabilistic Facts

In applications like parameter estimation, online sensor updates, reinforcement learning, and belief revision, fact probabilities often need to be altered dynamically without rebuilding the entire model. For managing C<pfacts> use the C<update_pfact>, C<set_pfact> and C<retract_pfact> methods, callable through the program object (the program object for C<prob_logic ModelName { ... }> can be accessed with C<$ModelName::PROGRAM>).

    use v5.38;
    use Logic::Probabilistic::Syntax;

    prob_logic SensorFusion {
        pfact 0.20 => sensor_alarm('cam1');
        pfact 0.15 => sensor_alarm('radar');

        rule intruder {
            sensor_alarm('cam1');
            sensor_alarm('radar');
        }
    }

    # 1. Query initial state
    query_prob SensorFusion::intruder -> my $res1;
    say "Initial P(intruder): $res1"; # ~0.0300

    # 2. Dynamically update camera sensor reading using $SensorFusion::PROGRAM
    $SensorFusion::PROGRAM->update_pfact(0.95, 'sensor_alarm', 'cam1');

    # 3. Upsert a new acoustic sensor reading
    $SensorFusion::PROGRAM->set_pfact(0.80, 'sensor_alarm', 'acoustic');

    # 4. Query again - reflecting the updated sensor probabilities
    query_prob SensorFusion::intruder -> my $res2;
    say "Updated P(intruder): $res2"; # ~0.1425

=head3 Updating with C<update_pfact>

Calling C<pfact> multiple times with the same predicate does not overwrite the earlier probability. Instead, it introduces multiple independent causes. To adjust the probability of an existing pfact, use C<update_pfact>.

    # Update probability in-place (supports either order of arguments):
    $prog->update_pfact(0.85, 'battery_low', 'drone_1');
    # or: $prog->update_pfact('battery_low', 0.85, 'drone_1');

    # Or pass a PFact object directly:
    my ($pf) = grep { $_->predicate eq 'battery_low' } $prog->all_pfacts;
    $prog->update_pfact($pf, 0.90);

Note that C<update_pfact> does not work on a fact declared with C<fact> (a C<fact> is a completely different object, it is not sugar for a C<pfact> with an implied probability of 1).

=head3 'Upsert' with C<set_pfact>

When you want to update an existing probabilistic fact if present, or create it if absent, use C<set_pfact>:

    # If 'sensor_ok(camera_front)' exists, updates its probability to 0.99.
    # If it does not exist, asserts it as a new pfact.
    $prog->set_pfact(0.99, 'sensor_ok', 'camera_front');

=head3 Retracting with C<retract_pfact> and C<retract_all_pfacts>

    # Retract the first matching pfact (returns the removed PFact object, or undef):
    my $removed = $prog->retract_pfact('sensor_alert');

    # Retract a specific ground atom:
    $prog->retract_pfact('node_down', 'alpha');

    # Retract all pfacts matching a predicate:
    my @removed_all = $prog->retract_all_pfacts('node_down');

=head3 Named-argument assertion with C<assert_pfact>

For low-level programmatic creation with full options use C<assert_pfact>.

    $prog->assert_pfact(
        probability => 0.75,
        predicate   => 'link_up',
        args        => ['router_a', 'router_b'],
        expires_in  => 60, # Optional TTL in seconds
    );

=head3 Time-to-live (TTL) and Expiring Facts

Probabilistic facts can be configured with an expiration lifetime (C<< expires_in => $seconds >>) or absolute epoch (C<< expires_at => $epoch >>). The inference engine automatically prunes expired facts before evaluating queries, or you can invoke manual cleanup.

    # Assert a transient belief valid for only 5 seconds:
    $prog->pfact(0.80, 'transient_glitch', { expires_in => 5 });

    # Prune any expired facts manually:
    my $pruned_count = $prog->cleanup_expired_pfacts();

=head2 Managing Categorical Choices

Categorical choices (annotated disjunctions) can also be mutated or removed dynamically using C<update_pchoice> and C<retract_pchoice>.

    # Update the probability distribution over outcomes in-place:
    $prog->update_pchoice('traffic', [
        [0.60, 'low'],
        [0.40, 'high'],
    ]);

    # Remove a categorical random variable entirely:
    $prog->retract_pchoice('traffic');
    
=head2 Model Persistence and Snapshots

C<Logic::Probabilistic> includes native JSON snapshot serialization via L<Logic::Probabilistic::Serializer>, allowing saving and loading from file. A snapshot captures:-

=over 4

=item * B<Probabilistic facts> (C<pfacts>)

Predicates, ground arguments, probabilities, and TTL expiration timestamps.

=item * B<Categorical choices> (C<pchoices>)

Predicates, base arguments, and outcome probability distributions.

=item * B<Deterministic background facts>

Horn clauses with empty bodies asserted into the relational program.

=item * B<Metadata>

Format version, engine identifier, model version, and export timestamp.

=back

Note: Rules with bodies remain defined in code; the snapshot serializes the factual knowledge base and parameter state.

=head3 Saving Snapshots (C<save_snapshot>)

C<save_snapshot> accepts a file path, an open filehandle, or an in-memory scalar reference. Passing C<pretty => 1> produces human-readable indented JSON.

    # 1. Save directly to a JSON file on disk:
    $prog->save_snapshot("model_state.json", pretty => 1);

    # 2. Save in-memory to a scalar variable:
    my $json_string;
    $prog->save_snapshot(\$json_string);

    # 3. Save to an open filehandle / stream:
    open my $fh, '>:encoding(UTF-8)', "state.json" or die $!;
    $prog->save_snapshot($fh);
    close $fh;

=head3 Loading Snapshots (C<load_snapshot>)

C<load_snapshot> restores facts into any existing or newly created program instance.

    # Load from a file on disk:
    my $loaded_count = $prog->load_snapshot("model_state.json");

    # Or load from an in-memory JSON string:
    $prog->load_snapshot(\$json_string);
    
=head3 Merge vs. Replace Modes

By default, C<load_snapshot> operates in 'replace' mode, clearing existing facts and choices while preserving compiled rules.

    # Replace mode (default): Wipes previous facts/choices and installs snapshot
    $prog->load_snapshot("checkpoint.json", mode => 'replace');

    # Merge mode: Combines snapshot facts with currently loaded facts
    $prog->load_snapshot("supplementary_beliefs.json", mode => 'merge');

=head3 Preserving TTLs in Simulations (C<< ttl_mode => 'relative' >>)

When saving facts with expiration lifetimes (C<< expires_in => $secs >>), storing an absolute timestamp means the fact might expire while the snapshot sits on disk.

To pause and resume simulations without losing remaining time-to-live, use relative TTL mode.

    # When reloading, adjust TTLs relative to the current time.
    $prog->load_snapshot("checkpoint.json", ttl_mode => 'relative');
    # or: $prog->load_snapshot("checkpoint.json", pause_ttl => 1);

=head2 Differentiable Logic Programming

C<Logic::Probabilistic> provides support for I<differentiable logic programming>. By treating probabilistic logical deduction as a differentiable function, exact analytical gradients can be computed and backpropagated into gradient-based optimizers and even neural networks, facilitating I<neurosymbolic> systems.

In exact inference mode, pass C<< with_gradients => 1 >> to compute exact partial derivatives with respect to all underlying Bernoulli facts and categorical choice outcomes. C<Logic::Probabilistic> computes these using boundary-safe prefix-suffix decision products, ensuring gradients evaluate with 100% numerical precision even when C<p_k = 0.0> or C<p_k = 1.0> (thereby avoiding division-by-zero errors).

    # Query with analytical gradients enabled
    my $res;
    query_prob Model::failure, with_gradients => 1 -> $res;

    # Check whether gradients are populated
    if ($res->has_gradients) {
        # Retrieve all gradients as a hashref
        my $grads = $res->gradients; # { 'fault_a' => 0.40, 'fault_b' => 0.60 }

        # Retrieve partial derivative for a specific fact (string name or PFact object)
        my $dp_da = $res->gradient('fault_a');
        say "dP / d(fault_a) = $dp_da";
    }


=head1 AUTHOR

Matt Johnson, C<< <mjohnson at affectivesilicon.com> >>

=head1 AI

This module was developed with assistance from various AI/LLM, particularly Gemini Flash 3.8.

=head1 SEE ALSO

L<Logic::Relational>, L<Logic::Probabilistic::Syntax>, L<Logic::Probabilistic::Program>,
L<Logic::Probabilistic::Distribution>, L<Logic::Probabilistic::Result>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Matt Johnson.

This is free software, licensed under the GNU General Public License, Version 3.

=cut

