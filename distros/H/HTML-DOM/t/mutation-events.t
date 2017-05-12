#!/usr/bin/perl -T

use strict; use warnings; no warnings qw 'utf8 parenthesis'; use lib 't';

use lib 't';
use HTML::DOM;

my $doc = new HTML::DOM;
my $event = $doc->createEvent('MutationEvents');

use HTML::DOM::Event::Mutation ':all';

# -------------------------#
use tests 3; # constants
cmp_ok MODIFICATION , '==', 1, 'MODIFICATION';
cmp_ok ADDITION , '==', 2, 'ADDITION';
cmp_ok REMOVAL , '==', 3, 'REMOVAL';


# -------------------------#
use tests 13; # initMutationEvent

is +()=$event->relatedNode, 0, 'relatedNode before init';
is $event->prevValue, undef, 'prevValue before init';
is $event->newValue, undef, 'newValue before init';
is $event->attrName, undef, 'attrName before init';
is $event->attrChange, undef, 'attrChange before init';

my $foo = bless[];
is_deeply [initMutationEvent $event
	DOMSubtreeModified => 1, 1,$foo,5,3,4,2
], [],
	'initMutationEvent returns nothing';

ok bubbles $event, 'event is bubbly after init*Event';
ok cancelable $event, 'event is cancelable after init*Event';
is $event->relatedNode, $foo, 'relatedNode type after init*Event';
is $event->prevValue, 5, 'prevValue after init*Event';
is $event->newValue, 3, 'newValue, after init*Event';
is $event->attrName, 4, 'attrName after init*Event';
is $event->attrChange, 2, 'attrChange after init*Event';

# -------------------------#
use tests 7; # init

init $event type       =>DOMSubtreeModified=>propagates_up=> 1,
            cancellable=> 1,                 rel_node     => $foo,
            prev_value => 5,                 new_value    => 3,
            attr_name  => 4,                 attr_change_type => 2;

ok bubbles $event, 'event is bubbly after init';
ok cancelable $event, 'event is cancelable after init';
is $event->relatedNode, $foo, 'relatedNode type after init';
is $event->prevValue, 5, 'prevValue after init';
is $event->newValue, 3, 'newValue, after init';
is $event->attrName, 4, 'attrName after init';
is $event->attrChange, 2, 'attrChange after init';

# -------------------------#
use tests 14; # trigger_event’s defaults
{
	my $elem = $doc->createElement('div');
	my $output;
	$elem->addEventListener($_ => sub {
		my $event = shift;
		isa_ok $event, 'HTML::DOM::Event::Mutation',
			$event->type . " event object";
		$output = join ',', map {
			my $foo = $event->$_;
			ref $foo || (defined $foo ? $foo : '_')
		} qw/ bubbles cancelable type relatedNode prevValue
		      newValue attrName attrChange /;
	})
	  for map "DOM$_", qw(SubtreeModified NodeInserted NodeRemoved
	                      NodeRemovedFromDocument
	                      NodeInsertedIntoDocument AttrModified
	                      CharacterDataModified);
	undef $output;
	$elem->trigger_event('DOMSubtreeModified');
	is $output,
	   "1,0,DOMSubtreeModified,_,_,_,_,_";

	undef $output;
	$elem->trigger_event('DOMNodeInserted');
	is $output,
	   "1,0,DOMNodeInserted,_,_,_,_,_";

	undef $output;
	$elem->trigger_event('DOMNodeRemoved');
	is $output,
	   "1,0,DOMNodeRemoved,_,_,_,_,_";

	undef $output;
	$elem->trigger_event('DOMNodeRemovedFromDocument');
	is $output,
	   "0,0,DOMNodeRemovedFromDocument,_,_,_,_,_";

	undef $output;
	$elem->trigger_event('DOMNodeInsertedIntoDocument');
	is $output,
	   "0,0,DOMNodeInsertedIntoDocument,_,_,_,_,_";

	undef $output;
	$elem->trigger_event('DOMAttrModified');
	is $output,
	   "1,0,DOMAttrModified,_,_,_,_,_";

	undef $output;
	$elem->trigger_event('DOMCharacterDataModified');
	is $output,
	   "1,0,DOMCharacterDataModified,_,_,_,_,_";

};

# -------------------------#

sub gimme_a_test_doc {
	my $doc = new HTML::DOM;
	$doc->write(
		'<html id=h>' .
		'<body id=b>' .
		'<div id=d1><p id=p11>a<p id=p12>a<p id=p13>a</div>' .
		'<div id=d2><p id=p21>a<p id=p22>a<p id=p23>a</div>' .
		'<div id=d3><p id=p31>a<p id=p32>a<p id=p33>a</div>'
	);
	$doc->close;
	my $scratch = [];
	for my$id(qw( h b d1 d2 d3 p11 p12 p13 p21 p22 p23 p31 p32 p33 )) {
		my $e = $doc->getElementById($id);
		$e->addEventListener($_ => sub {
			push @$scratch, "$id-".$_[0]->target->id."-"
				.lc$_[0]->type 
		})
			for qw(
				domsubtreemodified
				domnoderemovedfromdocument
				domnodeinsertedintodocument
			);

		# We need the evals around the $_[0]->foo->id things below,
		# because at one point I had events erroneously occurring,
		# with relatedNode set to undef.
		$e->addEventListener($_ => sub {
			push @$scratch,"$id-" . $_[0]->target->id ."-"
				. lc ($_[0]->type) . "-"
				. (eval{$_[0]->relatedNode->id}||'')
				.'-'.(eval{$_[0]->target->parent->id}||'')
		}) for qw ,domnodeinserted domnoderemoved,;
		$e->addEventListener(domattrmodified => sub {
			 no warnings 'uninitialized';
			push @$scratch, "$id-".$_[0]->target->id
			  ."-domattrmodified-".
			  (eval{
			    return join '',$_->name,$_->value
			      for $_[0]->relatedNode
			  }||'')."-".
			  $_[0]->target->hasAttribute($_[0]->attrName)."-".
			  join '-', map $_[0]->$_,
			    attrName=>attrChange=>prevValue=>newValue=>;
		});
		$e->addEventListener(domcharacterdatamodified => sub {
			push @$scratch, "$id-" .
			  (eval{$_[0]->target->id} ||
			    $_[0]->target->nodeName).
			  "-domcharacterdatamodified-".
			  join '-', map $_[0]->$_,
			    =>prevValue=>newValue=>;
		});	
	}
	$doc, $scratch;
}

