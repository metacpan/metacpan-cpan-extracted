use strict;
use warnings;

use Data::Dumper;
use Time::HiRes;
use Test::More;

my $CLASS = 'JavaScript::Duktape::XS';

sub test_remove_global {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my @names = qw/ bilbo frodo gandalf gonzo /;
    for my $name (@names) {
        my $value = "value for $name";

        my @globals_before = sort $vm->global_objects();

        $vm->set($name, $value);
        ok($vm->exists($name), "variable $name exists after set");

        my $got = $vm->get($name);
        is($got, $value, "got correct value for $name with get");

        $vm->remove($name);
        ok(!$vm->exists($name), "variable $name does not exist after remove");

        my @globals_after = sort $vm->global_objects();
        is_deeply(\@globals_before, \@globals_after, "globals fine after $name");
    }
}

sub test_remove_slot {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my $object = 'Sauron';
    $vm->set($object, {});
    my @slots = qw/ bilbo frodo gandalf gonzo /;
    for my $slot (@slots) {
        my $name = "$object.$slot";
        my $value = "value for $slot";

        my @globals_before = sort $vm->global_objects();

        $vm->set($name, $value);
        ok($vm->exists($name), "variable $name exists after set");

        my $got = $vm->get($name);
        is($got, $value, "got correct value for $name with get");

        $vm->remove($name);
        ok(!$vm->exists($name), "variable $name does not exist after remove");

        my @globals_after = sort $vm->global_objects();
        is_deeply(\@globals_before, \@globals_after, "globals fine after $name");
    }
}

sub main {
    use_ok($CLASS);

    test_remove_global();
    test_remove_slot();
    done_testing;
    return 0;
}

exit main();
