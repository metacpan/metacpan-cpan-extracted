package EBook::Ishmael::EBook::Epub;
use 5.016;
our $VERSION = '0.03';
use strict;
use warnings;

use File::Basename;
use File::Path;
use File::Spec;
use File::Temp qw(tempdir);

use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use XML::LibXML;

use EBook::Ishmael::EBook::Metadata;

my $MAGIC = pack 'C4', ( 0x50, 0x4b, 0x03, 0x04 );
my $CONTAINER = File::Spec->catfile(qw/META-INF container.xml/);

# This module only supports EPUBs with a single rootfile. The standard states
# there can be multiple rootfiles, but I have yet to encounter one that does.

# If file uses zip magic bytes, assume it to be an EPUB.
sub heuristic {

	my $class = shift;
	my $file  = shift;

	open my $fh, '<', $file
		or die "Failed to open $file for reading: $!\n";
	binmode $fh;
	read $fh, my $mag, 4;
	close $fh;

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

	for my $dc ($meta->findnodes('./dc:*')) {

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

		my $href = $item->getAttribute('href') or next;

		$href = File::Spec->catfile($self->{_contdir}, $href);

		next unless -f $href;

		push @{ $self->{_spine} }, $href;

	}

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
	};

	bless $self, $class;

	$self->read($file);

	$self->{Metadata}->format([ 'EPUB' ]);

	return $self;

}

sub read {

	my $self = shift;
	my $src  = shift;

	my $zip = Archive::Zip->new();

	unless ($zip->read($src) == AZ_OK) {
		die "Could not read $src as an EPUB zip archive\n";
	}

	foreach my $m ($zip->members()) {
		$m->unixFileAttributes($m->isDirectory() ? 0755 : 0644);
	}

	my $tmpdir = tempdir("shiori.XXXXXX", TMPDIR => 1, CLEANUP => 1);

	unless ($zip->extractTree('', $tmpdir) == AZ_OK) {
		die "Could not unzip $src to $tmpdir\n";
	}

	$self->{Source} = File::Spec->rel2abs($src);
	$self->{_unzip} = $tmpdir;

	$self->{_container} = File::Spec->catfile($self->{_unzip}, $CONTAINER);

	unless (-f $self->{_container}) {
		die "$src is not an EPUB file: does not have a META-INF/container.xml\n";
	}

	$self->_get_rootfile();
	$self->_read_rootfile();

	return 1;

}

sub html {

	my $self = shift;
	my $out  = shift;

	my $html = '';

	open my $fh, '>', $out // \$html
		or die sprintf "Failed to open %s for writing: $!\n", $out // 'in-memory scalar';
	binmode $fh, ':utf8';

	# Go through each file in _spine and extract the body of the XHTML tree.
	for my $f (@{ $self->{_spine} }) {

		my $dom = XML::LibXML->load_xml(location => $f);
		my $ns = $dom->documentElement->namespaceURI();

		my $xpc = XML::LibXML::XPathContext->new($dom);
		$xpc->registerNs('html', $ns);

		my ($body) = $xpc->findnodes('/html:html/html:body')
			or next;

		print { $fh } map { $_->toString } $body->childNodes();

	}

	close $fh;

	return $out // $html;

}

sub metadata {

	my $self = shift;

	return $self->{Metadata}->hash;

}

DESTROY {

	my $self = shift;

	rmtree($self->{_unzip}, { safe => 1 }) if defined $self->{_unzip};

}

1;
