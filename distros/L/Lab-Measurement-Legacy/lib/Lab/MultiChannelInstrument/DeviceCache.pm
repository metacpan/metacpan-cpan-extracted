package Lab::MultiChannelInstrument::DeviceCache;
#ABSTRACT: Multi-channel instrument device cache
$Lab::MultiChannelInstrument::DeviceCache::VERSION = '3.899';
use v5.20;

use warnings;
use strict;

require Tie::Hash;
use List::MoreUtils qw{ any };


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

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::MultiChannelInstrument::DeviceCache - Multi-channel instrument device cache (deprecated)

=head1 VERSION

version 3.899

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
