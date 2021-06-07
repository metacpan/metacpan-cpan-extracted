package HTML::Valid::Tagset;
use parent Exporter;
our @EXPORT_OK = qw/
    %boolean_attr
    %canTighten
    %emptyElement
    %isBlock
    %isBodyElement
    %isCDATA_Parent
    %isFormElement
    %isHTML2
    %isHTML3
    %isHTML4
    %isHTML5
    %isHeadElement
    %isHeadOrBodyElement
    %isInline
    %isKnown
    %isList
    %isObsolete
    %isPhraseMarkup
    %isProprietary
    %isTableElement
    %is_Possible_Strict_P_Content
    %linkElements
    %optionalEndTag
    @allTags
    @p_closure_barriers
    test_taginfo
    attributes
    all_attributes
    attr_type
    tag_attr_ok
/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);
use warnings;
use strict;
use utf8;
use Carp;
use HTML::Valid;

our $VERSION = $HTML::Valid::VERSION;

use vars qw(
    $VERSION
);

use constant {
# Rejected #define __LEXER_H__
# Rejected #define digit       1u
# Rejected #define letter      2u
# Rejected #define namechar    4u
# Rejected #define white       8u
# Rejected #define newline     16u
# Rejected #define lowercase   32u
# Rejected #define uppercase   64u
# Rejected #define digithex    128u
# Rejected #define CM_UNKNOWN      0
CM_EMPTY => (1 << 0),
CM_HTML => (1 << 1),
CM_HEAD => (1 << 2),
CM_BLOCK => (1 << 3),
CM_INLINE => (1 << 4),
CM_LIST => (1 << 5),
CM_DEFLIST => (1 << 6),
CM_TABLE => (1 << 7),
CM_ROWGRP => (1 << 8),
CM_ROW => (1 << 9),
CM_FIELD => (1 << 10),
CM_OBJECT => (1 << 11),
CM_PARAM => (1 << 12),
CM_FRAMES => (1 << 13),
CM_HEADING => (1 << 14),
CM_OPT => (1 << 15),
CM_IMG => (1 << 16),
CM_MIXED => (1 << 17),
CM_NO_INDENT => (1 << 18),
CM_OBSOLETE => (1 << 19),
CM_NEW => (1 << 20),
CM_OMITST => (1 << 21),
# Rejected #define xxxx                   0u
HT20 => 1,
HT32 => 2,
H40S => 4,
H40T => 8,
H40F => 16,
H41S => 32,
H41T => 64,
H41F => 128,
X10S => 256,
X10T => 512,
X10F => 1024,
XH11 => 2048,
XB10 => 4096,
VERS_SUN => 8192,
VERS_NETSCAPE => 16384,
VERS_MICROSOFT => 32768,
VERS_XML => 65536,
HT50 => 131072,
XH50 => 262144,
# Rejected #define VERS_UNKNOWN       (xxxx)
VERS_HTML20 => (1),
VERS_HTML32 => (2),
VERS_HTML40_STRICT => (4|32|256),
VERS_HTML40_LOOSE => (8|64|512),
VERS_FRAMESET => (16|128|1024),
VERS_XHTML11 => (2048),
VERS_BASIC => (4096),
VERS_HTML5 => (131072|262144),
VERS_HTML40 => ((4|32|256)|(8|64|512)|(16|128|1024)),
VERS_IFRAME => ((8|64|512)|(16|128|1024)),
VERS_LOOSE => ((1)|(2)|((8|64|512)|(16|128|1024))),
VERS_EVENTS => (((4|32|256)|(8|64|512)|(16|128|1024))|(2048)),
VERS_FROM32 => ((2)|((4|32|256)|(8|64|512)|(16|128|1024))),
VERS_FROM40 => (((4|32|256)|(8|64|512)|(16|128|1024))|(2048)|(4096)),
VERS_XHTML => (256|512|1024|2048|4096|262144),
VERS_ALL => ((1)|(2)|(((4|32|256)|(8|64|512)|(16|128|1024))|(2048)|(4096))|262144|131072),
VERS_PROPRIETARY => (16384|32768|8192),
};

my $taginfo = HTML::Valid::tag_information ();

our @allTags = sort keys %$taginfo;

