use strict;
use warnings;

use File::Basename;
use File::Path;
use File::System::Test;
use Test::More tests => 2774;

BEGIN { use_ok('File::System') }

-d 't/root' and rmtree('t/root', 1);
mkpath('t/root', 1, 0700);

-d 't/root2' and rmtree('t/root2', 1);
mkpath('t/root2', 1, 0700);

-d 't/root3' and rmtree('t/root3', 1);
mkpath('t/root3', 1, 0700);

-d 't/root4' and rmtree('t/root4', 1);
mkpath('t/root4', 1, 0700);

-d 't/root5' and rmtree('t/root5', 1);
mkpath('t/root5', 1, 0700);

my $root = File::System->new('Table', 
	'/'    => [ 'Real', root => 't/root' ],
);

# Checking initial file system root
is_root_sane($root);

my @mounts = (
	undef,
	[   mount => '/bar'         => 't/root2' => 't/root/bar'  ],
	[   mount => '/bar/baz'     => 't/root3' => 't/root2/baz' ],
	[   mount => '/bar/baz/qux' => 't/root4' => 't/root3/qux' ],
	[   mount => '/.bar'        => 't/root5' => 't/root/.bar' ],
	[ unmount => '/bar/baz/qux' => 't/root4' => 't/root3/qux' ],
	[ unmount => '/.bar'        => 't/root5' => 't/root/.bar' ],
	[ unmount => '/bar/baz'     => 't/root3' => 't/root2/baz' ],
	[ unmount => '/bar'         => 't/root2' => 't/root/bar'  ],
);

my %mounts = (
	'/'            => 't/root',
	'/bar'         => 't/root2',
	'/bar/baz'     => 't/root3',
	'/bar/baz/qux' => 't/root4',
	'/.bar'        => 't/root5',
);

my @dirs = qw(
	.bar .bar/.baz .bar/.baz/.qux .file2
	bar bar/baz bar/baz/qux file2
);

my @files = qw(
	.baz .file1 .file2/bar .file2/foo .file3 .file4 .foo .qux
	baz file1 file2/bar file2/foo file3 file4 foo qux
);

my @expected_mounts = ( '/' );
is_deeply([ sort $root->mounts ], [ sort @expected_mounts ]);

for my $cmd (@mounts) {

	if (defined $cmd && $cmd->[0] eq 'mount') {
		$root->mount($cmd->[1], [ 'Real', root => $cmd->[2] ]);

		push @expected_mounts, $cmd->[1];
		is_deeply([ sort $root->mounts ], [ sort @expected_mounts ]);
	} elsif (defined $cmd) {
		$root->unmount($cmd->[1]);

		@expected_mounts = grep { $cmd->[1] ne $_ } @expected_mounts;
		is_deeply([ sort $root->mounts ], [ sort @expected_mounts ]);
	}

	# create
	for my $path (@dirs) {
		ok(defined $root->create($path, 'd'));
	}

	for my $path (@files) {
		ok(defined $root->create($path, 'f'));
	}

	for my $path (@dirs, @files) {
		ok($root->exists($path));
		is_object_sane($root->lookup($path));
	}

	# Check to make sure child does essentially the same
	ok(defined $root->child('foo'));
	ok(!defined $root->child('foo2'));

	for my $path (@dirs, @files) {
		my $obj = $root->lookup($path);

		is_object_sane($obj);
	 
		# properties
		is_deeply([ $obj->properties ], [ qw/ basename dirname path object_type dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks / ]);
		is_deeply([ $obj->settable_properties ], [ qw/ mode uid gid atime mtime / ]);
	 
		$obj->set_property('mode', 0700);
		is($obj->get_property('mode') & 0777, 0700);
	 
		my $yesterday = time - 86400;
		$obj->set_property('atime', $yesterday);
		$obj->set_property('mtime', $yesterday);
		is($obj->get_property('atime'), $yesterday);
		is($obj->get_property('mtime'), $yesterday);
	}

	for my $path (@files) {
		my ($mp) = 
			sort { -(length($a) <=> length($b)) } 
			grep { $root->normalize_path($path) =~ /^$_/ } $root->mounts;
		my $real_path = $root->normalize_path($path);
		$real_path =~ s[$mp][$mounts{$mp}/];
		ok(-f $real_path);

		my $obj = $root->lookup($path);

		is_content_sane($obj);
		is_content_writable($obj);

		my $dir = $root->create("$mp/move_test", 'd');
		is_content_mobile($obj, $dir);
		$dir->remove('force');
	}

	for my $path (@dirs) {
		my ($mp) = 
			sort { -(length($a) <=> length($b)) } 
			grep { $root->normalize_path($path) =~ /$_/ } $root->mounts;
		my $real_path = $root->normalize_path($path);
		$real_path =~ s[$mp][$mounts{$mp}/];
		ok(-d $real_path);
		
		my $obj = $root->lookup($path);

		is_container_sane($obj);

		next if $mp = $obj->path;
		
		my $dir = $root->create("$mp/move_test", 'd');
		is_container_mobile($obj, $dir);
		$dir->remove('force');
	}

	is_glob_and_find_consistent($root);

	for my $path (@dirs) {
		my $obj = $root->lookup($path);

		is_glob_and_find_consistent($obj);
	}
}

rmtree([ qw( t/root t/root2 t/root3 t/root4 t/root5 ) ], 1);
