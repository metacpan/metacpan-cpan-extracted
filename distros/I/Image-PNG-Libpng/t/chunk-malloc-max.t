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

chunk_ok ('CHUNK_MALLOC_MAX');

my $max = 42;

my $wpng = fake_wpng ();
$wpng->set_chunk_malloc_max ($max);
my $rmax = $wpng->get_chunk_malloc_max ();
cmp_ok ($rmax, '==', $max, "chunk_malloc_max round trip");

done_testing ();
