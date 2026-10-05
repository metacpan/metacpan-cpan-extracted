#!/usr/bin/env perl
# Displays image files in a SIXEL capable terminal.
#
# Copyright (C) 2026 davenonymous.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
use v5.24;
use warnings;

use Getopt::Long qw(GetOptions);
use Imager;
use Imager::File::SIXEL;
use Pod::Usage qw(pod2usage);

my %options = (dither => 'diffusion');
GetOptions(\%options, 'width=i', 'height=i', 'dither=s', 'colors=i', 'help')
	or pod2usage(2);
pod2usage(1) if $options{help};
pod2usage('no image files given') unless @ARGV;

binmode STDOUT, ':raw';
my $failures = 0;
foreach my $file (@ARGV) {
	my $img = Imager->new(file => $file);
	unless ($img) {
		warn "$file: ", Imager->errstr, "\n";
		++$failures;
		next;
	}

	if ($options{width} || $options{height}) {
		$img = $img->scale(
			($options{width}  ? (xpixels => $options{width})  : ()),
			($options{height} ? (ypixels => $options{height}) : ()),
			type => 'min',
		);
	}

	my $sixel = '';
	my $written = $img->write(
		data             => \$sixel,
		type             => 'sixel',
		sixel_dither     => $options{dither},
		sixel_max_colors => $options{colors} // 256,
	);
	unless ($written) {
		warn "$file: ", $img->errstr, "\n";
		++$failures;
		next;
	}
	print $sixel, "\n";
}
exit($failures ? 1 : 0);

__END__

=head1 NAME

sixel-cat.pl - display images in a SIXEL capable terminal

=head1 SYNOPSIS

  sixel-cat.pl [--width PIXELS] [--height PIXELS] [--dither MODE]
               [--colors COUNT] FILE...

=head1 DESCRIPTION

Reads every FILE with L<Imager>, in any format Imager supports, and
writes it to standard output as a SIXEL image followed by a line break.

=head1 OPTIONS

=over

=item --width PIXELS, --height PIXELS

Scale the image, keeping its aspect ratio, to the largest size that
fits the given width and/or height; smaller images are enlarged.

=item --dither MODE

C<none>, C<ordered> or C<diffusion> (the default). See
L<Imager::File::SIXEL/sixel_dither>.

=item --colors COUNT

The largest number of colors to use, from 1 to 256 (the default).

=back

=head1 EXAMPLES

  sixel-cat.pl photo.png
  sixel-cat.pl --width 400 --dither ordered *.jpg

=cut
