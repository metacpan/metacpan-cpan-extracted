package Ithumb::XS;

=encoding UTF-8

=head1 NAME

Ithumb::XS - Image thumbnail creation routines

=head1 DESCRIPTION

Ithumb::XS is a fast, small (one function) and simple Perl-XS module
for creation a thumbnails, using Imlib2 library.

=head1 MAINTAINERS

Peter P. Neuromantic <p.brovchenko@protonmail.com>

=cut

use 5.024000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( convert_image );

our $VERSION = 'v0.4.0';

require XSLoader;
XSLoader::load('Ithumb::XS', $VERSION);

1;

__END__

=head1 SYNOPSIS

  use Ithumb::XS ();

  Ithumb::XS::convert_image({
      width     => 800,
      height    => 600,
      src_image => 'src_image.jpg',
      dst_image => 'dst_image.jpg'
  });

OO-interface:

  use Ithumb::XS;

  my $ithumb = Ithumb::XS->new;
  $ithumb->convert({
      width     => 800,
      height    => 600,
      src_image => 'src_image.jpg',
      dst_image => 'dst_image.jpg'
  });

=head1 METHODS

=head2 convert_image($);

Creates a small copy (with cropping) of the image.

=over 12

=item $_[0]->{width} - destination width

=item $_[0]->{height} - destination height

=item $_[0]->{src_image} - path to the source image

=item $_[0]->{dst_image} - path to the destionation result image

=back

=head2 convert($);

Creates a small copy (with cropping) of the image for OO-interface.

=over 12

=item $_[0]->{width} - destination width

=item $_[0]->{height} - destination height

=item $_[0]->{src_image} - path to the source image

=item $_[0]->{dst_image} - path to the destionation result image

=back

=head1 LICENSE

BSD 3-Clause License

Copyright (c) 2018, 2019 Peter P. Neuromantic <p.brovchenko@protonmail.com>
All rights reserved.

See LICENSE file for more details.

=cut
