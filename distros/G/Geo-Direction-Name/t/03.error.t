use strict;
use Test::Base;
plan tests => 5;

use Geo::Direction::Name;

eval { Geo::Direction::Name->new("bb_BB"); };
ok $@ =~ /Geo::Direction::Name::Spec not support this locale now: bb_BB/;

my $dobj = Geo::Direction::Name->new;

eval { $dobj->to_string("aaa"); };
ok $@ =~ /Direction value must be a number/;

eval { $dobj->to_string(180.0,{abbreviation => 2}); };
ok $@ =~ /Abbreviation parameter must be 0 or 1/;

eval { $dobj->to_string(180.0,{devide => 5}); };
ok $@ =~ /Devide parameter must be 4,8,16,32/;

is $dobj->from_string("foo"), undef;
