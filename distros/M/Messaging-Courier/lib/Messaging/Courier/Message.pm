package Messaging::Courier::Message;

use strict;
use warnings;

use EO;
use base qw( EO Class::Accessor::Chained );
__PACKAGE__->mk_accessors(qw( xmlnode ));
use Messaging::Courier::Frame;
use Encode qw(encode_utf8);
use XML::asData;

exception EO::Error::InvalidParameters;
exception Messaging::Courier::Message::Error::NoMessageClass;
exception Messaging::Courier::Message::Error::Serialize;

sub new_with_xmlnode {
  my $class = shift;
  my $node  = shift;
  if (!$node) {
    throw EO::Error::InvalidParameters
      text => 'no node passed to new_with_xmlnode';
  }
  my $self = $class->new();
  $self->xmlnode( $node );
  $self->inflate();
  return $self;
}

sub frame {
  my $self = shift;
  if (@_) {
    ## we take a clone here, as to avoid having a circular ref
    $self->{ frame } = shift->clone;
    return $self;
  }
  return $self->{ frame };
}

sub _doc {
  my $self = shift;
  $self->{ _fakedoc } ||= XML::LibXML::Document->new( "1.0", "UTF8" );
}

sub _node {
  my $self = shift;
  if (!$self->{ _topnode }) {
    my $node = $self->_doc->createElement( $self->name_for_xml );
    $self->{ _topnode } = $node;
  }
  return $self->{ _topnode };
}

sub addNode {
  my $self = shift;
  my $name = shift;
  my $other = { @_ };
  if (!$name || !exists $other->{ contents }) {
    throw EO::Error::InvalidParameters
      text => 'addNode needs a name and contents arg';
  }

  my $contents = $other->{contents};

  my $x = XML::asData->new;
  $x->objects(0);
  $x->root($name);
  my $node = $x->as_libxml($contents)->getDocumentElement;
  $self->_node->addChild( $node );
}

sub do_serialize {
  my $self = shift;
  $self->serialize();
  return $self->_node;
}

sub inflate {
  my $self = shift;
  my @nodes = $self->xmlnode->findnodes( $self->name_for_xml . '/*')->get_nodelist;

  my $x = XML::asData->new;
  $x->objects(0);

  foreach my $node (@nodes) {
    my $field = $node->nodeName();
    my $value = $x->as_data($node->toString);
    if (my $method = $self->can( $field )) {
      $method->( $self, $value );
    } # TODO should this explode if !$sub? - tom (see also Frame.pm)
  }
}

sub reply {
  my $self = shift;
  my $rclass = $self->reply_class;
  my $reply = $rclass->new();
  my $frame = Messaging::Courier::Frame->new();
  $reply->frame( $frame );
  $reply->frame->in_reply_to( $self->frame );
  return $reply;
}

sub in_reply_to {
  my $self = shift;
  my $msg = shift;
  $self->frame(Messaging::Courier::Frame->new) unless $self->frame;
  $self->frame->in_reply_to( $msg->frame );
  return $self;
}


sub name {
  my $self = shift;
  my $class = ref($self) || $self;
  return $class;
}

sub name_for_xml {
  my $self = shift;
  my $name = $self->name;
  $name =~ s/::/__/g;
  return $name;
}

sub sent_by {
  my $self = shift;
  my $courier = shift;
  return unless ($self->frame and $courier and $courier->id and $self->frame->sender);
  return ($courier->id eq $self->frame->sender);
}

sub serialize : abstract {}

sub reply_class {
  my $self = shift;
  return ref($self);
}

1;
