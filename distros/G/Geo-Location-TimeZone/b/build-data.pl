#!/usr/bin/perl

$|=1;
use strict;
use Geo::ShapeFile;
use Math::Polygon;
use Data::Dumper;

use lib "../lib";
use lib "lib";
use Geo::Location::TimeZone;
# This is a hacky script to generate the data used by Geo::Location::TimeZone.
# It essentially uses brute force.  It is run by the package maintainer, and
# not as part of unpacking the package.
# The steps taken are:
#	1) Read in list of centroid points and matching names.
#	2) read the ESRI Timezone boundary DB.
#	3) Iterate through above:
#		3a) Get the bounding box of the polygon.
#		3b) Work through each 15x15 box within the boundary, seeing if
#		    anything is within.
#			3b1) Check to see if any known centroids are within
#			     this 15x15 square.
#			3b2) else, check to see if the timezone matches the
#			     calculated zone.  Skip if so (save memory)
#			3b3) If a name different to the calculated one is
#			     found, write out this polygon.
#			3b4) If multiple polygons are found, work out the one
#			     with the largest area and use that one as the 
#			     default.
#
# Note: Everything found is kept in memory, so it can be output in one hit.

# Master data store.
my %data = ();

my $outdir = "../lib/Geo/Location/TimeZone/";
my $basezone = "Geo::Location::TimeZone";
my $geotzobj = $basezone->new();
my $totpack = 0;
my $totunpack = 0;

# Fun, ESRI did decimal hour offsets.
my %offcountries = (	"3.50"	=> "Asia/Tehran",
			"4.50"	=> "Asia/Kabul",
			"5.75"	=> "Asia/Katmandu",
			"-3.50"	=> "Canada/Newfoundland",
			"-9.50"	=> "Pacific/Marquesas",
			"9.50"	=> "Australia/Darwin",
			"6.50"	=> "Indian/Cocos",
			"-8.50"	=> "Pacific/Marquesas",
			"11.50"	=> "Pacific/Norfolk",
			"10.50"	=> "Australia/Adelaide",
			"12.75"	=> "Pacific/Chatham",
			"5.50"	=> "Asia/Calcutta",
			);
sub close15 {
	my $arg = shift;

	my $retval = int(( abs( $arg ) + 7.5 ) /15 );
	if( $arg < 7.5 ){
		$retval = 0 - $retval;
	}
	return( $retval );
}

sub expandbox {
	my $x = shift;
	my $y = shift;

	my @retval = ();

	$retval[0] = ( $x * 15 ) - 7.5;
	$retval[1] = ( $y * 15 ) - 7.5;
	$retval[2] = ( $x * 15 ) + 7.5;
	$retval[3] = ( $y * 15 ) + 7.5;

	# print STDERR "expandbox: $x $y : " . join( ",", @retval ) . "\n";

	return( @retval );
}

my $shapefile = "../../tarballs/timezone";

my %centroids = ();
my %recheck = ();

# File has the format 'lat tab lon tab name'.  To nearest degree.
my $centroidfile = "centroids.lst";

if( open( INFILE, $centroidfile ) ){
	while( my $inline = <INFILE> ){
		chomp( $inline );
		next unless( $inline =~ /^\s*(\-?\d+\.\d+)\s+(\-?\d+\.\d+)\s+(\S+)(\s+\d+\.\d+)?\s*$/ );
		my $lat = $1;
		my $lon = $2;
		my $zone = $3;
		my $radius = $4;


		# Simple 2-level hash.
		my $latstore = &close15( $lat );
		my $lonstore = &close15( $lon );
		my $storekey1 = $lonstore . "x" . $latstore;
		my $storekey2 = $lon . "x" . $lat;
		# print STDERR "Centroid - found $inline - $lat , $lon , $zone - $storekey1 , $storekey2\n";

		$centroids{"$storekey1"}{"$storekey2"} = $zone;

		if( defined( $radius ) ){
			if( $radius =~ /^\s*(\d+\.\d+)\s*$/ ){
				$centroids{"$storekey1"}{"$storekey2"} = $zone . "," . $1;
			}
		}
	}
	close( INFILE );
}

