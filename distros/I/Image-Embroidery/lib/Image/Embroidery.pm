package Image::Embroidery;

use 5.006;
use strict;
use warnings;
use Carp;
use IO::File;
use Bit::Vector;
use Data::Dumper;

=head1 NAME

Image::Embroidery - Parse and display embroidery data files

=head1 SYNOPSIS

  use Image::Embroidery;

  # Constructor
  $emb = Image::Embroidery->new();

=head1 ABSTRACT

Parse and display embroidery data files

=head1 DESCRIPTION

This module can be used to read, write and (with GD)
display embroidery data files. It currently only supports
Tajima DST files, but if there is any interest it could
be expanded to deal with other formats. In its current form
it isn't ideal for creating or modifying patterns, but
I'm reluctant to put much effort into it until someone
tells me they are using it.

=head1 EXAMPLES

This is an example of using the module to manipulate a
data file and write out the changes.

    use Image::Embroidery qw(:all);

    $emb = Image::Embroidery->new();

    $emb->read_file( '/path/to/embroidery.dst' ) or
       die "Failed to read data file: $!";
    
    # fiddle with the data structure some. this would make
    # the 201st entry a normal stitch that went 5 units right,
    # and 7 units up
    $emb->{'data'}{'pattern'}[200] = [ $NORMAL, 5, 7 ];

    # supply a new file name, or use the default of 
    # the original file name
    $emb->write_file( '/path/to/new_embroidery.dst' ) or
        die "Failed to write data file: $!";


This example demonstrates using GD to create an image
file using Image::Embroidery.

    use Image::Embroidery;
    use GD;
    
    $emb = Image::Embroidery->new();
    
    $emb->read_file( '/path/to/embroidery.dst' ) or
        die "Failed to read data file: $!";

    $im = new GD::Image( $emb->size() );
    
    # the first color you allocate will be the background color
    $black = $im->colorAllocate(0,0,0);

    # the order in which you allocate the rest is irrelevant
    $gray = $im->colorAllocate(128,128,128);
    $red = $im->colorAllocate(255,0,0);
    
    # you can control the thickness of the lines that are used to draw the 
    # image. the default thickness is 1, which will let you see individual
    # stitches. The higher you set the thickness, the smoother the image will
    # look. A thickness of 3 or 4 is good for showing what the finished product
    # will look like
    $im->setThickness(3);

    # the order you specify the colors is the order in which they
    # will be used. you must specify the correct number of colors
    $emb->draw_logo($im, $gray, $red);

    open(IMG, ">", "/path/to/embroidery.png");
    #  make sure you use binary mode when running on Windows
    binmode(IMG);
    print IMG $im->png;
    close(IMG);

Converting from one format to another

    $emb->read_file( '/path/to/embroidery.exp', 'exp' );
    $emb->save_file( '/path/to/embroidery.dst', 'dst' );

=head1 METHODS

=over 4

=cut

use vars qw(
	$VERSION
	@ISA
	@EXPORT_OK
	$NORMAL
	$JUMP
	$COLOR_CHANGE
);

require Exporter;

@ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw($NORMAL $JUMP $COLOR_CHANGE) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

$VERSION = '1.2';

$NORMAL = 0;
$JUMP = 1;
$COLOR_CHANGE = 2;

=item I<new>

  my $emb = Image::Embroidery->new();

The constructor.
=cut
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {
		ignore_header_coordinates => 0,
	};

	$self->{'filename'} = undef;

	bless ($self, $class);
	return $self;
}

=item I<read_file>

  $emb->read_file($filename);
  $emb->read_file($filename, 'tajima');

Read an embroidery data file in the specified file format.
See FILE FORMATS for supported formats. Default is Tajima DST.
Returns 0 on failure, 1 on success.

