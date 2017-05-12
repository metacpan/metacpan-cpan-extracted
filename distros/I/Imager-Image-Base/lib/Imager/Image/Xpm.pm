# -*- perl -*-

# Copyright (C) 2015 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Imager::Image::Xpm;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use base 'Imager::Image::Base';

use Image::Xpm;

sub new {
    my($class, %opts) = @_;
    my $file = delete $opts{file};
    die 'file option is mandatory' if !defined $file;
    die 'Unhandled options: ' . join(' ', %opts) if %opts;
    my $xpm = Image::Xpm->new(-file => $file);
    Imager::Image::Xpm->convert($xpm);
}

sub _has_transparency {
    my(undef, $image_base) = @_;
    my $palette = $image_base->get('-palette');
    if ($palette) {
	for my $color_spec (values %$palette) {
	    return 1 if ($color_spec->{'c'}||'') =~m{^none$}i;
	}
    }
    0;
}

1;

__END__

=head1 NAME

Imager::Image::Xpm - load XPM files into Imager objects

=head1 SYNOPSIS

   $imager_object = Imager::Image::Xpm->new(file => $xpm_filename);

=head1 DESCRIPTION

Load a XPM file into an L<Imager> object using L<Image::Xpm>.

The "none" pseudo color will be converted into transparent pixels.

=head2 EXAMPLE

Convert an XPM file to a PNG file:

   use Imager::Image::Xpm;
   Imager::Image::Xpm->new(file => $xpm_file)->write(file => $png_file, type => 'png');

=head1 AUTHOR

Slaven Rezic

=head1 SEE ALSO

L<Image::Xpm>, L<Imager>, L<Imager::Image::Base>.

=cut
