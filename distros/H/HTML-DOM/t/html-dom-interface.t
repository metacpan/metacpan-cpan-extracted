#!/usr/bin/perl -T

# This checks to make sure the module is actually  there  and  that
# %HTML::DOM::Interface has something in it.  It also makes sure  that
# changes made since its introduction are not undone. Is there any way to
# test this  fully  without  simply  copying  the  entire  hash  into  this
# test file?

use lib 't';
use strict; use warnings;

use HTML::DOM::Interface;

# -------------------------#
use tests 1; # is the hash there (and does it have somthing in it?)

ok(%HTML::DOM::Interface);

# -------------------------#
# Make sure all constants are defined
BEGIN {
    $::constests = 0;
    for (values %HTML::DOM::Interface) {
	if (ref && $$_{_constants}) { $::constests += @{$$_{_constants}} }
    }
}
use tests $::constests;

for (values %HTML::DOM::Interface) {
 for(@{ref || next; $$_{_constants} || next}) {
  ok defined eval, "$_ is defined";
 }
}

# -------------------------#
use tests 4; # changes made in 0.009

ok !exists $HTML::DOM::Interface{Document}, '{Document} doesn\'t exist';
ok exists $HTML::DOM::Interface{HTMLDocument}{createComment},
	"{HTMLDocument}{createComment} exists";
is $HTML::DOM::Interface{HTMLDocument}{_isa}, "Node",
	'HTMLDocument isa Node';
ok exists $HTML::DOM::Interface{'HTML::DOM::Collection::Options'},
	'HTML::DOM::Collection::Options is there';

# -------------------------#
use tests 25; # changes made in 0.010

ok exists $HTML::DOM::Interface{$_}, $_ for map "HTML::DOM::Element::$_",
	qw/ Table Caption TableColumn TableSection TR TableCell
	    FrameSet Frame IFrame /;
ok exists $HTML::DOM::Interface{HTMLFormElement}{reset},
	'form reset';

# DOM 2 core stuff
{
	my $constants = join ' ', '',
		@{ $HTML::DOM::Interface{DOMException}{_constants} }, '';
	like $constants, qr/ HTML::DOM::Exception::$_ /, $_,
		for qw/ INVALID_STATE_ERR SYNTAX_ERR
		       INVALID_MODIFICATION_ERR NAMESPACE_ERR
		     INVALID_ACCESS_ERR /;
}
ok exists $HTML::DOM::Interface{Attr}{ownerElement}, 'Attr->ownerElement';
ok exists $HTML::DOM::Interface{HTMLDocument}{importNode},
	'Document->importNode';
ok exists $HTML::DOM::Interface{Node}{$_}, "Node->$_"
	for qw/ isSupported hasAttributes normalize /;
ok !exists $HTML::DOM::Interface{HTMLElement}{normalize},
	"Element->normalize is gone";
ok exists $HTML::DOM::Interface{HTMLElement}{hasAttribute},
	"Element->hasAttribute";

# DOM 2 view stuff
ok exists $HTML::DOM::Interface{HTMLDocument}{defaultView}, 'defaultView';
ok exists $HTML::DOM::Interface{AbstractView};

# CSS stuff
ok exists $HTML::DOM::Interface{HTMLElement}{style}, 'style';

# -------------------------#
use tests 3; # changes made in 0.011

ok exists $HTML::DOM::Interface{HTMLLinkElement}{sheet},
	'HTMLLinkElement sheet';
ok exists $HTML::DOM::Interface{HTMLStyleElement}{sheet},
	'HTMLStyleElement sheet';
ok exists $HTML::DOM::Interface{HTMLDocument}{styleSheets}, 'styleSheets';

# -------------------------#
use tests 2; # changes made in 0.012

is $HTML::DOM::Interface{'HTML::DOM::Collection::Options'},
	'HTMLOptionsCollection',
	'HTML::DOM::Collection::Options maps to HTMLOptionsCollection';
ok exists $HTML::DOM::Interface{HTMLOptionsCollection},
	'HTMLOptionsCollection';

# -------------------------#
use tests 11; # changes made in 0.013

ok $HTML::DOM::Interface{CharacterData}{length} & &
	HTML::DOM::Interface::UTF16, 'length16';
ok $HTML::DOM::Interface{CharacterData}{substringData} & &
	HTML::DOM::Interface::UTF16, 'substringData16';
ok $HTML::DOM::Interface{CharacterData}{insertData} & &
	HTML::DOM::Interface::UTF16, 'insertData16';
ok $HTML::DOM::Interface{CharacterData}{deleteData} & &
	HTML::DOM::Interface::UTF16, 'deleteData16';
ok $HTML::DOM::Interface{CharacterData}{replaceData} & &
	HTML::DOM::Interface::UTF16, 'replaceData16';
