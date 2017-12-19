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

$js->resize_memory( 256 * 1024 * 2 );

$duk->peval_string(q{
    var str = '';
    print(n);
    while(1){
        // n is the previous size but we resized memory
        var x = new Buffer(++n * 5);
        throw new Error('should fail here');
    }
});

ok $duk->safe_to_string(-1) =~ /should fail here/;

undef $@;
eval {
    $duk->eval_string(q{
        // and now should fail
        print( (++n * 5) * 3 )
        var x = new Buffer( (256 * 1024 * 2) + 50 );
    });
};

ok $@ =~ /alloc failed/;

done_testing();
