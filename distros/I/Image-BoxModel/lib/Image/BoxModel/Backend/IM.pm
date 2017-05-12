package Image::BoxModel::Backend::IM;

use strict;
use warnings;

sub DrawLine{
	my $image = shift;
	my %p = (
		border_thickness => 1,
		@_
	);
	
	foreach ('x1', 'x2', 'y1', 'y2'){
		die __PACKAGE__, ": Mandatory parameter $_ missing" unless (exists $p{$_} and defined $p{$_});
	}
	
	print $image->{IM} -> Draw (
		primitive => 'line', 
		points => "$p{x1},$p{y1},$p{x2},$p{y2}", 
		stroke => $p{color}, 
		strokewidth => $p{thickness}
	); 
}

sub DrawRectangle{
	my $image = shift;
	my %p = (
		border_thickness => 1,
		@_
	);
	
	foreach ('left', 'right', 'bottom', 'top'){
		die __PACKAGE__, ": Mandatory parameter $_ missing" unless (exists $p{$_} and defined $p{$_});
		$p{$_} = sprintf ("%.0f", $p{$_}) unless ($image -> {precise});
	}
	
	($p{left}, $p{right}) = ($p{right}, $p{left}) if ($p{right} < $p{left});	#right border *must* be right, left must be left. Otherwise, the border will not be drawn correctly.
	($p{top}, $p{bottom}) = ($p{bottom}, $p{top}) if ($p{bottom}< $p{top}); 	#same for bottom & top.
	
	
	if (exists $p{color}){	#this is the first invocation: a simple rectangle with no border..
		print $image->{IM} -> Draw (primitive => "rectangle", points => "$p{left},$p{top},$p{right},$p{bottom}", stroke => $p{color}, fill=>$p{color}) ;
	}
	elsif (exists $p{fill_color} and exists $p{border_color}){	#and here the 2nd: rectangle with border..
		print $image->{IM} -> Draw (
			primitive => "rectangle", 
			points => "$p{left},$p{top},$p{right},$p{bottom}", 
			stroke => $p{border_color}, 
			fill=>$p{border_color}
		);
		
		print $image->{IM} -> Draw (
			primitive => "rectangle", 
			points => ($p{left}+$p{border_thickness}).",".($p{top}+$p{border_thickness}).",".($p{right}-$p{border_thickness}).",".($p{bottom}-$p{border_thickness}), 
			stroke => $p{fill_color}, 
			fill=>$p{fill_color}
		) unless ($p{border_thickness} >= ($p{right}-$p{left}) or $p{border_thickness} >= ($p{bottom}-$p{top}));	#we don't draw if there is nothing to draw..
	}
	else{
		die __PACKAGE__,": Either specify 'color' or 'fill_color' && 'border_color'. Die.";
	}
	$image -> print_message ("DrawRectangle with ",__PACKAGE__,"::DrawRectangle\n");
}

sub DrawCircle{
	my $image = shift;
	my %p = (
		border_thickness => 1,
		@_
	);
	
	foreach ('left', 'right', 'bottom', 'top'){
		die __PACKAGE__, ": Mandatory parameter $_ missing" unless (exists $p{$_} and defined $p{$_});
	}
	
	($p{left}, $p{right}) = ($p{right}, $p{left}) if ($p{right} < $p{left});	#right border *must* be right, left must be left. Otherwise, the border will not be drawn correctly.
	($p{top}, $p{bottom}) = ($p{bottom}, $p{top}) if ($p{bottom}< $p{top}); 	#same for bottom & top.
	
	my $centerx = int (($p{left} + $p{right}) / 2);
	my $centery = int (($p{top} + $p{bottom}) / 2);
	my $width   = int (($p{right} - $p{left}) / 2);
	my $height  = int (($p{bottom} - $p{top}) / 2);
	
	if (exists $p{color}){	#this is the first invocation: a simple rectangle with no border..
		print $image->{IM} -> Draw (
			primitive => "ellipse", 
			points => "$centerx,$centery,$width,$height,0,360", 
			stroke => $p{color}, 
			fill=>$p{color}
		);
	}
	elsif (exists $p{fill_color} and exists $p{border_color}){	#and here the 2nd: rectangle with border..
		print $image->{IM} -> Draw (
			primitive => "ellipse", 
			points => "$centerx,$centery,$width,$height,0,360", 
			stroke => $p{border_color}, 
			fill=>$p{fill_color}, 
			strokewidth=> $p{border_thickness}
		);
	}
	else{
		die __PACKAGE__,": Either specify 'color' or 'fill_color' && 'border_color'. Die.";
	}
	$image -> print_message ("DrawCircle with ",__PACKAGE__,"::DrawCircle\n");
}

