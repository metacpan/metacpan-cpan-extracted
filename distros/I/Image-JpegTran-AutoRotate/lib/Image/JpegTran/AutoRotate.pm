package Image::JpegTran::AutoRotate;
use 5.006;
use strict;
use Exporter ();
use Image::ExifTool ();
use Image::JpegTran qw(jpegtran);
use File::Temp qw(:POSIX);
use File::Copy qw(copy);

our $VERSION = '0.04';
our @ISA = qw(Exporter);
our @EXPORT = qw(auto_rotate);

sub auto_rotate {
    my ($from, $to) = @_;
    -s $from or return;
    my $exifTool = Image::ExifTool->new;
    $exifTool->ExtractInfo($from) or return;
    my $orientation = $exifTool->GetValue(Orientation => 'Raw') or return;
    my %TransformMap = (
        2 => [flip => 'horizontal'],
        3 => [rotate => 180],
        4 => [flip => 'vertical'],
        5 => ['transpose' => 1],
        6 => [rotate => 90],
        7 => ['transverse' => 1],
        8 => [rotate => 270]
    );
    my $transform = $TransformMap{$orientation} or return -1;
    my $tmp;
    $tmp = tmpnam() unless defined $to;
    jpegtran($from => ($tmp || $to), @$transform);
    if ($tmp and -s $tmp) {
        $to = $from;
        copy($tmp => $to) or return;
        unlink $tmp or return;
    }
    $exifTool->ExtractInfo($to) or return;
    $exifTool->SetNewValue(Orientation => 'Horizontal (normal)');
    $exifTool->WriteInfo($to);
    return 1;
}

__END__

=encoding utf8

=head1 NAME

Image::JpegTran::AutoRotate - Losslessly fix JPEG orientation

=head1 SYNOPSIS

    use Image::JpegTran::AutoRotate; # auto-exports auto_rotate

    auto_rotate('file.jpg'); # rotates in-place (via a temporary file)
    auto_rotate('from.jpg' => 'to.jpg'); # writes to another file

=head1 DESCRIPTION

Transforms JPEG files so that orientation becomes 1.

This is the same operation as C<exifautotran>, but with no dependencies on
command-line programs; instead, we use the excellent L<Image::JpegTran> and
L<Image::ExifTool> CPAN modules.

=head1 SEE ALSO

L<http://sylvana.net/jpegcrop/exif_orientation.html>

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<Image::JpegTran::AutoRotate>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
