#!/usr/bin/perl

use Modern::Perl;
use Test::More;
use Cwd;
use Data::Dumper;
use File::Temp qw/ tempdir /;

###### MAIN ######

use_ok('File::RandomGenerator');

test_constructor();
test_generate();

# TODO add test to ensure you return to the original dir

done_testing();

###### END MAIN ######

sub test_constructor {
	my $frg = File::RandomGenerator->new;
	ok( ref $frg eq 'File::RandomGenerator' );
}

sub test_generate {
	
	my $tmpdir = tempdir( DIR => "/tmp" );
	my $frg = File::RandomGenerator->new( root_dir => $tmpdir );
	my $expected_cnt = get_file_cnt( $frg->root_dir ) + $frg->num_files;
	ok( $frg->generate );
	my $actual_cnt = get_file_cnt( $frg->root_dir );
	ok( $expected_cnt == $actual_cnt )
		or say "expected $expected_cnt files, but found $actual_cnt";

	$tmpdir = tempdir( DIR => "/tmp" );
	$frg = File::RandomGenerator->new( root_dir => $tmpdir, depth => 3 );
	$expected_cnt = get_file_cnt( $frg->root_dir ) + $frg->num_files;
	ok( $frg->generate );
	ok( $expected_cnt == get_file_cnt( $frg->root_dir ) );
	ok_dir_cnt( $frg->root_dir, $frg->width, 1, $frg->depth );
}

sub ok_dir_cnt {
	
	my $dir        = shift;
	my $cnt        = shift;
	my $curr_depth = shift;
	my $max_depth  = shift;

	my $cwd = getcwd();
	chdir $dir or die "failed to chdir to $dir: $!";
	my $found = 0;

	opendir my $dh, $dir or die "$!";

	while ( my $e = readdir($dh) ) {
		next if $e eq '.' or $e eq '..';

		if ( -d $e ) {
			$found++;

			if ( $curr_depth + 1 < $max_depth ) {
				ok_dir_cnt( "$dir/$e", $cnt * 2, $curr_depth + 1,
							$max_depth );
			}
		}
	}

	ok( $cnt == $found, "found $found subdirs in dir $dir" )
		or say "expected $cnt dirs, but found $found";

	chdir $cwd or die "failed to chdir to $cwd";
}

sub get_file_cnt {
	my $dir = shift;

	my $orig_dir = getcwd();

	chdir $dir or die "failed to chdir to $dir: $!";
	my $found = 0;

	opendir my $dh, $dir or die "$!";

	while ( my $e = readdir($dh) ) {
		if ( -f $e ) {
			$found++;
		}
	}

	chdir $orig_dir or die "failed to chdir to $orig_dir";

	return $found;
}

sub ok_file_cnt {
	my $dir = shift;
	my $cnt = shift;

	my $cwd = getcwd();
	chdir $dir or die "failed to chdir to $cwd: $!";
	my $found = 0;

	opendir my $dh, $dir or die "$!";

	while ( my $e = readdir($dh) ) {
		next if $e eq '.' or $e eq '..';

		if ( -f $e ) {
			$found++;
		}
	}

	ok( $cnt == $found ) or say "expected $cnt files, but found $found";

	chdir $cwd or die "failed to chdir to $cwd";
}
