use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;
use Test::More;
use Encode;
use utf8;

my $js  = JavaScript::Duktape->new();
my $duk = $js->duk;

my $count = 0;

my $evalstr = <<'//JSEND';
    function test (s){
        is(s, "abc αβγ ß");
        is(s.toUpperCase().length, 10);
    }

    function uc(s) { return s.toUpperCase(); }
    toPerl( uc("abc αβγ ß") ) // ascii: abc,  greek:alpha beta gamma, german:sharp-s
//JSEND

$js->set(
    is => sub {
        is( shift, shift );
    }
);

$js->set(
    toPerl => sub {
        my $string = shift;
        is length $string, 10;

        use bytes;
        is length $string, 13;
        no bytes;

        is $string, uc("abc αβγ ß");
    }
);

$js->eval($evalstr);

my $jsTest = $js->get('test');
$jsTest->("abc αβγ ß");

done_testing(5);
