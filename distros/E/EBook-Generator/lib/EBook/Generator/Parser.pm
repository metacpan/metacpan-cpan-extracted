package EBook::Generator::Parser;

use 5.008009;
use strict;
use warnings;

use Data::Dumper;
use File::Slurp qw(read_file);
use XML::LibXML;
use XML::LibXML::XPathContext;
use Image::Size;

our $VERSION = '0.01';

sub new
{
	my ($class, @args) = @_;
	my $self = bless {}, $class;
	return $self->init(@args);
}

sub init
{
	my ($self, $browser, $xml_parser, $log) = @_;

	$self->{'tmp-dir'} = '/tmp/';

	$self->{'browser'} = $browser;

	$self->{'xml-parser'} = $xml_parser;

	$self->{'log'} = $log;

	$self->{'class-id-filter-words'} =
		['sidebar','respond','nav','menu','social','comment','bookmark',
		 'advert','next','prev','like','footer',' ad ','respost','respond'];
	
	$self->{'ignored-tags'} =
		['script','form','input','textarea','fieldset','select','head','meta','link'];

	$self->{'command-convert'} = getCommandPath('convert');
	$self->{'command-convert'} = '/usr/local/bin/convert' if
		$self->{'command-convert'} eq 'convert';

	return $self;
}

sub getCommandPath
{
	my ($command) = @_;
	my $path = `which $command`;
	$path =~ s/[\s\t\n\r]*$//g;
	return (length $path ? $path : $command);
}

sub parseContent
{
	my ($self, $content, $url, $options) = @_;

	$self->{'options'} = $options;

	# cleanup html
	my $html = $self->cleanup_html($content);

	# parse html file into DOM structure
	my $tree = $self->{'xml-parser'}->parse_html_string($html);
	my $dom = $tree->getDocumentElement();

	# extract meta information
	$self->{'meta'} = {
		'url'			 => $url,
		'title'    => $self->find_title($dom),
		'author'   => $self->find_author($dom),
		'date'     => $self->find_date($dom),
		'abstract' => $self->find_abstract($dom),
	};

	# find content container and extract content
	$self->find_content($dom);
	
	$self->{'files'} = [];
	$self->{'file-basename'} = $self->get_filebasename();

	$self->{'data'} = $self->dom_to_structure($dom);
	
	return ($self->{'meta'}, $self->{'data'});
}

sub cleanup
{
	my ($self) = @_;
	map {	unlink($_) } @{$self->{'files'}};
	$self->{'files'} = [];
}

sub dom_to_structure
{
	my ($self, $dom) = @_;
	return ['document', {}, $self->node_to_structure($dom)];
}

sub logNode
{
	my ($self, $node) = @_;
	my $s = $node->toString();
	$s =~ s/</[/g;
	$s =~ s/>/]/g;
	push @{$self->{'log'}}, $s;
}

