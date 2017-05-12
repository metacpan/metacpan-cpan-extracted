sub one {
  print "sub one\n";
}

sub two {
  print 'sub two'."\n";
}

sub three {
  print "sub three\n";
}

my $a = "sub five {}\n";
my $b = 'sub six {}';

__DATA__

sub four {
  print "four\n";
}
