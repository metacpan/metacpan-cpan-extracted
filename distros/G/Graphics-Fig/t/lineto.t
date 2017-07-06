use utf8;
use strict;
use warnings;
use Test::More tests => 7;
use File::Temp qw/ tempdir /;
use Graphics::Fig;
use t::FigCmp;

#
# Create temp directory.
#
my $dir = tempdir(CLEANUP => 1);
#my $dir = "/tmp";


#
# Test 1: lineto given distance, heading
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ], arrowMode => "forw" });
    $fig->lineto(2 * sqrt(2), 45);
    $fig->save("${dir}/lineto1.fig");
    &FigCmp::figCmp("${dir}/lineto1.fig", "t/lineto1.fig") || die;
};
ok($@ eq "", "test1");

#
# Test 2: lineto given multiple distance, heading pairs
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ], arrowMode => "forw" });
    $fig->lineto(3,   30);
    $fig->lineto(2,  120);
    $fig->lineto(3, -150);
    $fig->lineto(2,  -60);
    $fig->save("${dir}/lineto2.fig");
    &FigCmp::figCmp("${dir}/lineto2.fig", "t/lineto2.fig") || die;
};
ok($@ eq "", "test2");

#
# Test 3: lineto given one point
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ], arrowMode => "forw" });
    $fig->lineto([ -1, -1 ]);
    $fig->save("${dir}/lineto3.fig");
    &FigCmp::figCmp("${dir}/lineto3.fig", "t/lineto3.fig") || die;
};
ok($@ eq "", "test3");

#
# Test 4: lineto given multiple points (ignoring detachedLineto)
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 3, 2 ], arrowMode => "forw",
    				   detachedLineto => 1 });
    $fig->lineto([[ 2, 1 ], [ 0, 4 ], [ 4, 0 ]]);
    $fig->save("${dir}/lineto4.fig");
    &FigCmp::figCmp("${dir}/lineto4.fig", "t/lineto4.fig") || die;
};
ok($@ eq "", "test4");

#
# Test 5: multiple lineto calls
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 1, 1 ], arrowMode => "forw" });
    $fig->lineto([ 1, 3 ]);
    $fig->lineto([ 3, 5 ]);
    $fig->lineto([ 5, 5 ]);
    $fig->save("${dir}/lineto5.fig");
    &FigCmp::figCmp("${dir}/lineto5.fig", "t/lineto5.fig") || die;
};
ok($@ eq "", "test5");

#
# Test 6: multiple lineto calls, globally detached
#
eval {
    my $fig = Graphics::Fig->new({ position => [ 2, 2 ], arrowMode => "forw",
    				   detachedLineto => 1 });
    $fig->lineto([[ 2, 3 ], [ 3, 3 ]]);
    $fig->lineto([[ 3, 2 ], [ 4, 2 ]]);
    $fig->lineto([[ 4, 1 ], [ 3, 1 ]]);
    $fig->save("${dir}/lineto6.fig");
    &FigCmp::figCmp("${dir}/lineto6.fig", "t/lineto6.fig") || die;
};
ok($@ eq "", "test6");

#
# Test 7: multiple lineto calls, locally detached
#
eval {
    my $fig = Graphics::Fig->new({ arrowMode => "forw" });
    $fig->lineto(1,  135);
    $fig->lineto(2,   45);
    $fig->lineto(3,  -45, { new => 1 });
    $fig->lineto(4, -135);
    $fig->lineto(5,  135);
    $fig->lineto(6,   45);
    $fig->lineto(7,  -45, { new => 1 });
    $fig->lineto(8, -135);
    $fig->save("${dir}/lineto7.fig");
    &FigCmp::figCmp("${dir}/lineto7.fig", "t/lineto7.fig") || die;
};
ok($@ eq "", "test7");


exit(0);
