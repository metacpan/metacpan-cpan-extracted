package Layout::Flex;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.03';

use Font::Metrics ();

require XSLoader;
XSLoader::load('Layout::Flex', $VERSION);

1;

__END__

=encoding utf-8

=head1 NAME

Layout::Flex - CSS flexbox layout engine with wrap, gap, margin, and content driven sizing

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Layout::Flex;

    # Explicit sizing
    my @rects = Layout::Flex->compute(
        main_size     => 400,
        cross_size    => 300,
        direction     => 'row',
        justify       => 'space-between',
        align         => 'stretch',
        wrap          => 'wrap',
        align_content => 'space-around',
        gap           => 10,
        items => [
            { basis => 150, grow => 1, cross => 80, margin => 5 },
            { basis => 150, grow => 1, cross => 60, margin => 5 },
        ],
    );

    # Content driven sizing with a measure callback
    my @rects = Layout::Flex->compute(
        main_size  => 400,
        cross_size => 200,
        measure    => sub {
            my ($item, $avail_w) = @_;
            # $item hashref has text, font_size, and any custom keys you set
            # $avail_w is defined only during the wrap second pass
            my ($w, $h) = your_font_metrics($item->{text}, $item->{font_size});
            return ($w, $h);
        },
        items => [
            { text => 'Hello',     font_size => 14, grow => 1 },
            { text => 'Paragraph', font_size => 12, grow => 2, wrap_text => 1 },
        ],
    );

    for my $r (@rects) {
        my ($x, $y, $w, $h) = @$r;
    }

=head1 DESCRIPTION

Layout::Flex implements the CSS Flexible Box layout algorithm in C/XS. Given a 
container size and a list of flex items it computes the exact position and size 
of each item.

Both single line (C<nowrap>, default) and multi line (C<wrap>, C<wrap-reverse>)
modes are supported. In multi line mode, items that overflow the main axis are
collected onto new lines; each line runs an independent grow/shrink pass and
lines are then distributed across the cross axis according to C<align_content>.

C<gap> (or C<main_gap>/C<cross_gap>) inserts fixed space between items and
between lines before C<justify>/C<align_content> distributes any remaining free
space. Per-item margins (C<margin>, C<margin_top>, C<margin_right>,
C<margin_bottom>, C<margin_left>) offset items within their slot; the output
rect is always the content box, excluding margins.

Content-driven sizing is supported via a C<measure> callback. Items may carry a
C<text> key (and C<font_size>, plus any custom keys your callback needs); the
engine calls the callback to derive C<basis> and C<cross> before layout runs.
Items with C<wrap_text =E<gt> 1> trigger a second measurement pass once their
resolved width is known, allowing line-breaking callbacks to return the correct
wrapped height.

=head1 METHODS

=head2 compute

    my @rects = Layout::Flex->compute(%args);

Compute layout. Returns a list of C<[$x, $y, $w, $h]> array references, one per
item, in the same order as C<items>.

=head3 Container options

=over 4

=item C<main_size>

Size of the container along the main axis: width for C<row>, height for C<column>.

=item C<cross_size>

Size of the container along the cross axis: height for C<row>, width for C<column>.

=item C<direction>

C<row> (default) — items flow left to right.
C<column> — items flow top to bottom.

=item C<justify>

Distributes free space along the main axis. One of:

=over 4

=item C<start> (default) — pack items at the start

=item C<end> — pack items at the end

=item C<center> — centre items

=item C<space-between> — equal gaps between items, none at edges

=item C<space-around> — equal gaps around items (half-gap at edges)

=item C<space-evenly> — equal gaps between items and edges

=back

=item C<align>

Sizes and positions items along the cross axis within their line. One of:

=over 4

=item C<stretch> (default) — items fill the line's cross size (clamped to their constraints)

=item C<start> — items align to the start of the cross axis

=item C<end> — items align to the end of the cross axis

=item C<center> — items are centred on the cross axis

=back

=item C<wrap>

Controls whether items may wrap onto multiple lines. One of:

=over 4

=item C<nowrap> (default) — all items on one line; may overflow

=item C<wrap> — items wrap onto additional lines when they exceed C<main_size>

=item C<wrap-reverse> — same as C<wrap> but lines are stacked in reverse cross-axis order

=back

=item C<align_content>

Distributes lines across the cross axis when C<wrap> produces more than one line.
Has no effect in single-line layouts. One of:

=over 4

=item C<stretch> (default) — lines stretch equally to fill the container cross size

=item C<start> — lines packed at the start of the cross axis

=item C<end> — lines packed at the end

=item C<center> — lines centred

=item C<space-between> — equal gaps between lines, none at edges

=item C<space-around> — equal gaps around lines (half-gap at edges)

=item C<space-evenly> — equal gaps between lines and edges

=back

=item C<gap>

Shorthand that sets both C<main_gap> and C<cross_gap> to the same value.

=item C<main_gap>

Fixed space inserted between items within each line on the main axis. Reduces
free space before C<justify> distributes any remainder. Default C<0>.

