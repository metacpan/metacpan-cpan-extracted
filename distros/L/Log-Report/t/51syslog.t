#!/usr/bin/env perl
# Test syslog, but only mildly

use warnings;
use strict;

use Test::More;
use Log::Report undef, syntax => 'SHORT';

BEGIN
{   eval "require Sys::Syslog";
    plan skip_all => 'Sys::Syslog not installed'
        if $@;

    my $sv = Sys::Syslog->VERSION;
    eval { Sys::Syslog->VERSION(0.11) };
    plan skip_all => "Sys::Syslog too old (is $sv, requires 0.11)"
        if $@;

    plan tests => 1;
    use_ok('Log::Report::Dispatcher::Syslog');
}

dispatcher SYSLOG => 'syslog', to_prio => ['ALERT-' => 'err'];
dispatcher close => 'default';
notice "this is a test";
