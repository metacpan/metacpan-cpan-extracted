package Image::Maps::Plot::FromLatLong; # where in the world are London.pm members?

our $VERSION = 0.12;
our $DATE = "Thu 17 November 18:50 2004";
use 5.006;
use strict;
use warnings;
use Image::Magick;
use File::Basename;
use Data::Dumper;


use Config;

=head1 NAME

Image::Maps::Plot::FromLatLong - plots points on Mercator Projection world/regional map

=head1 SYNOPSIS

	use Image::Maps::Plot::FromLatLong;

	# Get ready
	$m = new Image::Maps::Plot::FromLatLong (
		MAP=>"THE WORLD",
		PATH=>"C:/out.html",	# Extension is irrelevant
		FONT=>"C:/winnt/fonts/arial.ttf",
	);

	# Now, Create an HTML page with images:
	$m->create_html;
	# Or just the image
	$m->create_imagefile;
	# Or get a reference to an image blob:
	$m->get_blob;

	# Create HTML pages of all maps in the db, with index
	my $m = new Image::Maps::Plot::FromLatLong(
		FONT=>'c:/winnt/fonts/arial.ttf',
	);
	$m->all("C:/");

	# Add a map
	$Image::Maps::Plot::FromLatLong::MAPS{"LONDON AREA"} = {
		FILE =>	'C:\PhotoWebServer\Perl\site\lib\Image\Maps\Plot\london_bourghs.jpg',
		DIM	 => [650,640],
		SPOTSIZE => 5,
		ANCHOR_PIXELS => [447,397],		# Greenwich on the pixel map
		ANCHOR_LATLON => [51.466,0],	# Greenwich lat/lon
		ANCHOR_NAME	  => 'Greenwich',
		ANCHOR_PLACE  => 'Observatory',
		ONEMILE		=> 19.5,			# 1 km = .6 miles  (10km=180px = 10miles=108px)
	};


	# Add a user to the db
	$m->load_db (".earth.dat");
	$m->add_entry ('Ike Elben Goddard','Hungary','H-1165');
	$m->save_db (".aliyah.dat");

	# Create map content on the fly:
	$maker = new Image::Maps::Plot::FromLatLong(
		MAP	=> "THE WORLD",
		FONT=>'c:/winnt/fonts/arial.ttf',
		PATH	=> "/Two.foo",
		DBFILE	=> undef,
		LOCATIONS => {
		  'Lee' => {
			 'LAT' => '51.592423',
			 'PLACE' => '#ffff44',
			 'LON' => '-0.171996'
		   },
		  'Lee Again' => {
			'PLACE' => '#ffff77',
			'LAT' => 46,
			'LON' => 16
		  },
		},
	);


	__END__

=head1 DESCRIPTION

Plots points defined by latitude/longitude on JPEG Mercator Projection maps,
optionally creating an HTML page with image map to display the image.

=head1 PREREQUISITES

	Data::Dumper;
	File::Basename;
	strict;
	warnings.

	WWW::MapBlast 0.02
	Image::Thumbnail 0.011

=head1 DISTRIBUTION CONTENTS

In addition to this file, the distribution uses the included files
for default settings: they should be placed in the same directory
as the module itself only if you wish to use default settings.

	.earth.dat
	london_postcodes.jpg
	uk.jpg
	world.jpg

=head1 EXPORTS

None.

=cut

#
# Global scalars
#
# Real-time output of what's going on; affecting by L<"new">.
our $ADDENTRY = 'MULTIPLE';		# Cf. L<"add_entry">
our %locations = ();			# Cf. L<"load_db">

#
# See L<NOTES ON LATITUDE AND LONGITUDE> and sub _make_latlon
#
our @LAT;
our @_LAT = (
	68.70, 	68.71,	68.73,	68.75,	68.79,	68.83,	68.88,	68.94,	68.99,
	69.05,	69.12,	69.18,	69.23,	69.28,	69.32,	69.36,	69.39,	69.40,	69.41
);
our @LON;
our @_LON = (
	69.17,	68.91,	68.13,	66.83,	65.03,	62.73,	59.96,	56.73,	53.06,
	49.00,	44.55,	39.77,	34.67,	29.32,	23.73,	17.96,	12.05,	6.05,	0.00,
);
&_make_latlon;


#
# Hack hack: prefix to locate our install dir
#
#my $MOD = "$Config{installsitelib}/".__PACKAGE__;
#$MOD =~ s/::/\//g;
#$MOD =~ s/[^\/]+$//;

