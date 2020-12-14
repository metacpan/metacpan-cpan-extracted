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

my %offs = (x_offset => 1, y_offset => 1, unit_type => 0);
my $wpng = fake_wpng ();
$wpng->set_oFFs (\%offs);
my $rpng = round_trip ($wpng, "$Bin/offs.png");
is_deeply ($rpng->get_oFFs (), \%offs, "Round trip of oFFs chunk");

done_testing ();
