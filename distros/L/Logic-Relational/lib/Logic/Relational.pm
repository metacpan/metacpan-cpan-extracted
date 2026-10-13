package Logic::Relational;

use v5.38;
use experimental 'signatures';

=head1 NAME

Logic::Relational - A pure-Perl relational logic system.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

	use v5.38;
	use Logic::Relational::Syntax;

	# Declare a logic database/"knowledgebase"
	logic Family {
		# Single fact assertion
		fact parent('Alice', 'Bob');

		# Grouped facts block assertion
		facts {
			parent('Alice', 'Charlie');
			parent('Bob', 'Diana');
			parent('Bob', 'Edward');
			parent('Edward', 'Fran');
			parent('Fran', 'George');
			parent('Heather', 'Edward');
		}

		# Rule: $g is grandparent of $c IF $g is parent of $p AND $p is parent of $c
		rule grandparent($g, $c) {
		    fresh my $p;
		    parent($g, $p);
		    parent($p, $c);
		}
		
		# "Ancestor" rule
		# Base case: A parent is an ancestor
		rule ancestor($c, $d) {
		    parent($c, $d);
		}

		# Recursive case: $c is ancestor of $d if $c is parent of $p AND $p is ancestor of $d
		rule ancestor($c, $d) {
		    fresh my $p;
		    parent($c, $p);
		    ancestor($p, $d);
		}
	}

	# Query: "Who are the children of Alice?"
	query Family::parent('Alice', fresh my $child) -> my $q1;

	while (my $sol = $q1->next) {
		say "Alice is parent of: " . $sol->value($child);
	}

	# Query: "Who are the grandchildren of Alice?"
	query Family::grandparent('Alice', fresh my $grandchild) -> my $q2;

	while ( my $sol = $q2->next ) {
		say "Alice is grandparent of: " . $sol->value($grandchild);
	}

	# Query: "Who are the parents of Edward?"
	query Family::parent(fresh my $parent, 'Edward') -> my $q3;

	while (my $sol = $q3->next) {
		say "A parent of Edward is: " . $sol->value($parent);
	}

	# Query: "Who are the ancestors of George?"
	query Family::ancestor(fresh my $ancestor, 'George') -> my $q4;

	while (my $sol = $q4->next) {
		say "An ancestor of George is: " . $sol->value($ancestor);
	}

=head1 DESCRIPTION

C<Logic::Relational> provides a relational logic engine in pure Perl, offering logical variables, structural unification, facts, rules, and backtracking depth-first search. 

It is most straightforwardly used with its syntax layer, L<Logic::Relational::Syntax>, which provides a hybrid Perl/Prolog-like syntax. 

Various examples are in the "examples" folder.

=head1 USAGE

Instead of writing functions that calculate outputs from inputs, declare relations between terms. In a relation, there are no fixed "inputs" or "outputs". A relation simply describes a logical truth that holds between values. Relations are declared in a logic database which can then be queried.

=head2 Atoms, Variables and Structured Data

I<Atoms> are concrete scalar values such as strings ('Alice') or numbers (42).

I<Logical variables> are declared with C<fresh my $var;> or inside C<rule> signatures. Unlike Perl scalars which store fixed values, an unbound logical variable represents a placeholder that can be unified with any term.

I<Structured data objects> are represented as I<compound terms> consisting of a functor name and positional arguments. Compound terms are created using C<< term( functor => @arguments ) >>.

=head2 Facts, Rules, Goals and Backtracking

I<Facts> declare relations between atoms.

I<Rules> allow you to infer new facts from existing ones. A rule states: C<"Head is true IF Body goals are true">.

When evaluating rules, the engine performs depth-first backtracking search. If a rule path leads to failure, the engine automatically backtracks to the previous choice point and tries alternative facts or rules.

C<true_goal> provides a goal that always succeeds. C<fail_goal> provides a goal that forces failure and backtracking.

=head2 Query execution

