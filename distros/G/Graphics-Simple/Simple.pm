=head1 NAME

Graphics::Simple -- a simple , device-independent graphics API for Perl

=head1 SYNOPSIS

	use Graphics::Simple;

	line 100,100,200,200;
	circle 50,50,25;
	stop(); clear(); # Wait for a button press, clear the page

=head1 DESCRIPTION

Ever had a Commodore C-64 or Vic-20 or some other of the machines
of that era? Where doing graphics was as simple as

	line 20,20,50,30;

and you didn't have to go through things like C<XOpenDisplay> etc.

This module tries to bring back the spirit of that era in a modern
environment:
this module presents a simple, unified API to several different
graphics devices - currently X (using Gtk and Gnome) and PostScript.

The interface is primarily made easy-to-use, starting from the idea
that the above C<line> command must work. Therefore, it exports
most of the primitives by default (you can turn this off).

However, everything is not sacrificed in the name
of simplicity: believing in "simple things simple, complicated
things possible", this module also allows multiple windows
(all the primitives also work as methods of window objects)
as well as raw access to the underlying devices - although the
device-independence is then lost.
In future plans are some sort of interactions with the devices
with which it is possible as well as the addition of more devices.

The C<use> command currently accepts the forms

	use Graphics::Simple;
	use Graphics::Simple qw/line circle/;
	use Graphics::Simple 300,400; # portrait paper
	use Graphics::Simple 300,400, qw/line circle/;

i.e. the optional size of the default window first and then
normal C<Exporter> arguments.

C<Graphics::Simple> has several different back-ends, currently 
GnomeCanvas, TkCanvas, PostScript and (not fully working yet) Fig.
Other backends are expected.

To start C<Graphics::Simple> with a given backend, you should set
the environment variable C<GSIMPL> to the value, e.g. by running
your script with the command

	GSIMPL='PostScript' perl gt1.pl

or by setting the environment variable permanently in your shell, by

	GSIMPL=PostScript
	export GSIMPL

or 

	setenv GSIMPL PostScript

depending on which shell you use.

=cut

# Handle output files as well

@Graphics::Simple::Window::ISA = Graphics::Simple;

package Graphics::Simple;

require Exporter;
@ISA='Exporter';

@EXPORT = qw/line linewidth circle text clear stop new_window line_to color arrow/;

@DefSize = (300,300);

sub import {
	if($_[1] =~ /^[0-9]+$/) {
		@DefSize = splice @_,1,2;
	}
	goto &Exporter::import;
}


$VERSION='0.04';

@impl = qw/
	GSGtk.pm
/;

# require 'GSGtk.pm';
# require 'GSPS.pm';

$impl = GnomeCanvas;
# $impl = PostScript;
if($ENV{GSIMPL}) {
	$impl = $ENV{GSIMPL}
}

sub new_window {
	my($x, $y) = @_;
	($x,$y) = @DefSize if(!$x) ;
	eval "use Graphics::Simple::$impl";
	die("Couldn't get implementation! '$@'") if $@;
	my($win) = "Graphics::Simple::$impl"->_construct($x,$y) ;
	$win->{Current_Color} = '#000000';
	$win->{Current_LineWidth} = 1;
	return $win;
}

$Graphics::ObjectName = "GOAAA0";

sub startargs {
	my  ($win, $name);
	$win = (UNIVERSAL::isa($_[0],Graphics::Simple::Window) ?
			shift :
			$Graphics::Simple::Window || 
			($Graphics::Simple::Window = new_window()));
	$name = (!ref $_[0] && $_[0] =~ /^[a-zA-Z]/ ?
			shift :
			$Graphics::ObjectName++);
	return ($win,$name);
}

sub startwin {
	$win = (UNIVERSAL::isa($_[0],Graphics::Simple::Window) ?
			shift :
			$Graphics::Simple::Window || 
			($Graphics::Simple::Window = new_window()));
	return $win;
}

=head2  line [$win_to], [$name], $x1, $y1, $x2, $y2, ...

Draws a line through the points given.

=cut

sub line {
	my ($win_to, $name) = &startargs;
	$win_to->_line($name, @_);
}

=head2  arrow [$win_to], [$name], $x1, $y1, $x2, $y2, ...

Like line, but makes an arrowhead in the end.

=cut

sub arrow {
	my ($win, $name) = &startargs;
	$win->line($name, @_);
	$win->_arrow_head(@_[-4,-3,-2,-1]);
}

sub _arrow_head {
	my($win, $x1,$y1,$x2,$y2) = @_;
	my $l = sqrt(($x2-$x1)**2 + ($y2-$y1)**2);
	return if abs($l) < 0.0000001;
	my $vx = ($x2-$x1)/$l;
	my $vy = ($y2-$y1)/$l;
	# my $par = 5 * sqrt($win->{Current_LineWidth}); 
	# my $perp = 4 * sqrt($win->{Current_LineWidth});
	my $par = 10;
	my $perp = 7;
	$win->line($x2-$par*$vx-$perp*$vy,
		   $y2-$par*$vy+$perp*$vx,
		   $x2, $y2,
		   $x2-$par*$vx+$perp*$vy,
		   $y2-$par*$vy-$perp*$vx);
}

