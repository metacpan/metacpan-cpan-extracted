# vim: set ft=perl :

use strict;
use warnings;

use File::Basename;
use File::Path;
use File::System::Test;
use Test::More tests => 339;

BEGIN { use_ok('File::System') }

-d 't/root' and rmtree('t/root', 1);
mkpath('t/root', 1, 0700);

-d 't/root2' and rmtree('t/root2', 1);
mkpath('t/root2', 1, 0700);

my $root = File::System->new('Layered', 
	my $root1 = File::System->new('Real', root => 't/root'),
	my $root2 = File::System->new('Real', root => 't/root2'),
);

# Checking initial file system root
is_root_sane($root);

sub uniq {
	my %uniq = map { $_ => 1 } @_;
	return sort keys %uniq;
}

my @dirs1 = qw(
	.bar .bar/.baz .file2 bar file2 quux
);

my @dirs2 = qw(
	.bar .bar/.baz .bar/.baz/.qux bar bar/baz bar/baz/qux bar/baz/quux file2
);

my @dirs = uniq(@dirs1, @dirs2);

my @files1 = qw(
	.baz .file1 .file2/bar .file2/foo .foo .qux
	file1 file2/bar file3 foo
);

my @files2 = qw(
	.baz .file1 .file3 .file4 .foo .qux
	baz file1 file2/foo file4 foo qux
);

my @files = uniq(@files1, @files2);

sub doubled {
	my %uniq;
	local $_;
   	for (@_) { $uniq{$_}++ }
	return sort grep { $uniq{$_} > 1 } keys %uniq;
}

my %skipped = (
	map({ $_ => 1 } doubled(@dirs1, @dirs2, @files1, @files2)),
	'.bar/.baz/.qux' => 1,
	'qux' => 1,
	'.file2' => 1,
	'bar/baz' => 1,
	'bar/baz/qux' => 1,
);

for my $path (@dirs1) {
	ok(defined $root1->create($path, 'd'));
}

for my $path (@files1) {
	ok(defined $root1->create($path, 'f'));
}

for my $path (@dirs2) {
	ok(defined $root2->create($path, 'd'));
}

for my $path (@files2) {
	ok(defined $root2->create($path, 'f'));
}

for my $path (@dirs, @files) {
	ok($root->exists($path));
	is_object_sane($root->lookup($path));
}

# Check to make sure child does essentially the same
ok(defined $root->child('foo'));
ok(!defined $root->child('foo2'));

## Checking child on a deeper scale:
my $child = $root;
is(($child = $child->child('bar'))->path, '/bar');
is(($child = $child->child('baz'))->path, '/bar/baz');
is(($child = $child->child('quux'))->path, '/bar/baz/quux');

for my $path (@dirs, @files) {
 	my $obj = $root->lookup($path);

	is_object_sane($obj);
 
 	# properties
 	is_deeply([ $obj->properties ], [ sort qw/ basename dirname path object_type dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks / ]);
 	is_deeply([ $obj->settable_properties ], [ sort qw/ mode uid gid atime mtime / ]);
 
 	$obj->set_property('mode', 0700);
 	is($obj->get_property('mode') & 0777, 0700);
 
 	my $yesterday = time - 86400;
 	$obj->set_property('atime', $yesterday);
 	$obj->set_property('mtime', $yesterday);
 	is($obj->get_property('atime'), $yesterday);
 	is($obj->get_property('mtime'), $yesterday);
}

for my $path (@files) {
	ok(-f "t/root/$path" || -f "t/root2/$path");

	my $obj = $root->lookup($path);

	is_content_sane($obj);
	is_content_writable($obj);

	unless ($skipped{$path}) {
		my $dir = $root->create('move_test', 'd');	
		is_content_mobile($obj, $dir);
		$dir->remove('force');
	}
}

for my $path (@dirs) {
	ok(-d "t/root/$path" || -d "t/root2/$path");
	
	my $obj = $root->lookup($path);

	is_container_sane($obj);

	### Due to the complexities of layered directory moves, the automatic tests
	### are inadequate.
#	unless ($skipped{$path}) {
#		my $dir = $root->create('move_test', 'd');
#		is_container_mobile($obj, $dir);
#		$dir->remove('force');
#	}
}

is_glob_and_find_consistent($root);

for my $path (@dirs) {
	my $obj = $root->lookup($path);

	is_glob_and_find_consistent($obj);
}

rmtree([ 't/root', 't/root2' ], 1);