# MARKSTOS -at- CPAN -dot- org suggested:
# I've not had a chance to test if this will burp
# on relative paths/under mod_perl....
my $MOD = __PACKAGE__;
$MOD =~ s/::/\//g;
$MOD = $INC{$MOD.".pm"} || '';
$MOD =~ s/\.pm$//i;

#
# Default maps: see L<"ADDING MAPS"> to ... add maps.
#
our %MAPS = (
	"THE WORLD" => {
		FILE	  	=> $MOD."world.jpg",
		DIM 	  	=> [823,485],
		SPOTSIZE	=> 2,
		ANCHOR_PIXELS => [389,258],		# Zero lat, zero lon
		ANCHOR_LATLON => [0,0],	# 0,0
		ANCHOR_NAME	  => '',
		ANCHOR_PLACE => 'Zero degrees latitude, zero degree longitude',
		ONEMILE 		=> 0.0342,	# was 0.0056, better with 0.0348
	},
	"THE UK" 	=> {
		FILE	  	=> $MOD."uk.jpg",
		DIM 	  	=> [363,447],
		SPOTSIZE	=> 4,
		ANCHOR_PIXELS => [305,388],		# Greenwich
		ANCHOR_LATLON => [51.466,0],
		ANCHOR_NAME	  => 'Greenwich',
		ANCHOR_PLACE  => 'Observatory',
		# ONEMILE	=> 00.55,
		ONEMILE	=> 0.51,
	},
	"A BAD MAP OF LONDON LONDON"	=> {
		FILE		=> $MOD."london_postcodes.jpg",
		DIM			=> [650,640],
		SPOTSIZE	=> 8,
		ANCHOR_PIXELS => [447,397],		# Greenwich
		ANCHOR_LATLON => [51.466,0],	# Greenwich
		ANCHOR_NAME	  => 'Greenwich',
		ANCHOR_PLACE  => 'Observatory',
		ONEMILE		=> 19.5,			# 1 km = .6 miles  (10km=180px = 10miles=108px)
	},

);


=head1 CONSTRUCTOR new

Returns an object in this class.

Accepts arguments in a hash, where keys/values are as follows:

=over 4

=item MAP

Either C<THE WORLD>, C<THE UK>, C<A BAD MAP OF LONDON>, or any other key to the C<%MAPS> hash
defined elsewhere, and documented L<below|"ADDING MAPS">.

=item PATH

The path at which to save - will use the filename you supply, but please include an extension,
coz I'm lazy. You will receive a C<.jpg> and C<.html> file in return.

=item DBFILE

Name of the configuration/db file - defaults to C<.earth.dat>, which comes
with the distribution: set to C<undef> if you do
not wish to use the default (perhaps because you are using the C<LOCATIONS>
field to supply a 'database' - see the next item).

=item LOCATIONS

