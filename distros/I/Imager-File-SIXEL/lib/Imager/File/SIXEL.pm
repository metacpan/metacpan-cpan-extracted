package Imager::File::SIXEL;

use v5.24;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Imager 1.013;
use Scalar::Util qw(blessed);
use XSLoader;

our $VERSION = '1.001';

XSLoader::load(__PACKAGE__, $VERSION);

use constant MAX_PALETTE_SIZE => 256;
use constant MAX_PAGE         => 2147483647;

sub _readSingle($im, $io, %opts) {
	my $page = $opts{page} // 0;

	unless ($page =~ /\A[0-9]+\z/ && $page <= MAX_PAGE) {
		$im->_set_error('page must be a non-negative integer');
		return;
	}
	$im->{IMG} = i_readsixel($io, $page, $opts{allow_incomplete} ? 1 : 0);
	unless ($im->{IMG}) {
		$im->_set_error(Imager->_error_as_msg);
		return;
	}
	return $im;
}

sub _readMultiple($io, %opts) {
	my @images = i_readsixel_multi($io, $opts{allow_incomplete} ? 1 : 0);
	unless (@images) {
		Imager->_set_error(Imager->_error_as_msg);
		return;
	}
	return map { bless { IMG => $_, ERRSTR => undef }, 'Imager' } @images;
}

# True for a reference to an array of red, green and blue values, with
# an optional alpha value, each an integer from 0 to 255.
sub _isRgbArray($spec) {
	return 0 unless $spec->@* == 3 || $spec->@* == 4;
	foreach my $value ($spec->@*) {
		return 0 unless defined $value && !ref $value && $value =~ /\A[0-9]+\z/ && $value <= 255;
	}
	return 1;
}

# Converts one entry of the colors option into an Imager::Color, or
# returns undef.
sub _paletteColor($spec) {
	return unless defined $spec;
	return $spec if blessed($spec) && $spec->isa('Imager::Color');
	if (ref $spec eq 'ARRAY') {
		return unless _isRgbArray($spec);
		return Imager::Color->new($spec->@*);
	}
	return if ref $spec;
	return Imager::Color->new($spec);
}

# Converts the colors option into an array reference of Imager::Color
# objects. Returns an empty list after recording an error on $target.
sub _paletteOption($target, $colors) {
	return (1, undef) unless defined $colors;

	unless (ref $colors eq 'ARRAY') {
		$target->_set_error('colors must be an array reference');
		return;
	}
	unless ($colors->@* >= 1 && $colors->@* <= MAX_PALETTE_SIZE) {
		$target->_set_error('colors must hold from 1 to ' . MAX_PALETTE_SIZE . ' colors');
		return;
	}

	my @palette;
	foreach my $index (0 .. $colors->$#*) {
		my $color = _paletteColor($colors->[$index]);
		unless ($color) {
			$target->_set_error("colors entry $index is not a valid color");
			return;
		}
		push @palette, $color;
	}
	return (1, \@palette);
}

sub _writeSingle($im, $io, %opts) {
	my ($ok, $palette) = _paletteOption($im, $opts{colors});
	return unless $ok;

	$im->_set_opts(\%opts, 'sixel_', $im)
	  or return;

	unless (i_writesixel($io, $palette, $im->{IMG})) {
		$im->_set_error(Imager->_error_as_msg);
		return;
	}
	return $im;
}

sub _writeMultiple($class, $io, $opts, @images) {
	unless (@images) {
		$class->_set_error('no images to write');
		return;
	}
	my ($ok, $palette) = _paletteOption($class, $opts->{colors});
	return unless $ok;

	$class->_set_opts($opts, 'sixel_', @images)
	  or return;

	unless (i_writesixel_multi($io, $palette, map { $_->{IMG} } @images)) {
		$class->_set_error($class->_error_as_msg);
		return;
	}
	return 1;
}

Imager->register_reader(
	type     => 'sixel',
	single   => \&_readSingle,
	multiple => \&_readMultiple,
);

Imager->register_writer(
	type     => 'sixel',
	single   => \&_writeSingle,
	multiple => \&_writeMultiple,
);

Imager->add_type_extensions('sixel', 'six', 'sixel');
Imager->add_file_magic(name => 'sixel', bits => "\x1BP", mask => 'xx');

1;

__END__

=encoding UTF-8

=head1 NAME

Imager::File::SIXEL - read and write SIXEL images with Imager

=head1 SYNOPSIS

    use Imager;
    use Imager::File::SIXEL;

    # Show an image in a terminal that supports SIXEL.
    my $img = Imager->new(file => 'photo.png')
      or die Imager->errstr;
    $img->write(fh => \*STDOUT, type => 'sixel')
      or die $img->errstr;

    # Encode into a Perl string instead.
    my $sixel = '';
    $img->write(data => \$sixel, type => 'sixel', sixel_max_colors => 64)
      or die $img->errstr;

    # Write a SIXEL file and read it back.
    $img->write(file => 'photo.six')
      or die $img->errstr;
    my $decoded = Imager->new(file => 'photo.six')
      or die Imager->errstr;

    # Read every image of a file that holds several.
    my @images = Imager->read_multi(file => 'recording.six', type => 'sixel')
      or die Imager->errstr;

    # Write several images into one file.
    Imager->write_multi({ file => 'slides.six', type => 'sixel' }, @images)
      or die Imager->errstr;

=head1 DESCRIPTION

SIXEL is the bitmap graphics format of the DEC VT200 to VT300 series
of terminals. Many current terminal emulators understand it, among
them xterm, mlterm, foot, WezTerm, Contour, mintty, Windows Terminal,
iTerm2 and Konsole, which makes it a common way to show images inside
a terminal.

This module adds the file type C<sixel> to L<Imager>:

=over

=item *

