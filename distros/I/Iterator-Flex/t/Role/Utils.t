#! perl

use Test2::V0;

package My::T::Role::Utils {
    use Package::Stash;

    use Iterator::Flex::Utils qw( throw_failure );

    sub ::Pkg {
        my $package = scalar caller;
        my $stash   = Package::Stash->new( $package );
        $stash->add_symbol( '$TEMPLATE', 'Package0000' )
          unless $stash->has_symbol( '$TEMPLATE' );

        my $name = *{ $stash->namespace->{TEMPLATE} }{SCALAR};
        ++${$name};
        my $pkg = Package::Stash->new( $package . '::' . ${$name} );
        $pkg->add_symbol( '&_throw' => sub { shift; throw_failure( @_ ) } );
        $pkg;
    }
}

subtest 'can_meth' => sub {

    package My::T::Role::Utils::can_meth;
    use Test2::V0;
    use Role::Tiny::With;
    use Iterator::Flex::Utils 'can_meth';

    subtest 'class' => sub {
        my $pkg = ::Pkg;

        subtest 'reverse order' => sub {
            # add in reverse order of lookup
            for my $method ( 'method1', '__method1__' ) {
                $pkg->add_symbol( '&' . $method, sub { } );

                is( can_meth( $pkg->name, $method ), $pkg->get_symbol( '&' . $method ), $method );
            }
        };

        subtest 'normal order' => sub {
            # add in order of lookup. should always get __method__
            for my $method ( '__method2__', 'method2' ) {
                $pkg->add_symbol( '&' . $method, sub { } );

                is( can_meth( $pkg->name, $method ), $pkg->get_symbol( '&__method2__' ), $method );
            }
        };

        subtest 'bad method' => sub {
            isa_ok( dies { can_meth( $pkg->name, [] ) }, ['Iterator::Flex::Failure::parameter'] );
        };

    };

    subtest 'object' => sub {
        my $pkg = ::Pkg;
        my $obj = bless {}, $pkg->name;

        subtest 'reverse order' => sub {
            # add in reverse order of lookup
            for my $method ( 'method1', '__method1__' ) {
                $pkg->add_symbol( '&' . $method, sub { } );

                is( can_meth( $obj, $method ), $pkg->get_symbol( '&' . $method ), $method );
            }
        };

        subtest 'normal order' => sub {
            # add in order of lookup. should always get __method__
            for my $method ( '__method2__', 'method2' ) {
                $pkg->add_symbol( '&' . $method, sub { } );

                is( can_meth( $obj, $method ), $pkg->get_symbol( '&__method2__' ), $method );
            }
        };

        subtest 'bad method' => sub {
            isa_ok( dies { can_meth( $obj, [] ) }, ['Iterator::Flex::Failure::parameter'] );
        };

    };

    subtest 'return value' => sub {

        my $pkg = ::Pkg;
        $pkg->add_symbol( '&__method__', sub { } );

        is( can_meth( $pkg->name, 'method', { name => 1 } ), '__method__', 'name' );

        is( can_meth( $pkg->name, 'method', { code => 1 } ), $pkg->get_symbol( '&__method__' ), 'code' );

        is(
            [ can_meth( $pkg->name, 'method', { code => 1, name => 1 } ) ],
            [ '__method__', $pkg->get_symbol( '&__method__' ) ],
            'name + code'
        );
    }

};

subtest 'throw_failure' => sub {

    package My::T::Role::Utils::_throw;
    use Test2::V0;
    use Iterator::Flex::Utils 'throw_failure';

    subtest 'class' => sub {
        my $pkg = ::Pkg;

        like(
            dies { throw_failure( internal => 'foo' ) },
            qr|Failure caught at t/Role/Utils.t line \d+\.$|m,
        );

    };


};

done_testing;
