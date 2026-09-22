#!perl

my $x = 1;
$x = outer();
$x = 2;
$x = 3;

sub inner  { die "boom\n"; }
sub middle { my $r = eval { inner(); 1 }; return $r ? "ok" : "caught: $@"; }
sub outer  { return middle(); }
