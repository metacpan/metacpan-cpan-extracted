package Image::CairoSVG;
use warnings;
use strict;

our $VERSION = '0.11';

use Carp qw/carp croak/;
use XML::Parser;
use Cairo;
use Image::SVG::Path qw/extract_path_info create_path_string/;

use constant M_PI => 3.14159265358979;

our $default_surface_type = 'argb32';
our $default_surface_size = 100;

sub new
{
    my ($class, %options) = @_;

    my $self = bless {};

    my $context = $options{context};
    my $surface = $options{surface};
    my $verbose = $options{verbose};

    delete $options{context};
    delete $options{surface};
    delete $options{verbose};

    for my $k (keys %options) {
	carp "Unknown option $k";
    }

    if ($verbose) {
	debugmsg ("Debugging messages switched on");
	$self->{verbose} = 1;
    }

    if ($context) {
	$self->{cr} = $context;
	if ($surface) {
	    carp "Value of surface ignored: specify either cr or surface";
	}
	if ($self->{verbose}) {
	    debugmsg ("Using user-supplied context $self->{cr}");
	}
    }
    elsif ($surface) {
	$self->{surface} = $surface;
	$self->make_cr ();
	if ($self->{verbose}) {
	    debugmsg ("Using user-supplied surface $self->{surface}");
	}
    }
    return $self;
}

sub make_cr
{
    my ($self) = @_;
    if (! $self->{surface}) {
	die "BUG: No surface";
    }
    $self->{cr} = Cairo::Context->create ($self->{surface});
    if (! $self->{cr}) {
	# We won't be able to do very much without a context.
	croak "Cairo::Context->create failed";
    }
}

sub render
{
    my ($self, $file) = @_;
    my $p = XML::Parser->new (
	Handlers => {

	    # I think (may be wrong) we only need to handle "start"
	    # tags for SVG. As far as I know, everything in SVG is a
	    # "start" tag plus attributes.

	    Start => sub {
		handle_start ($self, @_);
	    },
	    End => sub {
		handle_end ($self, @_);
	    },
	},
    );
    if ($file =~ /<.*>/) {
	if ($self->{verbose}) {
	    debugmsg ("Input looks like a scalar");
	}
	# parse from scalar
	$p->parse ($file);
    }
    elsif (! -f $file) {
	croak "No such file '$file'";
    }
    else {
	$self->{file} = $file;
	if ($self->{verbose}) {
	    debugmsg ("Input looks like a file");
	}
	$p->parsefile ($file);
    }
    return $self->{surface};
}

sub handle_end
{
    my ($self, $parser, $tag) = @_;
    # At the end of a group, delete its attributes.
    if ($tag eq 'g') {
	delete $self->{attr};
    }
}

# <svg> tag seen

sub svg
{
    my ($self, %attr) = @_;
    my $width;
    my $height;
    if ($attr{width}) {
	$width = $attr{width};
    }
    if ($attr{height}) {
	$height = $attr{height};
    }

    # Use viewBox attribute

    if (! defined $width && ! defined $height) {
	my $viewBox = $attr{viewBox} || $attr{viewbox};
	if ($viewBox) {
	    (undef, undef, $width, $height) = split /\s+/, $viewBox;
	}
    }
    my $surface = $self->{surface};
    if (! $self->{cr} && ! $surface) {
	if ($self->{verbose}) {
	    debugmsg ("User did not supply surface or context");
	}
	if (! $width || ! $height) {
	    carp "Image width or height not found in $self->{file}";
	    $surface = Cairo::ImageSurface->create (
		$default_surface_type,
		$default_surface_size,
		$default_surface_size,
	    );
	}
	else {
	    if ($self->{verbose}) {
		debugmsg ("Creating new surface");
	    }
	    $surface = Cairo::ImageSurface->create (
		$default_surface_type,
		$width,
		$height,
	    );
	}
	$self->{surface} = $surface;
	$self->make_cr ();
    }
}

# Start tag handler for the XML parser. This is private.

