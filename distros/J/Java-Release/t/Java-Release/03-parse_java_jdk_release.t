use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Java::Release qw(parse_java_jdk_release);
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $ret_hr = parse_java_jdk_release('jdk-7u15-linux-i586.tar.gz');
is_deeply(
	$ret_hr,
	{
		'j2se_release' => 7,
		'j2se_update' => 15,
		'j2se_arch' => 'i586',
		'j2se_version' => '7u15',
		'j2se_version_name' => '7 Update 15',
	},
	'Detect JDK 7u15.',
);

# Test.
$ret_hr = parse_java_jdk_release('jdk-7-linux-i586.tar.gz');
is_deeply(
	$ret_hr,
	{
		'j2se_release' => 7,
		'j2se_update' => undef,
		'j2se_arch' => 'i586',
		'j2se_version' => '7',
		'j2se_version_name' => '7 GA',
	},
	'Detect JDK 7.',
);

# Test.
$ret_hr = parse_java_jdk_release('jdk-8u151-linux-arm32-vfp-hflt.tar.gz');
is_deeply(
	$ret_hr,
	{
		'j2se_release' => 8,
		'j2se_update' => 151,
		'j2se_arch' => 'arm32-vfp-hflt',
		'j2se_version' => '8u151',
		'j2se_version_name' => '8 Update 151',
	},
	'Detect JDK 8 (arm32-vfp-hflt).',
);

# Test.
$ret_hr = parse_java_jdk_release('jdk-8u151-linux-arm64-vfp-hflt.tar.gz');
is_deeply(
	$ret_hr,
	{
		'j2se_release' => 8,
		'j2se_update' => 151,
		'j2se_arch' => 'arm64-vfp-hflt',
		'j2se_version' => '8u151',
		'j2se_version_name' => '8 Update 151',
	},
	'Detect JDK 8 (arm64-vfp-hflt).',
);

# Test.
$ret_hr = parse_java_jdk_release('jdk-9.0.4_linux-x64_bin.tar.gz');
is_deeply(
	$ret_hr,
	{
		'j2se_release' => 9,
		'j2se_interim' => 0,
		'j2se_update' => 4,
		'j2se_patch' => undef,
		'j2se_arch' => 'x64',
		'j2se_version' => '9.0.4',
		'j2se_version_name' => '9 Update 4',
	},
	'Detect JDK 9.',
);

# Test.
$ret_hr = parse_java_jdk_release('jdk-12_linux-x64_bin.tar.gz');
is_deeply(
	$ret_hr,
	{
		'j2se_release' => 12,
		'j2se_interim' => undef,
		'j2se_update' => undef,
		'j2se_patch' => undef,
		'j2se_arch' => 'x64',
		'j2se_version' => '12',
		'j2se_version_name' => '12 GA',
	},
	'Detect JDK 12.',
);

# Test.
eval {
	parse_java_jdk_release('foo-bar');
};
is($EVAL_ERROR, "Unsupported release.\n", 'Cannot parse release name.');
clean();
