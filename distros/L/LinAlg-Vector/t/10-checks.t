#!perl -T
use 5.006;
use strict;
use warnings;

use Test::More;
use Test::Exception;

use LinAlg::Vector;
use Package::Alias V => "LinAlg::Vector";

plan( tests => 73 );

#constructor - 10
{
  dies_ok(sub { V->new(data=>3); });
  dies_ok(sub { V->new(data=>"a"); });
  dies_ok(sub { V->new(data=>{}); });
  dies_ok(sub { V->new(data=>["a"]); });

  ok(V->new());
  ok(V->new(data=>[]));
  ok(V->new(data=>[3]));
  ok(V->new(data=>[3,-1,4]));

  #use convenience notation
  ok(V->new([1,3,4])->toString eq "[1,3,4]");
  ok(V->new([])->toString eq "[]");
}

#raw - 3
{
  is_deeply(V->new([1,3,2])->raw, [1,3,2]);
  is_deeply(V->new([])->raw, []);
  
  my $v = V->new([3,2,1]);
  my $r = $v->raw;
  $r->[4] = 33;
  ok($v->raw->[2] == 1);
}

#toString - 3
{
  ok(V->new()->toString eq "[]");
  ok(V->new(data=>[])->toString eq "[]");
  ok(V->new(data=>[1.0,-2,3.3])->toString eq "[1,-2,3.3]");
}

#len - 3
{
  ok(V->new()->len == 0);
  ok(V->new(data=>[])->len == 0);
  ok(V->new(data=>[1,1,1])->len == 3);
}

#eq 6
{
  ok(V->new()->eq(V->new()));
  ok(V->new(data=>[])->eq(V->new()));
  ok(V->new(data=>[1,2])->eq(V->new(data=>[1,2])));
  ok(!V->new(data=>[1,3])->eq(V->new(data=>[1,2])));

  #test precision
  ok(V->new([1,3])->eq(V->new([0.999,3.002]), -2));
  ok(!V->new([1,3])->eq(V->new([0.999,3.002]), -3));
}

#get/set - 8
{
  my $v1 = V->new(data=>[1.3,-2]);
  ok($v1->get(0) == 1.3);
  ok($v1->get(1) == -2);
  dies_ok(sub {
    my $v1 = V->new(data=>[2]);
    $v1->get(3);
  });

  $v1->set(0, 33);
  ok($v1->get(0) == 33);

  $v1->set(1, 12);
  ok($v1->get(1) == 12);

  dies_ok(sub {
    my $v1 = V->new(data=>[2]);
    $v1->set(3, 44);
  });

  dies_ok(sub {
    my $v1 = V->new(data=>[2]);
    $v1->set(0, "a");
  });

  ok($v1->toString eq "[33,12]");
}

#copy - 3
{
  my $v1 = V->new(data=>[1,2]);
  my $v2 = $v1->copy;
  ok($v1->toString eq $v2->toString);

  $v1->set(0, 33);
  ok($v1->get(0) == 33);
  ok($v2->get(0) == 1);
}

#add - 5
{
  ok(V->new(data=>[1,2,3])->add(V->new(data=>[4,2,2]))
    ->eq(V->new(data=>[5,4,5])));

  ok(V->new(data=>[1.3,2,3])->add(V->new(data=>[4,2,-2]))
    ->eq(V->new(data=>[5.3,4,1.0])));

  dies_ok(sub {
    my $v = V->new(data=>[1])->add(V->new(data=>[1,2]));
  });
  dies_ok(sub {
    my $v = V->new(data=>[1])->add(data=>[3]);
  });

  my ($v1, $v2) = (V->new(data=>[1,2]), V->new(data=>[3,4]));
  my $v3 = $v1->add($v2);
  ok(!$v1->eq($v3));
}

