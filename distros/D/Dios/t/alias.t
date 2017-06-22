use strict;
use warnings;

use Test::More;

BEGIN {
    if ($] < 5.022) {
        eval "use Data::Alias";
        plan skip_all => "Data::Alias required for aliased argument under Perl $]" if $@;
    }
}

{
    package Stuff;

    use Test::More;

    use Dios;

    method add_meaning($arg is alias, *@etc is alias) {
        $arg += 42;
        for my $extra (@etc) {
            $extra++;
        }
    }

    my $life = 23;
    Stuff->add_meaning($life);
    is $life, 23 + 42;

    $life = 86;
    my @etc  = (1..3);
    Stuff->add_meaning($life, @etc);
    is $life, 86 + 42;
    is_deeply \@etc, [2..4];
}

done_testing();
