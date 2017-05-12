package Image::BoxModel::Backend::GD;

use strict;
use warnings;
use Carp;

sub DrawLine{ 	# draws a filled, polygon, really..
				# For completeness there should be a method to draw lines with a border. I don't implement it at the moment.
	my $image = shift;
		my %p = (
		@_
	);
	
	foreach ('x1', 'x2', 'y1', 'y2'){
		confess __PACKAGE__, ": Mandatory parameter $_ missing" unless (exists $p{$_} and defined $p{$_});
	}
	
	if ($p{thickness} and $p{thickness}>1){
		# find out how by how many degrees the line is rotated relatively to a vertical line:
		use Math::Trig;
		# atan2: angle of line between vertical line (top to bottom) and line (x-compnent of line, y-component of line)
		my $angle =  rad2deg(atan2($p{x2}-$p{x1}, $p{y2}-$p{y1}));
		
		# now think of our line as a rotated rectangle. this makes it very easy to draw lines of a certain thickness. :-)
		# think of a rectangle where half of the thickness goes to one side of the line and the other half to the other side..
		
		my ($x1_1, $y1_1) = $image -> rotation ($p{x1}+ $p{thickness}/2, $p{y1}, $p{x1}, $p{y1}, -$angle);
		my ($x1_2, $y1_2) = $image -> rotation ($p{x1}- $p{thickness}/2, $p{y1}, $p{x1}, $p{y1}, -$angle);
		
		my ($x2_1, $y2_1) = $image -> rotation ($p{x2}+ $p{thickness}/2, $p{y2}, $p{x2}, $p{y2}, -$angle);
		my ($x2_2, $y2_2) = $image -> rotation ($p{x2}- $p{thickness}/2, $p{y2}, $p{x2}, $p{y2}, -$angle); 
		
		my $poly = new GD::Polygon;
		$poly	-> addPt($x1_1, $y1_1);
		$poly	-> addPt($x1_2, $y1_2);
		
		$poly	-> addPt($x2_2, $y2_2);
		$poly	-> addPt($x2_1, $y2_1);
		
		print $image->{GD} -> filledPolygon($poly,$image->Colors(color => $p{color}));
	}
	else { # thickness <=1: simply draw a line..
		print $image->{GD} -> line($p{x1}, $p{y1}, $p{x2}, $p{y2},$image->Colors(color => $p{color}));
	}
	
	$image -> print_message ("DrawLine with ",__PACKAGE__,"::DrawLine\n");
}

sub DrawRectangle{ # used for horizontal & vertical lines, too
	my $image = shift;
	my %p = (
		border_thickness => 1,
		@_
	);
	
	foreach ('left', 'right', 'bottom', 'top'){
		confess __PACKAGE__, ": Mandatory parameter $_ missing" unless (exists $p{$_} and defined $p{$_});
	}
	
	($p{left}, $p{right}) = ($p{right}, $p{left}) if ($p{right} < $p{left});	#right border *must* be right, left must be left. Otherwise, GD won't draw.
	($p{top}, $p{bottom}) = ($p{bottom}, $p{top}) if ($p{bottom}< $p{top}); 	#same for bottom & top.
	
	if (exists $p{color}){	#this is the first invocation: a simple rectangle without border..
		print $image->{GD} -> filledRectangle($p{left},$p{top},$p{right},$p{bottom},$image->Colors(color => $p{color}));	#Colors checks if color is present or adds it or rants
	}
	elsif (exists $p{fill_color} and exists $p{border_color}){	#and here the 2nd: rectangle with border..
		print $image->{GD} -> filledRectangle($p{left},$p{top},$p{right},$p{bottom},$image->Colors(color => $p{border_color}));
		print $image->{GD} -> filledRectangle(	#the line above draws simply a filled rectangle in border-color
			$p{left}	+ $p{border_thickness},	#then a second rectangle set inside [border_thickness] pixels is drawn onto it.
			$p{top}  	+ $p{border_thickness},
			$p{right}	- $p{border_thickness},
			$p{bottom}	- $p{border_thickness},
			$image		->Colors(color => $p{fill_color})
		) unless ($p{border_thickness} >= ($p{right}-$p{left}) or $p{border_thickness} >= ($p{bottom}-$p{top}));
	}
	else{
		die __PACKAGE__,": Either specify 'color' or 'fill_color' && 'border_color'. Die.";
	}
	
	$image -> print_message ("DrawRectangle with ",__PACKAGE__,"::DrawRectangle\n");
}

