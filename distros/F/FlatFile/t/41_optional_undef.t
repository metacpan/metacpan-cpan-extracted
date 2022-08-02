use strict; use warnings;

use Test::More tests => 5;
use FlatFile;
ok(1); # If we made it this far, we're ok.

my @TO_REMOVE = my $FILE = "/tmp/FlatFile.$$";
END { unlink @TO_REMOVE }

open F, ">", $FILE or die "$FILE: $!";
print F <DATA>;
close F;

my $f = FlatFile->new(FILE => $FILE,
                                  FIELDS => ["fruit", "color"],
                                  DEFAULTS => { color => undef },
                                  MODE => "<",
                                  );
ok($f);

my @apple = $f->lookup(fruit => "apple");
is(scalar(@apple), 1);
is ($apple[0]->fruit, "apple");
is ($apple[0]->color, undef);

__DATA__
apple
banana green
cherry red
kiwi brown
strawberry
