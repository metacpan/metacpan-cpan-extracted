# IO::Callback 1.08 t/iostring-para.t
# This is t/para.t from IO::String 1.08, adapted to IO::Callback.

use strict;
use warnings;

use Test::More tests => 9;
use Test::NoWarnings;

use IO::Callback;

my $fh;
my $str;
my $callback_state;

sub reset_test {
    $str = shift;
    $callback_state = 0;
    $fh = IO::Callback->new("<", \&callback);
}

sub callback {
    if ($callback_state == 0) {
        $callback_state = 1;
        return $str;
    } elsif ($callback_state == 1) {
        $callback_state = 2;
        return;
    } else {
        die "callback called again after eof";
    }
}

reset_test(<<EOT);
a

a
b

a
b
c



a
b
c
d
EOT

$/ = "";

is(<$fh>, "a\n\n");
is(<$fh>, "a\nb\n\n");
is(<$fh>, "a\nb\nc\n\n");
is(<$fh>, "a\nb\nc\nd\n");
is(<$fh>, undef);

reset_test(<<EOT);
a
b






EOT

is(<$fh>, "a\nb\n\n");
is(<$fh>, undef);
is(<$fh>, undef);

