use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Script;

{
    my $parent = Gnuplot::Builder::Script->new;
    $parent->add("foo", "bar");
    $parent->set(a => "A", b => "B", c => "C");
    
    my $child = $parent->new_child;
    $child->set(d => "d child", b => "b child");
    $child->add("hoge");

    is $child->to_string, <<EXP, "original child";
foo
bar
set a A
set b b child
set c C
set d d child
hoge
EXP

    $parent->add("FOO", "BAR");
    $parent->delete_option("b");
    $parent->set(a => "A parent", e => "E parent");
    is $child->to_string, <<EXP, "modification to the parent is reflected to the child.";
foo
bar
set a A parent
set c C
FOO
BAR
set e E parent
set d d child
set b b child
hoge
EXP
}

done_testing;
