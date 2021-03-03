#!perl
use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
use Test::Warnings;

# Error reporting and logging
# https://proj.org/development/reference/functions.html#error-reporting

plan tests => 2 + 5 + 1;

use Geo::LibProj::FFI qw( :all );


my ($e);


# proj_log_level

lives_ok { proj_log_level(0, PJ_LOG_NONE) } 'log_level none';
lives_and { is proj_log_level(0, PJ_LOG_TELL), PJ_LOG_NONE } 'log_level tell';

# proj_errno

diag "testing expected failure ...";
# PJ_LOG_NONE doesn't seem to have an effect on PROJ 7
lives_and { ok ! proj_create(0, "+proj=tpers") } 'proj_create fail';

# proj_context_errno

lives_and { ok $e = proj_context_errno(0) } 'context_errno';
lives_and { ok $e == 1027 || $e == -30 } 'context_errno value';

# proj_errno_set

# proj_errno_reset

# proj_errno_restore

# proj_errno_string

lives_and { like proj_errno_string($e), qr/\bInvalid value\b|\bh\b/i } 'errno_string';

# proj_context_errno_string

lives_and { like proj_context_errno_string(0, $e), qr/\bInvalid value\b|\bh\b/i } 'context_errno_string';


done_testing;
