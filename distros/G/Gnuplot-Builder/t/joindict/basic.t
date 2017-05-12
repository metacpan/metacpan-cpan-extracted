use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Fatal;
use lib "t";
use testlib::RefUtil qw(is_different);
use Gnuplot::Builder::JoinDict;

sub str_ok {
    my ($dict, $exp, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $msg = "" if not defined $msg;
    is $dict->to_string, $exp, "to_string(): $msg";
    is "$dict", $exp, qq{"": $msg};
}

sub keyval_ok {
    my ($dict, $exp_keys, $exp_values, $msg) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $msg = "" if not defined $msg;
    is_deeply [$dict->get_all_keys], $exp_keys, "get_all_keys(): $msg";
    is_deeply [$dict->get_all_values], $exp_values, "get_all_values(): $msg";
}

{
    note('--- default');
    my $no_arg = Gnuplot::Builder::JoinDict->new();
    str_ok($no_arg, "", "no arg OK");
    is $no_arg->separator, "", "no arg separator() OK";
    keyval_ok($no_arg, [], [], "no arg");
    
    my $no_content = Gnuplot::Builder::JoinDict->new(separator => "###");
    str_ok($no_content, "", "no content OK");
    is $no_content->separator, "###", "no content separator() OK";
    keyval_ok($no_content, [], [], "no content");

    my $no_separator = Gnuplot::Builder::JoinDict->new(content => [x => 1, y => 2, z => 3]);
    str_ok($no_separator, "123", "no separator OK");
    is $no_separator->separator, "", "no separator separator() OK";
    keyval_ok($no_separator, [qw(x y z)], [1, 2, 3], "no separator");
}

{
    note('--- content variation');
    my $SEP = ":";
    foreach my $case (
        {label => "empty", content => [], exp => "", exp_key => [], exp_val => []},
        {label => "single", content => [x => 1], exp => "1", exp_key => ["x"], exp_val => [1]},
        {label => "two", content => [x => 1, y => 2], exp => "1:2", exp_key => [qw(x y)], exp_val => [1, 2]},
        {label => "with undefs", content => [a => undef, b => 2, c => undef, d => 4, e => undef, f => undef],
         exp => "2:4", exp_key => [qw(a b c d e f)], exp_val => [undef, 2, undef, 4, undef, undef]},
        {label => "with empty strings", content => [a => '', b => 2, c => '', d => 4, e => '', f => ''],
         exp => ":2::4::", exp_key => [qw(a b c d e f)], exp_val => ["", 2, "", 4, "", ""]},
        {label => "duplicate keys", content => [a => 1, a => 2, a => 3], exp => '3', exp_key => ["a"], exp_val => [3]},
    ) {
        my $dict = Gnuplot::Builder::JoinDict->new(separator => $SEP, content => $case->{content});
        str_ok($dict, $case->{exp}, "$case->{label} OK");
        keyval_ok($dict, $case->{exp_key}, $case->{exp_val}, "$case->{label} OK");
    }
}

{
    my $orig = Gnuplot::Builder::JoinDict->new(
        separator => ":",
        content => [a => 1, b => 2, _b => undef, c => 3, d => 4]
    );
    is $orig->separator, ":", "orig separator() OK";
    
    note('--- set()');
    foreach my $case (
        {label => "single override", input => [c => 30],
         exp => '1:2:30:4', exp_key => [qw(a b _b c d)], exp_val => [1, 2, undef, 30, 4]},
        {label => "single addition", input => [e => 5],
         exp => '1:2:3:4:5', exp_key => [qw(a b _b c d e)], exp_val => [1, 2, undef, 3, 4, 5]},
        {label => "multi mixed", input => [f => 99, d => 40, b => undef],
         exp => '1:3:40:99', exp_key => [qw(a b _b c d f)], exp_val => [1, undef, undef, 3, 40, 99]},
        {label => "duplicate keys", input => [g => 100, b => 22, g => 200, b => 222, g => 300],
         exp => '1:222:3:4:300', exp_key => [qw(a b _b c d g)], exp_val => [1, 222, undef, 3, 4, 300]},
        {label => "revive undef", input => [_b => 23],
         exp => '1:2:23:3:4', exp_key => [qw(a b _b c d)], exp_val => [1, 2, 23, 3, 4]},
    ) {
        my $new = $orig->set(@{$case->{input}});
        is_different $new, $orig, "$case->{label}: set() returns a new object";
        str_ok $orig, "1:2:3:4", "$case->{label}: set() keeps the original intact";
        str_ok $new, $case->{exp}, "$case->{label}: set() result OK";
        keyval_ok $new, $case->{exp_key}, $case->{exp_val}, "$case->{label}: set() key-values OK";
        is $new->separator, ":", "$case->{label}: set() new separator OK";
    }

    note('--- delete()');
    foreach my $case (
        {label => "single", input => ["c"],
         exp => '1:2:4', exp_key => [qw(a b _b d)], exp_val => [1, 2, undef, 4]},
        {label => "single no exist", input => ["f"],
         exp => '1:2:3:4', exp_key => [qw(a b _b c d)], exp_val => [1, 2, undef, 3, 4]},
        {label => "multi mixed", input => [qw(f e b)],
         exp => '1:3:4', exp_key => [qw(a _b c d)], exp_val => [1, undef, 3, 4]},
        {label => "delete undef value", input => ["_b"],
         exp => '1:2:3:4', exp_key => [qw(a b c d)], exp_val => [1, 2, 3, 4]}
    ) {
        my $new = $orig->delete(@{$case->{input}});
        is_different $new, $orig, "$case->{label}: delete() returns a new object";
        str_ok $orig, "1:2:3:4", "$case->{label}: delete() keeps the original intact";
        str_ok $new, $case->{exp}, "$case->{label}: delete() result OK";
        keyval_ok $new, $case->{exp_key}, $case->{exp_val}, "$case->{label}: delete() key-values OK";
        is $new->separator, ":", "$case->{label}: delete() new separator OK";
    }

    {
        note('--- delete() -> set()');
        my $new = $orig->delete("c")->set(c => 3);
        str_ok $new, "1:2:4:3", "delete() -> set() rearrange the order";
        keyval_ok $new, [qw(a b _b d c)], [1, 2, undef, 4, 3], "delete() -> set(): key-values OK";
    }

    note('--- clone()');
    my $clone = $orig->clone;
    is_different $clone, $orig, "clone is a different object";
    str_ok $clone, "$orig", "clone string OK";
    keyval_ok $clone, [qw(a b _b c d)], [1, 2, undef, 3, 4], "clone()";
    is $clone->separator, ":", "clone separator OK";
    
    note('--- get()');
    foreach my $case (
        {in => "a", exp => 1}, {in => "b", exp => 2},
        {in => "_b", exp => undef}, {in => "c", exp => 3},
        {in => "d", exp => 4}, {in => "this does not exist", exp => undef}
    ) {
        is $orig->get($case->{in}), $case->{exp}, "get: $case->{in}: OK";
        is $clone->get($case->{in}), $case->{exp}, "get: $case->{in}: clone OK";
    }
}

{
    note('--- illegal input');
    foreach my $case (
        {label => "odd number content", input => [x => 1, 3], exp => qr/odd number/i},
        {label => "undef key", input => [undef, 10], exp => qr/undefined key/i},
    ) {
        like exception { Gnuplot::Builder::JoinDict->new(content => $case->{input}) }, $case->{exp}, "new(): $case->{label}";
        my $d = Gnuplot::Builder::JoinDict->new;
        like exception { $d->set(@{$case->{input}}) }, $case->{exp}, "set(): $case->{label}";
    }
}

done_testing;
