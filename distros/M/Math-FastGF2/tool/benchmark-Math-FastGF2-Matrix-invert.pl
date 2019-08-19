#!/usr/bin/env perl

use Test::More;

use Benchmark qw(:all);

#use FindBin qw($Bin);
#use lib "$Bin/../lib";

use Data::Dumper;

BEGIN {
    use_ok('Math::FastGF2::Matrix', ':all');
    use_ok('Crypt::IDA', ':all') 
	or BAIL_OUT "Skipping tests that require Crypt::IDA";	
};

my $key = [ 1,2,3,4,5,6,7,8 ];
my @opts = (			# we can re-use to get inverse matrix
    quorum => 4,		# for ida_key_to_matrix
    size   => 4,
    shares => 4,
    sharelist => [0..3],	# for ida_key_to_matrix
    xvals => [0..3],		# for inverse_cauchy_from_xys
    width  => 1,
    key    => $key,
    xylist => $key,				
);
my $mat4_key = ida_key_to_matrix(@opts);
my $inv4_key = ida_key_to_matrix(@opts, 
				 "invert?" => 1,
				 "sharelist" => [0..3]);

ok(ref $mat4_key, "create matrix from key?");
ok(ref $inv4_key, "create inverse matrix from key?");

my $inv4_cauchy;
ok($inv4_cauchy = Math::FastGF2::Matrix
   ->inverse_cauchy_from_xys(@opts, "xvals" => [0..3]),
   "method inverse_cauchy_from_xys returns something?");

ok($inv4_key->eq($inv4_cauchy), "New routine gets same result?");


timethese(10000, {
    "Old m->invert()" => sub { $inv4_key = $inv4_key->invert },
    "New inverse_cauchy_from_xys" => sub {
	$inv4_cauchy = Math::FastGF2::Matrix
	    ->inverse_cauchy_from_xys(@opts, "xvals" => [0..3])
    }}
);

# Go EXTREME(-ish) with a (50,50) scheme
$key = [1..100];
@opts = (			# we can re-use to get inverse matrix
    quorum  => 50,
    size    => 50,		# was "quorum"
    shares  => 50,
    sharelist => [0..49],
    xvals   => [0..49],		# was "sharelist"
    width   => 1,
    key     => $key,
    xylist  => $key,		# was "key"
);
my $mat50_key = ida_key_to_matrix(@opts);
my $inv50_key = ida_key_to_matrix(@opts, 
				 "invert?" => 1,
				 "sharelist" => [0..49]);

ok(ref $mat50_key, "create matrix from key?");
ok(ref $inv50_key, "create inverse matrix from key?");

my $inv50_cauchy;
ok($inv50_cauchy = Math::FastGF2::Matrix
   ->inverse_cauchy_from_xys(@opts, "xvals" => [0..49]),
   "method inverse_cauchy_from_xys returns something?");

ok($inv50_key->eq($inv50_cauchy), "New routine gets same result?");

#print "Expected:\n"; $inv4_key->print;
#print "Got:\n";      $inv4_cauchy->print;


timethese(100, {
    "Old m->invert()" => sub { $inv50_key = $inv50_key->invert },
    "New inverse_cauchy_from_xys" => sub {
	$inv50_cauchy = Math::FastGF2::Matrix
	    ->inverse_cauchy_from_xys(@opts, "xvals" => [0..49])
    }}
);



done_testing;
