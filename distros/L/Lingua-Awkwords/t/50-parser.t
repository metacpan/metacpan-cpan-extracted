#!perl
#
# parser tests. these of course depend on the various modules used by
# the parse not misbehaving

use strict;
use warnings;

use Test::Most;    # plan is down at bottom

my $deeply = \&eq_or_diff;

use Lingua::Awkwords::Parser;
use Lingua::Awkwords::Subpattern;

my $parser = Lingua::Awkwords::Parser->new;

my $test_counter = 0;

# various invalid forms to help confirm that the parser is not letting
# any old garbage through
#  -- https://tools.ietf.org/html/draft-thomson-postel-was-wrong-01
#
# TIL *64 is actually a valid pattern, as that's "nothing, weighted 64".
# This is not a very useful pattern; perhaps future versions can either
# simplify or fail on it, though if generating patterns on the fly there
# may be valid reasons for such a do-nothing. Also, ^bla is a valid
# pattern that filters bla from the empty string. Again perhaps better
# handled, somehow.
for my $bad (
    q{"meh},      q{["foo/bar]}, q{)},     q{]},
    q{(},         q{[},          q{(a/b/}, q{a*-1},
    q{[a*10*20]}, q{Z}
) {
    $test_counter++;
    dies_ok { $parser->from_string($bad) } "pattern >>>$bad<<< should fail";
}

my $ret;

# "abc" and just abc should be equivalent string parses
{
    $ret = $parser->from_string(q{"abc"});
    isa_ok($ret, 'Lingua::Awkwords::ListOf');
    is($ret->render, "abc");

    $ret = $parser->from_string(q{bcd});
    is($ret->render, "bcd");

    # filters! (this form is incompatible with the online version)
    $ret = $parser->from_string(q{cde^e});
    is($ret->render, "cd");

    $ret = $parser->from_string(q{cde^e^c});
    is($ret->render, "d");
}

# this form should be the same as the previous, explicit [] instead of
# the implication of such
{
    $ret = $parser->from_string(q{[def]});
    is($ret->render, "def");

    $ret = $parser->from_string(q{[efg]^f});
    is($ret->render, "eg");

    $ret = $parser->from_string(q{[fgh]^h^g^f});
    is($ret->render, "");
}

# whitespace only preserved within "quoted strings", including leading
# whitespace within those quotes. this required some fiddling with
# Parser::MGC to get right
{
    $ret = $parser->from_string(q{ ghi });
    is($ret->render, "ghi");

    $ret = $parser->from_string(q{ ghi "or not " });
    is($ret->render, "ghior not ");

    $ret = $parser->from_string(q{ ghi " also this" });
    is($ret->render, "ghi also this");
}

# subpatterns
{
    Lingua::Awkwords::Subpattern->update_pattern(Q => ['q']);
    $ret = $parser->from_string(q{ QQQ });
    is($ret->render, 'qqq');

    $ret = $parser->from_string(q{ Q o Q });
    is($ret->render, 'qoq');    # qoq is Klingon for robot, by the way
}

# (a) vs [a/] must produce the same results
{
    $ret = $parser->from_string(q{ (a) });

    srand 640;
    my @curl = map { $ret->render } 1 .. 10;

    my %uniq;
    @uniq{@curl} = ();
    $deeply->(\%uniq, { '' => undef, 'a' => undef });

    $ret = $parser->from_string(q{ [a/] });

    srand 640;
    my @sqrb = map { $ret->render } 1 .. 10;

    $deeply->(\@curl, \@sqrb);
}

# multiple alternatives
{
    $ret = $parser->from_string(q{ a/b/c/d });

    # NOTE has false(?) alarm'd on older perls on mswin32 where perhaps
    # the seed produces different random numbers than elsewhere (and
    # also next test)
    # http://www.cpantesters.org/cpan/report/ad196dad-6bfe-1014-88c5-db75185cf9ae
    # TODO make these author tests or statistical if it's more
    # widespread than old stuff running windows
    srand 640;
    my @alts = map { $ret->render } 1 .. 5;
    $deeply->(\@alts, [qw/b c c d a/]);
}

# recursion
{
    $ret = $parser->from_string(q{ [[a[b]][["c"]"d"]] });
    is($ret->render, 'abcd');

    $ret = $parser->from_string(q{ x[a/b]/y[c/d] });
    srand 640;
    my @recs = map { $ret->render } 1 .. 4;
    $deeply->(\@recs, [qw/xb yd xa yc/]);
}

plan tests => $test_counter + 18;
