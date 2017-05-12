package Image::WordCloud;

use 5.008;

use strict;
use warnings;

use Image::WordCloud::StopWords::EN qw(%STOP_WORDS);
use Carp qw(carp croak confess);
use Params::Validate qw(:all);
use List::Util qw(sum shuffle);
use File::Spec;
use File::ShareDir qw(:ALL);
use File::Find::Rule;
use Encode;
use GD;
use GD::Text::Align;
use Color::Scheme;
use Math::PlanePath::TheodorusSpiral;

our $VERSION = '0.03';

$ENV{IWC_DEBUG} = 0 if ! defined $ENV{IWC_DEBUG} || ! $ENV{IWC_DEBUG};

=head1 NAME

Image::WordCloud - Create word cloud images

=head1 SYNOPSIS

	use Image::WordCloud;
	use File::Slurp;
	
	my $wc = Image::WordCloud->new();
	
	# Add the Gettysburg Address
	my $text = read_file('script/gettysburg.txt');
	$wc->words($text);
	
	# Create the word cloud as a GD image
	my $gd = $wc->cloud();
	
	open(my $fh, '>', 'gettysburg.png');
		binmode $fh;
		print $fh $gd->png();
	close($fh);
	
	# See examples/gettysburg.png for how the created image looks.
	# script/gettysburg.pl will create it
	
	# The calls can also be chained like so:
	my $text = read_file('script/gettysburg.txt');
	my $gd = Image::WordCloud->new()
		->words($text)
		->cloud();

Create "word cloud" images from a set of specified words, similar to http://wordle.net.
Font size indicates the frequency with which a word is used.

Colors are generated randomly using L<Color::Scheme>. Fonts can be specified or chosen randomly.

=head1 FUNCTIONS

=head2 new( ... )

Accepts a number of parameters to alter the image look.

=over 4

=item * image_size => [$x, $y]

Sets the size of the image in pixels, accepts an arrayref. Defaults to [400, 400].

NOTE: Non-square images currently can look a little squirrely due to how Math::TheodorusSpiral fills a rectangle.

=item * word_count => $count

Number of words to show on the image. Defaults to 70.

=item * prune_boring => <1,0>

Prune "boring", or "stop" words. This module currently only supports English stop words (like 'the', 'a', 'and', 'but').
The full list is in L<Image::WordCloud::StopWords::EN>

Defaults to true.

=item * font => $name

Name of font to use. This is passed directly to L<GD::Text::Align> so it can either be a string like 'arial', or
a full path. However in order for non-path font names to work, L<GD> needs an environment variable like FONT_PATH
or FONT_TT_PATH to be set, or C<font_path> can be used to set it manually.

=item * font_path => $path_to_fonts

Set where your font .ttf files are located. If this is not specified, the path of this module's distribution
directory will be used via L<File::ShareDir>. Currently this module comes bundled with one set of fonts.

=item * background => [$r, $g, $b]

Takes an arrayref defining the background color to use. Defaults to [40, 40, 40]

=item * border_padding => <$pixels | $percent>

Padding to leave clear around the edges of the image, either in pixels or a percent with '%' sign. Defaults to '5%'

	my $wc = Image::WordCloud->new(border_padding => 20);
	my $wc = Image::WordCloud->new(border_padding => '25%');

Please note that this affects the speed with which this module can fit words into the image. In my tests on
the text of the Declaration of Independence, bumping the percentage by 5% increments progressed like so:

	0%:  15.25s
	5%:  21.50s
	10%: 30.00s
	15%: 63.6s avg

=back

=cut

#'

