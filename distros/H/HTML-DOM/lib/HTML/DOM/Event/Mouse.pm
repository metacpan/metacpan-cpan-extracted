package HTML::DOM::Event::Mouse;

our $VERSION = '0.058';

use warnings; no warnings qw 'utf8 parenthesis';
use strict;

require HTML::DOM::Event::UI;
our @ISA = HTML::DOM::Event::UI::;


sub screenX          { $_[0]{screen_x      } }
sub screenY        { $_[0]{screen_y  } }
sub clientX          { $_[0]{client_x     } }
sub clientY        { $_[0]{client_y } }
sub ctrlKey          { $_[0]{ctrl     } }
sub shiftKey        { $_[0]{shift    } }
sub altKey          { $_[0]{alt     } }
sub metaKey        { $_[0]{meta    } }
sub button          { $_[0]{button      } }
sub relatedTarget        { $_[0]{rel_target     } }

sub initMouseEvent {
	my $self = $_[0];
	my $x;
	$self->init(map +($_ => $_[++$x]),
		qw( type propagates_up cancellable view detail screen_x
		    screen_y client_x client_y ctrl alt shift meta
		    button rel_target )
	);
	return;
}

sub init {
	my $self = shift;
	my %args = @_;
	my %my_args = map +($_ => delete $args{$_}),
		qw( screen_x screen_y client_x client_y ctrl alt shift
		    meta button rel_target );
	$self->SUPER::init(%args);
	%$self = (%$self, %my_args);
	return;
}


*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|

__END__

=head1 NAME

HTML::DOM::Event::Mouse - A Perl class for HTML DOM mouse event objects

=head1 VERSION

Version 0.058

=head1 SYNOPSIS

  # ...

=head1 DESCRIPTION

This class provides MouseEvent objects for L<HTML::DOM>, which objects are
passed to event handlers for mouse events when they are invoked.
It inherits from L<HTML::DOM::Event::UI>.

=head1 METHODS

See also those inherited from L<HTML::DOM::Event::UI> and
L<HTML::DOM::Event>.

=head2 DOM Attributes

These are all read-only and ignore their arguments.

=over

=item screenX

=item screenY

=item clientX

=item clientY

This represent the coordinates within the screen or window (viewport),
respectively, of the mouse event.

=item ctrlKey

=item shiftKey

=item altKey

=item metaKey

These are booleans that indicate which modifier keys were pressed when the
event occurred.

=item button

A number representing the mouse button: 0 for the left (or the right button
on a left-handed mouse), 1 for the middle and 2 for the right (or left).

=item relatedTarget

References a node which, though it is not the target, was involved in the
event somehow. This is typically used for C<mouseover> events and indicates
the node that the mouse moved off.

=back

=head2 Other Methods

=over

=item initMouseEvent ( $name, $propagates_up, $cancellable, $view, $detail, $screen_x, $screen_y, $client_x, $client_y, $ctrl_key, $alt_key, $shift_key, $meta_key, $button, $related_target )

This initialises the event object. See L<HTML::DOM::Event/initEvent> for
more detail.

=item init ( ... )

Alternative to C<initMouseEvent> that's easier to use:

  init $event
      type => $type,
      propagates_up => 1,
      cancellable => 1,
      view => $view,
      detail => 1,
      screen_x => $foo,
      screen_y => $bar,
      client_x => $baz,
      client_y => $oto,
      ctrl     => $bop,
      alt      => 0,
      shift    => 0,
      meta     => 0,
      button   => 1,
      rel_target => $other_elem,
  ;

=back

=head1 SEE ALSO

=over 4

L<HTML::DOM>

L<HTML::DOM::Event>

L<HTML::DOM::Event::UI>
