use strict;
use warnings;

use Test::More;
use Dios::Types;

subtype Nested[T1,T2] of T1[T2];

subtype EmptyAoH of Array[Hash] where {
    for my $hash (@$_) {
        return 0 if keys %$hash;
    };
    return 1;
};


{
    subtype Short[T] of Array[T] where { @$_ < 10 };

    ok !eval{ Dios::Types::validate('Nested[Int,Num]', 'whatever' ) };
    like $@, qr{Incomprehensible type name}s;

    ok        Dios::Types::validate('Short[Int]',      [ (1)  x 9] , )  ;
    ok !eval{ Dios::Types::validate('Short[Int]',      [(1.1) x 9] , ) };
    like $@, qr{Value (.*) is not of type \QShort[Int]\E}s;

    ok        Dios::Types::validate('Short[Num]',      [(1.1) x 9] , )  ;
    ok !eval{ Dios::Types::validate('Short[Int]',      [ (1)  x 10], ) };
    like $@, qr{Value (.*) is not of type \QShort[Int]\E}s;
    ok !eval{ Dios::Types::validate('Short[Int]',      [(1.1) x 10], ) };
    like $@, qr{Value (.*) is not of type \QShort[Int]\E}s;
    ok !eval{ Dios::Types::validate('Short[Num]',      [(1.1) x 10], ) };
    like $@, qr{Value (.*) is not of type \QShort[Num]\E}s;
}

ok        Dios::Types::validate( 'Short[Int]',         [(1) x 9]    );
ok !eval{ Dios::Types::validate( 'Short[Int]',         [(1) x 11]   ) };
like $@, qr{Value (.*) is not of type \QShort[Int]\E}s;

ok        Dios::Types::validate( 'Nested[Array,Hash]', [{},{},{}]  );

ok        Dios::Types::validate( 'EmptyAoH',           [{},{}]     );
ok !eval{ Dios::Types::validate( 'EmptyAoH',           [{a=>1},{}] ) };
like $@, qr{Value (.*) is not of type \QEmptyAoH\E}s;

done_testing();
