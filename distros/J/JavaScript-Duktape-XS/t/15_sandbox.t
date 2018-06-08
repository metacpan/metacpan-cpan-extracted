use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Output;
use JavaScript::Duktape::XS;

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
    my $duk = JavaScript::Duktape::XS->new({ max_memory_bytes => 0});
    ok($duk, "created JavaScript::Duktape::XS object with max_memory_bytes => 0");
    stderr_like sub { $duk->eval(get_js()); },
                qr/error: Error: alloc failed/,
                "got correct error from memory sandbox";
}

sub test_sandbox_runtime {
    my $duk = JavaScript::Duktape::XS->new({ max_timeout_us => 0});
    ok($duk, "created JavaScript::Duktape::XS object with max_timeout_us => 0");
    stderr_like sub { $duk->eval(get_js()); },
                qr/error: RangeError: execution timeout/,
                "got correct error from runtime sandbox";
}

sub main {
    test_sandbox_memory();
    test_sandbox_runtime();
    done_testing;
    return 0;
}

exit main();
