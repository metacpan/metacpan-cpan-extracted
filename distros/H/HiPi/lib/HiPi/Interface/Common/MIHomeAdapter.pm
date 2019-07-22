#########################################################################################
# Package        HiPi::Interface::Common::MIHomeAdapter.pm
# Description  : Control Energenie MiHome Adapters
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Interface::Common::MIHomeAdapter;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Interface );
use HiPi qw( :energenie );
use HiPi::Board::ENER314_RT;
use Carp;

__PACKAGE__->create_accessors( qw(  manufacturer_id product_id sensor_id is_switch )  );

our $VERSION ='0.80';

sub new {
    my( $class, %userparams ) = @_;
    
    my %params = (
        manufacturer_id  => ENERGENIE_MANUFACTURER_ID,
    );
    
    foreach my $key (sort keys(%userparams)) {
        $params{$key} = $userparams{$key};
    }
    
    unless( defined($params{device}) ) {
        require ;
        $params{repeat} //= ENERGENIE_TXOOK_REPEAT_RATE;
        my $dev = HiPi::Board::ENER314_RT->new();
        $params{device} = $dev;
        
        
    }
    my $self = $class->SUPER::new(%params);
    
    return $self;
}

1;

__END__