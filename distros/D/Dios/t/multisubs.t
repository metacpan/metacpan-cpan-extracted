use strict;
use warnings;

use Test::More;
use Dios;

plan tests => 3;


multi func mfunc (Int $n, Ref   $r) { return 'Int, Ref';   }
multi      mfunc (Num $n, Ref   $r) { return 'Num, Ref';   }
multi func mfunc (Int $n, Array $r) { return 'Int, Array'; }
multi      mfunc (Num $n, Hash  $r) { return 'Num, Hash';  }
multi func mfunc (Int $n, Any   $r) { return 'Int, Any';   }

subtest 'mfunc' => sub {
    is mfunc(1,   \"scalar"), 'Int, Ref', 'Int, Ref';
    is mfunc(1.1, [1..3]   ), 'Num, Ref', 'Num, Ref';
    is mfunc(1.1, [1..3]   ), 'Num, Ref', 'Num, Ref';
    is mfunc(1.1, {a=>1}   ), 'Num, Hash','Num, Hash';
    is mfunc(1,   2        ), 'Int, Any', 'Int, Any';

    is mfunc(1,   {a=>1}   ), 'Int, Ref', 'Int, Ref';

#    is eval{ mfunc(1, {a=>1} ) }, undef, 'Ambiguous';
#    like $@, qr{\Qmfunc(Int,Ref)\E}xms, 'Correct message part 1';
#    like $@, qr{\Qmfunc(Num,Hash)\E}xms, 'Correct message part 2';

    is eval{ mfunc(undef, \1 ) }, undef, 'No match';
    like $@, qr{\QNo suitable 'mfunc' variant found\E}xms, 'Correct message';
};

class Demo {
    multi method mmeth (Int $n, Ref   $r) { return 'Int, Ref';   }
    multi method mmeth (Num $n, Ref   $r) { return 'Num, Ref';   }
    multi method mmeth (Int $n, Array $r) { return 'Int, Array'; }
    multi method mmeth (Num $n, Hash  $r) { return 'Num, Hash';  }
    multi method mmeth (Int $n, Any   $r) { return 'Int, Any';   }
};

subtest 'mmeth' => sub {
    my $obj = Demo->new;

    is $obj->mmeth(1,   \"scalar"), 'Int, Ref', 'Int, Ref';
    is $obj->mmeth(1.1, [1..3]   ), 'Num, Ref', 'Num, Ref';
    is $obj->mmeth(1.1, [1..3]   ), 'Num, Ref', 'Num, Ref';
    is $obj->mmeth(1.1, {a=>1}   ), 'Num, Hash','Num, Hash';
    is $obj->mmeth(1,   2        ), 'Int, Any', 'Int, Any';

    is $obj->mmeth(1,   {a=>1}   ), 'Int, Ref', 'Int, Ref';

#    is eval{ $obj->mmeth(1, {a=>1} ) }, undef, 'Ambiguous';
#    like $@, qr{\Qmmeth(Any,Int,Ref)\E}xms, 'Correct message part 1';
#    like $@, qr{\Qmmeth(Any,Num,Hash)\E}xms, 'Correct message part 2';

    is eval{ $obj->mmeth(undef, \1 ) }, undef, 'No match';
    like $@, qr{\QNo suitable 'mmeth' variant found\E}xms, 'Correct message';
};

class DemoDir is Demo {
    multi method mmeth (Int $n, Hash  $r) { return 'Int, Hash'; }
    multi method mmeth (Num $n, Hash  $r) { return 'NUM, HASH'; }
}

subtest 'derived mmeth' => sub {
    my $obj = DemoDir->new;

    is $obj->mmeth(1,   \"scalar"), 'Int, Ref', 'Int, Ref';
    is $obj->mmeth(1.1, [1..3]   ), 'Num, Ref', 'Num, Ref';
    is $obj->mmeth(1.1, [1..3]   ), 'Num, Ref', 'Num, Ref';
    is $obj->mmeth(1.1, {a=>1}   ), 'NUM, HASH','NUM, HASH';
    is $obj->mmeth(1,   2        ), 'Int, Any', 'Int, Any';

    is $obj->mmeth(1, {a=>1} ), 'Int, Hash', 'Int, Hash';

    is eval{ $obj->mmeth(undef, \1 ) }, undef, 'No match';
    like $@, qr{\QNo suitable 'mmeth' variant found\E}xms, 'Correct message';
};

done_testing();

