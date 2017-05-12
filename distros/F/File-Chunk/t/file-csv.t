#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Text::CSV_XS;
use Test::TempDir;
use IO::String;

use ok 'File::Chunk::Handle';

my $root = temp_root();
my $tsv  = Text::CSV_XS->new( { binary => 1, sep_char => "\t", quote_char => undef, eol => "\n" } );
my $csv  = Text::CSV_XS->new( { binary => 1, eol => "\n" } );
my $text = [ '0012006000000000000', "March\xc3\xa9s" ];

my $file = File::Chunk::Handle->new(file => $root->file('foo'), chunk_line_limit => 2);
my $foo  = $file->new_writer('01');
my $bar  = $file->new_writer('02');

for (1..6) {
    $csv->print($foo, [1,2,3,4,5]);
}

for (1..6) {
    $csv->print($bar, ['foo', 'bar']);
}

ok(-f $root->file('foo.d', '01', sprintf("%.8x.chunk", 0)));
ok(-f $root->file('foo.d', '01', sprintf("%.8x.chunk", 1)));
ok(-f $root->file('foo.d', '01', sprintf("%.8x.chunk", 2)));

my $chunk_1_str =  $root->file('foo.d', '01', sprintf("%.8x.chunk", 0))->slurp;
is($chunk_1_str, "1,2,3,4,5\n"x2);

my $reader = $file->new_reader();
for (1..6) {
    is_deeply( $csv->getline($reader), [1,2,3,4,5] );
}
for (1..6) {
    is_deeply( $csv->getline($reader), ['foo', 'bar'] );
}

is( $csv->getline($reader), undef);


my $utf8 = $file->new_writer('03');
$utf8->binmode(':bytes');
$tsv->print($utf8, $text);

done_testing;
