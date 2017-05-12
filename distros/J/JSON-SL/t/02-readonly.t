#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use JSON::SL;
use Devel::Peek;
use Data::Dumper;

my $sl = JSON::SL->new();
my $h = {};
my $v = [];

ok($sl->referrent_is_writeable($h), "Hash is writeable");
ok($sl->referrent_is_writeable(\$v), "Value (arrayref) is writeable");

$h->{something} = $v;
#make it read-only

$sl->make_referrent_readonly($h);
ok(!$sl->referrent_is_writeable($h), "Reference is read-only");

$sl->make_referrent_readonly(\$h->{something});
ok(!$sl->referrent_is_writeable(\$h->{something}), "Value is read-only");

eval {
    delete $h->{something};
};

ok($@, "Got error for modifying read-only hash ($@)");

$sl->make_referrent_writeable($h);
ok($sl->referrent_is_writeable($h), "Variable is writeable once more");
delete $h->{something};

done_testing();
