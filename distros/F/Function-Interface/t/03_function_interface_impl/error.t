use Test2::V0;

use Function::Interface::Impl;

like dies {
    Function::Interface::Impl::_error('some message', 'Foo.pm', 3);
}, qr/implements error: some message at Foo.pm line 3\n/;

done_testing;
