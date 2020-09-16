#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Iterator::Records;
use Data::Dumper;

my $i = Iterator::Records->new([[1, 2], [3, 4]], ['field1', 'field2']);
isa_ok ($i, 'Iterator::Records');

# Basic iteration.
my $iter = $i->iter();
is_deeply ($iter->(), [1, 2]);
is_deeply ($iter->(), [3, 4]);
my $last = $iter->();
ok (not defined $last);

# Make sure the second iteration is identical to the first.
$iter = $i->iter();
is_deeply ($iter->(), [1, 2]);
is_deeply ($iter->(), [3, 4]);
$last = $iter->();
ok (not defined $last);

# Now iterate hashrefs.
$iter = $i->iter_hash();
is_deeply ($iter->(), {'field1' => 1, 'field2' => 2});
is_deeply ($iter->(), {'field1' => 3, 'field2' => 4});
$last = $iter->();
ok (not defined $last);

# Itterate hashrefs to check for non-destructive assignment.
$iter = $i->iter_hash();
is_deeply ($iter->(), {'field1' => 1, 'field2' => 2});
is_deeply ($iter->(), {'field1' => 3, 'field2' => 4});
$last = $iter->();
ok (not defined $last);

# Finally, test the bind mechanism.
my ($f1, $f2) = (0, 0);
$iter = $i->iter_bind(\$f1, \$f2);
my $r = $iter->();
is ($f1, 1);
is ($f2, 2);
$r = $iter->();
is ($f1, 3);
is ($f2, 4);
$r = $iter->();
ok (not defined $r);

# And again, to verify non-destructive assignment.
($f1, $f2) = (0, 0);
$iter = $i->iter_bind(\$f1, \$f2);
$r = $iter->();
is ($f1, 1);
is ($f2, 2);
$r = $iter->();
is ($f1, 3);
is ($f2, 4);
$r = $iter->();
ok (not defined $r);

# Let's try iterating from a coderef. Remember, the coderef has to *return* a coderef that is the actual iterator.

sub foo {
  my $max = shift;
  my $i = 0;
  sub {
    return if $i > $max;
    return [$i++, $max-$i+1];
  }
}

$i = Iterator::Records->new(\&foo, ['count', 'remaining']);

$iter = $i->iter(20);
is_deeply ($iter->(), [0, 20]);
is_deeply ($iter->(), [1, 19]);
is_deeply ($iter->(), [2, 18]);
is_deeply ($iter->(), [3, 17]);

# And do it again.
$iter = $i->iter(2);
is_deeply ($iter->(), [0, 2]);
is_deeply ($iter->(), [1, 1]);
is_deeply ($iter->(), [2, 0]);
$r = $iter->();
ok (not defined $r);

#diag(Dumper ($i->load()));


done_testing ();
