use v5.38;
use lib ( 'lib', '../lib' );
use Logic::Probabilistic::Syntax;

=pod

Example from: https://dtai.cs.kuleuven.be/problog/tutorial/basic/02_bayes.html

%%%
0.7::burglary.
0.2::earthquake.

0.9::alarm :- burglary, earthquake.
0.8::alarm :- burglary, \+earthquake.
0.1::alarm :- \+burglary, earthquake.

evidence(alarm,true).
query(burglary).
query(earthquake).
%%%

=cut

prob_logic Alarm {

	pfacts {
		0.7 => burglary;
		0.2 => earthquake;
	}

	prule 0.9 => alarm {
		burglary;
		earthquake;
	}

	prule 0.8 => alarm {
		burglary;
		not { earthquake; }
	}

	prule 0.1 => alarm {
		not { burglary; } 
		earthquake;
	}
	
}

# evidence(alarm,true).
# query(burglary).
query_prob Alarm::burglary, 
	evidence => { alarm => 1 }->my $burglary_given_alarm;
say "P(burglary) (given alarm): ", $burglary_given_alarm->probability;

# evidence(alarm,true).
# query(earthquake).
query_prob Alarm::earthquake,
	evidence => { alarm => 1 }->my $earthquake_given_alarm;
say "P(earthquake) (given alarm): ", $earthquake_given_alarm->probability;

=pod

%%%
person(john).
person(mary).

0.7::burglary.
0.2::earthquake.

0.9::alarm :- burglary, earthquake.
0.8::alarm :- burglary, \+earthquake.
0.1::alarm :- \+burglary, earthquake.

0.8::calls(X) :- alarm, person(X).
0.1::calls(X) :- \+alarm, person(X).

evidence(calls(john),true).
evidence(calls(mary),true).

query(burglary).
query(earthquake).
%%%

=cut

prob_logic AlarmCalls {

	facts {
		person('John');
		person('Mary');
	}

	pfacts {
		0.7 => burglary;
		0.2 => earthquake;
	}

	prule 0.9 => alarm {
		burglary;
		earthquake;
	}

	prule 0.8 => alarm {
		burglary;
		not { earthquake; }
	}

	prule 0.1 => alarm {
		not { burglary; } 
		earthquake;
	}

	prule 0.8 => calls($x) {
		alarm;
		person($x);
	}

	prule 0.1 => calls($x) {
		not { alarm; } 
		person($x);
	}

}

# evidence(calls(john),true).
# evidence(calls(mary),true).
# query(burglary).
query_prob AlarmCalls::burglary,
	evidence => [ AlarmCalls::calls('John') => 1, AlarmCalls::calls('Mary') => 1 ]
	->my $burglary_given_calls;
say "P(burglary) (given calls): ", $burglary_given_calls->probability;

# evidence(calls(john),true).
# evidence(calls(mary),true).
# query(earthquake).
query_prob AlarmCalls::earthquake,
	evidence => [ AlarmCalls::calls('John') => 1, AlarmCalls::calls('Mary') => 1 ]
	->my $earthquake_given_calls;
say "P(earthquake) (given calls): ", $earthquake_given_calls->probability;

