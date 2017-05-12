#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception::LessClever;
use Data::Dumper;
use Carp;

our $CLASS;
our $RCLASS;
BEGIN {
    $CLASS = 'Devel::Declare::Parser';
    $RCLASS = 'Devel::Declare::Parser::Emulate';
    use_ok( $CLASS );
    use_ok( $RCLASS );
}

my $one = $RCLASS->new( 'test', 'test', 10 );
$one->line( qq/my \$xxx = test apple boy => "aaaaa" 'bbbb', (a => "b") ['a', 'b'] . \$xxx \%hash \@array \*glob Abc::DEF::HIJ { ... }/ );
$one->process;

is_deeply(
    $one->parts,
    [
        [ 'apple', undef ],
        [ 'boy', undef ],
        '=>',
        [ 'aaaaa', '"' ],
        [ 'bbbb', "'"  ],
        ',',
        [ 'a => "b"', '(' ],
        [ "'a', 'b'", '[' ],
        '.',
        '$xxx',
        '%hash',
        '@array',
        '*glob',
        [ 'Abc::DEF::HIJ', undef ],
    ],
    "Parsed properly"
);

like(
    $one->line(),
    qr/my \$xxx = test\s*\('apple', 'boy', =>, "aaaaa", 'bbbb', ,, \(a => "b"\), \['a', 'b'\], ., \$xxx, \%hash, \@array, \*glob, 'Abc::DEF::HIJ', sub \{ BEGIN \{ .*\->_edit_block_end\('.*'\) \};  \.\.\. \} \);/,
    "Got new line"
);

$one = $RCLASS->new( 'test', 'test', 0 );
$one->line( qq/test apple boy;/ );
$one->process;
is_deeply(
    $one->parts,
    [
        [ 'apple', undef ],
        [ 'boy', undef ],
    ],
    "Parts"
);
like(
    $one->line,
    qr/^test\s*\('apple', 'boy'\);/,
    "Non-codeblock"
);

$one = $RCLASS->new( 'test', 'test', 0 );
$one->line( <<EOT );
test
    apple
        =>
            (
    blah => 'blah',
    uhg => sub {
        aaa(
            'aaa'
        );
    },
);
EOT
$one->process;
is( $one->line, <<EOT, "umodified arrow ( form" );
test
    apple
        =>
            (
    blah => 'blah',
    uhg => sub {
        aaa(
            'aaa'
        );
    },
);
EOT


done_testing;

1;