#	elem = "..." | [type, {options...}, subelem1, subelem2, ...]
#	types: list, headline, paragraph, text, link, preformatted, picture,
#				 table, footnote?, ...?
#
sub node_to_structure
{
	my ($self, $node) = @_;
	my %handlers = (	
		'p' => sub {
			my ($self, $node) = @_;
			return ['paragraph', {}, $self->children_to_structure($node)];
		},
		'blockquote' => sub {
			my ($self, $node) = @_;
			my $text = $self->node_to_text($node);
			   $text =~ s/[\n\r]/ /g;
			return ['paragraph', {}, ['quote', {}, $text]];
		},
		'quote' => sub {
			my ($self, $node) = @_;
			return ['quote', {}, $self->children_to_structure($node)];
		},
		'h1' => sub {
			my ($self, $node) = @_;
			$self->{'has-section'}++;
			my $text = $self->node_to_text($node); #_children_to_latex($node)
			return ['headline', {'level' => 1}, $text];
		},
		'h2' => sub { 
			my ($self, $node) = @_;
			$self->{'has-section'}++;
			my $text = $self->node_to_text($node); #_children_to_latex($node)
			return ['headline', {'level' => 2}, $text];
		},
		'h3' => sub { 
			my ($self, $node) = @_;
			$self->{'has-section'}++;
			my $text = $self->node_to_text($node); #_children_to_latex($node)
			return ['headline', {'level' => 3}, $text];
		},
		'h4' => sub { 
			my ($self, $node) = @_;
			$self->{'has-section'}++;
			my $text = $self->node_to_text($node); #_children_to_latex($node)
			return ['headline', {'level' => 4}, $text];
		},
		'h5' => sub { 
			my ($self, $node) = @_;
			$self->{'has-section'}++;
			my $text = $self->node_to_text($node); #_children_to_latex($node)
			return ['headline', {'level' => 5}, $text];
		},
		'b|strong' => sub { 
			my ($self, $node) = @_;
			return ['text', {'weight' => 'bold'}, $self->children_to_structure($node)];
		},
		'i|emph' => sub { 
			my ($self, $node) = @_;
			return ['text', {'style' => 'italic'}, $self->children_to_structure($node)];
		},
		'ul' => sub { 
			my ($self, $node) = @_;
			return ['list', {'type' => 'unordered'}, $self->children_to_structure($node)];
		},
		'ol' => sub { 
			my ($self, $node) = @_;
			return ['list', {'type' => 'ordered'}, $self->children_to_structure($node)];
		},
		'li' => sub { 
			my ($self, $node) = @_;
			#push @{$self->{'log'}}, "---";
			#$self->logNode($node);
			my $res = ['text', {}, $self->children_to_structure($node)];
			#push @{$self->{'log'}}, Dumper($res);
			return $res;
		},
		'a' => sub {
			my ($self, $node) = @_;
			my $href = $node->getAttribute('href');
			if ($self->is_external_link($href)) {
				return ['link', {'target' => $href}, $self->children_to_structure($node)];
			} else {
				return ($self->children_to_structure($node));
			}
		},
		'code' => sub {
			my ($self, $node) = @_;
			return ['text', {'preformatted' => 1}, $self->children_to_structure($node)];
		},
		'pre' => sub {
			my ($self, $node) = @_;
			return ['preformatted', {}, $self->children_to_structure($node)];
		},
		'img' => sub {
			my ($self, $node) = @_;
			my ($filename, $url) = $self->download_file($self->{'meta'}->{'url'}, $node);
			return () unless defined $filename;
			my $filetype = $filename;
			   $filetype =~ s/^.*\.([^\.]*)$/$1/;
			return ['media', {'type' => $filetype, 'filename' => $filename, 'url' => $url}];
		},
	);

	my @data = ();
	my $type = $node->nodeType;
	if ($type == XML_ELEMENT_NODE) {
		my $name  = lc $node->tagName;
		my $class = ($node->hasAttribute('class') ? $node->getAttribute('class') : '');
		my $id    = ($node->hasAttribute('id')    ? $node->getAttribute('id')    : '');
		
		#print "[$name]\n";
		
		my $ignored_tags = join '|', map { quotemeta } @{$self->{'ignored-tags'}};
		if ($name !~ /($ignored_tags)/) {
			my $classid = $class.$id;
			my $filter_words = join '|', map { quotemeta } @{$self->{'class-id-filter-words'}};
			if ($classid =~ /($filter_words)/im) {
				# bad
			} else {
				# let the specific function handle the tag
				my $found = 0;
				foreach my $pattern (keys %handlers) {
					if ($name =~ /^($pattern)$/) {
						push @data, $handlers{$pattern}->($self, $node);
						$found = 1;
						last;
					}
				}
				push @data, $self->children_to_structure($node)
					unless $found;
			}
		}
	}
	elsif ($type == XML_TEXT_NODE) {
		my $value = $node->nodeValue();
		#push @{$self->{'log'}}, $node->nodeValue();
		#$self->logNode($node);
		$value =~ s/^[\s\t\n\r]*//g;
		$value =~ s/[\s\t\n\r]*$//g;
		push @data, $value
			if length $value;
	}
	#else {
	#	push @{$self->{'log'}}, $type;
	#}
	return (@data);
}

sub children_to_structure
{
	my ($self, $node) = @_;
	my @data;
	map { push @data, $self->node_to_structure($_); }
		$node->childNodes()->get_nodelist();
	return @data;
}

sub is_external_link
{
	my ($self, $href) = @_;
	return 0 unless defined $href;
	return 0 if $href =~ /javascript/;
	return 0 if $href !~ /^((ht|f)tp|mailto):\/\//;
	my $baseurl = $self->{'meta'}->{'url'};
	   $baseurl =~ s/^(((ht|f)tp|mailto):\/\/[a-zA-Z0-9\.]+).*$/$1/;
	   $baseurl = quotemeta $baseurl;
	#print "[$baseurl]\n[$href]\n\n";
	return 0 if $href =~ /^$baseurl/;
	return 1;
}

