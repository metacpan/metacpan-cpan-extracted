package Image::BoxModel::Lowlevel;

use warnings;
use strict;

use POSIX;	#for ceil() in ::Box
use Carp;

=head1 NAME

Image::BoxModel::Lowlevel - Lowlevel functions for Image::BoxModel

=head1 SYNOPSIS

  For an example and general information see Image::BoxModel.pm

=head1 DESCRIPTION

Image::BoxModel::Lowlevel implements some basic functionality. 

It does so by using the methods from Image::BoxModel::Backend::[LIBRARY]

There are more backends planned and more functionality for each backend.
(backends, patches, wishes are very welcome - in this order ;-)

Image::BoxModel::Lowlevel can be used directly, which is considered painful sometimes. 
You need to specify the size of a box before you can put text on it, for example, while 'Annotate' (inherited from ::Text) easily inserts a box and puts text on it.
On the other hand,  ::Lowlevel gives you full control.

=head2 Methods:

=cut

#########################
#Get width & height of a Box
#########################

=head3 GetBoxSize

 ($width, $height) = $image -> GetBoxSize (box => "name_of_your_box");

=cut

sub GetBoxSize{
	my $image = shift;
	my %p = @_;
	
	if ((exists $p{box} && defined $p{box}) && (exists $image->{$p{box}}{width})){
		return $image->{$p{box}}{width}, $image->{$p{box}}{height};
	}
	else{
		return "Box '$p{box}' is not (correctly, at least) defined";
	}
}



#########################
# Add a new box and resize another one (the "free"-box unless resize => box-to-resize is set)
#########################

=head3 Box

If you don't specify 'resize => $name_of_box_to_be_resized', the standard-box 'free' is chosen.

 $image -> Box (
	position 		=>[left|right|top|bottom], 
	width			=> $x, 
	height 			=> $y, 
	name 			=> $name_of_new_box,
	
	# You can either specify a background color, then the box will be filled with that color
	background  	=> [color]		
	
	# or you can define a border color and a background color, then you will get a nice rectangle with border.
	# if you omit border_thickness it defaults to 1
	background 		=> [color],
	border_color	=> [color], 
	border_thickness =>[color]
 );

=cut

sub Box{
	my $image = shift;
	my %p = @_;	#%p holds the _p_arameters
	my $resize = $p{resize} || 'free';
	
	#~ print "Name: $resize, Wert: ", $image->{$resize},"\n";
	croak __PACKAGE__,"::Box: You tried to put a box on '$resize' which does not exists. Die." unless exists $image ->{ $resize};
	
	croak __PACKAGE__,"::Box: Mandatory parameter name missing. Die." unless $p{name};
	return "$p{name} already exists. No box added" if (exists $image->{$p{name}});
	croak __PACKAGE__,"::Box: Mandatory parameter position missing. Die." unless $p{position};
	
	#return if width or height is not specified. 
	#(height wenn adding at top or bottom, width wen adding at left or right side.)
	if ($p{position} eq "top" or $p{position} eq "bottom"){
		
		return "Box: Please specify height > 0. No box added\n" 
			unless (exists $p{height} and $p{height} > 0);
			
		return "Box: Not enough free space on $resize for $p{name}. No box added\n (requested space: $p{height}, available: $image->{$resize}{height})\n" 
			if ($p{height} > $image->{$resize}{height});
	}
	elsif ($p{position} eq "left" or $p{position} eq "right"){
		
		return "Box: Please specify width > 0. No box added\n" 
			unless (exists $p{width} and $p{width} and $p{width} > 0);
			
		return "Box: Not enough free space on $resize for $p{name}. No box added\n (requested space: $p{width}, available: $image->{$resize}{width})\n" 
			if ($p{width} > $image->{$resize}{width});
	}
	
	$image -> print_message ("Add Box \"$p{name}\" with ", __PACKAGE__,"\n");
	
	
	$image->{$p{name}}={	#First we make the new box as big as the field which will be resized..
		top		=> $image->{$resize}{top},
		bottom	=> $image->{$resize}{bottom},
		left	=> $image->{$resize}{left} ,
		right	=> $image->{$resize}{right},
	};	
	
	#.. then we overwrite as needed.
	
	$p{width}  = ceil ($p{width})  if exists $p{width};
	$p{height} = ceil ($p{height}) if exists $p{height};
	
	if ($p{position} eq "top"){
		$image->{$p{name}}{bottom} 	= $image->{$resize}{top} + $p{height};	
		
		#The top margin of the resized field is set to the bottom of the new box.
		$image->{$resize}{top} 		= $image->{$p{name}}{bottom}+1;			
	}																			
	elsif ($p{position} eq "bottom"){
		$image->{$p{name}}{top} 	= $image->{$resize}{bottom} - $p{height};
		$image->{$resize}{bottom} 	= $image->{$p{name}}{top}-1;
	}
	elsif ($p{position} eq "left"){
		$image->{$p{name}}{right} 	= $image->{$resize}{left} + $p{width};
		$image->{$resize}{left} 	= $image->{$p{name}}{right}+1;
	}
	elsif ($p{position} eq "right"){
		$image->{$p{name}}{left} 	= $image->{$resize}{right} - $p{width};
		$image->{$resize}{right} 	= $image->{$p{name}}{left}-1;
	}
	else {
		return "Image::BoxModel::Lowlevel::Box: Position $p{position} unknown. No box added";
		
	}
	
	# if border_color and background are defined, draw a rectangle with border and fill it.
	if (exists $p{border_color} and defined $p{border_color} 
		and
		exists $p{background}   and defined $p{background}
		){
			
			$p{border_thickness} = 1 unless (exists $p{border_thickness} and defined $p{border_thickness} and $p{border_thickness} > 1);
			
			$image -> DrawRectangle(
				left 			=> $image->{$p{name}}{left}, 
				right 			=> $image->{$p{name}}{right}, 
				top 			=> $image->{$p{name}}{top}, 
				bottom 			=> $image->{$p{name}}{bottom}, 
				fill_color 		=> $p{background},
				border_color	=> $p{border_color}, 
				border_thickness => $p{border_thickness}
			);
	}
	# if there is only background, just fill the box with the color
	elsif (exists $p{background} and defined $p{background}){
		$image-> DrawRectangle(
			left 	=> $image->{$p{name}}{left}, 
			right 	=> $image->{$p{name}}{right}, 
			top 	=> $image->{$p{name}}{top}, 
			bottom 	=> $image->{$p{name}}{bottom}, 
			color 	=> $p{background}
		);
	}
	
	$image->{$p{name}}{width} 	= $image->{$p{name}}{right}  - $image->{$p{name}}{left};
	$image->{$p{name}}{height} 	= $image->{$p{name}}{bottom} - $image->{$p{name}}{top};
	
	$image->{$resize}{height} 	= $image->{$resize}{bottom}  - $image->{$resize}{top};	#calculate these values for later use.. laziness
	$image->{$resize}{width} 	= $image->{$resize}{right}   - $image->{$resize}{left};
	
	return;
}

