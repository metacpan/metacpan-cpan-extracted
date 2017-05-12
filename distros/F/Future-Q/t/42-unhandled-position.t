use strict;
use warnings;
use Test::More;
use Future::Q;
use FindBin;
use lib ("$FindBin::Bin");
use testlib::Utils qw(newf init_warn_handler test_log_num);
use Carp;

init_warn_handler;

sub create_future {
    return Future::Q->new;
}

sub fail_future {
    return create_future()->die("failure");
}

sub discard_failed_future {
    my $f = fail_future();
}

$Carp::Verbose = 0;

{
    my @logs = ();
    local $Future::Q::OnError = sub {
        push @logs, shift
    };
    discard_failed_future;
    is(int(@logs), 1, "1 warning");
    note(explain @logs);
    ok($logs[0] =~ qr/failure.*at .* line (\d+).*lost at .* line (\d+)/s, "log format OK");
    my ($line_die, $line_lost) = ($1, $2);
    my $exp_lost = 31;
    is($line_die, 17, "future died at 17");
    cmp_ok($line_lost, ">=", $exp_lost - 1, "lost around $exp_lost");
    cmp_ok($line_lost, "<=", $exp_lost + 1, "lost around $exp_lost");
}



sub create_subfuture {
    my $msg = shift;
    return Future::Q->new->die($msg);
}

sub call_wait_any {
    return Future::Q->wait_any(
        map { create_subfuture($_) } qw(one two three)
    );
}

sub discard_dependent_future {
    my $df = call_wait_any;
    undef $df;
    1;
}

{
    my @logs = ();
    local $Future::Q::OnError = sub {
        push(@logs, shift);
    };
    discard_dependent_future;

    my $exp_died_sub = 46;
    my $exp_lost = 57;
    is(int(@logs), 4, "4 warnings");
    note(explain @logs);
    ok($logs[0] =~ /lost at.* line (\d+)/s, "log format OK");
    my ($got_lost) = ($1);
    ## is($got_cons_dependent, $exp_cons_dependent, "constructed_at for dependent future OK");
    cmp_ok($got_lost, ">=", $exp_lost - 1, "lost_at for dependent future OK");
    cmp_ok($got_lost, "<=", $exp_lost + 1, "lost_at for dependent future OK");
    shift @logs;
    foreach my $i (0 .. $#logs) {
        my $log = $logs[$i];
        ok($log =~ /(?:one|two|three).*at.* line (\d+)/, "log format for subfuture $i OK") or diag("got: $log");
        my ($got_died_sub) = ($1);
        is($got_died_sub, $exp_died_sub, "subfuture $i died at OK");
    }
}

done_testing();

