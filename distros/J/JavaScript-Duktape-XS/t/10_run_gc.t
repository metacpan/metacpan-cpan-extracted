use strict;
use warnings;

use Test::More;
use JavaScript::Duktape::XS;

sub test_run_gc {
    my $name = 'gonzo';
    my $count = 1_000;
    my $duk = JavaScript::Duktape::XS->new();
    ok($duk, "created JavaScript::Duktape::XS object");

    $duk->set($name, {});
    foreach my $index (1..$count) {
        $duk->set("$name.value_$index", $index);
    }
    ok($duk, "created $count slots under $name");
    $duk->set($name, undef);
    ok($duk, "set $name to undef");
    my $got = $duk->run_gc();
    ok($got > 0, "ran GC with a non-zero number of passes ($got)");
}

sub main {
    test_run_gc();
    done_testing;

    return 0;
}

exit main();