B<Writing> turns any Imager image into SIXEL data that you can print
to a terminal or save to a file. You choose:

=over

=item *

how the colors are picked: L<C<sixel_palette>|/sixel_palette>,
L<C<sixel_max_colors>|/sixel_max_colors>, L<C<colors>|/colors>;

=item *

how colors that are not in the palette are approximated:
L<C<sixel_dither>|/sixel_dither>;

=item *

how transparency is handled:
L<C<sixel_alpha_threshold>|/sixel_alpha_threshold>;

=item *

the pixel aspect ratio: L<C<sixel_pan>|/sixel_pan>,
L<C<sixel_pad>|/sixel_pad>.

=back

=item *

B<Reading> turns SIXEL data, for example a file written by this module
or by C<img2sixel>, or a recording of terminal output, back into an
Imager image (L</READING>).

=back

The encoder is written in C and is fast enough to drive animations,
depending on the settings and the image (L</PERFORMANCE>).

You use this module through Imager's usual methods C<read()>,
C<read_multi()>, C<write()> and C<write_multi()> with
C<< type => 'sixel' >>. The module itself has no functions or methods
that you call directly.

=head2 Loading the module

    use Imager;
    use Imager::File::SIXEL;

Loading the module registers with Imager:

=over

=item *

the file type C<sixel> for reading and writing;

=item *

the file name extensions F<.six> and F<.sixel>, so that
C<< $img->write(file => 'picture.six') >> writes SIXEL without a
C<type> option;

=item *

detection of SIXEL data whose first two bytes are C<ESC P>, so that
C<< Imager->new(file => 'picture.six') >> or
C<< Imager->new(data => $sixel) >> reads SIXEL without a C<type>
option.

=back

Whether you need the C<use> line:

=over

=item *

With C<< type => 'sixel' >>, Imager loads the module by itself, so the
C<use> line is optional.

=item *

With a file name ending in F<.sixel> and no C<type>, Imager also loads
the module by itself, because the extension equals the type name.

=item *

When reading without C<type> from a file whose name ends in F<.six>,
or from C<data>, C<fh> or C<callback>, the module must already be
loaded. Otherwise Imager fails with a message such as
C<format 'six' not supported> or C<type parameter missing>.

=item *

When writing to a file whose name ends in F<.six> without C<type>,
the module must already be loaded too.

=item *

When writing, Imager takes the type from the file name extension. To
write SIXEL anywhere other than to a file ending in F<.six> or
F<.sixel>, pass C<< type => 'sixel' >>.

=back

Detection by content only works when the data starts with the 7-bit
introducer C<ESC P>. Data that starts with anything else, such as a
recording of a terminal session that begins with text, or the 8-bit
introducer byte 0x90, is not recognized by its content. Read it from
a file whose name ends in F<.six> or F<.sixel>, or pass
C<< type => 'sixel' >>.

=head1 DOCUMENTATION

The documentation of this module has three pages:

=over

=item L<Imager::File::SIXEL>

This page: loading the module, all read and write options, the tags,
how the palette is chosen, displaying images and animations in a
terminal, performance and error messages.

=item L<Imager::File::SIXEL::Examples>

Task-oriented examples for every feature, with figures that show what
each write option does to the image.

=item L<Imager::File::SIXEL::Format>

How the SIXEL format works, and exactly how this module reads and
writes it.

=back

=head1 TERMINOLOGY

=over

=item SIXEL data

The bytes that make up one or more SIXEL images. This is what you
print to a terminal.

=item SIXEL image

One image inside SIXEL data. Technically it is one I<device control
string>: it starts with C<ESC P> and ends with C<ESC \>, or with their
8-bit forms; see L<Imager::File::SIXEL::Format/What is read>. A file or
stream can hold several SIXEL images one after another.

=item color register

(Also spelled "colour"; this documentation uses "color" throughout.)
SIXEL images do not store a color per pixel. They define a small
table of colors, the color registers, and paint every pixel with one
of them. This module writes at most 256 registers per image.

=item palette

The colors the encoder puts into the color registers of a SIXEL image.
Every pixel is written in one of these colors. The list of colors
stored in a paletted Imager image is called its I<color table> in this
documentation, never its palette.

=item webmap

The fixed palette of 216 web-safe colors, the I<webmap palette>, selected with
C<< sixel_palette => 'webmap' >>; see L<C<sixel_palette>|/sixel_palette>.

=item adaptive palette

A palette computed from the colors of the image being written; the
default, see L<C<sixel_palette>|/sixel_palette>.

=item painted, unpainted

A pixel is painted when the SIXEL data sets it to a color. Unpainted
pixels show the background: transparent, or the background color,
see L<Imager::File::SIXEL::Format/Channels and transparency>.

=item raster attributes

A command at the start of the SIXEL data that declares the pixel aspect
ratio and the image size; see L<Imager::File::SIXEL::Format/THE SIXEL
FORMAT>.

=item dithering

Approximating a color that is not in the palette by a pattern of
palette colors, so that the eye mixes them into the intended color.

=item paletted image

An Imager image that stores an index into its own color table per
pixel (C<< $img->type eq 'paletted' >>), as opposed to a I<direct
color> image that stores the color itself
(C<< $img->type eq 'direct' >>). See L<Imager::ImageTypes>.

=item tag

A name and value stored on an Imager image, see L<Imager::ImageTypes/Tags>.
Some write options are stored as tags, see L</Write options are
stored on the image>.

=back

=head1 QUICK REFERENCE

=head2 Read options at a glance

Pass these to C<< $img->read(...) >>, C<< Imager->new(file => ...) >>
or C<< Imager->read_multi(...) >>.

=for highlighter language=text

    Option            Values                 Default  Effect
    ----------------  ---------------------  -------  ---------------------------------
    page              0, 1, 2, ...           0        which image of the data to read
    allow_incomplete  false or true          false    accept data that is cut off

