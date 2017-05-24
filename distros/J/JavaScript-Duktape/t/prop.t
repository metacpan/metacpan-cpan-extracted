use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;
use Test::More;

my $js  = JavaScript::Duktape->new();
my $duk = $js->duk;

$duk->push_c_function(
    sub {
        $duk->push_current_function();
        $duk->get_prop_string( -1, "prop_number" );
        $duk->dump();
        my $num = $duk->require_number(-1);
        is( $num, 9, "prop value" );
        return 1;
    },
    -1
);

$duk->push_int(9);
$duk->put_prop_string( -2, "prop_number" );

$duk->pcall(0);
my $num = $duk->require_number(-1);
is( $num, 9, "return value" );

done_testing(2);
