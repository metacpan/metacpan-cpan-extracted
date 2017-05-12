package Image::JpegCheck;
use strict;
use warnings;
use 5.008001;
use bytes;
use Fcntl ':seek';
use Carp ();
our $VERSION = '0.10';
our @ISA = qw/Exporter/;
our @EXPORT = ('is_jpeg');

sub is_jpeg {
    my ($file, ) = @_;
    if (ref $file) {
        if (ref $file eq 'GLOB') {
            return Image::JpegCheck::_is_jpeg($file);
        } elsif (ref $file eq 'SCALAR') {
            open my $fh, '<', $file or die $!;
            return Image::JpegCheck::_is_jpeg($fh);
        } elsif (ref $file eq 'Path::Class::File') {
            return Image::JpegCheck::_is_jpeg($file->openr);
        } else {
            Carp::croak('is_jpeg requires file-glob or filename');
        }
    } else {
        open my $fh, '<', $file or die $!;
        binmode $fh;
        my $ret = Image::JpegCheck::_is_jpeg($fh);
        close $fh;
        return $ret;
    }
}

use constant {
    SIZE_FIRST     => 0xC0,         # Range of segment identifier codes
    SIZE_LAST      => 0xC3,         #  that hold size info.
    SECTION_MARKER => "\xFF",
    SOI            => "\xFF\xD8",
    EOI            => "\xFF\xD9",
    EOI_RE         => qr/\xFF\xD9\xFF*$/,
    READ_SIZE      => 512,
    BYTE_STUFFING  => "\xFF"x512,
};

sub _is_jpeg {
    my $fh = $_[0];
    my ($buf, $code, $marker, $len);

    read($fh, $buf, 2);
    return 0 if $buf ne SOI;

    while (1) {
        read($fh, $buf, 2);
        ($marker, $code) = unpack("a a", $buf); # read segment header

        while ( $code eq SECTION_MARKER && ($marker = $code) ) {
            read($fh, $buf, 1);
           ($code) = unpack("a", $buf);
       }
       read($fh, $buf, 2);
       $len = unpack( "n", $buf );
        $code = ord($code);

        if ($marker ne SECTION_MARKER) {
            return 0; # invalid marker
        } elsif (($code >= SIZE_FIRST) && ($code <= SIZE_LAST)) {
            return 1; # got a size info
        } else {
            seek $fh, $len-2, SEEK_CUR; # skip segment body
        }
    }
    die "should not reach here";
}

1;
__END__

=head1 NAME

Image::JpegCheck - is this jpeg?

=head1 SYNOPSIS

  use Image::JpegCheck;
  is_jpeg('foo.jpg'); # => return 1 when this is jpeg

=head1 DESCRIPTION

Image::JpegCheck is jpeg file checker for perl.

Yes, I know. I know the L<Imager>, L<GD>, L<Image::Magick>, L<Image::Size>,
etc.But, I need tiny one. I want to use this module in the mod_perl =)

Code is taken from L<Image::Size>, and optimized it.

=head1 FUNCTIONS

=over 4

=item is_jpeg($stuff)

is_jpeg($stuff) validates your jpeg.stuff is:

    scalar:            filename
    scalarref:         jpeg itself
    file-glob:         file handle
    Path::Class::File: file object

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom ah! gmail.comE<gt>

=head1 THANKS TO

kazeburo++

yappo++

=head1 SEE ALSO

L<Image::Size>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
