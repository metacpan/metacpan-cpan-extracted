
require 5;
# Time-stamp: "2005-01-04 21:16:40 AST"
package HTML::DOMbo;
use strict;
use vars qw($VERSION);
$VERSION = '3.10';

use HTML::Element (); # just for sanity's sake
use XML::DOM; # import all the nice constants
use Carp ();

BEGIN { eval('sub DEBUG () {0}') unless defined &DEBUG; }

#---------------------------------------------------------------------------

# Types of things to handle:
# UNKNOWN_NODE (0)                The node type is unknown (not part of DOM)
#
# ELEMENT_NODE (1)                The node is an Element.
# ATTRIBUTE_NODE (2)              The node is an Attr.
# TEXT_NODE (3)                   The node is a Text node.
# CDATA_SECTION_NODE (4)          The node is a CDATASection.
# ENTITY_REFERENCE_NODE (5)       The node is an EntityReference.
# ENTITY_NODE (6)                 The node is an Entity.
# PROCESSING_INSTRUCTION_NODE (7) The node is a ProcessingInstruction.
# COMMENT_NODE (8)                The node is a Comment.
# DOCUMENT_NODE (9)               The node is a Document.
# DOCUMENT_TYPE_NODE (10)         The node is a DocumentType.
# DOCUMENT_FRAGMENT_NODE (11)     The node is a DocumentFragment.
# NOTATION_NODE (12)              The node is a Notation.
#
# ELEMENT_DECL_NODE (13)          The node is an ElementDecl (not part of DOM)
# ATT_DEF_NODE (14)               The node is an AttDef (not part of DOM)
# XML_DECL_NODE (15)              The node is an XMLDecl (not part of DOM)
#  ATTLIST_DECL_NODE (16)          The node is an AttlistDecl (not part of DOM)

sub XML::DOM::Node::to_XML_Element {
  require XML::Element;
  if(@_ < 2) {
    $_[0]->to_HTML_Element('XML::Element');
  } else {
    shift->to_HTML_Element(@_); # just an alias, then
  }
}

sub XML::DOM::Node::to_HTML_Element { # recursive method
  my $in = $_[0];
  my $element_class = ref($_[1] || '') || $_[1] || 'HTML::Element';

  #print "Input object $in\n";

  Carp::croak "What DOM node?" unless ref $in;
  Carp::croak "$in isn't a DOM node" unless $in->can('getNodeType');
  
  my $type = $in->getNodeType;
  
  if($type == DOCUMENT_FRAGMENT_NODE) {
    my(@c) = $type->getChildNodes;
    if(wantarray) {
      if(@c == 0) {
        return();
      } elsif(@c > 1) {
        return map $_->to_HTML_Element($element_class), @c;
      }
       # else fall thru
    } else {
      if(@c == 0) {
        return undef; # empty fragment!
      } elsif(@c == 1) {
        $in = $c[0];
        $type = $in->getNodeType; #update
      }
       # else fall thru
    }
  }
  
  if($type == DOCUMENT_NODE) {
    $in = $in->getDocumentElement()
     || Carp::croak "Document has no DocumentElement?"; # sanity
    $type = $in->getNodeType; #update
  }
  
  my $out;
  if($type == ELEMENT_NODE) {
    # What did we ever do to deserve such a bungled mess as the DOM?
    # The whole DOM looks like it was drafted in crayon-scrabbled Java
    #  pseudocode after a night spent huffing glue while listening to
    #  Def Leppard.
    #
    # Just look at this steaming mess of code it takes to get all an object's
    #  attributes!
    my(@attrs);
    my $attr_map = $in->getAttributes;
    my $i;
    my $this_attr;
    if($attr_map and $i = $attr_map->getLength) {
      for(my $j = 0; $j < $i; ++$j) {
        $this_attr = $attr_map->item($j);
        #print "    <",$this_attr->getName,'><', $this_attr->getValue, ">\n";
        push @attrs, $this_attr->getName, $this_attr->getValue;
      }
    }
    $out = $element_class->new($in->getTagName(), @attrs);
    
  } elsif($type == TEXT_NODE
       or $type == CDATA_SECTION_NODE
  ) {
    $out = $in->getNodeValue; # yes, just text!

  } elsif($type == ENTITY_REFERENCE_NODE) {
    $out = $in->getData;      # yes, just text!
    $out = '' unless defined $out; # sanity
  } elsif($type == COMMENT_NODE) {
    $out = $element_class->new('~comment', 'text', $in->getData);
    
  } elsif($type == PROCESSING_INSTRUCTION_NODE) {
    $out = $element_class->new('~pi',
                            'text', join(' ', $in->getTarget, $in->getData)
                           );
    
  } elsif($type == DOCUMENT_FRAGMENT_NODE) {
    # a fake-o div.
    $out = $element_class->new('div', '_implicit' => 1);
    
  } else {
    #Carp::croak "I don't know how to handle objects like $in ($type)";
    print "I don't know how to handle objects like $in ($type)" if $^W;
    return;
  }
  #TODO: Declarations?
  
  # Now attach children
  foreach my $c ($in->getChildNodes) {
    die "Trying to put children on a CDATA, Text, or EntityReference node!"
      unless ref $out;
     # Sanity.  But could entity references be children of Text?
    $out->push_content( $c->to_HTML_Element ); # RECURSE!
  }
  
  return $out;
}

