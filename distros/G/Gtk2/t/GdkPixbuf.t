#!/usr/bin/env perl
use strict;
use warnings;
use Gtk2::TestHelper tests => 112, noinit => 1;

my $show = 0;

use File::Temp qw(tempdir);
my $dir = tempdir(CLEANUP => 1);

my $gif = 'gtk-demo/floppybuddy.gif';

SKIP: {
	skip 'animation not found', 12
		unless -r $gif;

	my $ani = Gtk2::Gdk::PixbufAnimation -> new_from_file($gif);
	isa_ok ($ani, 'Gtk2::Gdk::PixbufAnimation');

	like ($ani->get_width, qr/^\d+$/);
	like ($ani->get_height, qr/^\d+$/);

	my $iter = $ani->get_iter;
	isa_ok ($iter, 'Gtk2::Gdk::PixbufAnimationIter');

	$iter = $ani->get_iter (0, 0);
	isa_ok ($iter, 'Gtk2::Gdk::PixbufAnimationIter');

	ok (!$ani->is_static_image);
	isa_ok($ani->get_static_image, 'Gtk2::Gdk::Pixbuf');

	# The next two seem to return TRUE on m68k but FALSE everywhere else, so
	# just test for definedness.
 	# http://buildd.debian.org/fetch.php?&pkg=libgtk2-perl&ver=1%3A1.121-1&arch=m68k&stamp=1151330512&file=log&as=raw
	ok (defined $iter->advance);
	ok (defined $iter->advance (0, 0));
	like ($iter->get_delay_time, qr/^\d+$/);
	ok (!$iter->on_currently_loading_frame);
	isa_ok ($iter->get_pixbuf, 'Gtk2::Gdk::Pixbuf');
}

eval {
	Gtk2::Gdk::PixbufAnimation -> new_from_file("aslkhaklh.gif");
};
isa_ok ($@, "Glib::File::Error");



my ($pixbuf, $pixels);

$pixbuf = Gtk2::Gdk::Pixbuf->new ('rgb', TRUE, 8, 61, 33);
isa_ok ($pixbuf, 'Gtk2::Gdk::Pixbuf', 'new with alpha');
is ($pixbuf->get_colorspace, 'rgb');
is ($pixbuf->get_n_channels, 4);
ok ($pixbuf->get_has_alpha);
is ($pixbuf->get_bits_per_sample, 8);
is ($pixbuf->get_width, 61);
is ($pixbuf->get_height, 33);
is ($pixbuf->get_rowstride, 244);
$pixels = $pixbuf->get_pixels;
ok ($pixels);
is (length($pixels), 8052);


$pixbuf = Gtk2::Gdk::Pixbuf->new ('rgb', FALSE, 8, 33, 61);
isa_ok ($pixbuf, 'Gtk2::Gdk::Pixbuf', 'new without alpha');
is ($pixbuf->get_colorspace, 'rgb');
is ($pixbuf->get_n_channels, 3);
ok (!$pixbuf->get_has_alpha);
is ($pixbuf->get_bits_per_sample, 8);
is ($pixbuf->get_width, 33);
is ($pixbuf->get_height, 61);
is ($pixbuf->get_rowstride, 100); # 100 is aligned, 99 is actual
$pixels = $pixbuf->get_pixels;
ok ($pixels);
# last row is not padded to the rowstride, hence 6099 not 6100
is (length($pixels), 6099); 


isa_ok ($pixbuf->copy, 'Gtk2::Gdk::Pixbuf', 'copy');


my $subpixbuf = $pixbuf->new_subpixbuf (10, 5, 7, 14);
isa_ok ($subpixbuf, 'Gtk2::Gdk::Pixbuf', 'new_subpixbuf');
# probably more validation of gdk-pixbuf's stuff, but it makes me happy
# to verify invariants like this.
is ($subpixbuf->get_width, 7);
is ($subpixbuf->get_height, 14);
is ($subpixbuf->get_rowstride, $pixbuf->get_rowstride);


my ($win, $vbox);
if ($show) {
	$win = Gtk2::Window->new;
	$vbox = Gtk2::VBox->new;
	$win->add ($vbox);
}

my @test_xpm = (
 '4 5 3 1',
 ' 	c None',
 '.	c red',
 '+	c blue',
 '.. +',
 '. ++',
 ' ++.',
 '++..',
 '+.. ');