sub handle_start
{
    my ($self, $parser, $tag, %attr) = @_;

    if ($tag eq 'svg') {
	$self->svg (%attr);
    }
    elsif ($tag eq 'path') {
	$self->path (%attr);
    }
    elsif ($tag eq 'polygon') {
	$self->polygon (%attr);
    }
    elsif ($tag eq 'line') {
	$self->line (%attr);
    }
    elsif ($tag eq 'circle') {
	$self->circle (%attr);
    }
    elsif ($tag eq 'ellipse') {
	$self->ellipse (%attr);
    }
    elsif ($tag eq 'rect') {
	$self->rect (%attr);
    }
    elsif ($tag eq 'title') {
	;
    }
    elsif ($tag eq 'g') {
	$self->{attr} = \%attr;
    }
    elsif ($tag eq 'polyline') {
	$self->polyline (%attr);
    }
    else {
	if ($self->{verbose}) {
	    print "Unhandled tag '$tag'.\n";
	}
#	warn "Unknown tag '$tag' in $self->{file}";
    }

    # http://www.princexml.com/doc/7.1/svg/
    # g, rect, circle, ellipse, line, path, text, tspan
}

sub rect
{
    my ($self, %attr) = @_;

    my $x = $self->convert_svg_units ($attr{x});
    my $y = $self->convert_svg_units ($attr{y});
    my $width = $self->convert_svg_units ($attr{width});
    my $height = $self->convert_svg_units ($attr{height});

    my $cr = $self->{cr};

    $cr->rectangle ($x, $y, $width, $height);

    $self->do_svg_attr (%attr);
}

sub ellipse
{
    my ($self, %attr) = @_;

    my $cx = $self->convert_svg_units ($attr{cx});
    my $cy = $self->convert_svg_units ($attr{cy});
    my $rx = $self->convert_svg_units ($attr{rx});
    my $ry = $self->convert_svg_units ($attr{ry});

    my $cr = $self->{cr};

    # http://cairographics.org/manual/cairo-Paths.html#cairo-arc

    $cr->save ();
    $cr->translate ($cx, $cy);
    $cr->scale ($rx, $ry);

    # Render it.

    $cr->arc (0, 0, 1, 0, 2*M_PI);

    $cr->restore ();

    $self->do_svg_attr (%attr);
}

sub circle
{
    my ($self, %attr) = @_;

    my $cx = $self->convert_svg_units ($attr{cx});
    my $cy = $self->convert_svg_units ($attr{cy});
    my $r = $self->convert_svg_units ($attr{r});

    my $cr = $self->{cr};

    # Render it.

    $cr->arc ($cx, $cy, $r, 0, 2*M_PI);

    $self->do_svg_attr (%attr);
}

sub split_points
{
    my ($points) = @_;
    my @points = split /,\s*|\s+/, $points;
    die "Bad points $points" if @points % 2 != 0;
    return @points;
}

sub polygon
{
    my ($self, %attr) = @_;
    my @points = split_points ($attr{points});

    my $cr = $self->{cr};

    # Render it.

    my $y = pop @points;
    my $x = pop @points;
    $cr->move_to ($x, $y);

    while (@points) {
	$y = pop @points;
	$x = pop @points;
	$cr->line_to ($x, $y);
    }
    $cr->close_path ();
    $self->do_svg_attr (%attr);
}

sub polyline
{
    my ($self, %attr) = @_;
    my @points = split_points ($attr{points});

    my $cr = $self->{cr};

    # Render it.

    my $y = pop @points;
    my $x = pop @points;
    $cr->move_to ($x, $y);

    while (@points) {
	$y = pop @points;
	$x = pop @points;
	$cr->line_to ($x, $y);
    }
    $self->do_svg_attr (%attr);
}

