#!/usr/bin/perl -w
use Test::More tests => 7;
use Test::Exception;

# Make sure Unix::Syslog doesn't get found
BEGIN { use Devel::Hide qw( Unix::Syslog ); } 

# Fake up a Sys::Syslog class
BEGIN { $INC{'Sys/Syslog.pm'} = 1; }
package Sys::Syslog;
our $VERSION = '0.00';
sub _stub    { die [ q{Sys::Syslog stub}, @_ ] }
*openlog    = \&_stub;
*syslog     = \&_stub;
*closelog   = \&_stub;
*setlogsock = sub { };

package main;

BEGIN { use_ok('Log::Syslog::Abstract', qw( openlog syslog closelog )) };

dies_ok { openlog('wookie', 'pid,ndelay', 'mail') } 'openlog hits our stub'; 
is_deeply( $@, [ q{Sys::Syslog stub}, 'wookie', 'pid,ndelay', 'mail' ], '... got expected data via the stub');

dies_ok { syslog('err', '%s', 'Our wookie is broken') } 'syslog hits our stub'; 
is_deeply( $@, [ q{Sys::Syslog stub}, 'err', '%s', 'Our wookie is broken' ], '... got expected data via the stub');

dies_ok { closelog() } 'closelog hits our stub'; 
is_deeply( $@, [ q{Sys::Syslog stub} ], '... got expected data via the stub');