# We've stored all the centroids.  

# Now attempt to read in data that is not from ESRI.  We use Data::Dumper.
my $odir = ".";
my $keycount = 0;
if( opendir( INDIR, "$odir" ) ){
	while( my $dentry = readdir( INDIR ) ){
		next unless( $dentry =~ /^custom\./ );
		my $fullfile = $odir . "/" . $dentry;
		next unless( -f $fullfile );

		if( open( INFILE, $fullfile ) ){
			my $inobj = "";
			while( my $line = <INFILE> ){
				$inobj .= $line;
			}
			close( INFILE );

			# Things in here are named 'ndata'.
			my %ndata = ();
			print "(Custom) Read in " . length( $inobj ) . " worth of stuff.\n";
			eval $inobj;

			if( $@ ){
				print "Err, $@\n";
			}

			# Lets run through the data here.
			foreach my $xkey( keys %ndata ){
				foreach my $ykey( keys %{$ndata{"$xkey"}} ){
					foreach my $rkey( keys %{$ndata{"$xkey"}{"$ykey"}} ){
						my $tref = ref( $ndata{"$xkey"}{"$ykey"}{"$rkey"} ) ;
						# print "Ref is $tref X\n";
						if( ! $tref ){
							$data{"$xkey"}{"$ykey"}{"$rkey"} = \$ndata{"$xkey"}{"$ykey"}{"$rkey"};
							# print "Copying noref stuff for $xkey,$ykey,$rkey \n";
						}elsif( $tref eq 'HASH' ){
							$recheck{"$xkey"}{"$ykey"}++;
							$data{"$xkey"}{"$ykey"}{"$keycount"}{"s"} = "$dentry";
							foreach my $skey( keys %{$ndata{"$xkey"}{"$ykey"}{"$rkey"}} ){
								$tref = ref( $ndata{"$xkey"}{"$ykey"}{"$rkey"}{"$skey"} );
								if( ! $tref ){
									$data{"$xkey"}{"$ykey"}{"$keycount"}{"$skey"} = $ndata{"$xkey"}{"$ykey"}{"$rkey"}{"$skey"};
								}elsif( $tref eq 'ARRAY' ){
									@{$data{"$xkey"}{"$ykey"}{"$keycount"}{"$skey"}} = @{$ndata{"$xkey"}{"$ykey"}{"$rkey"}{"$skey"}};
								}
								# print "Copying $tref stuff for $xkey,$ykey,$rkey,$skey as " . $ndata{"$xkey"}{"$ykey"}{"$rkey"}{"$skey"} . "\n";
							}
						}
						$keycount++;
					}
				}
			}
		}
	}
	closedir( INDIR );
}

# sleep 5;

# Finally, read in the shapefile data from ESRI.
my $shapeobjs = new Geo::ShapeFile( $shapefile );

