#!perl

use Test::More tests => 1;

use strict;
use warnings;

use JavaScript;

my $rt1 = JavaScript::Runtime->new();
my $cx1 = $rt1->create_context();

my $calls;
$cx1->bind_function(write => sub { print @_; $calls++; });

$cx1->eval(<<'END_OF_JAVASCRIPT');
for (i = 99; i > 0; i--) {
    write(i + " bottle(s) of beer on the wall, " + i + " bottle(s) of beer\n");
    write("Take 1 down, pass it around, ");
    if (i > 1) {
        write((i - 1) + " bottle(s) of beer on the wall.");
    } else {
        write("No more bottles of beer on the wall!");
    }
    write("\n");
}
END_OF_JAVASCRIPT

is($calls, 396);
