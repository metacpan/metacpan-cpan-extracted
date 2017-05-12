use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;
use lib "xt";
use testlib::XTUtil qw(if_no_file check_process_finish cond_check);

if_no_file "test_example_gif_animation.gif", sub {
    my $filename = shift;
    my $builder = Gnuplot::Builder::Script->new(<<"SET");
term = gif size 500,500 animate
output = "$filename"
SET
    
    my $FRAME_NUM = 10;
    my $result = $builder->run(sub {
        my $builder = Gnuplot::Builder::Script->new;
        foreach my $phase_index (0 .. ($FRAME_NUM-1)) {
            my $phase_deg = 360.0 * $phase_index / $FRAME_NUM;
            $builder->plot("sin(x + $phase_deg / 180.0 * pi)");
        }
    });
    cond_check sub {
        is $result, "", "gnuplot process should output no error message";
    };
    ok((-f $filename), "$filename created");
};


note("--- return value of run()");

foreach my $case (
    {label => "sync", async => 0, exp => "hogehoge\nfoobar\n"},
    {label => "async", async => 1, exp => ""}
) {
    my $builder = Gnuplot::Builder::Script->new;
    my $got = $builder->run_with(
        async => $case->{async},
        do => sub {
            my $writer = shift;
            $writer->("print 'hogehoge'\n");
            $writer->("print 'foobar'");
        }
    );
    cond_check sub {
        is $got, $case->{exp}, "$case->{label}: return value OK";
    };
}

{
    note("--- nested plotting methods share the same process ");
    sleep 1;
    Gnuplot::Builder::Process->FOR_TEST_clear_zombies;
    my $builder = Gnuplot::Builder::Script->new(
        term => "wxt size 1000,700",
    );
    $builder->run_with(async => 1, do => sub {
        my $writer = shift;
        my $base = Gnuplot::Builder::Script->new(<<'SET');
xlabel = "x values"
ylabel = "y values"
mxtics = 5
mytics = 5
SET
        my $left = $base->new_child->setq(ylabel => "");
        my $right = $base->new_child;
        my $PHASE_COUNT = 10;
        foreach my $phase_index (0..($PHASE_COUNT-1)) {
            Gnuplot::Builder::Script->new->multiplot("layout 1,2", sub {
                $left->plot("sin(x * $phase_index * pi / $PHASE_COUNT)");
                $right->plot("cos(x * $phase_index * pi / $PHASE_COUNT)");
            });
            $writer->("pause 0.5\n");
        }
    });
    is(Gnuplot::Builder::Process->FOR_TEST_process_num, 1, "1 process is shared by all the plotting methods.");
}

check_process_finish;
done_testing;
