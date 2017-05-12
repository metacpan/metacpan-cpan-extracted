package GD::3DBarGrapher;

# -----------------------------------------------------------------------------
#
# "3DBarGrapher"
#
# http://www.creationfactor.net/software.htm
#
# Copyright (c) 2009 S.I.Warhurst
#
# See DOCUMENTATION at end of file
#
# -----------------------------------------------------------------------------
# INITIALISATION
# -----------------------------------------------------------------------------

use strict;
use GD;

require Exporter;
@GD::3DBarGrapher::ISA = qw(Exporter);
@GD::3DBarGrapher::EXPORT_OK = qw(creategraph);
$GD::3DBarGrapher::VERSION = '0.9.6';

our $image;

# -----------------------------------------------------------------------------
# MAIN FUNCTION
# -----------------------------------------------------------------------------

sub creategraph {
	
	my($arrayref,$options) = @_;
	
	# --- get default config & update with customisations --- #
	
	my(%conf) = config();
	foreach my $k (keys %{$options}){
		$conf{lc($k)} = $$options{$k};
	}
	
	# --- get data --- #
	
	my(@data) = @$arrayref;
	
	# --- get dimensions of objects --- #
	
	my(%dims) = getdimensions(\@data,\%conf);
	
	# --- create graph --- #
	
	# adjust overall image dimensions if necessary
	$conf{imgw} = $dims{minwidth} if $dims{minwidth} > $conf{imgw};
	$conf{imgh} = $dims{minheight} if $dims{minheight} > $conf{imgh};
	$image = GD::Image->newTrueColor($conf{imgw},$conf{imgh});
	
	# fill image background colour
	my $col = $image->colorAllocate($conf{$conf{ibgcol}}{R},$conf{$conf{ibgcol}}{G},$conf{$conf{ibgcol}}{B});
	$image->fill(10,10,$col);
	
	# draw graph border if necessary
	if($conf{iborder} ne ""){
		my $col = $image->colorAllocate($conf{$conf{iborder}}{R},$conf{$conf{iborder}}{G},$conf{$conf{iborder}}{B});
		$image->rectangle(0,0,$conf{imgw}-1,$conf{imgh}-1,$col);
	}
	
	# draw title
	if($conf{ttext} ne ''){
		my $col = $image->colorAllocate($conf{$conf{tfontcol}}{R},$conf{$conf{tfontcol}}{G},$conf{$conf{tfontcol}}{B});
		if($conf{tfont} eq ''){
			my $x = ($conf{imgw}/2)-($dims{titlew}/2);
			my $y = $conf{ipadding};
			$image->string(gdGiantFont,$x,$y,$conf{ttext},$col);
		}
		else{
			my $x = ($conf{imgw}/2)-($dims{titlew}/2);
			my $y = $conf{ipadding} + $dims{titleh};
			$image->stringFT($col,$conf{tfont},$conf{tsize},0,$x,$y,$conf{ttext});
		}
	}
	
	# draw y label text
	if($conf{yltext} ne ''){
		my $col = $image->colorAllocate($conf{$conf{lfontcol}}{R},$conf{$conf{lfontcol}}{G},$conf{$conf{lfontcol}}{B});
		if($conf{lfont} eq ''){
			my $x = $conf{ipadding};
			my $temp = 0;
			$temp = ($conf{ipadding} + $dims{titleh}) if $dims{titleh} > 0;
			my $y = ((($dims{floor} + $dims{plotheight})/2) + ($dims{ylabelheight}/2)) + $temp + $conf{ipadding};
			$image->stringUp(gdLargeFont,$x,$y,$conf{yltext},$col);
		}
		else{
			my $x = $conf{ipadding} + $dims{ylabelwidth};
			my $temp = 0;
			$temp = ($conf{ipadding} + $dims{titleh}) if $dims{titleh} > 0;
			my $y = ((($dims{floor} + $dims{plotheight})/2) + ($dims{ylabelheight}/2)) + $temp + $conf{ipadding};
			$image->stringFT($col,$conf{lfont},$conf{lsize},90/57.2958,$x,$y,$conf{yltext});
		}
	}
	
	# draw x label text
	if($conf{xltext} ne ''){
		my $col = $image->colorAllocate($conf{$conf{lfontcol}}{R},$conf{$conf{lfontcol}}{G},$conf{$conf{lfontcol}}{B});
		if($conf{lfont} eq ''){
			my $x = $conf{imgw} - ($conf{ipadding} + (($dims{floor} + $dims{plotwidth})/2) + ($dims{xlabelwidth}/2));
			my $y = $conf{imgh} - $conf{ipadding} - $dims{xlabelheight};
			$image->string(gdLargeFont,$x,$y,$conf{xltext},$col);
		}
		else{
			my $x = $conf{imgw} - ($conf{ipadding} + (($dims{floor} + $dims{plotwidth})/2) + ($dims{xlabelwidth}/2));
			my $y = $conf{imgh} - $conf{ipadding};
			$image->stringFT($col,$conf{lfont},$conf{lsize},0,$x,$y,$conf{xltext});
		}
	}
	
	# draw main plot box
	my $col = $image->colorAllocate($conf{$conf{plinecol}}{R},$conf{$conf{plinecol}}{G},$conf{$conf{plinecol}}{B});
	my $ypos = $conf{ipadding};
	$ypos += $conf{ipadding} + $dims{titleh} if $conf{ttext} ne '';
	my $plotleftedge = $conf{imgw}-$conf{ipadding}-$dims{plotwidth};
	$image->rectangle($conf{imgw}-$conf{ipadding},$ypos,$plotleftedge,$ypos+$dims{plotheight},$col);
	
	# draw side & floor
	$image->line($plotleftedge,$ypos,$plotleftedge-$dims{floor},$ypos+$dims{floor},$col);
	$image->line($plotleftedge-$dims{floor},$ypos+$dims{floor},$plotleftedge-$dims{floor},$ypos+$dims{plotheight}+$dims{floor},$col);
	$image->line($plotleftedge-$dims{floor},$ypos+$dims{plotheight}+$dims{floor},$plotleftedge,$ypos+$dims{plotheight},$col);
	$image->line($plotleftedge-$dims{floor},$ypos+$dims{plotheight}+$dims{floor},$conf{imgw}-$conf{ipadding}-$dims{floor},$ypos+$dims{plotheight}+$dims{floor},$col);
	$image->line($conf{imgw}-$conf{ipadding}-$dims{floor},$ypos+$dims{plotheight}+$dims{floor},$conf{imgw}-$conf{ipadding},$ypos+$dims{plotheight},$col);
	
	# fill plot box, side and floor
	my $flr = $image->colorAllocate($conf{$conf{pflcol}}{R},$conf{$conf{pflcol}}{G},$conf{$conf{pflcol}}{B});
	my $bg = $image->colorAllocate($conf{$conf{pbgcol}}{R},$conf{$conf{pbgcol}}{G},$conf{$conf{pbgcol}}{B});
	$image->fill($plotleftedge,$ypos+$dims{plotheight}+2,$flr);
	if($conf{pbgfill} eq "gradient"){
		gradientfill($bg,$plotleftedge+1,$ypos+1,$plotleftedge+$dims{plotwidth}-1,$ypos+1,$dims{plotheight}-1,'',$conf{imgh});
		gradientfill($bg,($plotleftedge-$dims{floor})+1,($ypos+$dims{floor}),$plotleftedge-1,$ypos+2,$dims{plotheight}-1,'',$conf{imgh});
	}
	else{
		$image->fill($conf{imgw}-$conf{ipadding}-2,$ypos+2,$bg);
		$image->fill($plotleftedge-2,$ypos+$dims{floor}+2,$bg);
	}
	
	# draw div lines and y vals
	my ($x1,$x2,$x3) = ($conf{imgw}-$conf{ipadding}-$dims{plotwidth}-$dims{floor},$conf{imgw}-$conf{ipadding}-$dims{plotwidth},$conf{imgw}-$conf{ipadding});
	my ($y1,$y2) = ($ypos+$dims{plotheight}+$dims{floor},$ypos+$dims{plotheight});
	my $divspacing = $dims{plotheight}/$dims{numdivs};
	my $txtcol = $image->colorAllocate($conf{$conf{vfontcol}}{R},$conf{$conf{vfontcol}}{G},$conf{$conf{vfontcol}}{B});
	if($conf{vfont} ne ''){
		my($w,$h) = getstringsize($conf{vfont},"0",$conf{vsize},0);
		$image->stringFT($txtcol,$conf{vfont},$conf{vsize},0,$x1-$conf{iplotpad}-$w,$y1+($h/2),"0");
	}
	else{
		my($w,$h) = getstringsize("gdSmallFont","0");
		$image->string(gdSmallFont,$x1-$conf{iplotpad}-$w,$y1-($h/2),"0",$txtcol);
	}
	for(my $d = 1; $d <= $dims{numdivs}; $d++){
		$image->line($x1,$y1-($d*$divspacing),$x2,$y2-($d*$divspacing),$col);
		$image->line($x2,$y2-($d*$divspacing),$x3,$y2-($d*$divspacing),$col);
		if($conf{vfont} ne ''){
			my($w,$h) = getstringsize($conf{vfont},($dims{range}/$dims{numdivs})*$d,$conf{vsize},0);
			$image->stringFT($txtcol,$conf{vfont},$conf{vsize},0,$x1-$conf{iplotpad}-$w,($y1-($d*$divspacing))+($h/2),($dims{range}/$dims{numdivs})*$d);
		}
		else{
			my($w,$h) = getstringsize("gdSmallFont",($dims{range}/$dims{numdivs})*$d);
			$image->string(gdSmallFont,$x1-$conf{iplotpad}-$w,($y1-($d*$divspacing))-($h/2),($dims{range}/$dims{numdivs})*$d,$txtcol);
		}
	}
	
	# get imagemap html ready
	my($imgtag, $maptag, $areatag) = imagemaphtml();
	my ($imagemap,$shapes);
	$imagemap = $imgtag . $maptag;
	my ($filename) = $conf{file} =~ /([^\/]+)$/;
	$imagemap =~ s/%imagename%/$filename/;
	$imagemap =~ s/%width%/$conf{imgw}/;
	$imagemap =~ s/%height%/$conf{imgh}/;
	$filename =~ s/(\W+|_|\-)//g; # attempt to give map
	$filename .= time;	     # unique name!
	$imagemap =~ s/%mapname%/$filename/g;
	
	# draw columns or bars
	my ($colbar,%shades);
	if($conf{bfacecol} ne "random"){
		$colbar = $image->colorAllocate($conf{$conf{bfacecol}}{R},$conf{$conf{bfacecol}}{G},$conf{$conf{bfacecol}}{B});
		(%shades) = getshades($conf{$conf{bfacecol}}{R},$conf{$conf{bfacecol}}{G},$conf{$conf{bfacecol}}{B},\%conf);
	}
	else {
		my @rgb = ($conf{$conf{pflcol}}{R},$conf{$conf{pflcol}}{G},$conf{$conf{pflcol}}{B});
		my (%colour) = randomcolour();
		$colbar = $image->colorAllocate($colour{R},$colour{G},$colour{B});
		(%shades) = getshades($colour{R},$colour{G},$colour{B},\%conf);
	}
	my $shadetop = $image->colorAllocate($shades{top}{R},$shades{top}{G},$shades{top}{B});
	my $shadeside = $image->colorAllocate($shades{side}{R},$shades{side}{G},$shades{side}{B});
	my $xtxt = $image->colorAllocate($conf{$conf{vfontcol}}{R},$conf{$conf{vfontcol}}{G},$conf{$conf{vfontcol}}{B});
	my $keyn = scalar @data;
	my $spacing = ($dims{plotwidth} - $conf{iplotpad} - $conf{iplotpad} - $dims{floor} - ($keyn * $conf{bwidth})) / ($keyn-1);
	my $barpos = $plotleftedge + $conf{iplotpad};
	my ($bwidby2,$bwidby3,$bwidby4) = (
		int($conf{bwidth}/2),
		int($conf{bwidth}/3),
		int($conf{bwidth}/4)
	);
	my $floordepth = sprintf("%.0f",sqrt(($bwidby2*$bwidby2)/2));
	foreach my $d(@data){
		# draw x axis text
		if($conf{vfont} ne ''){
			my($w,$h,$x) = getstringsize($conf{vfont},$d->[0],$conf{vsize},45);
			$image->stringFT($xtxt,$conf{vfont},$conf{vsize},45/57.2958,($barpos-$w)+$x+$bwidby3,$ypos+$dims{plotheight}+$dims{floor}+$conf{iplotpad}+$h,$d->[0]);
		}
		else{
			my($h,$w) = getstringsize("gdSmallFont",$d->[0]);
			$image->stringUp(gdSmallFont,$barpos+($bwidby2-($w/2)),$ypos+$dims{plotheight}+$dims{floor}+$conf{iplotpad}+$h,$d->[0],$xtxt);
		}
		my $coords;
		# draw columns
		if($conf{bstyle} eq "column"){
			# draw bottom arc
			$image->filledArc($barpos+$bwidby2,$ypos+$dims{plotheight}+$bwidby4,$conf{bwidth},$bwidby2,0,180,$colbar);
			# draw bar
			my $centretopy = $ypos + ($dims{plotheight} - (($dims{plotheight}/$dims{range})*$d->[1])) + $bwidby4;
			$image->filledRectangle($barpos,$centretopy,$barpos+$conf{bwidth}-1,$ypos+$dims{plotheight}+$bwidby4,$colbar);
			if($conf{bcolumnfill} eq "gradient"){
				gradientfill($colbar,$centretopy,$barpos+$conf{bwidth}-1,$ypos+$dims{plotheight}+$bwidby4,$barpos+$conf{bwidth}-1,$conf{bwidth},'column',$conf{imgh});
			}
			# draw top ellipse
			$image->filledEllipse($barpos+$bwidby2,$centretopy,$conf{bwidth},$bwidby2,$shadetop);
			$coords = int($barpos) . "," . int($centretopy-$bwidby4) . "," . int($barpos+$conf{bwidth}) . "," . int($ypos+$dims{plotheight}+$bwidby4);
		}
		# draw bars
		else {
			# draw main bar face
			my $centretopy = $ypos + ($dims{plotheight} - (($dims{plotheight}/$dims{range})*$d->[1])) + $floordepth;
			$image->filledRectangle($barpos,$centretopy,$barpos+$conf{bwidth},$ypos+$dims{plotheight}+$floordepth,$colbar);
			# draw top and side sections
			my $poly = new GD::Polygon;
			$poly->addPt($barpos,$centretopy);
			$poly->addPt($barpos+$floordepth,$centretopy-$floordepth);
			$poly->addPt($barpos+$floordepth+$conf{bwidth},$centretopy-$floordepth);
			$poly->addPt($barpos+$conf{bwidth},$centretopy);
			$image->filledPolygon($poly,$shadetop);
			my $poly = new GD::Polygon;
			$poly->addPt($barpos+$floordepth+$conf{bwidth},$centretopy-$floordepth);
			$poly->addPt($barpos+$floordepth+$conf{bwidth},($ypos+$dims{plotheight}));
			$poly->addPt($barpos+$conf{bwidth},$ypos+$dims{plotheight}+$floordepth);
			$poly->addPt($barpos+$conf{bwidth},$centretopy);
			$image->filledPolygon($poly,$shadeside);
			$coords = int($barpos) . "," . int($centretopy-$floordepth) . "," . int($barpos+$conf{bwidth}+$spacing) . "," . int($ypos+$dims{plotheight}+$floordepth);
		}
		# create imagemap shape
		$shapes .= $areatag;
		$shapes =~ s/%coords%/$coords/;
		$shapes =~ s/%title%/$d->[0]: $d->[1]/;
		# increment xpos for next bar
		$barpos += ($conf{bwidth} + $spacing);
	}
	
	# finish imagemap html
	$imagemap =~ s/%shapes%/$shapes/g;
	
	# --- create image file --- #
	
	my $writedata;
	if($conf{file} =~ /\.gif$/i){
		$writedata = $image->gif();
	}
	elsif($conf{file} =~ /\.png$/i){
		my $q = 10-$conf{quality};
		$writedata = $image->png($q);
	}
	else{
		my $q = $conf{quality}*10;
		$writedata = $image->jpeg($q);
	}
	open IMG,">$conf{file}";
	binmode IMG;
	print IMG $writedata;
	close IMG;
	
	return $imagemap;
	
}

