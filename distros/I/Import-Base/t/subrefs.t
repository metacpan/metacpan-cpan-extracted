
use strict;
use warnings;
use lib 't/lib';
use Test::More;

subtest 'static API' => sub {

    subtest 'subrefs' => sub {
        subtest 'modules and imports' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package static::subref;
                #no strict; no warnings;
                use MyStaticSubrefs;
                my $foo;
                $bar = $foo . " derp";
                my $baz = 0 + "foo";
            };
            delete $SIG{__WARN__};

            ok !$@, 'lived' or diag $@;
            unlike $warn, qr/Use of uninitialized value/;
            like $warn, qr/Argument "foo" isn't numeric in addition/;
        };

        subtest 'subrefs in bundle' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package static::subref::bundle;
                #no strict; no warnings;
                use MyStaticSubrefs 'Lax';
                my $foo;
                $bar = $foo . " derp";
                my $baz = 0 + "foo";
            };
            delete $SIG{__WARN__};

            ok !$@, 'lived' or diag $@;
            unlike $warn, qr/Use of uninitialized value/;
            unlike $warn, qr/Argument "foo" isn't numeric in addition/;
            ok !$warn, 'we did nothing to warn';
        };

        subtest 'subrefs with side-effects' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package static::subref::isa;
                #no strict; no warnings;
                use MyStaticSubrefs 'Inherit';
            };
            delete $SIG{__WARN__};

            ok !$@, 'lived' or diag $@;
            ok !$warn, 'we did nothing to warn';
            ok static::subref::isa->isa( 'inherited' ), 'ISA was altered';
        };

    };
};

subtest 'dynamic API' => sub {

    subtest 'subrefs' => sub {
        subtest 'modules and imports' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package dynamic::subref;
                #no strict; no warnings;
                use MyDynamicSubrefs;
                my $foo;
                $bar = $foo . " derp";
                my $baz = 0 + "foo";
            };
            delete $SIG{__WARN__};

            ok !$@, 'lived' or diag $@;
            unlike $warn, qr/Use of uninitialized value/;
            like $warn, qr/Argument "foo" isn't numeric in addition/;
        };

        subtest 'subrefs in bundle' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package dynamic::subref::bundle;
                #no strict; no warnings;
                use MyDynamicSubrefs 'Lax';
                my $foo;
                $bar = $foo . " derp";
                my $baz = 0 + "foo";
            };
            delete $SIG{__WARN__};

            ok !$@, 'lived' or diag $@;
            unlike $warn, qr/Use of uninitialized value/;
            unlike $warn, qr/Argument "foo" isn't numeric in addition/;
            ok !$warn, 'we did nothing to warn';
        };

        subtest 'subrefs with side-effects' => sub {
            my $warn;
            local $SIG{__WARN__} = sub { $warn = $_[0] };
            eval q{
                package dynamic::subref::isa;
                #no strict; no warnings;
                use MyDynamicSubrefs 'Inherit';
            };
            delete $SIG{__WARN__};

            ok !$@, 'lived' or diag $@;
            ok !$warn, 'we did nothing to warn';
            ok dynamic::subref::isa->isa( 'inherited' ), 'ISA was altered';
        };

    };
};

done_testing;
