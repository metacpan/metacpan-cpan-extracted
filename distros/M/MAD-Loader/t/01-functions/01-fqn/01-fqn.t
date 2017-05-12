#!perl

use utf8;
use Test::Most;
use MAD::Loader qw{ fqn };

my @tests;

## Without a prefix
@tests = (
    [ undef,           undef, '',              'Undefined module' ],
    [ '',              undef, '',              'Empty module' ],
    [ '123::Foo',      undef, '',              'Invalid module name' ],
    [ 'Foo::Bar::123', undef, 'Foo::Bar::123', 'Valid module name' ],
);

subtest 'No prefix' => \&tests;

## With a empty prefix
@tests = (
    [ undef,           '', '',              'Undefined module' ],
    [ '',              '', '',              'Empty module' ],
    [ '123::Foo',      '', '',              'Invalid module name' ],
    [ 'Foo::Bar::123', '', 'Foo::Bar::123', 'Valid module name' ],
);
subtest 'Empty prefix' => \&tests;

## With an invalid prefix
@tests = (
    [ undef,           '123', '', 'Undefined module' ],
    [ '',              '123', '', 'Empty module' ],
    [ '123::Foo',      '123', '', 'Invalid module name' ],
    [ 'Foo::Bar::123', '123', '', 'Valid module name' ],
);
subtest 'Invalid prefix' => \&tests;

## With a valid prefix
@tests = (
    [ undef,           'Test', '',                    'Undefined module' ],
    [ '',              'Test', '',                    'Empty module' ],
    [ '123::Foo',      'Test', 'Test::123::Foo',      'Invalid module name' ],
    [ 'Foo::Bar::123', 'Test', 'Test::Foo::Bar::123', 'Valid module name' ],
);
subtest 'Valid prefix' => \&tests;

## With UTF-8 and fail
@tests = (
    [ '☃',      undef, '', 'At the beginning' ],
    [ 'Foo::☃', undef, '', 'Inside' ]
);
subtest "UTF-8 that doesn't match foo [:upper:] or \\w" => \&tests;

## With UTF-8 and pass
@tests = (
    [ 'Ç',    undef, 'Ç',    'At the beginning' ],
    [ 'João', undef, 'João', 'Inside' ],
);
subtest "UTF-8 that matches foo [:upper:] or \\w" => \&tests;

done_testing;

sub tests {
    foreach my $test (@tests) {
        my ( $module, $prefix, $expected, $name ) = @{$test};
        is( fqn( $module, $prefix ), $expected, $name );
    }
}
