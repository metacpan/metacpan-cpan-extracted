package HTTP::OAI::SAX::Driver;

use XML::LibXML;
use base XML::SAX::Base;
use XML::NamespaceSupport;

use strict;

our $VERSION = '4.11';

=pod

=head1 NAME

HTTP::OAI::SAXHandler - SAX2 utility filter

=head1 DESCRIPTION

This module provides utility methods for SAX2, including collapsing multiple "characters" events into a single event.

This module exports methods for generating SAX2 events with Namespace support. This *isn't* a fully-fledged SAX2 generator!

=over 4

=item $h = HTTP::OAI::SAXHandler->new()

Class constructor.

=cut

sub new
{
	my( $class, %self ) = @_;

	$self{ns} = XML::NamespaceSupport->new;

	my $self = $class->SUPER::new( %self );

	return $self;
}

sub generate
{
	my( $self, $node ) = @_;

	my $nodeType = $node->nodeType;

	if( $nodeType == XML_DOCUMENT_NODE )
	{
		$self->generate( $node->documentElement );
	}
	elsif( $nodeType == XML_DOCUMENT_FRAG_NODE )
	{
		$self->generate( $_ ) for $node->childNodes;
	}
	elsif( $nodeType == XML_ELEMENT_NODE )
	{
		$self->start_element( $node->nodeName, map {
				$_->nodeName => $_->nodeValue
			} $node->attributes
		);
		$self->generate( $_ ) for $node->childNodes;
		$self->end_element( $node->nodeName );
	}
	elsif( $nodeType == XML_TEXT_NODE )
	{
		$self->characters( { Data => $node->nodeValue } );
	}
}

sub start_oai_pmh
{
	my( $self ) = @_;

	$self->start_document;
	$self->xml_decl({'Version'=>'1.0','Encoding'=>'UTF-8'});
	$self->characters({'Data'=>"\n"});
	$self->start_prefix_mapping({
		Prefix => "",
		NamespaceURI => HTTP::OAI::OAI_NS(),
	});
	$self->start_prefix_mapping({
		Prefix => "xsi",
		NamespaceURI => "http://www.w3.org/2001/XMLSchema-instance",
	});
}

sub end_oai_pmh
{
	my( $self ) = @_;

	$self->end_prefix_mapping({
		Prefix => "",
		NamespaceURI => HTTP::OAI::OAI_NS(),
	});
	$self->end_prefix_mapping({
		Prefix => "xsi",
		NamespaceURI => "http://www.w3.org/2001/XMLSchema-instance",
	});
	$self->end_document;
}

sub data_element {
	my( $self, $Name, $value, @attr ) = @_;

	$self->start_element( $Name, @attr );
	$self->characters( {Data => $value} );
	$self->end_element( $Name );
}

sub start_prefix_mapping
{
	my( $self, $hash ) = @_;

	$self->{ns}->declare_prefix( $hash->{Prefix}, $hash->{NamespaceURI} );

	$self->SUPER::start_prefix_mapping( $hash );
}

sub start_element
{
	my( $self, $Name, @attr ) = @_;

	$self->{ns}->push_context;

	my %attr;
	while(my( $key, $value ) = splice(@attr,0,2))
	{
		next if !defined $value;
		my( $NamespaceURI, $Prefix, $LocalName );
		if( $key =~ /^xmlns:(.+)$/ )
		{
			$self->start_prefix_mapping( {Prefix => $1, NamespaceURI => $value} );
			$NamespaceURI = "http://www.w3.org/2000/xmlns/";
			$Prefix = "xmlns";
			$LocalName = $1;
		}
		elsif( $key eq "xmlns" )
		{
			$self->start_prefix_mapping( {Prefix => '', NamespaceURI => $value} );
			$NamespaceURI = '';
			$Prefix = '';
			$LocalName = $key;
		}
		elsif( $key =~ /^(.+):(.+)$/ )
		{
			$NamespaceURI = $self->{ns}->get_uri( $1 );
			$Prefix = $1;
			$LocalName = $2;
		}
		else
		{
			$NamespaceURI = '';
			$Prefix = '';
			$LocalName = $key;
		}
		$attr{"{$NamespaceURI}$LocalName"} = {
			NamespaceURI => $NamespaceURI,
			Prefix => $Prefix,
			LocalName => $LocalName,
			Name => $key,
			Value => $value,
		};
	}

	my ($Prefix,$LocalName) = split /:/, $Name;

	unless(defined($LocalName)) {
		$LocalName = $Prefix;
		$Prefix = '';
	}

	my $NamespaceURI = $self->{ns}->get_uri( $Prefix );

	$self->SUPER::start_element({
		'NamespaceURI'=>$NamespaceURI,
		'Name'=>$Name,
		'Prefix'=>$Prefix,
		'LocalName'=>$LocalName,
		'Attributes'=>\%attr
	});
}

sub end_element
{
	my( $self, $Name ) = @_;

	my ($Prefix,$LocalName) = split /:/, $Name;

	unless(defined($LocalName)) {
		$LocalName = $Prefix;
		$Prefix = '';
	}

	my $NamespaceURI = $self->{ns}->get_uri( $Prefix );

	$self->SUPER::end_element({
		'NamespaceURI'=>$NamespaceURI,
		'Name'=>$Name,
		'Prefix'=>$Prefix,
		'LocalName'=>$LocalName,
	});

	$self->{ns}->pop_context;
}

1;

__END__

=back

=head1 AUTHOR

Tim Brody <tdb01r@ecs.soton.ac.uk>
