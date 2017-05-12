use Test::Simple 'no_plan';

for my $tmp (qw(t/Hillary1.jpg.sq.jpg)){
   -f $tmp or next;
   unlink $tmp;

}


ok(1,'cleaned up');
