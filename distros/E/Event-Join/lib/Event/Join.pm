package Event::Join;
use Moose;
use List::Util qw(reduce first);

our $VERSION = '0.06';

has 'events' => (
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    required   => 1,
    auto_deref => 1,
);

has 'on_event' => (
    is       => 'ro',
    isa      => 'CodeRef',
    default  => sub { sub {} },
    required => 1,
);

has 'on_completion' => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);

has 'received_events' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} },
    required => 1,
    handles  => {
        'send_event' => 'set',
        'event_sent' => 'exists',
    },
);

sub _check_event_name {
    my ($self, $event_name) = @_;
    confess "'$event_name' is an unknown event"
      unless first { $event_name eq $_ } $self->events;
}

before send_event => sub {
    my ($self, $event_name) = @_;
    confess "Already sent event '$event_name'"
      if $self->event_sent($event_name);

    $self->_check_event_name($event_name);
};

around send_event => sub {
    my ($orig, $self, $event_name, $value) = @_;
    $self->$orig($event_name, $value);
};

after send_event => sub {
    my ($self, @args) = @_;

    $self->on_event->(@args);

    my $done = reduce { $a && $b } (
        1, map { $self->event_sent($_) } $self->events,
    );

    if($done){
        $self->on_completion->( $self->received_events );
    }
};

sub event_sender_for {
    my ($self, $event) = @_;
    $self->_check_event_name($event);
    return sub {
        $self->send_event($event, @_);
    };
}

1;

__END__

=head1 NAME

Event::Join - join multiple "events" into one

=head1 SYNOPSIS

    use Event::Join;

    my $joiner = Event::Join->new(
        on_completion => sub {
            my $events = shift;
            say 'Child exited with status '. $events->{child_done};
        },
        events => [qw/stdout_closed child_done/],
    );

    watch_fh $stdout, on_eof  => sub { $joiner->send_event('stdout_closed') };
    watch_child $pid, on_exit => sub { $joiner->send_event('child_done', $_[0]) };

    start_main_loop;

=head1 DESCRIPTION

When writing event-based programs, you often want to wait for a number
of events to occur, and then do something.  This module allows you to
do that without blocking.  It simply acts as a receiver for a number
of events, and then calls a callback when all events have occurred.

Note that although I mainly use this for "real" event-based
programming, the technique is rather versatile.  A config file parser
could be implemented like this:

   my $parsed_doc;
   my $parser_state = Event::Join->new(
       events        => [qw/username password machine_name/],
       on_completion => sub { $parsed_doc = shift },
   );

   while(!$parsed_doc && (my $line = <$fh>)){
       chomp $line;
       my ($k, $v) = split /:/, $line;
       $parser_state->send_event($k, $v);
   }

   say 'Username is '. $parsed_doc->{username};

=head1 METHODS

=head2 new

Create an instance.  Needs to be passed C<events>, an arrayref of
valid event names, and C<on_completion>, a coderef to call after all
events have been received.  This coderef is passed a hashref of events
and their values, and will only ever be called once (or not at all, if
the events never arrive).

=head2 send_event( $event_name, [$event_value] )

Send an event.  C<$event_name> is required, and must be an event that
was passed to the constructor.  An exception will be thrown if the
name is not valid.

C<$event_value> is optional; is is the value that goes into the hash
to be passed to the callback.  It can be true or false -- its value
does not affect whether or not the completino callback is called.

Finally, an exception is thrown if an event is sent more than once.

=head2 event_sent( $event_name )

Returns true if the event has been sent, false otherwise.  Note that
the true value is I<not> the value that was passed to C<send_event>,
it is just an arbitrary non-false value.

=head2 event_sender_for( $event_name )

Returns a coderef that sends C<$event_name> when run.  The first
argument to the coderef will become the second argument to
C<send_event>.

=head1 PATCHES

Is the module totally broken?  Patch my repository at:

    http://github.com/jrockway/event-join

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2009 Jonathan Rockway.

This module is Free Software.  You may distribute it under the same
terms as Perl itself.
