#!/usr/bin/perl
use strict;
use warnings;

use Logging::Simple;
use Test::More;


my @nums = qw(_0 _1 _2 _3 _4 _5 _6 _7);

my $log = Logging::Simple->new;

my $subs = $log->_sub_names;

is (ref $subs, 'ARRAY', "_sub_names() returns an aref");
is (@$subs, @nums, "count of sub names is ok");

my $i = 0;
for (@$subs){
    is ($_, $nums[$i], "sub $_ matches $nums[$i] ok");
    $i++;
}

done_testing();

