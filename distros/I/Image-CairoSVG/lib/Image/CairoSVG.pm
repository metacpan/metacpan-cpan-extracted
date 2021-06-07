package Image::CairoSVG;
use warnings;
use strict;
use utf8;

our $VERSION = '0.22';

# Core modules
use Carp qw/carp croak confess cluck/;
use Math::Trig qw!acos pi rad2deg deg2rad tan!;
use Scalar::Util 'looks_like_number';

# Modules the user needs to install

use XML::Parser;
use Cairo;
use Image::SVG::Path qw/extract_path_info/;

our $default_surface_type = 'argb32';
our $default_surface_size = 100;

# This is what the SVG standard says the default colour is.

our @defaultrgb = (0, 0, 0);

use constant {

    # The Cairo default value for the miter limit is slightly different to
    # the SVG default value, so this needs to be set initially to draw
    # SVGs correctly.

    # Cairo's default value is 10:
    # https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-set-miter-limit

    # SVG's default value is 4:
    # https://www.w3.org/TR/SVG11/painting.html#StrokeMiterlimitProperty
    # https://svgwg.org/svg2-draft/painting.html#StrokeMiterlimitProperty
    SVG_MITERLIMIT => 4,
    true => 1,
    false => 0,
};


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
	    carp "Value of surface option ignored: specify only one of either context or surface";
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

# Make the Cairo context for our surface.

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
    $self->{cr}->set_miter_limit (SVG_MITERLIMIT);
}

