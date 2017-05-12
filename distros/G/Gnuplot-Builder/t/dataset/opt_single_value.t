use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Dataset;
use Gnuplot::Builder::JoinDict;

foreach my $case (
    {method => 'set_option', label => "undef", val => undef,
     exp_str => "f(x)", exp_get => [undef], exp_get_s => undef},
    {method => 'set_option', label => "string", val => "bar",
     exp_str => "f(x) foo bar", exp_get => ["bar"], exp_get_s => "bar"},
    {method => 'set_option', label => "empty string", val => "",
     exp_str => 'f(x) foo', exp_get => [''], exp_get_s => ''},
    {method => 'set_option', label => "array-ref", val => ["bar", "buzz"],
     exp_str => 'f(x) foo bar buzz', exp_get => ["bar", "buzz"], exp_get_s => "bar"},
    {method => 'set_option', label => "array-ref with undef", val => [undef],
     exp_str => 'f(x)', exp_get => [undef], exp_get_s => undef},
    {method => 'set_option', label => "array-ref empty", val => [],
     exp_str => 'f(x)', exp_get => [], exp_get_s => undef},
    {method => 'set_option', label => "code", val => sub { "BAR" },
     exp_str => "f(x) foo BAR", exp_get => ["BAR"], exp_get_s => "BAR"},
    {method => 'set_option', label => "code returning undef", val => sub { undef },
     exp_str => 'f(x)', exp_get => [undef], exp_get_s => undef},
    {method => 'set_option', label => "code returning list", val => sub { ("BAR", "BUZZ") },
     exp_str => 'f(x) foo BAR BUZZ', exp_get => ["BAR", "BUZZ"], exp_get_s => "BAR"},
    {method => 'set_option', label => 'code returning empty list', val => sub { () },
     exp_str => 'f(x)', exp_get => [], exp_get_s => undef},

    {method => 'setq_option', label => "undef", val => undef,
     exp_str => "f(x)", exp_get => [undef], exp_get_s => undef},
    {method => 'setq_option', label => "string", val => "bar",
     exp_str => "f(x) foo 'bar'", exp_get => [q{'bar'}], exp_get_s => q{'bar'}},
    {method => 'setq_option', label => "empty string", val => "",
     exp_str => "f(x) foo ''", exp_get => [q{''}], exp_get_s => q{''}},
    {method => 'setq_option', label => "array-ref", val => ["bar", "buzz"],
     exp_str => "f(x) foo 'bar' 'buzz'", exp_get => [q{'bar'}, q{'buzz'}], exp_get_s => q{'bar'}},
    {method => 'setq_option', label => "array-ref with undef", val => [undef],
     exp_str => 'f(x)', exp_get => [undef], exp_get_s => undef},
    {method => 'setq_option', label => "array-ref empty", val => [],
     exp_str => 'f(x)', exp_get => [], exp_get_s => undef},
    {method => 'setq_option', label => "code", val => sub { "BAR" },
     exp_str => "f(x) foo 'BAR'", exp_get => [q{'BAR'}], exp_get_s => q{'BAR'}},
    {method => 'setq_option', label => "code returning undef", val => sub { undef },
     exp_str => 'f(x)', exp_get => [undef], exp_get_s => undef},
    {method => 'setq_option', label => "code returning list", val => sub { ("BAR", "BUZZ") },
     exp_str => "f(x) foo 'BAR' 'BUZZ'", exp_get => [q{'BAR'}, q{'BUZZ'}], exp_get_s => q{'BAR'}},
    {method => 'setq_option', label => 'code returning empty list', val => sub { () },
     exp_str => 'f(x)', exp_get => [], exp_get_s => undef},
) {
    my $label = "$case->{method} $case->{label}";
    my $method = $case->{method};
    my $dataset = Gnuplot::Builder::Dataset->new('f(x)');
    identical $dataset->$method(foo => $case->{val}), $dataset, "$label: $method() returns the dataset";
    is $dataset->to_string, $case->{exp_str}, "$label: to_string() OK";
    is_deeply [$dataset->get_option("foo")], $case->{exp_get}, "$label: get_option() OK";
    is scalar($dataset->get_option("foo")), $case->{exp_get_s}, "$label: get_option() in scalar context OK";
}

