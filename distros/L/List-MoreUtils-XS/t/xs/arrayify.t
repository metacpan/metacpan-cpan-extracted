#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
use lib ("t/lib");
use List::MoreUtils::XS (":all");


use Test::More;
use Test::LMU;
use Tie::Array ();

SCOPE:
{
    my @in = (1 .. 4, [5 .. 7], 8 .. 11, [[12 .. 17]], 18);
    my @out = arrayify @in;
    is_deeply(\@out, [1 .. 18], "linear flattened int mix i");
}

SCOPE:
{
    my @in = (1 .. 4, [[5 .. 11]], 12, [[13 .. 17]]);
    my @out = arrayify @in;
    is_deeply(\@out, [1 .. 17], "linear flattened int mix ii");
}

SCOPE:
{
    # typical structure when parsing XML using XML::Hash::XS
    my %src = (
        root => {
            foo_list => {foo_elem => {attr => 42}},
            bar_list => {bar_elem => [{hummel => 2}, {hummel => 3}, {hummel => 5}]}
        }
    );
    my @foo_elems = arrayify $src{root}->{foo_list}->{foo_elem};
    is_deeply(\@foo_elems, [{attr => 42}], "arrayified struct with one element");
    my @bar_elems = arrayify $src{root}->{bar_list}->{bar_elem};
    is_deeply(\@bar_elems, [{hummel => 2}, {hummel => 3}, {hummel => 5}], "arrayified struct with three elements");
}

SCOPE:
{
    my @in;
    tie @in, "Tie::StdArray";
    @in = (1 .. 4, [5 .. 7], 8 .. 11, [[12 .. 17]]);
    my @out = arrayify @in;
    is_deeply(\@out, [1 .. 17], "linear flattened magic int mix");
}

SCOPE:
{
    my (@in, @inner, @innest);
    tie @in,     "Tie::StdArray";
    tie @inner,  "Tie::StdArray";
    tie @innest, "Tie::StdArray";
    @inner  = (5 .. 7);
    @innest = ([12 .. 17]);
    @in     = (1 .. 4, \@inner, 8 .. 11, [@innest]);
    my @out = arrayify @in;
    is_deeply(\@out, [1 .. 17], "linear flattened magic int mixture");
}

SCOPE:
{
    my @in = (qw(av_make av_undef av_clear), [qw(av_push av_pop)], qw(av_fetch av_store), [['av_shift'], ['av_unshift']]);
    my @out = arrayify @in;
    is_deeply(
        \@out,
        [qw(av_make av_undef av_clear av_push av_pop av_fetch av_store av_shift av_unshift)],
        "linear flattened string mix i"
    );
}

leak_free_ok(
    arrayify => sub {
        my @in = (1 .. 4, [5 .. 7], 8 .. 11, [[12 .. 17]]);
        my @out = arrayify @in;
    },
    'arrayify magic' => sub {
        my (@in, @inner, @innest);
        tie @in,     "Tie::StdArray";
        tie @inner,  "Tie::StdArray";
        tie @innest, "Tie::StdArray";
        @inner  = (5 .. 7);
        @innest = ([12 .. 17]);
        @in     = (1 .. 4, \@inner, 8 .. 11, [@innest]);
        my @out = arrayify @in;
    }
);

SKIP:
{
    leak_free_ok(
        'arrayify with exception in overloading stringify at begin' => sub {
            my @in = (
                DieOnStringify->new, qw(av_make av_undef av_clear),
                [qw(av_push av_pop)],
                qw(av_fetch av_store),
                [['av_shift'], ['av_unshift']]
            );
            eval { my @out = arrayify @in; };
            diag($@) if ($@);
        },
    );
    leak_free_ok(
        'arrayify with exception in overloading stringify at end' => sub {
            my @in = (
                qw(av_make av_undef av_clear),
                [qw(av_push av_pop)],
                qw(av_fetch av_store),
                [['av_shift'], ['av_unshift']],
                DieOnStringify->new
            );
            eval { my @out = arrayify @in; };
            diag($@) if ($@);
        }
    );
}

done_testing;


