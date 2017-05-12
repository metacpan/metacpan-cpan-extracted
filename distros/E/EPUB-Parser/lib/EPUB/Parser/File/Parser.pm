package EPUB::Parser::File::Parser;
use strict;
use warnings;
use Carp;
use Smart::Args;
use XML::LibXML;
use XML::LibXML::XPathContext;

use constant CONTEXT_XPATH => {
    metadata => '/pkg:package/pkg:metadata',
    manifest => '/pkg:package/pkg:manifest',
    spine    => '/pkg:package/pkg:spine',
    guide    => '/pkg:package/pkg:guide',
    toc      => '/xhtml:html/xhtml:body/xhtml:nav[@id="toc"]',
};

sub new {
    args(
        my $class => 'ClassName',
        my $data,
    );

    my $xml = XML::LibXML->new({ no_network => 1, recover => 1 });
    my $xml_document = $xml->parse_string($data);
    my $xpath = XML::LibXML::XPathContext->new($xml_document);

    my $self = bless {
        parser              => $xpath,
        doc                 => $xml_document,
        current_context_key => '',
    } => $class;

    return $self;
}

sub context_node {
    my $self = shift;
    my $key  = shift;

    return $self->{parser}->getContextNode unless $key;

    if ( $self->{current_context_key} ne $key ) {

        croak "did not match key($key) in CONTEXT_XPATH()" unless my $xpath = CONTEXT_XPATH()->{$key};

        my $nodes = $self->{parser}->findnodes($xpath);
        my $context_node;
        if ( $nodes->size >= 1 ) {
            $context_node = $nodes->get_node(1);
        }

        croak '$context_node not found' unless $context_node;
        
        $self->{parser}->setContextNode($context_node);
        $self->{current_context_key} = $key;
    }

    return $self;
}

sub _find {
    my $self  = shift;
    my $xpath = shift or croak 'please input xpath';
    my $node  = shift || $self->context_node;

    $node ? $self->{parser}->findnodes($xpath, $node)
          : $self->{parser}->findnodes($xpath);
}

sub find {
    my $self  = shift;
    $self->_find(@_);
}

sub single {
    my $self  = shift;
    my $node_list = $self->_find(@_);
    if ( $node_list->size >= 1 ) {
        $node_list->get_node(1);
    }
}


1;
