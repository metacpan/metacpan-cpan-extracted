package Graphics::Magick::ColorHistogram;

use 5.008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(histogram);
our @EXPORT = qw();

our $VERSION = '1.00';

require XSLoader;
XSLoader::load('Graphics::Magick::ColorHistogram', $VERSION);

1;
__END__

=head1 NAME

Graphics::Magick::ColorHistogram - Calculate color frequency with optional quantization

=head1 SYNOPSIS

  use Graphics::Magick::ColorHistogram 'histogram';

  # calculate frequency of color in an image
  $counts = histogram("image.png"); # { aa77ff => 60, ... }

  # quantize image first then count
  $counts = histogram("image.jpg", 2); # at most two colors

=head1 FUNCTIONS

=over 4

=item histogram($filename, [$max_colors])

This routine counts the number of times each present color appears in an image.
Optionally, a number of colors can be given and the image data will first be
quantized to have no more than that many colors in it.

The return value is a hashref which maps hex RGB triplets to counts.

=back

=head1 EXPORTS

None by default, C<histogram> at request.

=head1 SEE ALSO

See http://www.graphicsmagick.org/quantize.html for information on how
the quantization is performed.

=head1 AUTHOR

Adam Thomason, E<lt>athomason@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Say Media Inc <cpan@saymedia.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut
