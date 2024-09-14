use strict;
use warnings;

use utf8;

BEGIN {
    # at the time of writing the Test2 'UTF8' plugin still uses :utf8 if left to its own devices
    binmode STDOUT, ':encoding(UTF-8)';
    binmode STDERR, ':encoding(UTF-8)';
}

use Test::More;
use Test::Fatal;
use Test::Deep;
use Object::Pad qw(:experimental(mop));

is(exception {
    eval <<'EOS' or die $@;
    package Example::Role {
        use Myriad::Role;
        method example;
    }

    package Example::Class {
        use Myriad::Class does => 'Example::Role';
        field $something;
        method example { $self }
    }
    1
EOS
}, undef, 'can create a class') or die explain $@;
my $obj = new_ok('Example::Class');
is($obj->example, $obj, 'can call a method');
cmp_deeply([ map { $_->name } Object::Pad::MOP::Class->for_class('Example::Class')->roles ], bag('Example::Role'), 'have expected rôle');
done_testing;

