use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::FileType;

subtest 'type constants' => sub {
	is(File,      'file',      'File');
	is(Directory, 'directory', 'Directory');
	is(Symlink,   'symlink',   'Symlink');
	is(Socket,    'socket',    'Socket');
	is(Pipe,      'pipe',      'Pipe');
	is(Block,     'block',     'Block');
	is(Char,      'char',      'Char');
};

subtest 'meta accessor' => sub {
	my $meta = Type();
	is($meta->count, 7, '7 file types');
	ok($meta->valid('file'),      'file is valid');
	ok($meta->valid('directory'), 'directory is valid');
	ok($meta->valid('symlink'),   'symlink is valid');
	ok(!$meta->valid('hardlink'), 'hardlink is not valid');
	is($meta->name('file'), 'File', 'name of file is File');
	is($meta->name('directory'), 'Directory', 'name of directory is Directory');
};

done_testing;
