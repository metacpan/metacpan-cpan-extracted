my $foo = 123;
my @foo = qw(1 2 3);
my %foo = (a => 1, b => 2, c => 3);
my $aref = [qw(3 2 1)];
my $undef;

$DB::single = 1;

1; # to avoid the program terminating
