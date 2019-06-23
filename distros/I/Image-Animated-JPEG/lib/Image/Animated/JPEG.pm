package Image::Animated::JPEG;

use strict;
use warnings;

use Encode;

our $VERSION = '0.03';

sub index {
	my $io_file = shift;
	my $args = shift;

	my @frames;

	print "Parsing file...\n" if $args && $args->{debug};

	# check
	my $soi = my_read($io_file, 2);
	unless ($soi eq "\xFF\xD8") {
		die "Does not look like a JPEG file: SOI missing at start of file";
	}

	# first frame
	my $cnt = 1;
	print " frame $cnt begins at 0\n" if $args && $args->{debug};
	push(@frames, {
		offset	=> 0,
		io_file	=> $io_file, # hand over, per frame (might be multiple files)
	});

	# subsequent frames
	local $/ = "\xFF\xD9\xFF\xD8"; # we look for EOI+SOI marker to avoid false-positives with embedded thumbs
	while(my $chunk = <$io_file>){
		my $pos = tell($io_file) - 2; # -2: compensate for inclusion of begin-marker
		print " frame $cnt ends at $pos\n" if $args && $args->{debug};
		push(@frames, {
			offset	=> $pos,
			io_file	=> $io_file, # a quirk for playajpeg: hand over the fh, per frame, as playajpeg may play a sequence of jpegs as animation
		});
		$frames[$cnt - 1]->{length} = $pos - $frames[$cnt - 1]->{offset};
		$cnt++;
	}
	seek($io_file, 0,0); # rewind fh
	pop(@frames); # last boundary is not beginning of a new frame
	$frames[-1]->{length} += 2; # last frame won't end with EOI+SOI

	return \@frames;
}

sub process {	# mostly from Image::Info
	my $args = $_[1];

	my $fh;
	if(ref($_[0]) eq 'SCALAR'){
		require IO::String;
		$fh = IO::String->new($_[0]) or die "Error using scalar-ref for reading: $!";
	}else{
		open($fh, "<", $_[0]) or die "Error opening file for reading: $!";
		binmode($fh);
	}

	my $soi = my_read($fh, 2, ($args && $args->{debug} ? 1 : undef));
	unless ($soi eq "\xFF\xD8") {
		my $offset = tell($fh) - 2;
		die "Does not look like a JPEG file: SOI missing at offset $offset";
	}

	my %markers;
	my @warnings;
	while (1) {
		my($ff, $mark) = unpack("CC", my_read($fh, 2, ($args && $args->{debug} ? 1 : undef)));
		last if !defined $ff;

		if ($ff != 0xFF) {	# enter when processing a chunk
		    my $corrupt_bytes = 2;
		    while(1) {
			my($ff) = unpack("C", my_read($fh,1, ($args && $args->{debug} ? 1 : undef)));
			return if !defined $ff;
			last if $ff == 0xFF;
			$corrupt_bytes++;
		    }
		    $mark = unpack("C", my_read($fh,1, ($args && $args->{debug} ? 1 : undef)));
		    push(@warnings, sprintf("Corrupt JPEG data, $corrupt_bytes extraneous bytes before marker 0x%02x", $mark));
		}
		if ($mark == 0xFF) {	# munge FFs (JPEG markers can be padded with unlimited 0xFF's)
		    for (;;) {
			($mark) = unpack("C", my_read($fh, 1, ($args && $args->{debug} ? 1 : undef)));
			last if $mark != 0xFF;
		    }
		}

		last if $mark == 0xDA || $mark == 0xD9;  # exit once we reach a SOS marker, or EOI (end of image)

		print "marker: FF ".sprintf("%#x",$mark)." \n" if $args && $args->{debug};
		my $marker_pos = tell($fh) - 2;
		my($len) = unpack("n", my_read($fh, 2, ($args && $args->{debug} ? 1 : undef))); # we found a marker, read its size
		last if $len < 2; # data-less marker

		last if $mark < 0xE0; # data-less marker

		# process_chunk($info, $img_no, $mark, my_read($fh, $len - 2));
		if($mark == 0xE0){
			my $data = my_read($fh, $len - 2, ($args && $args->{debug} ? 1 : undef));
			print "APP0 at ". $marker_pos ." len:$len \n" if $args && $args->{debug};

			# get_name($fh);
			my $name;
			my $rel_offset = 0;
			for(0..10){ # app-identifiers may be arbitrarily long, but let's stop after 10 bytes
				my ($value) = unpack("C", read_bytes(\$data, \$rel_offset, 1));
				last if $value == 0x00;
				$name .= chr($value);
			}

			$markers{$name} = {
				type => 'APP0',
				offset => $marker_pos,
				length => $len,
				data_offset => ($marker_pos + 4) + (length($name) + 1),
				data_length => ($len - 2) - (length($name) + 1)
			};
		}else{
			seek($fh,$len - 2,1);
		}

	}

#	print Dumper(\%markers,\@warnings);
	return \%markers;
}

