package EBook::Ishmael::EBook::FictionBook2;
use 5.016;
our $VERSION = '1.03';
use strict;
use warnings;

use File::Spec;
use MIME::Base64;

use XML::LibXML;

use EBook::Ishmael::EBook::Metadata;

my $NS = "http://www.gribuser.ru/xml/fictionbook/2.0";

# The following 3 hashes each correspond to an entry in a FictionBook's
# description node, which contains all of the metadata of a FictionBook
# document. Each pair represents a recognized entry and a handler for
# retrieving a value from that node.

my %TITLE = (
	'genre' => sub {

		my $node = shift;

		return genre => $node->textContent;

	},
	'author' => sub {

		my $node = shift;

		my $name = join(' ',
			grep { /\S/ } map { $_->textContent } $node->childNodes
		);

		return author => $name;

	},
	'book-title' => sub {

		my $node = shift;

		return title => $node->textContent;

	},
	'lang' => sub {

		my $node = shift;

		return language => $node->textContent;

	},
	'src-lang' => sub {

		my $node = shift;

		return language => $node->textContent;

	},
	'translator' => sub {

		my $node = shift;

		my $name = join(' ',
			grep { /\S/ } map { $_->textContent } $node->childNodes
		);

		return contributor => $name;

	},
);

my %DOCUMENT = (
	'author' => sub {

		my $node = shift;

		my $name = join(' ',
			grep { /\S/ } map { $_->textContent } $node->childNodes
		);

		return contributor => $name;

	},
	'program-used' => sub {

		my $node = shift;

		return software => $node->textContent;

	},
	'date' => sub {

		my $node = shift;

		return created => $node->textContent;

	},
	'id' => sub {

		my $node = shift;

		return id => $node->textContent;

	},
	'version' => sub {

		my $node = shift;

		return format => "FictionBook2 " . $node->textContent;

	},
	'src-ocr' => sub {

		my $node = shift;

		return author => $node->textContent

	},

);

my %PUBLISH = (
	'year' => sub {

		my $node = shift;

		return created => $node->textContent;

	},
	'publisher' => sub {

		my $node = shift;

		my $name = join(' ',
			grep { /\S/ } map { $_->textContent } $node->childNodes
		);

		return contributor => $name;

	},
	'book-name' => sub {

		my $node = shift;

		return title => $node->textContent;

	},
);

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
			next unless exists $TITLE{ $n->nodeName };
			my ($k, $v) = $TITLE{ $n->nodeName }->($n);
			push @{ $self->{Metadata}->$k }, $v;
		}
	}

	if (defined $doc) {
		for my $n ($doc->childNodes) {
			next unless exists $DOCUMENT{ $n->nodeName };
			my ($k, $v) = $DOCUMENT{ $n->nodeName }->($n);
			push @{ $self->{Metadata}->$k }, $v;
		}
	}

	if (defined $publish) {
		for my $n ($publish->childNodes) {
			next unless exists $PUBLISH{ $n->nodeName };
			my ($k, $v) = $PUBLISH{ $n->nodeName }->($n);
			push @{ $self->{Metadata}->$k }, $v;
		}
	}

	@{ $self->{_images} } = grep {
		($_->getAttribute('content-type') // '') =~ /^image\//
	} $xpc->findnodes('/FictionBook:FictionBook/FictionBook:binary');

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

		$self->{_cover} = $binary;

	}}

	return 1;

}

sub new {

	my $class = shift;
	my $file  = shift;

	my $self = {
		Source   => undef,
		Metadata => EBook::Ishmael::EBook::Metadata->new,
		_dom     => undef,
		_cover   => undef,
		_images  => [],
	};

	bless $self, $class;

	$self->{Source} = File::Spec->rel2abs($file);

	$self->{_dom} = XML::LibXML->load_xml(location => $file);

	$self->_read_metadata;

	unless (@{ $self->{Metadata}->format }) {
		$self->{Metadata}->format([ 'FictionBook2' ]);
	}

	return $self;

}

sub html {

	my $self = shift;
	my $out  = shift;

	my $html = '';

	open my $fh, '>', $out // \$html
		or die sprintf "Failed to open %s for writing: $!\n", $out // 'in-memory scalar';
	binmode $fh, ':utf8';

	my $ns = $self->{_dom}->documentElement->namespaceURI;

	my $xpc = XML::LibXML::XPathContext->new($self->{_dom});
	$xpc->registerNs('FictionBook', $ns);

	my @bodies = $xpc->findnodes(
		'/FictionBook:FictionBook' .
		'/FictionBook:body'
	) or die "Invalid FictionBook2 file $self->{Source}\n";

	print { $fh } map { $_->toString } map { $_->childNodes } @bodies;

	close $fh;

	return $out // $html;

}

sub raw {

	my $self = shift;
	my $out  = shift;

	my $raw = '';

	open my $fh, '>', $out // \$raw
		or die sprintf "Failed to open %s for writing: $!\n", $out // 'in-memory scalar';
	binmode $fh, ':utf8';

	my $ns = $self->{_dom}->documentElement->namespaceURI;

	my $xpc = XML::LibXML::XPathContext->new($self->{_dom});
	$xpc->registerNs('FictionBook', $ns);

	my @bodies = $xpc->findnodes(
		'/FictionBook:FictionBook' .
		'/FictionBook:body'
	) or die "Invalid FictionBook2 file $self->{Source}\n";

	print { $fh } map { $_->textContent } @bodies;

	close $fh;

	return $out // $raw;

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

	return undef unless $self->has_cover;

	my $bin;

	open my $fh, '>', $out // \$bin
		or die sprintf "Failed to open %s for writing: $!\n", $out // 'in-memory scalar';
	binmode $fh;

	print { $fh } decode_base64($self->{_cover}->textContent);

	close $fh;

	return $out // $bin;

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

	my $img = decode_base64($self->{_images}[$n]->textContent);

	return \$img;

}

1;
