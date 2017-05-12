use strict;
use Test::More tests => 1;

use Log::Dispatch::Config;

package Foo::Logger;
use base qw(Log::Dispatch::Config);

sub DESTROY {
    warn "destroying $_[0]";
}

package main;
Foo::Logger->configure('t/log.cfg');

my $warn;
$SIG{__WARN__} = sub { $warn .= "@_" };
{
    my $foo = Foo::Logger->instance;
    Foo::Logger->reload;
}

like $warn, qr/destroying/;

my $bar = Foo::Logger->instance;

END { unlink 't/log.out' if -e 't/log.out' }
