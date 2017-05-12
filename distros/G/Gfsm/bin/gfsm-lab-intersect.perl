#!/usr/bin/perl -w

if (!@ARGV || $ARGV[0] =~ m/^\-{1,2}h/) {
  print STDERR "Usage: $0 LABFILE...\n";
  exit 1;
}

our @labh = qw();
foreach $file (@ARGV) {
  $labs = {};
  open(LAB,"<$file") or die("$0: open failed for '$file': $!");
  while (defined($line=<LAB>)) {
    chomp($line);
    next if ($line =~ m/^\s*$/);
    ($sym,$lab) = split(/\s+/,$line);
    $labs->{$sym} = $lab;
  }
  close(LAB);
  push(@labh,$labs);
}

##-- intersection
$labs = shift(@labh);
$all  = { %$labs };
foreach $labs (@labh) {
  @bad  = grep {!exists($labs->{$_})} keys(%$all);
  delete(@$all{@bad});
}

##-- output
print
  map { "$_\t$all->{$_}\n" } sort {$all->{$a} <=> $all->{$b}} keys(%$all);
