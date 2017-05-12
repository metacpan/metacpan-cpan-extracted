use strict;
use warnings;
use Test::More tests => 3;

{
    package ProtoMRO;

    use mro;
    use MRO::Define;
    use Variable::Magic qw/wizard cast/;

    { package Dummy }

    BEGIN {
        MRO::Define::register_mro(q/proto/, sub {
            return [qw/Dummy ProtoMRO/];
        });
    }

    my $method_name;

    sub invoke_method {
        my ($caller, @args) = @_;
        return qq{invoking ${method_name} on $caller with @args};
    }

    my $wiz = wizard
        data  => sub { \$method_name },
        fetch => sub {
            ${ $_[1] } = $_[2];
            $_[2] = 'invoke_method';
            ();
        };

    cast %::ProtoMRO::, $wiz;
}

{
    package Bar;
    use mro 'proto';
}

can_ok('Bar', 'moo');
is(Bar->moo(1, 2, 3), 'invoking moo on Bar with 1 2 3');
my $moo = 'moo';
is(Bar->$moo(1, 2, 3), 'invoking moo on Bar with 1 2 3');
