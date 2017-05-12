package GD::OrgChart;

our $VERSION = '0.03';

# Copyright 2002, Gary A. Algier.  All rights reserved.  This module is
# free software; you can redistribute it or modify it under the same
# terms as Perl itself.

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# This allows declaration	use GD::OrgChart ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
	all => [ qw( ) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

use GD;

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{image} = undef;
	$self->{params} = {
		boxbgcolor => [255,255,255],
		boxfgcolor => [0,0,0],
		boxtextcolor => [255,0,0],
		boxtop => 4,
		boxbottom => 4,
		boxleft => 4,
		boxright => 4,
		boxborder => 1,
		linespacing => 4,
		size => 12,
		font => gdLargeFont,
		top => 10,
		bottom => 10,
		left => 10,
		right => 10,
		horzspacing => 20,
		vertspacing => 20,
		linewidth => 1,
		linecolor => [0,0,255],
		depth => 0,
		debug => 0,
	};
	if (@_ > 0 && ref($_[0]) eq "HASH") {
		my $p = shift;
		@{$self->{params}}{keys %$p} = values %$p;
	}
	bless($self,$class);
	return $self;
}

sub Image
{
	my $self = shift;

	if (@_) {
		$self->{image} = shift;
	}
	return $self->{image};
}


# BoundTree
#	usage:
#		$chart->BoundTree($node,{ params...})
sub BoundTree
{
	my $self = shift;
	my $node = shift;
	my %params = %{$self->{params}};

	if (@_ == 1 && ref($_[0]) eq "HASH") {
		my $p = shift;
		@params{keys %$p} = values %$p;
	}

# XXX: should we barf on left over arguments?

	return $self->_BoundTree($node,
		$params{depth} > 0 ? $params{depth} : 0,
		0,%params);
}

sub _BoundTree
{
	my $self = shift;
	my $node = shift;
	my $maxdepth = shift;;
	my $curdepth = 1 + shift;;
	my %params = @_;

	if ($node->{params} && ref($node->{params}) eq "HASH") {
		my $p = $node->{params};
		@params{keys %$p} = values %$p;
	}

	my (@box);
	my (@tree,$treeleft,$treeright,$treetop,$treebottom);

	@tree = @box = $self->BoundBox($node,$maxdepth,$curdepth,\%params);
	$node->{BoxBounds} = [ @box ];
	$node->{BoxSize} = sprintf("%dx%d",_height(@box),_width(@box));
	$treetop = _top(@tree);
	$treeleft = _left(@tree);
	$treebottom = _bottom(@tree);
	$treeright = _right(@tree);

	# if no subs or we are deep enough, we are done.
	if (!defined($node->{subs}) || ($maxdepth && $curdepth >= $maxdepth)) {
		$node->{TreeBounds} = [ @tree ];
		$node->{TreeSize} = sprintf("%dx%d",_height(@tree),_width(@tree));
		return @tree;
	}

	my $totalwidth = 0;
	my $highest = 0;
	foreach my $sub (@{$node->{subs}}) {
		my @sub = $self->_BoundTree($sub,$maxdepth,$curdepth,%params);
		$totalwidth += _width(@sub);
		$highest = _max($highest,_height(@sub));
	}
	$totalwidth += $params{horzspacing} * (scalar @{$node->{subs}} - 1);
	$treebottom += $params{vertspacing} * 2 + $highest;
	if (_width(@box) < $totalwidth) {
		my $diff = $totalwidth - _width(@box);
		$treeleft -= _firsthalf($diff);
		$treeright += _secondhalf($diff);
	}

	@tree = ($treeleft,$treebottom,$treeright,$treetop);

	$node->{TreeBounds} = [ @tree ];
	$node->{TreeSize} = sprintf("%dx%d",_height(@tree),_width(@tree));
	return @tree;
}


