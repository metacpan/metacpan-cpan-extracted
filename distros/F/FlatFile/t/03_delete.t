
use Test::More tests => 11;
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

# Open, read, delete first
@redfruit2 = $f->lookup(color => "red");
is(scalar(@redfruit2), 2);
$redfruit2[0]->delete;
my @redfruit1a = $f->lookup(color => "red");
is(scalar(@redfruit1a), 1);
is($redfruit1a[0]->fruit, $redfruit2[1]->fruit);
$f->flush;

$f = FlatFile->new(FILE => $FILE,
                                  FIELDS => [qw(fruit color)],
                                  MODE => "+<",
                               );
ok($f);

my @redfruit1b = $f->lookup(color => "red");
is(scalar(@redfruit1b), 1);
is($redfruit1b[0]->fruit, $redfruit2[1]->fruit);
$redfruit1b[0]->delete;
my @redfruit0a = $f->lookup(color => "red");
is(scalar(@redfruit0a), 0);
$f->flush;

$f = FlatFile->new(FILE => $FILE,
                                  FIELDS => [qw(fruit color)],
                                  MODE => "+<",
                               );
ok($f);

my @redfruit0b = $f->lookup(color => "red");
is(scalar(@redfruit0b), 0);



__DATA__
apple  red
banana green
cherry red
kiwi brown
