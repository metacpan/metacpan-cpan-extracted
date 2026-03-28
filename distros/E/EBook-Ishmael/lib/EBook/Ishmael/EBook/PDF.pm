package EBook::Ishmael::EBook::PDF;
use 5.016;
our $VERSION = '2.04';
use strict;
use warnings;

use File::Temp qw(tempfile tempdir);
use Time::Piece;

use File::Which;
use XML::LibXML;

use EBook::Ishmael::Dir;
use EBook::Ishmael::EBook::Metadata;
use EBook::Ishmael::HTML qw(prepare_html);
use EBook::Ishmael::ImageID qw(image_path_id);
use EBook::Ishmael::ShellQuote qw(safe_qx);

# This module basically delegates the task of processing PDFs to some of
# Poppler's utilities. The processing is quite inefficient, and the output is
# ugly; PDF isn't really a format suited for plain text rendering.

my $HAS_PDFTOHTML = defined which('pdftohtml');
my $HAS_PDFINFO   = defined which('pdfinfo');
my $HAS_PDFTOPNG  = defined which('pdftopng');
my $HAS_CONVERT   = defined which('convert');
my $HAS_PDFIMAGES = defined which('pdfimages');

our $CAN_TEST = (
    $HAS_PDFTOHTML                  and
    $HAS_PDFINFO                    and
    ($HAS_PDFTOPNG or $HAS_CONVERT) and
    $HAS_PDFIMAGES
);

my $MAGIC = '%PDF';

sub heuristic {

    my $class = shift;
    my $file  = shift;
    my $fh    = shift;

    read $fh, my ($mag), 4;

    return $mag eq $MAGIC;

}

sub _parse_pdf_date {

    my ($date) = @_;
    $date =~ s/^D://;
    $date =~ s/'//g;

    my ($year, $month, $day, $hour, $min, $sec, $tz) =
        $date =~ /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(Z|[+-]\d{4})$/
        or die "Invalid PDF date\n";

    if ($tz eq 'Z') {
        $tz = '+0000';
    }

    my $tp = eval {
        Time::Piece->strptime(
            "$year $month $day $hour $min $sec $tz",
            '%Y %m %d %H %M %S %z',
        )
    } or die "Failed to parse '$date'\n";
    return $tp->epoch;

}

sub _get_metadata {

    my $self = shift;

    my %meta = (
        'Author'       => sub { $self->{Metadata}->add_author(shift) },
        'CreationDate' => sub { $self->{Metadata}->set_created(eval { _parse_pdf_date(shift) }) },
        'Creator'      => sub { $self->{Metadata}->add_contributor(shift) },
        'ModDate'      => sub { $self->{Metadata}->set_modified(eval { _parse_pdf_date(shift) }) },
        'PDF version'  => sub { $self->{Metadata}->set_format('PDF ' . shift) },
        'Producer'     => sub { $self->{Metadata}->add_contributor(shift) },
        'Title'        => sub { $self->{Metadata}->set_title(shift) },
    );

    if (!$HAS_PDFINFO) {
        die "Cannot read PDF $self->{Source}: pdfinfo not installed\n";
    }

    my $info = safe_qx('pdfinfo', '-rawdates', $self->{Source});
    unless ($? >> 8 == 0) {
        die "Failed to run 'pdfinfo' on $self->{Source}\n";
    }

    for my $l (split /\n/, $info) {
        my ($field, $content) = split /:\s*/, $l, 2;
        unless (exists $meta{ $field } and $content) {
            next;
        }
        $meta{$field}->($content);
    }

    return 1;

}

sub _images {

    my $self = shift;

    $self->{_imgdir} = tempdir(CLEANUP => 1);

    my $root = File::Spec->catfile($self->{_imgdir}, 'ishmael');

    # TODO: Couldn't we just use system?
    safe_qx('pdfimages', '-png', $self->{Source}, $root);
    unless ($? >> 8 == 0) {
        die "Failed to run 'pdfimages' on $self->{Source}\n";
    }

    for my $f (dir($self->{_imgdir})) {
        my $format = image_path_id($f);
        next if not defined $format;
        push @{ $self->{_images} }, [ $f, $format ];
    }

    return 1;

}

