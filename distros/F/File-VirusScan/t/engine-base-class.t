package TestVirusScan::BaseEngine;
use strict;
use warnings;

use base qw( Test::Class );

use Test::More;
use Test::Exception;
use File::Temp ();

use File::VirusScan::Engine;

sub list_files : Test(8)
{
	my ($self) = @_;
	my $s = 'File::VirusScan::Engine';

	my $dir = File::Temp::tempdir( CLEANUP => 1 );	

	my @files = $s->list_files( $dir );
	is( scalar @files, 0, 'Empty list from empty directory');

	`touch $dir/file1`; # I am lazy
	@files = $s->list_files( $dir );
	is( scalar @files, 1, 'Single file in directory');
	is( $files[0], "$dir/file1", '... with correct name');

	@files = $s->list_files( "$dir/file1" );
	is( scalar @files, 1, 'One in list from filename instead of directory');
	is( $files[0], "$dir/file1", '... with correct name');

	mkdir "$dir/subdir";
	mkdir "$dir/subdir/subsubdir";
	`touch $dir/subdir/subsubdir/file2`; # I am stil lazy
	@files = sort $s->list_files( $dir );
	is( scalar @files, 2, 'Two files total below directory');
	is( $files[0], "$dir/file1", '... correct name for first');
	is( $files[1], "$dir/subdir/subsubdir/file2", '... correct name for second');
}


__PACKAGE__->runtests() unless caller();
1;