# The basic order we have to test for is as follows. This is what happens
# when a node is moved from one tree to  another.  All  the  node-moving
# events, except attrmodified, follow the same order, but some steps may
# sometimes be skipped.
#	event: noderemoved (node itself)
#	event: noderemovedfromdocument (node and children)
#	actual removal
#	insertion
#	event: nodeinserted
#	event: nodeinsertedintodocument
#	event: subtreemodified (nearest common parent)

# The event handlers above push the following info on to @$scratch, joined
# with hypens:
#	current target id, target id or nodeName, event name
# possibly followed by more info based on the type of event:
#	nodeinserted/removed:  related node id, parent id
#	attrmodfied:           related node name and value,
#                                whether the attr exists, attr name,
#	                         change type, prev value, new value
#	characterdatamodified: -prev value-new value


# -------------------------#
use tests 6; # $node->insertBefore
{
	my($doc, $scratch) = gimme_a_test_doc;

	$doc->getElementById('d3')->insertBefore(
		map $doc->getElementById($_), 'p21', 'p33'
	);
	is_deeply $scratch, [
		'p21-p21-domnoderemoved-d2-d2' ,
		'd2-p21-domnoderemoved-d2-d2' ,
		'b-p21-domnoderemoved-d2-d2' ,
		'h-p21-domnoderemoved-d2-d2' ,

		'p21-p21-domnoderemovedfromdocument' ,

		'p21-p21-domnodeinserted-d3-d3' ,
		'd3-p21-domnodeinserted-d3-d3' ,
		'b-p21-domnodeinserted-d3-d3' ,
		'h-p21-domnodeinserted-d3-d3' ,

		'p21-p21-domnodeinsertedintodocument' ,

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,
	], "insertBefore transferring an item to it's uncle (same level)";

	@$scratch = ();

	$doc->getElementById('d2')->insertBefore(
		map $doc->getElementById($_), 'd1', 'p22'
	);
	is_deeply $scratch, [
		'd1-d1-domnoderemoved-b-b' ,
		'b-d1-domnoderemoved-b-b' ,
		'h-d1-domnoderemoved-b-b' ,

		'd1-d1-domnoderemovedfromdocument' ,
		'p11-p11-domnoderemovedfromdocument' ,
		'p12-p12-domnoderemovedfromdocument' ,
		'p13-p13-domnoderemovedfromdocument' ,

		'd1-d1-domnodeinserted-d2-d2' ,
		'd2-d1-domnodeinserted-d2-d2' ,
		'b-d1-domnodeinserted-d2-d2' ,
		'h-d1-domnodeinserted-d2-d2' ,

		'd1-d1-domnodeinsertedintodocument' ,
		'p11-p11-domnodeinsertedintodocument' ,
		'p12-p12-domnodeinsertedintodocument' ,
		'p13-p13-domnodeinsertedintodocument' ,

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,
	], "insertBefore transferring an item to it's nephew (down)";

	@$scratch = ();

	$doc->body->insertBefore(
		map $doc->getElementById($_), 'd1', 'd2'
	);
	is_deeply $scratch, [
		'd1-d1-domnoderemoved-d2-d2' ,
		'd2-d1-domnoderemoved-d2-d2' ,
		'b-d1-domnoderemoved-d2-d2' ,
		'h-d1-domnoderemoved-d2-d2' ,

		'd1-d1-domnoderemovedfromdocument' ,
		'p11-p11-domnoderemovedfromdocument' ,
		'p12-p12-domnoderemovedfromdocument' ,
		'p13-p13-domnoderemovedfromdocument' ,

		'd1-d1-domnodeinserted-b-b' ,
		'b-d1-domnodeinserted-b-b' ,
		'h-d1-domnodeinserted-b-b' ,

		'd1-d1-domnodeinsertedintodocument' ,
		'p11-p11-domnodeinsertedintodocument' ,
		'p12-p12-domnodeinsertedintodocument' ,
		'p13-p13-domnodeinsertedintodocument' ,

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,
	], "insertBefore transferring an item to it's grandparent (up)";


	my $foo = $doc->body->removeChild($doc->getElementById('d3'));

	@$scratch = ();

	$foo->insertBefore($doc->getElementById('d1'));
	is_deeply $scratch, [
		'd1-d1-domnoderemoved-b-b' ,
		'b-d1-domnoderemoved-b-b' ,
		'h-d1-domnoderemoved-b-b' ,

		'd1-d1-domnoderemovedfromdocument' ,
		'p11-p11-domnoderemovedfromdocument' ,
		'p12-p12-domnoderemovedfromdocument' ,
		'p13-p13-domnoderemovedfromdocument' ,

		'd1-d1-domnodeinserted-d3-d3' ,
		'd3-d1-domnodeinserted-d3-d3' ,

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,

		'd3-d3-domsubtreemodified',
	], "insertBefore transferring to an unrelated tree";

	@$scratch = ();

	$doc->body->insertBefore(
		$foo->lastChild, $doc->getElementById('d2')
	);
	is_deeply $scratch, [
		'd1-d1-domnoderemoved-d3-d3' ,
		'd3-d1-domnoderemoved-d3-d3' ,

		'd1-d1-domnodeinserted-b-b' ,
		'b-d1-domnodeinserted-b-b' ,
		'h-d1-domnodeinserted-b-b' ,

		'd1-d1-domnodeinsertedintodocument' ,
		'p11-p11-domnodeinsertedintodocument' ,
		'p12-p12-domnodeinsertedintodocument' ,
		'p13-p13-domnodeinsertedintodocument' ,

		'd3-d3-domsubtreemodified',

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,
	], "insertBefore transferring from an unrelated tree";

	$foo = $doc->body->removeChild($doc->getElementById('d1'));
	@$scratch = ();
	
	$doc->body->insertBefore(
		$foo
	);
	is_deeply $scratch, [
		'd1-d1-domnodeinserted-b-b' ,
		'b-d1-domnodeinserted-b-b' ,
		'h-d1-domnodeinserted-b-b' ,

		'd1-d1-domnodeinsertedintodocument' ,
		'p11-p11-domnodeinsertedintodocument' ,
		'p12-p12-domnodeinsertedintodocument' ,
		'p13-p13-domnodeinsertedintodocument' ,

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,
	], "insertBefore just inserting";
}

