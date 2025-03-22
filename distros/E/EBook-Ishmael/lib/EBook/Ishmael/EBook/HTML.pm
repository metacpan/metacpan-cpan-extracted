package EBook::Ishmael::EBook::HTML;
use 5.016;
our $VERSION = '1.03';
use strict;
use warnings;

use File::Basename;
use File::Spec;

use XML::LibXML;

use EBook::Ishmael::EBook::Metadata;

my $XHTML_NS = 'http://www.w3.org/1999/xhtml';

my %META_ITEMS = (
	'dc.title'         => 'title',
	'dc.language'      => 'language',
	'dcterms.modified' => 'modified',
	'dc.creator'       => 'author',
	'dc.subject'       => 'genre',
	'dcterms.created'  => 'created',
	'generator'        => 'software',
	'description'      => 'description',
);

sub heuristic {

	my $class = shift;
	my $file  = shift;
	my $fh    = shift;

	return 1 if $file =~ /\.html?$/;
	return 0 unless -T $fh;

	read $fh, my ($head), 1024;

	return 0 if $head =~ /<[^<>]+xmlns\s*=\s*"\Q$XHTML_NS\E"[^<>]*>/;

	return $head =~ /<\s*html[^<>]*>/;

}

sub _read_metadata {

	my $self = shift;

	my ($ns) = $self->{_dom}->findnodes('/html/@xmlns');

	if (defined $ns and $ns->value eq $XHTML_NS) {
		$self->{Metadata}->format([ 'XHTML' ]);
	} else {
		$self->{Metadata}->format([ 'HTML' ]);
	}
	my ($head) = $self->{_dom}->findnodes('/html/head');

	unless (defined $head) {
		return 1;
	}

	my ($title) = $head->findnodes('./title');

	if (defined $title) {
		my $str = $title->textContent =~ s/\s+/ /gr;
		$self->{Metadata}->title([ $str ]);
	}

	for my $n ($head->findnodes('./meta')) {

		my $name = $n->getAttribute('name') // '';
		next unless exists $META_ITEMS{ $name };
		my $cont = $n->getAttribute('content') or next;

		my $method = $META_ITEMS{ $name };

		push @{ $self->{Metadata}->$method }, $cont;

	}

	my ($lang) = $self->{_dom}->findnodes('/html/@lang');

	if (defined $lang and !@{ $self->{Metadata}->language }) {
		$self->{Metadata}->language([ $lang->value ]);
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

	$self->{_dom} = XML::LibXML->load_html(
		location => $file,
		recover => 2,
	);

	$self->_read_metadata;

	unless (@{ $self->{Metadata}->title }) {
		$self->{Metadata}->title([ (fileparse($file, qr/\.[^.]*/))[0] ]);
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

	# Extract body from HTML tree and serialize that, or just serialize the
	# entire tree if there is no body.
	my ($body) = $self->{_dom}->documentElement->findnodes('/html/body');
	$body //= $self->{_dom}->documentElement;

	print { $fh } $body->toString();

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

	my ($body) = $self->{_dom}->findnodes('/html/body');
	$body //= $self->{_dom}->documentElement;

	print { $fh } $body->textContent;

	close $fh;

	return $out // $raw;

}

sub metadata {

	my $self = shift;

	return $self->{Metadata}->hash;

}

sub has_cover { 0 }

sub cover { undef }

sub image_num { 0 }

sub image { undef }

1;
