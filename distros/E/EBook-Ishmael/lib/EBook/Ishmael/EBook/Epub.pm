package EBook::Ishmael::EBook::Epub;
use 5.016;
our $VERSION = '1.06';
use strict;
use warnings;

use File::Basename;
use File::Path qw(remove_tree);
use File::Spec;

use XML::LibXML;

use EBook::Ishmael::EBook::Metadata;
use EBook::Ishmael::Unzip qw(unzip safe_tmp_unzip);

my $MAGIC = pack 'C4', ( 0x50, 0x4b, 0x03, 0x04 );
my $CONTAINER = File::Spec->catfile(qw/META-INF container.xml/);

my $DCNS = "http://purl.org/dc/elements/1.1/";

# This module only supports EPUBs with a single rootfile. The standard states
# there can be multiple rootfiles, but I have yet to encounter one that does.

# If file uses zip magic bytes, assume it to be an EPUB.
sub heuristic {

	my $class = shift;
	my $file  = shift;
	my $fh    = shift;

	read $fh, my $mag, 4;

	return $mag eq $MAGIC;
}

# Set _rootfile based on container.xml's rootfile@full-path attribute.
sub _get_rootfile {

	my $self = shift;

	my $dom = XML::LibXML->load_xml(location => $self->{_container});
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

	# Hash of epub metadata items and their corresponding Metadata method
	# accessors.
	my %dcmeta = (
		'contributor' => 'contributor',
		'creator'     => 'author',
		'date',       => 'created',
		'description' => 'description',
		'identifier'  => 'id',
		'language'    => 'language',
		'publisher'   => 'contributor',
		'subject'     => 'genre',
		'title',      => 'title',
	);

	$self->{_contdir} = dirname($self->{_rootfile});

	my $dom = XML::LibXML-> load_xml(location => $self->{_rootfile});
	my $ns = $dom->documentElement->namespaceURI;

	my $xpc = XML::LibXML::XPathContext->new($dom);
	$xpc->registerNs('package', $ns);
	$xpc->registerNs('dc', $DCNS);

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

		next unless exists $dcmeta{ $name };

		$text =~ s/\s+/ /g;

		my $method = $dcmeta{ $name };

		push @{ $self->{Metadata}->$method }, $text;

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

		next unless ($item->getAttribute('media-type') // '') =~ /^image\//;

		my $href = $item->getAttribute('href') or next;
		$href = File::Spec->catfile($self->{_contdir}, $href);

		push @{ $self->{_images} }, $href if -f $href;

	}

	my ($covmeta) = $xpc->findnodes('./package:meta[@name="cover"]', $meta);

	# Put if code in own block so that we can last out of it.
	if (defined $covmeta) {{

		my $covcont = $covmeta->getAttribute('content') or last;

		my ($covitem) = $xpc->findnodes("./package:item[\@id=\"$covcont\"]", $manif)
			or last;

		my $covhref = $covitem->getAttribute('href') or last;

		my $covpath = File::Spec->catfile($self->{_contdir}, $covhref);

		last unless -f $covpath;

		$self->{_cover} = $covpath;

	}}

	return 1;

}

sub new {

	my $class = shift;
	my $file  = shift;

	my $self = {
		Source     => undef,
		Metadata   => EBook::Ishmael::EBook::Metadata->new,
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
	};

	bless $self, $class;

	$self->read($file);

	unless (@{ $self->{Metadata}->title }) {
		$self->{Metadata}->title([ (fileparse($file, qr/\.[^.]*/))[0] ]);
	}

	$self->{Metadata}->format([ 'EPUB' ]);

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

		my $dom = XML::LibXML->load_xml(location => $_);
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

		my $dom = XML::LibXML->load_xml(location => $_);
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

	return $self->{Metadata}->hash;

}

sub has_cover {

	my $self = shift;

	return defined $self->{_cover};

}

sub cover {

	my $self = shift;
	my $out  = shift;

	return undef unless defined $self->{_cover};

	open my $rh, '<', $self->{_cover}
		or die "Failed to open $self->{_cover} for reading: $!\n";
	binmode $rh;
	my $bin = do { local $/ = undef; readline $rh };
	close $rh;

	if (defined $out) {
		open my $wh, '>', $out
			or die "Failed to open $out for writing: $!\n";
		binmode $wh;
		print { $wh } $bin;
		close $wh;
		return $out;
	} else {
		return $bin;
	}

}

sub image_num {

	my $self = shift;

	return scalar @{ $self->{_images} };

}

sub image {

	my $self = shift;
	my $n    = shift;

	if ($n >= $self->image_num) {
		return undef;
	}

	open my $fh, '<', $self->{_images}[$n]
		or die "Failed to open $self->{_images}[$n] for reading: $!\n";
	binmode $fh;
	my $img = do { local $/ = undef; readline $fh };
	close $fh;

	return \$img;

}

DESTROY {

	my $self = shift;

	remove_tree($self->{_unzip}, { safe => 1 }) if -d $self->{_unzip};

}

1;
