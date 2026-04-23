use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;

note("--- plot and splot");

sub add_case_param {
    my ($param_name, $param_vals, @rest) = @_;
    return map {
        my $c = $_;
        map { +{%$c, $param_name => $_} } @$param_vals
    } @rest;
}

{
    my @cases = add_case_param(
        "exit_status", [0, 1, 100], add_case_param(
        "method", ["plot_with", "splot_with"], add_case_param(
        "output", ["none", "test_on_exit_plot_splot.svg"], add_case_param(
        "async", [0, 1], {}
    ))));
    foreach my $case (@cases) {
        my $method = $case->{method};
        my $output = $case->{output};
        my $exit_status = $case->{exit_status};
        my $label = "method = $method, output = $output, async = $case->{async}, status = $exit_status";
        my $s = Gnuplot::Builder::Script->new(
            terminal => "svg",
        );
        $s->add("exit status $exit_status");
        my $got_status;
        $s->$method(
            dataset => $case->{method} eq 'plot_with' ? "sin(x)" : "sin(x) * sin(y)",
            on_exit => sub {
                my ($status) = @_;
                $got_status = $status;
            },
            output => $output eq "none" ? undef : $output,
            async => $case->{async},
        );
        Gnuplot::Builder::Process->wait_all;
        is($got_status, ($exit_status << 8), $label);
    }
}

note('--- multiplot and run');

{
    my @cases = add_case_param(
        "exit_status", [0, 1, 100], add_case_param(
        "output", ["none", "test_on_exit_multiplot_run.svg"], add_case_param(
        "async", [0, 1], add_case_param(
        "method",  ["multiplot_with", "run_with"], {}
    ))));
    foreach my $case (@cases) {
        my $method = $case->{method};
        my $output = $case->{output};
        my $exit_status = $case->{exit_status};
        my $label = "method = $method, output = $output, async = $case->{async}, status = $exit_status";
        my $s = Gnuplot::Builder::Script->new(
            terminal => "svg",
        );
        my $got_status;
        $s->$method(
            output => $output eq "none" ? undef : $output,
            async => $case->{async},
            on_exit => sub {
                my ($status) = @_;
                $got_status = $status;
            },
            do => sub {
                my ($writer) = @_;
                $writer->("exit status $exit_status\n");
            },
        );
        Gnuplot::Builder::Process->wait_all;
        is($got_status, ($exit_status << 8), $label);
    }
}

note("--- async");

{
    my @cases = add_case_param(
        "method", ["plot_with", "splot_with", "multiplot_with", "run_with"], {}
    );
    foreach my $case (@cases) {
        my $method = $case->{method};
        my $exit_status = 1;
        my $label = "method = $method";
        my $s = Gnuplot::Builder::Script->new(
            terminal => "svg",
        );
        my %args;
        if($method eq "plot_with" || $method eq "splot_with") {
            $args{dataset} = "sin(x)";
            $s->add("pause 1");
            $s->add("exit status $exit_status");
        }else {
            $args{do} = sub {
                my ($writer) = @_;
                $writer->("pause 1\n");
                $writer->("exit status $exit_status\n");
            };
        }
        my @got_statuses = ();
        $s->$method(
            %args,
            async => 1,
            on_exit => sub {
                my ($status) = @_;
                push(@got_statuses, $status);
            },
        );
        is_deeply(\@got_statuses, [], "$label: before on_exit callback is called");
        Gnuplot::Builder::Process->wait_all();
        is_deeply(\@got_statuses, [$exit_status << 8], "$label: after on_exit callback is called");
    }
}

note("--- writer is set");

{
    my @cases = add_case_param(
        "method", ["plot_with", "splot_with", "multiplot_with", "run_with"], add_case_param(
        "writer_method", ["direct", "context"], {}
    ));
    foreach my $case (@cases) {
        my $method = $case->{method};
        my $writer_method = $case->{writer_method};
        my $label = "method = $method, writer_method = $writer_method";
        my %args;
        if($method eq "plot_with" || $method eq "splot_with") {
            $args{dataset} = "sin(x)";
        }else {
            $args{do} = sub {};
        }
        my $s = Gnuplot::Builder::Script->new(
            terminal => "svg",
        );
        my @got_statuses;
        my $on_exit = sub {
            my ($status) = @_;
            push(@got_statuses, $status);
        };
        my $tester;
        if($writer_method eq "direct") {
            $tester = sub {
                $s->$method(
                    %args,
                    writer => sub {},
                    on_exit => $on_exit,
                );
            };
        }elsif($writer_method eq "context") {
            $tester = sub {
                $s->run_with(
                    do => sub {
                        $s->$method(
                            %args,
                            on_exit => $on_exit,
                        );
                    },
                );
            };
        }else {
            fail("unknown writer_method: $writer_method");
        }
        like(exception { $tester->(); }, qr/on_exit/, $label);
    }
}

done_testing;
