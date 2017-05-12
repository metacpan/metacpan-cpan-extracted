use strict;
use warnings;
use Fl qw[:color];
my $win = Fl::Window->new(1000, 480);
my $chart = Fl::Chart->new(20, 20, $win->w() - 40, $win->h() - 40, 'Chart');
$chart->bounds(-125, 125);
for (my $t = 0; $t < 15; $t += 0.5) {
    my $val = sin($t) * 125.0;
    $chart->add($val, sprintf('%-.1f', $val), ($val < 0) ? FL_RED : FL_GREEN);
}
$win->resizable($win);
$win->show();
exit Fl::run();