ok $HTML::DOM::Interface{Text}{splitText} & &
	HTML::DOM::Interface::UTF16, 'splitText16';
ok !($HTML::DOM::Interface{HTMLOptionElement}{index} &
	&HTML::DOM::Interface::READONLY),
	'HTMLOptionElement.index is not read-only';
ok !($HTML::DOM::Interface{HTMLInputElement}{type} &
	&HTML::DOM::Interface::READONLY),
	'HTMLInputElement.type is not read-only';
ok exists $HTML::DOM::Interface{HTMLFrameElement}{contentDocument},
		'HTMLFrameElement contentDocument';
ok exists $HTML::DOM::Interface{HTMLIFrameElement}{contentDocument},
		'HTMLIFrameElement contentDocument';
ok exists $HTML::DOM::Interface{DOMException}{code}, 'DOMException.code';

# -------------------------#
use tests 5; # changes made in 0.016
ok exists $HTML::DOM::Interface{MouseEvent},'MouseEvent';
ok exists $HTML::DOM::Interface{UIEvent},'UIEvent';
ok exists $HTML::DOM::Interface{MutationEvent},'MutationEvent';
ok $HTML::DOM::Interface{HTMLOptionsCollection}{_hash},
	'options doess hash';
ok $HTML::DOM::Interface{HTMLOptionsCollection}{_array},
	'options doess ary';

# -------------------------#
use tests 3; # changes made in 0.018
ok exists $HTML::DOM::Interface{HTMLDocument}{innerHTML},'doc->innerHTML';
ok exists $HTML::DOM::Interface{HTMLElement}{innerHTML},'elem->innerHTML';
ok exists $HTML::DOM::Interface{HTMLDocument}{location},'doc->location';

# -------------------------#
use tests 6; # changes made in 0.019
ok exists $HTML::DOM::Interface{EventTarget}, 'EventTarget';
is $HTML::DOM::Interface{Node}{_isa}, 'EventTarget','Node isa EventTarget';
ok !exists $HTML::DOM::Interface{Node}{addEventListener},
	'Node no longer has addEventListener';
ok !exists $HTML::DOM::Interface{Node}{dispatchEvent},
	'Node no longer has dispatchEvent';
ok !exists $HTML::DOM::Interface{Node}{removeEventListener},
	'Node no longer has removeEventListener';
is $HTML::DOM::Interface{'HTML::DOM::EventTarget'}, 'EventTarget',
	'HTML::DOM::EventTarget';

# -------------------------#
use tests 34; # changes made in 0.019
for(qw(
	abort beforeunload blur change click contextmenu dblclick drag
	dragend dragenter dragleave dragover dragstart drop error focus
	hashchange keydown keypress keyup load message mousedown
	mousemove mouseout mouseover mouseup mousewheel resize scroll
	select storage submit unload 
)) {
	ok exists $HTML::DOM::Interface{EventTarget}{"on$_"}, "on$_";
}

# -------------------------#
use tests 16; # changes made in 0.030
ok exists $HTML::DOM::Interface{HTMLDocument}{lastModified};
ok exists $HTML::DOM::Interface{AbstractView}{getComputedStyle};
ok exists $HTML::DOM::Interface{HTMLAnchorElement}{$_} for
 qw/ hash host hostname pathname port protocol search /;
ok exists $HTML::DOM::Interface{HTMLAreaElement}{$_} for
 qw/ hash host hostname pathname port protocol search /;

# -------------------------#
use tests 3; # changes made in 0.032
ok exists $HTML::DOM::Interface{HTMLElement}{$_}
 for qw/ insertAdjacentHTML insertAdjacentElement /;
ok eval 'HTML::DOM::Interface->import("UTF16");1', 'UTF16 is exportable';

# -------------------------#
use tests 2; # changes made in 0.033
ok exists $HTML::DOM::Interface{$_}{contentWindow}, "$_->contentWindow",
 for qw/ HTMLFrameElement HTMLIFrameElement /;

# -------------------------#
use tests 2; # changes made in 0.036
ok !exists $HTML::DOM::Interface{"HTML::DOM::TreeBuilder"};
ok exists $HTML::DOM::Interface{"HTMLElement"}{innerText}, 'innerText';

# -------------------------#
use tests 2; # changes made in 0.037
ok exists $HTML::DOM::Interface{"HTMLDocument"}{getElementsByClassName};
ok exists $HTML::DOM::Interface{"HTMLElement"}{getElementsByClassName};

# -------------------------#
use tests 2; # changes made in 0.054
ok $HTML::DOM::Interface{"NamedNodeMap"}{_hash};
ok $HTML::DOM::Interface{"NamedNodeMap"}{_array};
