use strict;
use warnings;

use Data::Dumper;
use Path::Tiny;
use Test::More;
use Test::Output qw/ stderr_from /;

my $CLASS = 'JavaScript::V8::XS';

sub load_js_file {
    my ($vm, $file) = @_;

    my $path = Path::Tiny::path($file);
    my $code = $path->slurp_utf8();
    $vm->eval($code);
    ok(1, "loaded file '$file'");
}

sub check_functions {
    my ($err, $file, $funcs) = @_;

    foreach my $func (@$funcs) {
        my $expected = quotemeta("at $func") . '.*' . quotemeta("($file:") . '[0-9]+(:[0-9]+)?' . quotemeta(')');
        like($err, qr/$expected/, "found function $file:$func in stack trace");
    }
}

sub check_variables {
    my ($err, $file, $vars) = @_;

    foreach my $var (@$vars) {
        my $expected = "[^a-zA-Z0-9_]" . quotemeta("$var") . "[^a-zA-Z0-9_]";
        like($err, qr/$expected/, "found variable $file:$var in stack trace");
    }
}

sub test_stacktrace {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my $js_code = <<EOS;
var fail = true;
function d() { if (fail) { throw new Error("failed"); } }
function c() { if (fail) { return gonzo.length; } }
function b() { c(); }
function main() { b(); return "ok"; }
EOS

    my $js_file = 'myFileName.js';
    $vm->eval($js_code, $js_file);

    my @funcs = qw/ main b c /;
    my @vars = qw/ gonzo /;
    my $call = 'main';
    my $err = stderr_from(sub { $vm->eval("$call()", $js_file) });
    # print STDERR Dumper($err);

    check_functions($err, $js_file, \@funcs);
    check_variables($err, $js_file, \@vars);
}

sub main {
    use_ok($CLASS);

    test_stacktrace();
    done_testing;
    return 0;
}

exit main();