# -------------------------#
use tests 6; # $node->replaceChild
{
	my($doc, $scratch) = gimme_a_test_doc;

	$doc->getElementById('d3')->replaceChild(
		map $doc->getElementById($_), 'p21', 'p33'
	);
	is_deeply $scratch, [
		'p33-p33-domnoderemoved-d3-d3' ,
		'd3-p33-domnoderemoved-d3-d3' ,
		'b-p33-domnoderemoved-d3-d3' ,
		'h-p33-domnoderemoved-d3-d3' ,

		'p33-p33-domnoderemovedfromdocument',

		'p21-p21-domnoderemoved-d2-d2' ,
		'd2-p21-domnoderemoved-d2-d2' ,
		'b-p21-domnoderemoved-d2-d2' ,
		'h-p21-domnoderemoved-d2-d2' ,

		'p21-p21-domnoderemovedfromdocument' ,

		'p21-p21-domnodeinserted-d3-d3' ,
		'd3-p21-domnodeinserted-d3-d3' ,
		'b-p21-domnodeinserted-d3-d3' ,
		'h-p21-domnodeinserted-d3-d3' ,

		'p21-p21-domnodeinsertedintodocument' ,

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,
	], "replaceChild transferring an item to it's uncle (same level)";

	@$scratch = ();

	$doc->getElementById('d2')->replaceChild(
		map $doc->getElementById($_), 'd1', 'p22'
	);
	is_deeply $scratch, [
		'p22-p22-domnoderemoved-d2-d2' ,
		'd2-p22-domnoderemoved-d2-d2' ,
		'b-p22-domnoderemoved-d2-d2' ,
		'h-p22-domnoderemoved-d2-d2' ,

		'p22-p22-domnoderemovedfromdocument',

		'd1-d1-domnoderemoved-b-b' ,
		'b-d1-domnoderemoved-b-b' ,
		'h-d1-domnoderemoved-b-b' ,

		'd1-d1-domnoderemovedfromdocument' ,
		'p11-p11-domnoderemovedfromdocument' ,
		'p12-p12-domnoderemovedfromdocument' ,
		'p13-p13-domnoderemovedfromdocument' ,

		'd1-d1-domnodeinserted-d2-d2' ,
		'd2-d1-domnodeinserted-d2-d2' ,
		'b-d1-domnodeinserted-d2-d2' ,
		'h-d1-domnodeinserted-d2-d2' ,

		'd1-d1-domnodeinsertedintodocument' ,
		'p11-p11-domnodeinsertedintodocument' ,
		'p12-p12-domnodeinsertedintodocument' ,
		'p13-p13-domnodeinsertedintodocument' ,

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,
	], "replaceChild transferring an item to it's nephew (down)";

	@$scratch = ();

	my $d2 = $doc->body->replaceChild(
		map $doc->getElementById($_), 'd1', 'd2'
	);
	is_deeply $scratch, [
		'd2-d2-domnoderemoved-b-b' ,
		'b-d2-domnoderemoved-b-b' ,
		'h-d2-domnoderemoved-b-b' ,

		'd2-d2-domnoderemovedfromdocument' ,
		'd1-d1-domnoderemovedfromdocument' ,
		'p11-p11-domnoderemovedfromdocument' ,
		'p12-p12-domnoderemovedfromdocument' ,
		'p13-p13-domnoderemovedfromdocument' ,
		'p23-p23-domnoderemovedfromdocument' ,

		'd1-d1-domnoderemoved-d2-d2' ,
		'd2-d1-domnoderemoved-d2-d2' ,
		'b-d1-domnoderemoved-d2-d2' ,
		'h-d1-domnoderemoved-d2-d2' ,

		'd1-d1-domnodeinserted-b-b' ,
		'b-d1-domnodeinserted-b-b' ,
		'h-d1-domnodeinserted-b-b' ,

		'd1-d1-domnodeinsertedintodocument' ,
		'p11-p11-domnodeinsertedintodocument' ,
		'p12-p12-domnodeinsertedintodocument' ,
		'p13-p13-domnodeinsertedintodocument' ,

		'd2-d2-domsubtreemodified',

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,
	], "replaceChild transferring an item to it's grandparent (up)";


	my $foo = $doc->body->removeChild($doc->getElementById('d3'));

	@$scratch = ();

	$foo->replaceChild($doc->getElementById('d1'), $foo->firstChild);
	is_deeply $scratch, [
		'p31-p31-domnoderemoved-d3-d3' ,
		'd3-p31-domnoderemoved-d3-d3' ,

		'd1-d1-domnoderemoved-b-b' ,
		'b-d1-domnoderemoved-b-b' ,
		'h-d1-domnoderemoved-b-b' ,

		'd1-d1-domnoderemovedfromdocument' ,
		'p11-p11-domnoderemovedfromdocument' ,
		'p12-p12-domnoderemovedfromdocument' ,
		'p13-p13-domnoderemovedfromdocument' ,

		'd1-d1-domnodeinserted-d3-d3' ,
		'd3-d1-domnodeinserted-d3-d3' ,

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,

		'd3-d3-domsubtreemodified',
	], "replaceChild transferring to an unrelated tree";

	$doc->body->appendChild($d2);
	@$scratch = ();
	$doc->body->replaceChild(
		$foo->firstChild, $d2
	);
	is_deeply $scratch, [
		'd2-d2-domnoderemoved-b-b' ,
		'b-d2-domnoderemoved-b-b' ,
		'h-d2-domnoderemoved-b-b' ,

		'd2-d2-domnoderemovedfromdocument' ,
		'p23-p23-domnoderemovedfromdocument' ,

		'd1-d1-domnoderemoved-d3-d3' ,
		'd3-d1-domnoderemoved-d3-d3' ,

		'd1-d1-domnodeinserted-b-b' ,
		'b-d1-domnodeinserted-b-b' ,
		'h-d1-domnodeinserted-b-b' ,

		'd1-d1-domnodeinsertedintodocument' ,
		'p11-p11-domnodeinsertedintodocument' ,
		'p12-p12-domnodeinsertedintodocument' ,
		'p13-p13-domnodeinsertedintodocument' ,

		'd3-d3-domsubtreemodified',

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,
	], "replaceChild transferring from an unrelated tree";

	$foo = $doc->body->removeChild($doc->getElementById('d1'));
	$doc->body->appendChild($d2);
	@$scratch = ();
	
	$doc->body->replaceChild(
		$foo, $d2
	);
	is_deeply $scratch, [
		'd2-d2-domnoderemoved-b-b' ,
		'b-d2-domnoderemoved-b-b' ,
		'h-d2-domnoderemoved-b-b' ,

		'd2-d2-domnoderemovedfromdocument' ,
		'p23-p23-domnoderemovedfromdocument' ,

		'd1-d1-domnodeinserted-b-b' ,
		'b-d1-domnodeinserted-b-b' ,
		'h-d1-domnodeinserted-b-b' ,

		'd1-d1-domnodeinsertedintodocument' ,
		'p11-p11-domnodeinsertedintodocument' ,
		'p12-p12-domnodeinsertedintodocument' ,
		'p13-p13-domnodeinsertedintodocument' ,

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,
	], "replaceChild inserting an orphaned node";
}

