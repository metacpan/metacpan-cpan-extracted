
`cp t/isinittab.master t/isinittab`;

sub lines
{
  $DB::single=1;
  open(F,"<t/out") || die $!;
  my @F=<F>;
  my $lines=$#F + 1;
  return $lines;
}

sub lastline
{
  open(F,"<t/out") || die $!;
  my @F=<F>;
  chomp(my $lastline=$F[$#F]);
  return $lastline;
}

1;