our %emptyElement;
our %optionalEndTag;
our %linkElements;
our %boolean_attr;
our %isHeadElement;
our %isBodyElement;
our %isPhraseMarkup;
our %isProprietary;
our %isHeadOrBodyElement;
our %isList;
our %isTableElement;
our %isFormElement;
our %isKnown;
our %canTighten;
our %isHTML5;
our %isHTML4;
our %isHTML3;
our %isHTML2;
our %isObsolete;
our %isInline;
our %isBlock;

for my $tag (@allTags) {
    $isKnown{$tag} = 1;
    my $ti = $taginfo->{$tag};
    my $versions = $ti->[1];
    my $model = $ti->[2];
    if ($model & CM_EMPTY) {
	$emptyElement{$tag} = 1;
    }
    if ($model & CM_OPT) {
	$optionalEndTag{$tag} = 1;
    }
    if ($model & CM_FIELD) {
	$isFormElement{$tag} = 1;
    }
    # See tidy-html5.c
    if ($model & (CM_TABLE|CM_ROWGRP|CM_ROW)) {
	$isTableElement{$tag} = 1;
    }
    if ($model & CM_HEAD) {
	$isHeadElement{$tag} = 1;
	if ($model & ~CM_HEAD) {
	    $isHeadOrBodyElement{$tag} = 1;
	    $isBodyElement{$tag} = 1;
	}
    }
    else {
	$isBodyElement{$tag} = 1;
    }
    if ($model & CM_OBSOLETE) {
	$isObsolete{$tag} = 1;
    }
    if ($model & CM_INLINE) {
	$isPhraseMarkup{$tag} = 1;
	$isInline{$tag} = 1;
    }
    if ($model & CM_BLOCK) {
	$isBlock{$tag} = 1;
    }
    if ($versions & VERS_HTML5) {
	$isHTML5{$tag} = 1;
    }
    if ($versions & VERS_HTML40) {
	$isHTML4{$tag} = 1;
    }
    if ($versions & VERS_HTML32) {
	$isHTML3{$tag} = 1;
    }
    if ($versions & VERS_HTML20) {
	$isHTML2{$tag} = 1;
    }
    if ($versions & VERS_PROPRIETARY) {
	$isProprietary{$tag} = 1;
    }
}


# Start of compatibility with HTML::Tagset

@isFormElement{qw/input button label/} = (1)x3;

# Does not exist in tidy-html classifications.

%isList         = map {; $_ => 1 } qw(ul ol dir menu);

%canTighten = %isKnown;
delete @canTighten{
  keys(%isPhraseMarkup), 'input', 'select',
  'xmp', 'listing', 'plaintext', 'pre',
};

our %isCDATA_Parent = map {; $_ => 1 }
  qw(script style  xmp listing plaintext);

# End of compatibility with HTML::Tagset

# @p_closure_barriers is a conceptual error in HTML::Tagset, see the
# documentation under "Issues with HTML::Tagset".

our @p_closure_barriers = ();

# %is_Possible_Strict_P_Content is just the inline elements, the
# content of HTML::Tagset makes absolutely no sense here and is
# contradictory to the specification it claims to be based on.

our %is_Possible_Strict_P_Content = %isInline;

