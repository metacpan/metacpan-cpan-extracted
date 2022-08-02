use strict; use warnings;

use Test::More tests => 13;
use FlatFile;
ok(1);

my @TO_REMOVE = my $FILE = "/tmp/FlatFile.$$";
END { unlink @TO_REMOVE }

open F, ">", $FILE or die "$FILE: $!";
print F "apple:red---banana:green---cherry:red---kiwi:brown---";
close F;

my $f = FlatFile->new(FILE => $FILE,
                                  FIELDS => [qw(fruit color)],
                                  MODE => "+<",
                                  FIELDSEP => ":",
                                  RECSEP => "---",
                                  );
ok($f);

my @redfruit2 = $f->lookup(color => "red");
is(scalar(@redfruit2), 2);

$f->append('strawberry', 'red');
my @recs = $f->c_lookup(sub {1});
is(scalar(@recs), 5);
my @redfruit3 = $f->lookup(color => "red");
is(scalar(@redfruit3), 3);
is($redfruit3[0]->fruit, 'apple');
is($redfruit3[2]->fruit, 'strawberry');

$f->flush;
undef $f;

$f = FlatFile->new(FILE => $FILE,
                               FIELDS => [qw(fruit color)],
                               MODE => "+<",
                               FIELDSEP => ":",
                               RECSEP => "---",
                              );
ok($f);
@recs = $f->c_lookup(sub {1});
is(scalar(@recs), 5);
$f->append('orange', 'orange');
my ($Orange) = $f->lookup(fruit => 'orange');
$f->delete_rec($Orange);
@recs = $f->c_lookup(sub {1});
is(scalar(@recs), 5);
$f->flush;

$f = FlatFile->new(FILE => $FILE,
                               FIELDS => [qw(fruit color)],
                               MODE => "+<",
                               FIELDSEP => ":",
                               RECSEP => "---",
                              );
ok($f);
@recs = $f->c_lookup(sub {1});
is(scalar(@recs), 5);
my @Orange = $f->lookup(fruit => 'orange');
is(scalar(@Orange), 0);
