use strict;
use warnings;

# ABSTRACT: Extract the Smart Health Card information from files

use PostScript::Convert;

package Health::SHC::Extract;

our $VERSION = '0.005';

=head1 NAME

Health::SHC::Extract - Extract Smart Health Card QR codes from PDFs or png files.

=head1 SYNOPSIS

    use Health::SHC::Extract;

    my $shc = Health::SHC::Extract->new();

    my @qrcodes = $shc->extract_qr_from_pdf('t/sample-qr-code.pdf');

    my @qrcodes = $shc->extract_qr_from_png('t/sample-qr-code.png');

=head1 DESCRIPTION

This perl module can extract a Smart Health Card's data from QR codes in
PDFs or image files.

The extract_qr_from_pdf function converts a pdf to a png and then calls
extract_qr_from_png.

=cut

=head1 PREREQUISITES

=over

=item * L<PostScript::Convert>

=item * L<File::Temp>

=item * L<Image::Magick>

=item * L<Barcode::ZBar>

=back

=cut

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2021 Timothy Legge <timlegge@cpan.org>

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 METHODS

=head3 B<new(...)>

Constructor; see OPTIONS above.

=cut

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;
}

=head3 B<extract_qr_from_pdf($filename)>

Extracts any Smart Health Card URI data from the QR codes found
in the PDF file.  It converts the PDF to a png file and extracts
the URIs from the image file by calling extract_qr_from_png.

Arguments:
    $filename:     string filename of a pdf file.

Returns: ARRAY  shc:/ URI from QR code

=cut

sub extract_qr_from_pdf {
    my $self     = shift;
    my $filename = shift;

    if ( ! -e $filename ) {
        return;
    }

    use File::Temp qw/ tempfile tempdir /;
    my ($fh, $output_filename) = tempfile('shctempfileXXXXX', SUFFIX => '.png');

    PostScript::Convert::psconvert($filename, filename => $output_filename, format => 'pnggray');
    my @qrcodes = $self->extract_qr_from_png($output_filename);

    unlink $output_filename;
    return @qrcodes;
}

=head3 B<extract_qr_from_png($filename)>

Extracts any Smart Health Card URI data from the QR codes found
in a png file.

Returns an array of shc:/ URIs

Arguments:
    $filename:     string filename of a png file.

Returns: ARRAY  shc:/ URI from QR code

=cut
sub extract_qr_from_png {
    my $self = shift;
    my $filename = shift;

    require Image::Magick;
    require Barcode::ZBar;

    # obtain image data
    my $magick = Image::Magick->new();
    $magick->Read($filename) && die;
    my $raw = $magick->ImageToBlob(magick => 'GRAY', depth => 8);

    # wrap image data
    my $image = Barcode::ZBar::Image->new();
    $image->set_format('Y800');
    my ($col, $rows) = $magick->Get(qw(columns rows));
    $image->set_size($col, $rows);
    $image->set_data($raw);

    # create a reader
    my $scanner = Barcode::ZBar::ImageScanner->new();

    # configure the reader
    $scanner->parse_config("enable");

    # scan the image for barcodes
    my $n = $scanner->scan_image($image);

    # extract results
    my @qrcodes;
    foreach my $symbol ($image->get_symbols()) {
        # do something useful with results
        my $data = $symbol->get_data();

        if ($data =~ /^shc:\//) {
            push (@qrcodes, $data);
        }
    }

    # clean up
    undef($image);
    return @qrcodes;
}
1;
