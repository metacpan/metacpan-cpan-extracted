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
use Image::PNG::Libpng ':all';

BEGIN: {
    use lib "$Bin";
    use IPNGLT;
};

chunk_ok ('CHUNK_CACHE_MAX');

my $png = create_reader ("$Bin/test.png");
my $n = 10;
$png->set_chunk_cache_max ($n);
my $rt = $png->get_chunk_cache_max ();
cmp_ok ($rt, '==', $n, "Round trip of chunk_cache_max");

done_testing ();
