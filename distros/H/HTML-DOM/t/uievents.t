#!/usr/bin/perl -T

use strict; use warnings; no warnings qw 'utf8 parenthesis'; use lib 't';

use lib 't';
use HTML::DOM;

my $doc = new HTML::DOM;
require HTML::DOM::View;
$doc->defaultView(my $v = bless[], HTML::DOM::View::);
my $event = $doc->createEvent('UIEvents');

# -------------------------#
use tests 8; # initUIEvent

is +()=$event->view, 0, 'event\'s view before init';
is $event->detail, undef, 'detail before init';

is_deeply [initUIEvent $event DOMActivate => 1, 1,$doc->defaultView,2], [],
	'initUIEvent returns nothing';

ok bubbles $event, 'event is bubbly after init*Event';
ok cancelable $event, 'event is cancelable after init*Event';
is $event->type, 'DOMActivate', 'event type after init*Event';
is $event->view, $doc->defaultView, 'view after init*Event';
is $event->detail, 2, 'detail after init*Event';

# -------------------------#
use tests 5; # init

init $event type => DOMActivate => propagates_up => 1,cancellable=> 1,
	view=>$doc->defaultView,detail=>2;

ok bubbles $event, 'event is bubbly after init';
ok cancelable $event, 'event is cancelable after init';
is $event->type, 'DOMActivate', 'event type after init';
is $event->view, $doc->defaultView, 'view after init';
is $event->detail, 2, 'detail after init';

# -------------------------#
use tests 6; # trigger_event’s defaults
{
	my $elem = $doc->createElement('div');
	my $output;
	$elem->addEventListener($_ => sub {
		my $event = shift;
		isa_ok $event, 'HTML::DOM::Event::UI',
			$event->type . " event object";
		$output = join ',', map {
			my $foo = $event->$_;
			ref $foo || (defined $foo ? $foo : '_')
		} qw/ bubbles cancelable type view detail /;
	})
	  for qw(DOMActivate DOMFocusIn DOMFocusOut);

	undef $output;
	$elem->trigger_event('DOMActivate');
	is $output,
	   "1,1,DOMActivate,HTML::DOM::View,1";

	undef $output;
	$elem->trigger_event('DOMFocusIn');
	is $output,
	   "1,0,DOMFocusIn,HTML::DOM::View,_";

	undef $output;
	$elem->trigger_event('DOMFocusOut');
	is $output,
		"1,0,DOMFocusOut,HTML::DOM::View,_";
};


