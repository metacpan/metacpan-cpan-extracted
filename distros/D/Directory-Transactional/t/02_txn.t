#!/usr/bin/perl

use strict;
use warnings;

use Path::Class;
use File::Spec::Functions;

use Test::More 'no_plan';
use Test::Exception;
use Test::TempDir qw(tempdir);

use ok 'Directory::Transactional';

my $name = catfile("foo", "foo.txt");


my $work;

foreach my $nfs ( 0, 1 ) {
	my $dir = tempdir;

	my $file = dir($dir)->file($name);

	{
		alarm 5;
		my $d = Directory::Transactional->new( root => $dir, nfs => $nfs );
		alarm 0;

		isa_ok( $d, "Directory::Transactional" );
		$work = $d->_work;

		ok( not(-e $file), "file does not exist" );

		{
			$d->txn_begin;

			ok( not(-e $file), "root file does not exist after starting txn" );

			is_deeply( [ $d->list("foo") ], [ ], "file listing" );
			is_deeply( [ $d->list("/") ],   [ ], "file listing" );

			$d->openw($name)->print("dancing\n");

			is_deeply( [ $d->list("foo") ], [ "foo/foo.txt" ], "file listing" );
			is_deeply( [ $d->list("/") ],   [ "foo" ], "file listing" );

			ok( not(-e $file), "root file does not exist after writing" );

			$d->txn_commit;
		}

		ok( -e $file, "file exists after comitting" );

		is( $file->slurp, "dancing\n", "file contents" );

		$d->txn_do(sub {
			$d->opena($name)->print("hippies\n");
		});

		ok( -e $file, "file exists after comitting" );

		is( $file->slurp, "dancing\nhippies\n", "file contents" );

		$d->txn_do(sub {
			$d->open(">", $name)->print("dancing\n");
		});

		ok( -e $file, "file exists after comitting" );

		is( $file->slurp, "dancing\n", "file contents" );

		$d->txn_do(sub {
			$d->open(">", "new_file.txt")->print("moose\n");
		});

		is( dir($dir)->file("new_file.txt")->slurp, "moose\n", "new file created, vivify did not die" );

		$d->txn_do(sub { $d->unlink("new_file.txt") });

		ok( not( -e dir($dir)->file("new_file.txt") ), "new file deleted" );

		$d->txn_do(sub {
			my $outer_path = $d->_work_path($name);

			ok( not( -e $outer_path ), "txn not yet modified" );

			is( $file->slurp, "dancing\n", "root file not yet modified" );

			$d->txn_do(sub {

				$d->openw($name)->print("hippies\n");

				ok( not( -e $outer_path ), "txn not yet modified" );

				is( $file->slurp, "dancing\n", "root file not yet modified" );

			});

			is( file($outer_path)->slurp, "hippies\n", "nested transaction comitted to parent" );

			is( $file->slurp, "dancing\n", "root file not yet modified" );
		});

		is( $file->slurp, "hippies\n", "root file comitted" );

		throws_ok {
			$d->txn_do(sub {
				$d->openr($name); # get a read lock, to test downgrading

				$d->txn_do(sub {
					my $path = $d->_work_path($name);

					is( $file->slurp, "hippies\n", "root file unmodified" );

					$d->openw($name)->print("hairy\n");

					is( $file->slurp, "hippies\n", "root file unmodified" );

					die "foo\n";
				});
			});
		} qr/^foo$/, "caught error in txn_do";

		is( $file->slurp, "hippies\n", "root file unmodified" );

		{
			$d->txn_begin;

			ok( -e $file, "file exists" );
			is( $file->slurp, "hippies\n", "unmodified" );

			ok( !$d->is_deleted($name), "not marked as deleted" );

			is_deeply( [ $d->list("foo") ], [ "foo/foo.txt" ], "file " );

			$d->unlink($name);

			ok( $d->is_deleted($name), "marked as deleted" );

			is_deeply( [ $d->list("foo") ], [ ], "file listing" );

			ok( -e $file, "file still exists" );
			is( $file->slurp, "hippies\n", "unmodified" );

			$d->txn_commit;

			ok( not(-e $file), "file removed" );
		}

		$file->openw->print("hippies\n");

		{
			$d->txn_begin;

			ok( -e $file, "file exists" );
			is( $file->slurp, "hippies\n", "unmodified" );

			ok( !$d->is_deleted($name), "not marked as deleted" );

			{
				$d->txn_begin;

				ok( !$d->is_deleted($name), "not marked as deleted" );

				$d->unlink($name);

				ok( $d->is_deleted($name), "marked as deleted" );

				ok( -e $file, "file still exists" );
				is( $file->slurp, "hippies\n", "unmodified" );

				$d->txn_commit;
			}

			ok( $d->is_deleted($name), "marked as deleted" );

			ok( -e $file, "file still exists" );
			is( $file->slurp, "hippies\n", "unmodified" );

			$d->txn_commit;

			ok( not(-e $file), "file removed" );
		}

		$file->openw->print("hippies\n");

		{
			my $targ = dir($dir)->file('oi_vey.txt');

			$d->txn_begin;

			ok( -e $file, "file exists" );
			is( $file->slurp, "hippies\n", "unmodified" );

			ok( !$d->is_deleted($name), "not marked as deleted" );

			{
				$d->txn_begin;

				ok( !$d->is_deleted($name), "not marked as deleted" );
				ok( $d->is_deleted("oi_vey.txt"), "target file is considered deleted" );

				is_deeply( [ $d->list("foo") ], [ "foo/foo.txt" ], "file listing" );
				is_deeply( [ $d->list("/") ],   [ "foo" ], "file listing" );

				$d->rename($name, "oi_vey.txt");

				is_deeply( [ $d->list("foo") ], [ ], "file listing" );
				is_deeply( [ $d->list("/") ],   [ "foo", "oi_vey.txt" ], "file listing" );

				ok( !$d->is_deleted("oi_vey.txt"), "renamed not deleted" );

				ok( -e $d->_work_path("oi_vey.txt"), "target exists in the txn dir" );

				my $stat = $d->stat("oi_vey.txt");
				is( $stat->nlink, 1, "file has one link (stat)" );

				ok( !$d->old_stat($name), "no stat for source file" );

				ok( $d->is_deleted($name), "marked as deleted" );

				ok( -e $file, "file still exists" );
				is( $file->slurp, "hippies\n", "unmodified" );

				$d->txn_commit;
			}

			ok( $d->is_deleted($name), "marked as deleted" );

			ok( -e $file, "file still exists" );
			is( $file->slurp, "hippies\n", "unmodified" );

			$d->txn_commit;

			ok( not(-e $file), "file removed" );

			ok( -e $targ, "target file exists" );

			is( $targ->slurp, "hippies\n", "contents" );
		}
	}

	ok( not( -d $work ), "work dir removed" );
}
