package Image::ParseGIF;
# 
######################################################################
# 
# Parse a GIF image into its component parts.
#  (c) 1999/2000 University of NSW
# 
# Written by Benjamin Low <b.d.low@unsw.edu.au>
#
######################################################################
# 
# Change Log
# 1999/08/30	0.01	First release.
# 1999/09/01	0.02	Fixed image version test. 
# 2000/05/15	0.10	Fixed a number of embarrasing problems (I was 
#						mixing up the initial bytes of each part)... 
#						Thanks to Doug Bagley for letting me know.
#						- also added the deanimate method.
# 2000/05/15	0.11	Fixed typo in print_parts
# 2000/06/05	0.20	Colour table manipulations, written by Ed Halley
#						- also added binmode to file i/o (also thanks to Ed)
#
######################################################################
# 

#use diagnostics;	# turn on -w warning explanations (verbose!)
use strict;			# try and pick up silly errors at compile time

use vars qw/@ISA @EXPORT_OK %EXPORT_TAGS $VERSION/;

use Exporter ();
@ISA         = qw/Exporter/;
@EXPORT_OK   = qw//;
%EXPORT_TAGS = qw//;
# add %EXPORT_TAGS to @EXPORT_OK
Exporter::export_tags();
Exporter::export_ok_tags();

$VERSION = 0.20;

use Fcntl qw(:DEFAULT :flock);  # sysopen, flock symbolic constants

use IO::Handle;
# also use IO::File in ::open()

sub new
# create a new object
{
	my ($class, $filename, @args) = @_;
	my $args;	# -> %args

	# check if %args were passed in by reference 
	#  ie. there's only one key with no value, and it's a hash ref
	if    (@args == 1 && ref($args[0]) eq 'HASH') { $args = $args[0]; }
	elsif (@args % 2 == 0)                        { $args = {@args}; }
	else  { $@ = "bad argument list"; return undef; }

	# instance data
	my $self = 
	{
		header	=> '',		# GIF header, screen desc, colour table
		parts	=> [],		# (image, control) parts
		trailer	=> '',		# trailer

		delay	=> 0,		# default delay between frames

		# three new options added by Ed Halley [ed@explorati.com]
		# - when set, these operations are applied to all colour table(s)
		invert		=> 0,	# toggle colour table(s) inversion (light-for-dark)
		posterize	=> 0,	# flatten colour table(s) (to N colours, 0 == off)
		desaturate	=> 0,	# toggle desaturatation (grayscale)

		debug	=> 0,		# debug state
		output	=> undef,	# IO::Handle to send output to (STDOUT by default)
	};

	# merge arguments
	while (my ($k, $v) = each %{$args})
	{
		$self->{lc($k)} = $v;
	}

	# allow the non-American spelling :-)
	$self->{posterize} = delete $self->{posterise} 
		if (exists $self->{posterise});

	bless ($self, $class);

	# set output filehandle
	$self->output($self->{'output'});

	# open input file if provided
	if ($filename) { return $self = undef unless $self->open($filename); }

	return $self;
}

sub debug
{
	my ($self, $l) = @_;
	return defined($l) ? $self->{'debug'} = $l : $self->{'debug'};
}

# new options added by Ed Halley [ed@explorati.com]
sub invert
{
	my ($self, $l) = @_;
	return defined($l) ? $self->{'invert'} = $l : $self->{'invert'};
}

# new option added by Ed Halley [ed@explorati.com]
sub posterize
{
	my ($self, $l) = @_;
	return defined($l) ? $self->{'posterize'} = $l : $self->{'posterize'};
}
sub posterise { shift->posterize(@_) }

# new option added by Ed Halley [ed@explorati.com]
sub desaturate
{
	my ($self, $l) = @_;
	return defined($l) ? $self->{'desaturate'} = $l : $self->{'desaturate'};
}