sub DrawCircle{ # draws an ellipse, really.
	my $image 	= shift;
	my %p 		= (
		border_thickness => 1,
		@_
	);
	
	($p{left}, $p{right}) = ($p{right}, $p{left}) if ($p{right} < $p{left});	# right border *must* be right, left must be left. Otherwise, GD won't draw.
	($p{top}, $p{bottom}) = ($p{bottom}, $p{top}) if ($p{bottom}< $p{top}); 	# same for bottom & top.
	
	foreach ('left', 'right', 'bottom', 'top'){
		die __PACKAGE__, ": Mandatory parameter $_ missing" unless (exists $p{$_} and defined $p{$_});
	}
	
	my $centerx = ($p{left} + $p{right}) / 2;
	my $centery = ($p{top} + $p{bottom}) / 2;
	
	if (exists $p{color}){	# this is the first invocation: a simple circle without border..
		print $image->{GD} -> filledEllipse ($centerx,$centery,$p{right}-$p{left},$p{bottom}-$p{top},$image->Colors(color => $p{color}));	#Colors checks if color is present or adds it or rants
	}
	elsif (exists $p{fill_color} and exists $p{border_color}){	# and here the 2nd: circle with border..
		print $image->{GD} -> filledEllipse(
			$centerx,
			$centery,
			$p{right}-$p{left},
			$p{bottom}-$p{top},
			$image->Colors(color => $p{border_color})
		);
		print $image->{GD} -> filledEllipse(	
			$centerx,
			$centery,
			$p{right}-$p{left}-$p{border_thickness}*2,
			$p{bottom}-$p{top}-$p{border_thickness}*2,
			$image->Colors(color => $p{fill_color})
		) unless ($p{border_thickness} >= ($p{right}-$p{left}) or $p{border_thickness} >= ($p{bottom}-$p{top}));
	}
	else{
		die __PACKAGE__,": Either specify 'color' or 'fill_color' && 'border_color'. Die.";
	}
	
	$image -> print_message ("DrawCircle with ",__PACKAGE__,"::DrawCircle\n");
	#~ $image->filledEllipse($cx,$cy,$width,$height,$color)
}

sub TextSize{
	my $image 	= shift;
	my %p 		= @_;	# shouln't it fall back to a standard font?
	
	#~ print "GD:TextSize: font: $p{font}";
	
	my (undef, undef, undef, @corner) = gd_text_size($p{font}, $p{textsize}, $p{text});
	
	return @corner;
}

