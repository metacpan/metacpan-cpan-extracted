#!/usr/bin/perl

use strict;

use Test::More qw(no_plan);

use Encode;

BEGIN {
	use_ok qw(IO::Easy);
	use_ok qw(IO::Easy::File);
	use_ok qw(IO::Easy::Dir);
};

#-----------------------------------------------

sub touch_test {
	my $file = shift;
	
	my ($at1, $mt1, $ct1) = ($file->stat (qw(atime mtime ctime)));

	sleep 2;

	$file->touch;

	my ($at2, $mt2, $ct2) = ($file->stat (qw(atime mtime ctime)));
	
	ok ($at1 < $at2, "$at1 < $at2");
	ok ($mt1 < $mt2, "$mt1 < $mt2");
	ok ($at2 == $mt2, "$at2 == $mt2");
	# ok ($ct1 == $ct2, "$ct1 == $ct2"); # fails at least in mac os x
	
}

#-----------------------------------------------

# File
{
	my $test_file_name = 'test_file_name';
	my $file = file ($test_file_name);

	$file->store;
	touch_test ($file);

	unlink $file;
	$file->touch;

	ok -f $file;

	my $data = "data";
	$file->store ($data);
	$file->touch;

	ok ($file->contents eq $data); # :)

	unlink $file;
}


# Dir
{
	my $test_dir_name = 'test_dir_name';
	my $dir = dir ($test_dir_name);

	$dir->create;

	touch_test ($dir);

	$dir->rm_tree;
	$dir->touch;

	ok -d $dir;

	$dir->rm_tree;
}

# Generic
# apla: very bad example
{
	my $test_file_name = 'test_file_name';
	my $io = IO::Easy->new ($test_file_name);
	
	$io->as_file->store;

	touch_test ($io);

	unlink $io;
	
	$io->as_dir->create;

	touch_test ($io);

	$io->as_dir->rm_tree;
}