sub get_filebasename
{
	return time();
}

sub download_file
{
	my ($self, $url, $node) = @_;
	
	return (undef, undef)
		if $node->hasAttribute('width') && 
		   $node->getAttribute('width') !~ /\%$/ &&
			 $node->getAttribute('width') < $self->{'options'}->{'min-img-width'};
	
	return (undef, undef)
		if $node->hasAttribute('height') && 
		   $node->getAttribute('height') !~ /\%$/ &&
			 $node->getAttribute('height') < $self->{'options'}->{'min-img-height'};
	
	# determine complete URL
	if ($node->hasAttribute('src') && 
	    ($node->getAttribute('src') =~ /^\// || 
	     $node->getAttribute('src') =~ /^(ht|f)tp\:\/\//)) {
		# absolute URL
		$url = $node->getAttribute('src');
	}
	else {
		# relative URL
		$url =~ s/[^\/]*$//;
		$url = $url.'/'.$node->getAttribute('src');
	}
	
	# determine filetype
	my ($filetype) = $url =~ /^.*\.([a-z0-9A-Z]+)$/;
	$filetype = lc $filetype;
	
	return (undef, undef)
		unless $filetype =~ /^(jpe?g|png|gif)$/;
		
	# download file
	my $data = '';
	if ($url =~ /^file:\/\//) {
		# local file -> fetch with File::Slurp
		my ($filename) = $url =~ /^file:\/\/(.*)$/;
		$data = read_file($filename);
	}
	else {
		my $request = HTTP::Request->new(GET => $url);
		my $response = $self->{'browser'}->request($request);
		$data = $response->content();
	}
	
	# write file to img file
	my $filename = $self->{'tmp-dir'}.$self->{'file-basename'}.'-'.scalar(@{$self->{'files'}}).'.'.$filetype;
	my $fh = IO::File->new('> '.$filename);
	print $fh $data;

	push @{$self->{'files'}}, $filename;

	if (lc $filetype eq 'gif') {
		# convert to png
		my $filename_png = $filename;
		   $filename_png =~ s/\.gif$/\.png/i;
		system($self->{'command-convert'}, $filename, $filename_png);
		
		push @{$self->{'files'}}, $filename;
		$filename = $filename_png;
		$url =~ s/\.gif$/\.png/i;
		$filetype = 'png';
	}
		
	my ($width, $height) = imgsize($filename);
	return (undef, undef) if !defined $width || !defined $height;	
	return (undef, undef) if $width <= 0 || $height <= 0;
	return (undef, undef) if defined $width && $width < $self->{'options'}->{'min-img-width'};
	return (undef, undef) if defined $height && $height < $self->{'options'}->{'min-img-height'};
	#print "w=$width h=$height w/h=".($width/$height)." h/w=".($height/$width)."\n";
	if (defined $width && defined $height && $width > $height) {
		return (undef, undef)
			if $width/$height > $self->{'options'}->{'image-max-length-aspect-ratio'};
	} else {
		return (undef, undef)
			if $height/$width > $self->{'options'}->{'image-max-length-aspect-ratio'};
	}
	
	# convert image to grayscale
	unless ($self->{'options'}->{'use-color-images'}) {
		my $filename2 = $self->{'tmp-dir'}.$self->{'file-basename'}.'-'.scalar(@{$self->{'files'}}).'_gray.'.$filetype;
		system($self->{'command-convert'}, '-type', 'Grayscale', $filename, $filename2);
		push @{$self->{'files'}}, $filename2;
		$filename = $filename2;
	}
	
	return ($filename, $url);
}

sub cleanup_html
{
	my ($self, $h) = @_;
	#$h =~ s/\&\#13\;/ /g;
	$h =~ s/\&nbsp\;/ /g;
	return $h;
}

sub find_abstract
{
	my ($self, $dom) = @_;
	my $abstract = '';
	# ...
	#print "($abstract)\n";
	return $abstract;
}

sub find_author
{
	my ($self, $dom) = @_;
	my $author = '';
	my $text = $self->node_to_text($dom);
	my $regex = 'by\s*([ a-zA-Z0-9\-]+)';
	if ($text =~ /$regex/) {
		($author) = $text =~ /$regex/;
	}
	$author = substr($author,0,100) if length($author) > 100;
	return $author;
}

sub find_date
{
	my ($self, $dom) = @_;
	my $date = ' \today ';
	my $text = $self->node_to_text($dom);
	my $regex = '(\d+\.\d+\.\d+|\d+\/\d+\/\d+)';
	if ($text =~ /$regex/) {
		($date) = $text =~ /$regex/;
	}
	$date = substr($date,0,20) if length($date) > 20;
	#print "($date)\n";
	return $date;
}

sub find_title
{
	my ($self, $dom) = @_;
	my $title = 'Untitled';
	if (scalar @{$dom->getElementsByTagName('title')}) {
		$title = ($dom->getElementsByTagName('title'))->[0]->textContent();
		$title =~ s/[^A-Za-z0-9\.\-\s\t].*$//g;
		$title =~ s/^(.*) - .*$/$1/g;
		$title =~ s/^[\s\t\n\r]*//g;
		$title =~ s/[\s\t\n\r]*$//g;
	}
	#print "($title)\n";
	return $title;
}

sub find_content
{
	my ($self, $node) = @_;
	$self->{'content'} = undef;
	
	# [div] > h1:first-child
	foreach my $div (get_child_nodes_by_tagname($node,'div',0)) {
		#print "[div] >\n";
		if (scalar get_child_nodes_by_tagname($div,'h1',1)) {
			#print "h1:first-child\n";
			$self->{'content'} = $div;
			last;
		}
	}
	return 1 if defined $self->{'content'};
	#exit;
	
	# [article] > header:first-child > hgroup:first-child > h1:first-child
	#print "[article] >\n";
	OUTER:
	foreach my $article (get_child_nodes_by_tagname($node,'article',0)) {
		#print "article...\n";
		foreach my $header (get_child_nodes_by_tagname($article,'header',1)) {
			#print "header...\n";
			foreach my $hgroup (get_child_nodes_by_tagname($header,'hgroup',1)) {
				#print "hgroup...\n";
				if (scalar get_child_nodes_by_tagname($hgroup,'h1',1)) {
					#print "h1!\n";
					$self->{'content'} = $article;
					last OUTER;
				}
			}
		}
	}
	return 1 if defined $self->{'content'};

	# [div] > div > h1|h2
	my $xpc = XML::LibXML::XPathContext->new($node);
	OUTER:
	foreach my $div ($xpc->findnodes('//div', $node)) {
		foreach my $subdiv ($xpc->findnodes('child::div', $div)) {
			if (scalar $xpc->findnodes('child::h1', $subdiv) ||
			    scalar $xpc->findnodes('child::h2', $subdiv)) {
				$self->{'content'} = $div;
				last OUTER;
			}
		}
	}
	return 1 if defined $self->{'content'};
	
	# [body]
	foreach my $body ($xpc->findnodes('//body', $node)) {
		$self->{'content'} = $body;
		last;
	}
	return 1 if defined $self->{'content'};
	
	$self->{'content'} = $node;
}

sub get_child_nodes_by_tagname
{
	my ($node, $tagname, $must_be_first, $level) = @_;
	return () unless defined $node;
	$must_be_first = 0 unless defined $must_be_first;
	$level = '  ' unless defined $level;
		
	my @children;
	if (lc($node->nodeName) eq lc($tagname)) {
		push @children, $node;
	}
	foreach my $child (@{$node->childNodes()}) {
		if ($child->nodeType == XML_ELEMENT_NODE) {
			if (lc($child->nodeName) eq lc($tagname)) {
				push @children, $child;
			}
			if ($must_be_first != 0) {
				last;
			}
		}
		push @children,
			map { get_child_nodes_by_tagname($_,$tagname,$must_be_first,$level.'    ') }
			@{$child->childNodes()};
	}
	return @children;
}

sub node_to_text
{
	my ($self, $node) = @_;
	my $s = $node->toString();
	$s =~ s/<\/?[a-zA-Z0-9\-]+[^>]*>//img;
	$s =~ s/[\s\t\n\r]+/ /g;
	return $s;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

EBook::Generator - Perl extension for creating EBooks from Websites.

=head1 SYNOPSIS

  use EBook::Generator;
  my $g = EBook::Generator->new();
  my $ebook = $g->readSource("http://www.google.com", fontSize => 12, grayImages => 1);
  $ebook->writeEBook("./Google.pdf");

=head1 DESCRIPTION

EBook::Generator can be used to generate a beautifully looking
e-book out of a website, aka HTML source. It uses LaTeX to
create the actual e-book.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Tom Kirchner, E<lt>kitomer@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tom Kirchner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