sub DrawText{
	my $image 	= shift;
	my %p 		= (
		@_
	);
	
	$p{font} = './'.$p{font} unless ($p{font} =~ /\//);
	
	$image -> print_message ("DrawText with ",__PACKAGE__,"::DrawText\n");
	my ($capital, $descender, $line_spacing, @corner) = gd_text_size($p{font}, $p{textsize}, $p{text});
	die "$@ $p{font}" if $@;
	my ($width, $height) = $image->GetTextSize (%p);
	
	my $warning =  __PACKAGE__. ": box '$p{box}' is to small for text: \"$p{text}\". Drawing anyway.\n (height: text: $height\tbox: ".$image -> {$p{box}}{height}."\n width: text: $width\tbox:".$image -> {$p{box}}{width}.")\n"
		if (($width > $image -> {$p{box}}{width}) || ($height > $image -> {$p{box}}{height}));
	
	#first, we need to determine the center of the text-box (which is the center of rotation):
	#"Center is default:
	my $x_rotation_center = $p{x_box_center};
	my $y_rotation_center = $p{y_box_center};

	if ($p{position} 	   =~ /North/i){
		$y_rotation_center = $image->{$p{box}}{top} + $height / 2;
	}
	elsif ($p{position}    =~ /South/i){
		$y_rotation_center = $image->{$p{box}}{bottom} - $height / 2;
	}
	if ($p{position}       =~ /West/i){	#This if is on purpose.. It may be ok. to have a combination like NortWest, but not NorthSouth ;-)
		$x_rotation_center = $image->{$p{box}}{left} + $width / 2;
	}
	elsif ($p{position}    =~ /East/i){
		$x_rotation_center = $image->{$p{box}}{right} - $width / 2;
	}

	#draw a small rectangle if desired
	if ($p{background}){
		$image->{GD} -> filledRectangle(
			$x_rotation_center-$width/2,
			$y_rotation_center-$height/2,
			$x_rotation_center+$width/2,
			$y_rotation_center+$height/2,
			$image->Colors(color =>$p{background})
		);
		$image->{GD} -> rectangle(
			$x_rotation_center-$width/2,
			$y_rotation_center-$height/2,
			$x_rotation_center+$width/2,
			$y_rotation_center+$height/2,
			$image->Colors(color =>'black')
		);
	}

	#show rotation centre; debug only
	#~ #$image->{GD} -> rectangle ($x_rotation_center -1, $y_rotation_center -1, $x_rotation_center +1, $y_rotation_center +1, $image->{colors}{black});

	#second, we need to draw each line, aligned as requested.

	my @lines = split (/\n/, $p{text});
	my $e = 1;
	my ($unrotated_width, $unrotated_height) = $image->GetTextSize (%p, rotate => 0);

	foreach my $line (@lines){
		
		my $y = $y_rotation_center - $unrotated_height / 2 + $capital * $e + $line_spacing * ($e-1); #Height of capital Ä * lines + $spacing * (lines-1)
		
		#~ print "FONT: $p{font}\nSIZE: $p{textsize}\nLINE:$line\n";
		
		my @line_bounds = GD::Image ->stringFT(0,$p{font},$p{textsize},0,0,0,$line, {resolution=>"72,72"});
		my $x;
		if ($p{align} 	 =~ /^center$/i){
			$x = $x_rotation_center -  (($line_bounds[2] - $line_bounds[0]) / 2);	
		}
		elsif ($p{align} =~ /^right$/i){
			$x = $x_rotation_center + $unrotated_width / 2 - ($line_bounds[2] - $line_bounds[0]) ;
		}
		else{
			$x = $x_rotation_center - $unrotated_width / 2;
		}
		
		#show text (unrotated), debug only:
		#~ #$image->{GD}->stringFT($image->{colors}{black},$p{font},$p{textsize},0,$x,$y,$line);
		
		($x, $y) = $image->rotation($x, $y, $x_rotation_center, $y_rotation_center, $p{rotate}) unless ($p{rotate} == 0);
		$image->{GD}->stringFT($image->Colors(color =>$p{color}),$p{font},$p{textsize},-$p{rotate}/180*$image->{PI},$x,$y,$line,{resolution=>"72,72"});	

		#show point where GD starts to draw text, debug only
		#~ #$image->{GD} -> rectangle ($x -1, $y -1, $x+1, $y +1, $image->{colors}{black});	
		
		$e ++;
	}
	
	#~ return $warning;
}

sub Colors{		#checks if color is allredy added to the object and adds it if not. dies on malformed or unknown colors.
	my $image 	= shift;
	my %p 		= @_;
	if ($p{color} =~ /^#/){	#this is an html-style color #ff6565 e.g.
		die "invalid color $p{color}" unless ($p{color} =~ /^#[\da-f]{6}?$/i);	#matches an # and then exactly 6 digits or a-f
		my $allready_present = 0;
		foreach (keys %{$image->{preset_colors}}){			#search hash if value found
			if ($image->{preset_colors}{$_} eq $p{color}){
				$allready_present = 1;
				last;
			}
		}
		if ($allready_present == 1){	
			return $image->{colors}{$image->{preset_colors}{$p{color}}}	#simply return color object
		}
		else{
			#~ print "new color: ", $p{color}, " direct from html-style definition\n";	
			my @rgb = $p{color} =~ /#(..)(..)(..)/;	#extract the r / g / b components. 
			$_ = hex($_) foreach (@rgb);	
			
			$image->{colors}{$p{color}} = $image->{GD}->colorAllocate($rgb[0],$rgb[1],$rgb[2]);#add color (name in hash is html-style name)
		}
	}
	else{
		if (exists $image->{preset_colors}{$p{color}}){			#add color (name in hash is html-style name)
			if (exists $image->{colors}{$image->{preset_colors}{$p{color}}}){	#html-form is saved in {preset_colors}{$p{color}}
				#~ print $image->{preset_colors}{$p{color}},"\n";
				return $image->{colors}{$image->{preset_colors}{$p{color}}}	#simply return color object
			}
			else{
				my @rgb = $image->{preset_colors}{$p{color}} =~ /#(..)(..)(..)/;
				$_ = hex($_) foreach (@rgb);
			
				$image->{colors}{$image->{preset_colors}{$p{color}}} = $image->{GD}->colorAllocate($rgb[0],$rgb[1],$rgb[2]);
				return $image->{colors}{$image->{preset_colors}{$p{color}}}
				#~ print "new color: ", $p{color}, " -> ", $image->{preset_colors}{$p{color}},"\n";
			}
		}
		else{
			die "Color $p{color} unknown. Die";
		}
	}
}

sub Save{
	my $image = shift;
	my %p = @_;
	$image -> print_message ("Save with ", __PACKAGE__, "\n");
	open (PNG, ">$p{file}") or die "can't open $p{file}: $!";
	print PNG $image->{GD}->png;
	close PNG;
}

#this sub does some calculations for some routines. As soon as all GD-work is done here, I will see if this sub is still the best way to do it..
sub gd_text_size{
	my ($font, $size, $text) = @_;
	no warnings;
	#~ print "gd_text_size: text: $text font: $font\n";
	
	$font = './'.$font unless ($font =~ /\//);
	
	my @corner;
	
	my @bounds = GD::Image->stringFT(0,$font,$size,0,0,0,"Ä", {resolution=>"72,72"});
	confess "$@ $font" if $@;
	my $capital = $bounds[1]- $bounds[7];

	@bounds = GD::Image->stringFT(0,$font,$size,0,0,0,"Äg", {resolution=>"72,72"});
	my $descender = $bounds[1]- $bounds[7] - $capital;
			
	my $line_spacing = $descender / 2;	#unimplemented: $line_spacing as argument

	($corner[3]{x}, undef, $corner[2]{x}, undef, $corner[1]{x}, undef, $corner[0]{x}, undef) = GD::Image->stringFT(0,$font,$size,0,0,0,$text, {resolution=>"72,72"});	
		#Get bounds of *unrotated* text
		# @bounds[0,1]  Lower left corner (x,y)
		# @bounds[2,3]  Lower right corner (x,y)
		# @bounds[4,5]  Upper right corner (x,y)
		# @bounds[6,7]  Upper left corner (x,y)

	my @lines = split (/\n/, $text);

	#define y-values according to test-string. This is not perfectly equal to the findings of the freetype-engine, but gives satisfiable, reliable results.
	$corner[0]{y} = 0 - $capital;
	$corner[1]{y} = $corner[0]{y};

	$corner[2]{y} = $corner[1]{y} + $capital * scalar(@lines) + $line_spacing * (scalar(@lines)-1) + $descender;	#baseline (=height of capital Ä) * number_of_lines + line_spacing * (number_of_lines-1) + descender
	$corner[3]{y} = $corner[2]{y};
	
	return $capital, $descender, $line_spacing, @corner;
}

1;