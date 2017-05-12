use strict;
use warnings;
use Test::More tests => 34;
use lib "../lib/";

use Math::Polynom;

sub alike {
    my ($v1,$v2,$precision) = @_;
    if ( abs(int($v1-$v2)) <= $precision ) {
	return 1;
    }
    return 0;
}

sub test_secant {
    my ($p,$args,$want) = @_;
    my $precision = $args->{precision} || 0.1;
    my $v = $p->secant(%$args);
    ok(alike($v,$want,$precision), $p->stringify." ->secant(p0 => ".$args->{p0}.", p1 => ".$args->{p1}.", precision => $precision) = $want (got $v)");
}

my $p1 = Math::Polynom->new(2 => 1, 0 => -4);
is( $p1->iterations, 0, "p1->iterations=0 before search" );
test_secant($p1, {p0 => 0.5, p1 => 1}, 2);
is( $p1->iterations, 4, "p1->iterations=3 after search" );
test_secant($p1, {p0 => 0.5, p1 => 1}, 2);
test_secant($p1, {p0 => -5, p1 => -1}, -2);
test_secant($p1, {p0 => 0.5, p1 => 1}, 2);
test_secant($p1, {p0 => 0.5, p1 => 1, precision => 0.0001}, 2);
test_secant($p1, {p0 => 0.5, p1 => 1, precision => 0.0000001}, 2);
test_secant($p1, {p0 => 0, p1 => -100, precision => 0.0000001}, -2);
is( $p1->iterations, 15, "p1->iterations=14 after search" );
test_secant($p1, {p0 => 0.5, p1 => 1}, 2);
is( $p1->iterations, 4, "p1->iterations=3 after simpler search" );


my $p2 = Math::Polynom->new(5 => 5, 3.2 => 4, 0.9 => -2);  # 5*x^5 + 4*x^3.2 - 2*x^0.9
test_secant($p2, {p0 => 0.5, p1 => 1, precision => 0.000000000000001}, 0.6161718040343);

eval { test_secant($p2, {p0 => 0.5, p1 => 1, precision => 0.000000000000001}, 0.6161718040343); };
ok( !defined $@ || $@ eq '', "secant() does not fails on polynom 2 with negative guess (newton_raphson would)" );

my $p3 = Math::Polynom->new(2 => 1, 1 => -2, 0 => 1); # x^2 -2*x +1
test_secant($p3, {p0 => 0.5, p1 => 1}, 1);
test_secant($p3, {p0 => 500, p1 => -500}, 1);
test_secant($p3, {p0 => 100000, p1 => 99999}, 1);

# TODO: handle calculation overflows...
my $v;
eval { $v = $p3->secant(p0 => 100000000000000000, p1 => 999999999999999999999, max_depth => 1); };
ok( defined $@ && $@ =~ /reached maximum number of iterations/, "secant() fails when max_depth reached" .((defined $v)?" (v=$v)":"") );
ok( defined $p3->error_message && $p3->error_message =~ /reached maximum number of iterations/, "\$p3->error_message looks good" );
is( $p3->error, Math::Polynom::ERROR_MAX_DEPTH, "\$p3->error looks good" );

# empty polynom error
my $p4 = Math::Polynom->new();
$v = undef;
eval { $v = $p4->secant(p0 => 0, p1 => 1); };
ok( defined $@ && $@ =~ /empty polynom/, "secant() fails on empty polynom".((defined $v)?" (v=$v)":"") );
ok( defined $p4->error_message && $p4->error_message =~ /empty polynom/, "\$p4->error_message looks good" );
is( $p4->error, Math::Polynom::ERROR_EMPTY_POLYNOM, "\$p4->error looks good" );

# a tuff one: the slope leads to a negative next try, while the polynom contains a root -> complex value
$v = undef;
my $p5 = Math::Polynom->new(0.2 => 2, 0 => -1); # 2*x^0.2-1
eval {
    $v = $p5->secant(p0 => 0, p1 => 10);
};
ok( defined $@ && $@ =~ /not a real number/, "secant() fails on polynom 2*x^0.2 - 1".((defined $v)?" (v=$v)":"") );
ok( defined $p5->error_message && $p5->error_message =~ /not a real number/, "\$p5->error_message looks good" );
is( $p5->error, Math::Polynom::ERROR_NAN, "\$p5->error looks good" );

# fault handling
eval { $p4->secant(p0 => 0, p1 => 0); };
ok((defined $@ && $@ =~ /same value for p0 and p1/),"secant() fails when p0 == p1");

eval {$p1->secant(p0 => undef, p1 => 0); };
ok((defined $@ && $@ =~ /got undefined p0/),"p0 => undef");

eval {$p1->secant(p0 => 0, p1 => undef); };
ok((defined $@ && $@ =~ /got undefined p1/),"p1 => undef");

eval {$p1->secant(precision => undef); };
ok((defined $@ && $@ =~ /got undefined precision/),"precision => undef");

eval {$p1->secant(p0 => 'abc', p1 => 0); };
ok((defined $@ && $@ =~ /got non numeric p0/),"p0 => 'abc'");

eval {$p1->secant(p0 => 0, p1 => 'abc'); };
ok((defined $@ && $@ =~ /got non numeric p1/),"p1 => 'abc'");

eval {$p1->secant(precision => 'abc'); };
ok((defined $@ && $@ =~ /got non numeric precision/),"precision => 'abc'");
