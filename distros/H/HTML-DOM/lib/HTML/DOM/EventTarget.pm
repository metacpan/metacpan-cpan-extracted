package HTML::DOM::EventTarget;

our $VERSION = '0.058';


use strict;
use warnings;
no warnings qw ' utf8 parenthesis ';

use Carp 'croak';
use HTML::DOM::Event;
use HTML::DOM::Exception qw 'UNSPECIFIED_EVENT_TYPE_ERR';
use Scalar::Util qw'refaddr  blessed';
use HTML::DOM::_FieldHash;

fieldhashes \my(
	%evh,  # event handlers
	%cevh, # capturing event handlers
	%aevh, # attribute event handlers
);

=head1 NAME

HTML::DOM::EventTarget - Perl implementation of the DOM EventTarget interface

=head1 VERSION

Version 0.058

=head1 SYNOPSIS

  use HTML::DOM;
  $doc = HTML::DOM->new;
  $doc->isa('HTML::DOM::EventTarget'); # true

  $event = $doc->createEvent('MouseEvents');
  $event->initEvent('click',1,1);

  $doc->trigger_event('click');
  $doc->dispatchEvent($event);
  # etc

=head1 DESCRIPTION

This class provides the W3C's EventTarget DOM interface. It serves as a
base class for L<HTML::DOM::Node> and L<HTML::DOM::Attr>, but any class you
write can inherit from it.

This class provides the methods listed under L</METHODS>, but will also use 
a few 
others
defined by subclasses, if they are present:

=over

=item parentNode

=item event_parent

These are used to determine the 'ancestry' of the event target, through
which the event will be dispatched. For each object, starting with the
target, the C<parentNode> method is called; if it doesn't exist or returns
false, the C<event_parent> method is tried. If that fails, then the object
is taken to be the topmost object.

=item error_handler

The return value of this method, if it exists and returns one, is presumed
to be a code ref, and is called whenever an event handler (listener) dies.
If there is no C<error_handler> method that returns true, then
C<< $target->ownerDocument->error_handler >> is used instead. If that
fails, then errors are ignored.

=item event_listeners_enabled

If this method exists and returns false, then event handlers are not 
called.
If there is no C<event_listeners_enabled> method,
then
C<< $target->ownerDocument->event_listeners_enabled >> is used instead.

=item ownerDocument

See C<error_handler> and C<event_listeners_enabled>.

=back

=head1 METHODS

If a subclass needs to store event handlers and listeners elsewhere (e.g.,
associating them with another object), it can override C<addEventListener>,
C<removeEventListener>, C<event_handler> and C<get_event_listeners>.

=over

=item addEventListener($event_name, $listener, $capture)

The C<$listener> should be either a coderef or an object with a
C<handleEvent> method. (HTML::DOM does not implement any such object since
it would just be a wrapper around a coderef anyway, but has support for
them.) An object with C<&{}> overloading will also do.

C<$capture> is a boolean indicating whether this is to be triggered during
the 'capture' phase.

=cut

sub addEventListener {
	my ($self,$name,$listener, $capture) = @_;
	(\(%cevh, %evh))[!$capture]->{$self}
		{lc $name}{refaddr $listener} = $listener;
	return;
}


=item removeEventListener($event_name, $listener, $capture)

The C<$listener> should be the same reference passed to 
C<addEventListener>.

=cut

sub removeEventListener {
	my ($self,$name,$listener, $capture) = @_;
	$name = lc $name;
	my $h = (\(%cevh, %evh))[!$capture];
	exists $h->{$self}
	  and exists $$h{$self}{$name}
	  and delete $$h{$self}{$name}{refaddr $listener};
	return;
}


=item on* (onthis, onthat, onclick, onfoo, etc.)

This applies to any all-lowercase method beginning with C<on>. Basically,
C<< $target->onclick(\&sub) >> is equivalent to
C<< $target->addEventListener('click', \&sub, 0) >>, except that it
replaces any event handler already assigned via C<onclick>, returning it.
C<< $target->onclick >> (without arguments) returns the event handler
previously assigned to C<onclick> if there is one.

=cut

sub AUTOLOAD {
	my($pack,$meth) = our $AUTOLOAD =~ /(.*)::(.*)/s;
	$meth =~ /^on([a-z]+)\z/
		or die "Can't locate object method \"$meth\" via package "
			. qq'"$pack" at '.join' line ',(caller)[1,2]
			,. "\n";
	shift->event_handler($1, @_);
}
sub DESTROY{}

=item event_handler ( $name )

=item event_handler ( $name, $new_value )

This is an accessor method for event listeners created by HTML or DOM
attributes beginning with 'on'. This is used internally by the C<on*>
methods. You can use it directly for efficiency's sake.

This method used to be called C<attr_event_listener>, but that was a
mistake, as there is a distinction between handlers and listeners. The old
name is still available but will be removed in a future release. It simply
calls C<event_handler>.

=cut

