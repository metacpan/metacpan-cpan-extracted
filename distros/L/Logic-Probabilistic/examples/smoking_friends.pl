use v5.38;
use lib ( 'lib', '../lib' );
use Logic::Probabilistic::Syntax;

=pod

% Example from: https://dtai.cs.kuleuven.be/problog/tutorial/tutslides/02_more.html
% "An example of friends and smokers with cycles:"

person(1).
person(2).
person(3).
person(4).

friend(1,2).
friend(2,1).
friend(2,4).
friend(3,4).
friend(4,2).

0.3::stress(X):- person(X).
0.2::influences(X,Y):-person(X), person(Y).

smokes(X) :- stress(X).
smokes(X) :- friend(X,Y), influences(Y,X), smokes(Y).

0.4::asthma(X) :- smokes(X).

query(asthma(_)).
query(smokes(_)).
query(stress(_)).
query(influences(_,_)).

=cut


prob_logic FriendSmoking {

	facts {
		person('Alice');
		person('Bob');
		person('Clara');
		person('David');
	
		friend('Alice', 'Bob');
		friend('Bob', 'Alice');
		friend('Bob', 'David');
		friend('Clara', 'David');
		friend('David', 'Bob');		
	}

	# 0.3::stress(X):- person(X).
	# 0.2::influences(X,Y):-person(X), person(Y).
	# Although it is possible to define the 'stress' and 'influences' relations using prules
	# it is more optimal to declare a set of pfacts directly, as it avoids the runtime overhead
	# of prules. For prules over a fixed finite domain, consider using loops like the below to
	# define the relation as a list of pfacts.
	foreach my $name1 ('Alice', 'Bob', 'Clara', 'David') {
		pfact 0.3 => stress($name1);
		foreach my $name2 ('Alice', 'Bob', 'Clara', 'David') {
			if ( $name1 ne $name2 ) {
				pfact 0.2 => influences($name1, $name2);
			}
		}
	}		
		
	# uncomment the prules below and comment out the foreach loop block above to check the difference
	# in execution speed.
#	prule 0.3 => stress($x) {
#		person($x);
#	}

#	prule 0.2 => influences($x, $y) {
#		person($x);
#		person($y);
#		$x \= $y;
#	}	

	rule smokes($x) {
		stress($x);
	}
	
	rule smokes($x) {
		fresh my $y;
		friend($x, $y);
		influences($y, $x);
		smokes($y);
	}

	pfacts {
		0.4 => asthma_cause('Alice');
		0.4 => asthma_cause('Bob');
		0.4 => asthma_cause('Clara');
		0.4 => asthma_cause('David');
	}
	
	rule asthma($x) {
		smokes($x);
		asthma_cause($x);
	}
	
    # Generator to format influences(name1, name2) as a single compound string tuple
    generator stringify(3), sub ( $name1, $name2, $tuple ) {
        my $done = 0;
        return sub {
            return () if $done++;
            return [ $name1, $name2, "influences($name1, $name2)" ];
        };
    };
	
	rule influences_string($string) {
		fresh my ($x, $y);
		influences($x, $y);
		stringify($x, $y, $string);		
	}
	
}

fresh my $p;

say "Asthma:";
query_dist FriendSmoking::asthma($p),
  method  => 'rejection',
  samples => 5_000,
  seed    => 42->my $asthma_dist;
say $asthma_dist;
print "\n";

say "Smokes:";
query_dist FriendSmoking::smokes($p),
  method  => 'rejection',
  samples => 5_000,
  seed    => 42->my $smokes_dist;
say $smokes_dist;
print "\n";

say "Stress:";
query_dist FriendSmoking::stress($p),
  method  => 'rejection',
  samples => 5_000,
  seed    => 42->my $stress_dist;
say $stress_dist;
print "\n";

say "Influences:";
query_dist FriendSmoking::influences_string($p),
  method  => 'rejection',
  samples => 5_000,
  seed    => 42->my $influence_dist;
say $influence_dist;

