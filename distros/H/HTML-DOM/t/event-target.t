#!/usr/bin/perl -T

use strict; use warnings;
no warnings qw 'utf8 parenthesis regexp once qw bareword syntax';

use lib 't';
use HTML::DOM;
use HTML::DOM::EventTarget;
use HTML::DOM::Event ':all';

my $doc = new HTML::DOM;
{
	package MyEventTarget;
	our @ISA = HTML::DOM::EventTarget::;

	sub event_parent {
		${+shift}
	}
}

my $child = bless \do{my $x}, MyEventTarget=>;
my $grandchild = bless \do{my $x = $child}, 'MyEventTarget';

# -------------------------#
use tests 10; # (add|remove)EventListener and get_event_listeners

{
	my $sub1 = sub{};
	my $sub2 = sub{};
	my $sub3 = sub{};
	my $sub4 = sub{};
	is_deeply[$child->get_event_listeners('click')],[],
		'get_event_listeners initially returns nothing';
	is_deeply[$child->addEventListener(click=>$sub1)],[], 
		'addEventListener returns nothing';
	$child->addEventListener(click=>$sub2);
	is_deeply[sort $child->get_event_listeners('click')],
	         [sort $sub1, $sub2], 'get_event_listeners after adding 2';
	$child->addEventListener(click=>$sub3, 1);
	$child->addEventListener(click=>$sub4, 1);
	is_deeply[sort $child->get_event_listeners('click', 1)],
	         [sort $sub3, $sub4],
		'get_event_listeners (for capture phase) after adding 2';
	is_deeply[$child->removeEventListener(click=>$sub1)],[],
		'removeEventListener does nothing';
	is_deeply[$child->get_event_listeners('click')],
	         [$sub2],
		'get_event_listeners after removing one';
	$child->removeEventListener(click=>$sub3, 1);
	is_deeply[$child->get_event_listeners('click', 1)],
	         [$sub4],
		'get_event_listeners for capture phase after removing one';
	$child->addEventListener(focus => $sub3);
	$child->addEventListener(focus => $sub4);
	$child->addEventListener(focus => $sub2, 1);
	is_deeply[[$child->get_event_listeners('click')],
	          [$child->get_event_listeners('click', 1)],
	          [sort($child->get_event_listeners('focus'))],
	          [$child->get_event_listeners('focus', 1),]],
	         [[$sub2],
	          [$sub4],
	          [sort $sub3, $sub4],
	          [$sub2]],
	         'different slots for different event types and phases';
	$child->onsubmit($sub1);
	is +()=$child->get_event_listeners('submit'), 1,
	 'get_event_listeners with attribute event handlers';
	is +()=$child->get_event_listeners('submit',1), 0,
	 'event handlers to not apply to the capture phase';
}

# Let's clean up after ourselves:
clear_event_listeners($child, 'click', 'focus', 'submit');

sub clear_event_listeners {
	my $target = shift;
	for my $type(@_) {
		$target->removeEventListener($type, $_)
			for $target->get_event_listeners($type);
		$target->removeEventListener($type, $_, 1)
			for $target->get_event_listeners($type, 1);
	}
}


# -------------------------#
use tests 4; # event dispatch:
# First we'll make sure that the events are triggered in the right order,
# and for the right event type.

my $event = $doc->createEvent;
my $event2 = $doc->createEvent;
init $event type => click => cancellable => 1 => propagates_up => 1;
init $event2 type => focus => cancellable => 0 => propagates_up => 0;

our $e;

# some of these never get called--or shouldn't, if the module's work-
# ing correctly.
$child->addEventListener(click => sub { $e .= '-cclick1' });
$child->addEventListener(click => sub { $e .= '-cclick2' });
$child->addEventListener(click => sub { $e .= '-cclick1-capture' }, 1);
$child->addEventListener(click => sub { $e .= '-cclick2-capture' }, 1);
$grandchild->addEventListener(click => sub { $e .= '-gcclick1' });
$grandchild->addEventListener(click => sub { $e .= '-gcclick2' });
$grandchild->addEventListener(
	click => sub { $e .= '-gcclick1-capture' }, 1);
$grandchild->addEventListener(
	click => sub { $e .= '-gcclick2-capture' }, 1);
$child->addEventListener(focus => sub { $e .= '-cfocus1' });
$child->addEventListener(focus => sub { $e .= '-cfocus2' });
$child->addEventListener(focus => sub { $e .= '-cfocus1-capture' }, 1);
$child->addEventListener(focus => sub { $e .= '-cfocus2-capture' }, 1);
$grandchild->addEventListener(focus => sub { $e .= '-gcfocus1' });
$grandchild->addEventListener(focus => sub { $e .= '-gcfocus2' });
$grandchild->addEventListener(
	focus => sub { $e .= '-gcfocus1-capture' }, 1);