sub event_handler {
	my ($self,$name) = (shift,shift);
	$name = lc $name;
	my $old = exists $aevh{$self} && exists $aevh{$self}{$name}
	 && $aevh{$self}{$name};
	@_ and $aevh{$self}{$name} = shift;
	$old ||();
}
sub attr_event_listener { shift->event_handler(@_) }


=item get_event_listeners($event_name, $capture)

This is not a DOM method (hence the underscores in the name). It returns a
list of all event listeners for the given event name. C<$capture> is a
boolean that indicates which list to return, either 'capture' listeners or
normal ones.

If there is an event handler for this event (and C<$capture> is false),
then C<get_event_listeners> tacks a wrapper for the event handler on to the
end of the list it returns.

=for comment
This is no longer true. But we may need a similar warning in case other packages install listeners that must not be removed.
B<Warning:> This method is intended mostly for internal use, but you can
go ahead and use it if you like. Just beware that some of the event
handlers returned may have been installed automatically by HTML::DOM, and
are necessary for its internal workings, so don't go passing those to
C<removeEventListener> and expect all to go well.

=cut

sub get_event_listeners { # uses underscores because it is not a DOM method
	my($self,$name,$capture) = @_;
	$name = lc $name;
	my $h = (\(%cevh, %evh))[!$capture]->{$self};
	my @ret = $h && exists $$h{$name}
		? values %{$$h{$name}}
		: ();
	if(!$capture && exists $aevh{$self} && exists $aevh{$self}{$name}
	   and defined (my $aevh = $aevh{$self}{$name})) {
		@ret, sub {
			my $ret =
			 defined blessed $aevh && $aevh->can('call_with')
			 ? call_with $aevh $_[0]->currentTarget, $_[0]
			 : &$aevh($_[0]);
			defined $ret
			 && ($name eq 'mouseover' ? $ret : !$ret)
			 && $_[0]->preventDefault;
		}
	}
	else { @ret }
}

=item dispatchEvent($event_object)

$event_object is an object returned by HTML::DOM's C<createEvent> method,
or any object that implements the interface documented in 
L<HTML::DOM::Event>.

C<dispatchEvent> does not automatically call the handler passed to the
document's C<default_event_handler>. It is expected that the code that
calls this method will do that (see also L</trigger_event>).

The return value is a boolean indicating whether the default action
should be taken (i.e., whether preventDefault was I<not> called).

=for comment
Actually, it's the event object itself (unless it was called in
auto-vivacious mode and the event was never auto-vivved); but that’s an
implementation detail that’s subject to change willy-nilly.

=cut

sub dispatchEvent {
	_dispatch_event(shift, 1, shift);
}

sub _dispatch_event { # This is where all the work is.
	# We accept two different types of arg lists:
	#   1) $target->...($yes_it_is_an_event_object, $event_obj)
	#   2) $target->...($no_it's_not_an_event_object,
	#                   $event_category, \&arg_maker, %more_args)
	# The second is for autovivving the event object, as we do with
	# attr modifications, to avoid creating an attr node unnecessarily.
	# We init an event with (%more_args, &arg_maker).

	my ($target, $event) = (shift,shift);
	$event &&= shift or my ($cat, $args, %args) = @_;;
	my $name = $event ? $event->type : $args{type};

	die HTML::DOM::Exception->new(UNSPECIFIED_EVENT_TYPE_ERR,
		'The type of event has not been specified')
		unless defined $name and length $name;

	$event->_set_target($target) if $event && !$event->target;

	local *@;

	# Check to see whether we are supposed to skip event handlers, and
	# short-circuit if that’s the case:
	Foo: {
		my $doc;
		my $sub = $target->can('event_listeners_enabled')
		       || (eval{$doc = $target->ownerDocument}||next Foo)
		                 ->can('event_listeners_enabled')
		       || last Foo;
		&$sub($doc||$target) or return $event||1
	}
	
	# Basic event flow is as follows:
	# 1.  The  'capturing'  phase:  Go through the  node's  ancestors,
	#     starting from the top of the tree. For each one, trigger any
	#     capture events it might have.
	# 2.  Trigger events on the $target.
	# 3. 'Bubble-blowing' phase: Trigger events on the target's ances-
	#     tors in reverse order (top last).

	my $eh = eval{$target->error_handler}
	       ||eval{$target->ownerDocument->error_handler};

	my @lineage = $target;
	{
		push @lineage, eval{$lineage[-1]->parentNode}
	                     ||eval{$lineage[-1]->event_parent}
		             ||last;
		redo
	}
	shift @lineage; # shouldn’t include the target
	# $lineage[-1] is the root, by the way

	my $initted;

	for (reverse @lineage) { # root first
		my @l = $_->get_event_listeners($name, 1);
		if(@l and !$initted++) {
			# ~~~ This occurs three times; it probably ought to
			#     go it its own sub
			$event ||= do {
				(my $e =
				  ($target->ownerDocument||$target)
				   ->createEvent($cat)
				)->init(
					%args, &$args
				);
				$e->_set_target($target) unless $e->target;
				$e;
			};
			$event->_set_eventPhase(
				HTML::DOM::Event::CAPTURING_PHASE);
		}
		$event-> _set_currentTarget($_) if @l;
		for(@l) {
			eval {
			  defined blessed $_ && $_->can('handleEvent') ?
			  $_->handleEvent($event) : &$_($event);
			  1
			} or $eh and &$eh();
		}
		return !cancelled $event if
			($event||next)->propagation_stopped;
	}

	my @l =  $target->get_event_listeners($name);
	if(@l) {
		unless ($initted++) {
			$event ||= do {
				(my $e =
				  ($target->ownerDocument||$target)
				   ->createEvent($cat)
				)->init(
					%args, &$args
				);
				$e->_set_target($target) unless $e->target;
				$e;
			};
		};
		$event->_set_eventPhase(HTML::DOM::Event::AT_TARGET);
		$event->_set_currentTarget($target);
	}
	eval {
		defined blessed $_ && $_->can('handleEvent') ?
			$_->handleEvent($event) : &$_($event);
		1
	} or $eh and &$eh() for @l;
	return +($event) x !cancelled $event if
		$event
		? $event->propagation_stopped || !$event->bubbles
		: !$args{propagates_up};

	my $initted2;
	for (@lineage) { # root last
		my @l = $_->get_event_listeners($name);
		if(@l){
			unless($initted++) {
				$event ||= do {
					(my $e =
					  ($target->ownerDocument||$target)
					   ->createEvent($cat)
					)->init(
						%args, &$args
					);
					$e->_set_target($target)
					  unless $e->target;
					$e;
				};
			}
			unless ($initted2++) {
				$event->_set_eventPhase(
					HTML::DOM::Event::BUBBLING_PHASE);
			}
		}
		$event-> _set_currentTarget($_) if @l;
		eval {
			defined blessed $_ && $_->can('handleEvent') ?
				$_->handleEvent($event) : &$_($event);
			1
		} or $eh and &$eh() for(@l);
		return +($event) x !cancelled $event
			if ($event||next)->propagation_stopped;
	}
	return +($event) x !($event||return 1)->cancelled ;
}

