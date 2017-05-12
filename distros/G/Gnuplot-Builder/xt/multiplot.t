use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;
use lib "xt";
use testlib::XTUtil qw(if_no_file check_process_finish cond_check);

if_no_file "test_multiplot_noopt.png", sub {
    my $filename = shift;
    my $upper = Gnuplot::Builder::Script->new(
        size => "1, 0.4",
        origin => "0, 0.5"
    );
    my $lower = Gnuplot::Builder::Script->new(
        size => "1, 0.4",
        origin => "0, 0"
    );
    my $ret = Gnuplot::Builder::Script->new(
        term => "png size 500,500",
        output => "'$filename'"
    )->multiplot(sub {
        $upper->plot("sin(x) title 'sin(x) upper'");
        $lower->plot("cos(x) title 'cos(x) lower'");
    });
    cond_check sub {
        is($ret, "", "gnuplot process should output no message");
    };
    ok((-f $filename), "$filename created");
};

if_no_file "test_multiplot_opt.png", sub {
    my $filename = shift;
    my $ret = Gnuplot::Builder::Script->new(
        term => "png size 700,500",
        output => "'$filename'"
    )->multiplot("layout 1,2", sub {
        my $builder = Gnuplot::Builder::Script->new;
        $builder->plot("sin(x) title 'sin(x) left'");
        $builder->plot("cos(x) title 'cos(x) right'");
    });
    cond_check sub {
        is($ret, "", "gnuplot process should output no message");
    };
    ok((-f $filename), "$filename created");
};

if_no_file "test_multiplot_error.png", sub {
    my $filename = shift;
    my $result = Gnuplot::Builder::Script->new(
        term => "png size 600,200",
        output => "'$filename'"
    )->multiplot(sub {
        my $writer = shift;
        $writer->("set hoge foo bar\n");
        $writer->("plot cos(x) title 'multiplot error'");
    });
    cond_check sub {
        isnt $result, "", "gnuplot process should output some error message";
    };
    note("Process output: $result");
};


note("--- test return values");

foreach my $case (
    {label => "sync", async => 0, exp => "hogehoge\nfoobar\n" },
    {label => "async", async => 1, exp => ""}
){
    my $got = Gnuplot::Builder::Script->new(
        print => "'-'"
    )->multiplot_with(async => $case->{async}, do => sub {
        my $writer = shift;
        $writer->("print 'hogehoge'\n");
        $writer->("print 'foobar'\n");
        $writer->("plot sin(x) title 'multiplot $case->{label}'");
    });
    cond_check sub {
        is $got, $case->{exp}, "$case->{label}: return value of multiplot_with() OK";
    };
}

check_process_finish;

done_testing;