# -----------------------------------------------------------------------------
# SUBROUTINES
# -----------------------------------------------------------------------------

sub config {

	my %conf = (

		# colours

		black		=> { R => 0,   G => 0,   B => 0   },
		white		=> { R => 255, G => 255, B => 255 },
		vltgrey		=> { R => 245, G => 245, B => 245 },
		ltgrey		=> { R => 230, G => 230, B => 230 },
		midgrey		=> { R => 180, G => 180, B => 180 },
		midblue		=> { R => 54,  G => 100, B => 170 },
		
		# file output details
		
		file		=> '',			# file path and name; file extension can be .jpg|gif|png
		quality		=> '9',			# image file quality: 1 (worst) - 10 (best)

		# main image properties

		imgw		=> 400,			# preferred width - maybe more depending on bar properties and number of x-axis values specified
		imgh		=> 320,			# preferred height - maybe more depending on bar properties and number of y-axis values specified
		ipadding	=> 14,			# padding between items, eg: between top of image and title
		iplotpad	=> 8,			# padding between axis vals and plot area
		ibgcol		=> 'white',		# background colour
		iborder		=> '',			# defaults to no border

		# plot area properties

		plinecol	=> 'midgrey',	# line colour
		pflcol		=> 'vltgrey',	# floor colour
		pbgcol		=> 'ltgrey',	# background colour
		pbgfill		=> 'gradient',	# 'gradient' or 'solid' for fill type
		plnspace	=> 25,			# minimum spacing between divisions
		pnumdivs	=> 6,			# maximum number of divisions

		# bar properties
		bstyle		=> 'bar',		# can be 'column' or 'bar'
		bcolumnfill	=> 'gradient',	# 'gradient' or 'solid' for columns
		bminspace	=> 18,			# minimum spacing between bars
		bwidth		=> 18,			# width
		bfacecol	=> 'midblue',	# colour of column/bar face, or 'random' for random colour

		# graph title

		ttext		=> '',			# title text
		tfont		=> '',			# specify path/truetype font otherwise defaults to gdGiantFont
		tsize		=> 11,			# font size
		tfontcol	=> 'black',		# font colour

		# axis labels

		xltext		=> '',			# x label text
		yltext		=> '',			# y label text
		lfont		=> '',			# specify path/truetype font otherwise defaults to gdLargeFont
		lsize		=> 10,			# font size
		lfontcol	=> 'midblue',	# font colour

		# axis values

		vfont		=> '',			# specify path/truetype font otherwise defaults to gdSmallFont
		vsize		=> 8,			# font size
		vfontcol	=> 'black',		# font colour

	);
	
	return %conf;
}

