# NAME

Imager::File::SIXEL - read and write SIXEL images with Imager

# SYNOPSIS

```perl
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
```

# DESCRIPTION

SIXEL is the bitmap graphics format of the DEC VT200 to VT300 series
of terminals. Many current terminal emulators understand it, among
them xterm, mlterm, foot, WezTerm, Contour, mintty, Windows Terminal,
iTerm2 and Konsole, which makes it a common way to show images inside
a terminal.

This module adds the file type `sixel` to [Imager](https://metacpan.org/pod/Imager):

- **Writing** turns any Imager image into SIXEL data that you can print
to a terminal or save to a file. You choose:
    - how the colors are picked: [`sixel_palette`](#sixel_palette),
    [`sixel_max_colors`](#sixel_max_colors), [`colors`](#colors);
    - how colors that are not in the palette are approximated:
    [`sixel_dither`](#sixel_dither);
    - how transparency is handled:
    [`sixel_alpha_threshold`](#sixel_alpha_threshold);
    - the pixel aspect ratio: [`sixel_pan`](#sixel_pan),
    [`sixel_pad`](#sixel_pad).
- **Reading** turns SIXEL data, for example a file written by this module
or by `img2sixel`, or a recording of terminal output, back into an
Imager image (["READING"](#reading)).

The encoder is written in C and is fast enough to drive animations,
depending on the settings and the image (["PERFORMANCE"](#performance)).

You use this module through Imager's usual methods `read()`,
`read_multi()`, `write()` and `write_multi()` with
`type => 'sixel'`. The module itself has no functions or methods
that you call directly.

## Loading the module

```perl
use Imager;
use Imager::File::SIXEL;
```

Loading the module registers with Imager:

- the file type `sixel` for reading and writing;
- the file name extensions `.six` and `.sixel`, so that
`$img->write(file => 'picture.six')` writes SIXEL without a
`type` option;
- detection of SIXEL data whose first two bytes are `ESC P`, so that
`Imager->new(file => 'picture.six')` or
`Imager->new(data => $sixel)` reads SIXEL without a `type`
option.

Whether you need the `use` line:

- With `type => 'sixel'`, Imager loads the module by itself, so the
`use` line is optional.
- With a file name ending in `.sixel` and no `type`, Imager also loads
the module by itself, because the extension equals the type name.
- When reading without `type` from a file whose name ends in `.six`,
or from `data`, `fh` or `callback`, the module must already be
loaded. Otherwise Imager fails with a message such as
`format 'six' not supported` or `type parameter missing`.
- When writing to a file whose name ends in `.six` without `type`,
the module must already be loaded too.
- When writing, Imager takes the type from the file name extension. To
write SIXEL anywhere other than to a file ending in `.six` or
`.sixel`, pass `type => 'sixel'`.

Detection by content only works when the data starts with the 7-bit
introducer `ESC P`. Data that starts with anything else, such as a
recording of a terminal session that begins with text, or the 8-bit
introducer byte 0x90, is not recognized by its content. Read it from
a file whose name ends in `.six` or `.sixel`, or pass
`type => 'sixel'`.

# DOCUMENTATION

The documentation of this module has three pages:

- [Imager::File::SIXEL](README.md)

    This page: loading the module, all read and write options, the tags,
    how the palette is chosen, displaying images and animations in a
    terminal, performance and error messages.

- [Imager::File::SIXEL::Examples](docs/Examples.md)

    Task-oriented examples for every feature, with figures that show what
    each write option does to the image.

- [Imager::File::SIXEL::Format](docs/Format.md)

    How the SIXEL format works, and exactly how this module reads and
    writes it.

# TERMINOLOGY

- SIXEL data

    The bytes that make up one or more SIXEL images. This is what you
    print to a terminal.

- SIXEL image

    One image inside SIXEL data. Technically it is one _device control
    string_: it starts with `ESC P` and ends with `ESC \`, or with their
    8-bit forms; see ["What is read" in Imager::File::SIXEL::Format](docs/Format.md#what-is-read). A file or
    stream can hold several SIXEL images one after another.

- color register

    (Also spelled "colour"; this documentation uses "color" throughout.)
    SIXEL images do not store a color per pixel. They define a small
    table of colors, the color registers, and paint every pixel with one
    of them. This module writes at most 256 registers per image.

- palette

    The colors the encoder puts into the color registers of a SIXEL image.
    Every pixel is written in one of these colors. The list of colors
    stored in a paletted Imager image is called its _color table_ in this
    documentation, never its palette.

- webmap

    The fixed palette of 216 web-safe colors, the _webmap palette_, selected with
    `sixel_palette => 'webmap'`; see [`sixel_palette`](#sixel_palette).

- adaptive palette

    A palette computed from the colors of the image being written; the
    default, see [`sixel_palette`](#sixel_palette).

- painted, unpainted

    A pixel is painted when the SIXEL data sets it to a color. Unpainted
    pixels show the background: transparent, or the background color,
    see ["Channels and transparency" in Imager::File::SIXEL::Format](docs/Format.md#channels-and-transparency).

- raster attributes

    A command at the start of the SIXEL data that declares the pixel aspect
    ratio and the image size; see ["THE SIXEL
    FORMAT" in Imager::File::SIXEL::Format](docs/Format.md#the-sixel-format).

- dithering

    Approximating a color that is not in the palette by a pattern of
    palette colors, so that the eye mixes them into the intended color.

- paletted image

    An Imager image that stores an index into its own color table per
    pixel (`$img->type eq 'paletted'`), as opposed to a _direct
    color_ image that stores the color itself
    (`$img->type eq 'direct'`). See [Imager::ImageTypes](https://metacpan.org/pod/Imager%3A%3AImageTypes).

- tag

    A name and value stored on an Imager image, see ["Tags" in Imager::ImageTypes](https://metacpan.org/pod/Imager%3A%3AImageTypes#Tags).
    Some write options are stored as tags, see ["Write options are
    stored on the image"](#write-options-are-stored-on-the-image).

# QUICK REFERENCE

## Read options at a glance

Pass these to `$img->read(...)`, `Imager->new(file => ...)`
or `Imager->read_multi(...)`.

| Option             | Values        | Default | Effect                          |
| ------------------ | ------------- | ------- | ------------------------------- |
| `page`             | 0, 1, 2, ...  | 0       | which image of the data to read |
| `allow_incomplete` | false or true | false   | accept data that is cut off     |

Details: [`page`](#page), [`allow_incomplete`](#allow_incomplete).

## Write options at a glance

Pass these to `$img->write(...)` or `Imager->write_multi(...)`.

| Option                  | Values                           | Default     |
| ----------------------- | -------------------------------- | ----------- |
| `sixel_palette`         | 'adaptive' or 'webmap'           | 'adaptive'  |
| `sixel_max_colors`      | an integer from 1 to 256         | 256         |
| `colors`                | array ref of 1 to 256 colors     | (none)      |
| `sixel_dither`          | 'diffusion', 'ordered' or 'none' | 'diffusion' |
| `sixel_alpha_threshold` | an integer from 0 to 255         | 128         |
| `sixel_pan`             | an integer from 1 to 2147483647  | 1           |
| `sixel_pad`             | an integer from 1 to 2147483647  | 1           |

| Option                   | Effect                                                 |
| ------------------------ | ------------------------------------------------------ |
| `sixel_palette`          | computed palette or the fixed 216-color webmap palette |
| `sixel_max_colors`       | largest number of colors the encoder picks itself      |
| `colors`                 | your own palette                                       |
| `sixel_dither`           | how colors missing from the palette are approximated   |
| `sixel_alpha_threshold`  | which pixels of an image with alpha are transparent    |
| `sixel_pan`, `sixel_pad` | pixel aspect ratio (height to width)                   |

Details: ["Write options"](#write-options). The `sixel_` options are stored on the
image as tags; `colors` is not. See ["Write options are stored on
the image"](#write-options-are-stored-on-the-image).

## Tags at a glance

| Tag            | Value                                                    |
| -------------- | -------------------------------------------------------- |
| `i_format`     | 'sixel'                                                  |
| `sixel_pan`    | pixel aspect ratio, height part (1 for current encoders) |
| `sixel_pad`    | pixel aspect ratio, width part (1 for current encoders)  |
| `i_incomplete` | 1 if the image was cut off (only with allow_incomplete)  |

Details: ["Tags set when reading"](#tags-set-when-reading).

# EXAMPLES

[Imager::File::SIXEL::Examples](docs/Examples.md) shows every feature in use, with
figures that show what each write option does to the image. Its
examples, by topic:

## Showing and saving images

- [Show an image in the terminal](docs/Examples.md#show-an-image-in-the-terminal)
- [Encode into a string](docs/Examples.md#encode-into-a-string)
- [Save a SIXEL file and read it back](docs/Examples.md#save-a-sixel-file-and-read-it-back)
- [Convert a SIXEL file to PNG](docs/Examples.md#convert-a-sixel-file-to-png)
- [Write several images into one file
(`write_multi`)](docs/Examples.md#write-several-images-into-one-file-write_multi)

## Reading SIXEL data

- [Read SIXEL data from a string or a
pipe](docs/Examples.md#read-sixel-data-from-a-string-or-a-pipe)
- [Read one image of a file that holds
several](docs/Examples.md#read-one-image-of-a-file-that-holds-several)
- [Read every image of a file](docs/Examples.md#read-every-image-of-a-file)
- [Read data that is cut off
(truncated)](docs/Examples.md#read-data-that-is-cut-off-truncated)
- [Read untrusted data safely (limit memory and
time)](docs/Examples.md#read-untrusted-data-safely-limit-memory-and-time)

## Changing the look of the output

- [Make the SIXEL data smaller](docs/Examples.md#make-the-sixel-data-smaller)
- [Reduce the number of colors
(`sixel_max_colors`)](docs/Examples.md#reduce-the-number-of-colors-sixel_max_colors)
- [Choose how colors are approximated
(`sixel_dither`)](docs/Examples.md#choose-how-colors-are-approximated-sixel_dither)
- [Use the fixed webmap palette
(`sixel_palette`)](docs/Examples.md#use-the-fixed-webmap-palette-sixel_palette)
- [Use your own (custom) palette
(`colors`)](docs/Examples.md#use-your-own-custom-palette-colors)
- [Use the palette of a paletted image](docs/Examples.md#use-the-palette-of-a-paletted-image)
- [Images with transparency
(`sixel_alpha_threshold`)](docs/Examples.md#images-with-transparency-sixel_alpha_threshold)
- [Non-square pixels (`sixel_pan`,
`sixel_pad`)](docs/Examples.md#non-square-pixels-sixel_pan-sixel_pad)

## Options, errors and animation

- [Write the same image again with other settings (options are
remembered)](docs/Examples.md#write-the-same-image-again-with-other-settings-options-are-remembered)
- [Handle errors](docs/Examples.md#handle-errors)
- [Play an animation](docs/Examples.md#play-an-animation)

# READING

```perl
my $img = Imager->new;
$img->read(file => 'image.six', type => 'sixel')
  or die $img->errstr;

my @images = Imager->read_multi(file => 'stream.six', type => 'sixel')
  or die Imager->errstr;
```

Any input source that Imager supports works: `file`, `fh`, `data`,
`callback`, see [Imager::Files](https://metacpan.org/pod/Imager%3A%3AFiles).

## What is read

The decoder searches the input for SIXEL images and skips everything
else: text, escape sequences and other control strings before, between
and after the images. A recording of a terminal session can therefore
be read directly. Each SIXEL image becomes one Imager image:

- It has three channels (RGB), or four (RGB plus alpha) if the SIXEL
image declares that unpainted pixels are transparent.
- It is a paletted image if it has at most 256 colors, and a direct
color image with 8 bits per sample otherwise.
- It is at least as large as the painted area, and at least as large
as the size declared in its raster attributes.
- Its pixels are not stretched to the pixel aspect ratio, which is
reported in the tags `sixel_pan` and `sixel_pad` instead.

["READING" in Imager::File::SIXEL::Format](docs/Format.md#reading) describes in detail which data
is accepted and how the decoded image is built.

## Read options

### `page`

Which image to read with `read()` or `Imager->new(...)`, counting
from 0.

**Values:** an integer from 0 to 2147483647.

**Default:** 0, the first image.

`read_multi()` ignores this option and returns every image.

### `allow_incomplete`

Whether to accept an image cut off by the end of the input
(truncated).

**Values:** any Perl value, taken as true or false.

**Default:** false.

If false, such an image makes the read fail with `premature end of
SIXEL data`. If true, the part that was read is returned, and the tag
`i_incomplete` is set to 1 on that image. If that part has no pixels
and declares no size, the read still fails, with
`SIXEL image contains no pixels`. `allow_incomplete` works the same
way with `read_multi()`; there, a cut-off image is always the last
one, and the images before it are returned complete.

## Tags set when reading

- `i_format`

    Always `sixel`.

- `sixel_pan` and `sixel_pad`

    The pixel aspect ratio as height (`sixel_pan`) to width
    (`sixel_pad`). The values come from the raster attributes, if the
    image has them before its first pixel data and both values in them are
    at least 1. Otherwise they come from the first parameter of the control
    string (P1, see ["THE SIXEL FORMAT" in Imager::File::SIXEL::Format](docs/Format.md#the-sixel-format)): 5:1
    for P1 = 2; 3:1 for P1 = 3 or 4; 1:1 for P1 = 7, 8 or 9; and 2:1 for
    any other value or without P1. Nearly all current encoders, including
    this one, write 1:1 into the raster attributes, so both tags are 1 for
    their images.

    These tags are also write options. When you write an image that was
    read from SIXEL data, its aspect ratio is therefore kept. Images made
    from it with `scale()`, `copy()`, `to_paletted()` and similar
    methods do not carry the tags, so they are written with square
    pixels.

- `i_incomplete`

    1 if the end of the input cut the image off. Only set with
    [`allow_incomplete`](#allow_incomplete).

## Resource limits

Images larger than the limits set with `Imager->set_file_limits`
are rejected, whether the size is declared in the SIXEL data or
results from the pixels painted. By default, Imager limits only the
memory of an image, to 1 GiB. The decoder also stops with the error
`SIXEL data paints too many pixels` when the data paints the same
pixels over far more often than any real image does; the exact limit
is in ["Resource limits" in Imager::File::SIXEL::Format](docs/Format.md#resource-limits).

Before reading untrusted data, set file limits that fit your
application and limit the size of the input you accept, as shown in
["Read untrusted data safely (limit
memory and time)" in Imager::File::SIXEL::Examples](docs/Examples.md#read-untrusted-data-safely-limit-memory-and-time).

# WRITING

```perl
$img->write(file => 'image.six')
  or die $img->errstr;

my $sixel = '';
$img->write(data => \$sixel, type => 'sixel', sixel_dither => 'ordered')
  or die $img->errstr;

Imager->write_multi({ file => 'frames.six', type => 'sixel' }, @images)
  or die Imager->errstr;
```

Any output target that Imager supports works: `file`, `fh`, `data`,
`callback`, see [Imager::Files](https://metacpan.org/pod/Imager%3A%3AFiles). With `file`, the type is taken from
the extension `.six` or `.sixel`; with the other targets, pass
`type => 'sixel'`.

## What is written

Each image is written as one SIXEL image in plain 7-bit ASCII, with
the image size and the pixel aspect ratio in its raster attributes and
at most 256 color registers. Images with an alpha channel are marked
so that unpainted pixels are transparent. `write_multi()` writes the
images one after another, with nothing in between.

SIXEL expresses colors as percentages, 101 levels per channel instead
of 256, so every color is rounded to the nearest level. Writing an
image that was read from SIXEL data again loses nothing further, as
long as it is written with its own colors.

["WRITING" in Imager::File::SIXEL::Format](docs/Format.md#writing) describes the exact output and
the color precision in detail.

## Write options

Every option can be omitted. Invalid values make the write fail with a
message that names the option, before any SIXEL data is written (see
["DIAGNOSTICS"](#diagnostics)). With `write_multi()`, the options of all images are
checked before the first image is written.

Integer options take a decimal integer: an optional `+` or `-`
followed by digits, with nothing else, not even spaces. Leading zeros
are allowed. A Perl number works if it turns into such a string, so
`16` and `16.0` are both 16, but the strings `'16.0'`, `' 16'`,
`'0x10'` and `'1e2'` are invalid. (One exception: a single trailing
line break, as in `"16\n"`, is accepted, because Imager stores such a
value as an integer.)

Keyword options must match exactly, including case and spaces:
`'ordered'` is valid, `'Ordered'` and `'ordered '` are not.

Passing `undef` for a `sixel_` option removes the setting stored on
the image, so the default applies (see ["Write options are stored on
the image"](#write-options-are-stored-on-the-image)).

Do not pass a reference other than an array reference as the value of
a `sixel_` option:

- A hash or code reference makes the write fail with `Unknown reference
type HASH supplied for sixel_dither` or a similar message. Other
`sixel_` options passed with it may already be stored on the image
(see ["Write options are stored on the image"](#write-options-are-stored-on-the-image)).
- An [Imager::Color](https://metacpan.org/pod/Imager%3A%3AColor) object is stored as a string such as
`color(1,2,3,255)` and fails as an invalid value.
- An array reference gives each image its own value with
`write_multi()`, see below. With `write()`, its first element is
used.

With `file`, Imager creates or empties the file before the options
are checked, so a write that fails because of an invalid option
leaves an empty file behind.

### `sixel_palette`

Which palette to use when [`colors`](#colors) is not given. With
`'webmap'`, the webmap palette is always used. With `'adaptive'`, an
image that has few enough colors is written with its own colors
instead; see ["How the palette is chosen"](#how-the-palette-is-chosen).

**Values:** `'adaptive'` or `'webmap'`, in lowercase; the comparison
is case sensitive.

**Default:** `'adaptive'`.

**Stored on the image:** yes, later writes use it too; see
["Write options are stored on the image"](#write-options-are-stored-on-the-image).

- `'adaptive'`

    A palette of at most [`sixel_max_colors`](#sixel_max_colors) colors,
    computed from the image so that it fits the image as well as possible.
    It therefore differs from image to image. (How: the color histogram of
    the image is divided into boxes, always splitting the box whose split
    removes the most squared error; the box averages are then refined by
    two rounds of k-means.)

- `'webmap'`

    The webmap palette, 216 web-safe colors: every combination of the
    levels 0, 20, 40, 60, 80 and 100 percent for red, green and blue. It
    is the same for every image, so no palette has to be computed.
    [`sixel_max_colors`](#sixel_max_colors) does not reduce it. Terminals
    need at least 216 color registers to show it correctly.

Figure: ["Use the fixed webmap palette
(sixel\_palette)" in Imager::File::SIXEL::Examples](docs/Examples.md#use-the-fixed-webmap-palette-sixel_palette).

### `sixel_max_colors`

The maximum number of colors (color registers) of a palette that the
encoder picks itself: the adaptive palette, or the image's own colors.

**Values:** an integer from 1 to 256.

**Default:** 256.

**Stored on the image:** yes, later writes use it too; see
["Write options are stored on the image"](#write-options-are-stored-on-the-image).

It limits the adaptive palette, and it decides whether an image is
written with its own colors (rules 3 and 4 of ["How the palette is
chosen"](#how-the-palette-is-chosen)). It does not limit the webmap palette or a palette passed
with [`colors`](#colors). Fewer colors give smaller SIXEL data and
faster drawing, at the cost of quality.

Figure: ["Reduce the number of colors
(sixel\_max\_colors)" in Imager::File::SIXEL::Examples](docs/Examples.md#reduce-the-number-of-colors-sixel_max_colors).

### `colors`

Your own palette.

**Values:** a reference to an array of 1 to 256 colors.

**Default:** none.

**Stored on the image:** no.

Each entry is one of:

- an [Imager::Color](https://metacpan.org/pod/Imager%3A%3AColor) object;
- a reference to an array of red, green and blue values, each an
integer from 0 to 255, such as `[255, 128, 0]`; a fourth value, the
alpha value, is allowed;
- a string that `Imager::Color->new` accepts, such as `'#FF8000'`
or `'red'`.

The alpha value of a color is ignored. [Imager::Color::Float](https://metacpan.org/pod/Imager%3A%3AColor%3A%3AFloat) objects
are not accepted.

```perl
$img->write(data => \$sixel, type => 'sixel',
            colors => ['#000000', [255, 255, 255], 'red']);
```

`colors` takes precedence over [`sixel_palette`](#sixel_palette) and
[`sixel_max_colors`](#sixel_max_colors). Every pixel is written in
one of these colors, approximated as set by
[`sixel_dither`](#sixel_dither).

Figure: ["Use your own (custom) palette
(colors)" in Imager::File::SIXEL::Examples](docs/Examples.md#use-your-own-custom-palette-colors).

### `sixel_dither`

How pixels whose color is not in the palette are written.

**Values:** `'diffusion'`, `'ordered'` or `'none'`, in lowercase;
the comparison is case sensitive.

**Default:** `'diffusion'`.

**Stored on the image:** yes, later writes use it too; see
["Write options are stored on the image"](#write-options-are-stored-on-the-image).

- `'diffusion'`

    Floyd-Steinberg error diffusion in serpentine order. It gives the best
    still images. However, a change anywhere in the image changes the dot
    pattern of everything below it, which flickers in animations.

- `'ordered'`

    An 8 x 8 Bayer matrix whose strength follows the spacing of the
    palette colors. The pattern is tied to the pixel position. With a fixed
    palette (webmap or [`colors`](#colors)), areas of an image that did
    not change therefore stay identical from one animation frame to the
    next.

- `'none'`

    Each pixel gets the palette color nearest to it in RGB space; on a tie,
    the color with the lower register number. Of the three settings, this
    usually gives the smallest SIXEL data, especially with a fixed palette,
    but smooth gradients turn into visible bands.

With `'diffusion'` and `'ordered'`, the nearest palette color is
looked up with each channel reduced to 64 levels instead of 256, which
is faster; the dithering compensates for the small error this adds. Images
written with their own colors (rules 3 and 4 of ["How the palette is
chosen"](#how-the-palette-is-chosen)) are never dithered, because every pixel is in the palette.

Figure: ["Choose how colors are
approximated (sixel\_dither)" in Imager::File::SIXEL::Examples](docs/Examples.md#choose-how-colors-are-approximated-sixel_dither).

### `sixel_alpha_threshold`

Which pixels of an image with an alpha channel are left transparent.

**Values:** an integer from 0 to 255.

**Default:** 128.

**Stored on the image:** yes, later writes use it too; see
["Write options are stored on the image"](#write-options-are-stored-on-the-image).

Pixels whose alpha value is below the threshold are not painted, so
the terminal background shows through. All other pixels are painted in
their color, ignoring their alpha value. With 0, every pixel is
painted, including fully transparent ones, in the color stored in
their red, green and blue channels; areas of a new image that were
never drawn on are black. The option has no effect on images without
an alpha channel.

Figure: ["Images with transparency
(sixel\_alpha\_threshold)" in Imager::File::SIXEL::Examples](docs/Examples.md#images-with-transparency-sixel_alpha_threshold).

### `sixel_pan`

The height part of the pixel aspect ratio written into the image. Each
pixel is `sixel_pan / sixel_pad` times as high as it is wide.

**Values:** an integer from 1 to 2147483647.

**Default:** 1.

**Stored on the image:** yes, later writes use it too; see
["Write options are stored on the image"](#write-options-are-stored-on-the-image).

Terminals that honor the ratio stretch the image accordingly; others
ignore it. Images read from SIXEL data carry the tags `sixel_pan` and
`sixel_pad`, so they keep their aspect ratio when written again.

Figure: ["Non-square pixels (sixel\_pan,
sixel\_pad)" in Imager::File::SIXEL::Examples](docs/Examples.md#non-square-pixels-sixel_pan-sixel_pad).

### `sixel_pad`

The width part of the pixel aspect ratio; see [`sixel_pan`](#sixel_pan).

**Values:** an integer from 1 to 2147483647.

**Default:** 1.

**Stored on the image:** yes, later writes use it too; see
["Write options are stored on the image"](#write-options-are-stored-on-the-image).

## Write options are stored on the image

This module stores every write option whose name starts with
`sixel_` as a tag of the same name on the image before writing it,
following the convention of Imager's own file formats. This has three
consequences:

- You can set the options as tags instead of passing them:

    ```perl
    $img->settag(name => 'sixel_dither', value => 'ordered');
    $img->write(file => 'a.six');    # uses ordered dithering
    ```

- The options stay on the image and apply to later writes of the same
image. To return to the default, pass the option with the default value
or with `undef`, or delete the tag with `$img->deltag(name =>
'sixel_dither')`. See ["Write the same
image again with other settings (options are remembered)" in Imager::File::SIXEL::Examples](docs/Examples.md#write-the-same-image-again-with-other-settings-options-are-remembered).
- An invalid value is stored like a valid one. Later writes of the same
image fail in the same way until you pass a valid value or `undef`,
or delete the tag.

With `write_multi()`:

- A `sixel_` option passed to `write_multi()` is stored on every image,
replacing any value stored there before.
- If the value is an array reference, its elements are stored on the
images in order: the first element on the first image, and so on.
Images beyond the end of the array keep their own setting. For
example, `sixel_pan => [2, 3]` stores 2 on the first image and 3
on the second.
- A `sixel_` option that is not passed is taken from each image's own
tag, if it has one. To write the images with different settings, set
the tags on the images and do not pass the options.

The `colors` option is not stored.

## How the palette is chosen

The first rule that applies decides:

1. If [`colors`](#colors) is given, that palette is used.
2. If [`sixel_palette`](#sixel_palette) is `'webmap'`, the webmap
palette is used.
3. If the image is a paletted image whose color table has at most
[`sixel_max_colors`](#sixel_max_colors) entries, its color table is
used: color register _n_ holds color table entry _n_, except that
an entry that rounds to the same SIXEL percentages as an earlier entry
uses the register of that earlier entry. This is the
fastest way and loses nothing apart from the rounding to SIXEL
percentages. Use it to control the palette yourself, see
["Use the palette of a paletted image" in Imager::File::SIXEL::Examples](docs/Examples.md#use-the-palette-of-a-paletted-image).
4. If the painted pixels of the image (see
[`sixel_alpha_threshold`](#sixel_alpha_threshold)) have at most
[`sixel_max_colors`](#sixel_max_colors) different colors, these
colors are used. The colors are counted after they are rounded to
SIXEL percentages, so two colors that round to the same percentages
count once and share a color register.
5. Otherwise an adaptive palette of at most
[`sixel_max_colors`](#sixel_max_colors) colors is computed.

In rules 3 and 4 every pixel color is in the palette, so
[`sixel_dither`](#sixel_dither) has no effect.

## Image types and bit depth

Images of any type and sample size can be written:

- Gray (grayscale) images are written as RGB.
- Samples with more than 8 bits (16-bit and double precision images)
are reduced to 8 bits before the colors are rounded to SIXEL
percentages.
- Images with an alpha channel, gray or color, are written with P2 = 1,
so that unpainted pixels are transparent; see
[`sixel_alpha_threshold`](#sixel_alpha_threshold).

# DISPLAYING IMAGES IN A TERMINAL

The terminal draws SIXEL data at the text cursor. Where the cursor is
afterwards depends on the terminal: usually on the line below the
image, in some terminals on the last text line the image covers. Print
a line break after the image so that the next output starts below it.

- Send the data to the terminal unchanged. This encoder writes plain
ASCII without line breaks, which I/O layers such as `:crlf` or
`:encoding(UTF-8)` leave intact. SIXEL data from other sources can
contain line breaks or 8-bit control bytes such as 0x90, which these
layers would change. Set `binmode STDOUT, ':raw'` before you send
SIXEL data, and the data arrives unchanged in either case.
- `$img->write(fh => $handle, ...)` writes through the handle's I/O
layers and buffer, exactly like `print`, so the advice above applies
to it as well. Layers that change every byte, such as
`:encoding(UTF-16LE)`, corrupt the data. In-memory handles
(`open my $fh, '`', \\$buffer>) and tied handles work.
- Scale large images down to the size at which they should appear
before writing them. Large images take long to transfer and draw.
- Terminal multiplexers such as tmux and GNU screen pass SIXEL data
through only if they support it and are configured to do so.

## Does my terminal support SIXEL?

A terminal that supports SIXEL answers the primary device attributes
request, `ESC [ c`, with a list of numbers separated by semicolons,
and one of these numbers is `4`. To check by hand, run this in bash
or zsh:

```sh
printf '\e[c'; read -r -s -t 1 -d c answer; echo "${answer#*\[}"
```

It prints the answer, for example `?62;4;6;22` or `?64;1;4;22`. Both
of these contain the number `4` (the `4` inside `64` does not
count), so the terminal supports SIXEL. If only an empty line is
printed, the terminal did not answer within one second. Some terminals
need SIXEL switched on. xterm, for example, must emulate a VT340 and,
for images with more than 16 colors, needs more color registers than
the 16 of the VT340:

```sh
xterm -ti vt340 -xrm 'XTerm*numColorRegisters: 256'
```

## Terminals with fewer than 256 color registers

Such terminals draw an image with wrong colors when the image uses
more colors than they have registers. For them, set
[`sixel_max_colors`](#sixel_max_colors) to their register count, do
not use the webmap palette, which needs 216 registers, and do not pass
more colors with [`colors`](#colors) than the terminal has registers.

# ANIMATION

The encoder is fast enough for real-time animation. Encode each frame
into a string and draw it at a fixed position:

```perl
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
```

`ESC [ ? 2026 h` and `ESC [ ? 2026 l` begin and end a synchronized
update, which keeps the terminal from showing half-drawn frames.
Terminals that do not support it ignore these sequences.

The frame must fit into the terminal window with at least one text line
to spare below it. Otherwise the terminal scrolls after each frame and
the frames jump. The script `examples/sixel-animate.pl` in the
distribution is a complete version of this loop.

Recommendations:

- Use a fixed palette: `sixel_palette => 'webmap'`, or one palette
computed once for the whole animation and passed with [`colors`](#colors):

    ```perl
    my @palette = Imager->make_palette({ make_colors => 'mediancut' },
                                       @sample_frames);
    $frame->write(data => \$sixel, type => 'sixel',
                  colors => \@palette, sixel_dither => 'ordered');
    ```

    An adaptive palette is computed for each frame anew. Any change to the
    image can change the palette and with it every pixel of the frame.

- Use `sixel_dither => 'ordered'` or `sixel_dither => 'none'`.
With a fixed palette, both leave unchanged areas unchanged;
`'diffusion'` does not.
- The terminal, not the encoder, usually limits the frame rate: it has to
receive, parse and draw every frame. Smaller frames, fewer colors
([`sixel_max_colors`](#sixel_max_colors)), `sixel_dither => 'none'`,
and the webmap palette combined with `'ordered'` or `'none'`
dithering all reduce the amount of SIXEL data per frame; see the table
in ["PERFORMANCE"](#performance).

# PERFORMANCE

The encoder builds the palette from a color histogram, maps the pixels
through a lookup table of nearest palette colors, and writes the SIXEL
data band by band. Each band's pixels are grouped by color in linear
time, split into runs of columns, and packed into as few passes over
the band as possible (see ["THE SIXEL
FORMAT" in Imager::File::SIXEL::Format](docs/Format.md#the-sixel-format)). In fully painted bands, the first pass paints whole columns
that later passes paint over, so that it compresses into long repeats.
On the author's test images, the SIXEL data for the same pixels was
typically 4 to 20 percent smaller than that of libsixel 1.10.5 with
adaptive palettes, and more with fixed palettes. For very simple images
both are about the same size.

The table shows the times for one complete
`$img->write(data => \$buffer, type => 'sixel')` call, measured
with `examples/sixel-bench.pl` on an Intel Core i5-12600K with Perl
5.38 and Imager 1.033, in milliseconds per call (ms), the resulting
frames per second (fps) and the size of the SIXEL data in bytes. The
"Synth" columns are for the benchmark's default image, smooth
gradients with noise. The "Photo" columns are for `snake.png` from
the libsixel distribution, a photograph with fine detail, which is
about the hardest case for the encoder.

| Size    | Dither    | Palette  | Synth ms | Synth fps | Synth bytes | Photo ms | Photo fps | Photo bytes |
| ------- | --------- | -------- | -------: | --------: | ----------: | -------: | --------: | ----------: |
| 256x256 | diffusion | adaptive |      2.1 |       472 |       70607 |      5.5 |       182 |       98613 |
| 256x256 | ordered   | adaptive |      1.5 |       685 |       65440 |      3.7 |       270 |      110899 |
| 256x256 | none      | adaptive |      1.7 |       603 |       65944 |      4.8 |       207 |       89583 |
| 256x256 | ordered   | webmap   |      0.9 |      1155 |       36965 |      1.5 |       680 |       52080 |
| 256x256 | none      | webmap   |      0.6 |      1629 |        9256 |      1.5 |       673 |       25949 |
| 192x128 | diffusion | adaptive |      0.9 |      1073 |       27619 |      3.1 |       324 |       45451 |
| 192x128 | ordered   | adaptive |      0.7 |      1483 |       26704 |      2.4 |       419 |       49446 |
| 192x128 | none      | adaptive |      0.8 |      1307 |       26971 |      2.9 |       342 |       42365 |
| 192x128 | ordered   | webmap   |      0.5 |      2200 |       15222 |      0.8 |      1277 |       22875 |
| 192x128 | none      | webmap   |      0.3 |      3814 |        3885 |      0.8 |      1280 |       12476 |
| 640x480 | diffusion | adaptive |      8.9 |       112 |      373095 |     15.4 |        65 |      341301 |
| 640x480 | ordered   | adaptive |      5.8 |       172 |      329641 |      8.7 |       115 |      389983 |
| 640x480 | none      | adaptive |      6.4 |       157 |      329569 |     11.4 |        88 |      267180 |
| 640x480 | ordered   | webmap   |      3.3 |       305 |      160163 |      4.3 |       231 |      203313 |
| 640x480 | none      | webmap   |      3.0 |       335 |       49565 |      4.2 |       236 |       73404 |

Every setting encodes all three sizes of both images at more than 60
frames per second on this machine. At 640 x 480, the default settings
leave the least headroom, which is one reason why ordered dithering is
recommended for animations. To measure your own machine and images,
run `examples/sixel-bench.pl`, which accepts `--file`. Decoding a
640 x 480 image takes about 5 milliseconds.

# DIAGNOSTICS

Failures are reported through `$img->errstr` or `Imager->errstr` as usual; see ["Handle errors" in Imager::File::SIXEL::Examples](docs/Examples.md#handle-errors). The
messages specific to this module are listed here. `N` stands for a
number. In the `unknown ... value` messages, `...` stands for the
value you passed; in `file size limit - ...`, for Imager's
explanation.

## Messages when reading

- `no SIXEL image found`

    The input holds no SIXEL image. With a [`page`](#page) above 0, the
    message is `SIXEL page N not found` instead.

- `SIXEL page N not found`

    The input holds fewer than N + 1 images, so the image that the
    [`page`](#page) option asks for does not exist.

- `page must be a non-negative integer`

    The [`page`](#page) option is not an integer from 0 to 2147483647.

- `premature end of SIXEL data`

    The input ends inside an image; see [`allow_incomplete`](#allow_incomplete).

- `SIXEL image contains no pixels`

    An image paints no pixel and declares no size, so there is nothing to
    return.

- `SIXEL data paints too many pixels`

    The data paints over the same pixels far more often than any real
    image does; see ["Resource limits"](#resource-limits).

- `image dimensions are too large`
- `file size limit - ...`

    The image is larger than the limits set with
    `Imager->set_file_limits` or larger than the decoder supports;
    see ["Resource limits"](#resource-limits).

- `read failed`

    The file or handle read from reported an error.

## Messages when writing

- `sixel_max_colors must be an integer from 1 to 256`
- `sixel_alpha_threshold must be an integer from 0 to 255`
- `sixel_pan must be an integer from 1 to 2147483647`
- `sixel_pad must be an integer from 1 to 2147483647`

    The option has a value that is not an integer or is out of range; see
    ["Write options"](#write-options). The value may come from a tag stored by an earlier
    write, see ["Write options are stored on the image"](#write-options-are-stored-on-the-image).

- `unknown sixel_palette value '...'`
- `unknown sixel_dither value '...'`

    The option has a value that is not one of its keywords; see
    [`sixel_palette`](#sixel_palette) and
    [`sixel_dither`](#sixel_dither). Keywords are case sensitive:
    `'Webmap'` fails, `'webmap'` works.

- `colors must be an array reference`
- `colors must hold from 1 to 256 colors`
- `colors entry N is not a valid color`

    The [`colors`](#colors) option is not an array reference, has too few or too
    many entries, or entry N (counting from 0) is not a color. An array of
    values is not a color if it does not hold 3 or 4 integers from 0 to
    255.

- `Unknown reference type ... supplied for ...`

    A `sixel_` option has a reference as its value that is neither an
    array reference nor, inside an array, an [Imager::Color](https://metacpan.org/pod/Imager%3A%3AColor) object; see
    ["Write options"](#write-options). This message comes from Imager.

- `no images to write`

    `write_multi()` was called without images.

- `image too large to encode`

    The image is too wide or too large for the encoder's buffers in
    memory.

- `cannot read the image palette`

    Imager could not return the palette of a paletted image. This points
    to a problem in Imager or in the image object, not in your options.

- `write failed`
- `error closing output`

    The file or handle written to reported an error, for example because
    the disk is full. Imager buffers the output, so the error often only
    shows when the buffer is written out at the end, as `error closing
    output`.

## Messages when reading or writing

- `out of memory`

    Memory could not be allocated.

# LIMITATIONS

- The encoder uses at most 256 color registers per image. The decoder
accepts up to 1024.
- Colors are limited to the 101 levels per channel that SIXEL
percentages can express; see ["Color precision" in Imager::File::SIXEL::Format](docs/Format.md#color-precision).
- Semi-transparent pixels are either painted fully or not at all; see
[`sixel_alpha_threshold`](#sixel_alpha_threshold). SIXEL has no
partial transparency.
- The decoder does not stretch images whose pixel aspect ratio is not
1:1; see ["Pixel aspect ratio" in Imager::File::SIXEL::Format](docs/Format.md#pixel-aspect-ratio).
- The horizontal grid size parameter (P3) of the control string is
ignored, as current terminals do.

# EXAMPLE PROGRAMS

The `examples` directory of the distribution holds three complete
programs. Each one prints its options with `--help`.

- examples/sixel-cat.pl

    Shows image files in the terminal, in any format that Imager can
    read, with options for size, dithering and number of colors.

    ```sh
    perl examples/sixel-cat.pl --width 400 --dither ordered photo.jpg
    ```

- examples/sixel-animate.pl

    Plays a generated animation and reports the frame rate reached and the
    time spent encoding.

    ```sh
    perl examples/sixel-animate.pl --width 320 --height 240 --fps 30
    ```

- examples/sixel-bench.pl

    Measures the encoding speed for several image sizes and settings, as in
    ["PERFORMANCE"](#performance).

    ```sh
    perl examples/sixel-bench.pl --file photo.png --sizes 640x480
    ```

# INSTALLATION

Requirements: Perl 5.24 or later, Imager 1.013 or later with its
headers, and a C compiler. With [cpanm](https://metacpan.org/pod/App%3A%3Acpanminus):

```sh
cpanm Imager::File::SIXEL
```

From a source checkout:

```sh
cpanm --installdeps .
perl Makefile.PL
make
make test
make install
```

# SEE ALSO

[Imager::File::SIXEL::Examples](docs/Examples.md), [Imager::File::SIXEL::Format](docs/Format.md).

[Imager](https://metacpan.org/pod/Imager), [Imager::Files](https://metacpan.org/pod/Imager%3A%3AFiles), [Imager::ImageTypes](https://metacpan.org/pod/Imager%3A%3AImageTypes).

The SIXEL chapter of the VT330/VT340 Programmer Reference Manual:
[https://vt100.net/docs/vt3xx-gp/chapter14.html](https://vt100.net/docs/vt3xx-gp/chapter14.html).

libsixel, the reference implementation of SIXEL encoding and decoding:
[https://github.com/libsixel/libsixel](https://github.com/libsixel/libsixel).

The source code: [https://github.com/davenonymous/perl-imager-sixel](https://github.com/davenonymous/perl-imager-sixel).

# AUTHOR

davenonymous <dave@davenonymous.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2026 davenonymous.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