#sub - 5
{
  ok(V->new(data=>[1,2,3])->subt(V->new(data=>[4,2,2]))
    ->eq(V->new(data=>[-3,0,1])));

  ok(V->new(data=>[1.3,2,3])->subt(V->new(data=>[4,2,-2]))
    ->eq(V->new(data=>[-2.7,0,5])));

  dies_ok(sub {
    my $v = V->new(data=>[1])->subt(V->new(data=>[1,2]));
  });
  dies_ok(sub {
    my $v = V->new(data=>[1])->subt(data=>[3]);
  });

  my ($v1, $v2) = (V->new(data=>[1,2]), V->new(data=>[3,4]));
  my $v3 = $v1->subt($v2);
  ok(!$v1->eq($v3));
}

#dot - 4
{
  ok(V->new(data=>[1,2,3])->dot(V->new(data=>[1,3,2])) == 13);
  ok(V->new(data=>[1.2,2,3])->dot(V->new(data=>[1,3,2])) == 13.2);
  dies_ok(sub {
    my $v = V->new(data=>[1])->dot(V->new(data=>[1,2]));
  });
  dies_ok(sub {
    my $v = V->new(data=>[1])->dot(data=>[3]);
  });
}

#x/y/z = 3
{
  ok(V->new([1,2,3])->x == 1);
  ok(V->new([1,2,3])->y == 2);
  ok(V->new([1,2,3])->z == 3);
}

#cross - 5
{
  ok(V->new(data=>[3,2,4])->cross(V->new(data=>[1,-3,2]))
    ->eq(V->new(data=>[16,-2,-11])));

  ok(V->new(data=>[-1,2,3])->cross(V->new(data=>[3,4,2.2]))
    ->eq(V->new(data=>[-7.6,11.2,-10])));

  dies_ok(sub {
    my $v = V->new(data=>[3,2,4])->cross(V->new(data=>[1,-3]));
  });
  dies_ok(sub {
    my $v = V->new(data=>[3,2,4])->cross(data=>[1,-3,2]);
  });

  my ($v1, $v2) = (V->new(data=>[3,2,4]), V->new(data=>[1,-3,2]));
  my $v3 = $v1->cross($v2);
  ok(!$v1->eq($v3));
}

#scale - 4
{
  ok(V->new(data=>[1,2,3])->scale(2)->eq(V->new(data=>[2,4,6])));
  ok(V->new(data=>[1,2,3])->scale(0)->eq(V->new(data=>[0,0,0])));
  dies_ok(sub {
    my $v = V->new(data=>[1,2,3])->scale("a");
  });

  my $v1 = V->new(data=>[1,2,3]);
  my $v2 = $v1->scale(2);
  ok(!$v1->eq($v2));
}

#mag - 3
{
  ok(V->new(data=>[1,2,3])->mag == sqrt(1+4+9));
  ok(V->new(data=>[3,4])->mag == sqrt(9+16));
  isnt(V->new(data=>[3,4])->mag, 6);
}

#unit - 4
{
  ok(V->new(data=>[10,0])->unit->eq(V->new(data=>[1,0])));
  ok(V->new(data=>[6])->unit->eq(V->new(data=>[1])));

  my $mag = sqrt(14);
  ok(V->new(data=>[1,2,3])->unit
    ->eq(V->new(data=>[1/$mag, 2/$mag, 3/$mag])));

  isnt(V->new(data=>[6])->unit->eq(V->new(data=>[2])), 1);
}

#proj - 4
{
  ok(V->new(data=>[3,5])->proj(V->new(data=>[1,0]))->eq(V->new(data=>[3,0])));
  ok(V->new(data=>[3,5])->proj(V->new(data=>[0,1]))->eq(V->new(data=>[0,5])));

  ok(V->new(data=>[3,3])->proj(V->new(data=>[8,8]))->toString 
    eq V->new(data=>[3,3])->toString);

  ok(V->new(data=>[3,3])->proj(V->new(data=>[6,2]))->toString 
    eq V->new(data=>[3.6,1.2])->toString);
}