sub path
{
    my ($self, %attr) = @_;

    # Get and parse the "d" attribute from the path.

    my $d = $attr{d};
    croak "No d in path" unless $d;
    my @path_info = extract_path_info ($d, {
	absolute => 1,
	no_shortcuts => 1,
    });

    # Cairo context.

    my $cr = $self->{cr};

    if (! $cr) {
	croak "No context in $self";
    }

    for my $element (@path_info) {

	my $key = $element->{svg_key};

	if ($key eq lc $key) {
	    # This is a bug, "extract_path_info" above should never
	    # return a lower-case key, which means a relative path.
	    die "Path parse conversion to absolute failed";
	}

	if ($key eq 'S') {
	    # This is a bug, "extract_path_info" above should never
	    # return a shortcut key, they should have been converted
	    # to C keys.
	    die "Path parse conversion to no shortcuts failed";
	}

	if ($key eq 'M') {
	    # Move to
	    $cr->new_sub_path ();
	    $cr->move_to (@{$element->{point}});
	}
	elsif ($key eq 'L') {
	    $cr->line_to (@{$element->{point}});
	}
	elsif ($key eq 'C') {
	    $cr->curve_to (@{$element->{control1}},
			   @{$element->{control2}},
			   @{$element->{end}});
	}
	elsif ($key eq 'Z') {
	    $cr->close_path ();
	}
	elsif ($key eq 'Q') {
	    # Cairo doesn't support quadratic bezier curves, so we use
	    # quadbez to draw them.
	    quadbez ($cr, $element->{control}, $element->{end});
	}
	elsif ($key eq 'V') {
	    # Vertical line, x remains constant, so use original x ($xo).
	    my ($xo, undef) = $cr->get_current_point ();
	    $cr->line_to ($xo, $element->{y});
	}
	elsif ($key eq 'H') {
	    # Horizontal line, y remains constant, so use original y ($yo).
	    my (undef, $yo) = $cr->get_current_point ();
	    $cr->line_to ($element->{x}, $yo);
	}
	elsif ($key eq 'A') {
	    $self->svg_arc ($element);
	}
	else {
	    carp "Unknown SVG path key '$key': ignoring";
	}
    }
    $self->do_svg_attr (%attr);
}

# This is a Perl translation of 
# https://github.com/Kozea/CairoSVG/blob/74701790b5fd299e99f993b18ea676f3284907b4/cairosvg/surface/path.py

sub svg_arc
{
    my ($self, $element) = @_;
    my $rx = $element->{rx};
    my $ry = $element->{ry};
    my $x3 = $element->{x};
    my $y3 = $element->{y};

    my $cr = $self->{cr};

    # rx=0 or ry=0 means straight line

    if ($rx == 0 || $ry == 0) {
	$cr->line_to ($x3, $y3);
	return;
    }

    my ($x1, $y1) = $cr->get_current_point ();

    # Calculations

    my $x_axis_rotation = (M_PI * $element->{x_axis_rotation})/180;
    my $large_arc_flag = $element->{large_arc_flag};
    my $sweep_flag = $element->{sweep_flag};

    # Translate $x3, $y3 to relative coords

    $x3 -= $x1;
    $y3 -= $y1;

    my $radii_ratio = $ry / $rx;

    my ($xe, $ye) = rotate ($x3, $y3, -$x_axis_rotation);

    $ye /= $radii_ratio;
    my $angle = point_angle (0, 0, $xe, $ye);

    $xe = sqrt ($xe**2 + $ye**2);
    $ye = 0;

    if ($xe / 2 > $rx) {
	$rx = $xe / 2;
    }
    my $xc = $xe / 2;
    my $yc = sqrt ($rx**2 - $xc**2);

    if (! ($large_arc_flag ^ $sweep_flag)) {
	$yc = -$yc;
    }
    ($xe, $ye) = rotate ($xe, 0, $angle);
    ($xc, $yc) = rotate ($xc, $yc, $angle);

    my $angle1 = point_angle ($xc, $yc, 0, 0);
    my $angle2 = point_angle ($xc, $yc, $xe, $ye);

    # Draw the arc

    $cr->save ();
    $cr->translate ($x1, $y1);
    $cr->rotate ($x_axis_rotation);
    if ($sweep_flag) {
	$cr->arc ($xc, $yc, $rx, $angle1, $angle2);
    }
    else {
	$cr->arc_negative ($xc, $yc, $rx, $angle1, $angle2);
    }
    $cr->restore ();
}

# Quadratic bezier curve shim for Cairo

# Private routine for this module.

sub quadbez
{
    my ($cr, $p2, $p3) = @_;

    if (! $cr->has_current_point ()) {
	# This indicates a bug has happened, because there is always a
	# current point when rendering an SVG path.
	die "Invalid drawing of quadratic bezier without a current point";
    }

    my @p1 = $cr->get_current_point ();
    my @p2_1;
    my @p2_2;

    # https://en.wikipedia.org/wiki/B%C3%A9zier_curve#Degree_elevation

    for my $c (0, 1) {
	$p2_1[$c] = ($p1[$c] + 2 * $p2->[$c]) / 3;
	$p2_2[$c] = ($p3->[$c] + 2 * $p2->[$c]) / 3; 
    }
    $cr->curve_to (@p2_1, @p2_2, @$p3);
}

