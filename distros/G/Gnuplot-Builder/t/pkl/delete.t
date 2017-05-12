use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Builder;
use lib "t";
use testlib::PKLUtil qw(expect_pkl);
use Gnuplot::Builder::PartiallyKeyedList;

sub elems_ok {
    my ($pkl, @keys) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    foreach my $key (@keys) {
        my $exp_val = uc($key);
        is $pkl->get($key), $exp_val, "$key = $exp_val";
    }
}

sub create_pkl {
    my $p = Gnuplot::Builder::PartiallyKeyedList->new;
    $p->set("a", "A");
    $p->add(1);
    $p->add(2);
    $p->set("b", "B");
    $p->set("c", "C");
    $p->add(3);
    $p->set("d", "D");
    return $p;
}

{
    note("--- delete various positions");
    foreach my $case (
        {del => "a", check => [qw(b c d)]},
        {del => "b", check => [qw(a c d)]},
        {del => "c", check => [qw(a b d)]},
        {del => "d", check => [qw(a b c)]},
        {del => "e", del_exp => undef, check => [qw(a b c d)]},
    ) {
        my $p = create_pkl;
        my $del_exp = exists($case->{del_exp}) ? $case->{del_exp} : uc($case->{del});
        is $p->delete($case->{del}), $del_exp, "return from delete OK";
        elems_ok $p, @{$case->{check}};
        is $p->get($case->{del}), undef, "return undef for deleted key";
        is $p->size, scalar(@{$case->{check}} + 3), "size OK";
    }
}

{
    note("--- add and set after delete");
    my $p = create_pkl;
    $p->delete("a");
    $p->delete("c");
    elems_ok $p, qw(b d);
    is $p->size, 5;
    $p->set("e", "E");
    $p->add(4);
    $p->add(5);
    $p->set("c", "C");
    $p->set("b", "B2");
    is $p->size, 9;
    elems_ok $p, qw(c d e);
    is $p->get("b"), "B2";
    is $p->get("a"), undef;
    expect_pkl $p, [[undef,1], [undef,2], [b => "B2"], [undef,3], [d => "D"],
                    [e => "E"], [undef,4], [undef,5], [c => "C"]];
    
}

done_testing;
