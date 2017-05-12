use strict;
use warnings;

use Test::More;

use Exception::Class (
    'Foo',
    'Bar' => { isa => 'Foo' },
);

## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
{
    eval { Foo->throw( error => 'foo' ) };

    my $e = Exception::Class->caught('Bar');

    ok( !$e, 'caught returns false for wrong class' );
}

{
    eval { Foo->throw( error => 'foo' ) };

    my $e = Bar->caught();

    ok( !$e, 'caught returns false for wrong class' );
}

{
    eval { Foo->throw( error => 'foo' ) };

    my $e = Exception::Class->caught('Foo');

    ok( $e, 'caught returns exception for correct class' );
    isa_ok( $e, 'Foo' );
    is( $e->message, 'foo', 'message is "foo"' );
}

{
    eval { Foo->throw( error => 'foo' ) };

    my $e = Foo->caught();

    ok( $e, 'Foo->caught() returns exception' );
    isa_ok( $e, 'Foo' );
}

{
    eval { Foo->throw( error => 'foo' ) };

    my $e = Exception::Class->caught();

    ok( $e, 'Foo->caught() returns exception' );
    isa_ok( $e, 'Foo' );
}

done_testing();
