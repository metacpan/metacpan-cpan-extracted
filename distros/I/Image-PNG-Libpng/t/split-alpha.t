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
use File::Compare;
compfu ("$Bin/libpng/basi4a08.png", 'basi4a08');

done_testing ();
exit;

sub compfu
{
    my ($file, $name) = @_;
    my $png = read_png_file ($file);
    my $sep = split_alpha ($png);
    my $datafile = $name.'-data.bin';
    my $origdatafile = "$Bin/split-alpha/$name-data.bin";
    open my $DOUT, '>', $datafile or die $!;
    print $DOUT $sep->{data};
    close $DOUT;
    my $alphafile = $name.'-alpha.bin';
    my $origalphafile = "$Bin/split-alpha/$name-alpha.bin";
    open my $AOUT, '>', $alphafile or die $!;
    print $AOUT $sep->{alpha};
    close $AOUT;
    ok (! compare ($datafile, $origdatafile), "compare $datafile and $origdatafile failed");
    ok (! compare ($alphafile, $origalphafile), "compare $alphafile and $origalphafile failed");
    unlink $datafile or warn "unlink $datafile failed: $!";
    unlink $alphafile or warn "unlink $alphafile failed: $!";
}