=item trigger_event($event, ...)

Here is another non-DOM method. C<$event> can be an event object or simply 
an event name. This method triggers an
event for real, first calling C<dispatchEvent> and then running the default
action for the event unless an event listener cancels it.

It can take named args following the C<$event> arg. These are passed to the
event object's C<init> method. Any
omitted args will be filled in with reasonable defaults. These are
completely ignored if C<$event> is an event object.

Also, you can use the C<default> arg to provide a coderef that will be
called as the default event handler. L<HTML::DOM::Node> overrides it to do
just that, so you shouldn't need to use this arg except on a custom
subclass of EventTarget.

When C<$event> is an event name, C<trigger_event> automatically chooses the
right event class and a set of default args for that event name, so you can
supply just a few. E.g.,

  $elem->trigger_event('click',  shift => 1, button => 1);

=begin comment

Internal-only features:

The interface for this is very clunky, so I’m keeping it private for now.
It only exists for the sake of the implementation, anyway.

The named args can contain DOMActivate_default => \&sub to specify a
default handler for an event type. We don't use default =>
{ DOMActivate => \&sub } as I originally intended, because that would make
it harder for multiple classes
to say SUPER::trigger_event($evnt, ..._default => ) without clobbering each
other.

And there's the 'create event object on demand' interface, which is as
follows:

$thing->trigger_event('DOMAttrModified', auto_viv => \&arg_maker);

This does not automatically supply the view.

=end comment

=cut

sub trigger_event { # non-DOM method
	my ($target, $event, %args) = @_;
	if($args{auto_viv}) {
		# For efficiency’s sake, we skip creating the event object
		# here, and have _dispatch_event create the object on
		# demand, using the code ref that we pass to it.
		my ($cat, @init_args) = HTML'DOM'Event'defaults($event);
		unshift @init_args, type => $event;
		if(my $rv = _dispatch_event(
			$target, 0, $cat, $args{auto_viv},
			@init_args
		)) {
			my $def = 
				$args{"$event\_default"} ||
				$args{"default"}
				 || return;
			unless (ref $rv) {
				($rv =
				  HTML'DOM'Event'create_event($cat)
				)->init(my @args =
					@init_args, &{$args{auto_viv}}
				);
				$rv->_set_target($target);
			}
			&$def($rv);
		}
		return;
	}
	my $type;
	defined blessed $event && $event->isa('HTML::DOM::Event')
	? $type =  $event->type 
	: do {
		$type = $event;
		$event = HTML'DOM'Event'create_event((
				my (undef, @init_args) =
					HTML'DOM'Event'defaults($type)
			)[0]);
		$event->init(
			type=>$type,
			@init_args,
			%args
		);
	};

	$target->dispatchEvent($event) and &{
		$args{"$type\_default"} ||
		$args{default}
		|| return
	}($event);
	return;
}


=back

=cut

1;
__END__


=head1 SEE ALSO

L<HTML::DOM>

L<HTML::DOM::Event>

L<HTML::DOM::Node>

L<HTML::DOM::Attr>
