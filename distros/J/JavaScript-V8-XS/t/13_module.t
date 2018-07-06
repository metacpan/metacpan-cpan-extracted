use strict;
use warnings;

use Data::Dumper;
use Test::More;

my $CLASS = 'JavaScript::V8::XS';

sub _module_resolve {
    my ($requested_id, $parent_id) = @_;

    my $module_name = sprintf("%s.js", $requested_id);
    # printf STDERR ("resolve_cb requested-id='%s', parent-id='%s', resolve-to='%s'\n", $requested_id, $parent_id, $module_name);
    return $module_name;

}

sub _module_load {
    my ($module_name, $exports, $module) = @_;

    # printf STDERR ("load_cb module_name='%s'\n", $module_name);

    my $source;
    if ($module_name eq 'pig.js') {
        $source = sprintf("module.exports = 'you\\'re about to get eaten by %s';", $module_name);
    }
    elsif ($module_name eq 'cow.js') {
        $source = "module.exports = require('pig');";
    }
    elsif ($module_name eq 'ape.js') {
        $source = "module.exports = { module: module, __filename: __filename, wasLoaded: module.loaded };";
    }
    elsif ($module_name eq 'badger.js') {
        $source = "exports.foo = 123; exports.bar = 234;";
    }
    elsif ($module_name eq 'comment.js') {
        $source = "exports.foo = 123; exports.bar = 234; // comment";
    }
    elsif ($module_name eq 'shebang.js') {
        $source = "#!ignored\nexports.foo = 123; exports.bar = 234;";
    }

    return $source;
}

sub test_module {
    my $vm = $CLASS->new();
    $vm->set('perl_module_resolve', \&_module_resolve);
    $vm->set('perl_module_load', \&_module_load);
    ok($vm, "created $CLASS object");


    SKIP: {
        skip 'modules not (yet) supported in V8';

        $vm->eval('var p = require("pig");');
        is($vm->typeof('p'), 'string', 'basic require()');

        $vm->eval('var r = require("cow"); var c = r.indexOf("pig");');
        # printf STDERR ("cow: %s", Dumper($vm->get('r')));
        ok($vm->get('c') >= 0, 'nested require()');

        $vm->eval('var ape1 = require("ape"); var ape2 = require("ape");');
        my $a1 = $vm->get('ape1');
        my $a2 = $vm->get('ape2');
        is_deeply($a1, $a2, 'cached require');

        $vm->eval('var ape1 = require("ape"); var inCache = "ape.js" in require.cache; delete require.cache["ape.js"]; var ape2 = require("ape");');
        ok($vm->get('inCache'), 'cached required, inCache');
        ok($vm->get('ape2') ne $vm->get('ape1'), 'cached require, not equal');

        $vm->eval('var ape3 = require("ape");');

        is($vm->typeof('ape3.module.require'), "function", "module.require is a function");

        my $a30 = $vm->get('ape3');
        my $a31 = $vm->get('ape3.module.exports');
        my $a32 = $vm->get('ape3.module.id');
        my $a33 = $vm->get('ape3.module.filename');
        my $a34 = $vm->get('ape3.module.loaded');
        my $a35 = $vm->get('ape3.wasLoaded');
        my $a36 = $vm->get('ape3.__filename');

        is_deeply($a30, $a31, 'aped require');

        is($a32, 'ape.js', 'ape module id');

        is($a32, $a33, 'ape module filename');

        ok( $a34, 'module loaded');
        ok(!$a35, 'wasLoaded');

        is($a36, 'ape.js', 'ape __filename');

        $vm->eval('var badger = require("badger");');
        # printf STDERR ("badger: %s", Dumper($vm->get('badger')));
        is($vm->get('badger.foo'), 123, 'exports.foo assignment');
        is($vm->get('badger.bar'), 234, 'exports.bar assignment');

        $vm->eval('var comment = require("comment");');
        # printf STDERR ("comment %s", Dumper($vm->get('comment')));
        is($vm->get('comment.foo'), 123, 'comment.foo, last line with // comment');
        is($vm->get('comment.bar'), 234, 'comment.bar, last line with // comment');

        $vm->eval('var shebang = require("shebang");');
        is($vm->get('shebang.foo'), 123, 'shebang.foo');
        is($vm->get('shebang.bar'), 234, 'shebang.bar');
    };
}

sub main {
    use_ok($CLASS);

    test_module();
    done_testing;

    return 0;
}

exit main();