sub my_read {	# from Image::Info
	my($fh, $len) = @_;
	print " my_read: len:$len \n" if $_[2];
	my $buf;
	my $n = read($fh, $buf, $len);
	die "read failed: $!" unless defined $n;
	die "short read ($len/$n) at pos " . tell($fh) unless $n == $len;
	$buf;
}


sub encode_ajpeg_marker {
	return "AJPEG\000" . encode_ajpeg_data(@_);
}

sub decode_ajpeg_marker {
	return decode_ajpeg_data( substr($_[0],6) );
}

#   +------------- segment --------------+
#   | APP0-marker	  		 |
#   |		  +--"marker" / data ----+
#   | 		  | AJPEG-marker	 |
#   | 		  | 			 |
#   <marker><length><identifier>\x00<data>
#    FF E0   00 00   AJPEG       00  ... 

## expects a hashref
## encodes hash keys according to the AJPEG schema
sub encode_ajpeg_data {
	my $ref = shift;
	my $args = shift; # debug, future: version

	die "encode_ajpeg_data expects a hash-ref" unless $ref && ref($ref) eq 'HASH';

	my $binary;

	$binary = pack("C1",0); # version:0

	for my $key (keys %$ref){
		unless(defined($ref->{$key})){
			warn "encode_ajpeg_data: $key value is undef and will be ignored!" if $args && $args->{debug};
			next;
		}
		if($key eq 'version'){
			warn "encode_ajpeg_data: Only format version 0 is currenty implemented!" if $args && $args->{debug} && $ref->{$key} != 0;
			next;
		}
		if($key eq 'delay'){
			if($ref->{$key} <= 255){
				print "encode_ajpeg_data: delay $ref->{$key} (byte)\n" if $args && $args->{debug};
				$binary .= "\x01" . pack("C",$ref->{$key});
			}elsif($ref->{$key} <= 65535){
				print "encode_ajpeg_data: delay $ref->{$key} (short)\n" if $args && $args->{debug};
				$binary .= "\x02" . pack("n",$ref->{$key});
			}else{
				print "encode_ajpeg_data: delay $ref->{$key} (long)\n" if $args && $args->{debug};
				$binary .= "\x04" . pack("N",$ref->{$key});
			}
		}elsif($key eq 'repeat'){
			if($ref->{$key} <= 255){
				print "encode_ajpeg_data: repeat $ref->{$key} (byte)\n" if $args && $args->{debug};
				$binary .= "\x11" . pack("C",$ref->{$key});
			}elsif($ref->{$key} <= 65535){
				print "encode_ajpeg_data: repeat $ref->{$key} (short)\n" if $args && $args->{debug};
				$binary .= "\x12" . pack("n",$ref->{$key});
			}else{
				die "repeat values must be <= 65535";
			}
		}elsif($key eq 'parse_next'){
			if($ref->{$key} <= 255){
				$binary .= "\x21" . pack("C",$ref->{$key});
			}elsif($ref->{$key} <= 65535){
				$binary .= "\x22" . pack("n",$ref->{$key});
			}else{
				die "parse_next values must be <= 65535";
			}
		}elsif($key eq 'length'){
			if($ref->{$key} <= 255){
				$binary .= "\x31" . pack("C",$ref->{$key});
			}elsif($ref->{$key} <= 65535){
				$binary .= "\x32" . pack("n",$ref->{$key});
			}else{
				$binary .= "\x34" . pack("N",$ref->{$key});
			}
		}elsif($key eq 'previous'){
			if($ref->{$key} <= 255){
				$binary .= "\x41" . pack("C",$ref->{$key});
			}elsif($ref->{$key} <= 65535){
				$binary .= "\x42" . pack("n",$ref->{$key});
			}else{
				$binary .= "\x44" . pack("N",$ref->{$key});
			}
		}elsif($key eq 'x_offset'){
			if($ref->{$key} <= 255){
				$binary .= "\x51" . pack("C",$ref->{$key});
			}elsif($ref->{$key} <= 65535){
				$binary .= "\x52" . pack("n",$ref->{$key});
			}else{
				die "x_offset values must be <= 65535";
			}
		}elsif($key eq 'y_offset'){
			if($ref->{$key} <= 255){
				$binary .= "\x61" . pack("C",$ref->{$key});
			}elsif($ref->{$key} <= 65535){
				$binary .= "\x62" . pack("n",$ref->{$key});
			}else{
				die "x_offset values must be <= 65535";
			}
		}elsif($key eq 'dispose_op'){
			if($ref->{$key} <= 2){
				$binary .= "\x71" . pack("C",$ref->{$key});
			}else{
				die "dispose_op values must be <= 2";
			}
		}elsif($key eq 'metadata'){
			# skip, for later
		}else{
			warn "encode_ajpeg_data: '$key' is not recognized";
		}
	}

	# specs do not require it, but it may make sense to sort
	# "potentially longer" byte segments, like metadata, to the end
	# of the AJPEG segmemt
	if($ref->{'metadata'}){ # A0
		print "encode_ajpeg_data: metadata \n" if $args && $args->{debug};
		for my $mkey (keys %{ $ref->{'metadata'} }){
			print " metadata: ". $mkey .":". $ref->{'metadata'}->{$mkey} ."\n" if $args && $args->{debug};
			my $mkey_utf8 = encode('utf-8',$mkey);
			my $mvalue_utf8 = encode('utf-8',$ref->{'metadata'}->{$mkey});

			$binary .= pack("C",160) . pack("C",length($mkey_utf8)) . $mkey_utf8 . pack("C",length($mvalue_utf8)) . $mvalue_utf8;
		}
	}

	return $binary;
}


