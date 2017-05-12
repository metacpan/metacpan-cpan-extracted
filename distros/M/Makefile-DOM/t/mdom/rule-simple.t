use lib 'inc';
use Test::Base;
use MDOM::Document::Gmake;
#use Smart::Comments;

plan tests => 8 * blocks();

run {
    my $block = shift;
    my $name = $block->name;

    my $dom = MDOM::Document::Gmake->new(\$block->src);
    ok $dom, "DOM tree okay - $name";
    my $rule = $dom->child(0);

    ok $rule, "Assignment obj okay - $name";
    my @got_targets = $rule->targets;
    my @expected_targets = eval $block->targets;
    die "eval targets failed ($name) - $@" if $@;
    is fmt(@got_targets), fmt(@expected_targets), "targets array okay - $name";
    is
        join('', @{ scalar($rule->targets) }),
        join('', @expected_targets),
        "targets calar okay - $name";

    ok $rule, "Assignment obj okay - $name";
    my @got_prereqs = $rule->normal_prereqs;
    my @expected_prereqs = eval $block->prereqs;
    die "eval prereqs failed ($name) - $@" if $@;
    is fmt(@got_prereqs), fmt(@expected_prereqs), "prereqs array okay - $name";
    is
        join('', @{ scalar($rule->normal_prereqs) }),
        join('', @expected_prereqs),
        "prereqs calar okay - $name";

    is $rule->colon, $block->colon, "colon okay - $name";

};

sub fmt {
    join ', ', map { "'$_'" } @_;
}

__DATA__

=== TEST 1:
--- src
 a.c b.cpp : a.h dir/hello.h
--- targets
'a.c', ' ', 'b.cpp'
--- colon:  :
--- prereqs
'a.h', ' ', 'dir/hello.h'


=== TEST 2:
--- src
 abc:: hello, world # this is a comment
--- targets
'abc'
--- colon:  ::
--- prereqs
'hello,', ' ', 'world'



=== TEST 3:
--- src
%.a :: b \
    c \
        d
--- targets
'%.a'
--- colon:  ::
--- prereqs
'b', ' ', "\\\n", '    ', 'c', ' ', "\\\n", '        ', 'd'

