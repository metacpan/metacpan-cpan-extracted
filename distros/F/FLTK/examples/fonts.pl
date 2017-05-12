#!/usr/bin/perl
use FLTK qw( :Fonts );

$win = new Fl_Window(200, 200);
$quit = new Fl_Button(50, 105, 100, 30, "Quit");
$quit->callback(sub { exit;});
$f = new Fl_Button(50, 5, 100, 30, "Font");
$f->callback(\&get_font);
$win->end();
$win->show();

$x = 0;
Fl::run();

sub get_font {
	my ($w) = @_;
  my @fontlist = qw( courier helvetica times screen );
  if($x == $#fontlist) { $x = 0;}
	my $font = fl_font($fontlist[$x]);
  $x++;
	if($font) {
		$f->label_font($font);
	}
}
