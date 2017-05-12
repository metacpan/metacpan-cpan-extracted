# ABSTRACT: Sugar to let you instrument event listeners at a distance
package Event::Wrappable;
{
  $Event::Wrappable::VERSION = '0.1.1';
}
use strict;
use warnings;
use Scalar::Util qw( refaddr weaken );
use Sub::Exporter -setup => {
    exports => [qw( event event_method )],
    groups => { default => [qw( event event_method )] },
    };
use Sub::Clone qw( clone_sub );

our %INSTANCES;

our @EVENT_WRAPPERS;

sub wrap_events {
    my $class = shift;
    my( $todo, @wrappers ) = @_;
    local @EVENT_WRAPPERS = ( @EVENT_WRAPPERS, @wrappers );
    $todo->();
}

my $LAST_ID;


sub _new {
    my $class = shift;
    my( $event, $raw_event ) = @_;
    bless $event, $class;
    my $storage = $INSTANCES{refaddr $event} = {};
    weaken( $storage->{'wrapped'} = $event );
    weaken( $storage->{'base'}    = $raw_event );
    $storage->{'wrappers'} = [ @EVENT_WRAPPERS ];
    $storage->{'id'} = ++ $LAST_ID;
    return $event;
}


sub event(&) {
    my( $raw_event ) = @_;
    my $event = clone_sub $raw_event;
    if ( @EVENT_WRAPPERS ) {
        for (reverse @EVENT_WRAPPERS) {
            $event = $_->($event);
        }
    }
    return __PACKAGE__->_new( $event, $raw_event );
}


sub event_method($$) {
    my( $object, $method ) = @_;
    my $method_sub = ref($method) eq 'CODE' ? $method : $object->can($method);
    return event { unshift @_, $object; goto $method_sub };
}

sub get_unwrapped {
    my $self = shift;
    return $INSTANCES{refaddr $self}->{'base'};
}

sub get_wrappers {
    my $self = shift;
    my $wrappers = ref $self
                 ? $INSTANCES{refaddr $self}->{'wrappers'}
                 : \@EVENT_WRAPPERS;
    return wantarray ? @$wrappers : $wrappers;
}

sub object_id {
    my $self = shift;
    return $INSTANCES{refaddr $self}->{'id'};
}

sub DESTROY {
    my $self = shift;
    delete $INSTANCES{refaddr $self};
}

sub CLONE {
    my $self = shift;
    foreach (keys %INSTANCES) {
        my $object = $INSTANCES{$_}{'wrapped'};
        $INSTANCES{refaddr $object} = $INSTANCES{$_};
        delete $INSTANCES{$_};
    }
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Event::Wrappable - Sugar to let you instrument event listeners at a distance

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

    use Event::Wrappable;
    use AnyEvent;
    use AnyEvent::Collect;
    my @wrappers = (
        sub {
            my( $event ) = @_;
            return sub { say "Calling event..."; $event->(); say "Done with event" };
        },
    );

    my($w1,$w2);
    # Collect just waits till all the events registered in its block fire
    # before returning.
    collect {
        Event::Wrappable->wrap_events( sub {
            $w1 = AE::timer 0.1, 0, event { say "First timer triggered" };
        }, @wrappers );
        $w2 = AE::timer 0.2, 0, event { say "Second timer triggered" };
    };

    # Will print:
    #     Calling event...
    #     First timer triggered
    #     Done with event
    #     Second timer triggered

    # The below does the same thing, but using method handlers instead.

    use MooseX::Declare;
    class ExampleClass {
        method listener_a {
            say "First timer event handler";
        }
        method listener_b {
            say "Second timer event handler";
        }
    }

    collect {
        my $listeners = ExampleClass->new;
        Event::Wrappable->wrap_events( sub {
            $w1 = AE::timer 0.1, 0, event_method $listeners=>"listener_a";
        }, @wrappers );
        $w2 = AE::timer 0.2, 0, event_method $listeners=>"listener_b";
    };

=head1 DESCRIPTION

This is a helper for creating globally wrapped events listeners.  This is a
way of augmenting all of the event listeners registered during a period of
time.  See L<AnyEvent::Collect> and L<MooseX::Event> for examples of its
use.

A lexically scoped variant might be desirable, however I'll have to explore
the implications of that for my own use cases first.

=head1 CLASS METHODS

=head2 method wrap_events( CodeRef $code, @wrappers )

Adds @wrappers to the event wrapper list for the duration of $code.

   Event::Wrappable->wrap_events(sub { setup_some_events() }, sub { wrapper() });

This change to the wrapper list is dynamically scoped, so any events
registered by functions you call will be wrapped as well.

=head2 method get_wrappers() returns Array|ArrayRef

In list context returns an array of the current event wrappers.  In scalar
context returns an arrayref of the wrappers used on this event.

=head1 METHODS

=head2 method get_unwrapped() returns CodeRef

Returns the original, unwrapped event handler from the wrapped version.

=head2 method get_wrappers() returns Array|ArrayRef

In list context returns an array of the wrappers used on this event.  In
scalar context returns an arrayref of the wrappers used on this event.

=head2 method object_id() returns Int

Returns an invariant unique identifier for this event.  This will not change
even across threads and is suitable for hashing based on an event.

=head1 HELPERS

=head2 sub event( CodeRef $code ) returns CodeRef

Returns the wrapped code ref, to be passed to be an event listener.  This
code ref will be blessed as Event::Wrappable.

=head2 sub event_method( $object, $method ) returns CodeRef

Returns a wrapped code ref suitable for use in an event listener.  The code
ref basically the equivalent of:

    sub { $object->$method(@_) }

Except faster and without the anonymous wrapper sub in the call stack.  Method
lookup is done when you register the event, which means that if you can't
apply any roles to the object after you register event listeners using it.

=for test_synopsis use v5.10.0;

=head1 SOURCE

The development version is on github at L<http://https://github.com/iarna/Event-Wrappable>
and may be cloned from L<git://https://github.com/iarna/Event-Wrappable.git>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

More information can be found at:

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Event-Wrappable>

=back

=head2 Bugs / Feature Requests

Please report any bugs at L<https://github.com/iarna/Event-Wrappable/issues>.

=head1 AUTHOR

Rebecca Turner <becca@referencethis.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Rebecca Turner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

