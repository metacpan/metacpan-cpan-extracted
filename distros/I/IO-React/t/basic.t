# -*- mode: perl -*-

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}
use IO::React;
$loaded = 1;
print "ok 1\n";

# Test utils
my $i = 2;
sub success (&) { eval { $_[0]->() }; print ($@ ? "not ok $i\n" : "ok $i\n"); $i++; }
sub failure (&) { eval { $_[0]->() }; print ($@ ? "ok $i\n" : "not ok $i\n"); $i++; }

# Basic tests
my $ioh = new IO::Handle;

# Create an object
success {
  my $r = new IO::React($ioh);
};

# set_wait
success {
  my $r = new IO::React($ioh);
  $r->set_wait(0);
};

success {
  my $r = new IO::React($ioh);
  $r->set_wait(30);
};

success {
  my $r = new IO::React($ioh);
  $r->set_wait(undef);
};

failure {
  my $r = new IO::React($ioh);
  $r->set_wait("invalid");
};

# set_timeout
success {
  my $r = new IO::React($ioh);
  $r->set_timeout(sub {});
};

failure {
  my $r = new IO::React($ioh);
  $r->set_timeout(1);
};

# set_eof
success {
  my $r = new IO::React($ioh);
  $r->set_eof(sub {});
};

failure {
  my $r = new IO::React($ioh);
  $r->set_eof(1);
};

# set_display
success {
  my $r = new IO::React($ioh);
  $r->set_display(0);
};

success {
  my $r = new IO::React($ioh);
  $r->set_display(1);
};
