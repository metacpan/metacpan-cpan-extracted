package AppThing;
use lib './lib';
use LEOCHARRE::Class2;
use strict;
__PACKAGE__->make_constructor;
__PACKAGE__->make_accessor_setget_unique_array('_hands');

1;



use Test::Simple 'no_plan';
use strict;
use lib './lib';

print STDERR "\n ============================================ $0 \n\n";
use Smart::Comments '###';

my $href;

ok(1);

my $i = AppThing->new;

ok($i,'instanced');

for my $method ( qw(_hands _hands_count _hands_add _hands_delete _hands_clear _hands_exists)){
   ok($i->can($method), "can $method()");
}
print STDERR "\n---------------------line ".__LINE__."\n\n";







ok $i->_hands_add('hi there');

$href = $i->_hands_href;
### $href

ok $i->_hands_count;


ok $i->_hands_delete('hi there');

$href = $i->_hands_href;
### $href



