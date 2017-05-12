# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 15;    # last test to print

use Log::Log4perl::Tiny qw( :subs );

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