sub imagemaphtml {

	my $imgtag = qq[<img src="%imagename%" width="%width%" height="%height%" border="0" usemap="#%mapname%" />\n];
	my $maptag = qq[<map name="%mapname%" id="%mapname%">\n%shapes%</map>];
	my $areatag = qq[<area shape="rect" coords="%coords%" href="#" title="%title%" />\n];
	return ($imgtag, $maptag, $areatag);
}

sub getstringsize {

	my ($font,$string,$size,$angle) = @_;

	if($font =~ /^gd\w+Font$/){
		my %gdfonts = (
			'gdTinyFont'		=> { 'w' => 5, 'h' => 8  },
			'gdSmallFont'		=> { 'w' => 6, 'h' => 12 },
			'gdMediumBoldFont'	=> { 'w' => 7, 'h' => 13 },
			'gdLargeFont'		=> { 'w' => 8, 'h' => 16 },
			'gdGiantFont'		=> { 'w' => 9, 'h' => 15 }
		);
		return ($gdfonts{$font}{w}*length($string),$gdfonts{$font}{h});
	}
	else {
		my ($wid,$hgt,$x);
		my $tst = new GD::Image(1000,1000,1);
		my $tmp = $tst->colorAllocate(0,0,0);
		my $radangle = $angle / 57.2958;
		my @bounds = GD::Image->stringFT($tmp,$font,$size,$radangle,50,950,$string);
		if ($angle == 0) {
			$wid = $bounds[4]-$bounds[6];
			$hgt = $bounds[1]-$bounds[7];
		}
		elsif ($angle == 45) {
			$wid = $bounds[2]-$bounds[6];
			$hgt = $bounds[1]-$bounds[5];
			$x   = $bounds[0]-$bounds[6];
		}
		else {
			$wid = $bounds[0]-$bounds[6];
			$hgt = $bounds[1]-$bounds[3];
		}
		#print "LL=$bounds[0],$bounds[1] LR=$bounds[2],$bounds[3] UR=$bounds[4],$bounds[5] UL=$bounds[6],$bounds[7]" if $string eq "Number sold";
		return ($wid,$hgt,$x);
	}
}

