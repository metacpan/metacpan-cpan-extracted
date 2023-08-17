# Copyright (C) 2016-2023 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This file is distributed under the same terms and conditions as
# Perl itself.

use strict;

use Test::More;

use File::Globstar qw(globstar);

use lib 't/lib';
use File::Globstar::Tester;

my $tester = File::Globstar::Tester->new;
$tester->createFiles(
	'dir_1/file1.txt',
	'dir.2/file2.txt',
	'dir_1/file3.md',
	'dir.2/file4.md',
);

my @files = globstar '**/*.txt';
is_deeply [sort @files],
	[('dir.2/file2.txt', 'dir_1/file1.txt')],
	'find both txt files';

done_testing;
