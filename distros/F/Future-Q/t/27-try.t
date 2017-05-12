use strict;
use warnings;
use Test::More;
use Test::Identity;
use Future::Q;
use FindBin;
use lib ("$FindBin::RealBin");
use testlib::Utils qw(newf);

note("------ tests for try() method");

{
    note("--- try() should execute the code immediately with the given args");
    my $callbacked = 0;
    Future::Q->try(sub {
        $callbacked = 1;
        is_deeply(\@_, [], "no args OK");
    });
    ok($callbacked, "callbacked");

    $callbacked = 0;
    Future::Q->try(sub {
        $callbacked = 1;
        is_deeply(\@_, [10], "single arg OK");
    }, 10);
    ok($callbacked, "callbacked");

    $callbacked = 0;
    Future::Q->try(sub {
        $callbacked = 1;
        is_deeply(\@_, [qw(a b c)], "multiple args OK");
    }, qw(a b c));
    ok($callbacked, "callbacked");
}

{
    note("--- case: normal return (scalar)");
    my $f = Future::Q->try(sub {
        return 10;
    });
    isa_ok($f, "Future::Q");
    ok($f->is_fulfilled, "f is fulfilled");
    is_deeply([$f->get], [10], "f result OK");
}

{
    note("--- case: normal return (list)");
    my $f = Future::Q->try(sub {
        return (1,2,3);
    });
    isa_ok($f, "Future::Q");
    ok($f->is_fulfilled, "f is fulfilled");
    is_deeply([$f->get], [1,2,3], "f result OK");
}

{
    note("--- case: die");
    my $f = Future::Q->try(sub {
        die "failure\n";
    });
    isa_ok($f, "Future::Q");
    ok($f->is_rejected, "f is rejected");
    is_deeply([$f->failure], ["failure\n"], "f failure OK");
    $f->catch(sub {}); ## handled
}

foreach my $case (
    {label => "pending", return => newf},
    {label => "fulfilled", return => newf()->fulfill()},
    {label => "rejected", return => newf()->reject(1)},
    {label => "cancelled", return => newf()->cancel()},
) {
    note("--- case: a single $case->{label} future");
    my $f = Future::Q->try(sub {
        return $case->{return};
    });
    identical($f, $case->{return}, "f is identical to the returned future");
    $f->catch(sub {}); ## handled
}

{
    note("--- case: return with no arg");
    my $f = Future::Q->try(sub {
        return;
    });
    isa_ok($f, "Future::Q");
    ok($f->is_fulfilled, "f is fulfilled");
    is_deeply([$f->get], [], "f result OK");
}

{
    note("--- case: return list of futures");
    my @returns = map { newf } 1..4;
    $returns[1]->fulfill(10);
    $returns[2]->reject(20);
    $returns[3]->cancel();
    my $f = Future::Q->try(sub {
        return @returns;
    });
    isa_ok($f, "Future::Q");
    ok($f->is_fulfilled, "f is fulfilled");
    my @results = $f->get();
    is(int(@results), int(@returns), "results num OK");
    foreach my $i (0..$#returns) {
        identical($results[$i], $returns[$i], "results[$i] OK");
    }
    $returns[2]->catch(sub {}); ## handled
}

done_testing();