To execute a query on a logic database, use the name of the logic database with the fact or rule to query, substituting logic variables to be bound as required. The query will return an iterator object that will yield solutions.

	# Execute a query and assign iterator
	query Family::grandparent('Alice', fresh my $child) -> my $q;

	# Option A: Step through solutions with iterator
	while (my $sol = $q->next) {
		say "Grandchild: " . $sol->value($child);
	}

	# Option B: Collect all solution objects directly (list or arrayref)
	my @sols = $q->all( limit => 100 );	# default limit: 10,000

	# Option C: Extract all reified values bound to a variable directly
	my @grandchildren = $q->all_values($child);

	# Option D: Extract deduplicated values bound to a variable
	my @unique_grandchildren = $q->distinct_values($child);

	# Option E: Extract tuples of multiple variables (deduplicated by default)
	query Family::parent(fresh my $p, fresh my $c) -> my $q_pairs;
	my @pairs = $q_pairs->all_tuples([$p, $c]);

=head2 Unification

Unification attempts to make two terms identical by finding a suitable set of variable bindings. If the terms cannot be unified, it returns C<undef>, allowing the search engine to backtrack cleanly without side effects. Use C<unify($x, $y)> or equivalent syntax C<$x := $y>.

There are unification-style tests available which do not bind variables:

=over 4

=item *

C<$x == $y;> B<Strict identity>. Tests if terms are currently syntactically identical without mutating variables.

=item *

C<$x \== $y;> B<Strict Non-Identity>. Succeeds if terms are not syntactically identical.

=item *

C<$x !:= $y;> B<Non-Unifiability>. Fails if C<$x> and C<$y> I<can> unify.

=back

When two terms are unified, the engine executes a recursive structural comparison following these rules:

=over 2

=item 1. Variable Dereferencing ("Walking")

Before comparing any two terms, both terms are dereferenced ("walked") through the current substitution environment. If a variable C<$X> was previously bound to C<'Alice'>, the unifier evaluates C<'Alice'> rather than the raw variable object.

=item 2. Unbound Logical Variables and the Occurs Check

If an unbound variable C<$X> is unified with another term C<$T>:

=over 4

=item *

If C<$T> is the exact same variable C<$X>, unification succeeds with no changes.

=item *

If C<$T> is another unbound variable C<$Y>, C<$X> and C<$Y> become aliased so that binding one in the future automatically binds the other.

=item *

If C<$T> is a concrete term, C<$X> is bound to C<$T>, provided that C<$T> does not contain C<$X>. The engine performs a strict B<occurs check> to prevent circular infinite structures (such as C<$X = f($X)>).

=back

=item 3. Compound Terms and Native Data Structures

=over 4

=item *

B<Compound Terms:> Two terms C<f(A1, A2)> and C<g(B1, B2)> unify if and only if their functors are identical (C<f eq g>), their arities match, and all corresponding arguments unify pairwise.

=item *

B<Native Perl Arrays:> Arrays unify element-by-element. Tail matching via C<rest($tail)> allows list destructuring (e.g. unifying C<[$head, rest($tail)]> with C<[1, 2, 3]> binds C<$head = 1> and C<$tail = [2, 3]>).

=item *

B<Native Perl Hashes:> Hashes unify by key. Unifying C<={ id => $id, _ => rest($r) }> with a payload matches specified keys while capturing optional remaining key/value pairs into C<$r>. C<slurp> can be used as an alias for C<rest> if preferred.

=back

=item 4. Atomic Values and Plain Scalars

Plain scalars (strings, numbers) and L<Logic::Relational::Atom> objects unify if and only if their string representations are identical under standard Perl string equality.

=back

=head2 List processing

Lists can be decomposed into their first element (C<$head>) and the remaining tail list (C<$tail>) using C<[$head, rest($tail)]> (C<slurp> is an equivalent syntax to C<rest> if preferred). For example:-

	use v5.38;
	use Logic::Relational::Syntax;

	logic ListRules {
		# Base case: $x is the head of the list
		rule list_member($x, [$x, rest($tail)]) {
			true_goal;
		}

		# Recursive case: $x is in the tail of the list
		rule list_member($x, [$y, rest($tail)]) {
			list_member($x, $tail);
		}
	}

	query ListRules::list_member('C', ['A', 'B', 'C', 'D', 'E']) -> my $q;
	if ( $q->next ) {
		say "'C' is a member of list ['A', 'B', 'C', 'D', 'E']";
	}
	else {
		say "'C' is not a member of list ['A', 'B', 'C', 'D', 'E']";
	}

