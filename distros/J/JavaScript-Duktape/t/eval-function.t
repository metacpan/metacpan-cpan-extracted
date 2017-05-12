use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;
use Test::More;

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

$duk->push_function(sub {
    fail("failed from javascript land");
}, 1);

$duk->put_global_string("perlfail");

$duk->push_function(sub {
    ok(1, "success from javascript land");
}, 1);

$duk->put_global_string("perlok");

$duk->push_string("Hi");
sub safe_fn {
    eval {
        print "called\n";
        eval { die; };
        $duk->push_string("bye");
        die;
        $duk->require_int(99);
        print "called\n";
    };
    if ($@){
        ok(1, $@);
        $duk->push_string("Error String");
        #this should throw bye string
        $duk->throw();
    }
    fail("should never get here");
}

$duk->push_function(\&safe_fn, 10);
$duk->put_global_string("perlFn");
$duk->peval_string(qq~
    try {
        perlFn();
        perlfail();
    } catch (e){
        perlok();
        throw(e);
    }
    perlfail();
    9;
~);

my $top = $duk->get_top();
is($top, 2);
my $string = $duk->get_string(-1);
is($string, "Error String", $string);

done_testing(4);
