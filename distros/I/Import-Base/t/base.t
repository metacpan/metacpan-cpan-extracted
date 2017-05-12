
use strict;
use warnings;
use lib 't/lib';
use Test::More;

subtest 'static API' => sub {
    subtest 'common imports' => sub {
        subtest 'strict' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package static::no::strict;
                no strict;
                use MyStatic;
                $foo = 0;
            };
            delete $SIG{__WARN__};

            like $@, qr/Global symbol "\$foo" requires explicit package name/;
            ok !$warn, 'no warnings' or diag $warn;
        };

        subtest 'warnings' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package static::no::warnings;
                no warnings;
                use MyStatic;
                my $foo = 0 + "foo";
            };
            delete $SIG{__WARN__};
            ok !$@, 'lived' or diag $@;
            like $warn, qr/Argument "foo" isn't numeric in addition/;
        };
    };

    subtest 'bundles' => sub {
        subtest 'no bundles are imported by default' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package static::without::bundle;
                no strict; no warnings;
                use MyStatic;
                catdir( "", "foo" );
            };
            delete $SIG{__WARN__};

            like $@, qr/\QUndefined subroutine &static::without::bundle::catdir called/;
            ok !$warn, 'no warnings' or diag $warn;
        };

        subtest 'bundle imports sub' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package static::with::bundle;
                no strict; no warnings;
                use MyStatic 'Spec';
                catdir( "", "foo" );
            };
            delete $SIG{__WARN__};

            unlike $@, qr/\QUndefined subroutine &static::with::bundle::catdir called/;
            ok !$@, 'lived' or diag $@;
            ok !$warn, 'no warnings' or diag $warn;
        };

        subtest 'bundle unimports' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package static::with::bundle::unimport;
                no strict; no warnings;
                use MyStatic 'lax';
                my $foo;
                my $bar = $foo . " bar";
            };
            delete $SIG{__WARN__};
            ok !$@, 'lived' or diag $@;
            unlike $warn, qr/Use of uninitialized value \$foo in concatenation/;
            ok !$warn, 'no warnings' or diag $warn;
        };
    };

    subtest 'inheritance' => sub {
        subtest 'common imports' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package static::no::inherited::strict;
                no strict;
                use MyStaticInherits;
                $foo = 0;
                $bar = "foo";
                $$bar = 1;
            };
            delete $SIG{__WARN__};

            unlike $@, qr/Global symbol "\$foo" requires explicit package name/;
            like $@, qr/\QCan't use string ("foo") as a SCALAR ref/;
            ok !$warn, 'no warnings' or diag $warn;
        };

        subtest 'bundles' => sub {
            subtest 'no bundles are imported by default' => sub {
                my $warn;
                local $SIG{__WARN__} = sub { $warn = $_[0] };
                eval q{
                    package static::without::inherited::bundle;
                    no strict; no warnings;
                    use MyStaticInherits;
                    catfile( "", "foo" );
                };
                delete $SIG{__WARN__};

                like $@, qr/\QUndefined subroutine &static::without::inherited::bundle::catfile called/;
                ok !$warn, 'no warnings' or diag $warn;
            };

            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package static::with::inherited::bundle;
                no strict; no warnings;
                use MyStaticInherits 'Spec';
                catfile( "", "foo" );
                catdir( "", "foo" );
            };
            delete $SIG{__WARN__};

            unlike $@, qr/\QUndefined subroutine &static::with::inherited::bundle::catdir called/;
            unlike $@, qr/\QUndefined subroutine &static::with::inherited::bundle::catfile called/;
            ok !$@, 'lived' or diag $@;
            ok !$warn, 'no warnings' or diag $warn;
        };
    };
};

subtest 'dynamic API' => sub {
    subtest 'common imports' => sub {
        subtest 'strict' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package dynamic::no::strict;
                no strict;
                use MyDynamic;
                $foo = 0;
            };
            delete $SIG{__WARN__};

            like $@, qr/Global symbol "\$foo" requires explicit package name/;
            ok !$warn, 'no warnings' or diag $warn;
        };

        subtest 'warnings' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package dynamic::no::warnings;
                no warnings;
                use MyDynamic;
                my $foo = 0 + "foo";
            };
            delete $SIG{__WARN__};
            like $warn, qr/Argument "foo" isn't numeric in addition/;
            ok !$@, 'lived' or diag $@;
        };
    };

    subtest 'bundles' => sub {
        subtest 'no bundles are imported by default' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package dynamic::without::bundle;
                no strict; no warnings;
                use MyDynamic;
                catdir( "", "foo" );
            };
            delete $SIG{__WARN__};

            like $@, qr/\QUndefined subroutine &dynamic::without::bundle::catdir called/;
            ok !$warn, 'no warnings' or diag $warn;
        };

        subtest 'bundle imports sub' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package dynamic::with::bundle;
                no strict; no warnings;
                use MyDynamic 'Spec';
                catdir( "", "foo" );
            };
            delete $SIG{__WARN__};

            unlike $@, qr/\QUndefined subroutine &dynamic::with::bundle::catdir called/;
            ok !$@, 'lived' or diag $@;
            ok !$warn, 'no warnings' or diag $warn;
        };

        subtest 'bundle unimports' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package dynamic::with::bundle::unimport;
                no strict; no warnings;
                use MyDynamic 'lax';
                my $foo;
                my $bar = $foo . " bar";
            };
            delete $SIG{__WARN__};
            unlike $warn, qr/Use of uninitialized value \$foo in concatenation/;
            ok !$warn, 'no warnings' or diag $warn;
            ok !$@, 'lived' or diag $@;
        };
    };

    subtest 'inheritance' => sub {
        subtest 'common imports' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package dynamic::no::inherited::strict;
                no strict;
                use MyDynamicInherits;
                $foo = 0;
                $bar = "foo";
                $$bar = 1;
            };
            delete $SIG{__WARN__};

            unlike $@, qr/Global symbol "\$foo" requires explicit package name/;
            like $@, qr/\QCan't use string ("foo") as a SCALAR ref/;
            ok !$warn, 'no warnings' or diag $warn;
        };

        subtest 'bundles' => sub {
            subtest 'no bundles are imported by default' => sub {
                my $warn;
                local $SIG{__WARN__} = sub { $warn = $_[0] };
                eval q{
                    package dynamic::without::inherited::bundle;
                    no strict; no warnings;
                    use MyDynamicInherits;
                    catfile( "", "foo" );
                };
                delete $SIG{__WARN__};

                like $@, qr/\QUndefined subroutine &dynamic::without::inherited::bundle::catfile called/;
                ok !$warn, 'no warnings' or diag $warn;
            };

            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package dynamic::with::inherited::bundle;
                no strict; no warnings;
                use MyDynamicInherits 'Spec';
                catfile( "", "foo" );
                catdir( "", "foo" );
            };
            delete $SIG{__WARN__};

            unlike $@, qr/\QUndefined subroutine &dynamic::with::inherited::bundle::catdir called/;
            unlike $@, qr/\QUndefined subroutine &dynamic::with::inherited::bundle::catfile called/;
            ok !$@, 'lived' or diag $@;
            ok !$warn, 'no warnings' or diag $warn;
        };
    };
};

done_testing;
