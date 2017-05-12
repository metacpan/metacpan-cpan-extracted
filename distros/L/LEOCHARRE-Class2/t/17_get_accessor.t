package GiaBunny;
use lib './lib';
use LEOCHARRE::Class2;
use strict;
__PACKAGE__->make_constructor;

__PACKAGE__->make_accessor_setget({
   'key' => 'val',
});
__PACKAGE__->make_accessor_get({
   name => 'jenni',
});

1;








use Test::Simple 'no_plan';
use strict;
use lib './t';
use lib './lib';
#use GiaBunny;
ok(1);

my $a = GiaBunny->new();
ok($a, 'object instanced');
ok($a->key eq 'val' );

# this should croak
ok( !eval{ $a->name('value') }, "trying to set name via a get only accessor does not work");

ok( $a->name );
ok( $a->name eq 'jenni',"name is jenni, the default in the class");



# if we set the name in the constructor it should be ok


my $b = GiaBunny->new({ key => 'bla', name =>'gia' });
ok($b->key eq 'bla');
ok($b->key('another val'));
ok($b->key eq 'another val');



ok( $b->name );
ok( $b->name eq 'gia', "name is gia, was passed in constructor"); 



