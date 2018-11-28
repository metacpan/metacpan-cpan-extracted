package Ithumb::XS;

=encoding UTF-8

=head1 NAME

Ithumb::XS - Small and simple thumbnail module, based on Imlib2 library.

=head1 DESCRIPTION

Ithumb::XS is a very small (one function) and simple Perl-XS module
for creation a thumbnails, using Imlib2 library.

=head1 MAINTAINERS

Peter P. Neuromantic <p.brovchenko@protonmail.com>

=cut

use 5.020001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( create_thumbnail );

our $VERSION = 'v0.1.4.1';

require XSLoader;
XSLoader::load('Ithumb::XS', $VERSION);

1;

__END__

=head1 SYNOPSIS

  use Ithumb::XS;

  Ithumb::XS::create_thumbnail('src.png', 100, 100, 'output.png');

=head1 METHODS

=head2 create_thumbnail($src_image, $width, $height, $dst_image);

Creates a small copy (with cropping) of the image.

=over 12

=item C<$source_image> - full path to source image

=item C<$width> - destination width

=item C<$height> - destination height

=item C<$dst_image> - full path to destionation result image
  
=back

=head1 LICENSE

BSD 3-Clause License

Copyright (c) 2018, Peter P. Neuromantic <p.brovchenko@protonmail.com>
All rights reserved.

See LICENSE file for more details.

=cut
