package HTML::DOM::Event;

our $VERSION = '0.058';


use strict;
use warnings;

# Look, TMTOWTDI:
sub	CAPTURING_PHASE  (){             1,}
sub	AT_TARGET             (){ 2,}
	sub BUBBLING_PHASE             (){       3,}	

use HTML::DOM::Exception 'NOT_SUPPORTED_ERR';
use Exporter 5.57 'import';

our @EXPORT_OK = qw'
	CAPTURING_PHASE            
	AT_TARGET        
	BUBBLING_PHASE              
';
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub new {
	bless {time => time}, $_[0];
}

sub create_event {
	my $class = class_for($_[0]);
	defined $class or die new HTML::DOM::Exception NOT_SUPPORTED_ERR,
		"The event category '$_[0]' is not supported";
	(my $path =$class) =~ s/::/\//g;
	require "$path.pm";
	$class->new
}

# ----------- ATTRIBUTE METHODS ------------- #
# (all read-only)

sub type          { $_[0]{name      } }
sub target        { $_[0]{target    }||() }
sub currentTarget { $_[0]{cur_target}||() }
sub eventPhase    { $_[0]{phase     } }
sub bubbles       { $_[0]{froth     } }
sub cancelable    { $_[0]{cancelable} }
sub timeStamp     { $_[0]{time      } }
sub cancelled     { $_[0]{cancelled } } # non-DOM
sub propagation_stopped { $_[0]{stopped} } # same hear


# ----------- METHOD METHODS ------------- #

sub stopPropagation { $_[0]{stopped  } = !0; return }
sub preventDefault  { $_[0]{cancelled} = !0 if $_[0]->cancelable; return }
#  similar:
sub _set_eventPhase    { $_[0]{phase     } = $_[1] }
sub _set_target        { $_[0]{target    } = $_[1] }
sub _set_currentTarget { $_[0]{cur_target} = $_[1] }

sub initEvent {
	shift->init(
		type => shift,
		propagates_up => shift,
		cancellable => shift,
	);
	return;
}

sub init {
	my($event, %args) = @_;
	return if defined $event->eventPhase;
	@$event{qw/name froth cancelable target/}
		= @args{qw/ type propagates_up cancellable target /};
	$event;
}

# ----------- OTHER STUFF ------------- #

# ~~~ Should I document these?
# ~~~ If I do make these public, I probably ought to rename them to make
#     some distinction between the arg types; the arg to class_for is a DOM
#     event module name, and the arg to defaults is an event type.

my %class_for = (
	'' => __PACKAGE__,
	UIEvents => 'HTML::DOM::Event::UI',
	HTMLEvents => __PACKAGE__,
	MouseEvents => 'HTML::DOM::Event::Mouse',
	MutationEvents => "HTML::DOM::Event::Mutation",
);

sub class_for {
	$class_for{$_[0]};
}

# ~~~ The DOM 2 spec lists mouseover and -out as cancellable. Firefox has
#     the cancelable property set to true, but preventDefault does nothing.
#     The DOM 3 spec also lists mousemove as cancellable. None of this
#     makes any sense.
my %defaults = (
	domfocusin  => [ UIEvents =>
		propagates_up => 1,
		cancellable => 0,
	],
	domfocusout => [ UIEvents =>
		propagates_up => 1,
		cancellable => 0,
	],
	domactivate => [ UIEvents =>
		propagates_up => 1,
		cancellable => 1,
		detail => 1,
	],
	click       => [ MouseEvents =>
		propagates_up => 1,
		cancellable => 1,
		detail => 1,
		screen_x => 0,
		screen_y => 0,
		client_x => 0,
		client_y => 0,
		ctrl => 0,
		alt => 0,
		shift => 0,
		meta => 0,
		button => 1,
	],
	mousedown   => [ MouseEvents =>
		propagates_up => 1,
		cancellable => 1,
		detail => 1,
		screen_x => 0,
		screen_y => 0,
		client_x => 0,
		client_y => 0,
		ctrl => 0,
		alt => 0,
		shift => 0,
		meta => 0,
		button => 1,
	],
	mouseup     => [ MouseEvents =>
		propagates_up => 1,
		cancellable => 1,
		detail => 1,
		screen_x => 0,
		screen_y => 0,
		client_x => 0,
		client_y => 0,
		ctrl => 0,
		alt => 0,
		shift => 0,
		meta => 0,
		button => 1,
	],
	mouseover   => [ MouseEvents =>
		propagates_up => 1,
		cancellable => 1,
		screen_x => 0,
		screen_y => 0,
		client_x => 0,
		client_y => 0,
		ctrl => 0,
		alt => 0,
		shift => 0,
		meta => 0,
	],
	mousemove   => [ MouseEvents =>
		propagates_up => 1,
		cancellable => 0,
		screen_x => 0,
		screen_y => 0,
		client_x => 0,
		client_y => 0,
		ctrl => 0,
		alt => 0,
		shift => 0,
		meta => 0,
	],
	mouseout    => [ MouseEvents =>
		propagates_up => 1,
		cancellable => 1,
		screen_x => 0,
		screen_y => 0,
		client_x => 0,
		client_y => 0,
		ctrl => 0,
		alt => 0,
		shift => 0,
		meta => 0,
	],
	domsubtreemodified  => [ MutationEvents =>
		propagates_up => 1,
		cancellable => 0,
	],
	domnodeinserted  => [ MutationEvents =>
		propagates_up => 1,
		cancellable => 0,
	],
	domnoderemoved  => [ MutationEvents =>
		propagates_up => 1,
		cancellable => 0,
	],
	domnoderemovedfromdocument  => [ MutationEvents =>
		propagates_up => 0,
		cancellable => 0,
	],
	domnodeinsertedintodocument  => [ MutationEvents =>
		propagates_up => 0,
		cancellable => 0,
	],
	domattrmodified  => [ MutationEvents =>
		propagates_up => 1,
		cancellable => 0,
	],
	domcharacterdatamodified  => [ MutationEvents =>
		propagates_up => 1,
		cancellable => 0,
	],
	load => [ HTMLEvents =>
		propagates_up => 0,
		cancellable => 0,
	],
	unload => [ HTMLEvents =>
		propagates_up => 0,
		cancellable => 0,
	],
	focus => [ HTMLEvents =>
		propagates_up => 0,
		cancellable => 0,
	],
	blur => [ HTMLEvents =>
		propagates_up => 0,
		cancellable => 0,
	],
	abort => [ HTMLEvents =>
		propagates_up => 1,
		cancellable => 0,
	],
	error => [ HTMLEvents =>
		propagates_up => 1,
		cancellable => 0,
	],
	select => [ HTMLEvents =>
		propagates_up => 1,
		cancellable => 0,
	],
	change => [ HTMLEvents =>
		propagates_up => 1,
		cancellable => 0,
	],
	# submit uses the defaults
	reset => [ HTMLEvents =>
		propagates_up => 1,
		cancellable => 0,
	],
	resize => [ HTMLEvents =>
		propagates_up => 1,
		cancellable => 0,
	],
	scroll => [ HTMLEvents =>
		propagates_up => 1,
		cancellable => 0,
	],
);

