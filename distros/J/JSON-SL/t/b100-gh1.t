#!/usr/bin/perl
use Test::More;
use JSON::SL;

my $input = "[ 5 ],  [ 6 ], { \"foo\" : \"bar\" }";
my $p = JSON::SL->new();
$p->set_jsonpointer(["/^"]);
$p->feed($input);
my @res = $p->fetch();

my $exp = [
    {
        'Value' => 5,
        'JSONPointer' => '/^',
        'Path' => '/0'
    },
    {
        'Value' => 6,
        'JSONPointer' => '/^',
        'Path' => '/0'
    },
    {
        'Value' => 'bar',
        'JSONPointer' => '/^',
        'Path' => '/foo'
    }
];

is_deeply(\@res, $exp);
done_testing();
