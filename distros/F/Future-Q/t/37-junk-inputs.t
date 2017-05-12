use strict;
use warnings;
use Test::More;
use Future::Q;
use FindBin;
use lib "$FindBin::RealBin";
use testlib::Utils qw(isnt_identical);

note("----- tests for junk inputs");


{
    note("--- then()");
    foreach my $case (
        {junk => [10], label => "number"},
        {junk => ["a", "b"], label => "string"},
        {junk => [[]], label => "array-ref"},
        {junk => [undef, undef, undef], label => "undef"},
        {junk => [{}], label => "hash-ref"},
    ) {
        my $f = Future::Q->new;
        my $nf = $f->then(@{$case->{junk}});
        isa_ok($nf, "Future::Q", "then() with input $case->{label} produces next future");
        isnt_identical($nf, $f, "nf and f is not identical");
        ok($nf->is_pending, "nf is pending because f is pending");
        $f->fulfill();
        ok($nf->is_fulfilled, "nf is fulfilled because f is fulfilled.");
    }
}

{
    note("--- try()");
    foreach my $case (
        {junk => [], label => "empty"},
        {junk => [10], label => "number"},
        {junk => ["a"], label => "string"},
        {junk => [undef], label => "undef"},
        {junk => [[]], label => "array-ref"},
        {junk => [{}], label => "hash-ref"},
    ) {
        my $f = Future::Q->try($case->{junk});
        isa_ok($f, "Future::Q", "try() with input $case->{label} produces a future");
        ok($f->is_rejected, "... and the future is rejected.");
        $f->catch(sub {}); ## handled
    }
}
done_testing();

