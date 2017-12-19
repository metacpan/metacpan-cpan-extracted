use lib './lib';
use strict;
use warnings;
use Data::Dumper;
use JavaScript::Duktape;
use Test::More;

my $js  = JavaScript::Duktape->new();
my $duk = $js->duk;

$js->set( ok => \&Test::More::ok );

if ( !eval{ require JSON::PP; 1 } ) {
    plan skip_all => 'JSON::PP missing';
}

my $json = JSON::PP->new->convert_blessed();

ok (ref true eq 'boolean' || ref true eq 'JavaScript::Duktape::Bool');

my $json_string  = $json->encode({
    test_true  => true,
    test_false => false,
});

my $obj = $js->eval(qq{
    var obj = JSON.parse('$json_string');
    ok( obj.test_true === true )
    ok( obj.test_false === false )
    obj;
});

is $obj->{test_true}, true;
is $obj->{test_false}, false;

ok $obj->{test_true};
ok !$obj->{test_false};

my $perl  = $json->decode($json_string);

$js->set( perl => $perl );

$js->eval(qq{
    ok( perl.test_true === true )
    ok( perl.test_false === false )
});

done_testing(9);
