#!perl -wT

# use lib 'lib';

use strict;
use warnings;

use Carp;
use Test::Most tests => 15;
use Test::Exception;

BEGIN {
	use_ok('File::Open::NoCache::ReadOnly');
}

# isa_ok(File::Open::NoCache::ReadOnly->new(), 'File::Open::NoCache::ReadOnly', 'Creating File::Open::NoCache::ReadOnly object');
# isa_ok(File::Open::NoCache::ReadOnly::new(), 'File::Open::NoCache::ReadOnly', 'Creating File::Open::NoCache::ReadOnly object');
# isa_ok(File::Open::NoCache::ReadOnly->new->new(), 'File::Open::NoCache::ReadOnly', 'Cloning File::Open::NoCache::ReadOnly object');
ok(!defined(File::Open::NoCache::ReadOnly::new()));

# Test 1: No arguments, should carp and return undef
{
	local $@;
	local $SIG{__WARN__} = sub { $@ = shift };
	my $obj = File::Open::NoCache::ReadOnly->new();
	like($@, qr/Usage: File::Open::NoCache::ReadOnly->new/, 'Carps on no arguments');
	ok(!defined $obj, 'Returns undef when no arguments given');
}

my $filename = 'lib/File/Open/NoCache/ReadOnly.pm';

# Test 2: Hashref arguments
{
	my $obj = File::Open::NoCache::ReadOnly->new({ filename => $filename });
	isa_ok($obj, 'File::Open::NoCache::ReadOnly', 'Creates object with hashref');
	cmp_ok($obj->{filename}, 'eq', $filename, 'Correctly sets filename');
}

# Test 3: Hash arguments
{
	my $obj = File::Open::NoCache::ReadOnly->new(filename => $filename);
	isa_ok($obj, 'File::Open::NoCache::ReadOnly', 'Creates object with hash arguments');
	cmp_ok($obj->{filename}, 'eq', $filename, 'Correctly sets filename');
}

# Test 4: Odd non-hash arguments, should set filename
{
	my $obj = File::Open::NoCache::ReadOnly->new($filename);
	isa_ok($obj, 'File::Open::NoCache::ReadOnly', 'Creates object with filename argument');
	cmp_ok($obj->{filename}, 'eq', $filename, 'Correctly sets filename');
}

# Test 5: fd is correct
{
	my $obj = File::Open::NoCache::ReadOnly->new(filename => $filename);
	isa_ok($obj, 'File::Open::NoCache::ReadOnly', 'Creates object with existing filename');
	ok(defined $obj->{fd}, 'File descriptor is set');
}

# Test 6: Non-existent file with filename and fatal => 1
{
	throws_ok { File::Open::NoCache::ReadOnly->new(filename => 'non_existent.txt', fatal => 1) }
		qr/non_existent.txt: /, 'Croaks on non-existent file with fatal';
}

# Test 7: Non-existent file with filename and no fatal flag
{
	local $@;
	local $SIG{__WARN__} = sub { $@ = shift };
	my $obj = File::Open::NoCache::ReadOnly->new(filename => 'non_existent.txt');
	like($@, qr/non_existent.txt: /, 'Carps on non-existent file without fatal');
	ok(!defined $obj, 'Returns undef when file not found without fatal');
}
