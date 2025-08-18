#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use File::Spec;
use File::Temp qw/tempfile tempdir/;
use YAML::XS qw/DumpFile/;

use_ok('Log::Abstraction');

# Create a temp config file
my $tempdir = tempdir(CLEANUP => 1);
my $config_file = File::Spec->catdir($tempdir, 'config.yml');

# Write a fake config
my $class_name = 'Log::Abstraction';

DumpFile($config_file, {
	$class_name => { script_name => 'foo' }
});

# Create object using the config_file
my $obj = Log::Abstraction->new(config_file => $config_file);

cmp_ok($obj->is_debug(), '==', 0, 'is_debug is not set');

ok($obj, 'Object was created successfully');
isa_ok($obj, 'Log::Abstraction');
cmp_ok($obj->{'script_name'}, 'eq', 'foo', 'read script_name from config');

# Windows gets confused with the case, it seems that it only likes uppercase environment variables
if($^O ne 'MSWin32') {
	subtest 'Environment test' => sub {
		local $ENV{'Log::Abstraction::script_name'} = 'bar';

		$obj = Log::Abstraction->new(config_file => $config_file);

		ok($obj, 'Object was created successfully');
		isa_ok($obj, 'Log::Abstraction');
		cmp_ok($obj->{'script_name'}, 'eq', 'bar', 'read script_name from environment');
	}
};

# Nonexistent config file is ignored
throws_ok {
	Log::Abstraction->new(config_file => '/nonexistent/path/to/config.yml');
} qr/File not readable/, 'Throws error for nonexistent config file';

# Malformed config file (not a hashref)
# my ($badfh, $badfile) = tempfile();
# print $badfh "--- Just a list\n- foo\n- bar\n";
# close $badfh;

# throws_ok {
	# Log::Abstraction->new(config_file => $badfile);
# } qr/Can't load configuration from/, 'Throws error if config is not a hashref';

# Config file exists but has no key for the class
my $nofield_file = File::Spec->catdir($tempdir, 'nokey.yml');
DumpFile($nofield_file, {
	NotTheClass => { script_name => 'xyzzy' }
});
$obj = Log::Abstraction->new(config_file => $nofield_file);
ok($obj, 'Object created with config that lacks class key');
ok(!defined($obj->{'script_name'}), 'Falls back to default if class key missing');

done_testing();
