use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;
use Time::HiRes qw(time);
use lib "xt";
use testlib::XTUtil qw(if_no_file check_process_finish cond_check);


if_no_file "test_plot.png", sub {
    my $filename = shift;
    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(<<SET);
term   = png size 500,500
xrange = [-2:2]
yrange = [-1:1]
xlabel = "x label"
ylabel = "y label"
SET
    $builder->setq(output => $filename);
    my $ret = $builder->plot("sin(2 * pi * x)");
    cond_check sub {
        is $ret, "", "gnuplot process should output nothing.";
    };
    ok((-f $filename), "$filename output OK");
};

if_no_file "test_splot.png", sub {
    my $filename = shift;
    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(<<SET);
term   = png size 500,500
xrange = [-2:2]
yrange = [-2:2]
zrange = [-1:1]
xlabel = "x label"
ylabel = "y label"
zlabel = "z label"
SET
    $builder->setq(output => $filename);
    my $ret = $builder->splot("sin(x*x + y*y) / (x*x + y*y)");
    cond_check sub {
        is $ret, "", "gnuplot process should output nothing";
    };
    ok((-f $filename), "$filename output OK");
};

if_no_file "test_error.png", sub {
    my $filename = shift;
    my $builder = Gnuplot::Builder::Script->new;
    $builder->add("hohwa afafaw  adfhas asefhas");
    $builder->add("asha arasaf h a");
    $builder->set(term => "png size 200,200");
    $builder->setq(output => $filename);
    my $result = $builder->plot("sin(x)");
    cond_check sub {
        isnt $result, "", "gnuplot process should output some error messages";
    };
    note("gnuplot error message: $result");
};

if_no_file "test_print.png", sub {
    my $filename = shift;
    my $builder = Gnuplot::Builder::Script->new;
    $builder->add(qq{print "hoge hoge"});
    $builder->add(qq{print "foo bar"});
    $builder->set(term => "png size 700,500");
    $builder->setq(output => $filename, title => "print test");
    my $ret = $builder->plot("cos(x)");
    cond_check sub {
        is $ret, <<EXP, "gnuplot process output by print command OK";
hoge hoge
foo bar
EXP
    };
};


my @tested_terms = ("wxt");
if($^O eq 'MSWin32') {
    push @tested_terms, "windows";
}else {
    push @tested_terms, "x11";
}
if($ENV{GNUPLOT_BUILDER_TEST_QT}) {
    note("qt term will be tested");
    push @tested_terms, "qt";
}else {
    diag("If you want to test qt term, set GNUPLOT_BUILDER_TEST_QT environement variable");
}

foreach my $term (@tested_terms) {
    my $builder = Gnuplot::Builder::Script->new(term => "$term");
    {
        note("--- $term terminal: no error");
        my $before_time = time;
        my $ret = $builder->plot("cos(x)");
        cond_check sub {
            is $ret, "", "$term: gnuplot process should output nothing";
        };
        my $wait_time = time - $before_time;
        cmp_ok $wait_time, "<", 1, "$term: plot() should return immediately";
    }
    {
        note("--- $term terminal: with error");
        my $result = $builder->plot('sin(x) ps 4 with lp title "FOOBAR"');
        cond_check sub {
            isnt $result, "", "$term: gnuplot process should output some error messages";
        };
        note("$term: gnuplot error message: $result");
    }
}

check_process_finish;
done_testing;
