use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::JoinDict;
use lib "t";
use testlib::RefUtil qw(is_different);

my $dict = Gnuplot::Builder::JoinDict->new(
    separator => ":", content => [x => 1, y => 2]
);

{
    my $new_dict = $dict->set_all("hoge");
    is_different($new_dict, $dict, "set_all() returns a new object");
    is "$new_dict", "hoge:hoge", "set_all values to hoge";
    is $new_dict->get("x"), "hoge", "value x";
    is $new_dict->get("y"), "hoge", "value y";
}

is $dict->set(y => 3, z => 4)->set_all("foo")->to_string, "foo:foo:foo", "more elements";

{
    my $new_dict = $dict->set_all(undef);
    is "$new_dict", "", "set_all(undef) clears the values";
    is $new_dict->set(y => 8, x => 5, z => 9)->to_string, "5:8:9", "value order is fixed because keys are still present";
}

done_testing;
