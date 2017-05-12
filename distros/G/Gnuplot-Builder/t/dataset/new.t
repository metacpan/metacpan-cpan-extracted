use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Dataset;
use lib "t";
use testlib::DatasetUtil qw(get_data);


{
    note("--- new()");
    my $dataset = Gnuplot::Builder::Dataset->new();
    is $dataset->to_string, "", "empty";
    
    $dataset = Gnuplot::Builder::Dataset->new('f(x)', with => "lp", lw => 3);
    is $dataset->to_string, "f(x) with lp lw 3", "source and opts OK";
    is_deeply [$dataset->get_option("with")], ["lp"], "option 'with' OK";
}

{
    note("--- new_file()");
    my $dataset = Gnuplot::Builder::Dataset->new_file();
    is $dataset->to_string, "", "empty";
    
    $dataset = Gnuplot::Builder::Dataset->new_file('hoge.dat', u => "3:4", every => "::1");
    is $dataset->to_string, q{'hoge.dat' u 3:4 every ::1}, "file and opts OK";
    is_deeply [$dataset->get_option("every")], ["::1"], "option 'every' OK";
}

{
    note("--- new_data() with string data");
    my $dataset = Gnuplot::Builder::Dataset->new_data(<<DATA, with => "lp", lw => 2);
1 11
2 12
3 13
DATA
    is $dataset->to_string, q{'-' with lp lw 2}, "to_string() ok";
    is get_data($dataset), "1 11\n2 12\n3 13\n", "inline data ok";
}

{
    note("--- new_data() with code");
    my $dataset = Gnuplot::Builder::Dataset->new_data(sub {
        my ($dataset, $writer) = @_;
        $writer->("1 10 5\n");
        $writer->("2 20 5\n");
        $writer->("3 30 5");
    }, u => '1:2:3', title => q{'hoge hoge'}, with => "yerrorbars");
    is $dataset->to_string, q{'-' u 1:2:3 title 'hoge hoge' with yerrorbars}, "to_string() OK";
    is get_data($dataset), "1 10 5\n2 20 5\n3 30 5", "inline data OK";
}

done_testing;
