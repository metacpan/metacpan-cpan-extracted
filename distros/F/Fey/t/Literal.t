use strict;
use warnings;

use Test::More 0.88;
use Fey::Literal;

{
    my $lit = Fey::Literal->new_from_scalar(4.2);
    isa_ok( $lit, 'Fey::Literal::Number' );

    $lit = Fey::Literal->new_from_scalar(4);
    isa_ok( $lit, 'Fey::Literal::Number' );

    $lit = Fey::Literal->new_from_scalar('4');
    isa_ok( $lit, 'Fey::Literal::Number' );

    $lit = Fey::Literal->new_from_scalar('hello');
    isa_ok( $lit, 'Fey::Literal::String' );

    $lit = Fey::Literal->new_from_scalar('hello 21');
    isa_ok( $lit, 'Fey::Literal::String' );

    $lit = Fey::Literal->new_from_scalar('');
    isa_ok( $lit, 'Fey::Literal::String' );
}

{

    package Num;

    use overload '0+' => sub { ${ $_[0] } };

    sub new {
        my $num = $_[1];
        return bless \$num, __PACKAGE__;
    }
}

{
    my $lit = Fey::Literal->new_from_scalar( Num->new(42) );
    isa_ok( $lit, 'Fey::Literal::Number' );
    is( $lit->number(), 42, 'value is 42' );
}

{

    package Str;

    use overload q{""} => sub { ${ $_[0] } };

    sub new {
        my $str = $_[1];
        return bless \$str, __PACKAGE__;
    }
}

{
    my $lit = Fey::Literal->new_from_scalar( Str->new('test') );
    isa_ok( $lit, 'Fey::Literal::String' );
    is( $lit->string(), 'test', 'value is test' );
}

{
    eval { Fey::Literal::Term->new( [] ) };
    like(
        $@, qr/Validation failed/,
        'Term rejects an non-blessed ref'
    );

    eval { Fey::Literal::Term->new( bless {}, 'Foo' ) };
    like(
        $@, qr/Validation failed/,
        'Term rejects an blessed ref that is not overloaded and does not have a sql_or_alias_method'
    );
}

done_testing();
