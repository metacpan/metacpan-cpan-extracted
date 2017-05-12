package CanvasRichText;
use strict;
use utf8;
use Gnome2::Canvas;
use Glib qw(TRUE FALSE);

sub setup_text {
	my $root = shift;
	Gnome2::Canvas::Item->new ($root,
			       'Gnome2::Canvas::Rect',
			       "x1", -90.0,
			       "y1", -50.0,
			       "x2", 110.0,
			       "y2", 50.0,
			       "fill_color", "green",
			       "outline_color", "green",
			       );

	Gnome2::Canvas::Item->new ($root,
			       'Gnome2::Canvas::RichText',
			       "x", -90.0,
			       "y", -50.0,
			       "width", 200.0,
			       "height", 100.0,
			       "text", 
			       "English is so boring because everyone uses it.\n"
			       ."Here is something exciting:  "
			       ."وقد بدأ ثلاث من أكثر المؤسسات تقدما في شبكة اكسيون برامجها كمنظمات لا تسعى للربح، ثم تحولت في السنوات الخمس الماضية إلى مؤسسات مالية منظمة، وباتت جزءا من النظام المالي في بلدانها، ولكنها تتخصص في خدمة قطاع المشروعات الصغيرة. وأحد أكثر هذه المؤسسات نجاحا هو »بانكوسول« في بوليفيا.\n"
			       ."And here is some more plain, boring English.",
			       "grow_height", TRUE,
			       );

	Gnome2::Canvas::Item->new ($root,
			       'Gnome2::Canvas::Ellipse',
			       "x1", -5.0,
			       "y1", -5.0,
			       "x2", 5.0,
			       "y2", 5.0,
			       "fill_color", "white",
			       );

	Gnome2::Canvas::Item->new ($root,
			       'Gnome2::Canvas::Rect',
			       "x1", 100.0,
			       "y1", -30.0,
			       "x2", 200.0,
			       "y2", 30.0,
			       "fill_color", "yellow",
			       "outline_color", "yellow",
			       );

	Gnome2::Canvas::Item->new ($root,
			       'Gnome2::Canvas::RichText',
			       "x", 100.0,
			       "y", -30.0,
			       "width", 100.0,
			       "height", 60.0,
			       "text", "The quick brown fox jumped over the lazy dog.\n",
			       "cursor_visible", TRUE,
			       "cursor_blink", TRUE,
			       "grow_height", TRUE, 
			       );

	Gnome2::Canvas::Item->new ($root,
			       'Gnome2::Canvas::Rect',
			       "x1", 50.0,
			       "y1", 70.0,
			       "x2", 150.0,
			       "y2", 100.0,
			       "fill_color", "pink",
			       "outline_color", "pink",
			       );

	Gnome2::Canvas::Item->new ($root,
			       'Gnome2::Canvas::RichText',
			       "x", 50.0,
			       "y", 70.0,
			       "width", 100.0,
			       "height", 30.0,
			       "text", "This is a test.\nI enjoy tests a great deal\nThree lines!",
			       "cursor_visible", TRUE,
			       "cursor_blink", TRUE,
			       );
}

sub create {
	my $vbox = Gtk2::VBox->new (FALSE, 4);
	$vbox->set_border_width (4);
	$vbox->show;

	my $alignment = Gtk2::Alignment->new (0.5, 0.5, 0.0, 0.0);
	$vbox->pack_start ($alignment, TRUE, TRUE, 0);
	$alignment->show;

	my $frame = Gtk2::Frame->new;
	$frame->set_shadow_type ('in');
	$alignment->add ($frame);
	$frame->show;

	# Create the canvas and board

	my $canvas = Gnome2::Canvas->new;
	$canvas->set_size_request (600, 450);
	$frame->add ($canvas);
	$canvas->show;

	my $root = $canvas->root;

	setup_text ($root);

	return $vbox;
}

1;
