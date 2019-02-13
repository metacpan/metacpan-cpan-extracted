use strict;
use warnings;
use Test::More;
use Devel::Probe;
my $file = __FILE__;
my $expected = {
    $file => {
        29 => "foo",
        30 => { blorg => "bar"},
        31 => ["baz"],
    }
};

my $triggered;
Devel::Probe::trigger(sub {
    my ($file, $line, $args) = @_;
    $triggered->{$file}->{$line} = $args;
});

my $actions = [
    { action => "enable" },
    map {
        { action => "define", file => $file, lines => [$_], args => $expected->{$file}->{$_} }
    } sort keys %{ $expected->{$file} }
];

Devel::Probe::config({actions => $actions});

my $x = 1; # probe 1
my $y = 2; # probe 2
my $z = $y * 42; # probe 3

is_deeply(
    $triggered,
    $expected,
    "probes fired with correct arguments"
);

done_testing;