for ( my $c = 1 ; $c <= $shapeobjs->shapes() ; $c++ ){
# for ( my $c = 1 ; $c <= 2 ; $c++ ){
	my $lshape = $shapeobjs->get_shp_record( $c );

	# Retrieve the textual records associated with this shape.
	my %lsh_db = $shapeobjs->get_dbf_record( $c );

	my $lzone = undef;


	# Collect the initial zone.
	if( defined( $lsh_db{"ZONE"} ) ){
		if( $lsh_db{"ZONE"} =~ /^\s*(\-?\d+)(\.00)?\s*$/ ){
			my $loff = $1;
			$lzone = "Etc/GMT";
			if( $loff > 0 ){
				$lzone .= "+" . $loff;
			}elsif( $loff < 0 ){
				$lzone .= $loff;
			}
		}else{
			# It is a zone with a fractional offset.  Use the
			# inbuilt list.
			if( defined( $offcountries{$lsh_db{"ZONE"}} ) ){
				$lzone = $offcountries{$lsh_db{"ZONE"}};
			}else{
				$lzone = "Unknown/" . $lsh_db{"ZONE"};
			}
		}
	}else{
		$lzone = "undefinedzone";
	}

	print STDERR "Shape number $c , zone is " . $lsh_db{"ZONE"} . " and $lzone X\n";

	# If a zone hasn't been found, we might find it later via the centroid
	# list.  Lets start looping.
	for ( my $s = 1 ; $s <= $lshape->num_parts ; $s++ ){
		my @points = ();

		# Store the points in a local array.
		foreach my $point( $lshape->get_part( $s ) ){
			push @points, [$point->X, $point->Y];
		}

		# Create the polygon.
		my $poly = Math::Polygon->new( @points );

		# What is the bounding box for this?
		my ($xmin, $ymin, $xmax, $ymax) = $poly->bbox;


		# Change those into 15 degree chunks.
		$xmin = &close15( $xmin );
		$ymin = &close15( $ymin );
		$xmax = &close15( $xmax );
		$ymax = &close15( $ymax );

		my $oymin = $ymin;

		# print STDERR "$lzone received $xmin $ymin $xmax $ymax\n";

		# Start working through all of the possibilities.
		while( $xmin <= $xmax ){

			# Get the zone for this longitude.
			my $szone = "Etc/GMT";
			if( $xmin > 0 ){
				$szone .= "+" . $xmin;
			}elsif( $xmin < 0 ){
				$szone .= $xmin;
			}

			# See whether we found a specific match.
			my $forceuse = 0;
			if( $lzone !~ /^Etc/ || $szone ne $lzone ){
				$forceuse++;
			}

			$ymin = $oymin;

			while( $ymin <= $ymax ){

				# We skip this grid if there is already data
				# from other sources.
				if( defined( $data{"$xmin"}{"$ymin"}{"o"} ) ){
					$ymin++;
					next;
				}

				my $usezone = $lzone;

				# print STDERR "$xmin/$xmax , $ymin/$ymax    \n";

				# Expand the xmin,ymin to a rectangle that
				# we can use fillClip on.
				my @bbox = &expandbox( $xmin, $ymin );

				print STDERR "$lzone Grid $xmin:$ymin - Restricting to " . join( ",", @bbox ) . "   \r";
				my $newpoly = $poly->fillClip1( @bbox );

				# Skip if nothing sensible was returned,
				# meaning that there is nothing in this
				# block.
				if( ! defined( $newpoly ) ){
					$ymin++;
					next;
				}elsif( $newpoly->nrPoints <= 1 ){
					print STDERR "$lzone has 0 or 1 points\n";
					$ymin++;
					next;
				}else{
					print STDERR "$lzone Found something within " . join( ",", @bbox ) . "\n";
				}


				# See if there are any centroid points.  We
				# then use 'contains' on each one to see if
				# it matches.  This should be 'good enough',
				# as the ESRI data should not have any 
				# overlaps.  The name found replaces the
				# calculated value in $szone.
				my $centlook = $xmin . "x" . $ymin;
				my @centzones = ();
				if( defined( $centroids{"$centlook"} ) ){
					# Run through the points, and sees if
					# $newpoly->contains has it.
					my $zcount = 1;
					foreach my $checkkey( keys %{$centroids{"$centlook"}} ){
						next unless( $checkkey =~ /^(\-?\d+\.\d+)x(\-?\d+\.\d+)$/ );
						next unless( $newpoly->contains( [ $1, $2 ] ) );
						push @centzones, $1 . "," . $2 . "," . $centroids{"$centlook"}{"$checkkey"};
						$usezone = $centroids{"$centlook"}{"$checkkey"};
						# There may be a radius, which
						# is not good to have here.
						# print STDERR "Centroid - $centlook and key $checkkey - $usezone X\n";
						$usezone = $1 if( $usezone =~ /^([^,]+),/ );
					}
				}

				# If we are going to use this zone, simplify
				# the polygon.
				if( $szone ne $usezone || $forceuse ){
					# Unfortunately, simplify occasionally
					# has issues.  At heart is that 
					# fillClip1 will sometimes produce a
					# lot of points along a clipped line.
					# Since we're clipping on only vertical
					# and horizontal lines, we can simplify
					# this ourselves, although it'll be
					# slower.
					# $newpoly = $newpoly->simplify( same => 0, slope => 0.001 );
					my @masspoints = $newpoly->points();
					my $diddel = 0;
					for( my $curoff = 0; $curoff < ( scalar @masspoints ) - 3 ; $curoff++ ){
						$curoff=0 if( $curoff < 0 );
						# If either the X or Y coords of
						# 3 points in succession are
						# the same, then it is a line
						# that we can simplify ourselve
						my $trimX = 0;
						my $trimY = 0;
						my $candel = 0;
						if( $masspoints[$curoff][0] == $masspoints[$curoff+1][0] && $masspoints[$curoff][0] == $masspoints[$curoff+2][0] ){
							$trimX++;
						}
						if( $masspoints[$curoff][1] == $masspoints[$curoff+1][1] && $masspoints[$curoff][1] == $masspoints[$curoff+2][1] ){
							$trimY++;
						}

						# Match the case of two 
						# identical points being
						# present, but not part of a 
						# line series.
						if( ! $trimX && ! $trimY ){
							if( $masspoints[$curoff][0] == $masspoints[$curoff+1][0] && $masspoints[$curoff][1] == $masspoints[$curoff+1][1] ){
								$candel++;
							}
						}else{
							$candel++ if( $trimX );
							$candel++ if( $trimY );
						}

						while( $candel > 0 ){
							# print STDERR "Removing point: " . $masspoints[$curoff][0] . "," . $masspoints[$curoff][1] . " vs ". $masspoints[$curoff+1][0] . "," . $masspoints[$curoff+1][1] . "\n";
							# delete( $masspoints[$curoff+1] );
							splice( @masspoints, $curoff+1, 1 );
							$candel--;
							$diddel++;
						}

						if( $trimX || $trimY ){
							$curoff--;
						}
					}

					if( $diddel ){
						print STDERR "Removed $diddel points leaving " . scalar @masspoints . " \n";
						# Recreate the poly using the
						# reduced set of points.
						# print STDERR "Recreating the polygon: " . join( ",", @masspoints ) . " X\n";
						$newpoly = Math::Polygon->new( @masspoints );

					}
				}

				# Save this zone if something different
				# is found, and the polygon has a bit of area.
				my $tarea = 0;
				if( $szone ne $usezone || $forceuse ){
					$tarea = $newpoly->area();
					if( $tarea > 0 ){
						# Increment the count.
						$keycount++;
						$data{"$xmin"}{"$ymin"}{"$keycount"}{"a"} = $tarea;
					}
				}

				if( $tarea != 0 ){
					# print "\t\$data{\"$xmin\"}{\"$ymin\"}{\"$keycount\"}{\"z\"} = \"$usezone\";\n";
					# print "\t\$data{\"$xmin\"}{\"$ymin\"}{\"$keycount\"}{\"p\"} = ( ";
					# Save the area of the poly.
					$data{"$xmin"}{"$ymin"}{"$keycount"}{"a"} = $newpoly->area();
					if( scalar @centzones <= 1 ){
						$data{"$xmin"}{"$ymin"}{"$keycount"}{"z"} = "$usezone";
						if( $usezone =~ /^\s*$/ ){
							print STDERR "Huh?  No zone! ($xmin, $ymin, $keycount, ESRI $c, $s )\n";
						}
					}else{
						print STDERR "Found centzones with " . scalar @centzones . " records\n";
						for( my $centoff = 0; $centoff < scalar @centzones ; $centoff++ ){
							$data{"$xmin"}{"$ymin"}{"$keycount"}{"z" . $centoff} = $centzones["$centoff"];
						}
					}
					$data{"$xmin"}{"$ymin"}{"$keycount"}{"c"} = "ESRI";
					# Reference for finding where the
					# data came from.
					$data{"$xmin"}{"$ymin"}{"$keycount"}{"s"} = "$c,$s";
					my $teststr = $geotzobj->do_pack( poly => $newpoly );
					# print STDERR "Got do_pack string of " . length( $teststr ) . "\n";
					$totpack += length( $teststr );
					foreach my $fpoint( $newpoly->points ){
						# print ${$fpoint}[0] . "," . ${$fpoint}[1] . ",";
						push @{$data{"$xmin"}{"$ymin"}{"$keycount"}{"p"}}, [${$fpoint}[0], ${$fpoint}[1]];
					}
					# print " );\n";
					$recheck{"$xmin"}{"$ymin"}++;
				}else{
					# print STDERR "Skipping - $lzone, $szone\n";
				}

				# Finally increment.
				$ymin++;
			}

			# Inc xmin
			# print STDERR "inc xmin $xmin\n";
			$xmin++;
		}
	}
}

