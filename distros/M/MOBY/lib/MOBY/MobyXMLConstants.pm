package MOBY::MobyXMLConstants;
use strict;
use vars qw( $VERSION @ISA @EXPORT @NodeNames);

$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

BEGIN {
	@ISA = qw( Exporter );
#########################################################
	#The purpose of this module is to emulate some of the   #
	#functionality found in the XML::DOM::Node module. Upon #
	#switching parsers, it was apparent that some subs didnt#
	#exist in LibXML and so they have been recreated here.  #
#########################################################
	# Constants for XML::DOM Node types
	@EXPORT = qw(
	  UNKNOWN_NODE
	  ELEMENT_NODE
	  ATTRIBUTE_NODE
	  TEXT_NODE
	  CDATA_SECTION_NODE
	  ENTITY_REFERENCE_NODE
	  ENTITY_NODE
	  PROCESSING_INSTRUCTION_NODE
	  COMMENT_NODE
	  DOCUMENT_NODE
	  DOCUMENT_TYPE_NODE
	  DOCUMENT_FRAGMENT_NODE
	  NOTATION_NODE
	  ELEMENT_DECL_NODE
	  ATT_DEF_NODE
	  XML_DECL_NODE
	  ATTLIST_DECL_NODE
	  getNodeTypeName
	);
}

#---- Constant definitions
# Node types
sub UNKNOWN_NODE ()                { 0 }     # not in the DOM Spec
sub ELEMENT_NODE ()                { 1 }
sub ATTRIBUTE_NODE ()              { 2 }
sub TEXT_NODE ()                   { 3 }
sub CDATA_SECTION_NODE ()          { 4 }
sub ENTITY_REFERENCE_NODE ()       { 5 }
sub ENTITY_NODE ()                 { 6 }
sub PROCESSING_INSTRUCTION_NODE () { 7 }
sub COMMENT_NODE ()                { 8 }
sub DOCUMENT_NODE ()               { 9 }
sub DOCUMENT_TYPE_NODE ()          { 10 }
sub DOCUMENT_FRAGMENT_NODE ()      { 11 }
sub NOTATION_NODE ()               { 12 }
sub ELEMENT_DECL_NODE ()           { 13 }    # not in the DOM Spec
sub ATT_DEF_NODE ()                { 14 }    # not in the DOM Spec
sub XML_DECL_NODE ()               { 15 }    # not in the DOM Spec
sub ATTLIST_DECL_NODE ()           { 16 }    # not in the DOM Spec
@NodeNames = (
			   "UNKNOWN_NODE",                          # not in the DOM Spec!
			   "XML_ELEMENT_NODE",
			   "XML_ATTRIBUTE_NODE",
			   "XML_TEXT_NODE",
			   "XML_CDATA_SECTION_NODE",
			   "XML_ENTITY_REF_NODE",
			   "XML_ENTITY_NODE",
			   "XML_PI_NODE",
			   "XML_COMMENT_NODE",
			   "XML_DOCUMENT_NODE",
			   "XML_DOCUMENT_TYPE_NODE",
			   "XML_DOCUMENT_FRAG_NODE",
			   "XML_NOTATION_NODE",
			   "XML_ELEMENT_DECL_NODE",
			   "XML_ATT_DEF_NODE",
			   "XML_DECL_NODE",
			   "XML_ATTLIST_DECL_NODE"
);

# this sub takes in a LibXML::Node and outputs the nodeTypeName.
sub getNodeTypeName {
	$NodeNames[ $_[0]->nodeType ];
}
1;
