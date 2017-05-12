use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;
use Test::More;

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

$duk->push_function(sub {
    ok(1, "success from javascript land");
}, 1);

$duk->put_global_string("perlok");

my $data = {
    num => 9,
    func => sub {
        is(1, $_[0]);
        is("Hi", $_[1]);
        is($_[2], true); #true
        ok($_[2]); #true

        is($_[3], false); #false
        ok(!$_[3]); #false

        #XXX : test null $_[4]
        ok(!$_[4]);
        is($_[4], null);

        ##fifth argument passed as javascript function
        $_[5]->(sub {
            my $d = shift;
            is($d, "Hi again");
            return [1, 2, 3];
        });

        return { h => 9999 };
    },
    str => 'Hello',
    un => undef,
    n => null,
    t => true,
    f => false
};

$js->set('perl', $data);

$duk->peval_string(qq~
    //print(JSON.stringify(perl));
    if (perl.str === 'Hello') perlok();
    if (typeof perl.un === 'undefined') perlok();
    if (perl.n === null) perlok();
    if (perl.t === true) perlok();
    if (perl.f === false) perlok();
    if (typeof perl.func === 'function') perlok();

    var obj = perl.func(1, "Hi", true, false, null, function(d){
        var ret = d('Hi again');
        if (typeof ret === 'object') perlok();
        if (ret.length === 3){
            perlok();
        }
    });
    if(obj.h === 9999) perlok();
~);
$duk->dump();


if (false){
    print "OK\n";
}

done_testing(18);
