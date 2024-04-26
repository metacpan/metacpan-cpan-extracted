package HTML5::DOM;
use strict;
use warnings;

# Node types
use HTML5::DOM::Node;
use HTML5::DOM::Element;
use HTML5::DOM::Fragment;
use HTML5::DOM::Comment;
use HTML5::DOM::DocType;
use HTML5::DOM::Text;
use HTML5::DOM::Document;

use HTML5::DOM::Encoding;
use HTML5::DOM::Tree;
use HTML5::DOM::Collection;
use HTML5::DOM::CSS;
use HTML5::DOM::TokenList;

our $VERSION = '1.26';
require XSLoader;

# https://developer.mozilla.org/pl/docs/Web/API/Element/nodeType
use constant	ELEMENT_NODE					=> 1; 
use constant	ATTRIBUTE_NODE					=> 2;	# not supported
use constant	TEXT_NODE						=> 3; 
use constant	CDATA_SECTION_NODE				=> 4;	# not supported
use constant	ENTITY_REFERENCE_NODE			=> 5;	# not supported
use constant	ENTITY_NODE						=> 6;	# not supported
use constant	PROCESSING_INSTRUCTION_NODE		=> 7;	# not supported
use constant	COMMENT_NODE					=> 8; 
use constant	DOCUMENT_NODE					=> 9; 
use constant	DOCUMENT_TYPE_NODE				=> 10; 
use constant	DOCUMENT_FRAGMENT_NODE			=> 11; 
use constant	NOTATION_NODE					=> 12;	# not supported