# -------------------------#
use tests 2; # $node->removeChild
{
	my($doc, $scratch) = gimme_a_test_doc;

	my $d3 = $doc->body->removeChild(
		$doc->getElementById('d3')
	);
	is_deeply $scratch, [
		'd3-d3-domnoderemoved-b-b' ,
		'b-d3-domnoderemoved-b-b' ,
		'h-d3-domnoderemoved-b-b' ,

		'd3-d3-domnoderemovedfromdocument' ,
		'p31-p31-domnoderemovedfromdocument' ,
		'p32-p32-domnoderemovedfromdocument' ,
		'p33-p33-domnoderemovedfromdocument' ,

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,
	], "removeChild removing items from the document";

	$d3->appendChild($doc->getElementById('d1'))
	;@$scratch = ();

	$d3->removeChild($d3->lastChild);
	is_deeply $scratch, [
		'd1-d1-domnoderemoved-d3-d3' ,
		'd3-d1-domnoderemoved-d3-d3' ,

		'd3-d3-domsubtreemodified' ,
	], "removeChild removing an item from a node outside the doc";
}


# -------------------------#
use tests 6; # $node->appendChild
{
	my($doc, $scratch) = gimme_a_test_doc;

	$doc->getElementById('d3')->appendChild(
		$doc->getElementById('p21')
	);
	is_deeply $scratch, [
		'p21-p21-domnoderemoved-d2-d2' ,
		'd2-p21-domnoderemoved-d2-d2' ,
		'b-p21-domnoderemoved-d2-d2' ,
		'h-p21-domnoderemoved-d2-d2' ,

		'p21-p21-domnoderemovedfromdocument' ,

		'p21-p21-domnodeinserted-d3-d3' ,
		'd3-p21-domnodeinserted-d3-d3' ,
		'b-p21-domnodeinserted-d3-d3' ,
		'h-p21-domnodeinserted-d3-d3' ,

		'p21-p21-domnodeinsertedintodocument' ,

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,
	], "appendChild transferring an item to it's uncle (same level)";

	@$scratch = ();

	$doc->getElementById('d2')->appendChild(
		$doc->getElementById('d1')
	);
	is_deeply $scratch, [
		'd1-d1-domnoderemoved-b-b' ,
		'b-d1-domnoderemoved-b-b' ,
		'h-d1-domnoderemoved-b-b' ,

		'd1-d1-domnoderemovedfromdocument' ,
		'p11-p11-domnoderemovedfromdocument' ,
		'p12-p12-domnoderemovedfromdocument' ,
		'p13-p13-domnoderemovedfromdocument' ,

		'd1-d1-domnodeinserted-d2-d2' ,
		'd2-d1-domnodeinserted-d2-d2' ,
		'b-d1-domnodeinserted-d2-d2' ,
		'h-d1-domnodeinserted-d2-d2' ,

		'd1-d1-domnodeinsertedintodocument' ,
		'p11-p11-domnodeinsertedintodocument' ,
		'p12-p12-domnodeinsertedintodocument' ,
		'p13-p13-domnodeinsertedintodocument' ,

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,
	], "appendChild transferring an item to it's nephew (down)";

	@$scratch = ();

	$doc->body->appendChild(
		$doc->getElementById('d1')
	);
	is_deeply $scratch, [
		'd1-d1-domnoderemoved-d2-d2' ,
		'd2-d1-domnoderemoved-d2-d2' ,
		'b-d1-domnoderemoved-d2-d2' ,
		'h-d1-domnoderemoved-d2-d2' ,

		'd1-d1-domnoderemovedfromdocument' ,
		'p11-p11-domnoderemovedfromdocument' ,
		'p12-p12-domnoderemovedfromdocument' ,
		'p13-p13-domnoderemovedfromdocument' ,

		'd1-d1-domnodeinserted-b-b' ,
		'b-d1-domnodeinserted-b-b' ,
		'h-d1-domnodeinserted-b-b' ,

		'd1-d1-domnodeinsertedintodocument' ,
		'p11-p11-domnodeinsertedintodocument' ,
		'p12-p12-domnodeinsertedintodocument' ,
		'p13-p13-domnodeinsertedintodocument' ,

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,
	], "appendChild transferring an item to it's grandparent (up)";


	my $foo = $doc->body->removeChild($doc->getElementById('d3'));

	@$scratch = ();

	$foo->appendChild($doc->getElementById('d1'));
	is_deeply $scratch, [
		'd1-d1-domnoderemoved-b-b' ,
		'b-d1-domnoderemoved-b-b' ,
		'h-d1-domnoderemoved-b-b' ,

		'd1-d1-domnoderemovedfromdocument' ,
		'p11-p11-domnoderemovedfromdocument' ,
		'p12-p12-domnoderemovedfromdocument' ,
		'p13-p13-domnoderemovedfromdocument' ,

		'd1-d1-domnodeinserted-d3-d3' ,
		'd3-d1-domnodeinserted-d3-d3' ,

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,

		'd3-d3-domsubtreemodified',
	], "appendChild transferring to an unrelated tree";

	@$scratch = ();

	$doc->body->appendChild(
		$foo->lastChild
	);
	is_deeply $scratch, [
		'd1-d1-domnoderemoved-d3-d3' ,
		'd3-d1-domnoderemoved-d3-d3' ,

		'd1-d1-domnodeinserted-b-b' ,
		'b-d1-domnodeinserted-b-b' ,
		'h-d1-domnodeinserted-b-b' ,

		'd1-d1-domnodeinsertedintodocument' ,
		'p11-p11-domnodeinsertedintodocument' ,
		'p12-p12-domnodeinsertedintodocument' ,
		'p13-p13-domnodeinsertedintodocument' ,

		'd3-d3-domsubtreemodified',

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,
	], "appendChild transferring from an unrelated tree";

	$foo = $doc->body->removeChild($doc->getElementById('d1'));
	@$scratch = ();
	
	$doc->body->appendChild(
		$foo
	);
	is_deeply $scratch, [
		'd1-d1-domnodeinserted-b-b' ,
		'b-d1-domnodeinserted-b-b' ,
		'h-d1-domnodeinserted-b-b' ,

		'd1-d1-domnodeinsertedintodocument' ,
		'p11-p11-domnodeinsertedintodocument' ,
		'p12-p12-domnodeinsertedintodocument' ,
		'p13-p13-domnodeinsertedintodocument' ,

		'b-b-domsubtreemodified' ,
		'h-b-domsubtreemodified' ,
	], "appendChild just inserting";
}


