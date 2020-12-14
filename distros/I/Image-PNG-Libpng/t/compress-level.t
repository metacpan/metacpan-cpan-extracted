# Test that the compression level tests work as expected.

# Greg Kennedy contributed this in December 2020.

use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;

binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

BEGIN: {
    use lib "$Bin";
    use IPNGLT;
};
skip_old ();

use Image::PNG::Libpng ':all';

# These are the compression levels used in the PngSuite 

my @levels = (0, 3, 6, 9);

my $filesizes_changed = 0;

# Read the example files

foreach my $src_level (@levels) {
    my $ffile = sprintf("%s/libpng/z%02dn2c08.png", $Bin, $src_level);
    my $src_size = -s $ffile;
    my $src_png = read_png_file ($ffile);
    ok ($src_png, "Read test file '$ffile'");

    foreach my $target_level (@levels) {
	my $dest_png = copy_png ($src_png);
	$dest_png->set_compression_level ($target_level);
	my $output = $dest_png->write_to_scalar ();
	my $dest_size = length $output;
	if ($src_level == $target_level) {
	    cmp_ok ($src_size, '==', $dest_size,
		"source $ffile (level: $src_level, $src_size bytes) equal to target (level: $target_level, $dest_size bytes)" );
	}
	elsif ($src_level < $target_level) {
	    cmp_ok ($src_size, '>=', $dest_size,
		"source $ffile (level: $src_level, $src_size bytes) larger than target (level: $target_level, $dest_size bytes)" );
	    $filesizes_changed++;
	}
	else {
	    cmp_ok ($src_size, '<=', $dest_size,
		"source $ffile (level: $src_level, $src_size bytes) smaller than target (level: $target_level, $dest_size bytes)" );
	    $filesizes_changed++;
	}
    }
}

ok ($filesizes_changed > 0,
    "$filesizes_changed files changed size because of compress_level");

# Test failures

my $ffile = "$Bin/libpng/z06n2c08.png";
my $src_png = read_png_file ($ffile);
ok ($src_png, "Read test file '$ffile'");

# Got errors on Linux when reusing the same PNG, seems to be a bug in libpng.

# http://matrix.cpantesters.org/?dist=Image-PNG-Libpng%200.48_04

# https://github.com/glennrp/libpng/issues/301

eval {
    my $dest_png = copy_png ($src_png);
    $dest_png->set_compression_level (99999);
};
ok ($@, "Error with too big compression level");

eval {
    my $dest_png = copy_png ($src_png);
    $dest_png->set_compression_level (-99999);
};
ok ($@, "Error with too small compression level");

eval {
    my $dest_png = copy_png ($src_png);
    # -1 is Z_DEFAULT_COMPRESSION
    $dest_png->set_compression_level (-1);
    my $output = $dest_png->write_to_scalar ();
};
ok (! $@, "No error with compression -1 for default compression");

eval {
    my $dest_png = copy_png ($src_png);
    # 0 is Z_NO_COMPRESSION
    $dest_png->set_compression_level (0);
    my $output = $dest_png->write_to_scalar ();
};
ok (! $@, "No error with compression level 0 (none)");

eval {
    my $dest_png = copy_png ($src_png);
    # 9 is Z_BEST_COMPRESSION
    $dest_png->set_compression_level (9);
    my $output = $dest_png->write_to_scalar ();
};
ok (! $@, "No error with compression level 9 (best)");


done_testing ();
