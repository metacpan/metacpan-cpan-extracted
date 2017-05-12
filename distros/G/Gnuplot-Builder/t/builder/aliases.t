use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder;

{
    my $script = gscript(foo => "bar");
    isa_ok $script, "Gnuplot::Builder::Script";
    is "$script", "set foo bar\n", "script result OK";
}

{
    my $dataset = gfunc("f(x)", with => "lp");
    isa_ok $dataset, "Gnuplot::Builder::Dataset";
    is "$dataset", "f(x) with lp", "dataset func result OK";
}

{
    my $dataset = gfile('hoge.dat', u => '3:4');
    isa_ok $dataset, "Gnuplot::Builder::Dataset";
    is "$dataset", "'hoge.dat' u 3:4", "dataset file result OK";
}

{
    my $dataset = gdata("1 10\n2 20\n", u => '1:2');
    isa_ok $dataset, "Gnuplot::Builder::Dataset";
    is "$dataset", "'-' u 1:2", "dataset data result OK";
    my $inline_data = "";
    $dataset->write_data_to(sub { $inline_data .= shift });
    is $inline_data, "1 10\n2 20\n", "inline data OK";
}

{
    gwait();
    ok "gwait() returns";
}

done_testing;