$pixbuf = Gtk2::Gdk::Pixbuf->new_from_xpm_data (@test_xpm);
isa_ok ($pixbuf, 'Gtk2::Gdk::Pixbuf', 'new_from_xpm_data');
is ($pixbuf->get_width, 4);
is ($pixbuf->get_height, 5);
ok ($pixbuf->get_has_alpha);
$vbox->add (Gtk2::Image->new_from_pixbuf ($pixbuf)) if $show;


#
# Don't crash if we get partial data.  Eat the any warnings from GdkPixbuf
# to avoid scary messages on stderr from the test suite.
#
my $log = Glib::Log->set_handler ('GdkPixbuf', ['warning'], sub {print "@_\n"});
$pixbuf = Gtk2::Gdk::Pixbuf->new_from_xpm_data (@test_xpm[0..2]);
ok (! defined ($pixbuf), "Don't crash on broken pixmap data");
$pixbuf = Gtk2::Gdk::Pixbuf->new_from_xpm_data (@test_xpm[0..5]);
ok (defined $pixbuf, "Don't crash on partial pixmap data");
Glib::Log->remove_handler ('GdkPixbuf', $log);


# raw pixel values to make the xpm above
my $rawdata = pack 'C*',
    255,0,0,255,    255,0,0,255,    0,0,0,0,        0,0,255,255,
    255,0,0,255,    0,0,0,0,        0,0,255,255,    0,0,255,255,
    0,0,0,0,        0,0,255,255,    0,0,255,255,    255,0,0,255,
    0,0,255,255,    0,0,255,255,    255,0,0,255,    255,0,0,255,
    0,0,255,255,    255,0,0,255,    255,0,0,255,    0,0,0,0,
;

$pixbuf = Gtk2::Gdk::Pixbuf->new_from_data ($rawdata, 'rgb', TRUE, 8, 4, 5, 16);
isa_ok ($pixbuf, 'Gtk2::Gdk::Pixbuf', 'new_from_data');
is ($pixbuf->get_colorspace, 'rgb');
ok ($pixbuf->get_has_alpha);
is ($pixbuf->get_width, 4);
is ($pixbuf->get_height, 5);
is ($pixbuf->get_rowstride, 16);
$vbox->add (Gtk2::Image->new_from_pixbuf ($pixbuf)) if $show;

{
  {
    package MyOverloaded;
    use overload '""' => \&stringize;
    sub new {
      my ($class) = @_;
      my $str = "not this value";
      return bless \$str, $class;
    }
    sub stringize {
      my ($self) = @_;
      return "\x01\x02\x03";
    }
  }
  my $overloaded = MyOverloaded->new;
  $pixbuf = Gtk2::Gdk::Pixbuf->new_from_data ($overloaded, 'rgb',
					      0,   # alpha
					      8,   # bits
					      1,1, # width,height
					      3);  # rowstride
  is ($pixbuf->get_pixels, "\x01\x02\x03");
  $vbox->add (Gtk2::Image->new_from_pixbuf ($pixbuf)) if $show;
}

# inlined data from gdk-pixbuf-csource, run on the xpm from above
my $inlinedata =
  "GdkP" # Pixbuf magic (0x47646b50)
. "\0\0\0[" # length: header (24) + pixel_data (67)
. "\2\1\0\2" # pixdata_type (0x2010002)
. "\0\0\0\20" # rowstride (16)
. "\0\0\0\4" # width (4)
. "\0\0\0\5" # height (5)
  # pixel_data:
. "\202\377\0\0\377\4\0\0\0\0\0\0\377\377\377\0\0\377\0\0\0\0\202\0\0\377"
. "\377\1\0\0\0\0\202\0\0\377\377\1\377\0\0\377\202\0\0\377\377\202\377"
. "\0\0\377\1\0\0\377\377\202\377\0\0\377\1\0\0\0\0";

$pixbuf = Gtk2::Gdk::Pixbuf->new_from_inline ($inlinedata, TRUE);
isa_ok ($pixbuf, 'Gtk2::Gdk::Pixbuf', 'new_from_inline');
is ($pixbuf->get_colorspace, 'rgb');
ok ($pixbuf->get_has_alpha);
is ($pixbuf->get_width, 4);
is ($pixbuf->get_height, 5);
is ($pixbuf->get_rowstride, 16);
$vbox->add (Gtk2::Image->new_from_pixbuf ($pixbuf)) if $show;


#
# these functions can throw Gtk2::Gdk::Pixbuf::Error and Glib::File::Error
# exceptions.
#
my $filename = "$dir/testsave1.jpg";
$pixbuf->save ($filename, 'jpeg', quality => 75.0);
ok (1);

