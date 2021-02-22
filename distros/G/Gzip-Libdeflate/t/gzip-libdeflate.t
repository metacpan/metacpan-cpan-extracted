# This is a test for module Gzip::Libdeflate.

use warnings;
use strict;
use utf8;
use Test::More;
use_ok ('Gzip::Libdeflate');
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use FindBin '$Bin';

use Gzip::Libdeflate;

for my $type (qw!gzip deflate zlib!) {
    for my $level (1..12) {
	my $c = Gzip::Libdeflate->new (type => $type, level => $level);
	my $in = "monkey business! " x 100;
	# Be careful since this uses length & that is not the number of
	# bytes if $in is a character string.
	my $size = length ($in);
	my $out = $c->compress ($in);
	cmp_ok (length ($out), '<', length ($in), "Compressed $type $level");
	my $rt = $c->decompress ($out, $size);
	is ($rt, $in, "Round trip $type $level");
    }
}

# Use default gzip type
my $d = Gzip::Libdeflate->new ();
open my $gzin, "<:raw", "$Bin/index.html.gz" or die $!;
my $guff = '';
while (<$gzin>) {
    $guff .= $_;
}
my $guffout = $d->decompress ($guff);
like ($guffout, qr/<html/, "Decompressed a file");

done_testing ();

