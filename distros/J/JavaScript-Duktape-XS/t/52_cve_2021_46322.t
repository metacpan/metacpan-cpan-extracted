use strict;
use warnings;

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print qq{1..0 # SKIP these tests are for testing by the author\n};
        exit
    }
}

use Data::Dumper;
use Test::More;

my $CLASS = 'JavaScript::Duktape::XS';

sub test_cve_2021_46322 {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my $code = join '', <DATA>;
    $vm->eval($code);

    ok 'true', 'survived';
}

sub main {
    use_ok($CLASS);

    test_cve_2021_46322();
    done_testing;
    return 0;
}

exit main();
__DATA__
function JSEtest() {
    var src = [];
    var i;

    src.push('(function test() {');
    for (i = 0; i < 1e4; i++) {
        src.push('var x' + i + ' = ' + i + ';');
    }
    src.push('var arguments = test(); return "dummy"; })');
    src = src.join('');

    var f = eval(src)(src);

    try {
        f();
    } catch (e) {
        print(e.name + ': ' + e.message);
    }

    print('still here');
}

try {
    JSEtest();
} catch (e) {
    print(e.stack || e);
}
