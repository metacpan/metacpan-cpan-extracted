use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Output qw/ combined_from stderr_like /;

my $CLASS = 'JavaScript::V8::XS';

sub get_js {
    my $js = <<JS;
function a() {
    var str = '';
    for (step = 0; step < 10000000; step++) {
        str += 'gonzo';
    }
}

function b() {
    while(true){ x = new Uint8Array(0xFFFF); x[0xFFFE] = 0xFF; }
}

a();
JS
    return $js;
}

sub test_sandbox_memory {
    # my $vm = $CLASS->new({ max_memory_bytes => 0});
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object with max_memory_bytes => 0");

    SKIP: {
        skip 'sandboxing not (yet) supported in V8', 1;
        my $combined;
        eval {
            # $combined = combined_from(sub { $vm->eval(get_js()); });
            $vm->eval(get_js());
            1;
        } or do {
            $combined = $@ // 'zombie error';
        };
        like($combined,
            qr/error: Error: (alloc failed|allocation failure)/,
            "got correct error from memory sandbox");
    };
}

sub test_sandbox_runtime {
    my $vm = $CLASS->new({ max_timeout_us => 0});
    ok($vm, "created $CLASS object with max_timeout_us => 0");

    SKIP: {
        skip 'sandboxing not (yet) supported in V8', 1;
        stderr_like sub { $vm->eval(get_js()); },
        qr/error: RangeError: execution timeout/,
        "got correct error from runtime sandbox";
    };
}

sub main {
    use_ok($CLASS);

    test_sandbox_memory() for (1..2);
    test_sandbox_runtime();
    done_testing;
    return 0;
}

exit main();
