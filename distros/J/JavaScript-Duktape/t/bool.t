use lib './lib';
use strict;
use warnings;
use Data::Dumper;
use JavaScript::Duktape;
use Test::More;

my $js  = JavaScript::Duktape->new();
my $duk = $js->duk;

$js->set( ok => \&Test::More::ok );

$js->set( 'obj' => {
    test_true => true,
    test_false => false,
    test_true_ref => \1,
    test_false_ref => \0
});

my $obj = $js->eval(q{
    ok( obj.test_true === true )
    ok( obj.test_false === false )
    ok( obj.test_true_ref === true )
    ok( obj.test_false_ref === false )
    obj;
});

is $obj->{test_true}, true;
is $obj->{test_false}, false;
is $obj->{test_true_ref}, true;
is $obj->{test_false_ref}, false;

ok $obj->{test_true};
ok !$obj->{test_false};

done_testing(10);
