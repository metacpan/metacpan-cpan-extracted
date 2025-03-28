package Image::JPEG::Size;

use strict;
use warnings;

our $VERSION = '0.03';

use Carp qw(croak);
use XSLoader;

XSLoader::load(__PACKAGE__, $VERSION);

sub new {
    my $class = shift;
    my %args = @_ == 1 && ref($_[0]) eq 'HASH' ? %{ $_[0] }
             : @_ % 2 == 0 ? @_
             :    croak("$class\->new takes a hash list or hash ref");
    return $class->_new(\%args);
}

sub DESTROY { $_[0]->_destroy }

sub file_dimensions_hash {
    my ($w, $h) = shift->file_dimensions(@_);
    return width => $w, height => $h;
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Image::JPEG::Size - find the size of JPEG images

=head1 SYNOPSIS

    use Image::JPEG::Size;

    my $jpeg_sizer = Image::JPEG::Size->new;
    my ($width, $height) = $jpeg_sizer->file_dimensions($filename);

=head1 DESCRIPTION

This module uses libjpeg to rapidly determine the size of one or more JPEG
images.

=head1 CONSTRUCTOR

First create an instance of the class:

    my $jpeg_sizer = Image::JPEG::Size->new;

The constructor initialises internal libjpeg structures; if that fails, an
exception is thrown.

The constructor takes attributes as either a hash reference or a listified
hash. Unknown attributes are ignored. The following attributes are understood:

=over 4

=item C<error>

Specifies the action to take on encountering a non-recoverable error in an
image; see L</ERROR HANDLING>. Defaults to C<fatal>.

=item C<warning>

Specifies the action to take on encountering a recoverable error in an image;
see L</ERROR HANDLING>. Defaults to C<warn>.

=back

=head1 METHODS

=head2 C<file_dimensions>

You can repeatedly call C<file_dimensions> in list context to find the width
and height of your JPEG images:

    my ($width, $height) = $jpeg_sizer->file_dimensions($filename);

For now, the JPEG images must be supplied as a filename.

=head2 C<file_dimensions_hash>

In some cases, you may prefer to get the image dimensions as a hash. The
C<file_dimensions_hash> takes a single filename argument, and returns
a listified hash with keys C<width> and C<height>.

=head1 ERROR HANDLING

By default, recoverable errors in the image are reported using Perl's warning
mechanism, and non-recoverable errors cause an exception to be thrown. However,
this behaviour can be changed when creating an Image::JPEG::Size instance. The
options are:

=over 4

=item C<fatal>

Throw an exception with information about the error, and stop processing this
image immediately.

=item C<warn>

Emit a Perl warning with information about the error. If the error is
non-recoverable, image processing stops immediately, and its dimensions are
reported as 0×0 pixels.

=item C<quiet>

Suppress the error entirely. If the error is non-recoverable, image processing
stops immediately, and its dimensions are reported as 0×0 pixels.

=back

=head1 AUTHOR

Aaron Crane, E<lt>arc@cpan.orgE<gt>

Currently maintained by Robert Rothenberg E<lt>rrwo@cpan.orgE<gt>.

The initial development of this module was sponsored by Science Photo Library
L<https://www.sciencephoto.com/>.

=head1 COPYRIGHT

Copyright 2017, 2025 Aaron Crane.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
