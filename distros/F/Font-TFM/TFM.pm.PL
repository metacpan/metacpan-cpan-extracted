use Config;
my $filename = $0;
$filename =~ s/\.PL$//;

my $dir = '.';
if (@ARGV and $ARGV[0] =~ /^-dTEXFONTSDIR=/) {
	( $dir = shift ) =~ s/^-dTEXFONTSDIR=//;
}

open OUT,">$filename" or die "Can't create $filename: $!";
chmod(0755, $filename);
print "Extracting $filename (setting \$TEXFONTSDIR to `$dir')\n";


print OUT <<'EOF';

=head1 NAME

Font::TFM -- read information from TeX font metric files

=cut


package Font::TFM;
use strict;
use vars qw( $VERSION $DEBUG $TEXFONTSDIR $TEXFONTSUSELS
	$LSFILENAME $MULTIPLY $errstr );

# ################
# Global variables
#
$VERSION = '1.01';
$errstr = '';
$DEBUG = 0;
sub DEBUG ()	{ $DEBUG; }
sub Error {
	$errstr = join '', @_;
	print STDERR @_, "\n" if $DEBUG;
}

EOF

print OUT qq!\$TEXFONTSDIR = '$dir';\n!;

print OUT <<'EOF';
$TEXFONTSUSELS = 1;
$LSFILENAME = "ls-R";
$MULTIPLY = 65536;

# #####################
# Load new font at size
#
sub new_at {
	my ($class, $fontname, $size) = @_;
	new($class, 'name' => $fontname, 'at' => $size);
}

