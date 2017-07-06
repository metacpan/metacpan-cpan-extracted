use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings 0.009 ':no_end_test', ':all';

require Carp;
my $period = ($Carp::VERSION >= 1.25) ? "." : "";

my $line;
{
    package Foo;
    use ok 'Devel::PartialDump' => qw(warn show carp dump);

    sub w { $line = __LINE__; warn ["foo"] }
    sub c { carp ["foo"] }
    sub d { dump ["foo"] }
    sub s { $line = __LINE__; show ["foo"] }
}

can_ok( Foo => qw(warn show carp dump) );


is_deeply(
    [ warnings { Foo::w } ],
    [ "[ \"foo\" ] at " . __FILE__ . " line $line$period\n" ],
    'warn',
);

is_deeply(
    [ warnings { Foo::c; $line = __LINE__ } ],
    [ "[ \"foo\" ] at " . __FILE__ . " line $line$period\n" ],
    'carp',
);

is_deeply(
    [ warnings { like(Foo::d, qr/foo/, 'dump') } ],
    [ ],
    'dump doesn\'t warn',
);

is_deeply(
    [ warnings { is_deeply(Foo::s, ['foo'], 'show') } ],
    [ "[ \"foo\" ] at " . __FILE__ . " line $line$period\n" ],
    'show warns and shows',
);

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