#---------------------------------------------------------------------------

sub HTML::Element::to_XML_DOM { # recursive method
  my($in, $doc) = @_;
  Carp::croak "What element?" unless $in and ref $in;
  $doc ||= XML::DOM::Document->new();

  my $out;
  my $tag = $in->tag;
  # Make a DOM clone of this node:
  {
    # Consider the different kinds of HTML::Element objects,
    #  which are distinguished not by their class, but by their
    #  "tag" (GI) attribute:

    DEBUG && print "+ $tag\n";
    die "No tag for $in?" unless defined $tag and length $tag;
     # enforce minimal sanity
    my($k,$v); # scratch

    if($tag eq '~literal') {
      Carp::croak "Can't put a ~literal into a DOM tree";
      # No, it's not the same as a CDATA.  ~literals are a hack.
      
    } elsif($tag eq '~declaration') {
      # Might as well ignore?

    } elsif($tag eq '~pi') {
      $k = $in->attr('text');
      if($k =~ m<^\s*(\S+)\s+(.*)$>s) {
        $out = $doc->createProcessingInstruction($1,$2);
      } elsif($k =~ m<^\s*(\S+)>s) { # minimal sanity?
        $out = $doc->createProcessingInstruction($1,'');
      } else {
        return; # give up
      }

    } elsif($tag eq '~comment') {
      $k = $in->attr('text');
      $k = join(' ', @$k) if ref($k) eq 'ARRAY';  # never used?
      $out = $doc->createComment($k);

    } else {
      # It's a normal element!

      $out = $doc->createElement($tag);
       # An exception will be thrown there if $tag isn't a legal
       #  XML element name.
      my @attrs = $in->all_external_attr();
      while(@attrs) {
        ($k,$v) = splice @attrs,0,2;
        next if $k eq '/'; # hack.
        DEBUG && print "    attr <$k><$v>\n";
        $out->setAttribute($k,$v);
         # An exception will be thrown there if $k isn't a legal
         #  attribute name.
      }
    }
  }

  # Now, recursively, make and attach children.
  {
    my $new_c; #scratch
    foreach my $c ($in->content_list) {
      if(ref($c)) {
        $new_c = $c->to_XML_DOM($doc) || next;
      } else {
        $new_c = $doc->createTextNode($c);
      }
      $out->appendChild($new_c); # and attach
    }
    # Could conceivably throw an exception if you've done
    #  something bone stupid like put a child under a
    #  comment node.
  }
  
  DEBUG && print "- $tag\n";
  return $out;
}

#---------------------------------------------------------------------------

1;

__END__

=head1 NAME

HTML::DOMbo -- convert between XML::DOM and {XML/HTML}::Element trees

=head1 SYNOPSIS

  use HTML::DOMbo;
  use HTML::TreeBuilder;
  my $tree = HTML::TreeBuilder->new;
  $tree->parse_from_file('foo.html');
  my $dom_tree = $tree->to_XML_DOM;
  # Now you have a DOM element in $dom_tree!

=head1 DESCRIPTION

This class puts a method into HTML::Element called C<to_XML_DOM>, and
puts into the class XML::DOM::Node two methods, C<to_HTML_Element> and
C<to_XML_Element>.

=head2 to_XML_DOM

The class HTML::TreeBuilder robustly produces parse trees of HTML, but
the trees are made of HTML::Element objects, not W3C DOM objects.  If
you want to access a TreeBuilder-made parse tree (in C<$tree>) with a
DOM interface, use HTML::DOMbo and then call

  my $dom_tree = $tree->to_XML_DOM;

This returns a new object of the appropriate class (presumably
XML::DOM::Element), in a new DOM document, having the same structure
and content as the given HTML::TreeBuilder/Element tree.  If you want
the elements to be instantiated against an existing document object,
instead call:

  my $dom_tree = $tree->to_XML_DOM($existing_dom_document);

=head2 to_HTML_Element and to_XML_Element

This module provides two experimental methods (in the XML::DOM::Node
class) called C<to_HTML_Element> and C<to_XML_Element>, which clone a
DOM node (or DOM document, or document fragment) as a new HTML::Element
or XML::Element object.  You need to have the XML::Element module (from
the XML::TreeBuilder dist) installed in order to use the C<to_XML_Element>
method.

It is possible for this to throw a fatal exception.  And it it
possible for this to return a text string instead (if the DOM node
given was a text node).  Moreover, in list context it may return any
number of items, if the source object is a document fragment
containing more than one top-level node, or no nodes.

Users are encouraged to report to me any problems (or successes) in using
this method.  The behavior of this method may change in response to your
requests.

=head1 SEE ALSO

L<XML::DOM>, L<HTML::TreeBuilder>, L<HTML::Element>, L<XML::Element>.

=head1 COPYRIGHT

Copyright 2000 Sean M. Burke.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Sean M. Burke, E<lt>sburke@cpan.orgE<gt>

=cut