Optional: a reference to a hash that will add and replace items in the
module's content 'database'. Format of the hash referred to should be:

	$LOCATIONS = {
	    'This key is a printable proper name' => {
        'LAT' => 11111111,	# Latitude value, or 11111111 if unknown
	    'PLACE' => 'An Image;:Magick Colour Name or printable descriptor of the location',
	    'LON' => 11111111	# Longitude value, or 11111111 if unknown
	},

If C<PLACE> fields are supplied as hex colour names (C<#> prefix)
then their values will not be printed.

Note that if you supply this field I<without> supplying the C<DBFILE>
with a value of C<undef>, you will inherit the default location 'database'.

=item IMG_URI_PREFIX

If supplied, will be prefixed to the value of the C<IMG> C<src> attribute
in HTML pages generated.

=item CHAT

Set if you want rabbit (Amos: that's London-speak for talk) to STDERR.

=item CREATIONTXT

Text output onto the image.  Defaults to 'Created on <date> by <package>.';

=item TITLE

Title text to include on the image (in bold) and as the content of the HTML page's C<TITLE> element: is appended with the name of the map.  This defaults to C<London.pm>, where this module originates.

=item FONT

Font for the above: absolute path or something Image Magick can find.

=item INCLUDEANCHOR

Set if you wish the map's anchor point to be included in the output.

=item FNPREFIX

Filename prefix - added to the start of all files output except the db file.
Default is C<m_>.

=item KEYS2VALUES

If set, will assume the 'place' sub-keys in C<locations> hash are colour values
for spots printed.

=item BORDER, FILL

Border and fill colours: if not set, SPOTCOLOUR will set them both.

=item CSS

Formatted inline CSS to go within a C<STYLE type='text/css'> block in the header.

=item EXTRA_HTML

If defined, added at the end of the page.

=back

=cut

sub new { my $class = shift;
	die "Please call with a package ID" if not defined $class;
	my %args;
	my $self = {};
	bless $self,$class;

	# Take parameters and place in object slots/set as instance variables
	if (ref $_[0] eq 'HASH'){	%args = %{$_[0]} }
	elsif (not ref $_[0]){		%args = @_ }
	%locations = ();
	undef %locations;

	# Default instance variables
	$self->{HTML} 			= '';									# Will contain the HTML for the image and image map
	$self->{MAP}			= "THE WORLD";								# Default map cf. our %MAPS
	$self->{CREATIONTXT} 	= "Created on ".(scalar localtime)." by ".__PACKAGE__;
	$self->{FNPREFIX} 		= 'm_';
	$self->{DBFILE}			= "$MOD/.earth.dat";
	$self->{HTML}			= undef;
	$self->{FILL} 			= "white";
	$self->{BORDER} 		= "red";
	$self->{SPOTCOLOUR}		= "red";
	$self->{IMG_URI_PREFIX}	= "";
	$self->{EXTRA_HTML}		= "";
	$self->{CSS}			= " ";
	$self->{TITLE} 			= " ";

	# Overwrite default instance variables with user's values
	foreach (keys %args) {	$self->{$_} = $args{$_} }

	$self->{BORDER}			= $self->{SPOTCOLOUR} unless exists $self->{BORDER};
	$self->{FILL}			= $self->{SPOTCOLOUR} unless exists $self->{FILL};

	# Legacy
	if ($self->{DBNAME}){
		$self->{DBFILE}			= $self->{DBNAME};
		undef $self->{DBNAME};
		delete $self->{DBNAME};
	}

	$self->load_db($self->{DBFILE}) if $self->{DBFILE};

	if ($self->{LOCATIONS}){
		die "LOCATIONS must be a reference to a hash" if ref $self->{LOCATIONS} ne 'HASH';
		foreach my $l (keys %{$self->{LOCATIONS}}){
			$locations{$l} = $self->{LOCATIONS}->{$l};
		}
	}
	if (not defined $self->{TITLE}){
		$self->{TITLE}	= $self->{MAP};
	}

	return $self;
}


=head1 METHOD create_html

Creates an image and an HTML page.

Requires that the C<PATH> field be set (see L<CONSTRUCTOR>).

=cut

sub create_html { my $self=shift;
	die  "Please supply an output path in your calling object\n" if not exists $self->{PATH};
	my ($name,$path,$suffix) = fileparse($self->{PATH},'(\.[^.]*)?$' );
	die  "Please supply a filepath with a dummy extension" if not defined $name;
	$self->{PATH} = $path.$name;
	$self->{IMGPATH} = $name.'.jpg';

	# Try to load the image into our object
	die "There is no option for a map of $self->{MAP}" if not exists $MAPS{$self->{MAP}};
	if (not -e $MAPS{$self->{MAP}}->{FILE}){
		warn "No map for $self->{MAP}: $!" ;
		return undef;
	}

	$self->_load_map or die "Could not read map from $MAPS{$self->{MAP}}->{FILE}:\nReason: $!\n ";

	# Now we have the argument for the map in question:
	$self->_add_html_top;
	$self->_add_map_top;

	$self->_populate(1);

	$self->_add_map_bottom;
	$self->_add_html_bottom;

	return $self->_save(1);
}



=head1 METHOD create_imagefile

Creates just an image file.

Requires that the C<PATH> field be set (see L<CONSTRUCTOR>).

=cut

sub create_imagefile { my $self=shift;
	die  "Please supply an output path in your calling object \n" if not exists $self->{PATH};
	my ($name,$path,$suffix) = fileparse($self->{PATH},'(\.[^.]*)?$' );
	die  "Please supply a filepath with a dummy extension" if not defined $name;
	$self->{PATH} = $path.$name;
	$self->{IMGPATH} = $name.'.jpg';

	# Try to load the image into our object
	die "There is no option for a map of $self->{MAP}" if not exists $MAPS{$self->{MAP}};
	if (not -e $MAPS{$self->{MAP}}->{FILE}){
		warn "No map for $self->{MAP} at $MAPS{$self->{MAP}}->{FILE}: $!" ;
		return undef;
	}

	$self->_load_map or die "Could not read map from $MAPS{$self->{MAP}}->{FILE}: $!";

	$self->_populate;
	return $self->_save;
}




=head1 METHOD create_blob

Creates an image and return a reference to it's BLOB.

Requires that the C<PATH> field be set (see L<CONSTRUCTOR>).

=cut

sub create_blob { my $self=shift;
	if ($self->{PATH}){
		my ($name,$path,$suffix) = fileparse($self->{PATH},'(\.[^.]*)?$' );
		$self->{PATH} = $path.$name;
		$self->{IMGPATH} = $name.'.jpg';
	}

	# Try to load the image into our object
	if (not exists $MAPS{$self->{MAP}}){
		warn "There is no option for a map of $self->{MAP}";
		return undef;
	}
	if (not -e $MAPS{$self->{MAP}}->{FILE}){
		warn "No map for $self->{MAP}: $!" ;
		return undef;
	}
	if (not $self->_load_map){
		warn "Could not read map from $MAPS{$self->{MAP}}->{FILE}: $!";
		return undef;
	}

	$self->_populate;
	return \$self->{IM}->ImageToBlob();
}




#
# Just loads the map specified in the FILE field of MAP array
# field specified by the calling object's MAP field.
#
sub _load_map { my $self=shift;
	$self->{IM} = Image::Magick->new;
	my $err = $self->{IM}->Read($MAPS{$self->{MAP}}->{FILE});
	warn "Load map error: $err ($!)" if $err;
	return $err? undef:1;
}


=head1 METHOD all (base_path,base_url,title, blurb)

A method that produces all available maps, and an index page with thumbnails.

It accepts four arguments, a path at which files can be built,
a filename prefix (see L<"new">), a title, and blurb to add beneath the list of hyperlinks to the maps.

If no base path is supplied, the C<PATH> field is used.

An index page will be produced, linking to the following files for each map:

=over 4

m_C<MAPNAME>.jpg
m_C<MAPNAME>_t.jpg
m_C<MAPNAME>.html

=back

where MAPNAME is ... the name of the map.  The C<m_> prefix is held in the instance variable C<FNPREFIX>.
You may also wish to look at and adjust the instance variable C<CREATIONTXT>.

=cut

sub all { my ($caller, $fpath,$fnprefix,$title,$blurb) = (@_);
	die "'all' is now a method!" if not ref $caller;
	$fpath = $caller->{PATH} unless $fpath;
	die "Please supply a PATH directory (first argument)" if not defined $fpath;
	die "No such directory as suppiled: $fpath" unless -d $fpath;
	if ($fpath !~ /(\/|\\)$/){$fpath.="/";}
	$fnprefix = '' if not defined $fnprefix;
	if (not defined $title) {
		$title = "London.pm";
	}
	if (not defined $blurb) {
		$blurb =
		"These maps were created on ".(scalar localtime)." by ".__PACKAGE__;
		$blurb .=", available on <A href='http://search.cpan.org'>CPAN</A>, from data last updated on $DATE."
		."<P>Maps originate either from the CIA (who placed them in the public domain), or unknown sources (defunct personal pages on the web)."."<BR><HR><P><SMALL>Copyright (C) <A href='mailto:lGoddard\@CPAN.Org'>Lee Goddard</A> 2001 - available under the same terms as Perl itself</SMALL></P>";
	};
	my $self = bless {};
	$self->{HTML} = '';
	$self->_add_html_top("$title Maps Index");
	$self->{HTML} .= "<H1>$title Maps<HR></H1>\n";

	foreach my $map (keys %MAPS){
		$map =~ /(\w+)$/;
		die "Error making filename: didn't match regex" if not defined $1;
		$_ = __PACKAGE__;
		my $mapmaker = new (__PACKAGE__,{
			MAP=>$map,
			PATH=>$fpath.$fnprefix.$1,
			FONT=>$caller->{FONT},
			THUMB_SIZE => $caller->{THUMB_SIZE},
		});
		if ($mapmaker->create_html){
			my ($tx,$ty) = $self->_create_thumbnail($fpath.$fnprefix.$1, $caller->{THUMB_SIZE});
			$self->{HTML}.="<P><A href='$fnprefix$1.html'>";
			$self->{HTML}.="<IMG alt='$1' src='"
				.($self->{IMG_URI_PREFIX}?$self->{IMG_URI_PREFIX}:"")
				."$fnprefix$1_t.jpg' hspace='12' border='1' width='$tx' height='$ty'>";
			$self->{HTML}.="$1";
			$self->{HTML}.="</A></P>\n";
		}
	}

	$self->{HTML}.="<P>&nbsp;</P>";
	$self->{HTML}.=$blurb;
	$self->_add_html_bottom;
	open OUT,">$fpath$fnprefix"."index.html" or die "Couldn't open <$fpath$fnprefix"."index.html> for writing";
	print OUT $self->{HTML};
	close OUT;
}


#
# Private method _save
#
# Saves the product of the module: saves HTML if eponymous field has content.
#
# Accepts a file path at which to save the JPEG and HTML output.
# Supply a filename with any suffix: it will be ignored, and the JPEG image and HTML files will be given C<.jpg> and C<.html>
# suffixes respectively.
#
sub _save { my $self = shift;
	die  "Please call as a method." if not defined $self or not ref $self;
	local (*OUT);

	# Add text to image
	my $title = $self->{TITLE};
	my @textlines = split /(by.*)$/,$self->{CREATIONTXT};

	#my ($x,$y) = $self->{IM}->getBounds();
	my ($x,$y) = ($self->{IM}->Get('columns'),$self->{IM}->Get('rows'));

	$x = 5;
	$y = 17;

	my $err = $self->{IM}->Annotate(
		font=>$self->{FONT} || 'Arial.ttf',
		pointsize=>10, fill=>$self->{FILL}, text=>@textlines
	);
	warn $err if $err;

	# Save  the JPEG
	warn "Going to save image for $self->{MAP} as $self->{PATH}.jpg...\n" if $self->{chat};
	$err = $self->{IM}->Write($self->{PATH}.".jpg");
	die "Could not save map as $self->{PATH}.jpg" if $err;
	warn "Saved image\n" if $self->{chat};

	# Save the HTML
	if (defined $self->{HTML}){
		warn "Going to save HTML as $self->{PATH}.html...\n" if $self->{chat};
		open OUT, ">$self->{PATH}.html" or die "Could not save to <$self->{PATH}.html> ";
		print OUT $self->{HTML};
		close OUT;
		warn "Saved HTML\n" if $self->{chat};
	}
	warn "OK.\n" if $self->{chat};
	return 1;
}



# _populate
#
# Populates the current map: adds HTML if passed an argument
#
sub _populate { my ($self,$add_html) = (shift,shift);
	die  "Please call as a method." if not defined $self or not ref $self;
	warn "Populating the $self->{MAP} map.\n" if $self->{chat};

	# Add the anchor point?
	if (exists $self->{INCLUDEANCHOR}){
		my ($x,$y) = $self->_latlon_to_xy(
			$self->{MAP},
			$MAPS{$self->{MAP}}->{ANCHOR_LATLON}[0],
			$MAPS{$self->{MAP}}->{ANCHOR_LATLON}[1]
		);
		if (defined $x and defined $y){
			$self->_add_to_map(
				$x,$y,
				$MAPS{$self->{MAP}}->{ANCHOR_NAME},
				$MAPS{$self->{MAP}}->{ANCHOR_PLACE}
			);
		}
	}

	foreach my $pusson (keys %locations){
		warn "\tadding $pusson $locations{$pusson}->{PLACE}\n" if $self->{chat};
		my ($x,$y) = $self->_latlon_to_xy(
			$self->{MAP},$locations{$pusson}->{LAT},$locations{$pusson}->{LON}
		);
		if (defined $x and defined $y){
			$self->_add_to_map(
				$x,$y, $pusson, $locations{$pusson}->{PLACE}||"-", $add_html
			);
		}
	}
}



#
# Private method: _add_to_map (x,yx,name,place)
#
# Adds to the current image and to the HTML being created
# 	cf. $self->{IM}, $self->{HTML}.
#
# 	Accepts: x and y co-ordinates in the current map ($self->{MAP})
#			 name of entry
#			 optionally, name of place
#			 optional flag to create HTML for image map
#
sub _add_to_map { my ($self, $x,$y,$name,$place,$add_html) = (@_);
	# Add to the image
	die "Please call this METHOD with x,y, name,place!" if not defined $self or not defined $x or not defined $y or not defined $name; # Place is optional
	my $err;
	if ($x<0 or $x>$MAPS{$self->{MAP}}->{DIM}[0]
	or  $y<0 or $y>$MAPS{$self->{MAP}}->{DIM}[1]){
			warn "\t...out of the map bounds, not adding.\n" if $self->{chat};
			return undef;
	}

	$name  =~ s/'/\\'/g;
	$place =~ s/'/\\'/g;


	if (not exists $self->{FLOODFILL}){
		$err = $self->{IM}->Draw(
			primitive=>'circle',
			x	=> ($x-($MAPS{$self->{MAP}}->{SPOTSIZE}/2)),
			y	=> ($y-($MAPS{$self->{MAP}}->{SPOTSIZE}/2)),
			bordercolor => $self->{BORDER},
			fill 	=> 	($self->{KEYS2VALUES}
					? ($place)
					: $self->{FILL}
			),
			stroke	=> 	$self->{BORDER},
			strokewidth => "1",
			antialias	=>1,
			points=>$MAPS{$self->{MAP}}->{SPOTSIZE}
				.","
				.$MAPS{$self->{MAP}}->{SPOTSIZE}
				.","
				.$MAPS{$self->{MAP}}->{SPOTSIZE},
		);
	} else {
		$err = $self->{IM}->ColorFloodfill(
			x	=> ($x-($MAPS{$self->{MAP}}->{SPOTSIZE}/2)),
			y	=> ($y-($MAPS{$self->{MAP}}->{SPOTSIZE}/2)),
			fill 	=> 	($self->{KEYS2VALUES}
					? ($place)
					: $self->{FILL}
			),
#			bordercolor => ($self->{FLOODFILLBORDER}?$self->{FLOODFILLBORDER}:'#000000')
		);
	}

	warn "Could not draw at $x,$y: $err ..." if $err and $self->{chat};


	# Add to the HTML
	if ($add_html){
		$self->{HTML} .= "<area "
			. "shape='circle' coords='"
			.($x+($MAPS{$self->{MAP}}->{SPOTSIZE}/2))
			.","
			.(1+$y+($MAPS{$self->{MAP}}->{SPOTSIZE}/2))
			.",$MAPS{$self->{MAP}}->{SPOTSIZE}' "
			. "alt='"
				.($place!~/^#/? "$name ($place)" : $name)
			."' title='$name";
		$self->{HTML} .= " ($place)" if defined $place;
		$self->{HTML} .= "' href='javascript:alert(\"$name\\n"
		.($place!~/^#/? " ($place)" : "")
		."\")' target='_self'>\n";
	}
	warn "\t...adding to map at $x,$y\n" if $self->{chat};
}



#
# Private methods: _add_html_top, _add_map_top, _add_map_bottom, _add_html_bottom
#
# Call before adding elements to the map, to initiate up the HTML image map, and include the HTML iamge.
# Optional second argument used as HTML TITLE element contents when no $self->{MAP} has been defined.
#
sub _add_html_top { my $self=shift;
	$self->{HTML} =	"<html>\n<head>\n\t<title>"
	.($self->{TITLE}?$self->{TITLE}:"")
	."</title>
	<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>";
	if (exists $self->{CSS} and defined $self->{CSS}){
		$self->{HTML} .= "
		<style type='text/css'>
		$self->{CSS}
		</style>
		";
	}
	$self->{HTML}.="\n</head>\n<body>\n"
	.($self->{TITLE}?"<h1>$self->{TITLE}</h1>\n":"");
}


sub _add_map_top { my $self = shift;
	my ($x,$y) = ($self->{IM}->Get('columns'),$self->{IM}->Get('rows'));
	$self->{HTML}
	.="<div align='center'>\n"
	. "<img alt='' src='$self->{IMG_URI_PREFIX}$self->{IMGPATH}' width='$x' height='$y' usemap='#$self->{MAP}' border='1'>\n"
	. "<map name='$self->{MAP}'>\n\n";
}


sub _add_map_bottom { my $self = shift;
	$self->{HTML} .= "\n</map>\n</div>\n";
}


sub _add_html_bottom { my $self = shift;
	$self->{HTML} .= "$self->{EXTRA_HTML}\n</body></html>\n\n";
}








#
# METHOD: &_latlon_to_xy (map,latitude,longitude)
#
# Map latitude and longitude to pixel on $MAPS{$map}
#
#	Accepts: name of map to map onto (key to our %MAPS)
#			 latitude, longitude
#	Returns: the new co-ords on the map passed
#
#	As it took me some time to get around this,
#	I've not optimized the code for fear. But hey,
#	at least you get to see my workings, as they
#	said in 'O' level Maths....
#
sub _latlon_to_xy { my ($self,$map,$lat,$lon) = (@_);
	if ($lat>90) {warn "\t...can't add, incomplete/missing location details ($lat,$lon).\n" if $self->{chat}; return undef;}
	# Lat, Lon in miles
	my $m_lat = $lat - @{$MAPS{$map}->{ANCHOR_LATLON}}[0];
	my $m_lon = $lon - @{$MAPS{$map}->{ANCHOR_LATLON}}[1];
	$m_lat = $m_lat * $LAT[int $lat];
	$m_lon = $m_lon * 69;
#	my $loni = int $lon;
#	$loni = -$loni if $loni<0;
#	if ($loni>90){ $loni = 90 - ($loni-90); }
#	$m_lon = $m_lon * ($LON[$loni]);

	# Invert to plot on map
	$m_lat = -$m_lat;
	my $px_lat = $m_lat * $MAPS{$map}->{ONEMILE};
	my $px_lon = $m_lon * $MAPS{$map}->{ONEMILE};
	# As zero degrees latitude is the equator, lat (y) is plotted
	# from the bottom of the image - this must be inverted!
	$px_lat += @{$MAPS{$map}->{ANCHOR_PIXELS}}[1];
	$px_lon += @{$MAPS{$map}->{ANCHOR_PIXELS}}[0];
	# Return in x,y order
	return (int $px_lon, int $px_lat);
}



=head1 METHOD load_db

A method that loads a "database" hash from the specified path.

Returns a true value on success, C<undef> on failure.

=cut

sub load_db { my ($self,$dbname) = (shift,shift);
	local *IN;
	warn "Loading DB from $dbname...\n" if $self->{chat};
	if (not open IN, $dbname){
		warn "Couldn't open the configuration file <$dbname> for reading";
		return undef;
	}
	read IN, $_, -s IN;
	close IN;
	my $VAR1; # will come from evaluating the file produced by Data::Dumper.
	eval ($_);
	warn $@ if $@;
	%locations = %{$VAR1};
	warn "OK.\n"  if $self->{chat};
	return 1;
}


=head1 METHOD save_db

A method that saves the currently loaded "database" hash to the filename specified as the only arguemnt.

Note tha tyou may want to load a db before saving.

Returns nothing, but does C<die> on failure.

=cut

# Simply uses C<Data::Dumper> to dump the hash that stores the user values

sub save_db { my ($self,$dbname) = (shift,shift);
	local *OUT;
	open OUT,">$dbname" or die "Couldn't open the configuration file <$dbname> for writing";
	print OUT Dumper(\%locations);
	close OUT;
}


=head1 METHOD add_entry

A method that accepts: $name, $latitude, $longitude, maybe $place_or_colour

If an entry already exists for $name, will return C<undef> unless
the global scalar C<$ADDENTRY> is set to it's default value of C<MULTIPLE>,
in which case $name will be appended with the time.

Does not save them to file - you must do that manually (L<"METHOD save_db">), but
note that you may wish to load the db before adding to it and saving.

Incidentaly returns a reference to the new key.

See also L<ADDING MAPS>.

=cut

sub add_entry { my ($self, $name, $lat,$lon,$place) = (@_);
	eval('use WWW::MapBlast 0.02;');
	die "Can't add_entry without \$name, \$lat, \$lon, and maybe \$place_or_colour"
		unless (defined $name and defined $lat and defined $lon);

	$lat = 11111111 if not defined $lat or $lat eq '';
	$lon = 11111111 if not defined $lon or $lon eq '';
	if (not defined $place or $place eq ''){
		$place = $name
	}

	if (exists $locations{$name} ){
		if ($ADDENTRY ne 'MULTIPLE'){
			warn "Not adding duplicate entry for $name at $lat, $lon.\n" if $self->{chat};
			return undef;
		}
		$name .= " (".(scalar localtime).")";	# grep?
	}

	$locations{$name} = {
			PLACE=>$place,
			LAT=>$lat,
			LON=>$lon,
	};

	return \$locations{$name};
}



=head1 &remove_entry

A subroutine, not a method, that accepts the name field of the entry in the db, and returns
C<1> on success, C<undef> if no such entry exists.

=cut

sub remove_entry { my ($name) = (shift);
	return undef if not exists $locations{$name};
	delete $locations{$name};
	return 1;
}


#
# METHOD _create_thumbnail (path to image, size of longest side)
# Creates and saves a thumbnail of the specified image.
# Returns the name of the image
#
sub _create_thumbnail { my ($self,$path,$size) = (shift,shift,shift);
	eval ("use Image::Thumbnail 0.011");
	die $@ if $@;
	# Load your source image
	die "Passed no filepath to create_thumbnail " if not defined $path;
	$path .= '.jpg';
	die "Passed bad filepath to create_thumbnail <$path>: $!" if not defined $path or not -e $path;
	$size = $self->{THUMB_SIZE} if not defined $size;
	$size = 75 if not defined $size;

	# Create the thumbnail from it, where the biggest side is 50 px
	my $outpath = $path;
	$outpath =~ s/\.jpg$/_t.jpg/;
	my $thumb = Image::Thumbnail->new(
		inputpath => $path,
		size => $size,
		outputpath => $outpath,
		CHAT => $self->{chat},
		create => 1,
	);
	return ($thumb->{x},$thumb->{y});
}


#
# Make @LAT and @LON to get length of a degree
#
sub _make_latlon {
	LAT:{
		my $i = 0;
		foreach (@_LAT){
			for my $j (0..4){
				last LAT if $i+$j>90;
				$LAT[$i+$j] = $_;
			}
			$i += 5;
		}
	}

	LON:{
		my $i = 0;
		foreach (@_LON){
			for my $j (0..4){
				last LON if $i+$j>90;
				$LON[$i+$j] = $_;
			}
			$i += 5;
		}
	}
}

=head1 ADDING MAPS

A future version may allow you to pass map data to the constructor.
In the meantime, adding maps is not in itself a big deal, perl-wise. Add a new key to
the C<%MAPS> hash, with the value of an anonymous hash with the content listed below.

=over 4

=item FILE

scalar file name of Mercator Projection map.

=item DIM

anon array of dimensions of map in pixels [x,y].
You could create DIM on the fly using C<Image::Magick>, but there's probably no point, as you're
almost certainly going to have to edit the map to align it with longitude and latitude
(if you find a stock of public-domain maps that are already aligned, please drop
the author a line).

=item SPOTSIZE

scalar number for the size of the map-marker spots, in pixels

=item ANCHOR_PIXELS

anon array of the pixel location of the arbitrary anchor pont [x,y]

=item ANCHOR_LATLON

anon array of the latitude/longitude of the arbitrary anchor pont [x,y]

=item ANCHOR_NAME

scalar name of the anchor, when marked on map

=item ANCHOR_PLACE

scalar place name of the anchor, when marked on map

=item ONEMILE

scalar representation of 1 mile in pixels

=back

=head1 NOTES ON LATITUDE AND LONGITUDE

After L<http://www.mapblast.com/myblast/helpFaq.mb#2|http://www.mapblast.com/myblast/helpFaq.mb#2>:

=over 4

Zero degrees latitude is the equator, with the North pole at 90 degrees latitude and the South pole at -90 degrees latitude.
one degree is approximately 69 miles. Greenwich, England is at 51.466 degrees north of the equator.

Zero degrees longitude goes through Greenwich, England.
Again, Each 69 miles from this meridian represents approximately 1 degree of longitude.
East/West is plus/minus respectively.

=back

Actually, latitude and longitude vary depending upon the degree in hand:
see L<The Compton Encyclopdedia|http://www.comptons.com/encyclopedia/ARTICLES/0100/01054720_A.html#P17> for more information.

=head1 CAVEATS

The exmaple map, london_postcodes.jpg, is inaccurate.

Whilst degrees of latitude are accurate to two decimal places, Degrees of
longitude are taken to be 69 miles: this isn't quite right - see
L<NOTES ON LATITUDE AND LONGITUDE>. This will be adjusted in a later version.

All images must be JPEGs - PNG or other support could easily be added.

=head1 REVSIONS

=over 4

=item 1.2

Corrected a slight mis-positioning of points.

Replaced GD with Image::Magick as I was seeing terrible JPEG output
with GD.

Replaced support for non-maintained C<Image::GD::Thumbnail> with
C<Image::Thumbnail>; evaluate a require of this at run time rather
than using the apparently still shakey pragmas.

Added methods to create just images and to return references to image blobs.

=item 1.0

Don't remember.

=item 0.25

Clean IMG path and double-header bugs

=item 0.23

Added more documentation; escaping of href text

=item 0.22

Added thumbnail images to index page

=back

=head1 SEE ALSO

perl(1); L<Image::Magick|http://www.ImageMagick.org> (C<http://www.ImageMagick.org>); L<File::Basename>; L<Acme::Pony>; L<Data::Dumper>; L<WWW::MapBlast>; L<Image::Thumbnail>

=head1 THANKS

Thanks to the London.pm group for their test data and insipration, to Leon for his patience with all that mess on the list, to Philip Newton for his frankly amazing knowledge of international postcodes.

Thanks also to the CIA, L<About.com|http://wwww.about.com>, L<The University of Texas|http://www.lib.utexas.edu/maps>,
and L<The Ordnance Survey|http://www.ordsvy.gov.uk/freegb/index.htm#maps>
for their public-domain maps.

=head1 AUTHOR

Lee Goddard <lgoddard -at- cpan -point- org>

=head1 COPYRIGHT

Copyright (C) Lee Goddard, 2001.  All Rights Reserved.

This module is supplied and may be used under the same terms as Perl itself.

The public domain maps provided with this distribution are the property of their respective copyright holders.

=cut

1;

__END__

matlab:

axesm('mapprojection','mercator'); displaym( worldhi(mask));