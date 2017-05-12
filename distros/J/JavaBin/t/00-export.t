use strict;
use warnings;

use Test::More;

{ package JavaBin::Both;    use JavaBin qw/from_javabin to_javabin/ }
{ package JavaBin::Default; use JavaBin }
{ package JavaBin::Empty;   use JavaBin () }
{ package JavaBin::Foo;     use JavaBin 'foo' }
{ package JavaBin::From;    use JavaBin 'from_javabin' }
{ package JavaBin::To;      use JavaBin 'to_javabin' }

my %test = (
    both    => [qw/from_javabin to_javabin/],
    default => [qw/from_javabin to_javabin/],
    empty   => [],
    foo     => ['foo'],
    from    => ['from_javabin'],
    to      => ['to_javabin'],
);

no strict 'refs';

is_deeply [ sort keys %{"JavaBin::\u${_}::"} ], [ 'BEGIN', @{ $test{$_} } ], $_
    for sort keys %test;

done_testing;
