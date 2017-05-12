use Test::Effects tests => 15;
use warnings;
use 5.014;

use lib 'tlib';

my $warned;

sub _check_warning {
    no warnings 'uninitialized';
    my $warning = "@_" =~ qr{ \A (Variable \s \S+) \s \Qis not available\E }x;
    my $line = '???';
    for my $upscope (0..100) {
        if (caller($upscope) eq 'main') {
            $line = (caller $upscope)[2];
            last;
        }
    }
    ok $warning => "Warned ($+) as expected at line $line";

    $warned = 1;
}

BEGIN { $SIG{__WARN__} = \&_check_warning; }

{
    subtest 'fail --> my inner scalar', sub {
        plan tests => 2;

        my $errmsg;
        use TestModule errors => \$errmsg; BEGIN{ if (!$warned) { fail 'Did not warn as expected' } ok $warned => 'Warning given at line '.__LINE__; $warned = 0 }

        effects_ok { TestModule::dont_succeed() }
                   { return => undef }
                => 'Correct effects';

        is $errmsg, undef() => 'Failed to bind, as expected';
    };
}

{
    subtest 'fail --> my inner hash', sub {
        plan tests => 2;

        my $errmsg;
        use TestModule errors => ($errmsg = {}); BEGIN{ if (!$warned) { fail 'Did not warn as expected' } ok $warned => 'Warning given at line '.__LINE__; $warned = 0 }

        effects_ok { TestModule::dont_succeed() }
                { return => undef }
                => 'Correct effects';

        ok ref($errmsg) ne 'HASH' || !keys %$errmsg => 'Failed to bind, as expected';
    };
}

{
    subtest 'fail --> my inner array', sub {
        plan tests => 2;
        my @errmsg;

        use TestModule errors => \@errmsg; BEGIN{ if (!$warned) { fail 'Did not warn as expected' } ok $warned => 'Warning given at line '.__LINE__; $warned = 0 }

        effects_ok { TestModule::dont_succeed() }
                { return => undef }
                => 'Correct effects';

        is_deeply \@errmsg, [] => 'Failed to bind, as expected';
    };
}



my $outer_var;
{
    subtest 'fail --> my outer scalar', sub {
        plan tests => 2;
        use TestModule errors => \$outer_var; BEGIN{ ok !$warned => 'No unexpected warning at line '.__LINE__; $warned = 0 }

        effects_ok { TestModule::dont_succeed() }
                { return => undef }
                => 'Correct effects';

        is_deeply $outer_var, ["Didn't succeed"]
                    => 'Successfully bound, as expected';
    };
}

{
    subtest 'fail --> our package scalar', sub {
        plan tests => 2;
        our $error;
        use TestModule errors => \$error; BEGIN{ ok !$warned => 'No unexpected warning at line '.__LINE__; $warned = 0 }

        effects_ok { TestModule::dont_succeed() }
                { return => undef }
                => 'Correct effects';

        is_deeply $error, ["Didn't succeed"]
                    => 'Successfully bound, as expected';
    };
}

{
    subtest 'fail --> qualified package scalar', sub {
        plan tests => 2;

        use TestModule errors => \$Other::var; BEGIN{ ok !$warned => 'No unexpected warning at line '.__LINE__; $warned = 0 }

        effects_ok { TestModule::dont_succeed() }
                { return => undef }
                => 'Correct effects';

        is_deeply $Other::var, ["Didn't succeed"]
                    => 'Successfully bound, as expected';
    };
}

done_testing();
