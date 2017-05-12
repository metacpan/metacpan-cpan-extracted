package Finance::Bitcoin::Feed::Site::BitStamp;
use strict;
use Finance::Bitcoin::Feed::Site::BitStamp::Socket;
use Mojo::Base 'Finance::Bitcoin::Feed::Site';

our $VERSION = '0.01';

has 'socket';
has 'site' => 'BITSTAMP';

sub go {
    my $self = shift;
    $self->SUPER::go;
    $self->debug('connecting...');
    $self->socket(Finance::Bitcoin::Feed::Site::BitStamp::Socket->new($self));
    return $self->socket->go;
}

1;
__END__

=head1 NAME

Finance::Bitcoin::Feed::Site::BitStamp -- the class that connect and fetch the bitcoin price data from site bitstamp


=head1 SYNOPSIS

    use Finance::Bitcoin::Feed::Site::BitStamp;
    use AnyEvent;

    my $obj = Finance::Bitcoin::Feed::Site::BitStamp->new();
    # listen on the event 'output' to get the adata
    $obj->on('output', sub { shift; say @_ });
    $obj->go();

    # dont forget this 
    AnyEvent->condvar->recv;

=head1 DESCRIPTION

Connect to site BitStamp by protocol Pusher and fetch the bitcoin price data.

=head1 EVENTS

This class inherits all events from L<Finance::Bitcoin::Feed::Site>.
The most important event is 'output'.

=head2 output

It will be emit by its parent class when print out the data. You can listen on this event to get the output.


=head1 SEE ALSO

L<Finance::Bitcoin::Feed::Site>

L<Finance::BitStamp::Socket>

L<bitstamp|https://www.bitstamp.net/websocket/>

=head1 AUTHOR

Chylli  C<< <chylli@binary.com> >>

