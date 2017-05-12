package AppThing2;
use lib './lib';
use LEOCHARRE::Class2;
use strict;
__PACKAGE__->make_constructor;
__PACKAGE__->make_accessor_setget_unique_array({ 'hands' => [qw/this is my default handiture/] });
1;


use Test::Simple 'no_plan';
use strict;
use lib './lib';

print STDERR "\n--------------------- APPTHING 2, line ".__LINE__."\n\n";
# ------------------------------------------------------------------------------------------------------------

my $href2;

ok(1);

my $r = AppThing2->new;
ok($r,'instanced');


my @hands = $r->hands;
### @hands
ok( @hands and scalar @hands, " have hands and count of it") or exit ;

for my $hand(qw/this is my default handiture/){
   print STDERR "\n-----TESTING '$hand'------\n";
   ok $r->hands_exists($hand);
   ok $r->hands_delete($hand);

   ok( ! $r->hands_exists($hand)    );
   ok $r->hands_add($hand);
}

$href2 = $r->hands_href;
### $href2


