use strict;
use warnings;

use Data::Dumper;
use Time::HiRes;
use Test::More;

my $CLASS = 'JavaScript::Duktape::XS';

sub test_declarations {
    my %types = (
        const => 1,
        let   => 0,
        var   => 1,
    );
    for my $type (sort keys %types) {
        next unless $types{$type};

        my $vm = $CLASS->new();
        ok($vm, "created $CLASS object");

        my $name = "my_$type";
        my $num = 42;
        my $got;

        $got = $vm->eval("$type $name = $num; $name;");
        is($got, $num, "compiled $type");
        $got = $vm->get($name);
        is($got, $num, "and $type has correct value");

        # $got = $vm->eval('$type webpack = (options, callback) => { $type gonzo = 11; };');
        $got = $vm->eval("$type webpack = function(options, callback) { $type gonzo = 11; }; $name");
        is($got, $num, "compiled funny");
    }
}

sub main {
    use_ok($CLASS);

    test_declarations();
    done_testing;
    return 0;
}

exit main();
