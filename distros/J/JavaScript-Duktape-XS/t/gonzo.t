use strict;
use warnings;

use POSIX qw< dup dup2 >;
use Devel::Peek;
use Data::Dumper;
use Test::More;
use JavaScript::Duktape::XS;

sub test_set_get {
    my $duk = JavaScript::Duktape::XS->new();
    ok($duk, "created JavaScript::Duktape::XS object");

    my $obj = {}; bless $obj, "Gonzo";
    my %values = (
        'undef'  => undef,
        '0_int' => 0,
        '1' => 1,
        '0_double' => 0.0,
        '1/10' => 0.1,
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
        $duk->set($name, $expected);
        my $got = $duk->get($name);
        is_deeply($got, $expected, "set and get for [$case]")
            or printf STDERR ("%s", Dumper({got => $got, expected => $expected}));
    }
}

sub test_eval {
    my $duk = JavaScript::Duktape::XS->new();
    ok($duk, "created JavaScript::Duktape::XS object");

    my $callback = sub {
        printf("HOI [%s]\n", join(",", map +(defined $_ ? $_ : "UNDEF"), @_));
        return scalar @_;
    };
    $duk->set('gonzo' => $callback);
    my @commands = (
        [ "'gonzo'" => 'gonzo' ],
        [ "3+4*5"   => 23 ],
        [ "true"    => 1 ],
        [ "null"    => undef ],
        [ "print('Hello world from Javascript!');" => undef, 'Hello world from Javascript!' ],
        [ "print(2+3*4)" => undef, '14' ],
        [ 'gonzo()' => 0, 'HOI []' ],
        [ 'gonzo(1)' => 1, 'HOI [1]' ],
        [ 'gonzo("a", "b")' => 2, 'HOI [a,b]' ],
        [ 'gonzo("a", 1, null, "b")' => 4, 'HOI [a,1,UNDEF,b]' ],
    );

    foreach my $cmd (@commands) {
        my ($js, $expected_return, $expected_output) = @$cmd;
        $expected_output //= '';
        my $output = '';

        # Move STDOUT to store results in $output
        my $real_stdout;
        open $real_stdout, ">&STDOUT" || warn "Can't preserve STDOUT\n$!\n";
        close STDOUT;
        open STDOUT, '>', \$output or die "Can't open STDOUT: $!";
        select STDOUT; $| = 1;

        my $got = $duk->eval($js);

        # Now recover original STDOUT
        close STDOUT;
        open STDOUT, ">&", $real_stdout;
        select STDOUT; $| = 1;

        chomp($output);
        is($output, $expected_output, "eval output [$js]");
        is_deeply($got, $expected_return, "eval return [$js]");
    }
}

sub test_roundtrip {
    my $duk = JavaScript::Duktape::XS->new();
    ok($duk, "created JavaScript::Duktape::XS object");

    my $test_name;
    my $expected_args;
    my $callback = sub {
        is_deeply(\@_, $expected_args, "expected args $test_name")
            or printf STDERR Dumper({ got => \@_, expected => $expected_args });
        return $expected_args;
    };
    $duk->set('perl_test' => $callback);
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

        $duk->set($name, $args);
        my $got_set = $duk->get($name);
        is_deeply($got_set, $args, "set / get works for $name");

        my $js_name = "js_$name";
        $test_name = $name;
        $expected_args = $args;
        my $got_eval = $duk->eval("$js_name = perl_test.apply(this, $name)");
        is_deeply($got_eval, $args, "calling perl_test() works for $name");

        my $got_get = $duk->get($js_name);
        is_deeply($got_get, $args, "return value from perl_test() works for $name");
    }
}

sub main {
    test_set_get();
    test_eval();
    test_roundtrip();
    done_testing;
    return 0;
}

exit main();
