#!perl -w
use strict;
use Test::More tests => 11;

use Devel::LexAlias qw(lexalias);

# testing for predictive destruction.  especially around ithreads
my $expect;
sub Foo::DESTROY {
    my ($destroyed) = @{ shift() };
    is( $destroyed, $expect, "expected destruction of $expect" );
}

sub inner {
    my $inner = bless ['$inner'], 'Foo';
    $expect = '$outer';
    lexalias(1, '$outer', \$inner);
    $expect = '';
}

sub outer {
    my $outer = bless [ '$outer' ], 'Foo';
    inner;
    is ( $outer->[0], '$inner', "alias worked" );
    $expect = '$inner';
}
outer;

sub steal_foo {
    my $foo = 1;
    lexalias(\&foo, '$x', \$foo);
    lexalias(\&foo, '@y', [qw( foo bar baz )]);

    eval { lexalias(\&foo, '$x', $foo) };
    ok( $@, "blew an error" );
    like( $@, qr/^ref is not a reference/, "useful error" );
}

sub bar {
    my $foo = 2;
    lexalias(2, '$x', \$foo);
}

sub steal_above {
    bar();
    lexalias(1, '@y', [qw( foo bar bray )]);
}


sub foo {
    my $x = 22;
    my @y = qw( a b c );

    is( $x, 22, "x before" );
    is_deeply( \@y, [qw( a b c )], "y before" );

    steal_foo;

    is( $x, 1, "x after" );
    is_deeply( \@y, [qw( foo bar baz )], "y after" );

    steal_above;

    is( $x, 2, "x above after" );
    is_deeply( \@y, [qw( foo bar bray )], "y after" );

}

foo;
print "# out of foo\n";

exit 0;
