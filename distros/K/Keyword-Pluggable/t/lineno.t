#!perl
use strict;
use warnings FATAL => 'all';

use Test::More tests => 6;

BEGIN {
    package Some::Module;
    use Keyword::Pluggable;
    sub import {
        Keyword::Pluggable::define keyword => 'provided', code => 'if';
    }
    sub unimport {
        Keyword::Pluggable::undefine keyword => 'provided';
    }
    $INC{'Some/Module.pm'} = __FILE__;
};

use Some::Module;

provided (1) {
    is(__LINE__, 22);
}

#line 1
provided(1){is __LINE__, 1;}
is __LINE__, 2;

provided
#line 1
(1) { is __LINE__, 1; }
is __LINE__, 2;

provided (2) { provided (3) {
        is __LINE__, 5;
    }
}
