package EBook::Ishmael::EBook::HTML;
use 5.016;
our $VERSION = '0.02';
use strict;
use warnings;

use File::Spec;

use XML::LibXML;

# Nothing fancy, just check if the file has an html suffix.
sub heuristic {

	my $class = shift;
	my $file  = shift;

	return $file =~ /\.x?html?$/;

}

# Check to see if the html page has any of the following:
# * title
# * lang
sub _read_metadata {

	my $self = shift;

	my ($lang) = $self->{_dom}->findnodes('/html/@lang');

	if (defined $lang) {
		push @{ $self->{Metadata}->{language} }, $lang->value;
	}

	my ($head) = $self->{_dom}->findnodes('/html/head');

	unless (defined $head) {
		return 1;
	}

	my ($title) = $head->findnodes('./title');

	if (defined $title) {
		my $str = $title->textContent =~ s/\s+/ /gr;
		push @{ $self->{Metadata}->{title} }, $str;
	}

	return 1;

}

sub new {

	my $class = shift;
	my $file  = shift;

	my $self = {
		Source   => undef,
		Metadata => {},
		_dom     => undef,
	};

	bless $self, $class;

	$self->{Source} = File::Spec->rel2abs($file);

	$self->{_dom} = XML::LibXML->load_html(location => $file);

	$self->_read_metadata;

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

sub metadata {

	my $self = shift;

	return $self->{Metadata};

}

1;