sub render
{
    my ($self, $file) = @_;
    my $p = XML::Parser->new (
	Handlers => {
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
    $self->{depth} = 0;
    $self->_render ($self->{top});
    return $self->{surface};
}

# These elements are not rendered.

my %no_render = (
    clipPath => true,
    defs => true,
    linearGradient => true,
    radialGradient => true,
    title => true,
);

# This is the rendering routine for an element and its children. The
# rendering routine for individual objects is "_draw".

sub _render
{
    my ($self, $element, $pattr) = @_;
    my $tag = $element->{tag};
    if ($no_render{$tag}) {
	# Put the title into the output PNG as text, etc.
	return;
    }
    my ($attr, $restore) = $self->_draw ($element, $pattr);
    $self->{depth}++;
    my $child = $element->{child};
    for (@$child) {
	$self->_render ($_, $attr);
    }
    $self->{depth}--;
    $self->_draw_end ($element, $restore);
}

# Extract the ID in an href from a list of attributes. This has to
# deal with both xlink:href and href.

sub x_id
{
    my (%attr) = @_;
    my $id = $attr{'xlink:href'};
    if (! $id) {
	$id = $attr{href};
    }
    if (! $id) {
	carp "No xlink:href/href found";
	return undef;
    }
    $id =~ s/^#//;
    return $id;
}

# Process a <use> element. We can't easily call this routine "use"
# since that is a Perl keyword.

sub processUse
{
    my ($self, %attr) = @_;
    my $id = x_id (%attr);
    my $element = $self->get_id ($id);
    if (! $element) {
	carp "ID $id in use not found";
	return;
    }
    my $cr = $self->{cr};
    my $x = $attr{x};
    my $y = $attr{y};
    if (defined $x || defined $y) {
	if (! defined $x) {
	    $x = 0;
	}
	if (! defined $y) {
	    $y = 0;
	}
	$self->msg ("Moving to $x $y");
	$cr->save ();
	$cr->translate ($x, $y);
    }

    $self->_render ($element, \%attr);

    if (defined $x || defined $y) {
	$cr->restore ();
    }
}

# This is the rendering routine for individual items in the SVG
# document such as a circle.

sub _draw
{
    my ($self, $element, $pattr) = @_;
    my $tag = $element->{tag};
    $self->msg ("<$tag>");
    my $attr = $element->{attr};

    # %attr is a holder for inherited attributes. The inherited
    # attributes are not written into $element->{attr} since it's
    # possible that a <use> element might re-use the element, but want
    # to give it different inherited attributes, so %attr does the job
    # of keeping the actual element attributes (the ones written in
    # the SVG itself) separate from the inherited (implicit)
    # attributes.

    my %attr = %$attr;

    # This list of inherited things is guesswork so far, there is
    # probably a list of what to copy somewhere but I haven't located
    # it yet.

    for my $key (qw!
	fill
	fill-opacity
	fill-rule
	opacity
	stroke
	stroke-dasharray
	stroke-dashoffset
	stroke-linecap
	stroke-linejoin
	stroke-miterlimit
	stroke-opacity
	stroke-width
    !) {
	if ($pattr->{$key} && ! defined $attr{$key}) {
	    $attr{$key} = $pattr->{$key};
	}
    }

    # If true, do not draw (fill or stroke) the current object.
    my $nodraw;

    if ($self->{_clipping}) {
	$self->msg ("_clipping, not rendering");
	$nodraw = true;
    }
    my $restore = $self->do_svg_attr (%attr);
    if ($tag eq 'svg' || $tag eq 'g') {
	# These are non-rendering, i.e. don't result in visual output.
	$nodraw = true;
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
    elsif ($tag eq 'polyline') {
	$self->polyline (%attr);
    }
    elsif ($tag eq 'use') {
	$self->processUse (%attr);
	# The element is rendered within processUse.
	$nodraw = true;
    }
    elsif ($tag eq 'defs') {
	# Throw an exception. Arriving here is a bug, we should have
	# stopped at _render. The <defs> element is processed and
	# stored by the parser, but it is not used directly by the
	# renderer. Its children are probably used by a <use> element.
	confess "<defs> element reached";
    }
    elsif ($no_render{$tag}) {
	confess "<$tag> element reached";
    }
    else {
	if ($self->{verbose}) {
	    # There are probably many of these since this module is
	    # not up to spec, so only complain if the user wants
	    # "verbose" messages.
	    $self->msg ("Unable to draw SVG element '<$tag>'");
	    $nodraw = 1;
	}
    }
    if (! $nodraw) {
	$self->do_fill_stroke (\%attr);
    }
    return (\%attr, $restore);
}

sub do_clip_path
{
    my ($self, $id) = @_;
    $id =~ s!url\(#(.*?)\)!$1!;
    my $element = $self->get_id ($id);
    if (! $element) {
	carp "ID $id in clip-path not found";
	return;
    }
    my $tag = $element->{tag};
    if ($tag ne 'clipPath') {
	carp "Cannot clip to non-clipPath '$tag'";
	return;
    }
    $self->msg ("Clipping to $id");
    $self->{_clipping} = true;
    $self->{depth}++;
    my $children = $element->{child};
    for my $child (@$children) {
	$self->_render ($child);
    }
    $self->{_clipping} = false;
    $self->msg ("Finished clipping to $id");
    $self->{depth}--;
    my $cr = $self->{cr};
    $cr->clip ();
}

sub _draw_end
{
    my ($self, $element, $restore) = @_;
    my $tag = $element->{tag};
    $self->msg ("</$tag>");
    if ($restore) {
	my $cr = $self->{cr};
	$cr->restore ();
    }
}

sub handle_end
{
    # Last argument is $tag
    my ($self, $parser, undef) = @_;
    my $element = pop @{$self->{elements}};
    my $attr = $element->{attr};
}

sub svg
{
    my ($self, %attr) = @_;

    # Try to work out the height and width of the image. SVG is a very
    # complicated format, so the height and width can be stored in
    # multiple places.

    my $min_x;
    my $min_y;
    my $width;
    my $height;
    my $x_scale;
    my $y_scale;
    if ($attr{width}) {
	$width = $attr{width};
	($width, $x_scale) = svg_units_scale ($width);
    }
    if ($attr{height}) {
	$height = $attr{height};
	($height, $y_scale) = svg_units_scale ($height);
    }

    # Use viewBox attribute

    if (! defined $width && ! defined $height) {
	my $viewBox = $attr{viewBox} || $attr{viewbox};
	if ($viewBox) {
	    ($min_x, $min_y, $width, $height) = split /\s+/, $viewBox;
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
    my $cr = $self->{cr};
    if (defined $min_x && defined $min_y && ($min_x != 0 || $min_y != 0)) {
	$cr->translate (-$min_x, -$min_y);
    }
    if (defined $x_scale && defined $y_scale &&
	($x_scale != 1 || $y_scale != 1)) {
	$self->msg ("Scaling to $x_scale / $y_scale");
	$cr->scale ($x_scale, $y_scale);
    }

    my $svg = {
	tag => 'svg',
	attr => \%attr,
	child => [],
    };

    # Store of ids of elements within the tree
    $self->{ids} = {};
    # Currently open tags (misnamed)
    $self->{elements} = [$svg];
    $self->{top} = $svg;
}

sub add_element
{
    my ($self, $tag, $attr) = @_;
    my $element = {
	tag => $tag,
	attr => $attr,
	child => [],
    };
    my $top = $self->{elements}[-1];
    if (! $top) {
	die "Empty stack";
    }
    push @{$top->{child}}, $element;
    $element->{parent} = $top;
    push @{$self->{elements}}, $element;
    return $element;
}

# Store an ID so it can be retrieved later.

sub store_id
{
    my ($self, $element, $id) = @_;
    my $already = $self->{ids}{$id};
    if ($already) {
	carp "Duplicate id '$id' on element '<$already->{tag}>'";
	return;
    }
    $self->{ids}{$id} = $element;
}

# Retrieve an element by ID. This is used by <use>.

sub get_id
{
    my ($self, $id) = @_;
    my $already = $self->{ids}{$id};
    if ($already) {
	return $already;
    }
    return undef;
}

# Start tag handler for the XML parser. This is private.

sub handle_start
{
    my ($self, $parser, $tag, %attr) = @_;

    if ($tag eq 'svg') {
	$self->svg (%attr);
    }
    else {
	my $element = $self->add_element ($tag, \%attr);
	# I don't think svgs ids need to be stored here.
	if ($attr{id}) {
	    $self->store_id ($element, $attr{id});
	}
    }
}

# Around the rugged rectangle the ragged rascals ran. "Polyfill" for
# Cairo since it has no native rounded rectangles.

sub rounded_rectangle
{
    my ($self, %attr) = @_;
    my $cr = $self->{cr};
    # https://www.cairographics.org/samples/rounded_rectangle/
    my $x = svg_units ($attr{x});
    my $y = svg_units ($attr{y});
    my $width = svg_units ($attr{width});
    my $height = svg_units ($attr{height});
    my $rx;
    if ($attr{rx}) {
	if ($attr{rx} =~ /([0-9\.]+)%$/) {
	    $rx = $width * $1/100;
	}
	else {
	    $rx = svg_units ($attr{rx});
	}
    }
    # This is a kludge/hack at the moment.
    #    my $ry;
    #    if ($attr{ry}) {
    #	$ry = svg_units ($attr{ry});
    #    }
    $cr->new_sub_path ();
    $cr->arc ($x + $width - $rx, $y +           $rx, $rx, -pi/2,      0);
    $cr->arc ($x + $width - $rx, $y + $height - $rx, $rx,     0,   pi/2);
    $cr->arc ($x + $rx,          $y + $height - $rx, $rx,  pi/2,     pi);
    $cr->arc ($x + $rx,          $y +           $rx, $rx,    pi, 3*pi/2);
    $cr->close_path ();
}

sub rect
{
    my ($self, %attr) = @_;

    if ($attr{rx} || $attr{ry}) {
	rounded_rectangle ($self, %attr);
	return;
    }

    my $x = svg_units ($attr{x});
    my $y = svg_units ($attr{y});
    my $width = svg_units ($attr{width});
    my $height = svg_units ($attr{height});

    my $cr = $self->{cr};

    $cr->rectangle ($x, $y, $width, $height);

}

sub ellipse
{
    my ($self, %attr) = @_;

    my $cx = svg_units ($attr{cx});
    my $cy = svg_units ($attr{cy});
    my $rx = svg_units ($attr{rx});
    my $ry = svg_units ($attr{ry});

    my $cr = $self->{cr};

    # http://cairographics.org/manual/cairo-Paths.html#cairo-arc

    $cr->save ();
    $cr->translate ($cx, $cy);
    $cr->scale ($rx, $ry);

    # Render it.

    $cr->arc (0, 0, 1, 0, 2*pi);

    $cr->restore ();

}

sub circle
{
    my ($self, %attr) = @_;

    my $cx = svg_units ($attr{cx});
    my $cy = svg_units ($attr{cy});
    my $r = svg_units ($attr{r});

    my $cr = $self->{cr};

    # Render it.

    $cr->arc ($cx, $cy, $r, 0, 2*pi);
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
}

sub path
{
    my ($self, %attr) = @_;

    # Get and parse the "d" attribute from the path using
    # Image::SVG::Path.

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
	    confess "Path parse conversion to absolute failed";
	}

	if ($key eq 'S') {
	    # This is a bug, "extract_path_info" above should never
	    # return a shortcut key, they should have been converted
	    # to C keys.
	    confess "Path parse conversion to no shortcuts failed";
	}
	if ($key eq 'M') {
	    # Move to
	    $cr->new_sub_path ();
	    $cr->move_to (@{$element->{point}});

	    # This is debugging code from the changeover to two-stage
	    # rendering.

	    # $self->msg ("Move to @{$element->{point}}");
	    # print $cr->status (), "\n";
	    # my @p1 = $cr->get_current_point ();
	    # $self->msg ("Move to @p1");

	}
	elsif ($key eq 'L') {
	    $cr->line_to (@{$element->{point}});
	}
	elsif ($key eq 'C') {
	    $cr->curve_to (
		@{$element->{control1}},
		@{$element->{control2}},
		@{$element->{end}},
	    );
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
}

# This is a Perl translation of the arc drawing code in
# https://github.com/Kozea/CairoSVG/blob/master/cairosvg/path.py

sub svg_arc
{
    my ($self, $element) = @_;
    my $cr = $self->{cr};
    my ($x1, $y1) = $cr->get_current_point ();
    my ($rx, $ry) = ($element->{rx}, $element->{ry});
    my $rotation = deg2rad ($element->{x_axis_rotation});
    my $fa = $element->{large_arc_flag};
    my $fs = $element->{sweep_flag};
    if ($fa != 0 && $fa != 1) {
	croak "large-arc-flag must be either 0 or 1";
    }
    if ($fs != 0 && $fs != 1) {
	croak "sweep-flag must be either 0 or 1";
    }
    my $x3 = $element->{x};
    my $y3 = $element->{y};
    $x3 -= $x1;
    $y3 -= $y1;
    my $radii_ratio = $ry / $rx;
    my ($xe, $ye) = rotate ($x3, $y3, -$rotation);
    $ye /= $radii_ratio;

    my $angle = point_angle (0, 0, $xe, $ye);

    $xe = sqrt ($xe**2 + $ye**2);
    $ye = 0;
    my $xe2 = $xe / 2;
    if ($rx < $xe2) {
	$rx = $xe2;
    }
    my $xc = $xe2;
    my $yc = sqrt ($rx**2 - $xc**2);
    if ($fa == $fs) {
	$yc = - $yc;
    }
    ($xe, $ye) = _rotate ($xe, 0, $angle);
    ($xc, $yc) = _rotate ($xc, $yc, $angle);
    my $angle1 = _point_angle ($xc, $yc, 0, 0);
    my $angle2 = _point_angle ($xc, $yc, $xe, $ye);
    $cr->save ();
    $cr->translate ($x1, $y1);
    $cr->rotate ($rotation);
    $cr->scale (1, $radii_ratio);
    if ($fs) {
	$cr->arc ($xc, $yc, $rx, $angle1, $angle2);
    }
    else {
	$cr->arc_negative ($xc, $yc, $rx, $angle1, $angle2);
    }
    $cr->restore ();
    
}

sub _point_angle
{
    my ($cx, $cy, $px, $py) = @_;
    return atan2 ($py - $cy, $px - $cx);
}

sub _rotate
{
    my ($x, $y, $angle) = @_;
    my $s = sin $angle;
    my $c = cos $angle;
    my $xr = $c * $x - $s * $y;
    my $yr = $c * $y + $s * $x;
    return ($xr, $yr);
}

# Quadratic bezier curve shim for Cairo

# Private routine for this module.

sub quadbez
{
    my ($cr, $p2, $p3) = @_;

    if (! $cr->has_current_point ()) {
	# This indicates a bug has happened, because there is always a
	# current point when rendering an SVG path.
	confess "Invalid drawing of quadratic bezier without a current point";
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
}

my %units = (
    # https://www.w3.org/TR/css3-values/#absolute-lengths

    # 96 pixels per inch divided by 25.4 millimetres per inch gives
    # pixels / mm. This is the way an SVG made by Inkscape will be
    # dimensioned in a web browser.

    mm => 96/25.4,
    in => 96,
    px => 1,
);

# Return units and a scale

sub svg_units_scale
{
    my ($thing) = @_;
    if (! defined $thing) {
	return (0, 1);
    }
    if ($thing eq '') {
	return (0, 1);
    }
    if (looks_like_number ($thing)) {
	return ($thing, 1);
    }
    if ($thing =~ /([0-9\.]+)%$/) {
	return (undef,1);
    }
    if ($thing =~ /([0-9\.]+)(\w+)$/) {
	my $number = $1;
	my $unit = $2;
	my $u = $units{$unit};
	if ($u) {
	    return ($number * $u, $u);
	}
	carp "Unknown unit $unit in '$thing'";
	return ($number, 1);
    }
    carp "Failed to convert SVG units '$thing'";
    return (undef, 1);
}

sub svg_units
{
    my ($value, undef) = svg_units_scale (@_);
    return $value;
}

my $fpnum = qr!-?(?:[0-9]*\.[0-9]+|0|[0-9]+)!;

# Save the drawing context if necessary.

sub save
{
    my ($self, $restore_ref) = @_;
    if (! $$restore_ref) {
	my $cr = $self->{cr};
	$cr->save ();
	$$restore_ref = 1;
    }
}

# We have a path in the cairo surface and now we have to do the SVG
# instructions specified by "%attr".

sub do_svg_attr
{
    my ($self, %attr) = @_;

    my $restore;

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
	    $attr{$key} = $value;
	}
    }
    my $cr = $self->{cr};
    my $stroke_width = $attr{"stroke-width"};
    if ($stroke_width) {
	$self->save (\$restore);
	$stroke_width = svg_units ($stroke_width);
	$cr->set_line_width ($stroke_width);
    }
    my $linecap = $attr{"stroke-linecap"};
    if ($linecap) {
	$self->save (\$restore);
	$cr->set_line_cap ($linecap);
    }
    my $linejoin = $attr{"stroke-linejoin"};
    if ($linejoin) {
	$self->save (\$restore);
	$cr->set_line_join ($linejoin);
    }
    my $transform = $attr{transform};
    if ($transform) {
	$self->save (\$restore);
	$self->do_transforms (%attr);
    }
    my $fill_rule = $attr{'fill-rule'};
    if ($fill_rule) {
	$self->save (\$restore);
	# Cairo supports the same two things as SVG, but with
	# different names.
	if ($fill_rule eq 'nonzero') {
	    $cr->set_fill_rule ('winding');
	}
	elsif ($fill_rule eq 'evenodd') {
	    $cr->set_fill_rule ('even-odd');
	}
	else {
	    carp "Unhandled value '$fill_rule' for 'fill-rule' attribute";
	}
    }
    my $miterlimit = $attr{'stroke-miterlimit'};
    if (defined $miterlimit) {
	$self->save (\$restore);
	$cr->set_miter_limit ($miterlimit);
    }
    my $clip_path = $attr{'clip-path'};
    if (defined $clip_path) {
	$self->do_clip_path ($clip_path);
    }
    my $stroke_dashoffset = $attr{'stroke-dashoffset'};
    my $stroke_dasharray = $attr{'stroke-dasharray'};
    if ($stroke_dasharray) {
	$self->save (\$restore);
	my @sd;
	while ($stroke_dasharray =~ /($fpnum)/g) {
	    push @sd, $1;
	}
	if (! defined $stroke_dashoffset) {
	    $stroke_dashoffset = 0;
	}
	$cr->set_dash ($stroke_dashoffset, @sd);
    }
    return $restore;
}

# The reason this is as complicated as it is is because SVG accepts
# not only commas and/or spaces as separators, but also things like
# -30-40 as two numbers in transform arguments. Did this
# "optimization" by SVG designers really do anything useful?

my $sep = qr!(?:\s+|\s*,\s*)!;
my $num = qr![-0-9\.]+!;
my $sepnum = qr!(?:$sep$num|$sep?-$num)!;

sub sepnum
{
    my ($sepnum) = @_;
    $sepnum =~ s!^$sep!!;
    return $sepnum;
}

sub do_transforms
{
    my ($self, %attr) = @_;
    my $cr = $self->{cr};
    # Transformers - robots in disguise
    my $transform = $attr{transform};
    while ($transform =~ /((?:translate|scale|rotate|matrix|skewX|skewY)\s*\([^\)]*\))/g) {
	my $change = $1;
	if ($change =~ /translate\s*\(\s*($num)($sepnum)\s*\)/) {
	    my $x = $1;
	    my $y = sepnum ($2);
	    $self->msg ("translate ($x, $y)");
	    $cr->translate ($x, $y);
	    next;
	}
	if ($change =~ /scale\s*\(\s*($num)(?:$sep($num))?\s*\)/) {
	    my $x = $1;
	    my $y = $2;
	    if (defined $y) {
		$y = sepnum ($y);
	    }
	    else {
		# scale may take one argument
		$y = $x;
	    }
	    $self->msg ("scale ($x, $y)");
	    $cr->scale ($x, $y);
	    next;
	}
	if ($change =~ /
	    rotate\s*\(
	    \s*($num)\s*
	    (?:($sepnum)($sepnum))?
	    \s*\)
	/x) {
	    my $angle = $1;
	    my $x = $2;
	    my $y = $3;
	    my $trans;
	    if (defined $x && defined $y) {
		$x = sepnum ($x);
		$y = sepnum ($y);
		$trans = 1;
	    }
	    if ($trans) {
		$cr->translate ($x, $y)
	    }
	    $cr->rotate (deg2rad ($angle));
	    if ($trans) {
		$cr->translate (-$x, -$y)
	    }
	    if ($trans) {
		$self->msg ("rotate $angle around $x $y");
	    }
	    else {
		$self->msg ("rotate $angle !");
	    }
	    next;
	}
	if ($change =~ m!
	    skew([XY])\s*
	    \(\s*
	    ($num)
	    \s*\)
	!x) {
	    my $xy = $1;
	    my $angle = deg2rad ($2);
	    my $t = tan ($angle);
	    my @nums;
	    if ($xy eq 'X') {
		@nums = (1, 0, $t, 1, 0, 0);
	    }
	    elsif ($xy eq 'Y') {
		@nums = (1, $t, 0, 1, 0, 0);
	    }	
	    else {
		die "$xy should be either X or Y";
	    }
	    multiply ($cr, \@nums);
	    next;
	}
	if ($change =~ m!
	    matrix\s*
	    \(\s*
	    ($num)
	    ($sepnum)
	    ($sepnum)
	    ($sepnum)
	    ($sepnum)
	    ($sepnum)
	    \s*\)
	!x) {
	    my @nums = ($1, $2, $3, $4, $5, $6);
	    @nums = map {sepnum ($_)} @nums;
	    multiply ($cr, \@nums);
	    next;
	}
    }
    # $transform = trim ($transform);
    # if ($transform) {
    # 	warn "Unhandled '$transform'";
    # }
}

sub multiply
{
    my ($cr, $nums) = @_;
    my $matrix = $cr->get_matrix ();
    my $m = Cairo::Matrix->init (@$nums);
    $matrix = $m->multiply ($matrix);
    $cr->set_matrix ($matrix);
}

sub do_fill_stroke
{
    my ($self, $attr) = @_;
    my $cr = $self->{cr};
    my $fill = $attr->{fill};
    my $stroke = $attr->{stroke};
    # To save doing lots of checks here, the set_colour method is
    # designed so that these opacity values can be undefined if they
    # are not present in $attr.
    my $fill_opacity = $attr->{'fill-opacity'};
    my $stroke_opacity = $attr->{'stroke-opacity'};
    my $opacity = $attr->{opacity};
    # I haven't checked whether this is the correct priority.
    if (defined $opacity && ! defined $fill_opacity) {
	$fill_opacity = $opacity;
    }
    if (defined $opacity && ! defined $stroke_opacity) {
	$stroke_opacity = $opacity;
    }

    if ($fill && $fill ne 'none') {
	if ($stroke && $stroke ne 'none') {
	    # I haven't checked whether it should be fill before
	    # stroke, but the results of doing it this way look right,
	    # so presumably this is what the standard says to do.
	    $self->set_colour ($fill, $fill_opacity);
	    $cr->fill_preserve ();
	    $self->msg ("Filling with $fill");
	    $self->set_colour ($stroke, $stroke_opacity);
	    $cr->stroke ();
	    $self->msg ("Stroking after fill with $stroke");
	}
	else {
	    $self->set_colour ($fill, $fill_opacity);
	    $self->msg ("Filling with $fill");
	    $cr->fill ();
	}
    }
    elsif ($stroke && $stroke ne 'none') {
	$self->set_colour ($stroke, $stroke_opacity);
	$self->msg ("Stroking only with $stroke");
	$cr->stroke ();
    }
    elsif (! $fill && ! $stroke) {
	$self->msg ("Filling with black");
	# Filling with black is the default action.
	$self->set_colour ('#000000', $fill_opacity);
	$cr->fill ();
    }
}

# Graphics::ColorNames::WWW for some reason returns these as integers
# with the R, G, and B components multiplied by factors of 256, so to
# use that module we would need to then divide the numbers to get the
# R, G and B values back. It was easier just to copy and paste.

my %color2rgb = (
    'aliceblue'         => [240, 248, 255],
    'antiquewhite'      => [250, 235, 215],
    'aqua'              => [ 0, 255, 255],
    'aquamarine'        => [127, 255, 212],
    'azure'             => [240, 255, 255],
    'beige'             => [245, 245, 220],
    'bisque'            => [255, 228, 196],
    'black'             => [ 0, 0, 0],
    'blanchedalmond'    => [255, 235, 205],
    'blue'              => [ 0, 0, 255],
    'blueviolet'        => [138, 43, 226],
    'brown'             => [165, 42, 42],
    'burlywood'         => [222, 184, 135],
    'cadetblue'         => [ 95, 158, 160],
    'chartreuse'        => [127, 255, 0],
    'chocolate'         => [210, 105, 30],
    'coral'             => [255, 127, 80],
    'cornflowerblue'    => [100, 149, 237],
    'cornsilk'          => [255, 248, 220],
    'crimson'           => [220, 20, 60],
    'cyan'              => [ 0, 255, 255],
    'darkblue'          => [ 0, 0, 139],
    'darkcyan'          => [ 0, 139, 139],
    'darkgoldenrod'     => [184, 134, 11],
    'darkgray'          => [169, 169, 169],
    'darkgreen'         => [ 0, 100, 0],
    'darkgrey'          => [169, 169, 169],
    'darkkhaki'         => [189, 183, 107],
    'darkmagenta'       => [139, 0, 139],
    'darkolivegreen'    => [ 85, 107, 47],
    'darkorange'        => [255, 140, 0],
    'darkorchid'        => [153, 50, 204],
    'darkred'           => [139, 0, 0],
    'darksalmon'        => [233, 150, 122],
    'darkseagreen'      => [143, 188, 143],
    'darkslateblue'     => [ 72, 61, 139],
    'darkslategray'     => [ 47, 79, 79],
    'darkslategrey'     => [ 47, 79, 79],
    'darkturquoise'     => [ 0, 206, 209],
    'darkviolet'        => [148, 0, 211],
    'deeppink'          => [255, 20, 147],
    'deepskyblue'       => [ 0, 191, 255],
    'dimgray'           => [105, 105, 105],
    'dimgrey'           => [105, 105, 105],
    'dodgerblue'        => [ 30, 144, 255],
    'firebrick'         => [178, 34, 34],
    'floralwhite'       => [255, 250, 240],
    'forestgreen'       => [ 34, 139, 34],
    'fuchsia'           => [0xff, 0, 0xff],
    'gainsboro'         => [220, 220, 220],
    'ghostwhite'        => [248, 248, 255],
    'gold'              => [255, 215, 0],
    'goldenrod'         => [218, 165, 32],
    'gray'              => [128, 128, 128],
    'grey'              => [128, 128, 128],
    'green'             => [ 0, 128, 0],
    'greenyellow'       => [173, 255, 47],
    'honeydew'          => [240, 255, 240],
    'hotpink'           => [255, 105, 180],
    'indianred'         => [205, 92, 92],
    'indigo'            => [ 75, 0, 130],
    'ivory'             => [255, 255, 240],
    'khaki'             => [240, 230, 140],
    'lavender'          => [230, 230, 250],
    'lavenderblush'     => [255, 240, 245],
    'lawngreen'         => [124, 252, 0],
    'lemonchiffon'      => [255, 250, 205],
    'lightblue'         => [173, 216, 230],
    'lightcoral'        => [240, 128, 128],
    'lightcyan'         => [224, 255, 255],
    'lightgoldenrodyellow' => [250, 250, 210],
    'lightgray'         => [211, 211, 211],
    'lightgreen'        => [144, 238, 144],
    'lightgrey'         => [211, 211, 211],
    'lightpink'         => [255, 182, 193],
    'lightsalmon'       => [255, 160, 122],
    'lightseagreen'     => [ 32, 178, 170],
    'lightskyblue'      => [135, 206, 250],
    'lightslategray'    => [119, 136, 153],
    'lightslategrey'    => [119, 136, 153],
    'lightsteelblue'    => [176, 196, 222],
    'lightyellow'       => [255, 255, 224],
    'lime'              => [ 0, 255, 0],
    'limegreen'         => [ 50, 205, 50],
    'linen'             => [250, 240, 230],
    'magenta'           => [255, 0, 255],
    'maroon'            => [128, 0, 0],
    'mediumaquamarine'  => [102, 205, 170],
    'mediumblue'        => [ 0, 0, 205],
    'mediumorchid'      => [186, 85, 211],
    'mediumpurple'      => [147, 112, 219],
    'mediumseagreen'    => [ 60, 179, 113],
    'mediumslateblue'   => [123, 104, 238],
    'mediumspringgreen' => [ 0, 250, 154],
    'mediumturquoise'   => [ 72, 209, 204],
    'mediumvioletred'   => [199, 21, 133],
    'midnightblue'      => [ 25, 25, 112],
    'mintcream'         => [245, 255, 250],
    'mistyrose'         => [255, 228, 225],
    'moccasin'          => [255, 228, 181],
    'navajowhite'       => [255, 222, 173],
    'navy'              => [ 0, 0, 128],
    'oldlace'           => [253, 245, 230],
    'olive'             => [128, 128, 0],
    'olivedrab'         => [107, 142, 35],
    'orange'            => [255, 165, 0],
    'orangered'         => [255, 69, 0],
    'orchid'            => [218, 112, 214],
    'palegoldenrod'     => [238, 232, 170],
    'palegreen'         => [152, 251, 152],
    'paleturquoise'     => [175, 238, 238],
    'palevioletred'     => [219, 112, 147],
    'papayawhip'        => [255, 239, 213],
    'peachpuff'         => [255, 218, 185],
    'peru'              => [205, 133, 63],
    'pink'              => [255, 192, 203],
    'plum'              => [221, 160, 221],
    'powderblue'        => [176, 224, 230],
    'purple'            => [128, 0, 128],
    'red'               => [255, 0, 0],
    'rosybrown'         => [188, 143, 143],
    'royalblue'         => [ 65, 105, 225],
    'saddlebrown'       => [139, 69, 19],
    'salmon'            => [250, 128, 114],
    'sandybrown'        => [244, 164, 96],
    'seagreen'          => [ 46, 139, 87],
    'seashell'          => [255, 245, 238],
    'sienna'            => [160, 82, 45],
    'silver'            => [192, 192, 192],
    'skyblue'           => [135, 206, 235],
    'slateblue'         => [106, 90, 205],
    'slategray'         => [112, 128, 144],
    'slategrey'         => [112, 128, 144],
    'snow'              => [255, 250, 250],
    'springgreen'       => [ 0, 255, 127],
    'steelblue'         => [ 70, 130, 180],
    'tan'               => [210, 180, 140],
    'teal'              => [ 0, 128, 128],
    'thistle'           => [216, 191, 216],
    'tomato'            => [255, 99, 71],
    'turquoise'         => [ 64, 224, 208],
    'violet'            => [238, 130, 238],
    'wheat'             => [245, 222, 179],
    'white'             => [255, 255, 255],
    'whitesmoke'        => [245, 245, 245],
    'yellow'            => [255, 255, 0],
    'yellowgreen'       => [154, 205, 50],
);

sub name2colour
{
    my ($colour) = @_;
    my $c = $color2rgb{lc $colour};
    if (! $c) {
	warn "Unknown colour $colour";
	return @defaultrgb;
    }
    return map {$_/255} @$c;
}

# Hex digit
my $h = qr/[0-9a-f]/i;
my $hh = qr/$h$h/;
# One argument of an rgb() command.
my $rgb = qr/[0-9\.]+%?/;
my $com = qr/\s*,\s*/;

sub rgb
{
    my ($val) = @_;
    if ($val =~ s/%$//) {
	return $val / 100;
    }
    return $val / 255;
}

sub string_to_rgb
{
    my ($colour) = @_;
    if (! defined $colour) {
	confess "No color";
    }
    my @c = @defaultrgb;
    if ($colour eq 'black') {
	@c = (0, 0, 0);
    }
    elsif ($colour eq 'white') {
	@c = (1, 1, 1);
    }
    elsif ($colour =~ /^#($h)($h)($h)$/) {
	@c = (hex ($1)/15, hex ($2)/15, hex ($3)/15);
    }
    elsif ($colour =~ /^#($hh)($hh)($hh)$/) {
	@c = (hex ($1)/255, hex ($2)/255, hex ($3)/255);
    }
    elsif ($colour =~ /^rgb\s*\(($rgb)$com($rgb)$com($rgb)\)\s*$/) {
	@c = (rgb ($1), rgb ($2), rgb ($3));
    }
    else {
	@c = name2colour ($colour);
    }
    return @c;
}


sub set_colour
{
    my ($self, $colour, $opacity) = @_;
    my $cr = $self->{cr};
    if ($colour =~ /^url\(#(.*?)\)/) {
	my $gid = $1;
	$self->use_gradient ($gid);
	return;
    }
    my @c = string_to_rgb ($colour);
    if (defined $opacity) {
	$self->msg ("Setting opacity to $opacity");
	if ($opacity > 1 || $opacity < 0) {
	    carp "Opacity value $opacity out of bounds";
	    $opacity = 1;
	}
	$cr->set_source_rgba (@c, $opacity);
    }
    else {
	$cr->set_source_rgb (@c);
    }
}

# https://developer.mozilla.org/en-US/docs/Web/SVG/Element/linearGradient

my %linearDefaults = (
    x1 => '0%',
    y1 => '0%',
    x2 => '100%',
    y2 => '0%',
);

# https://developer.mozilla.org/en-US/docs/Web/SVG/Element/radialGradient

my %radialDefaults = (
    cx => '50%',
    cy => '50%',
    fr => '0%',
    r => '50%',
    # These should be set to the values of cx and cy if they are not
    # defined separately.
    fx => 'error',
    fy => 'error',
);

# These are the arguments in the order which Cairo requires.

my @rgargs = qw!fx fy fr cx cy r!;

sub use_gradient
{
    my ($self, $gid) = @_;
    my $element = $self->get_id ($gid);
    if (! $element) {
	carp "Could not find element with ID $gid";
	return;
    }
    my $cr = $self->{cr};
    my $tag = $element->{tag};
    my $attr = $element->{attr};
    my $children = $element->{child};
    my $pat;
    my $noscale;
    my $gradientUnits = $attr->{gradientUnits};
    if (defined $gradientUnits && $gradientUnits eq 'userSpaceOnUse') {
	$noscale = 1;
    }
    my ($x1, $y1, $x2, $y2) = $cr->fill_extents ();
    if ($tag eq 'linearGradient') {
	my @args;
	my $i = 0;
	for (qw!x1 y1 x2 y2!) {
	    if ($attr->{$_}) {
		$args[$i] = $attr->{$_};
	    }
	    else {
		$args[$i] = $linearDefaults{$_};
	    }
	    $i++;
	}
	for (@args) {
	    if ($_ =~ s/\%$//) {
		$_ /= 100;
	    }
	}
	if (! $noscale) {
	    my $xdiff = $x2 - $x1;
	    my $ydiff = $y2 - $y1;
	    $args[0] = adjust ($args[0], $x1, $xdiff);
	    $args[1] = adjust ($args[1], $y1, $ydiff);
	    $args[2] = adjust ($args[2], $x1, $xdiff);
	    $args[3] = adjust ($args[3], $y1, $ydiff);
	}
	$self->msg ("Linear gradient arguments: @args");
	$pat = Cairo::LinearGradient->create (@args);
	read_stops ($children, $pat);
	$cr->set_source ($pat);
	return;
    }
    elsif ($tag eq 'radialGradient') {
	my %args;
	for (@rgargs) {
	    if ($attr->{$_}) {
		$args{$_} = $attr->{$_};
	    }
	    else {
		$args{$_} = $radialDefaults{$_};
	    }
	}
	if (! defined $attr->{fx}) {
	    $args{fx} = $args{cx};
	}
	if (! defined $attr->{fy}) {
	    $args{fy} = $args{cy};
	}
	for (@rgargs) {
	    if ($args{$_} =~ s/\%$//) {
		$args{$_} /= 100;
	    }
	}
	if (! $noscale) {
	    my $xdiff = $x2 - $x1;
	    my $ydiff = $y2 - $y1;
	    my $rdiff = $xdiff;
	    if ($xdiff != $ydiff) {
		$rdiff = sqrt (($xdiff ** 2 + $ydiff ** 2)/2);
	    }
	$self->msg ("Radial gradient arguments: @args{@rgargs}\n");
	    $args{fx} = adjust ($args{fx}, $x1, $xdiff);
	    $args{fy} = adjust ($args{fy}, $y1, $ydiff);
	    $args{fr} = adjust ($args{fr},   0, $rdiff);
	    $args{cx} = adjust ($args{cx}, $x1, $xdiff);
	    $args{cy} = adjust ($args{cy}, $y1, $ydiff);
	    $args{r}  = adjust ($args{r},    0, $rdiff);
	}
	$self->msg ("Radial gradient arguments: @args{@rgargs}\n");
	$pat = Cairo::RadialGradient->create (@args{@rgargs});
	read_stops ($children, $pat);
	$cr->set_source ($pat);
	return;
    }
    else {
	carp "Don't know what to do with tag '$tag'";
	return;
    }
}

sub read_stops
{
    my ($children, $pat) = @_;
    for my $child (@$children) {
	my $cattr = $child->{attr};
	my $offset = $cattr->{offset};
	if (! defined $offset) {
	    $offset = 0;
	}
	if ($offset =~ s/\%$//) {
	    $offset /= 100;
	}
	my $stop_colour = $cattr->{'stop-color'};
	my @rgb = @defaultrgb;
	if (defined $stop_colour) {
	    @rgb = string_to_rgb ($stop_colour);
	}
	my $stop_opacity = $cattr->{'stop-opacity'};
	if (defined $stop_opacity) {
	    $pat->add_color_stop_rgba ($offset, @rgb, $stop_opacity);
	}
	else {
	    $pat->add_color_stop_rgb ($offset, @rgb);
	}
    }
}

sub adjust
{
    my ($value, $start, $diff) = @_;
    $value = $start + $value * $diff;
    return $value;
}


sub surface
{
    my ($self) = @_;
    return $self->{surface};
}

# Direction of vector from ($cx, $cy) to ($px, $py) in radians

sub point_angle
{
    my ($cx, $cy, $px, $py) = @_;
    return atan2 ($py - $cy, $px - $cx);
}

# Rotate $x and $y anticlockwise by $angle in radians

sub rotate
{
    my ($x, $y, $angle) = @_;
    my $s = sin $angle;
    my $c = cos $angle;
    return ($x * $c - $y * $s, $x * $s + $y * $c);
}

sub msg
{
    my ($self, $msg) = @_;
    if (! $self->{verbose}) {
	return;
    }
    print "  " x $self->{depth};
    print "$msg\n";
}

sub debugmsg
{
    my (undef, $file, $line) = caller (0);
    printf ("%s:%d: ", $file, $line);
    print "@_\n";
}

sub trim
{
    my ($s) = @_;
    $s =~ s!^\s+|\s+$!!g;
    return $s;
}

1;

