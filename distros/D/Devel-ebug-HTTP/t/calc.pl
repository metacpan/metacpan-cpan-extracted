#!perl

my $q = 1;
my $w = 2;
my $e = add($q, $w);
$e++;
$e++;

print "$e\n";

sub add {
  my($z, $x) = @_;
  my $c = $z + $x;
  return $c;
}
