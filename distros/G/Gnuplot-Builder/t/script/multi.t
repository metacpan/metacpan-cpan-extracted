use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Script;
use lib "t";
use testlib::ScriptUtil qw(plot_str);

my @test_cases = (
    {
        label => "example: direct write",
        args => {
            option => 'layout 2,1',
            do => sub {
                my $writer = shift;
                $writer->("plot sin(x)\n");
                $writer->("plot cos(x)\n");
            }
        },
        exp => <<'EXP'
set multiplot layout 2,1
plot sin(x)
plot cos(x)
unset multiplot
EXP
    },
    {
        label => "example: mix direct and another builder",
        args => {
            do => sub {
                my $writer = shift;
                my $another_builder = Gnuplot::Builder::Script->new;
                $another_builder->plot("sin(x)"); ## This is the same as below
                $another_builder->plot_with(
                    dataset => "sin(x)",
                    writer => $writer
                );
            }
        },
        exp => <<'EXP'
set multiplot
plot sin(x)
plot sin(x)
unset multiplot
EXP
    },
    {
        label => "with output",
        args => {
            output => "hoge.eps",
            do => sub { $_[0]->("plot sin(x)\n") },
        },
        exp => <<'EXP'
set output 'hoge.eps'
set multiplot
plot sin(x)
unset multiplot
set output
EXP
    },
    {
        label => "the code not calling writer",
        args => {
            option => "title 'test'",
            do => sub {  }
        },
        exp => <<'EXP'
set multiplot title 'test'
unset multiplot
EXP
    },
    {
        label => "async has no effect if writer is present",
        args => {
            option => "layout 3,1",
            async => 1,
            do => sub {
                Gnuplot::Builder::Script->new->plot("sin(x)", "cos(x)");
            }
        },
        exp => <<'EXP'
set multiplot layout 3,1
plot sin(x),cos(x)
unset multiplot
EXP
    },
    {
        label => "code data without trailing newline",
        args => {
            do => sub {
                my $writer = shift;
                $writer->("set ");
                $writer->("termi");
                $writer->("nal png");
            }
        },
        exp => <<'EXP'
set multiplot
set terminal png
unset multiplot
EXP
    },
    {
        label => "code calling writer with empty data",
        args => {
            do => sub { $_[0]->(""); $_[0]->(undef); $_[0]->() }
        },
        exp => <<'EXP'
set multiplot
unset multiplot
EXP
    }
);


foreach my $case (@test_cases) {
    my $builder = Gnuplot::Builder::Script->new;
    my $got = plot_str($builder, "multiplot_with", %{$case->{args}});
    is $got, $case->{exp}, "$case->{label}: multiplot_with() OK";
}



{
    note("--- example: multiplot from non-empty Script.");
    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(mxtics => 5, mytics => 5, term => "png");
    
    my $script = "";
    $builder->multiplot_with(
        output => "multi.png",
        writer => sub { $script .= $_[0] },
        option => 'title "multiplot test" layout 2,1',
        do => sub {
            my $another_builder = Gnuplot::Builder::Script->new;
            $another_builder->setq(title => "sin")->plot("sin(x)");
            $another_builder->setq(title => "cos")->plot("cos(x)");
        }
    );
    is $script, <<'EXP', "result OK";
set mxtics 5
set mytics 5
set term png
set output 'multi.png'
set multiplot title "multiplot test" layout 2,1
set title 'sin'
plot sin(x)
set title 'cos'
plot cos(x)
unset multiplot
set output
EXP
}

{
    note("--- jump out of multiplot() due to exception");
    my $builder = Gnuplot::Builder::Script->new;
    local $@;
    my $result = "";
    eval {
        $builder->multiplot_with(
            writer => sub { $result .= $_[0] },
            option => "layout 6,1",
            do => sub {
                foreach my $freq (1 .. 6) {
                    $builder->plot("sin($freq * x) title 'f = $freq'");
                    die "BOOM!" if $freq == 2;
                }
            }
        );
        fail("this should not be executed");
    };
    like $@, qr{^BOOM!}, "exception thrown";
    is $result, <<'EXP', "it should write scripts until it dies";
set multiplot layout 6,1
plot sin(1 * x) title 'f = 1'
plot sin(2 * x) title 'f = 2'
EXP
}

done_testing;