$grandchild->addEventListener(
	focus => sub { $e .= '-gcfocus2-capture' }, 1);

$@ = 'drit'; # Make sure event dispatch leaves this alone.

$e = '';
ok $grandchild->dispatchEvent($event), 'dispatchEvent returns true';
like $e, qr/^-cclick(\d)-capture      # Each pair can be run in any order,
             -cclick(?!\1)\d-capture  # hence the (\d) and (?!\1)\d.
             -gcclick(\d)
             -gcclick(?!\2)\d
             -cclick(\d)
             -cclick(?!\3)\d
         \z/x, 'order of fizzy event dispatch';

$e = '';
$grandchild->dispatchEvent($event2); # This event is not bubbly.
like $e, qr/^-cfocus(\d)-capture      # Each pair can be run in any order,
             -cfocus(?!\1)\d-capture  # hence the (\d) and (?!\1)\d.
             -gcfocus(\d)
             -gcfocus(?!\2)\d
          \z/x, 'order of flat event dispatch';

is $@, 'drit', 'event dispatch leaves $@ alone'; # bug in 0.033 and earlier

clear_event_listeners($child, 'click', 'focus');
clear_event_listeners($grandchild, 'click', 'focus');


# -------------------------#
use tests 1; # event dispatch:
# Now we need to see whether eventPhase is set correctly.

($event = $doc->createEvent)->initEvent(click => 1, 1);
$child->addEventListener(click => sub { $e .= $_[0]->eventPhase }, 1);
$child->addEventListener(click => sub { $e .= $_[0]->eventPhase }, 1);
$child->addEventListener(click => sub { $e .= $_[0]->eventPhase });
$child->addEventListener(click => sub { $e .= $_[0]->eventPhase });
$grandchild->addEventListener(click => sub { $e .= $_[0]->eventPhase });
$grandchild->addEventListener(click => sub { $e .= $_[0]->eventPhase });

$e = '';
$grandchild->dispatchEvent($event);
is $e, '112233', 'value of eventPhase during event dispatch';

clear_event_listeners($child, 'click');
clear_event_listeners($grandchild, 'click');


# -------------------------#
use tests 3; # event dispatch: stopPropagation

{
	# I put stopPropagation in both listeners for each phase, since
	# they could be called either order and I need to make sure that
	# the other handler at the same level is still called *after* the
	# first one has called stopPropagation.
	$child->addEventListener(click => my $capture1 = sub {
		$_[0]->stopPropagation;
		$e .= '-'
	}, 1);
	$child->addEventListener(click => my $capture2 = sub {
		$_[0]->stopPropagation;
		$e .= '-'
	}, 1);
	$grandchild->addEventListener(click => my $at_target1 = sub {
		$_[0]->stopPropagation; $e .= '='
	});
	$grandchild->addEventListener(click => my $at_target2 = sub {
		$_[0]->stopPropagation; $e .= '='
	});
	$child->addEventListener(click => my $fzz1 = sub {
		$_[0]->stopPropagation; $e .= '≡'
	});
	$child->addEventListener(click => my $fzz2 = sub {
		$_[0]->stopPropagation; $e .= '≡'
	});
	$doc->addEventListener(click => sub {
		$e = "You didn't expect this, did you?"
	});

	$e = '';
	($event = $doc->createEvent)->initEvent(click => 1, 1);
	$grandchild->dispatchEvent($event);
	is $e, '--', 'stopPropagation at capture phase';

	$child->removeEventListener(click => $_, 1)
		for $capture1, $capture2;

	$e = '';
	($event = $doc->createEvent)->initEvent(click => 1, 1);
	$grandchild->dispatchEvent($event);
	is $e, '==', 'stopPropagation at the target';

	$grandchild->removeEventListener(click => $_)
		for $at_target1, $at_target2;

	$e = '';
	($event = $doc->createEvent)->initEvent(click => 1, 1);
	$grandchild->dispatchEvent($event);
	is $e, '≡≡', 'stopPropagation at the bubbly phase';

}

clear_event_listeners($child, 'click');
clear_event_listeners($grandchild, 'click');
clear_event_listeners($doc, 'click');


# -------------------------#
use tests 10; # event dispatch:
#             qw/ target currentTarget preventDefault cancelable /
#    This section also makes sure that event types are indifferent to case.

