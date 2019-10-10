[![Build Status](https://travis-ci.org/spiritloose/MP4-LibMP4v2.svg?branch=master)](https://travis-ci.org/spiritloose/MP4-LibMP4v2)
# NAME

MP4::LibMP4v2 - Perl interface to the libmp4v2

# SYNOPSIS

    use MP4::LibMP4v2;
    my $mp4 = MP4::LibMP4v2->read('/path/to/movie.mp4');
    my $num_tracks = $mp4->get_number_of_tracks;
    for (my $i = 0; $i < $num_tracks; $i++) {
        my $track_id = $mp4->find_track_id($i);
        my $bit_rate = $mp4->get_track_bit_rate($track_id);
    }

# DESCRIPTION

The MP4::LibMP4v2 module provides an interface to the libmp4v2.
This module supports libmp4v4 version 2 or above.
Please use [MP4::File](https://metacpan.org/pod/MP4::File) for its version 1.

# METHODS

## MP4::LibMP4v2->optimize($filename \[, $to\_filename\])

Optimize the mp4 file.

## MP4::LibMP4v2->read($filename) :MP4::LibMP4v2

Read the file and return an instance of MP4::LibMP4v2.

## MP4::LibMP4v2->set\_log\_level($level)

Set log level. Defaults to MP4\_LOG\_NONE.

## MP4::LibMP4v2->get\_log\_level() :Int

Get log level.

## $mp4->get\_file\_name() :Str

## $mp4->info() :Str

## $mp4->have\_atom($atom\_name) :Bool

## $mp4->get\_integer\_property($prop\_name) :Int

## $mp4->get\_float\_property($prop\_name) :Num

## $mp4->get\_string\_property($prop\_name) :Str

## $mp4->get\_bytes\_property($prop\_name) :ArrayRef\[Str\]

## $mp4->get\_duration() :Int

## $mp4->get\_time\_scale() :Int

## $mp4->get\_od\_profile\_level() :Int

## $mp4->get\_scene\_profile\_level() :Int

## $mp4->get\_video\_profile\_level() :Int

## $mp4->get\_audio\_profile\_level() :Int

## $mp4->get\_graphics\_profile\_level() :Int

## $mp4->get\_number\_of\_tracks() :Int

## $mp4->find\_track\_id($index \[, $type, $subtype\]) :Int

## $mp4->find\_track\_index($track\_id) :Int

## $mp4->get\_track\_duration\_per\_chunk($track\_id) :Int

## $mp4->have\_track\_atom($track\_id, $atom\_name) :Bool

## $mp4->get\_track\_type($track\_id) :Str

## $mp4->get\_track\_media\_data\_name($track\_id) :Str

## $mp4->get\_track\_media\_original\_format($track\_id) :Str

## $mp4->get\_track\_duration($track\_id) :Int

## $mp4->get\_track\_time\_scale($track\_id) :Int

## $mp4->get\_track\_language($track\_id) :Str

## $mp4->get\_track\_name($track\_id) :Str

## $mp4->get\_track\_audio\_mpeg4\_type($track\_id) :Int

## $mp4->get\_track\_esds\_object\_type\_id($track\_id) :Int

## $mp4->get\_track\_fixed\_sample\_duration($track\_id) :Int

## $mp4->get\_track\_bit\_rate($track\_id) :Int

## $mp4->get\_track\_video\_metadata($track\_id) :ArrayRef\[Str\]

## $mp4->get\_track\_es\_configuration($track\_id) :ArrayRef\[Str\]

## $mp4->get\_track\_h264\_length\_size($track\_id) :Int

## $mp4->get\_track\_number\_of\_samples($track\_id) :Int

## $mp4->get\_track\_video\_width($track\_id) :Int

## $mp4->get\_track\_video\_height($track\_id) :Int

## $mp4->get\_track\_video\_frame\_rate($track\_id) :Num

## $mp4->get\_track\_audio\_channels($track\_id) :Int

## $mp4->is\_isma\_cryp\_media\_track($track\_id) :Bool

## $mp4->get\_track\_integer\_property($track\_id, $prop\_name) :Int

## $mp4->get\_track\_float\_property($track\_id, $prop\_name) :Num

## $mp4->get\_track\_string\_property($track\_id, $prop\_name) :Str

## $mp4->get\_track\_bytes\_property($track\_id, $prop\_name) :ArrayRef\[Str\]

## $mp4->get\_hint\_track\_rtp\_payload($track\_id) :Str

## $mp4->convert\_from\_movie\_duration($duration, $time\_scale) :Int

## $mp4->convert\_from\_track\_timestamp($track\_id, $timestamp, $time\_scale) :Int

## $mp4->convert\_to\_track\_timestamp($track\_id, $timestamp, $time\_scale) :Int

## $mp4->convert\_from\_track\_duration($track\_id, $duration, $time\_scale) :Int

## $mp4->convert\_to\_track\_duration($track\_id, $duration, $time\_scale) :Int

# CONSTANTS

## MP4\_LOG\_NONE

## MP4\_LOG\_ERROR

## MP4\_LOG\_WARNING

## MP4\_LOG\_INFO

## MP4\_LOG\_VERBOSE1

## MP4\_LOG\_VERBOSE2

## MP4\_LOG\_VERBOSE3

## MP4\_LOG\_VERBOSE4

## MP4\_OD\_TRACK\_TYPE

## MP4\_SCENE\_TRACK\_TYPE

## MP4\_AUDIO\_TRACK\_TYPE

## MP4\_VIDEO\_TRACK\_TYPE

## MP4\_HINT\_TRACK\_TYPE

## MP4\_CNTL\_TRACK\_TYPE

## MP4\_TEXT\_TRACK\_TYPE

## MP4\_SUBTITLE\_TRACK\_TYPE

## MP4\_SUBPIC\_TRACK\_TYPE

## MP4\_CLOCK\_TRACK\_TYPE

## MP4\_MPEG7\_TRACK\_TYPE

## MP4\_OCI\_TRACK\_TYPE

## MP4\_IPMP\_TRACK\_TYPE

## MP4\_MPEGJ\_TRACK\_TYPE

## MP4\_SECONDS\_TIME\_SCALE

## MP4\_MILLISECONDS\_TIME\_SCALE

## MP4\_MICROSECONDS\_TIME\_SCALE

## MP4\_NANOSECONDS\_TIME\_SCALE

## MP4\_SECS\_TIME\_SCALE

## MP4\_MSECS\_TIME\_SCALE

## MP4\_USECS\_TIME\_SCALE

## MP4\_NSECS\_TIME\_SCALE

## MP4\_MPEG4\_INVALID\_AUDIO\_TYPE

## MP4\_MPEG4\_AAC\_MAIN\_AUDIO\_TYPE

## MP4\_MPEG4\_AAC\_LC\_AUDIO\_TYPE

## MP4\_MPEG4\_AAC\_SSR\_AUDIO\_TYPE

## MP4\_MPEG4\_AAC\_LTP\_AUDIO\_TYPE

## MP4\_MPEG4\_AAC\_HE\_AUDIO\_TYPE

## MP4\_MPEG4\_AAC\_SCALABLE\_AUDIO\_TYPE

## MP4\_MPEG4\_CELP\_AUDIO\_TYPE

## MP4\_MPEG4\_HVXC\_AUDIO\_TYPE

## MP4\_MPEG4\_TTSI\_AUDIO\_TYPE

## MP4\_MPEG4\_MAIN\_SYNTHETIC\_AUDIO\_TYPE

## MP4\_MPEG4\_WAVETABLE\_AUDIO\_TYPE

## MP4\_MPEG4\_MIDI\_AUDIO\_TYPE

## MP4\_MPEG4\_ALGORITHMIC\_FX\_AUDIO\_TYPE

## MP4\_MPEG4\_ALS\_AUDIO\_TYPE

## MP4\_MPEG4\_LAYER1\_AUDIO\_TYPE

## MP4\_MPEG4\_LAYER2\_AUDIO\_TYPE

## MP4\_MPEG4\_LAYER3\_AUDIO\_TYPE

## MP4\_MPEG4\_SLS\_AUDIO\_TYPE

# SEE ALSO

[https://github.com/sergiomb2/libmp4v2](https://github.com/sergiomb2/libmp4v2), [MP4::File](https://metacpan.org/pod/MP4::File)

# LICENSE

Copyright (C) Jiro Nishiguchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jiro Nishiguchi <jiro@cpan.org>
