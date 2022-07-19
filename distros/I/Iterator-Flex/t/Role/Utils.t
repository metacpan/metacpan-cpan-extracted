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

subtest '_can_meth' => sub {

    package My::T::Role::Utils::_can_meth;
    use Test2::V0;
    use Role::Tiny::With;
    with 'Iterator::Flex::Role::Utils';

    my $_can_meth = \&_can_meth;

    subtest 'class' => sub {
        my $pkg = ::Pkg;

        subtest 'reverse order' => sub {
            # add in reverse order of lookup
            for my $method ( 'method1', '__method1__' ) {
                $pkg->add_symbol( '&' . $method, sub { } );

                is( $pkg->name->$_can_meth( $method ), $pkg->get_symbol( '&' . $method ), $method );
            }
        };

        subtest 'normal order' => sub {
            # add in order of lookup. should always get __method__
            for my $method ( '__method2__', 'method2' ) {
                $pkg->add_symbol( '&' . $method, sub { } );

                is( $pkg->name->$_can_meth( $method ), $pkg->get_symbol( '&__method2__' ), $method );
            }
        };

        subtest 'bad method' => sub {
            isa_ok( dies { $pkg->name->$_can_meth( [] ) }, ['Iterator::Flex::Failure::parameter'] );
        };

    };

    subtest 'object' => sub {
        my $pkg = ::Pkg;
        my $obj = bless {}, $pkg->name;

        subtest 'reverse order' => sub {
            # add in reverse order of lookup
            for my $method ( 'method1', '__method1__' ) {
                $pkg->add_symbol( '&' . $method, sub { } );

                is( $pkg->name->$_can_meth( $obj, $method ), $pkg->get_symbol( '&' . $method ), $method );
            }
        };

        subtest 'normal order' => sub {
            # add in order of lookup. should always get __method__
            for my $method ( '__method2__', 'method2' ) {
                $pkg->add_symbol( '&' . $method, sub { } );

                is( $pkg->name->$_can_meth( $obj, $method ), $pkg->get_symbol( '&__method2__' ), $method );
            }
        };

        subtest 'bad method' => sub {
            isa_ok( dies { $pkg->name->$_can_meth( $obj, [] ) }, ['Iterator::Flex::Failure::parameter'] );
        };

    };

    subtest 'return value' => sub {

        my $pkg = ::Pkg;
        $pkg->add_symbol( '&__method__', sub { } );

        is( $pkg->name->$_can_meth( 'method', { name => 1 } ), '__method__', 'name' );

        is( $pkg->name->$_can_meth( 'method', { code => 1 } ), $pkg->get_symbol( '&__method__' ), 'code' );

        is(
            [ $pkg->name->$_can_meth( 'method', { code => 1, name => 1 } ) ],
            [ '__method__', $pkg->get_symbol( '&__method__' ) ],
            'name + code'
        );
    }

};

subtest '_throw' => sub {

    package My::T::Role::Utils::_throw;
    use Test2::V0;
    use Role::Tiny ();

    subtest 'class' => sub {
        my $pkg = ::Pkg;
        Role::Tiny->apply_roles_to_package( $pkg->name, 'Iterator::Flex::Role::Utils' );

        my $name = $pkg->name;

        like(
            dies { eval "package $name; __PACKAGE__->_throw( internal => 'foo' )"; die $@ if $@ ne '' },
            qr|Failure caught at t/Role/Utils.t line \d+\.$|m,
        );

    };


};

done_testing;