=cut
sub read_file {
	my ($self, $file, $type) = @_;

	unless(defined($file)) { carp("No filename provided"); return 0; }
	unless(-f "$file" and -r "$file") { carp("File $file unreadable or nonexistant"); return 0; }
	my $fh = IO::File->new($file) or carp("Unable to open $file") and return 0;
  
	$self->{'filename'} = $file;
  
	$type = (defined($type)) ? lc($type) : 'tajima';

	if($type eq 'tajima' or $type eq 'dst') {
		return _read_tajima_file($self, $fh);
	} elsif($type eq 'melco' or $type eq 'exp') {
		return _read_melco_file($self, $fh);
	} else {
		carp("Request to read unknown file type!");
	}
}

sub _read_melco_file {
	my ($self, $fh) = @_;
	my $record;
	$self->{'data'} = {};

	my $colorchange = '8001';

	# i don't know why both of these can be used
	# for a jump record.
	my $jump1 = '8002';
	my $jump2 = '8004';

	# initialize pattern info, and set defaults for stuff that melco doesn't use (MX/MY/PD multi-volume data)
	foreach my $field ('color_changes', 'stitches', '+X', '-X', '+Y', '-Y', 'MX', 'MY', 'PD') {
		$self->{'data'}{$field} = 0;
	}
	$self->{'data'}{'label'} = 'FromMelco';

	# current offset from the starting point
	my $currentX = 0;
	my $currentY = 0;

	while($fh->read($record, 2)) {
		$record = unpack('H4', $record);

		my ($x, $y);

		# remove empty records that are sometimes inserted after color
		# changes.
		if($record eq '0000') {
			next;
		} elsif($record eq $colorchange) {
			push(@{$self->{'data'}{'pattern'}}, [ $COLOR_CHANGE ]);
			$self->{'data'}{'color_changes'}++;
			next;
		} elsif($record eq $jump1 or $record eq $jump2) {
			$fh->read($record, 2);
			($x, $y) = _decode_melco_delta( unpack('H4', $record) );
			push(@{$self->{'data'}{'pattern'}}, [ $JUMP, $x, $y ]);
		# some generators insert 8080 records, but I don't know what they mean
		} elsif($record =~ /^80/) {
			$fh->read(undef, 2);
			next;
		} else {
			($x, $y) = _decode_melco_delta($record);

			push(@{$self->{'data'}{'pattern'}}, [ $NORMAL, $x, $y ]);
			$self->{'data'}{'stitches'}++;
		}

		# keep track of how big the pattern is
		$currentX += $x;
		$currentY += $y;
		if($currentX > $self->{'data'}{'+X'}) { $self->{'data'}{'+X'} = $currentX; }
		if($currentX < $self->{'data'}{'-X'}) { $self->{'data'}{'-X'} = $currentX; }
		if($currentY > $self->{'data'}{'+Y'}) { $self->{'data'}{'+Y'} = $currentY; }
		if($currentY < $self->{'data'}{'-Y'}) { $self->{'data'}{'-Y'} = $currentY; }
	}

	# these are magnitudes, so remove the minus sign
	$self->{'data'}{'-X'} = abs($self->{'data'}{'-X'});
	$self->{'data'}{'-Y'} = abs($self->{'data'}{'-Y'});

	# store the total size of the pattern
	$self->{'data'}{'x_size'} = $self->{'data'}{'+X'} + $self->{'data'}{'-X'};
	$self->{'data'}{'y_size'} = $self->{'data'}{'+Y'} + $self->{'data'}{'-Y'};

	# last position
	$self->{'data'}{'AX'} = $currentX;
	$self->{'data'}{'AY'} = $currentY;

	return 1;
}

sub _encode_melco_delta {
	my ($x, $y) = @_;
	if($x < 0) { $x += 256; }
	if($y < 0) { $y += 256; }

	my $delta_record = sprintf('%02x%02x', $x, $y);
	return $delta_record;
}

sub _decode_melco_delta {
	my ($record) = @_;
	my $x = hex(substr($record, 0, 2));
	my $y = hex(substr($record, 2, 2));
	
	# 127 is the max stitch length, 128 is a special value
	# for encoding jumps and color changes
	if($x == 128 or $y == 128) {
		return (0, 0);
	}

	if($x > 127) { $x = $x - 256; }
	if($y > 127) { $y = $y - 256; }

	return ($x, $y);
}

