#!perl

use Test::More tests => 24;

use strict;
use warnings;

use JavaScript;

my $rt = JavaScript::Runtime->new();
my $cx = $rt->create_context();
$cx->bind_function(ok => \&ok);

{
    my $arr = JavaScript::PerlArray->new();
    ok(defined $arr);
    isa_ok($arr, "JavaScript::PerlArray");
    ok($arr->get_ref);
    my $av = $arr->get_ref;
    is(ref $av, "ARRAY");
    is_deeply($arr->get_ref, []);
}

{
    my $arr = $cx->eval(q/
        var array = new PerlArray();
        ok(array instanceof PerlArray);
        array;
/);

    isa_ok($arr, "JavaScript::PerlArray");
    is_deeply($arr->get_ref, []);
}

{
    my $arr = JavaScript::PerlArray->new();

    push @{$arr->get_ref}, 10, 20, 30;

    $cx->eval(q/
        function check_perlarray(arr) {
            ok(arr instanceof PerlArray);
            ok(arr.length == 3);
            ok(arr[0] == 10);
            ok(arr[1] == 20);
            ok(arr[2] == 30);
            ok(arr[-1] == 30);
        }
/);

    $cx->call(check_perlarray => $arr);
}

{
    $cx->eval(q/
        var array = new PerlArray();
        
        array.push(10);
        ok(array.length == 1);
        ok(array[0] == 10);
        
        array.unshift(20, 30);
        ok(array.length == 3);
        ok(array[0] == 20 && array[1] == 30 && array[2] == 10);
        
        ok(array.shift() == 20);
        ok(array.length == 2);
        
        ok(array.pop() == 10);
        ok(array.length == 1);
    /)
}

{
    my $arr = JavaScript::PerlArray->new();
    $cx->eval(q/
        function populate_perlarray_via_index(array) {
            array[2] = 20;
        }
    /);
    is_deeply($arr->get_ref, []);
    $cx->call(populate_perlarray_via_index => $arr);
    is_deeply($arr->get_ref, [undef, undef, 20]);
}