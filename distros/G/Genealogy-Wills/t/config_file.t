#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use File::Spec;
use File::Temp qw/tempfile tempdir/;
use YAML::Any qw/DumpFile/;

use_ok('Genealogy::Wills');

# Create a temp config file
my $tempdir = tempdir(CLEANUP => 1);
my $config_file = File::Spec->catdir($tempdir, 'config.yml');

# Write a fake config with a directory that exists
my $fake_directory = $tempdir; # just use the tempdir itself
my $class_name = 'Genealogy__Wills';

DumpFile($config_file, {
	$class_name => { directory => $fake_directory }
});

# Create object using the config_file
my $obj = Genealogy::Wills->new(config_file => $config_file);

ok($obj, 'Object was created successfully');
isa_ok($obj, 'Genealogy::Wills');
is($obj->{directory}, $fake_directory, 'Directory was read from config file');

subtest 'Environment test' => sub {
	local $ENV{'Genealogy__Wills__directory'} = '/';

	$obj = Genealogy::Wills->new(config_file => $config_file);

	ok($obj, 'Object was created successfully');
	isa_ok($obj, 'Genealogy::Wills');
	is($obj->{directory}, '/', 'Read config directory from the environment');
};

# Nonexistent config file dies
throws_ok {
	Genealogy::Wills->new(config_file => '/nonexistent/path/to/config.yml', config_dirs => ['']);
} qr/Can't load configuration from/, 'Throws error for nonexistent config file';

# Malformed config file (not a hashref)
my ($badfh, $badfile) = tempfile();
print $badfh "--- Just a list\n- foo\n- bar\n";
close $badfh;

lives_ok {
	Genealogy::Wills->new(config_file => $badfile);
} 'Runs OK if config is not a hashref';

# Config file exists but has no key for the class
my $nofield_file = File::Spec->catdir($tempdir, 'nokey.yml');
DumpFile($nofield_file, {
	NotTheClass => { directory => $tempdir }
});
$obj = Genealogy::Wills->new(config_file => $nofield_file, config_dirs => ['']);

ok($obj, 'Object created with config that lacks class key');
like($obj->{directory}, qr/lib.Genealogy.Wills.data$/, 'Falls back to default if class key missing (uses directory directly)');

# Directory in config file does not exist
my $bad_dir_file = File::Spec->catdir($tempdir, 'baddir.yml');
DumpFile($bad_dir_file, {
	$class_name => { directory => '/definitely/does/not/exist' }
});
my $obj2 = Genealogy::Wills->new(config_file => $bad_dir_file);
ok(!defined $obj2, 'Returns undef if directory from config file is invalid');

done_testing();
