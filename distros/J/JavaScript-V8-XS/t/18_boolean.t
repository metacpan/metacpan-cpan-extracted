use strict;
use warnings;

use Data::Dumper;
use Time::HiRes;
use Test::More;

my $CLASS = 'JavaScript::V8::XS';

sub test_boolean {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my $name = 'foo';
    my $js_code = "$name = { name: 'gonzo', male: true, plant: false }";
    $vm->eval($js_code);
    my $data = $vm->get($name);
    # print Dumper($data);
    isa_ok($data->{male}, "JSON::PP::Boolean");
    is(!!$data->{male}, !!1, "male is true");
    isa_ok($data->{plant}, "JSON::PP::Boolean");
    is(!!$data->{plant}, !!0, "plant is false");
}

sub main {
    use_ok($CLASS);

    test_boolean();
    done_testing;
    return 0;
}

exit main();
