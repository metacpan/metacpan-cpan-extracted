package HTTP::OAI::Metadata::METS;

use XML::LibXML;
use XML::LibXML::XPathContext;

@ISA = qw( HTTP::OAI::Metadata );

use strict;

our $VERSION = '4.08';

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	my %args = @_;
	$self;
}

sub _xc
{
	my $xc = XML::LibXML::XPathContext->new( @_ );
	$xc->registerNs( 'oai_dc', HTTP::OAI::OAI_NS );
	$xc->registerNs( 'mets', 'http://www.loc.gov/METS/' );
	$xc->registerNs( 'xlink', 'http://www.w3.org/1999/xlink' );
	return $xc;
}

sub files
{
	my $self = shift;
	my $dom = $self->dom;

	my $xc = _xc($dom);

	my @files;
	foreach my $file ($xc->findnodes( '*//mets:file' ))
	{
		my $f = {};
		foreach my $attr ($file->attributes)
		{
			$f->{ $attr->nodeName } = $attr->nodeValue;
		}
		$file = _xc($file);
		foreach my $locat ($file->findnodes( 'mets:FLocat' ))
		{
			$f->{ url } = $locat->getAttribute( 'xlink:href' );
		}
		push @files, $f;
	}

	return @files;
}

1;

__END__

=head1 NAME

HTTP::OAI::Metadata::METS - METS accessor utility

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 NOTE