sub new {
    my $proto = shift;
		
    my %opts = validate(@_, {
			image_size     => { type => ARRAYREF | UNDEF, 		optional => 1, default => [400, 400] },
			word_count     => { type => SCALAR | UNDEF,   		optional => 1, default => 70 },
			prune_boring   => { type => SCALAR | UNDEF,   		optional => 1, default => 1 },
			font           => { type => SCALAR | UNDEF,   		optional => 1 },
			font_file      => { type => SCALAR | UNDEF,   		optional => 1 },
			font_path      => { type => SCALAR | UNDEF,   		optional => 1 },
			background     => { type => ARRAYREF,         		optional => 1, default => [40, 40, 40] },
			border_padding => { type => SCALAR, 							optional => 1, regex => qr/^\d+\%?$/, default => '5%' },
    });
    
    # ***TODO: Figure out how many words to use based on image size?
		
		# Make sure the font file exists if it is specified
		if ($opts{'font_file'}) {
			unless (-f $opts{'font_file'}) {
				carp sprintf "Specified font file '%s' not found", $opts{'font_file'};
			}
		}
		
		# Make sure the font path exists if it is specified
		if ($opts{'font_path'}) {
			unless (-d $opts{'font_path'}) {
				carp sprintf "Specified font path '%s' not found", $opts{'font_path'};
			}
		}
		
		# Otherwise, try using ./share/fonts (so testing can be done)
		if (! $opts{'font_path'}) {
			my $local_font_path = File::Spec->catdir(".", "share", "fonts");
			unless (-d $local_font_path) {
				#carp sprintf "Local font path '%s' not found", $local_font_path;
			}
			
			$opts{'font_path'} = $local_font_path;
		}
		
		# If we still haven't found a font path, find the font path with File::ShareDir
		if (! $opts{'font_path'}) {
			my $font_path;
			eval {
				$font_path = File::Spec->catdir(dist_dir('Image-WordCloud'), "fonts");
			};
			if ($@) {
				#carp "Font path for dist 'Image-WordCloud' could not be found";
			}
			else {
				$opts{'font_path'} = $font_path;
			}
		}
		
    my $class = ref( $proto ) || $proto;
    my $self = { #Will need to allow for params passed to constructor
			words					 => {},
			image_size		 => $opts{'image_size'},
			word_count		 => $opts{'word_count'},
			prune_boring	 => $opts{'prune_boring'},
			font					 => $opts{'font'}      || "",
			font_path			 => $opts{'font_path'} || "",
			font_file			 => $opts{'font_file'} || "",
			background		 => $opts{'background'},
			border_padding => $opts{'border_padding'},
    };
    bless($self, $class);
    
    # Make sure we have a usable font file or font path
		unless (-f $self->{'font_file'} || -d $self->{'font_path'}) {
			carp sprintf "No usable font path or font file found, only fonts available will be from libgd, which suck";
		}
		# If a font_file is specified, use that as the only font
		elsif (-f $self->{'font_file'}) {
			$self->{fonts} = $self->{'font_file'};
		}
		# Otherwise if no font_file was specified and we have a font path, read in all the fonts from font_path
		elsif (! -f $self->{'font_file'} && -d $self->{'font_path'}) {
			my @fonts = File::Find::Rule->new()
										->extras({ untaint => 1})
										->file()
										->name('*.ttf')
										->in( $self->{'font_path'} );
			
			$self->{fonts} = \@fonts;
		}
		
		# Set the font path for GD::Text::* objects, if we have one to use
		if (-d $self->{'font_path'}) {
			GD::Text->font_path( $self->{'font_path'} );
		}

    return $self;
}

=head2 words(\%words_to_use | \@words | @words_to_use | $words)

Takes either a hashref, arrayref, array or string.

