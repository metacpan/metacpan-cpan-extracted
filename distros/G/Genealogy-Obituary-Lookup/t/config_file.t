#!/usr/bin/env perl

use strict;
use warnings;

use Errno qw(ENOENT);
use Test::Most;
use File::Spec;
use File::Temp qw/tempfile tempdir/;
use POSIX qw(strerror);	# Import the strerror function
use YAML::XS qw/DumpFile/;

use_ok('Genealogy::Obituary::Lookup');

# Create a temp config file
my $tempdir = tempdir(CLEANUP => 1);
my $config_file = File::Spec->catdir($tempdir, 'config.yml');

# Write a fake config with a directory that exists
my $fake_directory = $tempdir; # just use the tempdir itself
my $class_name = 'Genealogy__Obituary__Lookup';

DumpFile($config_file, {
	$class_name => { directory => $fake_directory }
});

# Create object using the config_file
my $obj = Genealogy::Obituary::Lookup->new(config_file => $config_file);

ok($obj, 'Object was created successfully');
isa_ok($obj, 'Genealogy::Obituary::Lookup');
is($obj->{directory}, $fake_directory, 'Directory was read from config file');

subtest 'Environment test' => sub {
	local $ENV{'Genealogy__Obituary__Lookup__directory'} = '/';

	$obj = Genealogy::Obituary::Lookup->new(config_file => $config_file);

	ok($obj, 'Object was created successfully');
	isa_ok($obj, 'Genealogy::Obituary::Lookup');
	is($obj->{directory}, '/', 'Read config directory from the environment');
};

# Nonexistent config file dies
my $mess = strerror(ENOENT);
throws_ok {
	Genealogy::Obituary::Lookup->new(config_file => '/nonexistent/path/to/config.yml');
} qr/\Q$mess\E/, 'Dies with non-existent config file';

# Malformed config file (not a hashref)
my ($badfh, $badfile) = tempfile();
print $badfh "--- Just a list\n- foo\n- bar\n";
close $badfh;

lives_ok {
	Genealogy::Obituary::Lookup->new(config_file => $badfile);
} 'Runs OK if config is not a hashref';

# Config file exists but has no key for the class
my $nofield_file = File::Spec->catdir($tempdir, 'nokey.yml');
DumpFile($nofield_file, {
	NotTheClass => { directory => $tempdir }
});

# Auto-discovery of the data directory only succeeds when it has been built.
# Under blib/ before `make` completes the database build, the path is absent.
my $has_data_dir = do {
	(my $base = $INC{'Genealogy/Obituary/Lookup.pm'} // '') =~ s/\.pm$//;
	$base && -d File::Spec->catdir($base, 'data');
};

SKIP: {
	skip 'module-relative data/ not present (run `make` first)', 2
		unless $has_data_dir;
	$obj = Genealogy::Obituary::Lookup->new(config_file => $nofield_file, config_dirs => ['']);
	ok($obj, 'Object created with config that lacks class key');
	like($obj->{directory}, qr/lib.Genealogy.Obituary.Lookup.data$/, 'Falls back to default if class key missing (uses directory directly)');
}

# Directory in config file does not exist
my $bad_dir_file = File::Spec->catdir($tempdir, 'baddir.yml');
DumpFile($bad_dir_file, {
	$class_name => { directory => '/definitely/does/not/exist' }
});

lives_ok {
	$obj = Genealogy::Obituary::Lookup->new(config_file => $bad_dir_file, config_dirs => [''])
} 'Throws no error if directory in config file is invalid';

ok(!defined($obj), 'Returns undef if directory in config file is invalid');

done_testing();