$pixbuf = Gtk2::Gdk::Pixbuf->new_from_file ($filename);
isa_ok ($pixbuf, 'Gtk2::Gdk::Pixbuf', 'new_from_file');

SKIP: {
  skip "new_from_file_at_size is new in 2.4", 3
    unless Gtk2->CHECK_VERSION(2,4,0);

  $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file_at_size ($filename, 20, 25);
  isa_ok ($pixbuf, 'Gtk2::Gdk::Pixbuf', 'new_from_file_at_size');
  is ($pixbuf->get_width, 20);
  is ($pixbuf->get_height, 25);
}

SKIP: {
  skip "new_from_file_at_scale is new in 2.6", 3
    unless Gtk2->CHECK_VERSION(2,6,0);

  $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file_at_scale ($filename, 20, 25, FALSE);
  isa_ok ($pixbuf, 'Gtk2::Gdk::Pixbuf', 'new_from_file_at_scale');
  is ($pixbuf->get_width, 20);
  is ($pixbuf->get_height, 25);
}

SKIP: {
  skip "new stuff", 3
    unless Gtk2->CHECK_VERSION (2,6,0);

  my ($format, $width, $height) = Gtk2::Gdk::Pixbuf->get_file_info ($filename);
  isa_ok ($format, "Gtk2::Gdk::PixbufFormat");
  is ($width, 4);
  is ($height, 5);
}



$filename = "$dir/testsaves.png";
eval {
  $pixbuf->save ($filename, 'png',
		 'key_arg_without_value_arg');
};
like ($@, qr/odd number of arguments detected/);

my $mtime = scalar localtime;
my $desc = 'Something really cool';
$pixbuf->save ($filename, 'png',
	       'tEXt::Thumb::MTime' => $mtime,
	       'tEXt::Description' => $desc,
	       #
	       # latin1 bytes upgraded to utf8 in the xsub
	       #
	       # Crib note: if there's no upgrade in the xsub then one of
	       # two bad things happen: if libpng was built without iTXt
	       # support then gdk-pixbuf gives a GError because the bytes
	       # are not valid utf8; or if libpng does have iTXt then
	       # gdk-pixbuf drops the bytes straight in an iTXt in the file,
	       # leaving invalid utf8 there.
	       #
	       'tEXt::Title' => "z \x{B1} .5");
ok (1);

$pixbuf = Gtk2::Gdk::Pixbuf->new_from_file ($filename);
isa_ok ($pixbuf, 'Gtk2::Gdk::Pixbuf', 'new_from_file');

is ($pixbuf->get_option ('tEXt::Description'), $desc, 'get_option works');
is ($pixbuf->get_option ('tEXt::Thumb::MTime'), $mtime, 'get_option works');
ok (! $pixbuf->get_option ('tEXt::noneXIStenTTag'),
    'get_option returns undef if the key is not found');
{
	my $got = $pixbuf->get_option ('tEXt::Title');
	my $want = "z \x{B1} .5";
	utf8::upgrade ($want);
	is ($got, $want, 'get_option tEXt::Title');
	SKIP: {
		utf8->can('is_utf8')
			or skip 'utf8::is_utf8() not available (perl 5.8.0)', 1;
		ok (utf8::is_utf8($got), 'get_option tEXt::Title is_utf8()');
	}
}

SKIP: {
	skip 'new 2.2 stuff', 3
		unless Gtk2->CHECK_VERSION(2, 2, 0);

	ok (! $pixbuf->set_option ('tEXt::Description', reverse $desc),
	    'set_option refuses to overwrite');
	ok ($pixbuf->set_option ('tEXt::woot', 'whee'));
	is ($pixbuf->get_option ('tEXt::woot'), 'whee');
}


# raw pixel values to make the xpm above, but with green for the
# transparent pixels, so we can use add_alpha.
$rawdata = pack 'C*',
    255,0,0,    255,0,0,    0,255,0,    0,0,255,
    255,0,0,    0,255,0,    0,0,255,    0,0,255,
    0,255,0,    0,0,255,    0,0,255,    255,0,0,
    0,0,255,    0,0,255,    255,0,0,    255,0,0,
    0,0,255,    255,0,0,    255,0,0,    0,255,0,
;

