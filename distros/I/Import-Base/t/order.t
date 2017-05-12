
use strict;
use warnings;
use lib 't/lib';
use Test::More;

subtest 'static API' => sub {

    subtest 'order' => sub {
        subtest 'base modules' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package static::order;
                use MyStaticOrdered;
                catdir( '' );
                splitdir( '' );
            };
            delete $SIG{__WARN__};

            unlike $@, qr/\QUndefined subroutine &static::order::catdir called/;
            unlike $@, qr/\QUndefined subroutine &static::order::splitdir called/;
            ok !$@, 'lived' or diag $@;
            ok !$warn, 'no warnings' or diag $warn;
        };

        subtest 'order in bundle' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package static::order::bundle;
                use MyStaticOrdered 'Early';
                $foo = "bar";
                $bar = "foo";
                $baz = $$bar;
            };
            delete $SIG{__WARN__};

            unlike $@, qr/Global symbol \S+ requires explicit package name/;
            like $@, qr/\QCan't use string ("foo") as a SCALAR ref/;
            ok !$warn, 'we did nothing to warn';
        };

        subtest 'order with "no"' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package static::order::no;
                use MyStaticOrdered 'Lax', 'Strict';
                $foo = "bar";
                $bar = 0 + $foo;
            };
            delete $SIG{__WARN__};

            ok !$@, 'lived' or diag $@;
            ok !$warn, 'we did nothing to warn' or diag $warn;
            unlike $@, qr/Global symbol "\$foo" requires explicit package name/;
            unlike $warn, qr/Argument "bar" isn't numeric in addition/;
        };

    };
};

subtest 'dynamic API' => sub {

    subtest 'order' => sub {
        subtest 'base modules' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package dynamic::order;
                use MyDynamicOrdered;
                catdir( '' );
                splitdir( '' );
            };
            delete $SIG{__WARN__};

            unlike $@, qr/\QUndefined subroutine &dynamic::order::catdir called/;
            unlike $@, qr/\QUndefined subroutine &dynamic::order::splitdir called/;
            ok !$@, 'lived' or diag $@;
            ok !$warn, 'no warnings' or diag $warn;
        };

        subtest 'order in bundle' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package dynamic::order::bundle;
                use MyDynamicOrdered 'Early';
                $foo = "bar";
                $bar = "foo";
                $baz = $$bar;
            };
            delete $SIG{__WARN__};

            unlike $@, qr/Global symbol \S+ requires explicit package name/;
            like $@, qr/\QCan't use string ("foo") as a SCALAR ref/;
            ok !$warn, 'we did nothing to warn';
        };

        subtest 'order with "no"' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package dynamic::order::no;
                use MyDynamicOrdered 'Lax', 'Strict';
                $foo = "bar";
                $bar = 0 + $foo;
            };
            delete $SIG{__WARN__};

            ok !$@, 'lived' or diag $@;
            ok !$warn, 'we did nothing to warn' or diag $warn;
            unlike $@, qr/Global symbol "\$foo" requires explicit package name/;
            unlike $warn, qr/Argument "bar" isn't numeric in addition/;
        };

    };
};

done_testing;