sub getdimensions {
	
	my @data = @{$_[0]};
	my %conf = %{$_[1]};

	my %dims = (
		minwidth	=> 0, # min overall graph width
		minheight	=> 0, # min overall graph height
		titlew		=> 0, # title width
		titleh		=> 0, # title text height
		ylabelwidth	=> 0, # y axis label width
		ylabelheight	=> 0, # y axis label height
		xlabelwidth	=> 0, # x axis label width
		xlabelheight	=> 0, # x axis label height
		xvalheight	=> 0, # largest x axis value height
		xhorheight	=> 0, # largest x axis value height
		yvalwidth	=> 0, # largest y axis value width
		floor		=> 0, # width/height of 3D floor/sides
		plotwidth	=> 0, # overall plot area width
		plotheight	=> 0, # overall plot area height
		numdivs		=> 6, # number of divisions in plot area
		range		=> 6000000  # upper range value
	);

	# --- calculate y axis ranges --- #

	# find highest number
	my $high = 0;
	foreach my $d(@data){
		$high = $d->[1] if $d->[1] > $high;
	}

	# find best number of divs and upper range number
	my @divs = (1,2,5,10,20,50,100,200,500,1000,2000,5000,10000,20000,50000,100000,200000,500000,1000000);
	foreach my $n(6,5,4){
		foreach my $d(@divs){
			if(($n*$d) > $high and (($n*$d)-$high) < ($dims{range}-$high)){
				$dims{numdivs} = $n;
				$dims{range} = $n*$d;
				last;
			}
		}
	}

	# --- calculate heights --- #

	# top padding
	$dims{minheight} += $conf{ipadding};

	# title height
	if($conf{ttext} ne ''){
		if($conf{tfont} eq ''){
			($dims{titlew},$dims{titleh}) = getstringsize("gdGiantFont",$conf{ttext});
		}
		else{
			($dims{titlew},$dims{titleh}) = getstringsize($conf{tfont},$conf{ttext},$conf{tsize},0);
		}
		$dims{minheight} += ($dims{titleh} + $conf{ipadding});	# add title height & padding below to minheight
	}

	# padding between x vals and plot area
	$dims{minheight} += $conf{iplotpad};

	# largest x val height - angled and horizontal
	foreach my $d(@data){
		if($conf{vfont} eq ''){
			my($h,$w) = getstringsize("gdSmallFont",$d->[0]);
			$dims{xvalheight} = $h if $h > $dims{xvalheight};
			my($w2,$h2) = getstringsize("gdSmallFont",$d->[0]);
			$dims{xhorheight} = $h2 if $h2 > $dims{xhorheight};
		}
		else{
			my($w,$h) = getstringsize($conf{vfont},$d->[0],$conf{vsize},45);
			$dims{xvalheight} = $h if $h > $dims{xvalheight};
			my($w2,$h2) = getstringsize($conf{vfont},$d->[0],$conf{vsize},0);
			$dims{xhorheight} = $h2 if $h2 > $dims{xhorheight};
		}
	}
	$dims{minheight} += $dims{xvalheight};

	# bottom padding
	$dims{minheight} += $conf{ipadding};

	# x axis label height & extra padding
	if($conf{xltext} ne ''){
		if($conf{lfont} eq ''){
			($dims{xlabelwidth},$dims{xlabelheight}) = getstringsize("gdMediumBoldFont",$conf{xltext});
		}
		else{
			($dims{xlabelwidth},$dims{xlabelheight}) = getstringsize($conf{lfont},$conf{xltext},$conf{lsize},0);
		}
		$dims{minheight} += ($dims{xlabelheight} + $conf{ipadding});
	}

	# --- calculate widths --- #

	# left padding
	$dims{minwidth} += $conf{ipadding};

	# y label width
	if($conf{yltext} ne ''){
		if($conf{lfont} eq ''){
			($dims{ylabelheight},$dims{ylabelwidth}) = getstringsize("gdMediumBoldFont",$conf{yltext});
		}
		else{
			($dims{ylabelwidth},$dims{ylabelheight}) = getstringsize($conf{lfont},$conf{yltext},$conf{lsize},90);
		}
		$dims{minwidth} += ($dims{ylabelwidth} + $conf{ipadding});
	}

	# largest y val width (ie: of upper range)
	if($conf{vfont} eq ''){
		($dims{yvalwidth},$dims{yvalheight}) = getstringsize("gdSmallFont",$dims{range});
	}
	else{
		($dims{yvalwidth},$dims{yvalheight}) = getstringsize($conf{vfont},$dims{range},$conf{vsize},0);
	}
	$dims{minwidth} += $dims{yvalwidth};

	# padding between y vals and plot area
	$dims{minwidth} += $conf{iplotpad};

	# right padding
	$dims{minwidth} += $conf{ipadding};

	# --- calculate plot area and make final adjustments to min width/height --- #

	# force practical minimum bar/column widths
	$conf{bwidth} = 10 if $conf{bwidth} < 10;
	$conf{bwidth} += 1 if $conf{bwidth} =~ /[02468]$/ and $conf{bstyle} eq "column";

	# floor/side sizes
	my $floorwidth = $conf{bwidth}*1.25;
	$dims{floor} = sprintf("%.0f",sqrt(($floorwidth*$floorwidth)/2));
	$dims{minheight} += $dims{floor};
	$dims{minwidth} += $dims{floor};

	# plot width
	$conf{bminspace} = $dims{xhorheight} if $conf{bminspace} < $dims{xhorheight}; # ensure min bar spacing !<= x val height
	my $keyn = scalar @data;
	$dims{plotwidth} = $conf{iplotpad} + ($keyn * $conf{bwidth}) + (($keyn-1) * $conf{bminspace}) + $conf{iplotpad} + $dims{floor};
	$dims{plotwidth} = $conf{imgw} - $dims{minwidth} if $dims{plotwidth} < $conf{imgw} - $dims{minwidth};
	$dims{minwidth} += $dims{plotwidth};

	# plot height
	$conf{plnspace} = $dims{yvalheight} if $conf{plnspace} < $dims{yvalheight}; # ensure min line spacing !<= y val height
	$dims{plotheight} = $dims{numdivs}*$conf{plnspace};
	$dims{plotheight} = $conf{imgh} - $dims{minheight} if $dims{plotheight} < $conf{imgh} - $dims{minheight};
	$dims{minheight} += $dims{plotheight};

	return %dims;
}

