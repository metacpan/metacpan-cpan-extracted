
use strict;
use Test2::V0;
use Test2::Tools::Exception qw/dies lives/;
use JavaScript::V8::CommonJS;
use FindBin;
use Data::Dumper;

my $js = JavaScript::V8::CommonJS->new(paths => ["$FindBin::Bin/modules"]);


subtest 'compile exception' => sub {
    my $error = dies { $js->eval(" require('exception')", "test_script") };
    isa_ok $error, 'JavaScript::V8::CommonJS::Exception';
    # diag Dumper $error->stack;
    like $error->message, 'ReferenceError: foo is not defined', 'message';
    like $error->line, 2, 'line';
    like $error->column, '?', 'column';
    is $error->source, "$FindBin::Bin/modules/notStrict.js", 'source';
    is $error->stack->[0]{source}, $error->source, 'stack top item';
    is @{$error->stack}, 4, 'stack length';
    is $error->stack->[-1], {
        source => 'test_script',
        line => 1,
        column => 2
    };
};

subtest 'runtime exception' => sub {
    my $error = dies { $js->eval("require('runtime_exception').makeError()", "test_script") };
    # diag Dumper $error->stack;
    isa_ok $error, 'JavaScript::V8::CommonJS::Exception';
    is $error->message, 'ReferenceError: invalidVar is not defined', 'message';
    is $error->line, 4, 'line';
    is $error->column, 16, 'column';
    like $error->source, "$FindBin::Bin/modules/runtime_exception.js", 'source';
    is $error->stack, [
        {
        'source' => "$FindBin::Bin/modules/runtime_exception.js",
        'line' => '4',
        'column' => '16'
        },
        {
        'column' => '30',
        'line' => '1',
        'source' => 'test_script'
        }
    ], 'stack';
};



done_testing;
