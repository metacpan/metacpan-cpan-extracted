use strict;
use warnings;
use Test::More;
use lib "../lib/";
use Math::Polynom;

eval "use Scalar::Util qw(looks_like_number)";
plan skip_all => "Data::Float required for testing eval()" if $@;

plan tests => 26;

sub alike {
    my($v1,$v2,$precision) = @_;
    if ( abs(int($v1-$v2)) <= $precision) {
	return 1;
    }
    return 0;
}

sub test_newton_raphson {
    my($p,$args,$want)=@_;
    my $precision = $args->{precision} || 0.1;
    my $v = $p->newton_raphson(%$args);
    ok(alike($v,$want,$precision), $p->stringify." ->newton_raphson(".( (exists $args->{guess}) ? "guess => ".$args->{guess}.", ":"" )."precision => $precision) = $want (got $v)");
}

my $p1 = Math::Polynom->new(2 => 1, 0 => -4);
test_newton_raphson($p1, {}, 2);
is( $p1->iterations, 3, "p1->iterations=3 after search" );
test_newton_raphson($p1, {guess => 1}, 2);
test_newton_raphson($p1, {guess => -1}, -2);
test_newton_raphson($p1, {guess => 100}, 2);
test_newton_raphson($p1, {guess => 100, precision => 0.0001}, 2);
test_newton_raphson($p1, {guess => 100, precision => 0.0000001}, 2);
test_newton_raphson($p1, {guess => -10000, precision => 0.0000001}, -2);

my $p2 = Math::Polynom->new(5 => 5, 3.2 => 4, 0.9 => -2);  # 5*x^5 + 4*x^3.2 - 2*x^0.9
test_newton_raphson($p2, {precision => 0.000000000000001}, 0.6161718040343);

my $v;

# expect 0.6161718040343 if succeeds?
$v = undef;
eval { $v = $p2->newton_raphson(guess => -10, precision => 0.000000000000001) };

# newton raphson will fail on some platforms, and work on others...
if (defined $v) {
    ok(looks_like_number($v) && abs($v - 0.6161718040343) < 0.000000000001, "\$p2 with negative guess was solved on this platform [\$v = $v]");
    ok(1,"nop");
    ok(1,"nop");
} else {
    ok( defined $@ && $@ =~ /not a real number/, "newton_raphson() fails on \$p2 with negative guess" );
    ok( $p2->error_message =~ /not a real number/, "\$p2->error_message looks good" );
    is( $p2->error, Math::Polynom::ERROR_NAN, "\$p2->error looks good" );
}

# can still be newton_raphson-ed after error
test_newton_raphson($p2, {guess => 50, precision => 0.01}, 0.6161718040343);

$v = undef;
eval { $v = $p2->newton_raphson(guess => 1, precision => 0.000000000000001, max_depth => 2) };

if (defined $v) {
    ok(looks_like_number($v) && abs($v - 0.6161718040343) < 0.000000000001, "\$p2 with limited max_depth was solved on this platform [\$v = $v]");
    ok(1,"nop");
    ok(1,"nop");
} else {
    ok( defined $@ && $@ =~ /reached maximum number of iterations/, "newton_raphson() fails on \$p2 with limited max_depth" );
    ok( defined $p2->error_message && $p2->error_message =~ /reached maximum number of iterations/, "\$p2->error_message looks good" );
    is( $p2->error, Math::Polynom::ERROR_MAX_DEPTH, "\$p2->error looks good" );
}

my $p3 = Math::Polynom->new(2 => 1, 1 => -2, 0 => 1); # x^2 -2*x +1
test_newton_raphson($p3, {guess => -10}, 1);
test_newton_raphson($p3, {guess => 10}, 1);
test_newton_raphson($p3, {guess => 1000000}, 1);

# TODO: handle calculation overflows...
#my $v = $p3->newton_raphson(guess => 100000000000000000);
# return 1e17, not good

my $p4 = Math::Polynom->new();
eval { $p4->newton_raphson(); };
ok( defined $@ && $@ =~ /empty polynom/, "newton_raphson() fails on empty polynom" );
ok( defined $p4->error_message && $p4->error_message =~ /empty polynom/, "\$p4->error_message looks good" );
is( $p4->error, Math::Polynom::ERROR_EMPTY_POLYNOM, "\$p4->error looks good" );

# fault handling
eval { $p1->newton_raphson(guess => undef); };
ok( defined $@ && $@ =~ /got undefined guess/, "guess => undef" );

eval { $p1->newton_raphson(precision => undef); };
ok( defined $@ && $@ =~ /got undefined precision/, "precision => undef" );

eval { $p1->newton_raphson(guess => 'abc'); };
ok( defined $@ && $@ =~ /got non numeric guess/, "guess => 'abc'" );

eval { $p1->newton_raphson(precision => 'abc'); };
ok( defined $@ && $@ =~ /got non numeric precision/, "precision => 'abc'" );
