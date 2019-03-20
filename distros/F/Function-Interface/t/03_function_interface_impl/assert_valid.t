use Test2::V0;
use lib 't/lib';

use Function::Interface::Impl;

BEGIN {
    no warnings qw(redefine);
    *Function::Interface::Impl::_error = sub {
        return "DIED: @_";
    }
}

use Foo;
use FooNoFoo;
use FooNoParamsInfo;
use FooNoReturnInfo;
use FooInvalidParams;
use FooInvalidReturn;

sub assert_valid {
    my ($package, $interface_package) = @_;
    Function::Interface::Impl::assert_valid(
        $package, $interface_package, __FILE__, __LINE__
    );
}

like assert_valid('Fo', 'IFoo'),
    qr/^DIED: implements package is not loaded yet. required to use/, 'cannot load impl package';

like assert_valid('Foo', 'IFo'),
    qr/^DIED: cannot load interface package: Can't locate IFo.pm/, 'cannot load interface package';

like assert_valid('Foo', 'Test2'),
    qr/^DIED: cannot get interface info/, 'cannot get interface info';

like assert_valid('FooNoFoo', 'IFoo'),
    qr/^DIED: function `foo` is required/, 'required methods';

like assert_valid('FooNoParamsInfo', 'IFoo'),
    qr/^DIED: cannot get function `foo` parameters info/, 'required params info';

like assert_valid('FooNoReturnInfo', 'IFoo'),
    qr/^DIED: cannot get function `foo` return info/, 'required return info';

like assert_valid('FooInvalidParams', 'IFoo'),
    qr/^DIED: function `foo` is invalid parameters/, 'invalid params';

like assert_valid('FooInvalidReturn', 'IFoo'),
    qr/^DIED: function `foo` is invalid return/, 'invalid return';

done_testing;
