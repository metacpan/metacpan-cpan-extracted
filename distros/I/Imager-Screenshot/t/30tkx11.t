#!perl -w
use strict;
use Test::More;

use Imager::Screenshot 'screenshot';

Imager::Screenshot->have_x11
  or plan skip_all => "No X11 support";

my $display = Imager::Screenshot::x11_open()
  or plan skip_all => "Cannot connect to display: ".Imager->errstr;

Imager::Screenshot::x11_close($display);

eval "use Tk;";
$@
  and plan skip_all => "Tk not available";

my $mw = Tk::MainWindow->new;

$mw->can('windowingsystem')
  or plan skip_all => 'Cannot determine windowing system';
$mw->windowingsystem eq 'x11'
  or plan skip_all => 'Tk windowing system not X11';

eval { $mw->geometry('+10+10'); };

plan tests => 2;

my ($im_mw, $im_label);
my $label = $mw->Label(-text => "test: $0")->pack;
$label->waitVisibility;
$mw->after(100 =>
           sub {
             $im_mw = screenshot(widget => $mw, decor => 1)
               or print "# mw: ", Imager->errstr, "\n";
	     $im_label = screenshot(widget => $label)
	       or print "# label: ", Imager->errstr, "\n";
             $mw->destroy;
           });
MainLoop();
ok($im_mw, "grab from a Tk widget (X11)");
ok($im_label, "grab label from a Tk widget (X11)");
