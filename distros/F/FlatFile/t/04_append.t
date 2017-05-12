
use Test::More tests => 13;
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

@redfruit2 = $f->lookup(color => "red");
is(scalar(@redfruit2), 2);

$f->append('strawberry', 'red');
@recs = $f->c_lookup(sub {1});
is(scalar(@recs), 5);
@redfruit3 = $f->lookup(color => "red");
is(scalar(@redfruit3), 3);
is($redfruit3[0]->fruit, 'apple');
is($redfruit3[2]->fruit, 'strawberry');

$f->flush;
undef $f;

$f = FlatFile->new(FILE => $FILE,
                               FIELDS => [qw(fruit color)],
                               MODE => "+<",
                              );
ok($f);
@recs = $f->c_lookup(sub {1});
is(scalar(@recs), 5);
$f->append('orange', 'orange');
($Orange) = $f->lookup(fruit => 'orange');
$f->delete_rec($Orange);
@recs = $f->c_lookup(sub {1});
is(scalar(@recs), 5);
$f->flush;

$f = FlatFile->new(FILE => $FILE,
                               FIELDS => [qw(fruit color)],
                               MODE => "+<",
                              );
ok($f);
@recs = $f->c_lookup(sub {1});
is(scalar(@recs), 5);
@Orange = $f->lookup(fruit => 'orange');
is(scalar(@Orange), 0);



__DATA__
apple  red
banana green
cherry red
kiwi brown