sub _read
# read and confirm I got what I asked for
#  - read $len and write into buffer at $offset
#    - if offset < 0, writes to (end of buffer + offset + 1) (this is different 
#      to perl's inbuilt read, which writes at end + offset, i.e. overwrites
#      last 'offset' bytes)
#  - returns false on error
# e.g.
#  _read($fh, $buf, 1);		# read 1 byte into offset 0
#  _read($fh, $buf, 1, 5);	# read 1 byte into offset 5
#  _read($fh, $buf, 1, -1);	# read 1 byte into offset (len($buf) + 'offset' + 1)
#
{
	my ($io, $buf, $len, $offset) = @_;

	$offset ||= 0;	# 0, if not defined or ''
	$offset += ($buf ? length($buf) + 1 : 1) if $offset < 0;
	$offset = 0 if ($offset < 0);

	my $r = $io->read($_[1], $len, $offset);

	$@ = "read error: $!", return undef unless (defined($r));

	# eof is ok
	$@ = "short read: $r / $len" unless ($r == 0 or $r == $len);

	return ($r == $len);
}

sub open
# open a gif and parse it
{
	use IO::File;

	my ($self, $filename) = @_;

	my $io = new IO::File ($filename, O_RDONLY);

	unless (defined $io)
		{ $@ = $!; warn "$@\n" if $self->{'debug'}; return undef }

	# be nice to non-unix users
	binmode($io);

	my $r = $self->parse($io);
	$io->close();
	return $r;
}

my $_autoflush = 1;	# class variable

sub _wrap
# wrap a filehandle (a la IO::Wrap, but use IO::Handle instead of FileHandle)
{
	my ($io, $mode) = @_;

	unless (UNIVERSAL::can($io, 'read'))
	{
		my $fh = $io;
		$io = new IO::Handle;
		# fdopen() the filehandle directly (i.e. dup the filehandle), rather 
		# than using fileno($fh). Using the fileno directly will cause the 
		# original file to be closed when the IO object is destroyed.
		unless ($io->fdopen($fh, $mode))
		{
			$@ = "could not open IO::Handle on [$fh]: $!";
			warn "$@\n";
			return undef;
		}

		$io->autoflush($_autoflush);

		# be nice to non-unix users
		binmode($io);
	}

	return $_[0] = $io;
}

sub autoflush
# class method to turn on/off autoflush for newly created IO::Handles
#  - as per IO::Handle's autoflush, calling autoflush without parameters
# will turn on autoflush.
{
	my ($self, $v) = @_;
	return $_autoflush = (defined($v) ? $v : 1);
}

sub _read_and_adjust_color_table
# colour-table reading and adjusting made into function by Ed Halley [ed@explorati.com]
# probably a lot of faster ways to do the transforms, but this is readable
{
	my ($self, $io, $flags) = @_;
	my $nColors = (1<<(($flags & 0x07) + 1));
	my $aColors = ' ' x (3*$nColors);

	warn "\treading colour table " .
		"[" . (3 * $nColors) . " bytes]\n" if $self->{'debug'};

	_read($io, $aColors, 3 * $nColors);

	my $i;
	if ($self->{'invert'})
	{
		warn "\tinverting colour table\n" if $self->{'debug'};
		for $i (0 .. ($nColors-1))
		{
			my ($r, $g, $b) = unpack("CCC", substr($aColors, 3*$i, 3));
			$r = 255-$r;
			$g = 255-$g;
			$b = 255-$b;
			substr($aColors, 3*$i, 3) = pack("CCC", $r, $g, $b);
		}
	}
	if ($self->{'desaturate'})
	{
		warn "\tdesaturating colour table\n" if $self->{'debug'};
		for $i (0 .. ($nColors-1))
		{
			my ($r, $g, $b) = unpack("CCC", substr($aColors, 3*$i, 3));
			my $avg = ($r + $g + $b) / 3;
			$r = $avg;
			$g = $avg;
			$b = $avg;
			substr($aColors, 3*$i, 3) = pack("CCC", $r, $g, $b);
		}
	}
	if ($self->{'posterize'})
	{
		warn "\tposterizing colour table\n" if $self->{'debug'};
		for $i (0 .. ($nColors-1))
		{
			my ($r, $g, $b) = unpack("CCC", substr($aColors, 3*$i, 3));
			#$r = ($r < 128 ? 0 : 255);
			#$g = ($g < 128 ? 0 : 255);
			#$b = ($b < 128 ? 0 : 255);
			# quantise each colour (BDL)
			my $s = 255 / $self->{'posterize'};
			$r = int (int($r/$s + 0.5) * $s);
			$g = int (int($g/$s + 0.5) * $s);
			$b = int (int($b/$s + 0.5) * $s);
			substr($aColors, 3*$i, 3) = pack("CCC", $r, $g, $b);
		}
	}

	$aColors;
}

