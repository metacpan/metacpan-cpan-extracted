use Test;
plan test => 3;
eval { require Devel::Leak };
ok($@, "", "loading module");
eval { import Devel::Leak };
ok($@, "", "running import");
@somewhere = ();
my $count = Devel::Leak::NoteSV($handle);
print "$count SVs so far\n";
for my $i (1..10)
 {
  @somewhere = qw(one two);
 }
my $now = Devel::Leak::CheckSV($handle);
ok($now, $count+2, "Number of SVs created unexpected");