sub TextSize{
	my $image = shift;
	my %p = @_;
	
	my (undef,undef,undef,undef, $w, $h, undef) = $image->{IM} -> QueryMultilineFontMetrics(text => $p{text}, font => $p{font}, pointsize => $p{textsize});
	
	#~ print "Measuring font $p{font}\n";
	
	my @corner;
	$corner[0]{x} = 0;
	$corner[0]{y} = 0;

	$corner[1]{x} = $w;
	$corner[1]{y} = 0;

	$corner[2]{x} = $w;
	$corner[2]{y} = $h;

	$corner[3]{x} = 0;
	$corner[3]{y} = $h;
	
	return @corner;

}

sub DrawText{
	my $image = shift;
	my %p = (
		font => 'default',
		@_
	);
	
	$image -> print_message ("DrawText with ",__PACKAGE__,"::DrawText\n");
	
	print __PACKAGE__," Warning: Font '$p{font}' not found. Using default (whatever this may be for IM)\n" unless (-f $p{font} or $p{font} eq 'default');
	
	my (undef,undef,undef,$descender, $w, $h, undef) = $image->{IM} -> QueryMultilineFontMetrics(text => $p{text}, font => $p{font}, pointsize => $p{textsize});
	
	my @corner;
	$corner[0]{x} = $p{x_box_center} - $w / 2;	#First, we put the text in the middle of the field
	$corner[0]{y} = $p{y_box_center} - $h / 2;
	
	$corner[1]{x} = $p{x_box_center} + $w / 2;
	$corner[1]{y} = $p{y_box_center} - $h / 2;
	
	$corner[2]{x} = $p{x_box_center} + $w / 2;
	$corner[2]{y} = $p{y_box_center} + $h / 2;
	
	$corner[3]{x} = $p{x_box_center} - $w / 2;
	$corner[3]{y} = $p{y_box_center} + $h / 2;
	
	unless ($p{rotate} == 0){	#rotating all 4 corners
		for (my $i = 0; $i < scalar(@corner); $i++){
			($corner[$i]{x}, $corner[$i]{y}) =  $image->rotation ($corner[$i]{x}, $corner[$i]{y}, $p{x_box_center}, $p{y_box_center}, $p{rotate});
		}
	}
	
	my %most =(
		left 	=> $p{x_box_center},
		right 	=> $p{x_box_center},
		top 	=> $p{y_box_center},
		bottom 	=>$p{y_box_center}
	);
	foreach (@corner){
		$most{left} 	= $_->{x} if ($_->{x} < $most{left});
		$most{right} 	= $_->{x} if ($_->{x} > $most{right});
		$most{top} 		= $_->{y} if ($_->{y} < $most{top});
		$most{bottom} 	= $_->{y} if ($_->{y} > $most{bottom});
	}
	
	my $width  = $most{right}-$most{left};
	my $height = $most{bottom}-$most{top};
	
	my $warning = "box '$p{box}' is to small for text: \"$p{text}\". Drawing anyway.\n (height: text: $height\tbox: ".$image -> {$p{box}}{height}."\n width: text: $width\tbox:".$image -> {$p{box}}{width}."\n" 
		if ((($most{right}-$most{left}) > $image -> {$p{box}}{width}) || (($most{bottom}-$most{top}) > $image -> {$p{box}}{height})) ;

	my $y = $p{y_box_center} - $h/2 + $descender;	#Ensure that descenders (g, q etc) are visible; descender has a negative value, so it's a subtraction really ..
	my $lines = 1;
	$lines ++ while ($p{text} =~ /\n/g);
	$y += $h / $lines; 
	my $x =0;
	
	#This only aligns the text relative to its "mini-box", which is positioned inside its box.
	#There are 2 things that need to be distinguished: text inside its mini-box can be of any rotation (align means a direction relative to the text: center, right, left), while the mini-box itself can be positioned relative to the absolute direction of the whole picture: north, west, south etc.
	if ($p{align} 	=~ /^Center$/){
		$p{align} 	= 'Center';	#this is important because IM ignores this parameter unless the first character is uppercase and the others are lowercase..
		$x 			= $p{x_box_center};
	}
	elsif ($p{align}=~ /^Right$/i){
		$p{align} 	= 'Right';
		$x 			= $p{x_box_center} + $w/2;	#Aligns relative to centered text-box
	}
	elsif ($p{align}=~ /^Left$/i){
		$p{align} 	= 'Left';
		$x 			= $p{x_box_center} - $w/2;
	}
	($x, $y) = $image -> rotation ($x, $y, $p{x_box_center}, $p{y_box_center}, $p{rotate}) unless ($p{rotate} == 0);
	#Now the text-mini-box is shifted to the desired edge(s) of the box. "Center" is the default, so nothing has to be done.
	my $y_shift = 0;
	my $x_shift = 0;
	if ($p{position} 	=~ /North/i){
		$y_shift 		= $image->{$p{box}}{top} - $most{top};	#All points need to be shifted vertically as many points as the topmost point of the (centered) text-box is bigger than the upper line of the box
	}
	elsif ($p{position} =~ /South/i){
		$y_shift 		= $image->{$p{box}}{bottom} - $most{bottom};
	}	
	if ($p{position} 	=~ /West/i){	#This if is on purpose.. It may be ok. to have a combination like NortWest, but not NorthSouth ;-)
		$x_shift 		= $image->{$p{box}}{left} - $most{left};
	}
	elsif ($p{position} =~ /East/i){
		$x_shift 		= $image->{$p{box}}{right} - $most{right};
	}
	if ($y_shift != 0){
		$_->{y} += $y_shift foreach (@corner);
		$p{y_box_center}+= $y_shift;
		$y += $y_shift;
		$most{$_} += $y_shift foreach ("top", "bottom");
	}
	if ($x_shift != 0){
		$_->{x} += $x_shift foreach(@corner);
		$p{x_box_center} += $x_shift;
		$x += $x_shift;
		$most{$_} += $x_shift foreach ("right", "left");
	}
	
	$image->{IM} -> Draw (primitive => 'rectangle', points => "$most{left}, $most{top}, $most{right}, $most{bottom}", fill => $p{background}) if ($p{background});
	$image->{IM} -> Annotate(%p, x=>$x, y=> $y, font => $p{font}, fill => $p{color}, pointsize => $p{textsize});	#the fill&pointsize-parameter is questionable, because they get passed into color&textsize as well (these are ignored by IM)!
	#~ $image->{IM} -> Draw (primitive => 'rectangle', points => ($x-2).",". ($y-2).",". ($x+2).",". ($y+2), fill => "yellow");#uncomment for debugging: little yellow square where IM begins ti draw text.

	return $warning;
}



sub Save{
	my $image 	= shift;
	my %p 		= @_;
	$image 		-> print_message ("Save with ", __PACKAGE__, "\n");
	$image		->{IM} -> Write(filename=> $p{file});
}
1;