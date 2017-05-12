use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::JoinDict;

my $val = Gnuplot::Builder::JoinDict->new(
    separator => ",", content => [width => 400, height => 300]
);
foreach my $case (
    {label => "single", method => "set_option",
     val => $val, exp => qq{set term 400,300\n}},
    {label => "in array", method => "set_option",
     val => [$val, "foo"], exp => qq{set term 400,300\nset term foo\n}},
    {label => "from code", method => "set_option",
     val => sub { ($val, "foo") }, exp => qq{set term 400,300\nset term foo\n}},

    {label => "single", method => "setq_option",
     val => $val, exp => qq{set term '400,300'\n}},
    {label => "in array", method => "setq_option",
     val => [$val, "foo"], exp => qq{set term '400,300'\nset term 'foo'\n}},
    {label => "from code", method => "setq_option",
     val => sub { ($val, "foo") }, exp => qq{set term '400,300'\nset term 'foo'\n}},
) {
    my $script = Gnuplot::Builder::Script->new;
    my $method = $case->{method};
    $script->$method(term => $case->{val});
    is $script->to_string, $case->{exp}, "$case->{label}: $case->{method}: to_string() OK";

    my @got_list = $script->get_option("term");
    my $got_scalar = $script->get_option("term");
    if($case->{method} eq "set_option") {
        identical $got_list[0], $val, "$case->{label}: $case->{method}: get_option() in list returns the object";
        identical $got_scalar, $val, "$case->{label}: $case->{method}: get_option() in scalar returns the object";
    }else {
        ok !ref($got_list[0]), "$case->{label}: $case->{method}: get_option() in list returns a stringified and quoted object";
        ok !ref($got_scalar), "$case->{label}: $case->{method}: get_option() in scalar returns a stringified and quoted object";
    }
}


done_testing;
