use t::boilerplate;

use Test::More;
use English qw( -no_match_vars );
use Class::Null;

use_ok 'File::DataClass::Types';

{  package MyCache;

   use Moo;
   use File::DataClass::Types qw( Cache );

   has 'test_cache' => is => 'ro', isa => Cache;
}

my $cache; eval { $cache = MyCache->new( test_cache => 'NotAnObjectRef' ) };

like $EVAL_ERROR, qr{ not \s+ an \s+ object }mx, 'Cache - not an object ref';

eval { $cache = MyCache->new( test_cache => Class::Null->new ) };

ok $cache->test_cache->isa( 'Class::Null' ), 'Cache - null object';

eval { $cache = MyCache->new( test_cache => bless {}, 'WrongClass' ) };

like $EVAL_ERROR, qr{ not \s+ of \s+ class }mx, 'Cache - wrong class';

{  package MyDummyClass;

   use Moo;
   use File::DataClass::Types qw( DummyClass );

   has 'test_dummy_class' => is => 'ro', isa => DummyClass;
}

my $dummy; eval { $dummy = MyDummyClass->new( test_dummy_class => 'NotNone' ) };

like $EVAL_ERROR, qr{ is \s not \s "none" }mx, 'DummyClass - not none';

eval { $dummy = MyDummyClass->new( test_dummy_class => 'none' ) };

is $dummy->test_dummy_class, 'none', 'DummyClass - is none';

{  package MyLock;

   use Moo;
   use File::DataClass::Types qw( Lock );

   has 'test_lock' => is => 'ro', isa => Lock;
}

my $lock; eval { $lock = MyLock->new( test_lock => 'NotAnObjectRef' ) };

like $EVAL_ERROR, qr{ not \s+ an \s+ object }mx, 'Lock - not an object ref';

eval { $lock = MyLock->new( test_lock => Class::Null->new ) };

ok $lock->test_lock->isa( 'Class::Null' ), 'Lock - null object';

eval { $lock = MyLock->new( test_lock => bless {}, 'WrongClass' ) };

like $EVAL_ERROR, qr{ is \s missing (.+) methods }mx, 'Lock - missing methods';

{  package MyOctalNum;

   use Moo;
   use File::DataClass::Types qw( OctalNum );

   has 'test_octal_num' => is => 'ro', isa => OctalNum, coerce => 1;
}

my $octal; eval { $octal = MyOctalNum->new( test_octal_num => undef ) };

like $EVAL_ERROR, qr{ not \s an \s octal \s number }mx, 'OctalNum - undefined';

eval { $octal = MyOctalNum->new( test_octal_num => q() ) };

like $EVAL_ERROR, qr{ not \s an \s octal \s number }mx, 'OctalNum - null str';

eval { $octal = MyOctalNum->new( test_octal_num => 8 ) };

like $EVAL_ERROR, qr{ not \s an \s octal \s number }mx, 'OctalNum - not octal';

eval { $octal = MyOctalNum->new( test_octal_num => 0 ) };

is $octal->test_octal_num, 0, 'OctalNum - is octal 0';

eval { $octal = MyOctalNum->new( test_octal_num => 7 ) };

is $octal->test_octal_num, 7, 'OctalNum - is octal 7';

eval { $octal = MyOctalNum->new( test_octal_num => 17 ) };

is( (sprintf '%o', $octal->test_octal_num), 17, 'OctalNum - is octal 17' );

ok $octal->test_octal_num == 15, 'OctalNum - is converted';

eval { $octal = MyOctalNum->new( test_octal_num => 18 ) };

like $EVAL_ERROR, qr{ \Qnot an octal number\E }mx, 'OctalNum - bad value 18';

{  package MyPath;

   use Moo;
   use File::DataClass::Types qw( Path );

   has 'test_path' => is => 'ro', isa => Path, coerce => Path->coercion;
}

my $path = MyPath->new( test_path => undef );

isa_ok $path->test_path, 'File::DataClass::IO';

eval { $path = MyPath->new( test_path => bless {}, 'Dummy' ) };

like $EVAL_ERROR, qr{ not \s of \s class }mx, 'Path - wrong class';

{  package MyResult;

   use Moo;
   use File::DataClass::Types qw( Result );

   has 'test_result' => is => 'ro', isa => Result;
}

eval { MyResult->new( test_result => bless {}, 'Dummy' ) };

like $EVAL_ERROR, qr{ not \s of \s class }mx, 'Result - wrong class';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