# DrawTree:
#	usage:
#		$chart->DrawTree($node,{ params ...});
sub DrawTree
{
	my $self = shift;
	my $node = shift;
	my %params = %{$self->{params}};

	my ($x,$y);

	if (@_ == 1 && ref($_[0]) eq "HASH") {
		my $p = shift;
		@params{keys %$p} = values %$p;
	}

# XXX: If there are arguments left we should produce a warning.

	# if this has not been done, do it now:
	if (!defined($node->{TreeBounds})) {
		$self->BoundTree($node,%params);
	}

	if (!defined($self->Image)) {
		my @b = @{$node->{TreeBounds}};
		my $w = _width(@b) + $params{left} + $params{right};
		my $h = _height(@b) + $params{top} + $params{bottom};
		$self->Image(GD::Image->new($w,$h));
		# use the box bg color as the first color allocated
		# so it becomes the image bg color
		$self->{image}->colorAllocate(@{$params{boxbgcolor}});
	}

	if (!defined($params{x}) || !defined($params{y})) {
		my $treewidth = _width(@{$node->{TreeBounds}})
			+ $params{left} + $params{right};
		my $boxheight = _height(@{$node->{BoxBounds}});
		$x = _firsthalf($treewidth);
		$y = _firsthalf($boxheight) + $params{top};
	}

	return $self->_DrawTree($node,$x,$y,
		$params{depth} > 0 ? $params{depth} : 0,
		0,%params);
}

sub _DrawTree
{
	my $self = shift;
	my $node = shift;
	my $x = shift;
	my $y = shift;
	my $maxdepth = shift;
	my $curdepth = 1 + shift;
	my %params = @_;

	if ($node->{params} && ref($node->{params}) eq "HASH") {
		my $p = $node->{params};
		@params{keys %$p} = values %$p;
	}

	my (@box);
	my (@tree,$treeleft,$treeright,$treetop,$treebottom);
	my ($temp,$junction,$subtop,$linecolor);

	# draw our box
	@box = $self->DrawBox($node,$x,$y,$maxdepth,$curdepth,\%params);
	$node->{BoxBounds} = [ @box ];
	$node->{BoxSize} = sprintf("%dx%d",_height(@box),_width(@box));

	@tree = @box;
	$treetop = _top(@tree);
	$treeleft = _left(@tree);
	$treebottom = _bottom(@tree);
	$treeright = _right(@tree);
	$node->{TreeBounds} = [ @tree ];
	$node->{TreeSize} = sprintf("%dx%d",_height(@tree),_width(@tree));

	# if no subs or we are deep enough, we are done.
	if (!defined($node->{subs}) || ($maxdepth && $curdepth >= $maxdepth)) {
		$node->{TreeBounds} = [ @tree ];
		$node->{TreeSize} = sprintf("%dx%d",_height(@tree),_width(@tree));
		return @tree;
	}

	# we have subs, so let us draw some lines
	$linecolor = $self->{image}->colorAllocate(@{$params{linecolor}});

	# this is the line from the bottom of our box to the horizontal line
	$temp = $y + _secondhalf(_height(@box));
	$junction = $temp + $params{vertspacing};
	$subtop = $junction + $params{vertspacing};
	$self->{image}->line($x,$temp,$x,$junction,$linecolor);

	$treebottom = $junction;

	my @widths = map {
			defined($_->{TreeBounds})
				? _width(@{$_->{TreeBounds}})
				: ();
		} @{$node->{subs}};
	my $subx = $x;

	if (@widths > 1) {
		my $totalwidth = 0;
		# there is more than one sub, so we need a horizontal line
		my $left = $widths[0];
		my $right = $widths[@widths-1];
		for my $w (@widths) {
			$totalwidth += $w;
		}
		$totalwidth += $params{horzspacing} * (@widths - 1);

		# the horizontal line is not centered, the tree below the
		# line is centered.
		$subx = $x - _firsthalf($totalwidth) + _firsthalf($left);
		$temp = $x + _secondhalf($totalwidth) - _secondhalf($right);

		$self->{image}->line($subx,$junction,
			$temp,$junction,$linecolor);
		$treeleft = _min($treeleft,$x - _firsthalf($totalwidth));
		$treeright = _max($treeleft,$x + _secondhalf($totalwidth));
	}

	# draw lines down to the sub trees and draw the trees
	for my $sub (@{$node->{subs}}) {
		my $width = shift @widths;
		$self->{image}->line($subx,$junction,
			$subx,$junction+$params{vertspacing},$linecolor);
		$temp = $junction + $params{vertspacing}
			+ _firsthalf(_height(@{$sub->{BoxBounds}}));
		my @sub = $self->_DrawTree($sub,$subx,$temp,
			$maxdepth,$curdepth,%params);
		$treeleft = _min($treeleft,_left(@sub));
		$treeright = _max($treeright,_right(@sub));
		$treebottom = _max($treebottom,_bottom(@sub));
		if (@widths) {
			$subx += _secondhalf($width);
			$subx += $params{horzspacing};
			$subx += _firsthalf($widths[0]);
		}
	}

	@tree = ($treeleft,$treebottom,$treeright,$treetop);
	$node->{TreeBounds} = [ @tree ];
	$node->{TreeSize} = sprintf("%dx%d",_height(@tree),_width(@tree));
	return @tree;
}