# parse a Tajima DST file
sub _read_tajima_file {
	my ($self, $fh) = @_;

	$self->{'data'} = {};
	my $field;
	my $stitch;

	my @x_incr = (  0,  0, 81,-81,  0,  0,  0,  0,
			3, -3, 27,-27,  0,  0,  0,  0,
			1, -1, 9,  -9,  0,  0,  0,  0
	);
	my @y_incr = (  0,  0,  0,  0,-81, 81,  0,  0,
			0,  0,  0,  0,-27, 27, -3,  3,
			0,  0,  0,  0, -9,  9, -1,  1
	);

	# keep track of the actual color changes we see, to verify that
	# it matches what's in the header. some programs incorrectly put
	# the number of colors in the header, which will be one too large
	my $actual_color_changes = 0;

	# i don't think the order of these header elements
	# can change, but i'll be flexible.
	while($fh->read($field, 2)) {
		# read the next character, which should be a colon
		# that separates the field name from the value. some
		# file generators forget the colon sometimes, so if
		# we don't get a colon back, we assume it's part of the data
		$fh->read(my $separator, 1);
		unless($separator eq ':') {
			$fh->seek(1,-1);
		}

		if($field eq 'LA') {
			$fh->read(my $label, 16);
			($self->{'data'}{'label'} = $label) =~ s/\s*$//;
		} elsif($field eq 'ST') {
			$fh->read($self->{'data'}{'stitches'}, 7);
			$self->{'data'}{'stitches'} = int($self->{'data'}{'stitches'});
		} elsif($field eq 'CO') {
			my $color_changes;
			$fh->read($color_changes, 3);
			$self->{'data'}{'color_changes'} = int($color_changes);
		} elsif($field =~ /^([-+][XY])$/) {
			$fh->read(my $val, 5);
			$self->{'data'}{"$1"} = int($val);
		} elsif($field =~ /^([AM][XY])$/) {
			my $field_name = $1;
			$fh->read(my $val, 6);
			$val =~ s/ //g;
			if($val =~ /^[\+\-]?\s*\d+$/) {
				$self->{'data'}{"$field_name"} = int($val);
			} else {
				$self->{'data'}{"$field_name"} = 0;
			}
		} elsif($field eq 'PD') {
			$fh->read($self->{'data'}{'PD'}, 9);
		} elsif(unpack('H6', $field) eq '2020') {
			last;
		} else {
			carp("Invalid header field: $field"); return 0;
		}

		# eat the CR that follows each field (except the last one, in which
		# case we're eating a 0x20)
		$fh->read(my $junk, 1);
	}

	$self->{'data'}{'x_size'} = $self->{'data'}{'+X'} + $self->{'data'}{'-X'};
	$self->{'data'}{'y_size'} = $self->{'data'}{'+Y'} + $self->{'data'}{'-Y'};

	# skip to the end of the header
	$fh->seek(512, 0);

	# the file spec for Tajima DST indicates that bits 0 and 1 of a
	# stitch should always be '1', but since they don't mean anything,
	# and some file generators don't follow the spec very carefully,
	# we just require them to be consistent throughout the file.
	# we store the values in the first stitch that we find, then 
	# compare subsequent stitches to the first value we saw. 
	my $stitch_bit_0;
	my $stitch_bit_1;


	while($fh->read($stitch, 3)) {
		my $v = Bit::Vector->new(24);
		$v->from_Hex(unpack('H6', $stitch));

		# just check for consistency to detect corrupt files, these bits are meaningless
		if(defined($stitch_bit_0)) {
			unless($v->bit_test(1) == $stitch_bit_1 and $v->bit_test(0) == $stitch_bit_0) {
				carp("Possibly corrupt data file: ", unpack('H6', $stitch));
			}
		} else {
			$stitch_bit_0 = $v->bit_test(0);
			$stitch_bit_1 = $v->bit_test(1);
		}

		# bit 6 is off for jumps and normal stitches
		if(!$v->bit_test(6)) {
			my ($x, $y) = (0, 0);
			# first two bits are not used. 6 and 7 are record type flags
			foreach my $index(2..5, 8..23) {
				$x += $x_incr[$index] if($v->bit_test($index));
				$y += $y_incr[$index] if($v->bit_test($index));
			}

			# bit 7 will be off for normal stitches, on for jumps
			push(@{$self->{'data'}{'pattern'}}, [ $v->bit_test(7), $x, $y ]);

		} elsif(!$v->bit_test(7)) {
			carp("Invalid operation code");
			return 0;
		} else {
			if($v->to_Hex() eq '0000C3') {
				push(@{$self->{'data'}{'pattern'}}, [ $COLOR_CHANGE ]);
				$actual_color_changes++;
			} elsif($v->to_Hex() eq '0000F3') {
				# this is the 'stop' code. sometimes there is trailing data, so
				# stop reading now.
				last;
			} else {
				carp("Invalid operation code");
				return 0;
			}
		}
	}

	# trust the data more than the header
	if($actual_color_changes != $self->{'data'}{'color_changes'}) {
		# TODO some kind of logging ("Tajima file header lists incorrect number of color changes: $self->{'data'}{'color_changes'}, should be $actual_color_changes");
		$self->{'data'}{'color_changes'} = $actual_color_changes;
	}

	return 1;
}

