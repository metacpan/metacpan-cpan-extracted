# perl
#$Id$
# 01_oo_lists_dual_reg_sorted.t
use strict;
use Test::More tests =>  30;
use List::Compare;
use lib ("./t");
use Test::ListCompareSpecial qw( :seen :wrap :arrays :hashes :results );
use IO::CaptureOutput qw( capture );

my @pred = ();
my %seen = ();
my %pred = ();
my @unpred = ();
my (@unique, @complement, @intersection, @union, @symmetric_difference, @bag);
my ($unique_ref, $complement_ref, $intersection_ref, $union_ref,
$symmetric_difference_ref, $bag_ref);
my ($LR, $RL, $eqv, $disj, $return, $vers);
my (@nonintersection, @shared);
my ($nonintersection_ref, $shared_ref);
my ($memb_hash_ref, $memb_arr_ref, @memb_arr);
my ($unique_all_ref, $complement_all_ref);
my @args;

my ($lc, $lca);

my %h10 = (
	abel  => 2, baker => 1, camera => 1, delta => 1, edward => 1, fargo => 1,
	golfer   => q{one},
);

my %h11 = (
	baker => 1, camera => 1, delta => 2, edward => 1, fargo => 1, golfer => 1,
	hilton   => 1,
);

my %h12 = (
	fargo    => 1, golfer   => 1, hilton   => 1, icon     => 2, jerky    => 1,	
);

eval { $lc  = List::Compare->new(\%h10, \%h11); };
like($@,
    qr/Values in a 'seen-hash' may only be positive integers/s,
    "Got expected error message for left-hand hash which was not a seen-hash"
);
like($@,
    qr/First hash in arguments/s,
    "Got expected error message for left-hand hash which was not a seen-hash"
);
like($@,
    qr/Key:\s+golfer\s+Value:\s+one/s,
    "Got expected error message for left-hand hash which was not a seen-hash"
);

eval { $lc  = List::Compare->new('-a', \%h10, \%h11); };
like($@,
    qr/Values in a 'seen-hash' must be numeric/s,
    "Got expected error message for left-hand hash which was not a seen-hash"
);
like($@,
    qr/First hash in arguments/s,
    "Got expected error message for left-hand hash which was not a seen-hash"
);
like($@,
    qr/Key:\s+golfer\s+Value:\s+one/s,
    "Got expected error message for left-hand hash which was not a seen-hash"
);

eval { $lc  = List::Compare->new(\%h10, \%h11, \%h12); };
like($@,
    qr/Values in a 'seen-hash' must be positive integers/s,
    "Got expected error message for hash which was not a seen-hash"
);
like($@,
    qr/Hash\s+0/s,
    "Got expected error message for hash which was not a seen-hash"
);
like($@,
    qr/Bad key-value pair:\s+golfer\s+one/s,
    "Got expected error message for hash which was not a seen-hash"
);

my %h20 = (
	abel  => 2, baker => 1, camera => 1, delta => 1, edward => 1, fargo => 1,
	golfer   => 1,
);

my %h21 = (
	baker => 1, camera => 1, delta => 2, edward => 1, fargo => 1, golfer => 1,
	hilton   => q{one},
);

eval { $lc  = List::Compare->new(\%h20, \%h21); };
like($@,
    qr/Values in a 'seen-hash' may only be positive integers/s,
    "Got expected error message for right-hand hash which was not a seen-hash"
);
like($@,
    qr/Second hash in arguments/s,
    "Got expected error message for right-hand hash which was not a seen-hash"
);
like($@,
    qr/Key:\s+hilton\s+Value:\s+one/s,
    "Got expected error message for right-hand hash which was not a seen-hash"
);

eval { $lc  = List::Compare->new('-a', \%h20, \%h21); };
like($@,
    qr/Values in a 'seen-hash' must be numeric/s,
    "Got expected error message for right-hand hash which was not a seen-hash"
);
like($@,
    qr/Second hash in arguments/s,
    "Got expected error message for right-hand hash which was not a seen-hash"
);
like($@,
    qr/Key:\s+hilton\s+Value:\s+one/s,
    "Got expected error message for right-hand hash which was not a seen-hash"
);

my %h30 = (
	abel  => 2, baker => 1, camera => 1, delta => 1, edward => 1, fargo => 1,
	golfer   => 0,
);

my %h31 = (
	baker => 1, camera => 1, delta => 2, edward => 1, fargo => 1, golfer => 1,
	hilton   => 1,
);

eval { $lc  = List::Compare->new(\%h30, \%h31); };
like($@,
    qr/Values in a 'seen-hash' may only be positive integers/s,
    "Got expected error message for left-hand hash which was not a seen-hash"
);
like($@,
    qr/First hash in arguments/s,
    "Got expected error message for left-hand hash which was not a seen-hash"
);
like($@,
    qr/Key:\s+golfer\s+Value:\s+0/s,
    "Got expected error message for left-hand hash which was not a seen-hash"
);

eval { $lc  = List::Compare->new('-a', \%h30, \%h31); };
like($@,
    qr/Values in a 'seen-hash' must be numeric/s,
    "Got expected error message for left-hand hash which was not a seen-hash"
);
like($@,
    qr/First hash in arguments/s,
    "Got expected error message for left-hand hash which was not a seen-hash"
);
like($@,
    qr/Key:\s+golfer\s+Value:\s+0/s,
    "Got expected error message for left-hand hash which was not a seen-hash"
);

eval { $lc  = List::Compare->new(\%h30, \%h31, \%h12); };
like($@,
    qr/Values in a 'seen-hash' must be positive integers/s,
    "Got expected error message for hash which was not a seen-hash"
);
like($@,
    qr/Hash\s+0/s,
    "Got expected error message for hash which was not a seen-hash"
);
like($@,
    qr/Bad key-value pair:\s+golfer\s+0/s,
    "Got expected error message for hash which was not a seen-hash"
);

my %h40 = (
	abel  => 2, baker => 1, camera => 1, delta => 1, edward => 1, fargo => 1,
	golfer   => 1,
);

my %h41 = (
	baker => 1, camera => 1, delta => 2, edward => 1, fargo => 1, golfer => 1,
	hilton   => 0,
);

eval { $lc  = List::Compare->new(\%h40, \%h41); };
like($@,
    qr/Values in a 'seen-hash' may only be positive integers/s,
    "Got expected error message for right-hand hash which was not a seen-hash"
);
like($@,
    qr/Second hash in arguments/s,
    "Got expected error message for right-hand hash which was not a seen-hash"
);
like($@,
    qr/Key:\s+hilton\s+Value:\s+0/s,
    "Got expected error message for right-hand hash which was not a seen-hash"
);

eval { $lc  = List::Compare->new('-a', \%h40, \%h41); };
like($@,
    qr/Values in a 'seen-hash' must be numeric/s,
    "Got expected error message for right-hand hash which was not a seen-hash"
);
like($@,
    qr/Second hash in arguments/s,
    "Got expected error message for right-hand hash which was not a seen-hash"
);
like($@,
    qr/Key:\s+hilton\s+Value:\s+0/s,
    "Got expected error message for right-hand hash which was not a seen-hash"
);



