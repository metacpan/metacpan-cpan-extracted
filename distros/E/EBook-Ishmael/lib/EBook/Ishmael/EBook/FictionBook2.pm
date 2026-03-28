package EBook::Ishmael::EBook::FictionBook2;
use 5.016;
our $VERSION = '2.04';
use strict;
use warnings;

use File::Spec;
use MIME::Base64;

use XML::LibXML;

use EBook::Ishmael::HTML qw(prepare_html);
use EBook::Ishmael::ImageID qw(mimetype_id);
use EBook::Ishmael::EBook::Metadata;
use EBook::Ishmael::Time qw(guess_time);

my $NS = "http://www.gribuser.ru/xml/fictionbook/2.0";

sub heuristic {

    my $class = shift;
    my $file  = shift;
    my $fh    = shift;

    return 1 if $file =~ /\.fb2$/;
    return 0 unless -T $fh;

    read $fh, my ($head), 1024;

    return $head =~ /<\s*FictionBook[^<>]+xmlns\s*=\s*"\Q$NS\E"[^<>]*>/;

}

sub _read_metadata {

    my $self = shift;

    my $ns = $self->{_dom}->documentElement->namespaceURI;

    my $xpc = XML::LibXML::XPathContext->new($self->{_dom});
    $xpc->registerNs('FictionBook', $ns);

    my ($desc) = $xpc->findnodes(
        '/FictionBook:FictionBook' .
        '/FictionBook:description'
    ) or return 1;

    my ($title)   = $xpc->findnodes('./FictionBook:title-info',    $desc);
    my ($doc)     = $xpc->findnodes('./FictionBook:document-info', $desc);
    my ($publish) = $xpc->findnodes('./FictionBook:publish-info',  $desc);

    if (defined $title) {
        for my $n ($title->childNodes) {
            my $name = $n->nodeName;
            if ($name eq 'genre') {
                $self->{Metadata}->add_genre($n->textContent);
            } elsif ($name eq 'author') {
                $self->{Metadata}->add_author(
                    join(' ', grep { /\S/ } map { $_->textContent } $n->childNodes)
                );
            } elsif ($name eq 'book-title') {
                $self->{Metadata}->set_title($n->textContent);
            } elsif ($name eq 'lang' or $name eq 'src-lang') {
                $self->{Metadata}->add_language($n->textContent);
            } elsif ($name eq 'translator') {
                $self->{Metadata}->add_contributor($n->textContent);
            }
        }
    }

    if (defined $doc) {
        for my $n ($doc->childNodes) {
            my $name = $n->nodeName;
            if ($name eq 'author') {
                $self->{Metadata}->add_contributor(
                    join(' ', grep { /\S/ } map { $_->textContent } $n->childNodes)
                );
            } elsif ($name eq 'program-used') {
                $self->{Metadata}->set_software($n->textContent);
            } elsif ($name eq 'date') {
                my $t = eval { guess_time($n->textContent) };
                if (defined $t) {
                    $self->{Metadata}->set_created($t);
                }
            } elsif ($name eq 'id') {
                $self->{Metadata}->set_id($n->textContent);
            } elsif ($name eq 'version') {
                $self->{Metadata}->set_format("FictionBook2 " . $n->textContent);
            } elsif ($name eq 'src-ocr') {
                $self->{Metadata}->add_author($n->textContent);
            }
        }
    }

    if (defined $publish) {
        for my $n ($publish->childNodes) {
            my $name = $n->nodeName;
            if ($name eq 'year' and not defined $self->{Metadata}->created) {
                my $t = eval { guess_time($n->textContent) };
                if (defined $t) {
                    $self->{Metadata}->set_created($t);
                }
            } elsif ($name eq 'publisher') {
                $self->{Metadata}->add_contributor($n->textContent);
            } elsif ($name eq 'book-name') {
                $self->{Metadata}->set_title($n->textContent);
            }
        }
    }

    for my $n ($xpc->findnodes('/FictionBook:FictionBook/FictionBook:binary')) {
        my $mime = $n->getAttribute('content-type');
        next if not defined $mime;
        my $format = mimetype_id($mime);
        next if not defined $format;
        push @{ $self->{_images} }, [ $n, $format ];
    }

    my ($covmeta) = $xpc->findnodes('./FictionBook:coverpage', $title);
    # Put if code inside own block so we can easily last out of it.
    if (defined $covmeta) {{
        my ($img) = $xpc->findnodes('./FictionBook:image', $covmeta)
            or last;
        my $href = $img->getAttribute('l:href') or last;
        $href =~ s/^#//;
        my ($binary) = $xpc->findnodes(
            "/FictionBook:FictionBook/FictionBook:binary[\@id=\"$href\"]"
        ) or last;
        my $mime = $binary->getAttribute('content-type');
        last if not defined $mime;
        my $format = mimetype_id($mime);
        last if not defined $format;
        $self->{_cover} = [ $binary, $format ];
    }}

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
        _dom     => undef,
        _cover   => undef,
        _images  => [],
    };

    bless $self, $class;

    $self->{Source} = File::Spec->rel2abs($file);

    $self->{_dom} = XML::LibXML->load_xml(
        location => $file,
        no_network => !$self->{Network},
    );

    $self->_read_metadata;

    if (not defined $self->{Metadata}->format) {
        $self->{Metadata}->set_format('FictionBook2');
    }

    return $self;

}

sub html {

    my $self = shift;
    my $out  = shift;

    my $ns = $self->{_dom}->documentElement->namespaceURI;

    my $xpc = XML::LibXML::XPathContext->new($self->{_dom});
    $xpc->registerNs('FictionBook', $ns);

    my @bodies = $xpc->findnodes(
        '/FictionBook:FictionBook' .
        '/FictionBook:body'
    ) or die "Invalid FictionBook2 file $self->{Source}\n";
    prepare_html(@bodies);

    my $html = join '',
        map { $_->toString }
        map { $_->childNodes }
        @bodies;

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

    my $ns = $self->{_dom}->documentElement->namespaceURI;

    my $xpc = XML::LibXML::XPathContext->new($self->{_dom});
    $xpc->registerNs('FictionBook', $ns);

    my @bodies = $xpc->findnodes(
        '/FictionBook:FictionBook' .
        '/FictionBook:body'
    ) or die "Invalid FictionBook2 file $self->{Source}\n";
    prepare_html(@bodies);

    my $raw = join '', map { $_->textContent } @bodies;

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
    my $bin = decode_base64($self->{_cover}[0]->textContent);
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

    my $img = decode_base64($self->{_images}[$n][0]->textContent);
    return ($img, $self->{_images}[$n][1]);

}

1;
