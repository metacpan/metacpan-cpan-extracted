
use strict;
use Test2::V0;
use Test2::Tools::Exception qw/dies lives/;
use JavaScript::V8::CommonJS;
use FindBin;
# use Data::Dumper;

my $js = JavaScript::V8::CommonJS->new(
    paths => ["$FindBin::Bin/modules"],
    v8_params => {
        time_limit => 1,
        flags => "--harmony"
    }
);


subtest 'harmony collections' => sub {

    is $js->eval("typeof Set"), "function", "Set";
    is $js->eval("typeof Map"), "function", "Map";
    is $js->eval("typeof WeakMap"), "function", "WeakMap";
};


subtest 'harmony proxy' => sub {

    is $js->eval("typeof Proxy"), "object", "Proxy";
};

subtest 'time limit' => sub {

    my $exception = dies { $js->eval("while(1) {}; 1") };
    ok $exception, 'dies';

    is $exception, '[JavaScript Exception] null at eval:0:?', 'exception';
    is $exception->is_time_limit, 1, 'exception->is_time_limit';
};






done_testing;
