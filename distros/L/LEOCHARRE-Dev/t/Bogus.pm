package Bogus;

sub new {
   my $c = shift;
   return bless {}, $c;
}

sub m1 {
   my $self = shift;
   return 1;
}
   





1;
