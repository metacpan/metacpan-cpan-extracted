#########################################################################################
# Package        HiPi::Huawei::Errors
# Description  : Error codes for HiPi::Huawei
# Copyright    : Copyright (c) 2019 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Huawei::Errors;
use strict;
use warnings;
use parent qw( HiPi::Class );

our $VERSION ='0.81';

our $errors = {
    '101'       => 'unable to get session tokens',
    '100'       => 'unknown error',
    '102'       => 'must provide user, old password and new password',
    '103'       => 'set login required before you attempt to change password',
    '104'       => 'bad serial number',
    '105'       => 'must provide user and password',
    '106'       => 'unknown error deserialising response',
    
    '110'       => 'your safety settings prevent this potentially damaging action',
    '111'       => 'invalid day value',
    '112'       => 'invalid limit value',
    '113'       => 'invalid threshold value',
    
    '400'       => 'error in http request / response',
    
    '100002'    => 'call not supported',
    '100003'    => 'access forbidden in current session context',
    '100004'    => 'system busy',
    '100005'    => 'system system reports request failed',
    '100006'    => 'invalid request parameter',
    '108001'    => 'invalid username',
    '108002'    => 'invalid password',
    '108003'    => 'user already logged in',
    '108006'    => 'invalid username or password',
    '108007'    => 'maximum session login attempts exceeded',
    '120001'    => 'voice busy',
    '125001'    => 'invalid token',
    '125002'    => 'invalid session',
    '125003'    => 'invalid token or session',
    
    '103024'    => 'serial number check failed',
    '103025'    => 'serial number check failed attempts exceed maximum 3 allowed',
};


sub get_error_message {
    my( $class, $errorcode ) = @_;
    $errorcode ||= 500;
    my $errorstring = $errors->{$errorcode} || $errors->{'100'};
    return $errorstring;
}

sub dump_errors {
    my $output = '';
    for my $key ( sort { $a <=> $b } keys %$errors ) {
        $output .= sprintf( qq(%-10s %s\n), $key, $errors->{$key} );
    }
    return $output;
}


1;

__END__


