#!/usr/bin/env perl
# Plays a generated animation in a SIXEL capable terminal.
#
# Copyright (C) 2026 davenonymous.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
use v5.24;
use warnings;
use feature qw(signatures);
no warnings qw(experimental::signatures);

use Getopt::Long qw(GetOptions);
use Imager;
use Imager::File::SIXEL;
use Imager::Fill;
use Imager::Fountain;
use Pod::Usage qw(pod2usage);
use Time::HiRes qw(sleep time);

my %options = (
	width   => 640,
	height  => 480,
	fps     => 60,
	seconds => 10,
	dither  => 'ordered',
	palette => 'webmap',
);
GetOptions(\%options, 'width=i', 'height=i', 'fps=f', 'seconds=f', 'dither=s', 'palette=s', 'help')
	or pod2usage(2);
pod2usage(1) if $options{help};

# A texture twice the frame size; each frame shows a moving window of it.
sub makeTexture($width, $height) {
	my $texture = Imager->new(xsize => 2 * $width, ysize => 2 * $height);
	my $fill = Imager::Fill->new(
		fountain => 'linear',
		xa       => 0,
		ya       => 0,
		xb       => $width / 2,
		yb       => $height / 3,
		repeat   => 'triangle',
		segments => Imager::Fountain->simple(
			positions => [0, 0.5, 1],
			colors    => [map { Imager::Color->new($_) } '#1B3B6F', '#E8A33D', '#A4243B'],
		),
	);
	$texture->box(fill => $fill);
	return $texture;
}

sub renderFrame($texture, $width, $height, $seconds) {
	my $frame = $texture->crop(
		left   => int($width / 2 * (1 + sin($seconds * 0.7))),
		top    => int($height / 2 * (1 + cos($seconds * 0.5))),
		width  => $width,
		height => $height,
	);
	$frame->circle(
		x     => $width / 2 + $width / 3 * cos($seconds * 2),
		y     => $height / 2 + $height / 3 * sin($seconds * 3),
		r     => $height / 8,
		color => '#F4F1DE',
		aa    => 1,
	);
	return $frame;
}

my $texture = makeTexture($options{width}, $options{height});
my $frameInterval = 1 / $options{fps};
my ($frames, $encodeSeconds, $bytes) = (0, 0, 0);

binmode STDOUT, ':raw';
STDOUT->autoflush(1);
my $interrupted = 0;
local $SIG{INT} = sub { $interrupted = 1 };

# hide the cursor and clear the screen; every frame is drawn at the top left
print "\e[?25l\e[2J";
my $start = time;
my $failure;
while (!$interrupted && (my $elapsed = time - $start) < $options{seconds}) {
	my $frame = renderFrame($texture, $options{width}, $options{height}, $elapsed);

	my $encodeStart = time;
	my $sixel = '';
	my $written = $frame->write(
		data          => \$sixel,
		type          => 'sixel',
		sixel_dither  => $options{dither},
		sixel_palette => $options{palette},
	);
	unless ($written) {
		$failure = $frame->errstr;
		last;
	}
	$encodeSeconds += time - $encodeStart;
	$bytes += length $sixel;
	++$frames;

	# synchronized update (ignored by terminals without support)
	print "\e[?2026h\e[H", $sixel, "\e[?2026l";

	my $wait = $start + $frames * $frameInterval - time;
	sleep($wait) if $wait > 0;
}
my $total = time - $start;
print "\e[?25h\n";
die "$failure\n" if defined $failure;
exit 0 unless $frames;

printf STDERR "%d frames in %.1f s: %.1f fps shown, %.2f ms per encode (%.0f fps possible), %.0f KiB per frame\n",
	$frames, $total, $frames / $total, 1000 * $encodeSeconds / $frames, $frames / $encodeSeconds, $bytes / $frames / 1024;

__END__

=head1 NAME

sixel-animate.pl - play a generated animation in a SIXEL capable terminal

=head1 SYNOPSIS

  sixel-animate.pl [--width PIXELS] [--height PIXELS] [--fps RATE]
                   [--seconds DURATION] [--dither MODE] [--palette KIND]

=head1 DESCRIPTION

Renders frames with L<Imager>, encodes each with L<Imager::File::SIXEL>
and draws it at the top left corner of the terminal, aiming for the
requested frame rate. On exit it reports the frame rate achieved and
the time spent encoding.

The frame rate shown on screen is usually limited by how fast the
terminal parses and draws SIXEL data, not by the encoder.

=head1 OPTIONS

=over

=item --width PIXELS, --height PIXELS

Frame size, 640 x 480 by default. The frame must fit into the terminal
window with at least one text line to spare below it.

=item --fps RATE

Target frame rate, 60 by default.

=item --seconds DURATION

Running time, 10 seconds by default. Press Ctrl-C to stop early.

=item --dither MODE

C<none>, C<ordered> (the default) or C<diffusion>.

=item --palette KIND

C<webmap> (the default) or C<adaptive>. A fixed palette keeps unchanged
areas of the picture unchanged from frame to frame.

=back

=cut