sub getshades {

	my @rgb = ($_[0],$_[1],$_[2]);
	my %conf = %{$_[3]};
	
	# make sure 2 or more colour values can accommodate darkening by 70
	my ($ctr,$darker) = (0,0);
	foreach my $c(@rgb){
		$ctr++ if $c >= 70;
	}
	$darker = 1 if $ctr >= 2;
	# create shades
	my %shades;
	my $ctr = 0;
	foreach my $s(qw/R G B/){
		# shades darker than face colour
		if($darker == 1){
			$conf{bcolumnfill} eq "gradient" and $conf{bstyle} eq "column" ? ($shades{top}{$s} = $rgb[$ctr] - 50) : ($shades{top}{$s} = $rgb[$ctr] - 70);
			$shades{side}{$s} = $rgb[$ctr] - 40;
			$shades{top}{$s} = 0 if $shades{top}{$s} < 0;
			$shades{side}{$s} = 0 if $shades{side}{$s} < 0;
		}
		# shades lighter than face colour
		else{
			$conf{bcolumnfill} eq "gradient" and $conf{bstyle} eq "column" ? ($shades{top}{$s} = $rgb[$ctr] + 40) : ($shades{top}{$s} = $rgb[$ctr] + 70);
			$shades{side}{$s} = $rgb[$ctr] + 50;
			$shades{top}{$s} = 255 if $shades{top}{$s} > 255;
			$shades{side}{$s} = 255 if $shades{side}{$s} > 255;
		}
		$ctr++;
	}
	return %shades;
}

