use strict;
use warnings;

use Test::More;

my $CLASS = 'JavaScript::Duktape::XS';

sub test_run_gc {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my $name = 'gonzo';
    my $count = 1_000;

    $vm->set($name, {});
    foreach my $index (1..$count) {
        $vm->set("$name.value_$index", $index);
    }
    ok($vm, "created $count slots under $name");
    $vm->set($name, undef);
    ok($vm, "set $name to undef");
    my $got = $vm->run_gc();
    ok($got > 0, "ran GC with a non-zero number of passes ($got)");
}

sub main {
    use_ok($CLASS);

    test_run_gc();
    done_testing;

    return 0;
}

exit main();