# -------------------------#
use tests 9; # Element attribute mutations
{
	my($doc, $scratch) = gimme_a_test_doc;
	my $div = $doc->getElementById('d1');

	$div->setAttribute("foo","bar");
	is_deeply $scratch, [
		'd1-d1-domattrmodified-foobar-1-foo-2--bar' ,
		'b-d1-domattrmodified-foobar-1-foo-2--bar' ,
		'h-d1-domattrmodified-foobar-1-foo-2--bar' ,
	], 'setAttribute when the attr doesn\'t exist';

	@$scratch = ();

	# The presence of event listeners causes attr nodes to be autovivi-
	# fied by events, so we need to reset it in order to test the right
	# code path.
	$div->attr("foo","bar");
	$div->setAttribute("foo","barr");
	is_deeply $scratch, [
		'd1-d1-domattrmodified-foobarr-1-foo-1-bar-barr' ,
		'b-d1-domattrmodified-foobarr-1-foo-1-bar-barr' ,
		'h-d1-domattrmodified-foobarr-1-foo-1-bar-barr' ,
	], 'setAttribute when the attr exists';

	@$scratch = ();

	$div->attr("foo","barr");
	$div->removeAttribute("foo");
	is_deeply $scratch, [
		'd1-d1-domattrmodified-foobarr--foo-3-barr-barr' ,
		'b-d1-domattrmodified-foobarr--foo-3-barr-barr' ,
		'h-d1-domattrmodified-foobarr--foo-3-barr-barr' ,
	], 'removeAttribute when the attr exists';

	@$scratch = ();

	$div->removeAttribute("foo");
	is_deeply $scratch, [
	], 'removeAttribute when the attr existeth not';

	$div->attr("foo","barr");	
	$div->getAttributeNode('foo');
	$div->removeAttribute("foo");
	is_deeply $scratch, [
		'd1-d1-domattrmodified-foobarr--foo-3-barr-barr' ,
		'b-d1-domattrmodified-foobarr--foo-3-barr-barr' ,
		'h-d1-domattrmodified-foobarr--foo-3-barr-barr' ,
	], 'removeAttribute when the attr exists & is an auto-vivved node';

	@$scratch = ();

	my $attr = $doc->createAttribute('foo');;
	$attr->value('bar');	
	$div->setAttributeNode($attr);
	is_deeply $scratch, [
		'd1-d1-domattrmodified-foobar-1-foo-2-bar-bar' ,
		'b-d1-domattrmodified-foobar-1-foo-2-bar-bar' ,
		'h-d1-domattrmodified-foobar-1-foo-2-bar-bar' ,
	], 'setAttributeNode when the attribute doesn\'t exist';

	@$scratch = ();

	$attr = $doc->createAttribute('foo');;
	$attr->value('barr');	
	$div->setAttributeNode($attr);
	is_deeply $scratch, [
		'd1-d1-domattrmodified-foobar-1-foo-3-bar-bar' ,
		'b-d1-domattrmodified-foobar-1-foo-3-bar-bar' ,
		'h-d1-domattrmodified-foobar-1-foo-3-bar-bar' ,

		'd1-d1-domattrmodified-foobarr-1-foo-2-barr-barr' ,
		'b-d1-domattrmodified-foobarr-1-foo-2-barr-barr' ,
		'h-d1-domattrmodified-foobarr-1-foo-2-barr-barr' ,
	], 'setAttributeNode when the attribute exists';

	@$scratch = ();

	$div->removeAttributeNode($attr);
	is_deeply $scratch, [
		'd1-d1-domattrmodified-foobarr--foo-3-barr-barr' ,
		'b-d1-domattrmodified-foobarr--foo-3-barr-barr' ,
		'h-d1-domattrmodified-foobarr--foo-3-barr-barr' ,
	], 'removeAttributeNode when the attr exists';

	$div->setAttributeNode($attr);
	@$scratch = ();

	$attr->value("onettn");
	is_deeply $scratch, [
		'd1-d1-domattrmodified-fooonettn-1-foo-1-barr-onettn' ,
		'b-d1-domattrmodified-fooonettn-1-foo-1-barr-onettn' ,
		'h-d1-domattrmodified-fooonettn-1-foo-1-barr-onettn' ,
	], 'modification of an attr node directly';
	

	# ~~~ All the shorthand HTML properties.
}


