use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Dataset;

{
    my $dataset = Gnuplot::Builder::Dataset->new;
    is $dataset->to_string, "", "at first, it's empty";
    is $dataset->get_source(), undef, "get_source() return undef";
}

note('--- basics');
foreach my $case (
    {method => "set_source", label => "string", val => "f(x)", exp => "f(x)"},
    {method => "set_source", label => "code", val => sub { 'g(x)' }, exp => "g(x)"},
    {method => 'setq_source', label => "string", val => 'hoge.dat', exp => q{'hoge.dat'}},
    {method => 'setq_source', label => "code", val => sub { "foobar's data.dat" }, exp => q{'foobar''s data.dat'}},
){
    my $label = "$case->{method} $case->{label}";
    my $method = $case->{method};
    my $dataset = Gnuplot::Builder::Dataset->new;
    identical $dataset->$method($case->{val}), $dataset, "$label: $method() returns the dataset";
    is $dataset->to_string, $case->{exp}, "$label: result OK";
    is $dataset->get_source(), $case->{exp}, "$label: get_source() OK";
    identical $dataset->delete_source(), $dataset, "$label: delete_source() returns the dataset";
    is $dataset->to_string, "", "$label: source deleted, result OK";
    is $dataset->get_source(), undef, "$label: source deleted, get_source() OK";
}

{
    note('--- code eval');
    foreach my $case (
        {method => "set_source", exp => q{f(x)}},
        {method => "setq_source", exp => q{'f(x)'}},
    ) {
        my $dataset = Gnuplot::Builder::Dataset->new;
        my $method = $case->{method};
        my $count = 0;
        $dataset->$method(sub {
            my ($inner_dataset) = @_;
            identical $inner_dataset, $dataset, "inner_dataset OK";
            ok wantarray, "code is in list context";
            $count++;
            return ('f(x)', 'g(x)');
        });
        is $count, 0, "$method: not called yet";
        
        is $dataset->get_source(), $case->{exp}, "$method: get_source OK";
        is $count, 1, "$method: called once";
        $count = 0;

        is $dataset->to_string(), $case->{exp}, "$method: to_string OK";
        is $count, 1, "$method: called once";
        $count = 0;
    }
}

{
    note("--- lazy setq example");
    my $dataset = Gnuplot::Builder::Dataset->new;
    my $file_index = 5;
    $dataset->setq_source(sub { qq{file_$file_index.dat} });
    is $dataset->to_string(), q{'file_5.dat'}, "result OK";
}

done_testing;


