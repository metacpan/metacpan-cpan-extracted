use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Output qw/ stdout_like /;

my $CLASS = 'JavaScript::Duktape::XS';

sub test_set_get_and_exists {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my $obj = {}; bless $obj, "Gonzo";
    my %values = (
        'undef'  => undef,
        '0_int' => 0,
        '1' => 1,
        '0_double' => 0.0,
        'one_half' => 0.5,
        'empty'  => '',
        'string'  => 'gonzo',
        'aref_empty' => [],
        'aref_ints' => [5, 6, 7],
        'aref_mixed' => [1, 0, 'gonzo'],
        'href_empty' => {},
        'href_simple' => { 'one' => 1, 'two' => 2 },
        'gonzo' => sub { print("HOI\n"); },
        'object' => $obj,

        'foo' => "2+3*4",
        'aref' => [2,3,4],
        'aref_aref' => [2, [3,4], 5 ],
        'href' => { foo => 1 },
        'href_aref' => { foo => [1,2,[3,4,5]] },
        'aref_href' => [2, { foo => 1 } ],
        'aref_large' => [2, 4, [ 1, 3], [ [5, 7], 9 ] ],
        'href_large' => { 'one' => [ 1, 2, { foo => 'bar'} ], 'two' => { baz => [3, 2]} },
    );
    foreach my $case (sort keys %values) {
        my $name = "name_$case";
        my $expected = $values{$case};
        ok(!$vm->exists($name), "does not exist yet for [$case]");
        $vm->set($name, $expected);
        my $got = $vm->get($name);
        ok($vm->exists($name), "exists for [$case]");
        is_deeply($got, $expected, "set and get for [$case]")
            or printf STDERR ("%s", Dumper({got => $got, expected => $expected}));
    }
    my %globals = map +( $_ => 1 ), @{ $vm->global_objects() };
    foreach my $case (sort keys %values) {
        my $name = "name_$case";
        ok(exists $globals{$name}, "global '$name' exists");
    }
}

sub test_eval {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my $callback = sub {
        printf("HOI [%s]\n", join(",", map +(defined $_ ? $_ : "UNDEF"), @_));
        return scalar @_;
    };
    my @commands = (
        [ "'gonzo'" => 'gonzo' ],
        [ "3+4*5"   => 23 ],
        [ "null"    => undef ],
        [ 'new ArrayBuffer()' => q<> ],
        [ 'new ArrayBuffer(3)' => qq<\0\0\0> ],
        [ 'new Uint8Array([0x21, 0x31])' => qq<\x21\x31> ],
        [ "print('Hello world from Javascript!');" => undef, 'Hello world from Javascript!' ],
        [ "print(2+3*4)" => undef, '14' ],
        [ q<print('this is a string', {this: 'object'})> => undef, q<this is a string [object Object]> ],
        [ q<print('this is a string', JSON.stringify({this: 'object'}))> => undef, q<this is a string {"this":"object"}> ],
        [ 'gonzo()' => 0, 'HOI []' ],
        [ 'gonzo(1)' => 1, 'HOI [1]' ],
        [ 'gonzo("a", "b")' => 2, 'HOI [a,b]' ],
        [ 'gonzo("a", 1, null, "b")' => 4, 'HOI [a,1,UNDEF,b]' ],
    );

    foreach my $cmd (@commands) {
        $vm->reset();
        $vm->set('gonzo' => $callback);
        my ($js, $expected_return, $expected_output) = @$cmd;
        $expected_output //= '';
        $expected_output = quotemeta($expected_output);

        my $output = '';
        my $got;
        stdout_like sub { $got = $vm->eval($js); },
                    qr/$expected_output/,
                    "got correct stdout from [$js]";
        is_deeply($got, $expected_return, "eval return [$js]") or diag explain $got;
    }
}

sub test_roundtrip {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my $test_name;
    my $expected_args;
    my $callback = sub {
        is_deeply(\@_, $expected_args, "expected args $test_name")
            or printf STDERR Dumper({ got => \@_, expected => $expected_args });
        return $expected_args;
    };
    $vm->set('perl_test' => $callback);
    my %args = (
        'empty' => [],
        'undef' => [undef],
        'one_number' => [1],
        'two_strings' => ['a','b'],
        'nested_aref' => [ [ 1, 2, [ 3, [], { foo => [5, 6] } ], [8] ] ],
        'nested_href' => [ { foo => 1, bar => [4,[],5,{},{baz=>3}] } ],
    );
    foreach my $name (sort keys %args) {
        my $args = $args{$name};

        $vm->set($name, $args);
        my $got_set = $vm->get($name);
        is_deeply($got_set, $args, "set / get works for $name");

        my $js_name = "js_$name";
        $test_name = $name;
        $expected_args = $args;
        my $got_eval = $vm->eval("$js_name = perl_test.apply(null, $name)");
        is_deeply($got_eval, $args, "calling perl_test() works for $name");

        my $got_get = $vm->get($js_name);
        is_deeply($got_get, $args, "return value from perl_test() works for $name");
    }
    my %globals = map +( $_ => 1 ), @{ $vm->global_objects() };
    foreach my $name (sort keys %args) {
        ok(exists $globals{$name}, "global '$name' exists");
    }
}

sub main {
    use_ok($CLASS);

    test_set_get_and_exists();
    test_eval();
    test_roundtrip();
    done_testing;
    return 0;
}

exit main();
