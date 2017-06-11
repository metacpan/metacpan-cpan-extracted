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
        while(1){
            str += 'XXXXXXXXXXXXXXXXXXXXXXXXXXX';
        }
    });
};

ok $@ =~ /memory/;

done_testing();
