#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use File::Spec;
use File::Temp qw/tempfile tempdir/;
use Scalar::Util;
use YAML::XS qw/DumpFile/;

use_ok('Locale::Places');

# Create a temp config file
my $tempdir = tempdir(CLEANUP => 1);
my $config_file = File::Spec->catdir($tempdir, 'config.yml');

# Write a fake config
my $class_name = 'Locale::Places';

DumpFile($config_file, {
	$class_name => { cache => 2 }
});

# Create object using the config_file
my $obj = Locale::Places->new(config_file => $config_file);

ok($obj, 'Object was created successfully');
isa_ok($obj, 'Locale::Places');
cmp_ok($obj->{'cache'}, '==', 2, 'read cache from config');

subtest 'Environment test' => sub {
	local $ENV{'Locale::Places::cache'} = 3;

	$obj = Locale::Places->new(config_file => $config_file);

	ok($obj, 'Object was created successfully');
	isa_ok($obj, 'Locale::Places');
	cmp_ok($obj->{'cache'}, '==', 3, 'read cache from config');
};

# Nonexistent config file
throws_ok {
	Locale::Places->new(config_file => '/nonexistent/path/to/config.yml');
} qr/No such file or directory/, 'Throws error for nonexistent config file';

# Malformed config file (not a hashref)
my ($badfh, $badfile) = tempfile();
print $badfh "--- Just a list\n- foo\n- bar\n";
close $badfh;

throws_ok {
	Locale::Places->new(config_file => $badfile);
} qr/Can't load configuration from/, 'Throws error if config is not a hashref';

# Config file exists but has no key for the class
my $nofield_file = File::Spec->catdir($tempdir, 'nokey.yml');
DumpFile($nofield_file, {
	NotTheClass => { cache => 4 }
});
$obj = Locale::Places->new(config_file => $nofield_file);
ok($obj, 'Object created with config that lacks class key');
ok(Scalar::Util::blessed($obj->{'cache'}), 'Falls back to default if class key missing');

done_testing();
