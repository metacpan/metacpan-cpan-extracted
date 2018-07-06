use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Output qw/ stderr_like /;

my $CLASS = 'JavaScript::V8::XS';

sub test_js_timeout {
    my ($vm) = @_;

    my $js = <<JS;
var perl_ret = 'EMPTY';
var perl_err = 'EMPTY';

function main() {
    perl_ret += 1

    setTimeout(function () {
        perl_ret += 7
    }, 1000)

    perl_ret += 2

    setTimeout(function () {
        perl_ret += 6
    }, 100)

    perl_ret += 3

    setTimeout(function () {
        perl_ret += 5
    })

    perl_ret += 4
}
JS
    my $got_eval = $vm->eval($js);
    my $got_run = $vm->dispatch_function_in_event_loop('main');
    my $perl_ret = $vm->get('perl_ret');
    is($perl_ret, 'EMPTY1234567', "timeouts dispatched correctly");
}

sub test_timeout_with_error {
    my ($vm) = @_;

    my $js = <<JS;
function main() {
    setTimeout(function () {
        var notdef;
        console.log(notdef.length);
    })
}
JS
    my $got_eval = $vm->eval($js);
    stderr_like sub { $vm->dispatch_function_in_event_loop('main'); },
                qr/Error:/,
                "got correct error from setTimeout";
}

sub main {
    use_ok($CLASS);

    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    test_js_timeout($vm);
    test_timeout_with_error($vm);

    done_testing;
    return 0;
}

exit main();
