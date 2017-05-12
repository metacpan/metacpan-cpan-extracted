use strict;
use warnings;

use Test::More tests => 20;
BEGIN { use_ok('Ganglia::Gmetric::PP', ':all') };

# gmetric cmdline tool reference output
my %reference = (
    "int8" => [
        "\0\0\0\0\0\0\0\4int8\0\0\0\bint8test\0\0\0\00218\0\0\0\0\0\6things\0\0\0\0\0\3\0\0\0<\0\0\0\0",
        [ "int8", "int8test", 18 ]
    ],
    "int32" => [
        "\0\0\0\0\0\0\0\5int32\0\0\0\0\0\0\tint32test\0\0\0\0\0\0\0010\0\0\0\0\0\0\6things\0\0\0\0\0\3\0\0\0<\0\0\0\0",
        [ "int32", "int32test", 0 ]
    ],
    "string" => [
        "\0\0\0\0\0\0\0\6string\0\0\0\0\0\nstringtest\0\0\0\0\0\02036.1673468564735\0\0\0\6things\0\0\0\0\0\3\0\0\0<\0\0\0\0",
        [ "string", "stringtest", "36.1673468564735" ]
    ],
    "double" => [
        "\0\0\0\0\0\0\0\6double\0\0\0\0\0\ndoubletest\0\0\0\0\0\01728.799646370172\0\0\0\0\6things\0\0\0\0\0\3\0\0\0<\0\0\0\0",
        [ "double", "doubletest", "28.799646370172" ]
    ],
    "uint32" => [
        "\0\0\0\0\0\0\0\6uint32\0\0\0\0\0\nuint32test\0\0\0\0\0\00257\0\0\0\0\0\6things\0\0\0\0\0\3\0\0\0<\0\0\0\0",
        [ "uint32", "uint32test", 57 ]
    ],
    "float" => [
        "\0\0\0\0\0\0\0\5float\0\0\0\0\0\0\tfloattest\0\0\0\0\0\0\02098.1403087306795\0\0\0\6things\0\0\0\0\0\3\0\0\0<\0\0\0\0",
        [ "float", "floattest", "98.1403087306795" ]
    ],
    "int16" => [
        "\0\0\0\0\0\0\0\5int16\0\0\0\0\0\0\tint16test\0\0\0\0\0\0\00285\0\0\0\0\0\6things\0\0\0\0\0\3\0\0\0<\0\0\0\0",
        [ "int16", "int16test", 85 ]
    ],
    "uint16" => [
        "\0\0\0\0\0\0\0\6uint16\0\0\0\0\0\nuint16test\0\0\0\0\0\00213\0\0\0\0\0\6things\0\0\0\0\0\3\0\0\0<\0\0\0\0",
        [ "uint16", "uint16test", 13 ]
    ],
    "uint8" => [
        "\0\0\0\0\0\0\0\5uint8\0\0\0\0\0\0\tuint8test\0\0\0\0\0\0\0017\0\0\0\0\0\0\6things\0\0\0\0\0\3\0\0\0<\0\0\0\0",
        [ "uint8", "uint8test", 7 ]
    ],
);

# test against self
my $gmond = Ganglia::Gmetric::PP->new(listen_host => 'localhost', listen_port => 0);
my $test_port = $gmond->sockport;

my $gmetric = Ganglia::Gmetric::PP->new(host => 'localhost', port => $test_port);
ok($gmetric, 'new');

for my $type (sort keys %reference) {
    # compare reference values to deparsed gmetric output
    my @parsed = $gmetric->parse($reference{$type}[0]);
    my $cmp = $reference{$type}[1];
    is_deeply([@parsed[0..2]], $cmp, "$type: deparsed gmetric output");

    # compare self-serialized values to self-deserialized
    my $sent = $gmetric->send(@$cmp);

    my $found = wait_for_readable($gmond);
    die "can't read from self" unless $found;

    @parsed = $gmond->receive;
    is_deeply([@parsed[0..2]], $cmp, "$type: deparsed own output");
}

sub wait_for_readable {
    my $sock = shift;
    vec(my $rin = '', fileno($sock), 1) = 1;
    return select(my $rout = $rin, undef, undef, 1);
}
