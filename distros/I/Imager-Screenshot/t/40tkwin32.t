#!perl -w
use strict;
use Test::More;

use Imager::Screenshot 'screenshot';

Imager::Screenshot->have_win32
  or plan skip_all => "No Win32 support";

eval "use Tk;";
$@
  and plan skip_all => "Tk not available";

my $im;
my $mw;
eval {
  $mw = Tk::MainWindow->new;
};
$@ and plan skip_all => 'Cannot create a window in Tk';

$mw->can('windowingsystem')
  or plan skip_all => 'Cannot determine windowing system';

$mw->windowingsystem eq 'win32'
  or plan skip_all => 'Tk windowing system not Win32';

plan tests => 1;

$mw->Label(-text => "test: $0")->pack;
$mw->after(100 =>
           sub {
             $im = screenshot(widget => $mw)
               or print "# ", Imager->errstr, "\n";
             $mw->destroy;
           });
MainLoop();
ok($im, "grab from a Tk widget");