sub randomcolour {

	my %colour;
	# generate random colour numbers but make sure not too close to floor colour
	for my $c(qw/R G B/){
		$colour{$c} = int(rand(256));
	}
	return %colour;
}

sub gradientfill
{
	# get params
	my ($clr,$fromx,$fromy,$tox,$toy,$height,$column,$conf_imgheight) = @_;

	# colour hash for passed colour
	my @n = $image->rgb($clr);
	my %c2 = (
		R => $n[0],
		G => $n[1],
		B => $n[2]
	);

	# work out darkness of colour and set offset accordingly
	my ($offset,$ctr) = (50,0);
	foreach my $i(qw/R G B/){
		$ctr++ if $c2{$i} > 150;
	}
	$offset += 35 if $ctr < 2 and $column eq '';

	# set up colour hash for lighter shade
	my %c1;
	foreach my $i(qw/R G B/){
		$c1{$i} = $c2{$i} + $offset;
		$c1{$i} = 255 if $c1{$i} > 255;
	}

	# initiate dynamic vars
	my $pixposf = $fromy;	# current from x position
	my $pixpost = $toy;	# current to x position
	my %clrs;
	my $rgb = 0;
	foreach ( keys %c1 ) { $clrs{$_}{clr} = $c1{$_}; }

	# add {adj} & {pix} & {pxctr} subhashes to %clrs
	foreach $rgb (qw/R G B/) {
		if ($c1{$rgb} > $c2{$rgb} and $height > ($c1{$rgb}-$c2{$rgb})) {
			$clrs{$rgb}{adj}	= -1;
			$clrs{$rgb}{pix}	= ($height-1)/($c1{$rgb}-$c2{$rgb});
		}
		elsif ($c1{$rgb} > $c2{$rgb} and $height < ($c1{$rgb}-$c2{$rgb})) {
			$clrs{$rgb}{adj}	= -(($c1{$rgb}-$c2{$rgb})/($height-1));
			$clrs{$rgb}{pix}	= 1;
		}
		elsif ($c2{$rgb} > $c1{$rgb} and $height > ($c2{$rgb}-$c1{$rgb})) {
			$clrs{$rgb}{adj}	= 1;
			$clrs{$rgb}{pix}	= ($height-1)/($c2{$rgb}-$c1{$rgb});
		}
		elsif ($c2{$rgb} > $c1{$rgb} and $height < ($c2{$rgb}-$c1{$rgb})) {
			$clrs{$rgb}{adj}	= ($c2{$rgb}-$c1{$rgb})/($height-1);
			$clrs{$rgb}{pix}	= 1;
		}
		$clrs{$rgb}{pxctr} = $clrs{$rgb}{pix};
	}

	# do gradient fill
	while ($column ne '' ? ($pixposf > $fromy-$height) : ($pixposf < $fromy+$height)) {
		# round to nearest integer and make sure within 0-255 range
		my %colour;
		foreach $rgb (qw/R G B/) {
			$colour{$rgb} = sprintf("%.0f",$clrs{$rgb}{clr});
			if ($colour{$rgb} > 255) {
				$colour{$rgb} = 255;
			}
			elsif ($colour{$rgb} < 0) {
				$colour{$rgb} = 0;
			}
		}
		# set line colour
		my $temp = $image->colorAllocate($colour{R},$colour{G},$colour{B});

		# draw line
		if($column ne ''){
			my $ind = $image->getPixel($pixposf,$tox);
			my $toytemp = $tox;
			while ($ind eq $clr and $toytemp < $conf_imgheight){
				$toytemp++;
				$ind = $image->getPixel($pixposf,$toytemp);
			}
			$image->line($pixposf,$fromx,$pixposf,$toytemp,$temp);
			$pixposf--;
		}
		else{
			$image->line($fromx,$pixposf,$tox,$pixpost,$temp);
			$pixposf++;
			$pixpost++;
		}

		# adjust RGB values
		foreach $rgb (qw/R G B/) {
			if($column ne ''){
				if ($pixposf == ($fromy-$height)) {
					$clrs{$rgb}{clr} = $c2{$rgb};
				}
				elsif ( $fromy-$pixposf >= $clrs{$rgb}{pxctr} ) {
					$clrs{$rgb}{pxctr} += $clrs{$rgb}{pix};
					$clrs{$rgb}{clr}   += $clrs{$rgb}{adj};
				}
			}
			else{
				if ($pixposf == ($fromy+$height)-1) {
					$clrs{$rgb}{clr} = $c2{$rgb};
				}
				elsif ( $pixposf-$fromy >= $clrs{$rgb}{pxctr} ) {
					$clrs{$rgb}{pxctr} += $clrs{$rgb}{pix};
					$clrs{$rgb}{clr}   += $clrs{$rgb}{adj};
				}
			}
		}
	}
	
}

