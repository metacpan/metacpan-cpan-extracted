# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 43;    # last test to print

use Log::Log4perl::Tiny qw( :easy );

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

for my $subname (
   qw(
   ALWAYS TRACE DEBUG INFO WARN ERROR FATAL
   LOGWARN LOGDIE LOGEXIT LOGCARP LOGCLUCK LOGCROAK LOGCONFESS
   get_logger
   )
  )
{
   can_ok(__PACKAGE__, $subname);
} ## end for my $subname (qw( ALWAYS TRACE DEBUG INFO WARN ERROR FATAL...

can_ok('Log::Log4perl', $_) for qw( import easy_init );

my $logger = Log::Log4perl::Tiny::get_logger();
ok($logger, 'got a logger instance');

$logger->level($Log::Log4perl::Tiny::DEBUG);

use Log::Log4perl qw( :easy );    # should be a no-op
Log::Log4perl->easy_init($Log::Log4perl::Tiny::ERROR);

is($logger->level(), $Log::Log4perl::Tiny::ERROR, 'easy_init');
