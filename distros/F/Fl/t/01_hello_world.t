use strict;
use warnings;
use Test::More 0.98;
use lib '../blib/', '../blib/lib', '../lib';
use Fl qw[:enum];
use Test::NeedsDisplay;
#
my $window = new_ok 'Fl::Window' => [100, 200, 340, 180], 'window';
my $box = new_ok 'Fl::Box' => [20, 40, 300, 100, 'Hello, World!'], 'box';
$box->box(FL_UP_BOX);
$box->labelfont(FL_BOLD +FL_ITALIC);
$box->labelsize(36);
$box->labeltype(FL_SHADOW_LABEL);
$window->end();
$window->show();
Fl::wait(1);
done_testing;