$pixbuf = Gtk2::Gdk::Pixbuf->new_from_data ($rawdata, 'rgb', FALSE, 8, 4, 5, 12);
isa_ok ($pixbuf, 'Gtk2::Gdk::Pixbuf', 'new_from_data');
ok (!$pixbuf->get_has_alpha);
is ($pixbuf->get_rowstride, 12);
$vbox->add (Gtk2::Image->new_from_pixbuf ($pixbuf)) if $show;

my $pixbuf2 = $pixbuf->add_alpha (TRUE, 0, 255, 0);
isa_ok ($pixbuf2, 'Gtk2::Gdk::Pixbuf', 'add_alpha');
ok ($pixbuf2->get_has_alpha);
$vbox->add (Gtk2::Image->new_from_pixbuf ($pixbuf2)) if $show;


$pixbuf->copy_area (2, 3,
                    $pixbuf2->get_width - 2,
		    $pixbuf2->get_height - 3,
		    $pixbuf2, 0, 2);


$pixbuf2->saturate_and_pixelate ($pixbuf2, 0.75, FALSE);

sub pack_rgba {
	use integer;
	return (($_[0] << 0) | ($_[1] << 8) | ($_[2] << 16) | ($_[3] << 24));
}
$pixbuf->fill (pack_rgba (255, 127, 96, 196));

SKIP: {
  skip "new 2.6 stuff", 2
    unless Gtk2->CHECK_VERSION (2, 6, 0);

  isa_ok ($pixbuf->flip (TRUE), "Gtk2::Gdk::Pixbuf");
  isa_ok ($pixbuf->rotate_simple ("clockwise"), "Gtk2::Gdk::Pixbuf");
}

$pixbuf = Gtk2::Gdk::Pixbuf->new ('rgb', TRUE, 8, 32, 32);
$pixbuf2->scale ($pixbuf, 0, 0, 10, 15, 1, 2, 1.2, 3.5, 'bilinear');

$pixbuf2->composite ($pixbuf,	# dest
		     10, 5,	# dest x & y
		     4, 5,	# dest width & height
		     0, 0,	# offsets
		     2.0, 4.0,	# x & y scale factors
		     'nearest',	# interp type
		     0.4);	# overall alpha

$pixbuf2->composite_color ($pixbuf,	# dest
			   10, 5,	# dest x & y
			   4, 5,	# dest width & height
			   0, 0,	# offsets
			   2.0, 4.0,	# x & y scale factors
			   'nearest',	# interp type
			   0.4,		# overall alpha
			   3, 4,	# check x & y
			   5,		# check size
			   pack_rgba (75, 75, 75, 255),		# color 1
			   pack_rgba (192, 192, 192, 255));	# color 2


$pixbuf = $pixbuf2->scale_simple (24, 25, 'tiles');
isa_ok ($pixbuf, 'Gtk2::Gdk::Pixbuf', 'scale_simple');


$pixbuf = $pixbuf2->composite_color_simple (24, 25, 'hyper', 0.4, 
			   5,		# check size
			   pack_rgba (75, 75, 75, 255),		# color 1
			   pack_rgba (192, 192, 192, 255));	# color 2
isa_ok ($pixbuf, 'Gtk2::Gdk::Pixbuf', 'composite_color_simple');


SKIP: {
  skip "GdkPixbufFormat stuff is new in 2.2.0", 14
    unless Gtk2->CHECK_VERSION (2,2,0);

  my @formats = Gtk2::Gdk::Pixbuf->get_formats;
  ok (scalar (@formats), "got a list back");
  is (ref $formats[0], 'Gtk2::Gdk::PixbufFormat', "list of formats");
  ok (exists $formats[0]{name}, "contains key 'name'");
  ok (exists $formats[0]{description}, "contains key 'description'");
  ok (exists $formats[0]{mime_types}, "contains key 'mime_types'");
  is (ref $formats[0]{mime_types}, 'ARRAY', "'mime_types' is a list");
  ok (exists $formats[0]{extensions}, "contains key 'extensions'");
  is (ref $formats[0]{extensions}, 'ARRAY', "'extensions' is a list");
  ok (exists $formats[0]{is_writable}, "contains key 'is_writable'");
  ok ($formats[0]{is_writable} == 0 || $formats[0]{is_writable} == 1,
      "'is_writable' is 0 or 1");

  SKIP: {
    skip "new format stuff", 4
      unless Gtk2->CHECK_VERSION (2,6,0);

    ok (exists $formats[0]{is_scalable});
    ok (exists $formats[0]{is_disabled});
    ok (exists $formats[0]{license});

    $formats[0]->set_disabled (TRUE);
    @formats = Gtk2::Gdk::Pixbuf->get_formats;
    is ($formats[0]->{is_disabled}, TRUE);
  }
}