=item I<write_file>

  $emb->write_file();
  $emb->write_file( $filename );
  $emb->write_file( $filename, $format );

Output the contents of the object's pattern to the specified
file, using the specified file format. If the filename
is omitted, the default filename will be the last
file that was successfully read using I<read_file()>. 
See FILE FORMATS for supported formats. Default is Tajima DST.
Returns 0 on failure, 1 on success.

=cut
sub write_file {
	my ($self, $file, $type) = @_;

	unless(defined($self->{'data'}{'pattern'})) {
		carp("You do not have a pattern to write");
		return 0;
	}

	unless(defined($file)) {
		if(defined($self->{'filename'})) {
			$file = $self->{'filename'}; 
		} else {
			carp("No filename supplied");
			return 0;
		}
	}
	my $fh = IO::File->new($file, "w") or carp("Unable to write to $file") and return 0;

	# for windows
	binmode($fh);

	if(defined($type)) {
		$type = lc($type);
	} else {
		$type = 'tajima';
	}

	if($type eq 'tajima' or $type eq 'dst') {
		return _write_tajima_file($self, $fh);
	} elsif($type eq 'melco' or $type eq 'exp') {
		return _write_melco_file($self, $fh);
	} else {
		carp("Request to write unknown file type!");
		return 0;
	}
}

# output a Melco EXP file
sub _write_melco_file {
	my ($self, $fh) = @_;

	foreach my $entry (@{$self->{'data'}{'pattern'}}) {
		if($entry->[0] == $NORMAL) {
			print $fh pack('H4', _encode_melco_delta($entry->[1], $entry->[2]));
		} elsif($entry->[0] == $JUMP) {
			print $fh pack('H4', '8004'); # this can be either 8002 or 8004
			print $fh pack('H4', _encode_melco_delta($entry->[1], $entry->[2]));
		} else { # color change
			# i don't think the extra zero records are required, but most generators
			# seem to put them in there.
			print $fh pack('H8', '80010000');
		}
	}
}