Details: L<C<page>|/page>, L<C<allow_incomplete>|/allow_incomplete>.

=head2 Write options at a glance

Pass these to C<< $img->write(...) >> or C<< Imager->write_multi(...) >>.

    Option                 Values                            Default
    ---------------------  --------------------------------  -----------
    sixel_palette          'adaptive' or 'webmap'            'adaptive'
    sixel_max_colors       an integer from 1 to 256          256
    colors                 array ref of 1 to 256 colors      (none)
    sixel_dither           'diffusion', 'ordered' or 'none'  'diffusion'
    sixel_alpha_threshold  an integer from 0 to 255          128
    sixel_pan              an integer from 1 to 2147483647   1
    sixel_pad              an integer from 1 to 2147483647   1

    Option                 Effect
    ---------------------  ------------------------------------------------------
    sixel_palette          computed palette or the fixed 216-color webmap palette
    sixel_max_colors       largest number of colors the encoder picks itself
    colors                 your own palette
    sixel_dither           how colors missing from the palette are approximated
    sixel_alpha_threshold  which pixels of an image with alpha are transparent
    sixel_pan, sixel_pad   pixel aspect ratio (height to width)

Details: L</Write options>. The C<sixel_> options are stored on the
image as tags; C<colors> is not. See L</Write options are stored on
the image>.

=head2 Tags at a glance

    Tag           Value
    ------------  --------------------------------------------------------
    i_format      'sixel'
    sixel_pan     pixel aspect ratio, height part (1 for current encoders)
    sixel_pad     pixel aspect ratio, width part (1 for current encoders)
    i_incomplete  1 if the image was cut off (only with allow_incomplete)

Details: L</Tags set when reading>.

=head1 EXAMPLES

L<Imager::File::SIXEL::Examples> shows every feature in use, with
figures that show what each write option does to the image. Its
examples, by topic:

=head2 Showing and saving images

=over

=item *

L<Show an image in the terminal|Imager::File::SIXEL::Examples/Show an
image in the terminal>

=item *

L<Encode into a string|Imager::File::SIXEL::Examples/Encode into a string>

=item *

L<Save a SIXEL file and read it back|Imager::File::SIXEL::Examples/Save
a SIXEL file and read it back>

=item *

L<Convert a SIXEL file to PNG|Imager::File::SIXEL::Examples/Convert a
SIXEL file to PNG>

=item *

L<Write several images into one file
(C<write_multi>)|Imager::File::SIXEL::Examples/Write several images
into one file (write_multi)>

=back

=head2 Reading SIXEL data

=over

=item *

L<Read SIXEL data from a string or a
pipe|Imager::File::SIXEL::Examples/Read SIXEL data from a string or a
pipe>

=item *

L<Read one image of a file that holds
several|Imager::File::SIXEL::Examples/Read one image of a file that
holds several>

=item *

L<Read every image of a file|Imager::File::SIXEL::Examples/Read every
image of a file>

=item *

L<Read data that is cut off
(truncated)|Imager::File::SIXEL::Examples/Read data that is cut off
(truncated)>

=item *

L<Read untrusted data safely (limit memory and
time)|Imager::File::SIXEL::Examples/Read untrusted data safely (limit
memory and time)>

=back

=head2 Changing the look of the output

=over

=item *

L<Make the SIXEL data smaller|Imager::File::SIXEL::Examples/Make the
SIXEL data smaller>

=item *

L<Reduce the number of colors
(C<sixel_max_colors>)|Imager::File::SIXEL::Examples/Reduce the number
of colors (sixel_max_colors)>

=item *

L<Choose how colors are approximated
(C<sixel_dither>)|Imager::File::SIXEL::Examples/Choose how colors are
approximated (sixel_dither)>

=item *

L<Use the fixed webmap palette
(C<sixel_palette>)|Imager::File::SIXEL::Examples/Use the fixed webmap
palette (sixel_palette)>

=item *

L<Use your own (custom) palette
(C<colors>)|Imager::File::SIXEL::Examples/Use your own (custom) palette
(colors)>

=item *

L<Use the palette of a paletted image|Imager::File::SIXEL::Examples/Use
the palette of a paletted image>

=item *

L<Images with transparency
(C<sixel_alpha_threshold>)|Imager::File::SIXEL::Examples/Images with
transparency (sixel_alpha_threshold)>

=item *

L<Non-square pixels (C<sixel_pan>,
C<sixel_pad>)|Imager::File::SIXEL::Examples/Non-square pixels
(sixel_pan, sixel_pad)>

=back

=head2 Options, errors and animation

=over

=item *

L<Write the same image again with other settings (options are
remembered)|Imager::File::SIXEL::Examples/Write the same image again
with other settings (options are remembered)>

=item *

L<Handle errors|Imager::File::SIXEL::Examples/Handle errors>

=item *

L<Play an animation|Imager::File::SIXEL::Examples/Play an animation>

=back

=head1 READING

=for highlighter language=perl

    my $img = Imager->new;
    $img->read(file => 'image.six', type => 'sixel')
      or die $img->errstr;

    my @images = Imager->read_multi(file => 'stream.six', type => 'sixel')
      or die Imager->errstr;

Any input source that Imager supports works: C<file>, C<fh>, C<data>,
C<callback>, see L<Imager::Files>.

=head2 What is read

The decoder searches the input for SIXEL images and skips everything
else: text, escape sequences and other control strings before, between
and after the images. A recording of a terminal session can therefore
be read directly. Each SIXEL image becomes one Imager image:

=over

=item *

It has three channels (RGB), or four (RGB plus alpha) if the SIXEL
image declares that unpainted pixels are transparent.

=item *

It is a paletted image if it has at most 256 colors, and a direct
color image with 8 bits per sample otherwise.

=item *

