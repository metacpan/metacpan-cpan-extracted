use Test2::V0;

use Function::Interface::Impl;

Function::Interface::Impl::_register_check_list('Foo', 'IFoo', 'Foo.pm', 3);

is @Function::Interface::Impl::CHECK_LIST, 1;
is $Function::Interface::Impl::CHECK_LIST[0], {
    package => 'Foo',
    interface_package => 'IFoo',
    filename => 'Foo.pm',
    line => 3,
};

done_testing;
