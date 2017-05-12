use strict;
use warnings;
use Test::More;
use Geo::Hash::XS;

ok my $gh = Geo::Hash::XS->new;
isa_ok $gh, 'Geo::Hash::XS';

{
    my @set = $gh->neighbors('xn76gg');
    my @expect = qw/xn76gu xn76uh xn76u5 xn76u4 xn76gf xn76gd xn76ge xn76gs/;
    ok eq_set \@set, \@expect or
        diag "got '@set', but expected '@expect'";
}

{
    my @set = $gh->neighbors('xpst02vt');
    my @expect = qw/xpst02vw xpst02vy xpst02vv xpst02vu xpst02vs xpst02vk xpst02vm xpst02vq/;
    ok eq_set \@set, \@expect or
        diag "got '@set', but expected '@expect'";
}

{
    my @set = $gh->neighbors('xn76gg', 2);
    my @expect = qw/xn76gu xn76uh xn76u5 xn76u4 xn76gf xn76gd xn76ge xn76gs 
                    xn76gv xn76gm xn76gk xn76g7 xn76um xn76u6 xn76g3 xn76g9 
                    xn76uk xn76u7 xn76gc xn76uj xn76gt xn76g6 xn76u1 xn76u3/;
    ok eq_set \@set, \@expect or
        diag "got '@set', but expected '@expect'";
}

{
    my @set = $gh->neighbors('xn76gg', 1, 1);
    my @expect = qw/xn76gv xn76gm xn76gk xn76g7 xn76um xn76u6 xn76g3 xn76g9 
                    xn76uk xn76u7 xn76gc xn76uj xn76gt xn76g6 xn76u1 xn76u3/;
    ok eq_set \@set, \@expect or
        diag "got '@set', but expected '@expect'";
}

done_testing;
