package EBook::Ishmael::EBook::Epub;
use 5.016;
our $VERSION = '2.03';
use strict;
use warnings;

use File::Basename;
use File::Path qw(remove_tree);
use File::Spec;

use XML::LibXML;

use EBook::Ishmael::EBook::Metadata;
use EBook::Ishmael::ImageID qw(mimetype_id);
use EBook::Ishmael::Time qw(guess_time);
use EBook::Ishmael::Unzip qw(unzip safe_tmp_unzip);

my $MAGIC = pack 'C4', ( 0x50, 0x4b, 0x03, 0x04 );
my $CONTAINER = File::Spec->catfile(qw/META-INF container.xml/);

my $DCNS = "http://purl.org/dc/elements/1.1/";

# This module only supports EPUBs with a single rootfile. The standard states
# there can be multiple rootfiles, but I have yet to encounter one that does.

# TODO: Make heuristic more precise.
# If file uses zip magic bytes, assume it to be an EPUB.
sub heuristic {

    my $class = shift;
    my $file  = shift;
    my $fh    = shift;

    return 0 if $file =~ /\.zip$/;

    read $fh, my $mag, 4;

    return $mag eq $MAGIC;
}

# Set _rootfile based on container.xml's rootfile@full-path attribute.
sub _get_rootfile {

    my $self = shift;

    my $dom = XML::LibXML->load_xml(
        location => $self->{_container},
        no_network => !$self->{Network},
    );
    my $ns = $dom->documentElement->namespaceURI;

    my $xpc = XML::LibXML::XPathContext->new($dom);
    $xpc->registerNs('container', $ns);

    my ($rf) = $xpc->findnodes(
        '/container:container'   .
        '/container:rootfiles'   .
        '/container:rootfile[1]' .
        '/@full-path'
    );

    unless (defined $rf) {
        die "Could not find root file in EPUB $self->{Source}\n";
    }

    $self->{_rootfile} = File::Spec->catfile($self->{_unzip}, $rf->value());

    return $self->{_rootfile};

}