sub read_bytes {
	my $binary_ref = shift;
	my $offset_ref = shift; # quirk: offset as ref, so a read_bytes(), like core::read, advances a pointer/offset
	my $length = shift;

	# print "  read $length bytes at ${$offset_ref} \n";
	my $data = substr(${$binary_ref}, ${$offset_ref}, $length);
	${$offset_ref} += $length;

	return $data;
}

## expects a scalar holding binary data
# decodes AJPEG schema binary encoded keys and values
sub decode_ajpeg_data {
	my $binary = shift;
	my $args = shift; # debug

	die "decode_ajpeg_data expects a scalar with binary data" unless defined($binary);

	my $length = length($binary);
	my $offset = 0;

	my %ref;

	print "decode_ajpeg_data: length:$length \n" if $args && $args->{debug};
	$ref{version} = unpack("C", read_bytes(\$binary,\$offset,1));
	print "decode_ajpeg_data: version:$ref{version} \n" if $args && $args->{debug};

	my $cnt;
	for(;;){
		$cnt++;

		my $byte = read_bytes(\$binary,\$offset, 1);
		if($byte){ # an "empty AJPEG marker" will only hold version, read_bytes beyond that will return undef (thus we skip $key_num/properties decoding)
			my $key_num = unpack("C", $byte);
			if($key_num == 1){
				$ref{'delay'} = unpack("C", read_bytes(\$binary,\$offset,1));
				print "decode_ajpeg_data: delay: $ref{'delay'} (byte) \n" if $args && $args->{debug};
			}elsif($key_num == 2){
				$ref{'delay'} = unpack("n", read_bytes(\$binary,\$offset,2));
				print "decode_ajpeg_data: delay: $ref{'delay'} (short) \n" if $args && $args->{debug};
			}elsif($key_num == 4){
				$ref{'delay'} = unpack("N1", read_bytes(\$binary,\$offset,4));
				print "decode_ajpeg_data: delay: $ref{'delay'} (long) \n" if $args && $args->{debug};
			}elsif($key_num == 17){
				$ref{'repeat'} = unpack("C", read_bytes(\$binary,\$offset,1));
				print "decode_ajpeg_data: repeat: $ref{'repeat'} (byte) \n" if $args && $args->{debug};
			}elsif($key_num == 18){
				$ref{'repeat'} = unpack("n", read_bytes(\$binary,\$offset,2));
				print "decode_ajpeg_data: repeat: $ref{'repeat'} (short) \n" if $args && $args->{debug};
			}elsif($key_num == 33){
				$ref{'parse_next'} = unpack("C", read_bytes(\$binary,\$offset,1));
			}elsif($key_num == 34){
				$ref{'parse_next'} = unpack("n", read_bytes(\$binary,\$offset,2));
			}elsif($key_num == 49){
				$ref{'length'} = unpack("C", read_bytes(\$binary,\$offset,1));
			}elsif($key_num == 50){
				$ref{'length'} = unpack("n", read_bytes(\$binary,\$offset,2));
			}elsif($key_num == 52){
				$ref{'length'} = unpack("N", read_bytes(\$binary,\$offset,4));
			}elsif($key_num == 65){
				$ref{'previous'} = unpack("C", read_bytes(\$binary,\$offset,1));
			}elsif($key_num == 66){
				$ref{'previous'} = unpack("n", read_bytes(\$binary,\$offset,2));
			}elsif($key_num == 68){
				$ref{'previous'} = unpack("N", read_bytes(\$binary,\$offset,4));
			}elsif($key_num == 81){
				$ref{'x_offset'} = unpack("C", read_bytes(\$binary,\$offset,1));
			}elsif($key_num == 82){
				$ref{'x_offset'} = unpack("n", read_bytes(\$binary,\$offset,2));
			}elsif($key_num == 97){
				$ref{'y_offset'} = unpack("C", read_bytes(\$binary,\$offset,1));
			}elsif($key_num == 98){
				$ref{'y_offset'} = unpack("n", read_bytes(\$binary,\$offset,2));
			}elsif($key_num == 113){
				$ref{'dispose_op'} = unpack("C", read_bytes(\$binary,\$offset,1));
			}elsif($key_num == 160){ # 0xA0
				my $mkey_utf8 = read_bytes(\$binary,\$offset, unpack('C',read_bytes(\$binary,\$offset,1)) );
				my $mvalue_utf8 = read_bytes(\$binary,\$offset, unpack('C',read_bytes(\$binary,\$offset,1)) );

				my $mkey = decode('utf-8', $mkey_utf8) if defined($mkey_utf8);
				my $mvalue = decode('utf-8', $mvalue_utf8) if defined($mvalue_utf8);
				print "decode_ajpeg_data: metadata: ". $mkey .":". $mvalue ." \n" if $args && $args->{debug};
				$ref{'metadata'}->{$mkey} = $mvalue;
			}
		}
		last if $offset >= $length;
	}

	return \%ref;
}

