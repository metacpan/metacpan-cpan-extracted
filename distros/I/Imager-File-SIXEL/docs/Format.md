# NAME

Imager::File::SIXEL::Format - how Imager::File::SIXEL reads and writes
the SIXEL format

# DESCRIPTION

This page describes the SIXEL format and exactly how
[Imager::File::SIXEL](../README.md) decodes and encodes it: which data the decoder
accepts, what the decoded image looks like, what the encoder writes,
and how the decoder limits the work that malicious data can cause.
You do not need it to use the module; the options are documented in
[Imager::File::SIXEL](../README.md), and [Imager::File::SIXEL::Examples](Examples.md) shows
them in use.

# THE SIXEL FORMAT

A SIXEL image is a device control string: `ESC P` (or the 8-bit
control character 0x90), numeric parameters separated by `;` (DEC
defines three), the letter `q`, the image data, and the string terminator
`ESC \` (or 0x9C). The parameters are P1, the pixel aspect ratio for
images without raster attributes; P2, which makes unpainted pixels
transparent when it is 1; and P3, the horizontal grid size, which
current terminals ignore.

The image data paints the image in horizontal bands six pixels high.
Each data character from `?` to `~` encodes one column of a band: the
character code minus 63 is a six-bit mask whose lowest bit is the top
pixel. Painting a band can take several passes, one per color, each
starting again at the left edge of the band. The other commands are:

| Command | Meaning                                              |
| ------- | ---------------------------------------------------- |
| `#`     | select a color register, or define its color         |
| `!`     | repeat the next data character a number of times     |
| `$`     | return to the start of the current band              |
| `-`     | move to the start of the next band                   |
| `"`     | raster attributes: pixel aspect ratio and image size |

Colors are defined as percentages from 0 to 100 per RGB channel, or in
the HLS color space.

# READING

## What is read

The decoder searches the input for SIXEL images. Everything else is
skipped: text, escape sequences and other control strings before,
between and after the images. That is why a recording of a terminal
session, for example one made with `script`, can be read directly.

Each SIXEL image becomes one Imager image. In detail:

