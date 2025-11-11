#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib './lib';
use open ':std' => 'utf8';
use Test::More;
use JSON;

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
}

# Testing enumerations, especially enumerations of non-references.

my $male = JSON::Schema::Validate->new({
    type => 'object',
    properties =>
    {
        chromosomes =>
        {
            enum => [
                [qw( X Y )],
                [qw( Y X )],
            ],
        }
    },
});

my $female = JSON::Schema::Validate->new({
    type => 'object',
    properties =>
    {
        chromosomes =>
        {
            enum => [
                [qw( X X )],
            ],
        }
    },
});

ok(
	!$male->validate({ name => "Kate", chromosomes => [qw( X X )] }),
	"it's short for Bob",
);

ok(
	$female->validate({ name => "Kate", chromosomes => [qw( X X )] }),
);

ok(
	$male->validate({ name => "Dave", chromosomes => [qw( X Y )] }),
);

ok(
	$male->validate({ name => "Arnie", chromosomes => [qw( Y X )] }),
);

ok(
	!$male->validate({ name => "Eddie", chromosomes => [qw( X Y Y )] }),
);

ok(
	!$male->validate({ name => "Steve", chromosomes => 'XY' }),
);

done_testing;

__END__

