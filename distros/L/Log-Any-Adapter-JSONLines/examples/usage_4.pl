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
    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
    $log->context->{serious} = 0;
    $log->trace('Logging TRACE', { card=>'0123456789012345' });
    $log->debug('Logging DEBUG', { card=>'0123456789012345' });
    $log->infof('Logging INFO %s', { card=>'0123456789012345' });
    $log->warning('Logging WARNING', { card=>'0123456789012345' });
    {
        ## no critic (Variables::ProhibitLocalVars)
        local $log->context->{serious} = 1;
        $log->error('Logging 1 ERROR', );
        $log->errorf('Logging 2 %s', 'ERROR');
        $log->errorf('Logging 3 %s', 'ERROR', { yes=>'no'});
        $log->errorf('Logging 4 %s, %s', 'ERROR', { yes=>'no'});
        local $log->context->{really} = 1;
        $log->fatal('Logging FATAL', { card=>'0123456789012345', }, { owner => 'Mikko' });
        $log->error();
    }
    $log->debug('Logging DEBUG', [1,2,3], {a=>1,b=>2}, sub { 'I am Mikko'}, [6,9,12]);
    return 0;
}

exit main(@ARGV);
