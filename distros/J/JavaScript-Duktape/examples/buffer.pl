use lib './lib';
use strict;
use warnings;
use Data::Dumper;

use JavaScript::Duktape;

my $js = JavaScript::Duktape->new;

my $buffer = $js->get_object( q{
    Buffer.prototype.get = function(n){
        return this[n] || '';
    };

    Buffer.prototype.set = function set(n, v){
        this[n] = v;
    };

    // will be implemented in perl
    // var buf = new Buffer(7);
    // buf.fill(97);
    // print(buf.toString());
    // var n = buf.slice(0, 2).fill('b');
    // print(buf.toString());

    Buffer;
});

my $buf = $buffer->new(7);

$buf->fill(97);
print $buf->byteLength, "\n"; #7
print $buf->toString('utf8'), "\n"; #aaaaaaa;

my $n = $buf->slice(0, 2)->fill('b');

print $n->byteLength, "\n"; #2
print $n->toString('utf8'), "\n"; #bb

print $n->get(1), "\n"; #98;
print $buf->get(6), "\n"; #97;