=head2 Built-in relations

Some commonly-used relations are built-in and are automatically available through a logic block. See C<stdlib_demo.pl> in the examples.

=over 4

=item *

C<append($l1, $l2, $out)> - List concatenation and splitting e.g. C<append([1,2], [3,4], $res)>

=item *

C<member($elem, $list)> - List membership and element generation e.g. C<member($x, ['a', 'b', 'c'])>

=item *

C<not_member($elem, $list)> - List non-membership (unification check) e.g. C<not_member('x', ['a', 'b', 'c'])>

=item *

C<length($list, $len)> - Relates a list to its integer length e.g. C<length([10, 20], $len)>

=item *

C<reverse($list, $rev)> - Reverses a list relationally e.g. C<reverse([1, 2, 3], $rev)>

=item *

C<select($elem, $list, $rest)> - Removes or inserts an element e.g. C<select('b', ['a','b','c'], $rest)>

=item *

C<permutation($list, $perm)> - Generates list permutations e.g. C<permutation([1, 2], $perm)>

=item *

C<between($low, $high, $val)> - Backtracking integer generator e.g. C<between(1, 10, $val)>

=item *

C<succ($x, $y)> - Successor relation (y = x + 1) e.g. C<succ(5, $next)>

=item *

C<min($x, $y, $min)> - Relational minimum e.g. C<min(10, 20, $m)>

=item *

C<max($x, $y, $max)> - Relational maximum e.g. C<max(10, 20, $m)>

=back


=head2 Arithmetic binding

To perform mathematical calculations once variables become ground (bound to concrete values), use the arithmetic evaluation operator "is": (C<< $var is <expr>; >>). For example, C<$n1 is $n - 1;> evaluates C<$n - 1> once C<$n> is bound, and unifies the result with C<$n1>.

=head2 Constraint Logic Programming (CLP(FD))

There is some support for Constraint Logic Programming over Finite Domains, which is useful for certain problems.

CLP(FD) operates in three phases:

=over 4

=item 1. 

B<Domain Declaration>: Constrain variables to integer ranges using C<$var in MIN..MAX;> or to a discrete list of integers using C<$var in [1, 4, 9, 16];>.

=item 2. 

B<Constraint Network>: Assert relationships (such as C<all_different($x, $y, $z)>).

=item 3. 

B<Labeling / Instantiation>: Trigger backtracking search using C<label($x, $y, $z)>.

=back

