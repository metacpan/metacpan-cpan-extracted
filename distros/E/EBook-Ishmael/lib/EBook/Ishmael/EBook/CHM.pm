package EBook::Ishmael::EBook::CHM;
use 5.016;
our $VERSION = '2.03';
use strict;
use warnings;

use File::Basename;
use File::Temp qw(tempdir);
use File::Spec;

use File::Which;
use XML::LibXML;

use EBook::Ishmael::Dir;
use EBook::Ishmael::EBook::Metadata;
use EBook::Ishmael::ImageID qw(image_path_id image_size);
use EBook::Ishmael::ShellQuote qw(safe_qx);

# TODO: Make more of an effort to find metadata

my $HAS_CHMLIB = defined which('extract_chmLib');
my $HAS_HH = defined which('hh.exe');
our $CAN_TEST = $HAS_CHMLIB || $HAS_HH;

my $MAGIC = 'ITSF';

sub heuristic {

    my $class = shift;
    my $file  = shift;
    my $fh    = shift;

    read $fh, my $mag, length $MAGIC;

    return $mag eq $MAGIC;

}

sub _extract {

    my $self = shift;

    if ($HAS_CHMLIB) {
        safe_qx('extract_chmLib', $self->{Source}, $self->{_extract});
        unless ($? >> 8 == 0) {
            die "Failed to run 'extract_chmLib' on $self->{Source}\n";
        }
    } elsif ($HAS_HH) {
        safe_qx('hh.exe', '-decompile', $self->{_extract}, $self->{Source});
        unless ($? >> 8 == 0) {
            die "Failed to run 'hh.exe' on $self->{Source}\n";
        }
    } else {
        die "Cannot extract CHM $self->{Source}; extract_chmLib nor hh.exe installed\n";
    }


    return 1;

}

sub _urlstr {

    my $self = shift;

    my $strfile = File::Spec->catfile($self->{_extract}, '#URLSTR');

    unless (-f $strfile) {
        die "Cannot read CHM $self->{Source}; #URLSTR missing\n";
    }

    open my $fh, '<', $strfile
        or die "Failed to open $strfile for reading: $!\n";
    binmode $fh;

    my @urls = split /\0+/, do { local $/ = undef; readline $fh };

    for my $url (@urls) {
        next unless $url =~ /\.html$/;
        $url = File::Spec->catfile($self->{_extract}, $url);
        next unless -f $url;
        push @{ $self->{_content} }, $url;
    }

    close $fh;

    return 1;

}

sub _hhc {

    my $self = shift;

    my ($hhc) = grep { /\.hhc$/ } dir($self->{_extract});

    unless (defined $hhc) {
        die "CHM $self->{Source} is missing HHC\n";
    }

    my $dom = XML::LibXML->load_html(
        location => $hhc,
        recover => 2,
        no_network => !$self->{Network},
    );

    my @locals = $dom->findnodes('//li/object/param[@name="Local"]');

    @{ $self->{_content} } =
        grep { /\.html?$/ }
        grep { -f }
        map { File::Spec->catfile($self->{_extract}, $_->getAttribute('value')) }
        grep { defined $_->getAttribute('value') }
        @locals;

    my ($gen) = $dom->findnodes('/html/head/meta[@name="GENERATOR"]/@content');

    if (defined $gen) {
        $self->{Metadata}->contributor([ $gen->value ]);
    }

    return 1;

}

sub _images {

    my $self = shift;
    my $dir  = shift // $self->{_extract};

    for my $f (dir($dir)) {
        if (-d $f) {
            $self->_images($f);
        } elsif (-f $f) {
            my $format = image_path_id($f);
            next if not defined $format;
            push @{ $self->{_images} }, [ $f, $format ];
        }
    }

    return 1;

}

sub _clean_html {

    my $node = shift;

    my @children = grep { $_->isa('XML::LibXML::Element') } $node->childNodes;

    # Remove the ugly nav bars from the top and bottom of the page. We
    # determine if a node is a navbar node if it contains an image that is
    # alt-tagged with either next or prev.
    if (@children and my ($alt) = $children[0]->findnodes('.//img/@alt')) {
        if ($alt->value =~ m/next|prev/i) {
            $node->removeChild(shift @children);
        }
    }
    if (@children and my ($alt) = $children[-1]->findnodes('.//img/@alt')) {
        if ($alt->value =~ m/next|prev/i) {
            $node->removeChild(pop @children);
        }
    }

    # Now get rid of the horizontal space placed before/after each nav bar.
    if (@children and $children[0]->nodeName eq 'hr') {
        $node->removeChild(shift @children);
    }
    if (@children and $children[-1]->nodeName eq 'hr') {
        $node->removeChild(pop @children);
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
        _extract => undef,
        _images  => [],
        _content => [],
    };

    bless $self, $class;

    $self->{Source} = File::Spec->rel2abs($file);

    $self->{_extract} = tempdir(CLEANUP => 1);
    $self->_extract;
    #$self->_urlstr;
    $self->_hhc;
    $self->_images;

    $self->{Metadata}->set_title((fileparse($self->{Source}, qr/\.[^.]*/))[0]);
    $self->{Metadata}->set_modified((stat $self->{Source})[9]);
    $self->{Metadata}->set_format('CHM');

    return $self;

}

sub html {

    my $self = shift;
    my $out  = shift;

    my $html = join '', map {

        my $dom = XML::LibXML->load_html(
            location => $_,
            recover => 2,
            no_network => !$self->{Network},
        );

        my ($body) = $dom->findnodes('/html/body');
        $body //= $dom->documentElement;

        _clean_html($body);

        map { $_->toString } $body->childNodes;

    } @{ $self->{_content} };

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

    my $raw = join '', map {

        my $dom = XML::LibXML->load_html(
            location => $_,
            recover => 2,
            no_network => !$self->{Network},
        );

        my ($body) = $dom->findnodes('/html/body');
        $body //= $dom->documentElement;

        $body->textContent;

    } @{ $self->{_content} };

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

    return $self->image_num > 0;

}

sub cover {

    my $self = shift;

    return (undef, undef) unless $self->has_cover;

    # Find largest image with a 1.3 height-width ratio, which is most likely
    # the cover image.
    my $cover;
    for my $i (0 .. $self->image_num - 1) {
        my ($data, $format) = $self->image($i);
        my $size = image_size($data, $format);
        if (not defined $size) {
            next;
        }
        # Cover images probably have at least a 1.3 height-width ratio.
        if ($size->[1] / $size->[0] < 1.3) {
            next;
        }
        if (
            not defined $cover or
            $cover->[2][0] * $cover->[2][1] < $size->[1] * $size->[0]
        ) {
            $cover = [ $data, $format, $size ];
        }
    }

    if (not defined $cover) {
        return (undef, undef);
    }

    return ($cover->[0], $cover->[1]);

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
    my $img = do { local $/ =  undef; readline $fh };
    close $fh;

    return ($img, $self->{_images}[$n][1]);

}

1;