sub _read_header
{
	my ($self, $io) = @_;
	my $b;		# used to buffer 'headers' which need to be unpacked
	my $flags;	# used for flag bitmaps

	warn "reading header\n" if $self->{'debug'};

	# get the GIF 'signature' (e.g. 'GIF89a')
	_read($io, $self->{'header'}, 6, 0);

	unless ($self->{'header'} =~ /^GIF(\d\d)([a-z])/)
	{
		$@ = "not a GIF - signature is [$self->{'header'}]";
		warn "$@\n" if $self->{'debug'};
		return undef;
	}

	my @spec_ver = qw/89 a/;
	my @img_ver = ($1, $2);

	# check the image version (note numbering = 87,88,...99, 00, 01, ..., 86)
	{
	local $"='';
	warn "\tGIF version [@img_ver] greater than [@spec_ver]\n" 
		if (($img_ver[0] < 87 ? $img_ver[0] + 100 : $img_ver[0]) > $spec_ver[0] 
		   or ($img_ver[0] == $spec_ver[0] and $img_ver[1] gt $spec_ver[1]));
	}

	# get logical screen description and test for presence of colour table
	_read($io, $b, 7);
	$self->{'header'} .= $b;

	($flags) = unpack("x4 C x2", $b);

	if ($flags & 0x80)	# get global color table if present
	{
		my $ctable = $self->_read_and_adjust_color_table($io, $flags);
		$self->{'header'} .= $ctable;
	}

	return 1;
}

sub _read_image_descriptor
# read an image descriptor and add to current part
{
	my ($self, $io, $part, $b) = @_;
	# $b - used to buffer 'headers' which need to be unpacked
	# - should contain the 'image separator' byte (0x2c) to start

	warn "reading image descriptor (-> part $part)\n" if $self->{'debug'};

	unless (ord($b) == 0x2c)
	{
		$@ = "not an image separator [$b]";
		warn "$@\n" if $self->{'debug'};
		return undef;
	}

	# append separator to current part
	$self->{'parts'}[$part] .= $b;

	# read descriptor
	_read($io, $b, 9);

	# append descriptor to current part
	$self->{'parts'}[$part] .= $b;

	if ($self->{'debug'} > 1)
	{
		# write (width x height) @ (top, left) (flags)
		my ($l, $t, $w, $h, $flags) = unpack("v v v v C", $b);
		my @f;
		push (@f, 'LOCAL_COLOUR_TABLE') 	if ($flags & 0x80);
		push (@f, 'INTERLACED')				if ($flags & 0x40);
		push (@f, 'SORTED_COLOUR_TABLE')	if ($flags & 0x20);
		push (@f, sprintf 'RESERVED(0x%x)', ($flags & 0x18)>>3)
			if ($flags & 0x18);
		warn sprintf("\t%dx%d@%d,%d (0x%.2x = %s)\n", $w, $h, $l, $t, 
			$flags, join('|', @f) || '-');
	}

	my ($flags) = unpack("x8 C", $b);
	if ($flags & 0x80)	# local colour map?
	{
		my $ctable = $self->_read_and_adjust_color_table($io, $flags);
		$self->{'parts'}[$part] .= $ctable;
	}

	# get 'LZW code size' parameter
	warn "\treading LZW code size\n" if $self->{'debug'};
	_read($io, $self->{'parts'}[$part], 1, -1);	# read 1 byte -> append to part

	# and now the sub-block/s
	_read($io, $b, 1);	# get block length
	$self->{'parts'}[$part] .= $b;
	while (ord($b) > 0)
	{
		warn "\t reading sub-block [" , ord($b), " bytes]\n" if 
			$self->{'debug'} > 1;
		_read($io, $self->{'parts'}[$part], ord($b), -1);
		# get either the block terminator (0x00) (ie. no more blocks), 
		#  or the block size of the next block
		_read($io, $b, 1);	# get block length
		$self->{'parts'}[$part] .= $b;
	}
	warn "\tdone sub-block, next part\n" if $self->{'debug'};

	return 1;
}

