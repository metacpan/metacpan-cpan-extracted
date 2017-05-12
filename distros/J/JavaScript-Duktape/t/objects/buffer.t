use lib './lib';
use strict;
use warnings;
use utf8;
use Encode;
use Data::Dumper;
use Test::More;
use JavaScript::Duktape;

my $js = JavaScript::Duktape->new;
my $duk = $js->duk;
my $ret = $duk->eval_string( q{
    Buffer.prototype.get = function(n){
        return this[n];
    };
    Buffer.prototype.set = function set(n, v){
        this[n] = v;
    };
    Buffer;
});

my $buffer = $duk->to_perl_object(-1);
$duk->pop();

for (0 .. 10){
    is $duk->get_top(), 0;
    my $gg = $buffer->new(7);

    $gg->fill('V');
    $gg->fill('V');
    my $t = $buffer->new(17);
    $t->fill(3);

    is $t->toString('utf8'), Encode::encode('UTF-8', ("\3" x 17) );
    is $t->byteLength, 17;

    is $t->get(0), 3;
    $t->set(1, 97);
    is $t->get(1), 97;

    my $n = $t->slice(0, 2)->fill('b');
    $n->fill('a');

    is $n->byteLength, 2;
    is $n->toString('utf8'), 'aa';

    is $gg->toString('utf8'), "V" x 7;
    is $gg->byteLength, 7;
}

is $duk->get_top(), 0;
done_testing(100);
