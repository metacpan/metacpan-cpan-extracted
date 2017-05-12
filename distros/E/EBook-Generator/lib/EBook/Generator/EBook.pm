package EBook::Generator::EBook;

use 5.008009;
use strict;
use warnings;

use strict;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request;
use File::Temp;
use IO::File;
use XML::LibXML;
use XML::LibXML::XPathContext;

use EBook::Generator::Reader;
use EBook::Generator::Parser;
use EBook::Generator::Exporter;
use EBook::Generator::Analyser;

sub new
{
	my ($class, @args) = @_;
	my $self = bless {}, $class;
	return $self->init(@args);
}

sub init
{
	my ($self, $url, %options) = @_;
	
	#--- user configurable options ---
	
	$self->{'options'} = {
		'debug' => 0,

		'min-img-width' => 100,
		'min-img-height' => 80,
		
		# identify advert images using the aspect ratio of image, e.g.
		#   1200 x 200 -> 1200/200 = 6   BAD!
		#   600  x 400 -> 600/400  = 1.5 OK!
		'image-max-length-aspect-ratio' => 3,
		
		'use-color-images' => 0,

		# currently only recognized for format XHTML
		'embed-images' => 1,
		'epub' => 0, # if the xhtml should be wrapped inside an EPUB document

		# only used for format PDF
		'local-tex-tree-path' => (exists $ENV{'HOME'} ? $ENV{'HOME'} : '/tmp').'/textree',
	};
	
	# parse user options
	foreach my $key (keys %{$self->{'options'}}) {
		$self->{'options'}->{$key} = $options{$key}
			if exists($options{$key}) && 
			   ref($options{$key}) eq ref($self->{'options'}->{$key});
	}

	#--- system options ---

	# web browser	
	$self->{'browser'} = LWP::UserAgent->new();
	$self->{'browser'}->timeout(10);

	# create xml parser
	$self->{'xml-parser'} = XML::LibXML->new();
	$self->{'xml-parser'}->recover(2);
	
	$self->{'url'} = $url;
	$self->{'log'} = [];
	
	$self->{'reader'} = 
		EBook::Generator::Reader->new($self->{'browser'}, $self->{'log'});
	
	$self->{'parser'} = 	
		EBook::Generator::Parser->new($self->{'browser'}, $self->{'xml-parser'}, $self->{'log'});

	$self->{'analyser'} = 
		EBook::Generator::Analyser->new($self->{'log'});

	$self->readSource();
	
	return $self;
}

sub readSource
{
	my ($self) = @_;

	@{$self->{'log'}} = ();
	
	# fetch content html
	my $raw = $self->{'reader'}->getContent($self->{'url'});
	
	# parse content into semantic datastructure structure
	my @result =	$self->{'parser'}->parseContent($raw, $self->{'url'}, $self->{'options'});
	$self->{'meta'} = $result[0];
	$self->{'data'} = $result[1];
	
	#print Dumper($self->{'data'}->toString());
	#exit;
	
	return $self;
}

sub writeEBook
{
	my ($self, $format) = @_;
	$format = 'pdf' unless defined $format;
	
	# analyse content
	$self->{'analyser'}->analyseContent($self);
	
	my $exporter  = EBook::Generator::Exporter->new($self->{'browser'}, $self->{'log'});
	my $filename = $exporter->writeEBook($self, $format, $self->{'options'});
	
	$self->{'parser'}->cleanup();
	return $filename;
}

sub getLog
{
	my ($self) = @_;
	return $self->{'log'};
}

1;