It is at least as large as the painted area, and at least as large
as the size declared in its raster attributes.

=item *

Its pixels are not stretched to the pixel aspect ratio, which is
reported in the tags C<sixel_pan> and C<sixel_pad> instead.

=back

L<Imager::File::SIXEL::Format/READING> describes in detail which data
is accepted and how the decoded image is built.

=head2 Read options

=head3 C<page>

Which image to read with C<read()> or C<< Imager->new(...) >>, counting
from 0.

B<Values:> an integer from 0 to 2147483647.

B<Default:> 0, the first image.

C<read_multi()> ignores this option and returns every image.

=head3 C<allow_incomplete>

Whether to accept an image cut off by the end of the input
(truncated).

B<Values:> any Perl value, taken as true or false.

B<Default:> false.

If false, such an image makes the read fail with C<premature end of
SIXEL data>. If true, the part that was read is returned, and the tag
C<i_incomplete> is set to 1 on that image. If that part has no pixels
and declares no size, the read still fails, with
C<SIXEL image contains no pixels>. C<allow_incomplete> works the same
way with C<read_multi()>; there, a cut-off image is always the last
one, and the images before it are returned complete.

=head2 Tags set when reading

=over

=item C<i_format>

Always C<sixel>.

=item C<sixel_pan> and C<sixel_pad>

The pixel aspect ratio as height (C<sixel_pan>) to width
(C<sixel_pad>). The values come from the raster attributes, if the
image has them before its first pixel data and both values in them are
at least 1. Otherwise they come from the first parameter of the control
string (P1, see L<Imager::File::SIXEL::Format/THE SIXEL FORMAT>): 5:1
for P1 = 2; 3:1 for P1 = 3 or 4; 1:1 for P1 = 7, 8 or 9; and 2:1 for
any other value or without P1. Nearly all current encoders, including
this one, write 1:1 into the raster attributes, so both tags are 1 for
their images.

These tags are also write options. When you write an image that was
read from SIXEL data, its aspect ratio is therefore kept. Images made
from it with C<scale()>, C<copy()>, C<to_paletted()> and similar
methods do not carry the tags, so they are written with square
pixels.

=item C<i_incomplete>

1 if the end of the input cut the image off. Only set with
L<C<allow_incomplete>|/allow_incomplete>.

=back

=head2 Resource limits

Images larger than the limits set with C<< Imager->set_file_limits >>
are rejected, whether the size is declared in the SIXEL data or
results from the pixels painted. By default, Imager limits only the
memory of an image, to 1 GiB. The decoder also stops with the error
C<SIXEL data paints too many pixels> when the data paints the same
pixels over far more often than any real image does; the exact limit
is in L<Imager::File::SIXEL::Format/Resource limits>.

Before reading untrusted data, set file limits that fit your
application and limit the size of the input you accept, as shown in
L<Imager::File::SIXEL::Examples/Read untrusted data safely (limit
memory and time)>.

=head1 WRITING

    $img->write(file => 'image.six')
      or die $img->errstr;

    my $sixel = '';
    $img->write(data => \$sixel, type => 'sixel', sixel_dither => 'ordered')
      or die $img->errstr;

    Imager->write_multi({ file => 'frames.six', type => 'sixel' }, @images)
      or die Imager->errstr;

Any output target that Imager supports works: C<file>, C<fh>, C<data>,
C<callback>, see L<Imager::Files>. With C<file>, the type is taken from
the extension F<.six> or F<.sixel>; with the other targets, pass
C<< type => 'sixel' >>.

=head2 What is written

Each image is written as one SIXEL image in plain 7-bit ASCII, with
the image size and the pixel aspect ratio in its raster attributes and
at most 256 color registers. Images with an alpha channel are marked
so that unpainted pixels are transparent. C<write_multi()> writes the
images one after another, with nothing in between.

SIXEL expresses colors as percentages, 101 levels per channel instead
of 256, so every color is rounded to the nearest level. Writing an
image that was read from SIXEL data again loses nothing further, as
long as it is written with its own colors.

L<Imager::File::SIXEL::Format/WRITING> describes the exact output and
the color precision in detail.

=head2 Write options

Every option can be omitted. Invalid values make the write fail with a
message that names the option, before any SIXEL data is written (see
L</DIAGNOSTICS>). With C<write_multi()>, the options of all images are
checked before the first image is written.

Integer options take a decimal integer: an optional C<+> or C<->
followed by digits, with nothing else, not even spaces. Leading zeros
are allowed. A Perl number works if it turns into such a string, so
C<16> and C<16.0> are both 16, but the strings C<'16.0'>, C<' 16'>,
C<'0x10'> and C<'1e2'> are invalid. (One exception: a single trailing
line break, as in C<"16\n">, is accepted, because Imager stores such a
value as an integer.)

Keyword options must match exactly, including case and spaces:
C<'ordered'> is valid, C<'Ordered'> and C<'ordered '> are not.

Passing C<undef> for a C<sixel_> option removes the setting stored on
the image, so the default applies (see L</Write options are stored on
the image>).

Do not pass a reference other than an array reference as the value of
a C<sixel_> option:

=over

=item *

A hash or code reference makes the write fail with C<Unknown reference
type HASH supplied for sixel_dither> or a similar message. Other
C<sixel_> options passed with it may already be stored on the image
(see L</Write options are stored on the image>).

=item *

An L<Imager::Color> object is stored as a string such as
C<color(1,2,3,255)> and fails as an invalid value.

=item *

An array reference gives each image its own value with
C<write_multi()>, see below. With C<write()>, its first element is
used.

=back

With C<file>, Imager creates or empties the file before the options
are checked, so a write that fails because of an invalid option
leaves an empty file behind.

=head3 C<sixel_palette>

