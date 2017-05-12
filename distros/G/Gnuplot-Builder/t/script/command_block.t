use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Dataset;
use lib "t";
use testlib::ScriptUtil qw(plot_str);

note("--- tests about command blocks of multiplot() and run()");

my @test_cases = (
    {
        label => "1-nest, plot",
        code => sub {
            my $builder = Gnuplot::Builder::Script->new(foo => "bar", fizz => "buzz");
            my $dataset = Gnuplot::Builder::Dataset->new_data("1 10\n2 20", u => "1:2");
            is $builder->plot("sin(x) w lp", $dataset), "", "nested plot() returns empty";
        },
        exp => <<'EXP',
set foo bar
set fizz buzz
plot sin(x) w lp,'-' u 1:2
1 10
2 20
e
EXP
    },
    {
        label => "1-nest, splot",
        code => sub {
            my $builder = Gnuplot::Builder::Script->new;
            $builder->add("print 'hogehoge'");
            is $builder->splot("sin(x*x + y*y)"), "", "nested splot() returns empty";
        },
        exp => <<'EXP',
print 'hogehoge'
splot sin(x*x + y*y)
EXP
    },
    {
        label => "1-nest, multiplot",
        code => sub {
            my $builder = Gnuplot::Builder::Script->new(foo => "bar");
            is $builder->multiplot(sub { $builder->plot("cos(x)") }), "", "nested multiplot() returns empty";
        },
        exp => <<'EXP',
set foo bar
set multiplot
set foo bar
plot cos(x)
unset multiplot
EXP
    },
    {
        label => "1-nest, run",
        code => sub {
            my $builder = Gnuplot::Builder::Script->new(foo => "bar");
            is $builder->run(sub { $_[0]->("print 'hogehoge'\n") }), "", "nested run() returns empty";
        },
        exp => <<'EXP',
set foo bar
print 'hogehoge'
EXP
    },
    {
        label => "1-nest, plot_with async",
        code => sub {
            my $builder = Gnuplot::Builder::Script->new();
            my $dataset = Gnuplot::Builder::Dataset->new_data("5 15", title => "'hoge'");
            $builder->plot_with(async => 1, dataset => [$dataset, "cos(x)"]);
        },
        exp => <<'EXP',
plot '-' title 'hoge',cos(x)
5 15
e
EXP
    },
    {
        label => "Dataset#write_data_to() -> writer",
        code => sub {
            my $writer = shift;
            my $dataset = Gnuplot::Builder::Dataset->new_data(sub {
                my ($dataset, $writer) = @_;
                $writer->("$_ " . ($_ * 10) . "\n") foreach 1..3;
            });
            $dataset->write_data_to($writer);
        },
        exp => <<'EXP',
1 10
2 20
3 30
EXP
    },
    {
        label => "1-nest, plot() to another writer",
        code => sub {
            my $builder = Gnuplot::Builder::Script->new(foo => "bar");
            my $result = plot_str($builder, "plot_with", dataset => "sin(x)");
            is $result, "set foo bar\nplot sin(x)\n", "inner plot result OK";
        },
        exp => "",
    },
    {
        label => "1-nest, splot() to another writer",
        code => sub {
            my $builder = Gnuplot::Builder::Script->new();
            my $result = plot_str($builder, "splot_with", dataset => "cos(x+y)");
            is $result, "splot cos(x+y)\n", "inner plot result OK";
        },
        exp => "",
    },
    {
        label => "1-nest, multiplot() to another writer",
        code => sub {
            my $builder = Gnuplot::Builder::Script->new;
            my $result = plot_str($builder, "multiplot_with",
                                  option => "layout 2,1",
                                  do => sub { $builder->plot("tan(x)"); $builder->plot("atan(x)") },);
            is $result, "set multiplot layout 2,1\nplot tan(x)\nplot atan(x)\nunset multiplot\n", "inner plot result OK";
        },
        exp => "",
    },
    {
        label => "1-nest, run() to another writer",
        code => sub {
            my $builder = Gnuplot::Builder::Script->new;
            my $result = plot_str($builder, "run_with",
                                  do => ["print 'foo'", "print 'bar'"]);
            is $result, "print 'foo'\nprint 'bar'\n", "inner plot result OK";
        },
        exp => "",
    },
    {
        label => "2-nest",
        code => sub {
            my $builder = Gnuplot::Builder::Script->new;
            $builder->run(sub {
                $builder->plot("sin(x) title 'no writer'");
            });
            my ($got_a, $got_b);
            $got_a = plot_str($builder, "run_with", do => sub {
                $builder->plot("sin(x) title 'run A'");
            });
            $got_b = plot_str($builder, "run_with", do => sub {
                $builder->plot("sin(x) title 'run B'");
            });
            is $got_a, "plot sin(x) title 'run A'\n", "result A OK";
            is $got_b, "plot sin(x) title 'run B'\n", "result B OK";
        },
        exp => "plot sin(x) title 'no writer'\n"
    },
    {
        label => "N-nest",
        code => sub {
            my $builder = Gnuplot::Builder::Script->new;
            $builder->run(sub { $builder->run(sub { $builder->run(sub { $builder->plot("sin(x) title 'nested plot'") }) }) });
        },
        exp => "plot sin(x) title 'nested plot'\n",
    },
    {
        label => "exception caught inside block",
        code => sub {
            my $builder = Gnuplot::Builder::Script->new(foo => "bar");
            local $@;
            eval {
                $builder->run(
                    "print '1'",
                    "print '2'",
                    sub { die "BOOM!" },
                    "print '3'",
                    "print '4'"
                );
                fail("this should not be executed");
            };
            like $@, qr{^BOOM!}, "exception thrown";
        },
        exp => <<'EXP'
set foo bar
print '1'
print '2'
EXP
    }
);

foreach my $case (@test_cases) {
    my $builder = Gnuplot::Builder::Script->new;
    foreach my $method (qw(multiplot_with run_with)) {
        my $exp_script = $case->{exp};
        if($method eq "multiplot_with") {
            $exp_script = "set multiplot\n${exp_script}unset multiplot\n";
        }
        my $got_script = plot_str($builder, $method, do => $case->{code});
        is $got_script, $exp_script, "method: $method, $case->{label}: script ok";
    }
}

done_testing;
