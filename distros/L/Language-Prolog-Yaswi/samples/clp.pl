#!/usr/bin/perl

# Constraint Logic Programming from Perl
#
# Inspired by PerlMonks discussion
# http://perlmonks.org/?node_id=778356

use strict;
use warnings;

use Language::Prolog::Yaswi qw(:load :query);
use Language::Prolog::Sugar vars => [qw(A B C D E F)],
                            functors => [qw(problem)];

swi_inline <<EOP;

:- use_module(library(clpfd)).

problem(Vars) :-
	Vars = [A, B, C, D, E, F],
	Vars ins 0..1,
	A + E #=< 1,
	A + B #=< 1,
	C + E #=< 1,
	D + F #=< 1,
	B + D #=< 1,
	A + C + E #>= 1,
	B + D #>= 1,
	E + F #>=  1,
	D + F #= 1,
	A + E #=< 1,
	C + D #=< 1,
	A + B + C + D + E + F #= 3,
	label(Vars).

EOP

swi_set_query(problem([A, B, C, D, E, F]));
while (swi_next) {
    my @r = swi_vars(A, B, C, D, E, F);
    print join(', ', @r), "\n";
}


