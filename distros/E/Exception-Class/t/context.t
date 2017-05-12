use strict;
use warnings;

use Test::More;

use Exception::Class (
    'Foo',
    'Bar' => { isa => 'Foo' },
);

Bar->NoContextInfo(1);

## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
{
    eval { Foo->throw( error => 'foo' ) };

    my $e = Exception::Class->caught;

    ok( defined( $e->trace ), 'has trace detail' );
}

{
    eval { Bar->throw( error => 'foo' ) };

    my $e = Exception::Class->caught;

    ok( !defined( $e->trace ), 'has no trace detail' );
}

done_testing();
