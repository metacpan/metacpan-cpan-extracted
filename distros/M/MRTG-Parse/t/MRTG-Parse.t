use Test::Simple tests => 2;

ok(1 + 2 == 3, 'Check  1 + 2 = 3   ;-)');

my $localtime           = localtime();
ok(defined($localtime), 'Check if localtime() works');