our %attr2type = (
    'abbr' => 'pcdata',
    'accept' => 'xtype',
    'accept-charset' => 'charset',
    'accesskey' => 'character',
    'action' => 'action',
    'add_date' => 'pcdata',
    'align' => 'align',
    'alink' => 'color',
    'alt' => 'pcdata',
    'archive' => 'urls',
    'aria-activedescendant' => 'pcdata',
    'aria-atomic' => 'pcdata',
    'aria-autocomplete' => 'pcdata',
    'aria-busy' => 'pcdata',
    'aria-checked' => 'pcdata',
    'aria-controls' => 'pcdata',
    'aria-describedby' => 'pcdata',
    'aria-disabled' => 'pcdata',
    'aria-dropeffect' => 'pcdata',
    'aria-expanded' => 'pcdata',
    'aria-flowto' => 'pcdata',
    'aria-grabbed' => 'pcdata',
    'aria-haspopup' => 'pcdata',
    'aria-hidden' => 'pcdata',
    'aria-invalid' => 'pcdata',
    'aria-label' => 'pcdata',
    'aria-labelledby' => 'pcdata',
    'aria-level' => 'pcdata',
    'aria-live' => 'pcdata',
    'aria-multiline' => 'pcdata',
    'aria-multiselectable' => 'pcdata',
    'aria-orientation' => 'pcdata',
    'aria-owns' => 'pcdata',
    'aria-posinset' => 'pcdata',
    'aria-pressed' => 'pcdata',
    'aria-readonly' => 'pcdata',
    'aria-relevant' => 'pcdata',
    'aria-required' => 'pcdata',
    'aria-selected' => 'pcdata',
    'aria-setsize' => 'pcdata',
    'aria-sort' => 'pcdata',
    'aria-valuemax' => 'pcdata',
    'aria-valuemin' => 'pcdata',
    'aria-valuenow' => 'pcdata',
    'aria-valuetext' => 'pcdata',
    'async' => 'bool',
    'autocomplete' => 'pcdata',
    'autofocus' => 'pcdata',
    'autoplay' => 'pcdata',
    'axis' => 'pcdata',
    'background' => 'url',
    'baseprofile' => 'pcdata',
    'bgcolor' => 'color',
    'bgproperties' => 'pcdata',
    'border' => 'border',
    'bordercolor' => 'color',
    'bottommargin' => 'number',
    'cellpadding' => 'length',
    'cellspacing' => 'length',
    'challenge' => 'pcdata',
    'char' => 'character',
    'charoff' => 'length',
    'charset' => 'charset',
    'checked' => 'bool',
    'cite' => 'url',
    'class' => 'pcdata',
    'classid' => 'url',
    'clear' => 'clear',
    'code' => 'pcdata',
    'codebase' => 'url',
    'codetype' => 'xtype',
    'color' => 'color',
    'cols' => 'cols',
    'colspan' => 'number',
    'compact' => 'bool',
    'content' => 'pcdata',
    'contenteditable' => 'pcdata',
    'contentscripttype' => 'pcdata',
    'contentstyletype' => 'pcdata',
    'contextmenu' => 'pcdata',
    'controls' => 'pcdata',
    'coords' => 'coords',
    'data' => 'url',
    'datafld' => 'pcdata',
    'dataformatas' => 'pcdata',
    'datapagesize' => 'number',
    'datasrc' => 'url',
    'datetime' => 'date',
    'declare' => 'bool',
    'default' => 'pcdata',
    'defer' => 'bool',
    'dir' => 'textdir',
    'dirname' => 'pcdata',
    'disabled' => 'bool',
    'display' => 'pcdata',
    'draggable' => 'pcdata',
    'dropzone' => 'pcdata',
    'encoding' => 'pcdata',
    'enctype' => 'xtype',
    'event' => 'pcdata',
    'face' => 'pcdata',
    'for' => 'idref',
    'form' => 'pcdata',
    'formaction' => 'pcdata',
    'formenctype' => 'pcdata',
    'formmethod' => 'pcdata',
    'formnovalidate' => 'pcdata',
    'formtarget' => 'pcdata',
    'frame' => 'tframe',
    'frameborder' => 'fborder',
    'framespacing' => 'number',
    'gridx' => 'number',
    'gridy' => 'number',
    'headers' => 'idrefs',
    'height' => 'length',
    'hidden' => 'pcdata',
    'high' => 'pcdata',
    'href' => 'url',
    'hreflang' => 'lang',
    'hspace' => 'number',
    'http-equiv' => 'pcdata',
    'icon' => 'pcdata',
    'id' => 'iddef',
    'ismap' => 'bool',
    'itemid' => 'pcdata',
    'itemprop' => 'pcdata',
    'itemref' => 'pcdata',
    'itemscope' => 'bool',
    'itemtype' => 'url',
    'keytype' => 'pcdata',
    'kind' => 'pcdata',
    'label' => 'pcdata',
    'lang' => 'lang',
    'language' => 'pcdata',
    'last_modified' => 'pcdata',
    'last_visit' => 'pcdata',
    'leftmargin' => 'number',
    'link' => 'color',
    'list' => 'pcdata',
    'longdesc' => 'url',
    'loop' => 'pcdata',
    'low' => 'pcdata',
    'lowsrc' => 'url',
    'manifest' => 'pcdata',
    'marginheight' => 'number',
    'marginwidth' => 'number',
    'max' => 'pcdata',
    'maxlength' => 'number',
    'media' => 'media',
    'mediagroup' => 'pcdata',
    'method' => 'fsubmit',
    'methods' => 'pcdata',
    'min' => 'pcdata',
    'multiple' => 'bool',
    'n' => 'pcdata',
    'name' => 'name',
    'nohref' => 'bool',
    'noresize' => 'bool',
    'noshade' => 'bool',
    'novalidate' => 'pcdata',
    'nowrap' => 'bool',
    'object' => 'pcdata',
    'onabort' => 'pcdata',
    'onafterprint' => 'pcdata',
    'onafterupdate' => 'script',
    'onbeforeprint' => 'pcdata',
    'onbeforeunload' => 'script',
    'onbeforeupdate' => 'script',
    'onblur' => 'script',
    'oncanplay' => 'pcdata',
    'oncanplaythrough' => 'pcdata',
    'onchange' => 'script',
    'onclick' => 'script',
    'oncontextmenu' => 'pcdata',
    'oncuechange' => 'pcdata',
    'ondataavailable' => 'script',
    'ondatasetchanged' => 'script',
    'ondatasetcomplete' => 'script',
    'ondblclick' => 'script',
    'ondrag' => 'pcdata',
    'ondragend' => 'pcdata',
    'ondragenter' => 'pcdata',
    'ondragleave' => 'pcdata',
    'ondragover' => 'pcdata',
    'ondragstart' => 'pcdata',
    'ondrop' => 'pcdata',
    'ondurationchange' => 'pcdata',
    'onemptied' => 'pcdata',
    'onended' => 'pcdata',
    'onerror' => 'pcdata',
    'onerrorupdate' => 'script',
    'onfocus' => 'script',
    'onhashchange' => 'pcdata',
    'oninput' => 'pcdata',
    'oninvalid' => 'pcdata',
    'onkeydown' => 'script',
    'onkeypress' => 'script',
    'onkeyup' => 'script',
    'onload' => 'script',
    'onloadeddata' => 'pcdata',
    'onloadedmetadata' => 'pcdata',
    'onloadstart' => 'pcdata',
    'onmessage' => 'pcdata',
    'onmousedown' => 'script',
    'onmousemove' => 'script',
    'onmouseout' => 'script',
    'onmouseover' => 'script',
    'onmouseup' => 'script',
    'onmousewheel' => 'pcdata',
    'onoffline' => 'pcdata',
    'ononline' => 'pcdata',
    'onpagehide' => 'pcdata',
    'onpageshow' => 'pcdata',
    'onpause' => 'pcdata',
    'onplay' => 'pcdata',
    'onplaying' => 'pcdata',
    'onpopstate' => 'pcdata',
    'onprogress' => 'pcdata',
    'onratechange' => 'pcdata',
    'onreadystatechange' => 'pcdata',
    'onredo' => 'pcdata',
    'onreset' => 'script',
    'onresize' => 'pcdata',
    'onrowenter' => 'script',
    'onrowexit' => 'script',
    'onscroll' => 'pcdata',
    'onseeked' => 'pcdata',
    'onseeking' => 'pcdata',
    'onselect' => 'script',
    'onshow' => 'pcdata',
    'onstalled' => 'pcdata',
    'onstorage' => 'pcdata',
    'onsubmit' => 'script',
    'onsuspend' => 'pcdata',
    'ontimeupdate' => 'pcdata',
    'onundo' => 'pcdata',
    'onunload' => 'script',
    'onvolumechange' => 'pcdata',
    'onwaiting' => 'pcdata',
    'open' => 'pcdata',
    'optimum' => 'pcdata',
    'pattern' => 'pcdata',
    'placeholder' => 'pcdata',
    'poster' => 'pcdata',
    'preload' => 'pcdata',
    'preserveaspectratio' => 'pcdata',
    'profile' => 'url',
    'prompt' => 'pcdata',
    'pubdate' => 'pcdata',
    'radiogroup' => 'pcdata',
    'rbspan' => 'number',
    'readonly' => 'bool',
    'rel' => 'linktypes',
    'required' => 'pcdata',
    'rev' => 'linktypes',
    'reversed' => 'pcdata',
    'rightmargin' => 'number',
    'role' => 'pcdata',
    'rows' => 'number',
    'rowspan' => 'number',
    'rules' => 'trules',
    'sandbox' => 'pcdata',
    'scheme' => 'pcdata',
    'scope' => 'scope',
    'scoped' => 'pcdata',
    'scrolling' => 'scroll',
    'sdaform' => 'pcdata',
    'sdapref' => 'pcdata',
    'sdasuff' => 'pcdata',
    'seamless' => 'pcdata',
    'selected' => 'bool',
    'shape' => 'shape',
    'showgrid' => 'bool',
    'showgridx' => 'bool',
    'showgridy' => 'bool',
    'size' => 'number',
    'sizes' => 'pcdata',
    'span' => 'number',
    'spellcheck' => 'pcdata',
    'src' => 'url',
    'srcdoc' => 'pcdata',
    'srclang' => 'pcdata',
    'srcset' => 'pcdata',
    'standby' => 'pcdata',
    'start' => 'number',
    'step' => 'pcdata',
    'style' => 'pcdata',
    'summary' => 'pcdata',
    'tabindex' => 'number',
    'target' => 'target',
    'text' => 'color',
    'title' => 'pcdata',
    'topmargin' => 'number',
    'type' => 'type',
    'urn' => 'pcdata',
    'usemap' => 'url',
    'valign' => 'valign',
    'value' => 'pcdata',
    'valuetype' => 'vtype',
    'version' => 'pcdata',
    'viewbox' => 'pcdata',
    'vlink' => 'color',
    'vspace' => 'number',
    'width' => 'length',
    'wrap' => 'pcdata',
    'x' => 'pcdata',
    'xml:lang' => 'lang',
    'xml:space' => 'pcdata',
    'xmlns' => 'pcdata',
    'y' => 'pcdata',
    'zoomandpan' => 'pcdata',
);



