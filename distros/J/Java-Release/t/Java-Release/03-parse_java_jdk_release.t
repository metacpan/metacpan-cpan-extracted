use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Java::Release qw(parse_java_jdk_release);
use Test::More 'tests' => 49;
use Test::NoWarnings;

# Test.
my $test_file = 'j2sdk-1_3_1_20-linux-i586.bin';
my $ret = parse_java_jdk_release($test_file);
is($ret->arch, 'i586', "Architecture from '$test_file'.");
is($ret->release, 3, "Release version from '$test_file'.");
is($ret->interim, 1, "Interim version from '$test_file'.");
is($ret->update, 20, "Update version from '$test_file'.");
is($ret->os, 'linux', "OS from '$test_file'.");
is($ret->version, '3.1.20', "Version from '$test_file'.");
is($ret->version_name, 'Java 3 Major 1 Update 20', "Version name from '$test_file'.");

# Test.
$test_file = 'jdk-7-linux-i586.tar.gz';
$ret = parse_java_jdk_release($test_file);
is($ret->arch, 'i586', "Architecture from '$test_file'.");
is($ret->release, '7', "Release from '$test_file'.");
is($ret->os, 'linux', "OS from '$test_file'.");
is($ret->version, '7', "Version from '$test_file'.");
is($ret->version_name, 'Java 7 GA', "Version name from '$test_file'.");

# Test.
$test_file = 'jdk-7u15-linux-i586.tar.gz';
$ret = parse_java_jdk_release($test_file);
is($ret->arch, 'i586', "Architecture from '$test_file'.");
is($ret->release, 7, "Release from '$test_file'.");
is($ret->update, 15, "Update version from '$test_file'.");
is($ret->os, 'linux', "OS from '$test_file'.");
is($ret->version, '7.0.15', "Version from '$test_file'.");
is($ret->version('old'), '7u15', "Version from '$test_file' (old version).");
is($ret->version_name, 'Java 7 Update 15', "Version name from '$test_file'.");

# Test.
$test_file = 'jdk-8u151-linux-arm32-vfp-hflt.tar.gz';
$ret = parse_java_jdk_release($test_file);
is($ret->arch, 'arm32-vfp-hflt', "Architecture from '$test_file'.");
is($ret->release, 8, "Release from '$test_file'.");
is($ret->update, 151, "Update version from '$test_file'.");
is($ret->os, 'linux', "OS from '$test_file'.");
is($ret->version, '8.0.151', "Version from '$test_file'.");
is($ret->version('old'), '8u151', "Version from '$test_file' (old version).");
is($ret->version_name, 'Java 8 Update 151', "Version name from '$test_file'.");

# Test.
$test_file = 'jdk-8u151-linux-arm64-vfp-hflt.tar.gz';
$ret = parse_java_jdk_release($test_file);
is($ret->arch, 'arm64-vfp-hflt', "Architecture from '$test_file'.");
is($ret->release, 8, "Release from '$test_file'.");
is($ret->update, 151, "Update version from '$test_file'.");
is($ret->os, 'linux', "OS from '$test_file'.");
is($ret->version, '8.0.151', "Version from '$test_file'.");
is($ret->version('old'), '8u151', "Version from '$test_file' (old version).");
is($ret->version_name, 'Java 8 Update 151', "Version name from '$test_file'.");

# Test.
$test_file = 'jdk-9.1.4_linux-x64_bin.tar.gz';
$ret = parse_java_jdk_release($test_file);
is($ret->arch, 'x64', "Architecture from '$test_file'.");
is($ret->release, 9, "Release from '$test_file'.");
is($ret->interim, 1, "Interim from '$test_file'.");
is($ret->update, 4, "Update version from '$test_file'.");
is($ret->os, 'linux', "OS from '$test_file'.");
is($ret->version, '9.1.4', "Version from '$test_file'.");
is($ret->version_name, 'Java 9 Major 1 Update 4', "Version name from '$test_file'.");

# Test.
$test_file = 'jdk-12_linux-x64_bin.tar.gz';
$ret = parse_java_jdk_release($test_file);
is($ret->arch, 'x64', "Architecture from '$test_file'.");
is($ret->release, 12, "Release from '$test_file'.");
is($ret->interim, undef, "Interim from '$test_file'.");
is($ret->update, undef, "Update version from '$test_file'.");
is($ret->os, 'linux', "OS from '$test_file'.");
is($ret->version, '12', "Version from '$test_file'.");
is($ret->version_name, 'Java 12 GA', "Version name from '$test_file'.");

# Test.
eval {
	parse_java_jdk_release('foo-bar');
};
is($EVAL_ERROR, "Unsupported release.\n", 'Cannot parse release name.');
clean();
