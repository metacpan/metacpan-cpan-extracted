use strict;
use warnings FATAL => "all";
use Test::More;
use lib "t";
use testlib::ScriptUtil qw(plot_str);
use testlib::Dataset;
use Gnuplot::Builder::Script;

note("--- single dataset");
foreach my $case (
    {
        label => "one-shot",
        provider => sub { $_[0]->(<<DATA) },
1 3
3 5
5 10
DATA
        exp => <<EXP
plot "-"
1 3
3 5
5 10
e
EXP
    },
    {
        label => "one line at a time",
        provider => sub {
            foreach my $line ("1 3", "3 5", "5 10") { $_[0]->("$line\n") }
        },
        exp => <<EXP
plot "-"
1 3
3 5
5 10
e
EXP
    },
    {
        label => "no trailing newline",
        provider => sub { $_[0]->("1 2 3 4") },
        exp => <<EXP
plot "-"
1 2 3 4
e
EXP
    },
    {
        label => "no invocation of writer",
        provider => sub {  },
        exp => <<EXP
plot "-"
EXP
    },
    {
        label => "call writer without data",
        provider => sub { $_[0]->(); $_[0]->(""); $_[0]->(undef); },
        exp => <<EXP
plot "-"
EXP
    }
) {
    my $builder = Gnuplot::Builder::Script->new;
    is plot_str($builder, "plot_with", dataset => testlib::Dataset->new('"-"', $case->{provider})),
        $case->{exp}, "$case->{label}: OK";
}


sub create_inline_data {
    my ($y_offset) = @_;
    return testlib::Dataset->new('"-"', sub {
        my $writer = shift;
        foreach my $x (1..3) {
            my $y = $x + $y_offset;
            $writer->("$x $y\n");
        }
    });
}

{
    note("--- mix of output option, inline data and string dataset");
    my $builder = Gnuplot::Builder::Script->new;
    my $no_inline_data_obj = testlib::Dataset->new('cos(x)', sub {});
    is plot_str($builder, "plot_with", output => "hoge.png",
                dataset => [create_inline_data(10), "sin(x) with lp",
                            $no_inline_data_obj, create_inline_data(20)]),
                    <<EXP, "plot command OK";
set output 'hoge.png'
plot "-",sin(x) with lp,cos(x),"-"
1 11
2 12
3 13
e
1 21
2 22
3 23
e
set output
EXP
}

done_testing;