$child->addEventListener(cLick => sub {
	is $_[0]->currentTarget, $child,
		'currentTarget at capture stage';
	is $_[0]->target, $grandchild,
		'"target" attr during capture phase';
}, 1);
$grandchild->addEventListener(clIck => sub {
	is $_[0]->currentTarget, $grandchild,
		'currentTarget at the target';
	is $_[0]->target, $grandchild,
		'"target" attr at the target';
});
$child->addEventListener(cliCk => sub {
	is scalar $_[0]->preventDefault, undef,
		'return val of preventDefault';
	is $_[0]->currentTarget, $child,
		'currentTarget while bubbles are being blown';
	is $_[0]->target, $grandchild,
		'"target" attr while froth is rising';
});

($event = $doc->createEvent)->initEvent(click => 1, 1);

ok! $grandchild->dispatchEvent($event),
	'preventDefault makes dispatchEvent return false';

clear_event_listeners($child, 'click');
clear_event_listeners($grandchild, 'click');

$grandchild->addEventListener(click => sub {
	$e = 'did it'; # make sure this handler is actually called
	$_[0]->preventDefault
});
($event = $doc->createEvent)->initEvent(click => 1, 0);
ok $grandchild->dispatchEvent($event),
	'preventDefault has no effect on uncancelable actions';
is $e, 'did it', 'And, yes, preventDefault *was* actually called.';

# -------------------------#
use tests 7; # event dispatch: event handlers
#  (accessors for event handlers are tested specifically further down)

clear_event_listeners($grandchild, 'click');
{
 ($event = $doc->createEvent)->initEvent('click',1,1);
 $grandchild->onclick(sub { 0 });
 ok !$grandchild->dispatchEvent($event),
  'defined false retval from attr event handler calls preventDefault';
 ($event = $doc->createEvent)->initEvent('click',1,1);
 $grandchild->onclick(sub{});
 ok $grandchild->dispatchEvent($event),
  'undef retval from attr event handler does not call preventDefault';
 ($event = $doc->createEvent)->initEvent('mouseover',1,1);
 $grandchild->onmouseover(sub{});
 ok $grandchild->dispatchEvent($event),
  'undef retval from onmouseover handler does not call preventDefault';
 ($event = $doc->createEvent)->initEvent('mouseover',1,1);
 $grandchild->onmouseover(sub{1});
 ok !$grandchild->dispatchEvent($event),
  'true retval from onmouseover handler calls preventDefault';
 my @scratch;
 *Function::call_with = sub { @scratch = @_ };
 $grandchild->onclick(bless[], 'Function');
 $grandchild->trigger_event('click');
 is $scratch[1], $grandchild, 'target is passed to call_with';
 isa_ok $scratch[2], 'HTML::DOM::Event', 'second arg to call_with';
 
 { package DelegatingEventTarget;
   our @ISA = HTML::DOM::EventTarget::;
   sub get_event_listeners { ${+shift}->get_event_listeners(@_) }
   sub event_handler       { ${+shift}->event_handler(@_) }
   sub addEventListener    { ${+shift}->addEventListener(@_) }
   sub removeEventListener { ${+shift}->removeEventListener(@_) }
 }
 my $delegate = bless \do{my $x = $grandchild}, DelegatingEventTarget::;
 $delegate->trigger_event('click');
 ($event = $doc->createEvent)->init(type => 'click');
 is $scratch[1], $delegate,
  'event handler wrappers can be transferred to other objects';
}

# -------------------------#
use tests 6; # exceptions thrown by dispatchEvent

$event = $doc->createEvent;
eval {
	$child->dispatchEvent($event);
};
isa_ok $@, 'HTML::DOM::Exception',
'$@ (after dispatchEvent with an uninited event)';
cmp_ok $@, '==', HTML::DOM::Exception::UNSPECIFIED_EVENT_TYPE_ERR,
    'dispatchEvent with an uninited event throws the ' .
    'appropriate error';

$event->initEvent(undef, 1, 1);
eval {
	$child->dispatchEvent($event);
};
isa_ok $@, 'HTML::DOM::Exception',
'$@ (after dispatchEvent with no event type)';
cmp_ok $@, '==', HTML::DOM::Exception::UNSPECIFIED_EVENT_TYPE_ERR,
    'dispatchEvent with an no event type throws the ' .
    'appropriate error';

$event->initEvent('' => 1, 1);
eval {
	$child->dispatchEvent($event);
};
isa_ok $@, 'HTML::DOM::Exception',
'$@ (after dispatchEvent with "" for the event type)';
cmp_ok $@, '==', HTML::DOM::Exception::UNSPECIFIED_EVENT_TYPE_ERR,
    'dispatchEvent with "" for the event type throws the ' .
    'appropriate error';