sub BoundBox
{
	my $self = shift;

	my $node = shift;
	my $maxdepth = shift;
	my $curdepth = shift;

	my %params = %{$self->{params}};
	if (@_ == 1) {
		my $p = shift;
		@params{keys %$p} = values %$p;
	}

	if ($node->{params} && ref($node->{params}) eq "HASH") {
		my $p = $node->{params};
		@params{keys %$p} = values %$p;
	}

	my ($width,$height);
	$width = $height = 0;

	if ($params{size} != 0 && defined($node->{text})) {
		my @text = split("\n",$node->{text});
		for my $text (@text) {
			my @bounds = _string(undef,0,
				$params{font},$params{size},0,0,$text);
			$width = _max($width,_width(@bounds));
			$height += _height(@bounds);
		}
		$height += (@text - 1) * $params{linespacing};
	}

	$width += $params{boxleft} + $params{boxright}
		+ 2 * $params{boxborder};
	$height += $params{boxtop} + $params{boxbottom}
		+ 2 * $params{boxborder};

	my ($left,$bottom,$right,$top);
	$left = -_firsthalf($width);
	$right = $left + $width;
	$top = -_firsthalf($height);
	$bottom = $top + $height;

	return ($left,$bottom,$right,$top);
}


sub DrawBox
{
	my $self = shift;

	my $node = shift;
	my $x = shift;
	my $y = shift;
	my $maxdepth = shift;
	my $curdepth = shift;

	my %params = %{$self->{params}};
	if (@_ == 1) {
		my $p = shift;
		@params{keys %$p} = values %$p;
	}

	if ($node->{params} && ref($node->{params}) eq "HASH") {
		my $p = $node->{params};
		@params{keys %$p} = values %$p;
	}

	my ($width,$height,@width,@height);
	$width = $height = 0;

	if ($params{size} != 0 && defined($node->{text})) {
		my @text = split("\n",$node->{text});
		for my $text (@text) {
			my @bounds = _string(undef,0,
					$params{font},$params{size},
					0,0,$text);
			push @width,_width(@bounds);
			push @height,_height(@bounds);
			$width = _max($width,_width(@bounds));
			$height += _height(@bounds);
		}
		$height += (@text - 1) * $params{linespacing};
	}

	$width += $params{boxleft} + $params{boxright}
		+ 2 * $params{boxborder};
	$height += $params{boxtop} + $params{boxbottom}
		+ 2 * $params{boxborder};

	my ($left,$bottom,$right,$top);
	$left = $x - _firsthalf($width);
	$right = $left + $width;
	$top = $y - _firsthalf($height);
	$bottom = $top + $height;

	my $bgcolor = $self->{image}->colorAllocate(@{$params{boxbgcolor}});
	my $fgcolor = $self->{image}->colorAllocate(@{$params{boxfgcolor}});
	my $textcolor = $self->{image}->colorAllocate(@{$params{boxtextcolor}});

	# make a "black" rectangle with a "white" fill
	$self->{image}->filledRectangle($left,$top,$right,$bottom,$fgcolor);
	$self->{image}->filledRectangle($left+$params{boxborder},
		$top+$params{boxborder},
		$right-$params{boxborder},
		$bottom-$params{boxborder},
		$bgcolor);

	if ($params{size} != 0 && defined($node->{text})) {
		my $ytemp = $top + $params{boxborder} + $params{boxtop};
		my @text = split("\n",$node->{text});
		for my $text (@text) {
			my $h = shift @height;
# Note:
#	The y coordinate supplied to stringFT must be the bottom
#	of the text, however, the y coordinate supplied to
#	string is the top of the text.  To deal with this
#	we pass (y + height).  This gets adjusted back before
#	string is called (see below in _string).
			_string($self->{image},$textcolor,
					$params{font},$params{size},
					$x - _firsthalf(shift @width),
					$ytemp + $h,$text);
			$ytemp += $h + $params{linespacing};
		}
	}

	return ($left,$bottom,$right,$top);
}


