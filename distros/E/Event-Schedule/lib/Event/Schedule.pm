package Event::Schedule;

use warnings;
use strict;

=head1 NAME

Event::Schedule - A simple way to organize timed events in, say, an IRC bot.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This class implements a very simple event schedule to be used in-process for simple functionality.
It was developed in the context of an IRC bot to enforce Roberts Rules of Order on a channel;
when someone is given the floor for a minute, we can simply schedule a call to a warning function in 
60 seconds.  We set a timer to call the event queue every second.

Obviously, long-running functions should not be called here.  Use threads for that.

The event itself is a closure, or anonymous coderef.  This makes it easy to encapsulate a given call
with its parameters.  If you've never encountered closures before, then this is your lucky day.

    use Event::Schedule;

    my $queue = Event::Schedule->new();

    # Let's schedule an event for a minute from now.
    $queue->add (60, sub { my_function ($a, $b); });

    ...  (we wait 60 seconds) ...
    $queue->tick(); # My function executes.

Future functionality could include a queue lister and perhaps some callback way to remove obsolete
events from the queue.

=head1 FUNCTIONS

=head2 new()

Creates a new event queue.  Notes the time when it does so.

=cut

sub new {
   my ($class) = @_;
   my $self = { last_tick => time,
                queue => {}
              };
   bless $self, $class;
   return $self;
}

=head2 add($time, $event)

Adds a scheduled event to be run after I<time> seconds.  The event is a closure, i.e. a coderef.

=cut

sub add {
   my ($self, $time, $event) = @_;

   $time += time();  # Time is given in seconds from right now.
   $self->{queue}->{$time} = [] unless $self->{queue}->{$time};
   push @{$self->{queue}->{$time}}, $event;
}

=head2 tick()

Call this every second to run all the closures scheduled for every second between the last tick and the time noe.

=cut

sub tick {
   my ($self) = @_;

   my $time;
   for ($time = $self->{last_tick},
        $time <= time(),
        $time++) {
      if ($self->{queue}->{$time}) {
         my $v = $self->{queue}->{$time};
         delete $self->{queue}->{$time};
         foreach my $event (@$v) {
            &$event();  # It's a closure!
         }
      }
   }
   $self->{last_tick} = time();
}


=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-event-schedule at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Event-Schedule>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Event::Schedule


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Event-Schedule>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Event-Schedule>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Event-Schedule>

=item * Search CPAN

L<http://search.cpan.org/dist/Event-Schedule/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Michael Roberts, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Event::Schedule
