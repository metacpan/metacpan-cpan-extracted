package EBook::Ishmael::EBook::CHM;
use 5.016;
our $VERSION = '1.04';
use strict;
use warnings;

use File::Basename;
use File::Temp qw(tempdir);
use File::Spec;

use File::Which;
use XML::LibXML;

use EBook::Ishmael::Dir;
use EBook::Ishmael::EBook::Metadata;
use EBook::Ishmael::ImageID;

# TODO: Make more of an effort to find metadata
# TODO: Add support for Windows via hh.exe
# I have tried to add hh support before, and it didn't work out well because
# hh doesn't know how to handle quoted arguments for some reason.

my $CHMLIB = which 'extract_chmLib';

our $CAN_TEST = defined $CHMLIB;

my $MAGIC = 'ITSF';

my @IMG = qw(png jpg jpeg tif tiff gif bmp webp);
my $IMGRX = sprintf "(%s)", join '|', @IMG;

sub heuristic {

	my $class = shift;
	my $file  = shift;
	my $fh    = shift;

	read $fh, my $mag, length $MAGIC;

	return $mag eq $MAGIC;

}

sub _extract {

	my $self = shift;

	unless (defined $CHMLIB) {
		die "Cannot extract CHM $self->{Source}; chmlib not installed\n";
	}

	qx/$CHMLIB "$self->{Source}" "$self->{_extract}"/;

	unless ($? >> 8 == 0) {
		die "Failed to run '$CHMLIB' on $self->{Source}\n";
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
		recover => 2
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
		} elsif ($f =~ /\.$IMGRX$/) {
			push @{ $self->{_images} }, $f;
		}
	}

	# Get image and data pairs.
	my @imgdat = map {

		open my $fh, '<', $_
			or die "Failed to open $_ for reading: $!\n";
		binmode $fh;

		[ $_, do { local $/ = undef; readline $fh } ];

	} @{ $self->{_images} };

	my @covers =
		map { $_->[0] }
		# Sort by size, we want the largest image
		sort { -s $a->[0] <=> -s $b->[0] }
		# Cover images probably have at least a 1.3 height-width ratio.
		grep { $_->[1][1] / $_->[1][0] >= 1.3 }
		grep { defined $_->[1] }
		map { [ $_->[0], image_size(\$_->[1]) ] }
		@imgdat;

	$self->{_cover} = $covers[-1] if @covers;

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

	my $self = {
		Source   => undef,
		Metadata => EBook::Ishmael::EBook::Metadata->new,
		_extract => undef,
		_images  => [],
		_content => [],
		_cover   => undef,
	};

	bless $self, $class;

	$self->{Source} = File::Spec->rel2abs($file);

	$self->{_extract} = tempdir(CLEANUP => 1);
	$self->_extract;
	#$self->_urlstr;
	$self->_hhc;
	$self->_images;

	$self->{Metadata}->title([ (fileparse($self->{Source}, qr/\.[^.]*/))[0] ]);
	$self->{Metadata}->modified([ scalar gmtime((stat $self->{Source})[9]) ]);
	$self->{Metadata}->format([ 'CHM' ]);

	return $self;

}

sub html {

	my $self = shift;
	my $out  = shift;

	my $html = join '', map {

		my $dom = XML::LibXML->load_html(
			location => $_,
			recover => 2,
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
	my $img = do { local $/ =  undef; readline $fh };
	close $fh;

	return \$img;

}

1;
