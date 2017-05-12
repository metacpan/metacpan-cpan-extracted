package Finance::Bitcoin::Feed::Site;
use strict;

use Mojo::Base 'Mojo::EventEmitter';
use AnyEvent;

our $VERSION = '0.05';

has last_activity_at     => 0;
has last_activity_period => 300;
has 'timer';
has started => 0;

#override this attribute by real site name
has site => '';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->on('timeout',  \&on_timeout);
    $self->on('data_out', \&on_data_out);

    my $timer = AnyEvent->timer(
        after    => 0,       # first invoke ASAP
        interval => 1,       # then invoke every second
        cb       => sub {    # the callback to invoke
            $self->timer_call_back;
        },
    );
    $self->timer($timer);

    return $self;
}

sub on_data_out {
    my ($self, @content) = @_;
    $self->last_activity_at(time());
    $self->emit('output', $self->site, @content);
    return;
}

sub timer_call_back {
    my $self = shift;
    return unless $self->started;
    if ($self->is_timeout) {
        $self->emit('timeout');
    }
    return;
}

sub set_timeout {
    my $self = shift;
    $self->debug('set timeout...');
    $self->last_activity_at(time - $self->last_activity_period - 100);
    return;
}

sub is_timeout {
    my $self = shift;
    return time() - $self->last_activity_at > $self->last_activity_period;
}

sub on_timeout {
    my $self = shift;

    $self->debug('reconnecting...');
    return $self->go;
}

sub go {
    my $self = shift;
    $self->debug("starting ", $self->site);
    $self->started(1);
    $self->last_activity_at(time());
    return;
}

sub debug {
    my $self = shift;
    if ($ENV{FINANCE_BITCOIN_FEED_DEBUG}) {
        say STDERR $self->site, "-------------------------";
        say STDERR @_;
    }
    return;
}

sub error {
    my ($self, @content) = @_;
    say STDERR $self->site, "-------------------------";
    say STDERR @content;
    return;
}

1;

__END__

=head1 NAME

Finance::Bitcoin::Feed::Site - Base class of Finance::Bitcoin::Feed::Site::* modules


=head1 SYNOPSIS

    use Mojo::Base 'Finance::Bitcoin::Feed::Site';
    has site => 'SITENAME';


    sub go{
       my $self = shift;
       #Dont' forget this line:
       $self->SUPER::go();
       # connect the site
       # parse the data
       # and emit the data by call
       $self->emit('data_out', $currency, $price);
    }

=head1 DESCRIPTION

It is a base class. It set some helper attributes and methods, and have an timer event that can restart the connection.
You just need to override the method 'go' to connect to the site.

=head1 ATTRIBUTES

This class  inherits all attributes from L<Mojo::EventEmitter> and add the following new ones:

=head2 last_activity_at

The time that the object receive the data from the server.
It is mainly updated by the method 'on_data_out'

=head2 last_activity_period

if time() - last_activity_at > last_activity_period, then we think the site is disconnected.

=head2 timer

The timer event to restart the connection

=head2 started

The tag that shows the site is running.

=head2 site

The site name which will be print in the debug information.

=head1 METHODS

=head2 new

Create object and set some events and timer

=head2 on_data_out

the callback which will be called when receive the event 'data_out'.
It will Then emit the event 'output'

The args of event data_out is:

    my ($self, $timestamp, $site, $currency, $price) = @_;

The unit of timestamp is ms.

=head2 timer_call_back

The callback called by timer. It will emit event 'timeout' when timeout.

=head2 set_timeout

=head2 is_timeout

=head2 on_timeout

The callback of event 'timeout'. It will call method 'go' to restart the connection

=head2 go

Establish the connection.

=head2 debug

Print debug information if the envrionment variable 'FINANCE_BITCOIN_FEED_DEBUG' is set to true.

=head2 error

Print error information if there is error.

=head1 EVENTS

This class  inherits all events from L<Mojo::EventEmitter> and add the following new ones:

=head2 data_out

It will be emitted by the site module when the site module want to output the data.

=head2 output

It will be emit by this module when print out the data. You can listen on this event to get the output.

=head2 timeout

It will be emit when the timer watch that the connection is timeout

=head1 SEE ALSO

L<Mojo::EventEmitter>

L<Finance::Bitcoin::Feed>

=head1 AUTHOR

Chylli  C<< <chylli@binary.com> >>

