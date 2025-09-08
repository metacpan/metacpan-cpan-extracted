#!perl
  
use strict;
use warnings;
use Graphics::Penplotter::GcodeXY;  
use Test::Simple 'no_plan';
  
my $g = new Graphics::Penplotter::GcodeXY(
          id        => "example declaration",
          papersize => "A3",
          units     => "pt",
          check     => 1,
          warn      => 1
        );

ok($g->scale(10.0));
for (my $y = 20; $y <= 80; $y += 5) {
    for (my $x = 20; $x <= 80; $x += 5) {
        if (($x % 10) == 0) {
            ok($g->line($x, $y, $x+3, $y-3));
        }
        else {
            ok($g->line($x, $y, $x+3, $y+3));
        }
    }
}


ok($g->translate(0,1190));
ok($g->rotate(-90));

# the picture:
ok($g->curve(219.14,562.34,223.2,520.3,277,542.2));
ok($g->curve(219.14,562.34,218.8,491,277,542.2));
ok($g->curve(242,282.6,225,274.4,199.4,265.8));
ok($g->curve(242,282.6,231,262.2,241,225.4));
ok($g->curve(386.68,338.04,425.3,360.2,440,400,460.8,412.8,476.8,427.28)); # 5
ok($g->curve(451.8,401.96,468.8,422,465,407.74,485.74,391.46,488.6,396,492.86,390.46)); # 6
ok($g->curve(446.84,472.6,453.2,496.4,463,477.4,472,508,465.6,472.12,499,474.4,485,447.72)); # 7


foreach my $i (0, 2, 4, 6, 8) {
    foreach my $j (1, 3, 5, 7) {
    ok($g->box($i,$j,$i+1,$j+1));
    ok($g->box($i+1,$j+1,$i+2,$j+2));
    }
}

ok($g->circle(200, 200, 200));

foreach my $i (0, 2, 4, 6, 8) {
    foreach my $j (1, 3, 5, 7) {
    ok($g->gsave());
    ok($g->translate($i,$j));
    ok($g->skewX(45));
    ok($g->box(0,0,1,1));
    ok($g->box(1,1,2,2));
    ok($g->grestore());
    }
}

foreach my $i (1 .. 4) {
    foreach my $j (1 .. 9) {
        ok($g->gsave());
        ok($g->translate($i*100, $j*100));
        ok($g->arc(0,0,50,0,$i*$j*10));
        ok($g->grestore());
    }
}

ok($g->pageborder(1));

my $tailx  = 100;
my $taily  = 100;
my $tipx   = 200;
my $tipy   = 200;
my $length = 10;
my $width  = 10;

ok($g->line($tailx, $taily, $tipx, $tipy));
ok($g->arrowhead($length, $width, 'open'));