# -------------------------#
use tests 8; # Character data mutations
{
	my($doc, $scratch) = gimme_a_test_doc;
	my $node = $doc->getElementById('p11')->firstChild;

	$node->data("stuff");
	is_deeply $scratch, [
		'p11-#text-domcharacterdatamodified-a-stuff' ,
		'd1-#text-domcharacterdatamodified-a-stuff' ,
		'b-#text-domcharacterdatamodified-a-stuff' ,
		'h-#text-domcharacterdatamodified-a-stuff' ,
	], 'data';

	@$scratch = ();

	$node->appendData("ing");
	is_deeply $scratch, [
		'p11-#text-domcharacterdatamodified-stuff-stuffing' ,
		'd1-#text-domcharacterdatamodified-stuff-stuffing' ,
		'b-#text-domcharacterdatamodified-stuff-stuffing' ,
		'h-#text-domcharacterdatamodified-stuff-stuffing' ,
	], 'appendData';

	@$scratch = ();

	$node->insertData(5,"er");
	is_deeply $scratch, [
		'p11-#text-domcharacterdatamodified-stuffing-stuffering' ,
		'd1-#text-domcharacterdatamodified-stuffing-stuffering' ,
		'b-#text-domcharacterdatamodified-stuffing-stuffering' ,
		'h-#text-domcharacterdatamodified-stuffing-stuffering' ,
	], 'insertData';

	@$scratch = ();

	$node->insertData16(5,"er");
	is_deeply $scratch, [
	  'p11-#text-domcharacterdatamodified-stuffering-stufferering' ,
	  'd1-#text-domcharacterdatamodified-stuffering-stufferering' ,
	  'b-#text-domcharacterdatamodified-stuffering-stufferering' ,
	  'h-#text-domcharacterdatamodified-stuffering-stufferering' ,
	], 'insertData16';

	@$scratch = ();

	$node->deleteData(5,2);
	is_deeply $scratch, [
	  'p11-#text-domcharacterdatamodified-stufferering-stuffering' ,
	  'd1-#text-domcharacterdatamodified-stufferering-stuffering' ,
	  'b-#text-domcharacterdatamodified-stufferering-stuffering' ,
	  'h-#text-domcharacterdatamodified-stufferering-stuffering' ,
	], 'appendData';

	@$scratch = ();

	$node-> deleteData16(1,1);
	is_deeply $scratch, [
		'p11-#text-domcharacterdatamodified-stuffering-suffering' ,
		'd1-#text-domcharacterdatamodified-stuffering-suffering' ,
		'b-#text-domcharacterdatamodified-stuffering-suffering' ,
		'h-#text-domcharacterdatamodified-stuffering-suffering' ,
	], 'deleteData16';

	@$scratch = ();

	$node->replaceData(4,5,'olk');
	is_deeply $scratch, [
		'p11-#text-domcharacterdatamodified-suffering-suffolk' ,
		'd1-#text-domcharacterdatamodified-suffering-suffolk' ,
		'b-#text-domcharacterdatamodified-suffering-suffolk' ,
		'h-#text-domcharacterdatamodified-suffering-suffolk' ,
	], 'replaceData';

	@$scratch = ();

	$node->replaceData16(0,1,"S");
	is_deeply $scratch, [
		'p11-#text-domcharacterdatamodified-suffolk-Suffolk' ,
		'd1-#text-domcharacterdatamodified-suffolk-Suffolk' ,
		'b-#text-domcharacterdatamodified-suffolk-Suffolk' ,
		'h-#text-domcharacterdatamodified-suffolk-Suffolk' ,
	], 'replaceData16';
}

