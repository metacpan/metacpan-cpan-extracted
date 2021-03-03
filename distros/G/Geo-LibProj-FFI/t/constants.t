#!perl
use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
use Test::Warnings;

# Constants

plan tests => 1 + 5 + 3 + 1;

use Geo::LibProj::FFI qw( :all );


my ($a);


lives_and { is eval "PJ_DEFAULT_CTX", 0 } 'PJ_DEFAULT_CTX';

# PJ_LOG_LEVEL
lives_and { is eval "PJ_LOG_NONE",  0 } 'PJ_LOG_NONE';
lives_and { is eval "PJ_LOG_ERROR", 1 } 'PJ_LOG_ERROR';
lives_and { is eval "PJ_LOG_DEBUG", 2 } 'PJ_LOG_DEBUG';
lives_and { is eval "PJ_LOG_TRACE", 3 } 'PJ_LOG_TRACE';
lives_and { is eval "PJ_LOG_TELL",  4 } 'PJ_LOG_TELL';

# PJ_DIRECTION
lives_and { is eval "PJ_FWD",   1 } 'PJ_FWD';
lives_and { is eval "PJ_IDENT", 0 } 'PJ_IDENT';
lives_and { is eval "PJ_INV",  -1 } 'PJ_INV';


done_testing;
