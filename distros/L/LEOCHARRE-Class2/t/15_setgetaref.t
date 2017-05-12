package AppThing;
use lib './lib';
use LEOCHARRE::Class2;
use strict;
__PACKAGE__->make_constructor;

__PACKAGE__->make_accessor_setget_aref(
   'hands',
);

__PACKAGE__->make_accessor_setget_aref({
   chairs => [],
   blocks => undef, # should still be []
   names => [qw(mack hack lack)],
});

__PACKAGE__->make_accessor_setget_aref([ 'animals' => [qw(moose cow mouse)]]);


__PACKAGE__->make_count_for('tests','inv');
1;


use Test::Simple 'no_plan';
use strict;
use lib './lib';

print STDERR "\n ============================================ $0 \n\n";
#use Smart::Comments '###';

ok(1);

my $i = AppThing->new({ tests => [qw(a b c)], inv => { a => 1, b => 2 }, });
ok($i,'instanced');

for my $method ( qw(names names_count chairs chairs_count blocks blocks_count hands hands_count)){
   ok($i->can($method), "can $method()");
}
my $r;
my $names = $i->names;
### $names

ok( $i->names_count == 3, 'names count is 3' );

my $r = $i->names;
### $r
$r = $i->names_count;
### $r

ok( @{$i->names}[1] eq 'hack');
$i->names([]);

ok( $i->names_count == 0 );

my $v;
my @v;
ok( $v=  $i->animals,'animals()' );
ok( @v = $i->animals, 'animals array');
ok( scalar @v == 3, "animals wantarray is 3 elems '@v'");
ok( 3 == $i->animals_count, "animals_count() as expected");


print STDERR "\n==============\n=== PART 2 ===\n\n";

for my $method( qw(names chairs blocks hands) ){
   my $method_count = "$method\_count";

   my $r;
   ok( $r = $i->$method );
   ok( ref $r eq 'ARRAY' );
   ok( $i->$method_count == 0 );
   
   print STDERR " changing content.. \n";
   push @$r, 'this';

   ok $i->$method_count == 1,'now count is 1';

   my @a = $i->$method;



   ok( "@a" eq 'this',"now eq this, '@a', thus returned an ARRAY not a ref");
   
   ok( scalar @a == 1,'scalar is 1');

   ok $i->$method_count == 1, 'method_count is 1 ';





}




### TESTS

ok( $i->tests_count);
ok( $i->tests_count == 3 );

ok( $i->inv_count);
ok( $i->inv_count == 2 );