sub _read_extension
# read an extension, but only and add to current part if it is a graphic 
# control
{
	my ($self, $io, $part, $b) = @_;
	# $b - used to buffer 'headers' which need to be unpacked
	# - should contain the 'extension introducer' byte (0x21) to start

	warn "reading extension (-> part $part)\n" if $self->{'debug'};

	unless (ord($b) == 0x21)
	{
		$@ = "not an extension [$b]";
		warn "$@\n" if $self->{'debug'};
		return undef;
	}

	# read extension type
	_read($io, $b, 1);

	my $t = ord($b);

	if ($t == 0xf9)		# graphic control (precursor to an image)
	{
		# graphic control precedes an image decriptor
		warn "\tgraphic control\n" if $self->{'debug'};

		# ok, want this extension so add introducer and type to current part
		$self->{'parts'}[$part] .= pack('C2', 0x21, 0xf9);

		_read($io, $b, 6);	# get the gc 'header'

		if ($self->{'debug'} > 1)
		{
			# write delay, transparent index, (flags)
			my ($s, $flags, $d, $i) = unpack("C C v C", $b);
			warn "\tERROR: invalid size (got $s, expected 4\n" if $s != 4;
			my @f;
			push (@f, sprintf 'RESERVED(0x%x)', ($flags & 0xe0)>>5)
				if ($flags & 0xe0);
			push (@f, sprintf 'DISPOSAL_METHOD(%d)', ($flags & 0x1c)>>2)
				if ($flags & 0x1c);
			push (@f, 'USER_INPUT')			if ($flags & 0x02);
			push (@f, "TRANSPARENT($i)")	if ($flags & 0x01);
			warn sprintf("\t[dt=%dms (0x%.2x = %s)]\n", $d*10,
				$flags, join('|', @f) || '-');
		}

		# update delay
		my ($s, $flags, $delay, $tci, $bt) = unpack("C C v C C", $b);

		$b = pack("C C v C C", $s, $flags, $self->{'delay'}, $tci, $bt);
		$self->{'parts'}[$part] .= $b;
	}
	elsif ($t == 0x01)	# plain text - skip
	{
		warn "\tplain text (skipping)\n" if $self->{'debug'};
		_read($io, $b, 13);	# 'header'
		_read($io, $b, 1);	# block length, or terminator (==0)
		while (ord($b) > 0)
		{
			warn "\t skipping sub-block [" , ord($b), " bytes]\n" if 
				$self->{'debug'} > 1;
			_read($io, $b, ord($b));
			# filter as per the GIF Plain Text Extension Recommendation,
			# - except use ? rather than space
			$b =~ s/[\x00-\x1f\x7f-\xff]/?/sg;
			warn "\t[$b]\n" if $self->{'debug'} > 1;
			_read($io, $b, 1);	# block length, or terminator (==0)
		}
	}
	elsif ($t == 0xff)	# application extension - skip
	{
		warn "\tapplication extension (skipping)\n" if $self->{'debug'};
		_read($io, $b, 12);	# 'header'
		if ($self->{'debug'} > 1)
		{
			my ($s, $id, @c) = unpack ('C a8 C3', $b);
			warn "\tERROR: invalid size (got $s, expected 11\n" if $s != 11;
			$id =~ s/[\x00-\x1f\x7f-\xff]/?/sg;	# filter non-printable chars
			warn "\t[$id, " . sprintf ('0x%x%x%x', @c) . "]\n";
		}
		_read($io, $b, 1);	# block length, or terminator (==0)
		while (ord($b) > 0)
		{
			warn "\t skipping sub-block [" , ord($b), " bytes]\n" if 
				$self->{'debug'} > 1;
			_read($io, $b, ord($b));
			_read($io, $b, 1);	# block length, or terminator (==0)
		}
	}
	elsif ($t == 0xfe)	# comment - skip
	{
		warn "\tcomment (skipping)\n" if $self->{'debug'};
		# no 'header'

		_read($io, $b, 1);	# block length, or terminator (==0)
		while (ord($b) > 0)
		{
			warn "\t skipping sub-block [" , ord($b), " bytes]\n" if 
				$self->{'debug'} > 1;
			_read($io, $b, ord($b));
			$b =~ s/[\x00-\x1f\x7f-\xff]/?/sg;	# filter non-printable chars
			warn "\t[$b]\n" if $self->{'debug'} > 1;
			_read($io, $b, 1);	# block length, or terminator (==0)
		}
	}
	else
	{
		$@ = "invalid extension label found";
		warn "$@\n" if $self->{'debug'};
		return undef;
	}

	return 1;
}