#########################
# Add Floating Box. These boxes can reside anywhere and can overlap. Poor error-checking!
#########################

=head3 FloatBox

To position a free-floating box wherever you want. There is virtually no error-checking, so perhaps better keep your hands off. ;-)

 $image -> FloatBox(
	top 	=> $top, 
	bottom	=> $bottom, 
	right	=> $right, 
	left	=> $top, 
	name	=> "whatever_you_call_it", 
	background =>[color]
 );

=cut

sub FloatBox{
	my $image = shift;
	my %p =@_;
	return "$p{name} already exists. No FloatBox added" if (exists $image->{$p{name}});
	foreach ("top", "bottom", "left", "right"){
		return __PACKAGE__,"::FloatBox: argument $_ missing. No FloatBox added" unless (exists $p{$_});
		$image->{$p{name}}{$_} = $p{$_};
	}
	
	$image -> print_message ("Add FloatBox \"$p{name}\" with ", __PACKAGE__,"\n");
	
	#shift right <-> left if left is more right than right ;-)
	($image->{$p{name}}{right}, $image->{$p{name}}{left})   = ($image->{$p{name}}{left}, $image->{$p{name}}{right}) 
		if ($image->{$p{name}}{left} > $image->{$p{name}}{right});
	#same for bottom and top
	($image->{$p{name}}{top}  , $image->{$p{name}}{bottom}) = ($image->{$p{name}}{bottom}  , $image->{$p{name}}{top}) 
		if ($image->{$p{name}}{bottom} < $image->{$p{name}}{top});
		
	$image->{$p{name}}{$_} = int ($image->{$p{name}}{$_}) foreach ('top', 'left');		#only allow integer values
	$image->{$p{name}}{$_} = ceil ($image->{$p{name}}{$_}) foreach ('right', 'bottom');
	
	my $top 	= $image->{$p{name}}{top};
	my $bottom 	= $image->{$p{name}}{bottom};
	my $left 	= $image->{$p{name}}{left};
	my $right 	= $image->{$p{name}}{right};
	if ((exists $p{background}) && (defined $p{background})){
		$image	-> DrawRectangle(
			left => $left, 
			right => $right, 
			top => $top, 
			bottom => $bottom, 
			color => $p{background}
		);
	}
	
	$image->{$p{name}}{width}  = $image->{$p{name}}{right} - $image->{$p{name}}{left};
	$image->{$p{name}}{height} = $image->{$p{name}}{bottom} - $image->{$p{name}}{top};
	
	return
}

