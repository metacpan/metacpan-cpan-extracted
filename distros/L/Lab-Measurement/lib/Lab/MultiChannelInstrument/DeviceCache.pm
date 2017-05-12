package Lab::MultiChannelInstrument::DeviceCache;

use warnings;
use strict;

require Tie::Hash;
use List::MoreUtils qw{ any };

our $VERSION = '3.542';

our @ISA = 'Tie::ExtraHash';

sub TIEHASH {
    my $class = shift;
    my $storage = bless [ {}, @_ ], $class;
    return $storage;
}

sub STORE {
    $_[0][0]{ $_[1] } = $_[2];
    if ( any { $_[1] eq $_ } @{ $_[0][1]->{multichannel_shared_cache} } ) {
        $_[0][1]->device_cache( { $_[1] => $_[2] } );
    }
}

sub FETCH {

    if ( any { $_[1] eq $_ } @{ $_[0][1]->{multichannel_shared_cache} } ) {
        return $_[0][1]->device_cache( $_[1] );
    }
    else {
        return $_[0][0]{ $_[1] };
    }
}

sub EXISTS {
    if ( any { $_[1] eq $_ } @{ $_[0][1]->{multichannel_shared_cache} } ) {
        return exists $_[0][1]->{device_cache}->{ $_[1] };
    }
    return exists $_[0][0]->{ $_[1] };
}

1;
