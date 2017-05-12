use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan skip_all => 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.' unless $ENV{TEST_AUTHOR};

my $cmds = {
  "grep -nr 'print STDERR Dumper' lib/ script/" => {},
};

# find all missed debug outputs
for my $cmd (keys %{$cmds}) {
  my $opt = $cmds->{$cmd};
  open(my $ph, '-|', $cmd.' 2>&1') or die('cmd '.$cmd.' failed: '.$!);
  ok($ph, 'cmd started');
  while(<$ph>) {
    my $line = $_;
    chomp($line);
    $line =~ s|//|/|gmx;
    fail($line);
  }
  close($ph);
}


done_testing();
