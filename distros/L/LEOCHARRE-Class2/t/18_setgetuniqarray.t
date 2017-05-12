package AppThing;
use lib './lib';
use LEOCHARRE::Class2;
use strict;
__PACKAGE__->make_constructor;
__PACKAGE__->make_accessor_setget_unique_array('hands');
1;



use Test::Simple 'no_plan';
use strict;
use lib './lib';

print STDERR "\n ============================================ $0 \n\n";
use Smart::Comments '###';

my $href;

ok(1);

my $i = AppThing->new({ hands => [qw/red blue green/] });
ok($i,'instanced');
for my $method ( qw(hands hands_count hands_add hands_delete hands_clear hands_exists)){
   ok($i->can($method), "can $method()");
}
print STDERR "\n---------------------line ".__LINE__."\n\n";




$href = $i->hands_href;
### $href


my @a = $i->hands;
### @a
my $hc = scalar @a;
ok( $hc == 3 );

ok $i->hands_count == $hc, "hands count is $hc";

$i->hands_add('purple');


ok $i->hands_exists('purple');



$href = $i->hands_href;
### $href
print STDERR "
---------- = = = = = = 
---------- = = = 1 = = 
---------- = = = = = = 
";




ok( $i->hands_count == ++$hc );



$href = $i->hands_href;
### $href
print STDERR "
---------- = = = = = = 
---------- = = = 2 = = 
---------- = = = = = = 
";

my $count70 = $i->hands_count;
ok $count70;



ok $i->hands_exists('red'), 'red hand there';

ok $i->hands_delete('red');
ok( 1,'deleted ref hand..');

my $count71 = $i->hands_count;


ok( $count70 == ($count71 + 1 ), "now old count is one more than present count ( $count71, $count70 )");


ok( ! $i->hands_exists('red'), 'now red hand no longer there');
ok $i->hands_add('red');
ok( $i->hands_exists('red') , 'now added red hand again!');
my $k = $i->hands_count;
ok( $k, "count now '$k'");

ok $i->hands_delete('red');



$href = $i->hands_href;
### $href
print STDERR "\n---------------------line ".__LINE__."\n\n";

my $aref = $i->hands_aref;
### $aref
print STDERR "\n---------------------line ".__LINE__."\n\n";





my $b = $i->hands_count;
$hc--;
ok( $b == $hc,"hands count from obj [$b] same as $hc" );

$i->hands_delete(qw/blue green purple/);

$href = $i->hands_href;
### $href






ok !$i->hands_count;
my $count_last = $i->hands_count;
### $count_last

my $o = new AppThing;

my $val = $o->hands_count;
ok defined $val;
ok $val == 0;


ok_part('FURTHER COUNT');


my $return = $o->hands_add('right','left');

ok( $return," return val is '$return'");
ok( $o->hands_count == 2, 'now hands count is 2');

ok( $return = $o->hands('one'),' add via name alone' );
### $return

ok( $o->hands_count == 3, "now hands is 3");

my @return = $o->hands;
### @return
ok( scalar @return == 3 );

sub ok_part { printf STDERR "\n%s\n= @_\n\n", '-'x60; 1 }
