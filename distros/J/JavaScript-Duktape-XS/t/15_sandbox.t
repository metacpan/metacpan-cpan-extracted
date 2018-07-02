use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Output qw/ stderr_like /;

my $CLASS = 'JavaScript::Duktape::XS';

sub get_js {
    my $js = <<JS;
var str = '';
for (step = 0; step < 1000000000; step++) {
    str += 'gonzo';
}
JS
    return $js;
}

sub test_sandbox_memory {
    my $vm = $CLASS->new({ max_memory_bytes => 0});
    ok($vm, "created $CLASS object with max_memory_bytes => 0");
    stderr_like sub { $vm->eval(get_js()); },
                qr/error: Error: alloc failed/,
                "got correct error from memory sandbox";
}

sub test_sandbox_runtime {
    my $vm = $CLASS->new({ max_timeout_us => 0});
    ok($vm, "created $CLASS object with max_timeout_us => 0");
    stderr_like sub { $vm->eval(get_js()); },
                qr/error: RangeError: execution timeout/,
                "got correct error from runtime sandbox";
}

sub main {
    use_ok($CLASS);

    test_sandbox_memory();
    test_sandbox_runtime();
    done_testing;
    return 0;
}

exit main();
