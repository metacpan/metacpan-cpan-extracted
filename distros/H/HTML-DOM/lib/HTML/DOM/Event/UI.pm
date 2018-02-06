package HTML::DOM::Event::UI;

our $VERSION = '0.058';

use warnings; no warnings qw 'utf8 parenthesis';
use strict;

require HTML::DOM::Event;
our @ISA = HTML::DOM::Event::;


sub view          { $_[0]{view      }||() }
sub detail        { $_[0]{detail    } }

sub initUIEvent {
	my $self = $_[0];
	my $x;
	$self->init(map +($_ => $_[++$x]),
		qw( type propagates_up cancellable view detail )
	);
	return;
}

sub init {
	my $self = shift;
	my %args = @_;
	my %my_args = map +($_ => delete $args{$_}),
		qw( view detail );
	$self->SUPER::init(%args);
	%$self = (%$self, %my_args);
	return;
}


*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|||*|

__END__

=head1 NAME

HTML::DOM::Event::UI - A Perl class for HTML DOM UIEvent objects

=head1 VERSION

Version 0.058

=head1 SYNOPSIS

  # ...

=head1 DESCRIPTION

This class provides UIEvent objects for L<HTML::DOM>, which objects are
passed to event handlers for certain event types when they are invoked.
It inherits from L<HTML::DOM::Event>.

=head1 METHODS

See also those inherited from L<HTML::DOM::Event>.

=head2 DOM Attributes

These are both read-only and ignore their arguments.

=over

=item view

The view object associated with the event.

=item detail

A number that's meant to specify some info about the event. For instance,
for the DOMActivate event, 1 is a normal activation, and 2 is a 
hyperactivation (whatever that means). A click event on an element triggers
a DOMActivate event, simply copying the C<detail> attribute from the click
event.

=back

=head2 Other Methods

=over

=item initUIEvent ( $name, $propagates_up, $cancellable, $view, $detail )

This initialises the event object. See L<HTML::DOM::Event/initEvent> for
more detail.

=item init ( ... )

Alternative to C<initUIEvent> that's easier to use:

  init $event
      type => $type,
      propagates_up => 1,
      cancellable => 1,
      view => $view,
      detail => 1,
  ;

=back

=head1 SEE ALSO

=over 4

L<HTML::DOM>

L<HTML::DOM::Event>

L<HTML::DOM::Event::Mouse>