sub line
{
    my ($self, %attr) = @_;
    my @fields = qw/x1 x2 y1 y2/;
    for (@fields) {
	if (! defined $attr{$_}) {
	    croak "No $_ in line";
	}
    }
    my $cr = $self->{cr};
    $cr->move_to ($attr{x1}, $attr{y1});
    $cr->line_to ($attr{x2}, $attr{y2});
    $self->do_svg_attr (%attr);
}

sub convert_svg_units
{
    my ($self, $thing) = @_;
    if (! defined $thing) {
	return 0;
    }
    if ($thing eq '') {
	return 0;
    }
    if ($thing =~ /^(\d|\.)+$/) {
	return $thing;
    }
    if ($thing =~ /(\d+)px/) {
	$thing =~ s/px$//;
	return $thing;
    }
    carp "Could not convert SVG units '$thing'";
}

# We have a path in the cairo surface and now we have to do the SVG
# crap specified by "%attr".

sub do_svg_attr
{
    my ($self, %attr) = @_;

    # Copy attributes from "self".

    if ($self->{attr}) {
	for my $k (keys %{$self->{attr}}) {
	    if (! $attr{$k}) {
		$attr{$k} = $self->{attr}{$k};
	    }
	    else {
		carp "Not overwriting attribute $k";
	    }
	}
    }

    if ($attr{style}) {
	my @styles = split /;/, $attr{style};
	for (@styles) {
	    my ($key, $value) = split /:/, $_, 2;
	    # Is this the way to do it?
	    $attr{$key} = $value;
	}
    }
    my $fill = $attr{fill};
    if ($fill) {
	$fill =~ s/^\s+|\s+$//g;
    }
    my $stroke = $attr{stroke};
    if ($stroke) {
	$stroke =~ s/^\s+|\s+$//g;
    }
    my $cr = $self->{cr};
    my $stroke_width = $attr{"stroke-width"};
    if ($stroke_width) {
	$stroke_width = $self->convert_svg_units ($stroke_width);
	$cr->set_line_width ($stroke_width);
    }
    if ($fill && $fill ne 'none') {
	if ($stroke && $stroke ne 'none') {
	    $self->set_colour ($fill);
	    $cr->fill_preserve ();
	    $self->set_colour ($stroke);
	    $cr->stroke ();
	}
	else {
	    $self->set_colour ($fill);
	    $cr->fill ();
	}
    }
    elsif ($stroke && $stroke ne 'none') {
	$self->set_colour ($stroke);
	$cr->stroke ();
    }
    elsif (! $fill && ! $stroke) {
	# Fill with black seems to be the default.
	$self->set_colour ('#000000');
	$cr->fill ();
    }
}

sub set_colour
{
    my ($self, $colour) = @_;
    my $cr = $self->{cr};
    # Hex digit
    my $h = qr/[0-9a-f]/i;
    my $hh = qr/$h$h/;
    if ($colour eq 'black') {
	$cr->set_source_rgb (0, 0, 0);
    }
    elsif ($colour eq 'white') {
	$cr->set_source_rgb (1, 1, 1);
    }
    elsif ($colour =~ /^#($h)($h)($h)$/) {
	$cr->set_source_rgb (hex ($1)/15, hex ($2)/15, hex ($3)/15);
    }
    elsif ($colour =~ /^#($hh)($hh)($hh)$/) {
	$cr->set_source_rgb (hex ($1)/255, hex ($2)/255, hex ($3)/255);
    }
    else {
	warn "Unknown colour '$colour'";
    }
}

sub surface
{
    my ($self) = @_;
    return $self->{surface};
}

# Return angle between x axis and point knowing given center.

# https://github.com/Kozea/CairoSVG/blob/74701790b5fd299e99f993b18ea676f3284907b4/cairosvg/surface/helpers.py#L116

sub point_angle
{
    my ($cx, $cy, $px, $py) = @_;
    return atan2 ($py - $cy, $px - $cx);
}

sub rotate
{
    my ($x, $y, $angle) = @_;
    return ($x * cos ($angle) - $y * sin ($angle),
	    $y * cos ($angle) + $x * sin ($angle));
}

sub debugmsg
{
    my (undef, $file, $line) = caller (0);
    printf ("%s:%d: ", $file, $line);
    print "@_\n";
}

1;

