package Finance::Bitcoin::Feed;

use strict;
use warnings;

use Mojo::Base 'Mojo::EventEmitter';
use AnyEvent;
use Module::Runtime qw(require_module);
use Carp;

use feature qw(say);

our $VERSION = '0.05';

has 'sites' => sub { [qw(Hitbtc BtcChina CoinSetter LakeBtc BitStamp)] };
has 'output' => sub {
    sub { shift; say join " ", @_ }
};

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->on('output', $self->output);
    return $self;
}

sub run {
    my $self = shift;

    my @sites;

    for my $site_class (@{$self->sites}) {
        $site_class = 'Finance::Bitcoin::Feed::Site::' . $site_class;
        eval { require_module($site_class) }
            || croak("No such module $site_class");
        my $site = $site_class->new;
        $site->on('output', sub { shift; $self->emit('output', @_) });
        $site->go;
        push @sites, $site;
    }

    AnyEvent->condvar->recv;
    return;
}

1;

__END__

=head1 NAME

Finance::Bitcoin::Feed - Collect bitcoin real-time price from many sites' streaming data source

=head1 SYNOPSIS

    use Finance::Bitcoin::Feed;

    #default output is to print to the stdout
    Finance::Bitcoin::Feed->new->run();
    # will print output to the stdout:
    # BITSTAMP BTCUSD 123.00
    

    #or custom your stdout
    open  my $fh, ">out.txt";
    $fh->autoflush();
    my $feed = Finance::Bitcoin::Feed->new(output => sub{
       my ($self, $site, $currency, $price) = @_;
       print $fh "the price currency $currency on site $site is $price\n";
    });
    # let's go!
    $feed->run();

    #you can also custom which site you want to connect
    Finance::Bitcoin::Feed->new(sites => [qw(LakeBtc)])->go;

=head1 DESCRIPTION

L<Finance::Bitcoin::Feed> is a bitcoin realtime data source which collect real time data source from these sites:

=over 4

=item * L<HitBtc|https://hitbtc.com/api#socketio>

=item * L<BtcChina|http://btcchina.org/websocket-api-market-data-documentation-en>

=item * L<CoinSetter|https://www.coinsetter.com/api/websockets/last>

=item * L<<lakebtc api|https://www.lakebtc.com/s/api>

=back

The default output format to the stdout by this format:

   site_name TIMESTAMP CURRENCY price

For example:

   COINSETTER 1418173081724 BTCUSD 123.00

The unit of timestamp is ms.

You can custom your output by listen on the event L<output> and modify the data it received.

Note the followiing sites doesn't give the timestamp. So the timestamp in the result will be 0:

LakeBtc

=head1 METHODS

This class inherits all methods from L<Mojo::EventEmitter>

=head2 new

This method have two arguments by which you can costumize the behavior of the feed:

=head3 sites

which sites you want to connect. It is in fact the array reference of  module names of Finance::Bitcoin::Feed::Site::*. Now there are the following sites:
Hitbtc
BtcChina
CoinSetter
LakeBtc
BitStamp

You can also put your own site module under this namespace and added here.

=head3 output

customize the output format by giving this argument a sub reference. It will be bind to the event 'output'. Please rever to the event <output>.

   # you can customize the output by giving argument 'output' to the new methold
    open  my $fh, ">out.txt";
    $fh->autoflush();
    my $feed = Finance::Bitcoin::Feed->new(output => sub{
       my ($self, $site, $timestamp, $currency, $price) = @_;
       print $fh "the price currency $currency on site $site is $price\n";
    });
    # let's go!
    $feed->run();


=head1 EVENTS

This class inherits all events from L<Mojo::EventEmitter> and add the following new ones:

=head2 output

This event has a default subscriber:

   #output to the stdout, the default action:
   $feed->on('output', sub { shift; say join " ", @_ } );

You can customize the output by giving argument 'output' to the new method

    open  my $fh, ">out.txt";
    $fh->autoflush();
    my $feed = Finance::Bitcoin::Feed->new(output => sub{
       my ($self, $site, $timestamp, $currency, $price) = @_;
       print $fh "the price currency $currency on site $site is $price\n";
    });
    # let's go!
    $feed->run();

Or you can bind output directly to the feed to get multi outout or you should unscribe this event first.

    $feed->on('output', sub {....})

The arguments of this event is:

$self: the site class object
timestamp: the timestamp of the data. If no timestamp is given by the site, then the value of it is 0.
sitename: the site class name
price: the price


=head1 DEBUGGING

You can set the FINANCE_BITCOIN_FEED_DEBUG environment variable to get some advanced diagnostics information printed to STDERR.
And these modules use L<Mojo::UserAgent>, you can also open the MOJO_USERAGENT_DEBUG environment variable:

   FINANCE_BITCOIN_FEED_DEBUG=1
   MOJO_USERAGENT_DEBUG=1

=head1 SEE ALSO

L<Mojo::EventEmitter>

L<Finance::Bitcoin::Feed::Site::BitStamp>

L<Finance::Bitcoin::Feed::Site::Hitbtc>

L<Finance::Bitcoin::Feed::Site::BtcChina>

L<Finance::Bitcoin::Feed::Site::CoinSetter>

L<Finance::Bitcoin::Feed::Site::LakeBtc>

L<Finance::Bitcoin::Feed::Site::BitStamp>

=head1 AUTHOR

Chylli  C<< <chylli@binary.com> >>

=head1 COPYRIGHT

Copyright 2014- Binary.com