=head2  line_to [$win], [$name], $x1, $y1, $x2, $y2, ...

Called several times in a sequence, starts and continues adding
points to a line. If called with no coordinates, finishes the
current line. This is just a convenient wrapper over a C<line> call with
all the parameters given - a faster way would just be to collect your
parameters to an array.

=cut

sub line_to {
	my ($win_to, $name) = &startargs;
	if(@_) {
		# $win_to->{Turtle_Name} = $name; # XXX
		push @{$win_to->{Turtle_Pts}}, @_;
	} else {
		my $p = delete $win_to->{Turtle_Pts};
		$win_to->_line($name, @$p);
	}
}

=head2  circle [$win], [$name], $x, $y, $radius

Duh.

=cut

sub circle {
	my ($win_to, $name) = &startargs;
	my($x, $y, $r) = @_;
	# $win_to->_circle($name, @_);
	$win_to->_ellipse($name, $x-$r, $y-$r, $x+$r, $y+$r);
}

=head2 ellipse [$win], [$name], $x1, $y1, $x2, $y2

The ellipse enclosed in the rectangle given by its two corners

=cut

sub ellipse {
	my ($win_to, $name) = &startargs;
	$win_to->_ellipse($name, @_);
}

=head2 text [$win], [$name], $x, $y, $string

Duh...

=cut

sub text {
	my ($win_to, $name) = &startargs;
	$win_to->_text($name, @_);
}

=head2 image [$win], [$name], $x, $y, $width, $height, $depth, $string

This command creates a rectangular bit- or pixmap. The $depth parameter
is the number of bytes per pixel (1 for B/W or 3 for RGB) and the string
is a string of packed bytes that describe the image.

For instance, the module PDL is a good source for such strings.

=cut

sub image {
	my($win_to, $name) = &startargs;
	$win_to->_image($name, @_);
}

=head2 clear, stop

	stop [$win]
	clear [$win]

C<clear> removes all the drawn elements from the window. <wait>
waits for a button press. These are usually coupled:

	stop; clear;

=cut

sub clear {
	my ($win_to) = &startargs;
	$win_to->_clear();
}

sub stop {
	my ($win_to) = &startargs;
	$win_to->_wait();
}


=head2 set_window, get_window

See the source - undocumented and potentially changing api

=cut

# We may get rid of these later.
sub set_window {
	my ($win) = @_;
	$Graphics::Simple::Window = $win;
}

sub get_window {
	return $Graphics::Simple::Window;
}


=head2 push_window, pop_window

C<Graphics::Simple> maintains a simple window stack so that subroutines
can easily use

	push_window $win;
	line ...
	pop_window();

to avoid having too many method calls.

=cut

{my @windows;
sub push_window {
	push @windows, $Window;
	$Window = $_[0];
}

sub pop_window {
	$Window = pop @windows;
}
}

=head2 color [$win,] $color;

Set the current color to $color. Currently, the colors known are

	red green blue black white

as well as any RGB color with the X syntax:

	color '#FFFF00';

is yellow. You can also give an array ref of three numbers between
0 and 1 for RGB colors.

=cut

{
my %colors = (
	red => '#FF0000',
	green => '#00FF00',
	blue => '#0000FF',
	black => '#000000',
	white => '#FFFFFF',
);
sub map_color {
	my($color) = @_;
	if(ref $color) {
		$color = sprintf("#%02x%02x%02x", map {$_*255} @$color)
	}
	$color = $colors{$color} if $colors{$color};
	die("Invalid color '$color': must be of form '#hhhhhh'")
	 unless $color =~ /^#[0-9a-fA-F]{6}?$/;
	return $color;
}
my $x = '[0-9a-fA-F]{2}?';
sub get_float_color {
	my($color) = @_;
	$color =~ /^#($x)($x)($x)$/ or die("$color not in X format");
	return [map {hex($_)/255.0} $1,$2,$3];
}
}

sub color {
	my ($win_to) = &startwin;
	my $color = map_color(shift);
	$win_to->{Current_Color} = $color;
	$win_to->_color_changed();
}

sub _color_changed { }

=head2 linewidth [$win,] $width

=cut

sub linewidth {
	my($win_to) = &startwin;
	$win_to->{Current_LineWidth} = shift;
	$win_to->_linewidth_changed();
}

sub _linewidth_changed { }

sub END {
	if(my $win = $Graphics::Simple::Window) {
		$win->_finish();
	}
}

1;

=head1 BUGS

This is an alpha proof-of-principle version - the API may still change
wildly.

=head1 AUTHOR

Copyright(C) Tuomas J. Lukka 1999. All rights reserved.
This software may be distributed under the same conditions as Perl itself.

=cut
