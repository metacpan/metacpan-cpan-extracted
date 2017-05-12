package Messaging::Courier::Frame;

use strict;
use warnings;

use DateTime;
use EO::Class;
use Data::UUID;
use XML::LibXML;

use EO;
use base qw( EO Class::Accessor::Chained );
__PACKAGE__->mk_accessors(qw( content id in_reply_to sender timestamp ));

exception Messaging::Courier::Frame::Error::InvalidNode;
exception Messaging::Courier::Frame::Error::InvalidXML;

sub init {
  my $self = shift;
  if ($self->SUPER::init( @_ )) {
    ## create the frame id at construction time
    my $id = Data::UUID->new->create_str;
    $self->id( $id );
    return 1;
  }
  return 0;
}

sub new_with_frame {
  my($class, $serialized) = @_;
  my $frame = $class->new;

  $frame->frame( $serialized );
  return $frame;
}

sub frame {
  my $self  = shift;
  my $frame = shift;

  my $doc;
  eval {
    $doc = XML::LibXML->new->parse_string($frame);
  };

  throw Messaging::Courier::Frame::Error::InvalidXML
    text => q{doesn't appear to be valid XML} if $@;

  my @nodes = $doc->findnodes('/envelope/*')->get_nodelist;

  throw Messaging::Courier::Frame::Error::InvalidFrame
    text => q{doesn't appear to be a courier frame} unless @nodes;

  foreach my $node (@nodes) {
    my $value;
    my $field = $node->nodeName;
    if ($field ne 'content') {
      $value = $node->textContent;
    } else {
      my @nodes = $node->findnodes( '*' )->get_nodelist;
      if (@nodes > 1) {
	my $count = scalar(@nodes);
	throw Messaging::Courier::Frame::Error::InvalidNode
	  text => "too many nodes in content node ($count vs 1)";
      }
      my $class = EO::Class->new_with_classname( $self->node_to_classname( $nodes[0]->nodeName ) );
      unless (UNIVERSAL::can($class->name, 'can')) {
	throw Messaging::Courier::Frame::Error::InvalidNode
	  text => 'could not load class ' . $class->name;
      }
      $value    = $class->name->new_with_xmlnode( $node );
      $value->frame( $self );
    }
    my $sub = $self->can( $field );
    # TODO should this explode if !$sub? - tom (see also Message.pm)
    $sub->( $self, $value ) if $sub;
  }

  return $self;
}

sub node_to_classname {
  my $self = shift;
  my $node = shift;
  if (!$node) {
    throw EO::Error::InvalidParameters text => 'no node name';
  }
  $node =~ s/__/::/g;
  $node;
}

sub on_send {
  my($self, $courier) = @_;

  my $timestamp = DateTime->now->datetime;

  $self->sender($courier->id);
  $self->timestamp($timestamp);
}

sub serialize {
  my($self) = @_;

  my $data;
  $data->{$_} = $self->$_ foreach qw(id sender timestamp);

  my $inreplyto = $self->in_reply_to;
  $data->{in_reply_to} = $inreplyto ? $inreplyto->id : 0;

  my $doc = XML::LibXML::Document->new("1.0", "UTF8");
  my $envelope = $doc->createElement("envelope");
  $doc->setDocumentElement($envelope);


  foreach my $field (qw(id sender timestamp in_reply_to)) {
    my $element = $doc->createElement($field);
    my $text = $doc->createTextNode($data->{$field});
    $element->addChild($text);
    $envelope->addChild($element);
  }

  my $element = $doc->createElement('type');
  my $text = $doc->createTextNode($self->content->name);
  $element->addChild($text);
  $envelope->addChild($element);

  $element = $doc->createElement( 'content' );
  $element->addChild( $self->content->do_serialize );
  $envelope->addChild( $element );

#  warn $doc->toString(1);
  return $doc->toString(0);
}

1;