=head3 GetTextSize

Get the boundig size of (rotated) text. Very useful to find out how big boxes need to be.
 ($width, $height) = $image -> GetTextSize(
	text 		=> "Your Text",
	textsize 	=> [number],
	rotate 		=> [in degrees, may be negative as well]
 );

=cut

sub GetTextSize{
	my $image = shift;
	my %p = (
		rotate 	=> 0,
		@_
	);
	
	$p{font} = default_font() unless (exists $p{font} and $p{font} and -f $p{font});
	
	#die if the mandatory parameters are missing
	my $warning;
	foreach ("text", "textsize"){
		$warning .= "Mandatory parameter \"$_\" missing. " unless (exists $p{$_});
	}
	die __PACKAGE__,"::GetTextSize: ".$warning . "dying." if ($warning);
	
	#get x&y of all corners:
	#@corner[0-3]{x|y}
	my @corner = $image->TextSize(text => $p{text}, font => $p{font}, textsize => $p{textsize});
	
	#rotate all 4 corners
	if ($p{rotate}){	
		for (my $i = 0; $i < scalar(@corner); $i++){
			($corner[$i]{x}, $corner[$i]{y}) =  $image -> rotation ($corner[$i]{x}, $corner[$i]{y}, 0, 0, $p{rotate});
		}
	}
	
	my %most =(
		left 	=> 0,
		right 	=> 0,
		top 	=> 0,
		bottom 	=>0
	);
	
	#find the left-, right-, top- and bottommost values.
	foreach (@corner){
		$most{left}  	= $_->{x} if ($_->{x} < $most{left});
		$most{right} 	= $_->{x} if ($_->{x} > $most{right});
		$most{top}   	= $_->{y} if ($_->{y} < $most{top});
		$most{bottom} 	= $_->{y} if ($_->{y} > $most{bottom});
	}
	return (ceil($most{right}- $most{left})), (ceil($most{bottom}-$most{top}));	#return width and height
	#ceil to ensure that the a the text will surely and safely fit.. There were strange errors in ::Backend::GD with values equaling while being inequal at the same time! I don't unterstand this.
}

=head3 BoxSplit

 $image -> BoxSplit (
	box => "name_of_parent", 
	orientation=> "[vertical|horizontal]", 
	number => $number_of_little_boxes),
 );

Splits a box into "number" small boxes. This can be useful if you want to have spreadsheet-style segmentation.

Naming of little boxes: parent_[number, counting from 0]

In bitmap-land we only have integer-size-boxes. Therefore some boxes may be 1 pixel taller than others..

Example:

If the parent is "myBox", then the babies are named myBox_0, myBox_1, ...myBox_2635 (if you are crazy enough to have 2635 babies)

=cut

sub BoxSplit{
	my $image = shift;
	my %p = @_;
	
	my $parent_size;	#because ::Box ignores the not used given dimension, we just set this to with or height of parent and feed it twice..
	my $position;
	if ($p{orientation} eq "vertical"){
		$parent_size 	= $image -> {$p{box}}{height};
		$position 		= "top";
	}
	elsif ($p{orientation} eq "horizontal"){
		$parent_size 	= $image -> {$p{box}}{width};
		$position 		= "left";
	}
	else{
		die __PACKAGE__,": Wrong value of mandatory parameter 'orientation': $p{orientation}, should be [vertical|horizontal]. Die.";
	}
	
	foreach (0.. $p{number}-1){	#baby-box No. 1 holds number 0..
		my $baby_size = sprintf("%.0f", ($parent_size / ($p{number} - $_)));
		#~ print "baby-size: $baby_size\t baby-name: $p{box}_$_\n";
		
		$parent_size   -= $baby_size;

		$image -> Box (
			resize 		=> $p{box}, 
			position 	=> $position, 
			width		=> $baby_size-1, 
			height 		=> $baby_size-1, 
			name		=> "$p{box}_$_",
			background  => $p{background_colors}[$_],
			
			border_color	=> $p{border_color}, 
			border_thickness => $p{border_thickness}
		);
	}
	return;	#nothing at the moment
}

#########################
# Add text to a box
#########################

=head3 Text

For easy use: Better use 'Annotate' (inherited from ::Text) instead of 'Text'. Annotate reserves a box automatically while Text does not. 

But of course, if you need / want full control, use 'Text'.

Put (rotated, antialized) text on a box. Takes a bunch of parameters, of which "text" and "textsize" are mandatory. 

 $image -> Text(
	text 		=> $text,
	textsize 	=> [number],
	color		=> "black",				
	font 		=> [font-file]
	rotate		=> [in degrees, may be negative as well],
	box 		=> "free",
	align 		=> [Left|Center|Right]",		#align is how multiline-text is aligned
	position 	=> [Center				#position is how text will be positioned inside its box
					NorthWest|
					North|
					NorthEast|
					West|
					SoutEast|
					South|
					SouthWest|
					West
				   ],
	background	=> [color]				#rather for debugging
 );

