# -*- perl -*-

# Copyright (C) 2015 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Imager::Image::Xbm;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use base 'Imager::Image::Base';

use Image::Xbm;

sub new {
    my($class, %opts) = @_;
    my $file = delete $opts{file};
    die 'file option is mandatory' if !defined $file;
    die 'Unhandled options: ' . join(' ', %opts) if %opts;
    my $xbm = Image::Xbm->new(-file => $file);
    $class->convert($xbm);
}

1;

__END__

=head1 NAME

Imager::Image::Xbm - load X11 bitmap files into Imager objects

=head1 SYNOPSIS

   $imager_object = Imager::Image::Xpm->new(file => $xbm_filename);

=head1 DESCRIPTION

Load a XBM (X11 bitmap) file into an L<Imager> object using L<Image::Xbm>.

=head2 EXAMPLE

Convert an XBM file to a PNG file:

   use Imager::Image::Xbm;
   Imager::Image::Xbm->new(file => $xbm_file)->write(file => $png_file, type => 'png');

=head1 AUTHOR

Slaven Rezic

=head1 SEE ALSO

L<Image::Xbm>, L<Imager>, L<Imager::Image::Base>.

=cut