If the argument is a hashref, keys are the words, values are their count. No further processing is done (we assume you've done it on your own).

If the argument is an array, arrayref, or string, the words are parsed to remove non-word characters and turn them lower-case.

=cut

#'

sub words {
	my $self = shift;
	
	#my @opts = validate_pos(@_,
  #	{ type => HASHREF | ARRAYREF, optional => 1 }, # \%words
  #);
  
  # Return words if no arguments are specified
  if (scalar(@_) == 0) { return $self->{words}; }
  
  my $arg1 = $_[0];
  
  my %words = ();
  
 	# More than one argument, assume we're being passed a list of words
  if (scalar(@_) > 1) {
  	my @words = @_;
  	
  	# Strip non-word characters, lc() each word and build the counts
  	foreach my $word (map { lc } @words) {
  		$word = Encode::decode('iso-8859-1', $word);
			$word =~ s/\W//o;
			$words{ $word }++;
		}
  }
  else {
  	# Argument is a hashref, just push it straight into %words
	  if (ref($arg1) eq 'HASH') {
	  	%words = %{ $arg1 };
		}
		# Argument is an arrayref
		elsif (ref($arg1) eq 'ARRAY') {
			my @words = @$arg1;
			
			# Strip non-word characters, lc() each word and build the counts
			foreach my $word (map { lc } @words) {
				$word = Encode::decode('iso-8859-1', $word);
				$word =~ s/\W//o;
				$words{ $word }++;
			}
		}
		# Argument is a scalar, assume it's a string of words
		else {
			my $words = $arg1;
			$words = Encode::decode('iso-8859-1', $words);
			
			while ($words =~ /(?<!<)\b([\w\-']+)\b(?!>)/g) { #' <-- so UltraEdit doesnt fubar syntax highliting
				my $word = lc($1);
				$word =~ s/\W//o;
				$words{ $word }++;
			}
		}
  }
  
  # Blank out the current word list;
  $self->{words} = {};
  
  $self->_prune_stop_words(\%words) if $self->{prune_boring};
  
  # Sort the words by count and let N number of words through, based on $self->{word_count}
  my $word_count = 1;
  foreach my $word (map { lc } sort { $words{$b} <=> $words{$a} } keys %words) {
  	last if $word_count > $self->{word_count};
  	
  	my $count = $words{$word};
  	
  	if ($word_count == 1) {
  		$self->{max_count} = $count;
  	}
  	
  	# Add this word to our list of words
  	$self->{words}->{$word} = $count;
  	
  	push(@{ $self->{word_list} }, {
  		word  => $word,
  		count => $count
  	});
  	
  	$word_count++;
  }
  
  $self->{words_changed} = 1;
  
  return $self;
}

=head2 cloud()

Make the word cloud. Returns a L<GD::Image>.

	my $gd = Image::WordCloud->new()->words(qw/some words etc/)->cloud();
	
	# Spit out the wordlcoud as a PNG
	$gd->png;
	
	# ... or a jpeg
	$gd->jpg;
	
	# Get the dimensions
	$gd->width;
	$gd->height;
	
	# Or anything else you can do with a GD::Image object

=cut

sub cloud {
	my $self = shift;
	
	# Set the font path for GD::Text::* objects, if we have one to use
	#if (-d $self->{'font_path'}) {
	#	GD::Text->font_path( $self->{'font_path'} );
	#}
	
	# Create the image object 
	my $gd = GD::Image->new($self->width, $self->height, 1); # Adding the 3rd argument (for truecolor) borks the background, it defaults to black.
	
	# Center coordinates of this iamge
	my $center_x = $gd->width  / 2;
	my $center_y = $gd->height / 2;
	
	my $background = $gd->colorAllocate( @{$self->{background}}[0,1,2] ); # Background color
	
	# Fill completely with background color
	$gd->filledRectangle(0, 0, $gd->width, $gd->height, $background);
	
	my $white = $gd->colorAllocate(255, 255, 255);
	my $black = $gd->colorAllocate(0, 0, 0);
	
	my @rand_colors = $self->_random_colors();

	my @palette = ();
	foreach my $c (@rand_colors) {
		my $newc = $gd->colorAllocate($c->[0], $c->[1], $c->[2]);
		push @palette, $newc;
	}
	
	# make the background interlaced (***TODO: why?)
  $gd->interlaced('true');
	
	# Array of GD::Text::Align objects that we will move around and then draw
	my @texts = ();
	
	# Get the bounds of the image
	my ($left_bound, $top_bound, $right_bound, $bottom_bound) = $self->_image_bounds();
	
	# Max an min font sizes in points
	my $max_points = $self->_max_font_size();
	#my $min_points = $self->_pixels_to_points(($bottom_bound - $top_bound) * 0.0175); # 0.02625;
	my $min_points = $self->_min_font_size();
	
	# Get the view scaling based on the area we can fill and what all the areas of
	#   the words at their scaled font sizes would produce
	my $view_scaling = $self->_view_scaling();
	
	# Scaling modifier for font sizes
	my $max_count = $self->{max_count};
	my $scaling = $max_points / $max_count;
	
	# For each word we have
	my @areas = ();
	#my @drawn_texts = ();
	
	# List of the bounding boxes of each text object. Each element is an arrayref
	# containing:
	#   1. Upper left x coordinate
	#   2. Upper left y coordinate
	#   3. Bounding box width
	#   4. Bounding box height
	my @bboxes = ();
	
	my $loop = 1;
	
	# Get a list of words sorted by frequency
	my @word_keys = sort { $self->{words}->{$b} <=> $self->{words}->{$a} } keys %{ $self->{words} };
	
	# Get the word scaling factors (higher frequency == bigger size
	my $scalings = $self->_word_scalings();
	
	# And then create the font sizes based on the scaling * the maximum font size
	
	#   Get the initial font sizes
	my $word_sizes = $self->_word_font_sizes();
	
	#   Scale the sizes by the view scaling
	my %word_sizes = map { $_ => $word_sizes->{$_} * $view_scaling } keys %$word_sizes;
	
	# Get the font size for each word using the Fibonacci sequence
#	my %word_sizes = ();
#	my $sloop = 0;
#	my $fib_counter = 1;
#	my $cur_size;
#	foreach my $word (@word_keys) {
#		if ($sloop == 0) {
#			my $term = Math::Fibonacci::term($fib_counter);
#			
#			$cur_size = (1 / $fib_counter * $max_points);
#			
#			$sloop = $term;
#			
#			$fib_counter++;
#		}
#		
#		$word_sizes{ $word } = $cur_size;
#		
#		$sloop--;
#	}
	
	foreach my $word ( shift @word_keys, shuffle @word_keys ) {
		my $count = $self->{words}->{$word};
		
		my $text = GD::Text::Align->new($gd);
		
		# Use a random color
		my $color = $palette[ rand @palette ];
		$text->set(color => $color);
		
		# Either use the specified font file...
		my $font = "";
		if ($self->{'font_file'}) {
			$font = $self->{'font_file'};
		}
		# Or the specified font
		elsif ($self->{'font'} && -d $self->{'font_path'}) {
			$font = $self->{'font'};
		}
		# ...or use a random font
		elsif (scalar @{$self->{'fonts'}} > 0) {
			$font = $self->{'fonts'}->[ rand @{$self->{'fonts'}} ];
				unless (-f $font) { carp "Font file '$font' not found"; }
		}
		
		my $size = $word_sizes{ $word };
		
		#my $size = $count * $scaling;
		#my $size = (1.75 / $loop) * $max_points;
		
		$size = $max_points if $size > $max_points;
		$size = $min_points if $size < $min_points;
		
		$text->set_font($font, $size);
		
		# Set the text to this word
		$text->set_text($word);
		
		push(@texts, $text);
		
		my ($w, $h) = $text->get('width', 'height');
		
		push(@areas, $w * $h);
		
		# Position to place the word in
		my ($x, $y);
		
		# Place the first word in the center of the screen
		if ($loop == 1) {
			$x = $center_x - ($w / 2);
			$y = $center_y + ($h / 4); # I haven't done the math see why dividing the height by 4 works, but it does
			
			# Move the image center around a little
			#$x += $self->_random_int_between($gd->width * .1 * -1, $gd->width * .1 );
			#$y += $self->_random_int_between($gd->height * .1 * -1, $gd->height * .1);
			
			# Move the first word around a little, but not TOO much!
			($x, $y) = $self->_init_coordinates($gd, $text, $x, $y);
		}
		else {
			# Get a random place to draw the text
			#   1. The text is drawn starting at its lower left corner
			#	  2. So we need to push the y value by the height of the text, but keep it less than the image height
			#   3. Keep a padding of 5px around the edges of the image
			#$y = $self->_random_int_between($h, $gd->height - 5);
			#$x = $self->_random_int_between(5,  $gd->width - $w - 5);
			
			# While this text collides with any of the other placed texts, 
			#   move it in an enlarging spiral around the image 
			
			# Make a spiral
			my $path = Math::PlanePath::TheodorusSpiral->new;
			
			# Get the boundary width and height for random initial placement (which is bounds of the first (biggest) string)
			my ($rand_bound_w, $rand_bound_h) = @{$bboxes[0]}[2,3];
			
			# Get the initial starting point
			my ($this_x, $this_y) = $self->_new_coordinates($gd, $path, 1, $rand_bound_w, $rand_bound_h);
			
			my $collision = 1;
			my $col_iter = 1; # Iterator to pass to M::P::TheodorusSpiral get new X,Y coords
			
			# Within an area of 250k pixels, it seems to work okay.
			#my $col_iter_increment = int($self->width * $self->height * 0.00002); # Increment to increase $col_iter by on each loop
			my $col_iter_increment = 1;
			$col_iter_increment = 1 if $col_iter_increment < 1; # Move it at least ONE iteration
			
			while ($collision) {
				# New text's coords and width/height
				# (x1,y1) lower left corner
		    # (x2,y2) lower right corner
			  # (x3,y3) upper right corner
		    # (x4,y4) upper left corner
				my ($b_x, $b_y, $b_x2, $b_y2) = ( $text->bounding_box($this_x, $this_y) )[6,7,2,3];
				my ($b_w, $b_h) = ($b_x2 - $b_x, $b_y2 - $b_y);
				
				foreach my $b (@bboxes) {
				    my ($a_x, $a_y, $a_w, $a_h) = @$b;
				    
				    # Upper left to lower right
				    if ($self->_detect_collision(
				    			$a_x, $a_y, $a_w, $a_h,
				    			$b_x, $b_y, $b_w, $b_h)) {
				    	
				    	$collision = 1;
				    	last;
				    }
				    else {
				    	$collision = 0;
				    }
				}
				last if $collision == 0;
				
				# TESTING:
				if ($col_iter % 1 == 0 && $ENV{IWC_DEBUG} >= 2) {
					my $hue = $col_iter;
					
				  my ($r,$g,$b) = $self->_hex2rgb( (Color::Scheme->new->from_hue($hue)->colors())[0] ); # hues can be over 360, they just wrap around the wheel
					my $c = $gd->colorAllocate($r,$g,$b);
										
					#$gd->filledRectangle($this_x, $this_y, $this_x + 1, $this_y + 1, $c);
					#$gd->string(gdGiantFont, $this_x, $this_y, $col_iter, $c);
					
					#$gd->setPixel($this_x, $this_y, $c);
					
					#my @bo = $text->bounding_box($this_x, $this_y, 0);
					#$self->_stroke_bbox($gd, $c, @bo);
					
					$gd->colorDeallocate($c);
				}
				
				$col_iter += $col_iter_increment;
				
				# Move text
				my $new_loc  = 0;
				while (! $new_loc) {
					($this_x, $this_y) = $self->_new_coordinates($gd, $path, $col_iter, $rand_bound_w, $rand_bound_h);
					
					my ($newx, $newy, $newx2, $newy2) = ( $text->bounding_box($this_x, $this_y) )[6,7,2,3];
					
					if ($newx < $left_bound || $newx2 > $right_bound ||
							$newy < $top_bound  || $newy2 > $bottom_bound) {
								
							#carp sprintf "New coordinates outside of image: (%s, %s), (%s, %s)", $newx, $newy, $newx2, $newy2;
							$col_iter += $col_iter_increment;
							if ($col_iter > 10_000) {
								carp sprintf "New coordinates for '%s' outside of image: (%s, %s)", $text->get('text'), $newx, $newy if $ENV{IWC_DEBUG};
								last;
							}
					}
					else {
							$new_loc = 1;
					}
				}
				
				# Center the image
				#$this_x -= $text->get('width') / 2;
				#$this_y -= $text->get('height') / 2;
				
				# Center the spiral
				#if (! $centered) {
				#	$this_x += $center_x;
				#	$this_y += $center_y;
				#}
			}
			
			# test draw
			#my @bounding = $text->bounding_box($this_x, $this_y, 0);
			#$self->_stroke_bbox($gd, $white, @bounding);
			
			# Backtrack the coordinates towards the center
			($this_x, $this_y) = $self->_backtrack_coordinates($text, \@bboxes, $this_x, $this_y, $gd);
			
			$x = $this_x;
			$y = $this_y;
		}
		
		my @bounding = $text->draw($x, $y, 0);
		#$self->_stroke_bbox($gd, undef, @bounding);
		
		my @rect = ($bounding[6], $bounding[7], $bounding[2] - $bounding[6], $bounding[3] - $bounding[7]);
		push(@bboxes, \@rect);
		
		$loop++;
	}
	
	my $total_area = sum @areas;
	
	$self->{words_changed} = 0; # reset the words changed flag
	
	# Return the image as PNG content
	return $gd;
}

# Return the bounds of the image
sub _image_bounds {
	my $self = shift;
	
	my ($left_bound, $top_bound, $right_bound, $bottom_bound);
	
	# Make the boundaries for the words
	my $pad = $self->{'border_padding'};
	
	# Handle zero-padding
	if ($pad =~ /^0\%?$/) {
		return (0, 0, $self->width, $self->height);
	}
	
	# Pad width a percentage of the image size
	if ($pad =~ /^\d+\%$/) {
		my ($percentage) = $pad =~ /(\d+)/;
		$percentage = $percentage / 100;
		
		$left_bound  = 0 + $self->width  * $percentage;
		$top_bound   = 0 + $self->height * $percentage;
		$right_bound  = $self->width -  $self->width  * $percentage;
		$bottom_bound = $self->height - $self->height * $percentage;
	}
	else {
		$left_bound  = 0 + $self->{'border_padding'};
		$top_bound   = 0 + $self->{'border_padding'};
		$right_bound  = $self->width  - $self->{'border_padding'};
		$bottom_bound = $self->height - $self->{'border_padding'};
	}
	
	return ($left_bound, $top_bound, $right_bound, $bottom_bound);
}

# Return the width and height of the image bounds
sub _image_bounds_width_height() {
	my $self = shift;
	
	my ($left_bound, $top_bound, $right_bound, $bottom_bound) = $self->_image_bounds();
	
	my $w = $right_bound - $left_bound;
	my $h = $bottom_bound - $top_bound;
	
	return ($w, $h);
}

# Given an initial starting point, move 
sub _init_coordinates {
	my $self = shift;
	my ($gd, $text, $x, $y) = @_;
	
	croak "No X coordinate specified" if ! defined $x;
	croak "No Y coordinate specified" if ! defined $y;
	
	# Make the boundaries for the words
	my ($left_bound, $top_bound, $right_bound, $bottom_bound) = $self->_image_bounds();
	
	my $fits = 0;
	my $c = 0;
	while (! $fits) {
		# Re-initialize the coords
		my $try_x = $x;
		my $try_y = $y;
		
		# Move the x,y coords around a little (width 10% of the image's dimensions so we stay mostly centered)
		$try_x += $self->_random_int_between($gd->width * .1 * -1, $gd->width * .1 );
		$try_y += $self->_random_int_between($gd->height * .1 * -1, $gd->height * .1);
		
		# Make sure the new coordinates aren't outside the bounds of the image!
		my ($newx, $newy, $newx2, $newy2) = ( $text->bounding_box($try_x, $try_y) )[6,7,2,3];
		
		if ($newx < $left_bound || $newx2 > $right_bound ||
				$newy < $top_bound  || $newy2 > $bottom_bound) {
				
				$fits = 0;
		}
		else {
				$x = $try_x;
				$y = $try_y;
				
				$fits = 1;
		}
		
		# Only try 50 times
		$c++;
		
		if ($c > 50) {
			#carp "Tried over 50 times to fit a word";
			last;
		}
	}
	
	return ($x, $y);
}

# Return new coordinates ($x, $y) that are no more than $bound_x or $bound_y digits away from the center of GD image $gd
sub _new_coordinates {
	my $self = shift;
	
	#my @opts = validate_pos(@_,
  #	{ isa => 'GD::Image' },
  #	{ isa => 'Math::PlanePath::TheodorusSpiral' },
  #	{ type => SCALAR, regex => qr/^[-+]?\d+$/, },
  #	{ type => SCALAR, regex => qr/^\d+|\d+\.\d+$/, },
  #	{ type => SCALAR, regex => qr/^\d+|\d+\.\d+$/, },
  #);
  
  my @opts = @_;
	
	my ($gd, $path, $iteration, $bound_x, $bound_y) = @opts;
	
	my ($x, $y) = map { int } $path->n_to_xy($iteration * 100); # use 'int' because it returns fractional coordinates
	
	# Move the center of this word within 50% of the area of the first word's bounding box
	$x += $self->_random_int_between($bound_x * -1 * .25, $bound_x * .25);
	$y += $self->_random_int_between($bound_y * -1 * .25, $bound_y * .25);
					
	$x += $gd->width / 2;
	$y += $gd->height / 2;
	
	return ($x, $y);
}

# Given a text box's position and dimensions, try to backtrack it towards the center
#   of the image until it collides with something. This should keep our words nicely
#   nestled against each other
sub _backtrack_coordinates {
	my $self = shift;
	
	my $text = shift;
	
	# Arrayref of bounding boxes to check for collision against
	my $colliders = shift;
	
	# X,Y coords to start with
	my ($x, $y) = (shift, shift);
	
	my ($center_x, $center_y) = ($self->width / 2, $self->height / 2);
	$center_x = $center_x - ($text->get('width') / 2);
	$center_y = $center_y + ($text->get('height') / 4);
	
	my $collision = 0;
	my $iter = 0;
	while (! $collision) {
		# Stop processing if we're within 1 pixel of the center of the iamge
		if (abs($center_x - $x) <= 1 &&
			  abs($center_y - $y) <= 1) {
			
			#printf "Coords (%s,%s) too near center (%s, %s), stopping on word '%s'\n",
			#	$x, $y,
			#	$center_x, $center_y, $text->get('text') if $ENV{IWC_DEBUG} >=2;
			
			last;
		}
		
		# Position and dimensions of the text string
		my ($a_x, $a_y, $a_x2, $a_y2) = ( $text->bounding_box($x, $y) )[6,7,2,3];
		my ($a_w, $a_h) = ($a_x2 - $a_x, $a_y2 - $a_y);
		
		my $collision_with = [];
		foreach my $b (@$colliders) {
		    my ($b_x, $b_y, $b_w, $b_h) = @$b;
		    
		    # Upper left to lower right
		    if ($self->_detect_collision(
		    			$a_x, $a_y, $a_w, $a_h,
		    			$b_x, $b_y, $b_w, $b_h)) {
		    	
		    	# Add this rectangle on to the ones we've had collisions with
		    	$collision_with = [$b_x, $b_y, $b_w, $b_h];
		    	
		    	$collision = 1;
		    	last;
		    }
		    else {
		    	$collision = 0;
		    }
		}
		
		# If there was collision...
		if ($collision == 1) {
			# Get the sides that we collided with the other rectangle on
			my @collision_sides = $self->_collision_sides($a_x, $a_y, $a_w, $a_h, @$collision_with);
			
			# If we only collided with one side, we should be able to move further along the other side,
			#   i.e. if we collided only on the X axis we can still move closer on the Y axis
			if (scalar @collision_sides == 1) {
				# We collided on a Y-axis side, so we can move on the X-axis
				if ($collision_sides[0] eq 'top' || $collision_sides[0] eq 'bottom') {
					$x = ($x < $center_x) ? $x+1 : $x-1;
				}
				# We collided on a X-axis side, so we can move on the Y-axis
				elsif ($collision_sides[0] eq 'left' || $collision_sides[0] eq 'right') {
					$y = ($y < $center_y) ? $y+1 : $y-1;
				}
			}
			# Total collision, stop moving!
			elsif (scalar @collision_sides >= 2) {
				last;
			}
		}
		# No collision!	
		else {
			$x = ($x < $center_x) ? $x+1 : $x-1;
			$y = ($y < $center_y) ? $y+1 : $y-1;
		}
		
		#my @bbox = $text->bounding_box($x, $y, 0);
		#$self->_stroke_bbox($gd, $gd->colorClosest(255, 255, 255), @bbox) if $iter % 10 == 0;
		
		$iter++;
	}
	
	#printf "New xy: $x, $y\n";
	
	return $x, $y;
}

# Return the minimum area we need to have to fit all the words based on the _max_font_size
sub _playing_field_area {
	my $self = shift;
	
	my ($max_font_size, $lastfont) = $self->_max_font_size();
	my $word_scalings = $self->_word_scalings();
	
	my $words = $self->words();
	
	my $area = 0;
	
	# Test GD object
	my $text_gd = GD::Image->new();
	
	# Get the area 
	foreach my $word (keys %$words) {
		my $text = GD::Text::Align->new($text_gd);
		$text->set_text($word);
		
		my $fontsize = $word_scalings->{ $word } * $max_font_size;
		$fontsize = $max_font_size if $fontsize > $max_font_size;
		$text->set_font($lastfont, $fontsize);
		
		my $word_area = $text->get('width') * $text->get('height');
		
		$area += $word_area;
	}
	
	return $area;
}

# Overall scaling we have to use to get all the words to fit in the playing field
sub _view_scaling {
	my $self = shift;
	
	# Get the total area we have to use
	my $pf_area = $self->_playing_field_area();
	
	# Get the ratio of width to height
	my ($w, $h) = $self->_image_bounds_width_height();
	#my $wh_ratio = $w / $h;
	
	#my $area_sq = sqrt($pf_area);
	#my $area_w = $area_sq * $wh_ratio;
	#my $area_h = $area_sq / $wh_ratio;
	
	my $area = $w * $h;
	
	my $scaling = $area / $pf_area;
}

# Return the maximum font-size this image can use
#   optionally also return the font that caused us the most issues
#   (i.e. has the largest size)
sub _max_font_size {
	my $self = shift;
	
	# If we already have a max font size and the words we are using haven't changed,
	#   return the saved max font size
	return $self->{max_font_size} if $self->{max_font_size} && ! $self->{words_changed};
	
	# Font size we'll return (start with 25% of the image height);
	my $init_fontsize = $self->_init_max_font_size();
	my $fontsize = $init_fontsize;
	
	# Image width and heigth
	#my ($w, $h) = ($self->width, $self->height);
	
	# Get the image bounds
	my ($left_bound, $top_bound, $right_bound, $bottom_bound) = $self->_image_bounds();
	
	# Get the word scaling factors
	my $scalings = $self->_word_scalings();
	
	# Get the longest word (length * scaling is being used to determine it, but there may be a better way)
	my $max_word = "";
	foreach my $word (keys %{ $self->words() }) {
		if (! $max_word) { $max_word = $word; next; } # init $max_word
		
		if (length($word) * $scalings->{ $word } > length($max_word) * $scalings->{ $max_word }) {
			$max_word = $word;
		}
	}
	
	#printf "Using max word %s\n", $max_word;
	
	# Create the text object
	my $t = new GD::Text::Align( GD::Image->new() );
	$t->set_text($max_word);
	
	# Get every possible font we can use
	my @fonts = $self->_get_all_fonts();
	
	# The last font that caused us size problems
	my $lastfont = "";
	
	while ($fontsize > 0) {
		my $toobig = 0;
		
		# The font size we try must include the scaling
		my $tryfontsize = $fontsize * $scalings->{ $max_word };
		
		# If the size exceeds our "max", set it back to the max. This is a hacky way
		# of making the sizes scale right but not excessively at the top end.
		if ($tryfontsize > $init_fontsize) {
			$tryfontsize = $init_fontsize;
		}
		
		# Go through every font
		foreach my $font (@fonts) {
			$lastfont = $font if ! $lastfont;
			
			# Set the font on this text object
			$t->set_font($font, $tryfontsize);
			
			#printf "Width is %s (max $w) at size %s in font %s\n", $t->get('width'), $tryfontsize, $font;
			
			# The text box is wider than the image bounds in this font, don't check the other fonts
			if ($t->get('width') > $right_bound - $left_bound) {
				$toobig = 1;
				$lastfont = $font;
				last;
			}
		}
		
		# If the text box wasn't too big, we've found our font size
		last if ! $toobig;
		
		# Decrease the font size for next iteration
		$fontsize--;
	}
	
	# Return the font size INCLUDING the scaling, because it will be scaled down
	#   in cloud()
	my $fontsize_with_scaling = $fontsize * $scalings->{ $max_word };
	
	#if ($fontsize_with_scaling > $init_fontsize) {
	#	carp sprintf "Fontsize %s bigger than init fontsize %s, reverting", $fontsize_with_scaling, $init_fontsize if $ENV{IWC_DEBUG};
	#	$fontsize_with_scaling = $init_fontsize;
	#}
	
	# Save the max font size so we can reuse it whenever cloud() is called,
	#   without running this method again
	$self->{max_font_size} = $fontsize_with_scaling;
	
	return wantarray ? ($fontsize_with_scaling, $lastfont) : $fontsize_with_scaling;
}

# Initial maximum font size is the 1/4 the heigth of the image
sub _init_max_font_size {
	my $self = shift;
	
	return $self->_pixels_to_points($self->width * .25);
}

# The minimum font size to use 
sub _min_font_size {
	my $self = shift;
	
	# Get the image bound dimensions
	my ($w, $h) = $self->_image_bounds_width_height();
	
	# The minimum font size is 0.8% of the image bounds height, seems to work nicely
	return $self->_pixels_to_points($h * 0.00875);
}

# Return a hashref of words with their associated scaling
sub _word_scalings {
	my $self = shift;
	
	# Get the words sorted by their count
	my @word_keys = sort { $self->{words}->{$b} <=> $self->{words}->{$a} } keys %{ $self->words() };
	
	my $sloop = 0;
	my %word_scalings = map { $sloop++; $_ => (1.75 / $sloop) } @word_keys;
	
	return \%word_scalings;
}

# Return a hashref of words with their scaled font sizes
sub _word_font_sizes {
	my $self = shift;
	
	my $max_font_size = $self->_max_font_size();
	
	my $word_scalings = $self->_word_scalings();
	
	my %word_sizes = map { $_ => $word_scalings->{$_} * $max_font_size } keys %{ $self->words() };
	
	return \%word_sizes;
}

# Return a single font
sub _get_font {
	my $self = shift;
	
	my $font = "";
	
	# From a font file
	if ($self->{'font_file'}) {
		$font = $self->{'font_file'};
	}
	# Or the specified font
	elsif ($self->{'font'} && -d $self->{'font_path'}) {
		$font = $self->{'font'};
	}
	# ...or use a random font
	elsif (scalar @{$self->{'fonts'}} > 0) {
		$font = $self->{'fonts'}->[ rand @{$self->{'fonts'}} ];
			unless (-f $font) { carp "Font file '$font' not found"; }
	}
	
	return $font;
}

# Get all fonts we can possibly use
sub _get_all_fonts {
	my $self = shift;
	
	my @fonts = ();
	if ($self->{'font_file'}) {
		@fonts = ($self->{'font_file'});
	}
	# Or the specified font
	elsif ($self->{'font'} && -d $self->{'font_path'}) {
		@fonts = ($self->{'font'});
	}
	# ...or all the fonts
	elsif (scalar @{$self->{'fonts'}} > 0) {
		@fonts = @{$self->{'fonts'}};
	}
	
	return @fonts;
}

# Given a number of pixels return the value in points (font size)
sub _pixels_to_points {
	my $self = shift;
	my $pixels = shift;
	
	return $pixels * 72 / 96;
}

# Given a number of points return the value in pixels
sub _points_to_pixels {
	my $self = shift;
	my $points = shift;
	
	return $points * 96 / 72;
}

# Return a list of random colors as an array of RGB arrayrefs
# ( [25,30,60], [2,204,300] ), etc.
sub _random_colors {
	my $self = shift;
	
	my %opts = validate(@_, {
		hue       => { type => SCALAR, optional => 1, default => int(rand(359))  },
		scheme    => { type => SCALAR, optional => 1, default => 'analogic' },
		variation => { type => SCALAR, optional => 1, default => 'default'  },
  });
  
  carp sprintf "Color scheme hue: %s", $opts{'hue'} if $ENV{IWC_DEBUG};
	
	my @rand_colors = map { [$self->_hex2rgb($_)] } Color::Scheme->new
		->from_hue( $opts{'hue'} )
		->scheme( $opts{'scheme'} )
		->variation( $opts{'variation'} )
		->colors();
	
	return @rand_colors;
}

# Convert a hexadecimal color to a list of rgb values
sub _hex2rgb {
	my $self = shift;
	my $hex = shift;

	my @rgb = map {hex($_) } unpack 'a2a2a2', $hex;
	return @rgb;
}

sub _prune_stop_words {
	my $self = shift;
	
	my @opts = validate_pos(@_, { type => HASHREF, optional => 1 });
	
	# Either use the words supplied to the subroutine or use what we have in the object
	my $words = {};
	if ($opts[0]) {
		$words = $opts[0];
	}
	else {
		$words = $self->{words};
	}
	
	# Read in the stop word file if we haven't already
	#if (! $self->{read_stop_file}) { $self->_read_stop_file(); }
	
	foreach my $word (keys %$words) {
			delete $words->{$word} if exists $STOP_WORDS{ $word };
	}
	
	return 1;
}

=head2 add_stop_words(@words)

Add new stop words onto the list. Automatically puts words in lowercase.

=cut

sub add_stop_words {
	my $self = shift;
	my @words = @_;
	
	foreach my $word (@words) {
		$STOP_WORDS{ lc($word) } = 1;
	}
		
	return $self;
}

# Detect a collision between two rectangles
#   Arguments are:
#		1: First rectangle's upper left X coord
#		2: First rectangle's upper left Y coord
#		3: First rectangle's width
#		4: First rectangle's height
#
#		1: Second rectangle's upper left X coord
#		2: Second rectangle's upper left Y coord
#		3: Second rectangle's width
#		4: Second rectangle's height
sub _detect_collision {
	my $self = shift;
	
	#my ($a_x, $a_y, $a_w, $a_h,
	#		$b_x, $b_y, $b_w, $b_h) = @_;
	
	#if (
	#	!( ($b_x > $a_x + $a_w) || ($b_x + $b_w < $a_x) ||
	#	   ($b_y > $a_y + $a_h) || ($b_y + $b_h < $a_y) )) {
	#
	# return 1;
	#}
	
	# If the two rectangle collide on the both planes then they intersect
	if ($self->_detect_x_collision(@_) && $self->_detect_y_collision(@_)) {
		return 1;
	}
	else {
		return 0;
	}
}

# Detect a collision on the X plane
sub _detect_x_collision {
	my $self = shift;
	
	my ($a_x, $a_y, $a_w, $a_h,
			$b_x, $b_y, $b_w, $b_h) = @_;
			
	if (! (($b_x > $a_x + $a_w) || ($b_x + $b_w < $a_x)) ) {
		return 1;
	}
	else {
		return 0;
	}
}

# Detect a collision on the Y plane
sub _detect_y_collision {
	my $self = shift;
	
	my ($a_x, $a_y, $a_w, $a_h,
			$b_x, $b_y, $b_w, $b_h) = @_;
			
	if (! (($b_y > $a_y + $a_h) || ($b_y + $b_h < $a_y)) ) {
		return 1;
	}
	else {
		return 0;
	}
}

# Return which side of object A collides with object B
sub _collision_sides {
	my $self = shift;
			
	my @sides = ();
	
	return @sides if ! $self->_detect_collision(@_);
	
	my ($a_x, $a_y, $a_w, $a_h,
			$b_x, $b_y, $b_w, $b_h) = @_;
	
	if (! ($b_x + $b_w > $a_x + $a_w)) {
		push(@sides, 'right');
	}
	
	if (! ($b_x + $b_w < $a_x + $a_w)) {
		push(@sides, 'left');
	}
	
	if (! ($b_y + $b_h > $a_y + $a_h)) {
		push(@sides, 'bottom');
	}
	
	if (! ($b_y + $b_h < $a_y + $a_h)) {
		push(@sides, 'top');
	}
	
	return @sides;
}

# Stroke the outline of a bounding box
sub _stroke_bbox {
	my $self  = shift;
	my $gd    = shift;
	my $color = shift;
	
	my ($x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4) = @_;
	
	$color ||= $gd->colorClosest(255,0,0);
	
	$gd->line($x1, $y1, $x2, $y2, $color);
	$gd->line($x2, $y2, $x3, $y3, $color);
	$gd->line($x3, $y3, $x4, $y4, $color);
	$gd->line($x4, $y4, $x1, $y1, $color);
}

# Return a random ingeger between two numbers
sub _random_int_between {
	my $self = shift;
	my($min, $max) = @_;
	
	# Assumes that the two arguments are integers themselves!
	return $min if $min == $max;
	($min, $max) = ($max, $min) if $min > $max;
	return $min + int rand(1 + $max - $min);
}

=head2 width()

Return wordcloud image width

=cut
sub width {
	return shift->{image_size}->[0];
}

=head2 height()

Return wordcloud image height

=cut
sub height {
	return shift->{image_size}->[1];
}

=head1 AUTHOR

Brian Hann, C<< <bhann at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests here L<https://github.com/c0bra/image-wordcloud-perl/issues>. 
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Image::WordCloud


You can also look for information at:

=over 4

=item * Github Issues Tracker (report bugs here)

L<https://github.com/c0bra/image-wordcloud-perl/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Image-WordCloud>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Image-WordCloud>

=item * Search CPAN

L<http://search.cpan.org/dist/Image-WordCloud/>

=item * MetaCPAN

L<https://metacpan.org/module/Image::WordCloud>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Brian Hann.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Image::WordCloud
