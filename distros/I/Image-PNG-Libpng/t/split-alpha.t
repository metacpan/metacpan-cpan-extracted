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
use Image::PNG::Libpng qw!split_alpha read_png_file!;

# 08, 16 = bit depths; the leading zero is required.
for my $bd (qw!08 16!) {
    # 4 = grayscale alpha, 6 = rgb alpha
    for my $ct (qw!4 6!) {
	# The n is "non-interlaced", but the interlaced files should
	# come out identical, so we reduce the number of files by a
	# half by recycling the n files as references.
	my $ref = "basn${ct}a${bd}";
	for my $in (qw!i n!) {
	    my $name = "bas$in${ct}a${bd}";
	    # PNG suite files
	    my $file = "$Bin/libpng/$name.png";
	    my $png = read_png_file ($file);
	    my $sep = split_alpha ($png);
	    for my $type (qw!data alpha!) {
		writef ($name, $ref, $type, $sep->{$type});
	    }
	}
    }
}
done_testing ();
exit;

# Write $data to a file and compare it to our reference data from the
# PDF::Builder tests. The original 16 bit RGB data from PDF::Builder
# had an off-by-one error, so that was replaced in Image::PNG::Libpng.

sub writef
{
    my ($name, $ref, $type, $data) = @_;
    my $datafile = "$name-$type.bin";
    my $reffile = "$Bin/split-alpha/$ref-$type.bin";
    open my $IN, '<:raw', $reffile or die $!;
    my $refdata;
    while (<$IN>) {
	$refdata .= $_;
    }
    close $IN or die $!;
    ok ($data eq $refdata, "$type data for $name = $ref data");
}
