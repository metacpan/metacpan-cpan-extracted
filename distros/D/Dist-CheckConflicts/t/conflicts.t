#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use lib 't/lib/conflicts';

{
    require Foo::Conflicts::Good;
    is_deeply(
        [ Foo::Conflicts::Good->calculate_conflicts ],
        [],
        "correct versions for all conflicts",
    );
    is(
        exception { Foo::Conflicts::Good->check_conflicts },
        undef,
        "no conflict error"
    );
}

{
    require Foo::Conflicts::Bad;

    is_deeply(
        [ Foo::Conflicts::Bad->calculate_conflicts ],
        [
            { package => 'Foo',      installed => '0.02', required => '0.03' },
            { package => 'Foo::Two', installed => '0.02', required => '0.02' },
        ],
        "correct versions for all conflicts",
    );
    is(
        exception { Foo::Conflicts::Bad->check_conflicts },
        "Conflicts detected for Foo::Conflicts::Bad:\n  Foo is version 0.02, but must be greater than version 0.03\n  Foo::Two is version 0.02, but must be greater than version 0.02\n",
        "correct conflict error"
    );
}

{
    require Bar::Conflicts::Good;
    is_deeply(
        [ Bar::Conflicts::Good->calculate_conflicts ],
        [],
        "correct versions for all conflicts",
    );
    is(
        exception { Bar::Conflicts::Good->check_conflicts },
        undef,
        "no conflict error"
    );
}

{
    require Bar::Conflicts::Bad;

    is_deeply(
        [ Bar::Conflicts::Bad->calculate_conflicts ],
        [
            { package => 'Bar',      installed => '0.02', required => '0.03' },
            { package => 'Bar::Two', installed => '0.02', required => '0.02' },
        ],
        "correct versions for all conflicts",
    );
    is(
        exception { Bar::Conflicts::Bad->check_conflicts },
        "Conflicts detected for Bar::Conflicts::Bad:\n  Bar is version 0.02, but must be greater than version 0.03\n  Bar::Two is version 0.02, but must be greater than version 0.02\n",
        "correct conflict error"
    );
}

{
    # conflicting module is utterly broken

    require Foo::Conflicts::Broken;

    my @conflicts;
    my $warning = '';
    {
        local $SIG{__WARN__} = sub { $warning .= $_[0] };
        @conflicts = Foo::Conflicts::Broken->calculate_conflicts;
    }

    like $warning,
        qr/Warning: Broken did not compile/,
        'Warning is issued when Broken fails to compile';

    is_deeply(
        \@conflicts,
        [
            { package => 'Broken', installed => 'unknown', required => '0.03' },
        ],
        "correct versions for all conflicts",
    );

    $warning = '';
    {
        local $SIG{__WARN__} = sub { $warning .= $_[0] };
        like(
            exception { Foo::Conflicts::Broken->check_conflicts },
            qr/^Conflicts detected for Foo::Conflicts::Broken:\n  Broken is version unknown, but must be greater than version 0.03\n/,
            "correct conflict error",
        );
    }
    like $warning,
        qr/Warning: Broken did not compile/,
        'Warning is also issued when Broken fails to compile',
    ;
}

done_testing;
