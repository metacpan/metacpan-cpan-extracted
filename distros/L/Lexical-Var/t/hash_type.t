use warnings;
use strict;

use Test::More tests => 18;

BEGIN { $^H |= 0x20000 if "$]" < 5.008; }

$SIG{__WARN__} = sub { die "WARNING: $_[0]" };

eval q{use Lexical::Var '%foo' => \undef;};
isnt $@, "";
eval q{use Lexical::Var '%foo' => \1;};
isnt $@, "";
eval q{use Lexical::Var '%foo' => \1.5;};
isnt $@, "";
eval q{use Lexical::Var '%foo' => \[];};
isnt $@, "";
eval q{use Lexical::Var '%foo' => \"abc";};
isnt $@, "";
eval q{use Lexical::Var '%foo' => bless(\(my$x="abc"));};
isnt $@, "";
eval q{use Lexical::Var '%foo' => \*main::wibble;};
isnt $@, "";
eval q{use Lexical::Var '%foo' => bless(\*main::wibble);};
isnt $@, "";
eval q{use Lexical::Var '%foo' => qr/xyz/;};
isnt $@, "";
eval q{use Lexical::Var '%foo' => bless(qr/xyz/);};
isnt $@, "";
eval q{use Lexical::Var '%foo' => [];};
isnt $@, "";
eval q{use Lexical::Var '%foo' => bless([]);};
isnt $@, "";
eval q{use Lexical::Var '%foo' => {};};
is $@, "";
eval q{use Lexical::Var '%foo' => bless({});};
is $@, "";
eval q{use Lexical::Var '%foo' => sub{};};
isnt $@, "";
eval q{use Lexical::Var '%foo' => bless(sub{});};
isnt $@, "";

eval q{use Lexical::Var '%foo' => {}; %foo if 0;};
is $@, "";
eval q{use Lexical::Var '%foo' => bless({}); %foo if 0;};
is $@, "";

1;