sub new {

    my $class = shift;
    my $file  = shift;
    my $enc   = shift;
    my $net   = shift // 1;

    my $self = {
        Source   => undef,
        Metadata => EBook::Ishmael::EBook::Metadata->new,
        Network  => $net,
        _imgdir  => undef,
        _images  => [],
    };

    bless $self, $class;

    $self->{Source} = File::Spec->rel2abs($file);

    $self->_get_metadata();

    if (not defined $self->{Metadata}->format) {
        $self->{Metadata}->set_format('PDF');
    }

    return $self;

}

sub html {

    my $self = shift;
    my $out  = shift;

    if (!$HAS_PDFTOHTML) {
        die "Cannot read PDF $self->{Source}: pdftohtml not installed\n";
    }

    my $raw = safe_qx('pdftohtml', '-i', '-s', '-stdout', $self->{Source});
    unless ($? >> 8 == 0) {
        die "Failed to run 'pdftohtml' on $self->{Source}\n";
    }

    my $dom = XML::LibXML->load_html(
        string => $raw,
        no_network => !$self->{Network},
    );

    my ($body) = $dom->findnodes('/html/body');
    prepare_html($body);

    my $html = join '', map { $_->toString } $body->childNodes;

    if (defined $out) {
        open my $fh, '>', $out
            or die "Failed to open $out for writing: $!\n";
        binmode $fh, ':utf8';
        print { $fh } $html;
        close $fh;
        return $out;
    } else {
        return $html;
    }

}

sub raw {

    my $self = shift;
    my $out  = shift;

    if (!$HAS_PDFTOHTML) {
        die "Cannot read PDF $self->{Source}: pdftohtml not installed\n";
    }

    my $rawml = safe_qx('pdftohtml', '-i', '-s', '-stdout', $self->{Source});
    unless ($? >> 8 == 0) {
        die "Failed to run 'pdftohtml' on $self->{Source}\n";
    }

    my $dom = XML::LibXML->load_html(
        string => $rawml,
        no_network => !$self->{Network},
    );

    my ($body) = $dom->findnodes('/html/body');
    prepare_html($body);

    my $raw = join '', $body->textContent;

    if (defined $out) {
        open my $fh, '>', $out
            or die "Failed to open $out for writing: $!\n";
        binmode $fh, ':utf8';
        print { $fh } $raw;
        close $fh;
        return $out;
    } else {
        return $raw;
    }

}

sub metadata {

    my $self = shift;

    return $self->{Metadata};

}

sub has_cover { 1 }

# Convert the first page of the PDF to a png as the cover, using either
# xpdf's pdftopng or ImageMagick's convert.
sub cover {

    my $self = shift;

    unless ($HAS_PDFTOPNG or $HAS_CONVERT) {
        die "Cannot dump PDF $self->{Source} cover: pdftopng or convert not installed\n";
    }

    my $png;

    if ($HAS_PDFTOPNG) {
        my $tmpdir = tempdir(CLEANUP => 1);
        my $tmproot = File::Spec->catfile($tmpdir, 'tmp');

        safe_qx('pdftopng', '-f', 1, '-l', 1, $self->{Source}, $tmproot);
        unless ($? >> 8 == 0) {
            die "Failed to run 'pdftopng' on $self->{Source}\n";
        }

        $png = (dir($tmpdir))[0];
        unless (defined $png) {
            die "'pdftopng' could not produce a cover image from $self->{Source}\n";
        }

    } elsif ($HAS_CONVERT) {
        my $tmppath = do {
            my ($h, $p) = tempfile(UNLINK => 1);
            close $h;
            $p;
        };

        # The '[0]' means the first page only
        safe_qx('convert', "$self->{Source}\[0\]", '-alpha', 'deactivate', "png:$tmppath");
        if (not -f $tmppath) {
            die "'convert' could not produce a cover image from $self->{Source}\n";
        }
        $png = $tmppath;

    } else {
        die;
    }

    open my $fh, '<', $png
        or die "Failed to open $png for reading: $!\n";
    binmode $fh;
    my $bin = do { local $/ = undef; readline $fh };
    close $fh;

    return ($bin, 'png');


}

sub image_num {

    my $self = shift;

    unless (defined $self->{_imgdir}) {
        $self->_images;
    }

    return scalar @{ $self->{_images} };

}

sub image {

    my $self = shift;
    my $n    = shift;

    if ($n >= $self->image_num) {
        return (undef, undef);
    }

    open my $fh, '<', $self->{_images}[$n][0]
        or die "Failed to open $self->{_images}[$n][0]: $!\n";
    binmode $fh;
    my $img = do { local $/ = undef; readline $fh };
    close $fh;

    return ($img, $self->{_images}[$n][1]);

}

1;
