#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('Method::Traits');
    # load from t/lib
    use_ok('Accessor::Trait::Provider');
}

=pod

This is an example of a simple provider
that will immediately build accessors
and overwrite the method.

=cut

BEGIN {
    package Person;

    use strict;
    use warnings;

    use MOP;
    use UNIVERSAL::Object;

    use Method::Traits qw[ Accessor::Trait::Provider ];

    our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
    our %HAS; BEGIN {
        %HAS = (
            fname => sub { "" },
            lname => sub { "" },
        )
    }

    sub first_name : Accessor(ro => 'fname');
    sub last_name  : Accessor(rw => 'lname');
}

my $p = Person->new( fname => 'Bob', lname => 'Smith' );
isa_ok($p, 'Person');

can_ok($p, 'first_name');
can_ok($p, 'last_name');

is($p->first_name, 'Bob', '... got the expected first_name');
is($p->last_name, 'Smith', '... got the expected last_name');

$p->last_name('Jones');

is($p->last_name, 'Jones', '... got the expected last_name');

done_testing;

