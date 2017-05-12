#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw( no_plan );

use_ok( 'MARC::Detrans::Rules' );
use_ok( 'MARC::Detrans::Rule' );

my $rules = MARC::Detrans::Rules->new();
isa_ok( $rules, 'MARC::Detrans::Rules' );

$rules->addRule(
    MARC::Detrans::Rule->new(
        from        => 'a',
        to          => 'b',
    )
);

$rules->addRule(
    MARC::Detrans::Rule->new(
        from        => 'a',
        to          => 'c',
        position    => 'initial'
    )
);

$rules->addRule(
    MARC::Detrans::Rule->new(
        from        => 'a',
        to          => 'd',
        position    => 'medial'
    )
);

$rules->addRule(
    MARC::Detrans::Rule->new(
        from        => 'a',
        to          => 'e',
        position    => 'final',
    )
);

$rules->addRule(
    MARC::Detrans::Rule->new(
        from        => ')',
        to          => ')'
    )
);

$rules->addRule(
    MARC::Detrans::Rule->new(
        from        => '(',
        to          => '('
    )
);

$rules->addRule(
    MARC::Detrans::Rule->new(
        from        => 'm',
        to          => 'n'
    )
);

is( $rules->convert( 'aaa' ), 'cde', 'initial, medial & final' );
is( $rules->convert( 'amama' ), 'cndne', 'non-position thrown in' );
is( $rules->convert( '(aaa' ), '(cde', 'leading punctuation' );
is( $rules->convert( 'aaa)' ), 'cde)', 'trailing punctuation' );

