use strict;
use warnings;
use Fl qw[:type];
#
my ($win, $out, $scrollbar);

# Scrollbar changed: show scrollbar's value when changed
sub Scrollbar_CB {
    $out->value($scrollbar->value());
}
$win = Fl::Window->new(500, 300, "Fl::Scrollbar Demo");
{
    # Create scrollbar
    $scrollbar = Fl::Scrollbar->new(0, 50, 500, 25, "Scrollbar");
    $scrollbar->type(FL_HORIZONTAL);
    $scrollbar->slider_size(.5);    # 1/2 scollbar's size
    $scrollbar->bounds(100, 200);   # min/max value of the slider's positions
    $scrollbar->value(150);         # initial value
    $scrollbar->step(10);           # force step to 10 (100, 110, 120..)
    $scrollbar->callback(\&Scrollbar_CB, $out);

    # Create output to show scrollbar's value
    $out = Fl::Output->new(200, 150, 100, 40, "Scrollbar Value:");
    $out->textsize(24);
}
$win->end();
$win->show();
Scrollbar_CB(0, 0);                 # show scrollbar's initial position
exit Fl::run();
