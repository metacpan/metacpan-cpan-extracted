
use strict;
use warnings;

use Test::More tests => 9;
use_ok 'Method::Signatures::Simple::ParseKeyword';

{
    package My::Obj;
    use Method::Signatures::Simple::ParseKeyword;

    method make($class: %opts) {
        bless {%opts}, $class;
    }
    method first($o) {
        $self->{first} = $o if @_>1;
        $self->{first};
    }
    method second () {
        $self->first + 1;
    }
    method nth($inc = 1) {
        $self->first + $inc;
    }
}

my $o = My::Obj->make(first => 1);
is $o->first, 1;
is $o->second, 2;
is $o->nth, 2;
is $o->nth(10), 11;

$o->first(10);

is $o->first, 10;
is $o->second, 11;
is $o->nth, 11;
is $o->nth(10), 20;

