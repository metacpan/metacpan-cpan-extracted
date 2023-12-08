#!perl
use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
use Test::Warnings 0.010 qw(warning :no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

# Error reporting and logging
# https://proj.org/development/reference/functions.html#error-reporting

plan tests => 2 + 8 + 6 + 4 + $no_warnings;

use Geo::LibProj::FFI qw( :all );


my ($p, $e, $w);


# proj_log_level

lives_ok { proj_log_level(0, PJ_LOG_NONE) } 'log_level none';
lives_and { is proj_log_level(0, PJ_LOG_TELL), PJ_LOG_NONE } 'log_level tell';

# proj_errno
# proj_errno_set
# proj_errno_reset
# proj_errno_restore

lives_and { ok $p = proj_create(0, "EPSG:4326") } 'proj_create';
lives_ok { proj_errno_set($p, 123) } 'errno_set 1';
lives_and { ok $e = proj_errno_reset($p) } 'errno_reset';
lives_ok { proj_errno_set($p, 234) } 'errno_set 2';
lives_and { is proj_errno($p), 234 } 'errno is set';
lives_ok { proj_errno_restore($p, $e) } 'errno_restore';
lives_and { is proj_errno($p), 123 } 'errno is restored';
lives_ok { proj_destroy($p) } 'proj_destroy';

# proj_log_func

my $id = "v46JbYsQTGZfw";  # app_data (to confirm that the custom function is in fact being used)
lives_ok { proj_log_func(0, $id, sub {
	my ($app_data, $log_level, $msg) = @_;
	warn "$app_data (lvl $log_level): $msg";
}) } 'log_func';

# testing expected failure
lives_and {
	proj_log_level(0, PJ_LOG_ERROR);
	$w = ''; $w = warning { $e = proj_create(0, "+proj=tpers"); };
	proj_log_level(0, PJ_LOG_NONE);
	ok ! $e;
} 'proj_create fail';
like ($w, qr/^\Q$id\E/, 'proj_create log_func') or diag 'got warning(s): ', explain($w);
like $w, qr/ \(lvl 1\): /, 'log_func PJ_LOG_ERROR';
like $w, qr/\b1027\b|-30\b/, 'log_func errno';
like $w, qr/\bInvalid value\b|\bh\b/, 'log_func errno_string';

# proj_context_errno

lives_and { ok $e = proj_context_errno(0) } 'context_errno';
lives_and { ok $e == 1027 || $e == -30 } 'context_errno value';

# proj_errno_string

lives_and { like proj_errno_string($e), qr/\bInvalid value\b|\bh\b/i } 'errno_string';

# proj_context_errno_string

lives_and { like proj_context_errno_string(0, $e), qr/\bInvalid value\b|\bh\b/i } 'context_errno_string';


done_testing;