# -------------------------#
use tests 8; # Mutations affecting Attr nodes
{
	my($doc, $scratch) = gimme_a_test_doc;
	my $div = $doc->getElementById('d1');

	$div->setAttribute("foo","barr"); # We want an attribute that
	                                  # already exists;
	@$scratch = ();

	my $attr = $div->getAttributeNode('foo');
	$attr->addEventListener('DOMCharacterDataModified' => sub {
		my $event = shift;
		push @$scratch, join '-', 
			$event->currentTarget->name,
			$event->target->nodeName,
			lc $event->type,
	});
	$attr->addEventListener($_ => sub {
		my $event = shift;
		push @$scratch, join '-', 
			$event->currentTarget->name,
			$event->target->nodeName,
			lc $event->type,
	}) for qw/ DOMNodeInserted DOMNodeInsertedIntoDocument
	           DOMNodeRemoved  DOMNodeRemovedFromDocument
	           DOMSubtreeModified /;

	$attr->value("barr");
	is_deeply $scratch, [
	], 'attr->value(...) the same as the existing value';

	$attr->nodeValue("barr");
	is_deeply $scratch, [
	], 'attr->nodeValue(...) the same as the existing value';

	$attr->value("barrel");
	is_deeply $scratch, [
		'foo-#text-domcharacterdatamodified' ,
		'd1-d1-domattrmodified-foobarrel-1-foo-1-barr-barrel' ,
		'b-d1-domattrmodified-foobarrel-1-foo-1-barr-barrel' ,
		'h-d1-domattrmodified-foobarrel-1-foo-1-barr-barrel' ,
	], 'attr->value(new_value)';

	@$scratch = ();

	$attr->nodeValue("d barrel");
	is_deeply $scratch, [
	  'foo-#text-domcharacterdatamodified' ,
	  'd1-d1-domattrmodified-food barrel-1-foo-1-barrel-d barrel' ,
	  'b-d1-domattrmodified-food barrel-1-foo-1-barrel-d barrel' ,
	  'h-d1-domattrmodified-food barrel-1-foo-1-barrel-d barrel' ,
	], 'attr->nodeValue(new)';

	@$scratch = ();

	$attr->firstChild->data("foo");
	is_deeply $scratch, [
	  'foo-#text-domcharacterdatamodified' ,
	  'd1-d1-domattrmodified-foofoo-1-foo-1-d barrel-foo' ,
	  'b-d1-domattrmodified-foofoo-1-foo-1-d barrel-foo' ,
	  'h-d1-domattrmodified-foofoo-1-foo-1-d barrel-foo' ,
	], 'direct modification of the text node';

	@$scratch = ();

	my $tn1 = $attr->firstChild,
	my $tn2 = $doc->createTextNode('led');
	for my $n($tn1, $tn2) {
		$n->addEventListener($_=>sub{
			push@$scratch,(lc shift->type)
		}) for map "domnode${_}document",
			'insertedinto', 'removedfrom'
	}

	$attr->replaceChild($tn2,$tn1);
	is_deeply $scratch, [
	  'foo-#text-domnoderemoved' ,
	  'domnoderemovedfromdocument' ,
	  'foo-#text-domnodeinserted' ,
	  'domnodeinsertedintodocument' ,
	  'foo-foo-domsubtreemodified',
	  'd1-d1-domattrmodified-fooled-1-foo-1-foo-led' ,
	  'b-d1-domattrmodified-fooled-1-foo-1-foo-led' ,
	  'h-d1-domattrmodified-fooled-1-foo-1-foo-led' ,
	], 'attr->replaceChild still attached to the doc';

	$div->detach;

	@$scratch = ();

	$attr->replaceChild($tn1,$tn2);
	is_deeply $scratch, [
	  'foo-#text-domnoderemoved' ,
	  'foo-#text-domnodeinserted' ,
	  'foo-foo-domsubtreemodified',
	  'd1-d1-domattrmodified-foofoo-1-foo-1-led-foo' ,
	], 'attr->replaceChild with its elem detached';

	$doc->body->push_content($div);
	$div->removeAttribute('foo');
	@$scratch = ();

	$attr->replaceChild($tn2,$tn1);
	is_deeply $scratch, [
	  'foo-#text-domnoderemoved' ,
	  'foo-#text-domnodeinserted' ,
	  'foo-foo-domsubtreemodified',
	], 'attr->replaceChild, the attr itself detached';

	# ~~~ need a test for moving a text node that is in use on to the
	#     attr
}

# -------------------------#
use tests 3; # Default event handlers triggered by mutation events
             # (there’s special handling for this case [auto-vivacious
{            # events] in EventTarget.pm/trigger_event)
	my $doc = new HTML::DOM; $doc->open;
	my $e;
	$doc->default_event_handler(sub { $e = shift });

	$doc->body->setAttribute("foo","bar");

	isa_ok $e, 'HTML::DOM::Event',
		'event auto-vivved solely for deh’s sake';
	is $e->target, $doc->body, 'target is set correctly';
	is $e->type, 'DOMAttrModified', 'type is set correctly';
}

