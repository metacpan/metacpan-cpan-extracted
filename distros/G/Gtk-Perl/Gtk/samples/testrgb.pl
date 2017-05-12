#!/usr/bin/perl -w

use Gtk -init;
use Time::HiRes qw (time);

use constant WIDTH => 640;
use constant HEIGHT => 480;
use constant FALSE => 0;
use constant TRUE => 1;
use constant NUM_ITERS => 100;

#use Benchmark 'cmpthese';

#cmpthese(2, {
#	'append' => 'use integer;$buf="";$val = 0; for ($j = 0; $j < WIDTH * HEIGHT * 6; $j++) {$buf .=chr(($val + (($val + int(rand (256))) >> 1)) >> 1)}',
#  	#'pack' => '$buf="";$val = 0;$buf .= pack("C*", map {($val + (($val + int(rand (256))) >> 1)) >> 1} 0..WIDTH*6) foreach (0..HEIGHT);',
#  	'pack2' => 'use integer;$buf="";$val = 0;$buf .= pack("C*", map {($val + (($val + int(rand (256))) >> 1)) >> 1} 0..WIDTH) foreach (0..HEIGHT*6);',
#});

sub testrgb_rgb_test {
  my $drawing_area = shift;
  my $buf = '';
  my ($j, $i, $val, $offset, $dither, $start_time, $total_time, $x, $y, $dith_max);

  $val = 0;
  #for ($j = 0; $j < WIDTH * HEIGHT * 6; $j++)
  #  {
  #    $val = ($val + (($val + int(rand (256))) >> 1)) >> 1;
  #    $buf .= chr($val);
  #  }
  {
  	use integer;
	$buf .= pack("c*", map {($val + (($val + int(rand (256))) >> 1)) >> 1} 0..WIDTH) foreach (0..HEIGHT*6);
  }

  # Let's warm up the cache, and also wait for the window manager
  #  to settle. 
  print "warm up the cache\n";
  for ($i = 0; 0 && $i < NUM_ITERS/10; $i++)
    {
      $offset = int(rand (WIDTH * HEIGHT * 3)) & -4;
      $drawing_area->window->draw_rgb_image (
			  $drawing_area->style->white_gc,
			  0, 0, WIDTH, HEIGHT,
			  'none',
			  substr($buf, $offset), WIDTH * 3);
			  #$buf, WIDTH * 3);
    }

  $dith_max = Gtk::Gdk::Rgb->ditherable ? 2 : 1;

  print "start\n";
  for ($dither = 0; $dither < $dith_max; $dither++)
    {
      $start_time = time ();
      for ($i = 0; $i < NUM_ITERS; $i++)
	{
	  $offset = int(rand (WIDTH * HEIGHT * 3)) & -4;
	  $drawing_area->window->draw_rgb_image (
			      $drawing_area->style->white_gc,
			      0, 0, WIDTH, HEIGHT,
			      $dither ? 'max' : 'none',
				  #Gtk::constsubstr($buf, $offset), WIDTH * 3);
			      substr($buf, $offset), WIDTH * 3);
			      #$buf, WIDTH * 3);
	}
      $total_time = time () - $start_time;
      printf "Color test%s time elapsed: %.2fs, %.1f fps, %.2f megapixels/s\n",
	       $dither ? " (dithered)" : "",
	       $total_time,
	       NUM_ITERS / $total_time,
	       NUM_ITERS * (WIDTH * HEIGHT * 1e-6) / $total_time;
    }

  for ($dither = 0; $dither < $dith_max; $dither++)
    {
      $start_time = time ();
      for ($i = 0; $i < NUM_ITERS; $i++)
	{
	  $offset = int(rand (WIDTH * HEIGHT)) & -4;
	  $drawing_area->window->draw_gray_image(
			       $drawing_area->style->white_gc,
			       0, 0, WIDTH, HEIGHT,
			       $dither ? 'max' : 'none',
				   #Gtk::constsubstr($buf, $offset), WIDTH);
			       substr($buf, $offset), WIDTH);
			       #$buf, WIDTH);
	}
      $total_time = time () - $start_time;
      printf "Grayscale test%s time elapsed: %.2fs, %.1f fps, %.2f megapixels/s\n",
	       $dither ? " (dithered)" : "",
	       $total_time,
	       NUM_ITERS / $total_time,
	       NUM_ITERS * (WIDTH * HEIGHT * 1e-6) / $total_time;
    }

  print ("Please submit these results to http://www.levien.com/gdkrgb/survey.html\n");

}

  Gtk::Gdk::Rgb->init;
  $window = Gtk::Widget->new ('Gtk::Window',
			   "GtkWindow::type", 'toplevel',
			   "GtkWindow::title", "testrgb",
			   "GtkWindow::allow_shrink", FALSE);
  $window->signal_connect( "destroy", sub {Gtk->main_quit});

  $vbox = new Gtk::VBox (FALSE, 0);

  $drawing_area = new Gtk::DrawingArea;

  $drawing_area->set_usize (WIDTH, HEIGHT);
  $vbox->pack_start ($drawing_area, FALSE, FALSE, 0);
  $drawing_area->show;

  $button = new Gtk::Button ("Quit");
  $vbox->pack_start ($button, FALSE, FALSE, 0);
  $button->signal_connect ("clicked", sub {$window->destroy});

  $button->show;

  $window->add ($vbox);
  $vbox->show;

  $window->show;

  testrgb_rgb_test ($drawing_area);

Gtk->main;

