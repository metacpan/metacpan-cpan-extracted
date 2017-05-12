package GiaBunny;
use lib './lib';
use LEOCHARRE::Class2;
use Smart::Comments '###';
use strict;
__PACKAGE__->make_constructor;

__PACKAGE__->make_accessor_setget({
   'key' => 'val',
});

1;








use Test::Simple 'no_plan';
use strict;
use lib './t';
use lib './lib';
#use GiaBunny;
use Smart::Comments '###';
ok(1);

my $a = GiaBunny->new();
ok($a, 'object instanced');
ok($a->key eq 'val' );

my $b = GiaBunny->new({ key => 'bla' });
ok($b->key eq 'bla');
ok($b->key('another val'));
ok($b->key eq 'another val');


my $b = GiaBunny->new({ key => undef });
ok( ! ($b->key eq 'val'),
   " # actually won't work.. since we check key existance to use default vals hmmm");


