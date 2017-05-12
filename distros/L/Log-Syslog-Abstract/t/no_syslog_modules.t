#!/usr/bin/perl -w
use Test::More tests => 2;
use Test::Exception;

# Make sure no syslog module gets found
use Devel::Hide qw( Unix::Syslog Sys::Syslog ); 

dies_ok { eval 'use Log::Syslog::Abstract qw( openlog syslog closelog );'; die $@ if $@; } 'use() dies';
like( $@, qr/Unable to detect either Unix::Syslog or Sys::Syslog/, '... with expected error');
