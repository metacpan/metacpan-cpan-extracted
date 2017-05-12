# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 24;    # last test to print

use Log::Log4perl::Tiny qw( :levels );

LEVEL:
for my $level (qw( TRACE DEBUG INFO WARN ERROR FATAL OFF DEAD )) {
   no strict 'refs';
   my $glob = $main::{$level};
   if (!ok($glob, "'$level', symbol table entry exists")) {
      fail "skipping further tests for '$level'" for 1 .. 2;
      next LEVEL;
   }
   my $sref = *{$glob}{SCALAR};
   ok(ref($sref),      'scalar entry is a reference');
   ok(defined($$sref), 'scalar entry is defined');
} ## end for my $level (qw( ALL TRACE DEBUG INFO WARN ERROR FATAL OFF ))
