package EBook::Generator::Exporter::XHTML;

use 5.008009;
use strict;
use warnings;

use MIME::Base64;

our $VERSION = '0.01';

sub new
{
	my ($class, @args) = @_;
	my $self = bless {}, $class;
	return $self->init(@args);
}

sub init
{
	my ($self, $browser) = @_;

	$self->{'final-dir'} = '/tmp/';

	$self->{'browser'} = $browser;
	
	$self->{'log'} = [];

	$self->{'handlers'} = {
		'document' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			my $content = $self->transform_nodes(@subnodes);
			$self->{'meta'}->{'date'} = time() if $self->{'meta'}->{'date'} =~ /\\today/;
			return
				'<html>'."\n".
					'<head>'."\n".
						'<title>'.$self->{'meta'}->{'title'}.'</title>'."\n".
						'<style type="text/css">'."\n".
							'body { padding: 10pt } '."\n".
							'body, p, b, i, a, h1, h2, h3, h4, h5 { font-family: Georgia, serif; } '."\n".
							'h1, h2, h3, h4, h5, ol, ul, li { margin: 5pt 0 }'."\n".
						'</style>'."\n".
					'</head>'."\n".
					'<body>'."\n".
						'<center>'."\n".
							$self->{'meta'}->{'title'}.'<br/>'."\n".
							'by <i>'.$self->{'meta'}->{'author'}.'</i><br/>'."\n".
							$self->{'meta'}->{'date'}.'<br/><br/>'."\n".
							$self->transform_text($self->{'meta'}->{'url'})."\n".
						'</center>'."\n".
						$content."\n".
					'</body>'."\n".
				'</html>'."\n";
		},
		'paragraph' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			return "<p>".$self->transform_nodes(@subnodes)."</p>\n";
		},
		'headline' => sub {
			my ($self, $node) = @_;
			my ($type, $opts, @subnodes) = @{$node};
			return 
				"\n\n".
				'<h'.$opts->{'level'}.'>'.
					$self->transform_nodes(@subnodes).
				"</h".$opts->{'level'}.">\n\n";
		},
		'text' => sub {
			my ($self, $node) = @_;
			my ($type, $opts, @subnodes) = @{$node};
			my $latex = $self->transform_nodes(@subnodes);
			$latex = '<code>'.$latex.'</code>'
				if exists $opts->{'preformatted'} && $opts->{'preformatted'} == 1;
			$latex = '<b>'.$latex.'</b>'
				if exists $opts->{'weight'} && $opts->{'weight'} eq 'bold';
			$latex = '<i>'.$latex.'</i>'
				if exists $opts->{'style'} && $opts->{'style'} eq 'italic';
			return ' '.$latex;
		},
		'link' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			return
				' <a href="'.$self->transform_text($opts->{'target'}).'">'.
					$self->transform_nodes(@subnodes).
				'</a>';
			
		},
		'media' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			if ($opts->{'type'} =~ /^(gif|jpe?g|png)$/i) {
				# picture	
				if ($self->{'options'}->{'embed-images'}) {
					my $fh = IO::File->new('< '.$opts->{'filename'});
					my $data = join '', <$fh>;
					return 
						"<p>".
							#'<img width="100%" alt="Image" src="'.$opts->{'url'}.'"/>'.
							'<img width="100%" alt="Image" src="data:image/'.$opts->{'type'}.
								';base64,'.encode_base64($data).'"/>'.
						"</p>\n";
				} else {
					return 
						"<p>".
							'<img width="100%" alt="Image" src="'.$opts->{'url'}.'"/>'.
						"</p>\n";				
				}
			}
			return '';
		},
		'list' => sub {
			my ($self, $node) = @_;
			my ($type, $opts, @subnodes) = @{$node};
			my $name = ($opts->{'type'} eq 'ordered' ? 'ol' : 'ul');
			return 
				'<'.$name.'>'."\n".
				join('', map {'<li>'.$self->transform_nodes($_)."</li>\n"} @subnodes).
				'</'.$name.'>'."\n";
		},
		'preformatted' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			return 
				' <pre>'.
				$self->transform_nodes(@subnodes).
				'</pre> '."\n";
		},
		'quote' => sub {
			my ($self, $node) = @_;			
			my ($type, $opts, @subnodes) = @{$node};
			return ' <quote>'.$self->transform_nodes(@subnodes).'</quote> '."\n";
		},
	};
	
	return $self;
}

sub writeEBook
{
	my ($self, $ebook, $options) = @_;

	$self->{'url'} = $ebook->{'url'};
	$self->{'options'} = $options;
	$self->{'meta'} = $ebook->{'meta'};

	# convert to xhtml
	my $converted = $self->transform_nodes($ebook->{'data'});
	
	# wrap xhtml inside an EPUB container
	my $filename;
	if ($self->{'options'}->{'epub'}) {
		use EBook::EPUB;
	
		my $epub = EBook::EPUB->new();

		# Set metadata: title/author/language/id
		$epub->add_title($self->{'meta'}->{'title'});
		$epub->add_author($self->{'meta'}->{'author'});
		$epub->add_date($self->{'meta'}->{'date'});
		#$epub->add_language('en');
		#$epub->add_identifier('1440465908', 'ISBN');

		# Add package content: stylesheet, font, xhtml and cover
		#$epub->copy_stylesheet('/path/to/style.css', 'style.css');
		#$epub->copy_file('/path/to/figure1.png', 'figure1.png', 'image/png');
		#$epub->encrypt_file('/path/to/CharisSILB.ttf', 'CharisSILB.ttf', 'application/x-font-ttf');
		#my $chapter_id = $epub->copy_xhtml('/path/to/page1.xhtml', 'page1.xhtml');
		
		# note: $epub->copy_xhtml(...) seems to be buggy
		$epub->add_xhtml('index.xhtml', $converted, linear => 'no');

		# Add top-level nav-point
		#my $navpoint = $epub->add_navpoint(
		#	label       => "Chapter 1",
		#	id          => $chapter_id,
		#	content     => 'page1.xhtml',
		#	play_order  => 1 # should always start with 1
		#);

		# Generate resulting ebook
		$filename = $self->{'final-dir'}.$ebook->{'meta'}->{'title'}.".epub";
		$epub->pack_zip($filename);
	}
	else {
		# write xhtml file
		$filename = $self->{'final-dir'}.$ebook->{'meta'}->{'title'}.".html";
		unlink($filename) if -f $filename;
		my $fh = IO::File->new("> ".$filename);
		print $fh $converted;	
	}
	print "have fun with: ".$filename."\n";
	return $filename;
}

sub transform_nodes
{
	my ($self, @nodes) = @_;	
	my $conv = '';
	foreach my $node (@nodes) {
		if (ref $node) {
			my $type = $node->[0];
			if (exists $self->{'handlers'}->{$type}) {
				$conv .= $self->{'handlers'}->{$type}->($self, $node);
			} else {
				my ($type, $opts, @subnodes) = @{$node};
				$conv .= $self->transform_nodes(@subnodes);
			}
		}
		else {
			$conv .= $self->transform_text($node);
		}
	}
	return $conv;
}

sub transform_text
{
	my ($self, $s) = @_;
	# ...
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