1;

# -----------------------------------------------------------------------------
# DOCUMENTATION
# -----------------------------------------------------------------------------

=head1 NAME

GD::3DBarGrapher - Create 3D bar graphs using GD

=head1 SYNOPSIS

  use GD::3DBarGrapher qw(creategraph);

  my @data = (
      ['Apples', 28],
      ['Pears',  43],
      ...etc 
  );

  my %options = (
      'file' => '/webroot/images/mygraph.jpg',
  );

  my $imagemap = creategraph(\@data, \%options);

=head1 DESCRIPTION

There is only one function in the 3dBarGrapher module and that is creategraph
which will return image map XHTML for use in a web page displaying the graph.

The data to graph must be passed in a multidimensional array where column 0
is the x-axis name of the item to graph and column 1 is it's associated
numerical value.

Graph options are passed in a hash and override the defaults listed below. At
minimum the 'file' option must be included and specify the full path and
filename of the graph to create.

=head1 Options

  my %options = (

    # colours

    black       => { R => 0,   G => 0,   B => 0   },
    white       => { R => 255, G => 255, B => 255 },
    vltgrey     => { R => 245, G => 245, B => 245 },
    ltgrey      => { R => 230, G => 230, B => 230 },
    midgrey     => { R => 180, G => 180, B => 180 },
    midblue     => { R => 54,  G => 100, B => 170 },

    # file output details

    file        => '', # file path and name; file extension
                       # can be .jpg|gif|png
    quality     => 9,  # image quality: 1 (worst) - 10 (best)
                       # Only applies to jpg and png

    # main image properties

    imgw        => 400,     # preferred width in pixels
    imgh        => 320,     # preferred height in pixels
    iplotpad    => 8,       # padding between axis vals & plot area
    ipadding    => 14,      # padding between other items
    ibgcol      => 'white', # COLOUR NAME; background colour
    iborder     => '',      # COLOUR NAME; border, if any

    # plot area properties

    plinecol    => 'midgrey',  # COLOUR NAME; line colour
    pflcol      => 'vltgrey',  # COLOUR NAME; floor colour
    pbgcol      => 'ltgrey',   # COLOUR NAME; back/side colour
    pbgfill     => 'gradient', # 'gradient' or 'solid'; back/side fill
    plnspace    => 25,         # minimum pixel spacing between divisions
    pnumdivs    => 6,          # maximum number of y-axis divisions

    # bar properties

    bstyle      => 'bar',      # 'bar' or 'column' style
    bcolumnfill => 'gradient', # 'gradient' or 'solid' for columns
    bminspace   => 18,         # minimum spacing between bars
    bwidth      => 18,         # width of bar
    bfacecol    => 'midblue',  # COLOUR NAME or 'random'; bar face,
	                           # 'random' for random bar face colour
    # graph title

    ttext       => '',      # title text
    tfont       => '',      # uses gdGiantFont unless a true type
                            # font is specified
    tsize       => 11,      # font point size
    tfontcol    => 'black', # COLOUR NAME; font colour

    # axis labels

    xltext      => '',        # x-axis label text
    yltext      => '',        # y-axis label text
    lfont       => '',        # uses gdLargeFont unless a true type
                              # font is specified
    lsize       => 10,        # font point size
    lfontcol    => 'midblue', # COLOUR NAME; font colour

    # axis values

    vfont       => '',      # uses gdSmallFont unless a true type
                            # font is specified
    vsize       => 8,       # font point size
    vfontcol    => 'black', # COLOUR NAME; font colour
    
  );

