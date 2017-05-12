use strict;
use warnings;
use Test::More;
use Future::Q;

note("--- by default, unhandled failures are reported by warn()");

my @warns = ();
$SIG{__WARN__} = sub {
    push @warns, @_;
};

{
    note("--- single unhandled failure");
    is(scalar(@warns), 0, "no warning at the beginning");
    {
        my $f = Future::Q->new->reject("HOGEHOGE");
        undef $f;
    }
    is(scalar(@warns), 1, "1 warning reported");
    like($warns[0], qr/HOGEHOGE.*lost at/s, "warning message ok");
    @warns = ();
}

{
    note("--- dependent future");
    is(scalar(@warns), 0, "no warning at the begining");
    {
        my @subs = map { Future::Q->new } 1..4;
        $subs[0]->fulfill(0);   ## immeidate done
        my $f = Future::Q->needs_all(@subs);
        $subs[1]->fulfill(10);  ## pending done
        $subs[2]->reject("FOOBAR");   ## pending fail
        ok $f->is_rejected, "f is rejected";
    }
    is(scalar(@warns), 2, "2 warnings");
    like($warns[0], qr/FOOBAR.*lost at/s, "warning[0] message ok");
    like($warns[1], qr/FOOBAR.*lost at/s, "warning[1] message ok");
    like($warns[1], qr/subfuture/si, "warning[1] is from the subfuture");
    @warns = ();
}

done_testing;

