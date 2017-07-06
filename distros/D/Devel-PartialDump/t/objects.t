use strict;
use warnings;

use Test::More 0.96;

package My::Object::Hash;
{
    use overload '""' => \&stringify;

    sub new {
        my $class = shift;
        bless { value => $_[0] }, $class;
    }
    sub stringify { $_[0]->{value} }
}

package My::Object::Array;
{
    use overload '""' => \&stringify;

    sub new {
        my $class = shift;
        bless [$_[0]], $class;
    }
    sub stringify { $_[0]->[0] }
}

package My::Object::Scalar;
{
    use overload '""' => \&stringify;

    sub new {
        my $class = shift;
        my $arg = shift;
        bless \$arg, $class;
    }
    sub stringify { ${$_[0]} }
}

package main;

use ok 'Devel::PartialDump';

my $hash   = My::Object::Hash->new('foo');
my $array  = My::Object::Array->new('foo');
my $scalar = My::Object::Scalar->new('foo');

subtest 'dump' => sub {
    my $d = Devel::PartialDump->new( objects => 1, stringify => 0 );

    is( $d->dump($hash), 'My::Object::Hash={ value: "foo" }' );
    is( $d->dump($array), 'My::Object::Array=[ "foo" ]' );
    is( $d->dump($scalar), 'My::Object::Scalar=\"foo"' );
};

subtest 'string value' => sub {
    my $d = Devel::PartialDump->new( objects => 0, stringify => 0 );

    like( $d->dump($hash), qr/^My::Object::Hash=HASH\(0x[0-9A-Fa-f]+\)$/ );
    like( $d->dump($array), qr/^My::Object::Array=ARRAY\(0x[0-9A-Fa-f]+\)$/ );
    like( $d->dump($scalar), qr/^My::Object::Scalar=SCALAR\(0x[0-9A-Fa-f]+\)$/ );
};

subtest 'string overload' => sub {
    my $d = Devel::PartialDump->new( objects => 0, stringify => 1 );

    is( $d->dump($hash), 'foo' );
    is( $d->dump($array), 'foo' );
    is( $d->dump($scalar), 'foo' );
};

done_testing;