# Reads metadata and _spine from rootfile.
sub _read_rootfile {

    my $self = shift;

    $self->{_contdir} = dirname($self->{_rootfile});

    my $dom = XML::LibXML-> load_xml(
        location => $self->{_rootfile},
        no_network => !$self->{Network},
    );
    my $ns = $dom->documentElement->namespaceURI;

    my $xpc = XML::LibXML::XPathContext->new($dom);
    $xpc->registerNs('package', $ns);
    $xpc->registerNs('dc', $DCNS);

    my ($vernode) = $xpc->findnodes(
        '/package:package/@version'
    );
    if (defined $vernode) {
        $self->{_version} = $vernode->getValue;
    }

    my ($meta) = $xpc->findnodes(
        '/package:package/package:metadata'
    );

    my ($manif) = $xpc->findnodes(
        '/package:package/package:manifest'
    );

    my ($spine) = $xpc->findnodes(
        '/package:package/package:spine'
    );

    unless (defined $meta) {
        die "EPUB $self->{Source} is missing metadata in rootfile\n";
    }

    unless (defined $manif) {
        die "EPUB $self->{Source} is missing manifest in rootfile\n";
    }

    unless (defined $spine) {
        die "EPUB $self->{Source} is missing spine in rootfile\n";
    }

    for my $dc ($xpc->findnodes('./dc:*', $meta)) {

        my $name = $dc->nodeName =~ s/^dc://r;
        my $text = $dc->textContent();

        $text =~ s/\s+/ /g;

        if ($name eq 'contributor') {
            $self->{Metadata}->add_contributor($text);
        } elsif ($name eq 'creator') {
            $self->{Metadata}->add_author($text);
        } elsif ($name eq 'date') {
            my $t = eval { guess_time($text) };
            if (defined $t) {
                $self->{Metadata}->set_created($t);
            }
        } elsif ($name eq 'description') {
            $self->{Metadata}->set_description($text);
        } elsif ($name eq 'identifier') {
            $self->{Metadata}->set_id($text);
        } elsif ($name eq 'language') {
            $self->{Metadata}->set_language($text);
        } elsif ($name eq 'publisher') {
            $self->{Metadata}->add_contributor($text);
        } elsif ($name eq 'subject') {
            $self->{Metadata}->add_genre($text);
        } elsif ($name eq 'title') {
            $self->{Metadata}->set_title($text);
        }

    }

    for my $itemref ($xpc->findnodes('./package:itemref', $spine)) {

        my $id = $itemref->getAttribute('idref') or next;

        my ($item) = $xpc->findnodes(
            "./package:item[\@id=\"$id\"]", $manif
        ) or next;

        unless (($item->getAttribute('media-type') // '') eq 'application/xhtml+xml') {
            next;
        }

        my $href = $item->getAttribute('href') or next;

        $href = File::Spec->catfile($self->{_contdir}, $href);

        next unless -f $href;

        push @{ $self->{_spine} }, $href;

    }

    # Get list of images
    for my $item ($xpc->findnodes('./package:item', $manif)) {
        my $mime = $item->getAttribute('media-type');
        next if not defined $mime;

        my $format = mimetype_id($mime);
        next if not defined $format;

        my $href = $item->getAttribute('href') or next;
        $href = File::Spec->catfile($self->{_contdir}, $href);
        next if not -f $href;

        push @{ $self->{_images} }, [ $href, $format ];

    }

    my ($covmeta) = $xpc->findnodes('./package:meta[@name="cover"]', $meta);
    # Put if code in own block so that we can last out of it.
    if (defined $covmeta) {{
        my $covcont = $covmeta->getAttribute('content') or last;
        my ($covitem) = $xpc->findnodes("./package:item[\@id=\"$covcont\"]", $manif)
            or last;
        my $covhref = $covitem->getAttribute('href') or last;
        my $covmime = $covitem->getAttribute('media-type') or last;
        my $format = mimetype_id($covmime) or last;
        my $covpath = File::Spec->catfile($self->{_contdir}, $covhref);
        last unless -f $covpath;
        $self->{_cover} = [ $covpath, $format ];
    }}

    return 1;

}

sub new {

    my $class = shift;
    my $file  = shift;
    my $enc   = shift;
    my $net   = shift // 1;

    my $self = {
        Source     => undef,
        Metadata   => EBook::Ishmael::EBook::Metadata->new,
        Network    => $net,
        _unzip     => undef,
        _container => undef,
        _rootfile  => undef,
        # Directory where _rootfile is, as that is where all of the "content"
        # files are.
        _contdir   => undef,
        # List of content files in order specified by spine.
        _spine     => [],
        _cover     => undef,
        _images    => [],
        _version   => undef,
    };

    bless $self, $class;

    $self->read($file);

    if (not defined $self->{Metadata}->title) {
        $self->{Metadata}->set_title((fileparse($file, qr/\.[^.]*/))[0]);
    }

    if (defined $self->{_version}) {
        $self->{Metadata}->set_format('EPUB ' . $self->{_version});
    } else {
        $self->{Metadata}->set_format('EPUB');
    }

    return $self;

}

sub read {

    my $self = shift;
    my $src  = shift;

    my $tmpdir = safe_tmp_unzip;

    unzip($src, $tmpdir);

    $self->{Source} = File::Spec->rel2abs($src);
    $self->{_unzip} = $tmpdir;

    $self->{_container} = File::Spec->catfile($self->{_unzip}, $CONTAINER);

    unless (-f $self->{_container}) {
        die "$src is an invalid EPUB file: does not have a META-INF/container.xml\n";
    }

    $self->_get_rootfile();
    $self->_read_rootfile();

    return 1;

}

sub html {

    my $self = shift;
    my $out  = shift;

    my $html = join '', map {

        my $dom = XML::LibXML->load_xml(
            location => $_,
            no_network => !$self->{Network},
        );
        my $ns = $dom->documentElement->namespaceURI;

        my $xpc = XML::LibXML::XPathContext->new($dom);
        $xpc->registerNs('html', $ns);

        my ($body) = $xpc->findnodes('/html:html/html:body')
            or next;

        map { $_->toString } $body->childNodes;

    } @{ $self->{_spine} };

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

    my $raw = join "\n\n", map {

        my $dom = XML::LibXML->load_xml(
            location => $_,
            no_network => !$self->{Network},
        );
        my $ns = $dom->documentElement->namespaceURI;

        my $xpc = XML::LibXML::XPathContext->new($dom);
        $xpc->registerNs('html', $ns);

        my ($body) = $xpc->findnodes('/html:html/html:body')
            or next;

        $body->textContent;

    } @{ $self->{_spine} };

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

    return (undef, undef) if not $self->has_cover;

    open my $fh, '<', $self->{_cover}[0]
        or die "Failed to open $self->{_cover}[0] for reading: $!\n";
    binmode $fh;
    my $img = do { local $/; readline $fh };
    close $fh;

    return ($img, $self->{_cover}[1]);

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

    remove_tree($self->{_unzip}, { safe => 1 }) if -d $self->{_unzip};

}

1;
