#!/usr/bin/env perl

use strict;
use warnings;

no warnings 'portable'; # suppress "v-string in use/require non-portable" warnings

use lib qw(t/lib);

use Test::More tests => 21;
use Devel::Pragma qw(hints);
use File::Spec;

# make sure use VERSION still works OK
use 5;
use 5.006;
use 5.006_000;
use 5.6.0;
use v5.6.0;

{
    BEGIN {
        hints();
        $^H{'Devel::Pragma::Test'} = 1;
    }

    BEGIN {
        require test_2;
    }

    BEGIN {
        is($^H{'Devel::Pragma::Test'}, 1, "compile-time require doesn't clobber %^H");
    }

    ok (test_2::test(), 'compile-time require');
}

{
    BEGIN {
        hints();
        $^H{'Devel::Pragma::Test'} = 1;
    }

    require test_3;

    ok (test_3::test(), 'runtime require');
}

{
    BEGIN {
        hints();
        $^H{'Devel::Pragma::Test'} = 1;
    }

    use test_4;

    BEGIN {
        is($^H{'Devel::Pragma::Test'}, 1, "use doesn't clobber %^H");
    }

    ok (test_4::test(), 'use');
}

{
    BEGIN {
        hints();
        $^H{'Devel::Pragma::Test'} = 1;
    }

    use test_4;

    BEGIN {
        is($^H{'Devel::Pragma::Test'}, 1, "reuse doesn't clobber %^H");
    }

    ok(test_4::test(), 'reuse');
}

eval {
    BEGIN {
        hints();
        $^H{'Devel::Pragma::Test'} = 1;
    }

    use test_7;

    BEGIN {
        is($^H{'Devel::Pragma::Test'}, 1, "eval block doesn't clobber %^H");
    }

    ok(test_7::test(), 'eval BLOCK');
};

ok(not($@), 'eval BLOCK OK');

eval q|
    {
        BEGIN {
            hints();
            $^H{'Devel::Pragma::Test'} = 1;
        }

        use test_8;

        BEGIN {
            is($^H{'Devel::Pragma::Test'}, 1, "eval EXPR doesn't clobber %^H");
        }

        ok(test_7::test(), 'eval EXPR');
    }
|;

ok(not($@), 'eval EXPR OK');

{
    BEGIN {
        hints();
        $^H{'Devel::Pragma::Test'} = 1;
    }

    use test_9;

    BEGIN {
        is($^H{'Devel::Pragma::Test'}, 1, "scope: %^H isn't clobbered");
    }

    ok (test_9::test(), 'scope');

    {
        use test_10;

        BEGIN {
            is($^H{'Devel::Pragma::Test'}, 1, "nested scope: %^H isn't clobbered");
        }

        ok (test_10::test(), 'nested scope');
    }

    use test_11;

    BEGIN {
        is($^H{'Devel::Pragma::Test'}, 1, "scope again: %^H isn't clobbered");
    }

    ok (test_11::test(), 'scope again');
}

{
    BEGIN {
        $^H{'Devel::Pragma::Test'} = 1;
        hints;
    }

    BEGIN {
        ok((($^H & 0x20000) == 0x20000), 'hints sets LOCALIZE_HH');
        is(hints->{'Devel::Pragma::Test'}, 1, 'hints returns a reference to %^H');
    }
}