if ($show) {
	$win->show_all;
	$win->signal_connect (delete_event => sub {Gtk2->main_quit});
	Gtk2->main;
}


SKIP: {
	skip "can't test display-related stuff without a display", 7
		unless Gtk2->init_check;

	my $window = Gtk2::Gdk::Window->new (undef, {
				width => 100,
				height => 50,
				wclass => 'output',
				window_type => 'toplevel',
			});
	my $pixmap = Gtk2::Gdk::Pixmap->new ($window, 100, 50, -1);
	my $bitmap = Gtk2::Gdk::Pixmap->new ($window, 100, 50, 1);
	my $gc = Gtk2::Gdk::GC->new ($pixmap);

	$pixbuf = Gtk2::Gdk::Pixbuf->new ('rgb', FALSE, 8, 100, 50);

	$pixbuf->render_threshold_alpha ($bitmap, 0, 0, 0, 0,
	                                 $bitmap->get_size,
	                                 0.75);

	$pixbuf->render_to_drawable ($pixmap, $gc, 0, 0, 50, 20,
	                             $pixmap->get_size, 'normal', 1, 3);

	$pixbuf->render_to_drawable_alpha ($pixmap, 0, 0, 0, 0,
	                                   $pixmap->get_size, 'bilevel', 0.75,
	                                   'normal', 1, 0);

	my $colormap = $pixmap->get_colormap;
	$pixbuf = $pixbuf->add_alpha (FALSE, 0, 0, 0);
	($pixmap, $bitmap) =
		$pixbuf->render_pixmap_and_mask_for_colormap ($colormap, 0.75);
	isa_ok ($pixmap, 'Gtk2::Gdk::Pixmap');
	isa_ok ($bitmap, 'Gtk2::Gdk::Bitmap');

	# context sensitive, make sure we get the right thing back
	$pixmap = $pixbuf->render_pixmap_and_mask_for_colormap ($colormap, 0.75);
	isa_ok ($pixmap, 'Gtk2::Gdk::Pixmap');


	($pixmap, $bitmap) = $pixbuf->render_pixmap_and_mask (0.75);
	isa_ok ($pixmap, 'Gtk2::Gdk::Pixmap');
	isa_ok ($bitmap, 'Gtk2::Gdk::Bitmap');

	# context sensitive, make sure we get the right thing back
	$pixmap = $pixbuf->render_pixmap_and_mask (0.75);
	isa_ok ($pixmap, 'Gtk2::Gdk::Pixmap');

	## FIXME create a GdkImage somehow
	#$pixbuf = Gtk2::Gdk::Pixbuf->get_from_image ($src, $cmap, $src_x, $src_y, $dest_x, $dest_y, $width, $height)
	#$pixbuf = $pixbuf->get_from_image ($src, $cmap, $src_x, $src_y, $dest_x, $dest_y, $width, $height)

	$pixbuf = Gtk2::Gdk::Pixbuf->get_from_drawable
			($pixmap, undef, 0, 0, 0, 0, $pixmap->get_size);
	isa_ok ($pixbuf, 'Gtk2::Gdk::Pixbuf', 'get_from_drawable');

	$pixbuf->get_from_drawable
			($pixmap, undef, 0, 0, 0, 0, $pixmap->get_size);
}



SKIP: {
        skip "save_to_buffer was introduced in 2.4", 3
                unless Gtk2->CHECK_VERSION (2, 4, 0);

        my ($width, $height) = (45, 89);
        my $data = pack "C*", map { int rand 255 } 0..(3*$width*$height);
        my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_data
                        ($data, 'rgb', FALSE, 8, $width, $height, $width*3);
        my $buffer = eval {
            $pixbuf->save_to_buffer ('jpeg', quality => 0.75);
        } || eval {
            $pixbuf->save_to_buffer ('png'); # fallback if jpeg not supported
        };
        ok ($buffer, 'save_to_buffer');

        my $loader = Gtk2::Gdk::PixbufLoader->new;
        $loader->write ($buffer);
        $loader->close;
        $pixbuf = $loader->get_pixbuf;
        is ($pixbuf->get_width, $width);
        is ($pixbuf->get_height, $height);
}

SKIP: {
        skip 'new 2.12 stuff', 0
                unless Gtk2->CHECK_VERSION (2, 12, 0);

	$pixbuf->apply_embedded_orientation;
}

# vim: set ft=perl :
