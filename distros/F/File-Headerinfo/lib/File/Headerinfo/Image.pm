package File::Headerinfo::Image;

use strict;
use base qw(File::Headerinfo);
use Image::Size;

=head1 NAME

File::Headerinfo::Image - an extractor of useful information from image files.

=head1 DESCRIPTION

I<File::Headerinfo::Image> is a thin (going on invisible) wrapper around Image::Size, which is able to retrieve dimensions from most types of image file.

=cut

sub parse_file {
	my $self = shift;
    my ($w, $h, $type) = Image::Size::imgsize( $self->path );
    return unless $w;
    $self->filetype(lc($type));
    $self->width($w);
    $self->height($h);
}

=head1 COPYRIGHT

Copyright 2004 William Ross (wross@cpan.org)

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Delivery>, L<Delivery::Clip>, L<Delivery::Clip::File>, L<Delivery::Clip::File::Reader>

=cut

1;