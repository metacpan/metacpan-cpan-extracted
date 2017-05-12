package Math;

our $VERSION = "0.5";

sub add {
   my ($p) = @_;
   my $sum;map({$sum += $_;} @$p);
   return({'res' => $sum});
}
sub multiply {
   my ($p) = @_;
   my $sum;map({$sum *= $_;} @$p);
   return({'res' => $sum});
}
1;
