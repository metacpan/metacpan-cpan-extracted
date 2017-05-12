# Copyright 2011, Google Inc. All Rights Reserved.
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

package Google::Ads::Common::XPathSAXParser;

use version;

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};

use Class::Std::Fast;
use Carp;
use XML::XPath;

# Keeps a mapping between SOAP objects and XPath nodes.
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
  my $self = shift;
  my $xml = shift;
  my $xp = XML::XPath->new(xml => $xml);
  my $node = $xp->find($self->get_xpath_expression())->get_node(0);

  if ($node) {
    # Clear out the past cached objects to nodes mapping to avoid memory
    # leaking.
    %OBJECTS_NODES_OF = ();
    $self->__parse_node($node);
    $self->set_current(undef);
  } else {
    die "Given expression " . $self->get_xpath_expresssion() . " didn't " .
      "match any nodes to parse.";
  }
}

# The parsing is done recursively through this method.
sub __parse_node {
  my $self = shift;
  my $node = shift;
  my $node_type = $node->getNodeType();
  my $parent = $node->getParentNode();
  my %handlers = %{$self->get_handlers()};

  $self->set_current($node);

  if ($node_type == XML::XPath::Node::ELEMENT_NODE &&
      ($handlers{Start} || $handlers{End})) {
    # bundle up attributes
    my %attribs = ();
    foreach my $attr (@{$node->getAttributes()}) {
      my $att_name = $self->get_namespaces() ?
          $attr->getLocalName() : $attr->getName();
      $attribs{$att_name} = $attr->getNodeValue();
    }

    my $name = $self->get_namespaces() ?
        $node->getLocalName() : $node->getName();
    if ($handlers{Start}) {
      $handlers{Start}($self, $name, \%attribs, $node);
    }
    foreach my $childNode (@{$node->getChildNodes()}) {
      $self->__parse_node($childNode);
    }
    if ($handlers{End}) {
      $handlers{End}($self, $name, \%attribs, $node);
    }
  } elsif ($node_type == XML::XPath::Node::TEXT_NODE && $handlers{Char}) {
    $handlers{Char}($self, $node->getValue(), $node);
  } elsif ($node_type == XML::XPath::Node::COMMENT_NODE && $handlers{Comment}) {
    $handlers{Comment}($self, $node->getValue(), $node);
  } elsif ($node_type == XML::XPath::Node::PROCESSING_INSTRUCTION_NODE &&
      $handlers{Proc}) {
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

  return $node->getNamespace($node->getPrefix())->getExpanded();
}

# Retrieves a string representation of the current parsed node or any given
# node.
sub recognized_string {
  my ($self, $node) = @_;

  $node = $self->get_current() if not defined $node;

  return $node->get_name();
}

# Associates a SOAP object with an XPath object.
sub link_object_to_node {
  my ($object, $node) = @_;
  $OBJECTS_NODES_OF{${$object}} = $node;
  $OBJECTS_NODES_OF{ident($node)} = $object;
}

# Retrieves an XPath node given its associated SOAP Object.
sub get_node_from_object {
  my ($object) = @_;
  return $OBJECTS_NODES_OF{${$object}};
}

# Retrieves a SOAP Object given its associated XPath node.
sub get_object_from_node {
  my ($node) = @_;
  return $OBJECTS_NODES_OF{ident($node)};
}

return 1;

=pod

=head1 NAME

Google::Ads::Common::XPathSAXParser

=head1 DESCRIPTION

Implements a SAX type of XML parser based on the L<XML::XPath:XML::XPath>.
And it is basically used during deserialization to tie XPath module nodes
with SOAP objects so the XPath module search functionalities can be used
to find SOAP objects.

=head1 METHODS

=head2 parse

Main entry point to start the parsing of the XML and report to the registered
handlers the parsed node in a depth-first traversal fashion as expected from
a SAX parser.

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

Optional an XPath node. If none given then the current parsed is used.

=head3 Returns

The registered namespace.

=head2 recognized_string

Retrieves a string representation of the current parsed node or any given
node.

=head3 Parameters

Optional an XPath node. If none given then the current parsed is used.

=head3 Returns

The string representation.

=head2 link_object_to_node

Links a SOAP Object with its XPath node.

=head3 Parameters

The SOAP object to associate.

The XPath node.

=head2 get_node_from_object

Retrieves an XPath node given its associated SOAP Object.

=head3 Parameters

The SOAP object.

=head3 Returns

The associated XPath node if found.

=head2 get_object_from_node

Retrieves a SOAP Object given its associated XPath node..

=head3 Parameters

The XPath node.

=head3 Returns

The associated SOAP Object.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 AUTHOR

David Torres E<lt>api.davidtorres at gmail.comE<gt>

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
