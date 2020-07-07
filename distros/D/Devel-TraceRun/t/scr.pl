use Thing;

my $f = sub { Thing::func() };

Thing::func([2]); # void
my @r = Thing::func([2]);

my @r2 = $f->("very long string", 2, bless {}, 'Thing');