sub defaults {
	my $evnt_name = lc $_[0];
	return exists $defaults{$evnt_name}
		? @{$defaults{$evnt_name}}
		: (''=>propagates_up=>1,cancellable=>1);
}

# ($event_category, @args) = HTML'DOM'Event'defaults foo;

1;
__END__


=head1 NAME

HTML::DOM::Event - A Perl class for HTML DOM Event objects

=head1 VERSION

Version 0.058

=head1 SYNOPSIS

  use HTML::DOM::Event ':all'; # get constants

  use HTML::DOM;
  $doc=new HTML::DOM;

  $event = $doc->createEvent;
  $event->initEvent(
      'click', # type
       1,      # whether it propagates up the hierarchy
       0,      # whether it can be cancelled
  );
  # OR:
  $event->init(
      type => 'click',
      propagates_up => 1,
      cancellable => 0,
  );

  $doc->body->dispatchEvent($event); # fake event (run the handlers)
  $doc->body->trigger_event($event); # real event

=head1 DESCRIPTION

This class provides event objects for L<HTML::DOM>, which objects are
passed to event handlers when they are triggered. It implements the W3C 
DOM's Event interface and serves as a base class for more specific event
classes.

=head1 METHODS

=head2 DOM Attributes

These are all read-only and ignore their arguments.

=over

=item type

The type, or name, of the event, without the 'on' prefix that HTML
attributes have; e.g., 'click'.

=item target

This returns the node on which the event occurred. It only works during
event propagation.

=item currentTarget

The returns the node whose handler is currently being called. (The event
might have been triggered on one of its child nodes.) This also works
only during event propagation.

=item eventPhase

Returns one of the constants listed below. This only makes sense during
event propagation.

=item bubbles

This attribute returns a list of C<Bubble> objects, each of which has a
C<diameter> and a C<wobbliness>, which can be retrieved by the
corresponding get_* methods. :-)

Actually, this strangely-named method returns true if the event propagates 
up the 
hierarchy after triggering
event handlers on the target.

=item cancelable

Returns true or false.

=item timeStamp

Returns the time at which the event object was created as returned by
Perl's built-in C<time> function.

=back

=head2 Other DOM Methods

=over

=item initEvent ( $name, $propagates_up, $cancelable )

This initialises the event object. C<$propagates_up> is whether the event
should trigger handlers of parent nodes after the target node's handlers
have been triggered. C<$cancelable> determines whether C<preventDefault>
has any effect.

=item stopPropagation

If this is called, no more event handlers will be triggered.

=item preventDefault

If this is called and the event object is cancelable, 
L<HTML::DOM::EventTarget's 
C<dispatchEvent>
method|HTML::DOM::EventTarget/dispatchEvent> will return false, indicating 
that
the default action is not to be taken.

=back

=head2 Non-DOM Methods

=over

=item init

This is a nice alternative to C<initEvent>. It takes named args:

  $event->init(
      type => 'click',
      propagates_up => 1,
      cancellable => 1,
  );

and returns the C<$event> itself, so you can write:

  $node->dispatchEvent( $doc->createEvent(...)->init(...) );

It also accepts C<target> as an argument. 
This allows you to trigger weird events that have the target set to some
object other than the actual target.
(L<C<dispatchEvent>|HTML::DOM::EventTarget/dispatchEvent> will not set the
target if it is already set.)

=item cancelled

Returns true if C<preventDefault> has been called.

=item propagation_stopped

Returns true if C<stopPropagation> has been called.

=back

=head1 EXPORTS

The following node type constants are exportable, individually or with
':all':

=over 4

=item CAPTURING_PHASE (1)

=item AT_TARGET (2)

=item BUBBLING_PHASE (3)

=back

=head1 SEE ALSO

=over 4

L<HTML::DOM>

L<HTML::DOM::Event::UI>

L<HTML::DOM::Event::Mouse>

L<HTML::DOM::Event::Mutation>

L<HTML::DOM::Node>