=cut

sub Text{
	my $image = shift;
	my %p = (
		color	=>"black",
		rotate	=>0,
		box		=> "free",
		rotate 	=> 0,
		align 	=> "Center",
		position=> "Center",
		@_
	);
	
	$p{font} = default_font() unless (exists $p{font} and $p{font} and -f $p{font});
	
	my $warning;
	foreach ("text", "textsize"){
		$warning .= "Mandatory parameter \"$_\" missing. " unless (exists $p{$_});
	}
	$warning .= "align = $p{align} is invalid. Valid are Right / Left / Center. " unless ($p{align} =~ /left/i or $p{align} =~ /right/i or $p{align} =~ /center/i);
	
	#if the box does not exist (Box couldn't / didn't want to make it due to missing parameters), we can't add text.
	#(It's better if we don't want to..)
	$warning .= "Box '$p{box}' does not exist. " unless (exists $image->{$p{box}});
	
	return "Text: ".$warning . "No Text added.\n" if ($warning);
	
	#center of box = left + (right-left) /2
	#later we will rotate the text around the center of the box.
	$p{x_box_center} = $image->{$p{box}}{left} + ($image->{$p{box}}{right} - $image->{$p{box}}{left}) / 2;	
	$p{y_box_center} = $image->{$p{box}}{top} + ($image->{$p{box}}{bottom} - $image->{$p{box}}{top}) / 2; 
	
	#DrawText lives in ::Backend::[your_library], because it has to do much library-specific calculations
	
	my $w = $image -> DrawText(%p);
	$warning .= $w if $w;
	
	$image -> print_message ("Add Text to Box \"$p{box}\" with ",__PACKAGE__,"\n");
	return $warning || return;	#to avoid "uninitialized value in calling line when using -w"
}

=head3 Save

 $image -> Save($filename);

Save the image to file. There is no error-checking at the moment. You need to know yourself if your chosen library supports the desired file-type.

=head3 DrawRectangle

Rectangle without border:

 $image -> DrawRectangle (top => $top, bottom => $bottom, right => $right, left => $left, color => "color");

Rectangle with border:

 $image -> DrawRectangle (top => $top, bottom => $bottom, right => $right, left => $left, fill_color => "color", border_color => "color");

Draws a rectangle with the given sides. There are no rotated rectangles at the moment.
 

=cut

#There is no Save, DrawRectangle.. here really, because they're in ::Backend::[library]

=head2 Internal methods:

(documentation for myself rather than the user)

=head3 rotation

To rotate a given point by any point. It takes the angle in degrees, which is very comfortable to me. 
If you want to rotate something, feel free to use it. :-)

 ($x, $y) = $image -> rotation($x, $y, $x_center, $y_center, $angle);

=cut

sub rotation{
	my $image = shift;
	my ($x, $y, $x_center, $y_center, $angle) = @_;
	#~ print "X: $x Y: $y x-center: $x_center y-center: $y_center angle: $angle\n";
	
	return ($x, $y) if ($angle == 0); # if angle == 0 then return immediately. 1st because there's nothing to do, 2nd to prevent from division by 0

	$angle = $image->{PI} / (360 / $angle) * 2;
	
	my $sin = sin ($angle);
	my $cos = cos ($angle);
	
	my $x1=$x;
	my $y1=$y;
	
	$x = ($x1 * $cos) - ($y1 * $sin) - ($x_center * $cos) + ($y_center * $sin) + $x_center;
	$y = ($x1 * $sin) + ($y1 * $cos) - ($x_center * $sin) - ($y_center * $cos) + $y_center;
	
	return $x, $y;
}

=head3 print_message

Checks if verbose is on and then prints messages.
 $image -> print_message("Text");

=cut

sub print_message{
	my $image = shift;
	print @_ if $image->{verbose};
}

sub default_font{
	my $package = __PACKAGE__;		# Gives Image::BoxModel::Lowlevel
	$package =~ s/::/\//g;			# 		Image/BoxModel/Lowlevel
									# Make default font: (path-to-lib)/Image/BoxModel/Backend/FreeSans.ttf
	(my $default_font = $INC{"$package.pm"}) =~ s/Lowlevel\.pm/Backend\/FreeSans.ttf/;
	if (-f $default_font){
		return $default_font;
	}
	else{
		die "Can't find default font. Please file bug report.";
	}
}


1;
__END__

=head2 EXPORT

Nothing. Please use the object oriented interface.



=head1 SEE ALSO

Nowhere at the moment.

=head1 AUTHOR

Matthias Bloch, <lt>matthias at puffin ch<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by :m)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
