
use strict;
use warnings;
use lib 't/lib';
use Test::More;

subtest 'import bundles at runtime' => sub {

    subtest "can't import special bundle at compile time" => sub {
        my $warn;
        local $SIG{__WARN__} = sub { $warn = $_[0] };
        eval q{
            package runtime::import::dies;
            use MyRuntime 'dies';
        };
        like $@, qr/GOODBYE/;
        ok !$warn or diag $warn;
    };

    my $warn;
    local $SIG{__WARN__} = sub { $warn = $_[0] };
    eval q{
        package runtime::import;
        use MyRuntime;
        eval {
            MyRuntime->import_bundle( 'dies' );
        };
        warn $@;
    };
    ok !$@ or diag $@;
    like $warn, qr/GOODBYE/;
};

done_testing;
