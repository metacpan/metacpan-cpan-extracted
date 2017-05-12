# Test that you can change the invocant.

use strict;
use warnings;

use Dios;
use Test::More;
plan tests => 8;

class StdInvocant {
    method foo { ::ok eval{ $self->bar } => 'std invocant' }
    method bar { 1 }
    method named($me:) { $me->foo() }
}

{
    use Dios { invocant => '$this' };
    class ThisInvocant {
        method foo { ::ok eval{ $this->bar } => 'this invocant' }
        method bar { 1 }
        method named($me:) { $me->foo() }
    }
}

class StdInvocantRevert {
    method foo { ::ok eval{ $self->bar } => 'std invocant reverts' }
    method bar { 1 }
    method named($me:) { $me->foo() }
}

{
    use Dios { inv => 'that' };
    class ThatInvocant {
        method foo { ::ok eval{ $that->bar } => 'that invocant' }
        method bar { 1 }
        method named($me:) { $me->foo() }
    }
}


StdInvocant->foo();
StdInvocant->named();

StdInvocantRevert->foo();
StdInvocantRevert->named();

ThisInvocant->foo();
ThisInvocant->named();

ThatInvocant->foo();
ThatInvocant->named();

done_testing();
