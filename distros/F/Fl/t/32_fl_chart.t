use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl qw[:chart :color :font];
my $chart1 = new_ok
    'Fl::Chart' => [20, 40, 300, 100, 'Hello, World!'],
    'chart w/ label';
my $chart2 = new_ok 'Fl::Chart' => [20, 40, 300, 100], 'chart2 w/o label';
my $chart = new_ok
    'Fl::Chart' => [20, 40, 300, 100, 'Hello, World!'],
    'box w/ label and box type';
#
isa_ok $chart, 'Fl::Widget';
#
can_ok $chart, 'add';
can_ok $chart, 'autosize';
can_ok $chart, 'bounds';
can_ok $chart, 'clear';
can_ok $chart, 'insert';
can_ok $chart, 'maxsize';
can_ok $chart, 'replace';
can_ok $chart, 'textcolor';
can_ok $chart, 'textfont';
can_ok $chart, 'textsize';
#
$chart->bounds(-125, 125);
is_deeply [$chart->bounds()], [-125, 125], 'bounds(lower, upper)';
is $chart->textcolor(), FL_FOREGROUND_COLOR,
    'textcolor defaults to FL_FOREGROUND_COLOR';
$chart->textcolor(FL_RED);
is $chart->textcolor(), FL_RED, 'textcolor changed to FL_RED';
#
undef $chart;
is $chart, undef, 'chart is now undef';
#
done_testing;
