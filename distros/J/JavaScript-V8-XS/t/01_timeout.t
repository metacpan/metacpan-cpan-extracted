use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Output qw/ stderr_like /;

my $CLASS = 'JavaScript::V8::XS';

sub test_js_timeout {
    my ($vm) = @_;

    my $js = <<JS;
var perl_ret = '';
var perl_err = '';

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
    my $name = 'main';
    my %types = (
        eval => "%s()",
        dispatch_function_in_event_loop => "%s",
    );
    foreach my $type (sort keys %types) {
        $vm->set('perl_ret', 'EMPTY');
        $vm->set('perl_err', 'EMPTY');
        my $format = $types{$type};
        my $js = sprintf($format, $name);
        my $got_run = $vm->$type($js);
        my $perl_ret = $vm->get('perl_ret');
        is($perl_ret, 'EMPTY1234567', "timeouts dispatched correctly for type $type");
    }
}

sub test_timeout_with_error {
    my ($vm) = @_;

    my $js = <<JS;
function main() {
    setTimeout(function () {
        var notdef;
        notdef.length = 2;
    })
}
JS
    my $got_eval = $vm->eval($js);
    my $name = 'main';
    my %types = (
        eval => "%s()",
        dispatch_function_in_event_loop => "%s",
    );
    foreach my $type (sort keys %types) {
        my $format = $types{$type};
        my $js = sprintf($format, $name);
        stderr_like sub { $vm->$type($js); },
                    qr/Error:/,
                    "got correct error from setTimeout for $type";
    }
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
