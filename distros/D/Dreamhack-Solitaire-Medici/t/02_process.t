use strict;

use Test::More tests => 6;

my $m;

BEGIN {
    use_ok( $m = 'Dreamhack::Solitaire::Medici' );
}

my $sol;
my @layout = ();
my $layout = '[Qd 7c 9s Qs Js][9d Ad Kd][8c 6s 10d 8s][Kc Qh 7s 6d 10s][Ah 6c 7h] [7d As Jd][Ks][6h Jh Jc Qc 9h 9c][Kh][Ac][8h][10c][8d][10h]';

eval {
    $sol = $m->new();
    @layout = $sol->parse_init_string($layout);
    $sol->init_layout(\@layout);
};

is( $#layout, 35, 'parse_init_string is ok' );
ok($sol->process(), 'build solitaire is ok');
is( $sol->{'attempts'}, 1, 'attempts count is ok' );
ok($sol->format(), 'format string not empty is ok');


# incorrect layout:
$layout = '[Qd 7c 9s Qs Js][9d Ad Kd][8c 6s 10d 8s][Kc Qh 7s 6d 10s][Ah 6c 7h][7d As Jd][10h][Ks][6h Jh Jc Qc 9h Ac][9c][Kh][8h][10c][8d]';
eval {
    @layout = $sol->parse_init_string($layout);
    $sol->init_layout(\@layout);
};

ok(!$sol->process(), 'bad layout is ok');

done_testing();
