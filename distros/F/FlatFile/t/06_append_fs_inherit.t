use strict; use warnings;

use Test::More tests => 12;
ok(1);

my @TO_REMOVE = my $FILE = "/tmp/FlatFile.$$";
END { unlink @TO_REMOVE }

open F, ">", $FILE or die "$FILE: $!";
print F <DATA>;
close F;

package FRUIT;
use FlatFile;
our @ISA = 'FlatFile';
our $FIELDS = [qw(fruit color)];
our $FIELDSEP = ":";

package main;
my $f = FRUIT->new(FILE => $FILE, MODE => "+<");
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

$f = FRUIT->new(FILE => $FILE, MODE => "+<");
ok($f);
@recs = $f->c_lookup(sub {1});
is(scalar(@recs), 5);
$f->append('orange', 'orange');
my ($Orange) = $f->lookup(fruit => 'orange');
$f->delete_rec($Orange);
@recs = $f->c_lookup(sub {1});
is(scalar(@recs), 5);
$f->flush;

$f = FRUIT->new(FILE => $FILE, MODE => "+<");
@recs = $f->c_lookup(sub {1});
is(scalar(@recs), 5);
my @Orange = $f->lookup(fruit => 'orange');
is(scalar(@Orange), 0);

__DATA__
apple:red
banana:green
cherry:red
kiwi:brown
