#!perl

my $add = sub {
  my($z, $x) = @_;
  my $c = $z + $x;
  return $c;
};

my $q = 1;
my $w = 2;
my $e = $add->($q, $w);
$e++;
$e++;

print "$e\n";

# unbreakable line
my $breakable_line = 1;
# other unbreakable line
