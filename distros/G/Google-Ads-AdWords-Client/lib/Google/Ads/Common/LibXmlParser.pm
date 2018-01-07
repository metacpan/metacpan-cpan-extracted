# Copyright 2017, Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Google::Ads::Common::LibXmlParser;

use strict;
use warnings;
use version;

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};

use Class::Std::Fast;
use Carp;
use XML::LibXML;

# Keeps a mapping between SOAP objects and nodes.
my %OBJECTS_NODES_OF;

# SAX handlers used as callbacks during parsing.
my %handlers_of : ATTR(:name<handlers> :default<{}>);

# Initial XPath expression to filter results to parse.
# Defaults to the root element.
my %xpath_expression_of : ATTR(:name<xpath_expression> :default<"/*">);

# Boolean to indicate when namespace prefixes have to be included 0 or
# excluded 1 from the reported names of elements parsed. Defaults to 1.
my %namespaces_of : ATTR(:name<namespaces> :default<1>);

# Stores the current element being parsed.
my %current_of : ATTR(:name<current> :default<>);

# Start the parsing.
# Takes the XML to parse.
sub parse {
  my ($self, $xml) = @_;
  my $doc  = XML::LibXML->new->parse_string($xml);
  my $root = $doc->documentElement();
  my $node = $root->findnodes($self->get_xpath_expression())->get_node(0);
  if ($root) {
    # Clear out the past cached objects to nodes mapping to avoid memory
    # leaking.
    %OBJECTS_NODES_OF = ();
    $self->__parse_node($root);
    $self->set_current(undef);
  } else {
    die "Given expression " . $self->get_xpath_expresssion() . " didn't " .
      "match any nodes to parse.";
  }
}

# The parsing is done recursively through this method.
sub __parse_node {
  my ($self, $node) = @_;
  my $node_type = $node->nodeType();
  my %handlers  = %{$self->get_handlers()};
  $self->set_current($node);

  if ($node_type == XML::LibXML::XML_ELEMENT_NODE
    && ($handlers{Start} || $handlers{End}))
  {
    # bundle up attributes
    my %attribs = ();
    foreach my $attr ($node->attributes()) {
      my $att_name =
        $self->get_namespaces() ? $attr->getLocalName() : $attr->name();
      if ($att_name) {
        $attribs{$att_name} = $attr->value();
      }
    }

    my $name =
      $self->get_namespaces() ? $node->localName() : $node->nodeName();
    if ($handlers{Start}) {
      $handlers{Start}($self, $name, \%attribs, $node);
    }
    foreach my $childNode (@{$node->childNodes()}) {
      $self->__parse_node($childNode);
    }
    if ($handlers{End}) {
      $handlers{End}($self, $name, \%attribs, $node);
    }
  } elsif ($node_type == XML::LibXML::XML_TEXT_NODE && $handlers{Char}) {
    $handlers{Char}($self, $node->nodeValue(), $node);
  } elsif ($node_type == XML::LibXML::XML_COMMENT_NODE && $handlers{Comment}) {
    $handlers{Comment}($self, $node->nodeValue(), $node);
  } elsif ($node_type == XML::LibXML::XML_PI_NODE
    && $handlers{Proc})
  {
    $handlers{Proc}($self, $node->getTarget(), $node->getData(), $node);
  } else {
    croak "Unknown node type: '", ref($node), "' type ", $node_type,
      " or not handler found.\n";
  }
}

# Retrieves the expanded namespace name of the current parsed node or any
# given node.
sub namespace {
  my ($self, $node) = @_;

  $node = $self->get_current() if not defined $node;

  return $node->lookupNamespaceURI($node->prefix());
}

# Retrieves a string representation of the current parsed node or any given
# node.
sub recognized_string {
  my ($self, $node) = @_;

  $node = $self->get_current() if not defined $node;

  return $node->nodeName();
}

# Associates a SOAP object with an object.
sub link_object_to_node {
  my ($object, $node) = @_;
  $OBJECTS_NODES_OF{${$object}} = $node;
  $OBJECTS_NODES_OF{ident($node)} = $object;
}

# Retrieves a node given its associated SOAP Object.
sub get_node_from_object {
  my ($object) = @_;
  return $OBJECTS_NODES_OF{${$object}};
}

# Retrieves a SOAP Object given its associated node.
sub get_object_from_node {
  my ($node) = @_;
  return $OBJECTS_NODES_OF{ident($node)};
}

return 1;

=pod

=head1 NAME

Google::Ads::Common::LibXmlParser

=head1 DESCRIPTION

Implements an XML parser based on the L<XML::LibXML>.

=head1 METHODS

=head2 parse

Main entry point to start the parsing of the XML and report to the registered
handlers the parsed node in a depth-first traversal fashion as expected from
a parser.

=head3 Parameters

The XML to parse.

=head2 __parse_node

The parsing is done recursively through this method.

=head3 Parameters

The node being parsed.

=head2 namespace

Retrieves the expanded namespace name of the current parsed node or any
given node.

=head3 Parameters

Optional a node. If none given then the current parsed is used.

=head3 Returns

The registered namespace.

=head2 recognized_string

Retrieves a string representation of the current parsed node or any given
node.

=head3 Parameters

Optional a node. If none given then the current parsed is used.

=head3 Returns

The string representation.

=head2 link_object_to_node

Links a SOAP Object with its node.

=head3 Parameters

The SOAP object to associate.

The node.

=head2 get_node_from_object

Retrieves a node given its associated SOAP Object.

=head3 Parameters

The SOAP object.

=head3 Returns

The associated node if found.

=head2 get_object_from_node

Retrieves a SOAP Object given its associated node.

=head3 Parameters

The node.

=head3 Returns

The associated SOAP Object.

=cut
