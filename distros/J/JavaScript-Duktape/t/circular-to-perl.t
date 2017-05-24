use strict;
use warnings;
use Data::Dumper;
use lib './lib';
use JavaScript::Duktape;
use Test::More;
use Data::Dumper;

my $js  = JavaScript::Duktape->new();
my $duk = $js->duk;

$duk->eval_string(q{
    var ob = { a : {} };
    var a = { kk : {  nn : { hello : 'there' } }, mmm: undefined, xxx: null, x: null, f: {}, hi : function(){} };
    a.a = a;
    a.b = { c : ob }
    a.d = { arr : [a,ob,3] };
    a;
});

my $obj = $duk->to_perl(-1);

is $obj->{a}, $obj;
is $obj->{d}->{arr}->[0], $obj;
is $obj->{a}->{b}->{c}, $obj->{d}->{arr}->[1];

done_testing(3);