# <MyHTML_tags>
use constant	TAG__UNDEF				=> 0x0;
use constant	TAG__TEXT				=> 0x1;
use constant	TAG__COMMENT			=> 0x2;
use constant	TAG__DOCTYPE			=> 0x3;
use constant	TAG_A					=> 0x4;
use constant	TAG_ABBR				=> 0x5;
use constant	TAG_ACRONYM				=> 0x6;
use constant	TAG_ADDRESS				=> 0x7;
use constant	TAG_ANNOTATION_XML		=> 0x8;
use constant	TAG_APPLET				=> 0x9;
use constant	TAG_AREA				=> 0xa;
use constant	TAG_ARTICLE				=> 0xb;
use constant	TAG_ASIDE				=> 0xc;
use constant	TAG_AUDIO				=> 0xd;
use constant	TAG_B					=> 0xe;
use constant	TAG_BASE				=> 0xf;
use constant	TAG_BASEFONT			=> 0x10;
use constant	TAG_BDI					=> 0x11;
use constant	TAG_BDO					=> 0x12;
use constant	TAG_BGSOUND				=> 0x13;
use constant	TAG_BIG					=> 0x14;
use constant	TAG_BLINK				=> 0x15;
use constant	TAG_BLOCKQUOTE			=> 0x16;
use constant	TAG_BODY				=> 0x17;
use constant	TAG_BR					=> 0x18;
use constant	TAG_BUTTON				=> 0x19;
use constant	TAG_CANVAS				=> 0x1a;
use constant	TAG_CAPTION				=> 0x1b;
use constant	TAG_CENTER				=> 0x1c;
use constant	TAG_CITE				=> 0x1d;
use constant	TAG_CODE				=> 0x1e;
use constant	TAG_COL					=> 0x1f;
use constant	TAG_COLGROUP			=> 0x20;
use constant	TAG_COMMAND				=> 0x21;
use constant	TAG_COMMENT				=> 0x22;
use constant	TAG_DATALIST			=> 0x23;
use constant	TAG_DD					=> 0x24;
use constant	TAG_DEL					=> 0x25;
use constant	TAG_DETAILS				=> 0x26;
use constant	TAG_DFN					=> 0x27;
use constant	TAG_DIALOG				=> 0x28;
use constant	TAG_DIR					=> 0x29;
use constant	TAG_DIV					=> 0x2a;
use constant	TAG_DL					=> 0x2b;
use constant	TAG_DT					=> 0x2c;
use constant	TAG_EM					=> 0x2d;
use constant	TAG_EMBED				=> 0x2e;
use constant	TAG_FIELDSET			=> 0x2f;
use constant	TAG_FIGCAPTION			=> 0x30;
use constant	TAG_FIGURE				=> 0x31;
use constant	TAG_FONT				=> 0x32;
use constant	TAG_FOOTER				=> 0x33;
use constant	TAG_FORM				=> 0x34;
use constant	TAG_FRAME				=> 0x35;
use constant	TAG_FRAMESET			=> 0x36;
use constant	TAG_H1					=> 0x37;
use constant	TAG_H2					=> 0x38;
use constant	TAG_H3					=> 0x39;
use constant	TAG_H4					=> 0x3a;
use constant	TAG_H5					=> 0x3b;
use constant	TAG_H6					=> 0x3c;
use constant	TAG_HEAD				=> 0x3d;
use constant	TAG_HEADER				=> 0x3e;
use constant	TAG_HGROUP				=> 0x3f;
use constant	TAG_HR					=> 0x40;
use constant	TAG_HTML				=> 0x41;
use constant	TAG_I					=> 0x42;
use constant	TAG_IFRAME				=> 0x43;
use constant	TAG_IMAGE				=> 0x44;
use constant	TAG_IMG					=> 0x45;
use constant	TAG_INPUT				=> 0x46;
use constant	TAG_INS					=> 0x47;
use constant	TAG_ISINDEX				=> 0x48;
use constant	TAG_KBD					=> 0x49;
use constant	TAG_KEYGEN				=> 0x4a;
use constant	TAG_LABEL				=> 0x4b;
use constant	TAG_LEGEND				=> 0x4c;
use constant	TAG_LI					=> 0x4d;
use constant	TAG_LINK				=> 0x4e;
use constant	TAG_LISTING				=> 0x4f;
use constant	TAG_MAIN				=> 0x50;
use constant	TAG_MAP					=> 0x51;
use constant	TAG_MARK				=> 0x52;
use constant	TAG_MARQUEE				=> 0x53;
use constant	TAG_MENU				=> 0x54;
use constant	TAG_MENUITEM			=> 0x55;
use constant	TAG_META				=> 0x56;
use constant	TAG_METER				=> 0x57;
use constant	TAG_MTEXT				=> 0x58;
use constant	TAG_NAV					=> 0x59;
use constant	TAG_NOBR				=> 0x5a;
use constant	TAG_NOEMBED				=> 0x5b;
use constant	TAG_NOFRAMES			=> 0x5c;
use constant	TAG_NOSCRIPT			=> 0x5d;
use constant	TAG_OBJECT				=> 0x5e;
use constant	TAG_OL					=> 0x5f;
use constant	TAG_OPTGROUP			=> 0x60;
use constant	TAG_OPTION				=> 0x61;
use constant	TAG_OUTPUT				=> 0x62;
use constant	TAG_P					=> 0x63;
use constant	TAG_PARAM				=> 0x64;
use constant	TAG_PLAINTEXT			=> 0x65;
use constant	TAG_PRE					=> 0x66;
use constant	TAG_PROGRESS			=> 0x67;
use constant	TAG_Q					=> 0x68;
use constant	TAG_RB					=> 0x69;
use constant	TAG_RP					=> 0x6a;
use constant	TAG_RT					=> 0x6b;
use constant	TAG_RTC					=> 0x6c;
use constant	TAG_RUBY				=> 0x6d;
use constant	TAG_S					=> 0x6e;
use constant	TAG_SAMP				=> 0x6f;
use constant	TAG_SCRIPT				=> 0x70;
use constant	TAG_SECTION				=> 0x71;
use constant	TAG_SELECT				=> 0x72;
use constant	TAG_SMALL				=> 0x73;
use constant	TAG_SOURCE				=> 0x74;
use constant	TAG_SPAN				=> 0x75;
use constant	TAG_STRIKE				=> 0x76;
use constant	TAG_STRONG				=> 0x77;
use constant	TAG_STYLE				=> 0x78;
use constant	TAG_SUB					=> 0x79;
use constant	TAG_SUMMARY				=> 0x7a;
use constant	TAG_SUP					=> 0x7b;
use constant	TAG_SVG					=> 0x7c;
use constant	TAG_TABLE				=> 0x7d;
use constant	TAG_TBODY				=> 0x7e;
use constant	TAG_TD					=> 0x7f;
use constant	TAG_TEMPLATE			=> 0x80;
use constant	TAG_TEXTAREA			=> 0x81;
use constant	TAG_TFOOT				=> 0x82;
use constant	TAG_TH					=> 0x83;
use constant	TAG_THEAD				=> 0x84;
use constant	TAG_TIME				=> 0x85;
use constant	TAG_TITLE				=> 0x86;
use constant	TAG_TR					=> 0x87;
use constant	TAG_TRACK				=> 0x88;
use constant	TAG_TT					=> 0x89;
use constant	TAG_U					=> 0x8a;
use constant	TAG_UL					=> 0x8b;
use constant	TAG_VAR					=> 0x8c;
use constant	TAG_VIDEO				=> 0x8d;
use constant	TAG_WBR					=> 0x8e;
use constant	TAG_XMP					=> 0x8f;
use constant	TAG_ALTGLYPH			=> 0x90;
use constant	TAG_ALTGLYPHDEF			=> 0x91;
use constant	TAG_ALTGLYPHITEM		=> 0x92;
use constant	TAG_ANIMATE				=> 0x93;
use constant	TAG_ANIMATECOLOR		=> 0x94;
use constant	TAG_ANIMATEMOTION		=> 0x95;
use constant	TAG_ANIMATETRANSFORM	=> 0x96;
use constant	TAG_CIRCLE				=> 0x97;
use constant	TAG_CLIPPATH			=> 0x98;
use constant	TAG_COLOR_PROFILE		=> 0x99;
use constant	TAG_CURSOR				=> 0x9a;
use constant	TAG_DEFS				=> 0x9b;
use constant	TAG_DESC				=> 0x9c;
use constant	TAG_ELLIPSE				=> 0x9d;
use constant	TAG_FEBLEND				=> 0x9e;
use constant	TAG_FECOLORMATRIX		=> 0x9f;
use constant	TAG_FECOMPONENTTRANSFER	=> 0xa0;
use constant	TAG_FECOMPOSITE			=> 0xa1;
use constant	TAG_FECONVOLVEMATRIX	=> 0xa2;
use constant	TAG_FEDIFFUSELIGHTING	=> 0xa3;
use constant	TAG_FEDISPLACEMENTMAP	=> 0xa4;
use constant	TAG_FEDISTANTLIGHT		=> 0xa5;
use constant	TAG_FEDROPSHADOW		=> 0xa6;
use constant	TAG_FEFLOOD				=> 0xa7;
use constant	TAG_FEFUNCA				=> 0xa8;
use constant	TAG_FEFUNCB				=> 0xa9;
use constant	TAG_FEFUNCG				=> 0xaa;
use constant	TAG_FEFUNCR				=> 0xab;
use constant	TAG_FEGAUSSIANBLUR		=> 0xac;
use constant	TAG_FEIMAGE				=> 0xad;
use constant	TAG_FEMERGE				=> 0xae;
use constant	TAG_FEMERGENODE			=> 0xaf;
use constant	TAG_FEMORPHOLOGY		=> 0xb0;
use constant	TAG_FEOFFSET			=> 0xb1;
use constant	TAG_FEPOINTLIGHT		=> 0xb2;
use constant	TAG_FESPECULARLIGHTING	=> 0xb3;
use constant	TAG_FESPOTLIGHT			=> 0xb4;
use constant	TAG_FETILE				=> 0xb5;
use constant	TAG_FETURBULENCE		=> 0xb6;
use constant	TAG_FILTER				=> 0xb7;
use constant	TAG_FONT_FACE			=> 0xb8;
use constant	TAG_FONT_FACE_FORMAT	=> 0xb9;
use constant	TAG_FONT_FACE_NAME		=> 0xba;
use constant	TAG_FONT_FACE_SRC		=> 0xbb;
use constant	TAG_FONT_FACE_URI		=> 0xbc;
use constant	TAG_FOREIGNOBJECT		=> 0xbd;
use constant	TAG_G					=> 0xbe;
use constant	TAG_GLYPH				=> 0xbf;
use constant	TAG_GLYPHREF			=> 0xc0;
use constant	TAG_HKERN				=> 0xc1;
use constant	TAG_LINE				=> 0xc2;
use constant	TAG_LINEARGRADIENT		=> 0xc3;
use constant	TAG_MARKER				=> 0xc4;
use constant	TAG_MASK				=> 0xc5;
use constant	TAG_METADATA			=> 0xc6;
use constant	TAG_MISSING_GLYPH		=> 0xc7;
use constant	TAG_MPATH				=> 0xc8;
use constant	TAG_PATH				=> 0xc9;
use constant	TAG_PATTERN				=> 0xca;
use constant	TAG_POLYGON				=> 0xcb;
use constant	TAG_POLYLINE			=> 0xcc;
use constant	TAG_RADIALGRADIENT		=> 0xcd;
use constant	TAG_RECT				=> 0xce;
use constant	TAG_SET					=> 0xcf;
use constant	TAG_STOP				=> 0xd0;
use constant	TAG_SWITCH				=> 0xd1;
use constant	TAG_SYMBOL				=> 0xd2;
use constant	TAG_TEXT				=> 0xd3;
use constant	TAG_TEXTPATH			=> 0xd4;
use constant	TAG_TREF				=> 0xd5;
use constant	TAG_TSPAN				=> 0xd6;
use constant	TAG_USE					=> 0xd7;
use constant	TAG_VIEW				=> 0xd8;
use constant	TAG_VKERN				=> 0xd9;
use constant	TAG_MATH				=> 0xda;
use constant	TAG_MACTION				=> 0xdb;
use constant	TAG_MALIGNGROUP			=> 0xdc;
use constant	TAG_MALIGNMARK			=> 0xdd;
use constant	TAG_MENCLOSE			=> 0xde;
use constant	TAG_MERROR				=> 0xdf;
use constant	TAG_MFENCED				=> 0xe0;
use constant	TAG_MFRAC				=> 0xe1;
use constant	TAG_MGLYPH				=> 0xe2;
use constant	TAG_MI					=> 0xe3;
use constant	TAG_MLABELEDTR			=> 0xe4;
use constant	TAG_MLONGDIV			=> 0xe5;
use constant	TAG_MMULTISCRIPTS		=> 0xe6;
use constant	TAG_MN					=> 0xe7;
use constant	TAG_MO					=> 0xe8;
use constant	TAG_MOVER				=> 0xe9;
use constant	TAG_MPADDED				=> 0xea;
use constant	TAG_MPHANTOM			=> 0xeb;
use constant	TAG_MROOT				=> 0xec;
use constant	TAG_MROW				=> 0xed;
use constant	TAG_MS					=> 0xee;
use constant	TAG_MSCARRIES			=> 0xef;
use constant	TAG_MSCARRY				=> 0xf0;
use constant	TAG_MSGROUP				=> 0xf1;
use constant	TAG_MSLINE				=> 0xf2;
use constant	TAG_MSPACE				=> 0xf3;
use constant	TAG_MSQRT				=> 0xf4;
use constant	TAG_MSROW				=> 0xf5;
use constant	TAG_MSTACK				=> 0xf6;
use constant	TAG_MSTYLE				=> 0xf7;
use constant	TAG_MSUB				=> 0xf8;
use constant	TAG_MSUP				=> 0xf9;
use constant	TAG_MSUBSUP				=> 0xfa;
use constant	TAG__END_OF_FILE		=> 0xfb;
use constant	TAG_LAST_ENTRY			=> 0xfc;
# </MyHTML_tags>

