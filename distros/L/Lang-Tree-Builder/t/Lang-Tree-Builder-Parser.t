# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tree-Builder.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
BEGIN { use_ok('Lang::Tree::Builder::Parser') };

#########################

my $parser = new Lang::Tree::Builder::Parser();
ok($parser);

my $data = $parser->parseFile('./t/data');
ok($data);
foreach my $class ($data->classes) {
    ok($class);
    ok ($class->name eq 'ClassA');
    my @args = $class->args;
    ok ($args[0]->name eq 'ArgA');
    ok ($args[0]->argname eq 'ArgA1');
    ok ($args[1]->name eq 'ArgA');
    ok ($args[1]->argname eq 'ArgA2');
    ok ($args[2]->name eq 'scalar');
    ok ($args[2]->argname eq 'foo_bar');
    ok $class->parent->name eq 'Parent::ClassA';
}
