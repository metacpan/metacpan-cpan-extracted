use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;

sub create_pair {
    my $parent = Gnuplot::Builder::Script->new;
    return ($parent, $parent->new_child);
}

{
    my ($parent, $child) = create_pair;
    isa_ok $child, "Gnuplot::Builder::Script";
    my @parent_code_args = ();
    $parent->set(
        string => "hoge",
        array => [1,2],
        undef => undef,
        code  => sub {
            push(@parent_code_args, \@_);
            ok wantarray, "list context OK";
            return "from parent";
        }
    );
    is $child->to_string, <<EXP, "child inherits all options from parent";
set string hoge
set array 1
set array 2
unset undef
set code from parent
EXP
    is scalar(@parent_code_args), 1, "code called once";
    identical $parent_code_args[0][0], $child, "code called with the child (not parent!)";
    is $parent_code_args[0][1], "code", "code called with the key";
    @parent_code_args = ();

    is_deeply [$child->get_option("string")], ["hoge"], "get parent's string";
    is_deeply [$child->get_option("array")], [1, 2], "get parent's array";
    is_deeply [$child->get_option("undef")], [undef], "get parent's undef";
    is_deeply [$child->get_option("code")], ["from parent"], "get parent's code";
    is scalar(@parent_code_args), 1, "code called once";
    is scalar($child->get_option("string")), "hoge", "get parent's string (scalar)";
    is scalar($child->get_option("array")), 1, "get parent's array (scalar)";
    is scalar($child->get_option("undef")), undef, "get parent's undef (scalar)";
    is scalar($child->get_option("code")), "from parent", "get parent's code (scalar)";
    @parent_code_args = ();

    my @child_code_args = ();
    $child->set(
        array => "not array",
        string => undef,
        undef => [],
        code => sub {
            push(@child_code_args, \@_);
            ok wantarray, "list context OK";
            return "from child";
        },
        "child only" => "CHILD",
    );
    is $child->to_string, <<EXP, "child settings should override parent's";
unset string
set array not array
set code from child
set child only CHILD
EXP
    is scalar(@parent_code_args), 0, "parent code not called";
    is scalar(@child_code_args), 1, "child code called once";
    identical $child_code_args[0][0], $child, "child code called with the child";
    is $child_code_args[0][1], "code", "key OK";
    @parent_code_args = @child_code_args = ();
    
    is_deeply [$child->get_option("string")], [undef], "get child's string";
    is_deeply [$child->get_option("array")], ["not array"], "get child's array";
    is_deeply [$child->get_option("undef")], [], "get child's undef";
    is_deeply [$child->get_option("code")], ["from child"], "get child's code";
    is scalar(@child_code_args), 1, "child code called once";
    is scalar($child->get_option("string")), undef, "get child's string (scalar)";
    is scalar($child->get_option("array")), "not array", "get child's array (scalar)";
    is scalar($child->get_option("undef")), undef, "get child's undef (scalar)";
    is scalar($child->get_option("code")), "from child", "get child's code (scalar)";
    @parent_code_args = @child_code_args = ();

    $child->delete_option("undef", "code");
    is $child->to_string, <<EXP, "delete the child's options, then the parent's options emerge again.";
unset string
set array not array
unset undef
set code from parent
set child only CHILD
EXP
    is scalar(@parent_code_args), 1, "parent code called once";
    is scalar(@child_code_args), 0, "child code no longer called";
    identical $parent_code_args[0][0], $child, "code arg 0 OK";
    is $parent_code_args[0][1], "code", "code arg 1 OK";
    @parent_code_args = @child_code_args = ();

    is_deeply [$child->get_option("string")], [undef], "get child's string";
    is_deeply [$child->get_option("array")], ["not array"], "get child's array";
    is_deeply [$child->get_option("undef")], [undef], "get parent's undef";
    is_deeply [$child->get_option("code")], ["from parent"], "get parent's code";
    is scalar(@parent_code_args), 1, "parent code called once";
    is scalar($child->get_option("string")), undef, "get child's string (scalar)";
    is scalar($child->get_option("array")), "not array", "get child's array (scalar)";
    is scalar($child->get_option("undef")), undef, "get parent's undef (scalar)";
    is scalar($child->get_option("code")), "from parent", "get parent's code (scalar)";
    @parent_code_args = @child_code_args = ();
}

done_testing;

