use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;
use Test::More;

my $js  = JavaScript::Duktape->new( max_memory => 256 * 1024 );
my $duk = $js->duk;

eval {
    $duk->eval_string(q{
        var str = '';
        var n = 1;
        while(1){
            var x = new Buffer(++n * 5);
        }
    });
};

ok $@ =~ /alloc failed/;

$duk->peval_string(q{
    var str = '';
    print(n);
    while(1){
        // n is the previous size so we should fail immediately
        var x = new Buffer(++n * 5);
        throw new Error('not reached');
    }
});

ok $duk->safe_to_string(-1) =~ /alloc failed/;

$duk->peval_string(q{
    var str = '';
    n = 1;
    while(1){
        // we reset n so buffer small and should not fail
        var x = new Buffer(++n * 100);
        throw new Error('should fail here');
    }
});

ok $duk->safe_to_string(-1) =~ /fail here/;

done_testing();
