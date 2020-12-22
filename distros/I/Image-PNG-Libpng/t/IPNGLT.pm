# The functions in this module are helpers for testing
# Image::PNG::Libpng. The name IPNGLT is just "Image PNG Libpng
# Testing module". This module should not be indexed by CPAN. See
# Makefile.PL.tmpl under "no_index/file".

package IPNGLT;
require Exporter;
our @ISA = qw(Exporter);
# We just export everything by default, because this is not a user module.
our @EXPORT = qw/
		    chunk_ok
		    fake_wpng
		    rmfile
		    round_trip
		    skip_itxt
		    skip_old
		/;
use warnings;
use strict;
use utf8;
use Test::More;
use Image::PNG::Const ':all';
use Image::PNG::Libpng ':all';

# Skip testing if the libpng doesn't seem to support itxt.

sub skip_itxt
{
    if (! libpng_supports ('iTXt') ||
	! libpng_supports ('zTXt') ||
	! libpng_supports ('tEXt') ||
	! libpng_supports ('TEXT')) {
	plan skip_all => 'your libpng does not support iTXt/zTXt/tEXt',
	return 1;
    }
    return 0;
}

# The most recent faulty response is for libpng version 1.6.12.
# http://www.cpantesters.org/cpan/report/f7295c1a-6bf5-1014-a07d-70c0b928df0

# Skip testing of set-text.t and compress-level.t for versions older
# than these, due to bugs or incompatibilities. Ideally the libpng
# PNG_*_SUPPORTED variables would be used here, but those are not very
# reliable.

my $oldmajor = 0; # Reject 0.*
my $oldminor = 5; # Reject 1.[0-5]
my $oldpatch = 12; # Reject 1.6.[0-12]

sub skip_old
{
    my $libpngver = Image::PNG::Libpng::get_libpng_ver ();
    if ($libpngver !~ /^([0-9]+)\.([0-9]+)\.([0-9]+)/) {
	plan skip_all => "Incomprehensible libpng version $libpngver";
	return 1;
    }
    my ($major, $minor, $patch) = ($1, $2, $3);
    if ($major > 1 || $minor > 6) {
	# Get out of here, since the test for $minor or $patch will be
	# tripped by 1.7.1 or 2.1.3 or something.
	return 0;
    }
    if ($major <= $oldmajor) {
	plan skip_all =>
	"Skipping: libpng major version $libpngver <= $oldmajor";
	return 1;
    }
    if ($minor <= $oldminor) {
	plan skip_all =>
	"Skipping: libpng minor version $libpngver <= $oldminor";
	return 1;
    }

    if ($patch <= $oldpatch) {
	plan skip_all =>
	"Skipping: libpng patch $libpngver <= $oldpatch";
	return 1;
    }
    return 0;
}

# Write $png to $filename then read it back in again. 

sub round_trip
{
    my ($png, $filename) = @_;
    rmfile ($filename);
    $png->write_png_file ($filename);
    my $rpng = read_png_file ($filename);
    rmfile ($filename);
    return $rpng;
}

# Clean up for both before and after writing a file.

sub rmfile
{
    my ($filename) = @_;
    if (-f $filename) {
	unlink $filename or warn "Failed to unlink '$filename': $!";
    }
}

# Create a fake write PNG for testing adding chunks.

my %default = (
    width => 1,
    height => 1,
    bit_depth => 8,
    color_type => PNG_COLOR_TYPE_GRAY,
);

sub fake_wpng
{
    my ($ihdr) = @_;
    if (! defined $ihdr) {
	$ihdr = \%default;
    }
    for my $k (keys %default) {
	if (! defined $ihdr->{$k}) {
	    $ihdr->{$k} = $default{$k};
	}
    }
    my $longpng = create_write_struct ();
    $longpng->set_IHDR ($ihdr);
    $longpng->set_rows (['X']);
    return $longpng;
}

sub chunk_ok
{
    my ($chunk) = @_;
    if (! libpng_supports ($chunk)) {
	plan skip_all => "This libpng doesn't support '$chunk'"
    }
}

1;
