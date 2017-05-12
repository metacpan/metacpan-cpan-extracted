#!/usr/bin/perl -T

use strict; use warnings; no warnings qw 'utf8 parenthesis'; use lib 't';

use lib 't';
use HTML::DOM;

my $doc = new HTML::DOM;
require HTML::DOM::View;
$doc->defaultView(my $v = bless[], HTML::DOM::View::);
my $event = $doc->createEvent('MouseEvents');

# -------------------------#
use tests 24; # initMouseEvent

is $event->screenX, undef, 'screenX before init';
is $event->screenY, undef, 'screenY before init';
is $event->clientX, undef, 'clientX before init';
is $event->clientY, undef, 'clientY before init';
is $event->ctrlKey, undef, 'ctrl before init';
is $event->shiftKey, undef, 'shift before init';
is $event->altKey, undef, 'alt before init';
is $event->metaKey, undef, 'meta before init';

my $foo = bless[];
is_deeply [initMouseEvent $event mouseover => 1, 1,$doc->defaultView,2,3,4,
	5,6,1,1,1,1,2,$foo], [],
	'initMouseEvent returns nothing';

ok bubbles $event, 'event is bubbly after init*Event';
ok cancelable $event, 'event is cancelable after init*Event';
is $event->type, 'mouseover', 'event type after init*Event';
is $event->view, $doc->defaultView, 'view after init*Event';
is $event->detail, 2, 'detail after init*Event';
is $event->screenX, 3, 'screenX after init*Event';
is $event->screenY, 4, 'screenY after init*Event';
is $event->clientX, 5, 'clientX after init*Event';
is $event->clientY, 6, 'clientY after init*Event';
ok $event->ctrlKey,, 'ctrl after init*Event';
ok $event->shiftKey,, 'shift after init*Event';
ok $event->altKey,, 'alt after init*Event';
ok $event->metaKey,, 'meta after init*Event';
is $event->button, 2, 'button after init*Event';
is $event->relatedTarget, $foo, 'relatedTarget after init*Event';

# -------------------------#
use tests 15; # init

$event=  $doc->createEvent('MouseEvents');

init $event
	type => 'mouseover',
	propagates_up => 1,
	cancellable => 1,
	view => $doc->defaultView,
	screen_x => 3, screen_y=>4,client_x=>5,
	client_y=>6,detail=>2,ctrl=>1,shift=>1,alt=>1,meta=>1,button=>2,
	rel_target=>$foo
;

ok bubbles $event, 'event is bubbly after init';
ok cancelable $event, 'event is cancelable after init';
is $event->type, 'mouseover', 'event type after init';
is $event->view, $doc->defaultView, 'view after init';
is $event->detail, 2, 'detail after init';
is $event->screenX, 3, 'screenX after init';
is $event->screenY, 4, 'screenY after init';
is $event->clientX, 5, 'clientX after init';
is $event->clientY, 6, 'clientY after init';
ok $event->ctrlKey,, 'ctrl after init';
ok $event->shiftKey,, 'shift after init';
ok $event->altKey,, 'alt after init';
ok $event->metaKey,, 'meta after init';
is $event->button, 2, 'button after init';
is $event->relatedTarget, $foo, 'relatedTarget after init';

# -------------------------#
use tests 12; # trigger_event’s defaults
{
	my $elem = $doc->createElement('div');
	my $output;
	$elem->addEventListener($_ => sub {
		my $event = shift;
		isa_ok $event, 'HTML::DOM::Event::Mouse',
			$event->type . " event object";
		$output = join ',', map {
			my $foo = $event->$_;
			ref $foo || (defined $foo ? $foo : '_')
		} qw/ bubbles cancelable type view detail screenX
		      screenY clientX clientY ctrlKey shiftKey altKey
		      metaKey button relatedTarget /;
	})
	  for qw(click mousedown mouseup mouseover mousemove mouseout);

	undef $output;
	$elem->trigger_event('click');
	is $output,
	   "1,1,click,HTML::DOM::View,1,0,0,0,0,0,0,0,0,1,_";

	undef $output;
	$elem->trigger_event('mousedown');
	is $output,
	   "1,1,mousedown,HTML::DOM::View,1,0,0,0,0,0,0,0,0,1,_";

	undef $output;
	$elem->trigger_event('mouseup');
	is $output,
		"1,1,mouseup,HTML::DOM::View,1,0,0,0,0,0,0,0,0,1,_";

	undef $output;
	$elem->trigger_event('mouseover');
	is $output,
	  "1,1,mouseover,HTML::DOM::View,_,0,0,0,0,0,0,0,0,_,_";

	undef $output;
	$elem->trigger_event('mousemove');
	is $output,
	  "1,0,mousemove,HTML::DOM::View,_,0,0,0,0,0,0,0,0,_,_";

	undef $output;
	$elem->trigger_event('mouseout');
	is $output,
		"1,1,mouseout,HTML::DOM::View,_,0,0,0,0,0,0,0,0,_,_";
};


