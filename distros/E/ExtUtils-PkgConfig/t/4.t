#
# $Id$
#

use strict;
use warnings;

use Test::More tests => 24;
use ExtUtils::PkgConfig;

require './t/swallow_stderr.inc';

$ENV{PKG_CONFIG_PATH} = './t/';

sub contains {
	my ($string, $sub_string) = @_;
	return -1 != index ($string, $sub_string);
}

my $macros;

$macros = ExtUtils::PkgConfig->create_version_macros (qw/test_glib-2.0/, 'GLIB');
ok (contains ($macros, 'GLIB_MAJOR_VERSION (2)'));
ok (contains ($macros, 'GLIB_MINOR_VERSION (2)'));
ok (contains ($macros, 'GLIB_MICRO_VERSION (3)'));
ok (contains ($macros, 'GLIB_CHECK_VERSION'));

# Check that '2.0b2.4' is turned into 2.0.4
$macros = ExtUtils::PkgConfig->create_version_macros (qw/test_non_numeric/, 'TEST');
ok (contains ($macros, 'TEST_MAJOR_VERSION (2)'));
ok (contains ($macros, 'TEST_MINOR_VERSION (0)'));
ok (contains ($macros, 'TEST_MICRO_VERSION (4)'));
ok (contains ($macros, 'TEST_CHECK_VERSION'));

# Check that '2' is turned into 2.0.0
$macros = ExtUtils::PkgConfig->create_version_macros (qw/test_short/, 'TEST');
ok (contains ($macros, 'TEST_MAJOR_VERSION (2)'));
ok (contains ($macros, 'TEST_MINOR_VERSION (0)'));
ok (contains ($macros, 'TEST_MICRO_VERSION (0)'));
ok (contains ($macros, 'TEST_CHECK_VERSION'));

swallow_stderr (sub {
	eval {
		ExtUtils::PkgConfig->create_version_macros (qw/__bad__/, 'BAD');
	};
	ok ($@);
});

my $header = 'eupc_test_tmp.h';

ExtUtils::PkgConfig->write_version_macros (
	$header,
	'test_glib-2.0' => 'GLIB',
	'test_non_numeric' => 'TEST');

ok (-f $header);
ok (open my $fh, '<', $header);
$/ = undef; $macros = <$fh>;
ok (contains ($macros, 'GLIB_MAJOR_VERSION'));
ok (contains ($macros, 'GLIB_MINOR_VERSION'));
ok (contains ($macros, 'GLIB_MICRO_VERSION'));
ok (contains ($macros, 'GLIB_CHECK_VERSION'));
ok (contains ($macros, 'TEST_MAJOR_VERSION'));
ok (contains ($macros, 'TEST_MINOR_VERSION'));
ok (contains ($macros, 'TEST_MICRO_VERSION'));
ok (contains ($macros, 'TEST_CHECK_VERSION'));
close $fh;
unlink $header;

swallow_stderr (sub {
	eval {
	  ExtUtils::PkgConfig->write_version_macros (
		$header,
		'__bad__' => 'BAD');
	};
	ok ($@);
});

if (-f $header) {
	unlink $header;
}