{
    note('--- object values');
    my $val = Gnuplot::Builder::JoinDict->new(
        separator => ":", content => [x => 1, y => 2]
    );
    foreach my $case (
        {label => "single", method => "set_option",
         val => $val, exp => q{'data' u 1:2}},
        {label => "in array", method => "set_option",
         val => [$val, "foo"], exp => q{'data' u 1:2 foo}},
        {label => "from code", method => "set_option",
         val => sub { ($val, "foo") }, exp => q{'data' u 1:2 foo}},

        {label => "single", method => "setq_option",
         val => $val, exp => q{'data' u '1:2'}},
        {label => "in array", method => "setq_option",
         val => [$val, "foo"], exp => q{'data' u '1:2' 'foo'}},
        {label => "from code", method => "setq_option",
         val => sub { ($val, "foo") }, exp => q{'data' u '1:2' 'foo'}},
    ) {
        my $dataset = Gnuplot::Builder::Dataset->new_file('data');
        my $method = $case->{method};
        $dataset->$method(u => $case->{val});
        is $dataset->to_string, $case->{exp}, "$case->{label}: $case->{method}: to_string() OK";

        my @got_list = $dataset->get_option("u");
        my $got_scalar = $dataset->get_option("u");
        if($case->{method} eq "set_option") {
            identical $got_list[0], $val, "$case->{label}: $case->{method}: get_option() in list returns the object";
            identical $got_scalar, $val, "$case->{label}: $case->{method}: get_option() in scalar returns the object";
        }else {
            ok !ref($got_list[0]), "$case->{label}: $case->{method}: get_option() in list returns a stringified and quoted object";
            ok !ref($got_scalar), "$case->{label}: $case->{method}: get_option() in scalar returns a stringified and quoted object";
        }
    }
}

{
    note('--- code-ref values');
    foreach my $case (
        {method => "set_option", exp => q{buzz}},
        {method => "setq_option", exp => q{'buzz'}},
    ) {
        my $method = $case->{method};
        my $dataset = Gnuplot::Builder::Dataset->new('f(x)');
        my $called = 0;
        $dataset->$method(fizz => sub {
            my ($inner_dataset, $opt_name) = @_;
            identical $inner_dataset, $dataset, "inner dataset OK";
            is $opt_name, "fizz", "opt name OK";
            ok wantarray, "list context OK";
            $called++;
            return ("buzz");
        });
        is $called, 0, "$method: not called yet";
        is $dataset->to_string, "f(x) fizz $case->{exp}", "$method: result OK";
        is $called, 1, "$method: called once";
        $called = 0;

        is_deeply [$dataset->get_option("fizz")], [$case->{exp}], "$method: get_option() OK";
        is $called, 1, "$method: called once";
        $called = 0;

        is scalar($dataset->get_option("fizz")), $case->{exp}, "$method: get_option() in scalar context OK";
        is $called, 1, "$method: called once";
        $called = 0;
    }
}

{
    note("--- example: array-ref value");
    my $dataset = Gnuplot::Builder::Dataset->new_file("hoge");
    $dataset->set_option(
        binary => ['record=356:356:356', 'skip=512:256:256']
    );
    is $dataset->to_string, q{'hoge' binary record=356:356:356 skip=512:256:256}, "to_string() ok";
    is_deeply [$dataset->get_option('binary')], ['record=356:356:356', 'skip=512:256:256'], "get_option() ok";
    is scalar($dataset->get_option("binary")), 'record=356:356:356', 'get_option() in scalar context OK';
}

done_testing;
