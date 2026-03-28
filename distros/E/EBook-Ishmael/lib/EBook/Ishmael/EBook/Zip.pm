package EBook::Ishmael::EBook::Zip;
use 5.016;
our $VERSION = '2.04';
use strict;
use warnings;

use Encode qw(decode);
use File::Basename;
use File::Path qw(remove_tree);
use File::Spec;
use List::Util qw(first);

use XML::LibXML;

use EBook::Ishmael::CharDet;
use EBook::Ishmael::Dir;
use EBook::Ishmael::ImageID qw(image_path_id is_image_path);
use EBook::Ishmael::EBook::Metadata;
use EBook::Ishmael::HTML qw(prepare_html text2html);
use EBook::Ishmael::Unzip qw(unzip safe_tmp_unzip);

# This isn't any official format, but generic zip archives are a common way of
# distributing some ebooks. This module basically looks for any text or HTML
# files and extracts content from those.

# TODO: Sort files more accurately
# For example, a zip file with these files would be sorted incorrectly:
# z/file-1.html
# z/file-2.html
# ...
# z/file-10.html   These will be sorted before file-2.html
# z/file-11.html

my $MAGIC = pack 'C4', ( 0x50, 0x4b, 0x03, 0x04 );

sub heuristic {

    my $class = shift;
    my $file  = shift;
    my $fh    = shift;

    return 0 unless $file =~ /\.zip$/;

    read $fh, my $mag, length $MAGIC;

    return $mag eq $MAGIC;

}

sub _images {

    my $dir = shift;

    my @img;

    for my $f (dir($dir)) {
        if (-d $f) {
            push @img, _images($f);
        } elsif (-f $f and is_image_path($f)) {
            push @img, $f;
        }
    }

    return @img;

}

sub _files {

    my $self = shift;
    my $dir  = shift;

    for my $f (dir($dir)) {
        if (-d $f) {
            $self->_files($f);
        } elsif (-f $f and is_image_path($f)) {
            push @{ $self->{_images} }, [ $f, image_path_id($f) ];
        } elsif (-f $f and $f =~ /\.(x?html?|txt)$/) {
            push @{ $self->{_content} }, $f;
        }
    }

}

sub new {

    my $class = shift;
    my $file  = shift;
    my $enc   = shift;
    my $net   = shift // 1;

    my $self = {
        Source   => undef,
        Metadata => EBook::Ishmael::EBook::Metadata->new,
        Encode   => $enc,
        Network  => $net,
        _tmpdir  => undef,
        _content => [],
        _images  => [],
        _cover   => undef,
    };

    bless $self, $class;

    my $title = (fileparse($file, qr/\.[^.]*/))[0];

    $self->{Source} = File::Spec->rel2abs($file);

    $self->{_tmpdir} = safe_tmp_unzip;
    unzip($self->{Source}, $self->{_tmpdir});

    $self->_files($self->{_tmpdir});

    unless (@{ $self->{_content} }) {
        die "$self->{Source}: Found no content files in Zip ebook archive\n";
    }

    $self->{_cover} = first { basename($_) =~ m/cover/i } @{ $self->{_images} };
    $self->{_cover} //= $self->{_images}[0];

    $self->{Metadata}->set_title($title);
    $self->{Metadata}->set_modified((stat $self->{Source})[9]);
    $self->{Metadata}->set_format('Zip');

    return $self;

}

sub html {

    my $self = shift;
    my $out  = shift;

    my $html = '';

    for my $f (@{ $self->{_content} }) {
        if ($f =~ /\.txt$/) {
            open my $fh, '<', $f
                or die "Failed to open $f for reading: $!\n";
            binmode $fh;
            my $text = do { local $/; <$fh> };
            close $fh;
            if (not defined $self->{Encode}) {
                $self->{Encode} = chardet($text) // 'ASCII';
            }
            $html .= text2html(decode($self->{Encode}, $text));
        } else {
            my $dom = XML::LibXML->load_html(
                location => $f,
                recover => 2,
                no_network => !$self->{Network},
            );
            my ($body) = $dom->findnodes('/html/body');
            $body //= $dom->documentElement;
            prepare_html($body);
            $html .= join '', map { $_->toString } $body->childNodes;
        }
    }

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

    my $raw;
    for my $c (@{ $self->{_content} }) {
        if ($c =~ /\.txt$/) {
            open my $fh, '<', $c
                or die "Failed to open $c for reading: $!\n";
            binmode $fh;
            my $r = do { local $/; <$fh> };
            close $fh;
            if (not defined $self->{Encode}) {
                $self->{Encode} = chardet($r) // 'ASCII';
            }
            $raw .= decode($self->{Encode}, $r) . "\n\n";
        } else {
            my $dom = XML::LibXML->load_html(
                location => $c,
                recover => 2,
                no_network => !$self->{Network},
            );
            my ($body) = $dom->findnodes('/html/body');
            $body //= $dom->documentElement;
            prepare_html($body);
            $raw .= $body->textContent . "\n\n";
        }
    }
    $raw =~ s/\n\n//;

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

sub has_cover {

    my $self = shift;

    return defined $self->{_cover};

}

sub cover {

    my $self = shift;

    return (undef, undef) unless $self->has_cover;

    open my $fh, '<', $self->{_cover}[0]
        or die "Failed to open $self->{_cover}[0] for reading: $!\n";
    binmode $fh;
    my $bin = do { local $/ = undef; readline $fh };
    close $fh;

    return ($bin, $self->{_cover}[1]);

}

sub image_num {

    my $self = shift;

    return scalar @{ $self->{_images} };

}

sub image {

    my $self = shift;
    my $n    = shift;

    if ($n >= $self->image_num) {
        return (undef, undef);
    }

    open my $fh, '<', $self->{_images}[$n][0]
        or die "Failed to open $self->{_images}[$n][0] for reading: $!\n";
    binmode $fh;
    my $img = do { local $/ = undef; readline $fh };
    close $fh;

    return ($img, $self->{_images}[$n][1]);

}

DESTROY {

    my $self = shift;

    remove_tree($self->{_tmpdir}, { safe => 1 }) if -d $self->{_tmpdir};

}

1;