- A SIXEL image starts with the control string introducer, either the
7-bit form `ESC P` or the 8-bit byte 0x90, followed by numeric
parameters separated by `;` (only the first two are used) and the
letter `q`. Control strings with any other final character, with
intermediate characters or with a private marker are not SIXEL and are
skipped. A byte 0x90 that is part of a UTF-8
encoded character in the surrounding text is not taken as an
introducer.
- A SIXEL image ends with the string terminator, either `ESC \` or the
8-bit byte 0x9C. It also ends with any other escape sequence, which is
then examined as the possible start of the next image, and with the
control characters CAN (0x18) and SUB (0x1A).
- Spaces, line breaks and control characters inside the image are
ignored, except those that end the image (ESC, CAN, SUB and the byte
0x9C, see above). Characters that have no meaning in SIXEL are ignored
too. Inside the numeric parameters of a command, a space ends a number,
so `#1 2` is read as `#1;2`, while a line break or another control
character is skipped, so `#1`, a line break and `2` are read as
`#12`.
- An image cut off by the end of the input (truncated) is an error,
unless [`allow_incomplete`](../README.md#allow_incomplete) is set.

## The decoded image

### Size

The image is as wide and as high as the area painted: up to and
including the rightmost and the lowest painted pixel. If raster
attributes (the `"` command) before the first pixel data declare a
width and a height of at least 1 each, the image has at least that
size. The height is not
rounded up to a multiple of six. Raster attributes after the first
pixel data are ignored, as on DEC terminals.

### Channels and transparency

If the second parameter of the control string (P2, see
["THE SIXEL FORMAT"](#the-sixel-format)) is 1, pixels that
were never painted are transparent, and the image has four channels
(RGB plus alpha). Otherwise the image has three channels (RGB), and
pixels that were never painted get the last color defined for
register 0, the background color, as on DEC terminals.

### Image type

If the decoded image has at most 256 colors, it is a paletted image
(`$img->type eq 'paletted'`); otherwise it is a direct color
image with 8 bits per sample. Only colors that at least one pixel of
the final image shows count; colors that were painted over completely
do not.

The colors are counted as color entries. The decoder keeps one color
entry per color register. When a register that has already painted
pixels gets a new color, the decoder adds a new entry for the new
color, so the pixels painted before keep the old one (see
["Redefined color registers"](#redefined-color-registers)). Unpainted pixels show a transparent
entry (red, green, blue and alpha all 0) in images with P2 = 1, and
otherwise the entry of register 0, which holds the last color defined
for it.

The color table of a paletted image holds the entries that are shown,
in this order:

- the entries of the registers, in register number order;
- the entries added for redefined registers, in the order in which they
were added;
- the transparent entry, if unpainted pixels are transparent.

Two entries can hold the same color.

### Redefined color registers

Each pixel keeps the color its register held when the pixel was
painted. Some encoders, for example `img2sixel -I` from libsixel,
redefine registers in the middle of an image to show more colors than
there are registers; their images decode as intended. DEC terminals,
xterm and libsixel instead recolor the pixels painted earlier when a
register is redefined. Both interpretations give the same result for
images that define each register only once, as nearly all encoders do,
including this one. The decoder keeps at most 65534 color entries per
image (registers plus entries added for redefinitions); once that many
exist, redefining a register recolors its earlier pixels.

### Color registers

There are 1024 color registers, numbered 0 to 1023. Higher register
numbers wrap around: register 1025 is register 1. Registers 0 to 15
start with the colors of the VT340, all others start black. Register 15
is selected until the data selects another one. Defining a color also
selects its register.

### Color definitions

RGB color definitions are percentages from 0 to 100; values above 100
are treated as 100. HLS definitions use the DEC hue circle, on which
blue is at 0 degrees, red at 120 and green at 240. Hues above 360 are
treated as 360, and lightness and saturation above 100 as 100.
Definitions in other color spaces, and definitions with fewer than
four parameters after the register number, are ignored, but still
select their register.

### Pixel aspect ratio

The aspect ratio is not applied: every SIXEL pixel becomes one image
pixel. It is reported in the tags `sixel_pan` and `sixel_pad`, see
["Non-square pixels (sixel\_pan,
sixel\_pad)" in Imager::File::SIXEL::Examples](Examples.md#non-square-pixels-sixel_pan-sixel_pad) for how to apply it.

## Resource limits

Images larger than the limits set with `Imager->set_file_limits`
are rejected, whether the size is declared in the raster attributes or
results from the pixels painted. By default, Imager limits only the
memory of an image, to 1 GiB.

The repeat command lets a few bytes paint many pixels, and the same
pixels can be painted over any number of times. The file limits bound
the memory used. To bound the time as well, decoding stops with the
error `SIXEL data paints too many pixels` when the number of painted
pixels exceeds 16 times the size of the decoder's pixel buffer plus
16777216 (2\*\*24). The buffer grows while the image is decoded and is
between 1 and about 4 times the final image size (width x height). The
check uses the buffer size at the time of painting, so data that
paints the same pixels many times before the image reaches its final
size is stopped sooner. For an image of W x H pixels, decoding stops
at the latest after 64 x W x H + 2\*\*24 painted pixels; if the raster
attributes declare the size, not before 16 x W x H + 2\*\*24.

Even within these bounds, a small input can take a lot of decoding
time when the file limits are large; see
["Resource limits" in Imager::File::SIXEL](../README.md#resource-limits) for what to do about it.

# WRITING

## What is written

Each image is written as one SIXEL image of this form (spaces added
for readability):

```text
ESC P 0 ; P2 ; 0 q " Pan ; Pad ; width ; height  color definitions  pixel data  ESC \
```

- P2 is 1 for images with an alpha channel, meaning that unpainted
pixels are transparent, and 0 otherwise.
- `Pan;Pad` is the pixel aspect ratio from
[`sixel_pan`](../README.md#sixel_pan) and
[`sixel_pad`](../README.md#sixel_pad), normally `1;1`.
- Only the 7-bit forms of the control characters are written, so the
data is plain ASCII.
- Colors are defined as RGB percentages. Only the color registers that
are used are defined, each one once, and they are numbered from 0 to
at most 255.

`write_multi()` writes the images one after another, each as an
independent SIXEL image, with nothing in between:

- The `sixel_` options apply to every image, as described in
["Write options are stored on the image" in Imager::File::SIXEL](../README.md#write-options-are-stored-on-the-image).
- A palette passed with [`colors`](../README.md#colors), and the
webmap palette, are used for every image. Adaptive palettes and the
image's own colors are determined for each image separately.

## Color precision

SIXEL defines colors as percentages from 0 to 100 per channel, so it
can express 101 levels per channel, not 256. When an image is written,
every color is rounded to the nearest of these levels. Reading the
result back gives the rounded colors. Writing that decoded image again
loses nothing further, provided the decoded image has at most
[`sixel_max_colors`](../README.md#sixel_max_colors) colors, so
that it is written with its own colors (rules 3 and 4 of
["How the palette is chosen" in Imager::File::SIXEL](../README.md#how-the-palette-is-chosen)).

# SEE ALSO

[Imager::File::SIXEL](../README.md), [Imager::File::SIXEL::Examples](Examples.md), [Imager](https://metacpan.org/pod/Imager).

The SIXEL chapter of the VT330/VT340 Programmer Reference Manual:
[https://vt100.net/docs/vt3xx-gp/chapter14.html](https://vt100.net/docs/vt3xx-gp/chapter14.html).

libsixel, the reference implementation of SIXEL encoding and decoding:
[https://github.com/libsixel/libsixel](https://github.com/libsixel/libsixel).

# AUTHOR

davenonymous <dave@davenonymous.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2026 davenonymous.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
