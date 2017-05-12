my $afoo = ['a' .. 'z'];
my $hfoo = {map +($_ => ord($_) - ord('a')), @$afoo};
my @afoo = @$afoo;
my %hfoo = %$hfoo;

$DB::single = 1;

1; # to avoid the program terminating
