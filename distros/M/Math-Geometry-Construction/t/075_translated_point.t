#!perl -T
use strict;
use warnings;

use Test::More tests => 50;
use Math::Geometry::Construction;
use Math::Vector::Real;

sub is_close {
    my ($value, $reference, $message, $limit) = @_;

    cmp_ok(abs($value - $reference), '<', ($limit || 1e-12), $message);
}

sub translated_point {
    my $construction = Math::Geometry::Construction->new;
    my $p;
    my $d;
    my $dp;
    my $pos;

    $p = $construction->add_point(position => [5, 7]);

    $d  = $construction->add_derivate
	('TranslatedPoint', input => [$p], translator => V(1, 0));
    $dp = $d->create_derived_point
	(position_selector => ['indexed_position', [0]]);

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 6, 'intersection x');
    is_close($pos->[1], 7, 'intersection y');
    
    $dp = $d->create_derived_point;

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 6, 'intersection x');
    is_close($pos->[1], 7, 'intersection y');
    
    $dp = $construction->add_derived_point
	('TranslatedPoint',
	 {input => [$p], translator => V(2, 3)},
	 {position_selector => ['indexed_position', [0]]});

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 7, 'intersection x');
    is_close($pos->[1], 10, 'intersection y');
    
    $dp = $construction->add_derived_point
	('TranslatedPoint',
	 {input => [$p], translator => [-1, 5]},
	 {});

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 4, 'intersection x');
    is_close($pos->[1], 12, 'intersection y');
    
    $dp = $construction->add_derived_point
	('TranslatedPoint',
	 {input => [$p], translator => [-3, -5]});

    ok(defined($dp), 'derived point defined');
    isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
    $pos = $dp->position;
    ok(defined($pos), 'position defined');
    isa_ok($pos, 'Math::Vector::Real');
    is(@$pos, 2, 'two components');
    is_close($pos->[0], 2, 'intersection x');
    is_close($pos->[1], 2, 'intersection y');
    
  SKIP: {
      skip("not implemented, yet", 7);
      $dp = $construction->add_derived_point
	  ('TranslatedPoint',
	   {input => [[1, 10]], translator => [-3, -5]});
      
      ok(defined($dp), 'derived point defined');
      isa_ok($dp, 'Math::Geometry::Construction::DerivedPoint');
      $pos = $dp->position;
      ok(defined($pos), 'position defined');
      isa_ok($pos, 'Math::Vector::Real');
      is(@$pos, 2, 'two components');
      is_close($pos->[0], 2, 'intersection x');
      is_close($pos->[1], 2, 'intersection y');
    }
}

sub id {
    my $construction = Math::Geometry::Construction->new;
    my $p;
    my $d;
    my $dp;

    $p = $construction->add_point(position => [1, -3]);
    is($p->id, 'P000000000', 'point id');

    $d = $construction->add_derivate
	('TranslatedPoint', input => [$p], translator => [3, 4]);
    is($d->id, 'D000000001', 'derivate id');

    $dp = $d->create_derived_point;
    is($dp->id, 'S000000002', 'derived point id');

    $dp = $construction->add_derived_point
	('TranslatedPoint', {input => [$p], translator => [1, 3]});
    is($dp->id, 'S000000004', 'derived point id');
    ok(defined($construction->object('D000000003')), 'derivate exists');

    $dp = $construction->add_derived_point
	('TranslatedPoint',
	 {input      => [$construction->add_point(position => [10, 21])],
	  translator => [4, -13]});
    foreach('P000000005',
	    'D000000006',
	    'S000000007')
    {
	ok(defined($construction->object($_)), "$_ defined");
    }
}

translated_point;
id;
