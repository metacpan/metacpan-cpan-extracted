#!/usr/bin/perl

use lib 'blib/lib';
use Logic::Easy;
use strict;
$|=1;

=pod

Prolog code:

    append([], X, X).
    append([X|R], L, [X|S]) :- append(R, L, S).

In long form:

    sub append {
        my ($a, $b, $ab) = @_;
        
        my ($x, $r, $l, $s);
        $_ = Logic::Variable->new for $x, $r, $l, $s;

        Logic::Basic::Alternation->new(
            Logic::Data::Unify->new(
                [$a, $b, $ab], 
                [[], $x, $x],
            ),

            Logic::Basic::Sequence->new(
                Logic::Data::Unify->new(
                    [ $a, $b, $ab ],
                    [ Logic::Data::Cons->new($x, $r),
                      $l,
                      Logic::Data::Cons->new($x, $s) ],
                ),
                Logic::Basic::Rule->new(sub {
                    append($r, $l, $s),
                }),
            ),
        );
    }

=cut

sub append {
    vars my ($X, $R, $L, $S);
    Logic-> any(
        Logic-> is([@_], [[], $X, $X]),
        Logic-> is([@_], [cons($X, $R), $L, cons($X, $S)])
             -> rule(sub { append($R, $L, $S) }));
}

{
    vars my ($X, $Y);

    !append($X, $Y, [1..($ARGV[0] || 25)]) -> bind($X, $Y, sub {
        print "@$X ; @$Y\n";
        fail;
    });
}
