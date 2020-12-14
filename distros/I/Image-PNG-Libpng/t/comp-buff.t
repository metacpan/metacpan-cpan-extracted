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

my $wpng = fake_wpng ();
my $n = 100;
$wpng->set_compression_buffer_size ($n);
my $r = $wpng->get_compression_buffer_size ();
ok ($r == $n, "Got buffer size back");
my $rpng = round_trip ($wpng, "comp-buff.png");
ok ($rpng, "Was able to read and write after setting compression buffer size");

{
    my $warn;
    local $SIG{__WARN__} = sub { $warn = "@_"; };
    my $swpng = fake_wpng ();
    $swpng->set_compression_buffer_size (1);
    ok ($warn, "Got warning '$warn' with small buffer size");
};

done_testing ();
