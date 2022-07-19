#! perl

# ABSTRACT: test translation of imported iterators

use strict;
use warnings;

use 5.10.0;

use Test2::V0;

use Iterator::Flex::Base;

use constant Base => 'Iterator::Flex::Base';

package My::Namespace {
    use Role::Tiny;
    use mro;

    around _namespaces => sub {
        my $orig = shift;
        return ( $_[0], &$orig );
    };

    around _role_namespaces => sub {
        my $orig = shift;
        return ( $_[0] . '::Role', &$orig );
    };

}

package C11::C12 {
    use parent ::Base();
    use Role::Tiny::With;
    with 'My::Namespace';
}
package C11 {
    use parent ::Base();
    use Role::Tiny::With;
    with 'My::Namespace';
}

is( [ Base->_namespaces ],      ['Iterator::Flex'],       'Base' );
is( [ Base->_role_namespaces ], ['Iterator::Flex::Role'], 'Base Role' );

is( [ C11->_namespaces ],      [ 'C11',      'Iterator::Flex' ], 'C11' );
is( [ C11::C12->_namespaces ], [ 'C11::C12', 'Iterator::Flex' ], 'C11::C12' );



done_testing;
