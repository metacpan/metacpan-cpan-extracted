use strict; use warnings;

use Test::More tests => 6;
use FlatFile;
ok(1); # If we made it this far, we're ok.

my @TO_REMOVE = my $FILE = "/tmp/FlatFile.$$";
END { unlink @TO_REMOVE }

open F, ">", $FILE or die "$FILE: $!";
print F <DATA>;
close F;

my $f = FlatFile->new(FILE => $FILE,
                                  FIELDS => [qw(fruit color)],
                                  MODE => "+<",
                                  );
ok($f);
is($f->rec_count, 4);
undef $f;

# does it work in the middle of a nextrec loop?
$f = FlatFile->new(FILE => $FILE,
                               FIELDS => [qw(fruit color)],
                               MODE => "<",
                              );
ok($f);
my $r1 = $f->nextrec;
my $r2 = $f->nextrec;
is($f->rec_count, 4);
my $r3 = $f->nextrec;
is($r3->fruit, "cherry");

__DATA__
apple  red
banana green
cherry red
kiwi brown
