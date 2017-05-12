use lib 'inc';
use Test::Base;
use MDOM::Document::Gmake;

plan tests => 8 * blocks();

run {
    my $block = shift;
    my $name = $block->name;

    my $dom = MDOM::Document::Gmake->new(\$block->src);
    ok $dom, "DOM tree okay - $name";
    my $assign = $dom->child(0);

    ok $assign, "Assignment obj okay - $name";
    my @got_lhs = $assign->lhs;
    my @expected_lhs = eval $block->lhs;
    die "eval lhs failed ($name) - $@" if $@;
    is fmt(@got_lhs), fmt(@expected_lhs), "lhs array okay - $name";
    is
        join('', @{ scalar($assign->lhs) }),
        join('', @expected_lhs),
        "lhs calar okay - $name";

    ok $assign, "Assignment obj okay - $name";
    my @got_rhs = $assign->rhs;
    my @expected_rhs = eval $block->rhs;
    die "eval rhs failed ($name) - $@" if $@;
    is fmt(@got_rhs), fmt(@expected_rhs), "rhs array okay - $name";
    is
        join('', @{ scalar($assign->rhs) }),
        join('', @expected_rhs),
        "rhs calar okay - $name";

    is $assign->op, $block->op, "op okay - $name";

};

sub fmt {
    join ', ', map { "'$_'" } @_;
}

__DATA__

=== TEST 1:
--- src
a := 3
--- lhs
'a'
--- op: :=
--- rhs
'3'


=== TEST 2:
--- src
 foo bar=hello, world !  # this is a comment
--- lhs
'foo', ' ', 'bar'
--- op: =
--- rhs
'hello,', ' ', 'world', ' ', '!', '  '



=== TEST 3:
--- src
@D ?= hello \
	world!
--- lhs
'@D'
--- op: ?=
--- rhs
'hello', ' ', "\\\n", "\t", 'world!'

