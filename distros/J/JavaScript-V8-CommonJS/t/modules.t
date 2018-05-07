use strict;
use Test2::V0;
use Test2::Tools::Exception qw/dies lives/;
use JavaScript::V8::CommonJS;
use FindBin;

my $js = JavaScript::V8::CommonJS->new(paths => ["$FindBin::Bin/modules"]);

$js->add_module( test => {
    assert => sub { ok $_[0], $_[1] },
    print  => sub { },
});


js_test('absolute');
js_test('cyclic');
js_test('determinism');
js_test('exactExports');
js_test('hasOwnProperty');
js_test('method');
js_test('missing');
js_test('monkeys');
js_test('nested');
js_test('relative');
js_test('transitive');



sub js_test {
    my $name = shift;
    local $js->{paths} = ["$FindBin::Bin/modules/1.0/$name"];
    subtest "$name" => sub {
        $js->eval("require('program')");
    };
}



done_testing;