1;

__END__

=head1 NAME

Image::Animated::JPEG - Library and scripts to create, play and modify Animated JPEG files

=head1 SYNOPSIS

   use Image::MetaData::JPEG;
   use Image::Animated::JPEG;

   ## load a JPEG file
   my $file = new Image::MetaData::JPEG($input_file);

   my $ref = Image::Animated::JPEG::encode_ajpeg_marker({
      delay  => 100,  # delay 100ms per frame
      repeat => 0,    # repeat forever
   });

   ## create a new APP0 segment/"tag"
   my $ani_seg = Image::MetaData::JPEG::Segment->new(
      'APP0',
      \$ref,	 # ref to Animated JPEG conform APP0 payload
      'NOPARSE', # tell Image::MetaData to not parse the segment (as it doesn't understand it, yet)
   );

   ## insert newly created segment, and write file
   $file->insert_segments($ani_seg);
   $file->save($output_file);

=head1 DESCRIPTION

This module provides functions to handle Animated JPEG files (AJPEGs), which are
similar to Motion-JPEG files, as they are just a concatenation of JPEGs.

The proposed Animated JPEG standard utilises JPEG/JFIF's APP0 application
extension segments to store playback settings, e.g. frame-rate (delay), loop
behaviour (repeat), etc., JFIF compliant as an additional APP0 marker. This
way, MJPEG files become a self-contained animation file similar to animated GIF
files.

The routines found in this module are able to index frames within an AJPEG file,
to process single frames in order to extract APP0 markers, and it provides
functions to encode and read segments in Animated JPEG's proposed segment data
format, version 0.

Also, this distribution comes bundled with five Animated JPEG utility scripts
which employ this module's routines to create, transform and play AJPEG files:

=over

=item * B<makeajpeg> - script to create Animated JPEG files on command-line.

=item * B<playajpeg> - a WxPerl-based Animated JPEG player GUI application.

=item * B<gif2ajpeg> - utilizes ImageMagick's I<convert> and I<makeani> to
convert animated gif files to Animated JPEG files.

