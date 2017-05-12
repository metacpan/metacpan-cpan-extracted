# IO::Callback 1.08 t/iostring-write.t
# This is t/write.t from IO::String 1.08, adapted to IO::Callback.

use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;

use IO::Callback;

my $str = '';
my $io = IO::Callback->new('>', sub { $str .= shift });

print $io "Heisan\n";
$io->print("a", "b", "c");

{
    local($\) = "\n";
    print $io "d", "e";
    local($,) = ",";
    print $io "f", "g", "h";
}

my $foo = "1234567890";

syswrite($io, $foo, length($foo));
$io->syswrite($foo);
$io->syswrite($foo, length($foo));
$io->write($foo, length($foo), 5);
$io->write("xxx\n", 100, -1);

for (1..3) {
    printf $io "i(%d)", $_;
    $io->printf("[%d]\n", $_);
}
select $io;
print "\n";

is( $str, "Heisan\nabcde\nf,g,h\n" .
          ("1234567890" x 3) . "67890\n" .
          "i(1)[1]\ni(2)[2]\ni(3)[3]\n\n",
    'data written to $str as expected'
);