# -------------------------#
use tests 444; # MutationEvents caused by DOM Level 0 attribute attributes
{
	my $doc = new HTML::DOM;

	my %attrnames = # for where the method differs from the attrname
	qw(
		className       class
		httpEquiv       http-equiv
		acceptCharset   accept-charset
		defaultSelected selected
		defaultValue    value
		htmlFor         for
		ch              char
		chOff           charoff
		defaultChecked  checked
	);
	my %booleans = map +($_=>1), # boolean attributes
	qw< disabled multiple defaultSelected readOnly isMap
	    defaultChecked compact noShade declare defer noWrap noResize >;

	for(
		[span     => qw[ id title lang dir className ]],
		[html     => qw[ version ]],
		[head     => qw[ profile ]],
		[link     => qw[ charset href hreflang media rel rev target
		                 type ]],
		[meta     => qw[ content name scheme httpEquiv ]],
		[base     => qw[ href target ]],
		[isindex  => qw[ prompt ]],
		[style    => qw[ media type ]],
		[body     => qw[ aLink background bgColor link text
		                 vLink ]],
		[form     => qw[ name action enctype method target
		                 acceptCharset]],
		[select   => qw[ name size tabIndex ]],
		[optgroup => qw[ label ]],
		[option   => qw[ label ]],
		[input    => qw[ accept accessKey align alt maxLength name
		                 size src tabIndex type useMap ]],
		[textarea => qw[ accessKey cols name rows tabIndex ]],
		[button   => qw[ accessKey name tabIndex ]],
		[label    => qw[ accessKey htmlFor ]],
		[legend   => qw[ accessKey align ]],
		[ul       => qw[ type ]],
		[ol       => qw[ start type ]],
		[li       => qw[ type value ]],
		[div      => qw[ align ]],
		[p        => qw[ align ]],
		[h1       => qw[ align ]],
		[q        => qw[ cite ]],
		[pre      => qw[ width ]],
		[br       => qw[ clear ]],
		[basefont => qw[ color face size ]],
		[font     => qw[ color face size ]],
		[hr       => qw[ align size width ]],
		[ins      => qw[ cite dateTime ]],
		[a        => qw[ accessKey charset coords href hreflang
		                 name rel rev shape tabIndex target
		                 type ]],
		[img      => qw[ name align alt border height hspace isMap
		                 longDesc src useMap vspace width ]],
		[object   => qw[ code align archive border codeBase
		                 codeType data height hspace name standby
		                 tabIndex type useMap vspace width ]],
		[param    => qw[ name type value valueType ]],
		[applet   => qw[ align alt archive code codeBase height
		                 hspace name object vspace width ]],
		[map      => qw[ name ]],
		[area     => qw[ accessKey alt coords href shape tabIndex
		                 target ]],
		[script   => qw[ event charset src type htmlFor ]],
		[table    => qw[ align bgColor border cellPadding
		                 cellSpacing frame rules summary width ]],
		[caption  => qw[ align ]],
		[col      => qw[ align span vAlign width ch chOff ]],
		[tbody    => qw[ align vAlign ch chOff ]],
		[tr       => qw[ align bgColor vAlign ch chOff ]],
		[td       => qw[ abbr align axis bgColor colSpan headers
		                 height rowSpan scope vAlign width
		                 ch chOff ]],
		[frameset => qw[ cols rows ]],
		[frame    => qw[ frameBorder longDesc marginHeight
		                 marginWidth name scrolling src ]],
		[iframe   => qw[ align frameBorder height longDesc
		                 marginHeight marginWidth name scrolling
		                 src width ]],
		[select   => qw[ disabled multiple ]],
		[optgroup => qw[ disabled ]],
		[option   => qw[ disabled defaultSelected ]],
		[input    => qw[ disabled readOnly defaultValue
		                 defaultChecked]],
		[textarea => qw[ disabled readOnly ]],
		[button   => qw[ disabled ]],
		[ul       => qw[ compact ]],
		[ol       => qw[ compact ]],
		[dl       => qw[ compact ]],
		[dir      => qw[ compact ]],
		[menu     => qw[ compact ]],
		[hr       => qw[ noShade ]],
		[object   => qw[ declare ]],
		[script   => qw[ defer ]],
		[td       => qw[ noWrap ]],
		[frame    => qw[ noResize ]],
	) {
		my $e = $doc->createElement(my $tag = shift @$_);

		my @scratch;
		# copied and pasted from gimme_a_test_doc (and tweaked):
		$e->addEventListener(domattrmodified => sub {
			 no warnings 'uninitialized';
			push @scratch, 
			  (eval{
			    return join '',$_->name,$_->value
			      for $_[0]->relatedNode
			  }||'')."-".
			  $_[0]->target->hasAttribute($_[0]->attrName)."-".
			  join '-', map lc $_[0]->$_,
			    attrName=>attrChange=>prevValue=>newValue=>;
		});
		
		for my $attr_m( @$_ ) {
			# attr_m == attribute method; _n == name
			my $attr_n = $attrnames{$attr_m} || lc $attr_m;
			my $is_bool = $booleans{$attr_m};
			@scratch = ();
			eval { $e->$attr_m("foo");}; $@ and (warn tag $e),die;
# Test right here --------
			my $testval = $is_bool ? $attr_n : 'foo';
			is_deeply \@scratch, [
			  "${attr_n}$testval-1-$attr_n-2--$testval" ,
			], "$tag elem  ->$attr_m(foo) creating the attr";
			next if $is_bool; # The next test doesn’t apply to
			@scratch = ();    # boolean attrs.
			$e->$attr_m("bar");
# A second test right here --
			is_deeply \@scratch, [
			 "${attr_n}bar-1-$attr_n-1-foo-bar" ,
			], "$tag elem  ->$attr_m(bar) changing the attr";
		}
	}



}