# output a Tajima DST file
sub _write_tajima_file {
	my ($self, $fh) = @_;

	# header
	printf $fh "LA:%-16s\r", $self->{'data'}{'label'};
	printf $fh "ST:%07d\r", $self->{'data'}{'stitches'};
	printf $fh "CO:%03d\r", $self->{'data'}{'color_changes'};

	for('+X', '-X', '+Y', '-Y') { printf $fh "$_:%05d\r", $self->{'data'}{$_}; }

	foreach my $key ('AX', 'AY', 'MX', 'MY') {
		if($self->{'data'}{$key} < 0) { printf $fh "$key:-%5s\r", abs($self->{'data'}{$key}); }
		else { printf $fh "$key:+%5s\r", $self->{'data'}{$key}; }
	}

	printf $fh "PD:%9s", $self->{'data'}{'PD'};

	# pad out the rest of the header (512 bytes total)
	printf $fh ' 'x386;

	# data
	foreach my $entry (@{$self->{'data'}{'pattern'}}) {
		if($entry->[0] == $NORMAL or $entry->[0] == $JUMP) {
			print $fh pack('B24', _get_tajima_move_record(@{$entry}));
		} else { # color change
			print $fh pack('H6', '0000C3');
		}
	}

	# this is the 'stop' code
	print $fh pack('H6', '0000F3');

	$fh->close();

	return 1;
}

sub _get_tajima_move_record {
	my ($jump,$x,$y) = @_;
	my ($b0, $b1, $b2);

	my %x = _get_tajima_components($x);
	my %y = _get_tajima_components($y);

	# byte 0
	$b0.=($y{  1}?'1':'0');
	$b0.=($y{ -1}?'1':'0');
	$b0.=($y{  9}?'1':'0');
	$b0.=($y{ -9}?'1':'0');
	$b0.=($x{ -9}?'1':'0');
	$b0.=($x{  9}?'1':'0');
	$b0.=($x{ -1}?'1':'0');
	$b0.=($x{  1}?'1':'0');

	# byte 1
	$b1.=($y{  3}?'1':'0');
	$b1.=($y{ -3}?'1':'0');
	$b1.=($y{ 27}?'1':'0');
	$b1.=($y{-27}?'1':'0');
	$b1.=($x{-27}?'1':'0');
	$b1.=($x{ 27}?'1':'0');
	$b1.=($x{ -3}?'1':'0');
	$b1.=($x{  3}?'1':'0');

	# byte 2
	$b2.=($jump?'1':'0');
	$b2.='0';
	$b2.=($y{ 81}?'1':'0');
	$b2.=($y{-81}?'1':'0');
	$b2.=($x{-81}?'1':'0');
	$b2.=($x{ 81}?'1':'0');
	$b2.='1';
	$b2.='1';

	# debug
	# print "x: $x => "; foreach (keys %x) { print "$_ "; } print "\n";
	# print "y: $y => "; foreach (keys %y) { print "$_ "; } print "\n";
	# print "$b0 $b1 $b2\n";

	return($b0.$b1.$b2);
}

sub _get_tajima_components {
	my ($n) = @_;
	my ($s,%c);

	for my $p (reverse(0..4)) {
		if($n<0) { $n*=-1; $s=!$s; }
		my $m = 0;
		for my $q (0..$p-1) { $m+=3**$q; }
		if($n>=3**$p-$m) { $n-=3**$p; $c{($s?-1:1)*3**$p}=1; }
	}
	return(%c);
}

=item I<draw_logo>

  $emb->draw_logo( $gd_image_object, @colors );

Write an image of the stored pattern to the supplied 
GD::Image object. You must supply the correct number of
colors for the pattern. Color arguments are those returned by
GD::Image::colorAllocate. Returns 0 on failure, 1 on success.

=cut
sub draw_logo {
	my ($self, $im, @colors) = @_;

	unless(defined($self->{'data'}{'pattern'})) {
		carp("You do not have a pattern to display");
		return 0;
	}

	unless(scalar(@colors) == $self->{'data'}{'color_changes'} + 1) {
		carp($self->{'data'}{'color_changes'} + 1, " colors required, ", scalar(@colors), " colors supplied");
		return 0;
	}

	my ($x, $y); 
	
	if($self->{'ignore_header_coordinates'}) {
		($x, $y) = ( int($self->{'data'}{'x_size'}/2), int($self->{'data'}{'y_size'}/2));
	} else {
		($x, $y) = ($self->{'data'}{'+X'}, $self->{'data'}{'y_size'} - $self->{'data'}{'+Y'});
	}

	my ($new_x, $new_y);

	foreach my $stitch (@{$self->{'data'}{'pattern'}}) {
		if($stitch->[0] == $NORMAL) {
			$new_x = $x + $stitch->[1];
			$new_y = $y - $stitch->[2];
			$im->line($x, $y, $new_x, $new_y, $colors[0]);
			$x = $new_x; $y = $new_y;
		} elsif($stitch->[0] == $JUMP) {
			$x = $x + $stitch->[1];
			$y = $y - $stitch->[2];
		} elsif($stitch->[0] == $COLOR_CHANGE) {
			shift @colors;
		}
	}
	return 1;
}

