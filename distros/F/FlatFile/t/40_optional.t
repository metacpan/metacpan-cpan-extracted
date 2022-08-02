use strict; use warnings;

use Test::More tests => 12;
use FlatFile;
ok(1); # If we made it this far, we're ok.

my @TO_REMOVE = my $FILE = "/tmp/FlatFile.$$";
END { unlink @TO_REMOVE }

open F, ">", $FILE or die "$FILE: $!";
print F <DATA>;
close F;

my $f = FlatFile->new(FILE => $FILE,
                                  FIELDS => ["fruit", "color"],
                                  DEFAULTS => { color => "red" },
                                  MODE => "<",
                                  );
ok($f);

my @apple = $f->lookup(fruit => "apple");
is(scalar(@apple), 1);
is ($apple[0]->fruit, "apple");
is ($apple[0]->color, "red");

my @redfruit3 = $f->lookup(color => "red");
is(scalar(@redfruit3), 3);
is($redfruit3[0]->fruit, "apple");
is($redfruit3[1]->fruit, "cherry");
is($redfruit3[2]->fruit, "strawberry");
is($redfruit3[0]->color, "red");
is($redfruit3[1]->color, "red");
is($redfruit3[2]->color, "red");

__DATA__
apple
banana green
cherry red
kiwi brown
strawberry
