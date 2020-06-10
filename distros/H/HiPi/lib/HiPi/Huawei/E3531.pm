#########################################################################################
# Package        HiPi::Huawei::E3531
# Description  : E3531 Implementation for HiPi::Huawei::Modem
# Copyright    : Copyright (c) 2019 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Huawei::E3531;
use strict;
use warnings;
use parent qw( HiPi::Huawei::Modem );

my @_package_accessors = qw( );

__PACKAGE__->create_accessors( @_package_accessors );

our $VERSION ='0.81';

sub new {
    my($class, %params) = @_;
    $params{'ip_address'} //= '192.168.8.1';
    my $self = $class->SUPER::new(%params);
    return $self;
}

1;

__END__