=item I<ignore_header_coordinates>

  my $ignoring = $emb->ignore_header_coordinates;
  $emb->ignore_header_coordinates( 1 );
  
Get or set whether to ignore the starting coordinates
in the file header, and assume that the pattern begins
in the center. Some programs that generate Tajima DST
files put incorrect values into the header that cause
the image to be off center. Enabling this will correct
those images, but will display images with correct
(but offcenter) starting points offset. This MUST be
called before calling read_file.

=cut
sub ignore_header_coordinates {
	my ($self, $ignore) = @_;
	
	if(defined($ignore)) {
		$self->{'ignore_header_coordinates'} = $ignore;
	}

	return $self->{'ignore_header_coordinates'};
}

=item I<label>

  my $label = $emb->label();
  $emb->label( $new_label );

Get or set the label that will be inserted into the file headers,
if the output format supports it.

=cut
sub label {
	my ($self, $label) = @_;

	if(defined($label)) {
		$self->{'label'} = $label;
	}
	return $self->{'label'};
}

=item I<size>

  my ($x, $y) = $emb->size();

Returns the X and Y size of the pattern.

=cut
sub size {
	my ($self) = @_;
	return ($self->{'data'}{'x_size'}, $self->{'data'}{'y_size'});
}

=item I<get_color_changes>

  my $changes = $emb->get_color_changes();

Return the number of colors changes in the pattern.

=cut
sub get_color_changes {
	my ($self) = @_;
	return $self->{'data'}{'color_changes'};
}

=item I<get_color_count>

  my $colors = $emb->get_color_count();

Returns the number of colors in the pattern.

=cut
sub get_color_count {
	my ($self) = @_;
	return ($self->{'data'}{'color_changes'} + 1);
}

=item I<get_stitch_count>

  my $count = $emb->get_stitch_count();

Return the total number of stitches in the pattern.

=cut
sub get_stitch_count {
	my ($self) = @_;
	return $self->{'data'}{'stitches'};
}

=item I<get_end_point>

  my ($x, $y) = $emb->get_end_point();

Returns the position of the last point in the pattern,
relative to the starting point.

=cut
sub get_end_point {
	my ($self) = @_;
	return ($self->{'data'}{'AX'}, $self->{'data'}{'AY'});
}

=item I<get_abs_size>

  my ($plus_x, $minus_x, $plus_y, $minus_y) = $emb->get_abs_size();

Returns the distance from the starting point to
the edges of the pattern, in the order +X, -X, +Y, -Y.

=cut
sub get_abs_size {
	my ($self) = @_;
	return ($self->{'data'}{'+X'}, $self->{'data'}{'-X'},
		$self->{'data'}{'+Y'}, $self->{'data'}{'-Y'});
}


1;
__END__

=back

=head1 FILE FORMATS

Supported file formats are Tajima DST and Melco EXP.
These can be specifed to the I<read_file()> and I<write_file()>
routines using the strings:

Tajima DST: 'tajima' or 'dst'
Melco EXP:  'melco' or 'exp'

Strings are case-insensitive. Tajima is always the default.

A note on Tajima DST files:
It seems that many applications that produce DST files
put incorrect information in the header. I've attempted
to work around invalid files as much as possible, but
occasionally there are still problems. If you have a file
that loads in another viewer but not in this module, let me
know and I'll see if I can fix the problem.

=head1 AUTHOR

Kirk Baucom, E<lt>kbaucom@schizoid.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Kirk Baucom

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