# <MyHTML_ns>
use constant	NS_UNDEF				=> 0x0;
use constant	NS_HTML					=> 0x1;
use constant	NS_MATHML				=> 0x2;
use constant	NS_SVG					=> 0x3;
use constant	NS_XLINK				=> 0x4;
use constant	NS_XML					=> 0x5;
use constant	NS_XMLNS				=> 0x6;
use constant	NS_ANY					=> 0x7;
use constant	NS_LAST_ENTRY			=> 0x7;
# </MyHTML_ns>

sub parseAsync($$;$$) {
	my ($self, $html, $options, $callback) = @_;
	
	if (ref($options) eq 'CODE' && !defined $callback) {
		$callback = $options;
		$options = {};
	}
	
	if (ref($callback) eq 'CODE') {
		require EV;
		require AnyEvent::Util;
		
		my ($r, $w) = AnyEvent::Util::portable_pipe();
		AnyEvent::fh_unblock($r);
		
		my $async_w;
		my $async = $self->_parseAsync($html, $options, fileno($w));
		
		$async_w = EV::io($r, EV::READ(), sub {
			close $w;
			close $r;
			undef $w;
			undef $r;
			undef $async_w;
			
			$callback->($async->wait);
		});
		
		return $async;
	} else {
		_parseAsync(@_);
	}
}

XSLoader::load('HTML5::DOM', $VERSION);

1;
__END__
