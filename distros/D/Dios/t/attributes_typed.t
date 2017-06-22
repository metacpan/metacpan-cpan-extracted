
use Dios;
use Test::More;

plan tests => 5;

class Typeful  {
    has         Int  $.int_attr where { $_ > 0 } is rw;
    has  Array[Num]  $.aon_attr                  is rw;
    has         Int  @.aoi_attr                  is rw;
    has         Int  %.hoi_attr                  is rw;

    method direct_assignment {
        ::ok  eval { $int_attr = 1;           1; } => 'Int attr assigned correctly';
        ::ok !eval { $int_attr = 0;           1; } => 'Int attr 0 assignment failed as expected';
        ::ok !eval { $int_attr = 'str';       1; } => 'Int attr str assignment failed as expected';

        ::ok  eval { $aon_attr = [1,2,3];     1; } => 'AoN attr assigned correctly';
        ::ok !eval { $aon_attr = [1,2,'str']; 1; } => 'AoN attr assignment failed as expected';

        ::ok  eval { @aoi_attr = (1,2,3);     1; } => 'AoI attr assigned correctly';
        eval {
            ::ok !eval { @aoi_attr = (1,2,'str'); 1; } => 'AoI attr assignment failed as expected';
            1;
        };

        eval {
            ::ok !eval { $aoi_attr[0] = 'str'; 1; } => 'AoI attr elem assignment failed as expected';
            1;
        };

        ::ok  eval { %hoi_attr = (a=>1, b=>-99);   1; } => 'HoI attr assigned correctly';

        eval {
            ::ok !eval { %hoi_attr = (a=>1, b=>'z');   1; } => 'HoI attr assignment failed as expected';
            1;
        };

        1;
    }
}

my $obj = Typeful->new({ int_attr => 1, aon_attr => [1,2,3], aoi_attr => [4,5,6], hoi_attr=>{c=>3,p=>0} });


subtest 'int_attr tests' => sub {

    ::is $obj->get_int_attr, 1
        => 'Int attr set correctly';

    ::ok !eval{ $obj = Typeful->new({ int_attr => [] }) ; 1; }
        => 'Non-int int_attr failed as expected';

    ::ok +(eval{ $obj->set_int_attr(42) ; 1; } // diag $@)
        => 'Int set_int_attr succeeded as expected';

    ::ok !eval{ $obj->set_int_attr('a') ; 1; }
        => 'Non-int set_int_attr failed as expected';

};


subtest 'aon_attr tests' => sub {

    ::is_deeply $obj->get_aon_attr, [1,2,3] => 'aon attr set correctly';

    ::ok !eval{ $obj = Typeful->new({ int_attr => 1, aon_attr => 'a' }) ; 1; }
        => 'Non-array aon_attr failed as expected';

    ::ok !eval{ $obj = Typeful->new({ int_attr => 1, aon_attr => ['a'] }) ; 1; }
        => 'Non-num aon_attr failed as expected';

    ::ok +(eval{ $obj->set_aon_attr([1,2,3]); 1 } // diag $@)
        => 'aon set_aon_attr succeeded as expected';

    ::ok !eval{ $obj->set_aon_attr(['a']) ; 1; }
        => 'Non-num set_aon_attr failed as expected';

};

subtest 'aoi_attr tests' => sub {

    ::is_deeply $obj->get_aoi_attr, [4,5,6] => 'aoi attr set correctly';

    ::ok !eval{ $obj = Typeful->new({ int_attr => 1, aoi_attr => 'a' }) ; 1; }
        => 'Non-array aoi_attr failed as expected';

    ::ok !eval{ $obj = Typeful->new({ int_attr => 1, aoi_attr => ['a'] }) ; 1; }
        => 'Non-num aoi_attr failed as expected';

    ::ok +(eval{ $obj->set_aoi_attr([4,5,6]); 1 } // diag $@)
        => 'aoi set_aoi_attr succeeded as expected';

    ::ok !eval{ $obj->set_aoi_attr(['a']) ; 1; }
        => 'Non-num set_aoi_attr failed as expected';

};

subtest 'hoi_attr tests' => sub {

    ::is_deeply $obj->get_hoi_attr, {c=>3,p=>0} => 'hoi attr set correctly';

    ::ok !eval{ $obj = Typeful->new({ int_attr => 1, hoi_attr => 'a' }) ; 1; }
        => 'Non-array hoi_attr failed as expected';

    ::ok !eval{ $obj = Typeful->new({ int_attr => 1, hoi_attr => ['a'] }) ; 1; }
        => 'Non-num hoi_attr failed as expected';

    ::ok +(eval{ $obj->set_hoi_attr({c=>3,p=>0}); 1 } // diag $@)
        => 'hoi set_hoi_attr succeeded as expected';

    ::ok !eval{ $obj->set_hoi_attr({c=>'a'}) ; 1; }
        => 'Non-num set_hoi failed as expected';

};

subtest 'Direct assignment' => sub {
    $obj->direct_assignment();
};

done_testing;

