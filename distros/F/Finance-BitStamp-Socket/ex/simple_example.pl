#!/usr/bin/perl -wT

use 5.010;
use strict;
use warnings;
use lib qw(../lib);

#use BitStamp::AnyEvent;
#use base qw(BitStamp::AnyEvent);
use Finance::BitStamp::Socket;
use base qw(Finance::BitStamp::Socket);
use Data::Dumper;

use constant DEBUG => 0;

# this will connect to the socket and then start calling the methods below as socket messages arrive...
main->new->go;

# note that a lot of method names are inherited from BitStamp::AnyEvent, so if you want to do more then what
# can be done in a method call, create a new Handler object, send the data there and then have the handler processes
# the responses.

# some additional/optional methods...

# to limit bandwidth to live_trades channel only, uncomment this...
#sub channels { ('live_trades') }

# if you have some special app key for the pusher site, enter it here...
#sub app_key { 'app key goes in here' }


# You want to use these.
# Write these to match what you want to do with the data... like store it into a database.
sub trade {
    my $self = shift;
    my $data = shift;
    print Data::Dumper->Dump([$data],['Trade']) if DEBUG;
    my ($id, $price, $amount) = @{$data}{qw(id price amount)};
    printf "\t[%s] %s BTC @ \$%s/BTC = \$%-8.2f\n", $id, $amount, $price, $price * $amount;
}

sub order_book {
    my $self = shift;
    my $data = shift;
    print Data::Dumper->Dump([$data],['Order Book']) if DEBUG;
    if (exists $data->{bids} or $data->{asks}) {
        foreach my $type (qw(bid ask)) {
            foreach my $listing ($data->{$type . 's'}) {
                foreach my $book (@$listing) {
                    my ($price, $amount) = @$book;
                    printf "\ttype: %s, price: %s, amount: %s\n", $type, $price, $amount;
                }
            }
        }
    }
}

1;


__END__