sub _string
{
	my $image = shift;
	my $color = shift;
	my $font = shift;
	my $size = shift;
	my $x = shift;
	my $y = shift;
	my $text = shift;

	my @b;

	if (ref($font)) {
		# must be builtin font
		@b = ($x,$y + $font->height,
			$x + $font->width * length($text),$y);
		if (defined($image)) {
			$image->string($font,$x,$y - $font->height
				,$text,$color);
		}
	}
	else {
		if (defined($image)) {
			@b = $image->stringFT($color,$font,
				$size,0,$x,$y,$text);
		}
		else {
			@b = GD::Image->stringFT($color,$font,
				$size,0,$x,$y,$text);
		}
		@b = _rebound(@b);
	}
	return @b;
}


# The GD package returns bounds as in:
#	(left,bottom,right,bottom,right,top,left,top)
# This is redundant.  I use the Postscript idea of:
#	(left,bottom,right,top)
# aka:
#	(llx,lly,urx,ury)
# This function does the conversion
sub _rebound
{
	if (@_ == 8) {
		 return @_[0,1,4,5];
	}
	else {
		return (0,0,0,0);
	}
}

# in many cases we need two different
# "half" values such that the sum equals the whole.
sub _firsthalf
{
	return int($_[0] / 2);
}

sub _secondhalf
{
	return $_[0] - int($_[0] / 2);
}

sub _top
{
	return $_[3];
}
sub _bottom
{
	return $_[1];
}
sub _left
{
	return $_[0];
}
sub _right
{
	return $_[2];
}
sub _width
{
	return abs($_[0] - $_[2]);
}
sub _height
{
	return abs($_[1] - $_[3]);
}
sub _min
{
	my $min = shift;
	my $x;

	while (@_) {
		$x = shift;
		$min = $x if ($x < $min);
	}
	return $min;
}
sub _max
{
	my $max = shift;
	my $x;

	while (@_) {
		$x = shift;
		$max = $x if ($x > $max);
	}
	return $max;
}

1;
__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

GD::OrgChart - Perl extension for generating personnel organization charts

=head1 SYNOPSIS

  # This bit of code will display a simple orgchart using the
  # Imagemagick "display" command

  use GD::OrgChart;
  use constant FONT => "/some/path/to/truetype/fonts/times.ttf";
  use IO::Pipe;

  our $COMPANY;

  # put data into $COMPANY such that it looks like:
  $COMPANY =
    { text => "Gary\nHome Owner", subs => [
      { text => "Tex\nVice President, Back Yard Security", subs => [
        { text => "Ophelia\nGate Watcher" },
        { text => "Cinnamon\nDeck Sitter" },
      ]},
      { text => "Dudley\nVice President, Front Yard Security", subs => [
        { text => "Jax\nBay Window Watcher" },
        { text => "Maisie\nDoor Watcher" },
      ]},
    ]};

  our $chart = GD::OrgChart->new({ size => 12, font => FONT });
  $chart->DrawTree($COMPANY);

  our $fh = IO::Pipe->new;
  if (!$fh || !($fh->writer("display -"))) {
    # error
    ...
  }
  binmode $fh;	# just in case

  our $image = $chart->Image;
  $fh->print($image->png);
  $fh->close();

=head1 DESCRIPTION

=head1 AUTHOR

Gary A. Algier, E<lt>gaa@magpage.comE<gt>

=head1 SEE ALSO

L<perl>.

=cut
