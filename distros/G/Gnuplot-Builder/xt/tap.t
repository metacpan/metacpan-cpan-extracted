use strict;
use warnings;
use Test::More;
use Gnuplot::Builder ();
use lib "xt";
use testlib::XTUtil qw(if_no_file cond_check);

sub check_tap_logs {
    my (@tap_logs) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    cmp_ok scalar(@tap_logs), ">", "0", "at least 1 tap_log is obtained";

    my $exp_pid;
    my $got_body = "";
    foreach my $i (0 .. $#tap_logs) {
        my ($pid, $event, $body) = @{$tap_logs[$i]};
        cmp_ok $pid, ">", 0, "log $i: positive PID";
        note("log $i: PID = $pid");
        if(defined $exp_pid) {
            is $pid, $exp_pid, "log $i: PID should be the same";
        }else {
            $exp_pid = $pid;
        }
        is $event, "write", "log $i: event should be always 'write'";
        $got_body .= $body;
    }
    return $got_body;
}

my $base = Gnuplot::Builder::Script->new;
$base->set(
    term => "png size 400,400",
    grid => "",
)->setq(
    xlabel => 'x',
    ylabel => 'y',
);

if_no_file "test_tap_plot.png", sub {
    note("--- plot() method");
    my $filename = shift;
    my $script = $base->new_child;
    my @tap_logs = ();
    local $Gnuplot::Builder::Process::TAP = sub {
        push @tap_logs, \@_;
    };
    $script->plot_with(dataset => ["sin(x)", "cos(x)"], output => $filename);
    cmp_ok scalar(@tap_logs), ">", "0", "at least 1 tap_log is obtained";

    my $got_body = check_tap_logs(@tap_logs);
    like $got_body, qr/set +term/, "set term in log";
    like $got_body, qr/set +grid/, "set grid in log";
    like $got_body, qr/set +xlabel/, "set xlabel in log";
    like $got_body, qr/set +ylabel/, "set ylabel in log";
    like $got_body, qr/set +output/, "set output in log";
    like $got_body, qr/plot +sin\(x\).*cos\(x\)/, "plot sin(x) and cos(x) in log";
    note("Log body:");
    note($got_body);
    ok(-e $filename, "$filename created by gnuplot process");
};

if_no_file "test_tap_run.png", sub {
    note("--- run() method");
    my $filename = shift;
    my $script = $base->new_child;
    my @tap_logs = ();
    local $Gnuplot::Builder::Process::TAP = sub {
        push @tap_logs, \@_;
    };
    $script->run(sub {
        my $writer = shift;
        $writer->(qq{print "FOOBAR"\n});
        $writer->(qq{set output "$filename"\n});
        $writer->(qq{plot cos(x)\n});
        $writer->(qq{set output\n});
    });
    my $got_body = check_tap_logs(@tap_logs);
    like $got_body, qr/set +term/, "set term in logs";
    like $got_body, qr/print "FOOBAR"/, "print in logs";
    like $got_body, qr/set output/, "set output in logs";
    like $got_body, qr/plot cos\(x\)/, "plot in logs";
    ok(-e $filename, "$filename created by gnuplot process");
};

{
    note("--- plot() with 'writer'. In this case, TAP code-ref is not called because there is no gnuplot process");
    my @tap_logs = ();
    local $Gnuplot::Builder::Process::TAP = sub {
        push @tap_logs, \@_;
    };
    my $script = $base->new_child;
    my $filename = "test_tap_noplot.png";
    $script->plot_with(
        dataset => 'sin(x)',
        output => $filename,
        writer => sub {}
    );
    ok(!-e $filename, "$filename should be created because of 'writer' option");
    is scalar(@tap_logs), 0, "no tap log should be recorded because of 'writer' option";
}

if_no_file "test_tap_module.png", sub {
    my $filename = shift;
    note("--- Tap module");
    my $output = `perl ./xt/testlib/plotter.pl '$filename'`;
    is $output, "", "no output because Tap is not in effect";
    ok(-e $filename, "$filename is generated");
    unlink($filename) or die "Cannot remove $filename: $!";
    
    $output = `perl -MGnuplot::Builder::Tap ./xt/testlib/plotter.pl '$filename'`;
    like $output, qr/set +term/, "set term in output";
    like $output, qr/set +xrange/, "set xrange in output";
    like $output, qr/set +title/, "set title in output";
    like $output, qr/set +xlabel/, "set xlabel in output";
    like $output, qr/set +ylabel/, "set ylabel in output";
    like $output, qr/set +output/, "set output in output";
    like $output, qr/plot +x \* x/, "plot x * x in output";
};

done_testing;
