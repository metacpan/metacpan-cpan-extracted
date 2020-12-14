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

plan skip_all => 'Your libpng does not support pCAL' if ! libpng_supports ('pCAL');


my %pcal = (
    purpose => 'I feel like chicken tonight, chicken tonight',
    x0 => 0.0,
    x1 => 1.0,
    type => 2, # Arbitrary base exponential mapping
    units => 'radian',
    params => [1,2,4.5], # Needs to be 3 otherwise we get "invalid
                         # parameter count" warning from lippng.
);

my $wpng = fake_wpng ();
$wpng->set_pCAL (\%pcal);
my $pcalpng = "$Bin/pcal.png";
my $rpng = round_trip ($wpng, $pcalpng);
my $rpcal = $rpng->get_pCAL ();
is_deeply ($rpcal, \%pcal, "round trip of pCAL chunk");
done_testing ();