sub parse
# parse a GIF, reading from a given filehandle or IO object
{
	my ($self, $io) = @_;
	my $b;		# used to buffer 'headers' which need to be unpacked

	unless (_wrap($io, 'r'))
	{
		$@ ||= "could not wrap [$io]";
		return undef;
	}

	# read header, aborting if it doesn't look like a GIF
	_read_header($self, $io) or return undef;

	# parse the parts, adding to any existing parts
	my $part = @{$self->{'parts'}};
	my $t;		# block type

	my $fp;		# file position (for debugging)
	warn "fpos=" . ($fp = tell($io)) . "\n" if $self->{'debug'} > 2;

	while (_read($io, $b, 1))
	{
		my $p = $part;	# used in debugging, below

		$t = ord($b);

		if ($t == 0x3b)		# trailer
		{
			warn "reading trailer\n" if $self->{'debug'};
			$self->{'trailer'} = $b;
		}

		elsif ($t == 0x2c)		# image descriptor
		{
			_read_image_descriptor($self, $io, $part, $b);
			$part++;	# start the next part
		}

		elsif ($t == 0x21)		# some kind of extension
		{
			_read_extension($self, $io, $part, $b);
		}

		else
		{
			# fall-through
			$@ = "invalid block label found [$t]";
			warn "$@\n" if $self->{'debug'};
			return undef;
		}

		if ($self->{'debug'} > 2)
		{
			$_ = tell($io);
			warn "fpos=$_ (+" . ($_ - $fp) . ") partlen=" . 
				length($self->{'parts'}[$p]||'') . "\n";
			$fp = $_;
		}
	}

	return 1;

}

sub header
# Return the image header
{
	return shift->{'header'};
}

sub trailer
# Return the image trailer
{
	return shift->{'trailer'};
}

sub parts
# Return list of the image parts in array context, or number of parts in 
# scalar context. (Does not include header or trailer).
{
	return wantarray ? @{shift->{'parts'}} : scalar(@{shift->{'parts'}});
}