Notes on options:

=over 5

=item 1.
Options commented with "COLOUR NAME" expect the name of one of the default
colours above, or you can define your own colours by adding new lines in the
same format

=item 2.
Overall graph width and height can exceed the preferred values, depending on
number of items to graph and the values specified for various settings like
bwidth, bminspace, etc

=item 3.
For better text quality it is recommended to specify true type fonts for
options tfont, lfont & vfont. the full path and font file name must be
included, eg: 'c:/windows/fonts/verdana.ttf'

=item 4.
Only options that default to empty can be defined as empty

=head1 Image Map

The creategraph function returns XHTML code for the image and an associated
image map, something like this:

  <img src="mygraph.jpg" width="400" height="320" border="0" usemap="#mygraphjpg1179003059" />
  <map name="mygraphjpg1179003059" id="mygraphjpg1179003059">
  <area shape="rect" coords="67,123,112,245" href="#" title="Apples: 28" />
  <area shape="rect" coords="112,75,158,245" href="#" title="Pears: 43" />
  ...etc
  </map>

=head1 Bugs

There aren't any known ones but feel free to report any you find and I may
(or may not) fix them! Contact swarhurst _at_ cpan.org

=head1 AUTHOR

3DBarGrapher is copyright (c) 2009 S.I.Warhurst and is distributed under the
same terms and conditions as Perl itself. See the Perl Artistic license:

http://www.perl.com/language/misc/Artistic.html

=head1 SEE ALSO

L<GD>

=cut
