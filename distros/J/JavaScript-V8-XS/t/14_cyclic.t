use strict;
use warnings;

use Data::Dumper;
use JSON::PP;
use Test::More;
use Test::Output qw/ stdout_from /;

my $CLASS = 'JavaScript::V8::XS';

sub test_cyclic_roundtrip {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my @array = qw/ 1 2 3 /;
    my %hash = ( "number" => 11, "string" => 'gonzo' );
    $hash{'array'} = \@array;
    $hash{'hash'} = \%hash;
    push @array, \%hash;
    push @array, \@array;

    $vm->set('perl_array', \@array);
    $vm->set('perl_hash', \%hash);

    my $got_array = $vm->get('perl_array');
    my $got_hash = $vm->get('perl_hash');

    is_deeply($got_array, \@array, "cyclic array roundtrip");
    is_deeply($got_hash, \%hash, "cyclic hash roundtrip");
}

sub test_cyclic_console {
    my %base = (
        array => [qw/ 1 2 3 /],
        hash  => { bilbo => 1, frodo => 2, sam => 3 },
    );
    my @array = @{ $base{array} };
    push @array, \@array;
    push @{ $base{array} }, '<cycle0>';

    my %hash = %{ $base{hash} };
    $hash{others} = \%hash;
    $base{hash}{others} = '<cycle0>';

    my %data = (
        array => \@array,
        hash  => \%hash,
    );

    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    foreach my $name (sort keys %data) {
        my $value = $data{$name};
        $vm->set($name, $value);

        my $out = stdout_from(sub { $vm->eval("console.log($name)") });
        my $got;
        eval {
            $got = JSON::PP::decode_json($out);
            1;
        } or do {
            my $error = $@ // 'WTF';
            ok(0, "could not decode output: $error");
        };

        my $expected = $base{$name};
        is_deeply($got, $expected, "$name: got correct output when logging a cyclic object")
            or diag explain({ got => $got, expected => $expected });
    }
}

sub main {
    use_ok($CLASS);

    test_cyclic_roundtrip();
    test_cyclic_console();
    done_testing;
    return 0;
}

exit main();
