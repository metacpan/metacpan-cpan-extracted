package Email::Barcode::Decode;

use warnings;
use strict;

use Carp 'croak';
use Email::MIME;
use File::Temp qw(tempdir);
use File::Find::Rule;
use Path::Class qw(file);
use Image::Magick;
use Barcode::ZBar;
use Cwd 'getcwd';
use Capture::Tiny 'capture';
use File::Which qw(which);

our $VERSION = '0.04';

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw{
    email
    header_obj
    attached_files
    _tmpdir
});

our @enhancers = (
    sub {
        my ($magick) = @_;
        $magick->Normalize();
        $magick->Contrast(sharpen => 1);

        my ($width,$height) = $magick->Get(qw(columns rows));
        $magick->Resize(height=>1500,width=>int($width*(1500/$height)))
            if $height > 1500;

        my $raw = $magick->ImageToBlob(
            magick            => 'YUV',
            'sampling-factor' => '4:2:2',
            interlace         => 'Plane'
        );

        return ($raw,'Y800');
    },
    sub {
        my ($magick) = @_;
        $magick->Set(dither => 'False');
        $magick->Quantize(colors     => 2);
        $magick->Quantize(colorspace => 'gray');
        $magick->ContrastStretch(levels => 0);

        my ($width,$height) = $magick->Get(qw(columns rows));
        $magick->Resize(height=>1500,width=>int($width*(1500/$height)))
            if $height > 1500;

        my $raw = $magick->ImageToBlob(magick => 'GRAY', depth => 8);

        return ($raw,'Y800');
    },
);

sub new {
    my ($class, %opts) = @_;

    my $email = $opts{email};
    croak 'need email string as argument'
        unless $email;

    my $tmpdir = tempdir( CLEANUP => 1 );
    $opts{_tmpdir} = $tmpdir;

    my @attached_files;
    my $parsed            = Email::MIME->new($email);
    $opts{header_obj}     = $parsed->header_obj;
    $opts{attached_files} = \@attached_files;

    foreach my $part ($parsed->parts) {
        my $filename = $part->filename;
        next unless $filename;
        my $body = $part->body;

        if ((
                ($part->content_type =~ m{application/pdf})
                || ($filename =~ m{\.pdf$})
            )
            && (scalar(which("gs")))
        ) {
            my $tmpdir2 = tempdir( CLEANUP => 1 );
            my $attached_pdf = file($tmpdir2, 'attached.pdf');
            $attached_pdf->spew($body);
            
            my $old_cwd = getcwd;
            chdir($tmpdir2);
            
            my ($stdout, $stderr, $exit) = capture {
                system(qw(
                    gs -dNOPAUSE -sDEVICE=jpeg -dFirstPage=1 -dLastPage=237
                    -sOutputFile=page%d.jpg -dJPEGQ=100 -r150x150 -q attached.pdf
                    -c quit
                ));
            };
            my @files =
                map { file($_) }
                sort
                File::Find::Rule
                ->file()
                ->name( 'page*.jpg' )
                ->in( $tmpdir2 );
            my $base_name = $filename;
            $base_name =~ s/[.]/-/g;
            foreach my $file (@files) {
                my $image_file = file($tmpdir, $base_name.'-'.$file->basename);
                $file->copy_to($image_file);
                push(@attached_files, $image_file);
            }
            
            chdir($old_cwd);
        }
        else {
            my $attached_file = file($tmpdir, $filename);
            $attached_file->spew($body);
            push(@attached_files, $attached_file);
        }
    }

    my $self  = $class->SUPER::new(\%opts);
    return $self;
}

sub get_symbols {
    my ($self) = @_;

    my $scanner = Barcode::ZBar::ImageScanner->new();
    $scanner->parse_config("enable");

    my @symbols;
    foreach my $file (@{$self->attached_files}) {
        my %unique_data;
        foreach my $enhancer (@enhancers) {
            my @new_symbols = _get_symbols_from_file($scanner, $file, $enhancer,);

            push(
                @symbols, (
                    map { +{
                        filename => $file->basename,
                        type     => $_->get_type,
                        data     => $_->get_data,
                    }}
                    grep { not($unique_data{$_->get_data}++) }   # only new/unique
                    @new_symbols,
                ),
            );
        }
    }

    return @symbols;
}

sub _get_symbols_from_file {
    my ($scanner, $file, $enhance_code) = @_;

    my $magick = Image::Magick->new();
    my $error = $magick->Read($file);
    die $error if $error;

    my ($raw, $raw_format) = $enhance_code->($magick);

    my $image = Barcode::ZBar::Image->new();
    $image->set_format($raw_format);
    $image->set_size($magick->Get(qw(columns rows)));
    $image->set_data($raw);

    $scanner->scan_image($image);

    return $image->get_symbols;
}

sub email_name {
    my ($self) = @_;
    my ($from) = Email::Address->parse($self->header_obj->header('From'));
    return $from->name;
}

sub email_from {
    my ($self) = @_;
    my ($from) = Email::Address->parse($self->header_obj->header('From'));
    return $from->address;
}



1;


__END__

=head1 NAME

Email::Barcode::Decode - decode barcodes out of an email

=head1 SYNOPSIS

    my $ebd = Email::Barcode::Decode->new(email => $msg);
    my @symbols = $ebd->get_symbols;
    foreach my $symbol (@symbols) {
        print(
            'decoded '  . $symbol->{type} .
            ' symbol "' . $symbol->{data} .'"'.
            ' file "'   . $symbol->{filename} .'"'.
            "\n"
        );
    }

=head1 DESCRIPTION

This module can extract barcode information out of email attachments.
It processes all email image attachments. When Ghostscript is installed
it converts every page into image. Images are scanned for barcodes using
L<Barcode::ZBar>.

=head1 PROPERTIES

    email
    header_obj
    attached_files

=head1 METHODS

=head2 new()

Object constructor. Requires C<email> string.

=head2 get_symbols()

Returns an array of hashed with barcode information. Ex.:

    my @symbols = ({
        filename => 'vcard-pdf-page2.jpg',
        type     => 'QR-Code',
        data     => 'http://search.cpan.org/perldoc?Email%3A%3ABarcode%3A%3ADecode',
    });

=head1 AUTHOR

Jozef Kutej

=cut