Which palette to use when L<C<colors>|/colors> is not given. With
C<'webmap'>, the webmap palette is always used. With C<'adaptive'>, an
image that has few enough colors is written with its own colors
instead; see L</How the palette is chosen>.

B<Values:> C<'adaptive'> or C<'webmap'>, in lowercase; the comparison
is case sensitive.

B<Default:> C<'adaptive'>.

B<Stored on the image:> yes, later writes use it too; see
L</Write options are stored on the image>.

=over

=item C<'adaptive'>

A palette of at most L<C<sixel_max_colors>|/sixel_max_colors> colors,
computed from the image so that it fits the image as well as possible.
It therefore differs from image to image. (How: the color histogram of
the image is divided into boxes, always splitting the box whose split
removes the most squared error; the box averages are then refined by
two rounds of k-means.)

=item C<'webmap'>

The webmap palette, 216 web-safe colors: every combination of the
levels 0, 20, 40, 60, 80 and 100 percent for red, green and blue. It
is the same for every image, so no palette has to be computed.
L<C<sixel_max_colors>|/sixel_max_colors> does not reduce it. Terminals
need at least 216 color registers to show it correctly.

=back

Figure: L<Imager::File::SIXEL::Examples/Use the fixed webmap palette
(sixel_palette)>.

=head3 C<sixel_max_colors>

The maximum number of colors (color registers) of a palette that the
encoder picks itself: the adaptive palette, or the image's own colors.

B<Values:> an integer from 1 to 256.

B<Default:> 256.

B<Stored on the image:> yes, later writes use it too; see
L</Write options are stored on the image>.

It limits the adaptive palette, and it decides whether an image is
written with its own colors (rules 3 and 4 of L</How the palette is
chosen>). It does not limit the webmap palette or a palette passed
with L<C<colors>|/colors>. Fewer colors give smaller SIXEL data and
faster drawing, at the cost of quality.

Figure: L<Imager::File::SIXEL::Examples/Reduce the number of colors
(sixel_max_colors)>.

=head3 C<colors>

Your own palette.

B<Values:> a reference to an array of 1 to 256 colors.

B<Default:> none.

B<Stored on the image:> no.

Each entry is one of:

=over

=item *

an L<Imager::Color> object;

=item *

a reference to an array of red, green and blue values, each an
integer from 0 to 255, such as C<[255, 128, 0]>; a fourth value, the
alpha value, is allowed;

=item *

a string that C<< Imager::Color->new >> accepts, such as C<'#FF8000'>
or C<'red'>.

=back

The alpha value of a color is ignored. L<Imager::Color::Float> objects
are not accepted.

    $img->write(data => \$sixel, type => 'sixel',
                colors => ['#000000', [255, 255, 255], 'red']);

C<colors> takes precedence over L<C<sixel_palette>|/sixel_palette> and
L<C<sixel_max_colors>|/sixel_max_colors>. Every pixel is written in
one of these colors, approximated as set by
L<C<sixel_dither>|/sixel_dither>.

Figure: L<Imager::File::SIXEL::Examples/Use your own (custom) palette
(colors)>.

=head3 C<sixel_dither>

How pixels whose color is not in the palette are written.

B<Values:> C<'diffusion'>, C<'ordered'> or C<'none'>, in lowercase;
the comparison is case sensitive.

B<Default:> C<'diffusion'>.

B<Stored on the image:> yes, later writes use it too; see
L</Write options are stored on the image>.

=over

=item C<'diffusion'>

Floyd-Steinberg error diffusion in serpentine order. It gives the best
still images. However, a change anywhere in the image changes the dot
pattern of everything below it, which flickers in animations.

=item C<'ordered'>

An 8 x 8 Bayer matrix whose strength follows the spacing of the
palette colors. The pattern is tied to the pixel position. With a fixed
palette (webmap or L<C<colors>|/colors>), areas of an image that did
not change therefore stay identical from one animation frame to the
next.

=item C<'none'>

Each pixel gets the palette color nearest to it in RGB space; on a tie,
the color with the lower register number. Of the three settings, this
usually gives the smallest SIXEL data, especially with a fixed palette,
but smooth gradients turn into visible bands.

=back

With C<'diffusion'> and C<'ordered'>, the nearest palette color is
looked up with each channel reduced to 64 levels instead of 256, which
is faster; the dithering compensates for the small error this adds. Images
written with their own colors (rules 3 and 4 of L</How the palette is
chosen>) are never dithered, because every pixel is in the palette.

Figure: L<Imager::File::SIXEL::Examples/Choose how colors are
approximated (sixel_dither)>.

=head3 C<sixel_alpha_threshold>

Which pixels of an image with an alpha channel are left transparent.

B<Values:> an integer from 0 to 255.

B<Default:> 128.

B<Stored on the image:> yes, later writes use it too; see
L</Write options are stored on the image>.

Pixels whose alpha value is below the threshold are not painted, so
the terminal background shows through. All other pixels are painted in
their color, ignoring their alpha value. With 0, every pixel is
painted, including fully transparent ones, in the color stored in
their red, green and blue channels; areas of a new image that were
never drawn on are black. The option has no effect on images without
an alpha channel.

Figure: L<Imager::File::SIXEL::Examples/Images with transparency
(sixel_alpha_threshold)>.

=head3 C<sixel_pan>

The height part of the pixel aspect ratio written into the image. Each
pixel is C<sixel_pan / sixel_pad> times as high as it is wide.

B<Values:> an integer from 1 to 2147483647.

B<Default:> 1.

B<Stored on the image:> yes, later writes use it too; see
L</Write options are stored on the image>.

Terminals that honor the ratio stretch the image accordingly; others
ignore it. Images read from SIXEL data carry the tags C<sixel_pan> and
C<sixel_pad>, so they keep their aspect ratio when written again.

Figure: L<Imager::File::SIXEL::Examples/Non-square pixels (sixel_pan,
sixel_pad)>.

