#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('Log::UDP::Server'); }

my $server = Log::UDP::Server->new( handler => sub {} );
isa_ok($server, 'Log::UDP::Server', "new() returns correct isa");
eval {
    local $SIG{'ALRM'} = sub { die("Alarm\n"); };
    alarm(1);
    $server->run();
    alarm(0);
};
if ($@ and $@ ne "Alarm\n") {
    if ( $@ =~ /Unable to bind/ ) {
        diag("Unable to create socket: $@") ;
    }
    else {
        fail("run() failed: $@");
    }
}
