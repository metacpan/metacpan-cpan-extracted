use strict;
use warnings;
use Fl;

# Simple tabs example
#      _____  _____
#   __/ Aaa \/ Bbb \______________________
#  |    _______                           |
#  |   |_______|                          |
#  |    _______                           |
#  |   |_______|                          |
#  |    _______                           |
#  |   |_______|                          |
#  |______________________________________|
#
my $win = Fl::Window->new(500, 200, 'Tabs Example');
my $tabs = Fl::Tabs->new(10, 10, 500 - 20, 200 - 20);

# Aaa tab
my $aaa = Fl::Group->new(10, 35, 500 - 20, 200 - 45, 'Aaa');
my $a1 = Fl::Button->new(50, 60, 90, 25, 'Button A1');
$a1->color(88 + 1);
my $a2 = Fl::Button->new(50, 90, 90, 25, 'Button A2');
$a2->color(88 + 2);
my $a3 = Fl::Button->new(50, 120, 90, 25, 'Button A3');
$a3->color(88 + 3);
$aaa->end();

# Bbb tab
my $bbb = Fl::Group->new(10, 35, 500 - 10, 200 - 35, 'Bbb');
my $b1 = Fl::Button->new(50, 60, 90, 25, 'Button B1');
$b1->color(88 + 1);
my $b2 = Fl::Button->new(150, 60, 90, 25, 'Button B2');
$b2->color(88 + 3);
my $b3 = Fl::Button->new(250, 60, 90, 25, 'Button B3');
$b3->color(88 + 5);
my $b4 = Fl::Button->new(50, 90, 90, 25, 'Button B4');
$b4->color(88 + 2);
my $b5 = Fl::Button->new(150, 90, 90, 25, 'Button B5');
$b5->color(88 + 4);
my $b6 = Fl::Button->new(250, 90, 90, 25, 'Button B6');
$b6->color(88 + 6);
$bbb->end();

#
$tabs->end();
$win->end();
$win->show();
exit Fl::run();
