use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;

{
    my $parent = Gnuplot::Builder::Script->new;
    my $child = $parent->new_child;
    $parent->set(a => "opt a");
    $parent->add("added sentence");
    $parent->define(a => "def a");
    is $child->to_string, <<EXP, "child is empty";
set a opt a
added sentence
a = def a
EXP

    $child->setq(a => "hoge");
    $child->add("added by child");
    is $child->to_string, <<EXP, "sentence added to child is appended";
set a 'hoge'
added sentence
a = def a
added by child
EXP

    $child->define(b => "def b child");
    $child->define(a => []);
    $child->add("added by child 2");
    is $child->to_string, <<EXP, "disable parent's definition by setting it to []";
set a 'hoge'
added sentence
added by child
b = def b child
added by child 2
EXP

    $child->delete_definition("a");
    is $child->to_string, <<EXP, "restore parent's definition by delete_definition()";
set a 'hoge'
added sentence
a = def a
added by child
b = def b child
added by child 2
EXP
}

done_testing;
