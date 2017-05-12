#!/usr/bin/perl -w

#TITLE: GdkImlib
#REQUIRES: Gtk GdkImlib

#use Gtk;
use Gtk::Gdk::ImlibImage;
use Gtk;

init Gtk;

$file = shift;

$sample = "../../Gtk/samples/xpm/marble.xpm";

$file = $sample if not defined $file and -f $sample;

die "Usage: $0 image_file\n" if not defined $file;

$im = load_image Gtk::Gdk::ImlibImage($file);

$w = $im->rgb_width;
$h = $im->rgb_height;

$win = new Gtk::Gdk::Window( {
	'window_type' => 'toplevel',
	'width' => $w,
	'height' => $h,
	'event_mask' => ['structure_mask']
});

$im->render($w, $h);
$p = $im->move_image();
$m = $im->move_mask;
$win->set_back_pixmap($p, 0);
$win->shape_combine_mask($m, 0, 0) if $m;
$win->clear;
$win->show;
Gtk::Gdk->flush;

$i = $j = $k = 0;
$m = undef;

print "----- Testing Scaling Code -----\n";

for($o=0;$o<4;$o++) {
	$k=0;
	($user, $system, undef, undef) = times;
	$t1 = $user+$system;
	for($n=0;$n<256;$n+=4) {
	     $i=$n;$j=($h*$n)/$w;
	     $i=1 if ($i<=0);
	     $j=1 if ($j<=0);
	     $k+=($i*$j);
	     $im->render($i,$j);
	     $p->imlib_free;
	     $p=$im->move_image;
	     $m=$im->move_mask;
	     $win->set_back_pixmap($p, 0);
	     $win->shape_combine_mask($m, 0, 0) if $m;
	     $win->clear;
	     $win->show;
	     Gtk::Gdk->flush;
	}
	($user, $system, undef, undef) = times;
	$t2 = $user+$system;
	$total = $t2-$t1;
	$total = 1 if ! $total;
	printf("\tpixels scaled per second this run:   %8i\n",$k/$total);
}
print "----- Testing Contrast Code -----\n";
($user, $system, undef, undef) = times;
$t1 = $user+$system;
$k=0;
for($n=0;$n<512;$n+=8) {
	$k+=($w*$h);
	$im->set_image_modifier({'gamma' => 256, 'contrast' => $n, 'brightness' => 256});
    $im->render($i,$j);
	$p->imlib_free;
	$p=$im->move_image;
	$m=$im->move_mask;
	$win->set_back_pixmap($p, 0);
	$win->shape_combine_mask($m, 0, 0) if $m;
	$win->clear;
	$win->show;
	Gtk::Gdk->flush;
}

($user, $system, undef, undef) = times;
$t2 = $user+$system;
$total = $t2-$t1;
$total = 1 if ! $total;
printf("\tpixels rendered per second this run: %8i\n",$k/$total);
print "----- Testing Brightness Code -----\n";
($user, $system, undef, undef) = times;
$t1 = $user+$system;
$k=0;
for($n=0;$n<512;$n+=8) {
	$k+=($w*$h);
	$im->set_image_modifier({'gamma' => 256, 'contrast' => 256, 'brightness' => $n});
    $im->render($i,$j);
	$p->imlib_free;
	$p=$im->move_image;
	$m=$im->move_mask;
	$win->set_back_pixmap($p, 0);
	$win->shape_combine_mask($m, 0, 0) if $m;
	$win->clear;
	$win->show;
	Gtk::Gdk->flush;
}
($user, $system, undef, undef) = times;
$t2 = $user+$system;
$total = $t2-$t1;
$total = 1 if ! $total;
printf("\tpixels rendered per second this run: %8i\n",$k/$total);
print "----- Testing Gamma Code -----\n";
($user, $system, undef, undef) = times;
$t1 = $user+$system;
$k=0;
for($n=0;$n<512;$n+=8) {
	$k+=($w*$h);
	$im->set_image_modifier({'gamma' => $n, 'contrast' => 256, 'brightness' => 256});
    $im->render($i,$j);
	$p->imlib_free;
	$p=$im->move_image;
	$m=$im->move_mask;
	$win->set_back_pixmap($p, 0);
	$win->shape_combine_mask($m, 0, 0) if $m;
	$win->clear;
	$win->show;
	Gtk::Gdk->flush;
}
($user, $system, undef, undef) = times;
$t2 = $user+$system;
$total = $t2-$t1;
$total = 1 if ! $total;
printf("\tpixels rendered per second this run: %8i\n",$k/$total);

