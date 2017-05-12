package Finance::Bitcoin::Feed::Site::LakeBtc;

use strict;
use warnings;
use Finance::Bitcoin::Feed::Site::LakeBtc::Socket;
use Mojo::Base 'Finance::Bitcoin::Feed::Site';
use Mojo::UserAgent;

our $VERSION = '0.05';

has ws_url => 'wss://www.LakeBTC.com/websocket';
has 'ua';
has site => 'LAKEBTC';

sub go {
    my $self = shift;
    $self->SUPER::go;

    $self->ua(Mojo::UserAgent->new());
    $self->debug('connecting...', $self->ws_url);
    $self->ua->websocket(
        $self->ws_url => sub {
            my ($ua, $tx) = @_;
            $self->debug('connected!');
            unless ($tx->is_websocket) {
                $self->error("Site " . $self->site . " WebSocket handshake failed!");

                # set timeout;
                $self->set_timeout;
                return;
            }

            bless $tx, 'Finance::Bitcoin::Feed::Site::LakeBtc::Socket';
            $tx->configure($self);
        });
    return;
}

1;

__END__

=head1 NAME

Finance::Bitcoin::Feed::Site::Lakebtc -- the class that connect and fetch the bitcoin price data from site lakebtc

=head1 SYNOPSIS

    use Finance::Bitcoin::Feed::Site::Lakebtc;
    use AnyEvent;

    my $obj = Finance::Bitcoin::Feed::Site::Lakebtc->new();
    # listen on the event 'output' to get the adata
    $obj->on('output', sub { shift; say @_ });
    $obj->go();

    # dont forget this
    AnyEvent->condvar->recv;

=head1 DESCRIPTION

Connect to site BitStamp by protocol socket.io v2.2.2 and fetch the bitcoin price data.

=head1 EVENTS

This class inherits all events from L<Finance::Bitcoin::Feed::Site> and add some new ones.
The most important event is 'output'.

=head2 output

It will be emit by its parent class when print out the data. You can listen on this event to get the output.

=head2 subscribe

It will subscribe channel from the source site. You can subscribe more channels in the method L</configure>

=head1 SEE ALSO

L<Finance::Bitcoin::Feed::Site>

L<lakebtc api|https://www.lakebtc.com/s/api>

L<Mojo::UserAgent>

=head1 BUGS

This module doesn't print the timestamp because the data source no timestamp.

=head1 AUTHOR

Chylli  C<< <chylli@binary.com> >>

