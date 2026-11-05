#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Ex::Op ();
use B::Deparse ();

# Before 5.14 a custom op is registered by name alone, with no class, so B
# hands B::Deparse a plain B::OP for the call and it dies asking for ->first.
plan skip_all => 'B::Deparse cannot tell a custom op\'s class before perl 5.14' if $] < 5.014;

BEGIN { Ex::Op::make(twice => sub { my ($x) = @_; $x * 2 }) }
sub uses_it { my ($y) = @_; twice($y) + 1 }

ok( Ex::Op::is_op(\&twice), 'an op' );
my @warn;
local $SIG{__WARN__} = sub { push @warn, $_[0] };
my $text = B::Deparse->new->coderef2text(\&uses_it);
is_deeply( \@warn, [], 'deparsing a sub that calls an op warns of nothing' ) or diag @warn;
like( $text, qr/twice\(\$y\)/, 'and shows the call as a call' );
unlike( $text, qr/XXX/, 'with no placeholder' );

done_testing;
