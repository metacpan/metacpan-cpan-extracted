# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 4;    # last test to print
use Log::Log4perl::Tiny qw( :easy get_logger LOGLEVEL );

use lib 't';
use TestLLT qw( set_logger log_is );

Log::Log4perl->easy_init({
   format => '%m',
   level  => $OFF,
});
set_logger(get_logger());

log_is {
   FATAL 'whatever';
} '', 'no output for FATAL when log level is $OFF';

log_is {
   ALWAYS 'whatever';
} 'whatever', 'output for ALWAYS when log level is $OFF';

LOGLEVEL $DEAD;

log_is {
   FATAL 'whatever';
} '', 'no output for FATAL when log level is $DEAD';

log_is {
   ALWAYS 'whatever';
} '', 'output for ALWAYS when log level is $DEAD';