CLP(FD) arithmetic constraints (C<< #= >>, C<< #< >>, C<< #> >>, C<< #<= >>, C<< #>= >>, C<< #/= >>) allow mathematical relationships to be asserted on unbound domain variables before and during search.

	use v5.38;
	use Logic::Relational::Syntax;

	# 3x3 Magic Square solver using declarative CLP(FD) arithmetic constraints (#=)
	logic MagicCLPFD {

		rule solve($square) {

		    # Declare cells and constrain their integer domain to 1..9
		    fresh my ( $m11, $m12, $m13, $m21, $m22, $m23, $m31, $m32, $m33 ) in 1..9;

		    # Output square structure
		    $square := [ $m11, $m12, $m13, $m21, $m22, $m23, $m31, $m32, $m33 ];

		    # Constraint 1: All cells must be distinct
		    all_different( $m11, $m12, $m13, $m21, $m22, $m23, $m31, $m32, $m33 );

		    # Constraint 2: Declarative CLP(FD) row sum constraints (#=)
		    $m11 + $m12 + $m13 #= 15;
		    $m21 + $m22 + $m23 #= 15;
		    $m31 + $m32 + $m33 #= 15;

		    # Constraint 3: Declarative CLP(FD) column sum constraints (#=)
		    $m11 + $m21 + $m31 #= 15;
		    $m12 + $m22 + $m32 #= 15;
		    $m13 + $m23 + $m33 #= 15;

		    # Constraint 4: Declarative CLP(FD) diagonal sum constraints (#=)
		    $m11 + $m22 + $m33 #= 15;
		    $m31 + $m22 + $m13 #= 15;

		    # Trigger backtracking search labeling
		    label( $m11, $m12, $m13, $m21, $m22, $m23, $m31, $m32, $m33 );
		}
	}

	# Run logic query
	query MagicCLPFD::solve( fresh my $sol )->my $q;

	my $count = 0;
	while ( my $s = $q->next ) {
		$count++;
		my $p = $s->value($sol);
		say "Solution #$count:\n";
		say "+---+---+---+";
		say "| $p->[0] | $p->[1] | $p->[2] |";
		say "+---+---+---+";
		say "| $p->[3] | $p->[4] | $p->[5] |";
		say "+---+---+---+";
		say "| $p->[6] | $p->[7] | $p->[8] |";
		say "+---+---+---+\n";
	}

=head3 Unification in CLP(FD)

If a domain-constrained variable C<$X> (e.g. C<$X in [1..5]>) is unified with another domain variable C<$Y> (e.g. C<$Y in [3..8]>), the unifier computes the set intersection of their domains (C<[3..5]>). If the resulting domain is empty, unification fails. If the intersection leaves a single value, the variable is automatically bound to that scalar.

=head2 Disjunction blocks

Disjunction (OR) represents branching choice points. While defining multiple C<rule>s with the same name creates top-level disjunction, you can create inline choice points inside a single rule body using C<either { ... } or { ... }>. Any number of C<or { ... }> blocks can follow an C<either { ... }>

	logic AccessControl {
		rule valid_user($user, $role) {
		    user_account($user, $role);
		    either {
		        unify($role, 'admin');
		    }
		    or {
		        unify($role, 'editor');
		    }
		    or {
		        unify($role, 'moderator');
		    }
		}
	}

=head2 Negation-as-Failure

Negation is implemented as Negation-as-Failure. Therefore, C<not { Goal }> succeeds if C<Goal> fails, and fails if C<Goal> succeeds.

	logic Security {
		fact banned_ip('192.168.1.50');
		fact banned_ip('10.0.0.99');

		# Access is allowed if IP is NOT banned
		rule allow_access($ip) {
		    not {
		        banned_ip($ip);
		    }
		}
	}

Variables inside a C<not { ... }> block must be ground (bound to concrete values) at evaluation time.

=head2 Subgoal Tabling (Memoization) and Cycle Handling

Standard depth-first relational search can struggle with cyclic data structures (such as bidirectional networks or graphs with loops) and left-recursive rules. C<Logic::Relational> provides two complementary mechanisms to handle recursion safely and efficiently:

=over 4

=item 1. B<Automatic Ancestor Cycle Pruning (Always Active)>

During rule evaluation, the engine tracks active ancestor calls along the current derivation path. If a recursive subgoal is called with arguments that are structurally identical (up to variable renaming) to an active ancestor call on the same branch, that branch is automatically pruned. This prevents infinite loops on cyclic graphs without requiring manual "visited" lists, while still exploring every distinct simple path. Structural recursion (such as list processing with C<append> or C<member>) is unaffected because recursive calls operate on progressively smaller substructures.

=item 2. B<Subgoal Tabling / Answer Memoization (C<table>)>

Declaring a predicate as I<tabled> instructs the engine to memoize unique answers for each subgoal call signature and evaluate recursive dependencies to a least fixpoint. Tabling provides three main benefits:

=over 4

=item *

B<Left-Recursion Support:> Rules such as C<reachable($x, $z) :- reachable($x, $y), edge($y, $z)> terminate cleanly instead of recursing infinitely.

=item *

B<Answer Deduplication:> On diamond-shaped or cyclic graphs where multiple paths lead to the same conclusion, a tabled predicate yields each unique answer only once.

=item *

B<Dynamic Programming Performance:> Repeated subgoals within a query reuse cached answers instead of recomputing derivations.

=back

=back

Use the C<table> keyword inside a C<logic> block to enable tabling for one or more predicates by C<name/arity> (or C<name/*> for all arities):

	logic Network {
		table reachable/2;

		facts {
			edge('A', 'B');
			edge('B', 'C');
			edge('C', 'A');    # cycle
			edge('C', 'D');
		}

		rule reachable($x, $y) {
			edge($x, $y);
		}

		# Left-recursive rule over a cyclic graph
		rule reachable($x, $z) {
			fresh my $y;
			reachable($x, $y);
			edge($y, $z);
		}
	}

	my $q;
	query Network::reachable('A', fresh my $node) -> $q;
	my @nodes = $q->all_values($node);    # ('A', 'B', 'C', 'D')

See C<tabling_and_cycles.pl> in the examples.

=head2 Guards

Use C<guard> to run Perl code inside a logic rule. For example:-

	guard([$age, $status], sub ($a, $s) {
		return $a >= 18 && $s eq 'active';
	});

C<$vars>: Array reference of logical variables passed into the subroutine.

C<sub>: Perl subroutine that receives the reified scalar values of those variables and returns a boolean (C<1> for goal success, C<0> for failure).

=head2 Generators

Use a C<generator> to access Perl iterator subroutines. On backtracking the iterator will be called to provide the subsequent value.

	logic Streams {
		# Generator named fibonacci with arity 1: fibonacci(N)
		generator fibonacci(1) sub ($n) {
		    my $f0 = 0;
		    my $f1 = 1;

		    # Returns an iterator closure that yields 1-element tuple arrayrefs
		    return sub {
		        my $curr = $f0;
		        $f0 = $f1;
		        $f1 = $curr + $f1;
		        return [$curr];
		    };
		};
	}

	query Streams::fibonacci( fresh my $val )->my $q;
	
	my $count = 0;
	while ( my $sol = $q->next ) {
		# Careful: will run indefinitely if not limited
		last if ++$count > 10;
		say "Fibonacci #$count = " . $sol->value($val);
	}

=head2 Accessing the program object

Inside any package declared with C<logic PackageName { ... }>, a package variable C<$PROGRAM> (e.g. C<$PackageName::PROGRAM>) is automatically instantiated. You can use C<$PROGRAM> to perform runtime operations, such as asserting and retracting facts:-

	logic AccessControl {
		fact user('alice', 28);
	}

	# assert a fact
	$AccessControl::PROGRAM->fact( user => 'bob', 30 );

	# assert a fact and get its unique clause ID
	my $clause_id = $AccessControl::PROGRAM->fact( user => 'charlie', 34 );
	
	# retract all facts matching the term pattern
	$AccessControl::PROGRAM->retract( user => 'bob', 30 );
	
	# retract a fact by its specific clause id
	$AccessControl::PROGRAM->retract_clause($clause_id);

	# enable, check, or disable subgoal tabling at runtime
	$AccessControl::PROGRAM->table('reachable/2');
	my $is_tabled = $AccessControl::PROGRAM->is_tabled('reachable/2');
	$AccessControl::PROGRAM->untable('reachable/2');
	
When a query iterator is created, it operates on an immutable snapshot of the program version at that moment, meaning that assertions or retractions made mid-query will not affect running queries.
	
For scenarios where facts should only exist for the duration of a specific task or block (such as hypothetical reasoning or request-scoped context), use C<with_facts>:

	$AccessControl::PROGRAM->with_facts(
		[
		    [ user => 'temp_guest', 25 ],
		    [ user => 'visitor', 30 ],
		],
		sub {
		    # Inside this callback, temp_guest and visitor exist as facts
		    query AccessControl::user(fresh my $u, fresh my $a) -> my $q;
		    while (my $sol = $q->next) {
		        say "User: " . $sol->value($u);
		    }
		}
	);

After the callback completes (even if an exception occurs), the temporary facts are automatically retracted.

=head2 Transactions

It is possible to wrap multiple database changes in an atomic transaction.

	try {
		$AccessControl::PROGRAM->transaction(sub {
			# make various changes 
		    $AccessControl::PROGRAM->fact( user => 'dave', 21 );
		    
		    # do various checks...
		    
		    # If an exception is thrown, all changes inside the block are rolled back.
		    die "Operation aborted due to some failure";
		});
	}
	catch ($e) {
		say "Transaction rolled back cleanly: $e";
	}

=head2 Expiring and mutating facts

Facts can be asserted with an explicit Time-To-Live (TTL) using C<assert_fact>:

	# Fact expires in 10 seconds
	$AccessControl::PROGRAM->assert_fact(
		term       => [ session => 'alice_token', 'active' ],
		expires_in => 10,
	);

	# Fact expires at a specific Unix timestamp
	$AccessControl::PROGRAM->assert_fact(
		term       => [ session => 'bob_token', 'active' ],
		expires_at => time + 300,
	);

	# Declarative Fact Mutation (expire_to)
	# At the time of expiry, a fact can mutate
	$AdventureGame::PROGRAM->assert_fact(
		term       => [ match_state => 'lit', 'storeroom' ],
		expires_in => 10,
		expire_to  => [ match_state => 'burnt_out', 'storeroom' ],
	);

=head2 Monitoring

Register an observer callback to monitor insertions and retractions.

	$PROGRAM->on_change(sub ($event) {
		my $op     = $event->operation; # 'assert' or 'retract'
		my $clause = $event->clause;
		say "EVENT: $op on clause " . $clause->head->as_string;
	});	
	
To debug complex logic programs or inspect how the engine traverses search trees, attach a trace listener to a query.	

	query MyProgram::my_pred(fresh my $x) -> my $q;

	$q->trace(sub ($event) {
		my $type = $event->type; # 'call', 'exit', 'redo', 'fail'
		my $goal = $event->goal;
		say sprintf("TRACE [%-5s] Goal: %s", $type, $goal->as_string);
	});
	
	while ( my $sol = $q->next ) {
		say $sol->value($x)
	}

=head2 Saving and Loading

Use C<save_snapshot> and C<load_snapshot> to save and load facts in a program to JSON file on disk on in memory.

	# Save current dynamic facts and metadata to a JSON snapshot file
	$AccessControl::PROGRAM->save_snapshot("save.json");

	# Or save directly to a scalar reference
	my $json_str;
	$AccessControl::PROGRAM->save_snapshot(\$json_str);

	# Load snapshot back from disk (mode => 'replace' clears dynamic facts while preserving static rules)
	$AccessControl::PROGRAM->load_snapshot("save.json", mode => 'replace');

	# Blend snapshot facts into existing database
	$AccessControl::PROGRAM->load_snapshot("save.json", mode => 'merge');

	# Relative TTL Mode (Game / Simulation Time): Pauses expiring facts when saved,
	# resuming their remaining TTL from the moment the snapshot is reloaded
	$AccessControl::PROGRAM->load_snapshot("save.json", ttl_mode => 'relative');

C<save_snapshot> exports ground facts and their metadata. When C<load_snapshot(mode => 'replace')> is called, it clears existing dynamic facts while preserving static logic C<rule> definitions compiled into the code.

=head3 TTL Modes for Expiring Facts

C<ttl_mode => 'absolute'> (default): Wall-clock time keeps ticking while saved on disk.

C<ttl_mode => 'relative'> (or C<pause_ttl => 1>): Game/simulation time pauses while saved on disk. When reloaded, expiring facts resume with their exact C<remaining_ttl> relative to the moment of loading.
	
=head1 SEE ALSO

L<AI::Prolog>

=cut

use Logic::Relational::DSL ();
our @EXPORT_OK = @Logic::Relational::DSL::EXPORT_OK;
use parent 'Exporter';

# Re-export symbols
for my $sym (@EXPORT_OK) {
    no strict 'refs';
    *{$sym} = \&{"Logic::Relational::DSL::$sym"};
}

=head1 AUTHOR

Matt Johnson <mjohnson@affectivesilicon.com>

=head1 AI

This module was developed with assistance from various AI/LLM, specifically ChatGPT 5.5 and Gemini Flash 3.5/3.6/3.8.

=head1 BUGS

Please report any bugs or feature requests to C<bug-logic-relational at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Logic-Relational>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Logic::Relational


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Logic-Relational>

=item * Search CPAN

L<https://metacpan.org/release/Logic-Relational>

=back


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Matt Johnson <mjohnson@affectivesilicon.com>.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007


=cut

1;