sub part
# Return an image part
#  - part == undef gives header
#  - part > num_parts gives trailer
{
	my ($self, $part) = @_;

	warn "returning part [" . (defined($part) ? 
		($part > $#{$self->{'parts'}} ? 'trailer' : $part) : 'header') . 
		"]\n" if ($self->{'debug'} > 1);

	return $self->{'header'} unless defined($part);
	return $self->{'trailer'} if ($part > $#{$self->{'parts'}});
	return $self->{'parts'}->[$part];
}

sub output
# Specify output filehandle.
{
	my ($self, $io) = @_;

	$io = *STDOUT unless defined($io);
	warn "output to $io\n" if ($self->{'debug'} > 1);
	unless (_wrap($io, 'w'))
	{
		$@ ||= "could not wrap [$io]";
		return undef;
	}
	warn "\t-> $io\n" if ($self->{'debug'} > 1);

	$self->{'output'} = $io;
}

sub print_part
# print a part to given fh, or default (set via ::output()) if none supplied
{
	my ($self, $part, $io) = @_;

	$io = defined($io) ? _wrap($io, 'w') : $self->{'output'};

	warn "printing part " . (defined $part ? $part : '-') . " to $io\n" 
		if $self->{'debug'} > 1;

	$io->print($self->{'parts'}->[$part]);
}

sub deanimate
# print header, given part and trailer to given / default fh
# - print a random part for indices < 0
{
	my ($self, $part, $io) = @_;

	$io = defined($io) ? _wrap($io, 'w') : $self->{'output'};

	$part ||= 0;
	$part = int rand(@{$self->{'parts'}}) if $part < 0;

	$io->print($self->{'header'});
	$io->print($self->{'parts'}->[$part]);
	$io->print($self->{'trailer'});
}

sub print_parts
# print zero or more parts to given / default fh
{
	my ($self, $part, $io) = @_;

	$io = defined($io) ? _wrap($io, 'w') : $self->{'output'};
	$part = @{$self->{'parts'}} unless defined $part;

	# where were we up to?
	my $ppart = $self->{'_ppart'} || 0;
	warn "printing parts $ppart - $part to $io\n" if ($self->{'debug'} > 1);
	while ($ppart <= $part)
	{
		warn " $ppart (" . length($self->{'parts'}->[$ppart]) . ") bytes\n" 
			if ($self->{'debug'} > 2);
		$io->print($self->{'parts'}->[$ppart++]);
	}
	$self->{'_ppart'} = $ppart;
}

sub print_percent
{
	my ($self, $p, $io) = @_;
	$p = 1 if $p > 1;
	$p = 0 if $p < 0;
	$self->print_parts(int($p * $#{$self->{'parts'}} + 0.5), $io);
}

sub print_header
{
	my ($self, $io) = @_;
	$io = defined($io) ? _wrap($io, 'w') : $self->{'output'};
	warn "printing header to $io\n" if ($self->{'debug'} > 1);
	$io->print($self->{'header'});
}

sub print_trailer
{
	my ($self, $io) = @_;
	$io = defined($io) ? _wrap($io, 'w') : $self->{'output'};
	warn "printing trailer to $io\n" if ($self->{'debug'} > 1);
	$io->print($self->{'trailer'});
}


1;	# return true, as require requires

__END__

#
######################################################################
#

=head1 NAME

Image::ParseGIF - Parse a GIF image into its compenent parts.

=head1 SYNOPSIS

  use Image::ParseGIF;

  $gif = new Image::ParseGIF ("image.gif") or die "failed to parse: $@\n";

  # write out a deanimated version, showing only the first frame
  $gif->deanimate(0);

  #  same again, manually printing each part
  print $gif->header;
  print $gif->part(0);
  print $gif->trailer;
  #  or, without passing scalars around:
  $gif->print_header;
  $gif->print_part(0);
  $gif->print_trailer;


  # send an animated gif frame by frame
  #  - makes for a progress bar which really means something
  $gif = new Image::ParseGIF ("progress.gif") or die "failed to parse: $@\n";

  $gif->print_header;

  $gif->print_percent(0.00);	# starting...
  do_some_work_stage1();

  $gif->print_percent(0.10);	# 10% complete
  do_some_work_stage2();

  $gif->print_percent(0.25);	# 25% complete
  do_some_work_stage3();

  $gif->print_percent(0.70);	# 70% complete
  do_some_work_stage4();

  $gif->print_percent(1.00);	# done!

  $gif->print_trailer;

=head1 DESCRIPTION

This module parses a Graphics Interchange Format (GIF) image into
its component 'parts'. A GIF is essentially made up of one or more 
images - multiple images typically are used for animated gifs.

=head2 PURPOSE

This module was written to allow a web application to display the status
of a request, without resorting to scripting or polling the server via 
client refresh.

Most web browsers (at least Netscape 2.02 & 4.05, Opera 3.21 and
Internet Explorer 4.0) show each frame as soon as it is received.
(Indeed, the GIF format is block-based so any image viewer which can
handle animated GIFs should operate similarly.) So, if we can arrange
for the parts of a progress bar image to be delivered to the client in
sympathy with the request's progress, we'll have made a dandy real-time
feedback mechanism. Contrast this with the common fixed animation used
at many sites, which are uncorrelated to the request state and not
at all realistic.

One implementation of this status mechanism involves the main application 
returning a page containing an image tag to a 'status' script (e.g. 
S<<img src="status.cgi?id="request_id">>). The status script interrogates 
the request's status (perhaps by reading from a pipe), and prints image frames 
as the request progresses.

At the moment the image is wholly read into memory. File
pointers could be used to operate from disk, however, given that most
web images are on the order of 1-100k, I don't see a lot of benefit in
bothering to do so.  Also, if a persistant application is used
(i.e. FCGI), the same image can be reused for many requests.

=head2 BACKGROUND

A gif image consists of:

=over

=item 1

a 'header' (including the GIF header (signature string) and logical screen 
descriptor)

=item 2 

a global colour map

=item 3 

zero or more 'graphic blocks' or 'extensions'

=over

=item *  

a block/extension header

=item *  

one or more sub-blocks per part

=back


=item 4  

a trailer

=back

Note that this module groups the GIF header, logical screen descriptor and
any global colour map into the 'header' part.

There are two types of 'descriptor blocks/extensions' defined in the GIF
specification [1]: an image descriptor; or an extension. Extensions can
contain 'control' information for things like animated gifs. Each descriptor
block/extension has its own 'header', often followed by one or more data
blocks. This module extracts only image descriptors and graphic control
extensions. Moreover, this module treats associated descriptor blocks and
extensions as a 'part' - an image 'part' is considered to be the extension/s
leading up to an image descriptor, plus the image descriptor.


=head1 CONSTRUCTOR / CLASS METHODS

In general, all C<Image::ParseGIF> methods return undef on error, possibly 
with an explanatory message in $@.

=over

=item autoflush ( STATE )

Class method (i.e. Image::ParseGIF::autoflush(0)). Sets default autoflush()
state for new output streams. On by default.

=item new ( [FILENAME] )

=item new ( FILENAME [,  ARGUMENTS ] )

=item new ( FILENAME [, {ARGUMENTS}] )

Creates a new C<Image::ParseGIF> object.

If FILENAME is supplied, opens and parses the given file.

ARGUMENTS may be:

=over

=item 'debug' (natural number)

Set the debug level.

=item 'output' (IO::Handle/filehandle/glob)

Sets the default output stream (default STDOUT). (See perl's binmode() 
regarding writing binary output.)

=item 'invert' (natural number)

Adjusts the colour inversion feature (default 0 is off).

=item 'posterize' (natural number)
=item 'posterise' (natural number)

Adjusts the colour posterization (high pass filtering) feature (default 0 is 
off, positive values increase the resulting gamut).

=item 'desaturate' (natural number)

Adjusts the colour-to-grayscale feature (default 0 is off).

=back

=back

=head1 METHODS

=over

=item debug ( LEVEL )

If LEVEL is omitted, returns the current debug level setting.

If LEVEL is defined, sets the current debug level.
The higher the debug level, the more output.

=item invert ( EXPR )

If EXPR is omitted, returns the current colour inversion setting.

If EXPR is defined, sets the current colour inversion setting.
Zero is off, nonzero inverts RGB colour table values,
leaving each one as a photo-negative colour instead.
Default is 0.

=item posterize ( EXPR )
=item posterise ( EXPR )

If EXPR is omitted, returns the current colour posterization setting.

If EXPR is defined (N), sets the current colour posterization setting.
Zero is off, nonzero posterizes RGB colour table values,
leaving each one to be one of N colors. Default is 0.

=item desaturate ( EXPR )

If EXPR is omitted, returns the current colour desaturization setting.

If EXPR is defined, sets the current colour desaturization setting.
Zero is off, nonzero desaturizes RGB colour table values,
leaving each one as a mean grayscale value.
Default is 0.

=item open ( FILENAME )

Opens the given file and C<parse>s it.

=item parse ( IO )

Parse a GIF, reading from a given filehandle / IO::Handle.

=item (header|trailer)

Returns the image (header|trailer) as a scalar.

=item parts

Returns a list of the image parts in array context, or the number of parts in 
scalar context. Does not include header or trailer.

=item part ( PART )

Returns an image part as a scalar. If PART == undef, returns header; 
if PART > number of parts, returns trailer.

= item output ( IO )

Specifies the default output filehandle / IO::Handle for all subsequent print_ 
calls. (See perl's binmode() regarding writing binary output.)

=item print_(header|trailer) ( [IO] )

Prints the (header|trailer) to the supplied / default output stream.

=item print_part ( [PART] [, IO] )

Prints the given PART to the supplied / default output stream.

=item print_parts ( [PART] [, IO] )

Remembers which part it was up to (PreviousPART), prints from from 
PreviousPART to PART to the supplied / default output stream.

=item print_percent ( PERCENT [, IO ] )

Prints PERCENT percent of the image frames. Remembers where it was up to, and 
will only print increasing part numbers (i.e. it won't duplicate parts). Note
you'll still need to print the header and trailer.

=item deanimate ( [PART] [, IO ] )

Prints header, given part (or part 0 if unspecified) and trailer to the 
supplied / default output stream.

=back


=head1 NOTES

You should be able to parse an image contained in any object which has
a read() method (e.g. IO::Scalar), however the object will have to support 
the OFFSET read() argument. As at version 1.114, IO::Scalar does not.

For example:
  $io = new IO::File ('blah');
  $gif = new Image::ParseGIF;
  $gif->parse($io) or die "failed to parse: $@\n";


=head1 "BUGS"

=over

=item 

It'd be nice to have a more generic interface to handle all GIF extensions, etc.

=item

And from the "In case you've ever wondered" department:

Natural Number (http://mathworld.wolfram.com/NaturalNumber.html)

"A positive integer 1, 2, 3, ... ([ref]). The set of natural numbers is
denoted N or Z+. Unfortunately, 0 is sometimes also included in the
list of ``natural'' numbers (Bourbaki 1968, Halmos 1974), and there
seems to be no general agreement about whether to include it.  In fact,
Ribenboim (1996) states ``Let [P] be a set of natural numbers; whenever
convenient, it may be assumed that [0 <element of> P].''"

=back

=head1 COPYRIGHT

Copyright (c) 1999/2000 University of New South Wales 
Benjamin Low <b.d.low@unsw.edu.au>. All rights reserved.

Colour-table portions added 1 June 2000 Ed Halley <ed@explorati.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Artistic License for more details.

=head1 AUTHORS

Benjamin Low <b.d.low@unsw.edu.au>

Ed Halley <ed@explorati.com>

=head1 SEE ALSO

This code was based on the CGI 89a spec [1] and the Image::DeAnim module
by Ken MacFarlane.

[1] http://member.aol.com/royalef/gif89a.txt


=cut
