#!/usr/bin/env perl
use strict;
use warnings;
use 5.008_006;
our $VERSION = 0.001;

use Log::Any qw( $log );
use Log::Any::Adapter( 'JSONLines',
    canonical => 1,
);

# ###################################################################
# main
sub main {
    # $log->debug('Create account', { nr=>'12345', user=>'Smith'});

    # $log->context->{user} = 'Smith';
    # $log->debug('Create account', { nr=>'12345' });

    # $log->context->{user} = 'Smith';
    # $log->context->{nr} = '12345';
    # $log->debug('Create account');

    # $log->debug('Create account');

    # $log->debug('Create account', {});

    # $log->debug('Create account', 'New Account', { nr=>'12345'}, {user=>'Smith'});

    # $log->debugf('Create account: %s', '12345', {user=>'Smith'});

    # $log->context->{user} = 'Smith';
    # $log->context->{nr} = '12345';
    # $log->debugf('Create account: %s', '12345', {user=>'Smith'});

    $log->context->{user} = 'Smith';
    $log->context->{nr} = '12345';
    $log->debug({user=>'Johnson'});
    $log->debug();
    $log->debug({ muu => 54321 });

    # $log->debug('Person:', sub { return 'Lastname, Firstname'; });

    return 0;
}

exit main(@ARGV);