# Private routine, for testing we got the tag info.

sub test_taginfo
{
    my ($tag) = @_;
    return $taginfo->{$tag};
}

# Valid arguments for attributes.

my %attributes_key = (
standard => 1,
);

sub options
{
    my (%options) = @_;
    my $version;
    if (! $options{standard} || $options{standard} eq 'html5') {
	$version = VERS_HTML5;
    }
    elsif ($options{standard} eq 'html2') {
	$version = VERS_HTML20;
    }
    elsif ($options{standard} eq 'html3') {
	$version = VERS_HTML32;
    }
    elsif ($options{standard} eq 'html4') {
	$version = VERS_HTML40;
    }
    else {
	carp "Unknown HTML version variable $options{standard}: this should be either html2, html3, html4, html5 (the default), or empty for html5. Defaulting to html5.";
	$version = VERS_HTML5;
    }
    for my $k (keys %options) {
	if (! $attributes_key{$k}) {
	    carp "Unknown key $k: valid keys for attributes are " . join (', ', sort keys %attributes_key) . "\n";
	}
    }
    return $version;
}

sub attributes
{
    my ($tag, %options) = @_;
    my $version = options (%options);
    $tag = lc $tag;
    if (! $isKnown{$tag}) {
	carp "Request for unknown HTML tag '$tag' in attributes: returning undefined value";
	return undef;
    }
    # Look up the HTML Tidy ID of this tag in our hash table.
    my $tagid = $taginfo->{$tag}[0];
    # Get the attributes.
    my $attr = HTML::Valid::tag_attr ($tagid, $version);
    return $attr;
}

sub all_attributes
{
    return HTML::Valid::all_attributes ();
}

# Store of tag/version/attribute valid combinations.

my %tag_attr;

sub tag_attr_ok
{
    my ($tag, $attr, %options) = @_;
    $tag = lc $tag;
    if (! $isKnown{$tag}) {
	carp "Request for unknown HTML tag '$tag' in attributes: returning undefined value";
	return undef;
    }
    my $version = options (%options);
    # If we haven't looked up attributes for this tag and version yet,
    # look them up.
    if (! $tag_attr{$tag}{$version}) {
	my $tagid = $taginfo->{$tag}[0];
	my $attrs = HTML::Valid::tag_attr ($tagid, $version);
	for my $attribute (@$attrs) {
	    # Store the attributes.
	    $tag_attr{$tag}{$version}{$attribute} = 1;
	}
    }
    return $tag_attr{$tag}{$version}{$attr};
}

sub attr_type
{
    my ($attr) = @_;
    return $attr2type{$attr};
}

1;