=item C<cross_gap>

Fixed space inserted between lines on the cross axis. Reduces free space before
C<align_content> distributes any remainder. Has no effect in single-line layouts.
Default C<0>.

=back

=head3 Item options

Each entry in C<items> is a hashref with:

=over 4

=item C<basis>

Initial main-axis size before grow/shrink is applied. Default C<0>.

=item C<grow>

C<flex-grow> factor. The item receives this fraction of positive free space
relative to the sum of all C<grow> values. Default C<0>.

=item C<shrink>

C<flex-shrink> factor. When items overflow the container this controls how much
each item gives back. Default C<1>.

=item C<min_main>, C<max_main>

Clamp the resolved main-axis size. C<max_main> of C<0> means unconstrained.
Default C<0> for both (unconstrained minimum).

=item C<cross>

Natural cross-axis size. Used when C<align> or C<align_self> is C<start>,
C<end>, or C<center>. Ignored under C<stretch>. Default C<0>.

=item C<min_cross>, C<max_cross>

Clamp the resolved cross-axis size. C<max_cross> of C<0> means unconstrained.

=item C<align_self>

Per-item override for C<align>. Accepts the same values (C<stretch>, C<start>,
C<end>, C<center>). Omit or leave undefined to inherit the container's C<align>.

=item C<margin>

Shorthand that sets all four margins to the same value.

=item C<margin_top>, C<margin_right>, C<margin_bottom>, C<margin_left>

Per-side margins. These are direction-aware: in C<row> layout,
C<margin_left>/C<margin_right> affect the main axis and
C<margin_top>/C<margin_bottom> affect the cross axis; in C<column> layout
the axes are swapped.

Margins reduce the free space available for grow/shrink and count toward
line-breaking decisions. The output rect is always the content box — margins
are factored into spacing but are not included in C<x>/C<y>/C<w>/C<h>.

=back

=head3 Content sizing

When a C<measure> callback is supplied on the container, items that carry a
C<text> key are automatically sized before layout runs. The following item
options control this behaviour.

=over 4

=item C<text>

The text content of the item. When C<measure> is set and this key is present,
the engine calls the measurer to determine C<basis> (main-axis natural size) and
C<cross> (cross-axis natural size). Any explicit C<basis> or C<cross> on the
item takes precedence and suppresses the corresponding measurement.

=item C<font_size>

Font size in points, passed to the measurer. Default C<12>. The built-in
C<'simple'> measurer uses C<font_size * 0.6> as character width and
C<font_size * 1.4> as line height.

=item C<wrap_text>

Boolean. When true, the item participates in a second measurement pass after
C<lf_compute> has resolved final widths. The measurer is called again with the
resolved width as a second argument C<$avail_w>, allowing it to return a
line-wrapped height. A second C<lf_compute> then runs to apply the new cross
sizes.

For row layouts the resolved width is C<$rect-E<gt>{w}>; for column layouts it
is C<$rect-E<gt>{h}>. The built-in C<'simple'> measurer calculates
C<ceil(len / floor(avail_w / char_w))> lines and multiplies by line height.

A code-ref measurer receives C<($item, $avail_w)> on the second pass and should
return C<($w, $h)>; the engine uses the returned C<$h> (and C<$w> if provided)
to update the item's cross size.

Items I<without> C<wrap_text> are measured only once; they keep their naturally
resolved dimensions.

=back

=head3 Container C<measure> option

=over 4

=item C<measure>

One of:

=over 4

=item C<'simple'>

Built-in proportional approximation. Width = C<length($text) * $font_size * 0.6>.
Height = C<$font_size * 1.4>. Useful for fast layout estimates without a real
font engine.

=item A code reference

    measure => sub {
        my ($item, $avail_w) = @_;
        # $avail_w is undef on the first pass; defined on the wrap_text second-pass
        ...
        return ($w, $h);
    }

Called once per item that has a C<text> key. On the first pass C<$avail_w> is
C<undef>; on the C<wrap_text> second pass it is the resolved main-axis size.
The item hashref contains C<text>, C<font_size>, and any other keys you set on
the item.

=back

=back

=head2 font_metrics_measure(%args)

    use Font::Metrics;
    my $fm      = Font::Metrics->new(name => 'Helvetica');
    my $measure = Layout::Flex->font_metrics_measure(fm => $fm, size => 12);

    my @rects = Layout::Flex->compute(
        main_size => 400,
        measure   => $measure,
        items     => [ { text => 'Hello World', grow => 1, wrap_text => 1 } ],
    );

Returns a C<measure> code-ref backed by a L<Font::Metrics> object. Replaces the
built-in C<'simple'> approximation with exact per-glyph advance widths.

Arguments:

=over 4

=item C<fm> (required)

A L<Font::Metrics> instance.

=item C<size>

Font size in points (default C<12>).

=item C<line_height>

Line height in points (default C<size * 1.2>).

=back

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 BUGS

Please report bugs at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Layout-Flex>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
