#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

use Test::More tests => 39;

use Err qw(declare_err throw_err is_err ex_is_err);

########################################################################
# ISA and automatic code handling
########################################################################

# with dot

declare_err ".Foo";
declare_err ".Foo.Bar";

ok("Err::Exception::Foo"->isa("Err::Exception"), "Foo isa Ex");
ok("Err::Exception::Foo"->isa("Exception::Class::Base"), "Foo isa Ex");
ok("Err::Exception::Foo::Bar"->isa("Err::Exception"), "Bar isa Ex");
ok("Err::Exception::Foo::Bar"->isa("Err::Exception::Foo"), "Bar isa Foo");

# without dot

declare_err "Foo";
declare_err "Foo.Bar";

ok("Foo"->isa("Err::Exception"), "Foo isa Ex");
ok("Foo"->isa("Exception::Class::Base"), "Foo isa Ex");
ok("Foo::Bar"->isa("Err::Exception"), "Bar isa Ex");
ok("Foo::Bar"->isa("Foo"), "Bar isa Foo");

########################################################################
# dynamic parent
########################################################################

# with dot

declare_err ".A";
declare_err ".A.B";
declare_err ".A.C",
  isa => ".A.B";

ok("Err::Exception::A::B"->isa("Err::Exception::A"), "a.b is a");
ok("Err::Exception::A::C"->isa("Err::Exception::A"), "a.c is a");
ok("Err::Exception::A::C"->isa("Err::Exception::A::B"), "a.c is a");

# without dot

declare_err "A";
declare_err "A.B";
declare_err "A.C",
  isa => "A.B";

ok("A::B"->isa("A"), "a.b is a");
ok("A::C"->isa("A"), "a.c is a");
ok("A::C"->isa("A::B"), "a.c is a");

########################################################################
# message
########################################################################

declare_err "AAAAAAAGH";

eval {
    throw_err "AAAAAAAGH", "My HAIR is on FIRE!";
};
is($@->message, "My HAIR is on FIRE!", "message");

########################################################################
# explanation
########################################################################

declare_err "Baz",
  description => "Barry White, saved my life";

declare_err "Baz.Buzz",
  description => "Like a bee!!";

declare_err "Baz.Blanc";

eval {
    throw_err "", "Womble";
};
is($@->description, "Generic exception");

eval {
    throw_err "Baz", "Bazzzzy";
};
is($@->description, "Barry White, saved my life", "description");

eval {
    throw_err "Baz.Buzz", "Buzzzzy";
};
is($@->description, "Like a bee!!", "overriden");

eval {
    throw_err "Baz.Blanc", "Tames Snakes";
};
is($@->description, "Barry White, saved my life", "inherited");

########################################################################
# defining another method 'on the fly'
########################################################################

declare_err "Flip",
  womble => "turnip";

eval {
    throw_err "Flip", "Flop";
};
is($@->womble, "turnip", "another field");

eval {
    throw_err "Flip", "Flop", womble => "Sweed";
};
is($@->womble, "Sweed", "override field per instance");

########################################################################
# ex_is_err
########################################################################

eval {
    throw_err "", "base class";
};
ok(ex_is_err(""), "ex_is_err");

eval { do {} };
ok(!ex_is_err("Baz"), "ex_is_err");
ok(!ex_is_err("Baz.Buzz"), "ex_is_err");

eval {
    die "not an err::exception";
};
ok(!ex_is_err("Baz"), "ex_is_err");
ok(!ex_is_err("Baz.Buzz"), "ex_is_err");

eval {
    throw_err "Baz", "yo!";
};
ok(ex_is_err("Baz"), "ex_is_err");
ok(!ex_is_err("Baz.Buzz"), "ex_is_err");

eval {
    throw_err "Baz.Buzz", "yo!"
};
ok(ex_is_err("Baz"), "ex_is_err");
ok(ex_is_err("Baz.Buzz"), "ex_is_err");

########################################################################
# is err
########################################################################

{
    eval {
        throw_err "", "base class";
    };
    local $_ = $@;
    ok(is_err(""), "ex_is_err");

}

{
    eval { do {} };
    local $_ = $@;
    ok(!is_err("Baz"), "is_err");
    ok(!is_err("Baz.Buzz"), "is_err");
}

{
    eval {
        die "not an err::exception";
    };
    local $_ = $@;
    ok(!is_err("Baz"), "is_err");
    ok(!is_err("Baz.Buzz"), "is_err");
}

{
    eval {
        throw_err "Baz", "yo!";
    };
    local $_ = $@;

    ok(is_err("Baz"), "is_err");
    ok(!is_err("Baz.Buzz"), "is_err");
}

{
    eval {
        throw_err "Baz.Buzz", "yo!"
    };
    local $_ = $@;
    ok(is_err("Baz"), "is_err");
    ok(is_err("Baz.Buzz"), "is_err");
}

