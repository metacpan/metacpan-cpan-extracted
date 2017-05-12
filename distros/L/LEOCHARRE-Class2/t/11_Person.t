use Test::Simple 'no_plan';
use strict;
use lib './t';
use lib './lib';
use Person;
use Smart::Comments '###';
ok(1);

my $f = Person->new({ hang => 'luster' });
ok($f, 'object instanced');

ok( ! $f->name );
ok( $f->hang eq  'luster');
ok( $f->pants == 27 );
ok( $f->speed );
ok( $f->age == 19 );

my $i = $f->inventory;
ok ref $i eq 'ARRAY';
### $i

ok( ! $f->name_last );
ok $f->name_last('charre') eq 'charre';

my $i2 = $f->inventory([qw(many things here)]);
### $i2
ok($f->inventory,'inventory');

my $i3 = $f->inventory([]);
### $i3



my $p = Person->new;
ok( ! $p->name_last,'name_last has nothing') or die;

my $i4 = $p->inventory;
### $i4
ok( $p->inventory ,'inventory');


### ----------------------
my $x=1;

for my $name ( qw(Marissa Morgan Melissa Miranda Monica) ){
   test_person($name);

}


sub test_person {
   my $name = shift;
   print STDERR "\n == TEST PERSON $x ==\n"; 
   $x++;

   my $housing = [qw(oriental victorian barn)];

   my $n = Person->new({ age => 22 });
   ok( ! $n->name_last,'name_last has nothing') or die;

   my $classhouses = $Person::houses;
   ### $classhouses

   my $houses = $n->houses;
   ok( ref $houses eq 'ARRAY', 'ref houses is arref');

   my $houses_count = $n->houses_count;
   ok(! $houses_count," houses count should be 0, is $houses_count");
   
   ok($n->age == 22);  

   ok( !$n->name );

   $n->name($name);

   $n->name_last('Ticelli');

   ok($n->name eq $name );
   
   my $adding_count = scalar @$housing;
   ### $adding_count
   for my $thing ( @$housing ){
      my $cnow = $n->houses_add($thing);
      ## $cnow
   }
   my $houses_count_2 = $n->houses_count;
   ok( $houses_count_2 == $adding_count, 
         "counf of houses in obj now is '$houses_count_2', is same as ammount inserted: '$adding_count'") 
         or die();


   


}







