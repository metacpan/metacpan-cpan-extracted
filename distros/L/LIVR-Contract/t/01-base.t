#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::More;

use LIVRContractSimpleClassExample;

my @negative_cases = (
    {
        package => 'LIVRContractSimpleClassExample',
        subname => 'create_object_named_input',
        args    => [id => '0'],
        type    => 'input',
        errors  => { name => 'REQUIRED', id => 'NOT_POSITIVE_INTEGER' },
    },
    {
        package => 'LIVRContractSimpleClassExample',
        subname => 'create_object_named_input',
        args    => [name => 'Viktor', id => 100],
        type    => 'output',
        errors  =>  { 0 => 'NOT_POSITIVE_INTEGER' },
    },
    {
        package => 'LIVRContractSimpleClassExample',
        subname => 'create_object_positional_input',
        args    => ['0'],
        type    => 'input',
        errors  => { 1 => 'NOT_POSITIVE_INTEGER', 2 => 'REQUIRED' },
    },
);


my @positive_cases = (
    {
        package => 'LIVRContractSimpleClassExample',
        subname => 'create_object_named_input',
        args    => [name => 'Viktor', id => 100],
    }
);


foreach my $case (@negative_cases) {
    my $package = $case->{package};
    my $subname = $case->{subname};
    my $args    = $case->{args};

    subtest "Test $package->$subname(${ \join(', ', @$args) }); should throw $case->{type} error" => sub {
        eval {
            $package->$subname(@$args);
        };

        ok($@, 'Should throw exception');
        isa_ok($@, 'LIVR::Contract::Exception');

        is($@->type, $case->{type}, "Shoul contain error type");
        is($@->subname, $subname, 'Should contain name of failed method');
        is($@->package, $package, 'Should contain name of failed package');

        is_deeply($@->errors, $case->{errors}, 'Should contain errors in Validator::LIVR format');
    };
}

done_testing();

1;
