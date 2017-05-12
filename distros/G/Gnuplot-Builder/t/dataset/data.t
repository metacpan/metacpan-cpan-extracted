use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Identity;
use Gnuplot::Builder::Dataset;
use lib "t";
use testlib::DatasetUtil qw(get_data_and_count get_data);

{
    note("--- initially, no inline data");
    my $dataset = Gnuplot::Builder::Dataset->new;
    my ($data, $count) = get_data_and_count($dataset);
    is $data, "", "no inline data OK";
    is $count, 0, "never called OK";
}

foreach my $case (
    {label => "undef", data => undef, exp => ""},
    {label => "single line", data => "1 10 20", exp => "1 10 20"},
    {label => "multiple lines", data => "1 10\n2 20\n3 30\n", exp => "1 10\n2 20\n3 30\n"},
    {label => "code, single call", data => sub { $_[1]->("1 100\n2 200") }, exp => "1 100\n2 200"},
    {label => "code, multiple calls",
     data => sub { $_[1]->("$_ " . ($_ * 1000) . "\n") for (3..5) },
     exp => "3 3000\n4 4000\n5 5000\n"},
    {label => "code, no call", data => sub { }, exp => ""},
) {
    my $dataset = Gnuplot::Builder::Dataset->new;
    identical $dataset->set_data($case->{data}), $dataset, "$case->{label}: set_data() returns the dataset";
    is get_data($dataset), $case->{exp}, "$case->{label}: inline data OK";
    identical $dataset->delete_data(), $dataset, "$case->{label}: delete_data() returns the dataset";
    is get_data($dataset), "", "$case->{label}: data deleted.";
}

{
    note("--- example: code-ref environment");
    my $dataset = Gnuplot::Builder::Dataset->new;
    my $count = 0;
    $dataset->set_data(sub {
        my ($inner_dataset, $writer) = @_;
        identical $inner_dataset, $dataset, "inner dataset is the dataset OK";
        is wantarray, undef, "void context OK";
        $count++;
        foreach my $x (1..3) {
            my $y = $x * 10;
            $writer->("$x $y\n");
        }
    });
    is $count, 0, "not called yet";
    my ($data, $writer_call_count) = get_data_and_count($dataset);
    is $data, "1 10\n2 20\n3 30\n", "data OK";
    is $writer_call_count, 3, "writer is called 3 times";
    is $count, 1, "data provider is called once";
}

done_testing;

