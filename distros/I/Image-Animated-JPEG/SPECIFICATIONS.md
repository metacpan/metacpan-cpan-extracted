Proposed specifications for Animated JPEG/JFIF, or colloquially "Animated JPEG"
("AJPEG"). Version 0. Revision 2.


## Introduction

This document describes a bare (container less) format for short videos and
animations.

AJPEG files following these specifications are a number of concatenated standard
JPEG/JFIF files, then regarded as frames of the animation. Each frame may carry
displaying metadata, used for playback-control, stored in an additional APP0
marker segment of the first and optionally any subsequent image frame. As such,
this format is mostly a standards compliant application extension of JPEG/JFIF
v1.02.


## Implementation Overview

JFIF/JPEG files are made up of segments (called "Tags" in TIFF files). Each
segment is identified by a marker (two bytes, FF and one more byte, identifying
the marker type), followed by the size of the segment (encoded in two more
bytes). For markers carrying data, these four bytes are then followed by the
actual marker data. This specification here uses the JFIF APP0 marker which is
identified by binary FF E0.

According to JPEG File Interchange Format, Version 1.02, additional APP0 marker
segments can be used to specify application specific extensions. JFIF compatible
decoders should skip any unsupported JFIF APP0 extension segments and continue
decoding, so adding additional APP0 marker segments does not corrupt the
individual JPEG frame.

  "Additional APP0 marker segment(s) can optionally be used to specify JFIF
  extensions. If used, these segment(s) must immediately follow the JFIF APP0
  marker. Decoders should skip any unsupported JFIF extension segments and
  continue decoding."
    -- JFIF v1.02 (http://www.w3.org/Graphics/JPEG/jfif3.pdf, p.2)

Application-specific APP0 marker segments are identified by a zero terminated
string which identifies the application. Application-markers are not limited to
4 chars. The proposed application format identifier for Animated JPEG, the
"Animated JPEG marker" ("AJPEG marker") is "AJPEG\x00", that's the marker
"AJPEG" followed by a binary zero (41 4A 50 45 47 00).

The marker "AJPEG" was chosen as the Motion-JPEG (MJPEG) namespace is already so
crowded with differing specifications, assumptions and implementations:
There's mjpeg as diverse de-facto-format, as codec in AVI files, as stream+http
header etc. Adding yet another format under this moniker would only contribute
to the confusion.

Animated JPEG files are identified by the presence of the AJPEG APP0 marker.

Standard JPEG/JFIF files are terminated by the EOI marker (End of image, binary
FF D9), while in an AJPEG file this marker merely indicates the end of one
animation frame within the stream of concatenated JPEG/JFIF image-data-ranges.

The first byte of the segment payload, after the marker+\x00, is the AJPEG
version identifier. Currently, there's only one version defined,
"request-for-comments/experimental version 0" (0x00). So the AJPEG segment
version 0 begins 41 4A 50 45 47 00 00.

The Animated JPEG APP0 segment provides information about the animation, which
is normally missing from a stream of concatenated JPEGs: definition(s) of
per-stream or per-frame display duration/delay, positioning of frames within a
display canvas, background dispose strategy, etc.

The first frame in the picture stream should be a "pseudo-header", holding the
most metadata about an animation stream, while subsequent frames may provide a
metadata-delta only, specifying what has changed since the previous frame in
terms of how the sequence of images should be displayed.

The AJPEG marker is only mandatory on the first image/frame of the stream.

So subsequent frames may alter previously defined playback parameters, or may
carry metadata about the single frame but not concerned with playback-control
(e.g. original filename), or subsequent frames may omit the APP0 AJPEG marker
completely.

The general rule is: if anything is omitted, assume it is unchanged from the
previous frame.

Each frame in an AJPEG file represents an I-Frame. By offsetting some frames
according to a x/y offset value-pair, it is possible to construct simple
P-Frames. AJPEG does not offer inter-frame compression.

The AJPEG format does not provide any notion of a display or canvas different in
size from the first frame, nor a facility to control a "background color". The
first frame of an animation is used to define the size of the display area (the
animation's canvas). The first frame is also used to layout the display tonally.
Deviating values for the "display area" are not possible.

This version of the AJPEG format does not offer an index facility, so the order
of frames within an AJPEG stream can't be changed via metadata. The first
image/frame in the file/stream is the first image/frame to be displayed.

The proposed suffix for animated JPEG is .ajpeg, but as the format does not
interfere with Motion-JPEG or single-image JPEG display, suffixes .mjpeg and
.jpg/.jpeg or even .ani.jpg can be used.

The proposed MIME-Type is "image/ajpeg".

Coming versions might allow:

* Omitting the Huffman table on subsequent frames, compare
  http://libav.org/avconv.html#toc-mjpeg2jpeg

* An index facility, to control play-order and repetition/reuse of frames.

* A flag for ping-pong (yoyo) playback (play forward, play backwards, looped or
  one-shot)

* A canvas size definition different from the size of the first frame, enabling
  a separate definition of canvas size and canvas background color.

* Encoding values as 3-byte integers.

* Dissolve transition between frames, via to-be created "Overlay strategy" or
  Disposal strategy


## The APP0 AJPEG Segment

AJPEG's metadata is encoded as binary key:value pairs within the data payload of
the AJPEG APP0 marker segment. Keys are always one byte long (one octet). Each
key defines a specific feature and defines how many bytes will follow to
represent the key's value. Values can be integers packed as byte, shorts, longs;
or multi-byte utf-8 encoded strings. There is no defined order for these binary
key:value pairs. This schema has been chosen to encode keys and values in as
few bytes as possible.

Although the following data-structures will very seldomly produce a binary FF,
note that in case the byte FF appears within the AJPEG segment, it must be
followed by a binary zero (0x00), according to JFIF spec.


### Delay

Binary key 0x01 -> followed by int8u (C) for delays 0-255ms

Binary key: 0x02 -> followed by int16u (n) big endian for delays 0-65535ms

Binary key: 0x04 -> followed by int32u (N) big endian for delays 0-42949672965ms

Optional. Global and per frame. Defines how long (in milliseconds) this frame,
and any other following frame not defining a delay should be displayed.
This may also be described as "frame duration" or "time this frame should be
displayed".

When no frame has a delay, delay for each frame of the whole stream defaults to
100ms.

As for APNGs, if the the delay value is 0, the decoder should render the next
frame as quickly as possible, though players/viewers may impose a reasonable
lower bound (longer delay).

Value meaning is the same as in animated GIFs ("delay before painting next
frame").

Note that the AJPEG default of 100ms delay per frame (10fps) is lower than what
most players default to for Motion-JPEGs (usually 40ms/ 25fps).

Also note that browsers usually introduce an upper limit for frame-rate. Very
low delay values, mostly below 0.02s, some below 0.06s, are rounded up to 0.1s
or 100ms. That's why many animated GIFs set delay to 0 while actually expecting
the playback rate to be 10fps.


### Repeat

Binary key 0x11 -> followed by int8u for repeat value 0-255

Binary key: 0x12 -> followed by int16u (n) big endian for repeat value 0-65535

Optional. Global only. Defines playback and repeat of this animation.
As this value defines a "global repeat", it makes sense only to define it on
first frame, as having a per-frame "repeat" of subsequent frames makes no sense.
Simply increasing the delay of a single frame has the same effect.

A value of 0 means "continuous"/ "looped"/ "indefinite" replay. "Play once" is
indicated by a value of 1, and values greater 1 mean "play n times".

Omitting repeat means continuous play (=0).

Value meanings are the same as in APNG's _num_plays_ definition or animated
GIF's (NAB extension) "repetitions". Default for AJPEG is continuous play,
contrary to original GIF89a, which is one-shot by default.


### Parse next

Binary key 0x21 -> followed by int8u with value 0-255

Binary key: 0x22 -> followed by int16u big endian for values between 0-65535

Optional. Tells implementations if the next frame should be parsed for metadata
in the APP0 animated JPEG marker segment. A value of 0 means: don't parse next
frame for metadata - effectively disabling parsing for all subsequent frames. A
value of 1 means: yes, parse next frame for markers. And a value > 1 tells an
implementation to skip parsing on next n-1 frames and only parse frame n
counting from current frame onwards.

Omitting parse-next is interpreted as 0: don't parse next and no subsequent
frames.

The intendend default behaviour for implementations is to treat the first frame
in an animated JPEG stream as a pseudo header for the whole animation,
minimising processing overhead by disabling parsing of subsequent frames.


### Length

Binary key: 0x31 -> followed by int8u for values between 0-255

Binary key: 0x32 -> followed by int16u big endian for values between 0-65535

Binary key: 0x34 -> followed by int32u big endian for values between
0-42949672965

Optional. Help implementing software to find the next frame by indicating the 
length of this frame/ this JPEG/JFIF element in the stream.


### Previous

Binary key: 0x41 -> followed by int8u for values between 0-255

Binary key: 0x42 -> followed by int16u big endian for values between 0-65535

Binary key: 0x44 -> followed by int32u big endian for values between
0-42949672965

Optional. Help implementing software to seek backwards, namely, to find the
beginning of the previous frame/ the previous JPEG/JFIF element in the stream
by indicating the absolute byte position of the previous frame's SOI marker.


### x Offset

Binary key: 0x51 -> followed by two int8u values between 0-255

Binary key: 0x52 -> followed by two int16u big endian for values between 0-65535

Defines the x offset (horizontal) of the North-West corner of the canvas. As the
first frame defines the canvas size, the first frame can't be smaller than
itself, so the offset values are ignored on first frames and are optional on
subsequent.

Omitting both offsets is interpreted as the default: position frame's NW corner
at 0,0. Omitting the y-offset when an x-offset is present is interpreted as:
x-offset,0.

### y Offset

Binary key: 0x61 -> followed by two int8u values between 0-255

Binary key: 0x62 -> followed by two int16u big endian for values between 0-65535

Defines the y offset (vertical) of the North-West corner of the canvas. As the
first frame defines the canvas size, the first frame can't be smaller than
itself, so the offset values are ignored on first frames and are optional on
subsequent.

Omitting both offsets is interpreted as the default: position frame's NW corner
at 0,0. Omitting the x-offset when an y-offset is present is interpreted as:
0,y-offset.

### Disposal strategy

Binary key: 0x71 -> followed by int8u for values between 0-2

Optional. A value of of 0 means "none": no disposal is done on this frame before
rendering the next; the contents of the output buffer are left as is. Value 1
means "background": the frame's region of the output buffer is to be cleared to
be the first frame, which acts as a background. A value of 2 means "previous":
the frame's region of the output buffer is to be reverted to the previous
contents before rendering the next frame.

Values are the same as in APNG's _dispose_op_ definition with a slightly
different handling of "background" (reverting to first frame vs. APNG's
"transparent black").


### Arbitrary metadata

Binary key: 0xA0 -> followed by int8u, bytes, int8u, bytes

Optional. Frames can carry arbitrary metadata key:value pairs. This key-value
store can be used to attach a (file-)name, filesystem stat-values, or any other
application specific data to an animation or single frames. The example
implementation uses this facility to restore former file metadata when frames
are extracted from an animated JPEG file and stored as singular files again.

The first byte defines the length of the key-name byte sequence. Keys can be 255
bytes long. This is followed by another byte giving the length of the value byte
sequence. Values can be 255 bytes in length. Both, key and value, are stored as
variable length utf-8 encoded byte sequences.


## Player Implementation

Each player or viewer implementing the AJPEG specifications here should
implement a number of default settings to apply to an AJPEG image stream. These
values are the fallback values in case the picture stream itself does not
provide specific settings via metadata:

Default delay for each frame is 100ms (equivalent of 10 frames per second).

Frame timings should be independent of the time required for decoding and
display of each frame, so that animations will run at the same rate regardless
of the performance of the decoder implementation.

The output buffer/display/canvas must be completely initialized with the first
frame of the animated JPEG file at the beginning of each play. This is to ensure
that each play of the animation will be identical.

Stand-alone player implementations are asked to expose (may implement) manual
controls to override an AJPEG stream's embedded playback properties, e.g. delay
or repeat, to enable a user to stop, step through, step forward/backwards, to
slow down or speed up an animation via keystroke or similar means.


## AUTHOR

Development of the _Animated JPEG_ JPEG/JFIF format extension has been funded by
Clipland GmbH, [clipland.com](http://www.clipland.com/)


## Copyright and License

This software specification is Copyright 2013-2017 Clipland GmbH. All rights
reserved.

Clipland GmbH licenses this specification to the public under the GNU Free
Documentation License (GNU FDL or GFDL) Version 1.3.