=head3 C<sixel_pad>

The width part of the pixel aspect ratio; see L<C<sixel_pan>|/sixel_pan>.

B<Values:> an integer from 1 to 2147483647.

B<Default:> 1.

B<Stored on the image:> yes, later writes use it too; see
L</Write options are stored on the image>.

=head2 Write options are stored on the image

This module stores every write option whose name starts with
C<sixel_> as a tag of the same name on the image before writing it,
following the convention of Imager's own file formats. This has three
consequences:

=over

=item *

You can set the options as tags instead of passing them:

    $img->settag(name => 'sixel_dither', value => 'ordered');
    $img->write(file => 'a.six');    # uses ordered dithering

=item *

The options stay on the image and apply to later writes of the same
image. To return to the default, pass the option with the default value
or with C<undef>, or delete the tag with C<< $img->deltag(name =>
'sixel_dither') >>. See L<Imager::File::SIXEL::Examples/Write the same
image again with other settings (options are remembered)>.

=item *

An invalid value is stored like a valid one. Later writes of the same
image fail in the same way until you pass a valid value or C<undef>,
or delete the tag.

=back

With C<write_multi()>:

=over

=item *

A C<sixel_> option passed to C<write_multi()> is stored on every image,
replacing any value stored there before.

=item *

If the value is an array reference, its elements are stored on the
images in order: the first element on the first image, and so on.
Images beyond the end of the array keep their own setting. For
example, C<< sixel_pan => [2, 3] >> stores 2 on the first image and 3
on the second.

=item *

A C<sixel_> option that is not passed is taken from each image's own
tag, if it has one. To write the images with different settings, set
the tags on the images and do not pass the options.

=back

The C<colors> option is not stored.

=head2 How the palette is chosen

The first rule that applies decides:

=over

=item 1.

If L<C<colors>|/colors> is given, that palette is used.

=item 2.

If L<C<sixel_palette>|/sixel_palette> is C<'webmap'>, the webmap
palette is used.

=item 3.

If the image is a paletted image whose color table has at most
L<C<sixel_max_colors>|/sixel_max_colors> entries, its color table is
used: color register I<n> holds color table entry I<n>, except that
an entry that rounds to the same SIXEL percentages as an earlier entry
uses the register of that earlier entry. This is the
fastest way and loses nothing apart from the rounding to SIXEL
percentages. Use it to control the palette yourself, see
L<Imager::File::SIXEL::Examples/Use the palette of a paletted image>.

=item 4.

If the painted pixels of the image (see
L<C<sixel_alpha_threshold>|/sixel_alpha_threshold>) have at most
L<C<sixel_max_colors>|/sixel_max_colors> different colors, these
colors are used. The colors are counted after they are rounded to
SIXEL percentages, so two colors that round to the same percentages
count once and share a color register.

=item 5.

Otherwise an adaptive palette of at most
L<C<sixel_max_colors>|/sixel_max_colors> colors is computed.

=back

In rules 3 and 4 every pixel color is in the palette, so
L<C<sixel_dither>|/sixel_dither> has no effect.

=head2 Image types and bit depth

Images of any type and sample size can be written:

=over

=item *

Gray (grayscale) images are written as RGB.

=item *

Samples with more than 8 bits (16-bit and double precision images)
are reduced to 8 bits before the colors are rounded to SIXEL
percentages.

=item *

Images with an alpha channel, gray or color, are written with P2 = 1,
so that unpainted pixels are transparent; see
L<C<sixel_alpha_threshold>|/sixel_alpha_threshold>.

=back

=head1 DISPLAYING IMAGES IN A TERMINAL

The terminal draws SIXEL data at the text cursor. Where the cursor is
afterwards depends on the terminal: usually on the line below the
image, in some terminals on the last text line the image covers. Print
a line break after the image so that the next output starts below it.

=over

=item *

Send the data to the terminal unchanged. This encoder writes plain
ASCII without line breaks, which I/O layers such as C<:crlf> or
C<:encoding(UTF-8)> leave intact. SIXEL data from other sources can
contain line breaks or 8-bit control bytes such as 0x90, which these
layers would change. Set C<binmode STDOUT, ':raw'> before you send
SIXEL data, and the data arrives unchanged in either case.

=item *

C<< $img->write(fh => $handle, ...) >> writes through the handle's I/O
layers and buffer, exactly like C<print>, so the advice above applies
to it as well. Layers that change every byte, such as
C<:encoding(UTF-16LE)>, corrupt the data. In-memory handles
(C<open my $fh, '>', \$buffer>) and tied handles work.

=item *

Scale large images down to the size at which they should appear
before writing them. Large images take long to transfer and draw.

=item *

Terminal multiplexers such as tmux and GNU screen pass SIXEL data
through only if they support it and are configured to do so.

=back

=head2 Does my terminal support SIXEL?

