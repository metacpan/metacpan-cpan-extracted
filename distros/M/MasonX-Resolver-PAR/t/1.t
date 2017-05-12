# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Simple tests => 2;

use MasonX::Resolver::PAR;

#########################
my $res=MasonX::Resolver::PAR->new(
    par_file=>"sample.par"
);
# Tests
ok($res and (ref $res eq "MasonX::Resolver::PAR"),"new() works");
ok(ref $res->get_info("/")  eq "HTML::Mason::ComponentSource","get_info() works");