# ########################
# Load new font with scale
#
sub new {
	my $class = shift;
	my %opts = ();
	if (@_ > 2 or (@_ == 2 and $_[1] !~ /^(\d*\.)?\d+$/)) {
		if (@_ % 2) {
			$opts{name} = shift;
		}
		%opts = @_;
	} else {
		@opts{'name', 'scale'} = @_;
	}
	
	# make the object
	my $self = bless {}, $class;

	my ($file_handle);
	eval {
		$file_handle = $self->open_tfm(%opts);
	};
	if ($@) {
		Error($@); return;
	}

	# read header
	my $buffer = '';
	if (read($file_handle, $buffer, 24) != 24) {
		Error("Error reading TFM header: $!"); return;
	}

	# get 12 fields of the header
	@{$self}{ qw(length headerlength smallest largest numwidth
		numheight numdepth numic numligkern numkern numext numparam) }
			= unpack "n12", $buffer;
	$self->{numofchars} = $self->{largest} - $self->{smallest} + 1;
	$self->{'length'} = $self->{'length'} * 4 - 24;
	$self->{headerlength} *= 4;

	# read rest of the file
	if (read($file_handle, $buffer, $self->{'length'})
		!= $self->{'length'}) {
			Error("Error reading body: $!"); return;
	}
	close $file_handle;

	my $headerrestlength = $self->{headerlength} - 18 * 4;

	my ($face, $headerrest, @charinfo, @width, @height, @depth,
		@italic, @ligkern, @kern, @exten);

	# split the file into various arrays
	(@{$self}{ qw(checksum designsize codingschemestringlength
		codingscheme familystringlength family sevenbitsafe ) },
	undef, undef, $face,
	$headerrest,
	@charinfo[0 .. $self->{numofchars} - 1],
	@width[0 .. $self->{numwidth} - 1],
	@height[0 .. $self->{numheight} - 1],
	@depth[0 .. $self->{numdepth} - 1],
	@italic[0 .. $self->{numic} - 1],
	@ligkern[0 .. $self->{numligkern} - 1],
	@kern[0 .. $self->{numkern} - 1],
	@exten[0 .. $self->{numext} - 1],
	@{$self->{param}}[1 .. $self->{numparam}],
	)
		= unpack "NNCA39CA19C4a$headerrestlength" .
			"a4" x $self->{numofchars} .
			"N$self->{numwidth}N$self->{numheight}N$self->{numdepth}N$self->{numic}" .
			"a4" x $self->{numligkern} .
			"N$self->{numkern}" .
			"a4" x $self->{numext} .
			"N$self->{numparam}", $buffer;
	# the unpack above does all the work, isn't it neat?
	
	$self->{designsize} = getfixword($self->{designsize});

	my $fontsize = $self->{designsize};
	if (defined $opts{at}) {
		$fontsize = $opts{at};
	} elsif (defined $opts{scale}) {
		$fontsize *= $opts{scale};
	}
	$self->{fontsize} = $fontsize;
	my $multiplysize = $fontsize * 
		( defined $opts{'multiply'} ? $opts{'multiply'} : $MULTIPLY );

	if ($self->{sevenbitsafe}) {
		$self->{sevenbitsafe} = 1;
	}

	$self->{face} = "";		# computation of face seems useless
	if ($face < 18) {
		my ($weight, $slope, $expansion) = ("M", "R", "R");
		if ($face - 12 >= 0) { $expansion = "E"; $face -= 12; }
		elsif ($face - 6 >= 0) { $expansion = "C"; $face -= 6; }
		if ($face - 4 >= 0) { $weight = "L"; $face -= 4; }
		elsif ($face - 2 >= 0) { $weight = "B"; $face -= 2; }
		if ($face > 0) { $slope = "I"; }
		$self->{face} = "$weight$slope$expansion";
	}

	@{$self->{headerrest}}[0 .. $headerrestlength] = split //, $headerrest;

	@width = map { getfixword($_) * $multiplysize } @width;
	@height = map { getfixword($_) * $multiplysize } @height;
	@depth = map { getfixword($_) * $multiplysize } @depth;
	@italic = map { getfixword($_) * $multiplysize } @italic;
	@kern = map { getfixword($_) * $multiplysize } @kern;
	$self->{param}[1] = getfixword($self->{param}[1]);
	@{$self->{param}}[2 .. $self->{numparam}] =
		map { getfixword($_) * $multiplysize }
			@{$self->{param}}[2 .. $self->{numparam}];
					# compute the actual dimensions

	if (@ligkern) {		# check for boundary char
		my ($skip, $next, $opbyte, $remainder);
		($skip, $next) = unpack "Ca1", $ligkern[0];
		if ($skip == 255) {
			$self->{"boundary"} = $next;
		}
		($skip, $next, $opbyte, $remainder) = unpack
			"Ca1CC", $ligkern[$#ligkern];
		if ($skip == 255) {
			process_lig_kern($self, "boundary", \@ligkern,
				256 * $opbyte + $remainder, \@kern);
		}
	}

	for (0 .. $self->{numofchars} - 1) {
		my $char = pack "C", $_ + $self->{smallest};
		my ($wid, $heidep, $italtag, $remainder)
			= unpack "C4", $charinfo[$_];
		next if ($wid == 0);
					# set up dimensions of the character
		($self->{width}{$char}, $self->{height}{$char},
			$self->{depth}{$char}, $self->{italic}{$char})
			= ($width[$wid], $height[$heidep >> 4],
			$depth[$heidep & 0x0f], $italic[$italtag >> 2]);
			
		my $tag = $italtag & 0x03;	# other info
		if ($tag == 1) {		# lig/kern program
			process_lig_kern($self, $char, \@ligkern, $remainder, \@kern);
		}
		elsif ($tag == 2) {		# larger character
			$self->{larger}{$char} = pack "C", $remainder;
		}
		elsif ($tag == 3) {		# extensible character
			my ($top, $mid, $bot, $rep) = unpack "C4", $exten[$remainder];
			$self->{extentop}{$char} = pack "C", $top if $top;
			$self->{extenmid}{$char} = pack "C", $mid if $mid;
			$self->{extenbot}{$char} = pack "C", $bot if $bot;
			$self->{extenrep}{$char} = $rep;
		}
	}
	$self;
}

# ###################################
# Open the file and return filehandle
#
sub open_tfm {
	my ($self, %opts) = @_;
	my $filename;
	if (defined $opts{file}) {
		$filename = $opts{file}
	} elsif (defined $opts{name}) {
		$filename = find_tfm_file(%opts) or
			die "No tfm file found for font $opts{name}";
	} else {
		die "Either font name or file name has to be specified";
	}

	# try to open the file
	print STDERR "Loading $filename\n" if DEBUG;
	open TFMFILE, $filename or
		die "Error opening $filename: $!";
	binmode TFMFILE;

	$self->{name} = $filename;
	$self->{name} =~ s/\.tfm$//i;
	$self->{name} =~ s!^.*/!!;

	return(\*TFMFILE);
}

# ###################################################
# Process the ligature/kerning program for a character
#
sub process_lig_kern {
	my ($self, $char, $ligkernref, $prognum, $kernref) = @_;
	my $firstinstr = 1;
	while (1) {
		my ($skipbyte, $nextchar, $opbyte, $remainder)
			= unpack "Ca1CC", $ligkernref->[$prognum];
		if ($firstinstr) {
			if ($skipbyte > 128) {
				$prognum = 256 * $opbyte + $remainder;
				($skipbyte, $nextchar, $opbyte, $remainder)
					= unpack "Ca1CC", $ligkernref->[$prognum];
			}
		}
		if ($opbyte >= 128
			and not exists $self->{kern}{$char .  $nextchar}) {
			$self->{kern}{$char . $nextchar}
				= $kernref->[ 256 * ($opbyte - 128)
							+ $remainder];
		}
		if ($opbyte < 128
			and not exists $self->{lig}{$char .  $nextchar}) {
			my ($a, $b, $c) = ($opbyte >> 2, ($opbyte >> 1) & 0x01, $opbyte & 0x01);
			my $out = "";
			$out .= $char if $b;
			$out .= pack "C", $remainder;
			$out .= $nextchar if $c;
			$self->{lig}{$char . $nextchar} = $out;
			$self->{ligpassover}{$char . $nextchar} = $a;
		}
		last if ($skipbyte >= 128);
		$prognum += $skipbyte + 1;
		$firstinstr = 0;
	}
}

# #################
# Find the TFM file
#
sub find_tfm_file {
	my %opts = @_;
	my $fontname = $opts{name};
	$fontname .= ".tfm" unless $fontname =~ /\.tfm$/i;
	print STDERR "Font::TFM::find_tfm_file: \$fontname = $fontname\n" if DEBUG;
	my $directory;
	for $directory (split /:/,
		(defined $opts{path} ? $opts{path} : $TEXFONTSDIR)) {
		print STDERR "Font::TFM::find_tfm_file: \$directory = $directory\n" if DEBUG;
		my $file = find_tfm_file_in_directory(%opts,
			name => $fontname, dir => $directory);
		return $file if defined $file;
	}
	return;
}
sub find_tfm_file_in_directory {
	my %opts = @_;
	my ($fontname, $directory) = ($opts{name}, $opts{dir});
	$directory .= '/' unless $directory eq '';
	my $tfmfile = "$directory$fontname";
	my $lsfile = "$directory$LSFILENAME";
	print STDERR "Font::TFM::find_tfm_file_in_directory: \$directory = $directory\n" if DEBUG;
	if (-f $tfmfile) {
		return $tfmfile;
	}
	my $usels = $TEXFONTSUSELS;
	if (defined $opts{usels}) {
		$usels = 1;
		$usels = 0 if $opts{usels} eq '0' or $opts{usels} eq 'no';
	}
	if (-f $lsfile and $usels) {
		my $file = find_tfm_file_in_ls($fontname, $lsfile);
		return $file if defined $file;
	}
	else {
		my $subdir;
		for $subdir (<$directory/*>) {
			next unless -d $subdir;
			my $file = find_tfm_file_in_directory(%opts,
							dir => $subdir);
			return $file if defined $file;
		}
	}
	return;
}
sub find_tfm_file_in_ls {
	my ($fontname, $lsfile) = @_;
	my $lsdir = $lsfile;
	$lsdir =~ s!/$LSFILENAME$!!;
	print STDERR "Font::TFM::find_tfm_file_in_ls: \$lsfile = $lsfile\n" if DEBUG;
	print STDERR "Font::TFM::find_tfm_file_in_ls: \$lsdir = $lsdir\n" if DEBUG;
	if (not open LSFILE, $lsfile) {
		Error("Error opening $lsfile: $!"); return;
	}
	local ($/) = "\n";
	while (<LSFILE>) {
		chomp;
		if (/:$/) {
			$lsdir = $_;
			$lsdir =~ s!:$!!;
			print STDERR "Font::TFM::find_tfm_file_in_ls: \$lsdir = $lsdir\n" if (DEBUG > 10);
		}
		elsif ($_ eq $fontname) {
			my $file = "$lsdir/$fontname";
			if (-f $file) {
				close LSFILE;
				print STDERR "file $fontname found in $lsfile\n" if DEBUG;
				return $file;
			}
		}
	}
	print STDERR "file $fontname not found in $lsfile\n" if DEBUG;
	return;
}
sub getfixword {
	my $val = $_[0];
	my $p = pack "L", $val;
	if ($val & 0x80000000) {
		$val = unpack "l", $p;
	}
	return ($val / (1 << 20));
}
sub kern {
	my ($self, $double, $second) = @_;
	$double .= $second if (defined $second);
	if (defined $self->{kern}{$double}) {
		return $self->{kern}{$double};
	}
	return 0;
}
sub lig {
	my ($self, $double, $second) = @_;
	$double .= $second if (defined $second);
	if (defined $self->{lig}{$double}) {
		return $self->{lig}{$double};
	}
	return undef;
}
sub ligpassover {
	my ($self, $double) = @_;
	$self->{ligpassover}{$double};
}
sub param {
	my ($self, $param) = @_;
	$self->{param}[$param];
}
sub word_dimensions {
	my ($self, $text) = @_;
	my @expanded = $self->expand($text);
	my ($width, $height, $depth) = (0, 0, 0);
	while (@expanded) {
		my $word = shift @expanded;
		while ($word =~ /./sg) {
			my $char = $&;
			$width += $self->width($char);
			my $newval = $self->height($char);
			$height = $newval if ($newval > $height);
			$newval = $self->depth($char);
			$depth = $newval if ($newval > $depth);
		}
                last if (not @expanded);
		$width += shift @expanded;
	}
	($width, $height, $depth);
}
sub expand {
	my ($self, $text) = @_;
	my $pos = 0;
	
	# ligature substitutions
	while ($pos < (length $text) - 1) {
		my $found;
		my $substr = substr $text, $pos, 2;
		$found = $self->lig(substr $text, $pos, 2);
		if (defined $found) {
			substr($text, $pos, 2) = $found;
			$pos += $self->ligpassover($substr);
		}
		else
			{ $pos++ }
	}

	# kerning processing
	my @out = ();
	my $currentstring = substr $text, 0, 1;
	while ($text =~ /(.)(?=(.))/gs) {
		if ($self->kern($1 . $2)) {
			push @out, $currentstring;
			$currentstring = '';
			push @out, $self->kern($1 . $2);
		}
		$currentstring .= $2
	}
	push @out, $currentstring;
	@out;
}


my %PARAM_NAMES = ( slant => 1, space => 2, spacestretch => 3,
	spaceshrink => 4, xheight => 5, emwidth => 6, quad => 6,
	extraspace => 7,
);
my @GENERAL_NAMES = qw( fontsize designsize name checksum codingscheme );
my @CHAR_NAMES = qw( width height depth italic );
my %WORD_NAMES = ( word_width => 0, word_height => 1, word_depth => 2 );
my %MATH_SY_NAMES = ( num1 => 8, num2 => 9, num3 => 10,
	denom1 => 11, denom2 => 12,
	sup1 => 13, sup2 => 14, sup3 => 15,
	sub1 => 16, sub2 => 17,
	supdrop => 18,
	subdrop => 19,
	delim1 => 20, delim2 => 21,
	axisheight => 22,
);
my %MATH_EX_NAMES = (
	defaultrulethickness => 8,
	bigopspacing1 => 9,
	bigopspacing2 => 10,
	bigopspacing3 => 11,
	bigopspacing4 => 12,
	bigopspacing5 => 13,
);

use vars qw( $AUTOLOAD );
sub AUTOLOAD {
	my $self = shift;
	my $function = $AUTOLOAD;
	local ($_);
	$function =~ s/^.*:://;
	$function =~ s/_//g;
	print STDERR "Autoloading $function\n" if DEBUG;
	return ($self->word_dimensions(shift))[$WORD_NAMES{$function}]
		if defined $WORD_NAMES{$function};
	return $self->{'param'}[$PARAM_NAMES{$function}]
		if (defined $PARAM_NAMES{$function});
	return $self->{$function}{$_[0]}
		if grep { $_ eq $function } @CHAR_NAMES;
	return $self->{$function}
		if grep { $_ eq $function } @GENERAL_NAMES;
	if ($self->{codingscheme} eq 'TeX math symbols'
		and defined $MATH_SY_NAMES{$function}) {
		return $self->{'param'}[$MATH_SY_NAMES{$function}]
	}
	if ($self->{codingscheme} eq 'TeX math extension'
		and defined $MATH_EX_NAMES{$function}) {
		return $self->{'param'}[$MATH_EX_NAMES{$function}]
	}
	die "Method $function not defined for $self";
}

sub Version	{ $VERSION; }
sub DESTROY {}
1;

__END__

=head1 SYNOPSIS

	use Font::TFM;  
	my $cmr = new Font::TFM name => 'cmr10'
		or die "Error reading font: $Font::TFM::errstr\n";
	print 'Designsize: ', $cmr->designsize(), "\n";
	print $cmr->width('A'), ', ', $cmr->kern('Wo'), "\n";

should print

	Designsize: 10
	491521.25, -54613.75

=head1 DESCRIPTION

To read the information from TFM (TeX font metrics) file, you first
create the object of B<Font::TFM> class in memory. You do this by
calling method B<Font::TFM::new> with font name and other parameters
and it creates a new TFM object in memory, loading all the necessary
information from the C<.tfm> file.

The parameters are passed to B<Font::TFM::new> in a form of a hash:

=over 4

=item name

Name of the font, for example cmr10. The file with the font is
searched for in the directories specified by the global variable
I<$Font::TFM::TEXFONTSDIR> or by a B<path> parameter.

=item file

Alternatively, instead of B<name>, you can specify full path to the
font file, for example /usr/lib/tex/fonts/cmr10.tfm. You have to
specify complete path, including the suffix if the file has any.

=item scale

If you want to load the font information at different size than the
design size, use this parameter, setting scale. The default is of
course 1.

=item at

If you want to load the font information at different size than the
design size, use this parameter, size in points (pt). Using B<at>
overrides B<scale>.

=item path

Colon separated value list of directories that fill be searched if you
specify the font by name. By default, global value
I<$Font::TFM::TEXFONTSDIR> is used.

=item usels

Value 1 tells B<Font::TFM::new> to use pregenerated listings of
directory contents, this is the default. The name of the file with the
listing is in global variable I<$Font::TFM::LSFILENAME> and defaults
to C<ls-R>.

To switch this behaviour off, use value 0 or 'no' for parameter
B<usels>, or set global variable I<$Font::TFM::TEXFONTSUSELS> to 0.

=item multiply

Dimensions reported by the object that you receive from
B<Font::TFM::new> are multiplied by value of I<$Font::TFM::MULTIPLY> *
actual size. Value of I<$Font::TFM::MULTIPLY> defaults to 65536 and
you can change it by this parameter when loading individual fonts.
of the font. Value 65536 is nice because the dimensions can be used
directly when writing the C<.dvi> file.

=back

If the file is not found (or there is some other problem), B<new>
returns C<undef> and sets error message to I<$Font::TFM::errstr>.

Examples:

	$cmr10 = new Font::TFM 'cmr10';
	$cmr10 = new Font::TFM 'name' => 'cmr10';
	$cmr10 = new Font::TFM 'file' => './dir/cmr10.tfm';
	$cmr12_14 = new Font::TFM 'name' => 'cmr12', at => 14
		or die 'Error loading font cmr12 at 14 pt: '
			. $Font::TFM::errstr;

For backward compatibility, you can use B<Font::TFM::new> with just
one parameter, the font name, or with two parameters, the font name
and the scale of the size, instead of the hash of parameters and
values. For backward compatibility, you can use B<Font::TFM::new_at>
with two parameters, font name and point size of the font.

After the file was loaded, you can use the following methods of
the object to query information about the font's properties and
about the characters, etc.

=over 4

=item designsize, fontsize

Returns the design size and the actual size of the font in pt.

	$cmr->designsize;	returns 10
	$cmr->fontsize;			10
	$cmr10_12->fontsize;		12

=item coding_scheme

Returns the coding scheme of the font.

	$cmr->coding_scheme;	returns TeX text

=item width, height, depth, italic

Returns the requested dimension for a specified character of
the font.

	$cmr->height("A")		447828.75
	$cmr10_12->height("A")		537394.5
	$cmr->italic("I")		0
	$cmr10_12->italic("f")		61167.75

=item kern, lig, ligpassover

For a two-letter string returns kern between them, ligature formed and
number of characters to pass over after the ligature, respectivelly.

	$cmr->lig("fi")			\014
	$cmr->lig("ff")			\013
	$cmr->lig("\013i")		\016
	$cmr10_12->kern("AV")		-87381.75

=item expand

One string parameter undergoes ligature expansion and then kernings
are inserted. Returns array containing of string, kern, string, ...

	$cmr->expand("AV--fix")		"A", -72818.125, "V{\014x"

=item word_dimensions

Returns the width, height and depth of a word. Does the lig/kern
expansion, so the result is the real space it will take on output.

	$cmr->word_dimensions("AV--fix")
					1947881.875, 455111.25, 0
	$cmr->word_dimensions("pm")	910225, 282168.75, 127431.25

=item word_width, word_height, word_depth

Calls C<word_dimensions> and returns appropriate element. No caching
is done, so it is better to call C<word_dimensions> yourself if you
will need more than one dimension of one word.

=item param

Returns parameter of the font, indexed from 1.

=item slant, x_height, em_width, quad

=item space, space_stretch, space_shrink, extra_space

Returns the parameter of the font, by name.

	$cmr->slant()			0
	$cmsl10->slant()		0.166671752929688
	$cmr->x_height()		282168.75
	$cmr->height("x")		282168.75
	$cmr->em_width()		655361.875
	$cmr->quad()			655361.875

	$cmr->space()			218453.75
	$cmr->space_stretch()		109226.875
	$cmtt10->space()		344061.25
	$cmtt10->space_stretch()	0

=item Additional parameters for math fonts

When the coding scheme of the font is TeX math symbols, there are
additional parameters num1 to num2, denom1 and denom2, sup1 to sup3,
sub1 and sub2, supdrop and subdrop, delim1 and delim2, and
axis_height available.

When the coding scheme is TeX math extension, there are additional
parameters default_rule_thickness and big_op_spacing1 through
big_op_spacing5.

=item name

Returns the name of the font.

=back

Variable I<$Font::TFM::DEBUG> may be set to 1 to get the processing
messages on the standard error output.

The module is subclassable. You can define you own module that would
provide alternate way of finding and opening the file. Just make new
module and define your own method open_tfm in it.

=head1 VERSION

1.01

=head1 AVAILABLE FROM

http://www.adelton.com/perl/Font-TFM/

=head1 AUTHOR

(c) 1996--2011 Jan Pazdziora.

All rights reserved. This package is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

Contact the author at jpx dash perl at adelton dot com.

=head1 SEE ALSO

TFtoPL for description of the TFM format, TeX::DVI(3),
TeX::DVI::Parse(3).

=cut

EOF
