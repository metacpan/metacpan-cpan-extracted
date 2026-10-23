use v5.38;
use lib ( 'lib', '../lib' );
use Logic::Probabilistic::Syntax;

=pod

Example from: https://dtai.cs.kuleuven.be/problog/tutorial/various/02_bousi.html

%% PROXIMITY EQUATIONS
0.5::equals(does_not, a_little).
0.2::equals(a_little, very_much).
0.1::equals(does_not, so_much).
0.6::equals(so_much, very_much).
0.5::equals(a_little, so_much).

%% FACTS
likes(john, whiskey, a_little).
likes(mary, whiskey, very_much).
likes(peter, whiskey, so_much).
likes(paul, whiskey, does_not).

%% RULES
equals(X,X).
equals(X,Y) :- equals(Y,X).

buy(X,P) :- likes(X, P, L), equals(L, very_much).

%% QUERY
query(buy(X, whiskey)).

=cut

prob_logic Whiskey {

	pfacts {
		0.5		=>	equals('does not', 'a little');
		0.2		=>	equals('a little', 'very much');
		0.1		=>	equals('does not', 'so much');
		0.6		=>	equals('so much', 'very much');
		0.5		=>	equals('a little', 'so much');
	}
	
	facts {
		likes('John', 'whiskey', 'a little');
		likes('Mary', 'whiskey', 'very much');
		likes('Peter', 'whiskey', 'so much');
		likes('Paul', 'whiskey', 'does not');	
	}
	
	rule equals($x, $x) { }
	rule equals($x, $y) {
		equals($y, $x);
	}
	
	rule buy($x, $p) {
		fresh my $l;
		likes($x, $p, $l);
		equals($l, 'very much');
	}	
}

say "Who buys whiskey?";
query_dist Whiskey::buy(fresh my $p, 'whiskey')->my $dist;
say $dist;

