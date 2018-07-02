use strict;
use warnings;

use Data::Dumper;
use Test::More;

my $CLASS = 'JavaScript::Duktape::XS';

sub test_stats {
    my $fib = 'function fib(n) { if (n <= 1) { return 1; } else { return fib(n-1)+fib(n-2);}}';
    foreach my $gather_stats (@{[ undef, 0, 1 ]}) {
        my $vm;
        if (!defined $gather_stats) {
            $vm = $CLASS->new();
            ok($vm, "created $CLASS object with default options");
        } else {
            $vm = $CLASS->new({gather_stats => $gather_stats});
            ok($vm, "created $CLASS object with gather_stats => $gather_stats");
        }

        $vm->eval($fib);

        for (1..3) {
            my $got = $vm->eval('fib(19);');
            my $stats = $vm->get_stats();
            # printf STDERR ("STATS: %s", Dumper($stats));
            foreach my $category (qw/ compile run /) {
                if (!$gather_stats) {
                    ok(!exists $stats->{$category}, "category $category does not exist in stats");
                }
                else {
                    if (!exists $stats->{$category}) {
                        ok(0, "category $category exists in stats");
                        next;
                    }
                    my $data = $stats->{$category};
                    foreach my $name (qw/ memory_bytes elapsed_us /) {
                        ok(exists $data->{$name}, "name $name exists in stats for $category");
                        ok($data->{$name} >= 0, "name $name has a valid value in stats for $category");
                    }
                }
            }
        }
    }
}

sub main {
    use_ok($CLASS);

    test_stats();
    done_testing;
    return 0;
}

exit main();