# -------------------------#
use tests 5; # trigger_event

clear_event_listeners($grandchild, 'click');

$grandchild->addEventListener(clink => sub {
	$_[0]->preventDefault
});

my @def = (default => sub {
	$e = $_[0];
});

$e = '';
($event = $doc->createEvent)->initEvent(clink => 1, 1);
$grandchild->trigger_event($event, @def);
is $e, '', 'event objects passed to trigger_event can be stopped';

$grandchild->trigger_event('clink', @def);
is $e, '', 'event names passed to trigger_event can be stopped';

$e = '';
($event = $doc->createEvent)->initEvent(clink => 1, 0);
$grandchild->trigger_event($event, @def);
is $e, $event,
    'the default event was run when an obj was passed to trigger_event';

clear_event_listeners($grandchild, 'clink');
$e = '';
$grandchild->trigger_event('clink', @def);
is $e->type, 'clink',
	'$event->type when an event name is passed to trigger_event';
is $e->target, $grandchild,
	'$event->target when an event name is passed to trigger_event';

undef $e; # remove circularities


# -------------------------#
use tests 1; # error_handler
# This doesn’t test $target->ownerDocument->error_handler; event-basics.t
# takes care of that.

{
	no warnings 'once';
	my $e;
	local *MyEventTarget'error_handler = sub{ sub{ $e = $@ }};
	$grandchild->addEventListener(foo => sub { die "67\n" });
	$grandchild->trigger_event('foo');
	is $e, "67\n", 'error_handler gets called';
}


# -------------------------#
use tests 7;  # event_listeners_enabled
{
	no warnings qw 'redefine once';
	my $e;
	local *MyEventTarget'event_listeners_enabled = sub{ 1 };
	$grandchild->addEventListener(foo => sub { ++$e });
	$grandchild->trigger_event('foo');
	is $e, 1,
	  'event handlers run when event_listeners_enabled returns true';
	local *MyEventTarget'event_listeners_enabled = sub{ 0 };
	$grandchild->trigger_event('foo');
	is $e, 1,
	  'event handlers don\'t run if event_listeners_enabled is false';
	local *MyEventTarget'event_listeners_enabled = sub{ 1 };
	local *MyDoc'event_listeners_enabled = sub { 0 };
	local *MyEventTarget'ownerDocument = sub { bless[], 'MyDoc' };
	$grandchild->trigger_event('foo');
	is $e, 2, 'An event_listeners_enabled method on the event';
	local *MyEventTarget'event_listeners_enabled = sub{ 0 };
	local *MyDoc'event_listeners_enabled = sub { 1 };
	$grandchild->trigger_event('foo');
	is $e, 2, ' target prevents ownerDocument from being checked.';
	undef *MyEventTarget'event_listeners_enabled;
	$grandchild->trigger_event('foo');
	is $e, 3, 'fallback to event_listeners_enabled';
	local *MyDoc'event_listeners_enabled = sub { 0 };
	$grandchild->trigger_event('foo');
	is $e, 3, '  on the ownerDocument';

	$grandchild->trigger_event('foo', default => sub {
	  is $_[0]->target, $grandchild,
	    'the event’s target is set when event handlers are disabled'
	    # something I got wrong at first
	});
	
}


# -------------------------#
use tests 8;  # on* and attr_event_listener
{
 my $scratch;
 my $sub1 = sub { $scratch .= "one called "};
 my $sub2 = sub {  $scratch .= "two called " };
 is +()=$child->onbdext, 0, 'null retval from on*';
 is +()=$child->onbdext($sub1),0,'null retval from on* initial assignment';
 is $child->onbdext($sub2), $sub1, 'on* returns old value';
 is $child->onbdext, $sub2, 'on* with no args after assignment';
 $child->trigger_event('bdext');
 is $scratch, "two called ",
  'on* registers event listener and removes old one';
 is $child->attr_event_listener('bdext'), $sub2,
  'attr_event_listener returns the same thing as on*';
 is $child->attr_event_listener('bdext',$sub1),$sub2,
  'setting attr_event_listener returns old val';
 is $child->onbdext, $sub1, 'and the change applies to on*';
}

# -------------------------#
use tests 1;  # error messages for invalid methods
{             # (Testing this is necessary since we implement AUTOLOAD.)
 eval { 'dwext'->HTML::DOM::Node::dwed; };
 like $@,
  qr/^Can't locate object method "dwed" via package "HTML::DOM::Node"/;
}
