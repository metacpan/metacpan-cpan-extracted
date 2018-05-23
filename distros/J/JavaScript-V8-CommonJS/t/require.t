
use strict;
use Test2::V0;
use Test2::Tools::Exception qw/dies lives/;
use JavaScript::V8::CommonJS;
use FindBin;
# use Data::Dumper;

my $js = JavaScript::V8::CommonJS->new(paths => ["$FindBin::Bin/modules"]);


subtest 'resolveModule - id' => sub {

    my $file = $js->_resolveModule('simpleMath');
    is $file, "$FindBin::Bin/modules/simpleMath.js", 'relative';
    is $js->eval("resolveModule('simpleMath')"), $file, 'relative (js)';
    is $js->_resolveModule('invalid'), undef, 'invalid';
};

subtest 'resolveModule - json' => sub {

    my $file = $js->_resolveModule('json/file');
    is $file, "$FindBin::Bin/modules/json/file.json", 'relative';
};


subtest 'resolveModule - relative' => sub {
    is $js->eval("typeof require('1.0/relative/submodule/a').foo"), 'function';
};


subtest 'require' => sub {
    is $js->eval("var module = require('simpleMath'); module.foo = 'bar'; module.add(2, 3)"), 5;
    is $js->eval("require('simpleMath').foo"), 'bar', 'cached';
    ok dies { $js->eval("require('invalid')") }, 'invalid module exception';
    like dies { $js->eval("require('notStrict')") }, qr/ReferenceError/, 'use strict';
    like dies { $js->eval("require('notStrict')") }, qr/ReferenceError/, 'dont cache bad modules';
};

subtest 'require json' => sub {
    is $js->eval("require('json/file').foo"), 'bar';
};


subtest 'add_module' => sub {
    local $js->{modules} = {};
    my $module = { bar => 'baz' };
    $js->add_module(foo => $module);
    is $js->modules->{foo}, $module;
    like dies { $js->add_module(foo => {}) }, qr/already exists/, "error: already exists";
};


subtest 'requireNative' => sub {
    local $js->{modules} = {};
    $js->add_module(foo => { bar => 'baz' });
    is $js->eval("requireNative('foo').bar"), 'baz';

    $js->add_module(simpleMath => { native => 'ok' });
    is $js->eval("require('simpleMath').native"), 'ok';

};




done_testing;
