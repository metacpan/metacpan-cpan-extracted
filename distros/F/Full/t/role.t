use Full::Script qw(:v1);

use Test::More;
use Test::Fatal;
use Test::Deep qw(cmp_deeply bag); # full import list pulls in blessed() as well

use Object::Pad qw(:experimental(mop)); # MOP access is still marked as experimental

is(exception {
    eval <<'EOS' or die $@;
    package Example::Role {
        use Full::Role qw(:v1);
        method example;
    }

    package Example::Class {
        use Full::Class qw(:v1), does => 'Example::Role';
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