=item * B<ajpeg2gif> - uses I<makeajpeg> to assemble and animated GIF from
an animated JPEG.

=item * B<ajpegtran> - lossless cropping of an entire animated JPEG animation
by executing I<jpegtran> on every separate frame.

=back

If you are interested in details of the proposed AJPEG format, the Why and How,
then read the README and SPECIFICATIONS files bundled with this distribution.

Also, the README file provides further information on how to set MIME-Type, etc.
on a *nix system so I<.ajpeg> files get associated with I<playajpeg>.

=head1 FUNCTIONS

=over

=item index($filehandle, $args)

Assumes a file is a concatenation of JPEG files, as known from MJPEG files and
as required for AJPEG files. Operates on the whole file. Scans such a file for
chunk/frame boundaries and builds an index of seek-offsets within the file.

Returns a reference to an array-of-hashes, each hash providing byte offsets
(boundaries) for each frame within the ajpeg file.

=item process($ref or $file)

This function operates on a chunk of a whole file (the single frame) or on a
singular file. It scans a JPEG/JFIF file/stream for APP0 segments.

Expects either a reference to a scalar holding a JPEG image (an in-memory JPEG
stream), or a scalar with a filename/path of a JPEG file. Relies on L<IO::String>
for in-memory streams.

Dies on error.

Returns a hash-of-hashes, with marker names (JFIF, AJPEG, ...) as keys, pointing 
to marker related information, for example:

   {
      AJPEG => {
         type   => 'APP0', # the only type of marker this function is looking for
         offset => ,       # position in file/stream, zero-based
         length => ,       # of the segment, as defined in JFIF "everything except leading \xFFF0"
         data_offset =>    # position where AJPEG marker payload begins (after application extension zero-terminator)
         data_length =>    # length of AJPEG data, everything from AJPEG version byte until end of segment
      },
      JFIF => {
         ...
      }
   }

=item encode_ajpeg_data($hashref,$args)

Expects a hashref with animation properties:

   {
      delay	 => # numeric value
      repeat	 => # numeric value
      parse_next => # numeric value
      length	 => # numeric value
      previous	 => # numeric value
      x_offset	 => # numeric value
      y_offset	 => # numeric value
      dispose_op => # numeric value
      metadata	 => {
         # hashref with arbitrary metadata key:value pairs
      }
   }

Dies on error.

Returns a scalar holding binary data (future segment's payload) on success.

Optionally, a second hashref holding arguments may be passed in:

   {
	debug	 => 1 # if set to true, print some info to stdout
   }

=item decode_ajpeg_data($data,$args)

Parses marker data according to AJPEG specs.

Expects a scalar holding binary data from an JPEG/JFIF APP0 marker, payload
only. That means: without leading "\xFF\xE0" APP0 mark, and without the two bytes
"chunk length" coming after the APP0 mark, and without the AJPEG application
extension identifier and without the binary-zero terminator trailing after it.
For an AJPEG segment, this means everything beginning with the version byte,
including the version byte itself, until the end of the segment.

Dies on error.

Returns a hashref with parameters found in the marker data.

Optionally, a second hashref holding arguments may be passed in:

   {
	debug	 => 1 # if set to true, print some info to stdout
   }

=back

=head1 CAVEATS

This module is alpha quality code. Don't use it to process important data unless
you know what you're doing.

The proposed Animated JPEG format specs are at version 0 (experimental, Request
for Comments). The specifications and this module's interface may change.

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

L<Image::MetaData::JPEG>, L<Image::Info>

This module and the L<Animated JPEG specifications|https://github.com/clipland/animated-jpeg/blob/master/SPECIFICATIONS.md>
currently reside on L<github|https://github.com/clipland/animated-jpeg>.

Specifications are also bundled with this distribution.

=head1 AUTHOR

Clipland GmbH L<http://www.clipland.com/>

=head1 COPYRIGHT & LICENSE

Copyright 2013-2019 Clipland GmbH. All rights reserved.

This library is free software, dual-licensed under L<GPLv3|http://www.gnu.org/licenses/gpl>/L<AL2|http://opensource.org/licenses/Artistic-2.0>.
You can redistribute it and/or modify it under the same terms as Perl itself.

JPEG marker parsing routines are mostly based on functions found in L<Image::Info>,
copyright 1999-2004 Gisle Aas, Tels 2006 - 2008, Slaven Rezic 2008 - 2013, et al.
Respective portions are marked in the source.