my %zulus = (	"0",	"Z",
		"1",	"A",
		"2",	"B",
		"3",	"C",
		"4",	"D",
		"5",	"E",
		"6",	"F",
		"7",	"G",
		"8",	"H",
		"9",	"I",
		"10",	"K",
		"11",	"L",
		"12",	"M",
		"-1",	"N",
		"-2",	"O",
		"-3",	"P",
		"-4",	"Q",
		"-5",	"R",
		"-6",	"S",
		"-7",	"T",
		"-8",	"U",
		"-9",	"V",
		"-10",	"W",
		"-11",	"X",
		"-12",	"Y",
	);

# Run through the list of things checked, outputting all the data.
my $fc = 0;
my $ec = 0;
# print "\n# Output of all data at " . time . "\nmy \%data = {\n";
for ( my $xc = -12 ; $xc <= 12 ; $xc++ ){
	my $doneX = 0;
	for ( my $yc = -6 ; $yc <= 6 ; $yc++ ){
		$ec++;
		if( ! $doneX && defined( $zulus{"$xc"} ) ){
			my $outfile = $outdir . "/" . $zulus{"$xc"} . ".pm";
			if( open( OUTPUT, "> $outfile" ) ){
				$doneX = 1;
				print OUTPUT "######## GeoData for $basezone - Check main library for copyright.\n";
				print OUTPUT "######## Roughly GMT $xc\n";
				print OUTPUT "package " . $basezone . "::" . $zulus{"$xc"} . ";\n";
				print OUTPUT "use Class::Singleton;\n";
				print OUTPUT "use " . $basezone . ";\n";

				print OUTPUT "\@ISA = qw(Class::Singleton Geo::Location::TimeZone);\n";
				print OUTPUT "# Coordinates are X,Y, NOT lat,lon\n";
				print OUTPUT "# Output of partial data at " . time . "\nmy \$data = {\n";
				print OUTPUT "\t# Longitude " . ( ( $xc * 15 ) - 7.5 ) . " to " . ( ( $xc * 15 ) + 7.5 ) . "\n";
				print OUTPUT "\t\"$xc\" => {\n";
			}else{
				print STDERR "Could not open file for $xc - $outfile \n";
			}
		}
		if( ! defined( $recheck{"$xc"}{"$yc"} ) ){
			print STDERR "$xc:$yc - Nothing\n";
			if( $doneX ){
				print OUTPUT "\t\t# Grid $xc:$yc ; No records found\n";
			}
		}elsif( $doneX ){
			print OUTPUT "\t\t# Grid $xc:$yc ; " . $recheck{"$xc"}{"$yc"} . " records\n";
			print OUTPUT "\t\t\"$yc\" => {\n";

			my $maxarea = -1;
			my $maxname = undef;
			foreach my $rkey( sort keys %{$data{"$xc"}{"$yc"}} ){
				next if( $rkey eq "o" );
				if( ! defined( $data{"$xc"}{"$yc"}{"$rkey"}{"a"} ) ){
					my $newpoly = Math::Polygon->new( @{$data{"$xc"}{"$yc"}{"$rkey"}{"p"}} );
					$data{"$xc"}{"$yc"}{"$rkey"}{"a"} = $newpoly->area();
				}
				if( $data{"$xc"}{"$yc"}{"$rkey"}{"a"} > $maxarea || $maxarea == -1 ){
					$maxarea = $data{"$xc"}{"$yc"}{"$rkey"}{"a"};
					$maxname = $rkey;
				}

			}

			# Decide what the default timezone is.
			if( defined( $maxname ) ){
				my @bbox = &expandbox( $xc, $yc );
				my @points = ();
				push @points, [$bbox[0],$bbox[1]];
				push @points, [$bbox[2],$bbox[3]];
				my $npoly = Math::Polygon->new( @points );

				# If there is only one polygon, and the area
				# is less than the bounding box, then we
				# need to retain it in the output.
				if( $maxarea < $npoly->area && $recheck{"$xc"}{"$yc"} > 1 ){
					# Need to output the timezones found
					# on the object that we're not putting
					# in as def_zs.
					foreach my $foundzs( keys %{$data{"$xc"}{"$yc"}{"$maxname"}} ){
						next unless( $foundzs =~ /^z/ );
						print OUTPUT "\t\t\t\"def_" . $foundzs . "\" => \"" . $data{"$xc"}{"$yc"}{"$maxname"}{"$foundzs"} . "\",\n";
						$data{"$xc"}{"$yc"}{"$maxname"}{"isdef"} = 1;
					}
				}else{
					# Huh.  One polygon found, 80.8481929106774 , 0 X
					print STDERR "Huh.  One polygon found, $maxarea , " . $npoly->area . " from points " . join(',', @bbox ) . " X\n";
				}
			}


			foreach my $rkey( sort keys %{$data{"$xc"}{"$yc"}} ){
				next if( $rkey eq "o" );
				next if( defined( $data{"$xc"}{"$yc"}{"$rkey"}{"isdef"} ) );
				print OUTPUT "\t\t\t\"$rkey\" => {\n";
				foreach my $foundzs( keys %{$data{"$xc"}{"$yc"}{"$rkey"}} ){
					next unless( $foundzs =~ /^z/ );
					print OUTPUT "\t\t\t\t\"" . $foundzs . "\" => \"" . $data{"$xc"}{"$yc"}{"$rkey"}{"$foundzs"} . "\",\n";
				}
				foreach my $maybe( "c", "s" ){
					next unless( defined( $data{"$xc"}{"$yc"}{"$rkey"}{"$maybe"} ) );
					print OUTPUT "\t\t\t\t\"$maybe\" => \"" . $data{"$xc"}{"$yc"}{"$rkey"}{"$maybe"} . "\",\n";
				}
				print OUTPUT "\t\t\t\t\"p\" => [";
				foreach my $tpoint (@{$data{"$xc"}{"$yc"}{"$rkey"}{"p"}} ){
					my $tmpstr = "[" . ${$tpoint}[0] . "," . ${$tpoint}[1] . "],";
					print OUTPUT $tmpstr;
					$totunpack += length( $tmpstr );
				}
				print OUTPUT "],\n";
				print OUTPUT "\t\t\t},\n";
			}

			print OUTPUT "\t\t},\n";
			$fc++;
		}
	}

	if( $doneX ){
		print OUTPUT "\t},\n";
		print OUTPUT "};\n";

		print OUTPUT "\n# Used by Class::Singleton\n";
		print OUTPUT "sub _new_instance\n";
		print OUTPUT "{\n";
    		print OUTPUT "\treturn shift->_init( \@_, data => \$data );\n";
		print OUTPUT "}\n";

		print OUTPUT "\n1;\n";
		close( OUTPUT );
		$doneX = 0;
	}
}
# print ");\n";

print "\n# Of $ec possible 15x15 squares, found data in $fc of them\n";
print "\n# Packed is $totpack, unpacked is $totunpack\n";

print STDERR "Found $fc of $ec \n";

# print Dumper( %data );
