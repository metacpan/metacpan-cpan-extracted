package EBook::Ishmael::EBook::FictionBook2;
use 5.016;
our $VERSION = '0.03';
use strict;
use warnings;

use File::Spec;

use XML::LibXML;

use EBook::Ishmael::EBook::Metadata;

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
);

my %PUBLISH = (
	'year' => sub {

		my $node = shift;

		return created => $node->textContent;

	},
);

# Just check for fb2 suffix, anything more would require us to parse XML, which
# would be too heavy for a quick heuristic.
sub heuristic {

	my $class = shift;
	my $file  = shift;

	return $file =~ /\.fb2$/;

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

	return 1;

}

sub new {

	my $class = shift;
	my $file  = shift;

	my $self = {
		Source   => undef,
		Metadata => EBook::Ishmael::EBook::Metadata->new,
		_dom     => undef,
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

	for my $b (@bodies) {
		print { $fh } map { $_->toString } $b->childNodes;
	}

	close $fh;

	return $out // $html;

}

sub metadata {

	my $self = shift;

	return $self->{Metadata}->hash;

}

1;
