use Deeme::Obj -strict;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

package Deeme::ObjTest;
use Deeme::Obj -strict;

use base 'Deeme::ObjTest::Base2';

__PACKAGE__->attr(heads => 1);
__PACKAGE__->attr('name');

package Deeme::ObjTestTest;
use Deeme::Obj 'Deeme::ObjTest';

package Deeme::ObjTestTestTest;
use Deeme::Obj "Deeme::ObjTestTest";

package main;

use Deeme::Obj;
use Deeme::ObjTest::Base1;
use Deeme::ObjTest::Base2;
use Deeme::ObjTest::Base3;

# Basic functionality
my $monkey = Deeme::ObjTest->new->bananas(23);
my $monkey2 = Deeme::ObjTestTest->new(bananas => 24);
is $monkey2->bananas, 24, 'right attribute value';
is $monkey->bananas,  23, 'right attribute value';

# Instance method
$monkey = Deeme::ObjTestTestTest->new;
$monkey->attr('mojo');
is $monkey->mojo(23)->mojo, 23, 'monkey has mojo';
ok !Deeme::ObjTestTest->can('mojo'),   'base class does not have mojo';
ok !!Deeme::ObjTestTest->can('heads'), 'base class has heads';
ok !Deeme::ObjTest->can('mojo'),       'base class does not have mojo';
ok !!Deeme::ObjTest->can('heads'),     'base class has heads';

# Default value defined but false
ok defined($monkey->coconuts);
is $monkey->coconuts, 0, 'right attribute value';
is $monkey->coconuts(5)->coconuts, 5, 'right attribute value';

# Default value support
$monkey = Deeme::ObjTest->new;
isa_ok $monkey->name('foobarbaz'), 'Deeme::ObjTest',
  'attribute value has right class';
$monkey2 = Deeme::ObjTest->new->heads('3');
is $monkey2->heads, 3, 'right attribute value';
is $monkey->heads,  1, 'right attribute default value';

# Chained attributes and callback default value support
$monkey = Deeme::ObjTest->new;
is $monkey->ears, 2, 'right attribute value';
is $monkey->ears(6)->ears, 6, 'right chained attribute value';
is $monkey->eyes, 2, 'right attribute value';
is $monkey->eyes(6)->eyes, 6, 'right chained attribute value';

# Tap into chain
$monkey = Deeme::ObjTest->new;
is $monkey->tap(sub { $_->name('foo') })->name, 'foo', 'right attribute value';
is $monkey->tap(sub { shift->name('bar')->name })->name, 'bar',
  'right attribute value';

# Inherit -base flag
$monkey = Deeme::ObjTest::Base3->new(evil => 1);
is $monkey->evil,    1,     'monkey is evil';
is $monkey->bananas, undef, 'monkey has no bananas';
is $monkey->bananas(3)->bananas, 3, 'monkey has 3 bananas';

# Exceptions
eval { Deeme::ObjTest->attr(foo => []) };
like $@, qr/Default has to be a code reference or constant value/,
  'right error';
eval { Deeme::ObjTest->attr(23) };
like $@, qr/Attribute "23" invalid/, 'right error';

done_testing();