A terminal that supports SIXEL answers the primary device attributes
request, C<ESC [ c>, with a list of numbers separated by semicolons,
and one of these numbers is C<4>. To check by hand, run this in bash
or zsh:

=for highlighter language=sh

    printf '\e[c'; read -r -s -t 1 -d c answer; echo "${answer#*\[}"

It prints the answer, for example C<?62;4;6;22> or C<?64;1;4;22>. Both
of these contain the number C<4> (the C<4> inside C<64> does not
count), so the terminal supports SIXEL. If only an empty line is
printed, the terminal did not answer within one second. Some terminals
need SIXEL switched on. xterm, for example, must emulate a VT340 and,
for images with more than 16 colors, needs more color registers than
the 16 of the VT340:

    xterm -ti vt340 -xrm 'XTerm*numColorRegisters: 256'

=head2 Terminals with fewer than 256 color registers

Such terminals draw an image with wrong colors when the image uses
more colors than they have registers. For them, set
L<C<sixel_max_colors>|/sixel_max_colors> to their register count, do
not use the webmap palette, which needs 216 registers, and do not pass
more colors with L<C<colors>|/colors> than the terminal has registers.

=head1 ANIMATION

The encoder is fast enough for real-time animation. Encode each frame
into a string and draw it at a fixed position:

=for highlighter language=perl

    use Imager;
    use Imager::File::SIXEL;
    use Time::HiRes qw(sleep time);

    binmode STDOUT, ':raw';
    STDOUT->autoflush(1);

    print "\e[?25l\e[2J";    # hide the cursor, clear the screen
    my $fps = 30;
    my $start = time;
    for my $n (0 .. 299) {
      my $frame = render_frame($n);    # your code; returns an Imager image

      my $sixel = '';
      $frame->write(data => \$sixel, type => 'sixel',
                    sixel_palette => 'webmap', sixel_dither => 'ordered')
        or die $frame->errstr;

      # Move the cursor to the top left corner and draw the frame
      # as one synchronized update.
      print "\e[?2026h\e[H", $sixel, "\e[?2026l";

      my $wait = $start + ($n + 1) / $fps - time;
      sleep $wait if $wait > 0;
    }
    print "\e[?25h\n";    # show the cursor again

C<ESC [ ? 2026 h> and C<ESC [ ? 2026 l> begin and end a synchronized
update, which keeps the terminal from showing half-drawn frames.
Terminals that do not support it ignore these sequences.

The frame must fit into the terminal window with at least one text line
to spare below it. Otherwise the terminal scrolls after each frame and
the frames jump. The script F<examples/sixel-animate.pl> in the
distribution is a complete version of this loop.

Recommendations:

=over

=item *

Use a fixed palette: C<< sixel_palette => 'webmap' >>, or one palette
computed once for the whole animation and passed with L<C<colors>|/colors>:

    my @palette = Imager->make_palette({ make_colors => 'mediancut' },
                                       @sample_frames);
    $frame->write(data => \$sixel, type => 'sixel',
                  colors => \@palette, sixel_dither => 'ordered');

An adaptive palette is computed for each frame anew. Any change to the
image can change the palette and with it every pixel of the frame.

=item *

Use C<< sixel_dither => 'ordered' >> or C<< sixel_dither => 'none' >>.
With a fixed palette, both leave unchanged areas unchanged;
C<'diffusion'> does not.

=item *

The terminal, not the encoder, usually limits the frame rate: it has to
receive, parse and draw every frame. Smaller frames, fewer colors
(L<C<sixel_max_colors>|/sixel_max_colors>), C<< sixel_dither => 'none' >>,
and the webmap palette combined with C<'ordered'> or C<'none'>
dithering all reduce the amount of SIXEL data per frame; see the table
in L</PERFORMANCE>.

=back

=head1 PERFORMANCE

The encoder builds the palette from a color histogram, maps the pixels
through a lookup table of nearest palette colors, and writes the SIXEL
data band by band. Each band's pixels are grouped by color in linear
time, split into runs of columns, and packed into as few passes over
the band as possible (see L<Imager::File::SIXEL::Format/THE SIXEL
FORMAT>). In fully painted bands, the first pass paints whole columns
that later passes paint over, so that it compresses into long repeats.
On the author's test images, the SIXEL data for the same pixels was
typically 4 to 20 percent smaller than that of libsixel 1.10.5 with
adaptive palettes, and more with fixed palettes. For very simple images
both are about the same size.

The table shows the times for one complete
C<< $img->write(data => \$buffer, type => 'sixel') >> call, measured
with F<examples/sixel-bench.pl> on an Intel Core i5-12600K with Perl
5.38 and Imager 1.033, in milliseconds per call (ms), the resulting
frames per second (fps) and the size of the SIXEL data in bytes. The
"Synth" columns are for the benchmark's default image, smooth
gradients with noise. The "Photo" columns are for F<snake.png> from
the libsixel distribution, a photograph with fine detail, which is
about the hardest case for the encoder.

=for highlighter language=text

    Size     Dither     Palette   Synth ms  Synth fps  Synth bytes  Photo ms  Photo fps  Photo bytes
    -------  ---------  --------  --------  ---------  -----------  --------  ---------  -----------
    256x256  diffusion  adaptive       2.1        472        70607       5.5        182        98613
    256x256  ordered    adaptive       1.5        685        65440       3.7        270       110899
    256x256  none       adaptive       1.7        603        65944       4.8        207        89583
    256x256  ordered    webmap         0.9       1155        36965       1.5        680        52080
    256x256  none       webmap         0.6       1629         9256       1.5        673        25949
    192x128  diffusion  adaptive       0.9       1073        27619       3.1        324        45451
    192x128  ordered    adaptive       0.7       1483        26704       2.4        419        49446
    192x128  none       adaptive       0.8       1307        26971       2.9        342        42365
    192x128  ordered    webmap         0.5       2200        15222       0.8       1277        22875
    192x128  none       webmap         0.3       3814         3885       0.8       1280        12476
    640x480  diffusion  adaptive       8.9        112       373095      15.4         65       341301
    640x480  ordered    adaptive       5.8        172       329641       8.7        115       389983
    640x480  none       adaptive       6.4        157       329569      11.4         88       267180
    640x480  ordered    webmap         3.3        305       160163       4.3        231       203313
    640x480  none       webmap         3.0        335        49565       4.2        236        73404

Every setting encodes all three sizes of both images at more than 60
frames per second on this machine. At 640 x 480, the default settings
leave the least headroom, which is one reason why ordered dithering is
recommended for animations. To measure your own machine and images,
run F<examples/sixel-bench.pl>, which accepts C<--file>. Decoding a
640 x 480 image takes about 5 milliseconds.

=head1 DIAGNOSTICS

Failures are reported through C<< $img->errstr >> or C<< Imager->errstr
>> as usual; see L<Imager::File::SIXEL::Examples/Handle errors>. The
messages specific to this module are listed here. C<N> stands for a
number. In the C<unknown ... value> messages, C<...> stands for the
value you passed; in C<file size limit - ...>, for Imager's
explanation.

=head2 Messages when reading

=over

=item C<no SIXEL image found>

The input holds no SIXEL image. With a L<C<page>|/page> above 0, the
message is C<SIXEL page N not found> instead.

=item C<SIXEL page N not found>

The input holds fewer than N + 1 images, so the image that the
L<C<page>|/page> option asks for does not exist.

=item C<page must be a non-negative integer>

The L<C<page>|/page> option is not an integer from 0 to 2147483647.

=item C<premature end of SIXEL data>

The input ends inside an image; see L<C<allow_incomplete>|/allow_incomplete>.

=item C<SIXEL image contains no pixels>

An image paints no pixel and declares no size, so there is nothing to
return.

=item C<SIXEL data paints too many pixels>

The data paints over the same pixels far more often than any real
image does; see L</Resource limits>.

=item C<image dimensions are too large>

=item C<file size limit - ...>

The image is larger than the limits set with
C<< Imager->set_file_limits >> or larger than the decoder supports;
see L</Resource limits>.

=item C<read failed>

The file or handle read from reported an error.

=back

=head2 Messages when writing

=over

=item C<sixel_max_colors must be an integer from 1 to 256>

=item C<sixel_alpha_threshold must be an integer from 0 to 255>

=item C<sixel_pan must be an integer from 1 to 2147483647>

=item C<sixel_pad must be an integer from 1 to 2147483647>

The option has a value that is not an integer or is out of range; see
L</Write options>. The value may come from a tag stored by an earlier
write, see L</Write options are stored on the image>.

=item C<unknown sixel_palette value '...'>

=item C<unknown sixel_dither value '...'>

The option has a value that is not one of its keywords; see
L<C<sixel_palette>|/sixel_palette> and
L<C<sixel_dither>|/sixel_dither>. Keywords are case sensitive:
C<'Webmap'> fails, C<'webmap'> works.

=item C<colors must be an array reference>

=item C<colors must hold from 1 to 256 colors>

=item C<colors entry N is not a valid color>

The L<C<colors>|/colors> option is not an array reference, has too few or too
many entries, or entry N (counting from 0) is not a color. An array of
values is not a color if it does not hold 3 or 4 integers from 0 to
255.

=item C<Unknown reference type ... supplied for ...>

A C<sixel_> option has a reference as its value that is neither an
array reference nor, inside an array, an L<Imager::Color> object; see
L</Write options>. This message comes from Imager.

=item C<no images to write>

C<write_multi()> was called without images.

=item C<image too large to encode>

The image is too wide or too large for the encoder's buffers in
memory.

=item C<cannot read the image palette>

Imager could not return the palette of a paletted image. This points
to a problem in Imager or in the image object, not in your options.

=item C<write failed>

=item C<error closing output>

The file or handle written to reported an error, for example because
the disk is full. Imager buffers the output, so the error often only
shows when the buffer is written out at the end, as C<error closing
output>.

=back

=head2 Messages when reading or writing

=over

=item C<out of memory>

Memory could not be allocated.

=back

=head1 LIMITATIONS

=over

=item *

The encoder uses at most 256 color registers per image. The decoder
accepts up to 1024.

=item *

Colors are limited to the 101 levels per channel that SIXEL
percentages can express; see L<Imager::File::SIXEL::Format/Color precision>.

=item *

Semi-transparent pixels are either painted fully or not at all; see
L<C<sixel_alpha_threshold>|/sixel_alpha_threshold>. SIXEL has no
partial transparency.

=item *

The decoder does not stretch images whose pixel aspect ratio is not
1:1; see L<Imager::File::SIXEL::Format/Pixel aspect ratio>.

=item *

The horizontal grid size parameter (P3) of the control string is
ignored, as current terminals do.

=back

=head1 EXAMPLE PROGRAMS

The F<examples> directory of the distribution holds three complete
programs. Each one prints its options with C<--help>.

=over

=item examples/sixel-cat.pl

Shows image files in the terminal, in any format that Imager can
read, with options for size, dithering and number of colors.

=for highlighter language=sh

    perl examples/sixel-cat.pl --width 400 --dither ordered photo.jpg

=item examples/sixel-animate.pl

Plays a generated animation and reports the frame rate reached and the
time spent encoding.

    perl examples/sixel-animate.pl --width 320 --height 240 --fps 30

=item examples/sixel-bench.pl

Measures the encoding speed for several image sizes and settings, as in
L</PERFORMANCE>.

    perl examples/sixel-bench.pl --file photo.png --sizes 640x480

=back

=head1 INSTALLATION

Requirements: Perl 5.24 or later, Imager 1.013 or later with its
headers, and a C compiler. With L<cpanm|App::cpanminus>:

    cpanm Imager::File::SIXEL

From a source checkout:

    cpanm --installdeps .
    perl Makefile.PL
    make
    make test
    make install

=head1 SEE ALSO

L<Imager::File::SIXEL::Examples>, L<Imager::File::SIXEL::Format>.

L<Imager>, L<Imager::Files>, L<Imager::ImageTypes>.

The SIXEL chapter of the VT330/VT340 Programmer Reference Manual:
L<https://vt100.net/docs/vt3xx-gp/chapter14.html>.

libsixel, the reference implementation of SIXEL encoding and decoding:
L<https://github.com/libsixel/libsixel>.

The source code: L<https://github.com/davenonymous/perl-imager-sixel>.

=head1 AUTHOR

davenonymous E<lt>dave@davenonymous.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 davenonymous.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
